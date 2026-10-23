--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_forces/reckoning.rs (коммит 2e16697)
--
-- UpdateGrindStates82D8E3E0, compared with S2 named82DDD2A8.
-- Maintains CURRENT's shared filters/frames and BodySpin history; no second
-- reckoning owner and no ground/air-state substitute.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local board_motion_output = require("../board_motion_output")
local body_spin = require("../../air/body_spin")
local ground_normal = require("../../air/ground_normal")
local reckoning_frames = require("../../riding/reckoning_frames")
local point_graph = require("../../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3
local GroundNormalFilter = ground_normal.GroundNormalFilter
local ReckoningFrames = reckoning_frames.ReckoningFrames

type V = { number }

local reckoning = {}

export type Settings = {
	ground_normal_smoothing: V,
	-- Stock schema: layout800 TiltVsRotGround,672 TiltVsSlopeGround.
	tilt_vs_rotation: point_graph.PointGraph,
	tilt_vs_slope: point_graph.PointGraph,
}

local function xyz(v: V): vector
	return vector.create(v[1], v[2], v[3])
end
local function lanes(v: vector): V
	return { v.x, v.y, v.z, 0.0 }
end
-- fn length из grind_forces.rs (super::length).
local function length(v: V): number
	local square = dot3(v, v)
	if square == 0.0 then
		return 0.0
	end
	return f32(square * board_motion_output.inverse_length_squared(square, 2))
end

-- ROBLOX: air: &mut AirState — используется только поле secondary_lean_angle.
function reckoning.update(
	orientation: any,
	frames: any,
	spin: body_spin.BodySpinState,
	air: any,
	settings: Settings,
	normal: V,
	heading: V,
	smoothing: number,
	reverse_stance: boolean,
	physical_body_spin: number
)
	local old_up = lanes(orientation.up)
	orientation.dynamic_up = orientation.up
	orientation.up_velocity = vector.zero
	frames.target_lean_angle = 0.0
	air.secondary_lean_angle = 0.0
	orientation.ground_blend = 0.0
	local ground = GroundNormalFilter.update(orientation.ground_filter, settings.ground_normal_smoothing, normal)
	orientation.ground_normal = xyz(ground)
	frames.heading = heading
	local candidate = {}
	for i = 1, 4 do
		candidate[i] = mul_add(old_up[i], smoothing, f32(normal[i] * f32(1.0 - smoothing)))
	end
	-- Native NormalizeSafe threshold is the original830BD350 splat1e-6;
	-- zero/short candidates retain the preceding up, not world-up.
	local up
	if length(candidate) > from_bits(0x3586_37bd) then
		local inverse = board_motion_output.inverse_length_squared(dot3(candidate, candidate), 2)
		up = { f32(candidate[1] * inverse), f32(candidate[2] * inverse), f32(candidate[3] * inverse), f32(candidate[4] * inverse) }
	else
		up = old_up
	end
	orientation.up = xyz(up)
	orientation.target = orientation.up
	GroundNormalFilter.filter(orientation.slow_filter, up)
	GroundNormalFilter.filter(orientation.fast_filter, up)
	GroundNormalFilter.publish_current(orientation.slow_filter, up)
	GroundNormalFilter.publish_current(orientation.fast_filter, up)
	ReckoningFrames.calculate_transform(frames, up, ground)
	ReckoningFrames.calculate_tilt(frames, reverse_stance, settings.tilt_vs_rotation, settings.tilt_vs_slope)
	-- Caller82D3F4E8 passes updateBodySpin=false, hence0. Other native callers
	-- may supply their actual PhysBodySpin; this is still the ground branch.
	body_spin.update_ground(spin, physical_body_spin)
	-- No ResetSpin: Air's spin_angle/spin_speed survive this function.
end

return reckoning
