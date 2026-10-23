--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/manual/settings.rs (коммит 2e16697)
--
-- physics_manual stock layout at global830CFDA4+200, wrapper+4.

local point_graph = require("../../point_graph")

local settings = {}

export type ManualGains = { proportional: number, integral: number, derivative: number }

export type ManualSettings = {
	-- NoiseVsSpeed has a 16-byte header; X/Y arrays start at +96/+128.
	noise_vs_speed: point_graph.PointGraph,
	-- +160 TorqueScalarWithNoContact; applies to emitted displacement, not state.
	torque_scale_without_contact: number,
	-- +164 TorqueBleedOffWithNoContact, +172 StartTorqueScalar.
	torque_bleed_without_contact: number,
	start_torque_scale: number,
	-- +184 ProceduralNoiseScalar, +188 ProceduralNoiseFreq.
	procedural_noise_scale: number,
	procedural_noise_frequency: number,
	-- +200/204/208 PowerScalar_P/I/D; +232/236/240 ManualScalar_P/I/D.
	powerslide: ManualGains,
	manual: ManualGains,
	-- +216 MaxTiltAngle (degrees); +224 MaxAngleDiff (native radians).
	maximum_tilt_degrees: number,
	maximum_angle_error: number,
	-- +244 D_Scalar_Limit, +248 BrakeTiltAngle (degrees), +252 AnimationNoiseScalar.
	derivative_limit: number,
	brake_tilt_degrees: number,
	animation_noise_scale: number,
}

export type ManualMode = {
	-- physics_mode+32 Hash_84CB2F459F3FC811, compared to abs(local ground
	-- velocity Z). Legacy Rust field name; the source reads Processed416,
	-- not the angular velocity at720. Original stock name remains unresolved.
	correction_angular_speed_threshold: number,
	-- physics_mode+36 Hash_F8CBC0F5FEF2240E, read as a byte.
	corrective_force_enabled: boolean,
}

return settings
