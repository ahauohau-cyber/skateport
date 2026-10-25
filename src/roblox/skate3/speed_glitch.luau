--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: макрос «спид-глитча» Skate 3 на одну клавишу.
--
-- Сам глитч — поведение оригинальной игры (в ядре sim ничего не меняем).
-- Ручной способ (раскладка Xbox):
--   1. встать спиной туда, куда хочешь улететь;
--   2. сойти с доски (Y) — не стоять на ней и не держать её;
--   3. прыжок (X);
--   4. в верхней точке прыжка — RB;
--   5. сразу Y (встать на доску).
-- Макрос жмёт это сам: сходит с доски, если нужно, прыгает, ловит верхнюю
-- точку по высоте таза скейтера и в тот же тик жмёт RB, затем Y.
-- Скорость после глитча случайная и срабатывает он не всегда — как в игре.

local speed_glitch = {}

local X, Y, RB = 0x4000, 0x8000, 0x0200

-- Физические состояния ядра (player/state.rs).
local BIPED_GROUND, BIPED_AIR, OFFBOARD_PUSHING = 500, 501, 502

export type Phase = "idle" | "dismount" | "wait_ground" | "jump" | "rise" | "rb" | "gap" | "mount"

export type Macro = {
	phase: Phase,
	ticks: number, -- тиков в текущей фазе
	last_height: number?,
	-- Настройки (тики по 1/60 с).
	rb_hold: number,
	gap: number,
	y_hold: number,
}

function speed_glitch.new(): Macro
	return { phase = "idle", ticks = 0, last_height = nil, rb_hold = 2, gap = 1, y_hold = 4 }
end

function speed_glitch.start(self: Macro)
	if self.phase == "idle" then
		self.phase = "dismount"
		self.ticks = 0
		self.last_height = nil
	end
end

local function go(self: Macro, phase: Phase)
	self.phase = phase
	self.ticks = 0
end

local function offboard(state: number): boolean
	return state == BIPED_GROUND or state == OFFBOARD_PUSHING
end

-- Один тик: state — физическое состояние ядра, hips_y — высота таза (метры).
-- Возвращает кнопки, которые добавить к геймпаду в этот тик.
function speed_glitch.step(self: Macro, state: number, hips_y: number): number
	if self.phase == "idle" then
		return 0
	end
	self.ticks += 1
	local phase = self.phase
	if phase == "dismount" then
		if offboard(state) then
			go(self, "jump")
			return 0
		end
		-- Y — сойти с доски; держим несколько тиков, потом ждём земли.
		if self.ticks <= 3 then
			return Y
		end
		go(self, "wait_ground")
		return 0
	elseif phase == "wait_ground" then
		if offboard(state) then
			go(self, "jump")
		elseif self.ticks > 120 then
			go(self, "idle")
		end
		return 0
	elseif phase == "jump" then
		if self.ticks <= 3 then
			return X
		end
		go(self, "rise")
		self.last_height = hips_y
		return 0
	elseif phase == "rise" then
		-- Ждём полёта и момента, когда таз перестал подниматься (вершина).
		local last = self.last_height or hips_y
		self.last_height = hips_y
		if state == BIPED_AIR and hips_y < last then
			go(self, "rb")
			return RB
		end
		if self.ticks > 90 then
			go(self, "idle")
		end
		return 0
	elseif phase == "rb" then
		if self.ticks < self.rb_hold then
			return RB
		end
		go(self, "gap")
		return 0
	elseif phase == "gap" then
		if self.ticks >= self.gap then
			go(self, "mount")
			return Y
		end
		return 0
	elseif phase == "mount" then
		if self.ticks < self.y_hold then
			return Y
		end
		go(self, "idle")
		return 0
	end
	return 0
end

return speed_glitch
