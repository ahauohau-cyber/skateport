--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/grind/admission.rs (коммит 2e16697)
--
-- Original S3 82D6A840 admission and82D6AF58 landing publication.
-- ROBLOX: &mut Prediction -> таблица меняется на месте;
-- effective_lock_distance: &mut Option<f32> -> ячейка { value = число или nil }.

local rt = require("../../../../rt")
local m = require("../math")
local launch = require("../launch")
local prediction_mod = require("../prediction")
local trigonometry = require("../../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local fmax = rt.fmax
local dot, sub, scale, cross, madd = m.dot, m.sub, m.scale, m.cross, m.madd
local length, normalize, reciprocal, angle_between = m.length, m.normalize, m.reciprocal, m.angle_between
local STEP = m.STEP
local Trajectory = prediction_mod.Trajectory

type Vector = m.Vector
type Prediction = prediction_mod.Prediction

local admission = {}

-- 82BD3E78, shared with the offboard surface-frame port.
local function clamp_angle(target: Vector, reference: Vector, limit: number): Vector
	local a = normalize(target)
	local b = normalize(reference)
	local axis = cross(a, b)
	local angle = trigonometry.acos(rt.fclamp(dot(a, b), -1.0, 1.0))
	local turns = math.floor(mul_add(angle, from_bits(0x3e22_f983), 0.5))
	local wrapped = mul_add(-turns, from_bits(0x40c9_0fdb), angle)
	if math.abs(wrapped) < limit or from_bits(0x3780_0000) > dot(axis, axis) then
		return target
	end
	local unit = normalize(axis)
	local sin, cos = trigonometry.sin_cos(f32(-limit * 0.5))
	local q = scale(unit, sin)
	return scale(madd(cross(q, madd(reference, cos, cross(q, reference))), 2.0, reference), length(target))
end

-- 82D6AF58: bias by cross-rail velocity, bound against the investigated
-- support normal, reject the rail axis, then normalize.
function admission.landing_normal(
	direction: Vector,
	velocity: Vector,
	support: Vector,
	velocity_scalar: number,
	maximum_angle_degrees: number
): Vector
	local across = sub(velocity, scale(direction, dot(direction, velocity)))
	local target = madd(across, -velocity_scalar, m.up())
	local limited = clamp_angle(target, support, f32(maximum_angle_degrees * from_bits(0x3c8e_fa35)))
	-- 82C1E170 removes only the positive normalized-direction component,
	-- multiplying by the ORIGINAL supplied direction.
	local component = dot(limited, normalize(direction))
	return normalize(if component > 0.0 then sub(limited, scale(direction, component)) else limited)
end

-- position/material stay intact; time, frame, trajectory and normal change.
function admission.apply_admitted_target(
	prediction: Prediction,
	candidate: any,
	correction: Vector,
	support_normal: Vector,
	reference_velocity: Vector,
	maximum_adjust: number,
	landing_velocity_scalar: number,
	landing_max_angle: number
)
	launch.adjust_trajectory(prediction.request.trajectory, candidate.frame, correction, maximum_adjust)
	prediction.result.contact_frame = candidate.frame
	prediction.result.contact_time = f32(f32(candidate.frame) * STEP)
	prediction.result.contact_normal = admission.landing_normal(
		candidate.direction,
		reference_velocity,
		support_normal,
		landing_velocity_scalar,
		landing_max_angle
	)
end

-- Admission and displacement portion82D6A840. The caller retries the next
-- ranked candidate on None, then applies82D609E0 and82D6AF58 on success.
-- This deliberately requires native surface evidence before any correction.
function admission.admitted_displacement(
	prediction: Prediction,
	candidate: any,
	edge: any,
	reference_velocity: Vector,
	processed_592: Vector,
	surface: any,
	limits: any,
	effective_lock_distance: { value: number? }
): Vector?
	local natural_landing = Trajectory.position_at(prediction.request.trajectory, prediction.result.contact_time)
	if f32(candidate.point[2] - natural_landing[2]) < from_bits(0xbecc_cccd) or candidate.direction[2] > f32(0.9) then
		return nil
	end
	local direction = normalize(sub(edge["end"], edge.start))
	local perpendicular = sub(reference_velocity, scale(direction, dot(direction, reference_velocity)))
	if math.abs(f32(perpendicular[2] * f32(1.0 - math.abs(direction[2])))) > limits.max_downward_speed then
		return nil
	end
	if surface.kind == 3 then
		return nil
	end
	local horizontal = m.copy(perpendicular)
	horizontal[2] = 0.0
	local max_speed = if surface.kind == 2 then limits.max_speed_squared_ledge else limits.max_speed_squared_rail
	if dot(horizontal, horizontal) > max_speed then
		return nil
	end
	local delta = sub(candidate.trajectory_point, candidate.point)
	local lock_distance
	if surface.kind == 2 then
		local incoming = dot(delta, surface.side) > 0.0
		local body = dot(sub(processed_592, edge.start), surface.side) > 0.0
		-- ROBLOX: ledge_scalars[i] (с нуля) -> [i + 1].
		local index = (if incoming then 0 else 2) + (if body then 0 else 1)
		lock_distance = f32(limits.lock_distance * limits.ledge_scalars[index + 1])
	else
		lock_distance = limits.lock_distance
	end
	lock_distance = fmax(lock_distance, f32(0.1))
	effective_lock_distance.value = lock_distance
	if candidate.distance >= lock_distance then
		return nil
	end
	local miss = sub(candidate.trajectory_point, edge.start)
	local correction = scale(sub(miss, scale(candidate.direction, dot(candidate.direction, miss))), -1.0)
	local distance = length(correction)
	if distance >= limits.lock_distance then
		local half_dimension = mul_add(limits.deck_dimensions[2], 0.5, f32(limits.deck_dimensions[1] * 0.5))
		correction = scale(correction, f32(mul_add(-limits.tip_scalar, half_dimension, distance) / distance))
	end
	local original = prediction.request.trajectory.velocity
	local adjusted = madd(correction, reciprocal(candidate.time), original)
	local angle = if f32(dot(original, original) * dot(adjusted, adjusted)) > from_bits(0x38d1_b717)
		then angle_between(original, adjusted)
		else 0.0
	if angle > f32(limits.maximum_adjust_angle * from_bits(0x3c8e_fa35)) then
		return nil
	end
	return correction
end

return admission
