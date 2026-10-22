--!strict
-- Сверка riding/collision_response, physics/skeleton_animation_record,
-- riding/ground_orientation, riding/reckoning_frames с настоящим skate-core
-- (golden/src/reckoning.rs) и перенос Rust-тестов этих модулей.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local cr = require("../../../src/skate_core/riding/collision_response")
local sar = require("../../../src/skate_core/physics/skeleton_animation_record")
local go = require("../../../src/skate_core/riding/ground_orientation")
local rf = require("../../../src/skate_core/riding/reckoning_frames")
local golden = require("../../golden/reckoning") :: any

local fb, f32, to_bits = u.fb, rt.f32, rt.to_bits
local GroundOrientation = go.GroundOrientation
local ReckoningFrames = rf.ReckoningFrames
local SkeletonAnimationMasses = sar.SkeletonAnimationMasses
local SkeletonAnimationRecord = sar.SkeletonAnimationRecord
local IDENTITY = sar.IDENTITY
local UP = vector.create(0, 1, 0)

local function F4(t: { number }): { number }
	return { fb(t[1]), fb(t[2]), fb(t[3]), fb(t[4]) }
end
local function M4(t: any): any
	return { F4(t[1]), F4(t[2]), F4(t[3]), F4(t[4]) }
end
local function G(t: any): any
	local x, y = {}, {}
	for i = 1, 8 do
		x[i] = fb(t[1][i])
		y[i] = fb(t[2][i])
	end
	return { x = x, y = y }
end
local function same4(a: { number }, t: { number }): boolean
	return u.same(a[1], t[1]) and u.same(a[2], t[2]) and u.same(a[3], t[3]) and u.same(a[4], t[4])
end
local function same44(a: any, t: any): boolean
	return same4(a[1], t[1]) and same4(a[2], t[2]) and same4(a[3], t[3]) and same4(a[4], t[4])
end
local function eq4(a: { number }, b: { number }): boolean
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
end
local function eq44(a: any, b: any): boolean
	return eq4(a[1], b[1]) and eq4(a[2], b[2]) and eq4(a[3], b[3]) and eq4(a[4], b[4])
end

return function(report: harness.Report)
	harness.test(report, "collision_response: 1500 вызовов vs Rust", function()
		for i, c in golden.response do
			local st = { maximum_velocity_delta = fb(c[1][1]), force_y_offset = fb(c[1][2]), force_scalar = fb(c[1][3]), target_displacement_velocity = fb(c[1][4]), torque_vs_angle = G(c[1][5]) }
			local inp = c[2]
			local out = cr.collision_response(st, {
				flags_2472 = inp[1], collision_displacement = F4(inp[2]), velocity = F4(inp[3]), forward = F4(inp[4]), up = F4(inp[5]),
				ground_normal = F4(inp[6]), time_step = fb(inp[7]), mass = fb(inp[8]),
			})
			if c[3] == false then
				assert(out == nil, "случай " .. i .. ": лишний ответ")
			else
				local w = c[3]
				assert(out and out.applied == w[1] and same4(out.force, w[2]) and same4(out.point, w[3]) and same4(out.angular_displacement, w[4])
					and same4(out.target_velocity, w[5]), "случай " .. i)
			end
		end
	end)

	harness.test(report, "collision_response: 1500 signed_angle vs Rust", function()
		for i, c in golden.signed do
			assert(u.same(cr.signed_angle(u.V(c[1]), u.V(c[2]), u.V(c[3])), c[4]), "случай " .. i)
		end
	end)

	harness.test(report, "skeleton_animation_record: массы и 40 × 6 update vs Rust", function()
		for ci, c in golden.skeleton do
			local sizes = {}
			for i, s in c.sizes do
				sizes[i] = u.V(s)
			end
			local masses = SkeletonAnimationMasses.from_bone_data(sizes, c.shapes, c.hat)
			for i = 1, 24 do
				assert(u.same(masses.part_weights[i], c.masses[1][i]) and u.same(masses.fractional[i], c.masses[3][i]), "массы " .. ci)
			end
			assert(u.same(masses.total, c.masses[2]), "сумма " .. ci)
			local rec = SkeletonAnimationRecord.default()
			for si, st in c.steps do
				if st.reset then
					SkeletonAnimationRecord.reset_history(rec)
				end
				local pose = {}
				for i, p in st.pose do
					pose[i] = M4(p)
				end
				SkeletonAnimationRecord.update(rec, pose, M4(st.to_board), masses)
				local o = st.out
				assert(same4(rec.centre_of_mass, o[1]) and same4(rec.centre_of_mass_delta, o[2]) and same4(rec.com_to_deck_world, o[3])
					and same4(rec.com_to_deck_world_delta, o[4]) and u.same(rec.reset_scalar, o[5]), string.format("случай %d шаг %d", ci, si))
			end
		end
	end)

	harness.test(report, "skeleton_animation_record: 30 map_animation_parts/compose_affine vs Rust", function()
		for ci, c in golden.mapping do
			local globals, frames = {}, {}
			for i, g in c.globals do
				globals[i] = M4(g)
			end
			for i, f in c.frames do
				frames[i] = M4(f)
			end
			local out = sar.map_animation_parts(globals, c.idx, frames)
			if c.out == false then
				assert(out == nil, "случай " .. ci .. ": нет ошибки")
			else
				assert(out, "случай " .. ci .. ": ошибка")
				for p = 1, 24 do
					assert(same44(out[p], c.out[p]), string.format("случай %d часть %d", ci, p))
				end
			end
			assert(same44(sar.compose_affine(frames[1], frames[2]), c.compose), "compose " .. ci)
		end
	end)

	harness.test(report, "ground_orientation: 40 × 60 update vs Rust", function()
		for ci, c in golden.orientation do
			local s = c.settings
			local st = {
				ground_normal_smoothing = F4(s[1]), up_vector_smoothing_slow = F4(s[2]), up_vector_smoothing_fast = F4(s[3]),
				dynamic_up_vs_ground_y = G(s[4]), ground_vector_blend = G(s[5]), deck_angle_usage_vs_speed = G(s[6]),
				up_vector_smoothing_vs_speed = G(s[7]), up_vector_max_delta_vs_speed = G(s[8]), ground_blend_max_delta = fb(s[9]),
				up_vector_max_acceleration = fb(s[10]), anti_wobble_damping = fb(s[11]), extra_side_damping = fb(s[12]),
				minimum_wheels_for_ground_blend = s[13],
			}
			local g = GroundOrientation.new(st)
			for si, step in c.steps do
				if step == "reset" then
					GroundOrientation.reset(g)
				else
					local i = step[1]
					GroundOrientation.update(g, st, {
						com_to_deck = u.V(i[1]), ground_normal = u.V(i[2]), dynamic_up = u.V(i[3]), speed = fb(i[4]), wheel_contact_count = i[5],
						animation_balance = fb(i[6]), deck_angle_curve_input = fb(i[7]), board_up = u.V(i[8]), board_forward = u.V(i[9]),
						effective_board_forward = u.V(i[10]), previous_reckoning_right = u.V(i[11]), prevent_up_behind_board = i[12],
					})
					local o = step[2]
					assert(u.same_v(g.dynamic_up, o[1]) and u.same_v(g.up, o[2]) and u.same_v(g.target, o[3]) and u.same_v(g.up_velocity, o[4])
						and u.same_v(g.ground_normal, o[5]) and u.same(g.ground_blend, o[6]), string.format("случай %d шаг %d", ci, si))
				end
			end
		end
	end)

	harness.test(report, "reckoning_frames: 60 × 30 transform/lean/tilt vs Rust", function()
		for ci, c in golden.frames do
			local f = ReckoningFrames.new()
			f.body_flip = M4(c.flip)
			local ta, tu = G(c.ta), G(c.tu)
			for si, st in c.steps do
				f.heading = F4(st[1])
				ReckoningFrames.calculate_transform(f, F4(st[2]), F4(st[3]))
				ReckoningFrames.calculate_dynamic_lean(f, F4(st[2]), F4(st[4]))
				ReckoningFrames.calculate_tilt(f, st[5], ta, tu)
				local o = st[6]
				assert(same44(f.ground, o[1]) and same44(f.system, o[2]) and same44(f.unflipped, o[3]) and same44(f.inverse_system, o[4])
					and same44(f.body_flip, o[5]) and same4(f.heading, o[6]) and u.same(f.target_lean_angle, o[7]) and same4(f.lateral_tilt, o[8]),
					string.format("случай %d шаг %d", ci, si))
			end
		end
	end)

	-- Перенос Rust-тестов.
	harness.test(report, "collision_response: late_false_still_publishes_collision_target_and_angle", function()
		local settings = {
			maximum_velocity_delta = 8.0, force_y_offset = f32(-0.05), force_scalar = 1.0, target_displacement_velocity = 1.0,
			torque_vs_angle = { x = { 0, 1, 2, 3, 4, 5, 6, 7 }, y = table.create(8, f32(0.03)) },
		}
		local input = {
			flags_2472 = 0x20000, collision_displacement = { 1, 0, 0, 0 }, velocity = { 2, 0, 4, 0 }, forward = { 0, 0, 1, 0 },
			up = { 0, 1, 0, 0 }, ground_normal = { 0, 1, 0, 0 }, time_step = f32(1 / 60), mass = 8.0,
		}
		local late = assert(cr.collision_response(settings, input))
		assert(not late.applied and eq4(late.force, { 0, 0, 0, 0 }) and eq4(late.target_velocity, { 1, 0, 4, 0 }) and late.angular_displacement[2] > 0)
		input.velocity = { -20, 0, 4, 0 }
		local clamped = assert(cr.collision_response(settings, input))
		assert(clamped.applied and math.abs(clamped.force[1] - 3840) < 0.001 and eq4(clamped.point, { 0, f32(-0.05), 0, 0 }))
		input.collision_displacement = input.ground_normal
		assert(cr.collision_response(settings, input) == nil)
	end)

	harness.test(report, "skeleton_animation_record: com_uses_original_bone_volume_excludes_board_and_preserves_reset_order", function()
		local sizes = table.create(24, vector.zero)
		sizes[1] = vector.create(100, 100, 100)
		sizes[2] = vector.create(1, 1, 1)
		sizes[3] = vector.create(1, 1, 3)
		local masses = SkeletonAnimationMasses.from_bone_data(sizes, table.create(24, 1), false)
		assert(masses.total == 4.0 and masses.fractional[1] == 0 and masses.fractional[2] == 0.25 and masses.fractional[3] == 0.75)
		local pose = {}
		for i = 1, 24 do
			pose[i] = IDENTITY()
		end
		pose[1][4] = { 1, 0, 0, 0 }
		pose[2][4] = { 1, 2, 0, 0 }
		pose[3][4] = { 1, 6, 0, 0 }
		local to_board = IDENTITY()
		to_board[4] = { 100, 20, -10, 0 }
		local record = SkeletonAnimationRecord.default()
		SkeletonAnimationRecord.update(record, pose, to_board, masses)
		assert(eq4(record.centre_of_mass, { 1, 5, 0, 0 }) and eq4(record.com_to_deck_world, { 0, 5, 0, 0 }) and eq4(record.com_to_deck_world_delta, { 0, 0, 0, 0 }))
		pose[2][4][2] += 4
		SkeletonAnimationRecord.update(record, pose, to_board, masses)
		assert(eq4(record.com_to_deck_world_delta, { 0, 1, 0, 0 }))
		SkeletonAnimationRecord.reset_history(record)
		assert(record.reset_scalar == 1.0)
		for i = 1, 24 do
			assert(eq44(record.pose[i], pose[i]))
		end
	end)

	harness.test(report, "skeleton_animation_record: global_bone_then_physics_frame_preserves_native_mapping_and_lanes", function()
		local l = sar.physics_bone_frame({ 0, 0, 0, 1 }, { 1, 2, 3, 7 })
		assert(eq4(l[1], { 1, 0, 0, 1 }) and eq4(l[2], { 0, 1, 0, 0 }) and eq4(l[3], { 0, 0, 1, 0 }))
		local global = { { 0, 1, 0, 11 }, { -1, 0, 0, 13 }, { 0, 0, 1, 17 }, { 10, 20, 30, 19 } }
		local indices = table.create(24, 0)
		indices[2] = 1
		local frames = {}
		for i = 1, 24 do
			frames[i] = IDENTITY()
		end
		frames[2] = l
		local mapped = assert(sar.map_animation_parts({ IDENTITY(), global }, indices, frames))
		assert(eq44(mapped[1], IDENTITY()))
		assert(eq4(mapped[2][1], global[1]) and eq4(mapped[2][2], global[2]) and eq4(mapped[2][3], global[3]))
		assert(eq4(mapped[2][4], { 8, 21, 33, 107 }))
		indices[24] = 2
		assert(sar.map_animation_parts({ IDENTITY(), global }, indices, frames) == nil)
	end)

	local function constant(value: number): any
		return { x = { 0, 1, 2, 3, 4, 5, 6, 7 }, y = table.create(8, value) }
	end
	local function settings(): any
		return {
			ground_normal_smoothing = { 1, 0, 0, 1 }, up_vector_smoothing_slow = { 1, 0, 0, 1 }, up_vector_smoothing_fast = { 1, 0, 0, 1 },
			dynamic_up_vs_ground_y = constant(1), ground_vector_blend = constant(0), deck_angle_usage_vs_speed = constant(0),
			up_vector_smoothing_vs_speed = constant(0), up_vector_max_delta_vs_speed = constant(1), ground_blend_max_delta = f32(0.1),
			up_vector_max_acceleration = 2.0, anti_wobble_damping = 0.5, extra_side_damping = f32(0.6), minimum_wheels_for_ground_blend = 0,
		}
	end
	local function input(normal: vector): any
		return {
			com_to_deck = UP, ground_normal = normal, dynamic_up = normal, speed = 0.0, wheel_contact_count = 4, animation_balance = 0.0,
			deck_angle_curve_input = 0.0, board_up = UP, board_forward = vector.create(0, 0, 1), effective_board_forward = vector.create(0, 0, 1),
			previous_reckoning_right = vector.create(1, 0, 0), prevent_up_behind_board = false,
		}
	end

	harness.test(report, "ground_orientation: stationary_filter_startup_has_no_false_tilt_or_acceleration", function()
		local s = settings()
		local state = GroundOrientation.new(s)
		for _ = 1, 120 do
			GroundOrientation.update(state, s, input(UP))
		end
		assert(state.up == UP and state.ground_normal == UP and state.up_velocity == vector.zero)
	end)

	harness.test(report, "ground_orientation: changed_contact_normal_does_not_instantly_replace_the_skater_up", function()
		local s = settings()
		local state = GroundOrientation.new(s)
		local wall = vector.create(1, 0, 0)
		GroundOrientation.update(state, s, input(wall))
		assert(state.ground_normal == wall and state.up ~= state.ground_normal)
		assert(state.up.y > 0.99 and state.up.x > 0 and state.up.x < 0.04)
		local w = state.slow_filter.words
		assert(w[5] == to_bits(state.up.x) and w[6] == to_bits(state.up.y) and w[7] == to_bits(state.up.z) and w[8] == 0)
	end)

	harness.test(report, "ground_orientation: landing_with_reported_tiny_up_residual_stays_finite", function()
		local s = settings()
		for _, previous_up in { UP, vector.create(f32(-1.6165965e-22), 1, f32(-4.2145673e-22)) } do
			local state = GroundOrientation.new(s)
			state.up = previous_up
			state.up_velocity = vector.create(f32(1.0e-22), 0, f32(2.0e-22))
			local landing = input(UP)
			landing.animation_balance = f32(-0.36950988)
			landing.wheel_contact_count = 2
			landing.speed = f32(3.4837468)
			landing.previous_reckoning_right = vector.create(f32(-0.49704847), f32(2.853549e-22), f32(0.86772275))
			GroundOrientation.update(state, s, landing)
			for _, v in { state.up, state.up_velocity, state.target } do
				assert(rt.is_finite(v.x) and rt.is_finite(v.y) and rt.is_finite(v.z))
			end
			assert(math.abs(state.up.y - 1.0) < 1e-6)
		end
	end)

	harness.test(report, "ground_orientation: acceleration_clamp_preserves_tiny_finite_delta", function()
		local delta = vector.create(f32(1.6165965e-22), 0, f32(4.2145673e-22))
		assert(go.clamp_length(delta, f32(0.03)) == delta)
	end)

	harness.test(report, "reckoning_frames: body_flip_changes_system_but_retains_ground_and_preflip_frames", function()
		local state = ReckoningFrames.new()
		state.heading = { 0, 0, 1, 0 }
		state.body_flip = { { 0, 0, -1, 0 }, { 0, 1, 0, 0 }, { 1, 0, 0, 0 }, { 3, 0, 0, 0 } }
		ReckoningFrames.calculate_transform(state, { 0, 1, 0, 0 }, { 0, 1, 0, 0 })
		assert(eq44(state.unflipped, IDENTITY()) and eq44(state.ground, IDENTITY()) and eq44(state.system, state.body_flip))
		assert(eq44(sar.compose_affine(state.system, state.inverse_system), IDENTITY()))
		ReckoningFrames.calculate_dynamic_lean(state, { 0, 1, 0, 0 }, { 0, 1, 0, 0 })
		assert(math.abs(state.target_lean_angle) < 0.001)
		state.lateral_tilt = { f32(0.3), 0, 0, 0 }
		local curve = { x = table.create(8, 0.0), y = table.create(8, 0.0) }
		ReckoningFrames.calculate_tilt(state, false, curve, curve)
		assert(eq4(state.lateral_tilt, { f32(0.3), 0, 0, 0 }))
	end)
end
