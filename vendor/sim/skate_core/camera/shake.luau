-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local v1 = import("skate_core/camera/manager_state")
local v2 = import("skate_core/camera/vector_tracker")
local v3 = import("skate_core/trigonometry")
local v4 = import("skate_core/camera/shake_update")
local clamp = v1.clamp
local dot, length, refined_reciprocal = v2.dot, v2.length, v2.refined_reciprocal
local t1 = {
    ShakeSamples = {}
}

function t1.ShakeSamples.from_rows(p2) -- line: 33
    if #p2 == 0 then
        error("Stock camera shake has no samples", 0)
    end

    for _, v5 in ipairs(p2) do
        for _, v6 in ipairs(v5) do
            if v6 ~= v6 or v6 == 1e999 or v6 == (-1e999) then
                error("Stock camera shake contains a non-finite sample", 0)
            end
        end
    end

    local v7 = table.create(#p2)
    local v8 = table.create(#p2)
    local t2 = { 0, 0, 0, 0 }
    local t3 = { 0, 0, 0, 0 }

    for _, v9 in ipairs(p2) do
        local t4 = {
            v9[1],
            v9[2],
            v9[3],
            0
        }
        local t5 = {
            v9[5],
            v9[6],
            v9[7],
            0
        }
        local t6 = {}

        t6[1] = t2[1] + t4[1]
        t6[2] = t2[2] + t4[2]
        t6[3] = t2[3] + t4[3]
        t6[4] = t2[4] + t4[4]

        local t7 = {}

        t7[1] = t3[1] + t5[1]
        t7[2] = t3[2] + t5[2]
        t7[3] = t3[3] + t5[3]
        t7[4] = t3[4] + t5[4]
        t3 = t7
        table.insert(v7, t4)
        table.insert(v8, t5)
        t2 = t6
    end

    local v10 = 1 / #p2
    local t8 = {
        t2[1] * v10,
        t2[2] * v10,
        t2[3] * v10,
        t2[4] * v10
    }
    local t9 = {
        t3[1] * v10,
        t3[2] * v10,
        t3[3] * v10,
        t3[4] * v10
    }

    for i = 1, #v7 do
        local v11 = v7[i]
        local v12 = v8[i]
        local t10 = {}

        t10[1] = v11[1] - t8[1]
        t10[2] = v11[2] - t8[2]
        t10[3] = v11[3] - t8[3]
        t10[4] = v11[4] - t8[4]
        v7[i] = t10

        local t11 = {}

        t11[1] = v12[1] - t9[1]
        t11[2] = v12[2] - t9[2]
        t11[3] = v12[3] - t9[3]
        t11[4] = v12[4] - t9[4]
        v8[i] = t11
    end

    return {
        rotations = v7,
        translations = v8
    }
end

t1.ShakeSettings = {}
t1.ShakeEffect = {}

function t1.ShakeEffect.new() -- line: 102
    return {
        time = 0,
        impulse = 0,
        weight = 0,
        translation = { 0, 0, 0, 0 }
    }
end

function t1.ShakeEffect.landing_impulse(p3, p4, p5, p6) -- line: 107
    -- upvalues: v3 (copy), clamp (copy), dot (copy), length (copy), refined_reciprocal (copy)
    local v13 = length(p5)

    if v13 < 9.999999747378752E-06 then
        return false
    end

    local v14 = refined_reciprocal(v13)
    local t12 = {
        v14 * p5[1],
        v14 * p5[2],
        v14 * p5[3],
        v14 * p5[4]
    }
    local v15 = clamp(dot({
        -p4[1],
        -p4[2],
        -p4[3],
        -p4[4]
    }, t12), -1, 1)
    local v17 = v13 * (1 - clamp(v3.acos(v15) * 0.6366197466850281, 0, 1))

    if v17 <= 0 then
        return false
    end

    local v18 = clamp((v17 - p6.impulse_minimum_velocity) / (p6.impulse_maximum_velocity - p6.impulse_minimum_velocity), 0, 1)
    local v19 = v18 * v18 * p6.impulse_magnitude

    if p3.impulse < v19 then
        p3.impulse = v19

        return true
    end

    return false
end

for v20, v21 in v4.ShakeEffect do
    t1.ShakeEffect[v20] = v21
end

return t1
