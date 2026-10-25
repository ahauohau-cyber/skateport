--!strict
-- ROBLOX: фиксированный шаг симуляции. В Rust это делает Bevy:
-- FixedUpdate + Time::<Fixed>::from_duration(clock.period()) и лимит кадра
-- 250 мс у Time<Virtual> (crates/skate-game/src/physics.rs, PhysicsPlugin).
-- Здесь — аккумулятор: кадр Roblox добавляет dt, симуляция снимает шаги
-- длиной period, пока хватает накопленного времени.
-- Модуль не трогает Roblox API: RunService подключает вызывающий скрипт.
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
--
-- ROBLOX: две защиты от лагов (идея из host/Loop примерочного плейса):
--   * «прилипание»: кадр, близкий к длине тика (±10 %), засчитывается ровно
--     как один тик. Иначе дрожание dt даёт 0, 2, 0, 2 тика за кадр — рывки и
--     двойные по цене кадры. Расхождение копится и понемногу возвращается.
--   * бюджет: за кадр не больше max_ticks тиков и не дольше budget секунд;
--     долг больше debt_max тиков сбрасывается (игра чуть замедляется вместо
--     «спирали смерти», когда каждый следующий кадр всё длиннее).

local fixed_step = {}

-- ROBLOX: Time<Virtual> в Bevy не даёт кадру быть длиннее 250 мс.
fixed_step.MAX_DELTA = 0.25

fixed_step.POLICY = {
	snap_tolerance = 0.1, -- доля тика: кадр в пределах — ровно один тик
	snap_limit = 0.5, -- доля тика: больше копить расхождение нельзя
	snap_bleed = 0.01, -- доля тика за кадр: возврат накопленного расхождения
	max_ticks = 3, -- тиков за кадр максимум
	budget = 1 / 45, -- секунд на тики за кадр (после первого тика)
	debt_max = 2, -- тиков долга можно перенести на следующие кадры
}

export type FixedStep = {
	accumulated: number, -- секунды, ещё не снятые симуляцией
	snap_error: number, -- секунды: сколько «прилипание» уже округлило
	dropped: number, -- тиков выброшено (для отладки)
}

function fixed_step.new(): FixedStep
	return { accumulated = 0, snap_error = 0, dropped = 0 }
end

-- Добавить время кадра и выполнить столько тиков, сколько помещается.
-- period(): длина тика в секундах (берётся заново перед каждым тиком,
--           потому что SimulationClock может поменять её, например в слоу-мо).
-- tick():   один шаг симуляции.
-- Возвращает число выполненных тиков и долю следующего тика (для смешивания поз).
function fixed_step.advance(self: FixedStep, dt: number, period: () -> number, tick: () -> ()): (number, number)
	local policy = fixed_step.POLICY
	local step = period()
	dt = math.min(dt, fixed_step.MAX_DELTA)

	-- Прилипание к одному тику.
	local diff = dt - step
	if math.abs(diff) <= policy.snap_tolerance * step and math.abs(self.snap_error + diff) <= policy.snap_limit * step then
		self.snap_error += diff
		dt = step
	end
	-- Понемногу возвращаем накопленное расхождение.
	if self.snap_error ~= 0 then
		local bleed = math.clamp(self.snap_error, -policy.snap_bleed * step, policy.snap_bleed * step)
		dt += bleed
		self.snap_error -= bleed
	end
	self.accumulated += math.max(dt, 0)

	local ticks = 0
	local started = os.clock()
	while self.accumulated >= step do
		if ticks >= policy.max_ticks or (ticks >= 1 and os.clock() - started > policy.budget) then
			-- Не успеваем: переносим немного долга, остальное выбрасываем.
			local keep = step * policy.debt_max
			if self.accumulated > keep then
				self.dropped += math.floor((self.accumulated - keep) / step)
				self.accumulated = keep
			end
			break
		end
		tick()
		self.accumulated -= step
		ticks += 1
		step = period()
	end
	return ticks, math.clamp(self.accumulated / step, 0, 1)
end

return fixed_step
