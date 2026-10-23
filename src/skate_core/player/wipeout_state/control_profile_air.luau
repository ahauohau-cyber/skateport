--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/control_profile_air.rs (коммит 2e16697)
--
-- Original profile-driven Wipeout air rotation82D3CB50.

local rt = require("../../../rt")
local m = require("./math")
local data = require("./data")
local orientation = require("./orientation")
local torque = require("./torque")
local sar = require("../../physics/skeleton_animation_record")
local point_graph = require("../../point_graph")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local sin_cos = trigonometry.sin_cos

type V = m.V

local control_profile_air = {}

local UP = { 0.0, 1.0, 0.0, 0.0 }
local ZERO = { 0.0, 0.0, 0.0, 0.0 }

local function transform(frame: sar.AnimationPartTransform, v: V): V
	return m.madd(frame[3], v[3], m.madd(frame[2], v[2], m.scale(frame[1], v[1])))
end

local function retain_input(input: number, previous: number, inertia: number): number
	if math.abs(input) >= math.abs(previous) then
		return input
	end
	return f32(f32(f32(1.0 - inertia) * input) + f32(previous * inertia))
end

local function horizontal_alignment(profile: any, effective: sar.AnimationPartTransform, direction: V, tilt: V): V
	local loc = m.normalize_or(profile.horizontal_axis, { 1.0, 0.0, 0.0, 0.0 })
	local world = transform(effective, loc)
	local target = orientation.rotate(tilt, m.normalize_or(m.cross(direction, UP), ZERO))
	if not profile.horizontal_directed then
		target = m.scale(target, if m.dot(world, target) > 0.0 then 1.0 else -1.0)
	end
	-- 82D3D4F0 uses the normalized authored axis here, before world composition;
	-- the angle query itself receives world/target. Preserve that distinction.
	local axis = m.normalize_or(m.cross(loc, target), ZERO)
	if not (m.dot(axis, axis) > f32(0.9)) then
		return ZERO
	end
	local angle = m.wrap_angle(orientation.projected_angle(world, target, axis))
	local limit = from_bits(0x3F49_0FDB)
	return m.scale(axis, f32(m.clamp(angle, -limit, limit) * f32(0.8)))
end

function control_profile_air.update(state: data.State, body: any, physical_com: V, effective: sar.AnimationPartTransform, input: { number }, profile: any)
	state.angular_velocity = torque.angular_velocity(body.record, body.definition.animation_masses.fractional)
	local radians = from_bits(0x3C8E_FA35)
	local tilt_input = {
		f32(f32(input[2] * profile.tilt_degrees) * radians),
		0.0,
		f32(f32(input[1] * profile.tilt_degrees) * -radians),
		0.0,
	}
	state.retained_tilt = m.madd(tilt_input, f32(0.05), m.scale(state.retained_tilt, f32(0.95)))
	local tilt_length = m.length(state.retained_tilt)
	local tilt_rotation = { 0.0, 0.0, 0.0, 1.0 }
	if tilt_length > f32(0.01) then
		local sin, cos = sin_cos(f32(tilt_length * 0.5))
		tilt_rotation = m.scale(m.scale(state.retained_tilt, m.reciprocal(tilt_length)), sin)
		tilt_rotation[4] = cos
	end
	local desired = transform(effective, orientation.alignment_up(profile.align_euler[1], profile.align_euler[2]))
	local side = m.normalize_or(state.right, ZERO)
	local projected_velocity = m.sub(state.velocity, m.scale(side, m.dot(state.velocity, side)))
	local direction
	if m.dot(state.forward, projected_velocity) <= 0.0 then
		direction = m.normalize(m.add(desired, { 0.0, -100.0, 0.0, 0.0 }))
	else
		direction = m.normalize_or(projected_velocity, desired)
	end
	local tilted_direction = orientation.rotate(tilt_rotation, direction)
	local axis = m.normalize_or(m.cross(tilted_direction, desired), desired)
	local angle = m.wrap_angle(orientation.signed_angle(tilted_direction, desired, axis))
	local distance_torque = if profile.align_with_velocity then m.scale(m.scale(axis, angle), profile.torque_distance) else ZERO

	local input_side_axis = orientation.rotate(tilt_rotation, desired)
	local input_forward_axis = orientation.rotate(tilt_rotation, m.normalize_or(m.cross(direction, UP), ZERO))
	state.retained_sideways_input = retain_input(state.sideways_input, state.retained_sideways_input, profile.spin_inertia)
	state.retained_forward_input = retain_input(state.forward_input, state.retained_forward_input, profile.spin_inertia)
	local side_spin = f32(profile.sideways_spin * state.retained_sideways_input)
	local forward_spin = f32(profile.forward_spin * state.retained_forward_input)
	local spin = m.madd(input_forward_axis, forward_spin, m.madd(input_side_axis, side_spin, ZERO))
	if m.dot(spin, state.angular_velocity) <= 0.0 then
		state.control_time = 0.0
	end
	spin = m.scale(spin, point_graph.PointGraph.evaluate(profile.spin_vs_time, state.control_time))
	local horizontal = if math.abs(side_spin) <= f32(0.1) then horizontal_alignment(profile, effective, direction, tilt_rotation) else ZERO
	local control = m.add(m.madd(m.sub(spin, state.angular_velocity), profile.torque_velocity, distance_torque), horizontal)
	torque.apply(body, physical_com, control)
end

local _ = mul_add
return control_profile_air
