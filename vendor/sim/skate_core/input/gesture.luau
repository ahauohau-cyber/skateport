-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

require(sim.import)

local t1 = {
    Pattern = {}
}

function t1.Pattern.eq(p2, p3) -- line: 24
    if p2.name ~= p3.name or p2.tolerance_squared ~= p3.tolerance_squared or #p2.points ~= #p3.points then
        return false
    end

    for i = 1, #p2.points do
        if p2.points[i][1] ~= p3.points[i][1] or p2.points[i][2] ~= p3.points[i][2] then
            return false
        end
    end

    return true
end

t1.Settings = {}
t1.Node = {}

function t1.Node.default() -- line: 43
    return {
        active = false,
        complete = false,
        next = 0,
        elapsed = 0,
        misses = 0,
        distance = 0
    }
end

function t1.Node.tick_reference(p4, p5, p6, p7) -- line: 55
    -- upvalues: rt (copy), t1 (copy)
    if p4.active then
        if not p4.complete then
            local v1 = t1.distance_squared(p5.points[p4.next + 1], p6)

            if v1 <= p5.tolerance_squared then
                p4.distance += v1
                p4.elapsed = bit32.band(p4.elapsed + 1, 1023)

                if p4.next + 1 == #p5.points then
                    p4.complete = true
                else
                    p4.next += 1
                    p4.misses = 0
                end
            else
                if p4.next ~= 1 or t1.distance_squared(p5.points[1], p6) > p5.tolerance_squared then
                    p4.elapsed = bit32.band(p4.elapsed + 1, 1023)
                    p4.misses = bit32.band(p4.misses + 1, 63)
                end

                if p7 < p4.misses then
                    rt.assign(p4, t1.Node.default())
                end
            end
        end
    else
        local v7 = t1.distance_squared(p5.points[1], p6)

        if v7 <= p5.tolerance_squared then
            local v8 = t1.Node.default()

            v8.active = true
            v8.next = 1
            v8.elapsed = 1
            v8.distance = v7
            rt.assign(p4, v8)
        end
    end
end

local function tick_scalar(p8, p9, p10, p11, p12) -- line: 99
    -- upvalues: rt (copy), t1 (copy)
    local active = p8.active
    local v9, v10, complete

    if active then
        complete = p8.complete
    else
        local v11 = p9.points[1]
        local v12 = v11[1] - p10
        local v13 = v11[2] - p11

        v9 = v12 * v12 + v13 * v13
        v10 = v9 <= p9.tolerance_squared
    end

    if active and complete or not active and not v10 then
        return false
    end

    if active then
        local points = p9.points
        local v14 = points[p8.next + 1]
        local v15 = v14[1] - p10
        local v16 = v14[2] - p11
        local v17 = v15 * v15 + v16 * v16

        if v17 <= p9.tolerance_squared then
            p8.distance += v17
            p8.elapsed = bit32.band(p8.elapsed + 1, 1023)

            if p8.next + 1 == #points then
                p8.complete = true
            else
                p8.next += 1
                p8.misses = 0
            end
        else
            local v19 = p8.next ~= 1

            if not v19 then
                local v20 = points[1]
                local v21 = v20[1] - p10
                local v22 = v20[2] - p11

                v19 = v21 * v21 + v22 * v22 > p9.tolerance_squared
            end

            if v19 then
                p8.elapsed = bit32.band(p8.elapsed + 1, 1023)
                p8.misses = bit32.band(p8.misses + 1, 63)
            end

            if not (p12 < p8.misses) then
                return v19
            end

            rt.assign(p8, t1.Node.default())
        end
    else
        local v25 = t1.Node.default()

        v25.active = true
        v25.next = 1
        v25.elapsed = 1
        v25.distance = v9
        rt.assign(p8, v25)
    end

    return true
end

function t1.Node.tick(p13, p14, p15, p16) -- line: 153
    -- upvalues: tick_scalar (copy)
    tick_scalar(p13, p14, p15[1], p15[2], p16)
end

function t1.Node.score(p17, p18) -- line: 160
    -- upvalues: rt (copy)
    local v26 = rt.fmin(rt.fmax(p17.distance, 0.15) / p18, 0.15)

    return p18 * p18 * p18 * p18 / (v26 * p17.elapsed)
end

function t1.distance_squared(p19, p20) -- line: 166
    local v27 = p19[1] - p20[1]
    local v28 = p19[2] - p20[2]

    return v27 * v27 + v28 * v28
end

t1.Recognition = {}

function t1.Recognition.eq(p21, p22) -- line: 177
    if p21.pattern == p22.pattern and p21.strength == p22.strength and p21.distance == p22.distance then
        return p21.elapsed == p22.elapsed
    end

    return false
end

t1.Recognizer = {}

function t1.Recognizer.new(p23) -- line: 191
    -- upvalues: rt (copy), t1 (copy)
    for _, v29 in p23 do
        local v30 = not (#v29.points >= 2 and #v29.points <= 15)

        if not v30 then
            local tolerance_squared = v29.tolerance_squared

            v30 = not (tolerance_squared == tolerance_squared and tolerance_squared ~= 1e999 and tolerance_squared ~= (-1e999)) or v29.tolerance_squared < 0
        end

        if not v30 then
            local v31 = v30

            for _, v32 in v29.points do
                for _, v33 in v32 do
                    if v33 ~= v33 or v33 == 1e999 or v33 == (-1e999) then
                        v31 = true
                        break
                    end
                end

                if v31 then
                    v30 = v31
                    break
                end

                v30 = v31
            end
        end

        if v30 then
            error("invalid native gesture pattern " .. v29.name, 0)
        end
    end

    return {
        has_previous_sample = false,
        refractory = false,
        held = nil,
        nodes = rt.filled(#p23, t1.Node.default()),
        patterns = p23
    }
end

function t1.Recognizer.patterns(p24) -- line: 222
    return p24.patterns
end

function t1.Recognizer.held(p25, p26) -- line: 229
    -- upvalues: t1 (copy)
    if p25.held == nil then
        return p25.held
    end

    local held = p25.held
    local v34 = p25.patterns[held + 1]

    if t1.distance_squared(v34.points[#v34.points], p26) > v34.tolerance_squared then
        p25.held = nil
    end

    return p25.held
end

function t1.Recognizer.sample_reference(p27, p28, p29) -- line: 242
    -- upvalues: rt (copy), t1 (copy)
    if p27.refractory then
        for i = 1, #p27.nodes do
            p27.nodes[i] = t1.Node.default()
        end

        p27.refractory = false
    else
        if p27.has_previous_sample then
            for i = 1, math.min(#p27.nodes, #p27.patterns) do
                t1.Node.tick(p27.nodes[i], p27.patterns[i], p28, p29.maximum_misses)
            end

            local v37 = #p27.nodes - 1
            local v38

            for i = 0, v37 do
                local v39 = p27.nodes[i + 1]

                if v39.complete and (v38 == nil or t1.Node.score(v39, #p27.patterns[i + 1].points) > t1.Node.score(p27.nodes[v38 + 1], #p27.patterns[v38 + 1].points)) then
                    v38 = i
                end
            end

            if v38 == nil then
                return nil
            end

            local v40 = rt.copy(p27.nodes[v38 + 1])
            local v41 = v40.elapsed / #p27.patterns[v38 + 1].points
            local v42, v43

            if p29.difficulty == 2 then
                v42 = 1.5
                v43 = 3
            else
                v42 = 1.75
                v43 = 4.4
            end

            local v44

            if v41 <= v42 then
                v44 = 1
            elseif v43 <= v41 then
                v44 = 0
            else
                local v45 = 1 / (v42 - v43)

                v44 = v45 * v41 + -(v45 * v43)
            end

            p27.refractory = true
            p27.held = v38

            return {
                pattern = v38,
                strength = v44,
                distance = v40.distance,
                elapsed = v40.elapsed
            }
        end

        p27.has_previous_sample = true
    end

    return nil
end

function t1.Recognizer.sample_w2(p30, p31, p32) -- line: 314
    -- upvalues: rt (copy), t1 (copy), tick_scalar (copy)
    if p30.refractory then
        for i = 1, #p30.nodes do
            p30.nodes[i] = t1.Node.default()
        end

        p30.refractory = false
    else
        if p30.has_previous_sample then
            local nodes, patterns = p30.nodes, p30.patterns
            local v48 = math.min(#nodes, #patterns)
            local v49 = p31[1]
            local v50 = p31[2]
            local maximum_misses = p32.maximum_misses

            for i = 1, v48 do
                tick_scalar(nodes[i], patterns[i], v49, v50, maximum_misses)
            end

            local v51 = #p30.nodes - 1
            local v52

            for i = 0, v51 do
                local v53 = p30.nodes[i + 1]

                if v53.complete and (v52 == nil or t1.Node.score(v53, #p30.patterns[i + 1].points) > t1.Node.score(p30.nodes[v52 + 1], #p30.patterns[v52 + 1].points)) then
                    v52 = i
                end
            end

            if v52 == nil then
                return nil
            end

            local v54 = rt.copy(p30.nodes[v52 + 1])
            local v55 = v54.elapsed / #p30.patterns[v52 + 1].points
            local v56, v57

            if p32.difficulty == 2 then
                v56 = 1.5
                v57 = 3
            else
                v56 = 1.75
                v57 = 4.4
            end

            local v58

            if v55 <= v56 then
                v58 = 1
            elseif v57 <= v55 then
                v58 = 0
            else
                local v59 = 1 / (v56 - v57)

                v58 = v59 * v55 + -(v59 * v57)
            end

            p30.refractory = true
            p30.held = v52

            return {
                pattern = v52,
                strength = v58,
                distance = v54.distance,
                elapsed = v54.elapsed
            }
        end

        p30.has_previous_sample = true
    end

    return nil
end

local v60 = false

function t1.set_sample_w2(p33) -- line: 386
    -- upvalues: v60 (ref)
    v60 = p33
end

local self = setmetatable({}, {
    __mode = "k"
})

function t1.forget(p34) -- line: 396
    -- upvalues: self (copy)
    self[p34] = nil
end

local v62 = false

function t1.set_sample_w3(p35) -- line: 440
    -- upvalues: v62 (ref)
    v62 = p35
end

function t1.Recognizer.sample(p36, p37, p38) -- line: 443
    -- upvalues: rt (copy), t1 (copy), tick_scalar (copy), v60 (ref), self (copy), v62 (ref)
    if v60 then
        return t1.Recognizer.sample_w2(p36, p37, p38)
    end

    if p36.refractory then
        for i = 1, #p36.nodes do
            p36.nodes[i] = t1.Node.default()
        end

        p36.refractory = false

        local v63 = self[p36]

        if v63 ~= nil then
            v63.valid = false
        end
    elseif p36.has_previous_sample then
        local nodes, patterns = p36.nodes, p36.patterns
        local v64 = #nodes
        local v65 = #patterns
        local v66 = math.min(v64, v65)
        local v67 = p37[1]
        local v68 = p37[2]
        local v69 = self[p36]

        if v69 ~= nil then
            if v69.valid and v69.sx == v67 and v69.sy == v68 and v69.nodes == nodes and v69.patterns == patterns and v69.count == v64 and v69.pattern_count == v65 and v69.maximum_misses == p38.maximum_misses then
                return nil
            end

            v69.valid = false
        end

        local maximum_misses = p38.maximum_misses
        local v70 = v66 < v64
        local v71 = v62
        local v72 = true

        for i = 1, v66 do
            local v73 = nodes[i]

            if v73.active then
                if tick_scalar(v73, patterns[i], v67, v68, maximum_misses) or v71 then
                    v72 = false
                end
            else
                local v74 = patterns[i]
                local v75 = v74.points[1]
                local v76 = v75[1] - v67
                local v77 = v75[2] - v68

                if v76 * v76 + v77 * v77 <= v74.tolerance_squared then
                    v72 = false
                    tick_scalar(v73, v74, v67, v68, maximum_misses)
                end
            end

            if v73.complete then
                v70 = true
            end
        end

        if v70 then
            local v78 = #p36.nodes - 1
            local v79

            for i = 0, v78 do
                local v80 = p36.nodes[i + 1]

                if v80.complete and (v79 == nil or t1.Node.score(v80, #p36.patterns[i + 1].points) > t1.Node.score(p36.nodes[v79 + 1], #p36.patterns[v79 + 1].points)) then
                    v79 = i
                end
            end

            if v79 == nil then
                return nil
            end

            local v81 = rt.copy(p36.nodes[v79 + 1])
            local v82 = v81.elapsed / #p36.patterns[v79 + 1].points
            local v83, v84

            if p38.difficulty == 2 then
                v83 = 1.5
                v84 = 3
            else
                v83 = 1.75
                v84 = 4.4
            end

            local v85

            if v82 <= v83 then
                v85 = 1
            elseif v84 <= v82 then
                v85 = 0
            else
                local v86 = 1 / (v83 - v84)

                v85 = v86 * v82 + -(v86 * v84)
            end

            p36.refractory = true
            p36.held = v79

            return {
                pattern = v79,
                strength = v85,
                distance = v81.distance,
                elapsed = v81.elapsed
            }
        end

        if v72 then
            local v87 = v69

            if v69 == nil then
                v87 = {}
                self[p36] = v87
            end

            v87.sx = v67
            v87.sy = v68
            v87.nodes = nodes
            v87.patterns = patterns
            v87.count = v64
            v87.pattern_count = v65
            v87.maximum_misses = maximum_misses
            v87.valid = true
        end
    else
        p36.has_previous_sample = true
    end

    return nil
end

local function tick_hz(p39, p40, p41, p42, p43, p44) -- line: 590
    -- upvalues: rt (copy), t1 (copy)
    local points = p40.points

    if p39.active then
        if not p39.complete then
            local v88 = points[p39.next + 1]
            local v89 = v88[1] - p41
            local v90 = v88[2] - p42
            local v91 = v89 * v89 + v90 * v90

            if v91 <= p40.tolerance_squared then
                p39.distance += v91
                p39.elapsed += p44

                if p39.next + 1 == #points then
                    p39.complete = true
                else
                    p39.next += 1
                    p39.misses = 0
                end
            else
                local v92 = p39.next ~= 1

                if not v92 then
                    local v93 = points[1]
                    local v94 = v93[1] - p41
                    local v95 = v93[2] - p42

                    v92 = v94 * v94 + v95 * v95 > p40.tolerance_squared
                end

                if v92 then
                    p39.elapsed += p44
                    p39.misses += p44
                end

                if p43 <= p39.misses then
                    rt.assign(p39, t1.Node.default())
                end
            end
        end
    else
        local v96 = points[1]
        local v97 = v96[1] - p41
        local v98 = v96[2] - p42
        local v99 = v97 * v97 + v98 * v98

        if v99 <= p40.tolerance_squared then
            local v100 = t1.Node.default()

            v100.active = true
            v100.next = 1
            v100.elapsed = p44
            v100.distance = v99
            rt.assign(p39, v100)
        end
    end
end

function t1.Recognizer.sample_hz(p45, p46, p47, p48) -- line: 639
    -- upvalues: rt (copy), t1 (copy), self (copy), tick_hz (copy)
    self[p45] = nil

    if p45.refractory then
        for i = 1, #p45.nodes do
            p45.nodes[i] = t1.Node.default()
        end

        local v101 = (p45.refractory_units or 6) - p48

        if v101 > 0 then
            p45.refractory_units = v101
        else
            p45.refractory = false
            p45.refractory_units = nil
        end
    else
        if p45.has_previous_sample then
            local nodes, patterns = p45.nodes, p45.patterns
            local v104 = math.min(#nodes, #patterns)
            local v105 = p46[1]
            local v106 = p46[2]
            local v107 = (p47.maximum_misses + 1) * 6

            for i = 1, v104 do
                tick_hz(nodes[i], patterns[i], v105, v106, v107, p48)
            end

            local function score(p49, p50) -- line: 666
                -- upvalues: rt (copy)
                local v108 = rt.fmin(rt.fmax(p49.distance, 0.15) / p50, 0.15)

                return p50 * p50 * p50 * p50 / (v108 * (p49.elapsed / 6))
            end

            local v109 = #nodes - 1
            local v110

            for i = 0, v109 do
                local v111 = nodes[i + 1]

                if v111.complete then
                    local v112 = true

                    if v110 ~= nil then
                        local v113 = #patterns[i + 1].points
                        local v114 = rt.fmin(rt.fmax(v111.distance, 0.15) / v113, 0.15)
                        local v115 = v113 * v113 * v113 * v113 / (v114 * (v111.elapsed / 6))
                        local v116 = nodes[v110 + 1]
                        local v117 = #patterns[v110 + 1].points
                        local v118 = rt.fmin(rt.fmax(v116.distance, 0.15) / v117, 0.15)

                        v112 = v117 * v117 * v117 * v117 / (v118 * (v116.elapsed / 6)) < v115
                    end

                    if v112 then
                        v110 = i
                    end
                end
            end

            if v110 == nil then
                return nil
            end

            local v119 = rt.copy(nodes[v110 + 1])
            local v120 = v119.elapsed / 6
            local v121 = v120 / #patterns[v110 + 1].points
            local v122, v123

            if p47.difficulty == 2 then
                v122 = 1.5
                v123 = 3
            else
                v122 = 1.75
                v123 = 4.4
            end

            local v124

            if v121 <= v122 then
                v124 = 1
            elseif v123 <= v121 then
                v124 = 0
            else
                local v125 = 1 / (v122 - v123)

                v124 = v125 * v121 + -(v125 * v123)
            end

            p45.refractory = true
            p45.refractory_units = 6
            p45.held = v110

            return {
                pattern = v110,
                strength = v124,
                distance = v119.distance,
                elapsed = v120
            }
        end

        p45.has_previous_sample = true
    end

    return nil
end

return t1
