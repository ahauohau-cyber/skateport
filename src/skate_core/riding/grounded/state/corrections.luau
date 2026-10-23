--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/corrections.rs (коммит 2e16697)
--
-- Ground correction paths called by `82D38800`.

local rt = require("../../../../rt")
local force_queue = require("../../../physics/force_queue")
local data = require("./data")

local from_bits = rt.from_bits
local to_bits = rt.to_bits

type F4 = { number }

local corrections = {}

local function call(value: any, err: any): any
	if err ~= nil then
		rt.raise(err)
	end
	return value
end
local function wrapping_add(value: number, add: number): number
	return rt.to_i32(value + add)
end
local function flip_sign_bit(value: number): number
	return from_bits(bit32.bxor(to_bits(value), 0x8000_0000))
end

export type AntiFlipNudgeInput = { deck_speed_2652: number, deck_axis_96: F4 }
-- ROBLOX: трейт AntiFlipNudgeMath -> методы math:dot3(l, r), math:scale_to_magnitude(v, sq, m).
export type AntiFlipNudgeResult = { attempted: boolean, queued: boolean }

local DECK_SPEED_LIMIT = from_bits(0x3f8c_cccd)

-- Complete state/branch/queue contract of `UpdateAntiFlipNudge` `82D39338`.
-- ROBLOX: Result<_, M::Error> -> (значение) или (nil, ошибка).
function corrections.update_anti_flip_nudge(state: data.PhysicsGroundState, input: AntiFlipNudgeInput, queue: any, math_: any): (AntiFlipNudgeResult?, any)
	return rt.catch(function(): AntiFlipNudgeResult
		local anti_flip_squared = call(math_:dot3(state.anti_flip_torque_2624, state.anti_flip_torque_2624))
		-- `ble` after `fcmpu` also takes the unordered case.
		state.anti_flip_nudge_frames_2752 = if anti_flip_squared > 0.0 then wrapping_add(state.anti_flip_nudge_frames_2752, 1) else 0
		if state.anti_flip_nudge_frames_2752 <= 12 or not (input.deck_speed_2652 < DECK_SPEED_LIMIT) then
			return { attempted = false, queued = false }
		end
		local direction = table.clone(input.deck_axis_96)
		if direction[2] > 0.0 then
			for i = 1, 4 do
				direction[i] = flip_sign_bit(direction[i])
			end
		end
		direction[2] = 0.0
		local squared = call(math_:dot3(direction, direction))
		if not (squared > from_bits(0x3a83_126f)) then
			return { attempted = false, queued = false }
		end
		local force = call(math_:scale_to_magnitude(direction, squared, 50.0))
		local queued = force_queue.BoardForceQueue.append(queue, {
			tag = 17,
			force_world = vector.create(force[1], force[2], force[3]),
			point_body = vector.zero,
		})
		-- The native byte is set after the append call regardless of capacity.
		state.anti_flip_nudge_applied_2723 = true
		return { attempted = true, queued = queued }
	end)
end

export type HangUpInput = {
	flags_1516: number,
	deck_speed_2652: number,
	scalar_84: number,
	-- Exact `vmsum3fp128` comparison at `82D39744..82D39764`.
	geometry_axis_dot_positive: boolean,
}

-- Complete counter and effect order of `ManageHangUps` `82D39510`.
function corrections.manage_hang_ups(state: data.PhysicsGroundState, input: HangUpInput, services: any): (boolean?, any)
	return rt.catch(function()
		local investigating = bit32.btest(input.flags_1516, 0x0800_0000)
		if investigating then
			if input.deck_speed_2652 < DECK_SPEED_LIMIT and input.scalar_84 < from_bits(0x3f66_6666) and input.scalar_84 > 0.0 then
				state.hang_detection_frames_2740 = wrapping_add(state.hang_detection_frames_2740, 1)
			end
		else
			state.hang_detection_frames_2740 = 0
		end
		if state.hang_detection_frames_2740 == 20 then
			state.hang_force_frames_2744 = 10
			state.vector_2608 = call(services:build_hang_force())
		end
		if state.hang_force_frames_2744 > 0 then
			if investigating then
				call(services:apply_hang_force(state.vector_2608))
			end
			state.hang_force_frames_2744 = wrapping_add(state.hang_force_frames_2744, -1)
			if state.hang_force_frames_2744 == 0 then
				state.hang_detection_frames_2740 = 0
			end
		end
		local geometry_candidate = input.deck_speed_2652 < DECK_SPEED_LIMIT
			and bit32.band(input.flags_1516, 0x0c00_0000) == 0x0c00_0000
			and input.geometry_axis_dot_positive
		local hung = false
		if geometry_candidate then
			hung = call(services:detect_hung_up_geometry())
		end
		state.hung_wipeout_frames_2748 = if hung then wrapping_add(state.hung_wipeout_frames_2748, 1) else 0
		if state.hung_wipeout_frames_2748 > 20 then
			call(services:request_wipeout())
		end
		return true
	end)
end

export type HalfpipeWheelCatchInput = {
	flags_1516: number,
	deck_speed_2652: number,
	deck_x_axis_y: number,
	deck_y_axis_y: number,
	signed_deck_distance: number,
}

-- Gating and effect order of `ManageHalfpipeWheelCatches` `82D39868`.
function corrections.manage_halfpipe_wheel_catches(input: HalfpipeWheelCatchInput, services: any): (boolean?, any)
	return rt.catch(function(): boolean
		local candidate = bit32.btest(input.flags_1516, 0x0800_0000)
			and input.deck_speed_2652 < 3.0
			and math.abs(input.deck_x_axis_y) < from_bits(0x3f11_eb85)
			and math.abs(input.deck_y_axis_y) < from_bits(0x3df5_c28f)
			and input.signed_deck_distance < from_bits(0x3de1_47ae)
			and input.signed_deck_distance > 0.0
		if not candidate then
			return false
		end
		local displacement = call(services:angular_displacement())
		call(services:apply_angular_displacement(displacement))
		return true
	end)
end

export type PinningInput = { flags_2488: number, frames_since_teleport_2584: number, flags_2472: number }

-- Complete state gating of `ConsiderPinning` `82D39A18`.
function corrections.consider_pinning(state: data.PhysicsGroundState, input: PinningInput, services: any): (boolean?, any)
	return rt.catch(function()
		if bit32.btest(input.flags_2488, 1) then
			state.pinning_2727 = false
			state.was_pinning_2728 = false
			return true
		end
		if state.human_player_2724 and input.frames_since_teleport_2584 < 90 then
			local eligible = state.was_pinning_2728 or input.frames_since_teleport_2584 < 30
			local controls_seen = input.frames_since_teleport_2584 > 0 and bit32.band(input.flags_2472, 0x0080_0000) == 0
			state.controls_latched_2725 = state.controls_latched_2725 or controls_seen
			if eligible and state.captured_position_valid_2726 and not state.controls_latched_2725 then
				call(services:pin_to_captured_position(state.captured_position_x_2656, state.captured_position_z_2660))
				state.pinning_2727 = true
			end
		end
		state.was_pinning_2728 = state.pinning_2727
		return true
	end)
end

return corrections
