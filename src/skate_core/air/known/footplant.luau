--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/known/footplant.rs (коммит 2e16697)
--
-- Footplant branch embedded in TU3 KnownAir update.

local rt = require("../../../rt")
local data = require("./data")

local f32 = rt.f32
local from_bits = rt.from_bits

local footplant = {}

local MIN_FOOTPLANT_TIME = from_bits(0x3DCC_CCCD) -- 0x820641A8.

-- `0x82D36728`, preserving the reset gate and the three update-call order.
function footplant.update_footplant(state: data.KnownAirState, frame: data.KnownAirFrame, runtime: any)
	if
		not bit32.btest(frame.flags_2480, 0x0400_0000)
		or bit32.btest(frame.flags_2476, 0x0400_0000)
		or state.time_in_state_180 <= MIN_FOOTPLANT_TIME
	then
		runtime:reset_footplants()
		return
	end

	local selected: data.KnownAirTrajectory = runtime:selector_trajectory_2704()
	local input: data.KnownAirFootplantInput = {
		trajectory = table.clone(selected),
		remaining_collision_time = f32(state.collision_time_196 - state.time_in_state_180),
		collision_position = state.collision_position_112,
		landing_normal = state.landing_normal_64,
	}
	runtime:shift_footplant_trajectory_to_index(input.trajectory, state.trajectory_index_216)
	runtime:update_footplant_prediction(input)
	runtime:update_footplant_lock(input)
	runtime:update_footplant_pose(input)
end

return footplant
