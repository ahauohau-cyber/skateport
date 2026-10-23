--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/input_phase/air_output.rs (коммит 2e16697)
--
-- Completed Air publication shared by physical state and graph consumers.
-- ROBLOX: RawVector ([u32; 4]) -> таблица из 4 слов; u8 -> число 0..255.

local air_output = {}

export type RawVector = { number }

export type AirOutputFields = {
	-- KnownAir Fill82D36880, retained template values outside states that write them.
	trajectory_apex_0: RawVector,
	collision_position_16: RawVector,
	landing_normal_32: RawVector,
	selector_vector_48: RawVector,
	trajectory_position_64: RawVector,
	landing_heading_80: RawVector,
	selector_com_position_96: RawVector,
	jump_velocity_delta_112: RawVector,
	launch_velocity_128: RawVector,
	time_in_state_176: number,
	collision_time_180: number,
	collision_normal_speed_188: number,
	time_to_apex_196: number,
	trajectory_index_220: number,
	-- ProcessOutput82DB7040: TrajectorySelector+9640.
	surface_category_232: number,
	selected_trajectory_240: { RawVector },
	trajectory_plane_samples_336: { number },
	known_air_valid_437: number,
	launched_442: number,
	-- Common ProcessOutput82DB703C: TrajectorySelector9653.
	flag_443: number,
	flag_444: number,
	-- Air324 high bits used by IsHandPlanting82BA55A8.
	handplant_flags_324: number,
	handplant_position_304: RawVector,
	handplant_time_320: number,
	vector_160: RawVector,
	scalar_184: number,
	landing_normal_144: RawVector,
	jump_height_200: number,
	-- FootPlantManager::Fill82D71040: predicted contact and ground-plant duration.
	footplant_contact_time_208: number,
	footplant_duration_212: number,
	footplant_surface_height_216: number,
	footplant_surface_224: number,
	footplant_left_449: number,
	footplant_right_450: number,
	reached_apex_436: number,
	flag_441: number,
	-- Reckoning +1597, published by Skate 3 82DB70D0.
	flag_445: number,
	flag_446: number,
	flag_447: number,
	flag_448: number,
	use_air_reckoning_452: number,
}

local function z4(): RawVector
	return { 0, 0, 0, 0 }
end

local AirOutputFields = {}
air_output.AirOutputFields = AirOutputFields

-- ROBLOX: #[derive(Default)] -> конструктор с нулями.
function AirOutputFields.default(): AirOutputFields
	return {
		trajectory_apex_0 = z4(),
		collision_position_16 = z4(),
		landing_normal_32 = z4(),
		selector_vector_48 = z4(),
		trajectory_position_64 = z4(),
		landing_heading_80 = z4(),
		selector_com_position_96 = z4(),
		jump_velocity_delta_112 = z4(),
		launch_velocity_128 = z4(),
		time_in_state_176 = 0,
		collision_time_180 = 0,
		collision_normal_speed_188 = 0,
		time_to_apex_196 = 0,
		trajectory_index_220 = 0,
		surface_category_232 = 0,
		selected_trajectory_240 = { z4(), z4(), z4(), z4() },
		trajectory_plane_samples_336 = table.create(25, 0),
		known_air_valid_437 = 0,
		launched_442 = 0,
		flag_443 = 0,
		flag_444 = 0,
		handplant_flags_324 = 0,
		handplant_position_304 = z4(),
		handplant_time_320 = 0,
		vector_160 = z4(),
		scalar_184 = 0,
		landing_normal_144 = z4(),
		jump_height_200 = 0,
		footplant_contact_time_208 = 0,
		footplant_duration_212 = 0,
		footplant_surface_height_216 = 0,
		footplant_surface_224 = 0,
		footplant_left_449 = 0,
		footplant_right_450 = 0,
		reached_apex_436 = 0,
		flag_441 = 0,
		flag_445 = 0,
		flag_446 = 0,
		flag_447 = 0,
		flag_448 = 0,
		use_air_reckoning_452 = 0,
	}
end

return air_output
