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

-- Собрать SkateMap из всех деталей под root. spawn — точка в стадах, где
-- доска встаёт колёсами на землю; heading — поворот вокруг Y (радианы).
function world_map.build(root: Instance, spawn: Vector3, heading: number, filter: ((BasePart) -> boolean)?): BuildResult
	local accept = filter or world_map.default_filter
	local collision = {}
	local rails = {}
	local skipped = {}
	for _, item in root:GetDescendants() do
		if item:IsA("BasePart") then
			if is_rail(item) then
				table.insert(rails, { name = item:GetFullName(), closed = false, points = rail_points(item), native = nil })
			end
			if accept(item) then
				local triangles = part_shapes.part_triangles(item)
				if triangles == nil then
					table.insert(skipped, item)
				else
					for _, t in triangles do
						local p = t.points
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
			end
		end
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
