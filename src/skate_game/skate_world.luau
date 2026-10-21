--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/skate_world.rs (коммит 2e16697)
--
-- TODO: перенесена только часть `collision_world` для переносимых карт
-- (сварка вершин, смежность рёбер, флаги выпуклости и вершин). Чтение
-- архивов retail-карт и `retail_collision_world` в Roblox не нужны: геометрию
-- даёт roblox/world_geometry. Сборка QueryMetadata (меши по 64 треугольника)
-- и вызов BoardWorld::with_query_metadata добавятся вместе с BoardWorld.

local rt = require("../rt")
local fixup = require("../skate_core/physics/collision/fixup")
local board_world = require("../skate_core/physics/board_world")
local contact = require("../skate_core/physics/contact")

local f32 = rt.f32
local TriangleFeature = fixup.TriangleFeature
local WorldTriangle = board_world.WorldTriangle

type Vector3 = vector

local skate_world = {}

-- ROBLOX: в Rust это `map.geometry.collision` — треугольник карты SKATE.
-- `points` — три вершины в метрах, `surface` — тег поверхности.
-- `native_edges` в Roblox не бывает: смежность всегда строится заново.
export type CollisionTriangle = {
	points: { Vector3 },
	surface: number,
}

-- ROBLOX: glam::Vec3 считает в f32 без fma — каждую операцию округляем.
local function sub(a: Vector3, b: Vector3): Vector3
	return vector.create(f32(a.x - b.x), f32(a.y - b.y), f32(a.z - b.z))
end

local function dot(a: Vector3, b: Vector3): number
	return f32(f32(f32(a.x * b.x) + f32(a.y * b.y)) + f32(a.z * b.z))
end

local function cross(a: Vector3, b: Vector3): Vector3
	return vector.create(
		f32(f32(a.y * b.z) - f32(b.y * a.z)),
		f32(f32(a.z * b.x) - f32(b.z * a.x)),
		f32(f32(a.x * b.y) - f32(b.x * a.y))
	)
end

-- glam Vec3::try_normalize: 1 / length, годится только конечное и > 0.
local function try_normalize(v: Vector3): Vector3?
	local length = f32(math.sqrt(dot(v, v)))
	local recip = f32(1 / length)
	if rt.is_finite(recip) and recip > 0 then
		return vector.create(f32(v.x * recip), f32(v.y * recip), f32(v.z * recip))
	end
	return nil
end

-- ROBLOX: f32::clamp.
local function clamp(value: number, lo: number, hi: number): number
	if value < lo then
		return lo
	elseif value > hi then
		return hi
	end
	return value
end

-- Ключ сварки: координата в миллиметрах, `round` как в Rust (от нуля).
local function weld_key(p: Vector3, inverse: number): string
	local function r(v: number): number
		-- ROBLOX: f64::round округляет половину от нуля, как math.round.
		return math.round(v * inverse)
	end
	return string.format("%d,%d,%d", r(p.x), r(p.y), r(p.z))
end

-- Часть `pub(crate) fn collision_world(map, material)` без retail-архива:
-- возвращает треугольники мира в исходном порядке.
-- ROBLOX: Result<_, String> -> (значение) или (nil, ошибка).
function skate_world.collision_world_triangles(
	collision: { CollisionTriangle },
	material: contact.RetailContactMaterial
): ({ board_world.WorldTriangle }?, string?)
	-- Match the reference RW mesh compiler's 1 mm vertex welding and reversed
	-- edge pairing. Triangle diagonals are adjacency, never authored ledges.
	local welded: { [string]: number } = {}
	local positions: { Vector3 } = {}
	local vertices: { { number } } = {}
	local normals: { Vector3 } = {}
	local inverse = 1 / f32(0.001)
	for _, tri in collision do
		local ids = {}
		for corner = 1, 3 do
			local p = tri.points[corner]
			local key = weld_key(p, inverse)
			local id = welded[key]
			if id == nil then
				-- ROBLOX: id вершины с нуля, как индекс в Rust.
				id = #positions
				welded[key] = id
				table.insert(positions, p)
			end
			ids[corner] = id :: number
		end
		local a, b, c = tri.points[1], tri.points[2], tri.points[3]
		local normal = try_normalize(cross(sub(b, a), sub(c, a)))
		if normal == nil then
			return nil, "Invalid SKATE collision triangle normal"
		end
		table.insert(vertices, ids)
		table.insert(normals, normal)
	end
	local cosines: { { number } } = {}
	local flags: { number } = {}
	for i = 1, #vertices do
		cosines[i] = { 1.0, 1.0, 1.0 }
		flags[i] = bit32.bor(TriangleFeature.ONE_SIDED, TriangleFeature.USE_EDGE_COSINES, 0xe0)
	end
	-- В Roblox нет native_edges, поэтому смежность строится для всех граней.
	local open: { [string]: { number } } = {}
	for i, ids in vertices do
		for edge = 0, 2 do
			local a, b = ids[edge + 1], ids[(edge + 1) % 3 + 1]
			local reverse_key = b .. ":" .. a
			local found = open[reverse_key]
			if found ~= nil then
				open[reverse_key] = nil
				local other, oe = found[1], found[2]
				local cosine = clamp(dot(normals[i], normals[other]), -1, 1)
				local orientation = dot(sub(positions[b + 1], positions[a + 1]), cross(normals[i], normals[other]))
				-- ExtendedEdgeCosine / MakeEdgeCode in rw_collision_mesh.cpp:
				-- orientation >= -1e-6 is convex; flat edges have no convex bit.
				for _, pair in { { i, edge }, { other, oe } } do
					local ti, e = pair[1], pair[2]
					cosines[ti][e + 1] = cosine
					if orientation <= f32(-1.0e-6) or cosine >= 1 then
						flags[ti] = bit32.band(flags[ti], bit32.bnot(bit32.lshift(0x20, e)))
					end
				end
			else
				local key = a .. ":" .. b
				if open[key] == nil then
					open[key] = { i, edge }
				end
			end
		end
	end
	local adjacent: { { number } } = {}
	for v = 1, #positions do
		adjacent[v] = {}
	end
	for i, ids in vertices do
		for _, v in ids do
			table.insert(adjacent[v + 1], i)
		end
	end
	for v0, faces in adjacent do
		local v = v0 - 1
		local reference = normals[faces[1]]
		local all = true
		for _, i in faces do
			if math.abs(f32(dot(reference, normals[i]) - 1)) > f32(0.01) then
				all = false
				break
			end
		end
		if all then
			for _, i in faces do
				for corner = 0, 2 do
					if vertices[i][corner + 1] == v then
						flags[i] = bit32.bor(flags[i], bit32.lshift(0x200, corner))
					end
				end
			end
		end
	end
	local triangles: { board_world.WorldTriangle } = {}
	for i, source in collision do
		local points = {
			positions[vertices[i][1] + 1],
			positions[vertices[i][2] + 1],
			positions[vertices[i][3] + 1],
		}
		-- Keep the supplied game's original static-world contact combine values.
		local triangle = WorldTriangle.from_vertices(points, material, source.surface, flags[i], cosines[i], 0.0)
		if triangle == nil then
			return nil, "Invalid SKATE collision volume"
		end
		table.insert(triangles, triangle)
	end
	return triangles, nil
end

return skate_world
