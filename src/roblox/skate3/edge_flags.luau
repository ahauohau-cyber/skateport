--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: флаги рёбер треугольников (native_edges карты SKATE), чтобы доска
-- не цеплялась за «внутренние» рёбра на стыках деталей.
--
-- В ядре (skate_world.collision_world) у ребра есть флаг «выпуклое» — по нему
-- колесо может удариться о ребро. Ядро ставит флаг всем рёбрам, у которых нет
-- соседнего треугольника с теми же вершинами. В картах Skate 3 стыки сшиты,
-- а у деталей Roblox — нет: клин стоит на полу, его нижнее ребро лежит на
-- плоскости пола, но вершины не общие. Ядро считает это ребро острым краем,
-- и доска «спотыкается» о начало клина, швы между блоками и т. д.
--
-- Здесь мы сами считаем то же, что ядро (сварка вершин 1 мм, пары рёбер,
-- косинус и выпуклость), и добавляем одно правило: ребро без пары, которое
-- лежит на поверхности другого треугольника, — не край, а шов; флаг снимаем.
-- Результат кодируем в native_edges (формат decode_native_edges ядра), тогда
-- ядро берёт наши флаги как есть.

local edge_flags = {}

type V = { number } -- {x, y, z}, метры
export type Triangle = { points: { V }, surface: number, material: number, native_edges: { number }? }

local WELD = 0.001 -- м, как в collision_world
local ON_PLANE = 0.01 -- м: ребро «лежит» на плоскости соседа
local CELL = 2.0 -- м: ячейка пространственной сетки

local function sub(a: V, b: V): V
	return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end
local function dot(a: V, b: V): number
	return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end
local function cross(a: V, b: V): V
	return { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] }
end
local function normalize(a: V): V
	local l = math.sqrt(dot(a, a))
	if l < 1e-12 then
		return { 0, 1, 0 }
	end
	return { a[1] / l, a[2] / l, a[3] / l }
end

-- Код угла ребра: косинус = 1 - pi^2 / (8 << code) (decode_native_edges).
local function angle_code(cosine: number): number
	local gap = 1 - cosine
	if gap <= 0 then
		return 27
	end
	local code = math.floor(math.log(1.2337005 / gap, 2) + 0.5)
	return math.clamp(code, 0, 27)
end

-- Точка p на треугольнике t (в пределах tol от плоскости и внутри с допуском)?
local function on_triangle(p: V, a: V, b: V, c: V, n: V, tol: number): boolean
	if math.abs(dot(sub(p, a), n)) > tol then
		return false
	end
	-- Барицентрическая проверка с небольшим запасом по краям.
	local v0, v1, v2 = sub(c, a), sub(b, a), sub(p, a)
	local d00, d01, d11 = dot(v0, v0), dot(v0, v1), dot(v1, v1)
	local d20, d21 = dot(v2, v0), dot(v2, v1)
	local denom = d00 * d11 - d01 * d01
	if math.abs(denom) < 1e-18 then
		return false
	end
	local u = (d11 * d20 - d01 * d21) / denom
	local v = (d00 * d21 - d01 * d20) / denom
	local eps = 0.002
	return u >= -eps and v >= -eps and u + v <= 1 + eps
end

-- Посчитать native_edges для всех треугольников (в месте, поле native_edges).
function edge_flags.compute(triangles: { Triangle }, yield: (() -> ())?)
	local n = #triangles
	-- 1. Сварка вершин и нормали.
	local ids: { { number } } = table.create(n)
	local key_to_id: { [string]: number } = {}
	local positions: { V } = {}
	local normals: { V } = table.create(n)
	local inv = 1 / WELD
	for i, t in triangles do
		local tri = table.create(3)
		for k = 1, 3 do
			local p = t.points[k]
			local key = string.format("%d,%d,%d", math.round(p[1] * inv), math.round(p[2] * inv), math.round(p[3] * inv))
			local id = key_to_id[key]
			if id == nil then
				table.insert(positions, p)
				id = #positions
				key_to_id[key] = id
			end
			tri[k] = id
		end
		ids[i] = tri
		local p = t.points
		normals[i] = normalize(cross(sub(p[2], p[1]), sub(p[3], p[1])))
	end

	-- 2. Пары рёбер (обратные направления), как в ядре.
	local cosines: { { number } } = table.create(n)
	local convex: { { boolean } } = table.create(n)
	local partner: { { number } } = table.create(n) -- соседний треугольник по ребру (0 — нет)
	for i = 1, n do
		cosines[i] = { 1, 1, 1 }
		convex[i] = { true, true, true }
		partner[i] = { 0, 0, 0 }
	end
	local open: { [string]: { number } } = {}
	for i = 1, n do
		local tri = ids[i]
		for j = 1, 3 do
			local a, b = tri[j], tri[j % 3 + 1]
			local back = b .. "," .. a
			local other = open[back]
			if other then
				open[back] = nil
				local oi, oj = other[1], other[2]
				local c = math.clamp(dot(normals[i], normals[oi]), -1, 1)
				local orientation = dot(sub(positions[b], positions[a]), cross(normals[i], normals[oi]))
				local is_convex = not (orientation <= -1e-6 or c >= 1)
				cosines[i][j], cosines[oi][oj] = c, c
				convex[i][j], convex[oi][oj] = is_convex, is_convex
				partner[i][j], partner[oi][oj] = oi, i
			else
				local fwd = a .. "," .. b
				if open[fwd] == nil then
					open[fwd] = { i, j }
				end
			end
		end
		if yield and i % 5000 == 0 then
			yield()
		end
	end

	-- 3. Сетка по XZ для поиска «подпирающих» треугольников.
	local grid: { [string]: { number } } = {}
	local function cell(x: number, z: number): string
		return math.floor(x / CELL) .. "," .. math.floor(z / CELL)
	end
	for i, t in triangles do
		local p = t.points
		local x0 = math.min(p[1][1], p[2][1], p[3][1])
		local x1 = math.max(p[1][1], p[2][1], p[3][1])
		local z0 = math.min(p[1][3], p[2][3], p[3][3])
		local z1 = math.max(p[1][3], p[2][3], p[3][3])
		for gx = math.floor(x0 / CELL), math.floor(x1 / CELL) do
			for gz = math.floor(z0 / CELL), math.floor(z1 / CELL) do
				local key = gx .. "," .. gz
				local list = grid[key]
				if list == nil then
					list = {}
					grid[key] = list
				end
				table.insert(list, i)
			end
		end
	end

	-- Треугольник (не i и не сосед по ребру), на поверхности которого лежит ребро.
	local function support(i: number, other: number, p: V, q: V): number?
		local mid = { (p[1] + q[1]) / 2, (p[2] + q[2]) / 2, (p[3] + q[3]) / 2 }
		local list = grid[cell(mid[1], mid[3])]
		if list == nil then
			return nil
		end
		-- Из подходящих берём самый «соосный» (два блока встык: верх соседа, а не его бок).
		local best, best_dot = nil, -math.huge
		for _, k in list do
			if k ~= i and k ~= other then
				local t = triangles[k].points
				local nk = normals[k]
				if on_triangle(p, t[1], t[2], t[3], nk, ON_PLANE) and on_triangle(q, t[1], t[2], t[3], nk, ON_PLANE) and on_triangle(mid, t[1], t[2], t[3], nk, ON_PLANE) then
					local d = dot(normals[i], nk)
					if d > best_dot then
						best, best_dot = k, d
					end
				end
			end
		end
		return best
	end

	-- 4. Выпуклые рёбра, лежащие на чужой поверхности, — шов, не край.
	-- Пример: нижнее ребро склона клина сшито с дном клина (острый выпуклый
	-- угол), но лежит на полу — колесо не должно о него биться.
	local vertex_supported: { [number]: boolean } = {}
	for i = 1, n do
		local tri = ids[i]
		for j = 1, 3 do
			if convex[i][j] then
				local a, b = tri[j], tri[j % 3 + 1]
				local k = support(i, partner[i][j], positions[a], positions[b])
				if k then
					cosines[i][j] = math.clamp(dot(normals[i], normals[k]), -1, 1)
					convex[i][j] = false
					vertex_supported[a] = true
					vertex_supported[b] = true
				end
			end
		end
		if yield and i % 2000 == 0 then
			yield()
		end
	end

	-- 5. Вершины: плоские (все соседние нормали совпадают) или лежащие на шве — без столкновений.
	local incident: { { number } } = table.create(#positions)
	for i = 1, #positions do
		incident[i] = {}
	end
	for i = 1, n do
		for _, v in ids[i] do
			table.insert(incident[v], i)
		end
	end
	local flat_vertex: { [number]: boolean } = {}
	for v, list in incident do
		local first = normals[list[1]]
		local flat = true
		for _, t in list do
			if math.abs(dot(first, normals[t]) - 1) > 0.01 then
				flat = false
				break
			end
		end
		if flat then
			flat_vertex[v] = true
		end
	end

	-- 6. Кодирование: байт угла ребра + 32 (ребро выпуклое) + 64 (вершина выключена).
	for i, t in triangles do
		local bytes = table.create(3)
		local tri = ids[i]
		for j = 1, 3 do
			local byte = angle_code(cosines[i][j])
			if convex[i][j] then
				byte += 32
			end
			local v = tri[j]
			if flat_vertex[v] or vertex_supported[v] then
				byte += 64
			end
			bytes[j] = byte
		end
		t.native_edges = bytes
	end
end

return edge_flags
