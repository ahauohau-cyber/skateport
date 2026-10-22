--!strict
-- Сверка skate_game/physics/riding_outputs с копией Rust-кода в
-- golden/src/riding_outputs.rs: стоковая доска 240 тиков по рампе; каждый тик —
-- лучи колёс, щупы деки/стены, reckoning, post-physics и toolkit.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local collections = require("../../../src/skate_data/collections")
local settings_mod = require("../../../src/skate_game/physics/settings")
local colliders = require("../../../src/skate_game/physics/colliders")
local riding_outputs = require("../../../src/skate_game/physics/riding_outputs")
local board_world = require("../../../src/skate_core/physics/board_world")
local query_metadata = require("../../../src/skate_core/physics/board_world/query_metadata")
local board_runtime = require("../../../src/skate_core/physics/board_runtime")
local board_toolkit = require("../../../src/skate_core/physics/board_toolkit")
local drive_frames = require("../../../src/skate_core/physics/drive_frames")
local force_queue = require("../../../src/skate_core/physics/force_queue")
local world_golden = require("../../golden/world") :: any

local fb, f32, to_bits = u.fb, rt.f32, rt.to_bits
local BoardWorld = board_world.BoardWorld
local BoardRuntime = board_runtime.BoardRuntime
local RidingOutputs = riding_outputs.RidingOutputs
local BoardProbes = riding_outputs.BoardProbes
local BoardToolkit = board_toolkit.BoardToolkit

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

local function bits4(v: vector): { number }
	return { to_bits(v.x), to_bits(v.y), to_bits(v.z), 0 }
end
local function same4(a: { number }, t: { number }): boolean
	return u.same(a[1], t[1]) and u.same(a[2], t[2]) and u.same(a[3], t[3]) and u.same(a[4], t[4])
end
local function same_probe(p: any, t: any): boolean
	return u.same_v(p.start, t[1]) and u.same_v(p.point, t[2]) and u.same_v(p.normal, t[3]) and p.surface_tag == t[4] and p.hit == t[5]
end

local QUERY = {
	volume_padding = f32(0.05), maximum_separating_distance = f32(0.5),
	edge_cos_bend_normal_threshold = f32(0.999), convexity_epsilon = f32(0.01), is_object = false,
}
local RETENTION = { capacity = 0xFFFFFFFF, duplicate_distance_squared = -1.0, deferred_reduction = true }

return function(report: harness.Report)
	harness.test(report, "riding_outputs: стоковая доска 240 тиков с выходами катания vs Rust", function()
		local ok_stock, stock = pcall(require, "../../../src/skate_data/stock")
		local ok_golden, golden = pcall(require, "../../golden/riding_outputs")
		if not ok_stock or not ok_golden then
			table.insert(report.lines, "      пропуск: нет данных игры (src/skate_data/stock)")
			return
		end
		local g = golden :: any
		local data = collections.expect(collections.Collections.from_data(stock :: any))
		local settings = assert(settings_mod.PhysicsSettings.load(data))
		local world = build_world()
		local flags = 0x2000
		local spawn = drive_frames.RetailAffineTransform.IDENTITY()
		spawn.translation = u.V(g.spawn)
		local b = BoardRuntime.new(settings.masses, settings.authored, spawn, settings.step.simulation, board_runtime.BoardMotion.Active)
		local riding = assert(RidingOutputs.load(data, b, flags))
		assert(u.same(riding.heading_adjust_factor, g.load[1]) and u.same(riding.motion.forward_speed, g.load[2]), "load")
		local dt = settings.step.simulation.time_step
		local retained = { 0.0, 1.0, 0.0, 0.0 }
		for ti, w in g.ticks do
			local tick = ti - 1
			local function check(cond: boolean, what: string)
				if not cond then
					error(string.format("тик %d: %s", tick, what), 2)
				end
			end
			BoardRuntime.clear_forces(b)
			if tick < 40 then
				force_queue.BoardForceQueue.append(BoardRuntime.forces_mut(b), { tag = 1, force_world = vector.create(0, 0, -24), point_body = vector.zero })
			end
			assert(RidingOutputs.start_wheel_queries(riding, b, world))
			assert(RidingOutputs.finish_wheel_queries(riding))
			local processed = {
				vectors_464_480_496_512_528 = { bits4(riding.ground.wheel_normal), { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, bits4(riding.ground.overall_normal) },
				vectors_544_560_592_608 = { bits4(riding.reckoning.up), { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } },
				scalar_2652 = riding.motion.speed,
				scalar_2616 = math.abs(riding.motion.forward_speed),
				wheel_count_2556 = riding.ground.wheel_contact_count,
				state_2508 = if tick % 50 < 25 then 100 else 101,
				time_on_ground_2752 = f32(f32(tick) * dt),
			}
			check(processed.state_2508 == w.state, "state")
			local spin = fb(w.spin)
			local balance = fb(w.balance)
			RidingOutputs.update_ground_reckoning(riding, b, { com_to_deck = vector.create(0, f32(0.9), f32(0.05)), body_spin = spin }, flags, balance, w.coffin, processed)
			local heading = RidingOutputs.update_input_heading(riding, riding.ground.wheel_normal.y, riding.motion.forward_speed)
			check(u.same(heading, w.heading), "heading_adjust_factor")
			local volumes = colliders.world_volumes(b, settings)
			local contacts = table.clone(BoardWorld.query_primitives(world, volumes, QUERY, RETENTION))
			check(#contacts == w.contacts, string.format("контактов %d, в Rust %d", #contacts, w.contacts))
			BoardRuntime.advance(b, contacts, { 0.0, 0.0 }, settings.step)
			assert(RidingOutputs.finish_post_physics(riding, b, false, flags, dt))
			local toolkit = BoardToolkit.from_board(b, flags, riding.motion.forward_speed,
				{ riding.ground.wheel_normal.x, riding.ground.wheel_normal.y, riding.ground.wheel_normal.z, 0.0 }, retained)
			retained = toolkit.filtered_normal
			BoardProbes.prepare_wall(riding.probes, processed, toolkit)

			local gr, wl, rc, rf, m = riding.ground, riding.wheel_lines, riding.reckoning, riding.reckoning_frames, riding.motion
			local wg = w.ground
			check(u.same_v(gr.wheel_normal, wg[1]) and u.same_v(gr.overall_normal, wg[2]) and gr.wheel_contact_count == wg[3] and gr.part_contact_count == wg[4], "ground: нормали/счётчики")
			for i = 1, 7 do
				check(u.same_v(gr.accelerations[i], wg[5][i]), "ground: ускорения")
			end
			check(u.same(gr.time_without_wheel_contact, wg[6]), "ground: время")
			for i = 1, 4 do
				check(u.same(wl.distances[i], w.lines[1][i]), "lines: расстояния")
			end
			check(u.same(wl.minimum_distance, w.lines[2]), "lines: минимум")
			check(same_probe(riding.probes.deck, w.deck_probe), "щуп деки")
			check(same_probe(riding.probes.wall, w.wall_probe), "щуп стены")
			local r = w.reck
			check(u.same_v(rc.up, r[1]) and u.same_v(rc.target, r[2]) and u.same_v(rc.up_velocity, r[3]) and u.same_v(rc.ground_normal, r[4]) and u.same(rc.ground_blend, r[5]), "reckoning")
			local fr = w.frames
			check(same4(rf.system[1], fr[1]) and same4(rf.system[3], fr[2]) and same4(rf.heading, fr[3]) and u.same(rf.target_lean_angle, fr[4]) and same4(rf.lateral_tilt, fr[5]), "reckoning_frames")
			local mo = w.motion
			check(u.same(m.speed, mo[1]) and u.same(m.ground_speed, mo[2]) and u.same(m.forward_speed, mo[3]) and u.same_v(m.linear_velocity, mo[4]) and u.same_v(m.ground_velocity, mo[5]), "motion")
			check(u.same_words(riding.body_spin.words, w.body_spin), "body_spin")
			local deck = BoardRuntime.bodies(b)[7].rates
			check(u.same_v(deck.position, w.deck[1]) and u.same_v(deck.linear_velocity, w.deck[2]), "дека")
			for i = 1, 4 do
				check(u.same(BoardRuntime.bodies(b)[i].inertia.angular_drag, w.drag[i]), "angular_drag")
			end
			check(same4(toolkit.filtered_normal, w.toolkit), "toolkit")
		end
	end)
end
