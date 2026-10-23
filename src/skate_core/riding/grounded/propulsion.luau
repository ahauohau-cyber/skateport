--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/propulsion.rs (коммит 2e16697)
--
-- Brake/push production82D38EB4..8F08 and submission82D39194..91B0.
-- These are two distinct slices of Ground UpdateSkateboard, not an entire
-- ground update: intervening native force/manual producers must execute.

local force_queue = require("../../physics/force_queue")
local braking = require("../braking")
local push = require("../push")

type Vector3 = vector

local propulsion = {}

-- Actual ProcessedPhysIn fields consumed by these two native calculations.
-- No raw button mapping, recomputed mass, normalized axis or host timestep.
export type GroundPropulsionInput = {
	flags_2468: number,
	flags_2472: number,
	-- +2608, produced by Skeleton's push attribute path82BDAC24/2C.
	target_speed: number,
	-- +2612, copied by ProcessInput82DB4878 from player1800->4 field168.
	signed_speed: number,
	-- +2616, separate from the signed projection above.
	absolute_body_speed: number,
	-- +2660, consumed directly. Existing mass-producer attribution82C0140C
	-- still needs a fresh containing-body audit; do not recompute here.
	scalar_2660: number,
	-- +2604, unlike Ground's fixed pumping timestep.
	timestep: number,
	-- +2728, Skeleton attribute scalar consumer82BDB0E8.
	brake_input: number,
	-- +352 and+368 are distinct effective axes, used verbatim.
	push_direction: Vector3,
	brake_direction: Vector3,
	-- Processed+2544 -> collection+4 -> layout+264.
	surface_braking_factor: number,
}

export type GroundPropulsionSettings = {
	-- Ground+32 toolkit offsets20/24/28, cached by82D94D08/1C/34.
	braking: braking.BrakeSettings,
	-- Toolkit+16 from physics_push layout+8 at82D94CF4.
	maximum_pushable_speed: number,
	-- Processed+2548 -> selected collection+4 -> layout+48/+52.
	-- These are separate from the pumping fields at that mode binding.
	mode_speed_changes: { number },
}

-- Native stack results retained until the later force-submission phase.
export type GroundPropulsion = {
	braking: any, -- QueuedPointForce
	push: push.PushAcceleration,
}

-- ROBLOX: enum PropulsionSubmission ->
-- { kind = "BrakingAndPush", queued = {bool, bool} } | { kind = "ManualCorrection", queued = bool }.

-- Run only after the earlier velocity/collision branches select82D38EB4.
-- The force helpers run even if the later manual branch suppresses submission.
-- Publishes Ground+2730 after push calculation, including clearing old state.
-- ROBLOX: push_suppressed_2730: &mut u8 -> ячейка { value }.
function propulsion.calculate(input: GroundPropulsionInput, settings: GroundPropulsionSettings, push_suppressed_2730: { value: number }): GroundPropulsion
	local brake = braking.calculate_braking({
		flags_2468 = input.flags_2468,
		input_2728 = input.brake_input,
		signed_speed = input.signed_speed,
		absolute_body_speed = input.absolute_body_speed,
		surface_factor = input.surface_braking_factor,
		direction = input.brake_direction,
	}, settings.braking)
	local p = push.calculate_acceleration({
		flags_2468 = input.flags_2468,
		flags_2472 = input.flags_2472,
		target_speed = input.target_speed,
		current_speed = input.signed_speed,
		absolute_body_speed = input.absolute_body_speed,
		scale = input.scalar_2660,
		delta_seconds = input.timestep,
		direction = input.push_direction,
	}, {
		maximum_pushable_speed = settings.maximum_pushable_speed,
		low_speed_change = settings.mode_speed_changes[1],
		high_speed_change = settings.mode_speed_changes[2],
	})
	push_suppressed_2730.value = if p.suppressed then 1 else 0
	return { braking = brake, push = p }
end

local GroundPropulsion = {}
propulsion.GroundPropulsion = GroundPropulsion

-- Call at82D39194 after native correction82D39338 and any tag4/5 writes,
-- before angular changes/tag6/1/8/16. Queues both records, even zero forces.
-- A true actual CalcManualEffect output80 selects the alternate tag7 path
-- and queues its corrective force+48/point+64 instead. Output81 is not
-- this selector.82D94A20 writes
-- no r9, preserving the output80 byte through the intervening drag call.
-- Returns each append result; the native21-entry limit may drop a record.
function GroundPropulsion.submit(self: GroundPropulsion, manual: any, queue: any): any
	local Q = force_queue.BoardForceQueue
	if manual.correction_active then
		local force = manual.corrective_force_world
		local point = manual.corrective_point_body
		return {
			kind = "ManualCorrection",
			queued = Q.append(queue, {
				tag = 7,
				force_world = vector.create(force[1], force[2], force[3]),
				point_body = vector.create(point[1], point[2], point[3]),
			}),
		}
	end
	local brake = Q.append(queue, self.braking)
	local p = Q.append(queue, { tag = 3, force_world = self.push.vector, point_body = self.push.local_point })
	return { kind = "BrakingAndPush", queued = { brake, p } }
end

return propulsion
