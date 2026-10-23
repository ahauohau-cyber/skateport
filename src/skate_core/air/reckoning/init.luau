--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/reckoning/mod.rs (коммит 2e16697)
--
-- Complete original TU3 Reckoning::UpdateAirStates82D8DBD8.
-- Shared Ground filters, frame owners and BodySpin history persist across states.
-- ROBLOX: &mut структуры -> таблицы, меняются на месте; Vector3 -> vector.

local rt = require("../../rt")
local body_flip = require("./body_flip")
local body_spin = require("./body_spin")
local ground_normal = require("./ground_normal")
local reckoning_frames = require("../riding/reckoning_frames")
local point_graph = require("../point_graph")
local data = require("@self/data")
local m = require("@self/math")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local GroundNormalFilter = ground_normal.GroundNormalFilter
local ReckoningFrames = reckoning_frames.ReckoningFrames
local BodySpinState = body_spin.BodySpinState
local evaluate = point_graph.PointGraph.evaluate
local angle, length, limit_angle, normalize, normalize_safe, rotate_heading, wrap =
	m.angle, m.length, m.limit_angle, m.normalize, m.normalize_safe, m.rotate_heading, m.wrap

type V = { number }

local reckoning = {}
reckoning.data = data
reckoning.math = m -- ROBLOX: приватный модуль, открыт для сверки.
reckoning.AirState = data.AirState
export type AirState = data.AirState
export type Input = data.Input
export type Settings = data.Settings
reckoning.clamp_vector_within_max_angle = m.limit_angle

local function lanes(v: vector): V
	return { v.x, v.y, v.z, 0.0 }
end
local function to_vector(v: V): vector
	return vector.create(v[1], v[2], v[3])
end

function reckoning.update(orientation: any, frames: any, spin: any, state: AirState, settings: Settings, input: Input)
	local old_up = lanes(orientation.up)
	orientation.dynamic_up = orientation.up
	frames.target_lean_angle = 0.0
	state.secondary_lean_angle = 0.0
	local ground = GroundNormalFilter.update(orientation.ground_filter, settings.ground_normal_smoothing, input.landing_normal)
	orientation.ground_normal = to_vector(ground)

	if input.additive_spin then
		state.spin_speed = f32(input.grind_adjusted_body_spin + input.target_spin)
	elseif input.direct_spin then
		state.spin_speed = input.target_spin
	else
		body_spin.update(spin, settings.body_spin, input.physical_body_spin, input.target_spin, true, if input.easy_body_spins then 1 else 0)
		state.spin_speed = BodySpinState.speed(spin)
	end
	state.spin_angle = mul_add(state.spin_speed, from_bits(0x3c88_8889), state.spin_angle)
	if state.flip_active then
		-- A short call-boundary view, not a second retained owner of matrix1008.
		local flip: body_flip.BodyFlipState = {
			angle = state.flip_angle,
			speed = state.flip_speed,
			requested_speed = state.flip_requested_speed,
			spin_transform = state.spin_transform,
			combined_transform = frames.body_flip,
		}
		body_flip.update(flip, settings.body_flip, {
			requested_speed = input.flip_request,
			spin_angle = state.spin_angle,
			normal = old_up,
			flip_axis = state.flip_axis,
			timestep = input.timestep,
			perfect_body_flips = input.perfect_body_flips,
		})
		state.flip_angle = flip.angle
		state.flip_speed = flip.speed
		state.flip_requested_speed = flip.requested_speed
		state.spin_transform = flip.spin_transform
		frames.body_flip = flip.combined_transform
	end

	local wrapped = wrap(angle(old_up, ground))
	local maximum = f32(wrapped * input.normal_blend)
	local target
	if math.abs(wrapped) >= from_bits(0x40c8_f61e) then
		target = if math.abs(old_up[2]) < from_bits(0x3f7d_70a4) then { 0.0, 1.0, 0.0, 0.0 } else { 1.0, 0.0, 0.0, 0.0 }
	else
		target = ground
	end
	local candidate = normalize(limit_angle(target, old_up, maximum))
	local max_delta = evaluate(settings.max_up_angle_delta, length(input.com_to_deck))
	local selected = if math.abs(wrap(angle(candidate, old_up))) > max_delta then limit_angle(candidate, old_up, max_delta) else candidate
	local up = normalize_safe(selected, old_up)
	orientation.up_velocity = vector.create(f32(up[1] - old_up[1]), f32(up[2] - old_up[2]), f32(up[3] - old_up[3]))
	orientation.up = to_vector(up)
	orientation.target = orientation.up

	if not state.flip_active then
		frames.heading = rotate_heading(frames.heading, up, f32(input.timestep * state.spin_speed))
	end
	-- 82D8C868 advances histories using retained control words, then publishes
	-- the chosen up into each current-position slot; no filter reinitialization.
	GroundNormalFilter.filter(orientation.slow_filter, up)
	GroundNormalFilter.filter(orientation.fast_filter, up)
	GroundNormalFilter.publish_current(orientation.slow_filter, up)
	GroundNormalFilter.publish_current(orientation.fast_filter, up)
	ReckoningFrames.calculate_transform(frames, up, ground)
	ReckoningFrames.calculate_tilt(frames, input.reverse_stance, settings.tilt_vs_rotation, settings.tilt_vs_slope)
end

-- Handplant Reckoning82D8E1C0. Uses the ordinary persistent normal filters.
function reckoning.update_plant(orientation: any, frames: any, spin: any, state: AirState, settings: Settings, up_in: V, heading: V, reverse: boolean)
	frames.heading = heading
	body_spin.update(spin, settings.body_spin, 0.0, 0.0, true, 0)
	local previous = lanes(orientation.up)
	orientation.dynamic_up = orientation.up
	frames.target_lean_angle = 0.0
	state.secondary_lean_angle = 0.0
	local normal = normalize(GroundNormalFilter.update(orientation.ground_filter, settings.ground_normal_smoothing, up_in))
	orientation.ground_normal = to_vector(normal)
	local up = normalize_safe(limit_angle(normal, previous, 1.0), previous)
	orientation.up_velocity = vector.create(f32(up[1] - previous[1]), f32(up[2] - previous[2]), f32(up[3] - previous[3]))
	orientation.up = to_vector(up)
	orientation.target = orientation.up
	GroundNormalFilter.filter(orientation.slow_filter, up)
	GroundNormalFilter.filter(orientation.fast_filter, up)
	GroundNormalFilter.publish_current(orientation.slow_filter, up)
	GroundNormalFilter.publish_current(orientation.fast_filter, up)
	ReckoningFrames.calculate_transform(frames, up, normal)
	ReckoningFrames.calculate_tilt(frames, reverse, settings.tilt_vs_rotation, settings.tilt_vs_slope)
end

return reckoning
