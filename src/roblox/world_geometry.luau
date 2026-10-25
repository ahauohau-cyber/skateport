--!strict
-- ROBLOX: геометрия мира из деталей плейса. В Rust её даёт карта SKATE
-- (crates/skate-game/src/skate_world.rs, collision_world) или тестовый уровень
-- (crates/skate-game/src/physics/ground.rs). Здесь — то же, но из BasePart:
-- каждую деталь раскладываем на треугольники в метрах, наружу лицевой стороной,
-- и отдаём в skate_world.collision_world_triangles, который строит смежность
-- рёбер ровно как Rust-хост.
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine

local skate_world = require("../skate_game/skate_world")
local contact = require("../skate_core/physics/contact")
local board_world = require("../skate_core/physics/board_world")

local world_geometry = {}

-- ROBLOX: физика Skate 3 настроена в метрах, Roblox меряет в стадах.
-- Официально 1 стад = 0.28 м. Все позиции переводятся этим множителем
-- на входе в симуляцию и обратно на выходе.
-- TODO: сверить масштаб с ростом R15-аватара (5 стадов = 1.4 м против 1.8 м у скейтера).
world_geometry.METRES_PER_STUD = 0.28

-- Материал статического мира — как floor_material в
-- crates/skate-game/src/physics/settings.rs: Ground job 8277C5D8 берёт
-- контекст 83034F34/38/3C, а комбинирование max/max/min оставляет материал
-- движущегося тела.
function world_geometry.floor_material(): contact.RetailContactMaterial
	return { static_friction = 0.0, dynamic_friction = 0.0, restitution = 1.0 }
end

local part_shapes = require(script.Parent.part_shapes)

function world_geometry.part_triangles(part: BasePart, surface: number?): { skate_world.CollisionTriangle }?
	return part_shapes.part_triangles(part, surface) :: any
end

-- Детали, которые скейт должен видеть: твёрдые и не принадлежащие персонажам.
function world_geometry.default_filter(part: BasePart): boolean
	if not part.CanCollide then
		return false
	end
	local model = part:FindFirstAncestorOfClass("Model")
	if model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil then
		return false
	end
	return true
end

-- Собрать мир из всех деталей под root (обычно workspace) — BoardWorld с
-- метаданными широкой фазы, как collision_world в Rust.
-- Треугольники идут без отбора по расстоянию: дальние кластеры по 64 треугольника
-- отсекает broadphase BoardWorld до узкой фазы.
-- Возвращает мир и список пропущенных деталей с неизвестной формой.
function world_geometry.collect(
	root: Instance,
	filter: ((BasePart) -> boolean)?
): (board_world.BoardWorld?, string? | { BasePart })
	local accept = filter or world_geometry.default_filter
	local collision: { skate_world.CollisionTriangle } = {}
	local skipped: { BasePart } = {}
	for _, item in root:GetDescendants() do
		if item:IsA("BasePart") and accept(item) then
			local triangles = world_geometry.part_triangles(item)
			if triangles == nil then
				table.insert(skipped, item)
			else
				table.move(triangles, 1, #triangles, #collision + 1, collision)
			end
		end
	end
	local world, err = skate_world.collision_world(collision, world_geometry.floor_material())
	if world == nil then
		return nil, err
	end
	return world, skipped
end

return world_geometry
