--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/pumping/settings.rs (коммит 2e16697)
--
-- Stock layout bindings consumed by TU3 Pumping Update/Calculate.

local point_graph = require("../../point_graph")

local settings = {}

export type PumpingSettings = {
	-- physics_pumping +16/+48 (the graph's four header floats are skipped).
	pump_vs_speed: point_graph.PointGraph,
	-- +96/+128, also skipping the PointNegGraphData8 header.
	pump_vs_time: point_graph.PointGraph,
	-- +160/+192, +224/+256, +288/+320.
	min_crouch_vs_ground_angle: point_graph.PointGraph,
	compression_vs_ground_angle: point_graph.PointGraph,
	compression_vs_deck_angle: point_graph.PointGraph,
	-- +364 PumpEffectDamping; +372 MinChangeInCOMBeforePumping.
	height_change_damping: number,
	minimum_height_change: number,
	-- +376 MaxDeltaHeightAllowedPerFrame.
	maximum_height_change: number,
	-- +380 CompressionGroundScalar; +384 CompressionDeckScalar.
	ground_compression_scale: number,
	deck_compression_scale: number,
	-- +392 AngularSpeedDamping.
	angular_speed_damping: number,
}

-- Ground 82D37E74 passes ProcessedPhysIn+2548, then Update loads wrapper+4.
-- ProcessInput 82DB4420..446C selects that wrapper from the five player modes.
export type PumpingMode = {
	-- +12 Hash_9D1AEE3D7D8A4A7. Name describes its use, not a recovered name.
	maximum_absorption_per_second: number,
	-- +16 Hash_D77AFD320B6241C5. Multiplied by the pumping timestep.
	maximum_acceleration_per_second: number,
	-- +20 PumpEffectFactorAbsorption; +24 PumpEffectFactor.
	absorption_factor: number,
	acceleration_factor: number,
}

return settings
