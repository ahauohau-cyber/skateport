-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/player/input_phase")
local PhysicalPlayerInput = v1.PhysicalPlayerInput
local t1 = {
    UP = { 0, 1065353216, 0, 0 }
}

function t1.reset_outputs(p1) -- line: 26
    -- upvalues: rt (copy), PhysicalPlayerInput (copy), t1 (copy)
    local surface_default_mode, component_1832_word_1876 = p1.surface_default_mode, p1.component_1832_word_1876
    local v2 = rt.copy(p1.skeleton.anim_to_world_11920)
    local v3 = bit32.band(p1.air.handplant_flags_324, 1342177279)
    local v4 = PhysicalPlayerInput.default()

    v4.air.handplant_flags_324 = v3
    v4.air.landing_normal_144 = rt.copy(t1.UP)
    v4.air.selected_trajectory_240 = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 3212836864, 3212836864, 3212836864, 3212836864 }
    }
    v4.reckoning.vector_96 = rt.copy(t1.UP)
    v4.ground.vector_64 = rt.copy(t1.UP)
    v4.ground.vector_80 = rt.copy(t1.UP)
    v4.ground.vector_96 = rt.copy(t1.UP)
    v4.ground.scalar_276 = -1
    v4.grinds.words_136_140 = { 4294967295, 0 }
    v4.skeleton.anim_to_world_11920 = v2
    v4.surface_default_mode = surface_default_mode
    v4.component_1832_word_1876 = component_1832_word_1876

    for v5 in p1 do
        if v4[v5] == nil then
            p1[v5] = nil
        end
    end

    for v6, v7 in v4 do
        p1[v6] = v7
    end
end

local assign_into, copy_into = v1.assign_into, v1.copy_into
local copy = rt.copy
local v8

local function build_template() -- line: 114
    -- upvalues: rt (copy), v1 (copy), PhysicalPlayerInput (copy), t1 (copy), v8 (ref)
    local v9 = PhysicalPlayerInput.default()

    v9.air.landing_normal_144 = rt.copy(t1.UP)
    v9.air.selected_trajectory_240 = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 3212836864, 3212836864, 3212836864, 3212836864 }
    }
    v9.reckoning.vector_96 = rt.copy(t1.UP)
    v9.ground.vector_64 = rt.copy(t1.UP)
    v9.ground.vector_80 = rt.copy(t1.UP)
    v9.ground.vector_96 = rt.copy(t1.UP)
    v9.ground.scalar_276 = -1
    v9.grinds.words_136_140 = { 4294967295, 0 }
    v8 = v1.freeze_deep(v9)

    return v8
end

local function is_vector(p2) -- line: 141
    if #p2 ~= 4 then
        return false
    end

    return type(p2[1]) == "number"
end

local function build_plan(p3, p4, p5) -- line: 144
    -- upvalues: build_plan (copy)
    local t2 = {}

    for v11 in p3 do
        table.insert(t2, v11)
    end

    table.sort(t2)

    local t3 = {
        scalar_count = 0,
        scalars = {},
        tables = {},
        vectors = {},
        arrays = {},
        others = {},
        records = {},
        plans = {}
    }

    for _, v12 in t2 do
        local v13 = p3[v12]

        if type(v13) == "table" then
            t3.tables[v12] = true

            if v12 ~= p5 then
                if #v13 == 4 and type(v13[1]) == "number" then
                    table.insert(t3.vectors, v12)
                elseif p4 and #v13 == 0 then
                    table.insert(t3.records, v12)
                    t3.plans[v12] = build_plan(v13, false, if v12 == "skeleton" then "anim_to_world_11920" else nil)
                else
                    local v17 = #v13 > 0
                    local n1 = 0

                    for _, v18 in v13 do
                        n1 += 1

                        if type(v18) ~= "table" or not (#v18 == 4 and type(v18[1]) == "number") then
                            v17 = false
                        end
                    end

                    if v17 and n1 == #v13 then
                        table.insert(t3.arrays, v12)
                    else
                        table.insert(t3.others, v12)
                    end
                end
            end
        else
            t3.scalars[v12] = v13
            t3.scalar_count += 1
        end
    end

    return t3
end

local v21

function t1.template() -- line: 195
    -- upvalues: v8 (ref), build_template (copy)
    return v8 or build_template()
end

local function reset_named(p6, p7, p8) -- line: 200
    -- upvalues: copy_into (copy), copy (copy)
    local v22 = p8[1]

    for v23 in p6 do
        if v22[v23] == nil then
            p6[v23] = nil
        end
    end

    p6.component_1832_word_1876 = 0
    p6.filtered_state_0 = 0
    p6.surface_default_mode = 0

    local landing_normal_144 = p6.board_reckoning_side_176

    if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
        copy_into(p6, "board_reckoning_side_176", p7.board_reckoning_side_176)
    else
        landing_normal_144[1] = 0
        landing_normal_144[2] = 0
        landing_normal_144[3] = 0
        landing_normal_144[4] = 0
    end

    local grinds = p6.air
    local grinds2 = p7.air
    local landing_normal_144_2, v24, v25, v26, v27

    if type(grinds) == "table" then
        v22 = p8[2]

        for v28 in grinds do
            if v22[v28] == nil then
                grinds[v28] = nil
            end
        end

        grinds.collision_normal_speed_188 = 0
        grinds.collision_time_180 = 0
        grinds.flag_441 = 0
        grinds.flag_443 = 0
        grinds.flag_444 = 0
        grinds.flag_445 = 0
        grinds.flag_446 = 0
        grinds.flag_447 = 0
        grinds.flag_448 = 0
        grinds.footplant_contact_time_208 = 0
        grinds.footplant_duration_212 = 0
        grinds.footplant_left_449 = 0
        grinds.footplant_right_450 = 0
        grinds.footplant_surface_224 = 0
        grinds.footplant_surface_height_216 = 0
        grinds.handplant_flags_324 = 0
        grinds.handplant_time_320 = 0
        grinds.jump_height_200 = 0
        grinds.known_air_valid_437 = 0
        grinds.launched_442 = 0
        grinds.reached_apex_436 = 0
        grinds.scalar_184 = 0
        grinds.time_in_state_176 = 0
        grinds.time_to_apex_196 = 0
        grinds.trajectory_index_220 = 0
        grinds.use_air_reckoning_452 = 0
        landing_normal_144 = grinds.collision_position_16

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "collision_position_16", grinds2.collision_position_16)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.handplant_position_304

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "handplant_position_304", grinds2.handplant_position_304)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.jump_velocity_delta_112

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "jump_velocity_delta_112", grinds2.jump_velocity_delta_112)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.landing_heading_80

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "landing_heading_80", grinds2.landing_heading_80)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.landing_normal_144

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "landing_normal_144", grinds2.landing_normal_144)
        else
            landing_normal_144_2 = grinds2.landing_normal_144
            v24 = landing_normal_144_2[1]
            v25 = landing_normal_144_2[2]
            v26 = landing_normal_144_2[3]
            v27 = landing_normal_144_2[4]
            landing_normal_144[1] = v24
            landing_normal_144[2] = v25
            landing_normal_144[3] = v26
            landing_normal_144[4] = v27
        end

        landing_normal_144 = grinds.landing_normal_32

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "landing_normal_32", grinds2.landing_normal_32)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.launch_velocity_128

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "launch_velocity_128", grinds2.launch_velocity_128)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.selected_trajectory_240
        landing_normal_144_2 = grinds2.selected_trajectory_240

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "selected_trajectory_240", landing_normal_144_2)
        else
            copy_into(landing_normal_144, 1, landing_normal_144_2[1])
            copy_into(landing_normal_144, 2, landing_normal_144_2[2])
            copy_into(landing_normal_144, 3, landing_normal_144_2[3])
            copy_into(landing_normal_144, 4, landing_normal_144_2[4])
        end

        landing_normal_144 = grinds.selector_com_position_96

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "selector_com_position_96", grinds2.selector_com_position_96)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.selector_vector_48

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "selector_vector_48", grinds2.selector_vector_48)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.trajectory_apex_0

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "trajectory_apex_0", grinds2.trajectory_apex_0)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.trajectory_plane_samples_336

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 25 then
            copy_into(grinds, "trajectory_plane_samples_336", grinds2.trajectory_plane_samples_336)
        else
            table.move(grinds2.trajectory_plane_samples_336, 1, 25, 1, landing_normal_144)
        end

        landing_normal_144 = grinds.trajectory_position_64

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "trajectory_position_64", grinds2.trajectory_position_64)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_160

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_160", grinds2.vector_160)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end
    else
        p6.air = copy(grinds2)
    end

    grinds = p6.animation
    grinds2 = p7.animation

    if type(grinds) == "table" then
        v22 = p8[3]

        for v29 in grinds do
            if v22[v29] == nil then
                grinds[v29] = nil
            end
        end

        grinds.collision_time_144 = grinds2.collision_time_144
        grinds.manual_opposition_168 = 0
        grinds.profile_148 = 0
        grinds.tricks_blocked_on_stairs_166 = 0
    else
        p6.animation = copy(grinds2)
    end

    grinds = p6.collision
    grinds2 = p7.collision

    if type(grinds) == "table" then
        v22 = p8[4]

        for v30 in grinds do
            if v22[v30] == nil then
                grinds[v30] = nil
            end
        end

        grinds.flag_215 = 0
        grinds.flag_216 = 0
        grinds.flag_3472 = 0
        grinds.flag_3475 = 0
        grinds.flag_3477 = 0
        grinds.flag_3478 = 0
        grinds.flag_3479 = 0
        grinds.flag_3480 = 0
        grinds.flag_3481 = 0
        grinds.flag_3482 = 0
        grinds.flag_3483 = 0
        grinds.scalar_28 = 0
        grinds.wheel_count_0 = 0
        landing_normal_144 = grinds.predicted_position_64

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "predicted_position_64", grinds2.predicted_position_64)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_48

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_48", grinds2.vector_48)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.wheel_contact_3296_3299

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "wheel_contact_3296_3299", grinds2.wheel_contact_3296_3299)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end
    else
        p6.collision = copy(grinds2)
    end

    grinds = p6.grinds
    grinds2 = p7.grinds

    if type(grinds) == "table" then
        v22 = p8[5]

        for v31 in grinds do
            if v22[v31] == nil then
                grinds[v31] = nil
            end
        end

        grinds.animation_id_144 = 0
        grinds.audio_surface_216 = 0
        grinds.crouch_132 = 0
        grinds.curb_321 = 0
        grinds.dropping_in_324 = 0
        grinds.flag_318 = 0
        grinds.flag_319 = 0
        grinds.flag_322 = 0
        grinds.flag_323 = 0
        grinds.grinding_316 = 0
        grinds.impact_speed_128 = 0
        grinds.is_ledge_320 = 0
        grinds.leaving_317 = 0
        grinds.scorable_id_152 = grinds2.scorable_id_152
        grinds.scoring_id_148 = 0
        grinds.tipslide_325 = 0
        grinds.tipslide_326 = 0
        grinds.trick_out_240 = 0
        landing_normal_144 = grinds.across_48

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "across_48", grinds2.across_48)
        else
            landing_normal_144_2 = grinds2.across_48
            v24 = landing_normal_144_2[1]
            v25 = landing_normal_144_2[2]
            v26 = landing_normal_144_2[3]
            v27 = landing_normal_144_2[4]
            landing_normal_144[1] = v24
            landing_normal_144[2] = v25
            landing_normal_144[3] = v26
            landing_normal_144[4] = v27
        end

        landing_normal_144 = grinds.animation_chromosome_268

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 6 then
            copy_into(grinds, "animation_chromosome_268", grinds2.animation_chromosome_268)
        else
            table.move(grinds2.animation_chromosome_268, 1, 6, 1, landing_normal_144)
        end

        copy_into(grinds, "animation_name_156", grinds2.animation_name_156)
        landing_normal_144 = grinds.camera_target_96

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "camera_target_96", grinds2.camera_target_96)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.direction_0

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "direction_0", grinds2.direction_0)
        else
            landing_normal_144_2 = grinds2.direction_0
            v24 = landing_normal_144_2[1]
            v25 = landing_normal_144_2[2]
            v26 = landing_normal_144_2[3]
            v27 = landing_normal_144_2[4]
            landing_normal_144[1] = v24
            landing_normal_144[2] = v25
            landing_normal_144[3] = v26
            landing_normal_144[4] = v27
        end

        landing_normal_144 = grinds.high_side_112

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "high_side_112", grinds2.high_side_112)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.normal_32

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "normal_32", grinds2.normal_32)
        else
            landing_normal_144_2 = grinds2.normal_32
            v24 = landing_normal_144_2[1]
            v25 = landing_normal_144_2[2]
            v26 = landing_normal_144_2[3]
            v27 = landing_normal_144_2[4]
            landing_normal_144[1] = v24
            landing_normal_144[2] = v25
            landing_normal_144[3] = v26
            landing_normal_144[4] = v27
        end

        landing_normal_144 = grinds.point_16

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "point_16", grinds2.point_16)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.primitive_end_80

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "primitive_end_80", grinds2.primitive_end_80)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.primitive_start_64

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "primitive_start_64", grinds2.primitive_start_64)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.scoring_chromosome_292

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 6 then
            copy_into(grinds, "scoring_chromosome_292", grinds2.scoring_chromosome_292)
        else
            table.move(grinds2.scoring_chromosome_292, 1, 6, 1, landing_normal_144)
        end

        copy_into(grinds, "scoring_name_176", grinds2.scoring_name_176)
        copy_into(grinds, "spline_guids_224_232", grinds2.spline_guids_224_232)
        landing_normal_144 = grinds.volatile_chromosome_244

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 6 then
            copy_into(grinds, "volatile_chromosome_244", grinds2.volatile_chromosome_244)
        else
            table.move(grinds2.volatile_chromosome_244, 1, 6, 1, landing_normal_144)
        end

        landing_normal_144 = grinds.words_136_140

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 2 then
            copy_into(grinds, "words_136_140", grinds2.words_136_140)
        else
            table.move(grinds2.words_136_140, 1, 2, 1, landing_normal_144)
        end
    else
        p6.grinds = copy(grinds2)
    end

    grinds = p6.ground
    grinds2 = p7.ground

    if type(grinds) == "table" then
        v22 = p8[6]

        for v32 in grinds do
            if v22[v32] == nil then
                grinds[v32] = nil
            end
        end

        grinds.flag_273 = 0
        grinds.flag_317 = 0
        grinds.flag_318 = 0
        grinds.hippy_jumping_322 = 0
        grinds.hippy_takeoff_323 = 0
        grinds.landing_half_turns_312 = 0
        grinds.scalar_276 = grinds2.scalar_276
        grinds.scalar_292 = 0
        grinds.scalar_296 = 0
        landing_normal_144 = grinds.vector_128

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_128", grinds2.vector_128)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_64

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_64", grinds2.vector_64)
        else
            landing_normal_144_2 = grinds2.vector_64
            v24 = landing_normal_144_2[1]
            v25 = landing_normal_144_2[2]
            v26 = landing_normal_144_2[3]
            v27 = landing_normal_144_2[4]
            landing_normal_144[1] = v24
            landing_normal_144[2] = v25
            landing_normal_144[3] = v26
            landing_normal_144[4] = v27
        end

        landing_normal_144 = grinds.vector_80

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_80", grinds2.vector_80)
        else
            landing_normal_144_2 = grinds2.vector_80
            v24 = landing_normal_144_2[1]
            v25 = landing_normal_144_2[2]
            v26 = landing_normal_144_2[3]
            v27 = landing_normal_144_2[4]
            landing_normal_144[1] = v24
            landing_normal_144[2] = v25
            landing_normal_144[3] = v26
            landing_normal_144[4] = v27
        end

        landing_normal_144 = grinds.vector_96

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_96", grinds2.vector_96)
        else
            landing_normal_144_2 = grinds2.vector_96
            v24 = landing_normal_144_2[1]
            v25 = landing_normal_144_2[2]
            v26 = landing_normal_144_2[3]
            v27 = landing_normal_144_2[4]
            landing_normal_144[1] = v24
            landing_normal_144[2] = v25
            landing_normal_144[3] = v26
            landing_normal_144[4] = v27
        end
    else
        p6.ground = copy(grinds2)
    end

    grinds = p6.off_board
    grinds2 = p7.off_board

    if type(grinds) == "table" then
        v22 = p8[7]

        for v33 in grinds do
            if v22[v33] == nil then
                grinds[v33] = nil
            end
        end

        grinds.angle_36 = 0
        grinds.angle_40 = 0
        grinds.cadence_phase_80 = 0
        grinds.distance_116 = 0
        grinds.dropping_board_322 = 0
        grinds.flag_304 = 0
        grinds.flag_308 = 0
        grinds.flag_311 = 0
        grinds.flag_314 = 0
        grinds.flag_315 = 0
        grinds.flag_316 = 0
        grinds.flag_318 = 0
        grinds.flag_319 = 0
        grinds.flag_320 = 0
        grinds.flag_324 = 0
        grinds.flag_328 = 0
        grinds.flag_329 = 0
        grinds.flag_330 = 0
        grinds.flag_334 = 0
        grinds.free_board_312 = 0
        grinds.hiding_board_321 = 0
        grinds.hippy_hurdling_317 = 0
        grinds.kind_88 = 0
        grinds.locomotion_state_84 = 0
        grinds.retrieving_board_323 = 0
        grinds.returning_board_313 = 0
        grinds.scalar_112 = 0
        grinds.scalar_148 = 0
        grinds.scalar_152 = 0
        grinds.scalar_156 = 0
        grinds.scalar_32 = 0
        grinds.scalar_92 = 0
        grinds.trajectory_time_120 = 0
        grinds.trajectory_valid_331 = 0
        grinds.word_144 = 0
        landing_normal_144 = grinds.flags_306_307

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 2 then
            copy_into(grinds, "flags_306_307", grinds2.flags_306_307)
        else
            table.move(grinds2.flags_306_307, 1, 2, 1, landing_normal_144)
        end

        landing_normal_144 = grinds.vector_160

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_160", grinds2.vector_160)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_176

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_176", grinds2.vector_176)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_192

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_192", grinds2.vector_192)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_208

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_208", grinds2.vector_208)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_224

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_224", grinds2.vector_224)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_240

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_240", grinds2.vector_240)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_64

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_64", grinds2.vector_64)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_96

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_96", grinds2.vector_96)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end
    else
        p6.off_board = copy(grinds2)
    end

    grinds = p6.physics
    grinds2 = p7.physics

    if type(grinds) == "table" then
        v22 = p8[8]

        for v34 in grinds do
            if v22[v34] == nil then
                grinds[v34] = nil
            end
        end

        grinds.flag_32 = 0
        landing_normal_144 = grinds.vector_16

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_16", grinds2.vector_16)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end
    else
        p6.physics = copy(grinds2)
    end

    grinds = p6.reckoning
    grinds2 = p7.reckoning

    if type(grinds) == "table" then
        v22 = p8[9]

        for v35 in grinds do
            if v22[v35] == nil then
                grinds[v35] = nil
            end
        end

        grinds.flag_164 = 0
        landing_normal_144 = grinds.vector_144

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_144", grinds2.vector_144)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_16

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_16", grinds2.vector_16)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_64

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_64", grinds2.vector_64)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_96

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_96", grinds2.vector_96)
        else
            landing_normal_144_2 = grinds2.vector_96
            v24 = landing_normal_144_2[1]
            v25 = landing_normal_144_2[2]
            v26 = landing_normal_144_2[3]
            v27 = landing_normal_144_2[4]
            landing_normal_144[1] = v24
            landing_normal_144[2] = v25
            landing_normal_144[3] = v26
            landing_normal_144[4] = v27
        end
    else
        p6.reckoning = copy(grinds2)
    end

    grinds = p6.scoring
    grinds2 = p7.scoring

    if type(grinds) == "table" then
        v22 = p8[10]

        for v36 in grinds do
            if v22[v36] == nil then
                grinds[v36] = nil
            end
        end

        grinds.capabilities_204 = 0
    else
        p6.scoring = copy(grinds2)
    end

    grinds = p6.skateboard
    grinds2 = p7.skateboard

    if type(grinds) == "table" then
        v22 = p8[11]

        for v37 in grinds do
            if v22[v37] == nil then
                grinds[v37] = nil
            end
        end

        grinds.scalar_160 = 0
        grinds.scalar_164 = 0
        grinds.scalar_168 = 0
        grinds.scalar_172 = 0
        landing_normal_144 = grinds.vector_128

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_128", grinds2.vector_128)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_144

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_144", grinds2.vector_144)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_64

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_64", grinds2.vector_64)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_80

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_80", grinds2.vector_80)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end

        landing_normal_144 = grinds.vector_96

        if type(landing_normal_144) ~= "table" or #landing_normal_144 ~= 4 then
            copy_into(grinds, "vector_96", grinds2.vector_96)
        else
            landing_normal_144[1] = 0
            landing_normal_144[2] = 0
            landing_normal_144[3] = 0
            landing_normal_144[4] = 0
        end
    else
        p6.skateboard = copy(grinds2)
    end

    grinds = p6.skeleton
    grinds2 = p7.skeleton

    if type(grinds) == "table" then
        v22 = p8[12]

        for v38 in grinds do
            if v22[v38] == nil then
                grinds[v38] = nil
            end
        end

        grinds.deck_pitch_540 = 0
        grinds.deck_yaw_536 = 0
        grinds.extra_weight_584 = 0
        grinds.flag_597 = 0
        grinds.flag_600 = 0
        grinds.flag_601 = 0
        grinds.hips_right_angle_496 = 0
        grinds.hips_up_angle_500 = 0
        grinds.no_support_time_548 = 0
        grinds.over_599 = 0
        grinds.response_change_588 = 0
        grinds.response_changed_605 = 0
        grinds.response_strength_580 = 0
        grinds.scalar_544 = 0
        grinds.teleport_pending_604 = 0
        grinds.time_until_teleport_576 = 0
        grinds.twist_504 = 0
    else
        p6.skeleton = copy(grinds2)
    end

    grinds = p6.state
    grinds2 = p7.state

    if type(grinds) ~= "table" then
        p6.state = copy(grinds2)

        return
    end

    v22 = p8[13]

    for v39 in grinds do
        if v22[v39] == nil then
            grinds[v39] = nil
        end
    end

    grinds.category_12 = 0
    grinds.counter_36 = 0
    grinds.flag_61 = 0
    grinds.flag_66 = 0
    grinds.flag_69 = 0
    grinds.flag_74 = 0
    grinds.identifier_8 = 0
    grinds.signed_ground_step_84 = 0
    grinds.skitch_value_40 = 0
    grinds.state_16 = 0
    grinds.surface_height_32 = 0
end

local t4

local function build_known(p9) -- line: 835
    -- upvalues: t4 (ref)
    local function set_of(p10) -- line: 837
        local t6 = {}

        for v40 in p10 do
            t6[v40] = true
        end

        return t6
    end

    local t7 = {}

    for v41 in p9 do
        t7[v41] = true
    end

    local t5 = {
        t7
    }
    local t8 = {}

    for v42 in p9 do
        table.insert(t8, v42)
    end

    table.sort(t8)

    for _, v43 in t8 do
        local v44 = p9[v43]

        if type(v44) == "table" and #v44 == 0 then
            local t9 = {}

            for v45 in v44 do
                t9[v45] = true
            end

            table.insert(t5, t9)
        end
    end

    t4 = t5

    return t5
end

local v46 = false

function t1.set_plan(p11) -- line: 863
    -- upvalues: v46 (ref)
    v46 = p11
end

local v47 = false

function t1.set_general(p12) -- line: 870
    -- upvalues: v47 (ref)
    v47 = p12
end

local v48 = false

function t1.set_in_place_reference(p13) -- line: 874
    -- upvalues: v48 (ref)
    v48 = p13
end

local function reset_record(p14, p15, p16) -- line: 880
    -- upvalues: copy_into (copy)
    local scalars, tables = p16.scalars, p16.tables
    local n2 = 0

    for v49 in p14 do
        local v50 = scalars[v49]

        if v50 ~= nil then
            p14[v49] = v50
            n2 += 1
        elseif tables[v49] == nil then
            p14[v49] = nil
        end
    end

    if n2 ~= p16.scalar_count then
        for v51, v52 in scalars do
            p14[v51] = v52
        end
    end

    local vectors = p16.vectors

    for i = 1, #vectors do
        local v53 = vectors[i]
        local v54 = p14[v53]
        local v55 = p15[v53]

        if type(v54) ~= "table" or #v54 ~= 4 then
            copy_into(p14, v53, v55)
        else
            local v56 = v55[1]
            local v57 = v55[2]
            local v58 = v55[3]
            local v59 = v55[4]

            v54[1] = v56
            v54[2] = v57
            v54[3] = v58
            v54[4] = v59
        end
    end

    local arrays = p16.arrays

    for i = 1, #arrays do
        local v60 = arrays[i]
        local v61 = p15[v60]
        local v62 = p14[v60]
        local v63 = #v61

        if type(v62) ~= "table" or #v62 ~= v63 then
            copy_into(p14, v60, v61)
        else
            for j = 1, v63 do
                copy_into(v62, j, v61[j])
            end
        end
    end

    local others = p16.others

    for i = 1, #others do
        local v64 = others[i]

        copy_into(p14, v64, p15[v64])
    end
end

local v65 = false

local function check_named(p17) -- line: 935
    -- upvalues: PhysicalPlayerInput (copy), copy (copy), build_plan (copy), v21 (ref), reset_named (copy), t4 (ref), build_known (copy), reset_record (copy), v65 (ref)
    local function differs(p18, p19, p20) -- line: 936
        -- upvalues: differs (copy)
        if type(p18) ~= type(p19) then
            return p20
        end

        if type(p18) == "table" then
            for v66, v67 in p18 do
                local v68 = differs(v67, p19[v66], p20 .. "." .. tostring(v66))

                if v68 then
                    return v68
                end
            end

            for v69 in p19 do
                if p18[v69] == nil then
                    return p20 .. "." .. tostring(v69)
                end
            end
        elseif p18 ~= p19 and (p18 == p18 or p19 == p19) or p18 == 0 and p19 == 0 and 1 / p18 ~= 1 / p19 then
            return p20
        end

        return nil
    end

    local v70 = v21

    if v70 == nil then
        v70 = build_plan(p17, true, nil)
        v21 = v70
    end

    local v71 = t4 or build_known(p17)

    for i = 1, 3 do
        local v72 = i + 12345

        local function fill(p21) -- line: 970
            -- upvalues: v72 (ref), fill (copy)
            for v73, v74 in p21 do
                if type(v74) == "table" then
                    fill(v74)
                elseif type(v74) == "number" then
                    v72 = (v72 * 1103515245 + 12345) % 2147483648
                    p21[v73] = v72 % 977 - 400.5
                end
            end
        end

        local v75 = PhysicalPlayerInput.default()

        fill(v75)
        v75.teleport_output = {
            ready = true
        }
        v75.grinds.surface_name_196 = { { 1, 2 } }

        if i >= 2 then
            v75.foreign = 1

            for _, v76 in v75 do
                if type(v76) == "table" and #v76 == 0 then
                    v76.foreign = { 1 }

                    local v77 = false

                    for v78, v79 in v76 do
                        if type(v79) == "table" and #v79 == 4 and i == 3 then
                            v76[v78] = { 1, 2, 3, 4, 5 }
                        elseif type(v79) == "number" and not v77 and v78 ~= "handplant_flags_324" then
                            v77 = true
                            v76[v78] = nil
                        end
                    end
                end
            end
        end

        local v80 = copy(v75)

        reset_record(v75, p17, v70)

        for j = 1, #v70.records do
            local v81 = v70.records[j]

            reset_record(v75[v81], p17[v81], v70.plans[v81])
        end

        reset_named(v80, p17, v71)

        local physical = differs(v75, v80, "physical")

        if physical ~= nil then
            error("output_reset: reset_named (generated) and the plan disagree at " .. physical .. ": run tools/offline/lane_b3logic/gen_reset.luau again", 0)
        end
    end

    v65 = true
end

function t1.reset_outputs_in_place(p22) -- line: 1017
    -- upvalues: t1 (copy), assign_into (copy), copy (copy), v8 (ref), build_template (copy), build_plan (copy), v21 (ref), reset_named (copy), t4 (ref), build_known (copy), v46 (ref), v47 (ref), v48 (ref), reset_record (copy), v65 (ref), check_named (copy)
    if v48 then
        return t1.reset_outputs_reference(p22)
    end

    local v82 = v8 or build_template()
    local surface_default_mode, component_1832_word_1876, skeleton = p22.surface_default_mode, p22.component_1832_word_1876, p22.skeleton
    local anim_to_world_11920 = skeleton.anim_to_world_11920
    local v83 = bit32.band(p22.air.handplant_flags_324, 1342177279)

    if v47 then
        skeleton.anim_to_world_11920 = nil

        for v84 in p22 do
            if v82[v84] == nil then
                p22[v84] = nil
            end
        end

        for v85, v86 in v82 do
            if type(v86) == "table" then
                local v87 = p22[v85]

                if type(v87) == "table" then
                    assign_into(v87, v86)
                else
                    p22[v85] = copy(v86)
                end
            else
                p22[v85] = v86
            end
        end

        p22.skeleton.anim_to_world_11920 = anim_to_world_11920
    elseif v46 then
        local v88 = v21

        if v88 == nil then
            v88 = build_plan(v82, true, nil)
            v21 = v88
        end

        reset_record(p22, v82, v88)

        local records, plans = v88.records, v88.plans

        for i = 1, #records do
            local v89 = records[i]
            local v90 = p22[v89]

            if type(v90) == "table" then
                reset_record(v90, v82[v89], plans[v89])
            else
                p22[v89] = copy(v82[v89])
            end
        end
    else
        if not v65 then
            check_named(v82)
        end

        reset_named(p22, v82, t4 or build_known(v82))
    end

    p22.air.handplant_flags_324 = v83
    p22.surface_default_mode = surface_default_mode
    p22.component_1832_word_1876 = component_1832_word_1876
end

function t1.reset_outputs_reference(p23) -- line: 1080
    -- upvalues: rt (copy), PhysicalPlayerInput (copy), t1 (copy)
    local surface_default_mode, component_1832_word_1876 = p23.surface_default_mode, p23.component_1832_word_1876
    local v91 = rt.copy(p23.skeleton.anim_to_world_11920)
    local v92 = bit32.band(p23.air.handplant_flags_324, 1342177279)
    local v93 = PhysicalPlayerInput.default()

    v93.air.handplant_flags_324 = v92
    v93.air.landing_normal_144 = rt.copy(t1.UP)
    v93.air.selected_trajectory_240 = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 3212836864, 3212836864, 3212836864, 3212836864 }
    }
    v93.reckoning.vector_96 = rt.copy(t1.UP)
    v93.ground.vector_64 = rt.copy(t1.UP)
    v93.ground.vector_80 = rt.copy(t1.UP)
    v93.ground.vector_96 = rt.copy(t1.UP)
    v93.ground.scalar_276 = -1
    v93.grinds.words_136_140 = { 4294967295, 0 }
    v93.skeleton.anim_to_world_11920 = v91
    v93.surface_default_mode = surface_default_mode
    v93.component_1832_word_1876 = component_1832_word_1876
    rt.assign(p23, v93)
end

return t1
