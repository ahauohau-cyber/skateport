--!strict
-- Сверка animation/foot_ik и physics/skeleton_{board_frames, board_offset,
-- air_frames, general, motion, biped_air, landing, landing_on_board, output}
-- с настоящим skate-core (golden/src/skel2.rs) и перенос Rust-тестов
-- foot_ik/tests.rs, post_contact, skeleton_board_offset, skeleton_landing,
-- skeleton_output/tests.rs. Эталон собран из данных игры: в git не идёт.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local sar = require("../../../src/skate_core/physics/skeleton_animation_record")
local fik = require("../../../src/skate_core/animation/foot_ik")
local sb = require("../../../src/skate_core/physics/skeleton_body")
local rigid_body = require("../../../src/skate_core/physics/rigid_body")
local skeleton_root = require("../../../src/skate_core/physics/skeleton_root")
local sbf = require("../../../src/skate_core/physics/skeleton_board_frames")
local sbo = require("../../../src/skate_core/physics/skeleton_board_offset")
local air = require("../../../src/skate_core/physics/skeleton_air_frames")
local general = require("../../../src/skate_core/physics/skeleton_general")
local motion = require("../../../src/skate_core/physics/skeleton_motion")
local biped = require("../../../src/skate_core/physics/skeleton_biped_air")
local landing = require("../../../src/skate_core/physics/skeleton_landing")
local lob = require("../../../src/skate_core/physics/skeleton_landing_on_board")
local so = require("../../../src/skate_core/physics/skeleton_output")

local f32 = rt.f32
local IDENTITY = sar.IDENTITY
local two_bone = fik.two_bone
local status = fik.status
local FootIkState = fik.state.FootIkState
local Geometry = fik.drive.Geometry
local SkeletonBoardFrames = sbf.SkeletonBoardFrames
local SkateboardOffset = sbo.SkateboardOffset
local SkeletonMotion = motion.SkeletonMotion
local LandingAdjustment = landing.LandingAdjustment

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

local function identities(n: number): { any }
	local t = {}
	for i = 1, n do
		t[i] = IDENTITY()
	end
	return t
end

local function load_golden(): any
	local ok, g = pcall(require, "../../golden/skel2")
	if ok and type(g) == "table" then
		return g
	end
	return nil
end

return function(report: harness.Report)
	-- Rust-тесты foot_ik/tests.rs.
	harness.test(report, "foot_ik: inverse_preserves_points_for_scaled_and_sheared_authored_frames", function()
		local frame = { { 2.0, 0.0, 0.0, 0.0 }, { 0.5, 3.0, 0.0, 0.0 }, { 0.0, 0.25, 4.0, 0.0 }, { 7.0, -2.0, 5.0, 0.0 } }
		local point = { f32(0.3), f32(-0.7), f32(1.2), 0.0 }
		local recovered = sar.transform_point(fik.inverse_affine(frame), sar.transform_point(frame, point))
		for lane = 1, 3 do
			assert(math.abs(recovered[lane] - point[lane]) < 2e-6)
		end
	end)

	harness.test(report, "foot_ik: frame_interpolation_uses_rotation_and_translation_at_the_same_weight", function()
		local target = IDENTITY()
		target[1] = { 0.0, 1.0, 0.0, 0.0 }
		target[2] = { -1.0, 0.0, 0.0, 0.0 }
		target[4] = { 8.0, 2.0, -4.0, 0.0 }
		local half, remaining = fik.interpolate_native(IDENTITY(), target, 0.5)
		assert(math.abs(half[1][1] - math.sqrt(0.5)) < 2e-6)
		assert(math.abs(half[1][2] - math.sqrt(0.5)) < 2e-6)
		assert(half[4][1] == 4.0 and half[4][2] == 1.0 and half[4][3] == -2.0)
		assert(math.abs(remaining - math.pi / 4) < 2e-6)
		local full, rest = fik.interpolate_native(IDENTITY(), target, 1.0)
		check(u.diff(full, target), "full")
		assert(rest == 0.0)
	end)

	harness.test(report, "foot_ik: reachable_two_bone_target_keeps_both_segment_lengths", function()
		local root = { 0.0, 0.0, 0.0, 0.0 }
		local middle = { f32(0.3), f32(0.4), 0.0, 0.0 }
		local end_ = { f32(0.6), 0.0, 0.0, 0.0 }
		local target = { value = { f32(0.7), 0.0, 0.0, 0.0 } }
		local solved = { value = { 0.0, 0.0, 0.0, 0.0 } }
		local result = two_bone.solve(root, middle, end_, solved, target, { minimum_degrees = 5.0, maximum_degrees = 175.0 }, true, 2)
		assert(result == "Solved")
		assert(target.value[1] == f32(0.7) and target.value[2] == 0.0 and target.value[3] == 0.0)
		local function distance(a: { number }, b: { number }): number
			return math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2 + (a[3] - b[3]) ^ 2)
		end
		assert(math.abs(distance(root, solved.value) - 0.5) < 2e-5)
		assert(math.abs(distance(solved.value, target.value) - 0.5) < 2e-5)
	end)

	harness.test(report, "foot_ik: foot_queries_affect_the_following_update_and_loss_sets_support_history", function()
		local contacts = fik.contact.ContactState.default()
		local statuses = {}
		local frames = {}
		for i = 1, 4 do
			statuses[i] = status.LimbStatus.default()
			frames[i] = fik.transforms.LimbFrames.default()
		end
		statuses[1].mode = "OnDeck"
		local function input(hit: any): any
			return {
				flags_2468 = 0x0200_0000,
				contact_bone = 10,
				foot_bones = { 10, 20 },
				hips_world_position = { 0.0, 0.0, 0.0, 0.0 },
				inverse_board = IDENTITY(),
				board = IDENTITY(),
				current_contacts = { hit, false },
			}
		end
		local CS = fik.contact.ContactState
		CS.update(contacts, statuses, frames, input(false))
		assert(not contacts.support_failed_this_update)
		assert(contacts.feet[1].query_state == 2)
		CS.update(contacts, statuses, frames, input({ 0.0, 0.0, 0.0, 0.0 }))
		assert(contacts.support_failed_this_update)
		assert(contacts.support_failed)
		assert(contacts.feet[1].query_state == 1)
		statuses[1].mode = "Disabled"
		CS.update(contacts, statuses, frames, input(false))
		assert(not contacts.support_failed_this_update)
		assert(contacts.support_failed)
	end)

	harness.test(report, "post_contact: original_tangent_rational_spans_both_constructor_quadrants", function()
		for _, a in { 0.01, 0.25, 0.75, 1.0, 1.5607964 } do
			local angle = f32(a)
			local actual = fik.post_contact.tangent(angle)
			local reference = f32(math.tan(angle))
			assert(math.abs(actual - reference) < 3e-5 * math.max(math.abs(reference), 1.0), tostring(angle))
		end
	end)

	-- Rust-тесты physics/tests/skeleton_board_offset.rs и skeleton_landing.rs.
	harness.test(report, "skeleton_board_offset: refresh_applies_without_decay_then_height_and_xz_decay_independently", function()
		local offset = SkateboardOffset.default()
		local transform = IDENTITY()
		transform[4] = { 15.0, 30.0, 45.0, 0.0 }
		SkateboardOffset.refresh_transform(offset, transform)
		local board = { value = IDENTITY() }
		local targets = identities(4)
		SkateboardOffset.update(offset, board, targets)
		check(u.diff(board.value[4], transform[4]), "board")
		check(u.diff(targets[4][4], transform[4]), "target")
		assert(offset.orientation_frames == 15.0)
		SkateboardOffset.refresh_height(offset, 10.0, 7.0)
		board.value = IDENTITY()
		targets = identities(4)
		SkateboardOffset.update(offset, board, targets)
		local ratio = f32(14.0 / 15.0)
		assert(offset.orientation_frames == 14.0)
		assert(offset.height_frames == 7.0)
		assert(board.value[4][1] == f32(15.0 * f32(ratio * ratio)))
		assert(board.value[4][2] == 10.0)
		check(u.diff(board.value, targets[1]), "targets")
		offset.orientation_frames = 0.0
		offset.height_frames = 1.0
		board.value = IDENTITY()
		SkateboardOffset.update(offset, board, targets)
		assert(offset.height_frames == 0.0)
		assert(offset.transform[4][2] == 0.0)
		assert(not offset.height_refreshed)
	end)

	harness.test(report, "skeleton_landing: ground_landing_uses_physical_height_velocity_and_preserves_release_order", function()
		local graph = { x = { 0.0, f32(0.3), f32(0.6), 1.0 }, y = { 1.0, 1.0, 1.0, 1.0 } }
		local settings = {
			manual_blend = graph, grind_blend = graph, coffin_height = graph,
			minimum_height = 0.5, maximum_velocity = 8.0, manual_damping = 17.5,
			manual_spring = 60.0, ground_minimum_compression_time = f32(0.05),
			ground_damping = 6.0, ground_spring = 60.0, grind_animation_target_time = f32(0.15),
			grind_damping = 10.0, grind_spring = 60.0, grind_target_delta = f32(0.01),
			desired_com_height = f32(0.85), coffin_time = f32(0.04), coffin_maximum_velocity = 5.0,
			coffin_blend_frames = 7.0, coffin_base_height = f32(0.2),
		}
		local adjustment = LandingAdjustment.default()
		local offset = SkateboardOffset.default()
		local input = {
			filtered_state = 2, flags_2468 = 0, flags_2472 = 0, flags_2476 = 0,
			balance = 0.0, physical_com_velocity_along_up = -2.0,
			physical_com_height = f32(0.8), animation_com_height = 1.0,
		}
		LandingAdjustment.update(adjustment, input, settings, offset)
		assert(not adjustment.active)
		input.filtered_state = 1
		input.flags_2476 = 0x1000_0000
		LandingAdjustment.update(adjustment, input, settings, offset)
		assert(adjustment.active)
		assert(adjustment.kind == 0)
		assert(math.abs(adjustment.velocity + 1.75) < 1e-6)
		assert(math.abs(offset.transform[4][2] - 0.205) < 1e-6)
		assert(offset.height_frames == 15.0)
		assert(offset.height_refreshed)
		input.filtered_state = 2
		LandingAdjustment.update(adjustment, input, settings, offset)
		assert(not adjustment.active)
		local step = rt.from_bits(0x3C88_8889)
		assert(adjustment.time == f32(step + step))
		assert(adjustment.previous_filtered_state == 2)
	end)

	-- Rust-тесты physics/skeleton_output/tests.rs.
	harness.test(report, "skeleton_output: solved_volume_is_converted_back_to_bone_and_preserves_unmapped_animation", function()
		local forward = identities(24)
		forward[2][4][1] = 2.0
		local parents = table.create(24, false) :: { number | false }
		parents[2] = 2
		local bone_indices = {}
		for i = 1, 24 do
			bone_indices[i] = i - 1
		end
		local output = {
			bone_indices = bone_indices,
			geometry = Geometry.new(parents, forward),
			board_bones = { front_truck = 25, back_truck = 26, front_left_wheel = 27, front_right_wheel = 28, back_left_wheel = 29, back_right_wheel = 30 },
			board_settings = { truck_tilt_scalar = 1.0, truck_tilt_max_angle = 1.0, truck_tilt_wobble_scalar = 1.0, truck_displacement_max = 1.0 },
		}
		local physical = identities(24)
		physical[2][4][1] = 12.0
		physical[3][4][1] = 7.0
		local world_to_anim = IDENTITY()
		world_to_anim[4][1] = -3.0
		local globals = identities(36)
		local locals = identities(36)
		locals[36][4][2] = 9.0
		local bodies = identities(6)
		bodies[1][4][1] = -1.0
		bodies[2][4][1] = 1.0
		bodies[3][4][1] = 1.0
		bodies[4][4][1] = -1.0
		so.SkeletonOutput.publish(output, {
			physical_parts = physical,
			world_to_animation = world_to_anim,
			board = {
				bodies = bodies,
				skeleton_board = physical[1],
				truck_frames = identities(2),
				deck_wobble_tilt = 0.0,
				deck_wobble_squish = 0.0,
				average_compression = { 0.0, 0.0 },
			},
		}, globals, locals)
		assert(math.abs(globals[2][4][1] - 7.0) < 1e-6)
		assert(math.abs(locals[2][4][1] - 3.0) < 1e-6)
		assert(locals[36][4][2] == 9.0)
	end)

	harness.test(report, "skeleton_output: wobble_emits_final_sample_before_expiry_and_selects_real_phase_curves", function()
		local function curve(value: number): any
			return { x = { 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0 }, y = table.create(8, value) }
		end
		local settings = { takeoff_tilt = curve(2.0), landing_tilt = curve(3.0), takeoff_squish = curve(4.0), landing_squish = curve(5.0), maximum_time = 0.0 }
		local W = so.wobble.Wobble
		local state = W.default()
		assert(not W.update(state, settings).sampled)
		W.trigger(state, true, true)
		local final_sample = W.update(state, settings)
		assert(final_sample.sampled)
		assert(not final_sample.remains_active)
		assert(final_sample.tilt == -3.0)
		assert(final_sample.squish == 5.0)
		assert(state.time == 0.0)
		assert(not W.update(state, settings).sampled)
		W.trigger(state, false, false)
		assert(W.update(state, settings).tilt == 2.0)
	end)

	harness.test(report, "skeleton_output: wobble_rotates_about_deck_forward_then_compresses_along_new_up", function()
		local board = IDENTITY()
		board[4] = { 4.0, 5.0, 6.0, 0.0 }
		local cell = { value = board }
		so.wobble.apply({ sampled = true, tilt = rt.from_bits(0x3FC9_0FDB), squish = 0.25, remains_active = true }, cell)
		local b = cell.value
		assert(math.abs(b[1][1]) < 2e-6)
		assert(math.abs(b[1][2] - 1.0) < 2e-6)
		assert(math.abs(b[2][1] + 1.0) < 2e-6)
		assert(b[3][1] == 0.0 and b[3][2] == 0.0 and b[3][3] == 1.0)
		assert(math.abs(b[4][1] - 3.75) < 2e-6)
		assert(math.abs(b[4][2] - 5.0) < 2e-6)
		assert(b[4][3] == 6.0)
	end)

	local golden = load_golden()
	if not golden then
		return
	end

	harness.test(report, "foot_ik/math: interpolate, interpolate_affine, inverse_affine × 300 vs Rust", function()
		for i, c in golden.math do
			local m, rem = fik.interpolate_native(c.a, c.b, c.w)
			check(u.diff(m, c.m), "#" .. i .. " m")
			check(u.diff(rem, c.rem), "#" .. i .. " rem")
			check(u.diff(fik.interpolate_affine(c.a, c.b, c.w), c.aff), "#" .. i .. " aff")
			check(u.diff(fik.inverse_affine(c.a), c.inv), "#" .. i .. " inv")
		end
	end)

	harness.test(report, "foot_ik/two_bone: 400 решений vs Rust", function()
		for i, c in golden.two_bone do
			local target = { value = table.clone(c.target_in) }
			local solved = { value = { 0.0, 0.0, 0.0, 0.0 } }
			local res = two_bone.solve(c.root, c.middle, c.end_, solved, target, { minimum_degrees = c.min, maximum_degrees = c.max }, c.ovr, c.budget)
			check(u.diff(res, c.res), "#" .. i .. " res")
			check(u.diff(solved.value, c.solved), "#" .. i .. " solved")
			check(u.diff(target.value, c.target), "#" .. i .. " target")
		end
	end)

	local settings = golden.settings
	harness.test(report, "foot_ik/status: 40 × 10 обновлений режимов и смешиваний vs Rust", function()
		for i, seq in golden.status do
			for k, st in seq do
				local limbs = deep(st.input)
				status.update_modes(limbs, st.feet, st.f2472)
				check(u.diff(limbs, st.modes), "#" .. i .. "/" .. k .. " modes")
				status.update_blends(limbs, settings.deck_half_width, settings.deck_total_half_length, st.f2480, settings.blend)
				check(u.diff(limbs, st.out), "#" .. i .. "/" .. k .. " blends")
			end
		end
	end)

	local g = golden.geometry
	local geometry = Geometry.new(g.parents, g.physics_frames)
	Geometry.validate_limbs(geometry, fik.state.LIMBS)

	local sizes, bones, body_settings
	do
		-- Тело собирается из эталона skel.luau (те же стоковые настройки).
		local ok, sk = pcall(require, "../../golden/skel")
		assert(ok and type(sk) == "table", "нужен tests/golden/skel.luau")
		sizes, bones, body_settings = sk.sizes, sk.bones, sk.body_settings
	end
	local sim = rigid_body.RetailSimulationStep.fixed_60_hz(30, f32(0.0005), vector.create(0.0, -9.81, 0.0))
	local body = sb.SkeletonBody.new(sb.SkeletonBodyDefinition.new(sizes, bones, body_settings, nil), golden.authored, golden.spawn, sim)

	harness.test(report, "foot_ik: геометрия, FootIkState.update и post_physics на теле 10 × 8 vs Rust", function()
		check(u.diff(geometry.inverse_part_frames, g.inverse_part_frames), "geometry")
		for i, seq in golden.foot_ik do
			for k, st in seq.steps do
				local at = "#" .. i .. "/" .. k
				local state = deep(st.pre)
				local drives = deep(st.drives_in)
				local updated = FootIkState.update(state, {
					flags_2468 = st.flags[1],
					flags_2472 = st.flags[2],
					flags_2480 = st.flags[3],
					animation_to_world = st.a2w,
					world_to_animation = st.w2a,
					physical_board = st.physical_board,
					contact_board = st.contact_board,
					inverse_contact_board = st.inverse_contact_board,
					animation = st.animation,
					original_animation = st.original,
					targets = st.targets,
					hips_world_position = st.hips,
					contact_bone = st.contact_bone,
					foot_bones = st.foot_bones,
					current_contacts = st.current,
				}, geometry, settings, drives)
				check(u.diff(updated, st.updated), at .. " updated")
				check(u.diff(drives, st.drives), at .. " drives")
				check(u.diff(state, st.mid), at .. " state")
				state = deep(st.post_state)
				local p = st.post_in
				local pupdated = fik.post_physics.update(state, body, geometry, settings, golden.post, p)
				check(u.diff(pupdated, st.post_updated), at .. " post updated")
				check(u.diff(state, st.out), at .. " post state")
				check(u.diff(body.record, st.record), at .. " record")
				check(u.diff(sb.SkeletonBody.part_transforms(body), st.body_pose), at .. " body")
			end
		end
	end)

	harness.test(report, "physics/skeleton_board_frames + skeleton_air_frames: 60 × 6 операций vs Rust", function()
		for i, seq in golden.frames do
			local roots = deep(seq.roots)
			local b = SkeletonBoardFrames.default()
			for k, o in seq.ops do
				local flags = { value = o.flags_in }
				local ret = nil
				local op = o.op
				if op == 0 then
					SkeletonBoardFrames.reset(b, o.t1)
				elseif op == 1 then
					SkeletonBoardFrames.publish_local_observations(b, roots, o.t1)
				elseif op == 2 then
					local dt = if o.flags_in % 2 == 0 then f32(1.0 / 60.0) else f32(0.02)
					SkeletonBoardFrames.publish_centre_of_mass(b, o.p, dt, bit32.band(o.flags_in, 0x400))
				elseif op == 3 then
					ret = SkeletonBoardFrames.prepare_ground(b, roots, o.t1, o.t2, flags)
				elseif op == 4 then
					ret = SkeletonBoardFrames.prepare_teleport(b, roots, o.t1, o.t2, flags)
				elseif op == 5 then
					SkeletonBoardFrames.update_com_lift(b, o.t1, o.p, o.x)
				elseif op == 6 then
					ret = air.prepare_animated(roots, b, o.t1, flags)
				elseif op == 7 then
					air.update_known_air_roots(roots, o.t1, o.p, o.p2, o.revert)
				elseif op == 8 then
					ret = air.prepare_known_air(roots, b, o.t1, flags)
					air.finish_known_air(roots, b, o.t2)
				else
					air.update_plant_roots(roots, o.t1, o.p, o.p2)
				end
				local at = "#" .. i .. "/" .. k .. " op" .. op
				check(u.diff(flags.value, o.flags), at .. " flags")
				check(u.diff(ret, o.ret), at .. " ret")
				check(u.diff(roots, o.roots), at .. " roots")
				check(u.diff(b, o.board), at .. " board")
			end
		end
	end)

	harness.test(report, "physics/skeleton_board_offset: 30 × 12 vs Rust", function()
		for i, seq in golden.offset do
			local o = SkateboardOffset.default()
			for k, st in ipairs(seq) do
				if st.op == 0 then
					SkateboardOffset.refresh_transform(o, st.t)
				elseif st.op == 1 then
					SkateboardOffset.refresh_height(o, st.h, st.frames)
				end
				local board = { value = deep(st.board_in) }
				local targets = deep(st.targets_in)
				SkateboardOffset.update(o, board, targets)
				local at = "#" .. i .. "/" .. k
				check(u.diff(board.value, st.board), at .. " board")
				check(u.diff(targets, st.targets), at .. " targets")
				check(u.diff(o, st.out), at .. " offset")
			end
		end
	end)

	harness.test(report, "physics/skeleton_general: root_velocity, гравитация, reset_to_animation vs Rust", function()
		for i, c in golden.general do
			local at = "#" .. i
			local prev = table.clone(c.prev0)
			check(u.diff(general.root_velocity(prev, c.cur, c.dt), c.vel), at .. " vel")
			check(u.diff(prev, c.prev), at .. " prev")
			general.apply_gravity_displacement(body, c.g)
			for p = 1, 26 do
				check(u.diff(body.bodies[p].rates.force_acceleration, c.forces[p]), at .. " force" .. p)
			end
			if c.reset then
				local anim = sar.SkeletonAnimationRecord.default()
				anim.centre_of_mass = { 1.0, 1.0, 1.0, 1.0 }
				anim.com_to_deck_world = { 1.0, 1.0, 1.0, 1.0 }
				local obs = general.reset_to_animation(body, anim, c.drive_pose, c.a2w, c.com_frame, sim)
				check(u.diff(obs, c.obs), at .. " obs")
				check(u.diff(anim.centre_of_mass, c.anim_com), at .. " anim com")
				check(u.diff(anim.com_to_deck_world, c.anim_deck), at .. " anim deck")
			end
			check(u.diff(body.record, c.record), at .. " record")
			for p = 1, 26 do
				check(u.diff(body.bodies[p].rates, c.bodies[p]), at .. " body" .. p)
			end
		end
	end)

	harness.test(report, "physics/skeleton_motion: 20 × 5 vs Rust", function()
		for i, seq in golden.motion do
			local m = SkeletonMotion.default()
			for k, o in ipairs(seq) do
				SkeletonMotion.process_trajectory(m, o.tb, o.a2w, o.dt)
				local f72 = { value = o.f72 }
				SkeletonMotion.publish_unadjusted_board(o.board, f72)
				local f68 = { value = o.f68 }
				local delta = SkeletonMotion.publish_adjusted_board(m, o.board, f68)
				local at = "#" .. i .. "/" .. k
				check(u.diff(f72.value, o.f72o), at .. " f72")
				check(u.diff(f68.value, o.f68o), at .. " f68")
				check(u.diff(delta, o.delta), at .. " delta")
				check(u.diff(m.trajectory, o.trajectory), at .. " trajectory")
				check(u.diff(m.inverse_trajectory, o.inverse_trajectory), at .. " inverse")
				check(u.diff(m.next_trajectory, o.next_trajectory), at .. " next")
				check(u.diff(m.velocity_world, o.velocity_world), at .. " velocity")
			end
		end
	end)

	harness.test(report, "physics/skeleton_biped_air и skeleton_landing_on_board vs Rust", function()
		for i, c in golden.biped do
			local roots = deep(c.roots0)
			local f68 = { value = c.f68 }
			local out = biped.prepare(roots, c.frame, c.tp, c.lc, c.mb, c.f76, f68)
			check(u.diff(out, c.out), "biped#" .. i .. " out")
			check(u.diff(f68.value, c.f68o), "biped#" .. i .. " flags")
			check(u.diff(roots, c.roots), "biped#" .. i .. " roots")
		end
		for i, c in golden.landing_on_board do
			local at = "lob#" .. i
			check(u.diff(lob.skate_root(c.old, c.com, c.f80, c.gy, c.st), c.sr), at .. " skate_root")
			local roots = deep(c.roots0)
			lob.update_root(roots, c.com, c.lc, c.spin, c.rf, c.rev)
			check(u.diff(roots, c.roots), at .. " roots")
			local pa = lob.pose_adjustment(c.w2a, c.ab, c.mb, c.iko, c.cvy, c.f80, c.time, c.g)
			check(u.diff(pa, c.pa), at .. " pose")
			assert((pa == nil) == (c.pa == nil), at .. " pose nil")
		end
	end)

	harness.test(report, "physics/skeleton_landing: 25 × 40 vs Rust", function()
		for i, seq in golden.landing do
			local adj = LandingAdjustment.default()
			local off = SkateboardOffset.default()
			for k, st in seq.steps do
				LandingAdjustment.update(adj, st.input, seq.settings, off)
				local at = "#" .. i .. "/" .. k
				check(u.diff(adj, st.adj), at .. " adjustment")
				check(u.diff(off, st.off), at .. " offset")
				if st.upd then
					SkateboardOffset.update(off, { value = IDENTITY() }, identities(4))
				end
			end
		end
	end)

	harness.test(report, "physics/skeleton_output: publish, wobble, correction vs Rust", function()
		local output = {
			bone_indices = g.bone_indices,
			geometry = geometry,
			board_bones = { front_truck = 30, back_truck = 31, front_left_wheel = 32, front_right_wheel = 33, back_left_wheel = 34, back_right_wheel = 35 },
			board_settings = golden.board_settings,
		}
		for i, c in golden.output do
			local globals = deep(c.g0)
			local locals = deep(c.l0)
			so.SkeletonOutput.publish(output, {
				physical_parts = c.physical,
				world_to_animation = c.w2a,
				board = {
					bodies = c.bodies,
					skeleton_board = c.sk_board,
					truck_frames = c.trucks,
					deck_wobble_tilt = c.tilt,
					deck_wobble_squish = c.squish,
					average_compression = c.comp,
				},
			}, globals, locals)
			check(u.diff(globals, c.globals), "output#" .. i .. " globals")
			check(u.diff(locals, c.locals), "output#" .. i .. " locals")
		end
		local W = so.wobble.Wobble
		for i, seq in golden.wobble do
			local w = W.default()
			for k, st in seq.steps do
				if st.trig ~= nil then
					W.trigger(w, st.trig.landing, st.trig.reverse)
				end
				local out = W.update(w, seq.settings)
				local board = { value = deep(st.board_in) }
				so.wobble.apply(out, board)
				local at = "wobble#" .. i .. "/" .. k
				check(u.diff(out, st.out), at .. " out")
				check(u.diff(board.value, st.board), at .. " board")
				check(u.diff(w, st.state), at .. " state")
			end
		end
		local CS = so.correction.CorrectionState
		for i, c in golden.correction do
			local state = CS.default()
			CS.observe_board(state, c.actual, c.predicted)
			state.pending = c.pending0
			CS.apply(state, body, c.gn, c.wipeout, c.f68, c.f76)
			local at = "correction#" .. i
			check(u.diff(state.board_prediction_error, c.error), at .. " error")
			check(u.diff(state.pending, c.pending), at .. " pending")
			check(u.diff(body.record, c.record), at .. " record")
			check(u.diff(sb.SkeletonBody.part_transforms(body), c.pose), at .. " pose")
		end
	end)
end
