-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = require(sim.import)("skate_core/physics/triangle_query")
local cross, dot, sub = v1.cross, v1.dot, v1.sub
local t1 = {
    Fraction = {}
}

function t1.Fraction.value(p1) -- line: 16
    return p1.numerator / p1.denominator
end

function t1.Fraction.before(p2, p3) -- line: 19
    return p2.numerator * p3.denominator < p3.numerator * p2.denominator
end

t1.Root = {}

function t1.sphere(p4, p5, p6, p7) -- line: 26
    -- upvalues: cross (copy), dot (copy), sub (copy)
    local v2 = sub(p6, p4)
    local v3 = p7 * p7

    if dot(v2, v2) < v3 then
        return {
            tag = "Hit",
            {
                numerator = 0,
                denominator = 1
            }
        }
    end

    local v4 = dot(v2, p5)

    if not (v4 > 0) then
        return {
            tag = "Away"
        }
    end

    local v5 = dot(p5, p5)
    local v6 = cross(v2, p5)
    local v7 = v5 * v3 + -dot(v6, v6)

    if not (v7 < 0) then
        local v8 = v4 - v5

        if not (v8 > 0 and v7 < v8 * v8) then
            return {
                tag = "Hit",
                {
                    numerator = v4 - math.sqrt(v7),
                    denominator = v5
                }
            }
        end
    end

    return {
        tag = "Miss"
    }
end

function t1.cylinder(p8, p9, p10, p11, p12) -- line: 52
    -- upvalues: cross (copy), dot (copy), sub (copy)
    local v9 = cross(sub(p10, p8), p11)
    local v10 = dot(v9, v9)
    local v11 = dot(p11, p11) * p12 * p12

    if v10 < v11 then
        return {
            tag = "Hit",
            {
                numerator = 0,
                denominator = 1
            }
        }
    end

    local v12 = cross(p9, p11)
    local v13 = dot(v9, v12)

    if not (v13 > 0) then
        return {
            tag = "Away"
        }
    end

    local v14 = dot(v12, v12)
    local v15 = v13 * v13 + -(v14 * v10)
    local v16 = v14 * v11 + v15

    if not (v16 < 0) then
        local v17 = v13 - v14

        if v17 < 0 or v17 * v17 < v16 then
            return {
                tag = "Hit",
                {
                    numerator = v13 - math.sqrt(v16),
                    denominator = v14
                }
            }
        end
    end

    return {
        tag = "Miss"
    }
end

function t1.sphere_xyz(p13, p14, p15, p16, p17, p18, p19, p20, p21, p22) -- line: 86
    local v18 = p19 - p13
    local v19 = p20 - p14
    local v20 = p21 - p15
    local v21 = p22 * p22

    if v18 * v18 + v19 * v19 + v20 * v20 < v21 then
        return 2, 0, 1
    end

    local v22 = v18 * p16 + v19 * p17 + v20 * p18

    if not (v22 > 0) then
        return 0, 0, 0
    end

    local v23 = p16 * p16 + p17 * p17 + p18 * p18
    local v24 = -v20 * p17 + v19 * p18
    local v25 = -v18 * p18 + v20 * p16
    local v26 = -v19 * p16 + v18 * p17
    local v27 = v23 * v21 + -(v24 * v24 + v25 * v25 + v26 * v26)

    if not (v27 < 0) then
        local v28 = v22 - v23

        if not (v28 > 0 and v27 < v28 * v28) then
            return 2, v22 - math.sqrt(v27), v23
        end
    end

    return 1, 0, 0
end

function t1.cylinder_xyz(p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35) -- line: 116
    local v29 = p29 - p23
    local v30 = p30 - p24
    local v31 = p31 - p25
    local v32 = -v31 * p33 + v30 * p34
    local v33 = -v29 * p34 + v31 * p32
    local v34 = -v30 * p32 + v29 * p33
    local v35 = v32 * v32 + v33 * v33 + v34 * v34
    local v36 = (p32 * p32 + p33 * p33 + p34 * p34) * p35 * p35

    if v35 < v36 then
        return 2, 0, 1
    end

    local v37 = -p28 * p33 + p27 * p34
    local v38 = -p26 * p34 + p28 * p32
    local v39 = -p27 * p32 + p26 * p33
    local v40 = v32 * v37 + v33 * v38 + v34 * v39

    if not (v40 > 0) then
        return 0, 0, 0
    end

    local v41 = v37 * v37 + v38 * v38 + v39 * v39
    local v42 = v40 * v40 + -(v41 * v35)
    local v43 = v41 * v36 + v42

    if not (v43 < 0) then
        local v44 = v40 - v41

        if v44 < 0 or v44 * v44 < v43 then
            return 2, v40 - math.sqrt(v43), v41
        end
    end

    return 1, 0, 0
end

return t1
