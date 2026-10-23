--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/known/mod.rs (коммит 2e16697)
--
-- Readable TU3 `PhysState_KnownAir` (state 201).
--
-- The routines in this module preserve the observed Skate 3 call, branch,
-- field, and constant order. Engine-owned objects and Xenon-specific vector
-- operations are mandatory adapter contracts; this module supplies no
-- guessed fallbacks.

local body = require("@self/body")
local data = require("@self/data")
local footplant = require("@self/footplant")
local lifecycle = require("@self/lifecycle")
local output = require("@self/output")
local post_physics = require("@self/post_physics")
local runtime = require("@self/runtime")
local trajectory = require("@self/trajectory")
local update = require("@self/update")

local known = {}

known.calculate_body_flip_speed = body.calculate_body_flip_speed
known.calculate_body_spin_speed = body.calculate_body_spin_speed
export type AffineTransform = data.AffineTransform
export type GrindFootBody = data.GrindFootBody
export type KnownAirFootplantInput = data.KnownAirFootplantInput
export type KnownAirFrame = data.KnownAirFrame
export type KnownAirModeSettings = data.KnownAirModeSettings
export type KnownAirOutput = data.KnownAirOutput
export type KnownAirPrediction = data.KnownAirPrediction
export type KnownAirReckoningFields = data.KnownAirReckoningFields
export type KnownAirSettings = data.KnownAirSettings
export type KnownAirState = data.KnownAirState
export type KnownAirTrajectory = data.KnownAirTrajectory
export type KnownAirWipeoutRequest = data.KnownAirWipeoutRequest
export type KnownAirWipeoutSettings = data.KnownAirWipeoutSettings
export type RestoreVelocityGeometry = data.RestoreVelocityGeometry
export type Vector4 = data.Vector4
known.enter = lifecycle.enter
known.exit = lifecycle.exit
known.fill_physics_output = output.fill_physics_output
known.check_upside_down_falling_wipeout = post_physics.check_upside_down_falling_wipeout
known.update_post_physics = post_physics.update_post_physics
export type KnownAirMath = runtime.KnownAirMath
export type KnownAirRuntime = runtime.KnownAirRuntime
known.init_trajectory_info = trajectory.init_trajectory_info
known.restore_velocity = trajectory.restore_velocity
known.update_trajectory_follow = trajectory.update_trajectory_follow
known.update = update.update
-- ROBLOX: pub(crate) — для тестов.
known.footplant = footplant
known.trajectory = trajectory

return known
