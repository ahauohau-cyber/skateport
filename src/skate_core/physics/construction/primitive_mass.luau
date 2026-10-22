--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/construction/primitive_mass.rs (коммит 2e16697)
--
-- Forward principal moments and volume from TU3 82AE7228/82AE6B78.
-- These quantities precede mass scaling and inverse-inertia construction.
-- ROBLOX: в Rust это подмодуль mass (`#[path]`), здесь — отдельный файл по тому же пути.

local rt = require("../../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

type Vector3 = vector

local primitive_mass_mod = {}

-- pub enum MassShape
-- ROBLOX: enum с данными -> таблица с полем kind.
-- Sphere { radius }; Capsule { radius, half_length } (продольная ось — local Z);
-- RoundedBox { half_extents, radius }; Cylinder { radius, half_length, padding };
-- Unsupported — треугольник, агрегат и прочие типы, отклонённые 82AE7228.
export type MassShape = {
	kind: "Sphere" | "Capsule" | "RoundedBox" | "Cylinder" | "Unsupported",
	radius: number?,
	half_length: number?,
	half_extents: Vector3?,
	padding: number?,
}

-- pub struct PrimitiveMass
export type PrimitiveMass = {
	moments_per_unit_mass: Vector3,
	volume: number,
}

local MIN_RADIUS = from_bits(0x33d6_bf95)
local SPHERE_VOLUME = from_bits(0x4086_0a92)
local FOUR_THIRDS = from_bits(0x3faa_aaab)
local TWO_THIRDS = from_bits(0x3f2a_aaab)
local ONE_THIRD = from_bits(0x3eaa_aaab)
local ONE_TWELFTH = from_bits(0x3daa_aaab)
local PI = from_bits(0x4049_0fdb)
local TWO_PI = from_bits(0x40c9_0fdb)
local F32_0_4 = f32(0.4)
local F32_0_05 = f32(0.05)

-- The native fsubs/fsel chooses the right operand for an unordered difference.
-- Keep this ordered comparison, including its signed-zero operand selection.
local function greater_extent(left: number, right: number): number
	if f32(left - right) >= 0.0 then
		return left
	end
	return right
end

-- Complete 82AE6B78: native rounded-box dimension floor, moments and volume.
local function rounded_box_mass(half_extents: Vector3, radius: number): PrimitiveMass
	local largest = greater_extent(half_extents.x, greater_extent(half_extents.y, half_extents.z))
	local floor = f32(greater_extent(f32(f32(largest + radius) * F32_0_05), MIN_RADIUS) - radius)
	local x = greater_extent(half_extents.x, floor)
	local y = greater_extent(half_extents.y, floor)
	local z = greater_extent(half_extents.z, floor)
	local radius_moment = f32(f32(radius * radius) * 0.5)
	local x_squared = f32(x * x)
	local y_squared = f32(y * y)
	local z_squared = f32(z * z)
	local xy_radius = f32(f32(x + y) * radius)
	local yz_radius = f32(f32(y + z) * radius)
	local xz_radius = f32(f32(x + z) * radius)
	local moment_x = mul_add(f32(mul_add(yz_radius, 2.0, z_squared) + y_squared), ONE_THIRD, radius_moment)
	local moment_y = mul_add(f32(mul_add(xz_radius, 2.0, x_squared) + z_squared), ONE_THIRD, radius_moment)
	local moment_z = mul_add(f32(mul_add(xy_radius, 2.0, x_squared) + y_squared), ONE_THIRD, radius_moment)
	local rounded_edges = f32(f32(f32(f32(mul_add(radius, TWO_THIRDS, x) + y) + z) * radius) * TWO_PI)
	local face_products = mul_add(f32(y + z), x, f32(y * z))
	local box_volume = f32(f32(f32(x * y) * z) * 8.0)
	return {
		moments_per_unit_mass = vector.create(moment_x, moment_y, moment_z),
		volume = mul_add(mul_add(face_products, 8.0, rounded_edges), radius, box_volume),
	}
end

-- Complete shape dispatch in 82AE7228. Unsupported shapes return no result,
-- matching the native false return and absence of output writes. All supported
-- branches retain the native scalar operation order and fused multiply-adds.
-- pub fn primitive_mass(shape: MassShape) -> Option<PrimitiveMass>
function primitive_mass_mod.primitive_mass(shape: MassShape): PrimitiveMass?
	if shape.kind == "Unsupported" then
		return nil
	elseif shape.kind == "Sphere" then
		local radius = greater_extent(shape.radius :: number, MIN_RADIUS)
		local radius_squared = f32(radius * radius)
		local moment = f32(radius_squared * F32_0_4)
		return {
			moments_per_unit_mass = vector.create(moment, moment, moment),
			volume = f32(f32(radius_squared * radius) * SPHERE_VOLUME),
		}
	elseif shape.kind == "Capsule" then
		local half_length = shape.half_length :: number
		local length_squared = f32(half_length * half_length)
		local radius = greater_extent(greater_extent(shape.radius :: number, MIN_RADIUS), f32(half_length * F32_0_05))
		local numerator = mul_add(
			mul_add(mul_add(radius, f32(1.6), f32(half_length * 0.75)), radius, f32(length_squared * 4.0)),
			radius,
			f32(length_squared * half_length)
		)
		local denominator = mul_add(radius, 4.0, f32(half_length * 3.0))
		local transverse = f32(numerator / denominator)
		local axial = f32(f32(radius * radius) * F32_0_4)
		return {
			moments_per_unit_mass = vector.create(transverse, transverse, axial),
			volume = f32(f32(f32(mul_add(radius, FOUR_THIRDS, f32(half_length * 2.0)) * radius) * radius) * PI),
		}
	elseif shape.kind == "RoundedBox" then
		return rounded_box_mass(shape.half_extents :: Vector3, shape.radius :: number)
	else
		-- Cylinder
		local radius = f32((shape.radius :: number) + (shape.padding :: number))
		local half_length = f32((shape.half_length :: number) + (shape.padding :: number))
		local radius_squared = f32(radius * radius)
		local transverse = f32(mul_add(f32(half_length * half_length), 4.0, f32(radius_squared * 3.0)) * ONE_TWELFTH)
		return {
			moments_per_unit_mass = vector.create(transverse, transverse, f32(radius_squared * 0.5)),
			volume = f32(f32(f32(half_length * radius) * radius) * TWO_PI),
		}
	end
end

return primitive_mass_mod
