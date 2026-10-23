--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/push_animation.rs (коммит 2e16697)
--
-- TU3 push animation calculations, upstream of the contact-driven push force.
-- `0x82BAD658` maps held time to strength; `0x82BACF50` updates the three
-- Andale parameters. These do not select an animation or synthesize root motion.

local rt = require("../../rt")
local point_graph = require("../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local PointGraph = point_graph.PointGraph

local push_animation = {}

export type PushAnimationCurves = {
	-- anim_motion/pushing, collection +640 (x +656, y +688).
	button_time_max: point_graph.PointGraph,
	-- Collection +560 (x +576, y +608).
	button_time_to_dv: point_graph.PointGraph,
	-- Collection +720 (x +736, y +768).
	blend_speed_over_frames: point_graph.PointGraph,
	-- Collection +800 (x +816, y +848).
	blend_acc_over_frames: point_graph.PointGraph,
}

export type PushBlendParameters = {
	hstr_vel_b: number,
	lstr_vel_b: number,
	-- A negative current value is the native uninitialized sentinel.
	vel_e: number,
}

local PushAnimationCurves = {}
push_animation.PushAnimationCurves = PushAnimationCurves

local function unit_interval(value: number): number
	-- Native fsel sequence also canonicalizes negative zero to positive zero.
	local lower = if -value >= 0.0 then 0.0 else value
	return if f32(1.0 - lower) >= 0.0 then lower else 1.0
end
push_animation.unit_interval = unit_interval

local function approach(current: number, target: number, rate: number, dt: number): number
	local difference = f32(target - current)
	local result
	if math.abs(difference) > f32(0.001) then
		if difference > 0.0 then
			local candidate = mul_add(dt, rate, current)
			result = if f32(candidate - target) >= 0.0 then target else candidate
		else
			-- Native fnmsubs, followed by fsel; preserve the fused operation.
			local candidate = -mul_add(dt, rate, -current)
			result = if f32(candidate - target) >= 0.0 then candidate else target
		end
	else
		result = target
	end
	return unit_interval(result)
end

function PushAnimationCurves.strength(self: PushAnimationCurves, held_seconds: number, speed: number): number
	local duration = PointGraph.evaluate(self.button_time_max, speed)
	return PointGraph.evaluate(self.button_time_to_dv, unit_interval(f32(held_seconds / duration)))
end

-- Returns the values written to shared properties +8/+12/+16 and then
-- published as HSTR_VEL_B, LSTR_VEL_B, VEL_E, in that order.
function PushAnimationCurves.update_blend(
	self: PushAnimationCurves,
	current: PushBlendParameters,
	target: PushBlendParameters,
	forward_speed: number,
	delta_seconds: number
): PushBlendParameters
	if current.vel_e < 0.0 then
		current = target
	end
	-- This factor is a native constant at 0x820849C8, not the graph dt.
	local frame_seconds = from_bits(0x3c88_8889)
	local velocity_rate = f32(1.0 / f32(PointGraph.evaluate(self.blend_speed_over_frames, current.vel_e) * frame_seconds))
	local speed = if forward_speed >= 0.0 then forward_speed else 0.0
	local strength_rate = f32(1.0 / f32(PointGraph.evaluate(self.blend_acc_over_frames, speed) * frame_seconds))
	return {
		hstr_vel_b = approach(current.hstr_vel_b, target.hstr_vel_b, velocity_rate, delta_seconds),
		lstr_vel_b = approach(current.lstr_vel_b, target.lstr_vel_b, velocity_rate, delta_seconds),
		vel_e = approach(current.vel_e, target.vel_e, strength_rate, delta_seconds),
	}
end

return push_animation
