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

local function rtl_is_finite(p4) -- line: 28
    if p4 ~= p4 or p4 == 1e999 then
        return false
    end

    return p4 ~= (-1e999)
end

local import = require(sim.import)
local v9 = import("skate_core/animation/output")
local v10 = import("skate_core/animation/pose_add")
local v11 = import("skate_core/animation/pose_blend")
local v12 = import("skate_core/animation/pose_mirror")
local v13 = import("skate_core/animation/pose_sample")
local v14 = import("skate_core/animation/pose_trajectory")
local AnimationBanks = import("skate_data/animation_banks").AnimationBanks
local AnimationFrames = import("skate_data/animation_frames").AnimationFrames
local v15 = import("skate_game/animation_pose/authored_clips")
local v16 = import("skate_game/animation_pose/lazy_clip")
local ensure = v16.ensure
local v17 = import("skate_core/animation/output/hierarchy")
local v18 = import("skate_core/animation/output/sqt")
local sample_key, select_frames = v13.sample_key, v13.select_frames
local blend_sample_into = v11.blend_sample_into
local add_into = v10.add_into
local channel_blend_sample_into = v11.channel_blend_sample_into
local t1 = {}
local v19 = buffer.create(4)

local function fb(p5) -- line: 67
    -- upvalues: v19 (copy)
    buffer.writeu32(v19, 0, p5)

    return (buffer.readf32(v19, 0))
end

local function select_two(p6, p7, p8) -- line: 77
    -- upvalues: rt (copy), v1 (copy)
    local v20 = false
    local v21 = false
    local v22 = false
    local v23 = false
    local v24 = false

    if p8 == 0 then
    else
        v20 = true
    end

    local v25

    if v20 then
        if p6 == p6 then
            v21 = true
        else
            v25 = false
            v22 = true
        end
    end

    v20 = false

    if v21 then
        if p6 == 1e999 then
            v25 = false
            v22 = true
        else
            v20 = true
        end
    end

    v21 = false

    if v20 then
        if p6 == (-1e999) then
            v23 = true
        else
            v21 = true
        end
    end

    v20 = false

    if v21 then
        v25 = true
        v22 = true
    end

    v21 = false

    if v23 then
        v25 = false
        v22 = true
    end

    v23 = false

    if v22 then
        if v25 then
            v23 = true
        else
            v24 = false
        end
    end

    v22 = false

    if v23 then
        if p6 < 0 then
            v24 = false
        else
            v22 = true
        end
    end

    v23 = false

    local v26

    if v22 then
        if p7 == p7 then
            v23 = true
        else
            v26 = false
            v21 = true
        end
    end

    v22 = false

    if v23 then
        if p7 == 1e999 then
            v26 = false
            v21 = true
        else
            v22 = true
        end
    end

    v23 = false

    if v22 then
        if p7 == (-1e999) then
            v20 = true
        else
            v23 = true
        end
    end

    if v23 then
        v26 = true
        v21 = true
    end

    if v20 then
        v26 = false
        v21 = true
    end

    v20 = false

    if v21 then
        if v26 then
            v20 = true
        else
            v24 = false
        end
    end

    if v20 then
        v24 = not (p7 <= 0)
    end

    if not v24 then
        error("Invalid stock animation sampling input", 0)
    end

    local v27 = p8 - 1
    local v28 = p6 * p7
    local v29

    if v28 ~= 0 and v28 > -1.1754943508222875E-38 and v28 < 1.1754943508222875E-38 then
        local v30 = math.abs(v28) * 7.1362384635298E+44
        local v31 = math.floor(v30)
        local v32 = v30 - v31

        v29 = (if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31) * 1.401298464324817E-45

        if v28 < 0 then
            v29 = -v29
        end
    else
        buffer.writef32(v1, 0, v28)
        v29 = buffer.readf32(v1, 0)
    end

    if not (v29 - v27 >= 0) then
        v27 = v29
    end

    local f_to_usize = rt.f_to_usize
    local v33 = v27 + 0
    local v34

    if v33 ~= 0 and v33 > -1.1754943508222875E-38 and v33 < 1.1754943508222875E-38 then
        local v35 = math.abs(v33) * 7.1362384635298E+44
        local v36 = math.floor(v35)
        local v37 = v35 - v36

        v34 = (if v37 > 0.5 or v37 == 0.5 and v36 % 2 == 1 then v36 + 1 else v36) * 1.401298464324817E-45

        if v33 < 0 then
            v34 = -v34
        end
    else
        buffer.writef32(v1, 0, v33)
        v34 = buffer.readf32(v1, 0)
    end

    local v38 = f_to_usize(v34)

    if p8 <= v38 then
        error("Stock frame selection exceeds decoded samples", 0)
    end

    local v41 = math.min(v38 + 1, p8 - 1)
    local f_to_int = rt.f_to_int
    local v42 = v27 - v38
    local v43

    if v42 ~= 0 and v42 > -1.1754943508222875E-38 and v42 < 1.1754943508222875E-38 then
        local v44 = math.abs(v42) * 7.1362384635298E+44
        local v45 = math.floor(v44)
        local v46 = v44 - v45

        v43 = (if v46 > 0.5 or v46 == 0.5 and v45 % 2 == 1 then v45 + 1 else v45) * 1.401298464324817E-45

        if v42 < 0 then
            v43 = -v43
        end
    else
        buffer.writef32(v1, 0, v42)
        v43 = buffer.readf32(v1, 0)
    end

    local v47 = v43 * 65535
    local v48

    if v47 == 0 or not (v47 > -1.1754943508222875E-38) or not (v47 < 1.1754943508222875E-38) then
        buffer.writef32(v1, 0, v47)
        v48 = buffer.readf32(v1, 0)

        return v38, v41, f_to_int(v48, 0, 65535) * 1.5259021893143654E-05
    end

    local v49 = math.abs(v47) * 7.1362384635298E+44
    local v50 = math.floor(v49)
    local v51 = v49 - v50

    v48 = (if v51 > 0.5 or v51 == 0.5 and v50 % 2 == 1 then v50 + 1 else v50) * 1.401298464324817E-45

    if v47 < 0 then
        v48 = -v48
    end

    return v38, v41, f_to_int(v48, 0, 65535) * 1.5259021893143654E-05
end

local v52, v53, v54, v55, v56, v57, v58, v59
local v60 = true
local v61
local v62 = true
local delta_into = v14.delta_into
local validate = v17.validate
local sqt_to_matrices_into = v18.sqt_to_matrices_into
local self = setmetatable({}, {
    __mode = "k"
})
local v64 = true

local function open_stock_clip(p9, p10, p11) -- line: 127
    -- upvalues: AnimationFrames (copy), v16 (copy), v64 (ref)
    if not v64 then
        return AnimationFrames.clip(p9, p11)
    end

    local v65 = p10.clips[string.upper(p11)]

    if v65 ~= nil and v65.decoded == nil then
        local open = v16.open
        local v66 = p10.banks[v65.bank + 1]
        local offset = v65.offset
        local ok, result = pcall(open, p9, p11, v66, offset)

        if ok then
            return result
        end
    end

    return AnimationFrames.clip(p9, p11)
end

local function stock_clip(p12, p13) -- line: 140
    -- upvalues: AnimationFrames (copy), self (copy), open_stock_clip (copy)
    local native = p12.native

    if native == nil then
        return AnimationFrames.clip(p12, p13)
    end

    local v67 = self[native]

    if v67 == nil then
        v67 = {}
        self[native] = v67
    end

    local v68 = v67[p13]

    if v68 == nil then
        v68 = open_stock_clip(p12, native, p13)
        v67[p13] = v68
    end

    return v68
end

local function debug_error(p14) -- line: 159
    if type(p14) ~= "table" or p14.tag == nil then
        return (tostring(p14))
    end

    if p14.tag == "InvalidParent" then
        return string.format("InvalidParent { bone: %d, parent: %d }", p14.bone, p14.parent)
    end

    return p14.tag
end

t1.PoseEvaluator = {}

local _ = t1.PoseEvaluator

function t1.PoseEvaluator.load(p15) -- line: 176
    -- upvalues: AnimationBanks (copy), t1 (copy)
    local v69 = t1.PoseEvaluator.from_banks(AnimationBanks.load(p15))

    t1.PoseEvaluator.load_authored_clips(v69, p15)

    return v69
end

function t1.PoseEvaluator.from_banks(p16) -- line: 183
    -- upvalues: AnimationFrames (copy), v15 (copy)
    return {
        frames = AnimationFrames.from_banks(p16),
        authored = v15.Replacements.default()
    }
end

function t1.PoseEvaluator.load_authored_clips(p17, p18, p19) -- line: 192
    -- upvalues: v15 (copy)
    p17.authored = v15.Replacements.load(p18, p17.frames, p19)
end

function t1.PoseEvaluator.evaluate_reference(p20, p21) -- line: 199
    -- upvalues: v1 (copy), v10 (copy), v11 (copy), v12 (copy), v14 (copy), AnimationFrames (copy), v15 (copy), t1 (copy)
    local t4 = {}

    for _, v70 in ipairs(p21) do
        local tag = v70.tag

        if tag == "Pose" then
            local samples = AnimationFrames.named_pose(p20.frames, v70.name).samples
            local v71 = table.create(#samples)

            for v72, v73 in ipairs(samples) do
                v71[v72] = t1.sqt_reference(v73)
            end

            table.insert(t4, v71)
        elseif tag == "Add" then
            local v74 = table.remove(t4)

            if v74 == nil then
                error("Animation add has no reference subtree", 0)
            end

            local v75 = t4[#t4]

            if v75 == nil then
                error("Animation add has no motion subtree", 0)
            end

            if #v75 ~= #v74 then
                error("Animation add bone counts differ", 0)
            end

            for i = 1, #v75 do
                if v70.motion_is_a then
                    v75[i] = v10.add(v75[i], v74[i], true)
                else
                    v75[i] = v10.add(v74[i], v75[i], false)
                end
            end
        elseif tag == "Mirror" then
            local v76 = t4[#t4]

            if v76 == nil then
                error("Animation mirror has no subtree", 0)
            end

            v12.mirror(v76, p20.frames.parents, p20.frames.mirror_indices, v70.trajectory_mode)
        elseif tag == "Clip" then
            local v77 = AnimationFrames.clip(p20.frames, v70.name)
            local v78 = v15.Replacements.clip(p20.authored, v77.name)

            if v78 ~= nil then
                v77 = v78
            end

            local v79 = t1.sample_clip_reference(v77, v70.time)

            if p20.frames.has_trajectory then
                local v80 = t1.sample_bone_reference(v77, v70.previous_time, 0)
                local t5

                if v70.loops ~= 0 then
                    local loop_rotation_bits, loop_translation_bits = v77.loop_rotation_bits, v77.loop_translation_bits

                    t5 = {}
                    buffer.writeu32(v1, 0, loop_rotation_bits[1])

                    local v82 = buffer.readf32(v1, 0)

                    buffer.writeu32(v1, 0, loop_rotation_bits[2])

                    local v84 = buffer.readf32(v1, 0)

                    buffer.writeu32(v1, 0, loop_rotation_bits[3])

                    local v86 = buffer.readf32(v1, 0)

                    buffer.writeu32(v1, 0, loop_rotation_bits[4])
                    t5.rotation = {
                        v82,
                        v84,
                        v86,
                        (buffer.readf32(v1, 0))
                    }
                    buffer.writeu32(v1, 0, loop_translation_bits[1])

                    local v89 = buffer.readf32(v1, 0)

                    buffer.writeu32(v1, 0, loop_translation_bits[2])

                    local v91 = buffer.readf32(v1, 0)

                    buffer.writeu32(v1, 0, loop_translation_bits[3])
                    t5.translation = {
                        v89,
                        v91,
                        (buffer.readf32(v1, 0))
                    }
                end

                v79[1] = v14.delta(v79[1], v80, t5)
            end

            table.insert(t4, v79)
        elseif tag == "WeightedBlend" then
            local weights = v70.weights
            local v93 = #t4 - #weights

            if v93 < 0 then
                error("Weighted blend pose stack underflow", 0)
            end

            local v94 = table.move(t4, v93 + 1, #t4, 1, table.create(#weights))
            local weighted = v11.weighted
            local ok, result = pcall(weighted, v94, weights)

            if not ok then
                error("Weighted blend: " .. (if type(result) ~= "table" then tostring(result)
                    elseif result.tag == nil then tostring(result)
                    elseif result.tag == "InvalidParent" then string.format("InvalidParent { bone: %d, parent: %d }", result.bone, result.parent)
                    else result.tag), 0)
            end

            for j = #t4, v93 + 1, -1 do
                t4[j] = nil
            end

            table.insert(t4, result)
        elseif tag == "Blend" or tag == "ChannelBlend" then
            local weight = v70.weight
            local v95 = table.remove(t4)

            if v95 == nil then
                error("Animation blend has no second subtree", 0)
            end

            local v96 = t4[#t4]

            if v96 == nil then
                error("Animation blend has no first subtree", 0)
            end

            if #v96 ~= #v95 then
                error("Animation subtree bone counts differ", 0)
            end

            for k = 1, #v96 do
                if tag == "ChannelBlend" then
                    v96[k] = v11.channel_blend_sample(v96[k], v95[k], weight, v70.use_channels_from_weights)
                else
                    v96[k] = v11.blend_sample(v96[k], v95[k], weight)
                end
            end
        end
    end

    if #t4 ~= 1 then
        error(string.format("Animation evaluation left%d poses", #t4), 0)
    end

    return table.remove(t4)
end

local self2 = setmetatable({}, {
    __mode = "k"
})

local function constant_pose(p22) -- line: 326
    -- upvalues: v55 (ref), v58 (ref), self2 (copy)
    local v98 = self2[p22]

    if v98 == nil then
        v98 = table.create(#p22)

        for v99, v100 in ipairs(p22) do
            v98[v99] = v55(v58(), v100)
        end

        self2[p22] = v98
    end

    return v98
end

local v101 = true

function t1.PoseEvaluator.evaluate(p23, p24) -- line: 351
    -- upvalues: v11 (copy), v12 (copy), v14 (copy), AnimationFrames (copy), v15 (copy), blend_sample_into (copy), add_into (copy), channel_blend_sample_into (copy), v19 (copy), v52 (ref), v53 (ref), v54 (ref), v55 (ref), v56 (ref), v57 (ref), v59 (ref), v60 (ref), v61 (ref), v62 (ref), delta_into (copy), stock_clip (copy), constant_pose (copy), v101 (ref)
    local t8 = {}
    local v102 = false

    for v103, v104 in ipairs(p24) do
        local tag = v104.tag

        if v102 then
            v102 = false
        elseif tag == "Pose" then
            local weight = AnimationFrames.named_pose(p23.frames, v104.name).samples

            if not v101 or p23.frames.native == nil then
                local v142 = table.create(#weight)

                for v143, v144 in ipairs(weight) do
                    local v145 = v55
                    local rotation = v52

                    v142[v143] = v145(rotation(), v144)
                end

                table.insert(t8, v142)
            else
                local v109 = p24[v103 + 1]
                local v110 = t8[#t8]

                if v109 ~= nil then
                    if v109.tag ~= "Add" or v110 == nil then
                        v109 = table.create(#weight)

                        for v139, v140 in ipairs(weight) do
                            local v141 = v55
                            local rotation = v52

                            v109[v139] = v141(rotation(), v140)
                        end

                        table.insert(t8, v109)
                    else
                        local v117 = constant_pose(weight)

                        if #v110 == #v117 then
                            if v109.motion_is_a and v60 then
                                for i = 1, #v110 do
                                    local v118 = v110[i]
                                    local rotation = v117[i]
                                    local translation = rotation.rotation
                                    local v119 = translation[1]
                                    local v120 = translation[2]
                                    local v121 = translation[3]
                                    local v122 = translation[4]

                                    translation = v118.translation

                                    local v123 = translation[1]
                                    local v124 = translation[2]
                                    local v125 = translation[3]
                                    local v126 = -v121 * v124 + v120 * v125
                                    local v127 = -v119 * v125 + v121 * v123
                                    local v128 = -v120 * v123 + v119 * v124
                                    local v129 = v122 * v123 + v126

                                    v126 = v122 * v124 + v127
                                    v127 = v122 * v125 + v128
                                    v128 = -v121 * v126 + v120 * v127

                                    local v130 = -v119 * v127 + v121 * v129

                                    v127 = -v120 * v129 + v119 * v126
                                    v129 = 2 * v128 + v123
                                    v128 = 2 * v130 + v124
                                    v130 = 2 * v127 + v125

                                    local scale = v118.scale
                                    local scale2 = rotation.scale

                                    v127 = scale2[1] * scale[1]
                                    v126 = scale2[2] * scale[2]
                                    v125 = scale2[3] * scale[3]
                                    v124 = scale2[4] * scale[4]
                                    scale2 = v118.rotation

                                    local translation2 = scale2[1]
                                    local translation3 = scale2[2]
                                    local v131 = scale2[3]
                                    local v132 = scale2[4]

                                    v123 = -v121 * translation3 + v120 * v131
                                    v118 = -v119 * v131 + v121 * translation2

                                    local v133 = -v120 * translation2 + v119 * translation3
                                    local v134 = v119 * v132 + (translation2 * v122 + v123)

                                    v123 = v120 * v132 + (translation3 * v122 + v118)
                                    v118 = v121 * v132 + (v131 * v122 + v133)
                                    v133 = v122 * v132 - (v119 * translation2 + v120 * translation3 + v121 * v131)
                                    v132 = rotation.translation
                                    v131 = v129 + v132[1]
                                    translation3 = v128 + v132[2]
                                    translation2 = v130 + v132[3]
                                    v132 = translation[4]
                                    scale[1] = v127
                                    scale[2] = v126
                                    scale[3] = v125
                                    scale[4] = v124
                                    scale2[1] = v134
                                    scale2[2] = v123
                                    scale2[3] = v118
                                    scale2[4] = v133
                                    translation[1] = v131
                                    translation[2] = translation3
                                    translation[3] = translation2
                                    translation[4] = v132
                                end
                            else
                                local v135 = v109.motion_is_a

                                if v135 then
                                    v135 = #v110

                                    for j = 1, v135 do
                                        add_into(v110[j], v117[j], true, v110[j])
                                    end
                                else
                                    v135 = #v110

                                    for k = 1, v135 do
                                        add_into(v117[k], v110[k], false, v110[k])
                                    end
                                end
                            end

                            v102 = true
                        else
                            v109 = table.create(#weight)

                            for v136, v137 in ipairs(weight) do
                                local v138 = v55
                                local rotation = v52

                                v109[v136] = v138(rotation(), v137)
                            end

                            table.insert(t8, v109)
                        end
                    end
                else
                    v109 = table.create(#weight)

                    for v111, v112 in ipairs(weight) do
                        local v113 = v55
                        local rotation = v52

                        v109[v111] = v113(rotation(), v112)
                    end

                    table.insert(t8, v109)
                end
            end
        elseif tag == "Add" then
            local weight = table.remove(t8)

            if weight == nil then
                error("Animation add has no reference subtree", 0)
            end

            local v146 = t8[#t8]

            if v146 == nil then
                error("Animation add has no motion subtree", 0)
            end

            if #v146 ~= #weight then
                error("Animation add bone counts differ", 0)
            end

            for n = 1, #v146 do
                if v104.motion_is_a then
                    add_into(v146[n], weight[n], true, v146[n])
                else
                    add_into(weight[n], v146[n], false, v146[n])
                end
            end

            v54(weight)
        elseif tag == "Mirror" then
            local weight = t8[#t8]

            if weight == nil then
                error("Animation mirror has no subtree", 0)
            end

            v12.mirror(weight, p23.frames.parents, p23.frames.mirror_indices, v104.trajectory_mode)
        elseif tag == "Clip" then
            local weight = stock_clip(p23.frames, v104.name)
            local v147 = v15.Replacements.clip(p23.authored, weight.name)

            if v147 ~= nil then
                weight = v147
            end

            if not v62 or weight.words == nil and weight.block_words == nil then
                local v253 = v60

                v253 = if not v253 or weight.words == nil and weight.block_words == nil then v56 elseif #weight.channel_weights >= weight.bone_count then v59 else v56
                v253 = v253(weight, v104.time)

                local v254 = p23.frames.has_trajectory

                if v254 then
                    v254 = v57(weight, v104.previous_time, 0)

                    local v255 = v253[1]

                    if v255 == nil then
                        v253[1] = v14.delta(v255, v254, nil)
                    end

                    local loop_rotation_bits = v104.loops

                    if loop_rotation_bits == 0 then
                        delta_into(v255, v254, 0, 0, 0, 1, 0, 0, 0)
                    else
                        loop_rotation_bits = weight.loop_rotation_bits

                        local loop_translation_bits = weight.loop_translation_bits

                        buffer.writeu32(v19, 0, loop_rotation_bits[1])

                        local v257 = buffer.readf32(v19, 0)

                        buffer.writeu32(v19, 0, loop_rotation_bits[2])

                        local v259 = buffer.readf32(v19, 0)

                        buffer.writeu32(v19, 0, loop_rotation_bits[3])

                        local v261 = buffer.readf32(v19, 0)

                        buffer.writeu32(v19, 0, loop_rotation_bits[4])

                        local v263 = buffer.readf32(v19, 0)

                        buffer.writeu32(v19, 0, loop_translation_bits[1])

                        local v265 = buffer.readf32(v19, 0)

                        buffer.writeu32(v19, 0, loop_translation_bits[2])

                        local v267 = buffer.readf32(v19, 0)

                        buffer.writeu32(v19, 0, loop_translation_bits[3])
                        delta_into(v255, v254, v257, v259, v261, v263, v265, v267, (buffer.readf32(v19, 0)))
                    end

                    loop_rotation_bits = v53
                    loop_rotation_bits(v254)
                end

                table.insert(t8, v253)
            else
                local v164 = p24[v103 + 1]
                local v165 = t8[#t8]
                local v166 = weight.bone_count

                if v164 ~= nil then
                    local v182 = v164.tag

                    if v182 ~= "Blend" or v165 == nil then
                        v166 = v60
                        v166 = if not v166 or weight.words == nil and weight.block_words == nil then v56 elseif #weight.channel_weights >= weight.bone_count then v59 else v56
                        v166 = v166(weight, v104.time)

                        local v239 = p23.frames.has_trajectory

                        if v239 then
                            v239 = v57(weight, v104.previous_time, 0)
                            v182 = v166[1]

                            if v182 == nil then
                                v166[1] = v14.delta(v182, v239, nil)
                            end

                            local loop_rotation_bits = v104.loops

                            if loop_rotation_bits == 0 then
                                delta_into(v182, v239, 0, 0, 0, 1, 0, 0, 0)
                            else
                                loop_rotation_bits = weight.loop_rotation_bits

                                local loop_translation_bits = weight.loop_translation_bits

                                buffer.writeu32(v19, 0, loop_rotation_bits[1])

                                local v241 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_rotation_bits[2])

                                local v243 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_rotation_bits[3])

                                local v245 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_rotation_bits[4])

                                local v247 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_translation_bits[1])

                                local v249 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_translation_bits[2])

                                local v251 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_translation_bits[3])
                                delta_into(v182, v239, v241, v243, v245, v247, v249, v251, (buffer.readf32(v19, 0)))
                            end

                            loop_rotation_bits = v53
                            loop_rotation_bits(v239)
                        end

                        table.insert(t8, v166)
                    elseif v166 >= 1 then
                        v182 = #v165

                        if v182 == v166 then
                            v182 = #weight.channel_weights

                            if v166 <= v182 then
                                v182 = v61
                                v102 = true
                                v182(p23, v165, weight, v104, v164.weight)
                            else
                                v166 = v60
                                v166 = if not v166 or weight.words == nil and weight.block_words == nil then v56 elseif #weight.channel_weights >= weight.bone_count then v59 else v56
                                v166 = v166(weight, v104.time)

                                local v197 = p23.frames.has_trajectory

                                if v197 then
                                    v197 = v57(weight, v104.previous_time, 0)
                                    v182 = v166[1]

                                    if v182 == nil then
                                        v166[1] = v14.delta(v182, v197, nil)
                                    end

                                    local loop_rotation_bits = v104.loops

                                    if loop_rotation_bits == 0 then
                                        delta_into(v182, v197, 0, 0, 0, 1, 0, 0, 0)
                                    else
                                        loop_rotation_bits = weight.loop_rotation_bits

                                        local loop_translation_bits = weight.loop_translation_bits

                                        buffer.writeu32(v19, 0, loop_rotation_bits[1])

                                        local v199 = buffer.readf32(v19, 0)

                                        buffer.writeu32(v19, 0, loop_rotation_bits[2])

                                        local v201 = buffer.readf32(v19, 0)

                                        buffer.writeu32(v19, 0, loop_rotation_bits[3])

                                        local v203 = buffer.readf32(v19, 0)

                                        buffer.writeu32(v19, 0, loop_rotation_bits[4])

                                        local v205 = buffer.readf32(v19, 0)

                                        buffer.writeu32(v19, 0, loop_translation_bits[1])

                                        local v207 = buffer.readf32(v19, 0)

                                        buffer.writeu32(v19, 0, loop_translation_bits[2])

                                        local v209 = buffer.readf32(v19, 0)

                                        buffer.writeu32(v19, 0, loop_translation_bits[3])
                                        delta_into(v182, v197, v199, v201, v203, v205, v207, v209, (buffer.readf32(v19, 0)))
                                    end

                                    loop_rotation_bits = v53
                                    loop_rotation_bits(v197)
                                end

                                table.insert(t8, v166)
                            end
                        else
                            v166 = v60
                            v166 = if not v166 or weight.words == nil and weight.block_words == nil then v56 elseif #weight.channel_weights >= weight.bone_count then v59 else v56
                            v166 = v166(weight, v104.time)

                            local v211 = p23.frames.has_trajectory

                            if v211 then
                                v211 = v57(weight, v104.previous_time, 0)
                                v182 = v166[1]

                                if v182 == nil then
                                    v166[1] = v14.delta(v182, v211, nil)
                                end

                                local loop_rotation_bits = v104.loops

                                if loop_rotation_bits == 0 then
                                    delta_into(v182, v211, 0, 0, 0, 1, 0, 0, 0)
                                else
                                    loop_rotation_bits = weight.loop_rotation_bits

                                    local loop_translation_bits = weight.loop_translation_bits

                                    buffer.writeu32(v19, 0, loop_rotation_bits[1])

                                    local v213 = buffer.readf32(v19, 0)

                                    buffer.writeu32(v19, 0, loop_rotation_bits[2])

                                    local v215 = buffer.readf32(v19, 0)

                                    buffer.writeu32(v19, 0, loop_rotation_bits[3])

                                    local v217 = buffer.readf32(v19, 0)

                                    buffer.writeu32(v19, 0, loop_rotation_bits[4])

                                    local v219 = buffer.readf32(v19, 0)

                                    buffer.writeu32(v19, 0, loop_translation_bits[1])

                                    local v221 = buffer.readf32(v19, 0)

                                    buffer.writeu32(v19, 0, loop_translation_bits[2])

                                    local v223 = buffer.readf32(v19, 0)

                                    buffer.writeu32(v19, 0, loop_translation_bits[3])
                                    delta_into(v182, v211, v213, v215, v217, v219, v221, v223, (buffer.readf32(v19, 0)))
                                end

                                loop_rotation_bits = v53
                                loop_rotation_bits(v211)
                            end

                            table.insert(t8, v166)
                        end
                    else
                        v166 = v60
                        v166 = if not v166 or weight.words == nil and weight.block_words == nil then v56 elseif #weight.channel_weights >= weight.bone_count then v59 else v56
                        v166 = v166(weight, v104.time)

                        local v225 = p23.frames.has_trajectory

                        if v225 then
                            v225 = v57(weight, v104.previous_time, 0)
                            v182 = v166[1]

                            if v182 == nil then
                                v166[1] = v14.delta(v182, v225, nil)
                            end

                            local loop_rotation_bits = v104.loops

                            if loop_rotation_bits == 0 then
                                delta_into(v182, v225, 0, 0, 0, 1, 0, 0, 0)
                            else
                                loop_rotation_bits = weight.loop_rotation_bits

                                local loop_translation_bits = weight.loop_translation_bits

                                buffer.writeu32(v19, 0, loop_rotation_bits[1])

                                local v227 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_rotation_bits[2])

                                local v229 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_rotation_bits[3])

                                local v231 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_rotation_bits[4])

                                local v233 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_translation_bits[1])

                                local v235 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_translation_bits[2])

                                local v237 = buffer.readf32(v19, 0)

                                buffer.writeu32(v19, 0, loop_translation_bits[3])
                                delta_into(v182, v225, v227, v229, v231, v233, v235, v237, (buffer.readf32(v19, 0)))
                            end

                            loop_rotation_bits = v53
                            loop_rotation_bits(v225)
                        end

                        table.insert(t8, v166)
                    end
                else
                    v166 = v60
                    v166 = if not v166 or weight.words == nil and weight.block_words == nil then v56 elseif #weight.channel_weights >= weight.bone_count then v59 else v56
                    v166 = v166(weight, v104.time)

                    local v167 = p23.frames.has_trajectory

                    if v167 then
                        v167 = v57(weight, v104.previous_time, 0)

                        local v168 = v166[1]

                        if v168 == nil then
                            v166[1] = v14.delta(v168, v167, nil)
                        end

                        local loop_rotation_bits = v104.loops

                        if loop_rotation_bits == 0 then
                            delta_into(v168, v167, 0, 0, 0, 1, 0, 0, 0)
                        else
                            loop_rotation_bits = weight.loop_rotation_bits

                            local loop_translation_bits = weight.loop_translation_bits

                            buffer.writeu32(v19, 0, loop_rotation_bits[1])

                            local v170 = buffer.readf32(v19, 0)

                            buffer.writeu32(v19, 0, loop_rotation_bits[2])

                            local v172 = buffer.readf32(v19, 0)

                            buffer.writeu32(v19, 0, loop_rotation_bits[3])

                            local v174 = buffer.readf32(v19, 0)

                            buffer.writeu32(v19, 0, loop_rotation_bits[4])

                            local v176 = buffer.readf32(v19, 0)

                            buffer.writeu32(v19, 0, loop_translation_bits[1])

                            local v178 = buffer.readf32(v19, 0)

                            buffer.writeu32(v19, 0, loop_translation_bits[2])

                            local v180 = buffer.readf32(v19, 0)

                            buffer.writeu32(v19, 0, loop_translation_bits[3])
                            delta_into(v168, v167, v170, v172, v174, v176, v178, v180, (buffer.readf32(v19, 0)))
                        end

                        loop_rotation_bits = v53
                        loop_rotation_bits(v167)
                    end

                    table.insert(t8, v166)
                end
            end
        elseif tag == "WeightedBlend" then
            local weight = v104.weights
            local v269 = #t8 - #weight

            if v269 < 0 then
                error("Weighted blend pose stack underflow", 0)
            end

            local v270 = table.move(t8, v269 + 1, #t8, 1, table.create(#weight))
            local result = v11.weighted
            local ok

            ok, result = pcall(result, v270, weight)

            if not ok then
                local loop_rotation_bits = error

                loop_rotation_bits("Weighted blend: " .. (if type(result) ~= "table" then tostring(result)
                    elseif result.tag == nil then tostring(result)
                    elseif result.tag == "InvalidParent" then string.format("InvalidParent { bone: %d, parent: %d }", result.bone, result.parent)
                    else result.tag), 0)
            end

            for n2 = #t8, v269 + 1, -1 do
                t8[n2] = nil
            end

            table.insert(t8, result)

            for n3 = 1, #v270 do
                v54(v270[n3])
            end
        elseif tag == "Blend" or tag == "ChannelBlend" then
            local weight = v104.weight
            local v272 = table.remove(t8)

            if v272 == nil then
                error("Animation blend has no second subtree", 0)
            end

            local v273 = t8[#t8]

            if v273 == nil then
                error("Animation blend has no first subtree", 0)
            end

            if #v273 ~= #v272 then
                error("Animation subtree bone counts differ", 0)
            end

            local v274

            if tag == "ChannelBlend" then
                v274 = #v273

                for n4 = 1, v274 do
                    channel_blend_sample_into(v273[n4], v272[n4], weight, v104.use_channels_from_weights)
                end
            else
                v274 = v60

                if v274 then
                    v274 = #v273

                    for n5 = 1, v274 do
                        local v275 = v273[n5]
                        local v276 = v272[n5]
                        local rotation = v275.rotation
                        local translation = v276.rotation
                        local v277 = rotation[1]
                        local v278 = rotation[2]
                        local v279 = rotation[3]
                        local v280 = rotation[4]
                        local v281 = translation[1]
                        local v282 = translation[2]
                        local v283 = translation[3]
                        local v284 = translation[4]
                        local v285, v286, v287, v288

                        if v277 * v281 + v278 * v282 + v279 * v283 + v280 * v284 > 0 then
                            v285 = (v281 - v277) * weight + v277
                            v286 = (v282 - v278) * weight + v278
                            v287 = (v283 - v279) * weight + v279
                            v288 = (v284 - v280) * weight + v280
                        else
                            v285 = -(v281 + v277) * weight + v277
                            v286 = -(v282 + v278) * weight + v278
                            v287 = -(v283 + v279) * weight + v279
                            v288 = -(v284 + v280) * weight + v280
                        end

                        v284 = v285 * v285 + v286 * v286 + v287 * v287 + v288 * v288
                        v283 = 1 / math.sqrt(v284)
                        v283 = v283 * 0.5 * (-v284 * (v283 * v283) + 1) + v283
                        v283 = v283 * 0.5 * (-v284 * (v283 * v283) + 1) + v283

                        local scale = v275.scale
                        local scale2 = v276.scale
                        local translation2 = v275.translation
                        local translation3 = v276.translation
                        local v289 = scale[1]
                        local v290 = scale[2]
                        local v291 = scale[3]
                        local v292 = scale[4]
                        local v293 = translation2[1]
                        local v294 = translation2[2]
                        local v295 = translation2[3]
                        local v296 = translation2[4]

                        v284 = (scale2[1] - v289) * weight + v289
                        v289 = (scale2[2] - v290) * weight + v290
                        v290 = (scale2[3] - v291) * weight + v291
                        v291 = (scale2[4] - v292) * weight + v292
                        v292 = (translation3[1] - v293) * weight + v293
                        v293 = (translation3[2] - v294) * weight + v294
                        v294 = (translation3[3] - v295) * weight + v295
                        v295 = (translation3[4] - v296) * weight + v296
                        scale[1] = v284
                        scale[2] = v289
                        scale[3] = v290
                        scale[4] = v291

                        local v297 = v285 * v283
                        local v298 = v286 * v283
                        local v299 = v287 * v283
                        local v300 = v288 * v283

                        rotation[1] = v297
                        rotation[2] = v298
                        rotation[3] = v299
                        rotation[4] = v300
                        translation2[1] = v292
                        translation2[2] = v293
                        translation2[3] = v294
                        translation2[4] = v295
                    end
                else
                    v274 = #v273

                    for n6 = 1, v274 do
                        blend_sample_into(v273[n6], v272[n6], weight)
                    end
                end
            end

            v274 = v54
            v274(v272)
        end
    end

    if #t8 ~= 1 then
        error(string.format("Animation evaluation left%d poses", #t8), 0)
    end

    return table.remove(t8)
end

function t1.PoseEvaluator.release(p25) -- line: 636
    -- upvalues: v54 (ref)
    v54(p25)
end

function t1.PoseEvaluator.check_hierarchy(p26, p27) -- line: 647
    -- upvalues: validate (copy)
    local v301 = #p27

    if v301 ~= #p26.frames.parents then
        error("Animation pose and hierarchy bone counts differ", 0)
    end

    local v302 = math.max(v301, 0)
    local parents = p26.frames.parents
    local ok, result = pcall(validate, v302, parents, 0, v301, v301)

    if ok then
        return
    end

    error("Invalid stock animation hierarchy: " .. (if type(result) ~= "table" then tostring(result)
        elseif result.tag == nil then tostring(result)
        elseif result.tag == "InvalidParent" then string.format("InvalidParent { bone: %d, parent: %d }", result.bone, result.parent)
        else result.tag), 0)
end

function t1.PoseEvaluator.write_matrices(p28, p29, p30, p31) -- line: 667
    -- upvalues: v17 (copy), sqt_to_matrices_into (copy)
    local v303 = #p29

    for i = 1, v303 do
        sqt_to_matrices_into(p31[i], p30[i], p29[i])
    end

    local parents = p28.frames.parents
    local concatenate_in_place = v17.concatenate_in_place

    for i = 1, v303 do
        local v304 = parents[i]

        if v304 ~= -1 and v304 ~= 0 then
            concatenate_in_place(p30[i], p30[v304 + 1])
        end
    end
end

function t1.PoseEvaluator.hierarchy_reference(p32, p33) -- line: 685
    -- upvalues: v9 (copy)
    if #p33 ~= #p32.frames.parents then
        error("Animation pose and hierarchy bone counts differ", 0)
    end

    local v305 = table.create(#p33)

    for v306, v307 in ipairs(p33) do
        v305[v306] = v9.sqt_to_matrix(v307)
    end

    local compose_hierarchy_in_place = v9.compose_hierarchy_in_place
    local v308 = #v305
    local parents = p32.frames.parents
    local ok, result = pcall(compose_hierarchy_in_place, v308, parents, 0, v305)

    if not ok then
        error("Invalid stock animation hierarchy: " .. (if type(result) ~= "table" then tostring(result)
            elseif result.tag == nil then tostring(result)
            elseif result.tag == "InvalidParent" then string.format("InvalidParent { bone: %d, parent: %d }", result.bone, result.parent)
            else result.tag), 0)
    end

    return v305
end

function t1.PoseEvaluator.hierarchy(p34, p35) -- line: 703
    -- upvalues: v9 (copy), v17 (copy)
    if #p35 ~= #p34.frames.parents then
        error("Animation pose and hierarchy bone counts differ", 0)
    end

    local v309 = table.create(#p35)

    for v310, v311 in ipairs(p35) do
        v309[v310] = v9.sqt_to_matrix(v311)
    end

    local compose_hierarchy_in_place_owned = v17.compose_hierarchy_in_place_owned
    local v312 = #v309
    local parents = p34.frames.parents
    local ok, result = pcall(compose_hierarchy_in_place_owned, v312, parents, 0, v309)

    if not ok then
        error("Invalid stock animation hierarchy: " .. (if type(result) ~= "table" then tostring(result)
            elseif result.tag == nil then tostring(result)
            elseif result.tag == "InvalidParent" then string.format("InvalidParent { bone: %d, parent: %d }", result.bone, result.parent)
            else result.tag), 0)
    end

    return v309
end

function t1.PoseEvaluator.hierarchy_into(p36, p37, p38) -- line: 730
    -- upvalues: v17 (copy), v18 (copy), t1 (copy)
    if #p38 ~= #p37 then
        return t1.PoseEvaluator.hierarchy(p36, p37)
    end

    if #p37 ~= #p36.frames.parents then
        error("Animation pose and hierarchy bone counts differ", 0)
    end

    local sqt_to_matrix_into = v18.sqt_to_matrix_into

    for v313, v314 in ipairs(p37) do
        sqt_to_matrix_into(p38[v313], v314)
    end

    local compose_hierarchy_in_place_owned = v17.compose_hierarchy_in_place_owned
    local v315 = #p38
    local parents = p36.frames.parents
    local ok, result = pcall(compose_hierarchy_in_place_owned, v315, parents, 0, p38)

    if not ok then
        error("Invalid stock animation hierarchy: " .. (if type(result) ~= "table" then tostring(result)
            elseif result.tag == nil then tostring(result)
            elseif result.tag == "InvalidParent" then string.format("InvalidParent { bone: %d, parent: %d }", result.bone, result.parent)
            else result.tag), 0)
    end

    return p38
end

function t1.sample_clip_reference(p39, p40) -- line: 749
    -- upvalues: v1 (copy), sample_key (copy), select_frames (copy), t1 (copy)
    buffer.writeu32(v1, 0, p39.fps_bits)

    local v316 = select_frames(p40, buffer.readf32(v1, 0), #p39.frames, true, 0)
    local v317 = p39.frames[v316.first + 1]
    local v318 = p39.frames[v316.second + 1]
    local v321 = math.min(#v317, #v318)
    local v322 = table.create(v321)

    for i = 0, v321 - 1 do
        local v323 = sample_key(t1.sqt_reference(v317[i + 1]), t1.sqt_reference(v318[i + 1]), v316)
        local translation = v323.translation

        buffer.writeu32(v1, 0, p39.channel_weights[i + 1])
        translation[4] = buffer.readf32(v1, 0)
        v322[i + 1] = v323
    end

    return v322
end

function t1.sample_bone_reference(p41, p42, p43) -- line: 767
    -- upvalues: v1 (copy), sample_key (copy), select_frames (copy), t1 (copy)
    buffer.writeu32(v1, 0, p41.fps_bits)

    local v325 = select_frames(p42, buffer.readf32(v1, 0), #p41.frames, true, 0)
    local v326 = sample_key(t1.sqt_reference(p41.frames[v325.first + 1][p43 + 1]), t1.sqt_reference(p41.frames[v325.second + 1][p43 + 1]), v325)
    local translation = v326.translation

    buffer.writeu32(v1, 0, p41.channel_weights[p43 + 1])
    translation[4] = buffer.readf32(v1, 0)

    return v326
end

function t1.sqt_reference(p44) -- line: 780
    -- upvalues: rt (copy)
    local from_bits = rt.from_bits

    return {
        scale = {
            from_bits(p44[1]),
            from_bits(p44[2]),
            from_bits(p44[3]),
            1
        },
        rotation = {
            from_bits(p44[4]),
            from_bits(p44[5]),
            from_bits(p44[6]),
            from_bits(p44[7])
        },
        translation = {
            from_bits(p44[8]),
            from_bits(p44[9]),
            from_bits(p44[10]),
            1
        }
    }
end

local function v328(p45, p46, p47, p48, p49) -- line: 798
    -- upvalues: v19 (copy)
    if p47 then
        local t9 = {}

        buffer.writeu32(v19, 0, p45[1])

        local v330 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p45[2])

        local v332 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p45[3])
        t9.scale = {
            v330,
            v332,
            buffer.readf32(v19, 0),
            1
        }
        buffer.writeu32(v19, 0, p45[4])

        local v335 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p45[5])

        local v337 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p45[6])

        local v339 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p45[7])
        t9.rotation = {
            v335,
            v337,
            v339,
            (buffer.readf32(v19, 0))
        }
        buffer.writeu32(v19, 0, p45[8])

        local v342 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p45[9])

        local v344 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p45[10])

        local v346 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p49)
        t9.translation = {
            v342,
            v344,
            v346,
            (buffer.readf32(v19, 0))
        }

        return t9
    end

    buffer.writeu32(v19, 0, p45[1])

    local v348 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p45[2])

    local v350 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p45[3])

    local v352 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p45[4])

    local v354 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p45[5])

    local v356 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p45[6])

    local v358 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p45[7])

    local v360 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p45[8])

    local v362 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p45[9])

    local v364 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p45[10])

    local v366 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p46[4])

    local v368 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p46[5])

    local v370 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p46[6])

    local v372 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p46[7])

    local v374 = buffer.readf32(v19, 0)
    local v375, v376, v377, v378

    if v354 * v368 + v356 * v370 + v358 * v372 + v360 * v374 > 0 then
        v375 = (v368 - v354) * p48 + v354
        v376 = (v370 - v356) * p48 + v356
        v377 = (v372 - v358) * p48 + v358
        v378 = (v374 - v360) * p48 + v360
    else
        v375 = -(v368 + v354) * p48 + v354
        v376 = -(v370 + v356) * p48 + v356
        v377 = -(v372 + v358) * p48 + v358
        v378 = -(v374 + v360) * p48 + v360
    end

    local v379 = v375 * v375 + v376 * v376 + v377 * v377 + v378 * v378
    local v380 = 1 / math.sqrt(v379)
    local v381 = v380 * 0.5 * (-v379 * (v380 * v380) + 1) + v380
    local v382 = v381 * 0.5 * (-v379 * (v381 * v381) + 1) + v381
    local t10 = {}

    buffer.writeu32(v19, 0, p46[1])

    local v384 = (buffer.readf32(v19, 0) - v348) * p48 + v348

    buffer.writeu32(v19, 0, p46[2])

    local v386 = (buffer.readf32(v19, 0) - v350) * p48 + v350

    buffer.writeu32(v19, 0, p46[3])
    t10.scale = {
        v384,
        v386,
        (buffer.readf32(v19, 0) - v352) * p48 + v352,
        p48 * 0 + 1
    }
    t10.rotation = {
        v375 * v382,
        v376 * v382,
        v377 * v382,
        v378 * v382
    }
    buffer.writeu32(v19, 0, p46[8])

    local v389 = (buffer.readf32(v19, 0) - v362) * p48 + v362

    buffer.writeu32(v19, 0, p46[9])

    local v391 = (buffer.readf32(v19, 0) - v364) * p48 + v364

    buffer.writeu32(v19, 0, p46[10])

    local v393 = (buffer.readf32(v19, 0) - v366) * p48 + v366

    buffer.writeu32(v19, 0, p49)
    t10.translation = {
        v389,
        v391,
        v393,
        (buffer.readf32(v19, 0))
    }

    return t10
end

local v394 = table.create(2048)
local n1 = 0

v52 = function() -- line: 849
    -- upvalues: v394 (copy), n1 (ref)
    local v395 = n1

    if v395 > 0 then
        local v396 = v394[v395]

        v394[v395] = nil
        n1 = v395 - 1

        return v396
    end

    return {
        scale = { 0, 0, 0, 0 },
        rotation = { 0, 0, 0, 0 },
        translation = { 0, 0, 0, 0 }
    }
end

v53 = function(p50) -- line: 864
    -- upvalues: v394 (copy), n1 (ref)
    local v397 = n1

    if not (v397 < 2048) then
        return
    end

    local v398 = v397 + 1

    v394[v398] = p50
    n1 = v398
end

v54 = function(p51) -- line: 873
    -- upvalues: v394 (copy), n1 (ref)
    local v399 = n1

    for i = 1, #p51 do
        if v399 >= 2048 then
            break
        end

        v399 += 1
        v394[v399] = p51[i]
    end

    n1 = v399
end

v55 = function(p52, p53) -- line: 886
    -- upvalues: v19 (copy)
    local scale, rotation, translation = p52.scale, p52.rotation, p52.translation

    buffer.writeu32(v19, 0, p53[1])

    local v401 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p53[2])

    local v403 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p53[3])

    local v405 = buffer.readf32(v19, 0)

    scale[1] = v401
    scale[2] = v403
    scale[3] = v405
    scale[4] = 1
    buffer.writeu32(v19, 0, p53[4])

    local v407 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p53[5])

    local v409 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p53[6])

    local v411 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p53[7])

    local v413 = buffer.readf32(v19, 0)

    rotation[1] = v407
    rotation[2] = v409
    rotation[3] = v411
    rotation[4] = v413
    buffer.writeu32(v19, 0, p53[8])

    local v415 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p53[9])

    local v417 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p53[10])

    local v419 = buffer.readf32(v19, 0)

    translation[1] = v415
    translation[2] = v417
    translation[3] = v419
    translation[4] = 1

    return p52
end

local function sample_pair_into(p54, p55, p56, p57, p58, p59) -- line: 895
    -- upvalues: v19 (copy)
    local scale, rotation, translation = p54.scale, p54.rotation, p54.translation

    if p57 then
        buffer.writeu32(v19, 0, p55[1])

        local v421 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[2])

        local v423 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[3])

        local v425 = buffer.readf32(v19, 0)

        scale[1] = v421
        scale[2] = v423
        scale[3] = v425
        scale[4] = 1
        buffer.writeu32(v19, 0, p55[4])

        local v427 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[5])

        local v429 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[6])

        local v431 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[7])

        local v433 = buffer.readf32(v19, 0)

        rotation[1] = v427
        rotation[2] = v429
        rotation[3] = v431
        rotation[4] = v433
        buffer.writeu32(v19, 0, p55[8])

        local v435 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[9])

        local v437 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[10])

        local v439 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p59)

        local v440 = buffer.readf32(v19, 0)

        translation[1] = v435
        translation[2] = v437
        translation[3] = v439
        translation[4] = v440
    else
        buffer.writeu32(v19, 0, p55[1])

        local v442 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[2])

        local v444 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[3])

        local v446 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[4])

        local v448 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[5])

        local v450 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[6])

        local v452 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[7])

        local v454 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[8])

        local v456 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[9])

        local v458 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p55[10])

        local v460 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p56[4])

        local v462 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p56[5])

        local v464 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p56[6])

        local v466 = buffer.readf32(v19, 0)

        buffer.writeu32(v19, 0, p56[7])

        local v468 = buffer.readf32(v19, 0)
        local v469, v470, v471, v472

        if v448 * v462 + v450 * v464 + v452 * v466 + v454 * v468 > 0 then
            v469 = (v462 - v448) * p58 + v448
            v470 = (v464 - v450) * p58 + v450
            v471 = (v466 - v452) * p58 + v452
            v472 = (v468 - v454) * p58 + v454
        else
            v469 = -(v462 + v448) * p58 + v448
            v470 = -(v464 + v450) * p58 + v450
            v471 = -(v466 + v452) * p58 + v452
            v472 = -(v468 + v454) * p58 + v454
        end

        local v473 = v469 * v469 + v470 * v470 + v471 * v471 + v472 * v472
        local v474 = 1 / math.sqrt(v473)
        local v475 = v474 * 0.5 * (-v473 * (v474 * v474) + 1) + v474
        local v476 = v475 * 0.5 * (-v473 * (v475 * v475) + 1) + v475

        buffer.writeu32(v19, 0, p56[1])
        scale[1] = (buffer.readf32(v19, 0) - v442) * p58 + v442
        buffer.writeu32(v19, 0, p56[2])
        scale[2] = (buffer.readf32(v19, 0) - v444) * p58 + v444
        buffer.writeu32(v19, 0, p56[3])
        scale[3] = (buffer.readf32(v19, 0) - v446) * p58 + v446
        scale[4] = p58 * 0 + 1

        local v480 = v469 * v476
        local v481 = v470 * v476
        local v482 = v471 * v476
        local v483 = v472 * v476

        rotation[1] = v480
        rotation[2] = v481
        rotation[3] = v482
        rotation[4] = v483
        buffer.writeu32(v19, 0, p56[8])
        translation[1] = (buffer.readf32(v19, 0) - v456) * p58 + v456
        buffer.writeu32(v19, 0, p56[9])
        translation[2] = (buffer.readf32(v19, 0) - v458) * p58 + v458
        buffer.writeu32(v19, 0, p56[10])
        translation[3] = (buffer.readf32(v19, 0) - v460) * p58 + v460
        buffer.writeu32(v19, 0, p59)
        translation[4] = buffer.readf32(v19, 0)
    end

    return p54
end

local function sample_buffer_into(p60, p61, p62, p63, p64, p65, p66, p67) -- line: 943
    -- upvalues: v19 (copy)
    local scale, rotation, translation = p60.scale, p60.rotation, p60.translation

    if p65 then
        local v487 = buffer.readf32(p61, p62)
        local v489 = buffer.readf32(p61, p62 + 4)
        local v491 = buffer.readf32(p61, p62 + 8)

        scale[1] = v487
        scale[2] = v489
        scale[3] = v491
        scale[4] = 1

        local v493 = buffer.readf32(p61, p62 + 12)
        local v495 = buffer.readf32(p61, p62 + 16)
        local v497 = buffer.readf32(p61, p62 + 20)
        local v499 = buffer.readf32(p61, p62 + 24)

        rotation[1] = v493
        rotation[2] = v495
        rotation[3] = v497
        rotation[4] = v499

        local v501 = buffer.readf32(p61, p62 + 28)
        local v503 = buffer.readf32(p61, p62 + 32)
        local v505 = buffer.readf32(p61, p62 + 36)

        buffer.writeu32(v19, 0, p67)

        local v506 = buffer.readf32(v19, 0)

        translation[1] = v501
        translation[2] = v503
        translation[3] = v505
        translation[4] = v506
    else
        local v507 = buffer.readf32(p61, p62)
        local v509 = buffer.readf32(p61, p62 + 4)
        local v511 = buffer.readf32(p61, p62 + 8)
        local v513 = buffer.readf32(p61, p62 + 12)
        local v515 = buffer.readf32(p61, p62 + 16)
        local v517 = buffer.readf32(p61, p62 + 20)
        local v519 = buffer.readf32(p61, p62 + 24)
        local v521 = buffer.readf32(p61, p62 + 28)
        local v523 = buffer.readf32(p61, p62 + 32)
        local v525 = buffer.readf32(p61, p62 + 36)
        local v527 = buffer.readf32(p63, p64 + 12)
        local v529 = buffer.readf32(p63, p64 + 16)
        local v531 = buffer.readf32(p63, p64 + 20)
        local v533 = buffer.readf32(p63, p64 + 24)
        local v534, v535, v536, v537

        if v513 * v527 + v515 * v529 + v517 * v531 + v519 * v533 > 0 then
            v534 = (v527 - v513) * p66 + v513
            v535 = (v529 - v515) * p66 + v515
            v536 = (v531 - v517) * p66 + v517
            v537 = (v533 - v519) * p66 + v519
        else
            v534 = -(v527 + v513) * p66 + v513
            v535 = -(v529 + v515) * p66 + v515
            v536 = -(v531 + v517) * p66 + v517
            v537 = -(v533 + v519) * p66 + v519
        end

        local v538 = v534 * v534 + v535 * v535 + v536 * v536 + v537 * v537
        local v539 = 1 / math.sqrt(v538)
        local v540 = v539 * 0.5 * (-v538 * (v539 * v539) + 1) + v539
        local v541 = v540 * 0.5 * (-v538 * (v540 * v540) + 1) + v540

        scale[1] = (buffer.readf32(p63, p64) - v507) * p66 + v507
        scale[2] = (buffer.readf32(p63, p64 + 4) - v509) * p66 + v509
        scale[3] = (buffer.readf32(p63, p64 + 8) - v511) * p66 + v511
        scale[4] = p66 * 0 + 1

        local v544 = v534 * v541
        local v545 = v535 * v541
        local v546 = v536 * v541
        local v547 = v537 * v541

        rotation[1] = v544
        rotation[2] = v545
        rotation[3] = v546
        rotation[4] = v547
        translation[1] = (buffer.readf32(p63, p64 + 28) - v521) * p66 + v521
        translation[2] = (buffer.readf32(p63, p64 + 32) - v523) * p66 + v523
        translation[3] = (buffer.readf32(p63, p64 + 36) - v525) * p66 + v525
        buffer.writeu32(v19, 0, p67)
        translation[4] = buffer.readf32(v19, 0)
    end

    return p60
end

local function frame_rows(p68, p69, p70) -- line: 991
    -- upvalues: ensure (copy)
    local v551 = p68.bone_count * 40
    local block_words = p68.block_words

    if block_words ~= nil then
        if p68.pending ~= nil then
            ensure(p68, p69, p70)
            block_words = p68.block_words
        end

        if block_words ~= nil then
            return block_words[bit32.rshift(p69, 3) + 1], bit32.band(p69, 7) * v551, block_words[bit32.rshift(p70, 3) + 1], bit32.band(p70, 7) * v551
        end
    end

    local words = p68.words

    return words, p69 * v551, words, p70 * v551
end

v58 = function() -- line: 1010
    return {
        scale = { 0, 0, 0, 0 },
        rotation = { 0, 0, 0, 0 },
        translation = { 0, 0, 0, 0 }
    }
end

local function sample_clip_packed(p71, p72, p73) -- line: 1022
    -- upvalues: v1 (copy), select_two (copy), v52 (ref), v58 (ref), sample_buffer_into (copy), frame_rows (copy)
    local bone_count = p71.bone_count

    buffer.writeu32(v1, 0, p71.fps_bits)

    local v552, v553, v554 = select_two(p72, buffer.readf32(v1, 0), p71.frame_count)
    local v555, v556, v557, v558 = frame_rows(p71, v552, v553)
    local v559 = table.create(bone_count)
    local v560 = v552 == v553
    local channel_weights = p71.channel_weights

    for i = 1, bone_count do
        v559[i] = sample_buffer_into(if p73 then v58() else v52(), v555, v556, v557, v558, v560, v554, channel_weights[i])
        v556 += 40
        v558 += 40
    end

    return v559
end

local function sample_bone_packed(p74, p75, p76, p77) -- line: 1046
    -- upvalues: v1 (copy), select_two (copy), v52 (ref), v58 (ref), sample_buffer_into (copy), frame_rows (copy)
    local bone_count = p74.bone_count

    buffer.writeu32(v1, 0, p74.fps_bits)

    local v562, v563, v564 = select_two(p75, buffer.readf32(v1, 0), p74.frame_count)
    local v565, v566, v567, v568 = frame_rows(p74, v562, v563)

    if bone_count <= p76 then
        error("attempt to index nil with number", 0)
    end

    return (sample_buffer_into(if p77 then v58() else v52(), v565, v566 + p76 * 40, v567, v568 + p76 * 40, v562 == v563, v564, p74.channel_weights[p76 + 1]))
end

local self3 = setmetatable({}, {
    __mode = "k"
})

local function clip_channel_floats(p78) -- line: 1084
    -- upvalues: v19 (copy), self3 (copy)
    local v571 = self3[p78]

    if v571 == nil then
        local channel_weights = p78.channel_weights

        v571 = table.create(#channel_weights)

        for v572, v573 in channel_weights do
            buffer.writeu32(v19, 0, v573)
            v571[v572] = buffer.readf32(v19, 0)
        end

        self3[p78] = v571
    end

    return v571
end

v59 = function(p79, p80) -- line: 1109
    -- upvalues: v1 (copy), select_two (copy), v394 (copy), n1 (ref), frame_rows (copy), clip_channel_floats (copy)
    local bone_count = p79.bone_count

    buffer.writeu32(v1, 0, p79.fps_bits)

    local v574, v575, v576 = select_two(p80, buffer.readf32(v1, 0), p79.frame_count)
    local v577, v578, v579, v580 = frame_rows(p79, v574, v575)
    local v581 = table.create(bone_count)
    local v582 = v574 == v575
    local v583 = clip_channel_floats(p79)

    for i = 1, bone_count do
        local v584 = n1
        local v585

        if v584 > 0 then
            v585 = v394[v584]
            v394[v584] = nil
            n1 = v584 - 1
        else
            v585 = {
                scale = { 0, 0, 0, 0 },
                rotation = { 0, 0, 0, 0 },
                translation = { 0, 0, 0, 0 }
            }
        end

        local scale, rotation, translation = v585.scale, v585.rotation, v585.translation

        if v582 then
            local v586 = buffer.readf32(v577, v578)
            local v588 = buffer.readf32(v577, v578 + 4)
            local v590 = buffer.readf32(v577, v578 + 8)

            scale[1] = v586
            scale[2] = v588
            scale[3] = v590
            scale[4] = 1

            local v592 = buffer.readf32(v577, v578 + 12)
            local v594 = buffer.readf32(v577, v578 + 16)
            local v596 = buffer.readf32(v577, v578 + 20)
            local v598 = buffer.readf32(v577, v578 + 24)

            rotation[1] = v592
            rotation[2] = v594
            rotation[3] = v596
            rotation[4] = v598

            local v600 = buffer.readf32(v577, v578 + 28)
            local v602 = buffer.readf32(v577, v578 + 32)
            local v604 = buffer.readf32(v577, v578 + 36)
            local v605 = v583[i]

            translation[1] = v600
            translation[2] = v602
            translation[3] = v604
            translation[4] = v605
        else
            local v606 = buffer.readf32(v577, v578)
            local v608 = buffer.readf32(v577, v578 + 4)
            local v610 = buffer.readf32(v577, v578 + 8)
            local v612 = buffer.readf32(v577, v578 + 12)
            local v614 = buffer.readf32(v577, v578 + 16)
            local v616 = buffer.readf32(v577, v578 + 20)
            local v618 = buffer.readf32(v577, v578 + 24)
            local v620 = buffer.readf32(v577, v578 + 28)
            local v622 = buffer.readf32(v577, v578 + 32)
            local v624 = buffer.readf32(v577, v578 + 36)
            local v626 = buffer.readf32(v579, v580 + 12)
            local v628 = buffer.readf32(v579, v580 + 16)
            local v630 = buffer.readf32(v579, v580 + 20)
            local v632 = buffer.readf32(v579, v580 + 24)
            local v633, v634, v635, v636

            if v612 * v626 + v614 * v628 + v616 * v630 + v618 * v632 > 0 then
                v633 = (v626 - v612) * v576 + v612
                v634 = (v628 - v614) * v576 + v614
                v635 = (v630 - v616) * v576 + v616
                v636 = (v632 - v618) * v576 + v618
            else
                v633 = -(v626 + v612) * v576 + v612
                v634 = -(v628 + v614) * v576 + v614
                v635 = -(v630 + v616) * v576 + v616
                v636 = -(v632 + v618) * v576 + v618
            end

            local v637 = v633 * v633 + v634 * v634 + v635 * v635 + v636 * v636
            local v638 = 1 / math.sqrt(v637)
            local v639 = v638 * 0.5 * (-v637 * (v638 * v638) + 1) + v638
            local v640 = v639 * 0.5 * (-v637 * (v639 * v639) + 1) + v639

            scale[1] = (buffer.readf32(v579, v580) - v606) * v576 + v606
            scale[2] = (buffer.readf32(v579, v580 + 4) - v608) * v576 + v608
            scale[3] = (buffer.readf32(v579, v580 + 8) - v610) * v576 + v610
            scale[4] = 0 * v576 + 1

            local v643 = v633 * v640
            local v644 = v634 * v640
            local v645 = v635 * v640
            local v646 = v636 * v640

            rotation[1] = v643
            rotation[2] = v644
            rotation[3] = v645
            rotation[4] = v646
            translation[1] = (buffer.readf32(v579, v580 + 28) - v620) * v576 + v620
            translation[2] = (buffer.readf32(v579, v580 + 32) - v622) * v576 + v622
            translation[3] = (buffer.readf32(v579, v580 + 36) - v624) * v576 + v624
            translation[4] = v583[i]
        end

        v581[i] = v585
        v578 += 40
        v580 += 40
    end

    return v581
end

v61 = function(p81, p82, p83, p84, p85) -- line: 1175
    -- upvalues: v1 (copy), blend_sample_into (copy), v19 (copy), select_two (copy), v52 (ref), v53 (ref), v57 (ref), delta_into (copy), sample_buffer_into (copy), frame_rows (copy), clip_channel_floats (copy)
    local bone_count = p83.bone_count
    local time = p84.time

    buffer.writeu32(v1, 0, p83.fps_bits)

    local v650, v651, v652 = select_two(time, buffer.readf32(v1, 0), p83.frame_count)
    local v653, v654, v655, v656 = frame_rows(p83, v650, v651)
    local channel_weights = p83.channel_weights
    local v657

    if p81.frames.has_trajectory then
        local v660 = sample_buffer_into(v52(), v653, v654, v655, v656, v650 == v651, v652, channel_weights[1])
        local v661 = v57(p83, p84.previous_time, 0)

        if p84.loops == 0 then
            delta_into(v660, v661, 0, 0, 0, 1, 0, 0, 0)
        else
            local loop_rotation_bits, loop_translation_bits = p83.loop_rotation_bits, p83.loop_translation_bits

            buffer.writeu32(v19, 0, loop_rotation_bits[1])

            local v663 = buffer.readf32(v19, 0)

            buffer.writeu32(v19, 0, loop_rotation_bits[2])

            local v665 = buffer.readf32(v19, 0)

            buffer.writeu32(v19, 0, loop_rotation_bits[3])

            local v667 = buffer.readf32(v19, 0)

            buffer.writeu32(v19, 0, loop_rotation_bits[4])

            local v669 = buffer.readf32(v19, 0)

            buffer.writeu32(v19, 0, loop_translation_bits[1])

            local v671 = buffer.readf32(v19, 0)

            buffer.writeu32(v19, 0, loop_translation_bits[2])

            local v673 = buffer.readf32(v19, 0)

            buffer.writeu32(v19, 0, loop_translation_bits[3])
            delta_into(v660, v661, v663, v665, v667, v669, v671, v673, (buffer.readf32(v19, 0)))
        end

        v53(v661)
        blend_sample_into(p82[1], v660, p85)
        v657 = 2
        v53(v660)
    else
        v657 = 1
    end

    local v675 = v650 == v651
    local v676 = v654 + (v657 - 1) * 40
    local v677 = v656 + (v657 - 1) * 40
    local v678 = clip_channel_floats(p83)

    for i = v657, bone_count do
        local v679, v680, v681, v682, v683, v684, v685, v686, v687, v688, v689

        if v675 then
            v683 = buffer.readf32(v653, v676)
            v684 = buffer.readf32(v653, v676 + 4)
            v685 = buffer.readf32(v653, v676 + 8)
            v679 = buffer.readf32(v653, v676 + 12)
            v680 = buffer.readf32(v653, v676 + 16)
            v681 = buffer.readf32(v653, v676 + 20)
            v682 = buffer.readf32(v653, v676 + 24)
            v687 = buffer.readf32(v653, v676 + 28)
            v688 = buffer.readf32(v653, v676 + 32)
            v686 = 1
            v689 = buffer.readf32(v653, v676 + 36)
        else
            local v699 = buffer.readf32(v653, v676)
            local v701 = buffer.readf32(v653, v676 + 4)
            local v703 = buffer.readf32(v653, v676 + 8)
            local v705 = buffer.readf32(v653, v676 + 12)
            local v707 = buffer.readf32(v653, v676 + 16)
            local v709 = buffer.readf32(v653, v676 + 20)
            local v711 = buffer.readf32(v653, v676 + 24)
            local v713 = buffer.readf32(v653, v676 + 28)
            local v715 = buffer.readf32(v653, v676 + 32)
            local v717 = buffer.readf32(v653, v676 + 36)
            local v719 = buffer.readf32(v655, v677 + 12)
            local v721 = buffer.readf32(v655, v677 + 16)
            local v723 = buffer.readf32(v655, v677 + 20)
            local v725 = buffer.readf32(v655, v677 + 24)
            local v726, v727, v728, v729

            if v705 * v719 + v707 * v721 + v709 * v723 + v711 * v725 > 0 then
                v726 = (v719 - v705) * v652 + v705
                v727 = (v721 - v707) * v652 + v707
                v728 = (v723 - v709) * v652 + v709
                v729 = (v725 - v711) * v652 + v711
            else
                v726 = -(v719 + v705) * v652 + v705
                v727 = -(v721 + v707) * v652 + v707
                v728 = -(v723 + v709) * v652 + v709
                v729 = -(v725 + v711) * v652 + v711
            end

            local v730 = v726 * v726 + v727 * v727 + v728 * v728 + v729 * v729
            local v731 = 1 / math.sqrt(v730)
            local v732 = v731 * 0.5 * (-v730 * (v731 * v731) + 1) + v731
            local v733 = v732 * 0.5 * (-v730 * (v732 * v732) + 1) + v732

            v683 = (buffer.readf32(v655, v677) - v699) * v652 + v699
            v684 = (buffer.readf32(v655, v677 + 4) - v701) * v652 + v701
            v685 = (buffer.readf32(v655, v677 + 8) - v703) * v652 + v703
            v686 = 0 * v652 + 1
            v679 = v726 * v733
            v680 = v727 * v733
            v681 = v728 * v733
            v682 = v729 * v733
            v687 = (buffer.readf32(v655, v677 + 28) - v713) * v652 + v713
            v688 = (buffer.readf32(v655, v677 + 32) - v715) * v652 + v715
            v689 = (buffer.readf32(v655, v677 + 36) - v717) * v652 + v717
        end

        local v739 = v678[i]
        local v740 = p82[i]
        local rotation = v740.rotation
        local v741 = rotation[1]
        local v742 = rotation[2]
        local v743 = rotation[3]
        local v744 = rotation[4]
        local v745, v746, v747, v748

        if v741 * v679 + v742 * v680 + v743 * v681 + v744 * v682 > 0 then
            v745 = (v679 - v741) * p85 + v741
            v746 = (v680 - v742) * p85 + v742
            v747 = (v681 - v743) * p85 + v743
            v748 = (v682 - v744) * p85 + v744
        else
            v745 = -(v679 + v741) * p85 + v741
            v746 = -(v680 + v742) * p85 + v742
            v747 = -(v681 + v743) * p85 + v743
            v748 = -(v682 + v744) * p85 + v744
        end

        local v749 = v745 * v745 + v746 * v746 + v747 * v747 + v748 * v748
        local v750 = 1 / math.sqrt(v749)
        local v751 = v750 * 0.5 * (-v749 * (v750 * v750) + 1) + v750
        local v752 = v751 * 0.5 * (-v749 * (v751 * v751) + 1) + v751
        local scale, translation = v740.scale, v740.translation
        local v753 = scale[1]
        local v754 = scale[2]
        local v755 = scale[3]
        local v756 = scale[4]
        local v757 = translation[1]
        local v758 = translation[2]
        local v759 = translation[3]
        local v760 = translation[4]
        local v761 = (v683 - v753) * p85 + v753
        local v762 = (v684 - v754) * p85 + v754
        local v763 = (v685 - v755) * p85 + v755
        local v764 = (v686 - v756) * p85 + v756
        local v765 = (v687 - v757) * p85 + v757
        local v766 = (v688 - v758) * p85 + v758
        local v767 = (v689 - v759) * p85 + v759
        local v768 = (v739 - v760) * p85 + v760

        scale[1] = v761
        scale[2] = v762
        scale[3] = v763
        scale[4] = v764

        local v769 = v745 * v752
        local v770 = v746 * v752
        local v771 = v747 * v752
        local v772 = v748 * v752

        rotation[1] = v769
        rotation[2] = v770
        rotation[3] = v771
        rotation[4] = v772
        translation[1] = v765
        translation[2] = v766
        translation[3] = v767
        translation[4] = v768
        v676 += 40
        v677 += 40
    end
end

v56 = function(p86, p87) -- line: 1289
    -- upvalues: v1 (copy), select_frames (copy), v52 (ref), sample_pair_into (copy), sample_clip_packed (copy)
    if p86.words ~= nil or p86.block_words ~= nil then
        return (sample_clip_packed(p86, p87, false))
    end

    local frames = p86.frames

    buffer.writeu32(v1, 0, p86.fps_bits)

    local v773 = select_frames(p87, buffer.readf32(v1, 0), #frames, true, 0)
    local v774 = frames[v773.first + 1]
    local v775 = frames[v773.second + 1]
    local v778 = math.min(#v774, #v775)
    local v779 = table.create(v778)
    local v780 = v773.first == v773.second
    local coefficient = v773.coefficient
    local channel_weights = p86.channel_weights

    for i = 1, v778 do
        v779[i] = sample_pair_into(v52(), v774[i], v775[i], v780, coefficient, channel_weights[i])
    end

    return v779
end

v57 = function(p88, p89, p90) -- line: 1315
    -- upvalues: v1 (copy), select_frames (copy), v52 (ref), sample_pair_into (copy), sample_bone_packed (copy)
    if p88.words ~= nil or p88.block_words ~= nil then
        return (sample_bone_packed(p88, p89, p90, false))
    end

    local frames = p88.frames

    buffer.writeu32(v1, 0, p88.fps_bits)

    local v781 = select_frames(p89, buffer.readf32(v1, 0), #frames, true, 0)

    return (sample_pair_into(v52(), frames[v781.first + 1][p90 + 1], frames[v781.second + 1][p90 + 1], v781.first == v781.second, v781.coefficient, p88.channel_weights[p90 + 1]))
end

function t1.set_lazy_clips(p91) -- line: 1333
    -- upvalues: v64 (ref)
    v64 = p91
end

function t1.set_fused_blend(p92) -- line: 1336
    -- upvalues: v62 (ref)
    v62 = p92
end

function t1.set_pose_add(p93) -- line: 1340
    -- upvalues: v101 (ref)
    v101 = p93
end

function t1.set_inline_loops(p94) -- line: 1344
    -- upvalues: v60 (ref)
    v60 = p94
end

t1.stock_clip = stock_clip
t1.select_two = select_two

function t1.sample_pool() -- line: 1351
    -- upvalues: v394 (copy), n1 (ref)
    return n1, v394
end

function t1.sample_clip(p95, p96) -- line: 1359
    -- upvalues: v1 (copy), select_frames (copy), v328 (copy), sample_clip_packed (copy)
    if p95.words ~= nil or p95.block_words ~= nil then
        return (sample_clip_packed(p95, p96, true))
    end

    local frames = p95.frames

    buffer.writeu32(v1, 0, p95.fps_bits)

    local v786 = select_frames(p96, buffer.readf32(v1, 0), #frames, true, 0)
    local v787 = frames[v786.first + 1]
    local v788 = frames[v786.second + 1]
    local v791 = math.min(#v787, #v788)
    local v792 = table.create(v791)
    local v793 = v786.first == v786.second
    local coefficient = v786.coefficient
    local channel_weights = p95.channel_weights

    for i = 1, v791 do
        v792[i] = v328(v787[i], v788[i], v793, coefficient, channel_weights[i])
    end

    return v792
end

function t1.sample_bone(p97, p98, p99) -- line: 1383
    -- upvalues: v1 (copy), select_frames (copy), v328 (copy), sample_bone_packed (copy)
    if p97.words ~= nil or p97.block_words ~= nil then
        return (sample_bone_packed(p97, p98, p99, true))
    end

    local frames = p97.frames

    buffer.writeu32(v1, 0, p97.fps_bits)

    local v794 = select_frames(p98, buffer.readf32(v1, 0), #frames, true, 0)

    return v328(frames[v794.first + 1][p99 + 1], frames[v794.second + 1][p99 + 1], v794.first == v794.second, v794.coefficient, p97.channel_weights[p99 + 1])
end

function t1.sqt(p100) -- line: 1403
    -- upvalues: v19 (copy)
    local t13 = {}

    buffer.writeu32(v19, 0, p100[1])

    local v799 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p100[2])

    local v801 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p100[3])
    t13.scale = {
        v799,
        v801,
        buffer.readf32(v19, 0),
        1
    }
    buffer.writeu32(v19, 0, p100[4])

    local v804 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p100[5])

    local v806 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p100[6])

    local v808 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p100[7])
    t13.rotation = {
        v804,
        v806,
        v808,
        (buffer.readf32(v19, 0))
    }
    buffer.writeu32(v19, 0, p100[8])

    local v811 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p100[9])

    local v813 = buffer.readf32(v19, 0)

    buffer.writeu32(v19, 0, p100[10])
    t13.translation = {
        v811,
        v813,
        buffer.readf32(v19, 0),
        1
    }

    return t13
end

return t1
