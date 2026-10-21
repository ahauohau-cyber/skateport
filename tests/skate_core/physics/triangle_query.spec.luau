--!strict
-- Сверка physics/triangle_query (+ sweep, closest, roots, walk) с настоящим skate-core.

local harness = require("../../harness")
local rt = require("../../../src/rt")
local triangle_query = require("../../../src/skate_core/physics/triangle_query")
local golden = require("../../golden/triangle_query")

local fb = rt.from_bits

local function V(t: { number }): vector
	return vector.create(fb(t[1]), fb(t[2]), fb(t[3]))
end

local function same(actual: number, bits: number): boolean
	return rt.to_bits(actual) == bits or (actual ~= actual and fb(bits) ~= fb(bits))
end

local function same_v(actual: vector, bits: { number }): boolean
	return same(actual.x, bits[1]) and same(actual.y, bits[2]) and same(actual.z, bits[3])
end

local function same_hit(actual: any, want: any): boolean
	return same_v(actual.position, want.position)
		and same_v(actual.normal, want.normal)
		and same(actual.fraction, want.fraction)
		and same(actual.volume_parameter[1], want.vp[1])
		and same(actual.volume_parameter[2], want.vp[2])
		and same(actual.volume_parameter[3], want.vp[3])
end

return function(report: harness.Report)
	harness.test(report, "triangle_query: triangle_segment vs Rust", function()
		local total, hits, bad, first = 0, 0, 0, nil
		for index, case in golden.segment do
			total += 1
			local result = {
				position = vector.create(9.0, 9.0, 9.0),
				normal = vector.create(0.0, 0.0, 1.0),
				fraction = 0.5,
				volume_parameter = { rt.f32(0.1), rt.f32(0.2), rt.f32(0.3) },
			}
			local vertices = { V(case.vertices[1]), V(case.vertices[2]), V(case.vertices[3]) }
			local ok = triangle_query.triangle_segment(
				result,
				V(case.start),
				V(case.direction),
				vertices,
				fb(case.line_radius),
				fb(case.fatness)
			)
			if case.ok then
				hits += 1
			end
			if ok ~= case.ok or not same_hit(result, case.result) then
				bad += 1
				first = first or index
			end
		end
		table.insert(report.lines, string.format("      segment: %d случаев (%d попаданий), расхождений %d", total, hits, bad))
		harness.check(bad == 0, "первое расхождение в случае " .. tostring(first))
	end)

	harness.test(report, "triangle_query: thin_triangle vs Rust", function()
		local total, hits, bad, first = 0, 0, 0, nil
		for index, case in golden.thin do
			total += 1
			local vertices = { V(case.vertices[1]), V(case.vertices[2]), V(case.vertices[3]) }
			local got = triangle_query.thin_triangle(V(case.start), V(case.direction), vertices)
			local ok
			if case.hit == false then
				ok = got == nil
			else
				hits += 1
				ok = got ~= nil and same_hit(got, case.hit)
			end
			if not ok then
				bad += 1
				first = first or index
			end
		end
		table.insert(report.lines, string.format("      thin: %d случаев (%d попаданий), расхождений %d", total, hits, bad))
		harness.check(bad == 0, "первое расхождение в случае " .. tostring(first))
	end)
end
