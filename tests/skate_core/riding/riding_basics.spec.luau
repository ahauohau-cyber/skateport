--!strict
-- Сверка air/body_spin, air/ground_normal, riding/speed_and_slope с настоящим
-- skate-core (golden/src/riding.rs) и перенос Rust-тестов speed_and_slope.

local harness = require("../../harness")
local u = require("../../util")
local body_spin = require("../../../src/skate_core/air/body_spin")
local ground_normal = require("../../../src/skate_core/air/ground_normal")
local speed_and_slope = require("../../../src/skate_core/riding/speed_and_slope")
local golden = require("../../golden/riding") :: any

local fb = u.fb
local BodySpinState = body_spin.BodySpinState
local GroundNormalFilter = ground_normal.GroundNormalFilter
local SpeedAndSlopeSettings = speed_and_slope.SpeedAndSlopeSettings

local function G(t: any): any
	local x, y = {}, {}
	for i = 1, 8 do
		x[i] = fb(t[1][i])
		y[i] = fb(t[2][i])
	end
	return { x = x, y = y }
end
local function F4(t: { number }): { number }
	return { fb(t[1]), fb(t[2]), fb(t[3]), fb(t[4]) }
end

return function(report: harness.Report)
	harness.test(report, "body_spin: 60 × 80 шагов update/update_ground vs Rust", function()
		for ci, case in golden.body_spin do
			local st = case.settings
			local curves = {}
			for i, c in st[3] do
				curves[i] = G(c)
			end
			local settings = { derivative_floor = fb(st[1]), acceleration_limit = fb(st[2]), curves = curves, input_fade_threshold = F4(st[4]) }
			local state = BodySpinState.new()
			for si, step in case.steps do
				if step[5] then
					body_spin.update_ground(state, fb(step[1]))
				else
					body_spin.update(state, settings, fb(step[1]), fb(step[2]), step[3], step[4])
				end
				assert(u.same_words(state.words, step[6]), string.format("случай %d шаг %d: слова разошлись", ci, si))
			end
		end
	end)

	harness.test(report, "ground_normal: 80 × 40 шагов фильтра vs Rust", function()
		for ci, case in golden.ground_normal do
			local f = GroundNormalFilter.initialized(F4(case.control), F4(case.init))
			for si, step in case.steps do
				local op, c, i = step[1], F4(step[2]), F4(step[3])
				local out
				if op == 0 then
					out = GroundNormalFilter.update(f, c, i)
				elseif op == 1 then
					out = GroundNormalFilter.filter_raw(f, c, i)
				else
					GroundNormalFilter.publish_current(f, i)
					out = { 0.0, 0.0, 0.0, 0.0 }
				end
				for lane = 1, 4 do
					assert(u.same(out[lane], step[4][lane]), string.format("случай %d шаг %d: выход", ci, si))
				end
				assert(u.same_words(f.words, step[5]), string.format("случай %d шаг %d: слова", ci, si))
			end
		end
	end)

	harness.test(report, "speed_and_slope: 3000 вызовов calculate vs Rust", function()
		for ci, case in golden.speed_and_slope do
			local st = { turn_torque_vs_speed = G(case[1]), turn_torque_vs_slope = G(case[2]), heading_adjust_max_speed = fb(case[3]) }
			for k, call in case[4] do
				assert(u.same(SpeedAndSlopeSettings.calculate(st, fb(call[1]), fb(call[2])), call[3]), string.format("случай %d вызов %d", ci, k))
			end
		end
	end)

	local function linear_settings(): any
		local keys = { 0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 1.0 }
		return {
			turn_torque_vs_speed = { x = table.clone(keys), y = table.clone(keys) },
			turn_torque_vs_slope = { x = table.clone(keys), y = table.clone(keys) },
			heading_adjust_max_speed = 8.0,
		}
	end

	harness.test(report, "speed_and_slope: coefficient_uses_absolute_forward_speed_and_saturates_its_fraction", function()
		local settings = linear_settings()
		local half_speed = SpeedAndSlopeSettings.calculate(settings, 0.0, 4.0)
		assert(math.abs(half_speed - 0.5) < 0.00001)
		assert(SpeedAndSlopeSettings.calculate(settings, 0.0, -4.0) == half_speed)
		assert(math.abs(SpeedAndSlopeSettings.calculate(settings, 0.0, 80.0) - 1.0) < 0.00001)
		assert(SpeedAndSlopeSettings.calculate(settings, 0.0, 0.0) == 0.0)
	end)

	harness.test(report, "speed_and_slope: over_vertical_slope_returns_to_the_first_curve_key", function()
		local settings = linear_settings()
		settings.turn_torque_vs_slope.y[1] = 0.375
		assert(SpeedAndSlopeSettings.calculate(settings, -1.0, 8.0) == 0.375)
		assert(SpeedAndSlopeSettings.calculate(settings, -2.0, 8.0) == 0.375)
		assert(math.abs(SpeedAndSlopeSettings.calculate(settings, 0.0, 8.0) - 1.0) < 0.00001)
	end)
end
