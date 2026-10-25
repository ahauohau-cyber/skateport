-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/math")
local v2 = import("skate_core/physics/board_ground")
local v3 = import("skate_core/physics/board_motion_output")
local v4 = import("skate_core/physics/native_arithmetic")
local inverse_length_squared = v3.inverse_length_squared
local t1 = {
    AirMath = {}
}

function t1.AirMath.minimum_vminfp(_, p2, p3) -- line: 22
    -- upvalues: v4 (copy)
    return v4.vector_min(p2, p3)
end

function t1.AirMath.length_squared_vmsum3fp(_, p5) -- line: 26
    -- upvalues: v4 (copy)
    return v4.dot3(p5, p5)
end

function t1.AirMath.length_vmsum3fp_vrsqrte(_, p7) -- line: 30
    -- upvalues: v4 (copy), inverse_length_squared (copy)
    local v5 = v4.dot3(p7, p7)
    local v6 = v5 * inverse_length_squared(v5, 2)

    if v5 == 0 then
        return 0
    end

    return v6
end

function t1.AirMath.clamp_vector_within_max_length(p8, p9, p10) -- line: 36
    -- upvalues: v4 (copy), t1 (copy)
    local v7 = t1.AirMath.length_vmsum3fp_vrsqrte(p8, p9)

    if not (v7 >= 1.52587890625E-05) then
        return p9
    end

    local v8 = if p10 - v7 >= -0 then v7 else p10
    local v9 = v4.reciprocal_estimate(v7)
    local v10 = v9 * (-v9 * v7 + 1) + v9
    local v11 = v10 * (-v10 * v7 + 1) + v10

    return {
        p9[1] * v8 * v11,
        p9[2] * v8 * v11,
        p9[3] * v8 * v11,
        p9[4] * v8 * v11
    }
end

function t1.angle_between_vectors(p11, p12) -- line: 56
    -- upvalues: v1 (copy), v2 (copy)
    local function xyz(p13) -- line: 57
        -- upvalues: v1 (copy)
        return v1.Vector3.new(p13[1], p13[2], p13[3])
    end

    return v2.angle_between(v1.Vector3.new(p11[1], p11[2], p11[3]), xyz(p12))
end

function t1.clamp_jump_velocity(p14, p15) -- line: 65
    -- upvalues: t1 (copy)
    local v12 = t1.AirMath.length_vmsum3fp_vrsqrte({}, p14)
    local v13 = t1.AirMath.length_vmsum3fp_vrsqrte({}, p15)

    if not (v13 - 1 >= -0) then
        v13 = 1
    end

    local v14 = if v12 < v13 then v12 / v13 else 1

    return {
        p15[1] * v14,
        p15[2] * v14,
        p15[3] * v14,
        p15[4] * v14
    }
end

return t1
