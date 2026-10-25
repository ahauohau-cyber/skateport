--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: треугольники столкновений для того, что нельзя разложить формулой:
--   * Terrain          — карта высот из лучей Roblox (вода пропускается);
--   * MeshPart         — настоящие треугольники меша через EditableMesh
--                        (AssetService:CreateEditableMeshAsync, как в примерочном
--                        плейсе); если меш чужой и Roblox его не отдаёт —
--                        карта высот по детали;
--   * Union, CornerWedge, Truss и прочее — карта высот по детали.
-- Карта высот: сетка лучей сверху вниз только по этой детали (RaycastParams
-- Include), четырёхугольники между попаданиями + «юбка» вниз по краям, чтобы
-- в бок детали можно было врезаться. Нависания (низ моста, тоннели) не видны —
-- для скейта важна верхняя поверхность.
-- Все точки — в метрах (1 стад = 0.28 м), лицевая сторона — наружу/вверх.

local AssetService = game:GetService("AssetService")

local world_scan = {}

local M = 0.28

export type Triangle = { points: { vector }, surface: number }

local function to_m(p: Vector3): vector
	return vector.create(p.X * M, p.Y * M, p.Z * M)
end

-- Треугольник с нормалью, смотрящей по направлению hint (если задан).
local function push(out: { Triangle }, a: Vector3, b: Vector3, c: Vector3, hint: Vector3?)
	local n = (b - a):Cross(c - a)
	if n.Magnitude < 1e-6 then
		return
	end
	if hint and n:Dot(hint) < 0 then
		b, c = c, b
	end
	table.insert(out, { points = { to_m(a), to_m(b), to_m(c) }, surface = 0 })
end

-- Сетка высот: heights[i][j] = Y попадания или nil. x0,z0 — угол, step — шаг.
-- bottom — нижняя отметка «юбки» (nil — без юбки).
local function grid_triangles(heights: { { number | false } }, x0: number, z0: number, step: number, nx: number, nz: number, bottom: number?): { Triangle }
	local out = {}
	local function h(i: number, j: number): number?
		local row = heights[i]
		if row == nil then
			return nil
		end
		local v = row[j]
		return if v then v else nil
	end
	local function p(i: number, j: number, y: number): Vector3
		return Vector3.new(x0 + (i - 1) * step, y, z0 + (j - 1) * step)
	end
	local up = Vector3.yAxis
	for i = 1, nx - 1 do
		for j = 1, nz - 1 do
			local a, b, c, d = h(i, j), h(i + 1, j), h(i + 1, j + 1), h(i, j + 1)
			if a and b and c and d then
				-- Диагональ выбираем по меньшему излому.
				if math.abs(a - c) <= math.abs(b - d) then
					push(out, p(i, j, a), p(i + 1, j, b), p(i + 1, j + 1, c), up)
					push(out, p(i, j, a), p(i + 1, j + 1, c), p(i, j + 1, d), up)
				else
					push(out, p(i, j, a), p(i + 1, j, b), p(i, j + 1, d), up)
					push(out, p(i + 1, j, b), p(i + 1, j + 1, c), p(i, j + 1, d), up)
				end
			elseif bottom == nil then
				-- Край без юбки: берём хотя бы три точки.
				local pts = {}
				for _, q in { { i, j, a }, { i + 1, j, b }, { i + 1, j + 1, c }, { i, j + 1, d } } do
					if q[3] then
						table.insert(pts, p(q[1] :: number, q[2] :: number, q[3] :: number))
					end
				end
				if #pts == 3 then
					push(out, pts[1], pts[2], pts[3], up)
				end
			end
		end
	end
	if bottom ~= nil then
		-- Юбка: вертикальная стенка там, где у ячейки с поверхностью нет соседа.
		for i = 1, nx do
			for j = 1, nz do
				local y = h(i, j)
				if y then
					for _, dir in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
						local ni, nj = i + dir[1], j + dir[2]
						if h(ni, nj) == nil then
							-- Стенка на полшага наружу, шириной в шаг.
							local centre = p(i, j, y) + Vector3.new(dir[1], 0, dir[2]) * (step / 2)
							local side = Vector3.new(dir[2], 0, -dir[1]) * (step / 2)
							local outward = Vector3.new(dir[1], 0, dir[2])
							local top_a, top_b = centre - side, centre + side
							local low_a = Vector3.new(top_a.X, math.min(bottom, y - 0.05), top_a.Z)
							local low_b = Vector3.new(top_b.X, math.min(bottom, y - 0.05), top_b.Z)
							push(out, top_a, top_b, low_b, outward)
							push(out, top_a, low_b, low_a, outward)
						end
					end
				end
			end
		end
	end
	return out
end

-- Лучи сверху вниз по сетке. include — список экземпляров, по которым бить.
local function scan(include: { Instance }, x0: number, z0: number, nx: number, nz: number, step: number, top: number, depth: number, yield: (() -> ())?): { { number | false } }
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = include
	params.IgnoreWater = true
	local heights = table.create(nx)
	local direction = Vector3.new(0, -depth, 0)
	local count = 0
	for i = 1, nx do
		local row = table.create(nz, false)
		local x = x0 + (i - 1) * step
		for j = 1, nz do
			local hit = workspace:Raycast(Vector3.new(x, top, z0 + (j - 1) * step), direction, params)
			if hit then
				row[j] = hit.Position.Y
			end
			count += 1
		end
		heights[i] = row
		if yield and count > 20000 then
			count = 0
			yield()
		end
	end
	return heights
end

-- Terrain вокруг centre в квадрате 2*radius стадов, шаг step стадов.
function world_scan.terrain(centre: Vector3, radius: number, step: number, yield: (() -> ())?): { Triangle }
	local terrain = workspace.Terrain
	local n = math.floor(radius * 2 / step) + 1
	local x0 = centre.X - radius
	local z0 = centre.Z - radius
	local top = centre.Y + 1024
	local heights = scan({ terrain }, x0, z0, n, n, step, top, 2048, yield)
	return grid_triangles(heights, x0, z0, step, n, n, nil)
end

-- Карта высот по одной детали (ось-выровненная сетка по её мировому AABB).
function world_scan.part_heightfield(part: BasePart): { Triangle }
	local cf, size = part.CFrame, part.Size
	local corners = {}
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				table.insert(corners, cf:PointToWorldSpace(Vector3.new(sx * size.X, sy * size.Y, sz * size.Z) / 2))
			end
		end
	end
	local lo, hi = corners[1], corners[1]
	for _, c in corners do
		lo = lo:Min(c)
		hi = hi:Max(c)
	end
	local extent = hi - lo
	-- Шаг: ~32 точки по длинной стороне, но не мельче 0.5 и не крупнее 2 стадов.
	local step = math.clamp(math.max(extent.X, extent.Z) / 32, 0.5, 2)
	local nx = math.max(2, math.ceil(extent.X / step) + 1)
	local nz = math.max(2, math.ceil(extent.Z / step) + 1)
	-- Сетку растягиваем ровно на AABB.
	local sx, sz = extent.X / (nx - 1), extent.Z / (nz - 1)
	step = math.max(sx, sz)
	nx = math.ceil(extent.X / step) + 1
	nz = math.ceil(extent.Z / step) + 1
	local heights = scan({ part }, lo.X, lo.Z, nx, nz, step, hi.Y + 1, extent.Y + 2, nil)
	return grid_triangles(heights, lo.X, lo.Z, step, nx, nz, lo.Y)
end

-- Кэш мешей по MeshId: треугольники в пространстве меша или false (не отдали).
local mesh_cache: { [string]: { { Vector3 } } | false } = {}

local function mesh_faces(part: MeshPart): { { Vector3 } }?
	local key = part.MeshId
	local cached = mesh_cache[key]
	if cached ~= nil then
		return if cached then cached else nil
	end
	local ok, mesh = pcall(function()
		return AssetService:CreateEditableMeshAsync(part.MeshContent)
	end)
	if not ok or mesh == nil then
		mesh_cache[key] = false
		return nil
	end
	local all = mesh:GetFaces()
	if #all > 30000 then
		-- Слишком тяжёлый меш для столкновений — пусть будет карта высот.
		mesh:Destroy()
		mesh_cache[key] = false
		return nil
	end
	local faces = {}
	for _, face in all do
		local ids = mesh:GetFaceVertices(face)
		if #ids == 3 then
			table.insert(faces, { mesh:GetPosition(ids[1]), mesh:GetPosition(ids[2]), mesh:GetPosition(ids[3]) })
		end
	end
	mesh:Destroy()
	mesh_cache[key] = faces
	return faces
end

-- Треугольники MeshPart: настоящие (EditableMesh) или карта высот.
function world_scan.mesh_part(part: MeshPart): { Triangle }
	local faces = mesh_faces(part)
	if faces == nil then
		return world_scan.part_heightfield(part)
	end
	-- Вершины меша в его исходных единицах; деталь растягивает их Size / MeshSize.
	local mesh_size = part.MeshSize
	local scale = Vector3.new(
		if mesh_size.X > 0 then part.Size.X / mesh_size.X else 1,
		if mesh_size.Y > 0 then part.Size.Y / mesh_size.Y else 1,
		if mesh_size.Z > 0 then part.Size.Z / mesh_size.Z else 1
	)
	local cf = part.CFrame
	local out = {}
	for _, f in faces do
		local a = cf:PointToWorldSpace(f[1] * scale)
		local b = cf:PointToWorldSpace(f[2] * scale)
		local c = cf:PointToWorldSpace(f[3] * scale)
		-- Порядок вершин меша Roblox — против часовой снаружи, как нужно ядру.
		push(out, a, b, c, nil)
	end
	return out
end

return world_scan
