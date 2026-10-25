-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/air/known/body")
local v2 = import("skate_core/air/known/data")
local v3 = import("skate_core/air/known/lifecycle")
local v4 = import("skate_core/air/known/output")
local v5 = import("skate_core/air/known/post_physics")
local v6 = import("skate_core/air/known/runtime")
local v7 = import("skate_core/air/known/trajectory")
local v8 = import("skate_core/air/known/update")

return {
    calculate_body_flip_speed = v1.calculate_body_flip_speed,
    calculate_body_spin_speed = v1.calculate_body_spin_speed,
    AffineTransform = v2.AffineTransform,
    GrindFootBody = v2.GrindFootBody,
    KnownAirFootplantInput = v2.KnownAirFootplantInput,
    KnownAirFrame = v2.KnownAirFrame,
    KnownAirModeSettings = v2.KnownAirModeSettings,
    KnownAirOutput = v2.KnownAirOutput,
    KnownAirPrediction = v2.KnownAirPrediction,
    KnownAirReckoningFields = v2.KnownAirReckoningFields,
    KnownAirSettings = v2.KnownAirSettings,
    KnownAirState = v2.KnownAirState,
    KnownAirTrajectory = v2.KnownAirTrajectory,
    KnownAirWipeoutRequest = v2.KnownAirWipeoutRequest,
    KnownAirWipeoutSettings = v2.KnownAirWipeoutSettings,
    RestoreVelocityGeometry = v2.RestoreVelocityGeometry,
    Vector4 = v2.Vector4,
    enter = v3.enter,
    exit = v3.exit,
    fill_physics_output = v4.fill_physics_output,
    check_upside_down_falling_wipeout = v5.check_upside_down_falling_wipeout,
    update_post_physics = v5.update_post_physics,
    KnownAirMath = v6.KnownAirMath,
    KnownAirRuntime = v6.KnownAirRuntime,
    init_trajectory_info = v7.init_trajectory_info,
    restore_velocity = v7.restore_velocity,
    update_trajectory_follow = v7.update_trajectory_follow,
    update = v8.update
}
