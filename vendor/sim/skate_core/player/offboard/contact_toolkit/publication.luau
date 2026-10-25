-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/contact_toolkit/analyzer_math")
local v2 = import("skate_core/player/offboard/contact_toolkit/classification")
local v3

local function toolkit() -- line: 13
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v3
end

local function dot(p1, p2) -- line: 19
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v3.dot(p1, p2)
end

local function length(p3) -- line: 22
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v3.length(p3)
end

local function sub(p4, p5) -- line: 25
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v3.sub(p4, p5)
end

local madd = v1.madd
local History = v2.History

return {
    publish = function(p6, p7, p8, p9, p10, p11, p12, p13) -- publish | line: 38
        -- upvalues: rt (copy), import (copy), v3 (ref), madd (copy), History (copy)
        p13.edge_position = rt.copy(p6.position)
        p13.edge_normal = rt.copy(p6.up)
        p13.distance_168 = 0

        if p7.last_ground ~= 0 then
            local v4 = p7.segments[p7.last_ground]["end"]
            local position = p6.position

            if v3 == nil then
                v3 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v5 = v3.sub(v4, position)
            local forward = p6.forward

            if v3 == nil then
                v3 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v6 = v3.dot(v5, forward)

            p13.distance_168 = if v6 >= 1.65 then 1E+10 else v6

            for _, v7 in p7.segments do
                if (v7.kind == 1 or v7.kind == 2) and v7.length > 0.05 then
                    local start = v7.start
                    local position = p6.position

                    if v3 == nil then
                        v3 = import("skate_core/player/offboard/contact_toolkit")
                    end

                    local v8 = v3
                    local v9 = v8.sub(start, position)
                    local forward = p6.forward

                    if v3 == nil then
                        v3 = import("skate_core/player/offboard/contact_toolkit")
                    end

                    local v10 = v3

                    p13.distance_168 = v10.dot(v9, forward)
                    break
                end
            end

            if bit32.band(p13.flags_176, 1) ~= 0 and p6.forward[2] > 0.2 and p13.normal[2] < 0.7 then
                for i = 1, 2 do
                    local v11, v12

                    if i == 1 then
                        v12 = p8.ground
                        v11 = math.min(p8.original_ground_count, #p8.ground)
                    else
                        v12 = p8.other
                        v11 = #p8.other
                    end

                    for j = 1, v11 do
                        local v14 = v12[j]
                        local position, position2, v15

                        if v14.normal[2] > 0.95 then
                            position = v14.position
                            position2 = p6.position

                            if v3 == nil then
                                v3 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            v15 = false
                        elseif bit32.band(v14.flags, 16) == 0 then
                            v15 = true
                        else
                            position = v14.position
                            position2 = p6.position

                            if v3 == nil then
                                v3 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            v15 = false
                        end

                        if not v15 then
                            local v16 = v3.sub(position, position2)
                            local up = p6.up

                            if v3 == nil then
                                v3 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            if v3.dot(v16, up) > 0 then
                                p13.flags_176 = bit32.bor(p13.flags_176, 512)
                            end

                            break
                        end
                    end
                end
            end

            local velocity = p6.velocity

            if v3 == nil then
                v3 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v17 = v3.length(velocity) * 0.25

            for _, v18 in p7.segments do
                if v18.kind == 0 or not (v18.normal[2] <= 0.9) then
                    p13.edge_normal = rt.copy(v18.normal)
                    v17 -= v18.length

                    if v17 <= 0 then
                        p13.edge_position = madd(v18.direction, v17, v18["end"])
                        break
                    end

                    p13.edge_position = rt.copy(v18["end"])
                    p13.flags_176 = bit32.bor(p13.flags_176, 4)
                end
            end
        end

        local v19 = #p9

        for i = 2, v19 do
            local v20 = p9[i]
            local order = v20.order
            local v21 = i - 1

            while v21 >= 1 and order < p9[v21].order do
                p9[v21 + 1] = p9[v21]
                v21 -= 1
            end

            p9[v21 + 1] = v20
        end

        if v19 == 0 then
            if p10 >= 0.3 then
                p13.flags_176 = bit32.band(p13.flags_176, 4294967294)
            else
                p13.flags_176 = bit32.bor(p13.flags_176, 1024)
            end
        else
            local velocity = p6.velocity

            if v3 == nil then
                v3 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v22 = v3.length(velocity) * 0.016666668
            local v23 = v19 - 1

            for i = 0, v19 - 1 do
                local v24 = p9[i + 1]
                local v25 = false

                if i + 1 < v19 then
                    local forward = p6.forward
                    local position = v24.position
                    local position2 = p6.position

                    if v3 == nil then
                        v3 = import("skate_core/player/offboard/contact_toolkit")
                    end

                    local v26 = v3.sub(position, position2)

                    if v3 == nil then
                        v3 = import("skate_core/player/offboard/contact_toolkit")
                    end

                    v25 = v3.dot(forward, v26) < v22
                end

                local v27 = v24.kind == 1
                local v28

                if v27 then
                    if v25 then
                        v28 = v25
                    else
                        local v29 = i + 1
                        local v30 = v19 - 1

                        v28 = v25

                        for j = v29, v30 do
                            local v31 = p9[j + 1]

                            if not (v31.low <= v24.high) then
                                v28 = v25
                                break
                            end

                            if v31.kind == 4 or v31.kind == 7 or v31.kind == 8 then
                                v28 = true
                                break
                            end

                            v28 = v25
                        end
                    end
                end

                if v27 and v28 then
                    local v32 = i + 1
                    local v33 = v19 - 1

                    v23 = i

                    for k = v32, v33 do
                        if p9[k + 1].segment == v24.segment then
                            v23 = k
                            break
                        end

                        v23 = i
                    end

                    break
                end

                if not v25 then
                    v23 = i
                    break
                end
            end

            rt.assign(p11, p9[v23 + 1])
            p13.target_position = rt.copy(p11.position)
            p13.target_normal = rt.copy(p11.normal)
            p13.flags_176 = bit32.bor(p13.flags_176, (bit32.bor(p11.flags, 2)))

            if bit32.band(p13.flags_176, 1) == 0 then
                p13.flags_176 = bit32.bor(p13.flags_176, 59)
                p13.position = rt.copy(p6.position)
                p13.normal = rt.copy(p6.up)
            end

            History.classify(p12, p13, p11.direction)
        end
    end
}
