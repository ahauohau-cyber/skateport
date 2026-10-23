--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/ground_jump/types.rs (коммит 2e16697)

local point_graph = require("../../point_graph")

type PointGraph = point_graph.PointGraph

local types = {}

export type GroundJump = {
	velocity: { number }, -- JumpInfo0, metres/second
	scalar_16: number, -- 82D93618 initializes and retains zero
	active: boolean, -- JumpInfo20
}

local GroundJump = {}
types.GroundJump = GroundJump

-- ROBLOX: #[derive(Default)].
function GroundJump.default(): GroundJump
	return { velocity = { 0.0, 0.0, 0.0, 0.0 }, scalar_16 = 0.0, active = false }
end

export type GroundJumpMode = {
	minimum_height_64: number, -- physics_mode Hash_BE3F74F978D777E5, metres
	minimum_height_68: number, -- JumpMinHeight, metres
	maximum_height: number, -- JumpMaxHeight72, metres
}

export type GroundJumpSettings = {
	vertical_response: PointGraph, -- PointGraph<16>, physics_jump0
	y_scalar_vs_normal_y: PointGraph, -- 128
	speed_scalar_vs_angle: PointGraph, -- 208
	minimum_height_vs_speed: PointGraph, -- 288
	maximum_height_vs_speed: PointGraph, -- 352
	speed_response_max_speed: number, -- 420, metres/second
	minimum_scalar: number, -- 424
	maximum_y_bonus: number, -- 428, metres/second
	adjust_z_factor: number, -- 432
	adjust_x_factor: number, -- 436
	absolute_minimum_height: number, -- 456, metres
	-- physics_jump.HippyJumpMinHeight/MaxHeight. These are separate from
	-- the ordinary jump-mode bounds in the stock data.
	hippy_minimum_height: number,
	hippy_maximum_height: number,
}

export type GroundJumpInput = {
	flags_2468: number,
	flags_2480: number,
	flags_2484: number,
	flags_2488: number,
	effective_forward: { number }, -- Processed160
	forward: { number }, -- 352
	current_velocity: { number }, -- 400 metres/second
	ground_reference_position: { number }, -- 480 metres
	reference_up: { number }, -- 544
	filtered_ground_normal: { number }, -- 576, BoardToolkit normal192
	animation_com_position: { number }, -- 592 metres
	prepared_velocity: { number }, -- 704 metres/second
	jump_strength: number, -- 2624, animation output
	jump_controls: { number }, -- 2628/2632, animation output
	gravity_y: number, -- 2648 metres/second squared
	surface_speed: number, -- 2656 metres/second
}

return types
