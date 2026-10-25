-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local v9 = require(sim.import)("skate_core/physics/native_arithmetic")

return {
    Settings = {},
    coefficients = function(p3, p4, p5) -- coefficients | line: 38
        -- upvalues: rt (copy), v1 (copy), v9 (copy)
        local v10 = rt.copy(p3)

        v10[1] *= p5.scale_x_acc

        local v11 = v9.dot3(v10, v10)
        local v12

        if v11 ~= 0 and v11 > -1.1754943508222875E-38 and v11 < 1.1754943508222875E-38 then
            local v13 = math.abs(v11) * 7.1362384635298E+44
            local v14 = math.floor(v13)
            local v15 = v13 - v14

            v12 = (if v15 > 0.5 or v15 == 0.5 and v14 % 2 == 1 then v14 + 1 else v14) * 1.401298464324817E-45

            if v11 < 0 then
                v12 = -v12
            end
        else
            buffer.writef32(v1, 0, v11)
            v12 = buffer.readf32(v1, 0)
        end

        local v16 = v9.reciprocal_square_root_estimate(v12)
        local v17 = v16 * 0.5 * (-v12 * (v16 * v16) + 1) + v16
        local v18 = v17 * 0.5 * (-v12 * (v17 * v17) + 1) + v17
        local v19 = if v12 == 0 then 0 else v12 * v18
        local v20 = rt.clamp((v19 - p5.min_bump_mag) / (p5.max_bump_mag - p5.min_bump_mag), 0, 1) * (1 - p5.min_bump_blend_value) + p5.min_bump_blend_value
        local t2 = if v19 > 9.999999974752427E-07 then {
            v10[1] * v18,
            v10[3] * v18
        } else { 0, 0 }
        local v21 = table.create(2)
        local v22 = t2[1] * v20

        v21[1] = if not p4 then v22 else -v22

        local v23 = t2[2] * v20

        v21[2] = if not p4 then v23 else -v23

        return v21
    end
}
