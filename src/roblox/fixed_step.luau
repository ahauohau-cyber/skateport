--!strict
-- ROBLOX: фиксированный шаг симуляции. В Rust это делает Bevy:
-- FixedUpdate + Time::<Fixed>::from_duration(clock.period()) и лимит кадра
-- 250 мс у Time<Virtual> (crates/skate-game/src/physics.rs, PhysicsPlugin).
-- Здесь — аккумулятор: кадр Roblox добавляет dt, симуляция снимает шаги
-- длиной period, пока хватает накопленного времени.
-- Модуль не трогает Roblox API: RunService подключает вызывающий скрипт.
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine

local fixed_step = {}

-- ROBLOX: Time<Virtual> в Bevy не даёт кадру быть длиннее 250 мс.
fixed_step.MAX_DELTA = 0.25

export type FixedStep = {
	accumulated: number, -- секунды, ещё не снятые симуляцией
}

function fixed_step.new(): FixedStep
	return { accumulated = 0 }
end

-- Добавить время кадра и выполнить столько тиков, сколько помещается.
-- period(): длина тика в секундах (берётся заново перед каждым тиком,
--           потому что SimulationClock может поменять её, например в слоу-мо).
-- tick():   один шаг симуляции.
-- Возвращает число выполненных тиков и долю следующего тика (для смешивания поз).
function fixed_step.advance(self: FixedStep, dt: number, period: () -> number, tick: () -> ()): (number, number)
	self.accumulated += math.min(dt, fixed_step.MAX_DELTA)
	local ticks = 0
	local step = period()
	while self.accumulated >= step do
		tick()
		self.accumulated -= step
		ticks += 1
		step = period()
	end
	return ticks, self.accumulated / step
end

return fixed_step
