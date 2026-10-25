-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/vector_tracker")
local v2 = import("skate_core/camera/orientation_math")
local v3 = import("skate_core/trigonometry")

local function compass() -- line: 12
    -- upvalues: import (copy)
    return import("skate_core/camera/compass")
end

local dot, length, refined_reciprocal = v1.dot, v1.length, v1.refined_reciprocal
local t1 = {
    Compass = {}
}

function t1.Compass.update_orbit_reference(p1, p2, p3) -- line: 28
    -- upvalues: rt (copy), import (copy), v3 (copy), dot (copy), length (copy), refined_reciprocal (copy), t1 (copy)
    local v4 = import("skate_core/camera/compass")
    local heading, horizontal, sub = v4.heading, v4.horizontal, v4.sub
    local v5 = rt.copy(p3.transform[4])
    local v6, v7

    if p3.selected_compass ~= 6 or p2 == 0 then
        p1.orbit_position = rt.copy(p3.camera_position)
        p1.headings[7] = heading(horizontal(sub(v5, p1.orbit_position)))
        p1.orbit_delta = 0
    else
        local v9 = -p3.look[1]

        if math.abs(v9) > 0.3 then
            v7 = (v9 - (if v9 >= 0 then 0.3 else -0.3)) * p2 * 4.48798942565918
            v6 = 0.9
        else
            v7 = 0
            v6 = 0.95
        end

        p1.orbit_delta = v4.wrap((1 - v6) * v7 + p1.orbit_delta * v6)

        local v10 = p1.orbit_delta * 0.5
        local t2 = {
            0,
            v3.sin(v10),
            0,
            v3.cos(v10)
        }

        p1.orbit_position = t1.add(v5, t1.rotate(t2, sub(p1.orbit_position, v5)))

        local v11 = horizontal(sub(p1.orbit_position, v5))
        local v12 = horizontal(sub(p3.camera_position, v5))
        local v13 = t1.normalize_safe(v11)
        local v14 = t1.normalize_safe(v12)
        local v15 = t1.cross(v13, v14)

        if dot(v13, v14) < 0.8659999966621399 then
            local v16 = length(v15)

            if v16 >= 0.001 then
                local v17 = refined_reciprocal(v16)
                local v18 = v3.sin(-0.2617993950843811)
                local t3 = {
                    v15[1] * v17 * v18,
                    v15[2] * v17 * v18,
                    v15[3] * v17 * v18,
                    v3.cos(-0.2617993950843811)
                }

                p1.orbit_position = t1.add(v5, t1.rotate(t3, v12))
            else
                p1.orbit_position = rt.copy(p3.camera_position)
            end
        end

        local v19 = sub(v5, p1.orbit_position)
        local v20 = length(v19)

        if v20 > 0.001 then
            local v21 = 2 / v20

            p1.orbit_position = sub(v5, {
                v19[1] * v21,
                v19[2] * v21,
                v19[3] * v21,
                v19[4] * v21
            })
        end

        p1.headings[7] = heading(horizontal(sub(v5, p1.orbit_position)))
    end
end

function t1.normalize_safe(p4) -- line: 87
    -- upvalues: v2 (copy), length (copy)
    if length(p4) > 9.999999974752427E-07 then
        return v2.normalize(p4)
    end

    return { 0, 0, 0, 0 }
end

function t1.add(p5, p6) -- line: 95
    return {
        p5[1] + p6[1],
        p5[2] + p6[2],
        p5[3] + p6[3],
        p5[4] + p6[4]
    }
end

function t1.cross(p7, p8) -- line: 99
    return {
        -p7[3] * p8[2] + p7[2] * p8[3],
        -p7[1] * p8[3] + p7[3] * p8[1],
        -p7[2] * p8[1] + p7[1] * p8[2],
        0
    }
end

function t1.rotate(p9, p10) -- line: 108
    -- upvalues: t1 (copy)
    local v22 = t1.cross(p9, p10)
    local t4 = {
        p9[4] * p10[1] + v22[1],
        p9[4] * p10[2] + v22[2],
        p9[4] * p10[3] + v22[3],
        p9[4] * p10[4] + v22[4]
    }
    local v23 = t1.cross(p9, t4)

    return {
        2 * v23[1] + p10[1],
        2 * v23[2] + p10[2],
        2 * v23[3] + p10[3],
        2 * v23[4] + p10[4]
    }
end

local PERF = import("skate_core/camera/tracker").PERF

function t1.Compass.update_orbit(p11, p12, p13) -- line: 130
    -- upvalues: import (copy), t1 (copy), PERF (copy)
    if PERF.reference or p13.selected_compass == 6 and p12 ~= 0 then
        return t1.Compass.update_orbit_reference(p11, p12, p13)
    end

    local v24 = p13.transform[4]
    local camera_position = p13.camera_position
    local v25 = camera_position[1]
    local v26 = camera_position[2]
    local v27 = camera_position[3]
    local v28 = camera_position[4]
    local orbit_position = p11.orbit_position

    orbit_position[1] = v25
    orbit_position[2] = v26
    orbit_position[3] = v27
    orbit_position[4] = v28
    p11.headings[7] = import("skate_core/camera/compass").heading_lanes(v24[1] - v25, 0, v24[3] - v27)
    p11.orbit_delta = 0
end

return t1
