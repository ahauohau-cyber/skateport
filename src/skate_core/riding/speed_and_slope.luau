--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/speed_and_slope.rs (коммит 2e16697)
--
-- Speed/slope coefficient published to the stock ActionGraph.
--
-- TU3 PhysicalPlayerHiLOD::CalculateHeadingAdjustFactor82DB5E10 is called
-- during PostInput82DB56C0. ProcessOutput82DB7580 publishes its result to
-- SkateboardMotion+192. The source uses the *turn torque* curves, despite
-- the function name; the nearby HeadingAdjustVsSpeed/Slope curves differ.

local rt = require("../../rt")
local native_arithmetic = require("../physics/native_arithmetic")
local point_graph = require("../point_graph")
local trigonometry = require("../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local PointGraph = point_graph.PointGraph

local speed_and_slope = {}

export type SpeedAndSlopeSettings = {
	-- physics_heading layout336/368.
	turn_torque_vs_speed: point_graph.PointGraph,
	-- physics_heading layout400/432.
	turn_torque_vs_slope: point_graph.PointGraph,
	-- physics_heading layout600.
	heading_adjust_max_speed: number,
}

local SpeedAndSlopeSettings = {}
speed_and_slope.SpeedAndSlopeSettings = SpeedAndSlopeSettings

-- Complete82DB5E10, including the slope cutoff and speed saturation.
--
-- `ground_normal_y` is ground output+96.Y, copied to ProcessedPhysIn+464;
-- `forward_speed` is skateboard output+168, copied to ProcessedPhysIn+2612.
-- The reciprocal/acos primitives retain their documented numerical
-- approximation boundary until independent hardware validation.
function SpeedAndSlopeSettings.calculate(self: SpeedAndSlopeSettings, ground_normal_y: number, forward_speed: number): number
	local normal_y = native_arithmetic.vector_min(1.0, native_arithmetic.vector_max(-1.0, ground_normal_y))
	local half_pi = from_bits(0x3FC9_0FDB)
	local inverse_half_pi = native_arithmetic.reciprocal_estimate(half_pi)
	for _ = 1, 2 do
		local error = mul_add(-inverse_half_pi, half_pi, 1.0)
		inverse_half_pi = mul_add(inverse_half_pi, error, inverse_half_pi)
	end
	local slope = f32(inverse_half_pi * trigonometry.acos(normal_y))
	if slope > from_bits(0x3F99_999A) then
		slope = 0.0
	end

	local absolute_speed = math.abs(forward_speed)
	local nonnegative_speed = if -absolute_speed >= -0.0 then 0.0 else absolute_speed
	local bounded_speed = if f32(self.heading_adjust_max_speed - nonnegative_speed) >= -0.0
		then nonnegative_speed
		else self.heading_adjust_max_speed
	local speed_fraction = f32(bounded_speed / self.heading_adjust_max_speed)
	local speed_factor = PointGraph.evaluate(self.turn_torque_vs_speed, speed_fraction)
	local slope_factor = PointGraph.evaluate(self.turn_torque_vs_slope, slope)
	return f32(speed_factor * slope_factor)
end

return speed_and_slope
