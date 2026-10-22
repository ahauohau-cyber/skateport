--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/reduction.rs (коммит 2e16697)

local rt = require("../../../rt")
local arithmetic = require("./arithmetic")

local from_bits = rt.from_bits
local cross, dot, scale, sub, vector = arithmetic.cross, arithmetic.dot, arithmetic.scale, arithmetic.sub, arithmetic.vector

local reduction = {}

type V = { number }

-- Complete geometric predicate 8277A208. Body IDs are checked by its caller.
-- The native comparison uses the *smaller* absolute plane displacement.
-- pub fn coplanar_contacts(a: &ContactRecord, b: &ContactRecord) -> bool
function reduction.coplanar_contacts(a: { number }, b: { number }): boolean
	local normal = vector(a, 8)
	if from_bits(0x3f7f_be77) > dot(normal, vector(b, 8)) then
		return false
	end
	local da = math.abs(dot(normal, sub(vector(a, 0), vector(b, 0))))
	local db = math.abs(dot(normal, sub(vector(a, 4), vector(b, 4))))
	local selected = if rt.f32(da - db) >= 0.0 then db else da
	return selected < from_bits(0x3c23_d70a)
end

-- Full 827798F8 point selection. Inputs are paired world-space positions;
-- output slots beyond the returned count retain the native write behavior.
-- The caller provides at least one pair, as the native function requires.
-- pub fn select_contact_points(a: &[V], b: &[V], normal: V, output: &mut [u32; 4]) -> usize
-- ROBLOX: индексы точек в output — как в Rust (с нуля).
function reduction.select_contact_points(a: { V }, b: { V }, normal: V, output: { number }): number
	assert(#a > 0 and #a == #b)
	local first = 0
	local origin = a[1]
	local depth = dot(normal, sub(a[1], b[1]))
	for i = 1, #a - 1 do
		local candidate = dot(normal, sub(a[i + 1], b[i + 1]))
		if depth > candidate then
			depth = candidate
			first = i
			origin = a[i + 1]
		end
	end
	local third_delta = sub(a[1], origin)
	local far_delta = third_delta
	local far = 0
	local distance = dot(far_delta, far_delta)
	for i = 1, #a - 1 do
		local delta = sub(a[i + 1], origin)
		local candidate = dot(delta, delta)
		if candidate > distance then
			distance = candidate
			far = i
			far_delta = delta
		end
	end
	if first == far then
		output[1] = first
		return 1
	end
	local third = 0
	local initial_area = cross(third_delta, far_delta)
	local area = dot(initial_area, initial_area)
	for i = 1, #a - 1 do
		local delta = sub(a[i + 1], origin)
		local area_vector = cross(delta, far_delta)
		local candidate = dot(area_vector, area_vector)
		if candidate > area then
			area = candidate
			third = i
			third_delta = delta
		end
	end
	output[1], output[2], output[3] = first, far, third
	if third == first or third == far then
		return 2
	end
	local side = cross(normal, far_delta)
	local sign = if dot(side, third_delta) >= 0.0 then 1.0 else -1.0
	local far_side = scale(side, sign)
	local third_side = scale(cross(normal, third_delta), sign)
	local edge = sub(third_delta, far_delta)
	local fourth = 9999
	local best = -1.0
	for i = 0, #a - 1 do
		local delta = sub(a[i + 1], origin)
		local selected
		if dot(delta, far_side) > 0.0 then
			if dot(delta, third_side) > 0.0 then
				selected = cross(delta, third_delta)
			else
				selected = cross(sub(delta, far_delta), edge)
			end
		else
			selected = cross(delta, far_delta)
		end
		local candidate = dot(selected, selected)
		if candidate > best then
			best = candidate
			fourth = i
		end
	end
	output[4] = fourth
	local extra = if fourth ~= first and fourth ~= far and fourth ~= third and fourth ~= 9999 then 1 else 0
	return 3 + extra
end

-- Complete 82779EB0 grouping/reduction. Retained contacts are restored to
-- original order; discarded tail records are not cleared. No drop count change.
-- pub(super) fn reduce(records: &mut [ContactRecord; 50], count: &mut u32)
-- ROBLOX: возвращает новый count.
function reduction.reduce(records: { { number } }, count: number): number
	local original = count
	assert(original <= 50)
	local assigned = table.create(50, false)
	local retained = {}
	for first = 0, original - 1 do
		if assigned[first + 1] then
			continue
		end
		assigned[first + 1] = true
		local group = { first }
		for next_index = first + 1, original - 1 do
			if
				not assigned[next_index + 1]
				and records[first + 1][4] == records[next_index + 1][4]
				and records[first + 1][8] == records[next_index + 1][8]
				and reduction.coplanar_contacts(records[first + 1], records[next_index + 1])
			then
				assigned[next_index + 1] = true
				table.insert(group, next_index)
			end
		end
		if #group <= 4 then
			for _, index in group do
				table.insert(retained, index)
			end
		else
			local a, b = {}, {}
			for k, index in group do
				a[k] = vector(records[index + 1], 0)
				b[k] = vector(records[index + 1], 4)
			end
			local selected = { 0, 1, 2, 3 }
			local length = reduction.select_contact_points(a, b, vector(records[first + 1], 8), selected)
			for k = 1, length do
				table.insert(retained, group[selected[k] + 1])
			end
		end
	end
	if #retained < original then
		table.sort(retained)
		count = #retained
		for destination0, source in retained do
			local destination = destination0 - 1
			if destination ~= source then
				-- Native 8277A300 loads/stores float fields individually. Its
				-- f32→f64→f32 copy quiets sNaNs; IDs/tag remain integer stores.
				local source_record = records[source + 1]
				local copy = table.create(64) :: { number }
				for i, word in source_record do
					if bit32.band(word, 0x7f80_0000) == 0x7f80_0000 and bit32.band(word, 0x007f_ffff) ~= 0 then
						copy[i] = bit32.bor(word, 0x0040_0000)
					else
						copy[i] = word
					end
				end
				for _, i in { 3, 7, 23 } do
					copy[i + 1] = source_record[i + 1]
				end
				records[destination + 1] = copy
			end
		end
	end
	return count
end

return reduction
