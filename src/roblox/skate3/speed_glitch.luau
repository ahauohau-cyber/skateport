--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: макрос «спид-глитча» Skate 3 на одну клавишу.
--
-- Сам глитч — поведение оригинальной игры (в ядре sim ничего не меняем).
-- Ручной способ (раскладка Xbox):
--   1. встать спиной туда, куда хочешь улететь;
--   2. сойти с доски (Y) и бросить её (курок, RT) — не стоять на ней и не держать;
--   3. прыжок (X);
--   4. на вершине прыжка — RB;
--   5. ровно через 3 кадра (1/20 с) — Y.
-- Доска «прилетает» к игроку и уезжает с ним со скоростью ~14 м/с
-- (толчками разгоняешься максимум до ~8.5).
--
-- Окно очень узкое (проверено в Studio): Y на кадр раньше или на 4 позже —
-- буста нет. Поэтому макрос жмёт X → RB → Y с точными задержками в тиках
-- ядра (1/60 с), а не по времени кадра.

local speed_glitch = {}

local X, Y, RB = 0x4000, 0x8000, 0x0200
local RT = 255

-- Физические состояния ядра (player/state.rs).
local BIPED_GROUND, BIPED_AIR, OFFBOARD_PUSHING = 500, 501, 502

export type Phase = "idle" | "dismount" | "wait_ground" | "drop" | "settle" | "jump" | "mount"

export type Settings = {
	drop_hold: number, -- тиков держать RT (бросить доску)
	settle: number, -- тиков постоять после броска
	x_hold: number, -- тиков держать X (прыжок)
	rb_at: number, -- тиков от нажатия X до RB (вершина прыжка)
	rb_hold: number, -- тиков держать RB
	y_after_rb: number, -- тиков от начала RB до Y (главная цифра: 3)
	y_hold: number, -- тиков держать Y
}

export type Macro = {
	phase: Phase,
	ticks: number, -- тиков в текущей фазе
	settings: Settings,
}

function speed_glitch.defaults(): Settings
	return { drop_hold = 10, settle = 40, x_hold = 3, rb_at = 31, rb_hold = 2, y_after_rb = 3, y_hold = 4 }
end

function speed_glitch.new(): Macro
	return { phase = "idle", ticks = 0, settings = speed_glitch.defaults() }
end

function speed_glitch.start(self: Macro)
	if self.phase == "idle" then
		self.phase = "dismount"
		self.ticks = 0
	end
end

local function go(self: Macro, phase: Phase)
	self.phase = phase
	self.ticks = 0
end

local function offboard(state: number): boolean
	return state == BIPED_GROUND or state == OFFBOARD_PUSHING
end

-- Один тик. state — физическое состояние ядра,
-- holding — доска у игрока в руках.
-- Возвращает кнопки и правый курок, которые добавить к геймпаду в этот тик.
function speed_glitch.step(self: Macro, state: number, holding: boolean): (number, number)
	if self.phase == "idle" then
		return 0, 0
	end
	local s = self.settings
	self.ticks += 1
	local phase = self.phase
	if phase == "dismount" then
		if offboard(state) then
			go(self, if holding then "drop" else "settle")
			return 0, 0
		end
		-- Y — сойти с доски; держим несколько тиков, потом ждём земли.
		if self.ticks <= 3 then
			return Y, 0
		end
		go(self, "wait_ground")
		return 0, 0
	elseif phase == "wait_ground" then
		if offboard(state) and self.ticks >= 30 then
			go(self, if holding then "drop" else "settle")
		elseif self.ticks > 150 then
			go(self, "idle")
		end
		return 0, 0
	elseif phase == "drop" then
		if self.ticks <= s.drop_hold then
			return 0, RT
		end
		go(self, "settle")
		return 0, 0
	elseif phase == "settle" then
		if self.ticks >= s.settle then
			go(self, "jump")
		end
		return 0, 0
	elseif phase == "jump" then
		-- Тики считаются от первого нажатия X: X, потом RB на rb_at, Y через y_after_rb.
		local t = self.ticks
		if t <= s.x_hold then
			return X, 0
		end
		if t >= s.rb_at + s.y_after_rb then
			go(self, "mount")
			self.ticks = 1
			return Y, 0
		end
		if t >= s.rb_at and t < s.rb_at + s.rb_hold then
			return RB, 0
		end
		if t > 20 and t < s.rb_at and state ~= BIPED_AIR then
			-- Прыжок не получился (не оторвались от земли) — отменяем.
			go(self, "idle")
		end
		return 0, 0
	elseif phase == "mount" then
		if self.ticks <= s.y_hold then
			return Y, 0
		end
		go(self, "idle")
		return 0, 0
	end
	return 0, 0
end

return speed_glitch
