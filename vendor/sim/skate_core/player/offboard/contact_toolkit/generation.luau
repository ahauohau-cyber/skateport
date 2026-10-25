-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/contact_toolkit/candidate")
local v2

local function toolkit() -- line: 12
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2
end

local function cross(p1, p2) -- line: 18
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.cross(p1, p2)
end

local function dot(p3, p4) -- line: 21
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.dot(p3, p4)
end

local function length(p5) -- line: 24
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.length(p5)
end

local function scale(p6, p7) -- line: 27
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.scale(p6, p7)
end

local function sub(p8, p9) -- line: 30
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.sub(p8, p9)
end

local Builder, between_slope, down_slope, up_slope = v1.Builder, v1.between_slope, v1.down_slope, v1.up_slope

return {
    generate = function(p10, p11, p12, p13, p14) -- generate | line: 44
        -- upvalues: rt (copy), import (copy), v2 (ref), dot (copy), Builder (copy), between_slope (copy), down_slope (copy), up_slope (copy)
        local t2 = {
            input = rt.copy(p10),
            profile = p11,
            obstruction = p13,
            candidates = {}
        }
        local v3 = bit32.band(p12.flags_176, 1) ~= 0

        if v3 then
            local velocity, up, up2, velocity2 = p10.velocity, p10.up, p10.up, p10.velocity

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v4 = v2.dot(up2, velocity2)

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v5 = v2.scale(up, v4)

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v6 = v2.sub(velocity, v5)

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            if v2.length(v6) < 0.01 then
                local add = Builder.add
                local position, normal = p12.position, p12.normal
                local right = p10.right
                local normal2 = p12.normal

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                add(t2, position, normal, v2.cross(right, normal2), -1, 0, 0)

                return t2.candidates
            end
        end

        if p11.last_ground == 0 then
            return t2.candidates
        end

        local function forward(p15) -- line: 65
            -- upvalues: p10 (copy), import (copy), v2 (ref), dot (copy)
            local position = p10.position

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            return dot(v2.sub(p15, position), p10.forward)
        end

        local v7 = p11.last_ground - 1
        local v9 = false
        local v10 = false
        local v8

        for i = 0, v7 do
            local v11 = rt.copy(p11.segments[i + 1])
            local v12

            if i + 1 < p11.last_ground then
                local v13 = p11.segments[i + 2]

                v12 = if v11.kind == 0 or v13.kind == 0 then rt.copy(v13.normal) else rt.copy(p10.up)
            else
                v12 = rt.copy(v11.normal)
            end

            local v14 = v8

            if not v10 then
                local v15 = if v8 == nil then p10.position else p11.segments[v8 + 1]["end"]
                local v16 = v11["end"]

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v17 = v2.sub(v16, v15)
                local up = p10.up

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                if v2.dot(v17, up) > 0 then
                    v14 = i
                end
            end

            local v18, v19

            if v11.kind == 1 and v11.length > 0.05 then
                local v20 = v11.length > 0.4
                local v21 = up_slope(p10, v11.length)
                local v22 = false
                local v23 = i + 1
                local v24

                while true do
                    if v23 < p11.last_ground then
                        local v25 = p11.segments[v23 + 1]
                        local start, position
                        local v26 = v22

                        if v22 then
                        elseif v25.kind == 2 then
                            start = v25.start
                            position = p10.position

                            if v2 == nil then
                                v2 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            local v27 = v2.sub(start, position)
                            local forward = p10.forward

                            if v2 == nil then
                                v2 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            v26 = v2.dot(v27, forward) < p13 - 0.35
                        end

                        if v25.kind ~= 0 and (v25.kind ~= 1 or v25.length >= 0.05) then
                            v24 = v26
                            break
                        end

                        local v29 = false

                        if v26 then
                            v29 = v26
                        else
                            local direction = v25.direction
                            local forward = p10.forward

                            if v2 == nil then
                                v2 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            if v2.dot(direction, forward) > 0.70700002 then
                                local start = v25.start
                                local position = p10.position

                                if v2 == nil then
                                    v2 = import("skate_core/player/offboard/contact_toolkit")
                                end

                                local v30 = v2.sub(start, position)
                                local forward = p10.forward

                                if v2 == nil then
                                    v2 = import("skate_core/player/offboard/contact_toolkit")
                                end

                                v29 = v2.dot(v30, forward) < p13 - 0.35
                            end
                        end

                        v22 = v29
                        v23 += 1
                        continue
                    end

                    v24 = v22
                    break
                end

                v18 = v10

                local v32
                local v31 = v21

                if v23 < p11.last_ground and p11.segments[v23 + 1].kind == 1 then
                    local v33 = rt.copy(p11.segments[v23 + 1]["end"])

                    v31 = between_slope(p10, v11["end"], v33)

                    if up_slope(p10, v11.length) * 0.5 < v31 then
                        v32 = if v9 then true else between_slope(p10, p10.position, v33) >= up_slope(p10, v11.length) * 0.5
                    else
                        v31 = v21
                        v32 = false
                    end
                else
                    v32 = false
                end

                local v34 = v9 or v24

                if v24 then
                    Builder.approach_up(t2, i, v20 and 128 or 0, v31)

                    local v36 = bit32.bor(64, if v32 or not v20 then 0 else 256)

                    Builder.point(t2, v11["end"], v12, i, v36, v32 and 2 or 3)
                end

                v19 = v34
            else
                if v11.kind == 2 and v11.length > 0.05 then
                    local v37 = v11.length > 0.4
                    local v38 = -down_slope(p10, v11.length)
                    local v39 = i + 1

                    while v39 < p11.last_ground do
                        local v40 = p11.segments[v39 + 1]

                        if v40.kind ~= 0 and (v40.kind ~= 2 or not (v40.length < 0.05)) then
                            break
                        end

                        v39 += 1
                    end

                    local v42
                    local v41 = v38

                    if v39 < p11.last_ground and p11.segments[v39 + 1].kind == 2 then
                        v41 = between_slope(p10, v11.start, p11.segments[v39 + 1].start)

                        if v41 < down_slope(p10, v11.length) * -0.5 then
                            v42 = true
                        else
                            v41 = v38
                            v42 = false
                        end
                    else
                        v42 = false
                    end

                    local v43

                    if v10 or v9 or v14 == nil then
                        v43 = false
                    else
                        local v44 = p11.segments[v14 + 1]["end"]
                        local position = p10.position

                        if v2 == nil then
                            v2 = import("skate_core/player/offboard/contact_toolkit")
                        end

                        local v45 = v2.sub(v44, position)
                        local up = p10.up

                        if v2 == nil then
                            v2 = import("skate_core/player/offboard/contact_toolkit")
                        end

                        v43 = v2.dot(v45, up) > 0.02

                        if i == 1 and p11.segments[1].kind == 0 then
                            v43 = false
                        end
                    end

                    if not v43 then
                        if v42 then
                            Builder.point(t2, v11.start, v12, i, 64, 5)
                        else
                            local start = v11.start
                            local position = p10.position

                            if v2 == nil then
                                v2 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            local v46 = v2.sub(start, position)
                            local forward = p10.forward

                            if v2 == nil then
                                v2 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            if v2.dot(v46, forward) <= 0.75 then
                                Builder.approach_down(t2, i, v37 and 256 or 0, v41, 4)
                                Builder.point(t2, v11.start, v12, i, bit32.bor(64, v37 and 128 or 0), 6)
                            end
                        end
                    end

                    v18 = true
                else
                    v18 = v10
                end

                v19 = v9
            end

            v10 = v18
            v8 = v14
            v9 = v19
        end

        local v48 = p10.position[2] - p12.position[2]

        if v3 and v48 > 0.01 then
            local v49 = if v48 >= 0.4 then bit32.bor(bit32.band(p14, 256), 64) else bit32.band(p14, 320)
            local v51, v52

            if #t2.candidates == 0 then
                v51 = if #t2.candidates == 0 then 7 else 8
                v52 = false
            elseif v10 then
                v52 = true
            else
                v51 = if #t2.candidates == 0 then 7 else 8
                v52 = false
            end

            if not v52 then
                Builder.approach_down(t2, -1, v49, -down_slope(p10, 0.8), v51)
            end
        elseif #t2.candidates == 0 then
            local advance = Builder.advance
            local velocity = p10.velocity

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            advance(t2, v2.length(velocity) * 0.016666668)
        end

        return t2.candidates
    end
}
