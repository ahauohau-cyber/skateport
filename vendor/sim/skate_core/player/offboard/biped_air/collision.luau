-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/air_launch/math")

local function recovered() -- line: 10
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/biped_air/recovered")
end

local add, dot, length, madd = v1.add, v1.dot, v1.length, v1.madd
local normalize, normalize_or, scale, sub = v1.normalize, v1.normalize_or, v1.scale, v1.sub
local ZERO = v1.ZERO
local t1 = {
    Response = {}
}

function t1.remove_positive(p1, p2) -- line: 31
    -- upvalues: rt (copy), dot (copy), normalize_or (copy), scale (copy), sub (copy), ZERO (copy)
    local v2 = dot(p1, normalize_or(p2, ZERO))

    if v2 > 0 then
        return sub(p1, scale(p2, v2))
    end

    return rt.copy(p1)
end

local remove_positive = t1.remove_positive

t1.State = {}

function t1.State.collision_response(p3, p4, p5, p6) -- line: 44
    -- upvalues: rt (copy), dot (copy), length (copy), normalize (copy), scale (copy), sub (copy)
    local t2 = {
        math.abs((dot(p4[1], p5))),
        (math.abs((dot(p4[2], p5))))
    }
    local v6 = table.create(2)

    for i = 0, 1 do
        local v7 = scale(p5, t2[i + 1])
        local v8 = p4[i + 1]
        local v10 = math.abs(v7[1])
        local v12 = math.abs(v7[2])
        local v14 = math.abs(v7[3])
        local v15 = v7[4]

        v6[i + 1] = length(sub(v8, {
            v10,
            v12,
            v14,
            (math.abs(v15))
        }))
    end

    local v16 = t2[1] > 0.2 or t2[2] > 0.2 or v6[1] > 0.2 or v6[2] > 0.2
    local t3 = {
        {
            p4[1][1],
            0,
            p4[1][3],
            p4[1][1]
        },
        {
            p4[2][1],
            0,
            p4[2][3],
            p4[2][1]
        }
    }
    local t4 = {
        length(t3[1]),
        length(t3[2])
    }
    local t5 = {
        restart = nil,
        request_52 = v16
    }

    if t4[1] > 0.01 or t4[2] > 0.01 then
        if p3.flags_544_550[7] then
            p3.flags_544_550[4] = true
        else
            local v18 = normalize(if t4[1] > t4[2] then t3[1] else t3[2])
            local v19 = rt.copy(p3.result.velocity_288)

            if (t4[1] > 0.01 or t4[2] > 0.01) and dot(v18, v19) < -10 then
                p3.flags_544_550[4] = true
            end

            if dot(v19, v18) < 0 then
                local v20 = p3.result.scalar_392 > p3.frame_208[4][2] and p3.result.normal_304[2] > 0.7

                if p6 and not v20 then
                    t5.restart = v18
                end
            end
        end
    end

    return t5
end

function t1.State.restart_packet(p7, p8, p9, p10, p11, p12) -- line: 98
    -- upvalues: rt (copy), import (copy), madd (copy), scale (copy), remove_positive (copy)
    local DT = import("skate_core/player/offboard/biped_air/recovered").DT
    local v21 = rt.copy(p8)

    p7.flags_544_550[3] = true

    local v22 = rt.copy(p9)

    v21.velocity_0 = madd(p9, 1, (remove_positive(remove_positive(p7.result.velocity_288, scale(v22, -1)), scale(p9, -1))))
    v21.board_position_80 = madd(p11, p12, p10)
    v21.position_32 = madd(v21.velocity_0, DT, p10)
    v21.has_board_position_116 = true
    p7.restart_normal_528 = rt.copy(p9)

    return v21
end

function t1.State.finish_restart(p13, p14, p15) -- line: 116
    -- upvalues: rt (copy)
    p13.frame_452 = 0
    p13.flags_544_550[1] = false
    p13.flags_544_550[2] = false
    p13.frame_80 = rt.copy(p14)
    p13.initial_up_480 = rt.copy(p15)
end

function t1.State.correct_restarted_sample(p16) -- line: 126
    -- upvalues: import (copy), add (copy), scale (copy), sub (copy), remove_positive (copy)
    if p16.flags_544_550[3] then
        local DT = import("skate_core/player/offboard/biped_air/recovered").DT
        local v25 = scale(p16.result.velocity_288, DT)

        p16.result.position_272 = add(sub(p16.result.position_272, v25), remove_positive(v25, scale(p16.restart_normal_528, -1)))
    end
end

return t1
