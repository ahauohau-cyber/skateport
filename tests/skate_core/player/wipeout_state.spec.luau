--!strict
-- Сверка player::wipeout_state на настоящем теле скелета с Rust
-- (golden/src/skel.rs -> tests/golden/wst.luau; данные игры, не в git).

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local ws = require("../../../src/skate_core/player/wipeout_state")
local sb = require("../../../src/skate_core/physics/skeleton_body")
local rigid_body = require("../../../src/skate_core/physics/rigid_body")
local skeleton_root = require("../../../src/skate_core/physics/skeleton_root")

local f32 = rt.f32
local SkeletonBody = sb.SkeletonBody

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end

return function(report: harness.Report)
	local ok_w, golden = pcall(require, "../../golden/wst")
	local ok_s, skel = pcall(require, "../../golden/skel")
	if not ok_w or not ok_s or type(golden) ~= "table" or type(skel) ~= "table" then
		return
	end
	local g: any = golden
	local sk: any = skel
	local sim = rigid_body.RetailSimulationStep.fixed_60_hz(30, f32(0.0005), vector.create(0.0, -9.81, 0.0))

	harness.test(report, "player/wipeout_state: тело, торк, управление, отклик, приводы, восстановление vs Rust", function()
		local total = 0
		for n, case in g do
			local body = SkeletonBody.new(sb.SkeletonBodyDefinition.new(sk.sizes, sk.bones, sk.body_settings, nil), sk.body_new.authored, sk.body_new.spawn, sim)
			local dn = sk.drives_new
			local drives = sb.SkeletonDrives.new(sk.joints.initial_bones, dn.initial_mapped, dn.parents, body.animation_to_world, sk.body_new.spawn, sim, dn.settings)
			for _, board in case.boards do
				SkeletonBody.publish_physical_record(body, board)
			end
			local st = ws.State.default()
			st.velocity = case.state_velocity
			st.maximum_speed = case.state_maximum_speed
			local contact = ws.contact_response.ContactResponse.new()
			local roots = skeleton_root.SkeletonRootFrames.default()
			for k, s in case.steps do
				total += 1
				local w = string.format("wst#%d step#%d (op %d)", n, k, s.op)
				local op = s.op
				local a, b, c, input, gesture, flags, com = s.a, s.b, s.c, s.input, s.gesture, s.flags, s.com
				local pi = st.profile
				local out: any = nil
				if op == 0 then
					ws.body.set_velocity(body, a)
				elseif op == 1 then
					ws.body.add_velocity(body, a)
				elseif op == 2 then
					ws.body.remove_normal_velocity(body, b)
				elseif op == 3 then
					ws.body.blend_velocity(body, a)
				elseif op == 4 then
					ws.body.limit_velocity(body, f32(math.abs(c) * 2.0))
				elseif op == 5 then
					if s.contact then
						ws.body.set_drag(body, math.abs(input[1]), math.abs(input[2]))
					else
						ws.body.set_wipeout_drag(body, c)
					end
				elseif op == 6 then
					ws.body.special_surface(body, f32(com[2] - 1.0))
				elseif op == 7 then
					out = ws.torque.angular_velocity(body.record, body.definition.animation_masses.fractional)
					ws.torque.apply(body, com, a)
				elseif op == 8 then
					out = ws.control_air.update(st, body, com, input, s.contact)
				elseif op == 9 then
					local words = { rt.to_bits(b[1]), rt.to_bits(b[2]), rt.to_bits(b[3]), rt.to_bits(b[4]) }
					ws.control_ground.update(st, body, com, s.effective, { vectors_464_480_496_512_528 = { words } }, case.profiles[pi + 1], s.x1, s.pose)
				elseif op == 10 then
					ws.control_profile_air.update(st, body, com, s.effective, input, case.profiles[pi + 1])
				elseif op == 11 then
					ws.profiles.prepare(st, case.profiles, gesture, input)
					ws.profiles.drift(st, body, case.profiles[st.profile + 1])
				elseif op == 12 then
					local nrm = ws.response.response_normal(if s.contact then b else nil, if gesture[1] > 0.0 then s.u1 else nil)
					ws.response.trigger(st, body, nrm, input)
					ws.response.update_counter(st, s.contact)
					out = nrm
				elseif op == 13 then
					ws.response.update_counter(st, s.contact)
					ws.response.retained_velocity(st, body, drives, case.drives, s.contact, bit32.band(flags[1], 8), com)
				elseif op == 14 then
					local wt = s.out.weights
					local res = ws.drives.update(drives, s.pose, case.drives, wt)
					out = { weights = wt, residual = res }
				elseif op == 15 then
					ws.drives.set_linear_root(drives, case.drives, c)
					ws.drives.set_angular_root(drives, case.drives, input[1])
				elseif op == 16 then
					out = ws.weights.update(st, case.weights, s.contact, gesture[1] > 0.0, flags[2], gesture)
				elseif op == 17 then
					st.time = f32(st.time + 0.5)
					ws.recovery.manage_recovery(st, bit32.band(flags[1], 1), flags[2], flags[3], f32(1.0 / 60.0), case.recovery)
					ws.recovery.post_physics(st, a, s.v1, s.contact, case.recovery)
					out = ws.recovery.response_strength(st)
				elseif op == 18 then
					ws.skeleton.update_roots(roots, s.pose[24], s.x1, a, com, s.v1, c)
					out = { a2w = roots.animation_to_world, w2a = roots.world_to_animation }
				elseif op == 19 then
					local o = ws.contact_response.ContactResponse.update(contact, body, {
						com_velocity_608 = a,
						material10_normal = if s.contact then b else nil,
						material11_normal = if gesture[1] > 0.0 then s.u1 else nil,
						effective_axis_224 = s.u2,
						wipeout_control_2824_2828 = input,
					})
					out = o
				else
					local o = ws.output.output(st, s.effective, b)
					out = {
						over_599 = o.over_599, scalar_544 = o.scalar_544, no_support_time_548 = o.no_support_time_548, can_leave_72 = o.can_leave_72,
						collision_time_144 = o.collision_time_144, profile_148 = o.profile_148, retained = o.retained_air_velocity_160, change = o.response_change_588,
						teleport_countdown_68 = o.teleport_countdown_68, hips_right_angle_496 = o.hips_right_angle_496, hips_up_angle_500 = o.hips_up_angle_500,
						up = ws.orientation.alignment_up(f32(a[1] * 20.0), f32(a[2] * 20.0)), projected = ws.orientation.projected_angle(a, b, s.u2),
					}
				end
				if s.out ~= nil then
					check(u.diff(out, s.out), w .. " out")
				end
				check(u.diff(st, s.state), w .. " state")
				check(u.diff(body, s.body), w .. " body")
				check(u.diff(drives, s.drives), w .. " drives")
			end
		end
		table.insert(report.lines, string.format("      wipeout_state: %d шагов на настоящем теле", total))
	end)
end
