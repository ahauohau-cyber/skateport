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
local v8 = import("skate_core/animation/output")
local CorrectionState = import("skate_core/physics/skeleton_output/correction").CorrectionState

local function solve() -- line: 39
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local function wipeout() -- line: 42
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout")
end

local function skeleton_output() -- line: 45
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_output")
end

local function foot_ik() -- line: 48
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_ik")
end

local function foot_physical_output() -- line: 51
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_physical_output")
end

local function animation_pose() -- line: 54
    -- upvalues: import (copy)
    return import("skate_game/animation_pose")
end

local v9 = import("skate_core/animation/output/sqt")
local t1 = {}
local v10, v11
local t2 = {}

local function new_matrices(p4) -- line: 70
    local v12 = table.create(p4)

    for i = 1, p4 do
        v12[i] = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        }
    end

    return v12
end

local function map_from_bits(p5) -- line: 83
    -- upvalues: v1 (copy)
    local v13 = table.create(#p5)

    for i = 1, #p5 do
        buffer.writeu32(v1, 0, p5[i])
        v13[i] = buffer.readf32(v1, 0)
    end

    return v13
end

local function map_to_bits(p6) -- line: 91
    -- upvalues: v1 (copy)
    local v15 = table.create(#p6)

    for i = 1, #p6 do
        local v16 = p6[i]

        if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
            local v17 = math.abs(v16) * 7.1362384635298E+44
            local v18 = math.floor(v17)
            local v19 = v17 - v18
            local v20 = if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18

            if v16 < 0 then
                v15[i] = v20 + 2147483648
            else
                v15[i] = v20
            end
        else
            buffer.writef32(v1, 0, v16)
            v15[i] = buffer.readu32(v1, 0)
        end
    end

    return v15
end

local function u8_from(p7) -- line: 99
    if p7 then
        return 1
    end

    return 0
end

local function debug_fmt(p8) -- line: 105
    -- upvalues: debug_fmt (copy)
    if type(p8) ~= "table" or p8.tag == nil then
        return (tostring(p8))
    end

    local t3 = {}

    for v21 in p8 do
        if type(v21) == "string" and v21 ~= "tag" then
            table.insert(t3, v21)
        end
    end

    table.sort(t3)

    local t4 = {}

    if #t3 > 0 then
        for _, v22 in t3 do
            table.insert(t4, v22 .. ": " .. tostring(p8[v22]))
        end

        return p8.tag .. " { " .. table.concat(t4, ", ") .. " }"
    end

    for _, v25 in ipairs(p8) do
        table.insert(t4, debug_fmt(v25))
    end

    if #t4 > 0 then
        return p8.tag .. "(" .. table.concat(t4, ", ") .. ")"
    end

    return p8.tag
end

local v26 = import("skate_core/animation/output/hierarchy")
local self = setmetatable({}, {
    __mode = "k"
})

t1.OWNED_POSE = true

local v28 = false

function t1.set_b3_twin(p9) -- line: 209
    -- upvalues: v28 (ref)
    v28 = p9
end

local v29 = false
local self2 = setmetatable({}, {
    __mode = "k"
})
local self3 = setmetatable({}, {
    __mode = "k"
})
local self4 = setmetatable({}, {
    __mode = "k"
})

function t1.set_deferred(p10) -- line: 220
    -- upvalues: v29 (ref)
    v29 = p10
end

function t1.deferred() -- line: 223
    -- upvalues: v29 (ref)
    return v29
end

function t1.skip_next(p11) -- line: 228
    -- upvalues: self2 (copy)
    self2[p11] = true
end

function t1.pending(p12) -- line: 232
    -- upvalues: self3 (copy)
    return self3[p12] or 0
end

local function owned_matrices(p13, p14) -- line: 236
    -- upvalues: new_matrices (copy), self (copy)
    local v33 = self[p13]

    if v33 == nil or v33.count ~= p14 then
        local v34 = new_matrices(p14)

        v33 = {
            count = p14,
            array = v34,
            matrices = table.clone(v34)
        }
        self[p13] = v33
    end

    return v33
end

local function render_tail(p15, p16, p17, p18, p19) -- line: 247
    -- upvalues: import (copy), v9 (copy), v10 (ref), v11 (ref), t2 (copy), new_matrices (copy), debug_fmt (copy), v26 (copy), self4 (copy), owned_matrices (copy)
    local v35 = v10

    if v35 == nil or #v35 ~= p19 then
        v35 = new_matrices(p19)
        v10 = v35
        v11 = new_matrices(p19)
    end

    for i = 1, p19 do
        t2[i] = false
    end

    local pose = p16.skeleton_output.pose

    for _, v36 in ipairs(pose.bone_indices) do
        t2[v36 + 1] = true
    end

    local v37 = owned_matrices(p16, p19)
    local array, matrices = v37.array, v37.matrices
    local sqt_to_matrix_into = v9.sqt_to_matrix_into

    for i = 1, p19 do
        local v38 = matrices[i]

        array[i] = v38

        if not t2[i] then
            sqt_to_matrix_into(v38, p18[i])
        end
    end

    for i = #array, p19 + 1, -1 do
        array[i] = nil
    end

    import("skate_game/physics/skeleton_output").SkeletonOutput.publish_owned(p16.skeleton_output, p16.animated_skeleton, p16.skeleton, p15.board, p15.settings.step.base_truck_transforms, p16.ground.steering.targets, p17, v35, array)

    local parents = p16.animation.evaluator.frames.parents
    local compose_hierarchy_in_place_owned = v26.compose_hierarchy_in_place_owned
    local ok, result = pcall(compose_hierarchy_in_place_owned, p19, parents, 0, array)

    if not ok then
        error(string.format("Physical render hierarchy: %s", (debug_fmt(result))), 0)
    end

    p16.render_pose = array

    local v39 = self4[p16]

    if v39 ~= nil then
        v39[1] = p19
        v39[2] = parents
        v39[3] = pose
    else
        self4[p16] = { p19, parents, pose }
    end
end

function t1.publish(p20, p21, p22) -- line: 300
    -- upvalues: v1 (copy), import (copy), CorrectionState (copy), t1 (copy), v28 (ref), v29 (ref), self2 (copy), self3 (copy), self4 (copy), render_tail (copy)
    if v28 then
        return t1.publish_r3(p20, p21, p22)
    end

    local v40 = import("skate_game/physics/solve").deck_frame(p20.board)
    local processed = p21.player_input.processed
    local v41 = import("skate_game/physics/wipeout").Wipeout.requests_wipeout(p21.wipeout, processed)
    local apply = CorrectionState.apply
    local correction = p21.skeleton_output.correction
    local skeleton = p21.skeleton
    local v42 = processed.vectors_544_560_592_608[1]
    local v43 = table.create(#v42)

    for i = 1, #v42 do
        buffer.writeu32(v1, 0, v42[i])
        v43[i] = buffer.readf32(v1, 0)
    end

    apply(correction, skeleton, v43, v41, processed.flags_2468, processed.flags_2476)

    local v45 = import("skate_game/physics/skeleton_output").SkeletonOutput.advance_wobble(p21.skeleton_output, p21.skeleton, v40)

    import("skate_game/physics/foot_ik").FootIk.post_physics(p21.foot_ik, p21.skeleton, {
        state_id = processed.state_2508,
        category_id = processed.category_2512,
        board_body_flag_868 = p20.riding.ground.part_contact_count ~= 0,
        wipeout = v41,
        flags_2468 = processed.flags_2468,
        flags_2484 = processed.flags_2484,
        value_2664 = processed.state_timer_2664,
        state_2520 = processed.player_state_value_2520,
        world_to_animation = p21.animated_skeleton.roots.world_to_animation,
        board = v45
    })

    local v46 = import("skate_game/physics/foot_physical_output").FootPhysicalOutputs.publish(p21.foot_physical, p21.skeleton.record, p20.settings.step.simulation.time_step)
    local physical = p21.player_input.physical

    physical.skeleton.flag_597 = p21.foot_ik.state.contacts.support_failed and 1 or 0
    physical.skeleton.flag_600 = v46.within_deck_box[1] and 1 or 0
    physical.skeleton.flag_601 = v46.within_deck_box[2] and 1 or 0

    local animation_to_world = p21.animated_skeleton.roots.animation_to_world
    local v47 = table.create(#animation_to_world)

    for i = 1, #animation_to_world do
        local v48 = animation_to_world[i]
        local v49 = table.create(#v48)

        for j = 1, #v48 do
            local v50 = v48[j]

            if v50 ~= 0 and v50 > -1.1754943508222875E-38 and v50 < 1.1754943508222875E-38 then
                local v51 = math.abs(v50) * 7.1362384635298E+44
                local v52 = math.floor(v51)
                local v53 = v51 - v52
                local v54 = if v53 > 0.5 or v53 == 0.5 and v52 % 2 == 1 then v52 + 1 else v52

                if v50 < 0 then
                    v49[j] = v54 + 2147483648
                else
                    v49[j] = v54
                end
            else
                buffer.writef32(v1, 0, v50)
                v49[j] = buffer.readu32(v1, 0)
            end
        end

        v47[i] = v49
    end

    physical.skeleton.anim_to_world_11920 = v47

    local reckoning = physical.reckoning
    local com_velocity = p21.animated_skeleton.board_frames.com_velocity
    local v55 = table.create(#com_velocity)

    for i = 1, #com_velocity do
        local v56 = com_velocity[i]

        if v56 ~= 0 and v56 > -1.1754943508222875E-38 and v56 < 1.1754943508222875E-38 then
            local v57 = math.abs(v56) * 7.1362384635298E+44
            local v58 = math.floor(v57)
            local v59 = v57 - v58
            local v60 = if v59 > 0.5 or v59 == 0.5 and v58 % 2 == 1 then v58 + 1 else v58

            if v56 < 0 then
                v55[i] = v60 + 2147483648
            else
                v55[i] = v60
            end
        else
            buffer.writef32(v1, 0, v56)
            v55[i] = buffer.readu32(v1, 0)
        end
    end

    reckoning.vector_16 = v55

    local reckoning2 = physical.reckoning
    local centre_of_mass = p21.animated_skeleton.board_frames.centre_of_mass
    local v61 = table.create(#centre_of_mass)

    for i = 1, #centre_of_mass do
        local v62 = centre_of_mass[i]

        if v62 ~= 0 and v62 > -1.1754943508222875E-38 and v62 < 1.1754943508222875E-38 then
            local v63 = math.abs(v62) * 7.1362384635298E+44
            local v64 = math.floor(v63)
            local v65 = v63 - v64
            local v66 = if v65 > 0.5 or v65 == 0.5 and v64 % 2 == 1 then v64 + 1 else v64

            if v62 < 0 then
                v61[i] = v66 + 2147483648
            else
                v61[i] = v66
            end
        else
            buffer.writef32(v1, 0, v62)
            v61[i] = buffer.readu32(v1, 0)
        end
    end

    reckoning2.vector_64 = v61

    local up = p20.riding.reckoning.up
    local reckoning3 = physical.reckoning
    local x = up.x
    local v67

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v68 = math.abs(x) * 7.1362384635298E+44
        local v69 = math.floor(v68)
        local v70 = v68 - v69

        v67 = if v70 > 0.5 or v70 == 0.5 and v69 % 2 == 1 then v69 + 1 else v69

        if x < 0 then
            v67 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v67 = buffer.readu32(v1, 0)
    end

    local y = up.y
    local v71

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v72 = math.abs(y) * 7.1362384635298E+44
        local v73 = math.floor(v72)
        local v74 = v72 - v73

        v71 = if v74 > 0.5 or v74 == 0.5 and v73 % 2 == 1 then v73 + 1 else v73

        if y < 0 then
            v71 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v71 = buffer.readu32(v1, 0)
    end

    local z = up.z
    local v75

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v76 = math.abs(z) * 7.1362384635298E+44
        local v77 = math.floor(v76)
        local v78 = v76 - v77

        v75 = if v78 > 0.5 or v78 == 0.5 and v77 % 2 == 1 then v77 + 1 else v77

        if z < 0 then
            v75 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v75 = buffer.readu32(v1, 0)
    end

    buffer.writef32(v1, 0, 0)
    reckoning3.vector_96 = {
        v67,
        v71,
        v75,
        (buffer.readu32(v1, 0))
    }

    local pose = p21.animation.pose
    local v80 = #pose

    import("skate_game/animation_pose").PoseEvaluator.check_hierarchy(p21.animation.evaluator, pose)

    if not (v29 and self2[p21]) then
        if self2[p21] then
            self2[p21] = nil
        end
    else
        self2[p21] = nil

        local v81 = self4[p21]

        if v81 ~= nil and v81[1] == v80 and v81[2] == p21.animation.evaluator.frames.parents and v81[3] == p21.skeleton_output.pose and (p21.climbing == nil or p21.climbing.clips == nil) then
            self3[p21] = (self3[p21] or 0) + 1

            return
        end
    end

    render_tail(p20, p21, p22, pose, v80)

    local v82 = self3[p21]

    if v82 ~= nil then
        self3[p21] = nil
        p21.pose_generation += v82
    end

    p21.pose_generation += 1
end

function t1.flush(p23, p24, p25) -- line: 383
    -- upvalues: import (copy), self3 (copy), render_tail (copy)
    local v83 = self3[p24]

    if v83 == nil and not p25 then
        return false
    end

    local pose = p24.animation.pose

    render_tail(p23, p24, import("skate_game/physics/skeleton_output").SkeletonOutput.average_compressions(p24.skeleton_output, p23.board), pose, #pose)

    if v83 ~= nil then
        self3[p24] = nil
        p24.pose_generation += v83
    end

    return true
end

function t1.publish_r3(p26, p27, p28) -- line: 398
    -- upvalues: v1 (copy), import (copy), v8 (copy), CorrectionState (copy), v9 (copy), v10 (ref), v11 (ref), t2 (copy), new_matrices (copy), debug_fmt (copy)
    local v85 = import("skate_game/physics/solve").deck_frame(p26.board)
    local processed = p27.player_input.processed
    local v86 = import("skate_game/physics/wipeout").Wipeout.requests_wipeout(p27.wipeout, processed)
    local apply = CorrectionState.apply
    local correction = p27.skeleton_output.correction
    local skeleton = p27.skeleton
    local v87 = processed.vectors_544_560_592_608[1]
    local v88 = table.create(#v87)

    for i = 1, #v87 do
        buffer.writeu32(v1, 0, v87[i])
        v88[i] = buffer.readf32(v1, 0)
    end

    apply(correction, skeleton, v88, v86, processed.flags_2468, processed.flags_2476)

    local v90 = import("skate_game/physics/skeleton_output").SkeletonOutput.advance_wobble(p27.skeleton_output, p27.skeleton, v85)

    import("skate_game/physics/foot_ik").FootIk.post_physics(p27.foot_ik, p27.skeleton, {
        state_id = processed.state_2508,
        category_id = processed.category_2512,
        board_body_flag_868 = p26.riding.ground.part_contact_count ~= 0,
        wipeout = v86,
        flags_2468 = processed.flags_2468,
        flags_2484 = processed.flags_2484,
        value_2664 = processed.state_timer_2664,
        state_2520 = processed.player_state_value_2520,
        world_to_animation = p27.animated_skeleton.roots.world_to_animation,
        board = v90
    })

    local v91 = import("skate_game/physics/foot_physical_output").FootPhysicalOutputs.publish(p27.foot_physical, p27.skeleton.record, p26.settings.step.simulation.time_step)
    local physical = p27.player_input.physical

    physical.skeleton.flag_597 = p27.foot_ik.state.contacts.support_failed and 1 or 0
    physical.skeleton.flag_600 = v91.within_deck_box[1] and 1 or 0
    physical.skeleton.flag_601 = v91.within_deck_box[2] and 1 or 0

    local animation_to_world = p27.animated_skeleton.roots.animation_to_world
    local v92 = table.create(#animation_to_world)

    for i = 1, #animation_to_world do
        local v93 = animation_to_world[i]
        local v94 = table.create(#v93)

        for j = 1, #v93 do
            local v95 = v93[j]

            if v95 ~= 0 and v95 > -1.1754943508222875E-38 and v95 < 1.1754943508222875E-38 then
                local v96 = math.abs(v95) * 7.1362384635298E+44
                local v97 = math.floor(v96)
                local v98 = v96 - v97
                local v99 = if v98 > 0.5 or v98 == 0.5 and v97 % 2 == 1 then v97 + 1 else v97

                if v95 < 0 then
                    v94[j] = v99 + 2147483648
                else
                    v94[j] = v99
                end
            else
                buffer.writef32(v1, 0, v95)
                v94[j] = buffer.readu32(v1, 0)
            end
        end

        v92[i] = v94
    end

    physical.skeleton.anim_to_world_11920 = v92

    local reckoning = physical.reckoning
    local com_velocity = p27.animated_skeleton.board_frames.com_velocity
    local v100 = table.create(#com_velocity)

    for i = 1, #com_velocity do
        local v101 = com_velocity[i]

        if v101 ~= 0 and v101 > -1.1754943508222875E-38 and v101 < 1.1754943508222875E-38 then
            local v102 = math.abs(v101) * 7.1362384635298E+44
            local v103 = math.floor(v102)
            local v104 = v102 - v103
            local v105 = if v104 > 0.5 or v104 == 0.5 and v103 % 2 == 1 then v103 + 1 else v103

            if v101 < 0 then
                v100[i] = v105 + 2147483648
            else
                v100[i] = v105
            end
        else
            buffer.writef32(v1, 0, v101)
            v100[i] = buffer.readu32(v1, 0)
        end
    end

    reckoning.vector_16 = v100

    local reckoning2 = physical.reckoning
    local centre_of_mass = p27.animated_skeleton.board_frames.centre_of_mass
    local v106 = table.create(#centre_of_mass)

    for i = 1, #centre_of_mass do
        local v107 = centre_of_mass[i]

        if v107 ~= 0 and v107 > -1.1754943508222875E-38 and v107 < 1.1754943508222875E-38 then
            local v108 = math.abs(v107) * 7.1362384635298E+44
            local v109 = math.floor(v108)
            local v110 = v108 - v109
            local v111 = if v110 > 0.5 or v110 == 0.5 and v109 % 2 == 1 then v109 + 1 else v109

            if v107 < 0 then
                v106[i] = v111 + 2147483648
            else
                v106[i] = v111
            end
        else
            buffer.writef32(v1, 0, v107)
            v106[i] = buffer.readu32(v1, 0)
        end
    end

    reckoning2.vector_64 = v106

    local up = p26.riding.reckoning.up
    local reckoning3 = physical.reckoning
    local x = up.x
    local v112

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v113 = math.abs(x) * 7.1362384635298E+44
        local v114 = math.floor(v113)
        local v115 = v113 - v114

        v112 = if v115 > 0.5 or v115 == 0.5 and v114 % 2 == 1 then v114 + 1 else v114

        if x < 0 then
            v112 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v112 = buffer.readu32(v1, 0)
    end

    local y = up.y
    local v116

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v117 = math.abs(y) * 7.1362384635298E+44
        local v118 = math.floor(v117)
        local v119 = v117 - v118

        v116 = if v119 > 0.5 or v119 == 0.5 and v118 % 2 == 1 then v118 + 1 else v118

        if y < 0 then
            v116 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v116 = buffer.readu32(v1, 0)
    end

    local z = up.z
    local v120

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v121 = math.abs(z) * 7.1362384635298E+44
        local v122 = math.floor(v121)
        local v123 = v121 - v122

        v120 = if v123 > 0.5 or v123 == 0.5 and v122 % 2 == 1 then v122 + 1 else v122

        if z < 0 then
            v120 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v120 = buffer.readu32(v1, 0)
    end

    buffer.writef32(v1, 0, 0)
    reckoning3.vector_96 = {
        v112,
        v116,
        v120,
        (buffer.readu32(v1, 0))
    }

    local pose = p27.animation.pose
    local v125 = #pose
    local v126 = v10
    local v127 = v11

    if v126 == nil or #v126 ~= v125 then
        v126 = new_matrices(v125)
        v127 = new_matrices(v125)
        v10 = v126
        v11 = v127
    end

    import("skate_game/animation_pose").PoseEvaluator.check_hierarchy(p27.animation.evaluator, pose)

    for i = 1, v125 do
        t2[i] = false
    end

    for _, v128 in ipairs(p27.skeleton_output.pose.bone_indices) do
        t2[v128 + 1] = true
    end

    local v129 = table.create(v125)
    local sqt_to_matrix_into = v9.sqt_to_matrix_into

    for i = 1, v125 do
        if t2[i] then
            v129[i] = v127[i]
        else
            v129[i] = sqt_to_matrix_into(v127[i], pose[i])
        end
    end

    import("skate_game/physics/skeleton_output").SkeletonOutput.publish_owned(p27.skeleton_output, p27.animated_skeleton, p27.skeleton, p26.board, p26.settings.step.base_truck_transforms, p27.ground.steering.targets, p28, v126, v129)

    local compose_hierarchy_in_place = v8.compose_hierarchy_in_place
    local v130 = #v129
    local parents = p27.animation.evaluator.frames.parents
    local ok, result = pcall(compose_hierarchy_in_place, v130, parents, 0, v129)

    if not ok then
        error(string.format("Physical render hierarchy: %s", (debug_fmt(result))), 0)
    end

    for i = 1, v125 do
        local v131 = v129[i]

        if v131 == v127[i] then
            local v132 = v131[1]
            local v133 = v131[2]
            local v134 = v131[3]
            local v135 = v131[4]

            v129[i] = {
                {
                    v132[1],
                    v132[2],
                    v132[3],
                    v132[4]
                },
                {
                    v133[1],
                    v133[2],
                    v133[3],
                    v133[4]
                },
                {
                    v134[1],
                    v134[2],
                    v134[3],
                    v134[4]
                },
                {
                    v135[1],
                    v135[2],
                    v135[3],
                    v135[4]
                }
            }
        end
    end

    p27.render_pose = v129
    p27.pose_generation += 1
end

function t1.publish_reference(p29, p30, p31) -- line: 539
    -- upvalues: rt (copy), v1 (copy), import (copy), v8 (copy), CorrectionState (copy), debug_fmt (copy)
    local v136 = import("skate_game/physics/solve").deck_frame(p29.board)
    local processed = p30.player_input.processed
    local v137 = import("skate_game/physics/wipeout").Wipeout.requests_wipeout(p30.wipeout, processed)
    local apply = CorrectionState.apply
    local correction = p30.skeleton_output.correction
    local skeleton = p30.skeleton
    local v138 = processed.vectors_544_560_592_608[1]
    local v139 = table.create(#v138)

    for i = 1, #v138 do
        buffer.writeu32(v1, 0, v138[i])
        v139[i] = buffer.readf32(v1, 0)
    end

    apply(correction, skeleton, v139, v137, processed.flags_2468, processed.flags_2476)

    local v141 = import("skate_game/physics/skeleton_output").SkeletonOutput.advance_wobble(p30.skeleton_output, p30.skeleton, v136)

    import("skate_game/physics/foot_ik").FootIk.post_physics(p30.foot_ik, p30.skeleton, {
        state_id = processed.state_2508,
        category_id = processed.category_2512,
        board_body_flag_868 = p29.riding.ground.part_contact_count ~= 0,
        wipeout = v137,
        flags_2468 = processed.flags_2468,
        flags_2484 = processed.flags_2484,
        value_2664 = processed.state_timer_2664,
        state_2520 = processed.player_state_value_2520,
        world_to_animation = p30.animated_skeleton.roots.world_to_animation,
        board = v141
    })

    local v142 = import("skate_game/physics/foot_physical_output").FootPhysicalOutputs.publish(p30.foot_physical, p30.skeleton.record, p29.settings.step.simulation.time_step)
    local physical = p30.player_input.physical

    physical.skeleton.flag_597 = p30.foot_ik.state.contacts.support_failed and 1 or 0
    physical.skeleton.flag_600 = v142.within_deck_box[1] and 1 or 0
    physical.skeleton.flag_601 = v142.within_deck_box[2] and 1 or 0

    local animation_to_world = p30.animated_skeleton.roots.animation_to_world
    local v143 = table.create(#animation_to_world)

    for i = 1, #animation_to_world do
        local v144 = animation_to_world[i]
        local v145 = table.create(#v144)

        for j = 1, #v144 do
            local v146 = v144[j]

            if v146 ~= 0 and v146 > -1.1754943508222875E-38 and v146 < 1.1754943508222875E-38 then
                local v147 = math.abs(v146) * 7.1362384635298E+44
                local v148 = math.floor(v147)
                local v149 = v147 - v148
                local v150 = if v149 > 0.5 or v149 == 0.5 and v148 % 2 == 1 then v148 + 1 else v148

                if v146 < 0 then
                    v145[j] = v150 + 2147483648
                else
                    v145[j] = v150
                end
            else
                buffer.writef32(v1, 0, v146)
                v145[j] = buffer.readu32(v1, 0)
            end
        end

        v143[i] = v145
    end

    physical.skeleton.anim_to_world_11920 = v143

    local reckoning = physical.reckoning
    local com_velocity = p30.animated_skeleton.board_frames.com_velocity
    local v151 = table.create(#com_velocity)

    for i = 1, #com_velocity do
        local v152 = com_velocity[i]

        if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
            local v153 = math.abs(v152) * 7.1362384635298E+44
            local v154 = math.floor(v153)
            local v155 = v153 - v154
            local v156 = if v155 > 0.5 or v155 == 0.5 and v154 % 2 == 1 then v154 + 1 else v154

            if v152 < 0 then
                v151[i] = v156 + 2147483648
            else
                v151[i] = v156
            end
        else
            buffer.writef32(v1, 0, v152)
            v151[i] = buffer.readu32(v1, 0)
        end
    end

    reckoning.vector_16 = v151

    local reckoning2 = physical.reckoning
    local centre_of_mass = p30.animated_skeleton.board_frames.centre_of_mass
    local v157 = table.create(#centre_of_mass)

    for i = 1, #centre_of_mass do
        local v158 = centre_of_mass[i]

        if v158 ~= 0 and v158 > -1.1754943508222875E-38 and v158 < 1.1754943508222875E-38 then
            local v159 = math.abs(v158) * 7.1362384635298E+44
            local v160 = math.floor(v159)
            local v161 = v159 - v160
            local v162 = if v161 > 0.5 or v161 == 0.5 and v160 % 2 == 1 then v160 + 1 else v160

            if v158 < 0 then
                v157[i] = v162 + 2147483648
            else
                v157[i] = v162
            end
        else
            buffer.writef32(v1, 0, v158)
            v157[i] = buffer.readu32(v1, 0)
        end
    end

    reckoning2.vector_64 = v157

    local up = p29.riding.reckoning.up
    local reckoning3 = physical.reckoning
    local t15 = {
        up.x,
        up.y,
        up.z,
        0
    }
    local v163 = table.create(#t15)

    for i = 1, #t15 do
        local v164 = t15[i]

        if v164 ~= 0 and v164 > -1.1754943508222875E-38 and v164 < 1.1754943508222875E-38 then
            local v165 = math.abs(v164) * 7.1362384635298E+44
            local v166 = math.floor(v165)
            local v167 = v165 - v166
            local v168 = if v167 > 0.5 or v167 == 0.5 and v166 % 2 == 1 then v166 + 1 else v166

            if v164 < 0 then
                v163[i] = v168 + 2147483648
            else
                v163[i] = v168
            end
        else
            buffer.writef32(v1, 0, v164)
            v163[i] = buffer.readu32(v1, 0)
        end
    end

    reckoning3.vector_96 = v163

    local v169 = import("skate_game/animation_pose").PoseEvaluator.hierarchy(p30.animation.evaluator, p30.animation.pose)
    local v170 = table.create(#p30.animation.pose)

    for v171, v172 in p30.animation.pose do
        v170[v171] = v8.sqt_to_matrix(rt.copy(v172))
    end

    import("skate_game/physics/skeleton_output").SkeletonOutput.publish(p30.skeleton_output, p30.animated_skeleton, p30.skeleton, p29.board, rt.copy(p29.settings.step.base_truck_transforms), rt.copy(p30.ground.steering.targets), p31, v169, v170)

    local compose_hierarchy_in_place = v8.compose_hierarchy_in_place
    local v173 = #v170
    local parents = p30.animation.evaluator.frames.parents
    local ok, result = pcall(compose_hierarchy_in_place, v173, parents, 0, v170)

    if not ok then
        error(string.format("Physical render hierarchy: %s", (debug_fmt(result))), 0)
    end

    p30.render_pose = v170
    p30.pose_generation += 1
end

return t1
