--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: замена crates/skate-game/src/input/platform.rs (коммит 2e16697).
--
-- В Rust platform.rs читает геймпад (SDL3/XInput) и отдаёт XboxState —
-- кнопки XInput, байты триггеров и знаковые оси стиков. Дальше всё идёт
-- через родной конвертер xbox.convert, историю и Pad.
-- В Roblox геймпада нет (управление только с ПК), поэтому этот модуль
-- собирает тот же XboxState из клавиатуры и мыши. Всё, что после него,
-- остаётся кодом порта без изменений.
--
-- Раскладка (своя, только ПК):
--   W A S D        левый стик (катание, поворот)
--   ЛКМ + мышь     правый стик (флик-стик трюков): зажать и вести мышь,
--                  смещение от точки нажатия / RADIUS_PX; отпустить = центр
--   стрелки        правый стик цифрой (запасной вариант без мыши)
--   Space          A  (толчок правой ногой)
--   LeftShift      X  (толчок левой / mongo)
--   F              B  (тормоз, спешиться в воздухе)
--   R              Y  (сойти с доски / встать)
--   Q / E          левый / правый триггер (грэбы)
--   Z / C          левый / правый бампер (C = GrabWorld)
--   LeftControl    клик левого стика, СКМ — клик правого
--   1 2 3 4        D-pad вверх / вниз / влево / вправо
--   Enter / Tab    Start / Back

local UserInputService = game:GetService("UserInputService")

local keyboard_pad = {}

-- XInput wButtons, как platform::BUTTON_NAMES.
local DPAD_UP, DPAD_DOWN, DPAD_LEFT, DPAD_RIGHT = 0x0001, 0x0002, 0x0004, 0x0008
local START, BACK, LEFT_STICK, RIGHT_STICK = 0x0010, 0x0020, 0x0040, 0x0080
local LEFT_SHOULDER, RIGHT_SHOULDER = 0x0100, 0x0200
local A, B, X, Y = 0x1000, 0x2000, 0x4000, 0x8000

local RADIUS_PX = 110
local AXIS_MAX = 32767

local BUTTONS: { { any } } = {
	{ Enum.KeyCode.Space, A },
	{ Enum.KeyCode.LeftShift, X },
	{ Enum.KeyCode.F, B },
	{ Enum.KeyCode.R, Y },
	{ Enum.KeyCode.Z, LEFT_SHOULDER },
	{ Enum.KeyCode.C, RIGHT_SHOULDER },
	{ Enum.KeyCode.LeftControl, LEFT_STICK },
	{ Enum.KeyCode.One, DPAD_UP },
	{ Enum.KeyCode.Two, DPAD_DOWN },
	{ Enum.KeyCode.Three, DPAD_LEFT },
	{ Enum.KeyCode.Four, DPAD_RIGHT },
	{ Enum.KeyCode.Return, START },
	{ Enum.KeyCode.Tab, BACK },
}

export type KeyboardPad = {
	number: number,
	anchor: Vector2?,
	enabled: boolean,
	connections: { RBXScriptConnection },
}

local function axis(value: number): number
	return math.clamp(math.round(value * AXIS_MAX), -32768, AXIS_MAX)
end

function keyboard_pad.new(): KeyboardPad
	local self: KeyboardPad = { number = 0, anchor = nil, enabled = true, connections = {} }
	table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.anchor = UserInputService:GetMouseLocation()
		end
	end))
	table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.anchor = nil
		end
	end))
	return self
end

function keyboard_pad.destroy(self: KeyboardPad)
	for _, c in self.connections do
		c:Disconnect()
	end
	table.clear(self.connections)
end

local function down(key: Enum.KeyCode): boolean
	return UserInputService:IsKeyDown(key)
end

-- Текущее состояние в формате XboxState (skate_core/input/xbox).
function keyboard_pad.state(self: KeyboardPad): any
	local buttons = 0
	if self.enabled and not UserInputService:GetFocusedTextBox() then
		for _, pair in BUTTONS do
			if down(pair[1]) then
				buttons = bit32.bor(buttons, pair[2])
			end
		end
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3) then
			buttons = bit32.bor(buttons, RIGHT_STICK)
		end
	else
		return { buttons = 0, triggers = { 0, 0 }, left = { 0, 0 }, right = { 0, 0 } }
	end
	local lx = (if down(Enum.KeyCode.D) then 1 else 0) - (if down(Enum.KeyCode.A) then 1 else 0)
	local ly = (if down(Enum.KeyCode.W) then 1 else 0) - (if down(Enum.KeyCode.S) then 1 else 0)
	local rx = (if down(Enum.KeyCode.Right) then 1 else 0) - (if down(Enum.KeyCode.Left) then 1 else 0)
	local ry = (if down(Enum.KeyCode.Up) then 1 else 0) - (if down(Enum.KeyCode.Down) then 1 else 0)
	local anchor = self.anchor
	if anchor then
		local offset = (UserInputService:GetMouseLocation() - anchor) / RADIUS_PX
		if offset.Magnitude > 1 then
			offset = offset.Unit
		end
		-- XInput: Y стика положителен вверх, у экрана Y растёт вниз.
		rx, ry = offset.X, -offset.Y
	end
	return {
		buttons = buttons,
		triggers = { if down(Enum.KeyCode.Q) then 255 else 0, if down(Enum.KeyCode.E) then 255 else 0 },
		left = { axis(lx), axis(ly) },
		right = { axis(rx), axis(ry) },
	}
end

-- Один опрос для ControllerInput.collect: слот 0 — клавиатура, остальные
-- отключены (как пустые слоты XInput).
function keyboard_pad.poll(self: KeyboardPad): { any }
	self.number += 1
	local off = { err = { kind = "Disconnected" } }
	return {
		{ ok = { number = self.number, state = keyboard_pad.state(self), subtype = 1, kind = nil } },
		off,
		off,
		off,
	}
end

-- Состояние в формате ядра sim (skate_game/input/platform): плоский XInput.
function keyboard_pad.gamepad(self: KeyboardPad): any
	local s = keyboard_pad.state(self)
	return {
		buttons = s.buttons,
		left_trigger = s.triggers[1],
		right_trigger = s.triggers[2],
		left_x = s.left[1],
		left_y = s.left[2],
		right_x = s.right[1],
		right_y = s.right[2],
	}
end

return keyboard_pad
