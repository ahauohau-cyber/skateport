-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/grind_contact")
local v2 = import("skate_core/trigonometry")
local dot3, scale, add, sub = v1.dot3, v1.scale, v1.add, v1.sub
local cross = v1.cross
local v3
local t1 = {}

t1.Control = {}

function t1.Control.default() -- line: 25
    return {
        yaw = 0,
        pitch = 0
    }
end

function t1.Control.update(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11) -- line: 30
    -- upvalues: rt (copy), dot3 (copy), v3 (ref)
    local v4, v5, v6

    if p2 == 0 then
        v5 = 0
        v6 = p10 * p10 * p10
        v4 = false
    elseif p2 == 3 then
        local v7 = p5 ~= p6
        local v8 = dot3(p4, p3)
        local v9 = (if not v7 then v8 else -v8) * (if p6 then -1 else 1)
        local v10 = if not (v9 > 0) or not (math.abs(p10) <= 0.01) or not (v9 > -0.25) then p10 elseif v7 then -0.71 else 0.71
        local v11 = if not (math.abs(v8) > 0.26) then v10 elseif v7 then rt.fmin(v10, 0) else rt.fmax(v10, 0)

        if v9 < -0.25 then
            v11 = if v7 then rt.fmax(v10, 0) else rt.fmin(v10, 0)
        end

        local v12 = (if p5 then 1 else -1) * (if p6 then -1 else 1)

        if p11 > 0 and v9 <= p11 then
            local v13 = (p11 - v9) * v12 * 10

            v11 = if v12 > 0 then rt.fmin(v13, v12) else rt.fmax(v13, v12)
        end

        if p7 then
            v11 = rt.clamp(v11 + v12 * 0.5, -1, 1)
        end

        local v14 = rt.clamp(v3(p8) * 0.85 + v3(p9) * 0.79, -0.85, 0.85)

        v5 = v14 * v14 * v14
        v6 = v11 * v11 * v11
        v4 = v11 ~= v10
    else
        v5 = 0
        v6 = 0
        v4 = false
    end

    local v15 = if v4 then 0.76 else 0.91

    p1.yaw = p1.yaw * 0.91 + v5 * 0.0899999737739563
    p1.pitch = (1 - v15) * v6 + p1.pitch * v15

    if math.abs(p1.yaw) < 1E-04 then
        p1.yaw = 0
    end

    if math.abs(p1.pitch) < 1E-04 then
        p1.pitch = 0
    end
end

v3 = function(p12) -- line: 99
    if p12 > 0.25 then
        return (p12 - 0.25) * 1.3333333333333333
    end

    if p12 < -0.25 then
        return (p12 + 0.25) * 1.3333333333333333
    end

    return 0
end

t1.deadzone = v3

function t1.rotate(p13, p14, p15) -- line: 110
    -- upvalues: v2 (copy), scale (copy), add (copy), cross (copy)
    local v16, v17 = v2.sin_cos(p15 * 0.5)
    local v18 = scale(p13, v16)

    return add(p14, scale(cross(v18, add(scale(p14, v17), cross(v18, p14))), 2))
end

local rotate = t1.rotate

function t1.truck_frame(p16, p17, p18, p19) -- line: 118
    -- upvalues: rt (copy), dot3 (copy), scale (copy), cross (copy), rotate (copy)
    local v19 = rotate(p17, p16[3], p18.yaw * -0.68)
    local v20 = cross(p17, v19)
    local v22 = math.sqrt((dot3(v20, v20)))

    if v22 <= 0.001 then
        return rt.copy(p16)
    end

    local v23 = scale(v20, 1 / v22)
    local v25 = rotate(v23, v19, p18.pitch * (if p19 then -0.68 else 0.68))

    return {
        v23,
        cross(v25, v23),
        v25,
        rt.copy(p16[4])
    }
end

function t1.tip_frame(p20, p21, p22, p23, p24) -- line: 132
    -- upvalues: rt (copy), dot3 (copy), scale (copy), sub (copy), cross (copy), rotate (copy)
    local v30 = rotate(scale(p21, if dot3(cross(p21, p22), sub(p20[4], p23)) > 0 then -1 else 1), p22, if p24 then 0.7330383062362671 else 0.3490658700466156)
    local v32 = scale(p21, if dot3(p21, p20[1]) > 0 then 1 else -1)

    return {
        v32,
        v30,
        cross(v32, v30),
        rt.copy(p20[4])
    }
end

return t1
