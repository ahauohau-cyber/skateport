--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_step.rs (коммит 2e16697)
--
-- The connected-board path through TU3's simulation frame.
--
-- Sources: simulation_job_setup_resolution.json (82DC35E0),
-- drive_solver_handoff_resolution.json (82DC3098 / 82AE27D0 / 82AE6590).
-- This owns compilation, shared reactions and integration. Collision queries
-- and ground/action-state force production have separate owners.

local rt = require("../../rt")
local assembly = require("./assembly")
local board = require("./board")
local contact = require("./contact")
local board_reports = require("./contact_feedback/board_reports")
local contact_solver = require("./contact_solver")
local drive_frames = require("./drive_frames")
local drive_parameters = require("./drive_parameters")
local force_queue = require("./force_queue")
local rigid_body = require("./rigid_body")
local solver = require("./solver")

local f32 = rt.f32
local BodyId = board.BodyId
local BODY_COUNT = board.BODY_COUNT

type Vector3 = vector

local board_step = {}

-- Board parts0..6 and their separate hook7 precede the physical skater.
board_step.ATTACHED_REACTION_BASE = BODY_COUNT + 1
local ATTACHED_REACTION_BASE = board_step.ATTACHED_REACTION_BASE
local U32_MAX = 0xFFFF_FFFF

-- pub enum CollisionBody { Board(BodyId), Attached(usize), StaticWorld }
-- ROBLOX: таблица с полем kind. Индексы с нуля, как в Rust.
export type CollisionBody = { kind: "Board" | "Attached" | "StaticWorld", id: number?, index: number? }

local CollisionBody = {}
board_step.CollisionBody = CollisionBody

function CollisionBody.Board(id: number): CollisionBody
	return { kind = "Board", id = id }
end
-- Index in AttachedStep::bodies, referencing the actual physical body.
function CollisionBody.Attached(index: number): CollisionBody
	return { kind = "Attached", index = index }
end
CollisionBody.StaticWorld = { kind = "StaticWorld" } :: CollisionBody

-- ROBLOX: #[derive(PartialEq)].
function CollisionBody.eq(a: CollisionBody, b: CollisionBody): boolean
	return a.kind == b.kind and a.id == b.id and a.index == b.index
end

function CollisionBody.contact_id(self: CollisionBody): number
	if self.kind == "Board" then
		return self.id :: number
	elseif self.kind == "Attached" then
		local id = ATTACHED_REACTION_BASE + (self.index :: number)
		assert(id <= U32_MAX, "attached contact body index exceeds host storage")
		return id
	end
	return U32_MAX
end

function CollisionBody.from_contact_id(id: number): CollisionBody
	if id == U32_MAX then
		return CollisionBody.StaticWorld
	elseif id < BODY_COUNT then
		return CollisionBody.Board(BodyId.ORDER[id + 1])
	end
	assert(id >= ATTACHED_REACTION_BASE, "board target has no collision volume")
	return CollisionBody.Attached(id - ATTACHED_REACTION_BASE)
end

-- Other assemblies participating in this SAME solve. References point to the
-- actual bodies owned by the physical skeleton and its hooks. The caller builds
-- their rows after publishing this tick's physical drive targets and forces.
-- ROBLOX: `&mut` ссылки -> таблицы, которые меняются на месте.
export type AttachedStep = {
	bodies: { assembly.BodySnapshot },
	contacts: { contact_solver.RetailContactJacobian },
	joints: { solver.JointConstraint },
	drives: { any },
}

function board_step.world_reaction(attached: AttachedStep): number
	return ATTACHED_REACTION_BASE + #attached.bodies
end

-- Narrow-phase output, in the collision provider's original A/B order.
-- Materials must already be combined by `combine_contact_materials`.
export type BoardCollision = {
	body_a: CollisionBody,
	body_b: CollisionBody,
	contact: contact.RetailContactInput,
}

export type BoardStepSettings = {
	simulation: rigid_body.RetailSimulationStep,
	-- Loaded from Simulation+176 by 82DC3098. Not a fixed solver constant.
	iterations: number,
	base_truck_transforms: { drive_frames.RetailAffineTransform },
	truck_dynamics: drive_parameters.RetailDriveDynamics,
	force_point_y_offset: number,
}

-- Reuses the contact workspace between ticks. Seven board bodies and the
-- separate hook share solver reactions. This does not assign islands or
-- implement the native activation partition for multiple disconnected assemblies.
export type BoardStep = {
	contacts: { contact_solver.RetailContactJacobian },
	reports: { board_reports.BoardContactReport },
	reactions: { rigid_body.RetailReactionCorrections },
	solved_reactions: { rigid_body.RetailReactionCorrections },
	diagnostic_capture: boolean,
	diagnostic_tick: number,
	diagnostic_snapshot: string?,
}

local BoardStep = {}
board_step.BoardStep = BoardStep

-- #[derive(Default)]
function BoardStep.default(): BoardStep
	return {
		contacts = {},
		reports = {},
		reactions = {},
		solved_reactions = {},
		diagnostic_capture = false,
		diagnostic_tick = 0,
		diagnostic_snapshot = nil,
	}
end

-- Read-only solver output, before DynamicUpdate consumes/clears it.
function BoardStep.solved_reactions(self: BoardStep): { rigid_body.RetailReactionCorrections }
	return self.solved_reactions
end
function BoardStep.contact_reports(self: BoardStep): { board_reports.BoardContactReport }
	return self.reports
end
function BoardStep.solved_contacts(self: BoardStep): { contact_solver.RetailContactJacobian }
	return self.contacts
end

local function zero_reaction(): rigid_body.RetailReactionCorrections
	return rigid_body.RetailReactionCorrections.default()
end

local function copy_reaction(r: rigid_body.RetailReactionCorrections): rigid_body.RetailReactionCorrections
	return {
		linear_displacement = r.linear_displacement,
		position_displacement = r.position_displacement,
		angular_displacement = r.angular_displacement,
		orientation_displacement = r.orientation_displacement,
	}
end

local function apply_deck_forces(bodies: { assembly.BodySnapshot }, forces: force_queue.BoardForceQueue, y_offset: number)
	local deck = bodies[BodyId.Deck + 1]
	local result = force_queue.BoardForceQueue.apply_to_deck(forces, {
		force_acceleration = deck.rates.force_acceleration,
		torque_acceleration = deck.rates.torque_acceleration,
		cool_down = deck.rates.cool_down,
	}, deck.rates.basis, deck.inertia.inverse_mass, deck.rates.world_inverse_inertia, y_offset)
	deck.rates.force_acceleration = result.force_acceleration
	deck.rates.torque_acceleration = result.torque_acceleration
	deck.rates.cool_down = result.cool_down
end

local function contact_body(
	body: CollisionBody,
	bodies: { assembly.BodySnapshot },
	attached: { assembly.BodySnapshot },
	world_reaction: number
): contact.RetailContactBodyState
	local zero = vector.zero
	if body.kind == "StaticWorld" then
		return {
			contact_body_id = U32_MAX,
			reaction_id = world_reaction,
			center_of_mass = zero,
			inverse_inertia_full = zero,
			inverse_inertia_split = zero,
			inverse_mass = 0.0,
			state = 0,
			force_acceleration = zero,
			torque_acceleration = zero,
			linear_velocity = zero,
			angular_velocity = zero,
			kinetic_energy = 0.0,
			cool_down = 0,
		}
	end
	local contact_id = CollisionBody.contact_id(body)
	local b = if body.kind == "Board" then bodies[(body.id :: number) + 1] else attached[(body.index :: number) + 1]
	local rates = b.rates
	local inertia = rigid_body.pack_world_inverse_inertia(rates.world_inverse_inertia)
	return {
		contact_body_id = contact_id,
		reaction_id = contact_id,
		center_of_mass = rates.position,
		inverse_inertia_full = inertia.full,
		inverse_inertia_split = inertia.split,
		inverse_mass = b.inertia.inverse_mass,
		-- The physical assemblies subscribe to post-solver feedback. Bit 8
		-- requests contact observations; it does not alter dynamic eligibility.
		state = bit32.bor(b.state_flags, 8),
		force_acceleration = rates.force_acceleration,
		torque_acceleration = rates.torque_acceleration,
		linear_velocity = rates.linear_velocity,
		angular_velocity = rates.angular_velocity,
		kinetic_energy = rates.kinetic_energy,
		cool_down = rates.cool_down,
	}
end

-- The caller supplies current poses, processed steering targets, queued
-- forces and narrow-phase contacts. It owns the separate force-queue reset
-- in GeneralUpdate (82C02360); consuming forces does not clear the queue.
-- ROBLOX: bodies и hook меняются на месте (`&mut` в Rust).
function BoardStep.advance(
	self: BoardStep,
	bodies: { assembly.BodySnapshot },
	hook: assembly.BoardHook,
	forces: force_queue.BoardForceQueue,
	collisions: { BoardCollision },
	truck_targets: { number },
	settings: BoardStepSettings
)
	BoardStep.advance_attached(self, bodies, hook, forces, collisions, truck_targets, settings, {
		bodies = {},
		contacts = {},
		joints = {},
		drives = {},
	})
end

function BoardStep.advance_attached(
	self: BoardStep,
	bodies: { assembly.BodySnapshot },
	hook: assembly.BoardHook,
	forces: force_queue.BoardForceQueue,
	collisions: { BoardCollision },
	truck_targets: { number },
	settings: BoardStepSettings,
	attached: AttachedStep
)
	-- StartFrame writes both timing fields (82DC2FB8). Use one dt for row
	-- construction and integration, and derive the reciprocal from it.
	local s = settings.simulation
	assert(rt.is_finite(s.time_step) and s.time_step > 0.0)
	local simulation: rigid_body.RetailSimulationStep = {
		time_step = s.time_step,
		frequency = f32(1.0 / s.time_step),
		cool_down = s.cool_down,
		minimum_energy = s.minimum_energy,
		gravity_acceleration = s.gravity_acceleration,
	}
	for _, collision in collisions do
		assert(not CollisionBody.eq(collision.body_a, collision.body_b))
	end

	apply_deck_forces(bodies, forces, settings.force_point_y_offset)
	local frames = assembly.prepare_drive_frames(settings.base_truck_transforms, truck_targets, hook)
	local world_reaction = board_step.world_reaction(attached)
	table.clear(self.reactions)
	for i = 1, world_reaction + 1 do
		self.reactions[i] = zero_reaction()
	end
	table.clear(self.contacts)
	table.clear(self.reports)
	table.clear(self.solved_reactions)
	local any_active = bit32.band(hook.body.state_flags, 4) ~= 0
	for _, body in bodies do
		any_active = any_active or bit32.band(body.state_flags, 4) ~= 0
	end
	for _, body in attached.bodies do
		any_active = any_active or bit32.band(body.state_flags, 4) ~= 0
	end
	if not any_active then
		return
	end
	for _, collision in collisions do
		-- Copy force/torque workspaces AFTER force accumulation. Otherwise
		-- ContactBatchBuild cannot oppose this frame's applied forces.
		local c = contact.generate_contact(
			collision.contact,
			contact_body(collision.body_a, bodies, attached.bodies, world_reaction),
			contact_body(collision.body_b, bodies, attached.bodies, world_reaction)
		)
		table.insert(self.contacts, contact_solver.build_contact_jacobian(c, simulation.time_step))
	end
	local constraints = assembly.BoardConstraints.build(bodies, hook, frames, settings.truck_dynamics, simulation.time_step)
	local board_contacts = #self.contacts
	local board_joints = #constraints.joints
	local board_drives = #constraints.drives
	table.move(attached.contacts, 1, #attached.contacts, #self.contacts + 1, self.contacts)
	table.move(attached.joints, 1, #attached.joints, #constraints.joints + 1, constraints.joints)
	table.move(attached.drives, 1, #attached.drives, #constraints.drives + 1, constraints.drives)
	solver.solve_constraints(self.contacts, constraints.joints, constraints.drives, self.reactions, settings.iterations)
	self.diagnostic_tick = rt.wrapping_add_u32(self.diagnostic_tick, 1)
	if self.diagnostic_capture and self.diagnostic_tick % 6 == 0 then
		-- ROBLOX: в Rust здесь отладочная строка Debug-формата; формат не переносим.
		local deck = BodyId.Deck
		local r = self.reactions[deck + 1]
		self.diagnostic_snapshot = string.format(
			"tick=%d deck_position=%s reaction_linear=%s reaction_angular=%s",
			self.diagnostic_tick,
			tostring(bodies[deck + 1].rates.position),
			tostring(r.linear_displacement),
			tostring(r.angular_displacement)
		)
	end
	for i, r in self.reactions do
		self.solved_reactions[i] = copy_reaction(r)
	end
	-- Every solver family finishes before ANY body integrates. The native
	-- job tree places BatchIntegrator after all island solver jobs.
	local all: { assembly.BodySnapshot } = {}
	for _, body in bodies do
		table.insert(all, body)
	end
	table.insert(all, hook.body)
	for _, body in attached.bodies do
		table.insert(all, body)
	end
	for i = 1, math.min(#all, #self.reactions) do
		local body = all[i]
		if bit32.band(body.state_flags, 4) ~= 0 then
			body.rates = rigid_body.integrate_body_rates(body.rates, body.inertia, simulation, self.reactions[i]).state
		end
		-- DynamicUpdate clears all four working vectors, not just the
		-- velocity-producing pair. Accumulated rows are rebuilt next tick.
		self.reactions[i] = zero_reaction()
	end
	-- ContactSpiesJob follows integration (82DC35E0). Step_Solver3 then
	-- publishes reports before the physical Adjust/Output phases.
	board_reports.collect(self.reports, self.contacts, bodies, attached.bodies, simulation.frequency)
	-- Physical output/spy consumers observe the rows from the shared solve.
	for k = 1, #attached.contacts do
		attached.contacts[k] = self.contacts[board_contacts + k]
	end
	for k = 1, #attached.joints do
		attached.joints[k] = constraints.joints[board_joints + k]
	end
	for k = 1, #attached.drives do
		attached.drives[k] = constraints.drives[board_drives + k]
	end
end

return board_step
