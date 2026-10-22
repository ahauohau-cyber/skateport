--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/drive_solver/builder.rs (коммит 2e16697)
--
-- TU3 drive Jacobian construction, separate from iterative solving.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local constraint_frames = require("../constraint_frames")
local drive_parameters = require("../drive_parameters")
local drive_frames = require("../drive_frames")

local f32 = rt.f32
local mul_add = rt.mul_add
local RetailDriveType = drive_parameters.RetailDriveType

type Vector3 = vector

local builder = {}

-- ROBLOX: `use super::*` — помощники drive_solver. Родитель подключает этот файл
-- лениво, поэтому здесь его можно подключить сразу.
local parent = require("../drive_solver") :: any
local basis_columns, project, point_rate = parent.basis_columns, parent.project, parent.point_rate
local add, sub, scale, dot, cross = parent.add, parent.sub, parent.scale, parent.dot, parent.cross
local is_active = parent.is_active

type WorldFrame = { orientation: any, arm: Vector3, position: Vector3 }

local function world_frame(body: any, frame: drive_frames.RetailDriveFrame): WorldFrame
	local arm = constraint_frames.transform_direction(body.basis, frame.translation)
	return {
		orientation = constraint_frames.compose(body.orientation, frame.orientation),
		arm = arm,
		position = add(body.center_of_mass, arm),
	}
end

type DriveCoefficients = { softness: number, target_displacement: { number }, maximum_strength: number }

local function components_of(v: Vector3): { number }
	return { v.x, v.y, v.z }
end

-- 82AE1E68..20B8 and the matching angular block219C..237C.
-- Inputs are already scaled in their source order; the hard cap affects only
-- position error, before the rate and acceleration displacements are added.
local function build_coefficients(
	params: drive_parameters.RetailDriveParams,
	position_error_in: { number },
	velocity_displacement: { number },
	acceleration_displacement: { number },
	time_step: number
): DriveCoefficients
	local position_error = table.clone(position_error_in)
	local damping = f32(time_step * params.damping)
	local position_weight, velocity_weight, acceleration_weight
	if params.drive_type == RetailDriveType.SoftDrive then
		local spring = f32(f32(time_step * params.spring_or_max_velocity) * time_step)
		local inverse = constraint_frames.reciprocal(f32(f32(1.0 + spring) + damping))
		position_weight = f32(inverse * spring)
		velocity_weight = f32(inverse * damping)
		acceleration_weight = f32(inverse * f32(spring + damping))
	else
		position_weight = f32(constraint_frames.reciprocal(f32(1.0 + damping)) * 1.0)
		velocity_weight = 1.0
		acceleration_weight = 1.0
	end
	if params.drive_type == RetailDriveType.HardDrive then
		local p = position_error
		local squared = native_arithmetic.dot3({ p[1], p[2], p[3], 0.0 }, { p[1], p[2], p[3], 0.0 })
		local maximum = f32(time_step * params.spring_or_max_velocity)
		if squared > f32(maximum * maximum) then
			local factor = f32(maximum * constraint_frames.reciprocal_sqrt(squared))
			for i = 1, 3 do
				position_error[i] = f32(position_error[i] * factor)
			end
		end
	end
	local target = {}
	for i = 1, 3 do
		local rate = f32(velocity_displacement[i] * velocity_weight)
		local position_and_rate = mul_add(position_error[i], position_weight, rate)
		target[i] = mul_add(acceleration_displacement[i], acceleration_weight, position_and_rate)
	end
	return {
		softness = acceleration_weight,
		target_displacement = target,
		-- Type zero follows the same native strength load; its authored params
		-- normally provide zero strength rather than the builder inventing it.
		maximum_strength = f32(f32(time_step * params.max_strength) * time_step),
	}
end

local function linear_effective_mass(frame_a: any, frame_b: any, arm_a: Vector3, arm_b: Vector3, axis: Vector3): number
	local denominator = 0.0
	if is_active(frame_a) then
		local angular = cross(arm_a, axis)
		denominator = f32(
			denominator
				+ f32(frame_a.inverse_mass + dot(angular, constraint_frames.multiply_inertia(frame_a.world_inverse_inertia, angular)))
		)
	end
	if is_active(frame_b) then
		local angular = cross(arm_b, axis)
		denominator = f32(
			denominator
				+ f32(frame_b.inverse_mass + dot(angular, constraint_frames.multiply_inertia(frame_b.world_inverse_inertia, angular)))
		)
	end
	return denominator
end

local function angular_effective_mass(frame_a: any, frame_b: any, axis: Vector3): number
	local denominator = 0.0
	if is_active(frame_a) then
		denominator = f32(denominator + dot(axis, constraint_frames.multiply_inertia(frame_a.world_inverse_inertia, axis)))
	end
	if is_active(frame_b) then
		denominator = f32(denominator + dot(axis, constraint_frames.multiply_inertia(frame_b.world_inverse_inertia, axis)))
	end
	return denominator
end

-- Scalar translation of TU3 `DriveJacobian::Build`.
-- RenderWare pairs frame A with internal `Drive::m_bodyA` at `Drive+0x10`
-- and frame B with `Drive::m_bodyB` at `Drive+0x14`. `Simulation::AddDrive`
-- stores its second body argument as internal A and its first as internal B.
-- The linear error is frame-B minus frame-A; the solver therefore applies
-- positive impulse to frame A and negative impulse to frame B.
-- pub fn build_drive_rows(frame_a_body, frame_b_body, frames, dynamics, time_step) -> RetailDriveRows
function builder.build_drive_rows(
	frame_a_body: any,
	frame_b_body: any,
	frames: drive_frames.RetailDriveFrames,
	dynamics: drive_parameters.RetailDriveDynamics,
	time_step: number
): any
	local frame_a_world = world_frame(frame_a_body, frames.body_a)
	local frame_b_world = world_frame(frame_b_body, frames.body_b)
	local arm_a = frame_a_world.arm
	local arm_b = frame_b_world.arm
	local linear_axes = basis_columns(constraint_frames.basis(frame_b_world.orientation))

	local raw_angular = constraint_frames.quaternion_rows(frame_a_world.orientation, frame_b_world.orientation)
	local components = { raw_angular.relative.x, raw_angular.relative.y, raw_angular.relative.z }
	local squared = {}
	for i = 1, 3 do
		local c = components[i]
		squared[i] = native_arithmetic.vector_min(native_arithmetic.vector_max(f32(c * c), 0.0), 1.0)
	end
	-- 830BDB40 selects bytes [0,4,8,8] in every word: any saturated
	-- quaternion component replaces ALL three axes with frame B's basis.
	local singular = squared[1] == 1.0 or squared[2] == 1.0 or squared[3] == 1.0
	local inverse_lengths = {}
	for i = 1, 3 do
		inverse_lengths[i] = if singular then 1.0 else constraint_frames.reciprocal_sqrt(f32(1.0 - squared[i]))
	end
	local angular_axes, angular_position_error = {}, {}
	for i = 1, 3 do
		angular_axes[i] = scale(if singular then linear_axes[i] else raw_angular.axes[i], inverse_lengths[i])
		angular_position_error[i] = f32(f32(components[i] * inverse_lengths[i]) * 2.0)
	end

	local linear_position_error = sub(frame_b_world.position, frame_a_world.position)
	local linear_velocity_displacement = sub(
		scale(point_rate(frame_b_body.linear_velocity, frame_b_body.angular_velocity, arm_b), time_step),
		scale(point_rate(frame_a_body.linear_velocity, frame_a_body.angular_velocity, arm_a), time_step)
	)
	local linear_acceleration_displacement = sub(
		scale(scale(point_rate(frame_b_body.force_acceleration, frame_b_body.torque_acceleration, arm_b), time_step), time_step),
		scale(scale(point_rate(frame_a_body.force_acceleration, frame_a_body.torque_acceleration, arm_a), time_step), time_step)
	)
	local angular_velocity_displacement = scale(sub(frame_b_body.angular_velocity, frame_a_body.angular_velocity), time_step)
	local angular_acceleration_displacement =
		scale(scale(sub(frame_b_body.torque_acceleration, frame_a_body.torque_acceleration), time_step), time_step)
	local linear_inverse_effective_mass, angular_inverse_effective_mass = {}, {}
	for index = 1, 3 do
		linear_inverse_effective_mass[index] =
			constraint_frames.reciprocal(linear_effective_mass(frame_a_body, frame_b_body, arm_a, arm_b, linear_axes[index]))
	end
	for index = 1, 3 do
		angular_inverse_effective_mass[index] =
			constraint_frames.reciprocal(angular_effective_mass(frame_a_body, frame_b_body, angular_axes[index]))
	end

	local linear_coefficients = build_coefficients(
		dynamics.linear,
		components_of(linear_position_error),
		components_of(linear_velocity_displacement),
		components_of(linear_acceleration_displacement),
		time_step
	)
	-- Linear weights combine in world space before the projection (20A8..20D0).
	local displacement = linear_coefficients.target_displacement
	local linear_target = project(vector.create(displacement[1], displacement[2], displacement[3]), linear_axes)
	local angular_coefficients = build_coefficients(
		dynamics.angular,
		angular_position_error,
		project(angular_velocity_displacement, angular_axes),
		project(angular_acceleration_displacement, angular_axes),
		time_step
	)
	local linear_target_impulse, angular_target_impulse, linear_maximum_impulse, angular_maximum_impulse = {}, {}, {}, {}
	for i = 1, 3 do
		linear_target_impulse[i] = f32(linear_target[i] * linear_inverse_effective_mass[i])
		angular_target_impulse[i] = f32(angular_coefficients.target_displacement[i] * angular_inverse_effective_mass[i])
		linear_maximum_impulse[i] = f32(linear_inverse_effective_mass[i] * linear_coefficients.maximum_strength)
		angular_maximum_impulse[i] = f32(angular_inverse_effective_mass[i] * angular_coefficients.maximum_strength)
	end
	return {
		frame_a_body = frame_a_body,
		frame_b_body = frame_b_body,
		arm_a = arm_a,
		arm_b = arm_b,
		linear_axes = linear_axes,
		angular_axes = angular_axes,
		linear_inverse_effective_mass = linear_inverse_effective_mass,
		angular_inverse_effective_mass = angular_inverse_effective_mass,
		linear_softness = linear_coefficients.softness,
		angular_softness = angular_coefficients.softness,
		linear_target_impulse = linear_target_impulse,
		angular_target_impulse = angular_target_impulse,
		linear_maximum_impulse = linear_maximum_impulse,
		angular_maximum_impulse = angular_maximum_impulse,
		accumulated_linear_impulse = { 0.0, 0.0, 0.0 },
		accumulated_angular_impulse = { 0.0, 0.0, 0.0 },
	}
end

return builder
