--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/mod.rs (коммит 2e16697)
--
-- TU3 trajectory selection82D67848/82D682E8/82D68800.
-- Host world storage and batch ownership are independent of console layout.
-- ROBLOX: pub use -> поля таблицы модуля; приватные модули (launch, math,
-- scoring) тоже доступны как поля, чтобы их можно было сверять с Rust.

local launch = require("@self/launch")
local grind_surface = require("@self/grind_surface")
local grind = require("@self/grind")
local math_ = require("@self/math")
local prediction = require("@self/prediction")
local query = require("@self/query")
local scoring = require("@self/scoring")
local selector = require("@self/selector")
local types = require("@self/types")

local trajectory = {}

trajectory.launch = launch
trajectory.grind_surface = grind_surface
trajectory.grind = grind
trajectory.math = math_
trajectory.prediction = prediction
trajectory.query = query
trajectory.scoring = scoring
trajectory.selector = selector
trajectory.types = types

trajectory.Prediction = prediction.Prediction
trajectory.QueryRequest = prediction.QueryRequest
trajectory.QueryResult = prediction.QueryResult
trajectory.Trajectory = prediction.Trajectory
trajectory.query_trajectory = query.query_trajectory
trajectory.TrajectorySelector = selector.TrajectorySelector
trajectory.WorldWithoutGrindEdges = selector.WorldWithoutGrindEdges
trajectory.LaunchInfo = types.LaunchInfo

export type Prediction = prediction.Prediction
export type QueryRequest = prediction.QueryRequest
export type QueryResult = prediction.QueryResult
export type Trajectory = prediction.Trajectory
export type SurfaceHit = query.SurfaceHit
export type Selection = selector.Selection
export type TrajectorySelector = selector.TrajectorySelector
export type LaunchInfo = types.LaunchInfo
export type SelectorInput = types.SelectorInput
export type SelectorSettings = types.SelectorSettings

return trajectory
