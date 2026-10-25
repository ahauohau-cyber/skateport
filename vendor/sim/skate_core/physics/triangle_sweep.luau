-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_core/physics/native_arithmetic")
local closest = import("skate_core/physics/triangle_closest").closest
local v3 = import("skate_core/physics/triangle_query")
local v4 = import("skate_core/physics/triangle_sweep_walk")
local Vector3 = import("skate_core/math").Vector3
local cross, dot, madd, scale = v3.cross, v3.dot, v3.madd, v3.scale
local sub = v3.sub
local t1 = {}

buffer.writeu32(v1, 0, 2097152)
t1.MIN_RECIPROCAL = buffer.readf32(v1, 0)

local MIN_RECIPROCAL = t1.MIN_RECIPROCAL
local add, l1

function t1.sweep_reference(p2, p3, p4, p5, p6) -- line: 36
    -- upvalues: v2 (copy), closest (copy), v4 (copy), cross (copy), dot (copy), madd (copy), scale (copy), sub (copy), MIN_RECIPROCAL (copy), add (ref), l1 (ref)
    p2.fraction = 0

    local v5 = p5[1]
    local v6 = p5[2]
    local v7 = p5[3]
    local v8 = sub(v6, v5)
    local v9 = sub(v7, v5)
    local v10 = sub(p3, v5)
    local v11 = cross(p4, v9)
    local v12 = dot(v8, v11)
    local n1 = 1

    if v12 < 0 then
        v12 = -v12
        n1 = -1
    end

    if not (dot(p2.normal, v10) * n1 < -p6) then
        local v13 = dot(v10, v11) * n1
        local v14 = l1(v11) * p6

        if not (v13 < -v14 or v14 + v12 < v13) then
            local v15 = cross(v8, p4)
            local v16 = dot(v10, v15) * n1
            local v17 = l1(v15) * p6

            if not (v16 < -v17) and not (v17 + v12 < v16) and not (v16 + v13 > v14 + v17 + v12) then
                local v18

                if MIN_RECIPROCAL < v12 then
                    local v19 = sub(v10, scale(p2.normal, n1 * p6))
                    local v20 = -(dot(v19, cross(v9, v8)) * n1)

                    if v12 < v20 then
                        return false
                    end

                    if v20 < 0 then
                        v18 = p4
                    else
                        local v21 = 1 / v12

                        p2.fraction = v21 * v20

                        local v22 = dot(v19, v11) * n1

                        if not (v22 < 0) and not (v12 < v22) then
                            local v23 = dot(v19, v15) * n1

                            if not (v23 < 0) and not (v12 < v23 + v22) then
                                p2.position = madd(p4, p2.fraction, p3)
                                p2.normal = scale(p2.normal, n1)
                                p2.volume_parameter = {
                                    v21 * v22,
                                    v21 * v23,
                                    0
                                }

                                return true
                            end
                        end

                        v10 = madd(p4, p2.fraction, v10)
                        v18 = scale(p4, 1 - p2.fraction)
                    end
                else
                    v18 = p4
                end

                local v24 = add(v10, v5)
                local v25 = closest(v24, p5)
                local v26 = sub(v24, v25.point)
                local v27 = dot(v26, v26)
                local v28 = p6 * p6 + -v27

                if v28 > 0 then
                    p2.position = v24

                    if v27 > 0 then
                        local v29 = v2.reciprocal_square_root_estimate(v27)

                        p2.normal = scale(v26, v29 * 0.5 * (-v27 * (v29 * v29) + 1) + v29)
                    end

                    p2.volume_parameter = {
                        v25.u,
                        v25.v,
                        v28
                    }
                else
                    if v25.region ~= 6 then
                        return v4.walk(p2, v24, v18, p5, v25, p6)
                    end

                    p2.position = v24

                    if v12 < 0 then
                        p2.normal = scale(p2.normal, -1)
                    end

                    p2.volume_parameter = {
                        v25.u,
                        v25.v,
                        0
                    }
                end

                return true
            end
        end
    end

    return false
end

local function sweep_core_r3(p7, p8, p9, p10, p11, p12, p13, p14, p15) -- line: 132
    -- upvalues: v2 (copy), closest (copy), v4 (copy), Vector3 (copy), MIN_RECIPROCAL (copy)
    p7.fraction = 0

    local v31 = p10[1]
    local v32 = p10[2]
    local v33 = p10[3]
    local x, y, z = v31.x, v31.y, v31.z
    local v34 = v32.x - x
    local v35 = v32.y - y
    local v36 = v32.z - z
    local v37 = v33.x - x
    local v38 = v33.y - y
    local v39 = v33.z - z
    local v40 = p8.x - x
    local v41 = p8.y - y
    local v42 = p8.z - z
    local x2, y2, z2 = p9.x, p9.y, p9.z
    local v43 = -z2 * v38 + y2 * v39
    local v44 = -x2 * v39 + z2 * v37
    local v45 = -y2 * v37 + x2 * v38
    local v46 = v34 * v43 + v35 * v44 + v36 * v45
    local n2 = 1

    if v46 < 0 then
        v46 = -v46
        n2 = -1
    end

    if (p12 * v40 + p13 * v41 + p14 * v42) * n2 < -p11 then
        return false
    end

    local v47 = (v40 * v43 + v41 * v44 + v42 * v45) * n2
    local v48 = (math.abs(v44) + math.abs(v45) + math.abs(v43)) * p11

    if v47 < -v48 or v48 + v46 < v47 then
        return false
    end

    local v49 = -v36 * y2 + v35 * z2
    local v50 = -v34 * z2 + v36 * x2
    local v51 = -v35 * x2 + v34 * y2
    local v52 = (v40 * v49 + v41 * v50 + v42 * v51) * n2
    local v53 = (math.abs(v50) + math.abs(v51) + math.abs(v49)) * p11

    if v52 < -v53 or v53 + v46 < v52 or v52 + v47 > v48 + v53 + v46 then
        return false
    end

    if p15 then
        p7.normal = Vector3.new(p12, p13, p14)
    end

    local v54

    if MIN_RECIPROCAL < v46 then
        local v55 = n2 * p11
        local v56 = v40 - p12 * v55
        local v57 = v41 - p13 * v55
        local v58 = v42 - p14 * v55
        local v59 = -v39 * v35 + v38 * v36
        local v60 = -v37 * v36 + v39 * v34
        local v61 = -v38 * v34 + v37 * v35
        local v62 = -((v56 * v59 + v57 * v60 + v58 * v61) * n2)

        if v46 < v62 then
            return false
        end

        if v62 < 0 then
            v54 = p9
        else
            local v63 = 1 / v46
            local v64 = v63 * v62

            p7.fraction = v64

            local v65 = (v56 * v43 + v57 * v44 + v58 * v45) * n2

            if not (v65 < 0) and not (v46 < v65) then
                local v66 = (v56 * v49 + v57 * v50 + v58 * v51) * n2

                if not (v66 < 0) and not (v46 < v66 + v65) then
                    p7.position = Vector3.new(x2 * v64 + p8.x, y2 * v64 + p8.y, z2 * v64 + p8.z)
                    p7.normal = Vector3.new(p12 * n2, p13 * n2, p14 * n2)
                    p7.volume_parameter = {
                        v63 * v65,
                        v63 * v66,
                        0
                    }

                    return true
                end
            end

            v40 = x2 * v64 + v40
            v41 = y2 * v64 + v41
            v42 = z2 * v64 + v42

            local v67 = 1 - v64

            v54 = Vector3.new(x2 * v67, y2 * v67, z2 * v67)
        end
    else
        v54 = p9
    end

    local v68 = Vector3.new(v40 + x, v41 + y, v42 + z)
    local v69 = closest(v68, p10)
    local point = v69.point
    local v70 = v68.x - point.x
    local v71 = v68.y - point.y
    local v72 = v68.z - point.z
    local v73 = v70 * v70 + v71 * v71 + v72 * v72
    local v74 = p11 * p11 + -v73

    if v74 > 0 then
        p7.position = v68

        if v73 > 0 then
            local v75 = v2.reciprocal_square_root_estimate(v73)
            local v76 = v75 * 0.5 * (-v73 * (v75 * v75) + 1) + v75

            p7.normal = Vector3.new(v70 * v76, v71 * v76, v72 * v76)
        end

        p7.volume_parameter = {
            v69.u,
            v69.v,
            v74
        }
    else
        if v69.region ~= 6 then
            return v4.walk(p7, v68, v54, p10, v69, p11)
        end

        p7.position = v68

        if v46 < 0 then
            p7.normal = Vector3.new(p12 * -1, p13 * -1, p14 * -1)
        end

        p7.volume_parameter = {
            v69.u,
            v69.v,
            0
        }
    end

    return true
end

local v77 = false

function t1.set_sweep_r3(p16) -- line: 257
    -- upvalues: v77 (ref)
    local v78 = v77

    v77 = p16

    return v78
end

local closest_xyz = import("skate_core/physics/triangle_closest").closest_xyz
local walk_xyz = v4.walk_xyz
local inverse_length = v3.inverse_length

local function sweep_core(p17, p18, p19, p20, p21, p22, p23, p24, p25, p26) -- line: 265
    -- upvalues: v2 (copy), Vector3 (copy), MIN_RECIPROCAL (copy), sweep_core_r3 (copy), v77 (ref), closest_xyz (copy), walk_xyz (copy), inverse_length (copy)
    if v77 then
        return sweep_core_r3(p17, p18, p19, p20, p21, p22, p23, p24, p25)
    end

    local v79 = p22 == nil

    p17.fraction = 0

    local v80 = p20[1]
    local v81 = p20[2]
    local v82 = p20[3]
    local x, y, z = v80.x, v80.y, v80.z
    local v83 = v81.x - x
    local v84 = v81.y - y
    local v85 = v81.z - z
    local v86 = v82.x - x
    local v87 = v82.y - y
    local v88 = v82.z - z
    local v89 = p18.x - x
    local v90 = p18.y - y
    local v91 = p18.z - z
    local x2, y2, z2 = p19.x, p19.y, p19.z
    local v92 = -z2 * v87 + y2 * v88
    local v93 = -x2 * v88 + z2 * v86
    local v94 = -y2 * v86 + x2 * v87
    local v95 = v83 * v92 + v84 * v93 + v85 * v94
    local n3 = 1

    if v95 < 0 then
        v95 = -v95
        n3 = -1
    end

    if not v79 and (p22 * v89 + p23 * v90 + p24 * v91) * n3 < -p21 then
        return false
    end

    local v96 = (v89 * v92 + v90 * v93 + v91 * v94) * n3
    local v97 = (math.abs(v93) + math.abs(v94) + math.abs(v92)) * p21

    if not (v96 < -v97 or v97 + v95 < v96) then
        local v98 = -v85 * y2 + v84 * z2
        local v99 = -v83 * z2 + v85 * x2
        local v100 = -v84 * x2 + v83 * y2
        local v101 = (v89 * v98 + v90 * v99 + v91 * v100) * n3
        local v102 = (math.abs(v99) + math.abs(v100) + math.abs(v98)) * p21

        if not (v101 < -v102) and not (v102 + v95 < v101) and not (v101 + v96 > v97 + v102 + v95) then
            local v103, v104, v105, v106

            if v79 then
                local v107 = x - v81.x
                local v108 = y - v81.y
                local v109 = z - v81.z
                local v110 = x - v82.x
                local v111 = y - v82.y
                local v112 = z - v82.z
                local v113 = -v109 * v111 + v108 * v112
                local v114 = -v107 * v112 + v109 * v110
                local v115 = -v108 * v110 + v107 * v111
                local v116 = inverse_length(v113 * v113 + v114 * v114 + v115 * v115)

                v103 = v113 * v116
                v104 = v114 * v116
                v105 = v115 * v116
                v106 = (v103 * v89 + v104 * v90 + v105 * v91) * n3 < -p21
            end

            if (not v79 or v106) and v79 then
                return false
            end

            if not v79 then
                v103 = p22
                v104 = p23
                v105 = p24
            end

            if p25 then
                if p26 then
                    local normal = p17.normal

                    normal.x = v103
                    normal.y = v104
                    normal.z = v105
                else
                    p17.normal = Vector3.new(v103, v104, v105)
                end
            end

            if MIN_RECIPROCAL < v95 then
                local v117 = n3 * p21
                local v118 = v89 - v103 * v117
                local v119 = v90 - v104 * v117
                local v120 = v91 - v105 * v117
                local v121 = -v88 * v84 + v87 * v85
                local v122 = -v86 * v85 + v88 * v83
                local v123 = -v87 * v83 + v86 * v84
                local v124 = -((v118 * v121 + v119 * v122 + v120 * v123) * n3)

                if v95 < v124 then
                    return false
                end

                if not (v124 < 0) then
                    local v125 = 1 / v95
                    local v126 = v125 * v124

                    p17.fraction = v126

                    local v127 = (v118 * v92 + v119 * v93 + v120 * v94) * n3

                    if not (v127 < 0) and not (v95 < v127) then
                        local v128 = (v118 * v98 + v119 * v99 + v120 * v100) * n3

                        if not (v128 < 0) and not (v95 < v128 + v127) then
                            p17.position = Vector3.new(x2 * v126 + p18.x, y2 * v126 + p18.y, z2 * v126 + p18.z)
                            p17.normal = Vector3.new(v103 * n3, v104 * n3, v105 * n3)
                            p17.volume_parameter = {
                                v125 * v127,
                                v125 * v128,
                                0
                            }

                            return true
                        end
                    end

                    v89 = x2 * v126 + v89
                    v90 = y2 * v126 + v90
                    v91 = z2 * v126 + v91

                    local v129 = 1 - v126

                    x2 *= v129
                    y2 *= v129
                    z2 *= v129
                end
            end

            local v130 = v89 + x
            local v131 = v90 + y
            local v132 = v91 + z
            local v133, v134, v135, v136, v137, v138 = closest_xyz(v130, v131, v132, p20)
            local v139 = v130 - v133
            local v140 = v131 - v134
            local v141 = v132 - v135
            local v142 = v139 * v139 + v140 * v140 + v141 * v141
            local v143 = p21 * p21 + -v142

            if v143 > 0 then
                p17.position = Vector3.new(v130, v131, v132)

                if v142 > 0 then
                    local v144 = v2.reciprocal_square_root_estimate(v142)
                    local v145 = v144 * 0.5 * (-v142 * (v144 * v144) + 1) + v144

                    p17.normal = Vector3.new(v139 * v145, v140 * v145, v141 * v145)
                end

                p17.volume_parameter = { v137, v138, v143 }
            else
                if v136 ~= 6 then
                    return walk_xyz(p17, v130, v131, v132, x2, y2, z2, p20, v136, v133, v134, v135, p21)
                end

                p17.position = Vector3.new(v130, v131, v132)

                if v95 < 0 then
                    p17.normal = Vector3.new(v103 * -1, v104 * -1, v105 * -1)
                end

                p17.volume_parameter = { v137, v138, 0 }
            end

            return true
        end
    end

    return false
end

function t1.sweep(p27, p28, p29, p30, p31) -- line: 404
    -- upvalues: sweep_core (copy)
    p27.fraction = 0

    local normal = p27.normal

    return sweep_core(p27, p28, p29, p30, p31, normal.x, normal.y, normal.z, false)
end

function t1.sweep_deferred_normal(p32, p33, p34, p35, p36, p37, p38, p39) -- line: 419
    -- upvalues: sweep_core (copy)
    return sweep_core(p32, p33, p34, p35, p36, p37, p38, p39, true)
end

function t1.sweep_lazy_normal(p40, p41, p42, p43, p44) -- line: 431
    -- upvalues: t1 (copy), v77 (ref), inverse_length (copy), sweep_core (copy)
    if not v77 then
        return sweep_core(p40, p41, p42, p43, p44, nil, nil, nil, true)
    end

    local v146 = p43[1]
    local v147 = p43[2]
    local v148 = p43[3]
    local x, y, z = v146.x, v146.y, v146.z
    local v149 = x - v147.x
    local v150 = y - v147.y
    local v151 = z - v147.z
    local v152 = x - v148.x
    local v153 = y - v148.y
    local v154 = z - v148.z
    local v155 = -v151 * v153 + v150 * v154
    local v156 = -v149 * v154 + v151 * v152
    local v157 = -v150 * v152 + v149 * v153
    local v158 = inverse_length(v155 * v155 + v156 * v156 + v157 * v157)

    return t1.sweep_deferred_normal(p40, p41, p42, p43, p44, v155 * v158, v156 * v158, v157 * v158)
end

function t1.sweep_lazy_normal_scratch(p45, p46, p47, p48, p49) -- line: 455
    -- upvalues: t1 (copy), v77 (ref), sweep_core (copy)
    if v77 then
        return t1.sweep_lazy_normal(p45, p46, p47, p48, p49)
    end

    return sweep_core(p45, p46, p47, p48, p49, nil, nil, nil, true, true)
end

function add(p50, p51) -- line: 462
    -- upvalues: Vector3 (copy)
    return Vector3.new(p50.x + p51.x, p50.y + p51.y, p50.z + p51.z)
end

t1.add = add

function l1(p52) -- line: 466
    return math.abs(p52.y) + math.abs(p52.z) + math.abs(p52.x)
end

t1.l1 = l1

return t1
