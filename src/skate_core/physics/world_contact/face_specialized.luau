--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/face_specialized.rs (коммит 2e16697)
-- В Rust это подмодуль dispatch (`#[path = "face_specialized.rs"] mod face_specialized`).

local rt = require("../../../rt")
local prism_math = require("./prism_math")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local load, dot, sub, madd, reciprocal = prism_math.load, prism_math.dot, prism_math.sub, prism_math.madd, prism_math.reciprocal
local bits = prism_math.bits

local face_specialized = {}

type V = { number }

-- fn vertex(feature: &MaximumFeature, edge: usize) -> V
local function vertex(feature: { number }, edge: number): V
	return load(feature, 4 + edge * 16)
end

-- fn project_to_face(face: &MaximumFeature, point: V) -> V
local function project_to_face(face: { number }, point: V): V
	local normal = load(face, 132)
	return madd(normal, dot(normal, sub(vertex(face, 0), point)), point)
end

-- fn append(output, count: &mut usize, a, b, point: V, a_is_first: bool)
-- ROBLOX: возвращает новый count.
local function append(output: { number }, count: number, a: { number }, b: { number }, point: V, a_is_first: boolean): number
	assert(count < 16, "feature prism point capacity exceeded")
	local ao, bo
	if a_is_first then
		ao, bo = 0, 64
	else
		ao, bo = 64, 0
	end
	local offset = count * 4
	rt.copy_into(output, ao + offset, bits(project_to_face(a, point)))
	rt.copy_into(output, bo + offset, bits(project_to_face(b, point)))
	return count + 1
end

-- The contained-vertex passes use lane-wise multiply/FMA operations, with a
-- rounded Y product followed by X and Z FMAs, instead of the VMX three-lane dot.
-- fn containment_dot(delta: V, normal: V) -> f32
local function containment_dot(delta: V, normal: V): number
	return mul_add(delta[3], normal[3], mul_add(delta[1], normal[1], f32(delta[2] * normal[2])))
end

-- fn intersect(output, a, b, normal: [u32; 4], a_is_first: bool) -> u32
local function intersect(output: { number }, a: { number }, b: { number }, normal_bits: { number }, a_is_first: boolean): number
	local count = 0
	local b_count = b[141]
	-- Full native edge-pair validity masks, including endpoint equality.
	-- Only the first lane of each mask controls publication, so broadcast
	-- feature lengths are read from their first lane here as in the source.
	for edge_a = 0, 3 do
		local a_origin = vertex(a, edge_a)
		local a_direction = load(a, 8 + edge_a * 16)
		local a_plane = load(a, 12 + edge_a * 16)
		local a_length = from_bits(a[16 + edge_a * 16 + 1])
		for edge_b = 0, b_count - 1 do
			local b_origin = vertex(b, edge_b)
			local b_direction = load(b, 8 + edge_b * 16)
			local b_length = from_bits(b[16 + edge_b * 16 + 1])
			local denominator = dot(b_direction, a_plane)
			local offset = dot(sub(a_origin, b_origin), a_plane)
			local point = madd(b_direction, f32(reciprocal(denominator) * offset), b_origin)
			local along_a = dot(sub(point, a_origin), a_direction)
			local valid = math.abs(denominator) > from_bits(0x3400_0000)
				and not (math.abs(offset) > math.abs(f32(b_length * denominator)))
				and not (0.0 > f32(offset * denominator))
				and not (along_a > a_length)
				and not (0.0 > along_a)
			if valid then
				count = append(output, count, a, b, point, a_is_first)
			end
		end
	end
	local normal = { from_bits(normal_bits[1]), from_bits(normal_bits[2]), from_bits(normal_bits[3]), from_bits(normal_bits[4]) }
	for _, pass in { { a, b, 4, b_count }, { b, a, b_count, 4 } } do
		local source: { number }, target: { number } = pass[1] :: any, pass[2] :: any
		local source_count: number, target_count: number = pass[3] :: any, pass[4] :: any
		for corner = 0, source_count - 1 do
			local origin = vertex(source, corner)
			local distance = containment_dot(sub(vertex(target, 0), origin), normal)
			-- The source transposes XYZ back into points with a literal W=1.
			local point = madd(normal, distance, origin)
			point[4] = 1.0
			local inside = true
			for edge = 0, target_count - 1 do
				local d = containment_dot(sub(point, vertex(target, edge)), load(target, 12 + edge * 16))
				if not (0.0 > d) then
					inside = false
					break
				end
			end
			if inside then
				count = append(output, count, a, b, point, a_is_first)
			end
		end
	end
	output[133] = count
	return if count ~= 0 then 1 else 0
end

-- TU3 82ACCEF0. The quad owns the outer edge-intersection loop even when it is
-- the second feature in the caller's pair. This order reaches contact reduction.
-- pub(super) fn quad_triangle(output, quad, triangle, normal: [u32; 4], quad_is_a: bool) -> u32
function face_specialized.quad_triangle(
	output: { number },
	quad: { number },
	triangle: { number },
	normal: { number },
	quad_is_a: boolean
): number
	return intersect(output, quad, triangle, normal, quad_is_a)
end

-- TU3 82ACD7D8. Its calculations match 82ACCEF0 with four inner edges and four
-- vertices in both containment passes; the source transposes these into lanes.
-- pub(super) fn quad_quad(output, a, b, normal: [u32; 4]) -> u32
function face_specialized.quad_quad(output: { number }, a: { number }, b: { number }, normal: { number }): number
	return intersect(output, a, b, normal, true)
end

return face_specialized
