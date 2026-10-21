--!strict
-- Проверка аккумулятора фиксированного шага.

local harness = require("../harness")
local fixed_step = require("../../src/roblox/fixed_step")
local clock_mod = require("../../src/skate_game/physics/clock")

local SimulationClock = clock_mod.SimulationClock

return function(report: harness.Report)
	harness.test(report, "fixed_step: 60 frames of 1/60 s give 60 ticks of the clock period", function()
		local clock = SimulationClock.default()
		local function period(): number
			return SimulationClock.period(clock) * 1e-9
		end
		local stepper = fixed_step.new()
		local ticks = 0
		for _ = 1, 600 do
			fixed_step.advance(stepper, 1 / 60, period, function()
				ticks += 1
			end)
		end
		-- 10 с по 0.0166666 с на тик = 600.0024 тика: целых тиков 600.
		harness.eq(ticks, 600, "ticks in 10 s")
	end)

	harness.test(report, "fixed_step: a long frame is capped at 0.25 s", function()
		local stepper = fixed_step.new()
		local ticks = fixed_step.advance(stepper, 5.0, function()
			return 0.0166666
		end, function() end)
		harness.eq(ticks, 15, "0.25 s / 0.0166666 s")
	end)
end
