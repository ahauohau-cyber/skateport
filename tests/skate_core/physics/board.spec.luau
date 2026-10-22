--!strict
-- Сверка board_runtime / board_step / board_pose / force_queue / contact_feedback
-- с настоящим skate-core (golden/src/board.rs): доска 90 тиков на плоскости.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local board_runtime = require("../../../src/skate_core/physics/board_runtime")
local board_step = require("../../../src/skate_core/physics/board_step")
local drive_frames = require("../../../src/skate_core/physics/drive_frames")
local drive_parameters = require("../../../src/skate_core/physics/drive_parameters")
local mass = require("../../../src/skate_core/physics/mass")
local rigid_body = require("../../../src/skate_core/physics/rigid_body")
local force_queue = require("../../../src/skate_core/physics/force_queue")
local collision_info = require("../../../src/skate_core/physics/contact_feedback/collision_info")
local compression = require("../../../src/skate_core/physics/contact_feedback/compression")
local golden = require("../../golden/board")

local fb = u.fb
local BoardRuntime = board_runtime.BoardRuntime

local function same_snap(s: any, t: { any }): boolean
	local r = s.rates
	return s.state_flags == t[1]
		and u.same_q(r.orientation, t[2])
		and u.same_b(r.basis, t[3])
		and u.same_b(r.world_inverse_inertia, t[4])
		and u.same_v(r.position, t[5])
		and u.same_v(r.linear_velocity, t[6])
		and u.same_v(r.angular_velocity, t[7])
		and u.same_v(r.force_acceleration, t[8])
		and u.same_v(r.torque_acceleration, t[9])
		and u.same(r.kinetic_energy, t[10])
		and r.cool_down == t[11]
end

local function same_report(rep: any, t: any): boolean
	return rep.part == t.part
		and board_step.CollisionBody.eq(rep.other, t.other)
		and rep.is_body_a == t.is_a
		and u.same_v(rep.normal, t.normal)
		and u.same_v(rep.position, t.position)
		and u.same_v(rep.relative_linear_velocity, t.rel)
		and rep.other_surface == t.surface
		and u.same_v(rep.normal_force_on_a, t.nf)
		and u.same_v(rep.friction_force_on_a, t.ff)
		and u.same_v(rep.tangents[1], t.t0)
		and u.same_v(rep.tangents[2], t.t1)
end

return function(report: harness.Report)
	harness.test(report, "board_runtime: 6 сценариев × 90 тиков доски на плоскости vs Rust", function()
		local gravity = vector.create(0.0, rt.f32(-9.81), 0.0)
		local total_ticks, bad_ticks, first = 0, 0, nil
		for si, sc in golden.scenarios do
			local simulation = rigid_body.RetailSimulationStep.fixed_60_hz(0, rt.f32(0.001), gravity)
			local settings: board_step.BoardStepSettings = {
				simulation = simulation,
				iterations = sc.iterations,
				base_truck_transforms = drive_frames.default_truck_transforms(),
				truck_dynamics = drive_parameters.retail_truck_drive_dynamics(drive_parameters.RetailTruckDriveSettings.STOCK()),
				force_point_y_offset = fb(sc.y_offset),
			}
			local b = BoardRuntime.new(
				mass.default_skateboard_mass_properties(),
				drive_frames.default_body_transforms(),
				u.A(sc.spawn),
				simulation,
				board_runtime.BoardMotion.Active
			)
			local ok = same_snap(b.hook.body, sc.init_hook)
			for i, want in sc.init do
				ok = ok and same_snap(b.bodies[i], want)
			end
			if not ok then
				bad_ticks += 1
				first = first or string.format("сценарий %d, начало", si)
			end
			for ti, tick in sc.ticks do
				total_ticks += 1
				if tick.op ~= nil then
					if tick.op.kind == "set_transform" then
						BoardRuntime.set_transform(b, u.A(tick.op.t))
					else
						BoardRuntime.reset_physical(b, drive_frames.default_body_transforms(), u.A(tick.op.t), tick.op.flags, gravity)
					end
				end
				BoardRuntime.clear_forces(b)
				for _, f in tick.forces do
					force_queue.BoardForceQueue.append(b.forces, { tag = f[1], force_world = u.V(f[2]), point_body = u.V(f[3]) })
				end
				local collisions = {}
				for _, c in tick.collisions do
					local i = c.input
					table.insert(collisions, {
						body_a = c.a,
						body_b = c.b,
						contact = {
							position_on_a = u.V(i[1]),
							position_on_b = u.V(i[2]),
							normal = u.V(i[3]),
							restitution = fb(i[4]),
							static_friction = fb(i[5]),
							dynamic_friction = fb(i[6]),
							tag = i[7],
						},
					})
				end
				BoardRuntime.advance(b, collisions, { fb(tick.targets[1]), fb(tick.targets[2]) }, settings)
				local good = same_snap(b.hook.body, tick.hook)
				for i, want in tick.bodies do
					good = good and same_snap(b.bodies[i], want)
				end
				local parts = BoardRuntime.part_transforms(b)
				for i, want in tick.parts do
					good = good and u.same_a(parts[i], want)
				end
				local reports = BoardRuntime.contact_reports(b)
				good = good and #reports == #tick.reports
				for i, want in tick.reports do
					good = good and reports[i] ~= nil and same_report(reports[i], want)
				end
				if not good then
					bad_ticks += 1
					first = first or string.format("сценарий %d, тик %d", si, ti)
				end
			end
		end
		table.insert(report.lines, string.format("      тиков: %d, расхождений %d", total_ticks, bad_ticks))
		harness.check(bad_ticks == 0, "первое расхождение: " .. tostring(first))
	end)

	harness.test(report, "contact_feedback: choose_surface vs Rust", function()
		u.count(report, harness, "choose_surface", golden.surfaces, function(case)
			return collision_info.choose_surface(case[1], case[2], case[3]) == case[4]
		end)
	end)

	harness.test(report, "contact_feedback: average_wheel_compressions vs Rust", function()
		u.count(report, harness, "average_wheel_compressions", golden.compressions, function(case)
			local function row(t: { number }): { number }
				return { fb(t[1]), fb(t[2]), fb(t[3]), fb(t[4]) }
			end
			local m = { row(case[1][1]), row(case[1][2]), row(case[1][3]), row(case[1][4]) }
			local w = { row(case[2][1]), row(case[2][2]), row(case[2][3]), row(case[2][4]) }
			local h = compression.average_wheel_compressions(m, w, fb(case[3]))
			return u.same(h[1], case[4]) and u.same(h[2], case[5])
		end)
	end)

	harness.test(report, "force_queue: total_body_mass vs Rust", function()
		u.count(report, harness, "total_body_mass", golden.total_mass, function(case)
			local xs = {}
			for i, x in case[1] do
				xs[i] = fb(x)
			end
			return u.same(force_queue.total_body_mass(xs), case[2])
		end)
	end)
end
