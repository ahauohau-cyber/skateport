--!strict
--!native
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


-- ROBLOX: варианты над записью, уже переведённой в числа (r[k + 1] =
-- f32::from_bits(words[k])); реакции — 16 чисел. Без временных таблиц:
-- результаты пишутся в переданные буферы. Порядок операций тот же.

-- project_correction над столбцами r со смещений c0/c1/c2 (в словах).
function joint_data.project_f(
	r: { number },
	c0: number,
	c1: number,
	c2: number,
	x: number,
	y: number,
	z: number,
	initial: { number },
	io: number,
	out: { number },
	oo: number
)
	for component = 1, 4 do
		local after_x = mul_add(r[c0 + component], x, initial[io + component])
		local after_y = mul_add(r[c1 + component], y, after_x)
		out[oo + component] = mul_add(r[c2 + component], z, after_y)
	end
end
local project_f = joint_data.project_f

-- relative_corrections: (точка B − точка A, угловая B − угловая A), по 3 числа.
function joint_data.relative_corrections_f(r: { number }, a: { number }, b: { number }): (number, number, number, number, number, number)
	local ax, ay, az = a[9], a[10], a[11]
	local bx, by, bz = b[9], b[10], b[11]
	local aarm_x, aarm_y, aarm_z = r[1], r[2], r[3]
	local barm_x, barm_y, barm_z = r[5], r[6], r[7]
	local pax = mul_add(-az, aarm_y, mul_add(ay, aarm_z, a[1]))
	local pay = mul_add(-ax, aarm_z, mul_add(az, aarm_x, a[2]))
	local paz = mul_add(-ay, aarm_x, mul_add(ax, aarm_y, a[3]))
	local pbx = mul_add(-bz, barm_y, mul_add(by, barm_z, b[1]))
	local pby = mul_add(-bx, barm_z, mul_add(bz, barm_x, b[2]))
	local pbz = mul_add(-by, barm_x, mul_add(bx, barm_y, b[3]))
	return f32(pbx - pax), f32(pby - pay), f32(pbz - paz), f32(bx - ax), f32(by - ay), f32(bz - az)
end

local ZERO4 = { 0.0, 0.0, 0.0, 0.0 }
local LI = table.create(4, 0)
local AI = table.create(4, 0)

-- apply_impulse_changes: реакции a и b меняются на месте.
function joint_data.apply_impulse_changes_f(
	r: { number },
	a: { number },
	b: { number },
	lx: number,
	ly: number,
	lz: number,
	gx: number,
	gy: number,
	gz: number
)
	-- linear_axes: слова 48/52/56, angular_axes: 60/64/68
	project_f(r, 48, 52, 56, lx, ly, lz, ZERO4, 0, LI, 0)
	project_f(r, 60, 64, 68, gx, gy, gz, ZERO4, 0, AI, 0)
	local ix, iy, iz = LI[1], LI[2], LI[3]
	local aix, aiy, aiz = AI[1], AI[2], AI[3]
	local arm_ax, arm_ay, arm_az = r[1], r[2], r[3]
	local arm_bx, arm_by, arm_bz = r[5], r[6], r[7]
	local tax = mul_add(-arm_az, iy, mul_add(arm_ay, iz, aix))
	local tay = mul_add(-arm_ax, iz, mul_add(arm_az, ix, aiy))
	local taz = mul_add(-arm_ay, ix, mul_add(arm_ax, iy, aiz))
	local tbx = mul_add(-arm_bz, iy, mul_add(arm_by, iz, aix))
	local tby = mul_add(-arm_bx, iz, mul_add(arm_bz, ix, aiy))
	local tbz = mul_add(-arm_by, ix, mul_add(arm_bx, iy, aiz))
	-- inverse_inertia_a: слова 72/76/80, inverse_inertia_b: 84/88/92
	local inverse_mass_a = r[76]
	local inverse_mass_b = r[88]
	-- Native publication order: linear A, linear B, angular A, angular B.
	for component = 1, 4 do
		local impulse = LI[component]
		a[component] = mul_add(impulse, inverse_mass_a, a[component])
		b[component] = mul_add(-impulse, inverse_mass_b, b[component])
	end
	project_f(r, 72, 76, 80, tax, tay, taz, a, 8, a, 8)
	for component = 1, 4 do
		local after_x = mul_add(-r[84 + component], tbx, b[8 + component])
		local after_y = mul_add(-r[88 + component], tby, after_x)
		b[8 + component] = mul_add(-r[92 + component], tbz, after_y)
	end
end

return joint_data
