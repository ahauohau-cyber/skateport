--!strict
-- Сверка physics/collision с настоящим skate-core (эталон golden/src/collision.rs).
-- Сравнение бит в бит: каждое поле результата.

local harness = require("../../harness")
local rt = require("../../../src/rt")
local sphere_triangle = require("../../../src/skate_core/physics/collision/sphere_triangle")
local world_contact = require("../../../src/skate_core/physics/collision/world_contact")
local fixup = require("../../../src/skate_core/physics/collision/fixup")
local golden = require("../../golden/collision")

local fb = rt.from_bits

local function V(t: { number }): vector
	return vector.create(fb(t[1]), fb(t[2]), fb(t[3]))
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

-- Совпадение числа с битами эталона.
local function same(actual: number, bits: number): boolean
	return rt.to_bits(actual) == bits or (actual ~= actual and fb(bits) ~= fb(bits))
end

local function same_v(actual: vector, bits: { number }): boolean
	return same(actual.x, bits[1]) and same(actual.y, bits[2]) and same(actual.z, bits[3])
end

local function same_pair(actual: any, expected: any): boolean
	return same_v(actual.a, expected.a) and same_v(actual.b, expected.b)
end

return function(report: harness.Report)
	harness.test(report, "collision: intersect_sphere_triangle vs Rust", function()
		local total, hits, bad, first = 0, 0, 0, nil
		for index, case in golden.sphere do
			total += 1
			local sphere = { center = V(case.center), radius = fb(case.radius) }
			local got = sphere_triangle.intersect_sphere_triangle(sphere, triangle(case.tri), fb(case.min_sep), case.is_a)
			local want = case.pair
			local ok
			if want == false then
				ok = got == nil
			else
				hits += 1
				ok = got ~= nil
					and same_v(got.separating_direction, want.sdir)
					and same(got.separating_distance, want.sdist)
					and same_v(got.normal, want.normal)
					and same_pair(got.points, want.points)
					and same(got.distance, want.distance)
					and got.triangle_region == want.region
			end
			if not ok then
				bad += 1
				first = first or index
			end
		end
		table.insert(report.lines, string.format("      sphere/triangle: %d случаев (%d с контактом), расхождений %d", total, hits, bad))
		harness.check(bad == 0, "первое расхождение в случае " .. tostring(first))
	end)

	harness.test(report, "collision: sphere_triangle_world_contact vs Rust", function()
		local total, hits, bad, first = 0, 0, 0, nil
		for index, case in golden.sphere do
			total += 1
			local sphere = { center = V(case.center), radius = fb(case.radius) }
			local s = case.settings
			local settings = {
				volume_padding = fb(s[1]),
				maximum_separating_distance = fb(s[2]),
				edge_cos_bend_normal_threshold = fb(s[3]),
				convexity_epsilon = fb(s[4]),
				is_object = s[5],
			}
			local got = world_contact.sphere_triangle_world_contact(sphere, triangle(case.tri), V(case.velocity), settings)
			local want = case.world
			local ok
			if want == false then
				ok = got == nil
			else
				hits += 1
				ok = got ~= nil and same_v(got.normal, want.normal) and same_pair(got.points, want.points)
			end
			if not ok then
				bad += 1
				first = first or index
			end
		end
		table.insert(report.lines, string.format("      world contact: %d случаев (%d с контактом), расхождений %d", total, hits, bad))
		harness.check(bad == 0, "первое расхождение в случае " .. tostring(first))
	end)

	harness.test(report, "collision: fix_up_triangle vs Rust", function()
		local total, accepted, bad, first = 0, 0, 0, nil
		for index, case in golden.fixup do
			total += 1
			local contacts = {}
			for i, c in case.contacts do
				contacts[i] = { a = V(c.a), b = V(c.b) }
			end
			local s = case.settings
			local ok, normal = fixup.fix_up_triangle(triangle(case.tri).feature, V(case.normal), contacts, {
				reverse = s[1],
				edge_cos_bend_normal_threshold = fb(s[2]),
				convexity_epsilon = fb(s[3]),
				is_object = s[4],
			})
			if case.ok then
				accepted += 1
			end
			local match = ok == case.ok and same_v(normal, case.out_normal)
			for i, c in case.out_contacts do
				match = match and same_pair(contacts[i], c)
			end
			if not match then
				bad += 1
				first = first or index
			end
		end
		table.insert(report.lines, string.format("      fixup: %d случаев (%d приняты), расхождений %d", total, accepted, bad))
		harness.check(bad == 0, "первое расхождение в случае " .. tostring(first))
	end)
end
