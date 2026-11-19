--!strict
--!native
--!optimize 2
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
-- косинус и выпуклость), и добавляем правило: выпуклое ребро, которое лежит
-- на чужой поверхности, — не край, а шов; флаг снимаем. Ребро может лежать
-- сразу на нескольких соседях (Т-стык крупной и мелких клеток Terrain) —
-- проверяем концы и середину каждый по отдельности.
-- Результат кодируем в native_edges (формат decode_native_edges ядра), тогда
-- ядро берёт наши флаги как есть.
--
-- Скорость (карты на 100 тыс. треугольников): числовые ключи вместо строк,
-- координаты в плоских массивах без временных таблиц, нативная компиляция,
-- огромные треугольники (пол-бейсплейт) — в отдельной корзине, а не в
-- тысячах клеток сетки.

local edge_flags = {}

type V = { number } -- {x, y, z}, метры (или vector)
export type Triangle = { points: { any }, surface: number, material: number, native_edges: { number }? }

local WELD = 0.001 -- м, как в collision_world
local ON_PLANE = 0.01 -- м: ребро «лежит» на плоскости соседа
local CELL = 4.0 -- м: ячейка пространственной сетки
local BIG_CELLS = 256 -- треугольник шире стольких ячеек — в «большую» корзину
local EPS = 0.002 -- запас барицентрической проверки

local function angle_code(cosine: number): number
	-- Код угла ребра: косинус = 1 - pi^2 / (8 << code) (decode_native_edges).
	local gap = 1 - cosine
	if gap <= 0 then
		return 27
	end
	local code = math.floor(math.log(1.2337005 / gap, 2) + 0.5)
	return math.clamp(code, 0, 27)
end

local function coords(p: any): (number, number, number)
	if type(p) == "table" then
		return p[1], p[2], p[3]
	end
	return p.x, p.y, p.z
end

-- Посчитать native_edges для всех треугольников (в месте, поле native_edges).
function edge_flags.compute(triangles: { Triangle }, yield: (() -> ())?)
	local n = #triangles
	local started = os.clock()
	local function maybe_yield()
		if yield and os.clock() - started > 0.012 then
			yield()
			started = os.clock()
		end
	end

	-- 1. Вершины треугольников (плоские массивы) и нормали.
	local ax, ay, az = table.create(n, 0), table.create(n, 0), table.create(n, 0)
	local bx, by, bz = table.create(n, 0), table.create(n, 0), table.create(n, 0)
	local cx, cy, cz = table.create(n, 0), table.create(n, 0), table.create(n, 0)
	local nxs, nys, nzs = table.create(n, 0), table.create(n, 0), table.create(n, 0)
	for i, t in triangles do
		local p = t.points
		local x1, y1, z1 = coords(p[1])
		local x2, y2, z2 = coords(p[2])
		local x3, y3, z3 = coords(p[3])
		ax[i], ay[i], az[i] = x1, y1, z1
		bx[i], by[i], bz[i] = x2, y2, z2
		cx[i], cy[i], cz[i] = x3, y3, z3
		local ux, uy, uz = x2 - x1, y2 - y1, z2 - z1
		local vx, vy, vz = x3 - x1, y3 - y1, z3 - z1
		local qx, qy, qz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
		local l = math.sqrt(qx * qx + qy * qy + qz * qz)
		if l < 1e-12 then
			nxs[i], nys[i], nzs[i] = 0, 1, 0
		else
			nxs[i], nys[i], nzs[i] = qx / l, qy / l, qz / l
		end
	end
	maybe_yield()

	-- 2. Сварка вершин (1 мм): ключ — vector из целых миллиметров.
	local inv = 1 / WELD
	local key_to_id: { [vector]: number } = {}
	local px, py, pz = {}, {}, {}
	local ids = table.create(n * 3, 0) -- ids[(i-1)*3 + k]
	local count = 0
	local function weld(x: number, y: number, z: number): number
		local key = vector.create(math.round(x * inv), math.round(y * inv), math.round(z * inv))
		local id = key_to_id[key]
		if id == nil then
			count += 1
			id = count
			key_to_id[key] = id
			px[id], py[id], pz[id] = x, y, z
		end
		return id
	end
	for i = 1, n do
		local base = (i - 1) * 3
		ids[base + 1] = weld(ax[i], ay[i], az[i])
		ids[base + 2] = weld(bx[i], by[i], bz[i])
		ids[base + 3] = weld(cx[i], cy[i], cz[i])
		if i % 4096 == 0 then
			maybe_yield()
		end
	end

	-- 3. Пары рёбер (обратные направления), как в ядре. Ключ — a * 2^26 + b.
	local cosines = table.create(n * 3, 1)
	local convex = table.create(n * 3, true)
	local partner = table.create(n * 3, 0)
	local open: { [number]: number } = {} -- ключ ребра -> (i-1)*3 + j
	local SHIFT = 67108864
	for i = 1, n do
		local base = (i - 1) * 3
		for j = 1, 3 do
			local a = ids[base + j]
			local b = ids[base + (j % 3) + 1]
			local slot = open[b * SHIFT + a]
			if slot then
				open[b * SHIFT + a] = nil
				local oi = (slot - 1) // 3 + 1
				local c = math.clamp(nxs[i] * nxs[oi] + nys[i] * nys[oi] + nzs[i] * nzs[oi], -1, 1)
				-- Ориентация: (b - a) · (n_i × n_oi).
				local kx = nys[i] * nzs[oi] - nzs[i] * nys[oi]
				local ky = nzs[i] * nxs[oi] - nxs[i] * nzs[oi]
				local kz = nxs[i] * nys[oi] - nys[i] * nxs[oi]
				local orientation = (px[b] - px[a]) * kx + (py[b] - py[a]) * ky + (pz[b] - pz[a]) * kz
				local is_convex = not (orientation <= -1e-6 or c >= 1)
				cosines[base + j], cosines[slot] = c, c
				convex[base + j], convex[slot] = is_convex, is_convex
				partner[base + j], partner[slot] = oi, i
			else
				local fwd = a * SHIFT + b
				if open[fwd] == nil then
					open[fwd] = base + j
				end
			end
		end
		if i % 4096 == 0 then
			maybe_yield()
		end
	end

	-- 4. Сетка по XZ для поиска «подпирающих» треугольников.
	local grid: { [number]: { number } } = {}
	local big: { number } = {}
	local GRID = 65536
	local function cell_key(gx: number, gz: number): number
		return (gx + 32768) * GRID + (gz + 32768)
	end
	for i = 1, n do
		local x0 = math.floor(math.min(ax[i], bx[i], cx[i]) / CELL)
		local x1 = math.floor(math.max(ax[i], bx[i], cx[i]) / CELL)
		local z0 = math.floor(math.min(az[i], bz[i], cz[i]) / CELL)
		local z1 = math.floor(math.max(az[i], bz[i], cz[i]) / CELL)
		if (x1 - x0 + 1) * (z1 - z0 + 1) > BIG_CELLS then
			table.insert(big, i)
		else
			for gx = x0, x1 do
				for gz = z0, z1 do
					local key = cell_key(gx, gz)
					local list = grid[key]
					if list == nil then
						list = {}
						grid[key] = list
					end
					table.insert(list, i)
				end
			end
		end
		if i % 4096 == 0 then
			maybe_yield()
		end
	end

	-- Точка (x, y, z) на треугольнике k (в пределах ON_PLANE от плоскости и
	-- внутри с запасом по краям)?
	local function on_triangle(k: number, x: number, y: number, z: number): boolean
		local ox, oy, oz = x - ax[k], y - ay[k], z - az[k]
		if math.abs(ox * nxs[k] + oy * nys[k] + oz * nzs[k]) > ON_PLANE then
			return false
		end
		local v0x, v0y, v0z = cx[k] - ax[k], cy[k] - ay[k], cz[k] - az[k]
		local v1x, v1y, v1z = bx[k] - ax[k], by[k] - ay[k], bz[k] - az[k]
		local d00 = v0x * v0x + v0y * v0y + v0z * v0z
		local d01 = v0x * v1x + v0y * v1y + v0z * v1z
		local d11 = v1x * v1x + v1y * v1y + v1z * v1z
		local d20 = ox * v0x + oy * v0y + oz * v0z
		local d21 = ox * v1x + oy * v1y + oz * v1z
		local denom = d00 * d11 - d01 * d01
		if math.abs(denom) < 1e-18 then
			return false
		end
		local u = (d11 * d20 - d01 * d21) / denom
		local v = (d00 * d21 - d01 * d20) / denom
		return u >= -EPS and v >= -EPS and u + v <= 1 + EPS
	end

	-- Лучший (самый «соосный» с i) треугольник, кроме i и other, под точкой.
	local function supporter(i: number, other: number, x: number, y: number, z: number): number?
		local best, best_dot = nil, -math.huge
		local function try(k: number)
			if k ~= i and k ~= other and on_triangle(k, x, y, z) then
				local d = nxs[i] * nxs[k] + nys[i] * nys[k] + nzs[i] * nzs[k]
				if d > best_dot then
					best, best_dot = k, d
				end
			end
		end
		local list = grid[cell_key(math.floor(x / CELL), math.floor(z / CELL))]
		if list then
			for _, k in list do
				try(k)
			end
		end
		for _, k in big do
			try(k)
		end
		return best
	end

	-- 5. Выпуклые рёбра, лежащие на чужой поверхности, — шов, не край.
	-- Пример: нижнее ребро склона клина сшито с дном клина (острый выпуклый
	-- угол), но лежит на полу — колесо не должно о него биться.
	local vertex_supported: { [number]: boolean } = {}
	for i = 1, n do
		local base = (i - 1) * 3
		for j = 1, 3 do
			local slot = base + j
			if convex[slot] then
				local a = ids[slot]
				local b = ids[base + (j % 3) + 1]
				local other = partner[slot]
				local mx, my, mz = (px[a] + px[b]) / 2, (py[a] + py[b]) / 2, (pz[a] + pz[b]) / 2
				local k = supporter(i, other, mx, my, mz)
				if k and supporter(i, other, px[a], py[a], pz[a]) and supporter(i, other, px[b], py[b], pz[b]) then
					cosines[slot] = math.clamp(nxs[i] * nxs[k] + nys[i] * nys[k] + nzs[i] * nzs[k], -1, 1)
					convex[slot] = false
					vertex_supported[a] = true
					vertex_supported[b] = true
				end
			end
		end
		if i % 1024 == 0 then
			maybe_yield()
		end
	end

	-- 6. Вершины: плоские (все соседние нормали совпадают) или лежащие на шве —
	-- без столкновений. Первая нормаль у вершины и флаг «не плоская».
	local first_n: { number } = table.create(count, 0)
	local not_flat: { [number]: boolean } = {}
	for i = 1, n do
		local base = (i - 1) * 3
		for k = 1, 3 do
			local v = ids[base + k]
			local f = first_n[v]
			if f == 0 then
				first_n[v] = i
			elseif not not_flat[v] then
				if math.abs(nxs[f] * nxs[i] + nys[f] * nys[i] + nzs[f] * nzs[i] - 1) > 0.01 then
					not_flat[v] = true
				end
			end
		end
	end
	maybe_yield()

	-- 7. Кодирование: байт угла ребра + 32 (ребро выпуклое) + 64 (вершина выключена).
	for i, t in triangles do
		local base = (i - 1) * 3
		local bytes = table.create(3)
		for j = 1, 3 do
			local slot = base + j
			local byte = angle_code(cosines[slot])
			if convex[slot] then
				byte += 32
			end
			local v = ids[slot]
			if not not_flat[v] or vertex_supported[v] then
				byte += 64
			end
			bytes[j] = byte
		end
		t.native_edges = bytes
	end
end

return edge_flags
