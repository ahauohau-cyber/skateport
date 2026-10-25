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

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_core/air/trajectory/math")
local v9 = import("skate_core/air/trajectory/grind_surface/orientation")
local cross, dot, sub = v8.cross, v8.dot, v8.sub

local function grind_surface() -- line: 36
    -- upvalues: import (copy)
    return import("skate_core/air/trajectory/grind_surface")
end

local t1 = {
    LandingOrientation = {}
}

function t1.update_landing_orientation(p4, p5, p6, p7, p8) -- line: 64
    -- upvalues: rt (copy), import (copy), v9 (copy), cross (copy), dot (copy), sub (copy), t1 (copy)
    local v10 = import("skate_core/air/trajectory/grind_surface")
    local GeometryType, GrindSurface = v10.GeometryType, v10.GrindSurface

    if p4 ~= nil then
        if bit32.band(p4.flags, GrindSurface.INVALID) == 0 then
            rt.assign(p7, v9.tilted_normal(p4.direction, p4.upmost_normal, p4.normal_limits))
            p8.kind = p4.kind
            p8.garbage = false
            p8.high_side = rt.copy(p4.high_side)

            local v11 = cross(p4.upmost_normal, p4.direction)

            if p4.kind == GeometryType.ThinRail then
                p8.boardslide_dir = rt.copy(v11)

                local v12 = if dot(v11, sub(p5, p6)) > 0 then rt.copy(v11) else t1.negate(v11)
                local v13 = cross(v12, p4.upmost_normal)

                p8.tipslide_dir = v9.rotate(v13, v12, 0.3490658700466156)
                p8.backslash_dir = v9.rotate(v13, v12, 2.4085545539855957)
            else
                local v14 = cross(v11, p4.upmost_normal)

                if p4.kind == GeometryType.FatRail then
                    p8.boardslide_dir = rt.copy(v11)
                else
                    p8.boardslide_dir = cross(p7, p4.direction)
                end

                local v15 = if dot(v11, p4.high_side) > 0 then 1 else -1

                p8.backslash_dir = v9.rotate({
                    v14[1] * v15,
                    v14[2] * v15,
                    v14[3] * v15,
                    v14[4] * v15
                }, {
                    v11[1] * v15,
                    v11[2] * v15,
                    v11[3] * v15,
                    v11[4] * v15
                }, 0.7330383062362671)
                p8.tipslide_dir = v9.rotate({
                    v14[1] * -v15,
                    v14[2] * -v15,
                    v14[3] * -v15,
                    v14[4] * -v15
                }, {
                    v11[1] * -v15,
                    v11[2] * -v15,
                    v11[3] * -v15,
                    v11[4] * -v15
                }, 0.3490658700466156)
            end
        else
            local t2 = {
                1, 0, 0, 0
            }

            rt.assign(p7, { 0, 1, 0, 0 })
            p8.kind = GeometryType.ThinRail
            p8.garbage = true
            p8.boardslide_dir = rt.copy(t2)
            p8.tipslide_dir = rt.copy(t2)
            p8.backslash_dir = t1.negate(t2)
            p8.high_side = rt.copy(t2)
        end
    else
        p8.kind = GeometryType.Impossible
        p8.garbage = true
    end
end

function t1.negate(p9) -- line: 119
    -- upvalues: v1 (copy)
    local v16 = p9[1]
    local v17

    if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
        local v18 = math.abs(v16) * 7.1362384635298E+44
        local v19 = math.floor(v18)
        local v20 = v18 - v19

        v17 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

        if v16 < 0 then
            v17 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v16)
        v17 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v17, 2147483648)))

    local v22 = buffer.readf32(v1, 0)
    local v23 = p9[2]
    local v24

    if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
        local v25 = math.abs(v23) * 7.1362384635298E+44
        local v26 = math.floor(v25)
        local v27 = v25 - v26

        v24 = if v27 > 0.5 or v27 == 0.5 and v26 % 2 == 1 then v26 + 1 else v26

        if v23 < 0 then
            v24 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v23)
        v24 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v24, 2147483648)))

    local v29 = buffer.readf32(v1, 0)
    local v30 = p9[3]
    local v31

    if v30 ~= 0 and v30 > -1.1754943508222875E-38 and v30 < 1.1754943508222875E-38 then
        local v32 = math.abs(v30) * 7.1362384635298E+44
        local v33 = math.floor(v32)
        local v34 = v32 - v33

        v31 = if v34 > 0.5 or v34 == 0.5 and v33 % 2 == 1 then v33 + 1 else v33

        if v30 < 0 then
            v31 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v30)
        v31 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v31, 2147483648)))

    local v36 = buffer.readf32(v1, 0)
    local v37 = p9[4]
    local v38

    if v37 ~= 0 and v37 > -1.1754943508222875E-38 and v37 < 1.1754943508222875E-38 then
        local v39 = math.abs(v37) * 7.1362384635298E+44
        local v40 = math.floor(v39)
        local v41 = v39 - v40

        v38 = if v41 > 0.5 or v41 == 0.5 and v40 % 2 == 1 then v40 + 1 else v40

        if v37 < 0 then
            v38 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v37)
        v38 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v38, 2147483648)))

    return {
        v22,
        v29,
        v36,
        (buffer.readf32(v1, 0))
    }
end

return t1
