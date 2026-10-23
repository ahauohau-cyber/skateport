--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/state/mod.rs (коммит 2e16697)
--
-- Readable TU3 `PhysState_PhysicsAir` lifecycle and update composition.
--
-- The state owns the recovered branch/order semantics. Calls into the board,
-- skeleton, trajectory selector, wipeout controller, and unresolved Xenon
-- vector math remain mandatory runtime interfaces with no fallback.

local board = require("@self/board")
local data = require("@self/data")
local jump_velocity = require("@self/jump_velocity")
local lifecycle = require("@self/lifecycle")
local m = require("@self/math")
local post_physics = require("@self/post_physics")
local runtime = require("@self/runtime")
local update = require("@self/update")

local state = {}

state.update_skateboard = board.update_skateboard
state.AirBoardForce = data.AirBoardForce
state.PhysicsAirState = data.PhysicsAirState
export type AirBoardForce = data.AirBoardForce
export type AirTrajectory = data.AirTrajectory
export type PhysicsAirFrame = data.PhysicsAirFrame
export type PhysicsAirOutput = data.PhysicsAirOutput
export type PhysicsAirReckoningFields = data.PhysicsAirReckoningFields
export type PhysicsAirSettings = data.PhysicsAirSettings
export type PhysicsAirState = data.PhysicsAirState
export type PhysicsAirMath = jump_velocity.PhysicsAirMath
state.calculate_velocity_from_jump = jump_velocity.calculate_velocity_from_jump
state.AirMath = m.AirMath
state.angle_between_vectors = m.angle_between_vectors
state.clamp_jump_velocity = m.clamp_jump_velocity
state.enter = lifecycle.enter
state.exit = lifecycle.exit
state.fill_physics_output = lifecycle.fill_physics_output
state.update_post_physics = post_physics.update_post_physics
export type PhysicsAirLaunchInfo = runtime.PhysicsAirLaunchInfo
export type PhysicsAirRuntime = runtime.PhysicsAirRuntime
state.integrate_trajectory_fixed_step = update.integrate_trajectory_fixed_step
state.update = update.update
state.wrap_signed_angle = update.wrap_signed_angle

return state
