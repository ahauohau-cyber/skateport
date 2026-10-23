--!strict
-- Сверка animation (часть 2) с настоящим skate-core (golden/src/anim2.rs)
-- и перенос Rust-тестов grind_control, intent_filter, kickturn, pose_blend,
-- pose_sample_vbr, posture, blend_space.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local gc = require("../../../src/skate_core/animation/grind_control")
local ga = require("../../../src/skate_core/animation/ground_acceleration")
local inf = require("../../../src/skate_core/animation/intent_filter")
local kt = require("../../../src/skate_core/animation/kickturn")
local manual = require("../../../src/skate_core/animation/manual")
local lq = require("../../../src/skate_core/animation/landing_quality")
local pa = require("../../../src/skate_core/animation/playback_attributes")
local pc = require("../../../src/skate_core/animation/playback_clip")
local ptree = require("../../../src/skate_core/animation/playback_tree")
local phase_blend = require("../../../src/skate_core/animation/phase_blend")
local playback_transition = require("../../../src/skate_core/animation/playback_transition")
local posture = require("../../../src/skate_core/animation/posture")
local pose_add = require("../../../src/skate_core/animation/pose_add")
local pose_blend = require("../../../src/skate_core/animation/pose_blend")
local pose_mirror = require("../../../src/skate_core/animation/pose_mirror")
local pose_sample = require("../../../src/skate_core/animation/pose_sample")
local pose_trajectory = require("../../../src/skate_core/animation/pose_trajectory")
local pch = require("../../../src/skate_core/animation/pumping_channel")
local rf = require("../../../src/skate_core/animation/riding_fakie")
local name_mod = require("../../../src/skate_core/animation/skeleton_input/name")
local golden = require("../../golden/anim2") :: any
assert(type(golden) == "table", tostring(golden))

local f32 = rt.f32
local T = ptree.PlaybackTree

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end
local function cerr(v: any, err: any): any
	return if err ~= nil then "err" else v
end

local function build(d: any): any
	if d.kind == "Clip" then
		local attrs = {}
		for i, a in d.attrs do
			attrs[i] = { name = a.name, kind = a.kind, begin = a.begin, ["end"] = a.end_, payload = a.payload }
		end
		return { kind = "Clip", name = d.name, clip = pc.PlaybackClip.new(d.frames, d.fps, d.base, d.flags, attrs) }
	elseif d.kind == "Phase" then
		local ch = {}
		for i, c in d.children do
			ch[i] = build(c)
		end
		return { kind = "PhaseBlend", value = phase_blend.PhaseBlend.new(d.parameter, ch) }
	elseif d.kind == "Blend" then
		local ch = {}
		for i, c in d.children do
			ch[i] = build(c)
		end
		return { kind = "BlendSpace", value = ptree.blend_space.BlendSpace.new(d.parameters, ch, d.simplexes) }
	elseif d.kind == "Select" then
		local cs = {}
		for i, c in d.candidates do
			cs[i] = { name = c.name, values = c.values, tree = build(c.tree) }
		end
		return { kind = "SelectionSpace", value = ptree.selection_space.SelectionSpace.new(d.parameters, cs) }
	elseif d.kind == "Trans" then
		return { kind = "Transition", value = playback_transition.PlaybackTransition.new(build(d.from), build(d.to), d.settings) }
	end
	return { kind = "BindPose", motion = build(d.motion), posture = d.posture, board_backwards = d.board_backwards, mirror_modes = d.mirror_modes, attribute_mirror = { pairs = d.mirror_pairs } }
end

return function(report: harness.Report)
	harness.test(report, "animation/grind_control: Fade 20 × 30, crouch/facing/twist 300 vs Rust", function()
		for i, c in golden.fade do
			local f = gc.Fade.default()
			for k, s in c.steps do
				local at = string.format("fade %d/%d ", i, k)
				if s.op == "begin" then
					check(u.diff(gc.Fade.begin(f, s.a, s.b, s.t), s.out), at)
				else
					local out = gc.Fade.update(f, s.dt, s.intent, c.settings)
					assert((out == nil) == (s.out == nil), at .. "nil")
					check(u.diff({ out or 0, f.value, f.target, f.step, f.elapsed }, { s.out or 0, s.value, s.target, s.step, s.elapsed }), at)
				end
			end
		end
		for i, c in golden.grind_misc do
			local a = c.a
			check(u.diff(gc.crouch(a[1], a[2], a[3], a[4], a[5], a[6], a[7]), c.crouch), "crouch #" .. i)
			assert(gc.facing.backwards(c.n, c.b, c.ground, c.mirrored) == c.backwards, "facing #" .. i)
			check(u.diff(gc.mirrored_twist(c.twist, c.mirrored), c.mirrored_twist), "twist #" .. i)
		end
	end)
	harness.test(report, "animation/ground_acceleration: 300 vs Rust", function()
		for i, c in golden.ground_acc do
			local o = ga.publish({ deck = c.deck, ground = c.ground, world_acceleration = c.world_acceleration }, { scale_x_acc = c.scale_x_acc, min_bump_mag = c.min_bump_mag })
			check(u.diff(o.acceleration, c.acceleration), "ground_acc #" .. i)
			assert(o.bumped == c.bumped, "bumped #" .. i)
		end
	end)
	harness.test(report, "animation/intent_filter: 30 × 40 vs Rust", function()
		for i, c in golden.intent_filter do
			local st = inf.State.default()
			for k, s in c.steps do
				local at = string.format("intent_filter %d/%d ", i, k)
				if s.op == "begin" then
					check(u.diff(inf.State.begin(st, c.settings), s.out), at)
				else
					check(u.diff({ inf.State.update(st, c.settings, s.input, s.dt, s.stance), st.elapsed, st.previous_delta }, { s.out, s.elapsed, s.previous_delta }), at)
				end
			end
		end
	end)
	harness.test(report, "animation/kickturn и manual: 20 × 30 vs Rust", function()
		for i, c in golden.kickturn do
			local st = kt.State.new()
			kt.State.begin(st, c.settings)
			for k, s in c.steps do
				local at = string.format("kickturn %d/%d ", i, k)
				if s.op == "begin" then
					kt.State.begin(st, c.settings)
				else
					assert(kt.State.needs_animation_length(st) == s.need, at .. "need")
					if s.need then
						kt.State.capture_animation_length(st, s.length)
					end
					local o = kt.State.update(st, s.dt, s.intent, { max_height = s.max_height, spin_scale = s.spin_scale }, c.settings)
					check(u.diff({ o.balance, o.spin }, { s.balance, s.spin }), at)
				end
			end
		end
		for i, c in golden.manual do
			local st = manual.State.default()
			for k, s in c.steps do
				if s.op == "begin" then
					manual.State.begin(st)
				else
					check(u.diff({ manual.State.update(st, s.manual, c.settings), st.velocity }, { s.out, s.velocity }), string.format("manual %d/%d ", i, k))
				end
			end
		end
	end)
	harness.test(report, "animation/landing_quality: 400 vs Rust", function()
		for i, c in golden.landing do
			local o = table.clone(c.start)
			lq.Output.update(o, c.input, c.settings)
			check(u.diff(o, c.out), "landing #" .. i)
		end
	end)
	harness.test(report, "animation/playback_attributes и sample_curve vs Rust", function()
		local function copy(a: any): any
			local c = table.clone(a)
			c.payload = table.clone(a.payload)
			c.name = table.clone(a.name)
			return c
		end
		for i, c in golden.pattr do
			local x = copy(c.a)
			local _, e1 = rt.catch(pa.blend, x, c.b, c.w)
			check(u.diff(cerr(x, e1), c.blend), "blend #" .. i)
			local y = copy(c.a)
			local _, e2 = rt.catch(pa.scale, y, c.w)
			check(u.diff(cerr(y, e2), c.scale), "scale #" .. i)
			local z = copy(c.a)
			local _, e3 = rt.catch(pa.add_weighted, z, c.b, c.w)
			check(u.diff(cerr(z, e3), c.add), "add #" .. i)
			local m = copy(c.m)
			local _, e4 = rt.catch(pa.AttributeMirror.apply, { pairs = c.pairs }, m)
			check(u.diff(cerr(m, e4), c.mirror), "mirror #" .. i)
			local v, e5 = rt.catch(pa.intersection, c.left, c.right, c.w)
			check(u.diff(cerr(v, e5), c.inter), "intersection #" .. i)
		end
		for i, c in golden.curve do
			local v, e = rt.catch(pc.sample_curve, c.words, c.t)
			assert((e ~= nil) == c.err, "curve err #" .. i)
			if not c.err then
				check(u.diff(v, c.out), "curve #" .. i)
			end
		end
	end)
	harness.test(report, "animation/playback_tree: 60 случайных деревьев × 30 операций vs Rust", function()
		for i, c in golden.trees do
			local t = build(c.tree)
			for k, op in c.ops do
				local at = string.format("tree %d op %d (%s) ", i, k, op.op)
				if op.op == "set_attributes" then
					local v, e = rt.catch(T.set_attributes, t, op.attrs)
					assert((e ~= nil) == op.err, at .. "err " .. tostring(e))
					if not op.err then
						assert(v == op.out, at .. "out")
					end
				elseif op.op == "advance" then
					local p = { crossed_end = false, overshoot = -1.0, remaining_before_wrap = -1.0 }
					T.advance(t, op.dt, op.phase, p)
					check(u.diff(p, op.res), at)
				elseif op.op == "set_time" then
					T.set_time(t, op.v)
				elseif op.op == "set_speed" then
					T.set_speed(t, op.v)
				elseif op.op == "evaluate" then
					local cmds = {}
					local v, e = rt.catch(T.evaluate, t, { cull_threshold = op.cull, update_history = op.history }, op.enabled, cmds)
					assert((e ~= nil) == op.err, at .. "err " .. tostring(e))
					if not op.err then
						assert(v == op.out, at .. "out")
						check(u.diff(cmds, op.cmds), at .. "cmds")
					end
				elseif op.op == "attributes" then
					local v, e = rt.catch(T.attributes, t, op.mask)
					assert((e ~= nil) == op.err, at .. "err " .. tostring(e))
					if not op.err then
						check(u.diff(v, op.out), at)
					end
				elseif op.op == "attribute" then
					local v, e = rt.catch(T.attribute, t, op.name, op.mask)
					assert((e ~= nil) == op.err, at .. "err " .. tostring(e))
					if not op.err then
						assert((v == nil) == (op.out == nil), at .. "nil")
						if v then
							check(u.diff(v, op.out), at)
						end
					end
				else
					check(u.diff({ T.length(t), T.time(t) }, { op.length, op.time }), at)
				end
			end
		end
	end)
	harness.test(report, "animation/pose_*: add, blend, channel, delta, sample_key, weighted, mirror, select_frames vs Rust", function()
		for i, c in golden.poses do
			check(u.diff(pose_add.add(c.a, c.b, c.m), c.add), "add #" .. i)
			check(u.diff(pose_blend.blend_sample(c.a, c.b, c.w), c.blend), "blend #" .. i)
			check(u.diff(pose_blend.channel_blend_sample(c.a, c.b, c.w, c.m), c.channel), "channel #" .. i)
			check(u.diff(pose_trajectory.delta(c.a, c.b, c.lt), c.delta), "delta #" .. i)
			check(u.diff(pose_sample.sample_key(c.a, c.b, c.sel), c.key), "key #" .. i)
			check(u.diff(pose_sample.sample_key_vbr(c.a, c.b, c.sel), c.key_vbr), "key_vbr #" .. i)
		end
		for i, c in golden.weighted do
			local v, e = rt.catch(pose_blend.weighted, c.poses, c.weights)
			if c.err then
				assert(e ~= nil and e.kind == c.err, "weighted err #" .. i .. " " .. tostring(e and e.kind))
			else
				assert(e == nil, "weighted #" .. i)
				check(u.diff(v, c.out), "weighted #" .. i)
			end
		end
		for i, c in golden.mirror do
			local pose = rt.copy and (rt :: any).copy(c.pose) or c.pose
			local _, e = rt.catch(pose_mirror.mirror, pose, c.parents, c.partners, c.mode)
			assert((e ~= nil) == c.err, "mirror err #" .. i)
			if not c.err then
				check(u.diff(pose, c.out), "mirror #" .. i)
			end
		end
		for i, c in golden.select_frames do
			local v, e = rt.catch(pose_sample.select_frames, c.t, c.fps, c.frames, c.blend, c.offset)
			assert((e ~= nil) == c.err, "select err #" .. i)
			if not c.err then
				check(u.diff(v, c.out), "select #" .. i)
			end
		end
	end)
	harness.test(report, "animation/pumping_channel и riding_fakie: 20 × 40 vs Rust", function()
		for i, c in golden.pumping do
			local st = pch.State.default()
			for k, s in c.steps do
				local o = pch.State.update(st, s.pump, s.occupied, c.settings)
				assert(o.start == s.start, string.format("pumping %d/%d start", i, k))
				check(u.diff(o.influence, s.influence), string.format("pumping %d/%d ", i, k))
				assert((o.influence == nil) == (s.influence == nil), "influence nil")
			end
		end
		for i, c in golden.fakie do
			local st = rf.State.default()
			for k, s in c.steps do
				assert(rf.State.update(st, s.p, s.dt, c.settings) == s.out, string.format("fakie %d/%d", i, k))
			end
		end
	end)

	-- Rust-тесты
	local function fs(): any
		return { response = 1, input_scale = 1, acceleration = 0.25, maximum_step = 0.5 }
	end
	harness.test(report, "grind_control: fade_skips_first_update_then_accelerates_and_reverses_without_dt_scaling", function()
		local a = gc.Fade.default()
		assert(gc.Fade.begin(a, -1, 1, 0) == 0)
		assert(gc.Fade.update(a, 10, 1, fs()) == nil and a.elapsed == 0)
		local b = table.clone(a)
		assert(gc.Fade.update(a, f32(0.01), 1, fs()) == 0.25)
		assert(gc.Fade.update(b, 0.5, 1, fs()) == 0.25 and a.elapsed ~= b.elapsed)
		assert(gc.Fade.update(a, f32(0.01), 1, fs()) == 0.75)
		assert(gc.Fade.update(a, f32(0.01), -1, fs()) == 1 and a.step == 0.25)
		assert(gc.Fade.update(a, f32(0.01), -1, fs()) == 1)
		assert(gc.Fade.update(a, f32(0.01), -1, fs()) == 0.75)
	end)
	harness.test(report, "grind_control: crouch_obeys_physical_minimum_and_two_sided_rate_limit", function()
		assert(gc.crouch(1, 0, 0.75, 0.25, 1, 2, 0.125) == 0.75)
		assert(gc.crouch(0.75, 0, 0.75, 0.25, 1, 2, 0.125) == 0.5)
		assert(gc.crouch(0.25, 0, 0, 0.25, 1, 2, 0.125) == 0.5)
		assert(gc.crouch(1, 0.5, 0, 0.25, 1, 10, 1) == 0.5)
	end)
	harness.test(report, "intent_filter: missing_input_uses_blend_out_without_ramp_and_zero_is_present", function()
		local p = { starting_value = 0, default_value = 0, scale = 1, filters = { 0, 0, 0, 0 }, ramp_time = 8, blend_rising = 0.5, blend_falling = 0.25, blend_out = 0.125 }
		local s = { elapsed = 0, previous_delta = 0, value = 1 }
		assert(inf.State.update(s, p :: any, nil, 1, { false, false }) == 0.875)
		s = { elapsed = 0, previous_delta = 0, value = 1 }
		assert(inf.State.update(s, p :: any, 0, 1, { false, false }) == 0.96875)
	end)
	harness.test(report, "kickturn: phase_clamp_preserves_zero_length_and_end_behavior", function()
		local g = { x = { 0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 1 }, y = { 0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 1 } }
		local st = { spin = g, height = { x = g.x, y = table.create(8, 2.0) } }
		local p = { max_height = f32(0.3), spin_scale = 0.5 }
		local s = kt.State.new()
		kt.State.begin(s, st)
		kt.State.capture_animation_length(s, 0)
		assert(kt.State.update(s, 0.25, 1, p, st).spin == 0.5)
		assert(kt.State.update(s, 10, -1, p, st).spin == -0.5)
	end)
	local function pose(rotation: { number }): any
		return { scale = { 1, 1, 1, 1 }, rotation = rotation, translation = { 0, 0, 0, 0 } }
	end
	harness.test(report, "pose_blend: weighted_rejects_invalid_weights_and_rotations", function()
		local identity = pose({ 0, 0, 0, 1 })
		for _, w in { 0 / 0, math.huge, -math.huge } do
			local _, e = rt.catch(pose_blend.weighted, { { identity } }, { w })
			assert(e and e.kind == "NonFiniteWeight")
		end
		for _, q in { { 0, 0, 0, 0 }, { math.huge, math.huge, math.huge, math.huge }, { 0 / 0, 0 / 0, 0 / 0, 0 / 0 } } do
			local _, e = rt.catch(pose_blend.weighted, { { pose(q) } }, { 1 })
			assert(e and e.kind == "InvalidQuaternion")
		end
	end)
	harness.test(report, "pose_blend: blend_retains_native_antipodal_and_zero_dot_decisions", function()
		local identity = pose({ 0, 0, 0, 1 })
		local same = pose_blend.blend_sample(identity, pose({ 0, 0, 0, -1 }), 0.5)
		assert(math.abs(same.rotation[4] - 1) < 1e-6)
		local quarter = pose_blend.blend_sample(identity, pose({ 1, 0, 0, 0 }), 0.5)
		assert(quarter.rotation[1] < 0)
		assert(math.abs(math.abs(quarter.rotation[1]) - math.sqrt(0.5)) < 1e-6)
	end)
	harness.test(report, "pose_sample_vbr: boundary_uses_second_key_but_retains_two_frame_normalization", function()
		local first = { scale = { 1, 1, 1, 1 }, rotation = { 0, 0, 2, 0 }, translation = { 7, 0, 0, 1 } }
		local second = { scale = { 1, 1, 1, 1 }, rotation = { 0, 0, 0, 2 }, translation = { 8, 0, 0, 1 } }
		local s = pose_sample.sample_key_vbr(first, second, { first = 7, second = 8, coefficient = 0.25 })
		check(u.diff(s.translation, second.translation), "t")
		check(u.diff(s.rotation, { 0, 0, 0, 1 }), "r")
		check(u.diff(pose_sample.sample_key_vbr(second, second, { first = 8, second = 8, coefficient = 0 }).rotation, second.rotation), "exact")
	end)
	harness.test(report, "posture: profile_values_and_failed_construction_keeps_request", function()
		for _, c in { { 1, "POSTURE_STIFF_POSE" }, { 2, "POSTURE_SLOUCH_POSE" }, { 3, "POSTURE_BUFF_POSE" } } do
			assert(posture.PosturePose.name(posture.PosturePose.from_profile(c[1] :: number) :: any) == c[2])
		end
		for _, v in { 0, 4, 0xffffffff } do
			assert(posture.PosturePose.from_profile(v) == nil)
		end
		local st = posture.PendingPosture.default()
		posture.PendingPosture.set_profile(st, 2)
		posture.PendingPosture.set_requested(st, true)
		assert(not pcall(posture.PendingPosture.apply, st, nil, function()
			error("missing pose")
		end))
		assert(posture.PendingPosture.is_pending(st))
		local tree = posture.PendingPosture.apply(st, {}, function(t: any, p: any)
			table.insert(t, p)
			return t
		end)
		assert(tree[1] == "Slouch" and not posture.PendingPosture.is_pending(st))
	end)
	harness.test(report, "posture: posture_commands_stay_inside_bind_and_mirror_layers", function()
		for _, p in { "none", "Stiff", "Slouch", "Buff" } do
			local pp = if p == "none" then nil else p
			local tree = { kind = "BindPose", motion = { kind = "Clip", name = "motion", clip = pc.PlaybackClip.new(31, 30, 1, 0, {}) }, posture = pp, board_backwards = true, mirror_modes = { 2, 1 }, attribute_mirror = { pairs = {} } }
			T.set_time(tree, 0.25)
			assert(T.time(tree) == 0.25 and T.length(tree) == 1)
			local cmds = {}
			assert(not T.evaluate(tree, { cull_threshold = 0, update_history = false }, false, cmds) and #cmds == 0)
			assert(T.evaluate(tree, { cull_threshold = 0, update_history = false }, true, cmds))
			assert(table.remove(cmds, 1).kind == "Clip")
			local expected = {}
			if pp then
				table.insert(expected, { kind = "Pose", name = posture.PosturePose.name(pp :: any) })
				table.insert(expected, { kind = "Add", motion_is_a = true })
			end
			for _, e in {
				{ kind = "Pose", name = "RIG_TPOSE" }, { kind = "Add", motion_is_a = true },
				{ kind = "Pose", name = "BOARD_BACKWARDS" }, { kind = "Add", motion_is_a = false },
				{ kind = "Pose", name = "BOARD_BACKWARDS_IK" }, { kind = "Add", motion_is_a = true },
				{ kind = "Mirror", trajectory_mode = 2 }, { kind = "Mirror", trajectory_mode = 1 },
			} do
				table.insert(expected, e)
			end
			check(u.diff(cmds, expected), "cmds")
		end
	end)
	harness.test(report, "blend_space: bump_space_planes_and_original_outside_projection", function()
		local S = ptree.blend_space.Simplex
		local s = { children = { 0, 1, 2 }, vertices = { { 0, 0 }, { 1, 0 }, { 0, 1 } }, normals = { { -1, -1 }, { 1, 0 }, { 0, 1 } }, scales = { 1, 1, 1 } }
		check(u.diff(S.coordinates(s, { 0.25, 0.5 }), { 0.25, 0.25, 0.5 }), "coords")
		check(u.diff(S.project(s, { 2, 0.5 }), { 1, 0 }), "p1")
		check(u.diff(S.project(s, { 0.5, 2 }), { 0.5, 0.5 }), "p2")
		check(u.diff(S.project(s, { -1, -1 }), { 0, 0 }), "p3")
		local _ = name_mod
	end)
end
