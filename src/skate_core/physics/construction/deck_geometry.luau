--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/construction/deck_geometry.rs (коммит 2e16697)
--
-- Deck collision children constructed by TU3 82C09290 and 82C0A2A0/3E0/510.
-- Allocation is host-owned; dimensions, child order, flags and arithmetic are
-- source-derived. Mass uses the actual primitive/triangle-AABB dispatch in
-- 82AE7058, including children whose collision-enable bit is clear.

local rt = require("../../../rt")
local math_mod = require("../../math")
local trigonometry = require("../../trigonometry")
local native_arithmetic = require("../native_arithmetic")
local primitive_mass_mod = require("./primitive_mass")
local mass_moments = require("./mass_moments")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local MassMoments = mass_moments.MassMoments

type Vector3 = vector
type Basis3 = math_mod.Basis3
type MassMoments = mass_moments.MassMoments

local deck_geometry = {}

-- ROBLOX: RetailAffineTransform определён в drive_frames, а drive_frames
-- подключает mass, которая подключает этот файл. Тип и IDENTITY повторены здесь.
export type RetailAffineTransform = { basis: Basis3, translation: Vector3 }

local function identity(): RetailAffineTransform
	return {
		basis = { columns = { { 1.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, { 0.0, 0.0, 1.0 } } },
		translation = vector.create(0, 0, 0),
	}
end

export type DeckGeometrySettings = {
	width: number,
	mid_length: number,
	thickness: number,
	-- Both fans read DeckBackEndSize. DeckFrontEndSize is not read here.
	back_end_size: number,
	front_end_angle_degrees: number,
	back_end_angle_degrees: number,
	-- DeckEndCapsules (Int32), despite the triangles produced by this loop.
	end_capsule_count: number,
	enable_deck_volume_collisions: boolean,
	enable_end_volume_collisions: boolean,
}

local DeckGeometrySettings = {}
deck_geometry.DeckGeometrySettings = DeckGeometrySettings

-- physicsdeck/default.xml, retaining the original Float words.
function DeckGeometrySettings.STOCK(): DeckGeometrySettings
	return {
		width = from_bits(0x3E75_C28F),
		mid_length = from_bits(0x3F17_0A3D),
		thickness = from_bits(0x3C75_C28F),
		back_end_size = from_bits(0x3E28_F5C3),
		front_end_angle_degrees = from_bits(0x4150_0000),
		back_end_angle_degrees = from_bits(0x4148_0000),
		end_capsule_count = 5,
		enable_deck_volume_collisions = true,
		enable_end_volume_collisions = true,
	}
end

-- pub enum DeckShape
-- ROBLOX: таблица с полем kind: RoundedBox { half_extents, radius },
-- Capsule { radius, half_length }, Sphere { radius },
-- Triangle { vertices, fatness, edge_cosines, volume_flags } (флаги Volume,
-- без отдельного бита collision-enable; это не флаги GPTriangle).
export type DeckShape = {
	kind: "RoundedBox" | "Capsule" | "Sphere" | "Triangle",
	half_extents: Vector3?,
	radius: number?,
	half_length: number?,
	vertices: { Vector3 }?,
	fatness: number?,
	edge_cosines: { number }?,
	volume_flags: number?,
}

export type DeckChild = {
	shape: DeckShape,
	transform: RetailAffineTransform,
	collision_enabled: boolean,
}

export type DeckGeometry = {
	children: { DeckChild },
}

local function translated(translation: Vector3): RetailAffineTransform
	local t = identity()
	t.translation = translation
	return t
end

-- Length path in 82E0B1E0.
local function vector_length_z(z: number): number
	local squared = native_arithmetic.dot3({ 0.0, 0.0, z, 0.0 }, { 0.0, 0.0, z, 0.0 })
	local inverse = native_arithmetic.reciprocal_square_root_estimate(squared)
	for _ = 1, 2 do
		local residual = mul_add(-squared, f32(inverse * inverse), 1.0)
		inverse = mul_add(f32(inverse * 0.5), residual, inverse)
	end
	if squared == 0.0 then
		return 0.0
	end
	return f32(squared * inverse)
end

local COSINE_COEFFICIENTS = {
	0x3D2A_AAAB,
	0xBAB6_0B61,
	0x37D0_0D01,
	0xB493_F27E,
	0x310F_76C8,
	0xAD49_CBA5,
	0x2957_3F9F,
	0xA534_13C3,
	0x20F2_A15D,
	0x9C86_71CB,
}

-- Standalone cosine 82473930. Its even-power tree differs from SinCos.
local function cosine(angle: number): number
	local turns = rt.round_ties_even(f32(angle * from_bits(0x3E22_F983)))
	local x = mul_add(-from_bits(0x40C9_0FDB), turns, angle)
	local x2 = f32(x * x)
	local x4 = f32(x2 * x2)
	local x6 = f32(x4 * x2)
	local x8 = f32(x4 * x4)
	local x10 = f32(x6 * x4)
	local x12 = f32(x6 * x6)
	local x14 = f32(x8 * x6)
	local x16 = f32(x8 * x8)
	local x18 = f32(x10 * x8)
	local x20 = f32(x10 * x10)
	local x22 = f32(x12 * x10)
	local powers = { x4, x6, x8, x10, x12, x14, x16, x18, x20, x22 }
	local result = mul_add(-0.5, x2, 1.0)
	for i, coefficient in COSINE_COEFFICIENTS do
		result = mul_add(from_bits(coefficient), powers[i], result)
	end
	return result
end

type Arc = { number } -- (sin, cos)

-- fn fan_triangle(previous, next, slope, width, length, center_z, fatness, front, enabled) -> DeckChild
local function fan_triangle(
	previous: Arc,
	next_arc: Arc,
	slope: Arc,
	width: number,
	length: number,
	center_z: number,
	fatness: number,
	front: boolean,
	enabled: boolean
): DeckChild
	local function point(arc: Arc): Vector3
		local along_end = f32(arc[1] * length)
		local elevation = if front then along_end else -along_end
		return vector.create(f32(arc[2] * width), f32(slope[1] * elevation), mul_add(along_end, slope[2], center_z))
	end
	return {
		shape = {
			kind = "Triangle",
			vertices = { vector.create(0.0, 0.0, center_z), point(previous), point(next_arc) },
			fatness = fatness,
			edge_cosines = { 1.0, -1.0, 1.0 },
			volume_flags = 0x3E2,
		},
		transform = identity(),
		collision_enabled = enabled,
	}
end

local DeckGeometry = {}
deck_geometry.DeckGeometry = DeckGeometry

-- pub fn new(settings: DeckGeometrySettings) -> Self
function DeckGeometry.new(settings: DeckGeometrySettings): DeckGeometry
	local half_width = f32(settings.width * 0.5)
	local half_length = f32(settings.mid_length * 0.5)
	local half_thickness = f32(settings.thickness * 0.5)
	local radius = f32(half_thickness * from_bits(0x3F66_6666))
	local children: { DeckChild } = ({
		{
			shape = {
				kind = "RoundedBox",
				half_extents = vector.create(
					f32(half_width - radius),
					f32(half_thickness - radius),
					f32(half_length - radius)
				),
				radius = radius,
			},
			transform = identity(),
			collision_enabled = settings.enable_deck_volume_collisions,
		},
	} :: any)

	-- 82E0B1E0: midpoint = first + (second-first)/2. These endpoints are
	-- parallel to local Z, so the orientation branch leaves identity.
	local longitudinal_half_delta = f32(f32(-half_length - half_length) * 0.5)
	local capsule_half_length = vector_length_z(longitudinal_half_delta)
	local capsule_center_z = f32(half_length + longitudinal_half_delta)
	local arc_width = f32(half_width - half_thickness)
	for _, x in { arc_width, f32(half_thickness - half_width) } do
		table.insert(children, ({
			shape = { kind = "Capsule", radius = half_thickness, half_length = capsule_half_length },
			transform = translated(vector.create(x, 0.0, capsule_center_z)),
			collision_enabled = settings.enable_end_volume_collisions,
		} :: any))
	end
	-- 82C0A3E0 retains the sphere constructor's enabled flag, independent
	-- of the two authored deck collision toggles.
	for _, z in { from_bits(0x3E70_A3D7), from_bits(0xBE70_A3D7) } do
		table.insert(children, ({
			shape = { kind = "Sphere", radius = f32(0.035) },
			transform = translated(vector.create(0.0, from_bits(0xBCA3_D70A), z)),
			collision_enabled = true,
		} :: any))
	end

	local radians = from_bits(0x3C8E_FA35)
	local back_angle = f32(settings.back_end_angle_degrees * radians)
	local front_angle = f32(settings.front_end_angle_degrees * radians)
	local back_slope = { trigonometry.sin(back_angle), cosine(back_angle) }
	local front_slope = { trigonometry.sin(front_angle), cosine(front_angle) }
	local end_length = f32(settings.back_end_size - half_thickness)
	local previous_back = { trigonometry.sin(0.0), cosine(0.0) }
	local previous_front = previous_back
	local count = settings.end_capsule_count
	for segment = 1, count do
		-- ROBLOX: `segment as f32`, `end_capsule_count as f32` — целые малы, точны в f32.
		local back_arc = f32(f32(segment * from_bits(0xC049_0FDB)) / count)
		local next_back = { trigonometry.sin(back_arc), cosine(back_arc) }
		table.insert(
			children,
			fan_triangle(
				previous_back,
				next_back,
				back_slope,
				arc_width,
				end_length,
				-half_length,
				half_thickness,
				false,
				settings.enable_deck_volume_collisions
			)
		)
		previous_back = next_back
		local front_arc = f32(f32(segment * from_bits(0x4049_0FDB)) / count)
		local next_front = { trigonometry.sin(front_arc), cosine(front_arc) }
		table.insert(
			children,
			fan_triangle(
				previous_front,
				next_front,
				front_slope,
				arc_width,
				end_length,
				half_length,
				half_thickness,
				true,
				settings.enable_deck_volume_collisions
			)
		)
		previous_front = next_front
	end
	return { children = children }
end

local DeckChild = {}
deck_geometry.DeckChild = DeckChild

-- pub fn mass_moments(&self) -> MassMoments
function DeckChild.mass_moments(self: DeckChild): MassMoments
	local s = self.shape
	local shape: primitive_mass_mod.MassShape
	local transform: RetailAffineTransform
	if s.kind == "Sphere" then
		shape, transform = { kind = "Sphere", radius = s.radius }, self.transform
	elseif s.kind == "Capsule" then
		shape, transform = { kind = "Capsule", radius = s.radius, half_length = s.half_length }, self.transform
	elseif s.kind == "RoundedBox" then
		shape, transform = { kind = "RoundedBox", half_extents = s.half_extents, radius = s.radius }, self.transform
	else
		-- TU3 TriangleVolume::GetBBox 82ADDC40, null transform branch:
		-- min(v0,min(v1,v2))-fatness, max(v0,max(v1,v2))+fatness.
		-- 82AE7058 deliberately uses this box for triangle mass; no
		-- triangle pose transform is applied again after this branch.
		local vertices = s.vertices :: { Vector3 }
		local fatness = s.fatness :: number
		local function axis(a: number, b: number, c: number): (number, number)
			local low = f32(native_arithmetic.vector_min(a, native_arithmetic.vector_min(b, c)) - fatness)
			local high = f32(native_arithmetic.vector_max(a, native_arithmetic.vector_max(b, c)) + fatness)
			local half = f32(f32(high - low) * 0.5)
			return half, f32(low + half)
		end
		local hx, cx = axis(vertices[1].x, vertices[2].x, vertices[3].x)
		local hy, cy = axis(vertices[1].y, vertices[2].y, vertices[3].y)
		local hz, cz = axis(vertices[1].z, vertices[2].z, vertices[3].z)
		shape = { kind = "RoundedBox", half_extents = vector.create(hx, hy, hz), radius = 0.0 }
		transform = translated(vector.create(cx, cy, cz))
	end
	local primitive = primitive_mass_mod.primitive_mass(shape :: any)
	assert(primitive, "every deck child follows a supported source mass branch")
	local moments = MassMoments.from_primitive(primitive)
	MassMoments.transform(moments, transform.basis, transform.translation)
	return moments
end

-- pub fn mass_moments(&self) -> MassMoments
function DeckGeometry.mass_moments(self: DeckGeometry): MassMoments
	local total = MassMoments.ZERO()
	for _, child in self.children do
		MassMoments.add(total, DeckChild.mass_moments(child))
	end
	-- The aggregate volume's transform is identity (82AD7740).
	MassMoments.transform(total, identity().basis, vector.create(0, 0, 0))
	return total
end

return deck_geometry
