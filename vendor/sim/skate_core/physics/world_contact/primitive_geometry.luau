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

local import = require(sim.import)
local v8 = import("skate_core/math")
local v9 = import("skate_core/physics/reciprocal_sqrt")
local v10 = import("skate_core/physics/world_contact/prism_math")
local Vector3 = v8.Vector3
local estimate = v9.estimate
local dot, sub, scale, madd = v10.dot, v10.sub, v10.scale, v10.madd
local cross, reciprocal = v10.cross, v10.reciprocal
local t1 = {
    ContactPrimitive = {}
}
local refined_inverse, put

local function triangle_from_volume_reference(p3, p4, p5, p6) -- line: 59
    -- upvalues: rt (copy), dot (copy), sub (copy), scale (copy), cross (copy), reciprocal (copy), t1 (copy), refined_inverse (ref)
    local t2 = {
        t1.lanes(p3[1], 1),
        t1.lanes(p3[2], 1),
        t1.lanes(p3[3], 1)
    }
    local v11 = cross(sub(t2[2], t2[1]), sub(t2[3], t2[1]))
    local v12 = dot(v11, v11)

    if v12 > 1.1920928955078125E-07 then
        v11 = scale(v11, refined_inverse(v12))
    end

    local t3 = {
        sub(t2[3], t2[1]),
        sub(t2[2], t2[3]),
        sub(t2[1], t2[2])
    }
    local t4 = {
        refined_inverse(dot(t3[1], t3[1])),
        refined_inverse(dot(t3[2], t3[2])),
        refined_inverse(dot(t3[3], t3[3]))
    }

    return {
        vertices = rt.copy(p3),
        feature = {
            normal = t1.xyz(v11),
            edges = {
                t1.xyz(scale(t3[1], t4[1])),
                t1.xyz(scale(t3[2], t4[2])),
                t1.xyz(scale(t3[3], t4[3]))
            },
            flags = bit32.band(p6, 4294967293),
            edge_cosines = rt.copy(p5)
        },
        edge_lengths = {
            reciprocal(t4[1]),
            reciprocal(t4[2]),
            reciprocal(t4[3])
        },
        fatness = p4
    }
end

t1.triangle_from_volume_reference = triangle_from_volume_reference

function t1.triangle_from_volume(p7, p8, p9, p10) -- line: 110
    -- upvalues: rt (copy), Vector3 (copy), reciprocal (copy), refined_inverse (ref)
    local v13 = p7[1]
    local v14 = p7[2]
    local v15 = p7[3]
    local x, y, z = v13.x, v13.y, v13.z
    local x2, y2, z2 = v14.x, v14.y, v14.z
    local x3, y3, z3 = v15.x, v15.y, v15.z
    local v16 = x2 - x
    local v17 = y2 - y
    local v18 = z2 - z
    local v19 = x3 - x
    local v20 = y3 - y
    local v21 = z3 - z
    local v22 = -v18 * v20 + v17 * v21
    local v23 = -v16 * v21 + v18 * v19
    local v24 = -v17 * v19 + v16 * v20
    local v25 = v22 * v22 + v23 * v23 + v24 * v24

    if v25 > 1.1920928955078125E-07 then
        local v26 = refined_inverse(v25)

        v22 *= v26
        v23 *= v26
        v24 *= v26
    end

    local v27 = x3 - x
    local v28 = y3 - y
    local v29 = z3 - z
    local v30 = x2 - x3
    local v31 = y2 - y3
    local v32 = z2 - z3
    local v33 = x - x2
    local v34 = y - y2
    local v35 = z - z2
    local v36 = refined_inverse(v27 * v27 + v28 * v28 + v29 * v29)
    local v37 = refined_inverse(v30 * v30 + v31 * v31 + v32 * v32)
    local v38 = refined_inverse(v33 * v33 + v34 * v34 + v35 * v35)

    return {
        vertices = rt.copy(p7),
        feature = {
            normal = Vector3.new(v22, v23, v24),
            edges = {
                Vector3.new(v27 * v36, v28 * v36, v29 * v36),
                Vector3.new(v30 * v37, v31 * v37, v32 * v37),
                Vector3.new(v33 * v38, v34 * v38, v35 * v38)
            },
            flags = bit32.band(p10, 4294967293),
            edge_cosines = rt.copy(p9)
        },
        edge_lengths = {
            reciprocal(v36),
            reciprocal(v37),
            reciprocal(v38)
        },
        fatness = p8
    }
end

function t1.transform_triangle_volume_reference(p11, p12, p13, p14, p15, p16) -- line: 158
    -- upvalues: scale (copy), madd (copy), t1 (copy), triangle_from_volume_reference (copy)
    local v39 = triangle_from_volume_reference(p11, p12, p13, p14)
    local v40 = table.create(3)

    for i = 1, 3 do
        local v41 = p15.columns[i]

        v40[i] = {
            v41[1],
            v41[2],
            v41[3],
            0
        }
    end

    local v42 = table.create(3)

    for i = 1, 3 do
        local v43 = p11[i]

        v42[i] = t1.xyz(madd(v40[3], v43.z, madd(v40[2], v43.y, madd(v40[1], v43.x, t1.lanes(p16, 1)))))
    end

    local normal = v39.feature.normal
    local v44 = t1.xyz(madd(v40[3], normal.z, madd(v40[2], normal.y, scale(v40[1], normal.x))))
    local v45 = triangle_from_volume_reference(v42, p12, p13, p14)

    v45.feature.normal = v44

    return v45
end

function t1.transform_triangle_volume(p17, p18, p19, p20, p21, p22) -- line: 186
    -- upvalues: Vector3 (copy), t1 (copy), refined_inverse (ref)
    local v46 = p17[1]
    local v47 = p17[2]
    local v48 = p17[3]
    local x, y, z = v46.x, v46.y, v46.z
    local x2, y2, z2 = v47.x, v47.y, v47.z
    local x3, y3, z3 = v48.x, v48.y, v48.z
    local v49 = x2 - x
    local v50 = y2 - y
    local v51 = z2 - z
    local v52 = x3 - x
    local v53 = y3 - y
    local v54 = z3 - z
    local v55 = -v51 * v53 + v50 * v54
    local v56 = -v49 * v54 + v51 * v52
    local v57 = -v50 * v52 + v49 * v53
    local v58 = v55 * v55 + v56 * v56 + v57 * v57

    if v58 > 1.1920928955078125E-07 then
        local v59 = refined_inverse(v58)

        v55 *= v59
        v56 *= v59
        v57 *= v59
    end

    local columns = p21.columns
    local v60 = columns[1]
    local v61 = columns[2]
    local v62 = columns[3]
    local v63 = v60[1]
    local v64 = v60[2]
    local v65 = v60[3]
    local v66 = v61[1]
    local v67 = v61[2]
    local v68 = v61[3]
    local v69 = v62[1]
    local v70 = v62[2]
    local v71 = v62[3]
    local x4, y4, z4 = p22.x, p22.y, p22.z
    local t5 = {
        Vector3.new(v69 * z + (v66 * y + (v63 * x + x4)), v70 * z + (v67 * y + (v64 * x + y4)), v71 * z + (v68 * y + (v65 * x + z4))),
        Vector3.new(v69 * z2 + (v66 * y2 + (v63 * x2 + x4)), v70 * z2 + (v67 * y2 + (v64 * x2 + y4)), v71 * z2 + (v68 * y2 + (v65 * x2 + z4))),
        Vector3.new(v69 * z3 + (v66 * y3 + (v63 * x3 + x4)), v70 * z3 + (v67 * y3 + (v64 * x3 + y4)), v71 * z3 + (v68 * y3 + (v65 * x3 + z4)))
    }
    local v72 = Vector3.new(v69 * v57 + (v66 * v56 + v63 * v55), v70 * v57 + (v67 * v56 + v64 * v55), v71 * v57 + (v68 * v56 + v65 * v55))
    local v73 = t1.triangle_from_volume(t5, p18, p19, p20)

    v73.feature.normal = v72

    return v73
end

function refined_inverse(p23) -- line: 242
    -- upvalues: estimate (copy)
    local v74 = estimate(p23)

    return v74 * 0.5 * (-p23 * (v74 * v74) + 1) + v74
end

function t1.transform_triangle_volume_into(p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36, p37, p38, p39, p40) -- line: 254
    -- upvalues: reciprocal (copy), refined_inverse (ref)
    local v75 = p25[1]
    local v76 = p25[2]
    local v77 = p25[3]
    local x, y, z = v75.x, v75.y, v75.z
    local x2, y2, z2 = v76.x, v76.y, v76.z
    local x3, y3, z3 = v77.x, v77.y, v77.z
    local v78 = x2 - x
    local v79 = y2 - y
    local v80 = z2 - z
    local v81 = x3 - x
    local v82 = y3 - y
    local v83 = z3 - z
    local v84 = -v80 * v82 + v79 * v83
    local v85 = -v78 * v83 + v80 * v81
    local v86 = -v79 * v81 + v78 * v82
    local v87 = v84 * v84 + v85 * v85 + v86 * v86

    if v87 > 1.1920928955078125E-07 then
        local v88 = refined_inverse(v87)

        v84 *= v88
        v85 *= v88
        v86 *= v88
    end

    local v89 = p35 * z + (p32 * y + (p29 * x + p38))
    local v90 = p36 * z + (p33 * y + (p30 * x + p39))
    local v91 = p37 * z + (p34 * y + (p31 * x + p40))
    local v92 = p35 * z2 + (p32 * y2 + (p29 * x2 + p38))
    local v93 = p36 * z2 + (p33 * y2 + (p30 * x2 + p39))
    local v94 = p37 * z2 + (p34 * y2 + (p31 * x2 + p40))
    local v95 = p35 * z3 + (p32 * y3 + (p29 * x3 + p38))
    local v96 = p36 * z3 + (p33 * y3 + (p30 * x3 + p39))
    local v97 = p37 * z3 + (p34 * y3 + (p31 * x3 + p40))
    local v98 = v95 - v89
    local v99 = v96 - v90
    local v100 = v97 - v91
    local v101 = v92 - v95
    local v102 = v93 - v96
    local v103 = v94 - v97
    local v104 = v89 - v92
    local v105 = v90 - v93
    local v106 = v91 - v94
    local v107 = refined_inverse(v98 * v98 + v99 * v99 + v100 * v100)
    local v108 = refined_inverse(v101 * v101 + v102 * v102 + v103 * v103)
    local v109 = refined_inverse(v104 * v104 + v105 * v105 + v106 * v106)
    local vertices = p24.vertices
    local v110 = vertices[1]

    v110.x = v89
    v110.y = v90
    v110.z = v91

    local v111 = vertices[2]

    v111.x = v92
    v111.y = v93
    v111.z = v94

    local v112 = vertices[3]

    v112.x = v95
    v112.y = v96
    v112.z = v97

    local feature = p24.feature
    local normal = feature.normal
    local v113 = p35 * v86 + (p32 * v85 + p29 * v84)
    local v114 = p36 * v86 + (p33 * v85 + p30 * v84)
    local v115 = p37 * v86 + (p34 * v85 + p31 * v84)

    normal.x = v113
    normal.y = v114
    normal.z = v115

    local edges = feature.edges
    local v116 = edges[1]
    local v117 = v98 * v107
    local v118 = v99 * v107
    local v119 = v100 * v107

    v116.x = v117
    v116.y = v118
    v116.z = v119

    local v120 = edges[2]
    local v121 = v101 * v108
    local v122 = v102 * v108
    local v123 = v103 * v108

    v120.x = v121
    v120.y = v122
    v120.z = v123

    local v124 = edges[3]
    local v125 = v104 * v109
    local v126 = v105 * v109
    local v127 = v106 * v109

    v124.x = v125
    v124.y = v126
    v124.z = v127
    feature.flags = bit32.band(p28, 4294967293)

    local edge_cosines = feature.edge_cosines
    local v128 = p27[1]
    local v129 = p27[2]
    local v130 = p27[3]

    edge_cosines[1] = v128
    edge_cosines[2] = v129
    edge_cosines[3] = v130

    local edge_lengths = p24.edge_lengths
    local v131 = reciprocal(v107)
    local v132 = reciprocal(v108)
    local v133 = reciprocal(v109)

    edge_lengths[1] = v131
    edge_lengths[2] = v132
    edge_lengths[3] = v133
    p24.fatness = p26

    return p24
end

function t1.pack_reference(p41) -- line: 328
    -- upvalues: v1 (copy), t1 (copy), put (ref)
    local v134 = table.create(48, 0)
    local v135, v136, v137, v138

    if p41.tag == "Sphere" then
        local v139 = p41[1]

        put(v134, 0, t1.lanes(v139.center, 1))
        v136 = "Sphere"
        v135 = v139.radius
        v137 = 0
        v138 = 1
    elseif p41.tag == "Capsule" then
        local center, axis, half_length = p41.center, p41.axis, p41.half_length

        put(v134, 0, t1.lanes(center, 1))
        put(v134, 16, t1.lanes(axis, 0))

        local v140

        if half_length == 0 then
            buffer.writef32(v1, 0, half_length)
            v140 = buffer.readu32(v1, 0)
        elseif half_length > -1.1754943508222875E-38 and half_length < 1.1754943508222875E-38 then
            local v141 = math.abs(half_length) * 7.1362384635298E+44

            v140 = math.floor(v141)

            local v142 = v141 - v140

            if v142 > 0.5 or v142 == 0.5 and v140 % 2 == 1 then
                v140 += 1
            end

            if half_length < 0 then
                v140 += 2147483648
            end
        else
            buffer.writef32(v1, 0, half_length)
            v140 = buffer.readu32(v1, 0)
        end

        v134[29] = v140
        v136 = "Capsule"
        v135 = p41.radius
        v137 = 65536
        v138 = 2
    elseif p41.tag == "Triangle" then
        local v143 = p41[1]

        put(v134, 0, t1.lanes(v143.vertices[1], 1))
        put(v134, 4, t1.lanes(v143.feature.normal, 0))
        put(v134, 8, t1.lanes(v143.vertices[2], 1))
        put(v134, 12, t1.lanes(v143.vertices[3], 1))

        for i = 0, 2 do
            put(v134, i * 4 + 16, t1.lanes(v143.feature.edges[i + 1], 0))

            local v144 = i + 28 + 1
            local v145 = v143.edge_lengths[i + 1]

            if v145 ~= 0 and v145 > -1.1754943508222875E-38 and v145 < 1.1754943508222875E-38 then
                local v146 = math.abs(v145) * 7.1362384635298E+44
                local v147 = math.floor(v146)
                local v148 = v146 - v147
                local v149 = if v148 > 0.5 or v148 == 0.5 and v147 % 2 == 1 then v147 + 1 else v147

                if v145 < 0 then
                    v134[v144] = v149 + 2147483648
                else
                    v134[v144] = v149
                end
            else
                buffer.writef32(v1, 0, v145)
                v134[v144] = buffer.readu32(v1, 0)
            end

            local v150 = i + 38 + 1
            local v151 = v143.feature.edge_cosines[i + 1]

            if v151 ~= 0 and v151 > -1.1754943508222875E-38 and v151 < 1.1754943508222875E-38 then
                local v152 = math.abs(v151) * 7.1362384635298E+44
                local v153 = math.floor(v152)
                local v154 = v152 - v153
                local v155 = if v154 > 0.5 or v154 == 0.5 and v153 % 2 == 1 then v153 + 1 else v153

                if v151 < 0 then
                    v134[v150] = v155 + 2147483648
                else
                    v134[v150] = v155
                end
            else
                buffer.writef32(v1, 0, v151)
                v134[v150] = buffer.readu32(v1, 0)
            end
        end

        v134[38] = v143.feature.flags
        v136 = "Triangle"
        v135 = v143.fatness
        v137 = 16973824
        v138 = 3
    elseif p41.tag == "RoundedBox" then
        local center, basis, half_extents = p41.center, p41.basis, p41.half_extents

        put(v134, 0, t1.lanes(center, 1))

        local t6 = {
            half_extents.x,
            half_extents.y,
            half_extents.z
        }

        for i = 0, 2 do
            local v156 = basis.columns[i + 1]
            local t7 = {
                v156[1],
                v156[2],
                v156[3],
                0
            }

            put(v134, i * 4 + 4, t7)
            put(v134, i * 4 + 16, t7)

            local v157 = i + 28 + 1
            local v158 = t6[i + 1]

            if v158 ~= 0 and v158 > -1.1754943508222875E-38 and v158 < 1.1754943508222875E-38 then
                local v159 = math.abs(v158) * 7.1362384635298E+44
                local v160 = math.floor(v159)
                local v161 = v159 - v160
                local v162 = if v161 > 0.5 or v161 == 0.5 and v160 % 2 == 1 then v160 + 1 else v160

                if v158 < 0 then
                    v134[v157] = v162 + 2147483648
                else
                    v134[v157] = v162
                end
            else
                buffer.writef32(v1, 0, v158)
                v134[v157] = buffer.readu32(v1, 0)
            end
        end

        v136 = "Box"
        v135 = p41.radius
        v137 = 50528256
        v138 = 4
    else
        error("unreachable: ContactPrimitive " .. tostring(p41.tag), 0)
    end

    local v163

    if v135 ~= 0 and v135 > -1.1754943508222875E-38 and v135 < 1.1754943508222875E-38 then
        local v164 = math.abs(v135) * 7.1362384635298E+44
        local v165 = math.floor(v164)
        local v166 = v164 - v165

        v163 = if v166 > 0.5 or v166 == 0.5 and v165 % 2 == 1 then v165 + 1 else v165

        if v135 < 0 then
            v163 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v135)
        v163 = buffer.readu32(v1, 0)
    end

    v134[33] = v163
    v134[36] = v137
    v134[37] = v138

    return v134, v136
end

local to_bits = rt.to_bits

buffer.writef32(v1, 0, 1)

local v167 = buffer.readu32(v1, 0)

buffer.writef32(v1, 0, 0)

local v168 = buffer.readu32(v1, 0)

local function pack_fill(p42, p43) -- line: 384
    -- upvalues: to_bits (copy), v167 (copy), v168 (copy)
    local tag = p43.tag
    local v169, v170, v171, v172

    if tag == "Sphere" then
        local v173 = p43[1]
        local center = v173.center
        local v174 = to_bits(center.x)
        local v175 = to_bits(center.y)
        local v176 = to_bits(center.z)

        p42[1] = v174
        p42[2] = v175
        p42[3] = v176
        p42[4] = v167
        v172 = "Sphere"
        v169 = v173.radius
        v170 = 0
        v171 = 1
    elseif tag == "Capsule" then
        local center, axis, half_length = p43.center, p43.axis, p43.half_length
        local v177 = to_bits(center.x)
        local v178 = to_bits(center.y)
        local v179 = to_bits(center.z)

        p42[1] = v177
        p42[2] = v178
        p42[3] = v179
        p42[4] = v167

        local v180 = to_bits(axis.x)
        local v181 = to_bits(axis.y)
        local v182 = to_bits(axis.z)

        p42[17] = v180
        p42[18] = v181
        p42[19] = v182
        p42[20] = v168
        p42[29] = to_bits(half_length)
        v172 = "Capsule"
        v169 = p43.radius
        v170 = 65536
        v171 = 2
    elseif tag == "Triangle" then
        local v183 = p43[1]
        local vertices, feature = v183.vertices, v183.feature
        local v184 = vertices[1]
        local v185 = to_bits(v184.x)
        local v186 = to_bits(v184.y)
        local v187 = to_bits(v184.z)

        p42[1] = v185
        p42[2] = v186
        p42[3] = v187
        p42[4] = v167

        local normal = feature.normal
        local v188 = to_bits(normal.x)
        local v189 = to_bits(normal.y)
        local v190 = to_bits(normal.z)

        p42[5] = v188
        p42[6] = v189
        p42[7] = v190
        p42[8] = v168

        local v191 = vertices[2]
        local v192 = to_bits(v191.x)
        local v193 = to_bits(v191.y)
        local v194 = to_bits(v191.z)

        p42[9] = v192
        p42[10] = v193
        p42[11] = v194
        p42[12] = v167

        local v195 = vertices[3]
        local v196 = to_bits(v195.x)
        local v197 = to_bits(v195.y)
        local v198 = to_bits(v195.z)

        p42[13] = v196
        p42[14] = v197
        p42[15] = v198
        p42[16] = v167

        local edges = feature.edges
        local edge_lengths = v183.edge_lengths
        local edge_cosines = feature.edge_cosines

        for i = 0, 2 do
            local v199 = edges[i + 1]
            local v200 = i * 4 + 16
            local v201 = v200 + 2
            local v202 = v200 + 3
            local v203 = v200 + 4
            local v204 = to_bits(v199.x)
            local v205 = to_bits(v199.y)
            local v206 = to_bits(v199.z)

            p42[v200 + 1] = v204
            p42[v201] = v205
            p42[v202] = v206
            p42[v203] = v168
            p42[i + 28 + 1] = to_bits(edge_lengths[i + 1])
            p42[i + 38 + 1] = to_bits(edge_cosines[i + 1])
        end

        p42[38] = feature.flags
        v172 = "Triangle"
        v169 = v183.fatness
        v170 = 16973824
        v171 = 3
    elseif tag == "RoundedBox" then
        local center, basis, half_extents = p43.center, p43.basis, p43.half_extents
        local v207 = to_bits(center.x)
        local v208 = to_bits(center.y)
        local v209 = to_bits(center.z)

        p42[1] = v207
        p42[2] = v208
        p42[3] = v209
        p42[4] = v167

        local x, y, z = half_extents.x, half_extents.y, half_extents.z
        local columns = basis.columns

        for i = 0, 2 do
            local v210 = columns[i + 1]
            local v211 = to_bits(v210[1])
            local v212 = to_bits(v210[2])
            local v213 = to_bits(v210[3])
            local v214 = i * 4 + 4
            local v215 = v214 + 2
            local v216 = v214 + 3
            local v217 = v214 + 4

            p42[v214 + 1] = v211
            p42[v215] = v212
            p42[v216] = v213
            p42[v217] = v168

            local v218 = i * 4 + 16
            local v219 = v218 + 2
            local v220 = v218 + 3
            local v221 = v218 + 4

            p42[v218 + 1] = v211
            p42[v219] = v212
            p42[v220] = v213
            p42[v221] = v168

            local v222 = if i == 0 then x elseif i == 1 then y else z

            p42[i + 28 + 1] = to_bits(v222)
        end

        v172 = "Box"
        v169 = p43.radius
        v170 = 50528256
        v171 = 4
    else
        error("unreachable: ContactPrimitive " .. tostring(tag), 0)
    end

    p42[33] = to_bits(v169)
    p42[36] = v170
    p42[37] = v171

    return p42, v172
end

function t1.pack(p44) -- line: 446
    -- upvalues: pack_fill (copy)
    return pack_fill(table.create(48, 0), p44)
end

local v223 = table.create(48, 0)

function t1.pack_into(p45, p46) -- line: 458
    -- upvalues: pack_fill (copy), v223 (copy)
    table.move(v223, 1, 48, 1, p45)

    return pack_fill(p45, p46)
end

function t1.lanes(p47, p48) -- line: 468
    return {
        p47.x,
        p47.y,
        p47.z,
        p48
    }
end

function t1.xyz(p49) -- line: 471
    -- upvalues: Vector3 (copy)
    return Vector3.new(p49[1], p49[2], p49[3])
end

function put(p50, p51, p52) -- line: 474
    -- upvalues: v1 (copy)
    local v224 = p51 + 1
    local v225 = p52[1]
    local v226

    if v225 ~= 0 and v225 > -1.1754943508222875E-38 and v225 < 1.1754943508222875E-38 then
        local v227 = math.abs(v225) * 7.1362384635298E+44
        local v228 = math.floor(v227)
        local v229 = v227 - v228

        v226 = if v229 > 0.5 or v229 == 0.5 and v228 % 2 == 1 then v228 + 1 else v228

        if v225 < 0 then
            v226 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v225)
        v226 = buffer.readu32(v1, 0)
    end

    p50[v224] = v226

    local v230 = p51 + 2
    local v231 = p52[2]
    local v232

    if v231 ~= 0 and v231 > -1.1754943508222875E-38 and v231 < 1.1754943508222875E-38 then
        local v233 = math.abs(v231) * 7.1362384635298E+44
        local v234 = math.floor(v233)
        local v235 = v233 - v234

        v232 = if v235 > 0.5 or v235 == 0.5 and v234 % 2 == 1 then v234 + 1 else v234

        if v231 < 0 then
            v232 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v231)
        v232 = buffer.readu32(v1, 0)
    end

    p50[v230] = v232

    local v236 = p51 + 3
    local v237 = p52[3]
    local v238

    if v237 ~= 0 and v237 > -1.1754943508222875E-38 and v237 < 1.1754943508222875E-38 then
        local v239 = math.abs(v237) * 7.1362384635298E+44
        local v240 = math.floor(v239)
        local v241 = v239 - v240

        v238 = if v241 > 0.5 or v241 == 0.5 and v240 % 2 == 1 then v240 + 1 else v240

        if v237 < 0 then
            v238 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v237)
        v238 = buffer.readu32(v1, 0)
    end

    p50[v236] = v238

    local v242 = p51 + 4
    local v243 = p52[4]
    local v244

    if v243 ~= 0 and v243 > -1.1754943508222875E-38 and v243 < 1.1754943508222875E-38 then
        local v245 = math.abs(v243) * 7.1362384635298E+44
        local v246 = math.floor(v245)
        local v247 = v245 - v246

        v244 = if v247 > 0.5 or v247 == 0.5 and v246 % 2 == 1 then v246 + 1 else v246

        if v243 < 0 then
            v244 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v243)
        v244 = buffer.readu32(v1, 0)
    end

    p50[v242] = v244
end

t1.refined_inverse = refined_inverse
t1.put = put

return t1
