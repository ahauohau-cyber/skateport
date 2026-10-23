--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout/mod.rs (коммит 2e16697)
--
-- Original TU3 shared Wipeout request calculation and persistent history.
-- Physical bail/recovery state response is scheduled by the game coordinator.

local air = require("@self/air")
local common = require("@self/common")
local data = require("@self/data")
local ground = require("@self/ground")
local requests = require("@self/requests")

local wipeout = {}

wipeout.check_air = air.check
wipeout.check_air_collision = air.check_collision
export type AirSettings = data.AirSettings
export type Frame = data.Frame
export type GroundSettings = data.GroundSettings
export type Mode = data.Mode
export type RequestInput = data.RequestInput
export type Settings = data.Settings
export type V = data.V
wipeout.check_ground = ground.check
wipeout.check_ground_animation = ground.check_animation
wipeout.check_plant = ground.check_plant
wipeout.Requests = requests.Requests
export type Requests = requests.Requests
-- pub(crate) use common::force as regional_force
wipeout.regional_force = common.force

return wipeout
