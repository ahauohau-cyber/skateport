-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    AirOutputFields = {}
}

function t1.AirOutputFields.default() -- line: 13
    -- upvalues: rt (copy)
    return {
        trajectory_apex_0 = table.create(4, 0),
        collision_position_16 = table.create(4, 0),
        landing_normal_32 = table.create(4, 0),
        selector_vector_48 = table.create(4, 0),
        trajectory_position_64 = table.create(4, 0),
        landing_heading_80 = table.create(4, 0),
        selector_com_position_96 = table.create(4, 0),
        jump_velocity_delta_112 = table.create(4, 0),
        launch_velocity_128 = table.create(4, 0),
        time_in_state_176 = 0,
        collision_time_180 = 0,
        collision_normal_speed_188 = 0,
        time_to_apex_196 = 0,
        trajectory_index_220 = 0,
        selected_trajectory_240 = rt.filled(4, table.create(4, 0)),
        trajectory_plane_samples_336 = table.create(25, 0),
        known_air_valid_437 = 0,
        launched_442 = 0,
        flag_443 = 0,
        flag_444 = 0,
        handplant_flags_324 = 0,
        handplant_position_304 = table.create(4, 0),
        handplant_time_320 = 0,
        vector_160 = table.create(4, 0),
        scalar_184 = 0,
        landing_normal_144 = table.create(4, 0),
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
        use_air_reckoning_452 = 0
    }
end

return t1
