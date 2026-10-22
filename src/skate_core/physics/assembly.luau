--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/assembly.rs (коммит 2e16697)
--
-- Board constraint construction from physical body snapshots.
--
-- The default TU3 assembly has six joints, two truck drives and a hook drive. Wheel drives
-- are an alternate configuration, disabled in the recovered stock assembly.
-- World collision and gameplay force production do not belong in this module.

local rt = require("../../rt")
local board = require("./board")
local constraint_batch = require("./constraint_batch")
local drive_frames = require("./drive_frames")
local drive_parameters = require("./drive_parameters")
local drive_solver = require("./drive_solver")
local joint_builder = require("./joint_builder")
local joint_records = require("./joint_records")
local rigid_body = require("./rigid_body")
local solver = require("./solver")
local truck_frames = require("./truck_frames")
local hook_drive = require("./hook_drive")
local drive_preparation = require("./drive_preparation")

local from_bits = rt.from_bits
local to_bits = rt.to_bits
local BodyId = board.BodyId
local RetailJointRecord = joint_records.RetailJointRecord

local assembly = {}

export type BodySnapshot = {
	state_flags: number,
	rates: rigid_body.RetailBodyRates,
	inertia: rigid_body.RetailInertiaDynamics,
}

-- Separate animated target body registered by CreateHookDrive 82C0D330.
-- It is not one of the seven physical board parts and must not be substituted
-- for the deck. Startup supplies its native body state explicitly.
export type BoardHook = {
	body: BodySnapshot,
	drive: hook_drive.HookDriveState,
}

-- ROBLOX: индекс реакции с нуля, как в Rust.
assembly.HOOK_REACTION = board.BODY_COUNT

-- The caller owns the snapshots, force accumulators and tick timing. No pose
-- is adjusted here to force the board onto a plane or into an animation.
export type BoardConstraints = {
	-- Eligible rows only; retained in native registration order.
	joints: { solver.JointConstraint },
	-- Front truck, back truck, then hook; native creation/insertion order.
	drives: { drive_solver.RetailDriveRows },
}

local function joint_body(body: BodySnapshot): joint_builder.RetailJointBodyInput
	local rates = body.rates
	return {
		reaction_guest_address = 0,
		state = body.state_flags,
		orientation = rates.orientation,
		center_of_mass = rates.position,
		basis = rates.basis,
		linear_velocity = rates.linear_velocity,
		angular_velocity = rates.angular_velocity,
		force_acceleration = rates.force_acceleration,
		torque_acceleration = rates.torque_acceleration,
		inverse_mass = body.inertia.inverse_mass,
		world_inverse_inertia = rigid_body.pack_world_inverse_inertia(rates.world_inverse_inertia),
	}
end

local function drive_body(body: BodySnapshot, reaction_index: number): drive_solver.RetailDriveBodyState
	local rates = body.rates
	return {
		reaction_index = reaction_index,
		state = body.state_flags,
		orientation = rates.orientation,
		basis = rates.basis,
		center_of_mass = rates.position,
		linear_velocity = rates.linear_velocity,
		angular_velocity = rates.angular_velocity,
		force_acceleration = rates.force_acceleration,
		torque_acceleration = rates.torque_acceleration,
		inverse_mass = body.inertia.inverse_mass,
		world_inverse_inertia = rigid_body.pack_world_inverse_inertia(rates.world_inverse_inertia),
	}
end

local BoardConstraints = {}
assembly.BoardConstraints = BoardConstraints

-- ROBLOX: bodies[id + 1] для BodyId id.
-- pub fn build(bodies, hook, frames, truck_dynamics, delta_seconds) -> Self
function BoardConstraints.build(
	bodies: { BodySnapshot },
	hook: BoardHook,
	frames: { drive_frames.RetailDriveFrames },
	truck_dynamics: drive_parameters.RetailDriveDynamics,
	delta_seconds: number
): BoardConstraints
	local joints = constraint_batch.compile_active(joint_records.default_joint_records(), function(record)
		return bodies[RetailJointRecord.live_body_a(record) + 1].state_flags,
			bodies[RetailJointRecord.live_body_b(record) + 1].state_flags
	end, function(record): solver.JointConstraint
		local a = RetailJointRecord.live_body_a(record)
		local b = RetailJointRecord.live_body_b(record)
		return {
			jacobian = joint_builder.build_retail_joint_jacobian({
				parameters = record.parameters,
				frames = record.frames,
				body_a = joint_body(bodies[a + 1]),
				body_b = joint_body(bodies[b + 1]),
				time_step = delta_seconds,
				-- Guest pointer metadata is not dereferenced by the host solver.
				joint_guest_address = 0,
			}),
			reaction_a = a,
			reaction_b = b,
		}
	end)
	local trucks = { BodyId.FrontTruck, BodyId.BackTruck }
	local deck = BodyId.Deck
	local drives = constraint_batch.compile_active({ 0, 1 }, function(index: number)
		return bodies[trucks[index + 1] + 1].state_flags, bodies[deck + 1].state_flags
	end, function(index: number)
		local truck = trucks[index + 1]
		return drive_solver.build_drive_rows(
			drive_body(bodies[truck + 1], truck),
			drive_body(bodies[deck + 1], deck),
			frames[index + 1],
			truck_dynamics,
			delta_seconds
		)
	end)
	local hook_rows = constraint_batch.compile_active({ true }, function(_)
		return hook.body.state_flags, bodies[deck + 1].state_flags
	end, function(_)
		return drive_solver.build_drive_rows(
			drive_body(hook.body, assembly.HOOK_REACTION),
			drive_body(bodies[deck + 1], deck),
			frames[3],
			hook_drive.HookDriveState.solver_dynamics(hook.drive),
			delta_seconds
		)
	end)
	table.move(hook_rows, 1, #hook_rows, #drives + 1, drives)
	return { joints = joints, drives = drives }
end

local function hook_frames(words: { number }): drive_frames.RetailDriveFrames
	local function f(i: number): number
		return from_bits(words[i + 1])
	end
	local function frame(offset: number): drive_frames.RetailDriveFrame
		return {
			orientation = { x = f(offset), y = f(offset + 1), z = f(offset + 2), w = f(offset + 3) },
			translation = vector.create(f(offset + 4), f(offset + 5), f(offset + 6)),
		}
	end
	return { body_a = frame(0), body_b = frame(8) }
end

-- SetTruckDriveFrames 82C0B9C0 followed by the active-drive quaternion
-- preparation in Island::Step_Solver2 82763B08. Hook normalization is a live
-- state write; it is not deferred to the animation frame setters.
-- ROBLOX: `hook: &mut BoardHook` — hook.drive.frames меняется на месте.
function assembly.prepare_drive_frames(
	base: { drive_frames.RetailAffineTransform },
	targets: { number },
	hook: BoardHook
): { drive_frames.RetailDriveFrames }
	local trucks = {}
	for k, frames in truck_frames.steering_drive_frames(base, targets) do
		local raw = rt.zeros(16)
		for i, frame in { frames.body_a, frames.body_b } do
			local q, t = frame.orientation, frame.translation
			local values = { q.x, q.y, q.z, q.w, t.x, t.y, t.z, 0.0 }
			for j = 1, 8 do
				raw[(i - 1) * 8 + j] = to_bits(values[j])
			end
		end
		drive_preparation.normalize_drive_frames(raw)
		trucks[k] = hook_frames(raw)
	end
	drive_preparation.normalize_drive_frames(hook.drive.frames)
	return { trucks[1], trucks[2], hook_frames(hook.drive.frames) }
end

return assembly
