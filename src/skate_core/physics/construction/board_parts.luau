--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/construction/board_parts.rs (коммит 2e16697)
--
-- Wheel/truck mass-input producers in TU3 82C0AA78 and 82C0A6F8.
-- Allocation, material publication and final inverse inertia are separate stages.

local rt = require("../../../rt")
local primitive_mass_mod = require("./primitive_mass")

local f32 = rt.f32
local from_bits = rt.from_bits

type Vector3 = vector
type MassShape = primitive_mass_mod.MassShape
type PrimitiveMass = primitive_mass_mod.PrimitiveMass

local board_parts = {}

export type WheelMassSettings = {
	-- physicswheels.WheelRadius; 82C0AB44..82C0AB8C.
	radius: number,
	-- physicswheels.WheelMass; 82C0ACC8..82C0AD04.
	mass: number,
	-- physics_world.SkateboardMassFactor; 82C0AD0C..82C0AD58.
	mass_factor: number,
}

local WheelMassSettings = {}
board_parts.WheelMassSettings = WheelMassSettings

-- Decoded stock collection inputs, not cached mass-property outputs.
-- ROBLOX: константа-таблица -> функция, чтобы каждый получал свою копию.
function WheelMassSettings.STOCK(): WheelMassSettings
	return {
		radius = from_bits(0x3cfd_f3b6),
		mass = from_bits(0x3da9_fbe7),
		mass_factor = from_bits(0x40a0_0000),
	}
end

export type TruckMassSettings = {
	wheel_radius: number,
	wheel_x_distance: number,
	-- physicstrucks layout +52 and +56.
	radius_scalar: number,
	half_height_scalar: number,
	-- physicstrucks layout +40 and physics_world.SkateboardMassFactor.
	mass: number,
	mass_factor: number,
}

local TruckMassSettings = {}
board_parts.TruckMassSettings = TruckMassSettings

function TruckMassSettings.STOCK(): TruckMassSettings
	return {
		wheel_radius = from_bits(0x3cfd_f3b6),
		wheel_x_distance = from_bits(0x3dc2_8f5c),
		radius_scalar = from_bits(0x3f09_999a),
		half_height_scalar = from_bits(0x3fac_cccd),
		mass = from_bits(0x3ec7_ae14),
		mass_factor = from_bits(0x40a0_0000),
	}
end

-- Actual shape dimensions and requested mass passed to 82AE7770.
export type PartMassInput = {
	shape: MassShape,
	requested_mass: number,
}

-- 82C0AA78 creates one shared sphere and applies the same mass inputs to all
-- four wheel definitions. WheelCapsuleLength is not read by this function.
-- pub fn wheel_mass_input(settings: WheelMassSettings) -> PartMassInput
function board_parts.wheel_mass_input(settings: WheelMassSettings): PartMassInput
	return {
		shape = { kind = "Sphere", radius = settings.radius },
		requested_mass = f32(settings.mass * settings.mass_factor),
	}
end

-- 82C0A6F8 -> 82AD9708: capsule radius and half-length each include the final
-- multiplication by one half. Both truck definitions share this shape.
-- pub fn truck_mass_input(settings: TruckMassSettings) -> PartMassInput
function board_parts.truck_mass_input(settings: TruckMassSettings): PartMassInput
	return {
		shape = {
			kind = "Capsule",
			radius = f32(f32(settings.wheel_radius * settings.radius_scalar) * 0.5),
			half_length = f32(f32(settings.wheel_x_distance * settings.half_height_scalar) * 0.5),
		},
		requested_mass = f32(settings.mass * settings.mass_factor),
	}
end

export type ForwardMassProperties = {
	primitive: PrimitiveMass,
	mass: number,
	principal_moments: Vector3,
}

-- The supported primitive stage of 82AE7770: shape calculation, density-one
-- mass fallback at 82AE79EC, then principal-moment scaling at 82AE7A24.
-- An unsupported shape needs the aggregate producer and returns no result.
-- pub fn forward_mass_properties(input: PartMassInput) -> Option<ForwardMassProperties>
function board_parts.forward_mass_properties(input: PartMassInput): ForwardMassProperties?
	local primitive = primitive_mass_mod.primitive_mass(input.shape)
	if primitive == nil then
		return nil
	end
	local mass = if input.requested_mass < rt.F32_MIN_POSITIVE then primitive.volume else input.requested_mass
	local moments = primitive.moments_per_unit_mass
	return {
		primitive = primitive,
		mass = mass,
		principal_moments = vector.create(f32(moments.x * mass), f32(moments.y * mass), f32(moments.z * mass)),
	}
end

return board_parts
