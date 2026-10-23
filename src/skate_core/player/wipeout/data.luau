--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout/data.rs (коммит 2e16697)
--
-- Actual observation values consumed by Wipeout82D8F9E0/82D90358.
-- ROBLOX: V = [f32; 4] -> таблица из 4 чисел; массивы с нуля -> [i + 1].

local sar = require("../../physics/skeleton_animation_record")
local point_graph = require("../../point_graph")

type Transform = sar.AnimationPartTransform

local data = {}

export type V = { number }

export type Frame = {
	flags_2468: number,
	flags_2472: number,
	flags_2476: number,
	flags_2480: number,
	flags_2484: number,
	category: number,
	timestep: number,
	time_on_ground: number,
	speed: number,
	animation_up: V,
	landing_angle: number,
	deck_velocity: V,
	com_velocity: V,
	jump_fix_frames: number,
	-- Actual solver deck pose and the retained Processed0/16/32 basis.
	deck: Transform,
	input_board: Transform,
	world_to_animation: Transform,
	closing_velocity: V,
	board_material_flags: number,
	board_contact: boolean,
	wheel_contact: boolean,
	board_contact_normal: V,
	opposing_contact: number,
	regions_force: { number }, -- [f32; 8]
	maximum_skater_force: number,
	vehicle_force: number,
	group_8: boolean,
	conflicting: boolean,
	compliant: boolean,
	highest_normal: V,
	pose_error: V,
	maximum_pose_error: number,
	flip_active: boolean,
	flip_requested_speed: number,
	system_up_y: number,
	grind_selected: boolean,
	grind_normal_valid: boolean,
	grind_normal: V,
}

export type Mode = {
	check_squash: boolean,
	check_bad_landing: boolean,
	ground_xz: number,
	bad_landing_scale: number,
}

export type GroundSettings = {
	vehicle_scalar: number,
	vehicle_contact: number,
	skitch_contact: number,
	skitch_scalar: number,
	skitch_arms_scalar: number,
	skater_scalar: number,
	max_squash: number,
	max_squash_coffin: number,
	max_displacement: number,
	max_contact: number,
	max_arm_contact: number,
	max_deck_error: number,
	opposing_contact: number,
	y_acceleration: number,
	light_dmo_scalar: number,
	player_scalar: number,
	ai_scalar: number,
	skitch_acc_scalar: number,
	balance_total: number,
	balance_min_speed: number,
	balance_base: number,
}

export type AirSettings = {
	xz_trick: number,
	y_trick: number,
	xz_acceleration: number,
	y_acceleration: number,
	max_squash: number,
	max_displacement: number,
	max_contact: number,
	max_arm_contact: number,
	body_flip_scalar: number,
	body_flip_acc_scalar: number,
	light_dmo_scalar: number,
	ignore_danger_frames: number,
	max_landing_speed: number,
	max_stairs_speed: number,
	max_grind_speed: number,
	-- Layout0 PointNegGraph; original directly reads X16/Y48.
	max_landing_angle: point_graph.PointGraph,
}

export type Settings = {
	ground: GroundSettings,
	air: AirSettings,
	lean_contact_y: number,
}

export type RequestInput = {
	flags_2468: number,
	flags_2476: number,
	flags_2480: number,
	flags_2484: number,
	animation_up_y: number,
	category: number,
}

return data
