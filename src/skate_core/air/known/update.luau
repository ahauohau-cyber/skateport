--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/known/update.rs (коммит 2e16697)
--
-- Full outer TU3 KnownAir update in recovered call order.

local rt = require("../../../rt")
local data = require("./data")
local body = require("./body")
local footplant = require("./footplant")
local trajectory = require("./trajectory")

local f32 = rt.f32
local from_bits = rt.from_bits
local select = trajectory.select

local update_mod = {}

local ALIGNMENT_LEAD_FRAMES = from_bits(0x4040_0000) -- 0x82063B08, 3.
local MIN_ALIGNMENT_FRAMES = from_bits(0x4000_0000) -- 0x82060C50, 2.
local ONE = from_bits(0x3F80_0000) -- 0x8231A844.
local BOARD_ERROR_WINDOW = from_bits(0x3D75_C28F) -- 0x82099460, 0.06.
local ZERO = 0.0 -- 0x82165A10.

local GRIND_FOOT_BODIES: { data.GrindFootBody } = { "Body3152", "Body3156", "Body3160", "Body3168", "Body3172", "Body3176" }

-- `PhysState_KnownAir::Update`, TU3 `0x82D35C58`.
function update_mod.update(
	state: data.KnownAirState,
	frame: data.KnownAirFrame,
	settings: data.KnownAirSettings,
	mode: data.KnownAirModeSettings,
	reckoning: data.KnownAirReckoningFields,
	runtime: any
)
	footplant.update_footplant(state, frame, runtime)
	if runtime:selector_has_just_changed() then
		trajectory.init_trajectory_info(state, frame, settings, mode, runtime)
	end
	runtime:update_air_collision()

	local body_flip_speed = body.calculate_body_flip_speed(state, frame, settings, mode, reckoning, runtime)
	local body_spin_speed = body.calculate_body_spin_speed(state, frame, settings, mode, reckoning, runtime)

	local remaining_frames = f32(f32(state.collision_time_196 - state.time_in_state_180) / frame.delta_time_2604)
	local after_lead = f32(remaining_frames - ALIGNMENT_LEAD_FRAMES)
	local alignment_frames = select(f32(after_lead - MIN_ALIGNMENT_FRAMES), after_lead, MIN_ALIGNMENT_FRAMES)

	if not state.grind_air_adjust_activated_212 and (state.reached_apex_208 or alignment_frames < settings.frames_for_grind_air_assist_436) then
		local started = runtime:grind_air_adjust_started()
		runtime:set_grind_air_adjust_activated(started)
		state.grind_air_adjust_activated_212 = true
	end

	if state.targeting_grind_213 and state.grind_air_adjust_activated_212 and runtime:grind_air_adjust_adjusting() then
		for _, b in GRIND_FOOT_BODIES do
			runtime:disable_grind_foot_collision(b)
		end
	end

	runtime:update_reckoning_air_states(state.landing_normal_64, f32(ONE / alignment_frames), body_spin_speed, body_flip_speed)
	trajectory.update_trajectory_follow(state, frame, settings, runtime)
	runtime:update_known_air_skeleton(state.target_com_position_160)

	if state.time_in_state_180 < BOARD_ERROR_WINDOW then
		runtime:set_skeleton_add_skateboard_error(true)
	end

	local head_target = if bit32.btest(frame.flags_2472, 0x0040_0000) then frame.alternate_head_target_112 else state.collision_position_112
	runtime:set_head_tracking_target(head_target, true)
	runtime:update_board_steering_tilt(ZERO)

	local board_y = runtime:board_transform_height()
	if not (state.max_y_188 > board_y) then
		state.max_y_188 = board_y
	end
	if not bit32.btest(frame.flags_2468, 0x0000_0008) then
		state.time_in_state_180 = f32(state.time_in_state_180 + frame.delta_time_2604)
	end

	local com_y = runtime:skeleton_com_position()[2]
	state.com_max_y_192 = select(f32(state.com_max_y_192 - com_y), state.com_max_y_192, com_y)
end

return update_mod
