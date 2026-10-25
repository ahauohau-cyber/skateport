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

local function rtl_from_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p3) -- line: 20
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v6 = math.abs(p3) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p3 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local MotionGraphAttribute = import("skate_core/animation/output/attributes").MotionGraphAttribute
local v9 = import("skate_core/animation/playback_attributes")
local v10

local function PlaybackTree() -- line: 39
    -- upvalues: import (copy), v10 (ref)
    local v11 = v10

    if v11 == nil then
        v11 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v11
    end

    return v11
end

local t1 = {}

local function query_scratch(p4) -- line: 64
    return {
        begin_time = -1,
        end_time = -1,
        status = 6,
        kind = 0,
        sequence_id = -1,
        payload = { { 0 } },
        name = p4
    }
end

local t2 = {}
local n1 = 0

local function acquire_scratch(p5) -- line: 93
    -- upvalues: query_scratch (copy), t2 (copy), n1 (ref)
    local v12 = n1

    if v12 == 0 then
        local v13 = query_scratch(p5)

        v13.scratch = true

        return v13
    end

    local v14 = t2[v12]

    t2[v12] = nil
    n1 = v12 - 1

    local v15 = v14.payload[1]

    v15[1] = 0
    v15[2] = nil
    v15[3] = nil
    v15[4] = nil
    v15[5] = nil
    v15[6] = nil
    v14.begin_time = -1
    v14.end_time = -1
    v14.name = p5
    v14.status = 6
    v14.kind = 0
    v14.sequence_id = -1

    return v14
end

local function release_scratch(p6) -- line: 113
    -- upvalues: t2 (copy), n1 (ref)
    local v16 = n1 + 1

    n1 = v16
    t2[v16] = p6
end

function t1.set_clip_word(p7) -- line: 118
    USE_CLIP_WORD = p7
end

function t1.scratch_pool() -- line: 122
    -- upvalues: t2 (copy), n1 (ref)
    return n1, t2
end

local eq = import("skate_core/animation/output/attributes").AttributeName.eq
local query_word = import("skate_core/animation/playback_clip").PlaybackClip.query_word

t1.PhaseBlend = {}

function t1.PhaseBlend.new(p8, p9) -- line: 140
    -- upvalues: rt (copy), import (copy), v10 (ref)
    if #p9 < 2 then
        error("PhaseBlend requires at least two authored children", 0)
    end

    local v17 = #p9
    local v18 = table.create(v17)

    for i = 0, v17 - 1 do
        v18[i + 1] = i
    end

    local t3 = {
        left = 0,
        right = 1,
        weight = 0,
        normalized = true,
        cull_threshold = 0,
        time = 0,
        parameter = rt.copy(p8)
    }
    local v19 = v10

    if v19 == nil then
        v19 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v19
    end

    t3.length = v19.length(p9[1])
    t3.children = p9
    t3.order = v18
    t3.values = table.create(v17, 0)
    t3.parameter_value = rt.F32_MAX

    return t3
end

function t1.PhaseBlend.set_time(p10, p11) -- line: 165
    -- upvalues: import (copy), v10 (ref)
    local v20 = v10

    if v20 == nil then
        v20 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v20
    end

    local v21 = p11 / p10.length
    local v22 = v20.length(p10.children[p10.left + 1]) * v21
    local v23 = v20.length(p10.children[p10.right + 1]) * v21

    v20.set_time(p10.children[p10.left + 1], v22)
    v20.set_time(p10.children[p10.right + 1], v23)
    p10.time = p11
end

function t1.PhaseBlend.phase(p12) -- line: 175
    return p12.time / (if -p12.length >= 0 then 1 else p12.length)
end

function t1.PhaseBlend.update_length(p13, p14) -- line: 179
    -- upvalues: import (copy), v10 (ref), t1 (copy)
    local v24 = v10

    if v24 == nil then
        v24 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v24
    end

    p13.length = v24.length(p13.children[p13.right + 1]) * p13.weight + v24.length(p13.children[p13.left + 1]) * (1 - p13.weight)
    t1.PhaseBlend.set_time(p13, p13.length * p14)
end

function t1.PhaseBlend.set_speed(p15, p16) -- line: 186
    -- upvalues: import (copy), v10 (ref), t1 (copy)
    local v25 = v10

    if v25 == nil then
        v25 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v25
    end

    local v26 = t1.PhaseBlend.phase(p15)

    for _, v27 in p15.order do
        v25.set_speed(p15.children[v27 + 1], p16)
    end

    t1.PhaseBlend.update_length(p15, v26)
end

function t1.PhaseBlend.advance_reference(p17, p18, p19, p20) -- line: 196
    -- upvalues: import (copy), v10 (ref)
    local v28 = v10

    if v28 == nil then
        v28 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v28
    end

    local v29 = v28.length(p17.children[p17.left + 1])
    local v30 = v28.length(p17.children[p17.right + 1])
    local v31 = p18 / p17.length

    v28.advance(p17.children[p17.left + 1], v31 * v29, p19, p20)

    local t4 = {
        crossed_end = false,
        overshoot = -1,
        remaining_before_wrap = -1
    }

    v28.advance(p17.children[p17.right + 1], v31 * v30, p19, t4)

    local v32 = 1 / v29

    p17.time = v28.time(p17.children[p17.left + 1]) * v32 * p17.length
    p20.remaining_before_wrap = p20.remaining_before_wrap * v32 * p17.length
    p20.overshoot = v32 * p17.length * p20.overshoot
end

local t5 = {}
local n2 = 0

function t1.PhaseBlend.advance(p21, p22, p23, p24) -- line: 221
    -- upvalues: import (copy), v10 (ref), t5 (copy), n2 (ref)
    local v33 = v10

    if v33 == nil then
        v33 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v33
    end

    local v34 = v33.length(p21.children[p21.left + 1])
    local v35 = v33.length(p21.children[p21.right + 1])
    local v36 = p22 / p21.length

    v33.advance(p21.children[p21.left + 1], v36 * v34, p23, p24)

    local v37 = n2
    local v38

    if v37 == 0 then
        v38 = {
            crossed_end = false,
            overshoot = -1,
            remaining_before_wrap = -1
        }
    else
        v38 = t5[v37]
        t5[v37] = nil
        n2 = v37 - 1
        v38.crossed_end = false
        v38.overshoot = -1
        v38.remaining_before_wrap = -1
    end

    v33.advance(p21.children[p21.right + 1], v36 * v35, p23, v38)

    local v39 = n2 + 1

    n2 = v39
    t5[v39] = v38

    local v40 = 1 / v34

    p21.time = v33.time(p21.children[p21.left + 1]) * v40 * p21.length
    p24.remaining_before_wrap = p24.remaining_before_wrap * v40 * p21.length
    p24.overshoot = v40 * p21.length * p24.overshoot
end

function t1.discarded_pool() -- line: 252
    -- upvalues: t5 (copy), n2 (ref)
    return n2, t5
end

function t1.PhaseBlend.set_attributes_reference(p25, p26) -- line: 257
    -- upvalues: rt (copy), v1 (copy), import (copy), MotionGraphAttribute (copy), v10 (ref), t1 (copy), eq (copy)
    local v41 = v10

    if v41 == nil then
        v41 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v41
    end

    local v42 = false

    for _, v43 in p25.order do
        local v44 = v41.set_attributes(p25.children[v43 + 1], p26)

        v42 = v42 or v44
    end

    local v45

    for _, v46 in p26 do
        if eq(v46.name, p25.parameter) then
            v45 = v46
            break
        end
    end

    local v47, v48

    if v45 ~= nil then
        if v45.normalized == p25.normalized then
            if math.abs(v45.value - p25.parameter_value) < 9.999999747378752E-05 then
                v47 = v42
                v48 = true
            else
                v48 = false
            end
        else
            v48 = false
        end
    else
        v47 = v42
        v48 = true
    end

    if not v48 then
        p25.parameter_value = v45.value
        v47 = true
        p25.normalized = v45.normalized
    end

    if not v47 then
        return false
    end

    for _, v50 in p25.order do
        local v51 = MotionGraphAttribute.to_animation({
            value = 0,
            name = rt.copy(p25.parameter)
        })

        v41.query_attribute(p25.children[v50 + 1], p25.parameter, 15, v51)

        local v52 = v51.payload[1][1]

        if v52 == nil then
            error("Uninitialized PhaseBlend parameter", 0)
        end

        local values = p25.values
        local v53 = v50 + 1

        buffer.writeu32(v1, 0, v52)
        values[v53] = buffer.readf32(v1, 0)
    end

    local order, values = p25.order, p25.values

    for i = #order - 1, 1, -1 do
        for j = 0, i - 1 do
            if values[order[j + 2] + 1] < values[order[j + 1] + 1] then
                local v54 = order[j + 1]

                order[j + 1] = order[j + 2]
                order[j + 2] = v54
            end
        end
    end

    local v55 = values[order[1] + 1]
    local v56 = values[order[#order] + 1]
    local v57 = if p25.normalized then (v56 - v55) * p25.parameter_value + v55 else p25.parameter_value
    local v58 = #order
    local n3 = 0

    while v58 ~= 0 do
        local v59 = rt.idiv(v58, 2)
        local v60 = n3 + v59

        if values[order[v60 + 1] + 1] < v57 then
            n3 = v60 + 1
            v58 -= v59 + 1
        else
            v58 = v59
        end
    end

    local v63 = math.min(math.max(n3, 1), #order - 1)
    local v64 = order[v63]
    local v65 = order[v63 + 1]
    local v66 = values[v64 + 1]
    local v67 = values[v65 + 1]
    local v68 = v67 - v66

    if v66 - v57 >= 0 then
        v57 = v66
    end

    if not (v67 - v57 >= 0) then
        v57 = v67
    end

    local v69 = v57 - v66

    if v68 == 0 then
        v68 = 1
    end

    local v70 = v69 / v68

    if -v70 >= 0 then
        v70 = 0
    end

    p25.weight = if not (1 - v70 >= 0) then 1 else v70

    local v71 = t1.PhaseBlend.phase(p25)

    p25.left = v64
    p25.right = v65
    t1.PhaseBlend.update_length(p25, v71)

    return true
end

function t1.PhaseBlend.set_attributes(p27, p28) -- line: 349
    -- upvalues: rt (copy), v1 (copy), import (copy), v10 (ref), t1 (copy), query_scratch (copy), t2 (copy), n1 (ref), query_word (copy)
    local v72 = v10

    if v72 == nil then
        v72 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v72
    end

    local v73 = false

    for _, v74 in p27.order do
        local v75 = v72.set_attributes(p27.children[v74 + 1], p28)

        v73 = v73 or v75
    end

    local v76, v77, v78, v79, v80
    local v81 = false
    local v82

    for _, v83 in p28 do
        local v84 = v83.name[1]

        if not v81 then
            local v85 = p27.parameter[1]

            v76 = v85[1]
            v77 = v85[2]
            v78 = v85[3]
            v79 = v85[4]
            v80 = v85[5]
            v81 = true
        end

        if v84[1] == v76 and v84[2] == v77 and v84[3] == v78 and v84[4] == v79 and v84[5] == v80 then
            v82 = v83
            break
        end

        v82 = nil
    end

    local v86, v87

    if v82 ~= nil then
        if v82.normalized == p27.normalized then
            if math.abs(v82.value - p27.parameter_value) < 9.999999747378752E-05 then
                v86 = v73
                v87 = true
            else
                v87 = false
            end
        else
            v87 = false
        end
    else
        v86 = v73
        v87 = true
    end

    if not v87 then
        p27.parameter_value = v82.value
        v86 = true
        p27.normalized = v82.normalized
    end

    if not v86 then
        return false
    end

    for _, v89 in p27.order do
        local v90 = p27.children[v89 + 1]
        local v91

        if v90.tag == "Clip" then
            v91 = query_word(v90.clip, p27.parameter, 15)
        else
            local parameter = p27.parameter
            local v92 = n1
            local v93

            if v92 == 0 then
                v93 = query_scratch(parameter)
                v93.scratch = true
            else
                v93 = t2[v92]
                t2[v92] = nil
                n1 = v92 - 1

                local v94 = v93.payload[1]

                v94[1] = 0
                v94[2] = nil
                v94[3] = nil
                v94[4] = nil
                v94[5] = nil
                v94[6] = nil
                v93.begin_time = -1
                v93.end_time = -1
                v93.name = parameter
                v93.status = 6
                v93.kind = 0
                v93.sequence_id = -1
            end

            v72.query_attribute(v90, p27.parameter, 15, v93)
            v91 = v93.payload[1][1]

            local v95 = n1 + 1

            n1 = v95
            t2[v95] = v93
        end

        if v91 == nil then
            error("Uninitialized PhaseBlend parameter", 0)
        end

        local values = p27.values
        local v96 = v89 + 1

        buffer.writeu32(v1, 0, v91)
        values[v96] = buffer.readf32(v1, 0)
    end

    local order, values = p27.order, p27.values

    for i = #order - 1, 1, -1 do
        for j = 0, i - 1 do
            if values[order[j + 2] + 1] < values[order[j + 1] + 1] then
                local v97 = order[j + 1]

                order[j + 1] = order[j + 2]
                order[j + 2] = v97
            end
        end
    end

    local v98 = values[order[1] + 1]
    local v99 = values[order[#order] + 1]
    local v100 = if p27.normalized then (v99 - v98) * p27.parameter_value + v98 else p27.parameter_value
    local v101 = #order
    local n4 = 0

    while v101 ~= 0 do
        local v102 = rt.idiv(v101, 2)
        local v103 = n4 + v102

        if values[order[v103 + 1] + 1] < v100 then
            n4 = v103 + 1
            v101 -= v102 + 1
        else
            v101 = v102
        end
    end

    local v106 = math.min(math.max(n4, 1), #order - 1)
    local v107 = order[v106]
    local v108 = order[v106 + 1]
    local v109 = values[v107 + 1]
    local v110 = values[v108 + 1]
    local v111 = v110 - v109

    if v109 - v100 >= 0 then
        v100 = v109
    end

    if not (v110 - v100 >= 0) then
        v100 = v110
    end

    local v112 = v100 - v109

    if v111 == 0 then
        v111 = 1
    end

    local v113 = v112 / v111

    if -v113 >= 0 then
        v113 = 0
    end

    p27.weight = if not (1 - v113 >= 0) then 1 else v113

    local v114 = t1.PhaseBlend.phase(p27)

    p27.left = v107
    p27.right = v108
    t1.PhaseBlend.update_length(p27, v114)

    return true
end

function t1.PhaseBlend.attributes(p29, p30) -- line: 465
    -- upvalues: import (copy), v9 (copy), v10 (ref)
    local v115 = v10

    if v115 == nil then
        v115 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v115
    end

    if p29.weight < p29.cull_threshold then
        return v115.attributes(p29.children[p29.left + 1], p30)
    end

    if p29.weight > 1 - p29.cull_threshold then
        return v115.attributes(p29.children[p29.right + 1], p30)
    end

    local v116 = v115.attributes(p29.children[p29.left + 1], p30)
    local v117 = v115.attributes(p29.children[p29.right + 1], 31)

    return v9.intersection(v116, v117, p29.weight)
end

function t1.PhaseBlend.query_attribute_reference(p31, p32, p33, p34) -- line: 479
    -- upvalues: rt (copy), import (copy), MotionGraphAttribute (copy), v9 (copy), v10 (ref)
    local v118 = v10

    if v118 == nil then
        v118 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v118
    end

    if p31.weight < p31.cull_threshold then
        return v118.query_attribute(p31.children[p31.left + 1], p32, p33, p34)
    end

    if p31.weight > 1 - p31.cull_threshold then
        return v118.query_attribute(p31.children[p31.right + 1], p32, p33, p34)
    end

    local v119 = v118.query_attribute(p31.children[p31.left + 1], p32, p33, p34)
    local v120 = MotionGraphAttribute.to_animation({
        value = 0,
        name = rt.copy(p32)
    })
    local v121 = v118.query_attribute(p31.children[p31.right + 1], p32, 31, v120)

    if not v119 or not v121 then
        return false
    end

    v9.blend(p34, v120, p31.weight)

    return true
end

function t1.PhaseBlend.query_attribute(p35, p36, p37, p38) -- line: 501
    -- upvalues: import (copy), v9 (copy), v10 (ref), query_scratch (copy), t2 (copy), n1 (ref)
    local v122 = v10

    if v122 == nil then
        v122 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v122
    end

    if p35.weight < p35.cull_threshold then
        return v122.query_attribute(p35.children[p35.left + 1], p36, p37, p38)
    end

    if p35.weight > 1 - p35.cull_threshold then
        return v122.query_attribute(p35.children[p35.right + 1], p36, p37, p38)
    end

    local v123 = v122.query_attribute(p35.children[p35.left + 1], p36, p37, p38)
    local v124 = n1
    local v125

    if v124 == 0 then
        v125 = query_scratch(p36)
        v125.scratch = true
    else
        v125 = t2[v124]
        t2[v124] = nil
        n1 = v124 - 1

        local v126 = v125.payload[1]

        v126[1] = 0
        v126[2] = nil
        v126[3] = nil
        v126[4] = nil
        v126[5] = nil
        v126[6] = nil
        v125.begin_time = -1
        v125.end_time = -1
        v125.name = p36
        v125.status = 6
        v125.kind = 0
        v125.sequence_id = -1
    end

    local v127 = v122.query_attribute(p35.children[p35.right + 1], p36, 31, v125)

    if not v123 or not v127 then
        local v128 = n1 + 1

        n1 = v128
        t2[v128] = v125

        return false
    end

    v9.blend(p38, v125, p35.weight)

    local v129 = n1 + 1

    n1 = v129
    t2[v129] = v125

    return true
end

function t1.PhaseBlend.evaluate(p39, p40, p41, p42) -- line: 526
    -- upvalues: v1 (copy), import (copy), v10 (ref)
    local v130 = v10

    if v130 == nil then
        v130 = import("skate_core/animation/playback_tree").PlaybackTree
        v10 = v130
    end

    p39.cull_threshold = p40.cull_threshold

    local cull_threshold = p40.cull_threshold
    local v131 = if cull_threshold - p39.weight >= 0 then cull_threshold else p39.weight
    local v132 = 1 - cull_threshold

    if not (v132 - v131 >= 0) then
        v131 = v132
    end

    local v133 = (v131 - cull_threshold) / (-cull_threshold * 2 + 1)
    local v134 = v133 * v133
    local v135

    if not (v133 > 0.5) and p39.left == p39.order[1] then
        local v136 = (-v133 * 4 + 4) * v134

        if v136 ~= 0 and v136 > -1.1754943508222875E-38 and v136 < 1.1754943508222875E-38 then
            local v137 = math.abs(v136) * 7.1362384635298E+44
            local v138 = math.floor(v137)
            local v139 = v137 - v138

            v135 = (if v139 > 0.5 or v139 == 0.5 and v138 % 2 == 1 then v138 + 1 else v138) * 1.401298464324817E-45

            if v136 < 0 then
                v135 = -v135
            end
        else
            buffer.writef32(v1, 0, v136)
            v135 = buffer.readf32(v1, 0)
        end
    elseif not (v133 > 0.5) or p39.right ~= p39.order[#p39.order] then
        v135 = p39.weight
    else
        local v140 = v133 * 4
        local v141 = (8 - v140) * v134 + -v140 + 1

        if v141 ~= 0 and v141 > -1.1754943508222875E-38 and v141 < 1.1754943508222875E-38 then
            local v142 = math.abs(v141) * 7.1362384635298E+44
            local v143 = math.floor(v142)
            local v144 = v142 - v143

            v135 = (if v144 > 0.5 or v144 == 0.5 and v143 % 2 == 1 then v143 + 1 else v143) * 1.401298464324817E-45

            if v141 < 0 then
                v135 = -v135
            end
        else
            buffer.writef32(v1, 0, v141)
            v135 = buffer.readf32(v1, 0)
        end
    end

    local v145 = v130.evaluate(p39.children[p39.left + 1], p40, p41 and v135 < 1, p42)
    local v146 = v130.evaluate(p39.children[p39.right + 1], p40, p41 and v135 > 0, p42)

    if v145 and v146 then
        table.insert(p42, {
            tag = "Blend",
            weight = v135
        })
    end

    return v145 or v146
end

return t1
