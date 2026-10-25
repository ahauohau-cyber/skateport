-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_core/physics/native_arithmetic")
local v3 = import("skate_core/physics/triangle_query")
local v4 = import("skate_core/physics/triangle_sweep_roots")
local Fraction = v4.Fraction
local dot, madd, scale, sub = v3.dot, v3.madd, v3.scale, v3.sub

local function triangle_sweep() -- line: 22
    -- upvalues: import (copy)
    return import("skate_core/physics/triangle_sweep")
end

local replaces, advance_fraction, inverse_radius
local t1 = {}

function t1.walk(p2, p3, p4, p5, p6, p7) -- line: 33
    -- upvalues: rt (copy), import (copy), v4 (copy), Fraction (copy), dot (copy), madd (copy), scale (copy), sub (copy), replaces (ref), advance_fraction (ref), inverse_radius (ref)
    local add = import("skate_core/physics/triangle_sweep").add
    local v5 = p3
    local v6 = p4
    local v7 = p6.region
    local v8 = rt.copy(p6.point)

    for _ = 0, 4 do
        local v9

        if v7 <= 2 then
            local v10 = v4.sphere(v5, v6, v8, p7)

            if v10.tag == "Away" then
                return false
            end

            local v11 = if v10.tag == "Miss" then nil else v10[1]
            local t2 = if v7 == 0 then {
                sub(p5[2], p5[1]),
                sub(p5[3], p5[1])
            }
                elseif v7 == 1 then {
                    sub(p5[1], p5[2]),
                    sub(p5[3], p5[2])
                }
                else {
                    sub(p5[1], p5[3]),
                    sub(p5[2], p5[3])
                }
            local v12 = v7
            local v13 = v11

            for i = 0, 1 do
                local v14 = t2[i + 1]
                local t3 = {
                    numerator = dot(sub(v8, v5), v14),
                    denominator = dot(v6, v14)
                }
                local v15, v16

                if replaces(v13, t3) then
                    v15 = t3
                    v16 = rt.idiv(v7 + (if i == 0 then 6 else 9), 2)
                else
                    v15 = v13
                    v16 = v12
                end

                v13 = v15
                v12 = v16
            end

            if v13 == nil then
                return false
            end

            v9 = Fraction.value(v13)

            if v12 <= 2 then
                advance_fraction(p2, v9)
                p2.position = madd(v6, v9, v5)
                p2.normal = scale(sub(p2.position, v8), inverse_radius(p7))
                p2.volume_parameter = {
                    if v7 == 1 then 1 else 0,
                    if v7 == 2 then 1 else 0,
                    0
                }

                return true
            end

            v7 = v12
        else
            local v19, v20

            if v7 == 3 then
                v19 = p5[1]
                v20 = sub(p5[2], p5[1])
            elseif v7 == 4 then
                v19 = p5[1]
                v20 = sub(p5[3], p5[1])
            else
                v19 = p5[2]
                v20 = sub(p5[3], p5[2])
            end

            local v21 = rt.copy(v19)
            local v22 = v4.cylinder(v5, v6, v19, v20, p7)

            if v22.tag == "Away" then
                return false
            end

            local v23 = if v22.tag == "Miss" then nil else v22[1]

            v8 = add(v19, v20)

            local v24 = {
                numerator = dot(sub(v8, v5), v20),
                denominator = dot(v6, v20)
            }
            local t5 = {
                numerator = dot(sub(v5, v19), v20),
                denominator = -v24.denominator
            }

            if replaces(v23, v24) then
                v7 = rt.idiv(v7, 2)
            else
                v8 = v21

                if replaces(v23, t5) then
                    v24 = t5
                    v7 = rt.idiv(v7 - 3, 2)
                else
                    v24 = v23
                end
            end

            if v24 == nil then
                return false
            end

            v9 = Fraction.value(v24)

            if v7 > 2 then
                advance_fraction(p2, v9)
                p2.position = madd(v6, v9, v5)

                local v25 = dot(sub(p2.position, v19), v20) * (1 / dot(v20, v20))
                local v26 = madd(v20, v25, v19)

                p2.normal = scale(sub(p2.position, v26), inverse_radius(p7))

                if v7 == 3 then
                    p2.volume_parameter = { v25, 0, 0 }
                elseif v7 == 4 then
                    p2.volume_parameter = { 0, v25, 0 }
                else
                    p2.volume_parameter = {
                        1 - v25,
                        v25,
                        0
                    }
                end

                return true
            end
        end

        advance_fraction(p2, v9)
        v5 = madd(v6, v9, v5)
        v6 = scale(v6, 1 - v9)

        if v9 > 1 then
            return false
        end
    end

    return true
end

local sphere_xyz, cylinder_xyz = v4.sphere_xyz, v4.cylinder_xyz
local Vector3 = import("skate_core/math").Vector3

buffer.writeu32(v1, 0, 2097152)

local v27 = buffer.readf32(v1, 0)

function t1.walk_xyz(p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20) -- line: 167
    -- upvalues: advance_fraction (ref), inverse_radius (ref), sphere_xyz (copy), cylinder_xyz (copy), Vector3 (copy), v27 (copy)
    local v28 = p15[1]
    local v29 = p15[2]
    local v30 = p15[3]
    local v31 = p9
    local v32 = p10
    local v33 = p11
    local v34 = p12
    local v35 = p13
    local v36 = p14
    local v37 = p16
    local v38 = p17
    local v39 = p18
    local v40 = p19

    for _ = 0, 4 do
        local v41

        if v37 <= 2 then
            local v42, v43, v44 = sphere_xyz(v31, v32, v33, v34, v35, v36, v38, v39, v40, p20)

            if v42 == 0 then
                return false
            end

            local v45 = v42 == 2
            local v46, v47
            local v48 = v30

            if v37 == 0 then
                v46 = v28
                v47 = v29
            else
                v47 = v28

                if v37 == 1 then
                    v46 = v29
                else
                    v48 = v29
                    v46 = v30
                end
            end

            local x, y, z = v46.x, v46.y, v46.z
            local v49 = v47.x - x
            local v50 = v47.y - y
            local v51 = v47.z - z
            local v52 = (v38 - v31) * v49 + (v39 - v32) * v50 + (v40 - v33) * v51
            local v53 = v34 * v49 + v35 * v50 + v36 * v51
            local v54, v55, v56, v57

            if not (v27 < v53) or not (v52 > 0) or v45 and v43 * v53 < v52 * v44 then
                v57 = v37
                v55 = v43
                v56 = v44
                v54 = v45
            else
                v55 = v52
                v56 = v53
                v54 = true
                v57 = (v37 + 6) // 2
            end

            local v58 = v48.x - x
            local v59 = v48.y - y
            local v60 = v48.z - z
            local v61 = (v38 - v31) * v58 + (v39 - v32) * v59 + (v40 - v33) * v60
            local v62 = v34 * v58 + v35 * v59 + v36 * v60
            local v63, v64, v65, v66

            if not (v27 < v62) or not (v61 > 0) or v54 and v55 * v62 < v61 * v56 then
                v66 = v57
                v64 = v55
                v65 = v56
                v63 = v54
            else
                v64 = v61
                v65 = v62
                v63 = true
                v66 = (v37 + 9) // 2
            end

            if not v63 then
                return false
            end

            v41 = v64 / v65

            if v66 <= 2 then
                advance_fraction(p8, v41)

                local v67 = v34 * v41 + v31
                local v68 = v35 * v41 + v32
                local v69 = v36 * v41 + v33

                p8.position = Vector3.new(v67, v68, v69)

                local v70 = inverse_radius(p20)

                p8.normal = Vector3.new((v67 - v38) * v70, (v68 - v39) * v70, (v69 - v40) * v70)
                p8.volume_parameter = {
                    if v37 == 1 then 1 else 0,
                    if v37 == 2 then 1 else 0,
                    0
                }

                return true
            end

            v37 = v66
        else
            local v74
            local v73 = v28

            if v37 == 3 then
                v74 = v29
            else
                v74 = v30

                if v37 ~= 4 then
                    v73 = v29
                end
            end

            local x, y, z = v73.x, v73.y, v73.z
            local v75 = v74.x - x
            local v76 = v74.y - y
            local v77 = v74.z - z
            local v78, v79, v80 = cylinder_xyz(v31, v32, v33, v34, v35, v36, x, y, z, v75, v76, v77, p20)

            if v78 == 0 then
                return false
            end

            local v81 = v78 == 2
            local v82 = x + v75
            local v83 = y + v76
            local v84 = z + v77
            local v85 = (v82 - v31) * v75 + (v83 - v32) * v76 + (v84 - v33) * v77
            local v86 = v34 * v75 + v35 * v76 + v36 * v77
            local v87 = (v31 - x) * v75 + (v32 - y) * v76 + (v33 - z) * v77
            local v88 = -v86
            local v89, v90, v91, v92, v93, v94, v95

            if v27 < v86 and v85 > 0 and (not v81 or not (v79 * v86 < v85 * v80)) then
                v95 = v86
                v93 = v37 // 2
                v90 = v82
                v91 = v83
                v92 = v84
                v89 = true
                v94 = v85
            else
                v90 = x
                v91 = y
                v92 = z

                if not (v27 < v88) or not (v87 > 0) or v81 and v79 * v88 < v87 * v80 then
                    v95 = v80
                    v93 = v37
                    v89 = v81
                    v94 = v79
                else
                    v95 = v88
                    v93 = (v37 - 3) // 2
                    v89 = true
                    v94 = v87
                end
            end

            if not v89 then
                return false
            end

            v41 = v94 / v95

            if v93 > 2 then
                advance_fraction(p8, v41)

                local v96 = v34 * v41 + v31
                local v97 = v35 * v41 + v32
                local v98 = v36 * v41 + v33

                p8.position = Vector3.new(v96, v97, v98)

                local v99 = ((v96 - x) * v75 + (v97 - y) * v76 + (v98 - z) * v77) * (1 / (v75 * v75 + v76 * v76 + v77 * v77))
                local v100 = v75 * v99 + x
                local v101 = v76 * v99 + y
                local v102 = v77 * v99 + z
                local v103 = inverse_radius(p20)

                p8.normal = Vector3.new((v96 - v100) * v103, (v97 - v101) * v103, (v98 - v102) * v103)

                if v93 == 3 then
                    p8.volume_parameter = { v99, 0, 0 }
                elseif v93 == 4 then
                    p8.volume_parameter = { 0, v99, 0 }
                else
                    p8.volume_parameter = {
                        1 - v99,
                        v99,
                        0
                    }
                end

                return true
            end

            v40 = v92
            v37 = v93
            v38 = v90
            v39 = v91
        end

        advance_fraction(p8, v41)
        v31 = v34 * v41 + v31
        v32 = v35 * v41 + v32
        v33 = v36 * v41 + v33

        local v104 = 1 - v41

        v34 *= v104
        v35 *= v104
        v36 *= v104

        if v41 > 1 then
            return false
        end
    end

    return true
end

function replaces(p21, p22) -- line: 311
    -- upvalues: import (copy), Fraction (copy)
    if p22.denominator > import("skate_core/physics/triangle_sweep").MIN_RECIPROCAL and p22.numerator > 0 then
        if p21 == nil then
            return true
        end

        return not Fraction.before(p21, p22)
    end

    return false
end

t1.replaces = replaces

function advance_fraction(p23, p24) -- line: 317
    p23.fraction = (1 - p23.fraction) * p24 + p23.fraction
end

t1.advance_fraction = advance_fraction

function inverse_radius(p25) -- line: 321
    -- upvalues: v2 (copy)
    local v105 = v2.reciprocal_estimate(p25)
    local v106 = v105 * (-v105 * p25 + 1) + v105

    return v106 * (-v106 * p25 + 1) + v106
end

t1.inverse_radius = inverse_radius

return t1
