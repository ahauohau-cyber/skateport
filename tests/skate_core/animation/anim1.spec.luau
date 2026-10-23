--!strict
-- Сверка animation (часть 1) с настоящим skate-core (golden/src/anim1.rs) и
-- перенос Rust-тестов bump, channel_playback, output/intents.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local A = "../../../src/skate_core/animation/"
local ale = require("../../../src/skate_core/animation/air_leg_extension")
local body_tilt = require("../../../src/skate_core/animation/body_tilt")
local bump = require("../../../src/skate_core/animation/bump")
local clip_clock = require("../../../src/skate_core/animation/clip_clock")
local cp = require("../../../src/skate_core/animation/channel_playback")
local crouching = require("../../../src/skate_core/animation/crouching")
local output = require("../../../src/skate_core/animation/output")
local commands = require("../../../src/skate_core/animation/commands")
local golden = require("../../golden/anim1") :: any
assert(type(golden) == "table", tostring(golden))

local _ = A
local f32 = rt.f32
local ClipClock = clip_clock.ClipClock
local IntentMap = output.intents.IntentMap

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end

local function pose_in(p: any): any
	local q = table.clone(p)
	q["local"] = p.local_
	q.local_ = nil
	return q
end
local function pose_out(p: any): any
	local q = table.clone(p)
	q.local_ = p["local"]
	q["local"] = nil
	return q
end

return function(report: harness.Report)
	harness.test(report, "animation/air_leg_extension: 30 × 40 vs Rust", function()
		for i, c in golden.air_leg do
			local st = ale.State.default()
			for k, s in c.steps do
				local at = string.format("air_leg %d/%d ", i, k)
				assert(ale.State.needs_initial_attribute(st) == s.need_init, at .. "need_init")
				assert(ale.State.needs_prelanding_query(st, s.p) == s.need_pre, at .. "need_pre")
				local prep = ale.prepare_to_land(s.query, s.full, s.p, c.settings)
				assert(prep == s.prep, at .. "prep")
				check(u.diff(ale.State.update(st, c.bone, s.p, c.settings, s.dt, s.initial, prep), s.out), at)
			end
		end
	end)
	harness.test(report, "animation/body_tilt: 20 × 40 vs Rust", function()
		for i, c in golden.body_tilt do
			local st = body_tilt.State.default()
			for k, s in c.steps do
				if s.disable then
					body_tilt.State.disable(st)
				end
				local out = body_tilt.State.update(st, s.enabled, s.mirrored, s.p, c.settings)
				assert((out == nil) == (s.out == nil), string.format("body_tilt %d/%d nil", i, k))
				if out then
					check(u.diff(out, s.out), string.format("body_tilt %d/%d ", i, k))
				end
			end
		end
	end)
	harness.test(report, "animation/bump: 400 vs Rust", function()
		for i, c in golden.bump do
			check(u.diff(bump.coefficients(c.a, c.mirrored, c.settings), c.out), "bump #" .. i)
		end
	end)
	harness.test(report, "animation/clip_clock: 40 × 40 vs Rust", function()
		for i, c in golden.clip do
			local clock = table.clone(c.clock)
			for k, s in c.steps do
				local at = string.format("clip %d/%d ", i, k)
				local res = table.clone(s.res_in)
				local status = 0
				if s.op == 0 then
					ClipClock.set_speed(clock, s.speed)
				elseif s.op == 1 then
					ClipClock.set_time(clock, s.time)
				elseif s.op == 2 then
					ClipClock.commit_evaluation(clock)
				else
					ClipClock.advance(clock, s.dt, s.phase, res)
					status = ClipClock.attribute_status(clock, s.begin, s.end_)
				end
				check(u.diff(clock, s.clock), at .. "clock")
				check(u.diff(res, s.res), at .. "res")
				assert(status == s.status, at .. "status")
				check(u.diff(ClipClock.sample_time(clock), s.sample), at .. "sample")
			end
		end
	end)
	harness.test(report, "animation/channel_playback: 30 × 40 + merge vs Rust", function()
		local C = cp.ChannelPlayback
		for i, c in golden.channel do
			local ch = C.new(c.settings)
			for k, s in c.steps do
				local at = string.format("channel %d/%d ", i, k)
				local out: any = nil
				if s.op == 0 then
					C["end"](ch)
				elseif s.op == 1 then
					C.end_with(ch, s.seconds, s.resurrect)
				elseif s.op == 2 then
					out = C.can_transition(ch, s.resurrect)
					if out then
						C.transition(ch, s.settings, s.resurrect)
					end
				elseif s.op == 3 then
					C.did_advance(ch, { crossed_end = s.crossed, overshoot = 0, remaining_before_wrap = 0 })
				else
					out = C.advance(ch, s.dt, s.length, s.time)
				end
				assert(out == s.out, at .. "out")
				check(u.diff(ch.weight, s.weight), at .. "weight")
				assert(C.expired(ch) == s.expired, at .. "expired")
			end
			check(u.diff(C.merge_attributes(ch, c.base, c.chan), c.merged), string.format("channel %d merge ", i))
		end
	end)
	harness.test(report, "animation/crouching: 20 × 50 vs Rust", function()
		for i, c in golden.crouch do
			local st = crouching.State.begin(c.begin, c.settings)
			check(u.diff(st.fraction, c.fraction0), string.format("crouch %d begin ", i))
			for k, s in c.steps do
				local at = string.format("crouch %d/%d ", i, k)
				check(u.diff(crouching.State.update(st, s.p, s.intents, s.dt, c.settings), s.out), at)
				check(u.diff(st.fraction, s.fraction), at .. "fraction")
			end
		end
	end)
	harness.test(report, "animation/output: sqt, sqt_to_local, иерархия vs Rust", function()
		for i, c in golden.sqt do
			check(u.diff(output.sqt_to_matrix(c.input), c.out), "sqt #" .. i)
		end
		for i, c in golden.sqt_local do
			local dst = rt.copy and (rt :: any).copy(c.dst) or c.dst
			local padded = output.sqt_to_local(c.n, c.offset, c.src, dst)
			assert(padded == c.out, "sqt_local padded #" .. i)
			check(u.diff(dst, c.result), "sqt_local #" .. i)
		end
		for i, c in golden.hierarchy do
			local dst = table.clone(c.dst)
			local ok = pcall(output.compose_hierarchy, c.n, c.parents, c.detached, c.local_, dst)
			assert(ok == c.ok, "hierarchy ok #" .. i)
			check(u.diff(dst, c.out), "hierarchy #" .. i)
			local inplace = table.clone(c.local_)
			local ok2 = pcall(output.compose_hierarchy_in_place, c.n, c.parents, c.detached, inplace)
			assert(ok2 == c.ok2, "inplace ok #" .. i)
			check(u.diff(inplace, c.inplace), "inplace #" .. i)
		end
	end)
	harness.test(report, "animation/output/intents: 20 × 80 операций vs Rust", function()
		for i, c in golden.intent_map do
			local m = IntentMap.default()
			for k, s in c.ops do
				local at = string.format("intents %d/%d ", i, k)
				local out: any = nil
				if s.op == 0 then
					local v, err = rt.catch(IntentMap.insert, m, { name = s.name, value = s.value })
					out = if err then "err" else v
				elseif s.op == 1 then
					local v, err = rt.catch(IntentMap.set, m, s.name, s.value)
					out = if err then "err" else v
				elseif s.op == 2 then
					out = IntentMap.remove(m, s.name)
				elseif s.op == 3 then
					out = IntentMap.get(m, s.name)
				end
				-- op 4: очистка решается случайно в эталоне; повторяем по записанной длине.
				if s.op == 4 and s.len == 0 and m.len ~= 0 then
					IntentMap.clear(m)
				end
				check(u.diff(out, s.out), at .. "out")
				assert(m.len == s.len, at .. "len")
				check(u.diff(IntentMap.entries(m), s.entries), at .. "entries")
			end
			local copy = IntentMap.default()
			IntentMap.replace_from(copy, m)
			check(u.diff(IntentMap.entries(copy), c.replaced), string.format("intents %d replace ", i))
		end
	end)
	harness.test(report, "animation/output: packet_reset, publish_evaluated, signal_hash vs Rust", function()
		for i, c in golden.packet do
			local pose = pose_in(c.pose)
			local fields = table.clone(c.fields)
			output.packet_reset.reset(pose, fields)
			check(u.diff(pose_out(pose), c.reset_pose), "reset pose #" .. i)
			check(u.diff(fields, c.reset_fields), "reset fields #" .. i)
			local st = table.clone(c.state)
			if st.signal then
				st.signal = table.clone(st.signal)
			end
			local ret = output.physics_packet.publish_evaluated(st, c.h, c.l, pose, c.ts, c.name)
			assert(ret == c.ret, "ret #" .. i)
			check(u.diff(pose_out(pose), c.out_pose), "publish pose #" .. i)
			check(u.diff(st, c.out_state), "publish state #" .. i)
		end
		for _, c in golden.signal_hash do
			assert(output.physics_packet.signal_hash(c[1]) == c[2], "signal_hash " .. c[1])
		end
	end)
	harness.test(report, "animation/output/actor_packet: 60 vs Rust", function()
		for i, c in golden.actor do
			local log = {}
			local e = c.env
			local settings = {}
			function settings:truck_tightness(idx: number)
				table.insert(log, "tight:" .. idx)
				return e.tight
			end
			function settings:wheel_hardness(idx: number)
				table.insert(log, "hard:" .. idx)
				return e.hard
			end
			function settings:requested_physics_mode(idx: number)
				table.insert(log, "mode:" .. idx)
				return e.mode
			end
			local env = {}
			function env:current_scene_mode()
				table.insert(log, "scene")
				return e.scene
			end
			function env:ignore_respawn_reset_button()
				table.insert(log, "ignore")
				return e.ignore
			end
			function env:actor_subobject56_slot16(a: any)
				table.insert(log, "slot16:" .. a.flags1904)
				return e.slot
			end
			function env:capture_physics_settings()
				table.insert(log, "capture")
				return settings
			end
			local actor = table.clone(c.actor)
			actor.external_physics = table.clone(actor.external_physics)
			local pose: any = { flags = c.flags }
			local fields: any = {}
			local pf: any = { external_impulse = { 0, 0, 0, 0 }, external_physics = { vectors = {}, flags = c.pf_flags }, external_reset = {}, actor_flag_1904_bit29 = false }
			output.actor_packet.publish(actor, pose, fields, pf, env :: any)
			check(u.diff(log, c.log), "actor log #" .. i)
			check(u.diff(actor, c.out_actor), "actor #" .. i)
			assert(pose.flags == c.out_flags, "actor flags #" .. i)
			check(u.diff(fields, c.fields), "actor fields #" .. i)
			check(u.diff(pf, c.pf), "actor pf #" .. i)
		end
	end)
	harness.test(report, "animation/commands: SetData очередь 30 vs Rust", function()
		local B = commands.buffers
		for i, c in golden.set_data do
			local pose = B.pose_buffers_default()
			local bufs = {}
			for k, init in c.init do
				if init.values then
					bufs[k] = B.BoneBuffers.initialized(pose.matrices, init.values)
				else
					bufs[k] = B.BoneBuffers.allocate(pose.matrices, init.len)
				end
			end
			local q = commands.batch.SetDataQueue.new(pose, c.max_units)
			local ids = {}
			for k, cmd in c.cmds do
				local update = if cmd.set then { kind = "Set", source = B.at(bufs[cmd.a + 1], cmd.fa), bone_count = cmd.count } else { kind = "Preserve" }
				local command = { kind = "Matrix", command = { update = update, internal = B.at(bufs[cmd.b + 1], cmd.fb), external = if cmd.external then B.at(bufs[cmd.c + 1], cmd.fc) else nil } }
				local deps: { any } = if cmd.dep ~= nil then { ids[cmd.dep + 1], false } else { false }
				local id, err = rt.catch(commands.batch.SetDataQueue.enqueue, q, cmd.bones, command, deps)
				assert((err == nil) == cmd.ok, string.format("set_data %d/%d ok", i, k))
				if id then
					table.insert(ids, id)
				end
			end
			local done, failure = commands.batch.PendingSetData.complete(commands.batch.SetDataQueue.submit(q))
			assert((done ~= nil) == c.ok, "set_data ok #" .. i)
			if done then
				for k, buf in bufs do
					local values = {}
					for bone = 0, c.init[k].len - 1 do
						local v, err = rt.catch(B.BoneBuffers.read, done.buffers.matrices, B.at(buf, bone), 1)
						values[bone + 1] = if err then false else v[1]
					end
					check(u.diff(values, c.result[k]), string.format("set_data %d buf %d ", i, k))
				end
			else
				assert((failure :: any).job.index == c.err.job, "set_data failure job #" .. i)
			end
		end
	end)

	-- Rust-тесты
	harness.test(report, "bump: bump_direction_scaling_thresholds_and_stance", function()
		local s = { scale_x_acc = 2, min_bump_mag = 10, min_bump_blend_value = f32(0.2), max_bump_mag = 30 }
		check(u.diff(bump.coefficients({ 0, 0, 0, 0 }, false, s), { 0, 0 }), "zero")
		for _, c in { { { 5, 0, 0, 99 }, { 0.2, 0 } }, { { 10, 0, 0, 0 }, { 0.6, 0 } }, { { 0, 0, -40, 0 }, { 0, -1 } }, { { f32(0.0000001), 0, 0, 0 }, { 0, 0 } } } do
			local result = bump.coefficients(c[1], false, s)
			local mirrored = bump.coefficients(c[1], true, s)
			for k = 1, 2 do
				assert(math.abs(result[k] - c[2][k]) < 1e-6 and mirrored[k] == -result[k])
			end
		end
		local d = bump.coefficients({ 12, 0, 18, 0 }, false, s)
		assert(math.abs(d[1] - 0.8) < 1e-6 and math.abs(d[2] - 0.6) < 1e-6)
	end)
	local function csettings(): any
		return { priority = 0, keep_alive = false, mirrored = false, speed = 1, blend_in = 0.5, hold_during_blend_in = true, blend_out = 0.5, hold_during_blend_out = false, use_attributes = false }
	end
	harness.test(report, "channel_playback: preincrement_fade_and_expiry_order_preserve_native_first_frame", function()
		local C = cp.ChannelPlayback
		local ch = C.new(csettings())
		assert(not C.advance(ch, 0.25, 2, 0) and ch.weight == 0)
		assert(C.advance(ch, 0.25, 2, 0) and ch.weight == 0.5)
		C["end"](ch)
		assert(C.advance(ch, 0.25, 2, 0.25) and ch.weight == 1 and not C.expired(ch))
		C.advance(ch, 0.25, 2, 0.5)
		assert(ch.weight == 0.5 and C.expired(ch))
	end)
	harness.test(report, "channel_playback: returning_channel_restores_from_existing_fade_without_zero_restart", function()
		local C = cp.ChannelPlayback
		local s = csettings()
		s.hold_during_blend_in = false
		local ch = C.new(s)
		C.advance(ch, 0.5, 2, 0)
		C["end"](ch)
		C.advance(ch, 0.25, 2, 0.5)
		assert(not C.can_transition(ch, false) and C.can_transition(ch, true))
		C.transition(ch, s, true)
		C.advance(ch, f32(0.1), 2, 0)
		assert(ch.weight == 0.5 and not C.expired(ch))
	end)
	local function key(seed: number): { number }
		return { seed, 0, 0, 0, 0, 0 }
	end
	harness.test(report, "output/intents: set_overwrites_and_remove_preserves_other_chain_entries", function()
		local m = IntentMap.default()
		local first, second = key(1), key(1 + output.intents.BUCKET_COUNT)
		assert(IntentMap.insert(m, { name = first, value = 1 }))
		assert(IntentMap.insert(m, { name = second, value = 2 }))
		assert(not IntentMap.set(m, first, 7))
		assert(IntentMap.get(m, first) == 7)
		assert(IntentMap.remove(m, first) and not IntentMap.remove(m, first))
		assert(m.len == 1 and IntentMap.entries(m)[1].name[1] == second[1])
	end)
	harness.test(report, "output/intents: apply_uses_existing_mutation_protocol_and_capacity", function()
		local m = IntentMap.default()
		local name = key(42)
		assert(IntentMap.apply(m, name, { kind = "Set", value = 3 }))
		assert(not IntentMap.apply(m, name, { kind = "None" }))
		assert(not IntentMap.apply(m, name, { kind = "Set", value = 4 }))
		assert(IntentMap.entries(m)[1].value == 4)
		assert(IntentMap.apply(m, name, { kind = "Remove" }) and m.len == 0)
	end)
	harness.test(report, "output/intents: insert_rejects_only_after_native_fixed_capacity", function()
		local m = IntentMap.default()
		for seed = 0, output.intents.ENTRY_CAPACITY - 1 do
			IntentMap.insert(m, { name = key(seed), value = seed })
		end
		local _, err = rt.catch(IntentMap.insert, m, { name = key(output.intents.ENTRY_CAPACITY), value = 0 })
		assert(err ~= nil)
	end)
end
