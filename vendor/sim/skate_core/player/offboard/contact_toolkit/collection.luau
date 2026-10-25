-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/contact_toolkit/analyzer_math")
local v2 = import("skate_core/player/offboard/contact_toolkit/profile")
local v3 = import("skate_core/physics/reciprocal_sqrt")
local v4 = import("skate_core/trigonometry")
local v5 = import("skate_core/air/trajectory")
local v6

local function toolkit() -- line: 16
    -- upvalues: import (copy), v6 (ref)
    if v6 == nil then
        v6 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v6
end

local function dot(p1, p2) -- line: 22
    -- upvalues: import (copy), v6 (ref)
    if v6 == nil then
        v6 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v6.dot(p1, p2)
end

local function scale(p3, p4) -- line: 25
    -- upvalues: import (copy), v6 (ref)
    if v6 == nil then
        v6 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v6.scale(p3, p4)
end

local function sub(p5, p6) -- line: 28
    -- upvalues: import (copy), v6 (ref)
    if v6 == nil then
        v6 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v6.sub(p5, p6)
end

local madd, plane_segment = v1.madd, v1.plane_segment
local QueryResult = v5.QueryResult
local folded_angle
local t1 = {
    collect = function(p7, p8, p9) -- collect | line: 44
        -- upvalues: rt (copy), import (copy), v2 (copy), v6 (ref), madd (copy), plane_segment (copy), QueryResult (copy), folded_angle (ref)
        if v6 == nil then
            v6 = import("skate_core/player/offboard/contact_toolkit")
        end

        local Samples = v6.Samples
        local v7 = rt.copy(p7.input)
        local v8 = Samples.default()
        local v9 = rt.copy(p9.trajectories[1])

        if QueryResult.valid(v9) then
            Samples.insert(v8, v7, v9.contact_position, v9.landing_normal, 1, -1, 0)
        end

        local t2 = {}
        local v12 = math.min(#p8.secondary, #p7.secondary)

        for _, v13 in p9.edges do
            local v14 = rt.copy(v13[1])
            local v15 = rt.copy(v13[2])

            if v6 == nil then
                v6 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v16 = v6.sub(v15, v14)

            if math.abs((folded_angle(v16, v7.forward))) > 0.5235987599999999 then
                local v18 = plane_segment(v7.position, v7.right, v14, v15)

                if v18 ~= nil then
                    Samples.insert(v8, v7, v18, v7.up, 2, -1, 0)
                end
            else
                local position = v7.position

                if v6 == nil then
                    v6 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v19 = v6.sub(v14, position)
                local forward = v7.forward

                if v6 == nil then
                    v6 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v20 = v6.dot(v19, forward)
                local position2 = v7.position

                if v6 == nil then
                    v6 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v21 = v6.sub(v15, position2)
                local forward2 = v7.forward

                if v6 == nil then
                    v6 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v22 = v6.dot(v21, forward2)
                local v23 = madd(v16, v20 / (v20 - v22), v14)
                local right, position3 = v7.right, v7.position

                if v6 == nil then
                    v6 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v24 = v6.sub(v23, position3)

                if v6 == nil then
                    v6 = import("skate_core/player/offboard/contact_toolkit")
                end

                if not (math.abs((v6.dot(right, v24))) > 0.5) then
                    for i = 1, v12 do
                        local v26 = p8.secondary[i]
                        local v27 = p7.secondary[i]
                        local v28 = v26.line.start[3]

                        if not (v28 < rt.fmin(v20, v22) or rt.fmax(v20, v22) < v28) then
                            local v29 = madd(v16, (v28 - v20) / (v22 - v20), v14)
                            local up, up2 = v7.up, v7.up
                            local start = v27.line.start

                            if v6 == nil then
                                v6 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            local v30 = v6.sub(v29, start)

                            if v6 == nil then
                                v6 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            local v31 = madd(up, v6.dot(up2, v30), v27.line.start)
                            local right = v7.right

                            if v6 == nil then
                                v6 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            local v32 = v6.sub(v31, v29)

                            if v6 == nil then
                                v6 = import("skate_core/player/offboard/contact_toolkit")
                            end

                            if not (math.abs((v6.dot(right, v32))) >= 0.05) then
                                local v34 = t2[i]

                                if v34 == nil or v31[2] > v34[2] then
                                    t2[i] = v31
                                end
                            end
                        end
                    end
                end
            end
        end

        for i = 1, #p7.secondary do
            local v35 = p7.secondary[i]
            local v36 = t2[i]
            local v37 = p9.lines[v35.forward_index + 1]

            if v37 ~= nil and v36 ~= nil and v36[2] > v37.position[2] then
                Samples.insert(v8, v7, v36, v7.up, 1, -1, 0)
            elseif v37 ~= nil then
                Samples.insert(v8, v7, v37.position, v37.normal, 1, -1, 0)
            elseif v36 ~= nil then
                Samples.insert(v8, v7, v36, v7.up, 1, -1, 0)
            end
        end

        for _, v38 in p7.primary do
            local v39 = p9.lines[v38.forward_index + 1]

            if v39 ~= nil then
                Samples.insert(v8, v7, v39.position, v39.normal, 0, -1, 0)
            end

            if v38.reverse_index ~= nil then
                local v40 = p9.lines[v38.reverse_index + 1]

                if v40 ~= nil then
                    Samples.insert(v8, v7, v40.position, v40.normal, 0, -1, 0)
                end
            end
        end

        v2.sort(v8.ground)
        v2.sort(v8.other)

        return v8
    end,
    folded_angle = function(p10, p11) -- folded_angle | line: 123
        -- upvalues: rt (copy), import (copy), v3 (copy), v4 (copy), v6 (ref), scale (copy)
        if v6 == nil then
            v6 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v41 = v6.dot(p10, p10)

        if v6 == nil then
            v6 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v42 = v6.dot(p11, p11)
        local v43 = 0

        if v41 > 9.999999747378752E-05 and v42 > 9.999999747378752E-05 then
            local function unit(p12, p13) -- line: 128
                -- upvalues: v3 (copy), scale (copy)
                local v44 = v3.estimate(p13)

                return scale(p12, v44 * 0.5 * (-p13 * (v44 * v44) + 1) + v44)
            end

            local acos = v4.acos
            local clamp = rt.clamp
            local v45 = v3.estimate(v41)
            local v46 = v45 * 0.5 * (-v41 * (v45 * v45) + 1) + v45

            if v6 == nil then
                v6 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v47 = v6.scale(p10, v46)
            local v48 = v3.estimate(v42)
            local v49 = v48 * 0.5 * (-v42 * (v48 * v48) + 1) + v48

            if v6 == nil then
                v6 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v50 = v6.scale(p11, v49)

            if v6 == nil then
                v6 = import("skate_core/player/offboard/contact_toolkit")
            end

            v43 = acos(clamp(v6.dot(v47, v50), -1, 1))
        end

        local v51 = v43 * 0.15915493667125702
        local v52 = v51 - math.floor(v51)
        local v53 = (v52 - (if v52 > 0.5 then 1 else 0)) * 6.2831854820251465
        local v54 = if v53 <= 0 then -1 else 1
        local v55 = v53 * v54

        if v55 > 1.5707964 then
            v55 -= 3.1415927
        end

        return v54 * v55
    end
}

folded_angle = t1.folded_angle

return t1
