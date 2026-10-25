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

local function rtl_fround(p4) -- line: 28
    -- upvalues: v1 (copy)
    if p4 ~= 0 and p4 > -1.1754943508222875E-38 and p4 < 1.1754943508222875E-38 then
        local v9 = math.abs(p4) * 7.1362384635298E+44
        local v8 = math.floor(v9)
        local v10 = v9 - v8

        if v10 > 0.5 or v10 == 0.5 and v8 % 2 == 1 then
            v8 += 1
        end

        local v11 = v8 * 1.401298464324817E-45

        if p4 < 0 then
            return -v11
        end

        return v11
    end

    buffer.writef32(v1, 0, p4)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v12 = import("skate_core/physics/board_motion_output")
local v13 = import("skate_core/physics/native_arithmetic")
local inverse_length_squared = v12.inverse_length_squared
local dot3, reciprocal_estimate = v13.dot3, v13.reciprocal_estimate
local t1 = {
    ground_history = function(p5) -- ground_history | line: 52
        -- upvalues: rt (copy), v1 (copy), reciprocal_estimate (copy)
        buffer.writeu32(v1, 0, p5.previous_position[1])

        local v15 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p5.previous_position[2])

        local v17 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p5.previous_position[3])

        local v19 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p5.previous_position[4])

        local t2 = {
            v15,
            v17,
            v19,
            (buffer.readf32(v1, 0))
        }

        buffer.writeu32(v1, 0, p5.current_position[1])

        local v22 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p5.current_position[2])

        local v24 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p5.current_position[3])

        local v26 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p5.current_position[4])

        local t3 = {
            v22,
            v24,
            v26,
            (buffer.readf32(v1, 0))
        }

        buffer.writeu32(v1, 0, p5.previous_filtered_delta[1])

        local v29 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p5.previous_filtered_delta[2])

        local v31 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p5.previous_filtered_delta[3])

        local v33 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p5.previous_filtered_delta[4])

        local t4 = {
            v29,
            v31,
            v33,
            (buffer.readf32(v1, 0))
        }
        local t5 = {
            t3[1] - t2[1],
            t3[2] - t2[2],
            t3[3] - t2[3],
            t3[4] - t2[4]
        }

        buffer.writeu32(v1, 0, p5.timestep_bits)

        local v35 = buffer.readf32(v1, 0)
        local v36 = reciprocal_estimate(v35)
        local v37 = v36 * (-v36 * v35 + 1) + v36
        local v38 = v37 * (-v37 * v35 + 1) + v37
        local v39 = t5[1]
        local v40

        if v39 ~= 0 and v39 > -1.1754943508222875E-38 and v39 < 1.1754943508222875E-38 then
            local v41 = math.abs(v39) * 7.1362384635298E+44
            local v42 = math.floor(v41)
            local v43 = v41 - v42

            v40 = if v43 > 0.5 or v43 == 0.5 and v42 % 2 == 1 then v42 + 1 else v42

            if v39 < 0 then
                v40 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v39)
            v40 = buffer.readu32(v1, 0)
        end

        local v44 = t5[2]
        local v45

        if v44 ~= 0 and v44 > -1.1754943508222875E-38 and v44 < 1.1754943508222875E-38 then
            local v46 = math.abs(v44) * 7.1362384635298E+44
            local v47 = math.floor(v46)
            local v48 = v46 - v47

            v45 = if v48 > 0.5 or v48 == 0.5 and v47 % 2 == 1 then v47 + 1 else v47

            if v44 < 0 then
                v45 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v44)
            v45 = buffer.readu32(v1, 0)
        end

        local v49 = t5[3]
        local v50

        if v49 ~= 0 and v49 > -1.1754943508222875E-38 and v49 < 1.1754943508222875E-38 then
            local v51 = math.abs(v49) * 7.1362384635298E+44
            local v52 = math.floor(v51)
            local v53 = v51 - v52

            v50 = if v53 > 0.5 or v53 == 0.5 and v52 % 2 == 1 then v52 + 1 else v52

            if v49 < 0 then
                v50 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v49)
            v50 = buffer.readu32(v1, 0)
        end

        local v54 = t5[4]
        local v55

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            local v56 = math.abs(v54) * 7.1362384635298E+44
            local v57 = math.floor(v56)
            local v58 = v56 - v57

            v55 = if v58 > 0.5 or v58 == 0.5 and v57 % 2 == 1 then v57 + 1 else v57

            if v54 < 0 then
                v55 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v55 = buffer.readu32(v1, 0)
        end

        return {
            delta = {
                v40,
                v45,
                v50,
                v55
            },
            filtered_delta = rt.from_fn(4, function(p6) -- line: 93
                -- upvalues: t4 (copy), t5 (copy), v38 (copy), v1 (copy)
                local v59 = v38 * (t5[p6 + 1] * 0.050000011920928955)
                local v60 = t4[p6 + 1] * 0.949999988079071 + v59

                if v60 ~= 0 and v60 > -1.1754943508222875E-38 and v60 < 1.1754943508222875E-38 then
                    local v62 = math.abs(v60) * 7.1362384635298E+44
                    local v61 = math.floor(v62)
                    local v63 = v62 - v61

                    if v63 > 0.5 or v63 == 0.5 and v61 % 2 == 1 then
                        v61 += 1
                    end

                    if v60 < 0 then
                        return v61 + 2147483648
                    end

                    return v61
                end

                buffer.writef32(v1, 0, v60)

                return (buffer.readu32(v1, 0))
            end)
        }
    end,
    ground_history_words = function(p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19) -- ground_history_words | line: 103
        -- upvalues: rt (copy), reciprocal_estimate (copy)
        local from_bits, to_bits = rt.from_bits, rt.to_bits
        local v64 = from_bits(p7)
        local v65 = from_bits(p8)
        local v66 = from_bits(p9)
        local v67 = from_bits(p10)
        local v68 = from_bits(p11)
        local v69 = from_bits(p12)
        local v70 = from_bits(p13)
        local v71 = from_bits(p14)
        local v72 = from_bits(p15)
        local v73 = from_bits(p16)
        local v74 = from_bits(p17)
        local v75 = from_bits(p18)
        local v76 = v68 - v64
        local v77 = v69 - v65
        local v78 = v70 - v66
        local v79 = v71 - v67
        local v80 = from_bits(p19)
        local v81 = reciprocal_estimate(v80)
        local v82 = v81 * (-v81 * v80 + 1) + v81
        local v83 = v82 * (-v82 * v80 + 1) + v82
        local v84 = from_bits(1064514355)
        local v85 = 1 - v84

        return to_bits(v76), to_bits(v77), to_bits(v78), to_bits(v79), to_bits(v72 * v84 + v83 * (v76 * v85)), to_bits(v73 * v84 + v83 * (v77 * v85)), to_bits(v74 * v84 + v83 * (v78 * v85)), to_bits(v75 * v84 + v83 * (v79 * v85))
    end,
    prepared_jump_velocity = function(p20) -- prepared_jump_velocity | line: 138
        -- upvalues: rt (copy), v1 (copy), inverse_length_squared (copy), dot3 (copy)
        buffer.writeu32(v1, 0, p20.skateboard_vector[1])

        local v87 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p20.skateboard_vector[2])

        local v89 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p20.skateboard_vector[3])

        local v91 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p20.skateboard_vector[4])

        local t8 = {
            v87,
            v89,
            v91,
            (buffer.readf32(v1, 0))
        }

        buffer.writeu32(v1, 0, p20.previous_velocity[1])

        local v94 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p20.previous_velocity[2])

        local v96 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p20.previous_velocity[3])

        local v98 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p20.previous_velocity[4])

        local t9 = {
            v94,
            v96,
            v98,
            (buffer.readf32(v1, 0))
        }
        local v100 = dot3(t8, t8)
        local v101

        if v100 ~= 0 and v100 > -1.1754943508222875E-38 and v100 < 1.1754943508222875E-38 then
            local v102 = math.abs(v100) * 7.1362384635298E+44
            local v103 = math.floor(v102)
            local v104 = v102 - v103

            v101 = (if v104 > 0.5 or v104 == 0.5 and v103 % 2 == 1 then v103 + 1 else v103) * 1.401298464324817E-45

            if v100 < 0 then
                v101 = -v101
            end
        else
            buffer.writef32(v1, 0, v100)
            v101 = buffer.readf32(v1, 0)
        end

        local v105 = inverse_length_squared(v101, 2)
        local v106 = if (if v101 == 0 then 0 else v101 * v105) > 9.999999974752427E-07 then {
            t8[1] * v105,
            t8[2] * v105,
            t8[3] * v105,
            t8[4] * v105
        } else table.create(4, 0)
        local v107 = v106[2]
        local v108

        if v107 ~= 0 and v107 > -1.1754943508222875E-38 and v107 < 1.1754943508222875E-38 then
            local v109 = math.abs(v107) * 7.1362384635298E+44
            local v110 = math.floor(v109)
            local v111 = v109 - v110

            v108 = if v111 > 0.5 or v111 == 0.5 and v110 % 2 == 1 then v110 + 1 else v110

            if v107 < 0 then
                v108 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v107)
            v108 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v108, 2147483648)))

        local v113 = buffer.readf32(v1, 0) * 9.800000190734863

        return rt.from_fn(4, function(p21) -- line: 173
            -- upvalues: t9 (copy), v106 (copy), v113 (copy), v1 (copy)
            local v114 = v106[p21 + 1] * v113 * 0.01666666753590107 + t9[p21 + 1]

            if v114 ~= 0 and v114 > -1.1754943508222875E-38 and v114 < 1.1754943508222875E-38 then
                local v116 = math.abs(v114) * 7.1362384635298E+44
                local v115 = math.floor(v116)
                local v117 = v116 - v115

                if v117 > 0.5 or v117 == 0.5 and v115 % 2 == 1 then
                    v115 += 1
                end

                if v114 < 0 then
                    return v115 + 2147483648
                end

                return v115
            end

            buffer.writef32(v1, 0, v114)

            return (buffer.readu32(v1, 0))
        end)
    end
}
local t10 = {
    0, 0, 0, 0
}

function t1.prepared_jump_velocity_words(p22, p23, p24, p25, p26, p27, p28, p29) -- line: 181
    -- upvalues: rt (copy), v1 (copy), inverse_length_squared (copy), dot3 (copy), t10 (copy)
    local from_bits, to_bits = rt.from_bits, rt.to_bits
    local v118 = from_bits(p22)
    local v119 = from_bits(p23)
    local v120 = from_bits(p24)
    local v121 = from_bits(p25)

    t10[1] = v118
    t10[2] = v119
    t10[3] = v120
    t10[4] = v121

    local v122 = from_bits(p26)
    local v123 = from_bits(p27)
    local v124 = from_bits(p28)
    local v125 = from_bits(p29)
    local v126 = dot3(t10, t10)
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

    local v131 = inverse_length_squared(v127, 2)
    local v132 = if v127 == 0 then 0 else v127 * v131
    local v133, v134, v135, v136

    if from_bits(897988541) < v132 then
        v134 = v118 * v131
        v133 = v119 * v131
        v135 = v120 * v131
        v136 = v121 * v131
    else
        v134 = 0
        v133 = 0
        v135 = 0
        v136 = 0
    end

    local v138 = from_bits((bit32.bxor(to_bits(v133), 2147483648))) * from_bits(1092406477)
    local v139 = from_bits(1015580809)

    return to_bits(v134 * v138 * v139 + v122), to_bits(v133 * v138 * v139 + v123), to_bits(v135 * v138 * v139 + v124), to_bits(v136 * v138 * v139 + v125)
end

return t1
