--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/manual_entry.rs (коммит 2e16697)
--
-- Ground's manual entry slice82D376F4..7750 and velocity helper82D37960.
-- Original-image bytes confirm the complete entry-helper branch/write order.
-- The game adapter supplies live board bodies and the shared dot calculation.

local rt = require("../../../rt")
local manual_state = require("../../physics/manual/state")

local f32 = rt.f32
local ManualState = manual_state.ManualState

type F4 = { number }

local manual_entry = {}

export type ManualGroundInput = {
	-- ProcessedPhysIn+2720; either signed zero bypasses every body operation.
	balance: number,
	-- ProcessedPhysIn+464, used directly without normalization.
	ground_normal: F4,
	-- ProcessedPhysIn+2468. Bit20 swaps the two contact-controlled groups.
	flags_2468: number,
	-- ProcessedPhysIn+2472. Bits26/27 select the two groups.
	flags_2472: number,
}

-- Direct part-body velocity access, not a force queue or delayed write list.
-- Resolve the live board assembly part on each call: native reads follow every
-- earlier write, including when multiple parts happen to refer to one body.
-- ROBLOX: трейты ManualGroundBodies / ManualGroundProjection -> таблицы методов:
--   bodies:linear_velocity(part) -> F4; bodies:set_linear_velocity(part, F4)
--   projection:normal_speed(ground_normal, velocity) -> (значение) или (nil, ошибка)
-- part — индекс с нуля, как в Rust.
export type ManualGroundBodies = {
	linear_velocity: (self: any, part: number) -> F4,
	set_linear_velocity: (self: any, part: number, velocity: F4) -> (),
}
export type ManualGroundProjection = {
	normal_speed: (self: any, ground_normal: F4, linear_velocity: F4) -> (number?, any),
}

local function remove_part(part: number, ground_normal: F4, bodies: ManualGroundBodies, projection: ManualGroundProjection)
	local velocity = bodies:linear_velocity(part)
	local normal_speed, err = projection:normal_speed(ground_normal, velocity)
	if err ~= nil then
		rt.raise(err)
	end
	local remaining = table.clone(velocity)
	for a = 1, 3 do
		-- Separate multiply then subtract82D379A4..A8, not a fused operation.
		local component = f32(ground_normal[a] * (normal_speed :: number))
		remaining[a] = f32(velocity[a] - component)
	end
	-- W is retained bit-for-bit by the native insert before each store.
	bodies:set_linear_velocity(part, remaining)
end

local function remove_velocity(input: ManualGroundInput, bodies: ManualGroundBodies, projection: ManualGroundProjection)
	if input.balance == 0.0 then
		return
	end
	remove_part(6, input.ground_normal, bodies, projection)
	-- Native flags are read after the deck write82D379B4..B8.
	local reversed = bit32.btest(input.flags_2468, bit32.lshift(1, 20))
	local contact26 = bit32.btest(input.flags_2472, bit32.lshift(1, 26))
	local contact27 = bit32.btest(input.flags_2472, bit32.lshift(1, 27))
	local first_group, second_group
	if reversed then
		first_group, second_group = contact26, contact27
	else
		first_group, second_group = contact27, contact26
	end
	if first_group then
		for _, part in { 0, 1, 4 } do
			remove_part(part, input.ground_normal, bodies, projection)
		end
	end
	if second_group then
		for _, part in { 2, 3, 5 } do
			remove_part(part, input.ground_normal, bodies, projection)
		end
	end
end

-- Full branch/write order of82D37960, conditional on the required projection.
-- Despite the recovered name, both signs of normal motion are removed. There
-- is no clamp, normal-length division, timestep or balance-sign selection.
-- ROBLOX: Result<(), P::Error> -> (true) или (nil, ошибка).
function manual_entry.remove_velocity_into_ground(input: ManualGroundInput, bodies: ManualGroundBodies, projection: ManualGroundProjection): (boolean?, any)
	return rt.catch(function()
		remove_velocity(input, bodies, projection)
		return true
	end)
end

-- Performs the actual manual-state reset/scaling, then its required velocity
-- continuation before returning to Ground Enter's subsequent category200 work.
-- An error retains the executed state/body prefix and must abort the tick.
function manual_entry.enter_ground(
	state: manual_state.ManualState,
	previous_category: number,
	powerslide_exit_scale: number,
	input: ManualGroundInput,
	bodies: ManualGroundBodies,
	projection: ManualGroundProjection
): (boolean?, any)
	if ManualState.enter_ground(state, previous_category, powerslide_exit_scale) == manual_state.ManualEntryContinuation.RemoveVelocityIntoGround then
		return manual_entry.remove_velocity_into_ground(input, bodies, projection)
	end
	return true, nil
end

return manual_entry
