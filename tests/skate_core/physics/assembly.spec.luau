--!strict
-- Сверка joint_records, joint_builder, hook_drive, truck_frames и assembly
-- с настоящим skate-core (golden/src/assembly.rs).

local harness = require("../../harness")
local u = require("../../util")
local joint_records = require("../../../src/skate_core/physics/joint_records")
local joint_builder = require("../../../src/skate_core/physics/joint_builder")
local hook_drive = require("../../../src/skate_core/physics/hook_drive")
local truck_frames = require("../../../src/skate_core/physics/truck_frames")
local assembly = require("../../../src/skate_core/physics/assembly")
local drive_frames = require("../../../src/skate_core/physics/drive_frames")
local drive_parameters = require("../../../src/skate_core/physics/drive_parameters")
local rigid_body = require("../../../src/skate_core/physics/rigid_body")
local solver = require("../../../src/skate_core/physics/solver")
local golden = require("../../golden/assembly")

local fb = u.fb
local DT = fb(0x3C88_8889)

local function jbody(t: { any }): any
	return {
		reaction_guest_address = t[1],
		state = t[2],
		orientation = u.Q(t[3]),
		center_of_mass = u.V(t[4]),
		basis = u.B(t[5]),
		linear_velocity = u.V(t[6]),
		angular_velocity = u.V(t[7]),
		force_acceleration = u.V(t[8]),
		torque_acceleration = u.V(t[9]),
		inverse_mass = fb(t[10]),
		world_inverse_inertia = { full = u.V(t[11]), split = u.V(t[12]) },
	}
end

return function(report: harness.Report)
	harness.test(report, "joint_records: joint_records vs Rust", function()
		u.count(report, harness, "joint_records", golden.records, function(case)
			local s = case.settings
			local recs = joint_records.joint_records({
				truck_twist_limit_degrees = fb(s[1]),
				truck_twist_angle_degrees = fb(s[2]),
				wheel_swing_limit_degrees = fb(s[3]),
			})
			for i, want in case.records do
				local got = recs[i]
				if got.definition_body_0 ~= want[1] or got.definition_body_1 ~= want[2] then
					return false
				end
				if not u.same_words(got.parameters.words, want[3]) or not u.same_words(got.frames.words, want[4]) then
					return false
				end
			end
			return #recs == #case.records
		end)
	end)

	harness.test(report, "joint_builder: build_retail_joint_jacobian vs Rust", function()
		u.count(report, harness, "build_retail_joint_jacobian", golden.joints, function(case)
			local j = joint_builder.build_retail_joint_jacobian({
				parameters = { words = case.p },
				frames = { words = case.f },
				body_a = jbody(case.a),
				body_b = jbody(case.b),
				time_step = DT,
				joint_guest_address = case.addr,
			})
			return u.same_words(j.words, case.out)
		end)
	end)

	harness.test(report, "hook_drive: состояния HookDriveState vs Rust", function()
		local steps = golden.hook
		local h = hook_drive.HookDriveState.initial()
		local animated = 0
		local function check(k: number)
			local want = steps[k]
			harness.check(
				u.same_words(h.frames, want[1]) and u.same_words(h.dynamics, want[2]) and animated == want[3],
				"шаг " .. k
			)
		end
		check(1)
		for k, op in { 0, 1, 2, 3, 0, 2, 1, 3 } do
			if op == 0 then
				animated = hook_drive.HookDriveState.enable_animation_soft(h)
			elseif op == 1 then
				hook_drive.HookDriveState.enable_angular_soft(h)
			elseif op == 2 then
				animated = hook_drive.HookDriveState.enable_angular_only(h)
			else
				animated = hook_drive.HookDriveState.disable_animation(h)
			end
			check(k + 1)
		end
	end)

	harness.test(report, "truck_frames: steering_truck_transforms / steering_drive_frames vs Rust", function()
		u.count(report, harness, "truck_frames", golden.trucks, function(case)
			local base = drive_frames.default_truck_transforms()
			local t = { fb(case[1][1]), fb(case[1][2]) }
			local tr = truck_frames.steering_truck_transforms(base, t)
			local fr = truck_frames.steering_drive_frames(base, t)
			return u.same_a(tr[1], case[2]) and u.same_a(tr[2], case[3]) and u.same_frames(fr[1], case[4]) and u.same_frames(fr[2], case[5])
		end)
	end)

	harness.test(report, "assembly: prepare_drive_frames + BoardConstraints + solve vs Rust", function()
		u.count(report, harness, "assembly", golden.assembly, function(case)
			local bodies = {}
			for i, b in case.bodies do
				bodies[i] = u.snapshot(b)
			end
			local hook = {
				body = u.snapshot(case.hook.body),
				drive = { frames = table.clone(case.hook.frames), dynamics = table.clone(case.hook.dynamics) },
			}
			local frames = assembly.prepare_drive_frames(
				drive_frames.default_truck_transforms(),
				{ fb(case.targets[1]), fb(case.targets[2]) },
				hook
			)
			for i, f in case.frames do
				if not u.same_frames(frames[i], f) then
					return false
				end
			end
			if not u.same_words(hook.drive.frames, case.hook_frames_after) then
				return false
			end
			local c = assembly.BoardConstraints.build(
				bodies,
				hook,
				frames,
				drive_parameters.retail_truck_drive_dynamics(drive_parameters.RetailTruckDriveSettings.STOCK()),
				DT
			)
			if #c.joints ~= #case.joints or #c.drives ~= case.drive_count then
				return false
			end
			for i, j in case.joints do
				local got = c.joints[i]
				if not u.same_words(got.jacobian.words, j[1]) or got.reaction_a ~= j[2] or got.reaction_b ~= j[3] then
					return false
				end
			end
			local reactions = {}
			for i = 1, 8 do
				reactions[i] = rigid_body.RetailReactionCorrections.default()
			end
			solver.solve_constraints({}, c.joints, c.drives, reactions, case.iterations)
			for i, d in case.drives do
				if not u.same_f3(c.drives[i].accumulated_linear_impulse, d[1]) or not u.same_f3(c.drives[i].accumulated_angular_impulse, d[2]) then
					return false
				end
			end
			for i, r in case.reactions do
				if not u.same_reaction(reactions[i], r) then
					return false
				end
			end
			return true
		end)
	end)
end
