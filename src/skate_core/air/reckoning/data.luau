--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/reckoning/data.rs (коммит 2e16697)
--
-- Additional persistent Reckoning fields and actual inputs for82D8DBD8.

local sar = require("../../physics/skeleton_animation_record")
local point_graph = require("../../point_graph")
local body_flip = require("../body_flip")
local body_spin = require("../body_spin")

local data = {}

export type AirState = {
	-- 1568/1572, shared with Ground entry and PhysicsAir exit.
	spin_angle: number,
	spin_speed: number,
	-- 1580 is cleared by UpdateAirStates (1576 lives in ReckoningFrames).
	secondary_lean_angle: number,
	flip_angle: number,
	flip_speed: number,
	flip_requested_speed: number,
	-- 1072; final combined1008 has one owner, ReckoningFrames.body_flip.
	spin_transform: sar.AnimationPartTransform,
	-- 1232 and1596; their native trajectory/entry producers remain the caller.
	flip_axis: { number },
	flip_active: boolean,
	-- 1597, BeginBodyFlip82D8EC60 and ResetBodyFlip82D8EAA4.
	flip_side: boolean,
}

local AirState = {}
data.AirState = AirState

-- 82D33178: scalar zeros, identity1072, world-X axis and inactive flip.
function AirState.new(): AirState
	return {
		spin_angle = 0.0,
		spin_speed = 0.0,
		secondary_lean_angle = 0.0,
		flip_angle = 0.0,
		flip_speed = 0.0,
		flip_requested_speed = 0.0,
		spin_transform = sar.IDENTITY(),
		flip_axis = { 1.0, 0.0, 0.0, 0.0 },
		flip_active = false,
		flip_side = false,
	}
end

-- Ground entry82D37538/PhysicsAir exit82D346A0 reset exactly this pair.
function AirState.reset_spin(self: AirState)
	self.spin_angle = 0.0
	self.spin_speed = 0.0
end

-- ROBLOX: #[derive(Clone)].
function AirState.clone(self: AirState): AirState
	local c = table.clone(self)
	c.spin_transform = sar.copy_transform(self.spin_transform)
	c.flip_axis = table.clone(self.flip_axis)
	return c
end

export type Settings = {
	ground_normal_smoothing: { number },
	-- PointNegGraphData8 layout336; caller directly evaluates its X/Y352/384.
	max_up_angle_delta: point_graph.PointGraph,
	tilt_vs_rotation: point_graph.PointGraph,
	tilt_vs_slope: point_graph.PointGraph,
	body_spin: body_spin.BodySpinSettings,
	body_flip: body_flip.BodyFlipSettings,
}

export type Input = {
	landing_normal: { number },
	normal_blend: number,
	target_spin: number,
	flip_request: number,
	-- Processed752, from the actual Skeleton animation COM-to-deck producer.
	com_to_deck: { number },
	timestep: number,
	-- Processed2812, live PhysBodySpin animation attribute.
	physical_body_spin: number,
	-- Processed2644, produced by Skeleton82BDD008; used only when2484bit15 is set.
	grind_adjusted_body_spin: number,
	additive_spin: boolean,
	direct_spin: boolean,
	reverse_stance: boolean,
	-- Actual selected physics_mode layout108 and28.
	easy_body_spins: boolean,
	perfect_body_flips: boolean,
}

return data
