--!strict
-- Общие помощники тестов: чтение битов из эталона и сравнение бит в бит.
local rt = require("../src/rt")

local util = {}

local fb, tb = rt.from_bits, rt.to_bits
util.fb = fb
util.tb = tb

function util.V(t: { number }): vector
	return vector.create(fb(t[1]), fb(t[2]), fb(t[3]))
end
function util.F3(t: { number }): { number }
	return { fb(t[1]), fb(t[2]), fb(t[3]) }
end
function util.Q(t: { number }): any
	return { x = fb(t[1]), y = fb(t[2]), z = fb(t[3]), w = fb(t[4]) }
end
function util.B(t: { { number } }): any
	return { columns = { util.F3(t[1]), util.F3(t[2]), util.F3(t[3]) } }
end
function util.A(t: any): any
	return { basis = util.B(t[1]), translation = util.V(t[2]) }
end

-- Совпадение с битами эталона; NaN с любой полезной нагрузкой считается равным.
function util.same(actual: number, bits: number): boolean
	return tb(actual) == bits or (actual ~= actual and fb(bits) ~= fb(bits))
end
local same = util.same
function util.same_v(actual: vector, bits: { number }): boolean
	return same(actual.x, bits[1]) and same(actual.y, bits[2]) and same(actual.z, bits[3])
end
function util.same_f3(actual: { number }, bits: { number }): boolean
	return same(actual[1], bits[1]) and same(actual[2], bits[2]) and same(actual[3], bits[3])
end
function util.same_q(q: any, t: { number }): boolean
	return same(q.x, t[1]) and same(q.y, t[2]) and same(q.z, t[3]) and same(q.w, t[4])
end
function util.same_b(actual: any, bits: { { number } }): boolean
	for c = 1, 3 do
		for r = 1, 3 do
			if not same(actual.columns[c][r], bits[c][r]) then
				return false
			end
		end
	end
	return true
end
function util.same_a(actual: any, t: any): boolean
	return util.same_b(actual.basis, t[1]) and util.same_v(actual.translation, t[2])
end
function util.same_frames(f: any, t: any): boolean
	return util.same_q(f.body_a.orientation, t[1])
		and util.same_v(f.body_a.translation, t[2])
		and util.same_q(f.body_b.orientation, t[3])
		and util.same_v(f.body_b.translation, t[4])
end
function util.same_words(a: { number }, b: { number }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #b do
		if a[i] ~= b[i] then
			local x, y = fb(a[i]), fb(b[i])
			if not (x ~= x and y ~= y) then
				return false
			end
		end
	end
	return true
end
function util.reaction(t: { { number } }): any
	return {
		linear_displacement = util.V(t[1]),
		position_displacement = util.V(t[2]),
		angular_displacement = util.V(t[3]),
		orientation_displacement = util.V(t[4]),
	}
end
function util.same_reaction(r: any, t: { { number } }): boolean
	return util.same_v(r.linear_displacement, t[1])
		and util.same_v(r.position_displacement, t[2])
		and util.same_v(r.angular_displacement, t[3])
		and util.same_v(r.orientation_displacement, t[4])
end
-- BodySnapshot из эталона (golden/src/assembly.rs, snapshot_s).
function util.snapshot(t: any): any
	local r, i = t.rates, t.inertia
	return {
		state_flags = t.flags,
		rates = {
			orientation = util.Q(r[1]),
			basis = util.B(r[2]),
			world_inverse_inertia = util.B(r[3]),
			position = util.V(r[4]),
			linear_velocity = util.V(r[5]),
			angular_velocity = util.V(r[6]),
			force_acceleration = util.V(r[7]),
			torque_acceleration = util.V(r[8]),
			kinetic_energy = fb(r[9]),
			cool_down = r[10],
		},
		inertia = {
			inverse_tensor = util.V(i[1]),
			inverse_mass = fb(i[2]),
			spherical = fb(i[3]),
			maximum_linear_velocity = fb(i[4]),
			maximum_angular_velocity = fb(i[5]),
			linear_drag = fb(i[6]),
			angular_drag = fb(i[7]),
		},
	}
end

-- Прогон набора случаев с подсчётом расхождений.
function util.count(report: any, harness: any, name: string, cases: { any }, check: (any) -> boolean)
	local bad, first = 0, nil
	for index, case in cases do
		if not check(case) then
			bad += 1
			first = first or index
		end
	end
	table.insert(report.lines, string.format("      %s: %d случаев, расхождений %d", name, #cases, bad))
	harness.check(bad == 0, "первое расхождение в случае " .. tostring(first))
end

-- Глубокое сравнение с эталоном: числа по битам (NaN равны любому NaN),
-- vector по компонентам, таблицы рекурсивно по ключам эталона и длине.
-- Возвращает nil или путь к первому расхождению.
function util.diff(actual: any, want: any, path: string?): string?
	local at = path or ""
	if type(want) == "number" then
		if type(actual) ~= "number" then
			return at .. ": ожидалось число, получено " .. typeof(actual)
		end
		-- Сначала биты f32 (различает ±0), затем точное равенство: целые слова
		-- u32 больше 2^24 при переводе в f32 теряли бы младшие биты.
		if not ((tb(actual) == tb(want) and actual == want) or (actual ~= actual and want ~= want)) then
			return string.format("%s: %.9g (0x%08x) vs %.9g (0x%08x)", at, actual :: number, tb(actual), want :: number, tb(want))
		end
		return nil
	elseif type(want) == "vector" then
		if type(actual) ~= "vector" then
			return at .. ": ожидался vector, получено " .. typeof(actual)
		end
		return util.diff(actual.x, want.x, at .. ".x") or util.diff(actual.y, want.y, at .. ".y") or util.diff(actual.z, want.z, at .. ".z")
	elseif type(want) == "table" then
		if type(actual) ~= "table" then
			return at .. ": ожидалась таблица, получено " .. typeof(actual)
		end
		if #actual ~= #want then
			return string.format("%s: длина %d vs %d", at, #actual, #want)
		end
		for k, v in want do
			local d = util.diff(actual[k], v, at .. "." .. tostring(k))
			if d then
				return d
			end
		end
		return nil
	end
	if actual ~= want then
		return string.format("%s: %s vs %s", at, tostring(actual), tostring(want))
	end
	return nil
end

return util
