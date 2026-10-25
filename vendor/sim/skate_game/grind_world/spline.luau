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

local function rtl_is_finite(p4) -- line: 28
    if p4 ~= p4 or p4 == 1e999 then
        return false
    end

    return p4 ~= (-1e999)
end

require(sim.import)

local t1 = {
    PrimitiveMetadata = {}
}

function t1.PrimitiveMetadata.eq(p5, p6) -- line: 54
    if p5.spline_guids[1] == p6.spline_guids[1] and p5.spline_guids[2] == p6.spline_guids[2] and p5.segment_index == p6.segment_index then
        return p5.flags == p6.flags
    end

    return false
end

local put

function t1.build(p7) -- line: 64
    -- upvalues: t1 (copy)
    return t1.build_rails(if p7 == nil then {} else p7.rails)
end

function t1.build_rails(p8) -- line: 68
    -- upvalues: rt (copy), v1 (copy), put (ref)
    if #p8 > 65535 then
        error("Pegasus spline table exceeds its uint16 rail count", 0)
    end

    local t2 = {}

    for _, v8 in p8 do
        local v9 = table.create(6, 0)
        local t3 = {}

        if v8.native ~= nil then
            local native = v8.native

            if #native < 28 then
                error(("Truncated native rail %*"):format(v8.name), 0)
            end

            local v95 = table.create(rt.idiv(#native, 4))

            for n = 0, rt.idiv(#native, 4) - 1 do
                local v96 = n * 4

                v95[n + 1] = ((native[v96 + 4] * 256 + native[v96 + 3]) * 256 + native[v96 + 2]) * 256 + native[v96 + 1]
            end

            v9[1] = v95[1]
            v9[2] = v95[2]
            v9[3] = v95[3]
            v9[4] = v95[4]
            v9[5] = v95[5]
            v9[6] = v95[6]

            local v97 = v9[2]
            local v98 = v9[1]

            v9[1] = v97
            v9[2] = v98

            local v99 = v9[4]
            local v100 = v9[3]

            v9[3] = v99
            v9[4] = v100

            if v95[7] ~= rt.idiv(#native - 28, 120) or rt.irem(#native - 28, 120) ~= 0 then
                error(("Invalid native rail segment count: %*"):format(v8.name), 0)
            end

            for n2 = 0, rt.idiv(#v95 - 7, 30) - 1 do
                table.insert(t3, rt.slice(v95, n2 * 30 + 7, n2 * 30 + 7 + 30))
            end
        else
            if #v8.points < 2 then
                error(("Rail %* needs two points"):format(v8.name), 0)
            end

            local n1 = 342167472
            local n2 = 1939669891

            local function mix(p9) -- line: 106
                -- upvalues: n1 (ref), n2 (ref)
                local v11 = bit32.bxor(n2, p9)
                local v12 = n1
                local v13 = v11 * 435
                local v15 = math.floor(v13 / 4294967296)

                n2 = v13 % 4294967296
                n1 = (v12 * 435 + v15 + v11 * 256) % 4294967296
            end

            for i = 1, #v8.name do
                local v16 = string.byte(v8.name, i)
                local v18 = bit32.bxor(n2, v16)
                local v19 = n1
                local v20 = v18 * 435
                local v22 = math.floor(v20 / 4294967296)

                n2 = v20 % 4294967296
                n1 = (v19 * 435 + v22 + v18 * 256) % 4294967296
            end

            for _, v23 in v8.points do
                for _, v24 in v23 do
                    local v25

                    if v24 == 0 then
                        buffer.writef32(v1, 0, v24)
                        v25 = buffer.readu32(v1, 0)
                    elseif v24 > -1.1754943508222875E-38 and v24 < 1.1754943508222875E-38 then
                        local v26 = math.abs(v24) * 7.1362384635298E+44

                        v25 = math.floor(v26)

                        local v27 = v26 - v25

                        if v27 > 0.5 or v27 == 0.5 and v25 % 2 == 1 then
                            v25 += 1
                        end

                        if v24 < 0 then
                            v25 += 2147483648
                        end
                    else
                        buffer.writef32(v1, 0, v24)
                        v25 = buffer.readu32(v1, 0)
                    end

                    local v28 = bit32.rshift(v25, 24)
                    local v30 = bit32.bxor(n2, v28)
                    local v31 = n1
                    local v32 = v30 * 435
                    local v34 = math.floor(v32 / 4294967296)

                    n2 = v32 % 4294967296
                    n1 = (v31 * 435 + v34 + v30 * 256) % 4294967296

                    local v36 = bit32.band(bit32.rshift(v25, 16), 255)
                    local v38 = bit32.bxor(n2, v36)
                    local v39 = n1
                    local v40 = v38 * 435
                    local v42 = math.floor(v40 / 4294967296)

                    n2 = v40 % 4294967296
                    n1 = (v39 * 435 + v42 + v38 * 256) % 4294967296

                    local v44 = bit32.band(bit32.rshift(v25, 8), 255)
                    local v46 = bit32.bxor(n2, v44)
                    local v47 = n1
                    local v48 = v46 * 435
                    local v50 = math.floor(v48 / 4294967296)

                    n2 = v48 % 4294967296
                    n1 = (v47 * 435 + v50 + v46 * 256) % 4294967296

                    local v51 = bit32.band(v25, 255)
                    local v53 = bit32.bxor(n2, v51)
                    local v54 = n1
                    local v55 = v53 * 435
                    local v57 = math.floor(v55 / 4294967296)

                    n2 = v55 % 4294967296
                    n1 = (v54 * 435 + v57 + v53 * 256) % 4294967296
                end
            end

            v9 = {
                n1,
                n2,
                745543431, 458826, 0, 0
            }

            local v58 = rt.copy(v8.points)
            local v59 = rt.copy(v58[1])
            local v60 = v58[#v58]

            if v8.closed and (v59[1] ~= v60[1] or v59[2] ~= v60[2] or v59[3] ~= v60[3]) then
                table.insert(v58, v59)
            end

            for j = 1, #v58 - 1 do
                local v61 = v58[j]
                local v62 = v58[j + 1]
                local v63 = table.create(30, 0)

                for k = 0, 2 do
                    local v64 = v62[k + 1] - v61[k + 1]
                    local v65 = k + 1
                    local v66 = -2 * v64

                    if v66 ~= 0 and v66 > -1.1754943508222875E-38 and v66 < 1.1754943508222875E-38 then
                        local v67 = math.abs(v66) * 7.1362384635298E+44
                        local v68 = math.floor(v67)
                        local v69 = v67 - v68
                        local v70 = if v69 > 0.5 or v69 == 0.5 and v68 % 2 == 1 then v68 + 1 else v68

                        if v66 < 0 then
                            v63[v65] = v70 + 2147483648
                        else
                            v63[v65] = v70
                        end
                    else
                        buffer.writef32(v1, 0, v66)
                        v63[v65] = buffer.readu32(v1, 0)
                    end

                    local v71 = k + 4 + 1
                    local v72 = 3 * v64

                    if v72 ~= 0 and v72 > -1.1754943508222875E-38 and v72 < 1.1754943508222875E-38 then
                        local v73 = math.abs(v72) * 7.1362384635298E+44
                        local v74 = math.floor(v73)
                        local v75 = v73 - v74
                        local v76 = if v75 > 0.5 or v75 == 0.5 and v74 % 2 == 1 then v74 + 1 else v74

                        if v72 < 0 then
                            v63[v71] = v76 + 2147483648
                        else
                            v63[v71] = v76
                        end
                    else
                        buffer.writef32(v1, 0, v72)
                        v63[v71] = buffer.readu32(v1, 0)
                    end

                    local v77 = k + 12 + 1
                    local v78 = v61[k + 1]

                    if v78 ~= 0 and v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
                        local v79 = math.abs(v78) * 7.1362384635298E+44
                        local v80 = math.floor(v79)
                        local v81 = v79 - v80
                        local v82 = if v81 > 0.5 or v81 == 0.5 and v80 % 2 == 1 then v80 + 1 else v80

                        if v78 < 0 then
                            v63[v77] = v82 + 2147483648
                        else
                            v63[v77] = v82
                        end
                    else
                        buffer.writef32(v1, 0, v78)
                        v63[v77] = buffer.readu32(v1, 0)
                    end

                    local v83 = k + 20 + 1
                    local v84 = rt.fmin(v61[k + 1], v62[k + 1])

                    if v84 ~= 0 and v84 > -1.1754943508222875E-38 and v84 < 1.1754943508222875E-38 then
                        local v85 = math.abs(v84) * 7.1362384635298E+44
                        local v86 = math.floor(v85)
                        local v87 = v85 - v86
                        local v88 = if v87 > 0.5 or v87 == 0.5 and v86 % 2 == 1 then v86 + 1 else v86

                        if v84 < 0 then
                            v63[v83] = v88 + 2147483648
                        else
                            v63[v83] = v88
                        end
                    else
                        buffer.writef32(v1, 0, v84)
                        v63[v83] = buffer.readu32(v1, 0)
                    end

                    local v89 = k + 24 + 1
                    local v90 = rt.fmax(v61[k + 1], v62[k + 1])

                    if v90 ~= 0 and v90 > -1.1754943508222875E-38 and v90 < 1.1754943508222875E-38 then
                        local v91 = math.abs(v90) * 7.1362384635298E+44
                        local v92 = math.floor(v91)
                        local v93 = v91 - v92
                        local v94 = if v93 > 0.5 or v93 == 0.5 and v92 % 2 == 1 then v92 + 1 else v92

                        if v90 < 0 then
                            v63[v89] = v94 + 2147483648
                        else
                            v63[v89] = v94
                        end
                    else
                        buffer.writef32(v1, 0, v90)
                        v63[v89] = buffer.readu32(v1, 0)
                    end
                end

                buffer.writef32(v1, 0, 1)
                v63[16] = buffer.readu32(v1, 0)
                table.insert(t3, v63)
            end
        end

        if #t3 == 0 then
            error(("Rail %* has no segments"):format(v8.name), 0)
        end

        for _, v101 in t3 do
            for n3 = 1, 28 do
                buffer.writeu32(v1, 0, v101[n3])

                local v103 = buffer.readf32(v1, 0)

                if v103 ~= v103 or v103 == 1e999 or v103 == (-1e999) then
                    error(("Non-finite spline data in %*"):format(v8.name), 0)
                end
            end

            for n4 = 0, 2 do
                buffer.writeu32(v1, 0, v101[n4 + 20 + 1])

                local v105 = buffer.readf32(v1, 0)

                buffer.writeu32(v1, 0, v101[n4 + 24 + 1])

                if buffer.readf32(v1, 0) < v105 then
                    error(("Inverted spline bounds in %*"):format(v8.name), 0)
                end
            end
        end

        table.insert(t2, {
            v9,
            t3
        })
    end

    local n3 = 0

    for _, v107 in t2 do
        n3 += #v107[2]
    end

    local v108 = #t2 * 32 + 16
    local v109 = n3 * 144 + v108

    if v109 > 4294967295 then
        error("Spline blob exceeds uint32 offsets", 0)
    end

    local v110 = table.create(v109, 0)

    put(v110, 0, #t2)
    put(v110, 4, n3)
    put(v110, 8, 16)
    put(v110, 12, v108)

    for i = 0, #t2 - 1 do
        local v111 = t2[i + 1][1]
        local v112 = t2[i + 1][2]
        local v113 = i * 32 + 16

        put(v110, v113 + 0, v111[1])
        put(v110, v113 + 4, v111[2])
        put(v110, v113 + 8, v111[3])
        put(v110, v113 + 12, v111[4])
        put(v110, v113 + 16, v111[5])
        put(v110, v113 + 20, v108)
        put(v110, v113 + 24, v108 + (#v112 - 1) * 144)
        put(v110, v113 + 28, v111[6])

        for j = 0, #v112 - 1 do
            local v114 = v112[j + 1]

            for k = 0, #v114 - 1 do
                put(v110, v108 + k * 4, v114[k + 1])
            end

            put(v110, v108 + 120, v113)

            if j > 0 then
                put(v110, v108 + 124, v108 - 144)
            end

            if j + 1 < #v112 then
                put(v110, v108 + 128, v108 + 144)
            end

            v108 += 144
        end
    end

    return v110
end

function t1.decoded_from_blob(p10) -- line: 212
    -- upvalues: rt (copy), v1 (copy)
    local function word(p11) -- line: 213
        -- upvalues: p10 (copy)
        return ((p10[p11 + 1] * 256 + p10[p11 + 2]) * 256 + p10[p11 + 3]) * 256 + p10[p11 + 4]
    end

    local t5 = {}
    local t6 = {}
    local v115 = ((p10[13] * 256 + p10[14]) * 256 + p10[15]) * 256 + p10[16]

    for i = 0, ((p10[5] * 256 + p10[6]) * 256 + p10[7]) * 256 + p10[8] - 1 do
        local v116 = v115 + i * 144
        local v117 = v116 + 120
        local v118 = ((p10[v117 + 1] * 256 + p10[v117 + 2]) * 256 + p10[v117 + 3]) * 256 + p10[v117 + 4]
        local v119 = v116 + 0 + 0

        buffer.writeu32(v1, 0, ((p10[v119 + 1] * 256 + p10[v119 + 2]) * 256 + p10[v119 + 3]) * 256 + p10[v119 + 4])

        local v121 = buffer.readf32(v1, 0)
        local v122 = v116 + 0 + 4

        buffer.writeu32(v1, 0, ((p10[v122 + 1] * 256 + p10[v122 + 2]) * 256 + p10[v122 + 3]) * 256 + p10[v122 + 4])

        local v124 = buffer.readf32(v1, 0)
        local v125 = v116 + 0 + 8

        buffer.writeu32(v1, 0, ((p10[v125 + 1] * 256 + p10[v125 + 2]) * 256 + p10[v125 + 3]) * 256 + p10[v125 + 4])

        local v127 = buffer.readf32(v1, 0)
        local v128 = v116 + 0 + 12

        buffer.writeu32(v1, 0, ((p10[v128 + 1] * 256 + p10[v128 + 2]) * 256 + p10[v128 + 3]) * 256 + p10[v128 + 4])

        local t7 = {
            v121,
            v124,
            v127,
            (buffer.readf32(v1, 0))
        }
        local v130 = v116 + 16 + 0

        buffer.writeu32(v1, 0, ((p10[v130 + 1] * 256 + p10[v130 + 2]) * 256 + p10[v130 + 3]) * 256 + p10[v130 + 4])

        local v132 = buffer.readf32(v1, 0)
        local v133 = v116 + 16 + 4

        buffer.writeu32(v1, 0, ((p10[v133 + 1] * 256 + p10[v133 + 2]) * 256 + p10[v133 + 3]) * 256 + p10[v133 + 4])

        local v135 = buffer.readf32(v1, 0)
        local v136 = v116 + 16 + 8

        buffer.writeu32(v1, 0, ((p10[v136 + 1] * 256 + p10[v136 + 2]) * 256 + p10[v136 + 3]) * 256 + p10[v136 + 4])

        local v138 = buffer.readf32(v1, 0)
        local v139 = v116 + 16 + 12

        buffer.writeu32(v1, 0, ((p10[v139 + 1] * 256 + p10[v139 + 2]) * 256 + p10[v139 + 3]) * 256 + p10[v139 + 4])

        local t8 = {
            v132,
            v135,
            v138,
            (buffer.readf32(v1, 0))
        }
        local v141 = v116 + 32 + 0

        buffer.writeu32(v1, 0, ((p10[v141 + 1] * 256 + p10[v141 + 2]) * 256 + p10[v141 + 3]) * 256 + p10[v141 + 4])

        local v143 = buffer.readf32(v1, 0)
        local v144 = v116 + 32 + 4

        buffer.writeu32(v1, 0, ((p10[v144 + 1] * 256 + p10[v144 + 2]) * 256 + p10[v144 + 3]) * 256 + p10[v144 + 4])

        local v146 = buffer.readf32(v1, 0)
        local v147 = v116 + 32 + 8

        buffer.writeu32(v1, 0, ((p10[v147 + 1] * 256 + p10[v147 + 2]) * 256 + p10[v147 + 3]) * 256 + p10[v147 + 4])

        local v149 = buffer.readf32(v1, 0)
        local v150 = v116 + 32 + 12

        buffer.writeu32(v1, 0, ((p10[v150 + 1] * 256 + p10[v150 + 2]) * 256 + p10[v150 + 3]) * 256 + p10[v150 + 4])

        local t9 = {
            v143,
            v146,
            v149,
            (buffer.readf32(v1, 0))
        }
        local v152 = v116 + 48 + 0

        buffer.writeu32(v1, 0, ((p10[v152 + 1] * 256 + p10[v152 + 2]) * 256 + p10[v152 + 3]) * 256 + p10[v152 + 4])

        local v154 = buffer.readf32(v1, 0)
        local v155 = v116 + 48 + 4

        buffer.writeu32(v1, 0, ((p10[v155 + 1] * 256 + p10[v155 + 2]) * 256 + p10[v155 + 3]) * 256 + p10[v155 + 4])

        local v157 = buffer.readf32(v1, 0)
        local v158 = v116 + 48 + 8

        buffer.writeu32(v1, 0, ((p10[v158 + 1] * 256 + p10[v158 + 2]) * 256 + p10[v158 + 3]) * 256 + p10[v158 + 4])

        local v160 = buffer.readf32(v1, 0)
        local v161 = v116 + 48 + 12

        buffer.writeu32(v1, 0, ((p10[v161 + 1] * 256 + p10[v161 + 2]) * 256 + p10[v161 + 3]) * 256 + p10[v161 + 4])

        local t10 = {
            t7,
            t8,
            t9,
            {
                v154,
                v157,
                v160,
                (buffer.readf32(v1, 0))
            }
        }
        local v163 = t10[1]
        local v164 = t10[2]
        local v165 = t10[3]
        local v166 = t10[4]
        local t11 = {
            v163[1] + v164[1] + (v165[1] + v166[1]),
            v163[2] + v164[2] + (v165[2] + v166[2]),
            v163[3] + v164[3] + (v165[3] + v166[3]),
            v163[4] + v164[4] + (v165[4] + v166[4])
        }
        local v167 = 0 + (t11[1] - v166[1]) ^ 2 + (t11[2] - v166[2]) ^ 2 + (t11[3] - v166[3]) ^ 2

        if v167 ~= v167 or v167 == 1e999 or v167 == (-1e999) then
            error(("Spline segment %* has a non-finite contact chord"):format(i), 0)
        end

        local v169 = math.abs(t11[1] - v166[1]) <= 1.52587890625E-05 and math.abs(t11[3] - v166[3]) <= 1.52587890625E-05

        table.insert(t5, {
            start = v166,
            ["end"] = t11,
            owner = rt.idiv(v118 - 16, 32) + 1
        })

        local format = string.format
        local v171 = ((p10[v118 + 1] * 256 + p10[v118 + 2]) * 256 + p10[v118 + 3]) * 256 + p10[v118 + 4]
        local v172 = v118 + 4
        local v173 = format("0x%08X%08X", v171, ((p10[v172 + 1] * 256 + p10[v172 + 2]) * 256 + p10[v172 + 3]) * 256 + p10[v172 + 4])
        local format2 = string.format
        local v174 = v118 + 8
        local v175 = ((p10[v174 + 1] * 256 + p10[v174 + 2]) * 256 + p10[v174 + 3]) * 256 + p10[v174 + 4]
        local v176 = v118 + 12
        local t13 = {}

        t13.spline_guids = {
            v173,
            format2("0x%08X%08X", v175, ((p10[v176 + 1] * 256 + p10[v176 + 2]) * 256 + p10[v176 + 3]) * 256 + p10[v176 + 4])
        }

        local idiv = rt.idiv
        local v177 = v118 + 20

        t13.segment_index = idiv(v116 - (((p10[v177 + 1] * 256 + p10[v177 + 2]) * 256 + p10[v177 + 3]) * 256 + p10[v177 + 4]), 144)
        t13.flags = v169 and 2147483648 or 0
        table.insert(t6, t13)
    end

    return t5, t6
end

function put(p12, p13, p14) -- line: 264
    p12[p13 + 1] = bit32.rshift(p14, 24)
    p12[p13 + 2] = bit32.band(bit32.rshift(p14, 16), 255)
    p12[p13 + 3] = bit32.band(bit32.rshift(p14, 8), 255)
    p12[p13 + 4] = bit32.band(p14, 255)
end

t1.put = put

return t1
