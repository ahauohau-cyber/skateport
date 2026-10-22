--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/construction/mass_moments.rs (коммит 2e16697)
--
-- Volume moments accumulated by TU3 82AE6CB8/82AE6D88/82AE6F88 and reduced
-- to a local principal frame by 82AE7508. This is the aggregate mass producer;
-- geometry construction and requested-mass scaling remain separate stages.

local rt = require("../../../rt")
local math_mod = require("../../math")
local primitive_mass_mod = require("./primitive_mass")
local principal_axes = require("./principal_axes")

local f32 = rt.f32
local mul_add = rt.mul_add

type Vector3 = vector
type Basis3 = math_mod.Basis3

local mass_moments = {}

-- Integrals of [x,y,z,1] outer products, in column order. The last column
-- holds first moments and volume. Keeping all lanes preserves native sums.
-- ROBLOX: columns[c][i] в Rust -> columns[c + 1][i + 1].
export type MassMoments = {
	columns: { { number } },
}

-- ROBLOX: RetailLocalMassFrame из rigid_body (поля basis и translation).
export type AggregateMassProperties = {
	volume: number,
	local_mass_frame: { basis: Basis3, translation: Vector3 },
	moments_per_unit_mass: Vector3,
}

local MassMoments = {}
mass_moments.MassMoments = MassMoments

-- pub const ZERO: Self
function MassMoments.ZERO(): MassMoments
	return { columns = { { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } } }
end

-- ROBLOX: Copy-структура -> явная копия.
function MassMoments.copy(self: MassMoments): MassMoments
	local c = self.columns
	return { columns = { table.clone(c[1]), table.clone(c[2]), table.clone(c[3]), table.clone(c[4]) } }
end

-- 82AE6CB8 converts primitive principal inertia into volume moments.
-- pub fn from_primitive(primitive: PrimitiveMass) -> Self
function MassMoments.from_primitive(primitive: primitive_mass_mod.PrimitiveMass): MassMoments
	local inertia = primitive.moments_per_unit_mass
	local volume = primitive.volume
	local x = f32(f32(f32(f32(inertia.z + inertia.y) - inertia.x) * volume) * 0.5)
	local y = f32(f32(f32(f32(inertia.z + inertia.x) - inertia.y) * volume) * 0.5)
	local z = f32(f32(f32(f32(inertia.y + inertia.x) - inertia.z) * volume) * 0.5)
	return {
		columns = {
			{ x, 0.0, 0.0, 0.0 },
			{ 0.0, y, 0.0, 0.0 },
			{ 0.0, 0.0, z, 0.0 },
			{ 0.0, 0.0, 0.0, volume },
		},
	}
end

-- fn product(matrix: [[f32; 4]; 4], vector: [f32; 4]) -> [f32; 4]
local function product(matrix: { { number } }, v: { number }): { number }
	local out = table.create(4) :: { number }
	for i = 1, 4 do
		out[i] = mul_add(
			matrix[4][i],
			v[4],
			mul_add(matrix[3][i], v[3], mul_add(matrix[2][i], v[2], f32(matrix[1][i] * v[1])))
		)
	end
	return out
end

-- 82AE6D88: H * moments * transpose(H). The source explicitly sets the
-- basis fourth lanes to zero and the translation fourth lane to one.
-- ROBLOX: `&mut self` — таблица меняется на месте.
-- pub fn transform(&mut self, basis: Basis3, translation: Vector3)
function MassMoments.transform(self: MassMoments, basis: Basis3, translation: Vector3)
	local b = basis.columns
	local affine = {
		{ b[1][1], b[1][2], b[1][3], 0.0 },
		{ b[2][1], b[2][2], b[2][3], 0.0 },
		{ b[3][1], b[3][2], b[3][3], 0.0 },
		{ translation.x, translation.y, translation.z, 1.0 },
	}
	local left = {}
	for c = 1, 4 do
		left[c] = product(affine, self.columns[c])
	end
	local columns = {}
	for column = 1, 4 do
		columns[column] = product(left, { affine[1][column], affine[2][column], affine[3][column], affine[4][column] })
	end
	self.columns = columns
end

-- 82AE6F88 adds successful children in volume order, without weighting or
-- normalizing them individually. Collision-enable flags are not read here.
-- pub fn add(&mut self, child: Self)
function MassMoments.add(self: MassMoments, child: MassMoments)
	for c = 1, 4 do
		for i = 1, 4 do
			self.columns[c][i] = f32(self.columns[c][i] + child.columns[c][i])
		end
	end
end

local function select_nonnegative(selector: number, positive: number, negative: number): number
	return if selector >= 0.0 then positive else negative
end

local F32_FLOOR = f32(0.0050000004)

-- 82AE7508 mutates the aggregate into its center-of-mass frame before
-- diagonalizing its inertia. Preserve this mutation and native axis order.
-- pub fn principal_properties(&mut self) -> AggregateMassProperties
function MassMoments.principal_properties(self: MassMoments): AggregateMassProperties
	-- ROBLOX: refined_reciprocal из mass.luau; mass подключает этот файл, поэтому
	-- подключение внутри функции разрывает цикл require.
	local refined_reciprocal = (require("../mass") :: any).refined_reciprocal
	local volume = self.columns[4][4]
	local inverse_volume = refined_reciprocal(volume)
	local center = vector.create(
		f32(self.columns[4][1] * inverse_volume),
		f32(self.columns[4][2] * inverse_volume),
		f32(self.columns[4][3] * inverse_volume)
	)
	MassMoments.transform(
		self,
		{ columns = { { 1.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, { 0.0, 0.0, 1.0 } } },
		vector.create(-center.x, -center.y, -center.z)
	)
	local m = self.columns
	local xy = f32(f32(m[2][1] + m[1][2]) * -0.5)
	local xz = f32(f32(m[3][1] + m[1][3]) * -0.5)
	local yz = f32(f32(m[3][2] + m[2][3]) * -0.5)
	local inertia = {
		{ f32(m[2][2] + m[3][3]), xy, xz },
		{ xy, f32(m[1][1] + m[3][3]), yz },
		{ xz, yz, f32(m[1][1] + m[2][2]) },
	}
	local axes = principal_axes.diagonalize(inertia)
	local maximum_yz = select_nonnegative(f32(inertia[2][2] - inertia[3][3]), inertia[2][2], inertia[3][3])
	local maximum = select_nonnegative(f32(inertia[1][1] - maximum_yz), inertia[1][1], maximum_yz)
	local floor = f32(maximum * F32_FLOOR)
	local moments = {}
	for i = 1, 3 do
		moments[i] = f32(select_nonnegative(f32(inertia[i][i] - floor), inertia[i][i], floor) * inverse_volume)
	end
	local columns = {}
	for i = 1, 3 do
		columns[i] = { axes[1][i], axes[2][i], axes[3][i] }
	end
	return {
		volume = volume,
		local_mass_frame = {
			basis = { columns = columns },
			translation = center,
		},
		moments_per_unit_mass = vector.create(moments[1], moments[2], moments[3]),
	}
end

return mass_moments
