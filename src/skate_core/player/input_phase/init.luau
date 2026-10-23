--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/input_phase/mod.rs (коммит 2e16697)
--
-- Skate 3 TU3 `PhysicalPlayerHiLOD::Input` (`0x82DB4048`).
--
-- The phase is split into direct field publication and an ordered runtime.
-- Separate native subsystems remain mandatory service calls; none have a
-- fallback implementation here.
-- ROBLOX: `pub use` -> поля таблицы модуля; `pub use types::*` -> копия полей types.

local publication = require("@self/publication")
local special_surface = require("@self/special_surface")
local motion_math = require("@self/motion_math")
local runtime = require("@self/runtime")
local types = require("@self/types")
local air_output = require("@self/air_output")
local pose_output = require("@self/pose_output")
local requests = require("@self/requests")
local grind_input = require("@self/grind_input")
local grind_output = require("@self/grind_output")

local input_phase = {}

-- Подмодули (в Rust приватные, но нужны тестам).
input_phase.publication = publication
input_phase.special_surface = special_surface
input_phase.motion_math = motion_math
input_phase.runtime = runtime
input_phase.types = types
input_phase.air_output = air_output
input_phase.pose_output = pose_output
input_phase.requests = requests
input_phase.grind_input = grind_input
input_phase.grind_output = grind_output

input_phase.publish_special_surface = special_surface.publish_special_surface

input_phase.InputPhaseError = runtime.InputPhaseError
input_phase.process_input = runtime.process_input
input_phase.start_input = runtime.start_input
input_phase.finish_input = runtime.finish_input

-- ROBLOX: `pub use types::*` — перечисляем явно, чтобы сохранить типы.
input_phase.copy = types.copy
input_phase.ProbeFields = types.ProbeFields
input_phase.LineTestFields = types.LineTestFields
input_phase.StateVariantFields = types.StateVariantFields
input_phase.CurrentStateFields = types.CurrentStateFields
input_phase.SkateboardMotionFields = types.SkateboardMotionFields
input_phase.SystemReckoningFields = types.SystemReckoningFields
input_phase.GroundOutputFields = types.GroundOutputFields
input_phase.CollisionOutputFields = types.CollisionOutputFields
input_phase.PhysicsOutputFields = types.PhysicsOutputFields
input_phase.OffBoardOutputFields = types.OffBoardOutputFields
input_phase.PhysicalPlayerInput = types.PhysicalPlayerInput
input_phase.PlayerInputState = types.PlayerInputState
input_phase.ProcessedPhysicsInput = types.ProcessedPhysicsInput
input_phase.ProcessedPhysicsSnapshot = types.ProcessedPhysicsSnapshot
input_phase.empty_external_physics = types.empty_external_physics
input_phase.AirOutputFields = air_output.AirOutputFields
input_phase.AnimationOutputFields = pose_output.AnimationOutputFields
input_phase.ScoringOutputFields = pose_output.ScoringOutputFields
input_phase.SkeletonOutputFields = pose_output.SkeletonOutputFields
input_phase.GrindInvestigationFields = grind_input.GrindInvestigationFields
input_phase.GrindOutputFields = grind_output.GrindOutputFields

export type RawVector = types.RawVector
export type RawMatrix = types.RawMatrix
export type ProbeFields = types.ProbeFields
export type LineTestFields = types.LineTestFields
export type StateVariantFields = types.StateVariantFields
export type CurrentStateFields = types.CurrentStateFields
export type SkateboardMotionFields = types.SkateboardMotionFields
export type SystemReckoningFields = types.SystemReckoningFields
export type GroundOutputFields = types.GroundOutputFields
export type CollisionOutputFields = types.CollisionOutputFields
export type PhysicsOutputFields = types.PhysicsOutputFields
export type OffBoardOutputFields = types.OffBoardOutputFields
export type PhysicalPlayerInput = types.PhysicalPlayerInput
export type AnimationInputPacket = types.AnimationInputPacket
export type NativeReferenceBase = types.NativeReferenceBase
export type NativeRelativeReference = types.NativeRelativeReference
export type PlayerInputState = types.PlayerInputState
export type ProcessedPhysicsInput = types.ProcessedPhysicsInput
export type ProcessedPhysicsSnapshot = types.ProcessedPhysicsSnapshot
export type AirOutputFields = air_output.AirOutputFields
export type SkeletonOutputFields = pose_output.SkeletonOutputFields
export type AnimationOutputFields = pose_output.AnimationOutputFields
export type ScoringOutputFields = pose_output.ScoringOutputFields
export type GrindInvestigationFields = grind_input.GrindInvestigationFields
export type GrindOutputFields = grind_output.GrindOutputFields
export type GroundHistoryRequest = requests.GroundHistoryRequest
export type GroundHistoryResult = requests.GroundHistoryResult
export type PrepareJumpRequest = requests.PrepareJumpRequest
export type InputPhaseServices = runtime.InputPhaseServices
export type InputPhaseError = runtime.InputPhaseError
export type InputContinuation = runtime.InputContinuation

return input_phase
