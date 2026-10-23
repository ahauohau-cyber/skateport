--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/braking.rs (коммит 2e16697)
--
-- TU3 ground braking and linear drag, using the existing ground-force
-- direct82D94AE0/82D94A20 exports and SKATE3_MAIN_SKATER_FUNCTIONS.md.
-- Cached ground settings are explicit inputs; no replacement tuning defaults.

local rt = require("../../rt")

local f32 = rt.f32

type Vector3 = vector

local braking = {}

export type BrakeSettings = {
	-- Cached settings +20, multiplied by processed input +2728.
	input_force: number,
	-- Cached settings +24. The second request overrides the first.
	override_force: number,
	-- Cached settings +28, compared against processed absolute speed +2616.
	minimum_speed: number,
}

export type BrakeInput = {
	flags_2468: number,
	input_2728: number,
	signed_speed: number,
	absolute_body_speed: number,
	-- Selected surface collection's layout +264.
	surface_factor: number,
	-- Processed vector +368, used without normalization.
	direction: Vector3,
}

-- Toolkit_CalcBraking 82D94AE0. GroundUpdate appends even a zero result
-- with tag 2 at 82D391A0. This result is force, not a velocity assignment.
function braking.calculate_braking(input: BrakeInput, settings: BrakeSettings): { tag: number, force_world: Vector3, point_body: Vector3 }
	local amount = if bit32.btest(input.flags_2468, 0x4000_0000) then f32(input.input_2728 * settings.input_force) else 0.0
	if bit32.btest(input.flags_2468, 0x2000_0000) then
		amount = settings.override_force
	end
	local scaled = f32(input.surface_factor * amount)
	local sign = if input.signed_speed < 0.0 then 1.0 else -1.0
	amount = f32(sign * scaled)
	-- 82D94B78 bge retains the amount when the comparison is unordered.
	if input.absolute_body_speed < settings.minimum_speed then
		amount = 0.0
	end
	return {
		tag = 2,
		force_world = vector.create(f32(input.direction.x * amount), f32(input.direction.y * amount), f32(input.direction.z * amount)),
		point_body = vector.zero,
	}
end

export type LinearDragSettings = {
	-- Cached +1244; multiplied by native constant 2.0 at 82060C50.
	brake_speed: number,
	-- Cached +1248.
	balance_speed: number,
	-- Cached +1252. Original semantic name remains unresolved.
	comparison_threshold: number,
	-- Cached +1256.
	balance_drag: number,
}

export type LinearDragInput = {
	flags_2468: number,
	absolute_body_speed: number,
	balance_2720: number,
	scalar_2724: number,
	-- Floating argument f1 supplied by GroundUpdate, distinct from speed.
	comparison_scalar: number,
}

-- Toolkit_CalcLinearDrag 82D94A20, including its low-speed brake override.
-- Applying the result to inertia is a separate caller operation.
function braking.calculate_linear_drag(input: LinearDragInput, settings: LinearDragSettings): number
	local brake_override = input.absolute_body_speed < f32(settings.brake_speed * 2.0)
		and bit32.btest(input.flags_2468, 0x6000_0000)
		and not (input.scalar_2724 > 0.0)
		and input.balance_2720 == 0.0
	local balance_drag = input.balance_2720 ~= 0.0
		and input.absolute_body_speed < settings.balance_speed
		and input.comparison_scalar > settings.comparison_threshold
	if brake_override then
		return 1.0
	elseif balance_drag then
		return settings.balance_drag
	end
	return 0.0
end

return braking
