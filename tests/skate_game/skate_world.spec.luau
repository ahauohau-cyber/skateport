--!strict
-- Проверка сборки мира: смежность рёбер куба и плоской сетки, контакт сферы
-- с верхней гранью. Без Roblox API: куб собирается вручную.

local harness = require("../harness")
local rt = require("../../src/rt")
local skate_world = require("../../src/skate_game/skate_world")
local primitive_query = require("../../src/skate_core/physics/world_contact/primitive_query")

local f32 = rt.f32

local MATERIAL = { static_friction = 0.0, dynamic_friction = 0.0, restitution = 1.0 }

-- Треугольник, повёрнутый лицом от точки center.
local function tri(a: vector, b: vector, c: vector, center: vector): skate_world.CollisionTriangle
	local n = vector.cross(b - a, c - a)
	if vector.dot(n, (a + b + c) / 3 - center) < 0 then
		b, c = c, b
	end
	return { points = { a, b, c }, surface = 0 }
end

local function cube(center: vector, half: number): { skate_world.CollisionTriangle }
	local function c(x: number, y: number, z: number): vector
		return center + vector.create(x * half, y * half, z * half)
	end
	local faces = {
		{ c(-1, 1, -1), c(1, 1, -1), c(1, 1, 1), c(-1, 1, 1) },
		{ c(-1, -1, -1), c(-1, -1, 1), c(1, -1, 1), c(1, -1, -1) },
		{ c(1, -1, -1), c(1, -1, 1), c(1, 1, 1), c(1, 1, -1) },
		{ c(-1, -1, -1), c(-1, 1, -1), c(-1, 1, 1), c(-1, -1, 1) },
		{ c(-1, -1, 1), c(-1, 1, 1), c(1, 1, 1), c(1, -1, 1) },
		{ c(-1, -1, -1), c(1, -1, -1), c(1, 1, -1), c(-1, 1, -1) },
	}
	local out = {}
	for _, f in faces do
		table.insert(out, tri(f[1], f[2], f[3], center))
		table.insert(out, tri(f[1], f[3], f[4], center))
	end
	return out
end

local function settings(): any
	-- crates/skate-game/src/physics/ground.rs, query_settings
	return {
		volume_padding = f32(0.05),
		maximum_separating_distance = 0.5,
		edge_cos_bend_normal_threshold = f32(0.999),
		convexity_epsilon = f32(0.01),
		is_object = false,
	}
end

return function(report: harness.Report)
	harness.test(report, "skate_world: куб — 12 треугольников, рёбра куба выпуклые, диагонали плоские", function()
		local triangles = skate_world.collision_world_triangles(cube(vector.zero, 1), MATERIAL)
		assert(triangles ~= nil)
		harness.check(#triangles == 12, "count " .. #triangles)
		local convex, flat = 0, 0
		for _, t in triangles do
			local feature = t.triangle.feature
			harness.check(t.triangle.feature.normal ~= vector.zero, "normal")
			for e = 0, 2 do
				local cosine = feature.edge_cosines[e + 1]
				local is_convex = bit32.band(feature.flags, bit32.lshift(0x20, e)) ~= 0
				if cosine >= 1 then
					flat += 1
					harness.check(not is_convex, "диагональ помечена выпуклой")
				else
					convex += 1
					harness.check(is_convex and math.abs(cosine) < 1e-6, "ребро куба")
				end
			end
			-- углы куба не плоские
			harness.check(bit32.band(feature.flags, 0xE00) == 0, "vertex flags")
		end
		harness.check(convex == 24 and flat == 12, string.format("convex %d flat %d", convex, flat))
	end)

	harness.test(report, "skate_world: плоская сетка — все вершины плоские (все грани у вершины в одной плоскости)", function()
		local quads = {}
		for i = 0, 1 do
			for j = 0, 1 do
				local function p(x: number, z: number): vector
					return vector.create(i + x, 0, j + z)
				end
				local below = vector.create(i + 0.5, -1, j + 0.5)
				table.insert(quads, tri(p(0, 0), p(1, 0), p(1, 1), below))
				table.insert(quads, tri(p(0, 0), p(1, 1), p(0, 1), below))
			end
		end
		local triangles = skate_world.collision_world_triangles(quads, MATERIAL)
		assert(triangles ~= nil)
		local flagged = 0
		for _, t in triangles do
			harness.check(t.triangle.feature.normal.y > 0.99, "нормаль вверх")
			for corner = 0, 2 do
				if bit32.band(t.triangle.feature.flags, bit32.lshift(0x200, corner)) ~= 0 then
					flagged += 1
				end
			end
		end
		harness.check(flagged == 24, "flagged " .. flagged)
	end)

	harness.test(report, "skate_world: сфера над кубом касается верхней грани", function()
		local triangles = skate_world.collision_world_triangles(cube(vector.zero, 1), MATERIAL)
		assert(triangles ~= nil)
		local radius = f32(0.3)
		local sphere = { kind = "Sphere", sphere = { center = vector.create(0.2, f32(1.3), 0.1), radius = radius } }
		local hits = 0
		for _, t in triangles do
			local m = primitive_query.primitive_triangle_world_contacts(sphere :: any, t.triangle, vector.create(0, -1, 0), settings())
			if m ~= nil then
				hits += 1
				harness.check(math.abs(m.normal.y) > 0.99, "нормаль контакта вертикальна")
			end
		end
		harness.check(hits >= 1, "нет контакта")
		-- далеко над кубом контакта нет
		local far = { kind = "Sphere", sphere = { center = vector.create(0, 5, 0), radius = radius } }
		for _, t in triangles do
			harness.check(primitive_query.primitive_triangle_world_contacts(far :: any, t.triangle, vector.zero, settings()) == nil, "лишний контакт")
		end
	end)
end
