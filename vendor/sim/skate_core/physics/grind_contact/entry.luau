-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/grind_contact")
local v2 = import("skate_core/physics/grind_contact/arithmetic")
local v3 = import("skate_core/physics/grind_contact/admission")
local v4 = import("skate_core/point_graph")
local dot3 = v1.dot3
local engagement_slope_sine = v3.engagement_slope_sine
local PointGraph = v4.PointGraph
local v5
local t1 = {}

t1.Input = {}
t1.Output = {}
t1.Engagement = {}

function t1.Engagement.default() -- line: 55
    return {
        tipslide_frames = 0
    }
end

function t1.Engagement.update(p1, p2) -- line: 60
    -- upvalues: rt (copy), v2 (copy), t1 (copy), dot3 (copy)
    if p2.valid and p2.kind == 2 and (p2.previous_state_2504 == 701 or p2.previous_state_2504 == 403) and p2.speed > 1.8 then
        p1.tipslide_frames = 8
    else
        local v6 = rt.wrapping_sub_u32(p1.tipslide_frames, 1)

        p1.tipslide_frames = if rt.to_i32(v6) < 0 then 0 else v6
    end

    local t2 = {
        impact_speed = 0,
        valid = p2.valid,
        flags = bit32.bor(bit32.band(p2.flags, 4261412863), p1.tipslide_frames > 0 and 33554432 or 0),
        entry_velocity = rt.copy(p2.previous_entry_velocity),
        wipeout_reasons = {}
    }

    if t2.valid then
        t2.flags = bit32.band(t2.flags, 3221225471)

        if p2.category == 100 or p2.category == 200 then
            if math.abs((dot3(p2.up, p2.direction))) > 0.5 then
                t2.valid = false

                if p2.category == 200 then
                    table.insert(t2.wipeout_reasons, 13)
                end
            else
                t2.flags = bit32.bor(t2.flags, 1073741824)

                local v10 = if p2.category == 100 then p2.board_velocity else p2.air_velocity

                t2.entry_velocity = if p2.category == 100 then t1.grounded_velocity(p2.kind, p2.direction, p2.board_velocity, p2.balance_2720, p2.speed, p2.vertical_help) else t1.airborne_velocity(p2.kind, p2.direction, p2.normal, p2.air_velocity)

                local t3 = {
                    t2.entry_velocity[1] - v10[1],
                    t2.entry_velocity[2] - v10[2],
                    t2.entry_velocity[3] - v10[3],
                    t2.entry_velocity[4] - v10[4]
                }

                t2.impact_speed = v2.square_root(dot3(t3, t3))

                if t2.impact_speed > p2.max_delta then
                    table.insert(t2.wipeout_reasons, 9)
                end

                local v11 = dot3(p2.board_velocity, p2.direction)
                local t4 = {
                    p2.direction[1] * v11 - p2.board_velocity[1],
                    p2.direction[2] * v11 - p2.board_velocity[2],
                    p2.direction[3] * v11 - p2.board_velocity[3],
                    p2.direction[4] * v11 - p2.board_velocity[4]
                }

                t4[2] = 0

                if dot3(t4, t4) > 49 and (p2.surface_kind == 0 or dot3(p2.board_velocity, p2.high_side) > 0) then
                    table.insert(t2.wipeout_reasons, 14)
                end

                if #t2.wipeout_reasons ~= 0 then
                    t2.valid = false
                end
            end
        end
    end

    return t2
end

function t1.grounded_velocity(p3, p4, p5, p6, p7, p8) -- line: 141
    -- upvalues: dot3 (copy), engagement_slope_sine (copy), PointGraph (copy)
    local v12 = if p3 == 1 then 0.1
        elseif (p3 == 2 or p3 == 4) and p6 ~= 0 and p7 < 1.45 then 1
        elseif p3 == 2 then 0.4
        elseif p3 ~= 0 and p3 ~= 3 and p3 ~= 4 and p3 ~= 5 then 0
        else 0.2
    local v13 = PointGraph.evaluate(p8, engagement_slope_sine(p4, p5)) * (1 - v12) + v12

    if not (1 - v13 >= 0) then
        v13 = 1
    end

    local v14 = dot3(p5, p4)

    return {
        p4[1] * v14 * v13 + p5[1] * (1 - v13),
        p4[2] * v14 * v13 + p5[2] * (1 - v13),
        p4[3] * v14 * v13 + p5[3] * (1 - v13),
        p4[4] * v14 * v13 + p5[4] * (1 - v13)
    }
end

function t1.airborne_velocity(p9, p10, p11, p12) -- line: 167
    -- upvalues: dot3 (copy), v5 (ref)
    local v15 = v5(p11, p10)
    local t5 = {
        v15[1] * dot3(p12, v15),
        v15[2] * dot3(p12, v15),
        v15[3] * dot3(p12, v15),
        v15[4] * dot3(p12, v15)
    }
    local v16 = if p9 == 0 or p9 == 3 then 0.4
        elseif p9 == 1 or p9 == 5 then 0.2
        elseif p9 == 2 or p9 == 4 then 0.8
        else 0

    return {
        (p12[1] - t5[1]) * v16 + p12[1] * (1 - v16),
        (p12[2] - t5[2]) * v16 + p12[2] * (1 - v16),
        (p12[3] - t5[3]) * v16 + p12[3] * (1 - v16),
        (p12[4] - t5[4]) * v16 + p12[4] * (1 - v16)
    }
end

function t1.airborne_rejections(p13, p14, p15, p16, p17, p18, p19, p20) -- line: 195
    -- upvalues: v2 (copy), dot3 (copy)
    if math.abs((dot3(p14, p13))) > 0.5 then
        return { 13 }
    end

    local t6 = {
        p17[1] - p16[1],
        p17[2] - p16[2],
        p17[3] - p16[3],
        p17[4] - p16[4]
    }
    local t7 = {}

    if p20 < v2.square_root(dot3(t6, t6)) then
        table.insert(t7, 9)
    end

    local v18 = dot3(p15, p13)
    local t8 = {
        p13[1] * v18 - p15[1],
        p13[2] * v18 - p15[2],
        p13[3] * v18 - p15[3],
        p13[4] * v18 - p15[4]
    }

    t8[2] = 0

    if dot3(t8, t8) > 49 and (p18 == 0 or dot3(p15, p19) > 0) then
        table.insert(t7, 14)
    end

    return t7
end

v5 = function(p21, p22) -- line: 232
    return {
        -p21[3] * p22[2] + p21[2] * p22[3],
        -p21[1] * p22[3] + p21[3] * p22[1],
        -p21[2] * p22[1] + p21[1] * p22[2],
        0
    }
end

t1.cross = v5

return t1
