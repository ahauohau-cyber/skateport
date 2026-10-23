--!strict
-- Сверка physics/skeleton_root и physics/skeleton_body с настоящим skate-core
-- (golden/src/skel.rs) и перенос Rust-тестов skeleton_root и
-- skeleton_body/tests/collision_feedback.rs. Эталон собран из данных игры:
-- в git не идёт, без него проверяются только Rust-тесты.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local sar = require("../../../src/skate_core/physics/skeleton_animation_record")
local skeleton_root = require("../../../src/skate_core/physics/skeleton_root")
local sb = require("../../../src/skate_core/physics/skeleton_body")
local rigid_body = require("../../../src/skate_core/physics/rigid_body")

local f32 = rt.f32
local IDENTITY = sar.IDENTITY
local SkeletonRootFrames = skeleton_root.SkeletonRootFrames
local SkeletonBody = sb.SkeletonBody
local SkeletonBodyDefinition = sb.SkeletonBodyDefinition
local SkeletonJoints = sb.SkeletonJoints
local SkeletonDrives = sb.SkeletonDrives
local SkeletonTargets = sb.SkeletonTargets :: any
local SkeletonCollisionMode = sb.SkeletonCollisionMode
local SkeletonCollisionFeedback = sb.SkeletonCollisionFeedback :: any
local SkeletonPoseErrors = sb.SkeletonPoseErrors
local BoneDriveDynamics = sb.BoneDriveDynamics

local function deep(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = deep(v)
	end
	return c
end

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end

local function load_golden(): any
	local ok, g = pcall(require, "../../golden/skel")
	if ok and type(g) == "table" then
		return g
	end
	return nil
end

local function simulation(): any
	return rigid_body.RetailSimulationStep.fixed_60_hz(30, f32(0.0005), vector.create(0.0, -9.81, 0.0))
end

local function test_settings(): any
	return {
		body = {
			enabled = true,
			normal_material = { static_friction = 0.0, dynamic_friction = 0.0, restitution = 0.0 },
			compliant = table.create(24, true),
			priority = table.create(24, 0.0),
			effect_time = 0.25,
		},
		response = { force_scale = 0.5, velocity_scale = 9.0, divisor = 1000.0, region_scale = 10.0 },
		small_object_mass = 5.5,
		ground_plane_max_distance = f32(0.3),
		ground_plane_max_angle = f32(0.8),
		skater_scalar = 0.5,
		ai_scalar = 1.0,
		groin_offset = { 0.0, 0.0, 0.0, 0.0 },
		face_offset = { 0.0, 0.0, 0.0, 0.0 },
		groin_radius = 0.0,
		face_radius = 0.0,
	}
end

local function identity26(): { any }
	local t = {}
	for i = 1, 26 do
		t[i] = IDENTITY()
	end
	return t
end

local function test_input(physical: any, frames: any, weights: any): any
	return {
		dt = 0.125,
		plane_point = { 0.0, 0.0, 0.0, 0.0 },
		plane_normal = { 0.0, 1.0, 0.0, 0.0 },
		reference_velocity = { 2.0, 0.0, 0.0, 0.0 },
		com_velocity = { 0.0, 0.0, 0.0, 0.0 },
		ragdoll = false,
		disable_ground_filter = false,
		ai_collision_scalar = false,
		offboard = false,
		entering_offboard = false,
		category_600 = false,
		request_partial_ragdoll = false,
		physical = physical,
		part_weights = weights,
		body_frames = frames,
	}
end

local function test_report(normal: { number }): any
	return {
		part = 2,
		normal = normal,
		point = { 0.0, 0.0, 0.0, 0.0 },
		tag = 0,
		other_group = 0,
		other_entity = nil,
		body_a = { state_flags = 4, inverse_mass = 0.5, linear_velocity = { 2.0, 0.0, 0.0, 0.0 } },
		body_b = { state_flags = 1, inverse_mass = 0.0, linear_velocity = { 0.0, 0.0, 0.0, 0.0 } },
		side_a = true,
		solved_vector = { 100.0, 0.0, 0.0, 0.0 },
	}
end

return function(report: harness.Report)
	-- Rust-тесты skeleton_root.
	harness.test(report, "skeleton_root: actual_board_prediction_and_source_heading_build_the_animation_frame", function()
		local roots = SkeletonRootFrames.default()
		local board = IDENTITY()
		board[4] = { 10.0, 2.0, 0.0, 0.0 }
		local animation = IDENTITY()
		animation[4] = { 1.0, 2.0, 3.0, 0.0 }
		SkeletonRootFrames.update(roots, board, { 5.0, 0.0, 0.0, 0.0 }, f32(0.02), animation, IDENTITY())
		assert(math.abs(roots.predicted_board_position[1] - f32(10.1)) < 1e-6)
		local recentered = sar.compose_affine(roots.animation_to_board, animation)
		for _, v in recentered[4] do
			assert(math.abs(v) < 1e-6)
		end
		assert(not roots.initialize_heading)
		roots.supplied_prediction = { 30.0, 40.0, 50.0, 0.0 }
		SkeletonRootFrames.update(roots, board, { 5.0, 0.0, 0.0, 0.0 }, f32(0.02), animation, IDENTITY())
		check(u.diff(roots.predicted_board_position, { 30.0, 40.0, 50.0, 0.0 }), "prediction")
		assert(roots.supplied_prediction == nil)
		check(u.diff(roots.previous_board_position, board[4]), "previous")
		local product = sar.compose_affine(roots.world_to_animation, roots.animation_to_world)
		local id = IDENTITY()
		for axis = 1, 4 do
			for lane = 1, 4 do
				assert(math.abs(product[axis][lane] - id[axis][lane]) < 1e-5)
			end
		end
	end)

	harness.test(report, "skeleton_root: degenerate_axis_falls_back_to_identity", function()
		local source = IDENTITY()
		source[1] = { 0.0, 0.0, 0.0, 0.0 }
		source[2] = { 0.0, 0.0, 0.0, 0.0 }
		source[3] = { 0.0, 0.0, 0.0, 0.0 }
		local result = skeleton_root.orthonormalize(source)
		local id = IDENTITY()
		for axis = 1, 3 do
			check(u.diff(result[axis], id[axis]), "axis")
		end
	end)

	-- Rust-тесты skeleton_body/tests/collision_feedback.rs.
	harness.test(report, "skeleton_body: handplant_contact_mask_survives_updates_and_restores_on_exit", function()
		local collision = SkeletonCollisionMode.new_normal(test_settings().body, false)
		for _ = 1, 3 do
			SkeletonCollisionMode.disable_handplant_contacts(collision, 2)
			SkeletonCollisionMode.select_driven(collision, 5)
			for _, part in { 1, 3, 4, 7, 8 } do
				assert(not collision.parts[part + 1].enabled, "plant contact part " .. part)
			end
			for _, part in { 2, 5, 6, 9, 10, 15, 19 } do
				assert(collision.parts[part + 1].enabled, "unaffected part " .. part)
			end
			SkeletonCollisionMode.finish_contact_frame(collision)
			assert(collision.pending_reenable)
			assert(collision.disable_count[4] == 1)
			assert(not collision.parts[4].enabled)
		end
		SkeletonCollisionMode.finish_contact_frame(collision)
		assert(not collision.pending_reenable)
		for _, part in { 1, 3, 4, 7, 8 } do
			assert(collision.parts[part + 1].enabled)
			assert(collision.disable_count[part + 1] == 0)
		end
	end)

	harness.test(report, "skeleton_body: support_contact_is_filtered_but_wall_contact_changes_drives_and_recovers", function()
		local physical = sb.SkeletonPhysicalRecord.default()
		physical.velocities[3] = { 2.0, 0.0, 0.0, 0.0 }
		local input = test_input(physical, identity26(), table.create(24, 1.0))
		local collision = SkeletonCollisionFeedback.new(test_settings())
		SkeletonCollisionFeedback.update(collision, input, { test_report({ 0.0, 1.0, 0.0, 0.0 }) })
		assert(collision.flags.any)
		assert(not collision.flags.compliant)
		assert(collision.drive_weight == 1.0)
		SkeletonCollisionFeedback.update(collision, input, { test_report({ -1.0, 0.0, 0.0, 0.0 }) })
		assert(collision.flags.compliant and collision.flags.has_impulse)
		assert(collision.bones[3].force == 2.0)
		assert(collision.drive_weight == 0.0)
		assert(rt.is_finite(collision.regions[2].weighted_force))
		SkeletonCollisionFeedback.update(collision, input, {})
		assert(collision.drive_weight == 0.5)
		SkeletonCollisionFeedback.update(collision, input, {})
		assert(collision.drive_weight == 1.0)
	end)

	harness.test(report, "skeleton_body: tiny_dynamic_opponent_is_noncompliant_even_for_compliant_bone", function()
		local physical = sb.SkeletonPhysicalRecord.default()
		physical.velocities[3] = { 2.0, 0.0, 0.0, 0.0 }
		local input = test_input(physical, identity26(), table.create(24, 1.0))
		local contact = test_report({ -1.0, 0.0, 0.0, 0.0 })
		contact.body_b.state_flags = 4
		contact.body_b.inverse_mass = 1.0
		local collision = SkeletonCollisionFeedback.new(test_settings())
		SkeletonCollisionFeedback.update(collision, input, { contact })
		assert(collision.bones[3].force == 1.0)
		assert(collision.flags.noncompliant)
		assert(not collision.flags.compliant and not collision.flags.has_impulse)
	end)

	harness.test(report, "skeleton_body: contact_planes_constrain_physical_pose_error_without_inventing_impulse", function()
		local collision = SkeletonCollisionFeedback.new(test_settings())
		local axis = { 0.0, 1.0, 0.0, 0.0 }
		local err = { 2.0, 3.0, 0.0, 0.0 }
		check(u.diff(SkeletonCollisionFeedback.filter_error(collision, err, axis), { 0.0, 0.0, 0.0, 0.0 }), "empty")
		table.insert(collision.planes, { normal = { 1.0, 0.0, 0.0, 0.0 }, part = 2 })
		local filtered = SkeletonCollisionFeedback.filter_error(collision, err, axis)
		assert(math.abs(filtered[1] - 2.0) < 1e-5)
		assert(filtered[2] == 0.0)
		local diagonal = f32(math.sqrt(0.5))
		collision.planes[1].normal = { diagonal, 0.0, diagonal, 0.0 }
		local projected = SkeletonCollisionFeedback.filter_error(collision, err, axis)
		assert(math.abs(projected[1] - 1.0) < 1e-5)
		assert(math.abs(projected[3] - 1.0) < 1e-5)
		collision.planes[1].normal = { -1.0, 0.0, 0.0, 0.0 }
		check(u.diff(SkeletonCollisionFeedback.filter_error(collision, err, axis), { 0.0, 0.0, 0.0, 0.0 }), "behind")
	end)

	harness.test(report, "skeleton_body: a_moving_group_8_body_reaches_native_impact_feedback_for_a_stationary_actor", function()
		local physical = sb.SkeletonPhysicalRecord.default()
		for _, offboard in { false, true } do
			local input = test_input(physical, identity26(), table.create(24, 1.0))
			input.offboard = offboard
			input.reference_velocity = { 0.0, 0.0, 0.0, 0.0 }
			local contact = test_report({ -1.0, 0.0, 0.0, 0.0 })
			contact.other_group = 8
			contact.body_a.linear_velocity = { 0.0, 0.0, 0.0, 0.0 }
			contact.body_b.state_flags = 4
			contact.body_b.inverse_mass = f32(1.0 / 1400.0)
			contact.body_b.linear_velocity = { 14.0, 0.0, 0.0, 0.0 }
			local collision = SkeletonCollisionFeedback.new(test_settings())
			SkeletonCollisionFeedback.update(collision, input, { contact })
			if offboard then
				-- TODO: в оригинале (коммит 2e16697) этот Rust-тест падает на offboard = true:
				-- ignore_ground отбрасывает контакт в точке плоскости. Порт повторяет
				-- поведение Rust, а не ожидание теста.
				assert(not collision.flags.group_8 and collision.maximum_group_8_force == 0.0)
				continue
			end
			assert(collision.flags.group_8 and collision.flags.has_impulse)
			assert(math.abs(collision.maximum_group_8_force - 14.0) < 1e-5)
			SkeletonCollisionFeedback.update(collision, input, {})
			assert(collision.maximum_group_8_force == 0.0)
		end
	end)

	local golden = load_golden()
	if not golden then
		return
	end

	harness.test(report, "physics/skeleton_root: 30 × 6 обновлений vs Rust", function()
		for i, seq in golden.root do
			local f = SkeletonRootFrames.default()
			for k, st in seq do
				if st.supplied ~= nil then
					f.supplied_prediction = table.clone(st.supplied)
				end
				if st.heading then
					f.initialize_heading = true
				end
				if st.kind == 3 then
					SkeletonRootFrames.update_teleport(f, st.board, st.animation_board, st.reckoning)
				elseif st.kind == 4 then
					SkeletonRootFrames.reset_initial_alignment(f, st.board)
				else
					SkeletonRootFrames.update(f, st.board, st.velocity, st.dt, st.animation_board, st.reckoning)
				end
				check(u.diff(f, st.out), "#" .. i .. "/" .. k)
			end
		end
	end)

	local sizes, bones, settings = golden.sizes, golden.bones, golden.body_settings
	harness.test(report, "physics/skeleton_body: SkeletonBodyDefinition без шляпы и со шляпой vs Rust", function()
		local h = golden.hat_in
		local hat = sb.HatGeometry.from_offsets(h.radius, h.thickness, h.angles, h.translation)
		for _, d in golden.definitions do
			local def = SkeletonBodyDefinition.new(sizes, bones, settings, if d.with_hat then hat else nil)
			check(u.diff(def.parts, d.parts), "parts")
			check(u.diff(def.animation_masses, d.masses), "masses")
		end
	end)

	local sim = simulation()
	local body = SkeletonBody.new(SkeletonBodyDefinition.new(sizes, bones, settings, nil), golden.body_new.authored, golden.body_new.spawn, sim)
	harness.test(report, "physics/skeleton_body: SkeletonBody new + 40 операций vs Rust", function()
		check(u.diff(body, golden.body_new.out), "new")
		for i, op in golden.body_ops do
			if op.op == 0 then
				SkeletonBody.set_part_transform(body, op.part, op.frame)
			elseif op.op == 1 then
				SkeletonBody.apply_part_displacement(body, op.part % 24, op.disp)
			else
				SkeletonBody.publish_physical_record(body, op.frame)
			end
			check(u.diff(body, op.out), "op#" .. i)
		end
	end)

	local joints_g = golden.joints
	local joints = SkeletonJoints.new(joints_g.initial_bones, joints_g.parents, joints_g.bones, joints_g.settings, joints_g.global)
	harness.test(report, "physics/skeleton_body: SkeletonJoints new + build vs Rust", function()
		check(u.diff(joints.records, joints_g.records), "records")
		check(u.diff(SkeletonJoints.build(joints, body.bodies, 10, sim.time_step), joints_g.built), "built")
	end)

	harness.test(report, "physics/skeleton_body: SkeletonDrives new/update/build и цели vs Rust", function()
		local dn = golden.drives_new
		local drives = SkeletonDrives.new(joints_g.initial_bones, dn.initial_mapped, dn.parents, body.animation_to_world, golden.body_new.spawn, sim, dn.settings)
		check(u.diff(drives, dn.out), "new")
		for i, op in golden.drives_ops do
			SkeletonDrives.update(drives, op.pose, op.partial, op.weight)
			if op.forced ~= nil then
				for _, b in drives.bones do
					if b ~= false then
						local bone = b :: any
						bone.dynamics.mode = op.forced
						local st = bone.dynamics.strengths
						for c = 0, 1 do
							BoneDriveDynamics.enable(bone.dynamics, c, st[c + 1], dn.settings.bone)
						end
					end
				end
			end
			local batch = SkeletonDrives.build(drives, body.bodies, 0, 26, sim.time_step)
			check(u.diff(drives, op.out), "op#" .. i)
			check(u.diff(batch.rows, op.rows), "rows#" .. i)
			check(u.diff(batch.identities, op.identities), "identities#" .. i)
			check(u.diff(batch.spy, op.spy), "spy#" .. i)
		end
		for i, t in golden.targets do
			SkeletonTargets.apply_future_deck_displacement(drives.targets, t.disp)
			local out = SkeletonTargets.update_positions(drives.targets, {
				animation_hips = t.h,
				animation_board = t.b,
				animation_to_world = t.a,
				inverse_board = t.i,
				skate_root = t.sr,
				com_frame = t.c,
				lifted_com_frame = t.l,
				teleporting = t.teleporting,
			}, body)
			check(u.diff(out, t.out), "target#" .. i)
			check(u.diff(drives.targets.bodies, t.target_bodies), "target bodies#" .. i)
			check(u.diff({ body.bodies[25].rates.linear_velocity, body.bodies[26].rates.linear_velocity }, t.extra_velocity), "extra#" .. i)
		end
	end)

	harness.test(report, "physics/skeleton_body: SkeletonCollisionMode 4 × 30 операций vs Rust", function()
		for si, seq in golden.modes do
			local settings_c = deep(golden.collision_settings)
			if seq.disabled then
				settings_c.enabled = false
			end
			local mode = SkeletonCollisionMode.new_normal(settings_c, seq.cull)
			local skel = SkeletonBody.new(SkeletonBodyDefinition.new(sizes, bones, settings, nil), golden.body_new.authored, golden.body_new.spawn, sim)
			local fs = test_settings()
			fs.body = settings_c
			local feedback = SkeletonCollisionFeedback.new(fs)
			for i, o in seq.ops do
				local op, a, b = o.op, o.a, o.b
				local err = false
				if op == 0 then
					SkeletonCollisionMode.disable_handplant_contacts(mode, a % 4)
				elseif op == 1 then
					local _, e = rt.catch(SkeletonCollisionMode.select_driven, mode, ({ 1, 3, 5, 6, 2, 0 })[a % 6 + 1])
					err = e ~= nil
				elseif op == 2 then
					SkeletonCollisionMode.normal_collision(mode)
				elseif op == 3 then
					SkeletonCollisionMode.disable_all(mode, a % 2 == 0)
				elseif op == 4 then
					SkeletonCollisionMode.enable_bone(mode, a % 24)
				elseif op == 5 then
					SkeletonCollisionMode.finish_contact_frame(mode)
				elseif op == 6 then
					SkeletonCollisionMode.normal_bone(mode, a % 24, b % 2 == 0)
				elseif op == 7 then
					SkeletonCollisionMode.restore_normal_properties(mode, skel)
				elseif op == 8 then
					SkeletonCollisionMode.apply_ragdoll_properties(mode, skel, a % 2 == 0, b % 2 == 0, o.drag, o.mats)
				elseif op == 9 then
					SkeletonCollisionMode.finish_ragdoll_request(mode, 7 + a % 4)
				else
					SkeletonCollisionMode.reset_body_state(mode, feedback)
				end
				local at = "#" .. si .. "/" .. i .. " op" .. op
				check(u.diff(err, o.err), at .. " err")
				check(u.diff(mode, o.out), at)
				for p = 1, 26 do
					check(u.diff(skel.bodies[p].inertia, o.inertia[p]), at .. " inertia" .. p)
					check(u.diff(skel.bodies[p].rates.world_inverse_inertia, o.wii[p]), at .. " wii" .. p)
				end
			end
		end
	end)

	harness.test(report, "physics/skeleton_body: SkeletonCollisionFeedback, filter_error, response и ошибки позы vs Rust", function()
		local fs = deep(golden.feedback_settings)
		fs.body = golden.collision_settings
		local physical = golden.feedback_record
		for si, seq in golden.feedback do
			local fb = SkeletonCollisionFeedback.new(fs)
			if seq.set_up then
				SkeletonCollisionFeedback.set_up_normal(fb)
			end
			for i, st in seq.steps do
				local inp = st.input
				local fl = inp.flags
				local input = {
					dt = inp.dt,
					plane_point = inp.plane_point,
					plane_normal = inp.plane_normal,
					reference_velocity = inp.reference_velocity,
					com_velocity = inp.com_velocity,
					ragdoll = fl[1],
					disable_ground_filter = fl[2],
					ai_collision_scalar = fl[3],
					offboard = fl[4],
					entering_offboard = fl[5],
					category_600 = fl[6],
					request_partial_ragdoll = fl[7],
					physical = physical,
					part_weights = golden.feedback_weights,
					body_frames = golden.feedback_frames,
				}
				SkeletonCollisionFeedback.update(fb, input, deep(st.reports))
				local at = "#" .. si .. "/" .. i
				check(u.diff(SkeletonCollisionFeedback.filter_error(fb, st.error, { 0.0, 1.0, 0.0, 0.0 }), st.filtered), at .. " filter")
				check(u.diff(SkeletonCollisionFeedback.fill_response(fb, physical, golden.feedback_weights), st.response), at .. " response")
				-- Эталон снят после fill_response (он накапливает wipeout_times).
				check(u.diff(fb, st.out), at .. " feedback")
				local errors = SkeletonPoseErrors.default()
				local tg = st.errors_in.targets
				SkeletonPoseErrors.set_targets(errors, { com = tg[1], lifted_com = tg[2], following_com = tg[3] })
				SkeletonPoseErrors.update(errors, physical, golden.feedback_animation_to_world, st.errors_in.drive_frames)
				check(u.diff(errors, st.errors), at .. " errors")
				check(u.diff(SkeletonPoseErrors.normal_response(errors, fb, inp.plane_normal), st.normal), at .. " normal")
				check(u.diff(SkeletonPoseErrors.partial_response(errors), st.partial), at .. " partial")
			end
		end
	end)
end
