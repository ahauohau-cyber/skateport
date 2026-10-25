-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

local function grind() -- line: 10
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local t1 = {
    State = {},
    PhysicalOutput = {},
    SideEffects = {}
}

function t1.fill(p1, p2, p3, p4) -- line: 44
    -- upvalues: rt (copy), import (copy)
    local Family = import("skate_game/physics/grind").Family
    local v1 = rt.copy(p3.geometry)

    p4.crouch = p2.crouch
    p4.leaving = p2.leaving
    p4.direction = rt.copy(p2.direction)
    p4.normal = rt.copy(p2.normal)
    p4.across = rt.copy(p2.across)
    p4.point = rt.copy(v1.point_1120)
    p4.primitive_endpoints = {
        rt.copy(v1.primitive_start_1264),
        rt.copy(v1.primitive_end_1280)
    }
    p4.impact_speed = v1.impact_speed_1492
    p4.audio_surface = p3.surface.audio_surface_1468
    p4.substate = p2.substate
    p4.is_ledge = v1.kind_1464 == 2
    p4.curb = bit32.band(v1.flags_1476, 1073741824) ~= 0
    p4.classification = p2.classification_104

    local spline_guids_1296 = v1.spline_guids_1296

    if spline_guids_1296 ~= nil then
        p4.spline_guids = rt.copy(spline_guids_1296)
    end

    if p4.is_ledge then
        p4.high_side = rt.copy(v1.high_side_1440)
    end

    p4.family = p1

    if p1 == Family.Tipslide or p1 == Family.FiveO or p1 == Family.Backslash then
        p4.on_front = bit32.band(p3.control.flags_1516, 536870912) ~= 0
    end

    if p1 == Family.Tipslide then
        p4.tipslide_324_325_326 = rt.copy(p2.tipslide_97_98_99)
    end

    return {
        air_jump_velocity_128 = if p2.just_jumped then rt.copy(p2.jump_velocity) else nil,
        wipeout_impulse_16 = if p2.slide_wipeout and (p1 == Family.Boardslide or p1 == Family.Darkslide) then rt.copy(p2.slide_impulse) else nil
    }
end

function t1.fill_fields(p5, p6, p7, p8) -- line: 86
    -- upvalues: rt (copy), import (copy), t1 (copy)
    local Family = import("skate_game/physics/grind").Family

    local function v(p9) -- line: 88
        -- upvalues: rt (copy)
        return rt.map(p9, rt.from_bits)
    end

    local direction_0 = p8.direction_0
    local t3 = {}

    t3.direction = rt.map(direction_0, rt.from_bits)

    local point_16 = p8.point_16

    t3.point = rt.map(point_16, rt.from_bits)

    local normal_32 = p8.normal_32

    t3.normal = rt.map(normal_32, rt.from_bits)

    local across_48 = p8.across_48

    t3.across = rt.map(across_48, rt.from_bits)

    local primitive_start_64 = p8.primitive_start_64

    t3.primitive_endpoints = {
        rt.map(primitive_start_64, rt.from_bits),
        v(p8.primitive_end_80)
    }

    local high_side_112 = p8.high_side_112

    t3.high_side = rt.map(high_side_112, rt.from_bits)
    t3.impact_speed = p8.impact_speed_128
    t3.crouch = p8.crouch_132
    t3.family = p5
    t3.substate = p8.words_136_140[2]
    t3.audio_surface = p8.audio_surface_216
    t3.spline_guids = rt.copy(p8.spline_guids_224_232)
    t3.classification = p8.trick_out_240
    t3.leaving = p8.leaving_317 ~= 0
    t3.on_front = p8.flag_318 ~= 0
    t3.is_ledge = p8.is_ledge_320 ~= 0
    t3.curb = p8.curb_321 ~= 0
    t3.tipslide_324_325_326 = {
        p8.dropping_in_324 ~= 0,
        p8.tipslide_325 ~= 0,
        p8.tipslide_326 ~= 0
    }

    local v5 = t1.fill(p5, p6, p7, t3)

    local function raw(p10) -- line: 116
        -- upvalues: rt (copy)
        return rt.map(p10, rt.to_bits)
    end

    local direction = t3.direction

    p8.direction_0 = rt.map(direction, rt.to_bits)

    local point = t3.point

    p8.point_16 = rt.map(point, rt.to_bits)

    local normal = t3.normal

    p8.normal_32 = rt.map(normal, rt.to_bits)

    local across = t3.across

    p8.across_48 = rt.map(across, rt.to_bits)

    local v6 = t3.primitive_endpoints[1]

    p8.primitive_start_64 = rt.map(v6, rt.to_bits)

    local v7 = t3.primitive_endpoints[2]

    p8.primitive_end_80 = rt.map(v7, rt.to_bits)

    if p7.geometry.kind_1464 == 2 then
        local high_side = t3.high_side

        p8.high_side_112 = rt.map(high_side, rt.to_bits)
    end

    local spline_guids_1296 = p7.geometry.spline_guids_1296

    if spline_guids_1296 ~= nil then
        p8.spline_guids_224_232 = rt.copy(spline_guids_1296)
    end

    p8.impact_speed_128 = t3.impact_speed
    p8.crouch_132 = t3.crouch
    p8.words_136_140 = {
        p5,
        t3.substate
    }
    p8.audio_surface_216 = t3.audio_surface
    p8.trick_out_240 = t3.classification
    p8.leaving_317 = t3.leaving and 1 or 0
    p8.is_ledge_320 = t3.is_ledge and 1 or 0
    p8.curb_321 = t3.curb and 1 or 0

    if p5 == Family.Tipslide or p5 == Family.FiveO or p5 == Family.Backslash then
        p8.flag_318 = t3.on_front and 1 or 0
    end

    if p5 == Family.Tipslide then
        p8.dropping_in_324 = t3.tipslide_324_325_326[1] and 1 or 0
        p8.tipslide_325 = t3.tipslide_324_325_326[2] and 1 or 0
        p8.tipslide_326 = t3.tipslide_324_325_326[3] and 1 or 0
    end

    return v5
end

return t1
