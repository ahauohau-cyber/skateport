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

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local v9 = import("skate_core/physics/native_arithmetic")
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local to_bits, from_bits = rt.to_bits, rt.from_bits

local function f32r(p3) -- line: 37
    -- upvalues: to_bits (copy), from_bits (copy)
    return from_bits(to_bits(p3))
end

local v10 = BodyId.index(BodyId.Deck) + 1
local t1 = {
    BoardMotionOutput = {}
}

local function f32r3(p4, p5, p6) -- line: 63
    -- upvalues: to_bits (copy), from_bits (copy), f32r (copy)
    if p4 < 1.1754943508222875E-38 and p4 > -1.1754943508222875E-38 and p4 ~= 0 or p5 < 1.1754943508222875E-38 and p5 > -1.1754943508222875E-38 and p5 ~= 0 or p6 < 1.1754943508222875E-38 and p6 > -1.1754943508222875E-38 and p6 ~= 0 then
        return from_bits(to_bits(p4)), from_bits(to_bits(p5)), f32r(p6)
    end

    local v11 = vector.create(p4, p5, p6)

    return v11.x, v11.y, v11.z
end

function t1.BoardMotionOutput.from_board(p7, p8, p9) -- line: 88
    -- upvalues: Vector3 (copy), BoardRuntime (copy), v10 (copy), t1 (copy), f32r3 (copy)
    local rates = BoardRuntime.bodies(p7)[v10].rates
    local columns = rates.basis.columns
    local columns2 = p7.mass_frames[v10].basis.columns

    if #columns ~= 3 or #columns2 ~= 3 then
        return t1.BoardMotionOutput.from_board_reference(p7, p8, p9)
    end

    local v12 = columns[1]
    local v13 = columns[2]
    local v14 = columns[3]
    local v15, v16, v17 = f32r3(v12[1], v12[2], v12[3])
    local v18, v19, v20 = f32r3(v13[1], v13[2], v13[3])
    local v21, v22, v23 = f32r3(v14[1], v14[2], v14[3])
    local v24 = table.create(3)

    for i = 1, 3 do
        local v25 = columns2[i]
        local v26, v27, v28 = f32r3(v25[1], v25[2], v25[3])
        local v29, v30, v31 = f32r3(v28 * v21 + (v27 * v18 + v26 * v15), v28 * v22 + (v27 * v19 + v26 * v16), v28 * v23 + (v27 * v20 + v26 * v17))

        v24[i] = { v29, v30, v31 }
    end

    if bit32.band(p9, 1048576) ~= 0 then
        local v32 = v24[1]
        local v33 = v24[3]

        v24[1] = {
            -v32[1],
            -v32[2],
            -v32[3]
        }
        v24[3] = {
            -v33[1],
            -v33[2],
            -v33[3]
        }
    end

    local linear_velocity, angular_velocity = rates.linear_velocity, rates.angular_velocity
    local v34 = linear_velocity.x * p8.x + linear_velocity.y * p8.y + linear_velocity.z * p8.z
    local v35 = Vector3.new(linear_velocity.x - p8.x * v34, linear_velocity.y - p8.y * v34, linear_velocity.z - p8.z * v34)
    local v36 = v24[3]

    return {
        angular_velocity = table.clone(angular_velocity),
        linear_velocity = table.clone(linear_velocity),
        ground_velocity = v35,
        speed = t1.length(linear_velocity),
        ground_speed = t1.length(v35),
        forward_speed = linear_velocity.x * v36[1] + linear_velocity.y * v36[2] + linear_velocity.z * v36[3],
        effective_basis = {
            columns = v24
        }
    }
end

function t1.BoardMotionOutput.effective_forward(p10, p11) -- line: 145
    -- upvalues: BoardRuntime (copy), v10 (copy), f32r3 (copy)
    local columns = BoardRuntime.bodies(p10)[v10].rates.basis.columns
    local columns2 = p10.mass_frames[v10].basis.columns

    if #columns ~= 3 or #columns2 ~= 3 then
        return nil
    end

    local v37 = columns[1]
    local v38 = columns[2]
    local v39 = columns[3]
    local v40, v41, v42 = f32r3(v37[1], v37[2], v37[3])
    local v43, v44, v45 = f32r3(v38[1], v38[2], v38[3])
    local v46, v47, v48 = f32r3(v39[1], v39[2], v39[3])
    local v49 = columns2[3]
    local v50, v51, v52 = f32r3(v49[1], v49[2], v49[3])
    local v53, v54, v55 = f32r3(v52 * v46 + (v51 * v43 + v50 * v40), v52 * v47 + (v51 * v44 + v50 * v41), v52 * v48 + (v51 * v45 + v50 * v42))

    if bit32.band(p11, 1048576) == 0 then
        return v53, v54, v55
    end

    return -v53, -v54, -v55
end

function t1.BoardMotionOutput.from_board_r3(p12, p13, p14) -- line: 170
    -- upvalues: Vector3 (copy), BoardRuntime (copy), to_bits (copy), from_bits (copy), f32r (copy), v10 (copy), t1 (copy)
    local rates = BoardRuntime.bodies(p12)[v10].rates
    local columns = rates.basis.columns
    local columns2 = p12.mass_frames[v10].basis.columns

    if #columns ~= 3 or #columns2 ~= 3 then
        return t1.BoardMotionOutput.from_board_reference(p12, p13, p14)
    end

    local v56 = columns[1]
    local v57 = columns[2]
    local v58 = columns[3]
    local v60 = from_bits(to_bits(v56[1]))
    local v62 = from_bits(to_bits(v56[2]))
    local v64 = from_bits(to_bits(v56[3]))
    local v66 = from_bits(to_bits(v57[1]))
    local v68 = from_bits(to_bits(v57[2]))
    local v70 = from_bits(to_bits(v57[3]))
    local v72 = from_bits(to_bits(v58[1]))
    local v74 = from_bits(to_bits(v58[2]))
    local v76 = from_bits(to_bits(v58[3]))
    local v77 = table.create(3)

    for i = 1, 3 do
        local v78 = columns2[i]
        local v80 = from_bits(to_bits(v78[1]))
        local v82 = from_bits(to_bits(v78[2]))
        local v84 = from_bits(to_bits(v78[3]))

        v77[i] = {
            from_bits(to_bits(v84 * v72 + (v82 * v66 + v80 * v60))),
            from_bits(to_bits(v84 * v74 + (v82 * v68 + v80 * v62))),
            f32r(v84 * v76 + (v82 * v70 + v80 * v64))
        }
    end

    if bit32.band(p14, 1048576) ~= 0 then
        local v88 = v77[1]
        local v89 = v77[3]

        v77[1] = {
            -v88[1],
            -v88[2],
            -v88[3]
        }
        v77[3] = {
            -v89[1],
            -v89[2],
            -v89[3]
        }
    end

    local linear_velocity, angular_velocity = rates.linear_velocity, rates.angular_velocity
    local v90 = linear_velocity.x * p13.x + linear_velocity.y * p13.y + linear_velocity.z * p13.z
    local v91 = Vector3.new(linear_velocity.x - p13.x * v90, linear_velocity.y - p13.y * v90, linear_velocity.z - p13.z * v90)
    local v92 = v77[3]

    return {
        angular_velocity = table.clone(angular_velocity),
        linear_velocity = table.clone(linear_velocity),
        ground_velocity = v91,
        speed = t1.length(linear_velocity),
        ground_speed = t1.length(v91),
        forward_speed = linear_velocity.x * v92[1] + linear_velocity.y * v92[2] + linear_velocity.z * v92[3],
        effective_basis = {
            columns = v77
        }
    }
end

function t1.BoardMotionOutput.from_board_reference(p15, p16, p17) -- line: 216
    -- upvalues: rt (copy), Vector3 (copy), BodyId (copy), BoardRuntime (copy), t1 (copy)
    local v93 = rt.copy(BoardRuntime.bodies(p15)[BodyId.index(BodyId.Deck) + 1].rates)
    local v94 = rt.copy(BoardRuntime.part_transforms(p15)[BodyId.index(BodyId.Deck) + 1].basis)

    if bit32.band(p17, 1048576) ~= 0 then
        for _, v95 in { 0, 2 } do
            v94.columns[v95 + 1] = rt.map(v94.columns[v95 + 1], function(p18) -- line: 223
                return -p18
            end)
        end
    end

    local v96 = t1.dot(v93.linear_velocity, p16)
    local v97 = t1.subtract(v93.linear_velocity, t1.scale(p16, v96))
    local v98 = rt.copy(v94.columns[3])

    return {
        angular_velocity = rt.copy(v93.angular_velocity),
        linear_velocity = rt.copy(v93.linear_velocity),
        ground_velocity = v97,
        speed = t1.length(v93.linear_velocity),
        ground_speed = t1.length(v97),
        forward_speed = t1.dot(v93.linear_velocity, Vector3.new(v98[1], v98[2], v98[3])),
        effective_basis = v94
    }
end

function t1.dot(p19, p20) -- line: 242
    return p19.x * p20.x + p19.y * p20.y + p19.z * p20.z
end

function t1.scale(p21, p22) -- line: 246
    -- upvalues: Vector3 (copy)
    return Vector3.new(p21.x * p22, p21.y * p22, p21.z * p22)
end

function t1.add(p23, p24) -- line: 250
    -- upvalues: Vector3 (copy)
    return Vector3.new(p23.x + p24.x, p23.y + p24.y, p23.z + p24.z)
end

function t1.subtract(p25, p26) -- line: 254
    -- upvalues: Vector3 (copy)
    return Vector3.new(p25.x - p26.x, p25.y - p26.y, p25.z - p26.z)
end

local fround = rt.fround

function t1.inverse_length_squared(p27, p28) -- line: 269
    -- upvalues: fround (copy)
    local v99 = if p27 < 1.1754943508222875E-38 and p27 > -1.1754943508222875E-38 and p27 ~= 0 then fround(p27) else vector.create(p27, 0, 0).x
    local v100 = 4096

    if not (v99 > 0 and v99 < 1.1754943508222875E-38) then
        v100 = 1
    else
        v99 *= 16777216
    end

    local v101 = 1 / math.sqrt(v99)
    local v102 = if v101 < 1.1754943508222875E-38 and v101 > -1.1754943508222875E-38 and v101 ~= 0 then fround(v101) else vector.create(v101, 0, 0).x

    for _ = 0, p28 - 1 do
        local v103 = v102 * v102
        local v104 = if v103 < 1.1754943508222875E-38 and v103 > -1.1754943508222875E-38 and v103 ~= 0 then fround(v103) else vector.create(v103, 0, 0).x
        local v105 = -v99 * v104 + 1
        local v106 = if v105 < 1.1754943508222875E-38 and v105 > -1.1754943508222875E-38 and v105 ~= 0 then fround(v105) else vector.create(v105, 0, 0).x
        local v107 = v102 * 0.5
        local v108 = (if v107 < 1.1754943508222875E-38 and v107 > -1.1754943508222875E-38 and v107 ~= 0 then fround(v107) else vector.create(v107, 0, 0).x) * v106 + v102

        v102 = if v108 < 1.1754943508222875E-38 and v108 > -1.1754943508222875E-38 and v108 ~= 0 then fround(v108) else vector.create(v108, 0, 0).x
    end

    local v109 = v102 * v100

    if v109 < 1.1754943508222875E-38 and v109 > -1.1754943508222875E-38 and v109 ~= 0 then
        return fround(v109)
    end

    return vector.create(v109, 0, 0).x
end

function t1.inverse_length_squared_reference(p29, p30) -- line: 324
    -- upvalues: rt (copy), v1 (copy), v9 (copy)
    local v110

    if p29 ~= 0 and p29 > -1.1754943508222875E-38 and p29 < 1.1754943508222875E-38 then
        local v111 = math.abs(p29) * 7.1362384635298E+44
        local v112 = math.floor(v111)
        local v113 = v111 - v112

        v110 = (if v113 > 0.5 or v113 == 0.5 and v112 % 2 == 1 then v112 + 1 else v112) * 1.401298464324817E-45

        if p29 < 0 then
            v110 = -v110
        end
    else
        buffer.writef32(v1, 0, p29)
        v110 = buffer.readf32(v1, 0)
    end

    local v114 = 4096

    if not (v110 > 0 and v110 < rt.F32_MIN_POSITIVE) then
        v114 = 1
    else
        v110 *= 16777216
    end

    local v115 = v9.reciprocal_square_root_estimate(v110)
    local v116

    if v115 ~= 0 and v115 > -1.1754943508222875E-38 and v115 < 1.1754943508222875E-38 then
        local v117 = math.abs(v115) * 7.1362384635298E+44
        local v118 = math.floor(v117)
        local v119 = v117 - v118

        v116 = (if v119 > 0.5 or v119 == 0.5 and v118 % 2 == 1 then v118 + 1 else v118) * 1.401298464324817E-45

        if v115 < 0 then
            v116 = -v116
        end
    else
        buffer.writef32(v1, 0, v115)
        v116 = buffer.readf32(v1, 0)
    end

    for _ = 0, p30 - 1 do
        local v120 = -v110
        local v121 = v116 * v116
        local v122

        if v121 ~= 0 and v121 > -1.1754943508222875E-38 and v121 < 1.1754943508222875E-38 then
            local v123 = math.abs(v121) * 7.1362384635298E+44
            local v124 = math.floor(v123)
            local v125 = v123 - v124

            v122 = (if v125 > 0.5 or v125 == 0.5 and v124 % 2 == 1 then v124 + 1 else v124) * 1.401298464324817E-45

            if v121 < 0 then
                v122 = -v122
            end
        else
            buffer.writef32(v1, 0, v121)
            v122 = buffer.readf32(v1, 0)
        end

        local v126 = v120 * v122 + 1
        local v127

        if v126 ~= 0 and v126 > -1.1754943508222875E-38 and v126 < 1.1754943508222875E-38 then
            local v128 = math.abs(v126) * 7.1362384635298E+44
            local v129 = math.floor(v128)
            local v130 = v128 - v129

            v127 = (if v130 > 0.5 or v130 == 0.5 and v129 % 2 == 1 then v129 + 1 else v129) * 1.401298464324817E-45

            if v126 < 0 then
                v127 = -v127
            end
        else
            buffer.writef32(v1, 0, v126)
            v127 = buffer.readf32(v1, 0)
        end

        local v131 = v116 * 0.5
        local v132

        if v131 ~= 0 and v131 > -1.1754943508222875E-38 and v131 < 1.1754943508222875E-38 then
            local v133 = math.abs(v131) * 7.1362384635298E+44
            local v134 = math.floor(v133)
            local v135 = v133 - v134

            v132 = (if v135 > 0.5 or v135 == 0.5 and v134 % 2 == 1 then v134 + 1 else v134) * 1.401298464324817E-45

            if v131 < 0 then
                v132 = -v132
            end
        else
            buffer.writef32(v1, 0, v131)
            v132 = buffer.readf32(v1, 0)
        end

        local v136 = v132 * v127 + v116

        if v136 ~= 0 and v136 > -1.1754943508222875E-38 and v136 < 1.1754943508222875E-38 then
            local v137 = math.abs(v136) * 7.1362384635298E+44
            local v138 = math.floor(v137)
            local v139 = v137 - v138

            v116 = (if v139 > 0.5 or v139 == 0.5 and v138 % 2 == 1 then v138 + 1 else v138) * 1.401298464324817E-45

            if v136 < 0 then
                v116 = -v116
            end
        else
            buffer.writef32(v1, 0, v136)
            v116 = buffer.readf32(v1, 0)
        end
    end

    local v140 = v116 * v114

    if v140 ~= 0 and v140 > -1.1754943508222875E-38 and v140 < 1.1754943508222875E-38 then
        local v142 = math.abs(v140) * 7.1362384635298E+44
        local v141 = math.floor(v142)
        local v143 = v142 - v141

        if v143 > 0.5 or v143 == 0.5 and v141 % 2 == 1 then
            v141 += 1
        end

        local v144 = v141 * 1.401298464324817E-45

        if v140 < 0 then
            return -v144
        end

        return v144
    end

    buffer.writef32(v1, 0, v140)

    return (buffer.readf32(v1, 0))
end

function t1.length(p31) -- line: 353
    -- upvalues: t1 (copy), fround (copy)
    local x, y, z = p31.x, p31.y, p31.z
    local v145 = x * x + y * y + z * z
    local v146 = if v145 < 1.1754943508222875E-38 and v145 > -1.1754943508222875E-38 and v145 ~= 0 then fround(v145) else vector.create(v145, 0, 0).x
    local v147 = v146 * t1.inverse_length_squared(v146, 2)

    if v146 == 0 then
        return 0
    end

    return v147
end

function t1.length_reference(p32) -- line: 369
    -- upvalues: v1 (copy), t1 (copy)
    local v148 = t1.dot(p32, p32)
    local v149

    if v148 ~= 0 and v148 > -1.1754943508222875E-38 and v148 < 1.1754943508222875E-38 then
        local v150 = math.abs(v148) * 7.1362384635298E+44
        local v151 = math.floor(v150)
        local v152 = v150 - v151

        v149 = (if v152 > 0.5 or v152 == 0.5 and v151 % 2 == 1 then v151 + 1 else v151) * 1.401298464324817E-45

        if v148 < 0 then
            v149 = -v149
        end
    else
        buffer.writef32(v1, 0, v148)
        v149 = buffer.readf32(v1, 0)
    end

    local v153 = v149 * t1.inverse_length_squared(v149, 2)

    if v149 == 0 then
        return 0
    end

    return v153
end

return t1
