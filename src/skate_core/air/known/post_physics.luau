--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/known/post_physics.rs (коммит 2e16697)
--
-- TU3 KnownAir post-physics and upside-down wipeout handling.

local rt = require("../../../rt")
local data = require("./data")

local post_physics = {}

-- `PhysState_KnownAir::CheckUpsideDownFallingWipeout`, TU3 `0x82D36650`.
function post_physics.check_upside_down_falling_wipeout(
	state: data.KnownAirState,
	frame: data.KnownAirFrame,
	mode: data.KnownAirModeSettings,
	settings: data.KnownAirWipeoutSettings,
	request: data.KnownAirWipeoutRequest,
	runtime: any
)
	if not mode.upside_down_falling_wipeout_enabled_2 then
		return
	end
	if bit32.btest(frame.flags_2468, 0x0000_0020) then
		return
	end
	if not (frame.skater_up_544[2] < settings.air_falling_min_up_y_260) then
		return
	end
	if runtime:dot3(state.landing_normal_64, frame.skater_up_544) < settings.air_falling_max_angle_264 then
		request.requested_35 = true
		request.scalar_116 = 0.0
		-- ROBLOX: u32::wrapping_add(1).
		request.counter_200 = rt.wrapping_add_u32(request.counter_200, 1)
	end
end

-- `PhysState_KnownAir::UpdatePostPhysics`, TU3 `0x82D36590`.
function post_physics.update_post_physics(
	state: data.KnownAirState,
	frame: data.KnownAirFrame,
	mode: data.KnownAirModeSettings,
	settings: data.KnownAirWipeoutSettings,
	request: data.KnownAirWipeoutRequest,
	runtime: any
)
	if not state.reached_apex_208 then
		local velocity = runtime:board_body_velocity()
		if velocity[2] < 0.0 then
			state.reached_apex_208 = true
		end
	end
	runtime:check_for_air_wipeout(true)
	post_physics.check_upside_down_falling_wipeout(state, frame, mode, settings, request, runtime)
end

return post_physics
