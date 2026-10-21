--!strict
-- Сверка physics/world_contact с настоящим skate-core (эталон golden/src/world_contact.rs).

local harness = require("../../harness")
local rt = require("../../../src/rt")
local primitive_query = require("../../../src/skate_core/physics/world_contact/primitive_query")
local primitive_pair = require("../../../src/skate_core/physics/world_contact/primitive_pair")
local reduction = require("../../../src/skate_core/physics/world_contact/reduction")
local buffer_mod = require("../../../src/skate_core/physics/world_contact/buffer")
local golden = require("../../golden/world_contact")

local fb = rt.from_bits
local ContactBuffer = buffer_mod.ContactBuffer

local function V(t: { number }): vector
	return vector.create(fb(t[1]), fb(t[2]), fb(t[3]))
end

local function same(actual: number, bits: number): boolean
	return rt.to_bits(actual) == bits or (actual ~= actual and fb(bits) ~= fb(bits))
end

local function same_v(actual: vector, bits: { number }): boolean
	return same(actual.x, bits[1]) and same(actual.y, bits[2]) and same(actual.z, bits[3])
end

local function triangle(t: any): any
	return {
		vertices = { V(t.vertices[1]), V(t.vertices[2]), V(t.vertices[3]) },
		feature = {
			normal = V(t.normal),
			edges = { V(t.edges[1]), V(t.edges[2]), V(t.edges[3]) },
			flags = t.flags,
			edge_cosines = { fb(t.edge_cosines[1]), fb(t.edge_cosines[2]), fb(t.edge_cosines[3]) },
		},
		edge_lengths = { fb(t.edge_lengths[1]), fb(t.edge_lengths[2]), fb(t.edge_lengths[3]) },
		fatness = fb(t.fatness),
	}
end

local function primitive(p: any): any
	if p.kind == "Sphere" then
		return { kind = "Sphere", sphere = { center = V(p.center), radius = fb(p.radius) } }
	elseif p.kind == "Capsule" then
		return { kind = "Capsule", center = V(p.center), axis = V(p.axis), half_length = fb(p.half_length), radius = fb(p.radius) }
	elseif p.kind == "Triangle" then
		return { kind = "Triangle", triangle = triangle(p.triangle) }
	else
		local c = p.basis
		return {
			kind = "RoundedBox",
			center = V(p.center),
			basis = {
				columns = {
					{ fb(c[1][1]), fb(c[1][2]), fb(c[1][3]) },
					{ fb(c[2][1]), fb(c[2][2]), fb(c[2][3]) },
					{ fb(c[3][1]), fb(c[3][2]), fb(c[3][3]) },
				},
			},
			half_extents = V(p.half_extents),
			radius = fb(p.radius),
		}
	end
end

local function same_manifold(got: any, want: any): boolean
	if want == false then
		return got == nil
	end
	if got == nil or got.count ~= want.count or not same_v(got.normal, want.normal) then
		return false
	end
	for i = 1, want.count do
		if not same_v(got.points[i].a, want.points[i].a) or not same_v(got.points[i].b, want.points[i].b) then
			return false
		end
	end
	return true
end

local function words_equal(a: { number }, b: { number }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

return function(report: harness.Report)
	harness.test(report, "world_contact: primitive_triangle_world_contacts vs Rust", function()
		local total, hits, bad, first = 0, 0, 0, nil
		local by_kind = {}
		for index, case in golden.world do
			total += 1
			local s = case.settings
			local settings = {
				volume_padding = fb(s[1]),
				maximum_separating_distance = fb(s[2]),
				edge_cos_bend_normal_threshold = fb(s[3]),
				convexity_epsilon = fb(s[4]),
				is_object = s[5],
			}
			local got = primitive_query.primitive_triangle_world_contacts(primitive(case.primitive), triangle(case.tri), V(case.velocity), settings)
			if case.result ~= false then
				hits += 1
			end
			if not same_manifold(got, case.result) then
				bad += 1
				first = first or index
				by_kind[case.primitive.kind] = (by_kind[case.primitive.kind] or 0) + 1
			end
		end
		local kinds = {}
		for k, n in by_kind do
			table.insert(kinds, k .. "=" .. n)
		end
		table.insert(report.lines, string.format("      world: %d случаев (%d с контактом), расхождений %d %s", total, hits, bad, table.concat(kinds, " ")))
		harness.check(bad == 0, "первое расхождение в случае " .. tostring(first))
	end)

	harness.test(report, "world_contact: primitive_pair_contacts vs Rust", function()
		local total, hits, bad, first = 0, 0, 0, nil
		local by_kind = {}
		for index, case in golden.pair do
			total += 1
			local s = case.settings
			local settings = {
				padding_a = fb(s[1]),
				padding_b = fb(s[2]),
				additional_padding = fb(s[3]),
				edge_cos_bend_normal_threshold = fb(s[4]),
				convexity_epsilon = fb(s[5]),
			}
			local got = primitive_pair.primitive_pair_contacts(primitive(case.a), primitive(case.b), settings)
			if case.result ~= false then
				hits += 1
			end
			if not same_manifold(got, case.result) then
				bad += 1
				first = first or index
				local key = case.a.kind .. "/" .. case.b.kind
				by_kind[key] = (by_kind[key] or 0) + 1
			end
		end
		local kinds = {}
		for k, n in by_kind do
			table.insert(kinds, k .. "=" .. n)
		end
		table.insert(report.lines, string.format("      pair: %d случаев (%d с контактом), расхождений %d %s", total, hits, bad, table.concat(kinds, " ")))
		harness.check(bad == 0, "первое расхождение в случае " .. tostring(first))
	end)

	harness.test(report, "world_contact: select_contact_points vs Rust", function()
		local bad, first = 0, nil
		for index, case in golden.select do
			local a, b = {}, {}
			for i, p in case.a do
				a[i] = { fb(p[1]), fb(p[2]), fb(p[3]) }
			end
			for i, p in case.b do
				b[i] = { fb(p[1]), fb(p[2]), fb(p[3]) }
			end
			local out = { 0, 1, 2, 3 }
			local n = reduction.select_contact_points(a, b, { fb(case.normal[1]), fb(case.normal[2]), fb(case.normal[3]) }, out)
			if n ~= case.count or not words_equal(out, case.out) then
				bad += 1
				first = first or index
			end
		end
		table.insert(report.lines, string.format("      select: %d случаев, расхождений %d", #golden.select, bad))
		harness.check(bad == 0, "первое расхождение в случае " .. tostring(first))
	end)

	harness.test(report, "world_contact: coplanar_contacts vs Rust", function()
		local bad, trues = 0, 0
		for _, case in golden.coplanar do
			if case.result then
				trues += 1
			end
			if reduction.coplanar_contacts(case.a, case.b) ~= case.result then
				bad += 1
			end
		end
		table.insert(report.lines, string.format("      coplanar: %d случаев (%d да), расхождений %d", #golden.coplanar, trues, bad))
		harness.check(bad == 0, "coplanar mismatch")
	end)

	harness.test(report, "world_contact: ContactBuffer allocate/duplicate/reduce/flush vs Rust", function()
		local bad, first = 0, nil
		for index, case in golden.buffer do
			local records = {}
			for i = 1, 50 do
				records[i] = rt.zeros(64)
			end
			local buf: buffer_mod.ContactBuffer = {
				count = 0,
				flushed = 0,
				capacity = case.capacity,
				dropped = 0,
				distance_squared_threshold = fb(case.threshold),
				allow_flush = case.allow_flush,
				deferred_reduction = case.deferred,
				full = 0,
				records = records,
			}
			local flushed = {}
			local function sink(recs: { { number } })
				local call = {}
				for i, r in recs do
					call[i] = table.clone(r)
				end
				table.insert(flushed, call)
			end
			local ok = true
			for _, op in case.ops do
				local slot = ContactBuffer.allocate(buf, sink)
				local want_slot = if op.slot < 0 then nil else op.slot
				if slot ~= want_slot then
					ok = false
				end
				local dup = false
				if slot ~= nil then
					buf.records[slot + 1] = table.clone(op.rec)
					dup = ContactBuffer.last_is_duplicate(buf)
					if dup then
						buf.count -= 1
					end
				end
				if dup ~= op.dup then
					ok = false
				end
			end
			ContactBuffer.flush(buf, sink)
			if #flushed ~= #case.flushed then
				ok = false
			else
				for i, call in case.flushed do
					if #flushed[i] ~= #call then
						ok = false
					else
						for j, rec in call do
							if not words_equal(flushed[i][j], rec) then
								ok = false
							end
						end
					end
				end
			end
			if buf.count ~= case.count or buf.flushed ~= case.flushed_count or buf.dropped ~= case.dropped or buf.full ~= case.full then
				ok = false
			end
			if not ok then
				bad += 1
				first = first or index
			end
		end
		table.insert(report.lines, string.format("      buffer: %d сценариев, расхождений %d", #golden.buffer, bad))
		harness.check(bad == 0, "первое расхождение в сценарии " .. tostring(first))
	end)
end
