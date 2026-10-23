--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/profiles.rs (коммит 2e16697)
--
-- The five authored physics_wipeout_control profiles and original82D3C3F8.
-- ROBLOX: profiles: &[Profile; 5] -> profiles[selected + 1].

local rt = require("../../../rt")
local m = require("./math")
local data = require("./data")
local point_graph = require("../../point_graph")
local skeleton_body = require("../../physics/skeleton_body")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local SkeletonBody = skeleton_body.SkeletonBody

type V = m.V

local profiles = {}

export type Profile = {
	roll_axis: V, -- 0
	horizontal_axis: V, -- 16
	align_euler: V, -- 32
	spin_vs_time: point_graph.PointGraph, -- 48, source uses X64/Y96
	direction_follow: number, -- 128
	torque_velocity: number, -- 132
	torque_distance: number, -- 136
	spin_inertia: number, -- 140
	roll_on_ground: boolean, -- 144
	ground_roll_torque: number, -- 148
	sideways_spin: number, -- 152
	forward_spin: number, -- 156
	horizontal_directed: boolean, -- 160
	drift_maximum_speed: number, -- 164
	drift_forward: number, -- 168
	drift_sideways: number, -- 172
	align_with_velocity: boolean, -- 176
	align_ground_with_velocity: boolean, -- 177
	ground_align_torque: number, -- 180
	tilt_degrees: number, -- 184
	drift_drag: number, -- 188
}

function profiles.prepare(state: data.State, list: { Profile }, gesture: { number }, input: { number })
	local x, z = gesture[1], gesture[2]
	local selected
	if math.abs(x) < f32(0.2) and math.abs(z) < f32(0.2) then
		selected = 0
	elseif math.abs(x) <= math.abs(z) then
		selected = if z <= 0.0 then 3 else 1
	else
		selected = if x <= 0.0 then 4 else 2
	end
	state.control_time = f32(state.control_time + from_bits(0x3C88_8889))
	if selected ~= state.profile then
		state.control_time = 0.0
		state.profile = selected
		state.retained_sideways_input = 0.0
		state.retained_forward_input = 0.0
	end
	local flat_velocity = table.clone(state.velocity)
	flat_velocity[2] = 0.0
	local normalized = m.normalize_or(flat_velocity, { 0.0, 0.0, 0.0, 0.0 })
	if state.direction_initialized then
		local follow = list[selected + 1].direction_follow
		state.forward = m.normalize_or(m.madd(normalized, follow, m.scale(state.forward, f32(1.0 - follow))), { 0.0, 0.0, 0.0, 0.0 })
	else
		state.direction_initialized = true
		state.forward = normalized
	end
	state.right = m.cross({ 0.0, 1.0, 0.0, 0.0 }, state.forward)
	local v = { input[1], 0.0, input[2], 0.0 }
	state.forward_input = m.dot(v, state.forward)
	state.sideways_input = m.dot(v, state.right)
end

-- Original82D3C928, after air rotational control; preserves body velocity W.
function profiles.drift(state: data.State, body: any, p: Profile)
	if state.retained_velocity_active then
		return
	end
	local desired = m.madd(state.right, f32(p.drift_sideways * state.sideways_input), m.scale(state.forward, f32(p.drift_forward * state.forward_input)))
	local change = {}
	for i = 1, 4 do
		change[i] = f32(from_bits(bit32.bxor(to_bits(state.velocity[i]), 0x8000_0000)) * p.drift_drag)
	end
	change[1] = f32(change[1] * f32(0.02))
	change[3] = f32(change[3] * f32(0.02))
	if m.dot(state.velocity, m.normalize_or(desired, { 0.0, 0.0, 0.0, 0.0 })) < p.drift_maximum_speed then
		change = m.add(change, desired)
	end
	change = m.scale(change, from_bits(0x3C88_8889))
	local bodies = SkeletonBody.bodies_mut(body)
	for i = 2, 24 do
		local lv = bodies[i].rates.linear_velocity
		bodies[i].rates.linear_velocity = vector.create(f32(lv.x + change[1]), f32(lv.y + change[2]), f32(lv.z + change[3]))
	end
end

return profiles
