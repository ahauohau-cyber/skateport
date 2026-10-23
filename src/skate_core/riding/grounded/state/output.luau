--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/output.rs (коммит 2e16697)
--
-- `PhysState_PhysicsGround::FillPhysOut` (`82D3A388`).
--
-- The TU3 body is a leaf: it reads Ground and ProcessedPhysIn fields and
-- writes distinct PhysOut records. Names recovered from Skate 2 are used only
-- where the TU3 offsets and operations agree. Remaining fields retain their
-- destination offsets. Xenon vector arithmetic uses the project's isolated
-- accepted host approximation; no generated runtime code is included.

local rt = require("../../../../rt")
local native_arithmetic = require("../../../physics/native_arithmetic")
local data = require("./data")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits

type F4 = { number }

local output = {}

-- ProcessedPhysIn values consumed by the TU3 output leaf.
export type GroundOutputFrame = {
	axis_464: F4,
	velocity_608: F4,
	absolute_body_speed_2616: number,
	deck_speed_2652: number,
	state_timer_2664: number,
	scalar_2720: number,
	flags_2476: number,
	flags_2484: number,
	-- ProcessedPhysIn+2548 -> selected collection+4 -> byte+109.
	selected_mode_flag_109: boolean,
}

-- Live collection values loaded through the global collection singleton.
export type GroundOutputSettings = {
	-- Selected ground-layout +4 and +8, added before the pushable-speed test.
	pushable_speed_terms_4_8: { number },
	-- Selected ground-layout +0, used by the conditional output+52/+58 test.
	mode_speed_threshold_0: number,
}

local function flush_subnormal(value: number): number
	local bits = to_bits(value)
	if bit32.band(bits, 0x7f80_0000) == 0 and bit32.band(bits, 0x007f_ffff) ~= 0 then
		return from_bits(bit32.band(bits, 0x8000_0000))
	end
	return value
end

local function reject_axis_component(velocity: F4, axis: F4): F4
	-- Direct TU3 sequence: vmsum3fp128, vmulfp128, vsubfp128. `dot3` is the
	-- isolated, explicitly documented host approximation for the Xenon sum.
	local projection = native_arithmetic.dot3(velocity, axis)
	local out = {}
	for lane = 1, 4 do
		local scaled = flush_subnormal(f32(axis[lane] * projection))
		out[lane] = flush_subnormal(f32(velocity[lane] - scaled))
	end
	return out
end

-- Complete TU3 output leaf. Every comparison uses the same strict relation as
-- its `fcmpu`/branch pair, so unordered values do not select either true path.
-- ROBLOX: Option -> значение или nil.
function output.fill_physics_output(state: data.PhysicsGroundState, frame: GroundOutputFrame, settings: GroundOutputSettings): any
	local has_world_grab_intent = bit32.btest(frame.flags_2476, 0x0040_0000)
	local velocity_projection_36 = nil
	if frame.state_timer_2664 == 0.0 then
		velocity_projection_36 = {
			velocity_without_axis_component = reject_axis_component(frame.velocity_608, frame.axis_464),
			active = true,
		}
	end
	return {
		skateboard_motion_4 = {
			is_push_accelerating = state.flag_2721,
			is_at_pushable_speed = frame.absolute_body_speed_2616 < f32(settings.pushable_speed_terms_4_8[1] + settings.pushable_speed_terms_4_8[2]),
		},
		velocity_projection_36 = velocity_projection_36,
		ground_32 = {
			wall_ride_exit = state.flag_2720,
			anti_flip_nudge_present = state.anti_flip_nudge_applied_2723,
			is_pinning = state.pinning_2727,
			anti_flip_torque = table.clone(state.anti_flip_torque_2624),
			time_to_skitch = state.scalar_2664,
			skitch_spline_height = state.scalar_2668,
			processed_scalar_2720 = frame.scalar_2720,
			processed_flag_2484_bit_13 = bit32.btest(frame.flags_2484, 0x0000_2000),
		},
		state_28 = {
			grab_spline_type = state.word_2560,
			grab_spline_object_id = state.word_2564,
			flag_84 = state.flag_2731,
			has_world_grab_intent_without_object = has_world_grab_intent and not state.flag_2729,
			manual_correction_write_78 = if state.manual_correction_2732 then true else nil,
		},
		intents_52 = {
			has_world_grab_intent = has_world_grab_intent,
			selected_mode_below_speed_threshold_58 = frame.selected_mode_flag_109 and frame.deck_speed_2652 < settings.mode_speed_threshold_0,
		},
		is_grabbing_object_72_304 = state.flag_2729,
		manual_opposition_56_168 = state.manual_opposition_2733,
		push_suppressed_20_596 = state.push_suppressed_2730,
	}
end

return output
