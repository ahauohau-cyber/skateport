--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/joint_builder/arithmetic.rs (коммит 2e16697)
--
-- Original TU3 joint angular limits and shared constraint-frame arithmetic.

local rt = require("../../../rt")
local math_mod = require("../../math")
local constraint_frames = require("../constraint_frames")
local native_arithmetic = require("../native_arithmetic")
local rigid_body = require("../rigid_body")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

type Vector3 = vector
type Basis3 = math_mod.Basis3
type RetailQuaternion = rigid_body.RetailQuaternion

local arithmetic = {}

export type JointParameters = {
	linear_position_allowance: Vector3,
	linear_velocity_allowance: Vector3,
	twist_velocity_allowance: number,
	swing_velocity_allowance: number,
	swing_threshold: number,
	twist_threshold: number,
	swing_mode: number,
	twist_mode: number,
}

export type JointFrames = {
	orientation_a: RetailQuaternion,
	anchor_a: Vector3,
	orientation_b: RetailQuaternion,
	anchor_b: Vector3,
	linear_orientation_b: RetailQuaternion,
}

export type Rqd = { relative: RetailQuaternion, axes: { Vector3 } }

function arithmetic.vector_from_words(words: { number }, offset: number): Vector3
	return vector.create(from_bits(words[offset + 1]), from_bits(words[offset + 2]), from_bits(words[offset + 3]))
end
local vector_from_words = arithmetic.vector_from_words

function arithmetic.quaternion_from_words(words: { number }, offset: number): RetailQuaternion
	return {
		x = from_bits(words[offset + 1]),
		y = from_bits(words[offset + 2]),
		z = from_bits(words[offset + 3]),
		w = from_bits(words[offset + 4]),
	}
end
local quaternion_from_words = arithmetic.quaternion_from_words

function arithmetic.decode_parameters(raw: { words: { number } }): JointParameters
	local w = raw.words
	return {
		linear_position_allowance = vector_from_words(w, 0),
		linear_velocity_allowance = vector_from_words(w, 4),
		twist_velocity_allowance = from_bits(w[9]),
		swing_velocity_allowance = from_bits(w[10]),
		swing_threshold = from_bits(w[13]),
		twist_threshold = from_bits(w[14]),
		swing_mode = w[15],
		twist_mode = w[16],
	}
end

function arithmetic.decode_frames(raw: { words: { number } }): JointFrames
	local w = raw.words
	return {
		orientation_a = quaternion_from_words(w, 0),
		anchor_a = vector_from_words(w, 4),
		orientation_b = quaternion_from_words(w, 8),
		anchor_b = vector_from_words(w, 12),
		linear_orientation_b = quaternion_from_words(w, 16),
	}
end

function arithmetic.vector_to_array(value: Vector3): { number }
	return { value.x, value.y, value.z }
end
local vector_to_array = arithmetic.vector_to_array

function arithmetic.cross(left: Vector3, right: Vector3): Vector3
	return constraint_frames.cross(left, right)
end
local cross = arithmetic.cross

function arithmetic.dot3(left: Vector3, right: Vector3): number
	return native_arithmetic.dot3({ left.x, left.y, left.z, 0.0 }, { right.x, right.y, right.z, 0.0 })
end
local dot3 = arithmetic.dot3

function arithmetic.add(left: Vector3, right: Vector3): Vector3
	return vector.create(f32(left.x + right.x), f32(left.y + right.y), f32(left.z + right.z))
end

function arithmetic.sub(left: Vector3, right: Vector3): Vector3
	return vector.create(f32(left.x - right.x), f32(left.y - right.y), f32(left.z - right.z))
end

function arithmetic.scale(value: Vector3, scalar: number): Vector3
	return vector.create(f32(value.x * scalar), f32(value.y * scalar), f32(value.z * scalar))
end
local scale = arithmetic.scale

function arithmetic.vmx_min(left: number, right: number): number
	return native_arithmetic.vector_min(left, right)
end

function arithmetic.vmx_max(left: number, right: number): number
	return native_arithmetic.vector_max(left, right)
end

function arithmetic.basis_column(basis: Basis3, index: number): Vector3
	local c = basis.columns[index + 1]
	return vector.create(c[1], c[2], c[3])
end
local basis_column = arithmetic.basis_column

function arithmetic.basis_columns(basis: Basis3): { Vector3 }
	return { basis_column(basis, 0), basis_column(basis, 1), basis_column(basis, 2) }
end
local basis_columns = arithmetic.basis_columns

function arithmetic.basis_from_quaternion_retail(q: RetailQuaternion): Basis3
	return constraint_frames.basis(q)
end

function arithmetic.quaternion_multiply(a: RetailQuaternion, b: RetailQuaternion): RetailQuaternion
	return constraint_frames.compose(a, b)
end

function arithmetic.point_rate(linear: Vector3, angular: Vector3, arm: Vector3): Vector3
	return constraint_frames.point_rate(linear, angular, arm)
end

function arithmetic.project(v: Vector3, axes: { Vector3 }): { number }
	return { dot3(v, axes[1]), dot3(v, axes[2]), dot3(v, axes[3]) }
end

function arithmetic.multiply_basis(basis: Basis3, v: Vector3): Vector3
	return constraint_frames.transform_direction(basis, v)
end

-- ROBLOX: relative[row][column] в Rust -> r[row + 1][column + 1].
function arithmetic.relative_basis(a: Basis3, b: Basis3): { { number } }
	local out = {}
	for row = 0, 2 do
		out[row + 1] = {}
		for column = 0, 2 do
			out[row + 1][column + 1] = dot3(basis_column(a, row), basis_column(b, column))
		end
	end
	return out
end

function arithmetic.create_rqd(world_a: RetailQuaternion, world_b: RetailQuaternion): Rqd
	local rows = constraint_frames.quaternion_rows(world_a, world_b)
	return { relative = rows.relative, axes = rows.axes }
end

function arithmetic.scaled_projection_columns(axes: { Vector3 }, inverse_effective_mass: { number }): { { number } }
	local out = {}
	for component = 1, 3 do
		out[component] = {}
		for row = 1, 3 do
			out[component][row] = f32(vector_to_array(axes[row])[component] * inverse_effective_mass[row])
		end
	end
	return out
end

function arithmetic.packed_inertia_columns(packed: rigid_body.RetailPackedWorldInverseInertia, inverse_mass: number): { { number } }
	return {
		{ packed.full.x, packed.full.y, packed.full.z, inverse_mass },
		{ packed.full.y, packed.split.y, packed.split.z, inverse_mass },
		{ packed.full.z, packed.split.z, packed.split.x, inverse_mass },
	}
end

function arithmetic.zero_inertia(): rigid_body.RetailPackedWorldInverseInertia
	return { full = vector.create(0, 0, 0), split = vector.create(0, 0, 0) }
end

-- pub(super) fn angular_rows(parameters, basis_a, basis_b, relative, rqd) -> ([Vector3; 3], [f32; 3], [f32; 3])
function arithmetic.angular_rows(
	parameters: JointParameters,
	basis_a: Basis3,
	basis_b: Basis3,
	relative: { { number } },
	rqd: Rqd
): ({ Vector3 }, { number }, { number })
	-- ROBLOX: tu3 из родителя; подключение внутри функции разрывает цикл require.
	local tu3 = (require("../joint_builder") :: any).tu3
	local finite_infinity = tu3.FINITE_INFINITY
	-- Native defaults are all three frame-B axes, including skipped limits.
	local axes = basis_columns(basis_b)
	local low = { -finite_infinity, -finite_infinity, -finite_infinity }
	local high = { finite_infinity, finite_infinity, finite_infinity }

	local swing_mode = parameters.swing_mode
	if swing_mode == 0 then
		axes[2] = rqd.axes[2]
		axes[3] = rqd.axes[3]
		low[2] = f32(2.0 * rqd.relative.y)
		high[2] = low[2]
		low[3] = f32(2.0 * rqd.relative.z)
		high[3] = low[3]
	elseif swing_mode == 1 then
		-- 82AE4178..4188 skips the cone calculation when all splatted
		-- cosine lanes compare >= the original 0.99999 guard.
		if not (relative[1][1] >= tu3.NEAR_PARALLEL) then
			local first_a = basis_column(basis_a, 0)
			local first_b = basis_column(basis_b, 0)
			local perpendicular_z = relative[1][3]
			local perpendicular_y = relative[1][2]
			local squared = mul_add(perpendicular_y, perpendicular_y, f32(perpendicular_z * perpendicular_z))
			local root = f32(squared * constraint_frames.reciprocal_sqrt(squared))
			root = if squared == 0.0 then 0.0 else root
			local inverse_length = f32(constraint_frames.reciprocal(root) * 1.0)
			axes[2] = scale(cross(first_a, first_b), inverse_length)
			axes[3] = cross(axes[2], first_a)
			-- The bound is written even while inside the cone, allowing
			-- the predicted rate to reach the limit during this step.
			low[2] = f32(f32(parameters.swing_threshold - relative[1][1]) * inverse_length)
		end
	elseif swing_mode == 2 or swing_mode == 3 then
		axes[2] = basis_column(basis_b, 1)
		if parameters.twist_mode == 0 then
			axes[3] = rqd.axes[3]
			low[3] = f32(2.0 * rqd.relative.z)
			high[3] = low[3]
		else
			axes[3] = cross(basis_column(basis_a, 0), axes[2])
			low[3] = -relative[1][2]
			high[3] = low[3]
		end
		if swing_mode == 2 then
			local denominator = relative[1][3]
			-- 82AE42F4..4304: equality skips the reciprocal and retains
			-- both unbounded values. NaN is not equal to zero.
			if denominator ~= 0.0 then
				local correction =
					f32(constraint_frames.reciprocal(denominator) * f32(parameters.swing_threshold - relative[1][1]))
				if denominator < 0.0 then
					high[2] = correction
				else
					low[2] = correction
				end
			end
		end
	else
		axes[2] = basis_column(basis_b, 1)
		axes[3] = basis_column(basis_b, 2)
	end

	local twist_mode = parameters.twist_mode
	if twist_mode == 0 then
		axes[1] = rqd.axes[1]
		low[1] = f32(2.0 * rqd.relative.x)
		high[1] = low[1]
	elseif twist_mode == 1 then
		axes[1] = basis_column(basis_a, 0)
		-- Derived matrix-index form matching the emitted TU3 subtraction.
		local denominator = f32(relative[3][2] - relative[2][3])
		-- 82AE4434..4444 also retains the unbounded interval at zero.
		if denominator ~= 0.0 then
			local numerator = f32(
				f32(f32(1.0 + relative[1][1]) * parameters.twist_threshold) - f32(relative[2][2] + relative[3][3])
			)
			local correction = f32(constraint_frames.reciprocal(denominator) * numerator)
			if denominator < 0.0 then
				high[1] = correction
			else
				low[1] = correction
			end
		end
	else
		axes[1] = basis_column(basis_b, 0)
	end

	return axes, low, high
end

return arithmetic
