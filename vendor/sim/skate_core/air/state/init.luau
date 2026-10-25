-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/air/state/board")
local v2 = import("skate_core/air/state/data")
local v3 = import("skate_core/air/state/jump_velocity")
local v4 = import("skate_core/air/state/lifecycle")
local v5 = import("skate_core/air/state/math")
local v6 = import("skate_core/air/state/post_physics")
local v7 = import("skate_core/air/state/runtime")
local v8 = import("skate_core/air/state/update")

return {
    update_skateboard = v1.update_skateboard,
    AirBoardForce = v2.AirBoardForce,
    AirTrajectory = v2.AirTrajectory,
    PhysicsAirFrame = v2.PhysicsAirFrame,
    PhysicsAirOutput = v2.PhysicsAirOutput,
    PhysicsAirReckoningFields = v2.PhysicsAirReckoningFields,
    PhysicsAirSettings = v2.PhysicsAirSettings,
    PhysicsAirState = v2.PhysicsAirState,
    PhysicsAirMath = v3.PhysicsAirMath,
    calculate_velocity_from_jump = v3.calculate_velocity_from_jump,
    AirMath = v5.AirMath,
    angle_between_vectors = v5.angle_between_vectors,
    clamp_jump_velocity = v5.clamp_jump_velocity,
    enter = v4.enter,
    exit = v4.exit,
    fill_physics_output = v4.fill_physics_output,
    update_post_physics = v6.update_post_physics,
    PhysicsAirLaunchInfo = v7.PhysicsAirLaunchInfo,
    PhysicsAirRuntime = v7.PhysicsAirRuntime,
    integrate_trajectory_fixed_step = v8.integrate_trajectory_fixed_step,
    update = v8.update,
    wrap_signed_angle = v8.wrap_signed_angle
}
