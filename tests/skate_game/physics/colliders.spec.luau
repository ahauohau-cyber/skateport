--!strict
-- Сверка skate_game/physics/colliders (world_volumes) с копией Rust-кода в
-- golden/src/colliders.rs: стоковая доска из данных игры, 2 × 200 тиков по рампе,
-- контакты от всех коллайдеров (колёса, траки, дека с концами и треугольниками).

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local collections = require("../../../src/skate_data/collections")
local settings_mod = require("../../../src/skate_game/physics/settings")
local colliders = require("../../../src/skate_game/physics/colliders")
local board_world = require("../../../src/skate_core/physics/board_world")
local query_metadata = require("../../../src/skate_core/physics/board_world/query_metadata")
local board_runtime = require("../../../src/skate_core/physics/board_runtime")
local drive_frames = require("../../../src/skate_core/physics/drive_frames")
local force_queue = require("../../../src/skate_core/physics/force_queue")
local world_golden = require("../../golden/world") :: any

local fb, f32 = u.fb, rt.f32
local BoardWorld = board_world.BoardWorld
local BoardRuntime = board_runtime.BoardRuntime

local function build_world(): any
	local material = { static_friction = 0.0, dynamic_friction = 0.0, restitution = 1.0 }
	local tris = {}
	for _, t in world_golden.triangles do
		table.insert(tris, assert(board_world.WorldTriangle.from_vertices(
			{ u.V(t[1]), u.V(t[2]), u.V(t[3]) }, material, t[4], t[5], u.F3(t[6]), fb(t[7]))))
	end
	local meshes = {}
	for start = 0, #tris - 1, 16 do
		local end_ = math.min(start + 16, #tris)
		local points = {}
		for i = start + 1, end_ do
			for _, p in tris[i].triangle.vertices do
				table.insert(points, p)
			end
		end
		table.insert(meshes, {
			geometry = 0, rejection_flags = 0, triangle_range = { start = start, end_ = end_ },
			local_to_world = drive_frames.RetailAffineTransform.IDENTITY(),
			world_to_local = drive_frames.RetailAffineTransform.IDENTITY(),
			local_bounds = assert(query_metadata.Bounds.from_points(points)),
			matching_group = -1, pool = query_metadata.QueryPool.Ground,
		})
	end
	return assert(BoardWorld.with_query_metadata(tris, { packed_surfaces = table.create(#tris, 0), meshes = meshes, static_edges = {}, island_flags = 0 } :: any))
end

local function same_primitive(p: any, t: any): boolean
	if p.kind ~= t[1] then
		return false
	end
	if p.kind == "Sphere" then
		return u.same_v(p.sphere.center, t[2]) and u.same(p.sphere.radius, t[3])
	elseif p.kind == "Capsule" then
		return u.same_v(p.center, t[2]) and u.same_v(p.axis, t[3]) and u.same(p.half_length, t[4]) and u.same(p.radius, t[5])
	elseif p.kind == "RoundedBox" then
		local c = p.basis.columns
		return u.same_v(p.center, t[2]) and u.same_f3(c[1], t[3]) and u.same_f3(c[2], t[4]) and u.same_f3(c[3], t[5])
			and u.same_v(p.half_extents, t[6]) and u.same(p.radius, t[7])
	end
	local tri = p.triangle
	return u.same_v(tri.vertices[1], t[2]) and u.same_v(tri.vertices[2], t[3]) and u.same_v(tri.vertices[3], t[4])
		and u.same_v(tri.feature.normal, t[5])
end

local QUERY = {
	volume_padding = f32(0.05), maximum_separating_distance = f32(0.5),
	edge_cos_bend_normal_threshold = f32(0.999), convexity_epsilon = f32(0.01), is_object = false,
}
local RETENTION = { capacity = 0xFFFFFFFF, duplicate_distance_squared = -1.0, deferred_reduction = true }

return function(report: harness.Report)
	harness.test(report, "colliders: стоковая доска 2 × 200 тиков по рампе vs Rust", function()
		local ok_stock, stock = pcall(require, "../../../src/skate_data/stock")
		local ok_golden, golden = pcall(require, "../../golden/colliders")
		if not ok_stock or not ok_golden then
			table.insert(report.lines, "      пропуск: нет данных игры (src/skate_data/stock)")
			return
		end
		local data = collections.expect(collections.Collections.from_data(stock :: any))
		local settings = assert(settings_mod.PhysicsSettings.load(data))
		local world = build_world()
		for si, sc in golden :: any do
			local spawn = drive_frames.RetailAffineTransform.IDENTITY()
			spawn.translation = u.V(sc.spawn)
			local b = BoardRuntime.new(settings.masses, settings.authored, spawn, settings.step.simulation, board_runtime.BoardMotion.Active)
			for ti, tick in sc.ticks do
				BoardRuntime.clear_forces(b)
				if ti <= 30 then
					force_queue.BoardForceQueue.append(BoardRuntime.forces_mut(b),
						{ tag = 1, force_world = vector.create(0.0, 0.0, f32(-20.0 - 10.0 * (si - 1))), point_body = vector.zero })
				end
				local volumes = colliders.world_volumes(b, settings)
				assert(#volumes == #tick.volumes, string.format("сцена %d тик %d: %d объёмов, в Rust %d", si, ti, #volumes, #tick.volumes))
				for k, want in tick.volumes do
					assert(same_primitive(volumes[k].primitive, want), string.format("сцена %d тик %d: объём %d (%s) разошёлся", si, ti, k, want[1]))
				end
				local collisions = table.clone(BoardWorld.query_primitives(world, volumes, QUERY, RETENTION))
				assert(#collisions == tick.count, string.format("сцена %d тик %d: %d контактов, в Rust %d", si, ti, #collisions, tick.count))
				BoardRuntime.advance(b, collisions, { fb(tick.targets[1]), fb(tick.targets[2]) }, settings.step)
				local r = BoardRuntime.bodies(b)[7].rates
				local d = tick.deck
				assert(u.same_v(r.position, d[1]) and u.same_v(r.linear_velocity, d[2]) and u.same_q(r.orientation, d[3]),
					string.format("сцена %d тик %d: дека разошлась", si, ti))
			end
		end
	end)
end
