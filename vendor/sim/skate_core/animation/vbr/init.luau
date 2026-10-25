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
local v8 = import("skate_core/animation/vbr/bits")
local v9 = import("skate_core/animation/vbr/header")
local v10 = import("skate_core/animation/vbr/transform")
local t1 = {
    VbrDecoder = {}
}

function t1.VbrDecoder.new(p3, p4, p5, p6) -- line: 48
    -- upvalues: v9 (copy)
    return {
        cached_block = nil,
        bytes = p3,
        header = v9.Header.read(p3, p4, p5, p6)
    }
end

function t1.VbrDecoder.frame_count(p7) -- line: 61
    return p7.header.frames
end

function t1.VbrDecoder.channel_count(p8) -- line: 65
    return p8.header.bones
end

function t1.VbrDecoder.decode_frame_reference(p9, p10) -- line: 72
    -- upvalues: rt (copy), v1 (copy), v8 (copy), v10 (copy)
    if p9.header.frames <= p10 then
        error(("VBR frame %* out of range"):format(p10), 0)
    end

    local v11 = rt.idiv(p10, 8)
    local v12 = p9.header.blocks[v11 + 1]
    local start, v13 = v12.start, v12["end"]

    if v13 < start or buffer.len(p9.bytes) < v13 then
        error(("range %*..%* out of range for slice of length %*"):format(start, v13, (buffer.len(p9.bytes))), 0)
    end

    local v14 = false

    if p9.cached_block ~= nil then
        if p9.cached_block[1] == v11 then
            v14 = true
        elseif v13 - start < 3 then
            error(`range start index 3 out of range for slice of length { v13 - start }`, 0)
        end
    elseif v13 - start < 3 then
        error(`range start index 3 out of range for slice of length { v13 - start }`, 0)
    end

    if not v14 then
        local v15 = v13 - start - 3
        local v16 = buffer.create(v15)

        buffer.copy(v16, 0, p9.bytes, start + 3, v15)
        p9.cached_block = {
            v11,
            v8.unpack_reference(v16, p9.header.widths)
        }
    end

    local v17 = p9.cached_block[2]
    local bones = p9.header.bones
    local v18 = table.create(bones)

    for i = 1, bones do
        v18[i] = {
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0
        }
    end

    local v19 = rt.irem(p10, 8)
    local n1 = 0
    local n2 = 0
    local n3 = 0

    for v20, v21 in ipairs(p9.header.channels) do
        local v22 = v20 - 1

        for j = 0, bones - 1 do
            local v23 = v18[j + 1]
            local v24 = p9.header.constant_flags[v22 * p9.header.bones + j + 1]

            for k = 0, v21.components - 1 do
                local v25

                if v24 then
                    v25 = p9.header.constants[n1 + 1]

                    if v25 == nil then
                        error(("index out of bounds: constant %*"):format(n1), 0)
                    end

                    n1 += 1
                else
                    if v13 - start <= v22 then
                        error(("index out of bounds: block byte %*"):format(v22), 0)
                    end

                    local v27 = v17[n2 + 1]

                    if v27 == nil then
                        error(("index out of bounds: coefficient %*"):format(n2), 0)
                    end

                    v25 = v10.decode_reference(v19, buffer.readu8(p9.bytes, start + v22), p9.header.dct_scale, v27, v21.min, v21.range)
                    n2 += 1
                end

                local v29 = n3 + k + 1

                if v25 ~= 0 and v25 > -1.1754943508222875E-38 and v25 < 1.1754943508222875E-38 then
                    local v30 = math.abs(v25) * 7.1362384635298E+44
                    local v31 = math.floor(v30)
                    local v32 = v30 - v31
                    local v33 = if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31

                    if v25 < 0 then
                        v23[v29] = v33 + 2147483648
                    else
                        v23[v29] = v33
                    end
                else
                    buffer.writef32(v1, 0, v25)
                    v23[v29] = buffer.readu32(v1, 0)
                end
            end
        end

        n3 += v21.components
    end

    return v18
end

local to_bits = rt.to_bits

function t1.VbrDecoder.decode_frame(p11, p12) -- line: 159
    -- upvalues: rt (copy), v8 (copy), v10 (copy), to_bits (copy)
    local header = p11.header

    if header.frames <= p12 then
        error(("VBR frame %* out of range"):format(p12), 0)
    end

    local bytes = p11.bytes
    local v34 = rt.idiv(p12, 8)
    local v35 = header.blocks[v34 + 1]
    local start, v36 = v35.start, v35["end"]

    if v36 < start or buffer.len(bytes) < v36 then
        error(("range %*..%* out of range for slice of length %*"):format(start, v36, (buffer.len(bytes))), 0)
    end

    local v37 = v36 - start
    local v38 = false

    if p11.cached_block ~= nil then
        if p11.cached_block[1] == v34 then
            v38 = true
        elseif v37 < 3 then
            error(("range start index 3 out of range for slice of length %*"):format(v37), 0)
        end
    elseif v37 < 3 then
        error(("range start index 3 out of range for slice of length %*"):format(v37), 0)
    end

    if not v38 then
        p11.cached_block = {
            v34,
            v8.unpack_range(bytes, start + 3, v36, header.widths)
        }
    end

    local v39 = p11.cached_block[2]
    local bones = header.bones
    local v40 = table.create(bones)

    for i = 1, bones do
        v40[i] = {
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0
        }
    end

    local v41 = rt.irem(p12, 8)
    local constants, constant_flags, dct_scale = header.constants, header.constant_flags, header.dct_scale
    local v42 = v10.tables()
    local v43 = dct_scale * dct_scale
    local v44 = dct_scale * 3.0517578125E-05
    local v45 = v42.inverse_dct[v41 + 1]
    local quantization = v42.quantization
    local n4 = 0
    local n5 = 0
    local n6 = 0

    for v46, v47 in ipairs(header.channels) do
        local v48 = v46 - 1
        local components, min, range = v47.components, v47.min, v47.range
        local v49 = v48 * bones
        local v50 = bones - 1
        local v51 = false
        local v52, v53, v54, v55, v56, v57, v58, v59

        for j = 0, v50 do
            local v60 = v40[j + 1]

            if constant_flags[v49 + j + 1] then
                for k = 0, components - 1 do
                    local v61 = constants[n4 + 1]

                    if v61 == nil then
                        error(("index out of bounds: constant %*"):format(n4), 0)
                    end

                    n4 += 1
                    v60[n6 + k + 1] = to_bits(v61)
                end
            else
                for n = 0, components - 1 do
                    if v37 <= v48 then
                        error(("index out of bounds: block byte %*"):format(v48), 0)
                    end

                    local v62 = v39[n5 + 1]

                    if v62 == nil then
                        error(("index out of bounds: coefficient %*"):format(n5), 0)
                    end

                    if not v51 then
                        local v64 = quantization[buffer.readu8(bytes, start + v48) + 1]

                        v51 = true
                        v52 = (v64[1] * v43 + v44) * v45[1]
                        v53 = (v64[2] * v43 + v44) * v45[2]
                        v54 = (v64[3] * v43 + v44) * v45[3]
                        v55 = (v64[4] * v43 + v44) * v45[4]
                        v56 = (v64[5] * v43 + v44) * v45[5]
                        v57 = (v64[6] * v43 + v44) * v45[6]
                        v58 = (v64[7] * v43 + v44) * v45[7]
                        v59 = (v64[8] * v43 + v44) * v45[8]
                    end

                    local v65 = (v62[1] * v52 + v62[2] * v53 + v62[3] * v54 + v62[4] * v55 + (v62[5] * v56 + v62[6] * v57 + v62[7] * v58 + v62[8] * v59) + 0.5) * range + min

                    n5 += 1
                    v60[n6 + n + 1] = to_bits(v65)
                end
            end
        end

        n6 += components
    end

    return v40
end

function t1.VbrDecoder.decode_frame_into(p13, p14, p15, p16) -- line: 261
    -- upvalues: rt (copy), v8 (copy), v10 (copy), to_bits (copy)
    local header = p13.header

    if header.frames <= p14 then
        error(("VBR frame %* out of range"):format(p14), 0)
    end

    local bytes = p13.bytes
    local v66 = rt.idiv(p14, 8)
    local v67 = header.blocks[v66 + 1]
    local start, v68 = v67.start, v67["end"]

    if v68 < start or buffer.len(bytes) < v68 then
        error(("range %*..%* out of range for slice of length %*"):format(start, v68, (buffer.len(bytes))), 0)
    end

    local v69 = v68 - start
    local v70 = false

    if p13.cached_block ~= nil then
        if p13.cached_block[1] == v66 then
            v70 = true
        elseif v69 < 3 then
            error(("range start index 3 out of range for slice of length %*"):format(v69), 0)
        end
    elseif v69 < 3 then
        error(("range start index 3 out of range for slice of length %*"):format(v69), 0)
    end

    if not v70 then
        p13.cached_block = {
            v66,
            v8.unpack_range(bytes, start + 3, v68, header.widths)
        }
    end

    local v71 = p13.cached_block[2]
    local bones = header.bones
    local v72 = rt.irem(p14, 8)
    local constants, constant_flags, dct_scale = header.constants, header.constant_flags, header.dct_scale
    local v73 = v10.tables()
    local v74 = dct_scale * dct_scale
    local v75 = dct_scale * 3.0517578125E-05
    local v76 = v73.inverse_dct[v72 + 1]
    local quantization = v73.quantization
    local n7 = 0
    local n8 = 0
    local n9 = 0

    for v77, v78 in ipairs(header.channels) do
        local v79 = v77 - 1
        local components, min, range = v78.components, v78.min, v78.range
        local v80 = v79 * bones
        local v81 = bones - 1
        local v82 = false
        local v83, v84, v85, v86, v87, v88, v89, v90

        for i = 0, v81 do
            local v91 = p16 + i * 40 + n9 * 4

            if constant_flags[v80 + i + 1] then
                for j = 0, components - 1 do
                    local v92 = constants[n7 + 1]

                    if v92 == nil then
                        error(("index out of bounds: constant %*"):format(n7), 0)
                    end

                    n7 += 1
                    buffer.writeu32(p15, v91 + j * 4, (to_bits(v92)))
                end
            else
                for k = 0, components - 1 do
                    if v69 <= v79 then
                        error(("index out of bounds: block byte %*"):format(v79), 0)
                    end

                    local v95 = v71[n8 + 1]

                    if v95 == nil then
                        error(("index out of bounds: coefficient %*"):format(n8), 0)
                    end

                    if not v82 then
                        local v97 = quantization[buffer.readu8(bytes, start + v79) + 1]

                        v82 = true
                        v83 = (v97[1] * v74 + v75) * v76[1]
                        v84 = (v97[2] * v74 + v75) * v76[2]
                        v85 = (v97[3] * v74 + v75) * v76[3]
                        v86 = (v97[4] * v74 + v75) * v76[4]
                        v87 = (v97[5] * v74 + v75) * v76[5]
                        v88 = (v97[6] * v74 + v75) * v76[6]
                        v89 = (v97[7] * v74 + v75) * v76[7]
                        v90 = (v97[8] * v74 + v75) * v76[8]
                    end

                    local v98 = (v95[1] * v83 + v95[2] * v84 + v95[3] * v85 + v95[4] * v86 + (v95[5] * v87 + v95[6] * v88 + v95[7] * v89 + v95[8] * v90) + 0.5) * range + min

                    n8 += 1
                    buffer.writeu32(p15, v91 + k * 4, (to_bits(v98)))
                end
            end
        end

        n9 += components
    end
end

local function build_plan(p17) -- line: 363
    -- upvalues: to_bits (copy)
    local bones, channels = p17.bones, p17.channels

    if #channels ~= 3 or channels[1].components ~= 3 or channels[2].components ~= 4 or channels[3].components ~= 3 then
        return false
    end

    local constants, constant_flags = p17.constants, p17.constant_flags
    local v101 = buffer.create(bones * 40)
    local v102 = table.create(3)
    local v103 = table.create(3)
    local n10 = 0
    local n11 = 0
    local n12 = 0

    for i = 1, 3 do
        local components = channels[i].components
        local v104 = (i - 1) * bones
        local t2 = {}

        v103[i] = n11

        for j = 0, bones - 1 do
            local v105 = j * 40 + n12 * 4

            if constant_flags[v104 + j + 1] then
                for k = 0, components - 1 do
                    local v106 = constants[n10 + 1]

                    if v106 == nil then
                        return false
                    end

                    n10 += 1
                    buffer.writeu32(v101, v105 + k * 4, (to_bits(v106)))
                end
            else
                for n = 0, components - 1 do
                    n11 += 1
                    t2[#t2 + 1] = v105 + n * 4
                end
            end
        end

        v102[i] = t2
        n12 += components
    end

    if #p17.widths < n11 then
        return false
    end

    return {
        template = v101,
        offsets = v102,
        firsts = v103,
        row_bytes = bones * 40
    }
end

local t3 = {}

function t1.VbrDecoder.decode_block_into(p18, p19, p20, p21, p22) -- line: 431
    -- upvalues: v8 (copy), v10 (copy), t1 (copy), to_bits (copy), build_plan (copy), t3 (copy)
    local header = p18.header
    local frames = header.frames
    local v109 = p19 * 8
    local v112 = math.min(v109 + 7, frames - 1)
    local plan = p18.plan

    if plan == nil then
        plan = build_plan(header)
        p18.plan = plan
    end

    if plan == false then
        for i = v109, math.max(v112, v109) do
            t1.VbrDecoder.decode_frame_into(p18, i, p20, p21 + (i - v109) * p22)
        end

        return -1
    end

    if frames <= v109 then
        error(("VBR frame %* out of range"):format(v109), 0)
    end

    local bytes = p18.bytes
    local v113 = header.blocks[p19 + 1]
    local start, v114 = v113.start, v113["end"]

    if v114 < start or buffer.len(bytes) < v114 then
        error(("range %*..%* out of range for slice of length %*"):format(start, v114, (buffer.len(bytes))), 0)
    end

    local v115 = v114 - start

    if v115 < 3 then
        error(("range start index 3 out of range for slice of length %*"):format(v115), 0)
    end

    v8.unpack_range_flat(bytes, start + 3, v114, header.widths, t3)

    local dct_scale = header.dct_scale
    local v116 = v10.tables()
    local v117 = dct_scale * dct_scale
    local v118 = dct_scale * 3.0517578125E-05
    local inverse_dct, quantization = v116.inverse_dct, v116.quantization
    local template, row_bytes = plan.template, plan.row_bytes
    local channels = header.channels
    local n13 = 0

    for i = 1, 3 do
        local v119 = plan.offsets[i]
        local v120 = #v119

        if v120 > 0 then
            local v121 = channels[i]
            local min, range = v121.min, v121.range
            local v123 = quantization[buffer.readu8(bytes, start + i - 1) + 1]
            local v124 = v123[1] * v117 + v118
            local v125 = v123[2] * v117 + v118
            local v126 = v123[3] * v117 + v118
            local v127 = v123[4] * v117 + v118
            local v128 = v123[5] * v117 + v118
            local v129 = v123[6] * v117 + v118
            local v130 = v123[7] * v117 + v118
            local v131 = v123[8] * v117 + v118
            local v132 = plan.firsts[i] * 8

            for j = v109, v112 do
                local v133 = p21 + (j - v109) * p22

                if i == 1 then
                    buffer.copy(p20, v133, template, 0, row_bytes)
                end

                local v134 = inverse_dct[j - v109 + 1]
                local v135 = v124 * v134[1]
                local v136 = v125 * v134[2]
                local v137 = v126 * v134[3]
                local v138 = v127 * v134[4]
                local v139 = v128 * v134[5]
                local v140 = v129 * v134[6]
                local v141 = v130 * v134[7]
                local v142 = v131 * v134[8]
                local v143 = v132

                for k = 1, v120 do
                    local v144 = (t3[v143 + 1] * v135 + t3[v143 + 2] * v136 + t3[v143 + 3] * v137 + t3[v143 + 4] * v138 + (t3[v143 + 5] * v139 + t3[v143 + 6] * v140 + t3[v143 + 7] * v141 + t3[v143 + 8] * v142) + 0.5) * range + min

                    v143 += 8

                    local v145 = math.abs(v144)

                    if not (v145 >= 1.1754943508222875E-38 and v145 < 3E+38) then
                        buffer.writeu32(p20, v133 + v119[k], (to_bits(v144)))

                        if not (v145 < 3E+38) then
                            n13 += 1
                        end
                    else
                        buffer.writef32(p20, v133 + v119[k], v144)
                    end
                end
            end
        elseif i == 1 then
            for n = v109, v112 do
                buffer.copy(p20, p21 + (n - v109) * p22, template, 0, row_bytes)
            end
        end
    end

    return n13
end

t1.VbrDecoder.build_plan = build_plan

function t1.VbrDecoder.prepare_blocks(p23) -- line: 527
    -- upvalues: build_plan (copy)
    local plan = p23.plan

    if plan == nil then
        plan = build_plan(p23.header)
        p23.plan = plan
    end

    if plan == false then
        return false
    end

    local template = plan.template

    for i = 0, plan.row_bytes - 4, 4 do
        if bit32.band(buffer.readu32(template, i), 2139095040) == 2139095040 then
            return false
        end
    end

    return true
end

return t1
