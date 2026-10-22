--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/joint_data.rs (коммит 2e16697)
--
-- Decoded joint/drive geometry and shared reaction application.
--
-- Record boundaries are four-float columns because native solver stores also
-- update their fourth lanes. Physical vectors/impulses have three components;
-- the fourth values are packed carry fields, not extra spatial dimensions.
-- ROBLOX: в Rust это подмодуль joint (`#[path]`), здесь — отдельный файл.
-- Смещения в байтах — как в Rust; слово с байта k лежит в [k / 4 + 1].

local rt = require("../../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

type Vector3 = vector
type Column = { number }

local joint_data = {}

function joint_data.read_column(words: { number }, byte_offset: number): Column
	local base = byte_offset // 4
	return { from_bits(words[base + 1]), from_bits(words[base + 2]), from_bits(words[base + 3]), from_bits(words[base + 4]) }
end
local read_column = joint_data.read_column

function joint_data.write_column(words: { number }, byte_offset: number, values: Column)
	local base = byte_offset // 4
	for i = 1, 4 do
		words[base + i] = to_bits(values[i])
	end
end
local write_column = joint_data.write_column

function joint_data.xyz(values: Column): Vector3
	return vector.create(values[1], values[2], values[3])
end
local xyz = joint_data.xyz

-- Matrix projection with the native X, Y, Z fused accumulation order. The
-- incoming accumulated impulse is the initial value for candidate projection.
function joint_data.project_correction(columns: { Column }, correction: Vector3, initial: Column): Column
	local out = {}
	for component = 1, 4 do
		local after_x = mul_add(columns[1][component], correction.x, initial[component])
		local after_y = mul_add(columns[2][component], correction.y, after_x)
		out[component] = mul_add(columns[3][component], correction.z, after_y)
	end
	return out
end
local project_correction = joint_data.project_correction

-- Velocity-producing displacement corrections at reaction offsets 0/32.
-- Contact-only pose corrections at 16/48 are neither read nor overwritten.
export type ReactionState = { linear: Column, angular: Column }

local ReactionState = {}
joint_data.ReactionState = ReactionState

function ReactionState.decode(words: { number }): ReactionState
	assert(#words == 16)
	return { linear = read_column(words, 0), angular = read_column(words, 32) }
end

function joint_data.publish_reactions(a: ReactionState, b: ReactionState, words_a: { number }, words_b: { number })
	write_column(words_a, 0, a.linear)
	write_column(words_b, 0, b.linear)
	write_column(words_a, 32, a.angular)
	write_column(words_b, 32, b.angular)
end

local function point_correction(reaction: ReactionState, arm: Vector3): Vector3
	local x, y, z = reaction.angular[1], reaction.angular[2], reaction.angular[3]
	return vector.create(
		mul_add(-z, arm.y, mul_add(y, arm.z, reaction.linear[1])),
		mul_add(-x, arm.z, mul_add(z, arm.x, reaction.linear[2])),
		mul_add(-y, arm.x, mul_add(x, arm.y, reaction.linear[3]))
	)
end

local function torque_at_offset(arm: Vector3, impulse: Vector3, angular_impulse: Vector3): Vector3
	return vector.create(
		mul_add(-arm.z, impulse.y, mul_add(arm.y, impulse.z, angular_impulse.x)),
		mul_add(-arm.x, impulse.z, mul_add(arm.z, impulse.x, angular_impulse.y)),
		mul_add(-arm.y, impulse.x, mul_add(arm.x, impulse.y, angular_impulse.z))
	)
end

-- `82AE1AE8` and `82AE3BC8` write these same response fields. Columns at
-- 64/96/128 and 80/112/144 project relative corrections into constraint axes;
-- 192..224 and 240..272 convert impulse changes back into world space.
export type ConstraintGeometry = {
	arm_a: Vector3,
	arm_b: Vector3,
	linear_projection: { Column },
	angular_projection: { Column },
	linear_axes: { Column },
	angular_axes: { Column },
	inverse_inertia_a: { Column },
	inverse_inertia_b: { Column },
}

local ConstraintGeometry = {}
joint_data.ConstraintGeometry = ConstraintGeometry

function ConstraintGeometry.decode(words: { number }): ConstraintGeometry
	assert(#words == 96)
	local function cols(base: number, stride: number): { Column }
		return { read_column(words, base), read_column(words, base + stride), read_column(words, base + 2 * stride) }
	end
	return {
		arm_a = xyz(read_column(words, 0)),
		arm_b = xyz(read_column(words, 16)),
		linear_projection = cols(64, 32),
		angular_projection = cols(80, 32),
		linear_axes = cols(192, 16),
		angular_axes = cols(240, 16),
		inverse_inertia_a = cols(288, 16),
		inverse_inertia_b = cols(336, 16),
	}
end

-- Both candidates must read this incoming snapshot before either impulse
-- is applied: 82AE2C00..2CC4 (joint), 82AE2E90..2F80 (drive).
function ConstraintGeometry.relative_corrections(self: ConstraintGeometry, a: ReactionState, b: ReactionState): (Vector3, Vector3)
	local point_a = point_correction(a, self.arm_a)
	local point_b = point_correction(b, self.arm_b)
	return vector.create(f32(point_b.x - point_a.x), f32(point_b.y - point_a.y), f32(point_b.z - point_a.z)),
		vector.create(
			f32(b.angular[1] - a.angular[1]),
			f32(b.angular[2] - a.angular[2]),
			f32(b.angular[3] - a.angular[3])
		)
end

-- 82AE2D24..2E40 / 82AE2FE0..30D4. One linear and one angular impulse
-- change affect both bodies through their own arm and inverse inertia.
function ConstraintGeometry.apply_impulse_changes(
	self: ConstraintGeometry,
	a: ReactionState,
	b: ReactionState,
	linear_change: Vector3,
	angular_change: Vector3
)
	local zero = { 0.0, 0.0, 0.0, 0.0 }
	local linear_impulse = project_correction(self.linear_axes, linear_change, zero)
	local angular_impulse = xyz(project_correction(self.angular_axes, angular_change, zero))
	local torque_a = torque_at_offset(self.arm_a, xyz(linear_impulse), angular_impulse)
	local torque_b = torque_at_offset(self.arm_b, xyz(linear_impulse), angular_impulse)
	local inverse_mass_a = self.inverse_inertia_a[1][4]
	local inverse_mass_b = self.inverse_inertia_b[1][4]
	-- Native publication order: linear A, linear B, angular A, angular B.
	for component = 1, 4 do
		local impulse = linear_impulse[component]
		a.linear[component] = mul_add(impulse, inverse_mass_a, a.linear[component])
		b.linear[component] = mul_add(-impulse, inverse_mass_b, b.linear[component])
	end
	a.angular = project_correction(self.inverse_inertia_a, torque_a, a.angular)
	for component = 1, 4 do
		local after_x = mul_add(-self.inverse_inertia_b[1][component], torque_b.x, b.angular[component])
		local after_y = mul_add(-self.inverse_inertia_b[2][component], torque_b.y, after_x)
		b.angular[component] = mul_add(-self.inverse_inertia_b[3][component], torque_b.z, after_y)
	end
end

return joint_data
