--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/construction.rs (коммит 2e16697)
--
-- SkeletonBody::Init82BE4900, head82BE5428 and extra capsules82BE5180.

local rt = require("../../../rt")
local math_mod = require("../../math")
local mass = require("../mass")
local primitive_mass_mod = require("../construction/primitive_mass")
local mass_moments = require("../construction/mass_moments")
local native_arithmetic = require("../native_arithmetic")
local rigid_body = require("../rigid_body")
local sar = require("../skeleton_animation_record")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

type Vector3 = vector
type Basis3 = math_mod.Basis3
type MassShape = primitive_mass_mod.MassShape
type RetailBodyMassProperties = rigid_body.RetailBodyMassProperties

-- ROBLOX: константы из mod.rs продублированы, чтобы не было циклического require.
local ANIMATION_PART_COUNT = 24

local construction = {}

export type BoneSettings = {
	mass_factor: number,
	ragdoll_mass_factor: number,
	has_collision: boolean,
	use_root_drive: boolean,
	volume_type: number,
	volume_scalar: number,
	num_parents: number,
}

export type SkeletonBodySettings = {
	-- Native MassOfSkeleton multiplies each original bone-box volume. It is
	-- not a requested total body mass and must not normalize the part masses.
	density: number,
	root_radius: number,
	root_half_length: number,
	capsule_radius_scalar: number,
	capsule_length_scalar: number,
	ragdoll_inverse_mass_factor: number,
	inertia_multiply_type: number,
	inertia_factor: number,
}

-- /// Authored cylinder and transform from physics_hat, before head aggregation.
export type HatGeometry = {
	radius: number,
	half_length: number,
	basis: Basis3,
	translation: Vector3,
}

local HatGeometry = {}
construction.HatGeometry = HatGeometry

-- ///82BE55A0..569C: authored Euler angles feed XMVectorSinCos directly.
function HatGeometry.from_offsets(radius: number, thickness: number, angles: Vector3, translation: Vector3): HatGeometry
	local sx, cx = trigonometry.sin_cos(angles.x)
	local sy, cy = trigonometry.sin_cos(angles.y)
	local sz, cz = trigonometry.sin_cos(angles.z)
	local cxsz = f32(cx * sz)
	local sxsz = f32(sx * sz)
	local sxcz = f32(sx * cz)
	local cxcz = f32(cx * cz)
	return {
		radius = radius,
		half_length = f32(thickness * 0.5),
		translation = translation,
		basis = {
			columns = {
				{ f32(cy * cz), f32(cy * sz), -sy },
				{ f32(f32(sy * sxcz) - cxsz), mul_add(sy, sxsz, cxcz), f32(cy * sx) },
				{ mul_add(sy, cxcz, sxsz), f32(f32(sy * cxsz) - sxcz), f32(cy * cx) },
			},
		},
	}
end

-- ROBLOX: hat: Option<HatGeometry> -> значение или nil.
export type SkeletonPart = {
	-- Part1 can additionally contain the separately described hat cylinder.
	shape: MassShape,
	hat: HatGeometry?,
	animated: RetailBodyMassProperties,
	ragdoll: RetailBodyMassProperties,
	inverse_mass_animated: number,
	inverse_mass_ragdoll: number,
}

export type SkeletonBodyDefinition = {
	parts: { SkeletonPart },
	bones: { BoneSettings },
	animation_masses: sar.SkeletonAnimationMasses,
}

local SkeletonBodyDefinition = {}
construction.SkeletonBodyDefinition = SkeletonBodyDefinition

local function copy_properties(p: RetailBodyMassProperties): RetailBodyMassProperties
	return {
		local_mass_frame = { basis = math_mod.Basis3.copy(p.local_mass_frame.basis), translation = p.local_mass_frame.translation },
		dynamics = table.clone(p.dynamics),
	}
end

-- ROBLOX: Result<_, &str> -> значение или rt.raise(строка).
local function mass_properties(shape: MassShape, hat: HatGeometry?, mass_value: number): RetailBodyMassProperties
	if hat ~= nil then
		-- Init82BE5428 uses cylinder first, then the head sphere. Preserve
		-- accumulation order and the later identity mass-frame override.
		local cylinder = primitive_mass_mod.primitive_mass({ kind = "Cylinder", radius = hat.radius, half_length = hat.half_length, padding = 0.0 })
		if cylinder == nil then
			rt.raise("Invalid skeleton hat primitive")
		end
		local moments = mass_moments.MassMoments.from_primitive(cylinder :: any)
		mass_moments.MassMoments.transform(moments, hat.basis, hat.translation)
		local head = primitive_mass_mod.primitive_mass(shape)
		if head == nil then
			rt.raise("Invalid head primitive")
		end
		mass_moments.MassMoments.add(moments, mass_moments.MassMoments.from_primitive(head :: any))
		local properties = mass.aggregate_mass_properties(moments, mass_value, mass.RETAIL_UNBOUNDED_VELOCITY, 0.0)
		properties.local_mass_frame = rigid_body.RetailLocalMassFrame.IDENTITY()
		return properties
	end
	local properties = mass.primitive_mass_properties({ shape = shape, requested_mass = mass_value } :: any, mass.RETAIL_UNBOUNDED_VELOCITY, 0.0)
	if properties == nil then
		rt.raise("Invalid skeleton primitive")
	end
	return properties :: RetailBodyMassProperties
end

-- /// DebugMultiplyInertiaTensor82E0B070 / SetSphericalInertiaTensor82E0B110.
local function adjust_inertia(properties: RetailBodyMassProperties, kind: number, factor: number)
	local d = properties.dynamics
	if kind == 1 then
		local reciprocal = native_arithmetic.reciprocal_estimate(factor)
		for _ = 1, 2 do
			reciprocal = mul_add(reciprocal, mul_add(-reciprocal, factor, 1.0), reciprocal)
		end
		local t = d.inverse_tensor
		d.inverse_tensor = vector.create(f32(t.x * reciprocal), f32(t.y * reciprocal), f32(t.z * reciprocal))
		t = d.inverse_tensor
		local xy = if t.x < t.y then t.x else t.y
		local xyz = if xy < t.z then xy else t.z
		d.spherical = f32(1.0 / xyz)
	elseif kind == 2 then
		local reciprocal = f32(1.0 / f32(factor * 3.0))
		local t = d.inverse_tensor
		local value = f32(f32(f32(t.x + t.y) + t.z) * reciprocal)
		d.inverse_tensor = vector.create(value, value, value)
		d.spherical = f32(1.0 / value)
	end
end

-- ROBLOX: Result<Self, &str> -> SkeletonBodyDefinition или rt.raise(строка).
-- Массивы sizes/bones — по части, индекс с 1.
function SkeletonBodyDefinition.new(sizes: { Vector3 }, bones: { BoneSettings }, settings: SkeletonBodySettings, hat: HatGeometry?): SkeletonBodyDefinition
	local parts: { SkeletonPart } = {}
	for i = 0, ANIMATION_PART_COUNT - 1 do
		local b = bones[i + 1]
		local size = sizes[i + 1]
		local shape: any
		if i == 0 then
			shape = { kind = "Capsule", radius = settings.root_radius, half_length = settings.root_half_length }
		elseif (i == 1 and hat ~= nil) or b.volume_type == 1 then
			local x = f32(size.x * 0.5)
			local y = f32(size.y * 0.5)
			shape = { kind = "Sphere", radius = f32((if f32(x - y) >= 0.0 then x else y) * b.volume_scalar) }
		elseif b.volume_type == 0 then
			local scalar = f32(b.volume_scalar * 0.5)
			shape = { kind = "RoundedBox", half_extents = vector.create(f32(size.x * scalar), f32(size.y * scalar), f32(size.z * scalar)), radius = 0.0 }
		elseif b.volume_type == 2 then
			local radius = f32(f32(size.x * settings.capsule_radius_scalar) * 0.5)
			local length = f32(f32(size.z * 0.5) - radius)
			shape = {
				kind = "Capsule",
				radius = f32(b.volume_scalar * radius),
				half_length = f32(f32((if -length >= 0.0 then 0.0 else length) * settings.capsule_length_scalar) * b.volume_scalar),
			}
		else
			rt.raise("Unresolved non-root skeleton volume type")
		end
		local base_mass = if i == 0 then from_bits(0x3A83_126F) else f32(settings.density * f32(f32(size.x * size.y) * size.z))
		local head_hat = if i == 1 then hat else nil
		local animated_mass = f32(b.mass_factor * base_mass)
		local ragdoll_mass = f32(b.ragdoll_mass_factor * base_mass)
		local animated = mass_properties(shape, head_hat, animated_mass)
		local ragdoll = mass_properties(shape, head_hat, ragdoll_mass)
		adjust_inertia(animated, settings.inertia_multiply_type, settings.inertia_factor)
		table.insert(parts, {
			shape = shape,
			hat = head_hat,
			animated = animated,
			ragdoll = ragdoll,
			inverse_mass_animated = f32(1.0 / animated_mass),
			inverse_mass_ragdoll = f32(settings.ragdoll_inverse_mass_factor / ragdoll_mass),
		})
	end
	--82BE4F80..4FC4 passes these independent radius/half-length/mass words.
	for _, words in { { 0x3E6B_851F, 0x3DCC_CCCD, 0x3DCC_CCCD }, { 0x3EB8_51EC, 0x3E85_1EB8, 0x3C23_D70A } } do
		local m = from_bits(words[3])
		local shape: MassShape = { kind = "Capsule", radius = from_bits(words[1]), half_length = from_bits(words[2]) }
		local properties = mass_properties(shape, nil, m)
		properties.dynamics.maximum_linear_velocity = from_bits(0x41EF_FFFF)
		properties.dynamics.maximum_angular_velocity = from_bits(0x41EF_FFFF)
		adjust_inertia(properties, 1, 5.0)
		table.insert(parts, {
			shape = shape,
			hat = nil,
			animated = properties,
			ragdoll = copy_properties(properties),
			inverse_mass_animated = f32(1.0 / m),
			inverse_mass_ragdoll = f32(1.0 / m),
		})
	end
	local volume_types = {}
	for i, b in bones do
		volume_types[i] = b.volume_type
	end
	return {
		parts = parts,
		animation_masses = sar.SkeletonAnimationMasses.from_bone_data(sizes, volume_types, hat ~= nil),
		bones = bones,
	}
end

return construction
