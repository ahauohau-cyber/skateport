-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/player/offboard/controller/state")
local IDENTITY, ZERO = v1.IDENTITY, v1.ZERO
local t1 = {}

t1.GroundResult = {}

function t1.export(p1) -- line: 29
    -- upvalues: rt (copy), t1 (copy)
    return {
        physical_frame = rt.copy(p1.motion.published_frame_64),
        animation_frame = rt.copy(p1.frame_output.frame),
        surface_frame = t1.build_frame(p1.surface.spring_normal, p1.motion.frame_0[3]),
        velocity = rt.copy(p1.frame_output.velocity),
        position = rt.copy(p1.position_368),
        angular_velocity = p1.motion.angular_velocity_688,
        alternate = p1.alternate_709,
        sliding = p1.sliding.active_710
    }
end

function t1.dot(p2, p3) -- line: 42
    return p2[1] * p3[1] + p2[2] * p3[2] + p2[3] * p3[3]
end

local dot2 = t1.dot

function t1.cross(p4, p5) -- line: 47
    return {
        -p4[3] * p5[2] + p4[2] * p5[3],
        -p4[1] * p5[3] + p4[3] * p5[1],
        -p4[2] * p5[1] + p4[1] * p5[2],
        -p4[4] * p5[4] + p4[4] * p5[4]
    }
end

local cross2 = t1.cross

function t1.invsqrt(p6) -- line: 57
    local v2 = 1 / math.sqrt(p6)
    local v3 = v2 * 0.5 * (-p6 * (v2 * v2) + 1) + v2

    return v3 * 0.5 * (-p6 * (v3 * v3) + 1) + v3
end

local invsqrt2 = t1.invsqrt

function t1.normalize(p7) -- line: 66
    -- upvalues: dot2 (copy), invsqrt2 (copy)
    local v4 = invsqrt2(dot2(p7, p7))

    return {
        p7[1] * v4,
        p7[2] * v4,
        p7[3] * v4,
        p7[4] * v4
    }
end

local normalize = t1.normalize

function t1.build_frame(p8, p9) -- line: 72
    -- upvalues: rt (copy), IDENTITY (copy), ZERO (copy), dot2 (copy), cross2 (copy), invsqrt2 (copy), normalize (copy)
    local v5 = cross2(p8, p9)
    local v6 = dot2(v5, v5)
    local v7 = v6 * invsqrt2(v6)

    if v6 == 0 then
        v7 = 0
    end

    if not (v7 > 1.52587890625E-05) then
        return rt.copy(IDENTITY)
    end

    local v8 = 1 / v7
    local v9 = v8 * (-v8 * v7 + 1) + v8
    local v10 = v9 * (-v9 * v7 + 1) + v9
    local t2 = {
        v5[1] * v10,
        v5[2] * v10,
        v5[3] * v10,
        v5[4] * v10
    }
    local v11 = normalize(p8)

    return {
        t2,
        v11,
        normalize(cross2(t2, v11)),
        rt.copy(ZERO)
    }
end

return t1
