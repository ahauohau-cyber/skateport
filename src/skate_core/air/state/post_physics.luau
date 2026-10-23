--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/state/post_physics.rs (коммит 2e16697)
--
-- TU3 PhysicsAir post-physics update (`0x82D34DD8`).

local data = require("./data")

local post_physics = {}

-- Latches the first strict downward board velocity, then always runs the air
-- wipeout check. Negative zero and NaN do not mark the apex.
function post_physics.update_post_physics(state: data.PhysicsAirState, runtime: any)
	if not state.reached_apex then
		local board_velocity = runtime:board_body_velocity()
		if board_velocity[2] < 0.0 then
			state.reached_apex = true
		end
	end
	runtime:check_for_air_wipeout(false)
end

return post_physics
