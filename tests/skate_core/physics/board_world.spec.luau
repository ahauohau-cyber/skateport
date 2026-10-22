--!strict
-- Сверка board_world (лучи, вода, query_primitives, широкая фаза) и доски,
-- катящейся по миру, с настоящим skate-core (golden/src/world.rs).

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local board_world = require("../../../src/skate_core/physics/board_world")
local query_metadata = require("../../../src/skate_core/physics/board_world/query_metadata")
local board_runtime = require("../../../src/skate_core/physics/board_runtime")
local board_step = require("../../../src/skate_core/physics/board_step")
local board = require("../../../src/skate_core/physics/board")
local drive_frames = require("../../../src/skate_core/physics/drive_frames")
local drive_parameters = require("../../../src/skate_core/physics/drive_parameters")
local mass = require("../../../src/skate_core/physics/mass")
local rigid_body = require("../../../src/skate_core/physics/rigid_body")
local force_queue = require("../../../src/skate_core/physics/force_queue")
local golden = require("../../golden/world") :: any

local fb, f32 = u.fb, rt.f32
local BoardWorld = board_world.BoardWorld
local BoardRuntime = board_runtime.BoardRuntime
local CollisionBody = board_step.CollisionBody

local IDENTITY_BASIS = { columns = { { 1.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, { 0.0, 0.0, 1.0 } } }

local function build_world(): any
	local material = { static_friction = 0.0, dynamic_friction = 0.0, restitution = 1.0 }
	local tris = {}
	for _, t in golden.triangles do
		local tri = board_world.WorldTriangle.from_vertices(
			{ u.V(t[1]), u.V(t[2]), u.V(t[3]) }, material, t[4], t[5], u.F3(t[6]), fb(t[7]))
		assert(tri, "треугольник эталона отвергнут")
		table.insert(tris, tri)
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
	local metadata = { packed_surfaces = table.create(#tris, 0), meshes = meshes, static_edges = {}, island_flags = 0 }
	local world, err = BoardWorld.with_query_metadata(tris, metadata :: any)
	assert(world, err)
	return world
end

local function same_collision(c: any, t: any): boolean
	return c.body_a.kind == "Board" and c.body_a.id == t[1]
		and u.same_v(c.contact.position_on_a, t[2])
		and u.same_v(c.contact.position_on_b, t[3])
		and u.same_v(c.contact.normal, t[4])
		and u.same(c.contact.restitution, t[5])
		and u.same(c.contact.static_friction, t[6])
		and u.same(c.contact.dynamic_friction, t[7])
		and c.contact.tag == t[8]
end

local QUERY = {
	volume_padding = f32(0.05), maximum_separating_distance = f32(0.5),
	edge_cos_bend_normal_threshold = f32(0.999), convexity_epsilon = f32(0.01), is_object = false,
}
local RETENTION = { capacity = 0xFFFFFFFF, duplicate_distance_squared = -1.0, deferred_reduction = true }

return function(report: harness.Report)
	harness.test(report, "board_world: 400 лучей query_swept_line vs Rust", function()
		local world = build_world()
		for i, l in golden.lines do
			local hit = BoardWorld.query_swept_line(world, u.V(l[1]), u.V(l[2]), fb(l[3]))
			local want = l[4]
			if want == false then
				assert(hit == nil, "луч " .. i .. ": лишнее попадание")
			else
				assert(hit, "луч " .. i .. ": нет попадания")
				assert(u.same_v(hit.geometry.position, want[1]) and u.same_v(hit.geometry.normal, want[2])
					and u.same(hit.geometry.fraction, want[3]) and hit.tag == want[4], "луч " .. i .. ": расхождение")
			end
		end
	end)

	harness.test(report, "board_world: 100 точек water_surface_at vs Rust", function()
		local world = build_world()
		for i, w in golden.water do
			local s = BoardWorld.water_surface_at(world, u.V(w[1]), f32(0.2), 1.0)
			if w[2] == false then
				assert(s == nil, "вода " .. i .. ": лишняя поверхность")
			else
				assert(s and u.same(s, w[2]), "вода " .. i .. ": расхождение")
			end
		end
	end)

	harness.test(report, "board_world: 300 наборов query_primitives vs Rust", function()
		local world = build_world()
		for i, case in golden.primitives do
			local vols = {}
			for _, v in case.volumes do
				local p = v.prim
				local prim: any
				if p.kind == "Sphere" then
					prim = { kind = "Sphere", sphere = { center = u.V(p.center), radius = fb(p.radius) } }
				elseif p.kind == "Capsule" then
					prim = { kind = "Capsule", center = u.V(p.center), axis = u.V(p.axis), half_length = fb(p.half_length), radius = fb(p.radius) }
				else
					prim = { kind = "RoundedBox", center = u.V(p.center), basis = IDENTITY_BASIS, half_extents = u.V(p.half_extents), radius = fb(p.radius) }
				end
				table.insert(vols, {
					collision_group = v.group,
					body = CollisionBody.Board(board.BodyId.ORDER[v.body + 1]),
					primitive = prim,
					motion = { linear_velocity = u.V(v.motion[1]), angular_velocity = u.V(v.motion[2]),
						force_acceleration = u.V(v.motion[3]), torque_acceleration = u.V(v.motion[4]) },
					material = { static_friction = fb(v.mat[1]), dynamic_friction = fb(v.mat[2]), restitution = fb(v.mat[3]) },
				})
			end
			local out = BoardWorld.query_primitives(world, vols, QUERY, RETENTION)
			assert(#out == #case.out, string.format("набор %d: %d контактов, в Rust %d", i, #out, #case.out))
			for k, want in case.out do
				assert(same_collision(out[k], want), string.format("набор %d, контакт %d: расхождение", i, k))
			end
		end
	end)

	harness.test(report, "board_world: доска 150 тиков на рампе (мир + BoardRuntime) vs Rust", function()
		local world = build_world()
		local gravity = vector.create(0.0, f32(-9.81), 0.0)
		local simulation = rigid_body.RetailSimulationStep.fixed_60_hz(0, f32(0.001), gravity)
		local settings = {
			simulation = simulation, iterations = 50,
			base_truck_transforms = drive_frames.default_truck_transforms(),
			truck_dynamics = drive_parameters.retail_truck_drive_dynamics(drive_parameters.RetailTruckDriveSettings.STOCK()),
			force_point_y_offset = f32(0.05),
		}
		local spawn = drive_frames.RetailAffineTransform.IDENTITY()
		spawn.translation = u.V(golden.ride_spawn)
		local b = BoardRuntime.new(mass.default_skateboard_mass_properties(), drive_frames.default_body_transforms(),
			spawn, simulation, board_runtime.BoardMotion.Active)
		local wheel = {
			radius = board.RETAIL_WHEEL_RADIUS,
			material = { static_friction = f32(0.8), dynamic_friction = f32(0.7), restitution = 0.0 },
			query = QUERY, retention = RETENTION,
		}
		for ti, tick in golden.ride do
			BoardRuntime.clear_forces(b)
			if ti <= 20 then
				force_queue.BoardForceQueue.append(BoardRuntime.forces_mut(b),
					{ tag = 1, force_world = vector.create(0.0, 0.0, -25.0), point_body = vector.zero })
			end
			local collisions = table.clone(BoardWorld.query(world, b, wheel :: any))
			assert(#collisions == #tick.collisions, string.format("тик %d: %d контактов, в Rust %d", ti, #collisions, #tick.collisions))
			for k, want in tick.collisions do
				assert(same_collision(collisions[k], want), string.format("тик %d, контакт %d: расхождение", ti, k))
			end
			BoardRuntime.advance(b, collisions, { fb(tick.targets[1]), fb(tick.targets[2]) }, settings :: any)
			local r = BoardRuntime.bodies(b)[7].rates
			local d = tick.deck
			assert(u.same_v(r.position, d[1]) and u.same_v(r.linear_velocity, d[2]) and u.same_v(r.angular_velocity, d[3])
				and u.same_q(r.orientation, d[4]), string.format("тик %d: дека разошлась", ti))
		end
	end)
end
