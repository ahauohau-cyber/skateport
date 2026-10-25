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
local v8 = import("skate_core/camera/vector_tracker")
local v9 = import("skate_core/camera/orientation_math")
local v10 = import("skate_core/physics/native_arithmetic")
local v11 = import("skate_core/input/angle")
local length, length3 = v8.length, v8.length3
local PERF = import("skate_core/camera/tracker").PERF
local t1 = {
    DropSettings = {},
    DropCollisionProvider = {},
    Probe = {},
    DropPredictor = {}
}

function t1.DropPredictor.new() -- line: 66
    -- upvalues: rt (copy)
    return {
        has_normal = false,
        elevation = 0,
        distance_offset = 0,
        target_elevation = 0,
        spacing = 0,
        selected = 0,
        pending = nil,
        horizontal_velocity = { 0, 0, 0, 0 },
        steepest_normal = { 0, 0, 0, 0 },
        probes = rt.filled(5, {
            start = { 0, 0, 0, 0 },
            ["end"] = { 0, 0, 0, 0 },
            normal = { 0, 0, 0, 0 },
            depth = 0,
            valid = false,
            hit = false
        })
    }
end

function t1.DropPredictor.reset(p4) -- line: 90
    p4.horizontal_velocity = { 0, 0, 0, 0 }
    p4.steepest_normal = { 0, 0, 0, 0 }
    p4.has_normal = false
    p4.elevation = 0
    p4.distance_offset = 0
    p4.target_elevation = 0
    p4.spacing = 0
    p4.selected = 0
    p4.pending = nil
end

function t1.DropPredictor.prediction_velocity(p5, p6, p7, p8) -- line: 103
    -- upvalues: rt (copy), length (copy)
    if p5 or p8.minimum_test_distance > length(p7) then
        local v12 = p6[3]

        return {
            v12[1] * p8.minimum_test_distance,
            v12[2] * p8.minimum_test_distance,
            v12[3] * p8.minimum_test_distance,
            v12[4] * p8.minimum_test_distance
        }
    end

    return rt.copy(p7)
end

function t1.DropPredictor.update_reference(p9, p10, p11, p12, p13, p14, p15, p16) -- line: 118
    -- upvalues: length (copy), t1 (copy)
    p9.horizontal_velocity = {
        p11[1],
        0,
        p11[3],
        0
    }

    if p12 then
        local v13 = length(p9.horizontal_velocity) * p15.total_test_time

        if -v13 >= 0 then
            v13 = 0
        end

        if not (p15.maximum_test_distance - v13 >= 0) then
            v13 = p15.maximum_test_distance
        end

        p9.spacing = v13 / 5

        local pending = p9.pending

        p9.pending = nil

        if pending ~= nil then
            t1.DropPredictor.consume(p9, pending[1], pending[2], p15.maximum_drop_distance)
        end

        local v14 = t1.DropPredictor.lines(p9, p10, p15.maximum_drop_distance)

        p9.pending = {
            v14,
            (p16.query(p16, v14, p14))
        }
        p9.selected = 0

        local n1 = 0

        for i = 0, 4 do
            local v15 = p9.probes[i + 1]

            if not v15.valid then
                break
            end

            if n1 < v15.depth then
                p9.selected = i
                n1 = v15.depth
            end
        end
    else
        p9.selected = 0

        for _, v16 in ipairs(p9.probes) do
            v16.valid = false
            v16.depth = 0
        end
    end

    t1.DropPredictor.update_elevation(p9, p12, p13)
end

function t1.DropPredictor.drop_depth(p17) -- line: 165
    local v17 = p17.probes[p17.selected + 1]

    if v17.valid then
        return v17.depth
    end

    return 0
end

function t1.DropPredictor.lines_reference(p18, p19, p20) -- line: 170
    -- upvalues: rt (copy), v9 (copy)
    local v18 = v9.normalize(p18.horizontal_velocity)
    local t2 = {
        0, 1, 0, 0
    }
    local v19 = table.create(10)

    for i = 0, 9 do
        local t3 = {}

        for j = 0, 3 do
            t3[j + 1] = v18[j + 1] * p18.spacing * (rt.idiv(i, 2) + 1) + p19[j + 1]
        end

        if rt.irem(i, 2) == 0 then
            v19[i + 1] = {
                start = rt.copy(p19),
                ["end"] = t3,
                radius = 0.009999999776482582
            }
        else
            local t4 = {}

            t4[1] = t3[1] - t2[1] * p20
            t4[2] = t3[2] - t2[2] * p20
            t4[3] = t3[3] - t2[3] * p20
            t4[4] = t3[4] - t2[4] * p20
            v19[i + 1] = {
                start = t3,
                ["end"] = t4,
                radius = 0.10000000149011612
            }
        end
    end

    return v19
end

function t1.DropPredictor.consume_reference(p21, p22, p23, p24) -- line: 200
    -- upvalues: rt (copy), length (copy)
    p21.has_normal = false

    for i = 0, 4 do
        if p23[i * 2 + 1].hit ~= 0 then
            for j = i, 4 do
                local v20 = p21.probes[j + 1]

                v20.valid = false
                v20.depth = 0
            end

            break
        end

        local v21 = p22[i * 2 + 2]
        local v22 = p23[i * 2 + 2]
        local v23 = p21.probes[i + 1]

        rt.assign(v23, {
            start = v21.start,
            ["end"] = v21["end"],
            normal = { 0, 0, 0, 0 },
            depth = p24,
            valid = true,
            hit = v22.hit ~= 0
        })

        if v23.hit then
            v23.depth = length({
                v22.position[1] - v21.start[1],
                v22.position[2] - v21.start[2],
                v22.position[3] - v21.start[3],
                v22.position[4] - v21.start[4]
            })
            v23["end"] = rt.copy(v22.position)
            v23.normal = rt.copy(v22.normal)

            if not p21.has_normal or math.abs(p21.steepest_normal[2]) > math.abs(v22.normal[2]) then
                p21.steepest_normal = rt.copy(v22.normal)
                p21.has_normal = true
            end
        end
    end
end

function t1.DropPredictor.update_elevation_reference(p25, p26, p27) -- line: 239
    -- upvalues: v1 (copy), v10 (copy), v11 (copy)
    local v28 = p25.probes[p25.selected + 1]
    local v29

    if v28.valid then
        local v30 = (p25.selected + 1) * p25.spacing
        local v31 = v10.reciprocal_estimate(v30)
        local v32 = v31 * (-v31 * v30 + 1) + v31
        local v33 = v11.atan(v28.depth * v32 + 0)
        local depth = v28.depth
        local v34

        if depth == 0 then
            buffer.writef32(v1, 0, depth)
            v34 = buffer.readu32(v1, 0)
        elseif depth > -1.1754943508222875E-38 and depth < 1.1754943508222875E-38 then
            local v35 = math.abs(depth) * 7.1362384635298E+44

            v34 = math.floor(v35)

            local v36 = v35 - v34

            if v36 > 0.5 or v36 == 0.5 and v34 % 2 == 1 then
                v34 += 1
            end

            if depth < 0 then
                v34 += 2147483648
            end
        else
            buffer.writef32(v1, 0, depth)
            v34 = buffer.readu32(v1, 0)
        end

        local v37 = bit32.band(v34, 2147483648)

        if v30 < 0 then
            buffer.writeu32(v1, 0, (bit32.bor(1078530011, v37)))
            v29 = buffer.readf32(v1, 0) + v33
        else
            v29 = v33
        end

        if v30 == 0 then
            buffer.writeu32(v1, 0, (bit32.bor(1070141403, v37)))
            v29 = buffer.readf32(v1, 0)
        end
    else
        v29 = 0
    end

    if v29 - 1.5707963705062866 >= 0 then
        v29 = 1.5707963705062866
    end

    local v40 = (if p27 then 40 else 70) * 0.01745329238474369

    if not (v29 - v40 >= 0) then
        v40 = v29
    end

    if not (p26 and v40 >= 0.2617993950843811) then
        p25.target_elevation = 0
    else
        p25.target_elevation = v40
    end

    local v42 = math.abs(p25.target_elevation - p25.elevation) * 57.295780181884766
    local v43 = (v42 - 7) * 0.04545454680919647 + 0.10000000149011612

    if 0.10000000149011612 - v43 >= 0 then
        v43 = 0.10000000149011612
    end

    if not (1.600000023841858 - v43 >= 0) then
        v43 = 1.600000023841858
    end

    if v43 < v42 then
        if p25.elevation >= p25.target_elevation then
            p25.elevation = -(v43 * 0.01745329238474369 + -p25.elevation)
        else
            p25.elevation = v43 * 0.01745329238474369 + p25.elevation
        end
    else
        p25.elevation = p25.target_elevation
    end
end

local self = setmetatable({}, {
    __mode = "k"
})

function t1.DropPredictor.prediction_velocity_lanes(p28, p29, p30, p31) -- line: 317
    -- upvalues: length3 (copy)
    local v45 = p30[1]
    local v46 = p30[2]
    local v47 = p30[3]

    if p28 or p31.minimum_test_distance > length3(v45, v46, v47) then
        local v48 = p29[3]
        local minimum_test_distance = p31.minimum_test_distance

        return v48[1] * minimum_test_distance, v48[2] * minimum_test_distance, v48[3] * minimum_test_distance, v48[4] * minimum_test_distance
    end

    return v45, v46, v47, p30[4]
end

local function write_lines(p32, p33, p34, p35) -- line: 336
    local horizontal_velocity = p32.horizontal_velocity
    local v49 = horizontal_velocity[1]
    local v50 = horizontal_velocity[2]
    local v51 = horizontal_velocity[3]
    local v52 = horizontal_velocity[4]
    local v53 = v49 * v49 + v50 * v50 + v51 * v51
    local v54 = 1 / math.sqrt(v53)
    local v55 = v54 * 0.5 * (-v53 * (v54 * v54) + 1) + v54
    local v56 = v55 * 0.5 * (-v53 * (v55 * v55) + 1) + v55
    local spacing = p32.spacing
    local v57 = v49 * v56 * spacing
    local v58 = v50 * v56 * spacing
    local v59 = v51 * v56 * spacing
    local v60 = v52 * v56 * spacing
    local v61 = p33[1]
    local v62 = p33[2]
    local v63 = p33[3]
    local v64 = p33[4]

    for i = 0, 4 do
        local v65 = i + 1
        local v66 = v57 * v65 + v61
        local v67 = v58 * v65 + v62
        local v68 = v59 * v65 + v63
        local v69 = v60 * v65 + v64
        local v70 = p35[i * 2 + 1]
        local start, v71 = v70.start, v70["end"]

        start[1] = v61
        start[2] = v62
        start[3] = v63
        start[4] = v64
        v71[1] = v66
        v71[2] = v67
        v71[3] = v68
        v71[4] = v69
        v70.radius = 0.009999999776482582

        local v72 = p35[i * 2 + 2]
        local start2, v73 = v72.start, v72["end"]

        start2[1] = v66
        start2[2] = v67
        start2[3] = v68
        start2[4] = v69

        local v74 = v66 - p34 * 0
        local v75 = v67 - p34 * 1
        local v76 = v68 - p34 * 0
        local v77 = v69 - p34 * 0

        v73[1] = v74
        v73[2] = v75
        v73[3] = v76
        v73[4] = v77
        v72.radius = 0.10000000149011612
    end

    return p35
end

local function new_lines() -- line: 366
    local v78 = table.create(10)

    for i = 1, 10 do
        v78[i] = {
            start = { 0, 0, 0, 0 },
            ["end"] = { 0, 0, 0, 0 },
            radius = 0
        }
    end

    return v78
end

function t1.DropPredictor.lines(p36, p37, p38) -- line: 374
    -- upvalues: PERF (copy), t1 (copy), write_lines (copy), new_lines (copy)
    if PERF.reference then
        return t1.DropPredictor.lines_reference(p36, p37, p38)
    end

    return (write_lines(p36, p37, p38, (new_lines())))
end

function t1.DropPredictor.consume(p39, p40, p41, p42) -- line: 381
    -- upvalues: length3 (copy), PERF (copy), t1 (copy)
    if PERF.reference then
        return t1.DropPredictor.consume_reference(p39, p40, p41, p42)
    end

    p39.has_normal = false

    local probes = p39.probes

    for i = 0, 4 do
        if p41[i * 2 + 1].hit ~= 0 then
            for j = i, 4 do
                local v79 = probes[j + 1]

                v79.valid = false
                v79.depth = 0
            end

            break
        end

        local v80 = p40[i * 2 + 2]
        local v81 = p41[i * 2 + 2]
        local v82 = probes[i + 1]
        local start, v83 = v80.start, v80["end"]
        local v84 = start[1]
        local v85 = start[2]
        local v86 = start[3]
        local v87 = start[4]
        local start2, v88, normal = v82.start, v82["end"], v82.normal

        start2[1] = v84
        start2[2] = v85
        start2[3] = v86
        start2[4] = v87

        local v89 = v81.hit ~= 0

        v82.valid = true
        v82.hit = v89

        if v89 then
            local position, normal2 = v81.position, v81.normal
            local v90 = position[1]
            local v91 = position[2]
            local v92 = position[3]
            local v93 = position[4]
            local v94 = normal2[1]
            local v95 = normal2[2]
            local v96 = normal2[3]
            local v97 = normal2[4]

            v82.depth = length3(v90 - v84, v91 - v85, v92 - v86)
            v88[1] = v90
            v88[2] = v91
            v88[3] = v92
            v88[4] = v93
            normal[1] = v94
            normal[2] = v95
            normal[3] = v96
            normal[4] = v97

            local steepest_normal, has_normal = p39.steepest_normal, p39.has_normal
            local v98 = if has_normal then math.abs(steepest_normal[2]) > math.abs(v95) else nil

            if not has_normal or v98 then
                steepest_normal[1] = v94
                steepest_normal[2] = v95
                steepest_normal[3] = v96
                steepest_normal[4] = v97
                p39.has_normal = true
            end
        else
            v82.depth = p42

            local v100 = v83[1]
            local v101 = v83[2]
            local v102 = v83[3]
            local v103 = v83[4]

            v88[1] = v100
            v88[2] = v101
            v88[3] = v102
            v88[4] = v103
            normal[1] = 0
            normal[2] = 0
            normal[3] = 0
            normal[4] = 0
        end
    end
end

function t1.DropPredictor.update(p43, p44, p45, p46, p47, p48, p49, p50) -- line: 428
    -- upvalues: PERF (copy), t1 (copy)
    if PERF.reference then
        return t1.DropPredictor.update_reference(p43, p44, p45, p46, p47, p48, p49, p50)
    end

    return t1.DropPredictor.update_lanes(p43, p44, p45[1], p45[3], p46, p47, p48, p49, p50)
end

function t1.DropPredictor.update_lanes(p51, p52, p53, p54, p55, p56, p57, p58, p59) -- line: 445
    -- upvalues: length3 (copy), t1 (copy), self (copy), write_lines (copy), new_lines (copy)
    local horizontal_velocity = p51.horizontal_velocity

    horizontal_velocity[1] = p53
    horizontal_velocity[2] = 0
    horizontal_velocity[3] = p54
    horizontal_velocity[4] = 0

    if p55 then
        local v104 = length3(p53, 0, p54) * p58.total_test_time

        if -v104 >= 0 then
            v104 = 0
        end

        if not (p58.maximum_test_distance - v104 >= 0) then
            v104 = p58.maximum_test_distance
        end

        p51.spacing = v104 / 5

        local pending = p51.pending

        p51.pending = nil

        if pending ~= nil then
            t1.DropPredictor.consume(p51, pending[1], pending[2], p58.maximum_drop_distance)
        end

        local v105 = p59.borrows_lines == true
        local query_into = p59.query_into

        if pending ~= nil and v105 and query_into ~= nil and self[pending] then
            query_into(p59, write_lines(p51, p52, p58.maximum_drop_distance, pending[1]), p57, pending[2])
            p51.pending = pending
        else
            local v106 = write_lines(p51, p52, p58.maximum_drop_distance, (new_lines()))
            local t8 = {
                v106,
                (p59.query(p59, v106, p57))
            }

            if v105 then
                self[t8] = true
            end

            p51.pending = t8
        end

        p51.selected = 0

        local probes = p51.probes
        local n2 = 0

        for i = 0, 4 do
            local v107 = probes[i + 1]

            if not v107.valid then
                break
            end

            if n2 < v107.depth then
                p51.selected = i
                n2 = v107.depth
            end
        end
    else
        p51.selected = 0

        for _, v108 in ipairs(p51.probes) do
            v108.valid = false
            v108.depth = 0
        end
    end

    t1.DropPredictor.update_elevation(p51, p55, p56)
end

local atan = v11.atan

function t1.DropPredictor.update_elevation(p60, p61, p62) -- line: 519
    -- upvalues: v1 (copy), PERF (copy), t1 (copy), atan (copy)
    if PERF.reference then
        return t1.DropPredictor.update_elevation_reference(p60, p61, p62)
    end

    local v109 = p60.probes[p60.selected + 1]
    local v110 = false
    local v111 = false
    local v112 = false
    local v113 = false
    local v114 = false
    local v115 = false
    local v116

    if v109.valid then
        v110 = true
    else
        v116 = 0
        v115 = true
    end

    local v117, depth, v118, v119

    if v110 then
        v117 = (p60.selected + 1) * p60.spacing
        depth = v109.depth

        local v120 = 1 / v117

        v118 = atan(depth * (v120 * (-v120 * v117 + 1) + v120) + 0)

        if v117 < 0 then
            v111 = true
        else
            v119 = v118
            v115 = false
        end
    end

    v110 = false

    if v111 then
        if depth == 0 then
            v112 = true
        else
            v110 = true
        end
    end

    v111 = false

    if v110 then
        if depth > -1.1754943508222875E-38 then
            v111 = true
        else
            v112 = true
        end
    end

    v110 = false

    if v111 then
        if depth < 1.1754943508222875E-38 then
            v110 = true
        else
            v112 = true
        end
    end

    v111 = false

    local v122

    if v112 then
        buffer.writef32(v1, 0, depth)
        v122 = buffer.readu32(v1, 0)
        v111 = true
    end

    v112 = false

    local v123, v124

    if v110 then
        local v125 = math.abs(depth) * 7.1362384635298E+44

        v123 = math.floor(v125)
        v124 = v125 - v123

        if v124 > 0.5 then
            v113 = true
        else
            v112 = true
        end
    end

    v110 = false

    local v126

    if v112 then
        if v124 == 0.5 then
            v110 = true
        else
            v126 = v123
            v114 = true
        end
    end

    if v110 then
        if v123 % 2 == 1 then
            v113 = true
        else
            v126 = v123
            v114 = true
        end
    end

    v110 = false

    if v113 then
        v126 = v123 + 1
        v114 = true
    end

    v113 = false

    if v114 then
        if depth < 0 then
            v113 = true
        else
            v110 = true
        end
    end

    if v110 then
        v122 = v126
        v111 = true
    end

    v110 = false

    if v113 then
        v122 = v126 + 2147483648
        v111 = true
    end

    v113 = false

    if v111 then
        if bit32.band(v122, 2147483648) == 0 then
            v110 = true
        else
            v113 = true
        end
    end

    if v113 then
        v119 = v118 + -3.1415927410125732
        v115 = false
    end

    if v110 then
        v119 = v118 + 3.1415927410125732
        v115 = false
    end

    if not v115 then
        if v117 == 0 then
            local v127

            if depth == 0 then
                buffer.writef32(v1, 0, depth)
                v127 = buffer.readu32(v1, 0)
            elseif depth > -1.1754943508222875E-38 and depth < 1.1754943508222875E-38 then
                local v128 = math.abs(depth) * 7.1362384635298E+44

                v127 = math.floor(v128)

                local v129 = v128 - v127

                if v129 > 0.5 or v129 == 0.5 and v127 % 2 == 1 then
                    v127 += 1
                end

                if depth < 0 then
                    v127 += 2147483648
                end
            else
                buffer.writef32(v1, 0, depth)
                v127 = buffer.readu32(v1, 0)
            end

            v116 = if bit32.band(v127, 2147483648) == 0 then 1.5707963705062866 else -1.5707963705062866
        else
            v116 = v119
        end
    end

    if v116 - 1.5707963705062866 >= 0 then
        v116 = 1.5707963705062866
    end

    local v130 = (if p62 then 40 else 70) * 0.01745329238474369

    if not (v116 - v130 >= 0) then
        v130 = v116
    end

    if not (p61 and v130 >= 0.2617993950843811) then
        v130 = 0
    end

    p60.target_elevation = v130

    local elevation = p60.elevation
    local v132 = math.abs(v130 - elevation) * 57.295780181884766
    local v133 = (v132 - 7) * 0.04545454680919647 + 0.10000000149011612

    if 0.10000000149011612 - v133 >= 0 then
        v133 = 0.10000000149011612
    end

    if not (1.600000023841858 - v133 >= 0) then
        v133 = 1.600000023841858
    end

    if v133 < v132 then
        if v130 <= elevation then
            p60.elevation = -(v133 * 0.01745329238474369 + -elevation)
        else
            p60.elevation = v133 * 0.01745329238474369 + elevation
        end
    else
        p60.elevation = v130
    end
end

return t1
