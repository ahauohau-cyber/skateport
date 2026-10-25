--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: карта SKATE (crates/skate-data/src/skate_map.rs, SkateMap) из деталей плейса.
--
-- В Rust карта приходит из файла .skate: треугольники столкновений, рельсы
-- для грайнда, точка появления. Здесь мы собираем ту же структуру из
-- Workspace, и дальше её ест родной skate_world.collision_world и
-- grind_world.StaticProvider без изменений.
--
-- Как пометить, по чему можно грайндить (рельсы, перила, края скамеек):
--   * тег CollectionService "SkateRail" на детали, или
--   * атрибут SkateRail = true.
-- Рельс идёт по самой длинной оси детали, по верхнему краю.
-- Детали с атрибутом SkateIgnore = true скейт не видит.

local CollectionService = game:GetService("CollectionService")

local part_shapes = require(script.Parent.Parent.part_shapes)
local world_scan = require(script.Parent.world_scan)
local edge_flags = require(script.Parent.edge_flags)

local world_map = {}

local M = part_shapes.METRES_PER_STUD

world_map.RAIL_TAG = "SkateRail"

-- Детали, которые скейт должен видеть: твёрдые, не персонажи и не наша доска.
function world_map.default_filter(part: BasePart): boolean
	if not part.CanCollide or part:GetAttribute("SkateIgnore") == true then
		return false
	end
	local model = part:FindFirstAncestorOfClass("Model")
	while model ~= nil do
		if model:FindFirstChildOfClass("Humanoid") ~= nil or model:GetAttribute("SkateIgnore") == true then
			return false
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return true
end

local function is_rail(part: BasePart): boolean
	return CollectionService:HasTag(part, world_map.RAIL_TAG) or part:GetAttribute("SkateRail") == true
end

-- Рельс: отрезок по самой длинной оси детали, поднятый до её верха.
local function rail_points(part: BasePart): { { number } }
	local size = part.Size
	local cf = part.CFrame
	local axis: Vector3, half: number
	if size.X >= size.Y and size.X >= size.Z then
		axis, half = cf.RightVector, size.X / 2
	elseif size.Z >= size.Y then
		axis, half = cf.LookVector, size.Z / 2
	else
		axis, half = cf.UpVector, size.Y / 2
	end
	-- Высота верха над центром: проекция полуразмеров (кроме оси рельса) на мировой Y.
	local height = 0
	for _, pair in { { cf.RightVector, size.X }, { cf.UpVector, size.Y }, { cf.LookVector, size.Z } } do
		if math.abs(pair[1]:Dot(axis)) < 0.99 then
			height += math.abs(pair[1].Y) * pair[2] / 2
		end
	end
	local centre = cf.Position + Vector3.new(0, height, 0)
	local a, b = centre - axis * half, centre + axis * half
	return { { a.X * M, a.Y * M, a.Z * M }, { b.X * M, b.Y * M, b.Z * M } }
end

-- Одна запись материала: категория поверхности 0, как в тестовом уровне
-- Rust (physics/ground.rs build_world: material0/category0).
local function default_material(): any
	return {
		name = "roblox",
		flags = 0,
		friction = 0.5,
		restitution = 0,
		color = { 1, 1, 1 },
		roughness = 1,
		emissive = 0,
		textures = { 0, 0, 0, 0, 0 },
		indirect_strength = 1,
		alpha_mode = 0,
		alpha_cutoff = 0,
		audio = 0,
		physics = 0,
		pattern = 0,
		depth_layer = nil,
		retail_definition = nil,
	}
end

export type BuildResult = {
	map: any,
	triangles: number,
	rails: number,
	skipped: { BasePart },
}

export type Options = {
	filter: ((BasePart) -> boolean)?,
	radius: number?, -- стады от spawn: детали дальше не берём (по умолчанию 600)
	terrain_radius: number?, -- стады: квадрат Terrain вокруг spawn (по умолчанию 220)
	terrain_step: number?, -- стады: шаг сетки Terrain (по умолчанию 2)
	edge_flags: boolean?, -- false — отдать рёбра ядру как есть
	yield: (() -> ())?,
	log: ((string) -> ())?,
}

-- Треугольники одной детали любым доступным способом.
local function part_triangles(part: BasePart): { any }
	local exact = part_shapes.part_triangles(part)
	if exact ~= nil then
		return exact
	end
	if part:IsA("MeshPart") then
		return world_scan.mesh_part(part)
	end
	return world_scan.part_heightfield(part)
end

-- Ядро сваривает вершины ближе 1 мм и отвергает вырожденные треугольники
-- ("Invalid SKATE collision volume"), поэтому слишком мелкие отбрасываем сами.
local MIN_EDGE = 0.003 -- м
local function valid(p: { vector }): boolean
	local a, b, c = p[1], p[2], p[3]
	if vector.magnitude(b - a) < MIN_EDGE or vector.magnitude(c - b) < MIN_EDGE or vector.magnitude(a - c) < MIN_EDGE then
		return false
	end
	local n = vector.cross(b - a, c - a)
	local area = vector.magnitude(n)
	-- Иглы (почти нулевая площадь при длинных рёбрах) тоже не нужны.
	return area > 1e-6 and area == area
end

local function add(collision: { any }, triangles: { any })
	for _, t in triangles do
		local p = t.points
		if not valid(p) then
			continue
		end
		table.insert(collision, {
			points = {
				{ p[1].x, p[1].y, p[1].z },
				{ p[2].x, p[2].y, p[2].z },
				{ p[3].x, p[3].y, p[3].z },
			},
			surface = t.surface,
			material = 1,
			native_edges = nil,
		})
	end
end

-- Расстояние от точки до AABB детали (стады).
local function distance_to(part: BasePart, point: Vector3): number
	local half = part.Size.Magnitude / 2
	return math.max(0, (part.Position - point).Magnitude - half)
end

-- Собрать SkateMap: детали в радиусе от spawn (стады), Terrain вокруг, рельсы.
-- heading — поворот доски вокруг Y (радианы).
function world_map.build(root: Instance, spawn: Vector3, heading: number, options: Options?): BuildResult
	local opts: Options = options or {}
	local accept = opts.filter or world_map.default_filter
	local radius = opts.radius or 600
	local yield = opts.yield
	local collision = {}
	local rails = {}
	local skipped = {}
	local count = 0
	for _, item in root:GetDescendants() do
		if item:IsA("BasePart") and item ~= workspace.Terrain and distance_to(item, spawn) <= radius then
			if is_rail(item) then
				table.insert(rails, { name = item:GetFullName(), closed = false, points = rail_points(item), native = nil })
			end
			if accept(item) then
				local ok, triangles = pcall(part_triangles, item)
				if ok then
					add(collision, triangles)
				else
					table.insert(skipped, item)
				end
				count += 1
				if yield and count % 200 == 0 then
					yield()
				end
			end
		end
	end
	local parts_triangles = #collision
	-- Terrain: только если в нём что-то есть.
	local terrain = workspace.Terrain
	local has_terrain = false
	pcall(function()
		has_terrain = terrain:CountCells() > 0
	end)
	if has_terrain then
		add(collision, world_scan.terrain(spawn, opts.terrain_radius or 220, opts.terrain_step or 2, yield))
	end
	-- Рёбра на стыках деталей (клин на полу, блоки встык) — не острые края.
	if opts.edge_flags ~= false then
		edge_flags.compute(collision, yield)
	end
	if opts.log then
		opts.log(string.format("[skate3] карта: детали %d треуг., terrain %d треуг., рельсов %d", parts_triangles, #collision - parts_triangles, #rails))
	end
	local map = {
		version = 1,
		name = "roblox",
		spawn = { spawn.X * M, spawn.Y * M, spawn.Z * M },
		heading = heading,
		environment = {},
		materials = { default_material() },
		textures = {},
		geometry = { vertices = {}, indices = {}, collision = collision },
		rails = rails,
		doors = {},
		lights = {},
		routes = {},
		extensions = {},
	}
	return { map = map, triangles = #collision, rails = #rails, skipped = skipped }
end

return world_map
