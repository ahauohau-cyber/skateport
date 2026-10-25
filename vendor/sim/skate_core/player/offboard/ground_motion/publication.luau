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

local v9 = require(sim.import)("skate_core/player/offboard/ground_motion/math")
local ZERO, sub, scale, madd = v9.ZERO, v9.sub, v9.scale, v9.madd
local dot, length, select = v9.dot, v9.length, v9.select

return {
    update = function(p3, p4) -- update | line: 43
        -- upvalues: rt (copy), v1 (copy), ZERO (copy), sub (copy), scale (copy), madd (copy), dot (copy), length (copy), select (copy)
        p3.published_frame_64 = rt.copy(p3.frame_0)

        if p3.correction_enabled_711 then
            local v10 = length(p3.correction_576)
            local v11

            if v10 ~= 0 and v10 > -1.1754943508222875E-38 and v10 < 1.1754943508222875E-38 then
                local v12 = math.abs(v10) * 7.1362384635298E+44
                local v13 = math.floor(v12)
                local v14 = v12 - v13

                v11 = (if v14 > 0.5 or v14 == 0.5 and v13 % 2 == 1 then v13 + 1 else v13) * 1.401298464324817E-45

                if v10 < 0 then
                    v11 = -v11
                end
            else
                buffer.writef32(v1, 0, v10)
                v11 = buffer.readf32(v1, 0)
            end

            if v11 <= 0.009999999776482582 then
                p3.correction_576 = rt.copy(ZERO)
                p3.correction_enabled_711 = false
            else
                local v15 = scale(p3.correction_576, 1 / v10)
                local v16 = v10 * -0.05000000074505806
                local v17 = select(-0.004999999888241291 - v16, v16, -0.004999999888241291)
                local v18 = dot(p4, v15)
                local v19 = select(v18 - v17, v17, v18)

                if -v10 < v19 then
                    p3.correction_576 = madd(v15, v19, p3.correction_576)
                else
                    p3.correction_576 = rt.copy(ZERO)
                    p3.correction_enabled_711 = false
                end
            end

            p3.published_frame_64[4] = sub(p3.published_frame_64[4], p3.correction_576)
        end
    end
}
