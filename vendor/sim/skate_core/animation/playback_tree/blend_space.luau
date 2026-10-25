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

local import = require(sim.import)
local v1 = import("skate_core/animation/output/attributes")
local v2 = import("skate_core/animation/playback_attributes")
local AttributeName, MotionGraphAttribute = v1.AttributeName, v1.MotionGraphAttribute
local v3

local function PlaybackTree() -- line: 26
    -- upvalues: import (copy), v3 (ref)
    local v4 = v3

    if v4 == nil then
        v4 = import("skate_core/animation/playback_tree").PlaybackTree
        v3 = v4
    end

    return v4
end

local t1 = {}
local fround = rt.fround

local function words_less(p2, p3) -- line: 46
    for i = 1, 5 do
        if p2[i] ~= p3[i] then
            return p2[i] < p3[i]
        end
    end

    return false
end

t1.Simplex = {}

function t1.Simplex.coordinates(p4, p5) -- line: 59
    -- upvalues: rt (copy), fround (copy)
    local v5 = #p4.children
    local v6 = table.create(v5)

    for i = 0, v5 - 1 do
        local v7 = p4.vertices[rt.irem(i + 1, v5) + 1]
        local v8 = rt.idiv(#p5, 2) - 1
        local n1 = 0
        local n2 = 0

        for j = 0, v8 do
            n1 = fround(p4.normals[i + 1][j * 2 + 1] * fround(p5[j * 2 + 1] - v7[j * 2 + 1]) + n1)
            n2 = fround(p4.normals[i + 1][j * 2 + 2] * fround(p5[j * 2 + 2] - v7[j * 2 + 2]) + n2)
        end

        local v9 = fround(n1 + n2)

        if rt.irem(#p5, 2) ~= 0 then
            local v10 = #p5 - 1

            v9 = fround(v9 + fround(p4.normals[i + 1][v10 + 1] * fround(p5[v10 + 1] - v7[v10 + 1])))
        end

        v6[i + 1] = fround(v9 * p4.scales[i + 1])
    end

    return v6
end

function t1.Simplex.project(p6, p7) -- line: 83
    -- upvalues: rt (copy), fround (copy)
    local v11 = rt.copy(p6.vertices)
    local v12 = table.create(#p7)

    for _, v13 in ipairs(p7) do
        local v14 = #v11 - 1
        local t2 = {}
        local v15 = v14 - 1
        local v16 = false

        for i = 0, v15 do
            for j = i + 1, #v11 - 1 do
                if #t2 == v14 then
                    v16 = true
                    break
                end

                local v17 = v11[i + 1]
                local v18 = v11[j + 1]

                if v17[1] < v13 ~= (v18[1] < v13) then
                    local v19 = fround(v18[1] - v17[1])

                    if math.abs(v19) <= 9.999999747378752E-06 then
                        table.insert(t2, rt.slice(v17, 1))

                        if #t2 < v14 then
                            table.insert(t2, rt.slice(v18, 1))
                        end
                    else
                        local v20 = fround(fround(v13 - v17[1]) / v19)
                        local v21 = table.create(#v17 - 1)

                        for k = 2, math.min(#v17, #v18) do
                            v21[k - 1] = fround(fround(v18[k] - v17[k]) * v20 + v17[k])
                        end

                        table.insert(t2, v21)
                    end
                end
            end

            if v16 then
                break
            end
        end

        if #t2 == 0 then
            local v24 = 0
            local v25 = rt.F32_MAX

            for v26, v27 in ipairs(v11) do
                local v28 = v26 - 1
                local v29 = fround(fround(v27[1] - v13) * fround(v27[1] - v13))

                if v29 < v25 then
                    v25 = v29
                    v24 = v28
                end
            end

            for _, v30 in ipairs(v11[v24 + 1]) do
                table.insert(v12, v30)
            end

            return v12
        end

        v11 = t2
        table.insert(v12, v13)

        while #t2 < v14 do
            table.insert(t2, rt.copy(t2[#t2]))
        end
    end

    return v12
end

t1.BlendSpace = {}

function t1.BlendSpace.new(p8, p9, p10) -- line: 153
    local v32 = #p8
    local v33 = v32 == 0 or v32 > 4 or #p9 < v32 + 1 or #p10 == 0

    if not v33 then
        for _, v34 in ipairs(p10) do
            local v35 = #v34.children ~= v32 + 1 or #v34.vertices ~= v32 + 1 or #v34.normals ~= v32 + 1 or #v34.scales ~= v32 + 1

            if not v35 then
                for _, v36 in ipairs(v34.children) do
                    if #p9 <= v36 then
                        v35 = true
                        break
                    end
                end
            end

            if not v35 then
                for i = 1, 2 do
                    local v37 = if i == 1 then v34.vertices else v34.normals
                    local v38 = v35

                    for _, v39 in ipairs(v37) do
                        if #v39 ~= v32 then
                            v35 = true
                            break
                        end

                        for _, v40 in ipairs(v39) do
                            if v40 ~= v40 or v40 == 1e999 or v40 == (-1e999) then
                                v38 = true
                                break
                            end
                        end

                        if v38 then
                            v35 = v38
                            break
                        end

                        v35 = v38
                    end

                    if v35 then
                        break
                    end
                end
            end

            if not v35 then
                for _, v41 in ipairs(v34.scales) do
                    if v41 ~= v41 or v41 == 1e999 or v41 == (-1e999) then
                        v35 = true
                        break
                    end
                end
            end

            if v35 then
                v33 = true
                break
            end
        end
    end

    if v33 then
        error("Invalid authored BlendSpace topology", 0)
    end

    local v42 = table.create(v32 + 1, 0)

    v42[1] = 1

    return {
        current = 0,
        time = 0,
        parameters = p8,
        children = p9,
        simplexes = p10,
        values = table.create(v32, 0),
        weights = v42
    }
end

function t1.BlendSpace.active_weights(p11) -- line: 222
    local children = p11.simplexes[p11.current + 1].children
    local t3 = {}

    for i = 1, math.min(#children, #p11.weights) do
        t3[i] = {
            children[i],
            p11.weights[i]
        }
    end

    return t3
end

function t1.BlendSpace.length(p12) -- line: 231
    -- upvalues: import (copy), v3 (ref), t1 (copy)
    local n3 = 0

    for _, v45 in ipairs(t1.BlendSpace.active_weights(p12)) do
        local v46 = v45[1]
        local v47 = v45[2]
        local v48 = v3

        if v48 == nil then
            v48 = import("skate_core/animation/playback_tree").PlaybackTree
            v3 = v48
        end

        n3 = v47 * v48.length(p12.children[v46 + 1]) + n3
    end

    return n3
end

function t1.BlendSpace.set_time(p13, p14) -- line: 240
    -- upvalues: import (copy), v3 (ref), t1 (copy)
    local v49 = p14 / t1.BlendSpace.length(p13)

    for _, v50 in ipairs(p13.simplexes[p13.current + 1].children) do
        local v51 = p13.children[v50 + 1]
        local v52 = v3

        if v52 == nil then
            v52 = import("skate_core/animation/playback_tree").PlaybackTree
            v3 = v52
        end

        local set_time = v52.set_time
        local v53 = v3

        if v53 == nil then
            v53 = import("skate_core/animation/playback_tree").PlaybackTree
            v3 = v53
        end

        set_time(v51, v49 * v53.length(v51))
    end
end

function t1.BlendSpace.set_speed(p15, p16) -- line: 249
    -- upvalues: import (copy), v3 (ref)
    for _, v54 in ipairs(p15.children) do
        local v55 = v3

        if v55 == nil then
            v55 = import("skate_core/animation/playback_tree").PlaybackTree
            v3 = v55
        end

        v55.set_speed(v54, p16)
    end
end

function t1.BlendSpace.advance(p17, p18, p19, p20) -- line: 255
    -- upvalues: rt (copy), import (copy), v3 (ref), t1 (copy)
    local v56 = t1.BlendSpace.length(p17)
    local children = p17.simplexes[p17.current + 1].children
    local v57 = children[1]
    local v58 = v3

    if v58 == nil then
        v58 = import("skate_core/animation/playback_tree").PlaybackTree
        v3 = v58
    end

    local v59 = v58.length(p17.children[v57 + 1])

    for v60, v61 in ipairs(children) do
        local v62 = v60 - 1
        local v63 = p17.children[v61 + 1]
        local t4 = {
            crossed_end = false,
            overshoot = -1,
            remaining_before_wrap = -1
        }
        local v64 = v3

        if v64 == nil then
            v64 = import("skate_core/animation/playback_tree").PlaybackTree
            v3 = v64
        end

        local advance = v64.advance
        local v65 = v3

        if v65 == nil then
            v65 = import("skate_core/animation/playback_tree").PlaybackTree
            v3 = v65
        end

        advance(v63, v65.length(v63) * (1 / v56) * p18, p19, t4)

        if v62 == 0 then
            rt.assign(p20, t4)
        end
    end

    local v66 = v56 / v59

    p20.overshoot *= v66
    p20.remaining_before_wrap *= v66

    local v67 = v3

    if v67 == nil then
        v67 = import("skate_core/animation/playback_tree").PlaybackTree
        v3 = v67
    end

    p17.time = v67.time(p17.children[v57 + 1]) * v66
end

function t1.BlendSpace.set_attributes(p21, p22) -- line: 280
    -- upvalues: rt (copy), import (copy), AttributeName (copy), v3 (ref), t1 (copy), fround (copy)
    local v68 = false

    for _, v69 in ipairs(p22) do
        local v70

        for v71, v72 in ipairs(p21.parameters) do
            if AttributeName.eq(v72, v69.name) then
                v70 = v71 - 1
                break
            end
        end

        if v70 ~= nil then
            local value = v69.value

            if value ~= value or value == 1e999 or value == (-1e999) then
                error("Nonfinite BlendSpace parameter", 0)
            end

            v68 = true
            p21.values[v70 + 1] = fround(v69.value)
        end
    end

    if not v68 then
        return false
    end

    local t5 = nil
    local v73 = rt.F32_MAX
    local t6

    for v74, v75 in ipairs(p21.simplexes) do
        local v76 = v74 - 1
        local v77 = t1.Simplex.coordinates(v75, p21.values)
        local v78 = true

        for _, v79 in ipairs(v77) do
            if not (v79 >= 0) then
                v78 = false
                break
            end
        end

        if v78 then
            t6 = { v76, v77 }
            break
        end

        local v80 = t1.Simplex.coordinates(v75, t1.Simplex.project(v75, p21.values))

        for i = 1, #v80 do
            if v80[i] < 0 then
                v80[i] = 0
            end
        end

        t1.normalize(v80)

        local n4 = 0

        for v81, v82 in ipairs(p21.values) do
            local n5 = 0

            for j = 1, math.min(#v75.vertices, #v80) do
                n5 = fround(v75.vertices[j][v81] * v80[j] + n5)
            end

            local v86 = fround(n5 - v82)

            n4 = fround(v86 * v86 + n4)
        end

        if n4 < v73 then
            v73 = n4
            t5 = { v76, v80 }
        end

        t6 = t5
    end

    if t6 == nil then
        error("BlendSpace has no finite projection", 0)
    end

    local v87 = t6[1]
    local v88 = t6[2]

    for i = 1, #v88 do
        v88[i] = rt.clamp(v88[i], 0, 1)
    end

    t1.normalize(v88)

    if v87 ~= p21.current then
        local v89 = p21.children[p21.simplexes[p21.current + 1].children[1] + 1]
        local v90 = v3

        if v90 == nil then
            v90 = import("skate_core/animation/playback_tree").PlaybackTree
            v3 = v90
        end

        local v91 = v90.time(v89)
        local v92 = v3

        if v92 == nil then
            v92 = import("skate_core/animation/playback_tree").PlaybackTree
            v3 = v92
        end

        local v93 = v91 / v92.length(v89)

        for _, v94 in ipairs(p21.simplexes[v87 + 1].children) do
            local v95 = p21.children[v94 + 1]
            local v96 = v3

            if v96 == nil then
                v96 = import("skate_core/animation/playback_tree").PlaybackTree
                v3 = v96
            end

            local set_time = v96.set_time
            local v97 = v3

            if v97 == nil then
                v97 = import("skate_core/animation/playback_tree").PlaybackTree
                v3 = v97
            end

            set_time(v95, v93 * v97.length(v95))
        end

        p21.current = v87
    end

    p21.weights = v88

    return true
end

function t1.BlendSpace.attributes(p23, p24) -- line: 362
    -- upvalues: import (copy), v2 (copy), AttributeName (copy), v3 (ref), words_less (copy)
    local children = p23.simplexes[p23.current + 1].children
    local v98 = v3

    if v98 == nil then
        v98 = import("skate_core/animation/playback_tree").PlaybackTree
        v3 = v98
    end

    local v99 = v98.attributes(p23.children[children[1] + 1], p24)

    for _, v100 in ipairs(v99) do
        v2.scale(v100, p23.weights[1])
    end

    for i = 1, #children - 1 do
        local v101 = children[i + 1]
        local v102 = v3

        if v102 == nil then
            v102 = import("skate_core/animation/playback_tree").PlaybackTree
            v3 = v102
        end

        local v103 = v102.attributes(p23.children[v101 + 1], p24)
        local t7 = {}
        local n6 = 0

        for _, v104 in ipairs(v99) do
            while true do
                if n6 < #v103 and words_less(v103[n6 + 1].name[1], v104.name[1]) then
                    n6 += 1
                    continue
                end

                local v105 = v103[n6 + 1]

                if v105 ~= nil and AttributeName.eq(v105.name, v104.name) then
                    v2.add_weighted(v104, v105, p23.weights[i + 1])
                    table.insert(t7, v104)
                end

                break
            end
        end

        v99 = t7
    end

    return v99
end

function t1.BlendSpace.query_attribute(p25, p26, p27, p28) -- line: 389
    -- upvalues: import (copy), v2 (copy), MotionGraphAttribute (copy), v3 (ref)
    local v106 = v3

    if v106 == nil then
        v106 = import("skate_core/animation/playback_tree").PlaybackTree
        v3 = v106
    end

    if not v106.query_attribute(p25.children[1], p26, p27, p28) then
        return false
    end

    v2.scale(p28, p25.weights[1])

    for i = 1, #p25.weights - 1 do
        local v107 = MotionGraphAttribute.to_animation({
            value = 0,
            name = p26
        })
        local v108 = v3

        if v108 == nil then
            v108 = import("skate_core/animation/playback_tree").PlaybackTree
            v3 = v108
        end

        if not v108.query_attribute(p25.children[i + 1], p26, 15, v107) then
            return false
        end

        v2.add_weighted(p28, v107, p25.weights[i + 1])
    end

    return true
end

function t1.BlendSpace.evaluate(p29, p30, p31, p32) -- line: 407
    -- upvalues: rt (copy), import (copy), v3 (ref)
    if not p31 then
        return false
    end

    for _, v109 in ipairs(p29.simplexes[p29.current + 1].children) do
        local v110 = v3

        if v110 == nil then
            v110 = import("skate_core/animation/playback_tree").PlaybackTree
            v3 = v110
        end

        if not v110.evaluate(p29.children[v109 + 1], p30, true, p32) then
            error("BlendSpace child produced no pose", 0)
        end
    end

    table.insert(p32, {
        tag = "WeightedBlend",
        weights = rt.copy(p29.weights)
    })

    return true
end

function t1.normalize(p33) -- line: 424
    -- upvalues: fround (copy)
    local n7 = 0

    for _, v111 in ipairs(p33) do
        n7 = fround(n7 + v111)
    end

    if not (n7 == n7 and n7 ~= 1e999 and n7 ~= (-1e999)) or n7 <= 0 then
        error("Degenerate BlendSpace weights", 0)
    end

    local v112 = fround(1 / n7)

    for i = 1, #p33 do
        p33[i] = fround(p33[i] * v112)
    end
end

return t1
