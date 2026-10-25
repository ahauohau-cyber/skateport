-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/animation/skeleton_input/name")
local t1 = {
    GrindOutputFields = {}
}

function t1.GrindOutputFields.default() -- line: 17
    -- upvalues: rt (copy), v1 (copy)
    local t2 = {
        1065353216, 0, 0, 0
    }
    local t3 = {
        0, 1065353216, 0, 0
    }
    local t4 = {
        0, 0, 0, 0, 0, 4294967295
    }

    return {
        direction_0 = rt.copy(t2),
        point_16 = table.create(4, 0),
        normal_32 = rt.copy(t3),
        across_48 = rt.copy(t3),
        primitive_start_64 = table.create(4, 0),
        primitive_end_80 = table.create(4, 0),
        camera_target_96 = table.create(4, 0),
        high_side_112 = table.create(4, 0),
        impact_speed_128 = 0,
        crouch_132 = 0,
        words_136_140 = { 4294967295, 0 },
        animation_id_144 = 0,
        scoring_id_148 = 0,
        scorable_id_152 = 4294967295,
        animation_name_156 = v1.encode({}),
        scoring_name_176 = v1.encode({}),
        surface_name_196 = nil,
        audio_surface_216 = 0,
        spline_guids_224_232 = { "0xFFFFFFFFFFFFFFFF", "0xFFFFFFFFFFFFFFFF" },
        trick_out_240 = 0,
        volatile_chromosome_244 = rt.copy(t4),
        animation_chromosome_268 = rt.copy(t4),
        scoring_chromosome_292 = rt.copy(t4),
        grinding_316 = 0,
        leaving_317 = 0,
        flag_318 = 0,
        flag_319 = 0,
        is_ledge_320 = 0,
        curb_321 = 0,
        flag_322 = 0,
        flag_323 = 0,
        dropping_in_324 = 0,
        tipslide_325 = 0,
        tipslide_326 = 0
    }
end

function t1.GrindOutputFields.reset_names(p1, p2, p3) -- line: 71
    -- upvalues: rt (copy)
    p1.animation_name_156 = rt.copy(p2)
    p1.scoring_name_176 = rt.copy(p2)
    p1.surface_name_196 = rt.copy(p3)
end

return t1
