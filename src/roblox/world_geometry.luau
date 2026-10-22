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

-- Тег поверхности. В SKATE-карте это код материала; в Roblox пока один тег 0.
-- TODO: сопоставить Enum.Material (Water, Ice, Grass...) с retail-тегами поверхностей.
local DEFAULT_SURFACE = 0

-- Число сегментов окружности при разбиении цилиндра и шара.
local CYLINDER_SEGMENTS = 16
local BALL_RINGS = 8

type Face = { Vector3 }

-- Грани деталей в локальных координатах (стады), центр детали в нуле.
local function block_faces(size: Vector3): { Face }
	local x, y, z = size.X / 2, size.Y / 2, size.Z / 2
	local function c(sx: number, sy: number, sz: number): Vector3
		return Vector3.new(sx * x, sy * y, sz * z)
	end
	return {
		{ c(-1, 1, -1), c(1, 1, -1), c(1, 1, 1), c(-1, 1, 1) }, -- верх
		{ c(-1, -1, -1), c(-1, -1, 1), c(1, -1, 1), c(1, -1, -1) }, -- низ
		{ c(1, -1, -1), c(1, -1, 1), c(1, 1, 1), c(1, 1, -1) }, -- +X
		{ c(-1, -1, -1), c(-1, 1, -1), c(-1, 1, 1), c(-1, -1, 1) }, -- -X
		{ c(-1, -1, 1), c(-1, 1, 1), c(1, 1, 1), c(1, -1, 1) }, -- +Z
		{ c(-1, -1, -1), c(1, -1, -1), c(1, 1, -1), c(-1, 1, -1) }, -- -Z
	}
end

-- WedgePart: низ и задняя стенка (+Z) полные, скат идёт от верха при +Z
-- к низу при -Z и смотрит вперёд-вверх (LookVector детали = -Z).
local function wedge_faces(size: Vector3): { Face }
	local x, y, z = size.X / 2, size.Y / 2, size.Z / 2
	local function c(sx: number, sy: number, sz: number): Vector3
		return Vector3.new(sx * x, sy * y, sz * z)
	end
	return {
		{ c(-1, -1, -1), c(-1, -1, 1), c(1, -1, 1), c(1, -1, -1) }, -- низ
		{ c(-1, -1, 1), c(-1, 1, 1), c(1, 1, 1), c(1, -1, 1) }, -- зад +Z
		{ c(-1, -1, -1), c(1, -1, -1), c(1, 1, 1), c(-1, 1, 1) }, -- скат
		{ c(1, -1, -1), c(1, -1, 1), c(1, 1, 1) }, -- бок +X
		{ c(-1, -1, -1), c(-1, 1, 1), c(-1, -1, 1) }, -- бок -X
	}
end

-- Цилиндр Roblox: ось вдоль X, диаметр — меньшее из Y и Z.
local function cylinder_faces(size: Vector3): { Face }
	local half = size.X / 2
	local radius = math.min(size.Y, size.Z) / 2
	local ring = {}
	for i = 0, CYLINDER_SEGMENTS - 1 do
		local angle = 2 * math.pi * i / CYLINDER_SEGMENTS
		ring[i + 1] = { math.cos(angle) * radius, math.sin(angle) * radius }
	end
	local faces = {}
	local cap_pos, cap_neg = {}, {}
	for i = 1, CYLINDER_SEGMENTS do
		local a = ring[i]
		local b = ring[i % CYLINDER_SEGMENTS + 1]
		table.insert(faces, {
			Vector3.new(-half, a[1], a[2]),
			Vector3.new(half, a[1], a[2]),
			Vector3.new(half, b[1], b[2]),
			Vector3.new(-half, b[1], b[2]),
		})
		table.insert(cap_pos, Vector3.new(half, a[1], a[2]))
		table.insert(cap_neg, Vector3.new(-half, a[1], a[2]))
	end
	table.insert(faces, cap_pos)
	table.insert(faces, cap_neg)
	return faces
end

-- Шар Roblox: диаметр — меньшая сторона детали.
local function ball_faces(size: Vector3): { Face }
	local radius = math.min(size.X, size.Y, size.Z) / 2
	local segments = CYLINDER_SEGMENTS
	local function point(ring: number, i: number): Vector3
		local theta = math.pi * ring / BALL_RINGS
		local phi = 2 * math.pi * i / segments
		return Vector3.new(
			math.sin(theta) * math.cos(phi) * radius,
			math.cos(theta) * radius,
			math.sin(theta) * math.sin(phi) * radius
		)
	end
	local faces = {}
	for ring = 0, BALL_RINGS - 1 do
		for i = 0, segments - 1 do
			local a, b = point(ring, i), point(ring, i + 1)
			local c, d = point(ring + 1, i + 1), point(ring + 1, i)
			if ring == 0 then
				table.insert(faces, { a, c, d })
			elseif ring == BALL_RINGS - 1 then
				table.insert(faces, { a, b, d })
			else
				table.insert(faces, { a, b, c, d })
			end
		end
	end
	return faces
end

-- Грани детали или nil, если форма пока не поддерживается.
local function part_faces(part: BasePart): { Face }?
	if part:IsA("WedgePart") then
		return wedge_faces(part.Size)
	elseif part:IsA("Part") then
		local shape = (part :: Part).Shape
		if shape == Enum.PartType.Block then
			return block_faces(part.Size)
		elseif shape == Enum.PartType.Wedge then
			return wedge_faces(part.Size)
		elseif shape == Enum.PartType.Cylinder then
			return cylinder_faces(part.Size)
		elseif shape == Enum.PartType.Ball then
			return ball_faces(part.Size)
		end
	end
	-- TODO: CornerWedgePart, MeshPart, UnionOperation и Terrain.
	return nil
end

-- Треугольники одной детали в мировых метрах. Лицевая сторона (нормаль
-- (b - a) x (c - a), как в triangle_from_volume) всегда наружу: деталь выпуклая,
-- поэтому сравниваем нормаль с направлением от внутренней точки детали.
function world_geometry.part_triangles(part: BasePart, surface: number?): { skate_world.CollisionTriangle }?
	local faces = part_faces(part)
	if faces == nil then
		return nil
	end
	local cf = part.CFrame
	local scale = world_geometry.METRES_PER_STUD
	-- Внутренняя точка — среднее всех вершин: для выпуклой детали оно строго
	-- внутри. Центр детали не годится: скат клина проходит прямо через него.
	local sum, count = Vector3.zero, 0
	for _, face in faces do
		for _, p in face do
			sum += p
			count += 1
		end
	end
	local interior = sum / count
	local out = {}
	for _, face in faces do
		for k = 2, #face - 1 do
			local a, b, c = face[1], face[k], face[k + 1]
			local normal = (b - a):Cross(c - a)
			if normal.Magnitude > 1e-9 then
				if normal:Dot((a + b + c) / 3 - interior) < 0 then
					b, c = c, b
				end
				local function world(p: Vector3): vector
					local w = cf:PointToWorldSpace(p)
					return vector.create(w.X * scale, w.Y * scale, w.Z * scale)
				end
				table.insert(out, { points = { world(a), world(b), world(c) }, surface = surface or DEFAULT_SURFACE })
			end
		end
	end
	return out
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

-- Собрать мир из всех деталей под root (обычно workspace).
-- Треугольники идут без отбора по расстоянию: лишние контакты с дальними
-- и задними гранями отсекает broadphase BoardWorld до узкой фазы.
-- Возвращает треугольники мира и список пропущенных деталей с неизвестной формой.
function world_geometry.collect(
	root: Instance,
	filter: ((BasePart) -> boolean)?
): ({ board_world.WorldTriangle }?, string? | { BasePart })
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
	local triangles, err = skate_world.collision_world_triangles(collision, world_geometry.floor_material())
	if triangles == nil then
		return nil, err
	end
	return triangles, skipped
end

return world_geometry
