--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/joint_builder.rs (коммит 2e16697)
--
-- Semantic port of TU3 `rw::physics::JointJacobian::Build`.
--
-- This module is intentionally separate from generic engine joints. It
-- accepts the exact 64-byte parameter and 80-byte frame records emitted by
-- `SkateboardBody::CreateJoints`, plus the rigid-body fields read by
-- `0x82AE3BC8`, and emits the 384-byte workspace consumed by the joint branch
-- of `0x82AE27D0`.

local rt = require("../../rt")
local math_mod = require("../math")
local constraint_frames = require("./constraint_frames")
local native_arithmetic = require("./native_arithmetic")
local rigid_body = require("./rigid_body")
local joint_records = require("./joint_records")
local a = require("@self/arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

type Vector3 = vector

local joint_builder = {}

joint_builder.tu3 = {
	JOINT_BATCH_BUILD = 0x82AE_39D0,
	JOINT_JACOBIAN_BUILD = 0x82AE_3BC8,
	JACOBIAN_RQD_CREATE = 0x82AE_0DB0,
	ITERATIVE_CONSTRAINT_SOLVER = 0x82AE_27D0,
	ACTIVE_BODY = 4,
	JACOBIAN_BYTES = 0x180,
	JACOBIAN_WORDS = 0x180 // 4,
	-- Observed TU3 vector constant used as the finite "unbounded" value.
	FINITE_INFINITY = from_bits(0x7F7F_FFFF),
	-- Observed singularity guard initialized at `0x830BDE50`.
	NEAR_PARALLEL = from_bits(0x3F7F_FF58),
}
local tu3 = joint_builder.tu3

-- Explicit body snapshot consumed by `JointJacobian::Build`. `basis` is kept
-- separate from `orientation` because TU3 reads both rather than rebuilding
-- one from the other. The reaction address is metadata copied into the raw
-- Jacobian; this port never dereferences it.
export type RetailJointBodyInput = {
	reaction_guest_address: number,
	state: number,
	orientation: rigid_body.RetailQuaternion,
	center_of_mass: Vector3,
	basis: math_mod.Basis3,
	linear_velocity: Vector3,
	angular_velocity: Vector3,
	force_acceleration: Vector3,
	torque_acceleration: Vector3,
	inverse_mass: number,
	world_inverse_inertia: rigid_body.RetailPackedWorldInverseInertia,
}

-- Complete explicit call state for TU3 `JointJacobian::Build`.
export type RetailJointBuildInput = {
	-- Observed 64-byte record at `Joint+4`.
	parameters: joint_records.RetailJointParametersRaw,
	-- Observed 80-byte record at `Joint+0`.
	frames: joint_records.RetailJointFramesRaw,
	-- Observed body at `Joint+0x10`.
	body_a: RetailJointBodyInput,
	-- Observed body at `Joint+0x14`.
	body_b: RetailJointBodyInput,
	-- Observed `Simulation+0xA0`.
	time_step: number,
	-- Observed source `Joint*`, retained in vector 12's fourth word.
	joint_guest_address: number,
}

-- ROBLOX: write_vector с четвёртым словом в виде битов. В Rust адрес проходит
-- через f32::from_bits/to_bits без изменений; в Luau сигнальный NaN исказился
-- бы при переводе в f64, поэтому слово пишется как есть.
local function write_vector(words: { number }, v: number, value: { number }, w_bits: number?)
	local start = v * 4
	words[start + 1] = to_bits(value[1])
	words[start + 2] = to_bits(value[2])
	words[start + 3] = to_bits(value[3])
	words[start + 4] = if w_bits ~= nil then w_bits else to_bits(value[4])
end

-- Builds TU3's fixed six-lane, 384-byte joint workspace.
-- The three linear and three angular accumulators begin at zero because the
-- retail builder clears all three 128-byte cache lines on every batch build.
-- pub fn build_retail_joint_jacobian(input: RetailJointBuildInput) -> RetailJointJacobian
function joint_builder.build_retail_joint_jacobian(input: RetailJointBuildInput): { words: { number } }
	local parameters = a.decode_parameters(input.parameters)
	local frames = a.decode_frames(input.frames)
	local active_a = bit32.band(input.body_a.state, tu3.ACTIVE_BODY) ~= 0
	local active_b = bit32.band(input.body_b.state, tu3.ACTIVE_BODY) ~= 0
	local time_step = input.time_step

	-- Observed composition order: body orientation followed by local frame.
	local world_orientation_a = a.quaternion_multiply(input.body_a.orientation, frames.orientation_a)
	local world_orientation_b = a.quaternion_multiply(input.body_b.orientation, frames.orientation_b)
	local world_linear_orientation = a.quaternion_multiply(input.body_b.orientation, frames.linear_orientation_b)
	local angular_basis_a = a.basis_from_quaternion_retail(world_orientation_a)
	local angular_basis_b = a.basis_from_quaternion_retail(world_orientation_b)
	local linear_basis = a.basis_from_quaternion_retail(world_linear_orientation)

	local arm_a = a.multiply_basis(input.body_a.basis, frames.anchor_a)
	local arm_b = a.multiply_basis(input.body_b.basis, frames.anchor_b)
	local linear_axes = a.basis_columns(linear_basis)
	-- Retained matrix product: the original gathers an RQD quaternion before
	-- constructing this matrix. The VA extension of 82AE3D98 (10242A35) is
	-- not independently decoded, so its rounding path remains unverified.
	local relative_matrix = a.relative_basis(angular_basis_a, angular_basis_b)
	local rqd = a.create_rqd(world_orientation_a, world_orientation_b)
	local angular_axes, angular_raw_low, angular_raw_high =
		a.angular_rows(parameters, angular_basis_a, angular_basis_b, relative_matrix, rqd)

	local inverse_mass_a = if active_a then input.body_a.inverse_mass else 0.0
	local inverse_mass_b = if active_b then input.body_b.inverse_mass else 0.0
	local inertia_a = if active_a then input.body_a.world_inverse_inertia else a.zero_inertia()
	local inertia_b = if active_b then input.body_b.world_inverse_inertia else a.zero_inertia()

	local linear_inverse_effective_mass = {}
	for index = 1, 3 do
		local ca = a.cross(arm_a, linear_axes[index])
		local cb = a.cross(arm_b, linear_axes[index])
		local ia = constraint_frames.multiply_inertia_from_zero(inertia_a, ca)
		local ib = constraint_frames.multiply_inertia_from_zero(inertia_b, cb)
		-- 82AE4814..4990 combines the two bodies component-wise, then uses
		-- (Z + Y) + (X + inverse_mass_A + inverse_mass_B), not two dot sums.
		local x = mul_add(cb.x, ib.x, mul_add(ca.x, ia.x, 0.0))
		local y = mul_add(cb.y, ib.y, mul_add(ca.y, ia.y, 0.0))
		local z = mul_add(cb.z, ib.z, mul_add(ca.z, ia.z, 0.0))
		local denominator = f32(f32(z + y) + f32(x + f32(inverse_mass_a + inverse_mass_b)))
		linear_inverse_effective_mass[index] = native_arithmetic.reciprocal_estimate(denominator)
	end
	local angular_inverse_effective_mass = {}
	for index = 1, 3 do
		local axis = angular_axes[index]
		local response = a.add(
			constraint_frames.multiply_inertia_from_zero(inertia_a, axis),
			constraint_frames.multiply_inertia_from_zero(inertia_b, axis)
		)
		local x = mul_add(axis.x, response.x, 0.0)
		local y = mul_add(axis.y, response.y, 0.0)
		local z = mul_add(axis.z, response.z, 0.0)
		-- 82AE496C..49A0: Z + (X + Y), one estimate, then the RQD factor 1/2.
		angular_inverse_effective_mass[index] = f32(0.5 * native_arithmetic.reciprocal_estimate(f32(z + f32(x + y))))
	end

	local point_velocity_a = a.point_rate(input.body_a.linear_velocity, input.body_a.angular_velocity, arm_a)
	local point_velocity_b = a.point_rate(input.body_b.linear_velocity, input.body_b.angular_velocity, arm_b)
	-- Native prediction is computed before the active-body inertia mask.
	-- An inactive body can still supply the source-owned kinematic rates.
	local point_acceleration_a = a.point_rate(input.body_a.force_acceleration, input.body_a.torque_acceleration, arm_a)
	local point_acceleration_b = a.point_rate(input.body_b.force_acceleration, input.body_b.torque_acceleration, arm_b)
	local displacement_a = a.scale(constraint_frames.multiply_add(point_acceleration_a, time_step, point_velocity_a), time_step)
	local displacement_b = a.scale(constraint_frames.multiply_add(point_acceleration_b, time_step, point_velocity_b), time_step)
	local relative_displacement = a.sub(displacement_b, displacement_a)
	local predicted_separation = a.sub(
		a.add(a.add(input.body_b.center_of_mass, arm_b), displacement_b),
		a.add(a.add(input.body_a.center_of_mass, arm_a), displacement_a)
	)
	local local_rate_displacement = a.project(relative_displacement, linear_axes)
	local local_separation = a.project(predicted_separation, linear_axes)

	local linear_low, linear_high = { 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0 }
	local position_allowance = a.vector_to_array(parameters.linear_position_allowance)
	local velocity_allowance = a.vector_to_array(parameters.linear_velocity_allowance)
	for lane = 1, 3 do
		local displacement_low = f32(local_separation[lane] - position_allowance[lane])
		local displacement_high = f32(local_separation[lane] + position_allowance[lane])
		local velocity_low = f32(local_rate_displacement[lane] - f32(velocity_allowance[lane] * time_step))
		local velocity_high = f32(local_rate_displacement[lane] + f32(velocity_allowance[lane] * time_step))
		local raw_low = a.vmx_max(displacement_low, a.vmx_min(velocity_low, displacement_high))
		local raw_high = a.vmx_min(displacement_high, a.vmx_max(velocity_high, displacement_low))
		linear_low[lane] = f32(raw_low * linear_inverse_effective_mass[lane])
		linear_high[lane] = f32(raw_high * linear_inverse_effective_mass[lane])
	end

	local relative_angular_rate = a.sub(
		constraint_frames.multiply_add(
			input.body_b.torque_acceleration,
			time_step,
			a.sub(input.body_b.angular_velocity, input.body_a.angular_velocity)
		),
		a.scale(input.body_a.torque_acceleration, time_step)
	)
	local local_angular_displacement = a.project(a.scale(relative_angular_rate, time_step), angular_axes)
	local angular_velocity_allowance = {
		parameters.twist_velocity_allowance,
		parameters.swing_velocity_allowance,
		parameters.swing_velocity_allowance,
	}
	local angular_low, angular_high = { 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0 }
	for lane = 1, 3 do
		local predicted_low = f32(angular_raw_low[lane] + local_angular_displacement[lane])
		local predicted_high = f32(angular_raw_high[lane] + local_angular_displacement[lane])
		local velocity_low = f32(local_angular_displacement[lane] - f32(angular_velocity_allowance[lane] * time_step))
		local velocity_high = mul_add(angular_velocity_allowance[lane], time_step, local_angular_displacement[lane])
		local raw_low = a.vmx_max(predicted_low, a.vmx_min(velocity_low, predicted_high))
		local raw_high = a.vmx_min(predicted_high, a.vmx_max(velocity_high, predicted_low))
		angular_low[lane] = f32(raw_low * angular_inverse_effective_mass[lane])
		angular_high[lane] = f32(raw_high * angular_inverse_effective_mass[lane])
	end

	local lp = a.scaled_projection_columns(linear_axes, linear_inverse_effective_mass)
	local ap = a.scaled_projection_columns(angular_axes, angular_inverse_effective_mass)
	local inertia_columns_a = a.packed_inertia_columns(inertia_a, inverse_mass_a)
	local inertia_columns_b = a.packed_inertia_columns(inertia_b, inverse_mass_b)

	local words = rt.zeros(tu3.JACOBIAN_WORDS)
	write_vector(words, 0, { arm_a.x, arm_a.y, arm_a.z }, input.body_a.reaction_guest_address)
	write_vector(words, 1, { arm_b.x, arm_b.y, arm_b.z }, input.body_b.reaction_guest_address)
	-- Vectors 2 and 3 are the cleared linear/angular accumulators.
	write_vector(words, 4, { lp[1][1], lp[1][2], lp[1][3], 0.0 })
	write_vector(words, 5, { ap[1][1], ap[1][2], ap[1][3], 0.0 })
	write_vector(words, 6, { lp[2][1], lp[2][2], lp[2][3], angular_low[1] })
	write_vector(words, 7, { ap[2][1], ap[2][2], ap[2][3], angular_low[2] })
	write_vector(words, 8, { lp[3][1], lp[3][2], lp[3][3], angular_high[1] })
	write_vector(words, 9, { ap[3][1], ap[3][2], ap[3][3], angular_high[2] })
	write_vector(words, 10, { linear_low[1], linear_low[2], linear_low[3], angular_low[3] })
	write_vector(words, 11, { linear_high[1], linear_high[2], linear_high[3], angular_high[3] })
	write_vector(words, 12, { linear_axes[1].x, linear_axes[1].y, linear_axes[1].z }, input.joint_guest_address)
	-- Packed carry lanes remain unverified pending direct TU3 instruction review.
	write_vector(words, 13, { linear_axes[2].x, linear_axes[2].y, linear_axes[2].z, linear_axes[2].x })
	write_vector(words, 14, { linear_axes[3].x, linear_axes[3].y, linear_axes[3].z, linear_axes[1].y })
	for lane = 1, 3 do
		local ax = angular_axes[lane]
		write_vector(words, 15 + lane - 1, { ax.x, ax.y, ax.z, ax.x })
	end
	for lane = 1, 3 do
		write_vector(words, 18 + lane - 1, inertia_columns_a[lane])
		write_vector(words, 21 + lane - 1, inertia_columns_b[lane])
	end
	return { words = words }
end

return joint_builder
