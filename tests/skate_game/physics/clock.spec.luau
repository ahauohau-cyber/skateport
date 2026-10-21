--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/physics/tests/clock.rs (коммит 2e16697)

local harness = require("../../harness")
local rt = require("../../../src/rt")
local clock_mod = require("../../../src/skate_game/physics/clock")
local slow_motion = require("../../../src/skate_core/camera/slow_motion")
local point_graph = require("../../../src/skate_core/point_graph")

local f32 = rt.f32
local SimulationClock = clock_mod.SimulationClock
local SlowMotionController = slow_motion.SlowMotionController
local PointGraph = point_graph.PointGraph

return function(report: harness.Report)
	harness.test(report, "clock: camera_rate_requests_expire_and_preserve_message_order", function()
		local clock = SimulationClock.default()
		local normal = SimulationClock.period(clock)
		local slow = { timestep = f32(1.0 / f32(35.4)), ticks = 1 }
		assert(SimulationClock.apply(clock, slow))
		SimulationClock.finish_tick(clock)
		-- Duration::from_nanos(28_571_400)
		harness.eq(SimulationClock.period(clock), 28_571_400, "slow period")
		SimulationClock.finish_tick(clock)
		harness.eq(SimulationClock.period(clock), normal, "back to normal")

		-- An End followed by a new Begin must retain the new request.
		assert(SimulationClock.apply(clock, SlowMotionController.end_()))
		assert(SimulationClock.apply(clock, slow))
		SimulationClock.finish_tick(clock)
		harness.check(SimulationClock.period(clock) ~= normal, "new request kept")
		assert(SimulationClock.apply(clock, SlowMotionController.end_()))
		SimulationClock.finish_tick(clock)
		harness.eq(SimulationClock.period(clock), normal, "end restores")

		-- SimulationRateRequest { ticks: 0, ..slow }
		assert(SimulationClock.apply(clock, { timestep = slow.timestep, ticks = 0 }))
		for _ = 1, 179 do
			SimulationClock.finish_tick(clock)
		end
		harness.check(SimulationClock.period(clock) ~= normal, "180-tick default still active")
		SimulationClock.finish_tick(clock)
		harness.eq(SimulationClock.period(clock), normal, "expired after 180")
	end)

	harness.test(report, "clock: camera_slow_motion_waits_for_a_positive_air_prediction", function()
		-- std::array::from_fn(|i| i as f32 / 15.0) для 16 точек
		local x, y = {}, {}
		for i = 0, 15 do
			x[i + 1] = f32(i / 15.0)
			y[i + 1] = f32(i / 15.0)
		end
		local settings = {
			timescale = PointGraph.new(x, y),
			fps_at_scale_one = 35.0,
		}
		local controller = SlowMotionController.begin(settings)
		local waiting = SlowMotionController.update(controller, f32(0.1), 0 / 0, settings)
		harness.check(math.abs(waiting.timestep - 1.0 / 57.5) < 1e-6, "waiting timestep")
		local predicted = SlowMotionController.update(controller, f32(0.1), 1.0, settings)
		local expected = 1.0 / (60.0 - 25.0 * (0.2 / 1.1))
		harness.check(math.abs(predicted.timestep - expected) < 1e-6, "predicted timestep")
	end)

	harness.test(report, "clock: default period is 16_666_600 ns (60 Hz in 100 ns units)", function()
		harness.eq(SimulationClock.period(SimulationClock.default()), 16_666_600)
	end)
end
