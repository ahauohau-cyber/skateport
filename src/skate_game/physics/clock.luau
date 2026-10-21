--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/physics/clock.rs (коммит 2e16697)
--
-- Offline tick cadence. Original TU3 Simulation::OnRequestSetSimRate82857EC8
-- sets a wall-clock timer; it does not change the physical integration step.

local rt = require("../../rt")
local slow_motion = require("../../skate_core/camera/slow_motion")

local f32 = rt.f32
local from_bits = rt.from_bits

local clock = {}

local NORMAL_STEP = from_bits(0x3c888889)
local I32_MAX = 2147483647

-- ROBLOX: Duration -> целое число наносекунд (u64 помещается в number до 2^53).
export type SimulationClock = {
	ticks_until_reset: number, -- u32
	timer_period: number, -- Duration в наносекундах
}

local SimulationClock = {}
clock.SimulationClock = SimulationClock

-- Original timer setter82966910..2C: integer division in100ns units.
-- fn timer_period(frequency: i32) -> Duration
local function timer_period(frequency: number): number
	-- ROBLOX: целочисленное деление Rust (оба числа положительные) -> //.
	return (10_000_000 // frequency) * 100
end
clock.timer_period = timer_period

-- impl Default for SimulationClock
function SimulationClock.default(): SimulationClock
	return {
		ticks_until_reset = 0,
		timer_period = timer_period(60),
	}
end

-- pub fn apply(&mut self, request: SimulationRateRequest) -> Result<(), String>
-- ROBLOX: Result -> (true) или (nil, текст ошибки).
function SimulationClock.apply(self: SimulationClock, request: slow_motion.SimulationRateRequest): (boolean?, string?)
	-- 82857F44..7C rounds the reciprocal to an integer timer frequency.
	-- ROBLOX: (x).trunc() -> к нулю; x здесь положительный или NaN/inf.
	local reciprocal = f32(f32(1.0 / request.timestep) + 0.5)
	local frequency = if reciprocal >= 0 then math.floor(reciprocal) else math.ceil(reciprocal)
	if not rt.is_finite(frequency) or frequency < 1.0 or frequency > f32(I32_MAX) then
		return nil, string.format("Invalid simulation-rate request: %s", tostring(request.timestep))
	end
	-- ROBLOX: frequency as i32 — значение уже целое и в пределах i32.
	frequency = math.min(frequency, I32_MAX)
	if 10_000_000 // frequency == 0 then
		return nil, "Simulation-rate request has a zero timer period"
	end
	self.timer_period = timer_period(frequency)
	if request.timestep == NORMAL_STEP then
		self.ticks_until_reset = 0
	elseif rt.to_i32(request.ticks) > 0 then
		self.ticks_until_reset = rt.wrapping_add_u32(request.ticks, 1)
	else
		-- TU3 hardcodes180 at82857F34; S2 used a debug setting here.
		self.ticks_until_reset = 180
	end
	return true, nil
end

-- pub fn finish_tick(&mut self)
function SimulationClock.finish_tick(self: SimulationClock)
	-- SimUpdate2 8285A694..A6C8 runs after the camera publication. Pending
	-- camera messages are dispatched at the start of the following tick.
	self.ticks_until_reset = rt.wrapping_sub_u32(self.ticks_until_reset, 1)
	if self.ticks_until_reset == 0 then
		self.timer_period = timer_period(60)
	end
end

-- pub fn period(&self) -> Duration
-- ROBLOX: наносекунды. В секунды: period * 1e-9.
function SimulationClock.period(self: SimulationClock): number
	return self.timer_period
end

return clock
