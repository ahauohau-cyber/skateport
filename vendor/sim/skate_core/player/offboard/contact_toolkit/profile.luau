-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/contact_toolkit/analyzer_math")
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

local normalize, reciprocal = v1.normalize, v1.reciprocal
local t1 = {
    Segment = {},
    Profile = {}
}

function t1.Profile.default() -- line: 48
    return {
        last_ground = 0,
        segments = {}
    }
end

local v3 = false

function t1.set_reference(p10) -- line: 54
    -- upvalues: v3 (ref)
    v3 = p10
end

local reciprocal_estimate = import("skate_core/physics/native_arithmetic").reciprocal_estimate
local estimate = import("skate_core/physics/reciprocal_sqrt").estimate

local function length3(p11, p12, p13) -- line: 70
    -- upvalues: estimate (copy)
    local v4 = p11 * p11 + p12 * p12 + p13 * p13

    if v4 == 0 then
        return 0
    end

    local v5 = estimate(v4)
    local v6 = v5 * 0.5 * (-v4 * (v5 * v5) + 1) + v5

    return v4 * (v6 * 0.5 * (-v4 * (v6 * v6) + 1) + v6)
end

local function reciprocal2(p14) -- line: 80
    -- upvalues: reciprocal_estimate (copy)
    local v7 = reciprocal_estimate(p14)
    local v8 = v7 * (-v7 * p14 + 1) + v7

    return v8 * (-v8 * p14 + 1) + v8
end

function t1.simplify(p15, p16) -- line: 92
    -- upvalues: t1 (copy), v3 (ref), reciprocal_estimate (copy), estimate (copy)
    if v3 then
        return t1.simplify_reference(p15, p16)
    end

    if #p16 < 2 then
        return 1E+10, #p16
    end

    local v9 = #p16
    local v10 = p16[#p16].sort_distance + 1
    local up = p15.up
    local v11 = #p16 - 2
    local n1 = 1E+10

    for i = 1, v11 do
        local v12 = p16[i]
        local v13 = p16[i + 1]
        local v14 = p16[i + 2]

        if bit32.band(v13.flags, 8) ~= 0 then
            v9 -= #p16 - 1 - i

            local position = v13.position
            local position2, forward = p15.position, p15.forward

            n1 = (position[1] - position2[1]) * forward[1] + (position[2] - position2[2]) * forward[2] + (position[3] - position2[3]) * forward[3]
            break
        end

        local v15 = v13.forward_distance - v12.forward_distance
        local v16 = v13.height - v12.height
        local v17 = v14.forward_distance - v13.forward_distance
        local v18 = v14.height - v13.height
        local v19 = v15 * v15 + v16 * v16 + 0
        local v20

        if v19 == 0 then
            v20 = 0
        else
            local v21 = estimate(v19)
            local v22 = v21 * 0.5 * (-v19 * (v21 * v21) + 1) + v21

            v20 = v19 * (v22 * 0.5 * (-v19 * (v22 * v22) + 1) + v22)
        end

        local v23 = v17 * v17 + v18 * v18 + 0
        local v24

        if v23 == 0 then
            v24 = 0
        else
            local v25 = estimate(v23)
            local v26 = v25 * 0.5 * (-v23 * (v25 * v25) + 1) + v25

            v24 = v23 * (v26 * 0.5 * (-v23 * (v26 * v26) + 1) + v26)
        end

        local v27 = v20 < 0.02 or v24 < 0.02

        if not v27 and (not (v15 * v17 + v16 * v18 + 0 < 0) or not (v15 * up[1] + v16 * up[2] + 0 * up[3] >= 0)) then
            local v28 = reciprocal_estimate(v20)
            local v29 = v28 * (-v28 * v20 + 1) + v28
            local v30 = v29 * (-v29 * v20 + 1) + v29
            local v31 = v15 * v30
            local v32 = v16 * v30
            local v33 = v30 * 0
            local v34 = reciprocal_estimate(v24)
            local v35 = v34 * (-v34 * v24 + 1) + v34
            local v36 = v35 * (-v35 * v24 + 1) + v35
            local v37 = v17 * v36
            local v38 = v18 * v36
            local v39 = v36 * 0
            local v40 = -v33 * v38 + v32 * v39
            local v41 = -v31 * v39 + v33 * v37
            local v42 = -v32 * v37 + v31 * v38
            local v43 = v40 * v40 + v41 * v41 + v42 * v42
            local v44

            if v43 == 0 then
                v44 = 0
            else
                local v45 = estimate(v43)
                local v46 = v45 * 0.5 * (-v43 * (v45 * v45) + 1) + v45

                v44 = v43 * (v46 * 0.5 * (-v43 * (v46 * v46) + 1) + v46)
            end

            v27 = v44 < 0.05
        end

        if v27 then
            v13.sort_distance = v10
            v9 -= 1
        end
    end

    t1.sort(p16)

    return n1, v9
end

function t1.simplify_reference(p17, p18) -- line: 138
    -- upvalues: import (copy), v2 (ref), reciprocal (copy), t1 (copy)
    if #p18 < 2 then
        return 1E+10, #p18
    end

    local v47 = #p18
    local v48 = p18[#p18].sort_distance + 1
    local v49 = #p18 - 2
    local n2 = 1E+10

    for i = 1, v49 do
        if bit32.band(p18[i + 1].flags, 8) ~= 0 then
            local v50 = v47 - (#p18 - 1 - i)
            local position = p18[i + 1].position
            local position2 = p17.position

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v51 = v2.sub(position, position2)
            local forward = p17.forward

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            n2 = v2.dot(v51, forward)
            v47 = v50
            break
        end

        local t2 = {
            p18[i + 1].forward_distance - p18[i].forward_distance,
            p18[i + 1].height - p18[i].height,
            0, 0
        }
        local t3 = {
            p18[i + 2].forward_distance - p18[i + 1].forward_distance,
            p18[i + 2].height - p18[i + 1].height,
            0, 0
        }

        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v52 = v2.length(t2)

        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v53 = v2.length(t3)
        local v54

        if v52 < 0.02 or v53 < 0.02 then
            v54 = true
        else
            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v55 = false

            if v2.dot(t2, t3) < 0 then
                local up = p17.up

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                v55 = v2.dot(t2, up) >= 0
            end

            local v56 = not v55

            if v56 then
                local v57 = reciprocal(v52)

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v58 = v2.scale(t2, v57)
                local v59 = reciprocal(v53)

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v60 = v2.scale(t3, v59)

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v61 = v2.cross(v58, v60)

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                v54 = v2.length(v61) < 0.05
            else
                v54 = v56
            end
        end

        if v54 then
            p18[i + 1].sort_distance = v48
            v47 -= 1
        end
    end

    t1.sort(p18)

    return n2, v47
end

function t1.sort(p19) -- line: 183
    for i = 2, #p19 do
        local v62 = p19[i]
        local sort_distance = v62.sort_distance
        local v63 = i - 1

        while v63 >= 1 and sort_distance < p19[v63].sort_distance do
            p19[v63 + 1] = p19[v63]
            v63 -= 1
        end

        p19[v63 + 1] = v62
    end
end

function t1.build(p20, p21) -- line: 197
    -- upvalues: rt (copy), import (copy), v2 (ref), normalize (copy), reciprocal (copy), t1 (copy)
    local v64 = t1.Profile.default()

    for i = 1, #p21 - 1 do
        local v65 = rt.copy(p21[i].position)
        local v66 = rt.copy(p21[i + 1].position)

        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v67 = v2.sub(v66, v65)

        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v68 = v2.length(v67)

        if not (v68 < 1E-04) then
            local v69 = reciprocal(v68)

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v70 = v2.scale(v67, v69)
            local forward = p20.forward

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v71 = v2.dot(forward, v70)
            local v72

            if math.abs(v71) > 0.5 then
                v72 = 0
            else
                local up = p20.up

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                v72 = if v2.dot(up, v70) >= 0 then 1 else 2
            end

            local v73 = v64.segments[#v64.segments]

            if v72 ~= 0 and v73 ~= nil and v73.kind == v72 then
                v73["end"] = v66

                local start = v73.start

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v74 = v2.sub(v66, start)

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                v73.length = v2.length(v74)

                local v75 = reciprocal(v73.length)

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                v73.direction = v2.scale(v74, v75)

                local right = p20.right

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                v73.normal = normalize(v2.cross(v74, right), p20.up)
            else
                local segments = v64.segments
                local t4 = {
                    kind = v72,
                    start = v65,
                    ["end"] = v66,
                    direction = v70
                }
                local right = p20.right

                if v2 == nil then
                    v2 = import("skate_core/player/offboard/contact_toolkit")
                end

                t4.normal = normalize(v2.cross(v67, right), p20.up)
                t4.length = v68
                table.insert(segments, t4)

                if v72 == 0 then
                    v64.last_ground = #v64.segments
                end
            end
        end
    end

    return v64
end

return t1
