-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t2 = {
    "position_272",
    "velocity_288",
    "normal_304",
    "contact_velocity_320",
    "contact_position_336",
    "adjustment_352",
    "apex_368"
}
local t1 = {}

t1.TrajectoryResult = {}

function t1.TrajectoryResult.default() -- line: 41
    return {
        time_remaining_384 = 0,
        duration_388 = 0,
        scalar_392 = 0,
        apex_time_396 = 0,
        frame_400 = 0,
        valid_404 = false,
        word_408 = 0,
        position_272 = { 0, 0, 0, 0 },
        velocity_288 = { 0, 0, 0, 0 },
        normal_304 = { 0, 0, 0, 0 },
        contact_velocity_320 = { 0, 0, 0, 0 },
        contact_position_336 = { 0, 0, 0, 0 },
        adjustment_352 = { 0, 0, 0, 0 },
        apex_368 = { 0, 0, 0, 0 }
    }
end

function t1.TrajectoryResult.eq(p1, p2) -- line: 61
    -- upvalues: t2 (copy)
    for _, v1 in t2 do
        local v2 = p1[v1]
        local v3 = p2[v1]

        if v2[1] ~= v3[1] or v2[2] ~= v3[2] or v2[3] ~= v3[3] or v2[4] ~= v3[4] then
            return false
        end
    end

    if p1.time_remaining_384 == p2.time_remaining_384 and p1.duration_388 == p2.duration_388 and p1.scalar_392 == p2.scalar_392 and p1.apex_time_396 == p2.apex_time_396 and p1.frame_400 == p2.frame_400 and p1.valid_404 == p2.valid_404 then
        return p1.word_408 == p2.word_408
    end

    return false
end

function t1.TrajectoryResult.reset(p3) -- line: 80
    p3.position_272 = { 0, 0, 0, 0 }
    p3.velocity_288 = { 0, 0, 0, 0 }
    p3.normal_304 = { 0, 0, 0, 0 }
    p3.contact_velocity_320 = { 0, 0, 0, 0 }
    p3.contact_position_336 = { 0, 0, 0, 0 }
    p3.time_remaining_384 = 0
    p3.duration_388 = 0
    p3.scalar_392 = 0
    p3.frame_400 = 0
    p3.valid_404 = false
    p3.word_408 = 0
end

t1.OffBoardOutput = {}

function t1.OffBoardOutput.eq(p4, p5) -- line: 117
    for _, v4 in { "vector_64", "vector_96", "vector_160", "vector_176", "vector_192", "vector_208", "vector_224", "vector_240" } do
        local v5 = p4[v4]
        local v6 = p5[v4]

        if v5[1] ~= v6[1] or v5[2] ~= v6[2] or v5[3] ~= v6[3] or v5[4] ~= v6[4] then
            return false
        end
    end

    if p4.scalar_32 == p5.scalar_32 and p4.scalar_92 == p5.scalar_92 and p4.word_144 == p5.word_144 and p4.scalar_148 == p5.scalar_148 and p4.scalar_152 == p5.scalar_152 and p4.scalar_156 == p5.scalar_156 and p4.flag_320 == p5.flag_320 and p4.flag_328 == p5.flag_328 then
        return p4.flag_331 == p5.flag_331
    end

    return false
end

return t1
