-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    Vector4 = {},
    AirTrajectory = {},
    PhysicsAirState = {}
}

function t1.PhysicsAirState.default() -- line: 37
    return {
        time_in_state = 0,
        start_y = 0,
        max_y = 0,
        reached_apex = false,
        use_centre_of_mass_velocity = false,
        selector_latch_174 = false,
        trajectory_query_countdown = 0,
        centre_of_mass_trajectory = {
            scalar_48 = -1,
            position = { 0, 0, 0, 0 },
            velocity = { 0, 0, 0, 0 },
            acceleration = { 0, 0, 0, 0 }
        },
        landing_normal = { 0, 1, 0, 0 }
    }
end

t1.PhysicsAirFrame = {}
t1.PhysicsAirSettings = {}
t1.PhysicsAirReckoningFields = {}
t1.AirBoardForce = {}
t1.AirBoardForce.ZERO = {
    force_world = { 0, 0, 0, 0 },
    point_board_local = { 0, 0, 0, 0 }
}
t1.PhysicsAirOutput = {}

return t1
