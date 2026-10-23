--!strict
-- Сверка air::body_flip, air::reckoning и physics::grind_forces::reckoning с
-- настоящим Rust (golden/src/airrk.rs) + перенос Rust-тестов (body_flip.rs,
-- reckoning/tests.rs).

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local body_flip = require("../../../src/skate_core/air/body_flip")
local body_spin = require("../../../src/skate_core/air/body_spin")
local reckoning = require("../../../src/skate_core/air/reckoning")
local grind_forces = require("../../../src/skate_core/physics/grind_forces")
local go_mod = require("../../../src/skate_core/riding/ground_orientation")
local rf = require("../../../src/skate_core/riding/reckoning_frames")
local ground_normal = require("../../../src/skate_core/air/ground_normal")
local sar = require("../../../src/skate_core/physics/skeleton_animation_record")
local golden = require("../../golden/airrk") :: any
assert(type(golden) == "table", tostring(golden))

local f32 = rt.f32
local GroundOrientation = go_mod.GroundOrientation
local ReckoningFrames = rf.ReckoningFrames
local BodySpinState = body_spin.BodySpinState
local AirState = reckoning.AirState
local words = ground_normal.GroundNormalFilter.words
local IDENTITY = sar.IDENTITY

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end
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

local function curve(value: number): any
	return { x = { 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0 }, y = table.create(8, f32(value)) }
end
local function orientation(): any
	return GroundOrientation.new({
		ground_normal_smoothing = { 1.0, 0.0, 0.0, 1.0 },
		up_vector_smoothing_slow = { f32(0.2), f32(0.1), f32(0.05), f32(0.3) },
		up_vector_smoothing_fast = { f32(0.7), f32(0.2), f32(0.1), f32(0.8) },
		dynamic_up_vs_ground_y = curve(0.0),
		ground_vector_blend = curve(0.0),
		deck_angle_usage_vs_speed = curve(0.0),
		up_vector_smoothing_vs_speed = curve(0.0),
		up_vector_max_delta_vs_speed = curve(1.0),
		ground_blend_max_delta = 0.0,
		up_vector_max_acceleration = 1.0,
		anti_wobble_damping = 0.5,
		extra_side_damping = 0.0,
		minimum_wheels_for_ground_blend = 1,
	})
end
local function settings(): any
	local curves = {}
	for i = 1, 7 do
		curves[i] = curve(1.0)
	end
	return {
		ground_normal_smoothing = { 1.0, 0.0, 0.0, 1.0 },
		max_up_angle_delta = curve(0.5),
		tilt_vs_rotation = curve(0.0),
		tilt_vs_slope = curve(0.0),
		body_spin = {
			derivative_floor = f32(0.4),
			acceleration_limit = f32(0.2),
			curves = curves,
			input_fade_threshold = table.create(4, rt.from_bits(0x37800000)),
		},
		body_flip = { smoothing = f32(0.1), maximum_speed = 5.0, spin_scale = 0.5, missing_attribute_value = 0.0 },
	}
end
local function input(): any
	return {
		landing_normal = { 0.0, 1.0, 0.0, 0.0 },
		normal_blend = f32(0.1),
		target_spin = 0.0,
		flip_request = 0.0,
		com_to_deck = { 0.0, 1.0, 0.0, 0.0 },
		timestep = f32(1.0 / 60.0),
		physical_body_spin = 0.0,
		grind_adjusted_body_spin = 0.0,
		additive_spin = false,
		direct_spin = true,
		reverse_stance = false,
		easy_body_spins = true,
		perfect_body_flips = false,
	}
end
local function lanes(v: vector): { number }
	return { v.x, v.y, v.z, 0.0 }
end

return function(report: harness.Report)
	harness.test(report, "body_flip: perfect_front_and_back_flips_finish_at_one_revolution_with_spin", function()
		local TAU = rt.from_bits(0x40c9_0fdb)
		for _, direction in { -1.0, 1.0 } do
			local state: any = { angle = 0.0, speed = 0.0, requested_speed = 0.0, spin_transform = IDENTITY(), combined_transform = IDENTITY() }
			local st: any = { smoothing = 1.0, maximum_speed = 20.0, spin_scale = 1.0, missing_attribute_value = 0.0 }
			for tick = 1, 360 do
				body_flip.update(state, st, {
					requested_speed = direction * 4.0,
					spin_angle = f32(TAU * rt.fmin(f32(f32(tick) / 180.0), 1.0)),
					normal = { 0.0, 1.0, 0.0, 0.0 },
					flip_axis = { 1.0, 0.0, 0.0, 0.0 },
					timestep = f32(1.0 / 60.0),
					perfect_body_flips = true,
				})
				assert(math.abs(state.angle) <= TAU)
				assert(state.angle * direction > 0.0)
				for _, col in state.combined_transform do
					for _, x in col do
						assert(rt.is_finite(x))
					end
				end
			end
			assert(math.abs(state.angle - direction * TAU) < 0.001)
			local id = IDENTITY()
			for i = 1, 3 do
				for j = 1, 3 do
					assert(math.abs(state.combined_transform[i][j] - id[i][j]) < 0.001)
				end
			end
		end
	end)
	harness.test(report, "air/reckoning: angle_limit_rotates_from_toward_target_and_preserves_parallel_branch", function()
		local result = reckoning.math.limit_angle({ 0.0, 0.0, 1.0, 0.0 }, { 1.0, 0.0, 0.0, 0.0 }, rt.from_bits(0x3f49_0fdb))
		assert(math.abs(result[1] - math.sqrt(0.5)) < 0.0001)
		assert(math.abs(result[3] - math.sqrt(0.5)) < 0.0001)
		check(u.diff(reckoning.math.limit_angle({ -2.0, 0.0, 0.0, 0.0 }, { 1.0, 0.0, 0.0, 0.0 }, f32(0.1)), { -2.0, 0.0, 0.0, 0.0 }), "parallel")
	end)
	harness.test(report, "air/reckoning: direct_and_additive_spin_use_fixed_angle_step_and_keep_body_spin_history", function()
		local o, frames, spin, state, inp = orientation(), ReckoningFrames.new(), BodySpinState.new(), AirState.new(), input()
		inp.target_spin = 2.0
		inp.timestep = f32(0.1)
		local old = table.clone(BodySpinState.words(spin))
		reckoning.update(o, frames, spin, state, settings(), inp)
		assert(state.spin_angle == f32(2.0 * rt.from_bits(0x3c888889)))
		check(u.diff(BodySpinState.words(spin), old), "history")
		assert(math.abs(frames.heading[1] - math.cos(0.2)) < 0.0001)
		assert(math.abs(frames.heading[3] + math.sin(0.2)) < 0.0001)
		inp.additive_spin = true
		inp.grind_adjusted_body_spin = 3.0
		reckoning.update(o, frames, spin, state, settings(), inp)
		assert(state.spin_speed == 5.0)
		check(u.diff(BodySpinState.words(spin), old), "history 2")
	end)
	harness.test(report, "air/reckoning: airborne_filter_update_retains_controls_and_publishes_current_normal", function()
		local o, frames, spin, state, inp = orientation(), ReckoningFrames.new(), BodySpinState.new(), AirState.new(), input()
		local slow_control = table.move(words(o.slow_filter), 1, 4, 1, {})
		local fast_control = table.move(words(o.fast_filter), 1, 4, 1, {})
		inp.landing_normal = { 0.0, f32(0.8), f32(0.6), 0.0 }
		reckoning.update(o, frames, spin, state, settings(), inp)
		assert(o.ground_normal.z > 0.59)
		assert(o.up.z > 0.0 and o.up.z < o.ground_normal.z)
		check(u.diff(table.move(words(o.slow_filter), 1, 4, 1, {}), slow_control), "slow")
		check(u.diff(table.move(words(o.fast_filter), 1, 4, 1, {}), fast_control), "fast")
		local up = lanes(o.up)
		local bits = {}
		for i = 1, 4 do
			bits[i] = rt.to_bits(up[i])
		end
		check(u.diff(table.move(words(o.slow_filter), 5, 8, 1, {}), bits), "published")
		check(u.diff(frames.ground[2], lanes(o.ground_normal)), "ground")
	end)
	harness.test(report, "air/reckoning: active_zero_flip_preserves_combined_frame_and_spin_reset_preserves_flip", function()
		local o, frames, spin, state, inp = orientation(), ReckoningFrames.new(), BodySpinState.new(), AirState.new(), input()
		state.flip_active = true
		inp.target_spin = 1.0
		reckoning.update(o, frames, spin, state, settings(), inp)
		check(u.diff(frames.body_flip, IDENTITY()), "flip")
		-- ROBLOX: assert_eq! сравнивает через == (-0.0 == 0.0).
		assert(frames.heading[1] == 1.0 and frames.heading[2] == 0.0 and frames.heading[3] == 0.0 and frames.heading[4] == 0.0)
		state.flip_angle = f32(0.3)
		state.flip_speed = f32(0.2)
		AirState.reset_spin(state)
		assert(state.spin_angle == 0.0 and state.spin_speed == 0.0)
		assert(state.flip_angle == f32(0.3) and state.flip_speed == f32(0.2))
		assert(state.flip_active)
	end)

	harness.test(report, "air/body_flip + limit_angle vs Rust", function()
		for n, c in golden.flip do
			local state: any = { angle = c.init.angle, speed = c.init.speed, requested_speed = 0.0, spin_transform = IDENTITY(), combined_transform = IDENTITY() }
			for k, st in c.steps do
				body_flip.update(state, c.settings, st.input)
				check(u.diff(state, { angle = st.angle, speed = st.speed, requested_speed = st.requested_speed, spin_transform = st.spin_transform, combined_transform = st.combined_transform }),
					string.format("flip#%d step#%d", n, k))
			end
		end
		for n, c in golden.limit do
			check(u.diff(reckoning.clamp_vector_within_max_angle(c.target, c.from, c.maximum), c.out), "limit#" .. n)
		end
	end)
	harness.test(report, "air/reckoning: update, update_plant, grind_forces::reckoning по шагам vs Rust", function()
		for n, c in golden.reckoning do
			local o = GroundOrientation.new(c.go)
			local frames = ReckoningFrames.new()
			frames.heading = c.heading0
			local spin = BodySpinState.new()
			local air = AirState.new()
			air.flip_active = c.air0.flip_active
			air.flip_axis = c.air0.flip_axis
			for k, st in c.steps do
				local w = string.format("reckoning#%d step#%d (%s)", n, k, st.kind)
				if st.kind == "update" then
					reckoning.update(o, frames, spin, air, c.settings, st.input)
				elseif st.kind == "plant" then
					reckoning.update_plant(o, frames, spin, air, c.settings, st.up, st.heading, st.reverse)
				else
					grind_forces.reckoning.update(o, frames, spin, air, c.grind_settings, st.normal, st.heading, st.smoothing, st.reverse, st.physical_body_spin)
				end
				check(u.diff(o, st.orientation), w .. " orientation")
				check(u.diff(frames, st.frames), w .. " frames")
				check(u.diff(BodySpinState.words(spin), st.spin), w .. " spin")
				check(u.diff(air, st.air), w .. " air")
			end
		end
	end)
	local _ = deep
end
