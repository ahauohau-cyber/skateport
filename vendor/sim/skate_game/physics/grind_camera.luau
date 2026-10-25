-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local t1 = {
    Contact = {},
    GrindCamera = {}
}
local GrindCamera = t1.GrindCamera

function t1.GrindCamera.default() -- line: 27
    return {
        family = 0,
        active = false,
        current = { 0, 0, 0, 0 },
        previous = { 0, 0, 0, 0 },
        error = { 0, 0, 0, 0 },
        midpoint = { 0, 0, 0, 0 }
    }
end

function t1.GrindCamera.condition_fields_reference(p1, p2) -- line: 42
    -- upvalues: rt (copy), GrindCamera (copy)
    local function vector(p3) -- line: 43
        -- upvalues: rt (copy)
        return rt.map(p3, rt.from_bits)
    end

    local t2

    if p2.grinding_316 ~= 0 then
        t2 = {}

        local point_16 = p2.point_16

        t2.point = rt.map(point_16, rt.from_bits)

        local direction_0 = p2.direction_0

        t2.direction = rt.map(direction_0, rt.from_bits)

        local primitive_start_64 = p2.primitive_start_64

        t2.endpoints = {
            rt.map(primitive_start_64, rt.from_bits),
            vector(p2.primitive_end_80)
        }
        t2.family = p2.words_136_140[1]
    end

    local direction_0 = p2.direction_0
    local t3 = {}

    t3.direction_0 = rt.map(direction_0, rt.from_bits)

    local camera_target_96 = p2.camera_target_96

    t3.camera_target_96 = rt.map(camera_target_96, rt.from_bits)
    t3.grinding_316 = p2.grinding_316
    GrindCamera.update(p1, t2, t3)
    p2.direction_0 = rt.map(t3.direction_0, rt.to_bits)
    p2.camera_target_96 = rt.map(t3.camera_target_96, rt.to_bits)
end

function t1.GrindCamera.update(p4, p5, p6) -- line: 68
    -- upvalues: rt (copy)
    if p5 ~= nil then
        local t4 = {
            (p5.endpoints[1][1] + p5.endpoints[2][1]) * 0.5,
            (p5.endpoints[1][2] + p5.endpoints[2][2]) * 0.5,
            (p5.endpoints[1][3] + p5.endpoints[2][3]) * 0.5,
            (p5.endpoints[1][4] + p5.endpoints[2][4]) * 0.5
        }

        if p4.active then
            if p5.family ~= p4.family or t4[1] ~= p4.midpoint[1] or t4[2] ~= p4.midpoint[2] or t4[3] ~= p4.midpoint[3] then
                p4.error = {
                    p4.current[1] + (p4.current[1] - p4.previous[1]) - p5.point[1],
                    p4.current[2] + (p4.current[2] - p4.previous[2]) - p5.point[2],
                    p4.current[3] + (p4.current[3] - p4.previous[3]) - p5.point[3],
                    p4.current[4] + (p4.current[4] - p4.previous[4]) - p5.point[4]
                }
            end
        else
            p4.error = { 0, 0, 0, 0 }
            p4.current = rt.copy(p5.point)
            p4.previous = rt.copy(p5.point)
        end

        p4.error = rt.map(p4.error, function(p7) -- line: 97
            return p7 * 0.95
        end)
        p4.previous = rt.copy(p4.current)
        p4.current = {
            p5.point[1] + p4.error[1],
            p5.point[2] + p4.error[2],
            p5.point[3] + p4.error[3],
            p5.point[4] + p4.error[4]
        }
        p4.family = p5.family
        p4.midpoint = t4
        p4.active = true
        p6.direction_0 = rt.copy(p5.direction)
        p6.camera_target_96 = rt.copy(p4.current)
    else
        p4.active = false
    end
end

local PERF = import("skate_core/camera/tracker").PERF
local from_bits, to_bits = rt.from_bits, rt.to_bits

function t1.GrindCamera.condition_fields(p8, p9) -- line: 131
    -- upvalues: t1 (copy), PERF (copy), from_bits (copy), to_bits (copy)
    if PERF.reference then
        return t1.GrindCamera.condition_fields_reference(p8, p9)
    end

    local direction_0 = p9.direction_0
    local v1 = from_bits(direction_0[1])
    local v2 = from_bits(direction_0[2])
    local v3 = from_bits(direction_0[3])
    local v4 = from_bits(direction_0[4])
    local camera_target_96 = p9.camera_target_96
    local v5 = from_bits(camera_target_96[1])
    local v6 = from_bits(camera_target_96[2])
    local v7 = from_bits(camera_target_96[3])
    local v8 = from_bits(camera_target_96[4])

    if p9.grinding_316 == 0 then
        p8.active = false
    else
        local point_16 = p9.point_16
        local v9 = from_bits(point_16[1])
        local v10 = from_bits(point_16[2])
        local v11 = from_bits(point_16[3])
        local v12 = from_bits(point_16[4])
        local primitive_start_64, primitive_end_80 = p9.primitive_start_64, p9.primitive_end_80
        local v13 = (from_bits(primitive_start_64[1]) + from_bits(primitive_end_80[1])) * 0.5
        local v14 = (from_bits(primitive_start_64[2]) + from_bits(primitive_end_80[2])) * 0.5
        local v15 = (from_bits(primitive_start_64[3]) + from_bits(primitive_end_80[3])) * 0.5
        local v16 = (from_bits(primitive_start_64[4]) + from_bits(primitive_end_80[4])) * 0.5
        local v17 = p9.words_136_140[1]
        local current, previous, error, midpoint = p8.current, p8.previous, p8.error, p8.midpoint
        local v18 = error[1]
        local v19 = error[2]
        local v20 = error[3]
        local v21 = error[4]
        local v22 = current[1]
        local v23 = current[2]
        local v24 = current[3]
        local v25 = current[4]

        if p8.active then
            if v17 ~= p8.family or v13 ~= midpoint[1] or v14 ~= midpoint[2] or v15 ~= midpoint[3] then
                v18 = v22 + (v22 - previous[1]) - v9
                v19 = v23 + (v23 - previous[2]) - v10
                v20 = v24 + (v24 - previous[3]) - v11
                v21 = v25 + (v25 - previous[4]) - v12
            end
        else
            v25 = v12
            v18 = 0
            v19 = 0
            v20 = 0
            v21 = 0
            v22 = v9
            v23 = v10
            v24 = v11
        end

        local v26 = v18 * 0.95
        local v27 = v19 * 0.95
        local v28 = v20 * 0.95
        local v29 = v21 * 0.95

        error[1] = v26
        error[2] = v27
        error[3] = v28
        error[4] = v29
        previous[1] = v22
        previous[2] = v23
        previous[3] = v24
        previous[4] = v25
        v5 = v9 + v26
        v6 = v10 + v27
        v7 = v11 + v28
        v8 = v12 + v29
        current[1] = v5
        current[2] = v6
        current[3] = v7
        current[4] = v8
        p8.family = v17
        midpoint[1] = v13
        midpoint[2] = v14
        midpoint[3] = v15
        midpoint[4] = v16
        p8.active = true
    end

    p9.direction_0 = {
        to_bits(v1),
        to_bits(v2),
        to_bits(v3),
        to_bits(v4)
    }
    p9.camera_target_96 = {
        to_bits(v5),
        to_bits(v6),
        to_bits(v7),
        to_bits(v8)
    }
end

return t1
