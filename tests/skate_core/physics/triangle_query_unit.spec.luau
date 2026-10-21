--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/tests/triangle_query.rs (коммит 2e16697)

local harness = require("../../harness")
local rt = require("../../../src/rt")
local triangle_query = require("../../../src/skate_core/physics/triangle_query")

local f32 = rt.f32
local thin_triangle = triangle_query.thin_triangle
local triangle_segment = triangle_query.triangle_segment
local dot = triangle_query.dot
local ZERO = vector.create(0, 0, 0)

local function V(x: number, y: number, z: number): vector
	return vector.create(x, y, z)
end

local function vertices(): { vector }
	return { V(0.0, 0.0, 0.0), V(0.0, 0.0, 1.0), V(1.0, 0.0, 0.0) }
end

local function sweep(start: vector, delta: vector, radius: number, fatness: number): any
	local result = {
		position = ZERO,
		normal = ZERO,
		fraction = 0.0,
		volume_parameter = { 0.0, 0.0, 0.0 },
	}
	if triangle_segment(result, start, delta, vertices(), f32(radius), f32(fatness)) then
		return result
	end
	return nil
end

local check, eq = harness.check, harness.eq

return function(report: harness.Report)
	harness.test(report, "triangle_query: wheel_segment_preserves_winding_fraction_and_barycentric_coordinates", function()
		local hit = thin_triangle(V(0.25, 0.1, 0.25), V(0.0, -0.2, 0.0), vertices())
		assert(hit, "unwrap")
		check(math.abs(hit.fraction - 0.5) < 1e-6, "fraction")
		check(math.abs(hit.position.y) < 1e-7, "position.y")
		check(math.abs(hit.normal.y - 1.0) < 1e-6, "normal.y")
		eq(hit.volume_parameter[1], 0.25)
		eq(hit.volume_parameter[2], 0.25)
		eq(hit.volume_parameter[3], 0.0)
		check(thin_triangle(V(0.25, -0.1, 0.25), V(0.0, 0.2, 0.0), vertices()) == nil, "back side")
		check(thin_triangle(V(0.75, 0.1, 0.75), V(0.0, -0.2, 0.0), vertices()) == nil, "outside")
	end)

	harness.test(report, "triangle_query: native_tolerance_accepts_small_endpoint_overrun_without_clamping", function()
		local start = V(0.25, 0.200001, 0.25)
		local hit = thin_triangle(start, V(0.0, -0.2, 0.0), vertices())
		assert(hit, "unwrap")
		check(hit.fraction > 1.0, "overrun accepted")
		check(thin_triangle(V(0.25, 0.201, 0.25), V(0.0, -0.2, 0.0), vertices()) == nil, "too far")
		check(thin_triangle(start, ZERO, vertices()) == nil, "zero direction")
	end)

	harness.test(report, "triangle_query: camera_sweep_resolves_face_edges_vertices_and_query_radius_offset", function()
		local delta = V(0.0, -2.0, 0.0)
		local face = sweep(V(0.25, 1.0, 0.25), delta, 0.1, 0.0)
		assert(face, "face")
		check(math.abs(face.fraction - 0.45) < 1e-6, "face fraction")
		check(math.abs(face.position.y) < 1e-6, "face position")
		local rounded_face = sweep(V(0.25, 1.0, 0.25), delta, 0.1, 0.2)
		assert(rounded_face, "rounded face")
		check(math.abs(rounded_face.fraction - 0.35) < 1e-6, "rounded fraction")
		check(math.abs(rounded_face.position.y - 0.2) < 1e-6, "rounded position")
		local edge = sweep(V(-0.06, 1.0, 0.5), delta, 0.1, 0.0)
		assert(edge, "edge")
		check(math.abs(edge.fraction - 0.46) < 1e-5, "edge fraction")
		check(math.abs(edge.normal.x + 0.6) < 1e-4, "edge normal x")
		check(math.abs(edge.normal.y - 0.8) < 1e-4, "edge normal y")
		check(math.abs(edge.position.x) < 1e-5 and math.abs(edge.position.y) < 1e-5, "edge position")
		eq(edge.volume_parameter[1], 0.5)
		eq(edge.volume_parameter[2], 0.0)
		eq(edge.volume_parameter[3], 0.0)
		local corner = sweep(V(-0.04, 1.0, -0.03), delta, 0.1, 0.0)
		assert(corner, "corner")
		local expected = f32(f32(1.0 - f32(math.sqrt(f32(f32(0.01) - f32(0.0025))))) * 0.5)
		check(math.abs(corner.fraction - expected) < 1e-5, "corner fraction")
		check(dot(corner.position, corner.position) < 1e-9, "corner position")
		eq(corner.volume_parameter[1], 0.0)
		eq(corner.volume_parameter[2], 0.0)
		eq(corner.volume_parameter[3], 0.0)
		check(sweep(V(-0.2, 1.0, 0.5), delta, 0.1, 0.0) == nil, "miss")
	end)

	harness.test(report, "triangle_query: rounded_query_handles_reverse_face_overlap_and_parallel_motion", function()
		local reverse = sweep(V(0.25, -1.0, 0.25), V(0.0, 2.0, 0.0), 0.1, 0.0)
		assert(reverse, "reverse")
		check(math.abs(reverse.fraction - 0.45) < 1e-6, "reverse fraction")
		check(math.abs(reverse.normal.y + 1.0) < 1e-6, "reverse normal")
		local overlap = sweep(V(0.25, 0.05, 0.25), ZERO, 0.1, 0.0)
		assert(overlap, "overlap")
		eq(overlap.fraction, 0.0)
		check(math.abs(overlap.volume_parameter[3] - 0.0075) < 1e-6, "penetration")
		local parallel = sweep(V(-1.0, 0.06, 0.5), V(2.0, 0.0, 0.0), 0.1, 0.0)
		assert(parallel, "parallel")
		check(math.abs(parallel.fraction - 0.46) < 1e-5, "parallel fraction")
		check(math.abs(parallel.normal.x + 0.8) < 1e-4, "parallel normal x")
		check(math.abs(parallel.normal.y - 0.6) < 1e-4, "parallel normal y")
	end)
end
