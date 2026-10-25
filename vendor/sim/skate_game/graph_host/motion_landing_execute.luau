-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local encode = import("skate_core/animation/skeleton_input/name").encode
local v1

local function motion_animation() -- line: 16
    -- upvalues: import (copy), v1 (ref)
    local v2 = v1

    if v2 == nil then
        v2 = import("skate_game/graph_host/motion_animation")
        v1 = v2
    end

    return v2
end

local v3

local function motion_riding_conditions() -- line: 25
    -- upvalues: import (copy), v3 (ref)
    local v4 = v3

    if v4 == nil then
        v4 = import("skate_game/graph_host/motion_riding_conditions")
        v3 = v4
    end

    return v4
end

local function attribute_name_eq(p1, p2) -- line: 35
    local v5 = p1[1]
    local v6 = p2[1]

    if v5[1] == v6[1] and v5[2] == v6[2] and v5[3] == v6[3] and v5[4] == v6[4] then
        return v5[5] == v6[5]
    end

    return false
end

local t1 = {}

function t1.execute(p3, p4, p5, p6, p7, p8, p9, p10, p11) -- line: 50
    -- upvalues: rt (copy), import (copy), encode (copy), v3 (ref), t1 (copy)
    local tag = p3.tag

    if tag == "IsAnticipating" then
        if p11 ~= 1 then
            p5.anticipating = p11 == 0
        end
    elseif tag == "IsLanding" then
        if p11 ~= 1 then
            p5.landing = p11 == 0
        end
    elseif tag == "IsManualing" then
        if p11 ~= 1 then
            p5.manualing = p11 == 0
        end
    elseif tag == "IsDoingTrick" then
        if p11 ~= 1 then
            p5.doing_trick = p11 == 0
        end
    elseif tag == "SetLandingData" then
        if p11 == 0 then
            if p8 == nil then
                error("SetLandingData requires actual landing publication", 0)
            end

            if p9 == nil then
                error("SetLandingData requires animation stance", 0)
            end

            t1.set(p6, "Spin", if p9 then p8.spin else -p8.spin)
            t1.set(p6, "AvgVelY", p8.last_good_landing_velocity)
            p4.value = p8.height
        elseif p11 == 1 then
            t1.set(p6, "disttocog", p4.value)
        end
    elseif tag == "DisableTricks" then
        local length = p3.length

        if p11 == 0 then
            p5.tricks_allowed = false
            p4.value = length
            p4.complete = false
        elseif p11 ~= 1 then
            p5.tricks_allowed = true
        elseif not p4.complete then
            p4.value -= p10

            if p4.value < 0 then
                p5.tricks_allowed = true
                p4.complete = true
            end
        end
    elseif tag == "ChooseRandomLanding" then
        local count = p3.count

        if p11 == 0 then
            if count <= 0 then
                error("ChooseRandomLanding requires numlandings > 0", 0)
            end

            local to_i32 = rt.to_i32
            local v7 = v3

            if v7 == nil then
                v7 = import("skate_game/graph_host/motion_riding_conditions")
                v3 = v7
            end

            local v8 = to_i32(v7.MotionRandom.next_u32(p7))

            if v8 < 0 and v8 ~= -2147483648 then
                v8 = -v8
            end

            local v9 = rt.irem(v8, count)
            local Random = encode("Random")
            local v10 = encode(string.format("%d", v9))
            local construction_values = p6.construction_values
            local v12

            for i = 1, #construction_values do
                local v13 = construction_values[i][1][1]
                local v14 = Random[1]

                if v13[1] == v14[1] and v13[2] == v14[2] and v13[3] == v14[3] and v13[4] == v14[4] and v13[5] == v14[5] then
                    v12 = construction_values[i]
                    break
                end

                v12 = nil
            end

            if v12 ~= nil then
                v12[2] = v10
            else
                table.insert(construction_values, {
                    Random,
                    v10
                })
            end
        elseif p11 == 2 then
            local construction_values = p6.construction_values
            local v15 = #construction_values
            local n1 = 0

            for i = 1, v15 do
                local v16 = construction_values[i]
                local v17 = v16[1]
                local Random = encode("Random")
                local v18 = v17[1]
                local v19 = Random[1]

                if v18[1] ~= v19[1] or v18[2] ~= v19[2] or v18[3] ~= v19[3] or v18[4] ~= v19[4] or v18[5] ~= v19[5] then
                    n1 += 1
                    construction_values[n1] = v16
                end
            end

            for i = v15, n1 + 1, -1 do
                construction_values[i] = nil
            end
        end
    end
end

function t1.set(p12, p13, p14) -- line: 161
    -- upvalues: import (copy), encode (copy), v1 (ref)
    local v20 = v1

    if v20 == nil then
        v20 = import("skate_game/graph_host/motion_animation")
        v1 = v20
    end

    v20.MotionAnimation.set_attribute(p12, {
        normalized = false,
        sequence_id = -1,
        name = encode(p13),
        value = p14
    })
end

return t1
