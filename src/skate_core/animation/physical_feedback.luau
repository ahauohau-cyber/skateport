--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/physical_feedback.rs (коммит 2e16697)
--
-- Physical publications consumed by riding animation, TU3 82DB6EC0.
--
-- This receives the actual board, Pumping, SpeedWobble and Reckoning results.
-- It does not reconstruct the skater frame from the deck or rendered pose.

local rt = require("../../rt")
local native_arithmetic = require("../physics/native_arithmetic")
local turn_conditioner = require("../input/turn_conditioner")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits

local physical_feedback = {}

-- The completed Reckoning owner's output required by animation publication.
-- There is intentionally no default: these are distinct physical frames.
export type ReckoningFeedback = {
	-- PhysOutSystemReckoning+64.
	system_position: vector,
	-- Reckoning+1152 -> PhysOutSystemReckoning+96 at 82DB7068.
	system_up: vector,
	-- PhysOutDeck+48.
	board_position: vector,
	-- Reckoning+1576, before the Processed2468 bit20 sign correction.
	target_lean_angle: number,
}

export type ControlFeedback = {
	-- The complete ProcessedPhysIn+2468 flag word.
	processed_flags: number,
	-- ProcessedPhysIn+2676 -> PhysOutGround+264.
	turn: number,
	-- AnimOutPhysIn+10370 -> PhysOutAnimation+156.
	animation_mirrored: boolean,
}

export type PhysicalFeedback = {
	turning: any,
	crouching: any,
	pumping_acceleration: number,
	-- PhysOutAnimation112, conditioned actual deck acceleration 82DF0508.
	ground_acceleration: { number },
	-- Original IsBumped 82BA7310 evaluated with anim_motion/bumps.
	bumped: boolean,
	-- Complete PhysOutAnimation 32..60, retained for other native consumers.
	conditioned_turn: { number },
}

local function vec(value: vector): { number }
	return { value.x, value.y, value.z, 0.0 }
end

local function flush_subnormal(value: number): number
	local bits = to_bits(value)
	if bit32.band(bits, 0x7f800000) == 0 then
		return from_bits(bit32.band(bits, 0x80000000))
	end
	return value
end

-- Postphysics publication followed by the animation turn conditioner 82DEFF38.
-- Stateful filtering happens once per conditioner update, without a dt factor.
function physical_feedback.publish(state: turn_conditioner.State, settings: turn_conditioner.Settings, motion: any, pumping: any, wobble: any, reckoning: ReckoningFeedback, controls: ControlFeedback, acceleration: any): PhysicalFeedback
	local lean = if bit32.band(controls.processed_flags, 0x00100000) ~= 0 then reckoning.target_lean_angle else -reckoning.target_lean_angle
	local turn = turn_conditioner.update(state, {
		body_160 = motion.speed,
		-- Skateboard::FillPhysOut 82C03230..3238 reads Wobble+36.
		body_176 = from_bits(wobble.words[6]),
		bundle_36_field_160 = lean,
		bundle_32_field_264 = controls.turn,
		animation_152 = if bit32.band(controls.processed_flags, 0x80000000) ~= 0 then 1 else 0,
		animation_156 = if controls.animation_mirrored then 1 else 0,
	}, settings)
	local system = vec(reckoning.system_position)
	local board = vec(reckoning.board_position)
	-- 82DB7A38..7A54: vsubfp followed by vmsum3fp. The isolated native
	-- arithmetic retains its documented host approximation boundary.
	local difference = {}
	for lane = 1, 4 do
		difference[lane] = flush_subnormal(f32(flush_subnormal(system[lane]) - flush_subnormal(board[lane])))
	end
	local height = native_arithmetic.dot3(difference, vec(reckoning.system_up))
	return {
		turning = {
			field_32 = turn[1],
			field_36 = turn[2],
			field_52 = turn[6],
			field_56 = turn[7],
			field_60 = turn[8],
			body_168 = motion.forward_speed,
		},
		crouching = {
			body_84 = motion.linear_velocity.y,
			body_164 = motion.ground_speed,
			-- 82C02CF0 copies Pumping+44, named mPumpPotential in S2 FillPhysOut.
			body_188 = pumping.pumping,
			force_516 = pumping.absorption,
			ground_force_520 = pumping.ground_normal_absorption,
			minimum_crouch_528 = pumping.minimum_crouch,
			deck_angle_532 = pumping.deck_angle_absorption,
			animation_height_72 = height,
		},
		pumping_acceleration = pumping.pump_acceleration,
		ground_acceleration = acceleration.acceleration,
		bumped = acceleration.bumped,
		conditioned_turn = turn,
	}
end

return physical_feedback
