--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_runtime.rs (коммит 2e16697)
--
-- Persistent board physics for the host game.
--
-- Ownership and spawning are host policy. Physical initialization follows TU3
-- AddRigidBody 82AE5928 and Reset 82776140: dynamic bodies start at rest with
-- gravity accumulated, while the separate hook has zero inverse mass/tensor.
-- Part pose conversion reuses 82BD4318/82C0B2C8; no packed body is retained
-- beside the state consumed and updated by BoardStep.

local rt = require("../../rt")
local math_mod = require("../math")
local assembly = require("./assembly")
local board = require("./board")
local board_pose = require("./board_pose")
local part_mod = require("./board_pose/part")
local board_step = require("./board_step")
local drive_frames = require("./drive_frames")
local force_queue = require("./force_queue")
local hook_drive = require("./hook_drive")
local rigid_body = require("./rigid_body")

local from_bits = rt.from_bits
local to_bits = rt.to_bits
local BODY_COUNT = board.BODY_COUNT
local BoardStep = board_step.BoardStep
local BoardForceQueue = force_queue.BoardForceQueue

type Vector3 = vector
type RetailAffineTransform = drive_frames.RetailAffineTransform
type PartPose = part_mod.PartPose

local board_runtime = {}

-- The host explicitly chooses the board's initial physical mode.
-- ROBLOX: enum без данных -> числа.
board_runtime.BoardMotion = { Active = 0, Frozen = 1, Static = 2 }
local BoardMotion = board_runtime.BoardMotion

local function motion_flags(mode: number): number
	if mode == BoardMotion.Active then
		return 4
	elseif mode == BoardMotion.Frozen then
		return 2
	end
	return 1
end

export type BoardRuntime = {
	bodies: { assembly.BodySnapshot },
	mass_frames: { rigid_body.RetailLocalMassFrame },
	hook: assembly.BoardHook,
	step: board_step.BoardStep,
	forces: force_queue.BoardForceQueue,
	-- Original assembly/part group: standard82C090C0=4, wipeout82C09160=7.
	collision_group: number,
}

local function zero_inertia(): rigid_body.RetailInertiaDynamics
	return {
		inverse_tensor = vector.zero,
		inverse_mass = 0.0,
		spherical = 0.0,
		maximum_linear_velocity = 0.0,
		maximum_angular_velocity = 0.0,
		linear_drag = 0.0,
		angular_drag = 0.0,
	}
end

local function pose_words(transform: RetailAffineTransform): { number }
	local words = rt.zeros(16)
	for axis = 0, 2 do
		local column = transform.basis.columns[axis + 1]
		for k = 1, 3 do
			words[axis * 4 + k] = to_bits(column[k])
		end
	end
	local t = transform.translation
	words[13], words[14], words[15] = to_bits(t.x), to_bits(t.y), to_bits(t.z)
	return words
end

local function transform_from_words(words: { number }): RetailAffineTransform
	local function f(i: number): number
		return from_bits(words[i + 1])
	end
	return {
		basis = { columns = { { f(0), f(1), f(2) }, { f(4), f(5), f(6) }, { f(8), f(9), f(10) } } },
		translation = vector.create(f(12), f(13), f(14)),
	}
end

local function mass_frame_words(frame: rigid_body.RetailLocalMassFrame): { number }
	return pose_words({ basis = frame.basis, translation = frame.translation })
end

local function body_pose_words(rates: rigid_body.RetailBodyRates): { number }
	local words = rt.zeros(44)
	local q = rates.orientation
	words[1], words[2], words[3], words[4] = to_bits(q.x), to_bits(q.y), to_bits(q.z), to_bits(q.w)
	words[5], words[6], words[7] = to_bits(rates.position.x), to_bits(rates.position.y), to_bits(rates.position.z)
	for axis = 0, 2 do
		local column = rates.basis.columns[axis + 1]
		for k = 1, 3 do
			words[16 + axis * 4 + k] = to_bits(column[k])
		end
	end
	return words
end

local function inertia_words(inertia: rigid_body.RetailInertiaDynamics): { number }
	return {
		to_bits(inertia.inverse_tensor.x),
		to_bits(inertia.inverse_tensor.y),
		to_bits(inertia.inverse_tensor.z),
		to_bits(0.0),
		to_bits(inertia.inverse_mass),
		to_bits(inertia.spherical),
		to_bits(inertia.maximum_linear_velocity),
		to_bits(inertia.maximum_angular_velocity),
		to_bits(inertia.linear_drag),
		to_bits(inertia.angular_drag),
	}
end

-- ROBLOX: `rates: &mut RetailBodyRates` — поля таблицы меняются на месте.
local function copy_pose(part: PartPose, rates: rigid_body.RetailBodyRates)
	local words = part.body
	assert(words, "transient pose adapter has a body")
	local function f(i: number): number
		return from_bits(words[i + 1])
	end
	rates.orientation = { x = f(0), y = f(1), z = f(2), w = f(3) }
	rates.position = vector.create(f(4), f(5), f(6))
	rates.basis = { columns = { { f(16), f(17), f(18) }, { f(20), f(21), f(22) }, { f(24), f(25), f(26) } } }
end

local function rates_transform(rates: rigid_body.RetailBodyRates): RetailAffineTransform
	return { basis = math_mod.Basis3.copy(rates.basis), translation = rates.position }
end

-- pub(crate) fn initialized_body(part, inertia, simulation, mode) -> BodySnapshot
function board_runtime.initialized_body(
	part: PartPose,
	inertia_in: rigid_body.RetailInertiaDynamics,
	simulation: rigid_body.RetailSimulationStep,
	mode: number
): assembly.BodySnapshot
	local is_static = mode == BoardMotion.Static
	local inertia = if is_static then zero_inertia() else inertia_in
	local rates: rigid_body.RetailBodyRates = {
		orientation = rigid_body.RetailQuaternion.IDENTITY(),
		basis = drive_frames.RetailAffineTransform.IDENTITY().basis,
		world_inverse_inertia = { columns = { { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 } } },
		position = vector.zero,
		linear_velocity = vector.zero,
		angular_velocity = vector.zero,
		force_acceleration = if is_static then vector.zero else simulation.gravity_acceleration,
		torque_acceleration = vector.zero,
		kinetic_energy = if is_static then 0.0 else rt.F32_MAX,
		cool_down = if mode == BoardMotion.Active then 0 else simulation.cool_down,
	}
	copy_pose(part, rates)
	rates.world_inverse_inertia = rigid_body.world_inverse_inertia(rates.basis, inertia.inverse_tensor)
	return { state_flags = motion_flags(mode), rates = rates, inertia = inertia }
end

local BoardRuntime = {}
board_runtime.BoardRuntime = BoardRuntime

-- `authored` contains part poses in board space. `spawn` places the deck
-- part in world space, and moves the other parts by the same rigid delta.
-- All mass properties come from the caller's physical data producer.
function BoardRuntime.new(
	masses: { rigid_body.RetailBodyMassProperties },
	authored: { RetailAffineTransform },
	spawn: RetailAffineTransform,
	simulation: rigid_body.RetailSimulationStep,
	mode: number
): BoardRuntime
	local parts: { PartPose } = {}
	for i = 1, BODY_COUNT do
		local part: PartPose = {
			transform = pose_words(authored[i]),
			local_mass_frame = mass_frame_words(masses[i].local_mass_frame),
			body = rt.zeros(44),
			inertia = if mode ~= BoardMotion.Static then inertia_words(masses[i].dynamics) else nil,
		}
		part_mod.set_part_transform(part, pose_words(authored[i]))
		parts[i] = part
	end
	local hook_part: PartPose = {
		transform = pose_words(drive_frames.RetailAffineTransform.IDENTITY()),
		local_mass_frame = nil,
		body = rt.zeros(44),
		inertia = nil,
	}
	board_pose.set_board_transform(parts, hook_part, pose_words(spawn))
	local bodies = {}
	for i = 1, BODY_COUNT do
		bodies[i] = board_runtime.initialized_body(parts[i], masses[i].dynamics, simulation, mode)
	end
	-- CreateHookDrive 82C0D330 creates its own STATIC_BODY target. It does
	-- not alias the deck or a global world body. Its mass calculation is
	-- irrelevant to physical response because this body has no inertia.
	local hook = {
		body = board_runtime.initialized_body(hook_part, zero_inertia(), simulation, BoardMotion.Static),
		drive = hook_drive.HookDriveState.initial(),
	}
	local mass_frames = {}
	for i = 1, BODY_COUNT do
		mass_frames[i] = masses[i].local_mass_frame
	end
	return {
		bodies = bodies,
		mass_frames = mass_frames,
		hook = hook,
		step = BoardStep.default(),
		forces = BoardForceQueue.default(),
		collision_group = 4,
	}
end

-- Opt-in inspection of completed rows; capture never changes solver inputs.
function BoardRuntime.take_solver_diagnostics(self: BoardRuntime, enabled: boolean): string?
	self.step.diagnostic_capture = enabled
	local snapshot = self.step.diagnostic_snapshot
	self.step.diagnostic_snapshot = nil
	return snapshot
end

function BoardRuntime.collision_group(self: BoardRuntime): number
	return self.collision_group
end
-- All seven native board parts share the current assembly group.
function BoardRuntime.set_collision_group(self: BoardRuntime, group: number)
	self.collision_group = group
end

function BoardRuntime.bodies(self: BoardRuntime): { assembly.BodySnapshot }
	return self.bodies
end
-- Gameplay may publish actual velocities/accumulators or physical mode
-- changes here. Rendering should use the immutable view or part poses.
function BoardRuntime.bodies_mut(self: BoardRuntime): { assembly.BodySnapshot }
	return self.bodies
end
function BoardRuntime.hook(self: BoardRuntime): assembly.BoardHook
	return self.hook
end
-- Animation/state services own the hook target and live drive parameters.
function BoardRuntime.hook_mut(self: BoardRuntime): assembly.BoardHook
	return self.hook
end
function BoardRuntime.forces(self: BoardRuntime): force_queue.BoardForceQueue
	return self.forces
end
function BoardRuntime.forces_mut(self: BoardRuntime): force_queue.BoardForceQueue
	return self.forces
end
function BoardRuntime.contact_reports(self: BoardRuntime): { any }
	return BoardStep.contact_reports(self.step)
end
-- Original post-solver observers consume these completed shared rows.
function BoardRuntime.solved_reactions(self: BoardRuntime): { rigid_body.RetailReactionCorrections }
	return BoardStep.solved_reactions(self.step)
end
function BoardRuntime.solved_contacts(self: BoardRuntime): { any }
	return BoardStep.solved_contacts(self.step)
end

-- Queue clearing is a separate gameplay phase, as in GeneralUpdate
-- 82C02360. Advancing physics does not silently consume its ownership.
function BoardRuntime.clear_forces(self: BoardRuntime)
	BoardForceQueue.clear(self.forces)
end

function BoardRuntime.hook_transform(self: BoardRuntime): RetailAffineTransform
	return rates_transform(self.hook.body.rates)
end

-- Live center-of-mass pose for collision and other physical consumers.
-- ROBLOX: id — BodyId (число с нуля).
function BoardRuntime.body_transform(self: BoardRuntime, id: number): RetailAffineTransform
	return rates_transform(self.bodies[id + 1].rates)
end

-- Live visual/collision part poses, including each mass-frame offset.
-- This derives poses from the integrated bodies rather than stale spawn
-- matrices, and never writes physics from presentation.
function BoardRuntime.part_transforms(self: BoardRuntime): { RetailAffineTransform }
	local out = {}
	for i = 1, BODY_COUNT do
		local part: PartPose = {
			transform = pose_words(rates_transform(self.bodies[i].rates)),
			local_mass_frame = mass_frame_words(self.mass_frames[i]),
			body = body_pose_words(self.bodies[i].rates),
			inertia = nil,
		}
		out[i] = transform_from_words(part_mod.part_transform(part))
	end
	return out
end

-- Physical portion of82C05F50/82C0D680. Restore the authored part poses,
-- apply the requested stance and board transform, then clear rates. State
-- flags, cooldown, inertias and target-body rates retain their own owners.
function BoardRuntime.reset_physical(
	self: BoardRuntime,
	authored: { RetailAffineTransform },
	target_in: RetailAffineTransform,
	processed_flags: number,
	gravity: Vector3
)
	local target = drive_frames.RetailAffineTransform.copy(target_in)
	local parts: { PartPose } = {}
	for i = 1, BODY_COUNT do
		parts[i] = {
			transform = pose_words(authored[i]),
			local_mass_frame = mass_frame_words(self.mass_frames[i]),
			body = body_pose_words(self.bodies[i].rates),
			inertia = inertia_words(self.bodies[i].inertia),
		}
	end
	for _, i in { 6, 0, 1, 2, 3, 4, 5 } do
		part_mod.set_part_transform(parts[i + 1], pose_words(authored[i + 1]))
	end
	if bit32.band(processed_flags, 0x0010_0000) ~= 0 then
		for _, i in { 1, 3 } do
			local c = target.basis.columns[i]
			target.basis.columns[i] = { -c[1], -c[2], -c[3] }
		end
	end
	local hook: PartPose = {
		transform = pose_words(BoardRuntime.hook_transform(self)),
		local_mass_frame = nil,
		body = body_pose_words(self.hook.body.rates),
		inertia = nil,
	}
	board_pose.set_board_transform(parts, hook, pose_words(target))
	for i, body in self.bodies do
		copy_pose(parts[i], body.rates)
		body.rates.linear_velocity = vector.zero
		body.rates.angular_velocity = vector.zero
		body.rates.force_acceleration = gravity
		body.rates.torque_acceleration = vector.zero
		body.rates.world_inverse_inertia = rigid_body.world_inverse_inertia(body.rates.basis, body.inertia.inverse_tensor)
	end
	copy_pose(hook, self.hook.body.rates)
	BoardForceQueue.clear(self.forces)
	-- Completed contacts belong to the old pose; host storage can be
	-- discarded without rebuilding physical bodies or their constraints.
	self.step = BoardStep.default()
end

-- Move the complete board assembly while preserving live rates, forces,
-- contacts, and solver ownership. This is the C055F0/C0B2C8 possession
-- position operation, distinct from the full physical reset above.
function BoardRuntime.set_transform(self: BoardRuntime, target: RetailAffineTransform)
	local authored = BoardRuntime.part_transforms(self)
	local parts: { PartPose } = {}
	for i = 1, BODY_COUNT do
		parts[i] = {
			transform = pose_words(authored[i]),
			local_mass_frame = mass_frame_words(self.mass_frames[i]),
			body = body_pose_words(self.bodies[i].rates),
			inertia = inertia_words(self.bodies[i].inertia),
		}
	end
	local hook: PartPose = {
		transform = pose_words(BoardRuntime.hook_transform(self)),
		local_mass_frame = nil,
		body = body_pose_words(self.hook.body.rates),
		inertia = nil,
	}
	board_pose.set_board_transform(parts, hook, pose_words(target))
	for i, body in self.bodies do
		copy_pose(parts[i], body.rates)
		body.rates.world_inverse_inertia = rigid_body.world_inverse_inertia(body.rates.basis, body.inertia.inverse_tensor)
	end
	copy_pose(hook, self.hook.body.rates)
end

function BoardRuntime.advance(
	self: BoardRuntime,
	collisions: { board_step.BoardCollision },
	truck_targets: { number },
	settings: board_step.BoardStepSettings
)
	BoardStep.advance(self.step, self.bodies, self.hook, self.forces, collisions, truck_targets, settings)
end

-- The skater, board and hook constraints exchange reactions in every
-- iteration; this never advances the skeleton in a separate solver.
function BoardRuntime.advance_attached(
	self: BoardRuntime,
	collisions: { board_step.BoardCollision },
	truck_targets: { number },
	settings: board_step.BoardStepSettings,
	attached: board_step.AttachedStep
)
	BoardStep.advance_attached(self.step, self.bodies, self.hook, self.forces, collisions, truck_targets, settings, attached)
end

-- Publish an animation target while retaining the hook's zero physical
-- response and its separate drive state.
function BoardRuntime.set_hook_transform(self: BoardRuntime, requested: RetailAffineTransform)
	local part: PartPose = {
		transform = pose_words(BoardRuntime.hook_transform(self)),
		local_mass_frame = nil,
		body = body_pose_words(self.hook.body.rates),
		inertia = nil,
	}
	part_mod.set_part_transform(part, pose_words(requested))
	copy_pose(part, self.hook.body.rates)
end

return board_runtime
