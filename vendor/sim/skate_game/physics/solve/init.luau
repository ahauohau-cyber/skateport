-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/solve/assembly_contacts")
local v2 = import("skate_game/physics/solve/diagnostics")
local v3 = import("skate_game/physics/skeleton_colliders")
local v4 = import("skate_game/physics/solid_contacts")
local v5 = import("skate_core/physics/board")
local v6 = import("skate_core/physics/board_step")
local v7 = import("skate_core/physics/board_runtime")
local v8 = import("skate_core/physics/board_world")
local v9 = import("skate_core/physics/collision/fixup")
local v10 = import("skate_core/physics/skeleton_animation_record")
local v11 = import("skate_core/physics/skeleton_body")
local BodyId = v5.BodyId
local ATTACHED_REACTION_BASE = v6.ATTACHED_REACTION_BASE
local BoardRuntime = v7.BoardRuntime
local BoardWorld = v8.BoardWorld
local IDENTITY = v10.IDENTITY
local PART_COUNT, SkeletonBody, SkeletonDrives, SkeletonJoints = v11.PART_COUNT, v11.SkeletonBody, v11.SkeletonDrives, v11.SkeletonJoints

local function colliders() -- line: 34
    -- upvalues: import (copy)
    return import("skate_game/physics/colliders")
end

local function network() -- line: 37
    -- upvalues: import (copy)
    return import("skate_game/physics/network")
end

local function player_physics() -- line: 40
    -- upvalues: import (copy)
    return import("skate_game/modding/player_physics")
end

local function board_manager() -- line: 43
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager")
end

local function board_manager_runtime() -- line: 46
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager/runtime")
end

local v12, v13, v14
local v15 = table.freeze({})
local t1 = {}

function t1.set_rider(p1) -- line: 65
    -- upvalues: import (copy), v13 (ref), v14 (ref)
    local v16 = v14

    if type(p1) == "table" then
        local v17 = import("skate_game/physics/solve/kinematic")

        v17.configure(p1)
        v14 = table.clone(p1)
        v13 = v17
    else
        if v13 ~= nil then
            v13.release()
        end

        v14 = nil
        v13 = nil
    end

    return v16
end

function t1.rider() -- line: 81
    -- upvalues: v14 (ref)
    return v14
end

function t1.rider_asleep() -- line: 86
    -- upvalues: v13 (ref)
    return v13 ~= nil and (v13.is_asleep())
end

function t1.set_resolve_mode(p2) -- line: 91
    -- upvalues: v12 (ref)
    local v18 = v12

    v12 = p2

    return v18
end

local function debug_fmt(p3) -- line: 98
    -- upvalues: debug_fmt (copy)
    if type(p3) ~= "table" then
        return (tostring(p3))
    end

    local t2 = {}

    if #p3 > 0 then
        for _, v19 in ipairs(p3) do
            table.insert(t2, debug_fmt(v19))
        end

        return "[" .. table.concat(t2, ", ") .. "]"
    end

    local t3 = {}

    for v20 in p3 do
        table.insert(t3, (tostring(v20)))
    end

    table.sort(t3)

    for _, v22 in ipairs(t3) do
        local v23 = p3[v22]

        if v23 == nil then
            v23 = p3[tonumber(v22)]
        end

        table.insert(t2, v22 .. ": " .. debug_fmt(v23))
    end

    return "{ " .. table.concat(t2, ", ") .. " }"
end

local t4 = {}
local t5 = {}
local t6 = {}
local t7 = {}

local function glam_distance_squared(p4, p5) -- line: 128
    local v25 = (p4.x or p4[1]) - (p5.x or p5[1])
    local v26 = (p4.y or p4[2]) - (p5.y or p5[2])
    local v27 = (p4.z or p4[3]) - (p5.z or p5[3])

    return v25 * v25 + v26 * v26 + v27 * v27
end

local t8 = {}
local v28 = table.create(2)
local v29 = table.freeze({
    ATTACHED_REACTION_BASE + 3,
    ATTACHED_REACTION_BASE + 7
})
local v30

function t1.skeleton_query_of(p6) -- line: 147
    -- upvalues: t8 (copy)
    table.clear(t8)

    for v31, v32 in p6 do
        if type(v32) == "table" then
            return nil
        end

        t8[v31] = v32
    end

    t8.edge_cos_bend_normal_threshold = -1

    return t8
end

function t1.advance(p7, p8, p9) -- line: 163
    -- upvalues: import (copy), t1 (copy)
    if next(p8.mod_part_overrides) ~= nil then
        local v33 = import("skate_game/modding/player_physics").apply_parts(p8)
        local advance_inner = t1.advance_inner
        local ok, result = pcall(advance_inner, p7, p8, p9)

        import("skate_game/modding/player_physics").PartRestore.restore(v33, p8)

        if not ok then
            error(result, 0)
        end
    else
        t1.advance_inner(p7, p8, p9)
    end
end

function t1.advance_inner(p10, p11, p12) -- line: 182
    -- upvalues: rt (copy), import (copy), v1 (copy), v2 (copy), v3 (copy), v4 (copy), v9 (copy), BodyId (copy), ATTACHED_REACTION_BASE (copy), BoardRuntime (copy), BoardWorld (copy), PART_COUNT (copy), SkeletonBody (copy), SkeletonDrives (copy), SkeletonJoints (copy), v12 (ref), t1 (copy), v13 (ref), v15 (copy), debug_fmt (copy), t4 (copy), t5 (copy), t6 (copy), t7 (copy), t8 (copy), v28 (copy), v29 (copy), v30 (ref)
    local v34 = import("skate_game/modding/player_physics").before_solve_rates_scratch(p10, p11)
    local v35

    if not v2.capture(p10, p11) then
        v35 = v2.snapshot_scratch(p10, p11)

        local validate = v2.validate
        local ok, result = pcall(validate, v35, "before shared solve")

        if not ok then
            error(string.format("%s; com_frame=%s; lifted_com_frame=%s; animation_root=%s; biped_position=%s; biped_surface=%s", tostring(result), debug_fmt(p11.animated_skeleton.board_frames.com_frame), debug_fmt(p11.animated_skeleton.board_frames.lifted_com_frame), debug_fmt(p11.animated_skeleton.roots.animation_to_world), debug_fmt(p11.biped_ground.controller.state.position_368), (debug_fmt(p11.biped_ground.controller.state.surface))), 0)
        end
    end

    local v36 = import("skate_game/physics/colliders").world_volumes_pooled(p10.board, p10.settings)
    local LiveState = import("skate_game/physics/offboard/board_manager/runtime").LiveState
    local v37 = #v36
    local n1 = 0

    for i = 1, v37 do
        local v38 = v36[i]

        if LiveState.volume_enabled(p11.board_possession_live, v38.body) then
            n1 += 1
            v36[n1] = v38
        end
    end

    for i = v37, n1 + 1, -1 do
        v36[i] = nil
    end

    local v39

    if v13 ~= nil then
        local network_proxies = p10.network_proxies

        if import("skate_game/physics/network").Proxies.deferred(network_proxies) == 0 and #network_proxies.volumes == 0 and #network_proxies.solids == 0 and #network_proxies.bodies == 0 then
            v39 = v13.begin(p10, p11)
        else
            v39 = 0
            v13.blocked(p10)
        end
    else
        v39 = 0
    end

    local v40 = if v39 == 1 then v15 else v3.enabled_volumes_pooled(p11.skeleton, p11.skeleton_collision)

    v9.in_rider_query = false

    local v41 = BoardWorld.query_primitives(p10.world, v36, p10.query, p10.retention, 1)
    local v42 = table.clone(v41)
    local query = p10.query

    table.clear(t8)

    local v43 = false
    local v44

    for v45, v46 in query do
        if type(v46) == "table" then
            v44 = nil
            v43 = true
            break
        end

        t8[v45] = v46
    end

    if not v43 then
        t8.edge_cos_bend_normal_threshold = -1
        v44 = t8
    end

    if v44 == nil then
        v44 = rt.copy(p10.query)
        v44.edge_cos_bend_normal_threshold = -1
    end

    local v47 = table.clone(v40)

    v3.retain_world_volumes(v47, p11.skeleton_collision)

    if v39 == 0 then
        v9.in_rider_query = true

        local v48 = BoardWorld.query_primitives(p10.world, v47, v44, p10.retention, 2)

        v9.in_rider_query = false

        for _, v49 in ipairs(v48) do
            table.insert(v42, v49)
        end

        if v13 ~= nil then
            v13.observe(v48, p10)
        end
    elseif v39 == 2 then
        v9.in_rider_query = true

        local v50 = BoardWorld.query_primitives(p10.world, v47, v44, p10.retention, 2)

        v9.in_rider_query = false
        v13.probe(v50, p10)
    end

    local v51, v52

    if v39 == 0 then
        v51 = v40
    else
        v52 = if v39 == 3 and v13.asleep_pairs() then v40 else nil
        v51 = {}
    end

    v1.append_pooled(v42, v36, v51, BoardRuntime.collision_group(p10.board), p11.skeleton_collision)

    if v52 ~= nil then
        v13.asleep_board_pairs(v42, v36, v52, BoardRuntime.collision_group(p10.board), p11.skeleton_collision)
    end

    local v53 = #v42

    if import("skate_game/physics/network").Proxies.deferred(p10.network_proxies) > 0 then
        if import("skate_game/physics/network").Proxies.resolve(p10.network_proxies, v42, v36, v51, p10, p11, v12) then
            v34 = import("skate_game/modding/player_physics").before_solve_rates_scratch(p10, p11)
        end
    elseif #p10.network_proxies.volumes > 0 then
        local volumes = p10.network_proxies.volumes
        local v54 = #volumes
        local bounds = import("skate_game/physics/network").bounds

        for i = 1, v54 do
            local v55, v56 = bounds(volumes[i].primitive)
            local x, y, z = v55.x, v55.y, v55.z

            t4[i] = x
            t5[i] = y
            t6[i] = z
            t7[i] = v56
        end

        for i = 1, 2 do
            local _ipairs = ipairs
            local v57 = if i == 1 then v36 else v51

            for _, v58 in _ipairs(v57) do
                local v59, v60 = bounds(v58.primitive)
                local x, y, z = v59.x, v59.y, v59.z

                for j = 1, v54 do
                    local v61 = x - t4[j]
                    local v62 = y - t5[j]
                    local v63 = z - t6[j]

                    if v61 * v61 + v62 * v62 + v63 * v63 <= (v60 + t7[j] + 0.05) ^ 2 then
                        v1.append_pair_pooled(v42, v58, volumes[j])
                    end
                end
            end
        end
    end

    v4.append(v42, v36, p10.network_proxies.solids, p10, p11)
    v4.append(v42, v51, p10.network_proxies.solids, p10, p11)
    p10.network_contacts = #v42 - v53
    p10.contact_count = #v42

    local time_step = p10.settings.step.simulation.time_step
    local v64, v65

    if v39 == 0 then
        v64 = SkeletonJoints.build(import("skate_game/modding/player_physics").joints_view(p11), SkeletonBody.bodies(p11.skeleton), ATTACHED_REACTION_BASE, time_step)
        import("skate_game/modding/player_physics").filter_joints(p11, v64)
        v65 = SkeletonDrives.build(p11.skeleton_drives, SkeletonBody.bodies(p11.skeleton), ATTACHED_REACTION_BASE, ATTACHED_REACTION_BASE + PART_COUNT, time_step)
        import("skate_game/modding/player_physics").filter_drives(p11, v65)
    else
        v64, v65 = v13.empty_rows()
    end

    local v66 = #v65.rows
    local v67 = SkeletonBody.bodies(p11.skeleton)
    local v68 = v67[4]
    local v69 = v67[8]

    v28[1] = v68
    v28[2] = v69
    import("skate_game/physics/offboard/board_manager").Owner.append_drives(p11.board_possession, BoardRuntime.bodies(p10.board)[BodyId.index(BodyId.Deck) + 1], v28, BodyId.index(BodyId.Deck), v29, time_step, v65.rows)
    v28[1] = nil
    v28[2] = nil
    import("skate_game/modding/player_physics").filter_possession(p11, v65.rows, v66)

    local t9 = {}

    for _, v70 in ipairs(SkeletonBody.bodies_mut(p11.skeleton)) do
        table.insert(t9, v70)
    end

    for _, v71 in ipairs(p11.skeleton_drives.targets.bodies) do
        table.insert(t9, v71)
    end

    for _, v72 in ipairs(p10.network_proxies.bodies) do
        table.insert(t9, v72)
    end

    local v73 = v13 ~= nil and v39 == 0 and v13.soft_begin(p11)

    BoardRuntime.advance_attached(p10.board, v42, p12, p10.settings.step, {
        bodies = t9,
        contacts = {},
        joints = v64,
        drives = v65.rows
    })

    if v39 == 3 then
        v13.asleep_end(p11, p10)
    elseif v39 ~= 0 then
        v13.place(p11, time_step)
    end

    if v73 then
        v13.soft_end(p11)
    end

    local joint_loads = p11.mod_contact_frame.joint_loads

    p11.mod_contact_frame = import("skate_game/modding/player_physics").after_solve(p10, p11, v34)
    p11.mod_contact_frame.joint_loads = import("skate_game/modding/player_physics").joint_loads_into(joint_loads, p11, v64, time_step)
    import("skate_game/physics/network").Proxies.capture_dynamics_reactions(p10.network_proxies, BoardRuntime.solved_reactions(p10.board), time_step)

    local ok, result

    if v2.live_finite(p10, p11) then
        ok = true
    else
        local validate = v2.validate
        local v74 = v2.snapshot_refs(p10, p11)

        ok, result = pcall(validate, v74, "after shared solve")
    end

    if not ok then
        local v75 = if v35 == nil then v2.captured_bodies() else v35

        error(string.format("%s; input_bodies=%s; contacts=%s; joints=%s; drives=%s", tostring(result), debug_fmt(v75), debug_fmt(v42), debug_fmt(v64), (debug_fmt(v65.rows))), 0)
    end

    v30 = t1.deck_frame_into(p10.board, v30)
    SkeletonBody.publish_physical_record(p11.skeleton, v30)

    for i = #v65.rows, v66 + 1, -1 do
        v65.rows[i] = nil
    end

    p11.solved_drives = v65
end

function t1.deck_frame_reference(p13) -- line: 556
    -- upvalues: rt (copy), BodyId (copy), BoardRuntime (copy), IDENTITY (copy)
    local v76 = BoardRuntime.part_transforms(p13)[BodyId.index(BodyId.Deck) + 1]
    local v77 = rt.copy(IDENTITY)

    for i = 0, #v76.basis.columns - 1 do
        local v78 = v76.basis.columns[i + 1]

        v77[i + 1][1] = v78[1]
        v77[i + 1][2] = v78[2]
        v77[i + 1][3] = v78[3]
    end

    v77[4] = {
        v76.translation.x,
        v76.translation.y,
        v76.translation.z,
        0
    }

    return v77
end

local from_bits, to_bits = rt.from_bits, rt.to_bits

local function f32r(p14) -- line: 577
    -- upvalues: from_bits (copy), to_bits (copy)
    return from_bits(to_bits(p14))
end

local v79 = BodyId.index(BodyId.Deck) + 1

function t1.deck_frame_w2(p15) -- line: 593
    -- upvalues: IDENTITY (copy), t1 (copy), from_bits (copy), to_bits (copy), v79 (copy)
    local rates = p15.bodies[v79].rates
    local v80 = p15.mass_frames[v79]
    local columns = rates.basis.columns
    local columns2 = v80.basis.columns

    if #columns ~= 3 or #columns2 ~= 3 or #IDENTITY ~= 4 then
        return t1.deck_frame_reference(p15)
    end

    local v81 = columns[1]
    local v82 = columns[2]
    local v83 = columns[3]
    local v85 = from_bits(to_bits(v81[1]))
    local v87 = from_bits(to_bits(v81[2]))
    local v89 = from_bits(to_bits(v81[3]))
    local v91 = from_bits(to_bits(v82[1]))
    local v93 = from_bits(to_bits(v82[2]))
    local v95 = from_bits(to_bits(v82[3]))
    local v97 = from_bits(to_bits(v83[1]))
    local v99 = from_bits(to_bits(v83[2]))
    local v101 = from_bits(to_bits(v83[3]))
    local position = rates.position
    local v102 = from_bits(to_bits(position.x))
    local v103 = from_bits(to_bits(position.y))
    local v104 = from_bits(to_bits(position.z))
    local v105 = table.create(4)

    for i = 1, 3 do
        local v106 = columns2[i]
        local v108 = from_bits(to_bits(v106[1]))
        local v110 = from_bits(to_bits(v106[2]))
        local v112 = from_bits(to_bits(v106[3]))
        local v113 = table.clone(IDENTITY[i])

        v113[1] = from_bits(to_bits(v112 * v97 + (v110 * v91 + v108 * v85)))
        v113[2] = from_bits(to_bits(v112 * v99 + (v110 * v93 + v108 * v87)))
        v113[3] = from_bits(to_bits(v112 * v101 + (v110 * v95 + v108 * v89)))
        v105[i] = v113
    end

    local translation = v80.translation
    local v117 = from_bits(to_bits(translation.x))
    local v118 = from_bits(to_bits(translation.y))
    local v119 = from_bits(to_bits(translation.z))

    v105[4] = {
        from_bits(to_bits(v119 * v97 + (v118 * v91 + (v117 * v85 + v102)))),
        from_bits(to_bits(v119 * v99 + (v118 * v93 + (v117 * v87 + v103)))),
        from_bits(to_bits(v119 * v101 + (v118 * v95 + (v117 * v89 + v104)))),
        0
    }

    return v105
end

local create = vector.create

local function tiny(p16) -- line: 639
    -- upvalues: from_bits (copy), to_bits (copy)
    return from_bits(to_bits(p16))
end

local function f32r3(p17, p18, p19) -- line: 643
    -- upvalues: from_bits (copy), to_bits (copy), create (copy)
    local v125 = create(p17, p18, p19)
    local x, y, z = v125.x, v125.y, v125.z

    if p17 < 1.1754943508222875E-38 and p17 > -1.1754943508222875E-38 and p17 ~= 0 then
        x = from_bits(to_bits(p17))
    end

    if p18 < 1.1754943508222875E-38 and p18 > -1.1754943508222875E-38 and p18 ~= 0 then
        y = from_bits(to_bits(p18))
    end

    if p19 < 1.1754943508222875E-38 and p19 > -1.1754943508222875E-38 and p19 ~= 0 then
        z = from_bits(to_bits(p19))
    end

    return x, y, z
end

local function deck_frame_numbers(p20, p21, p22, p23) -- line: 660
    -- upvalues: f32r3 (copy)
    local v126 = p20[1]
    local v127 = p20[2]
    local v128 = p20[3]
    local v129, v130, v131 = f32r3(v126[1], v126[2], v126[3])
    local v132, v133, v134 = f32r3(v127[1], v127[2], v127[3])
    local v135, v136, v137 = f32r3(v128[1], v128[2], v128[3])
    local v138, v139, v140 = f32r3(p22.x, p22.y, p22.z)
    local v141 = p21[1]
    local v142, v143, v144 = f32r3(v141[1], v141[2], v141[3])
    local v145, v146, v147 = f32r3(v144 * v135 + (v143 * v132 + v142 * v129), v144 * v136 + (v143 * v133 + v142 * v130), v144 * v137 + (v143 * v134 + v142 * v131))
    local v148 = p21[2]
    local v149, v150, v151 = f32r3(v148[1], v148[2], v148[3])
    local v152, v153, v154 = f32r3(v151 * v135 + (v150 * v132 + v149 * v129), v151 * v136 + (v150 * v133 + v149 * v130), v151 * v137 + (v150 * v134 + v149 * v131))
    local v155 = p21[3]
    local v156, v157, v158 = f32r3(v155[1], v155[2], v155[3])
    local v159, v160, v161 = f32r3(v158 * v135 + (v157 * v132 + v156 * v129), v158 * v136 + (v157 * v133 + v156 * v130), v158 * v137 + (v157 * v134 + v156 * v131))
    local v162, v163, v164 = f32r3(p23.x, p23.y, p23.z)
    local v165, v166, v167 = f32r3(v164 * v135 + (v163 * v132 + (v162 * v129 + v138)), v164 * v136 + (v163 * v133 + (v162 * v130 + v139)), v164 * v137 + (v163 * v134 + (v162 * v131 + v140)))

    return v145, v146, v147, v152, v153, v154, v159, v160, v161, v165, v166, v167
end

function t1.deck_frame(p24) -- line: 689
    -- upvalues: IDENTITY (copy), t1 (copy), v79 (copy), deck_frame_numbers (copy)
    local rates = p24.bodies[v79].rates
    local v168 = p24.mass_frames[v79]
    local columns = rates.basis.columns
    local columns2 = v168.basis.columns

    if #columns ~= 3 or #columns2 ~= 3 or #IDENTITY ~= 4 then
        return t1.deck_frame_reference(p24)
    end

    local v169, v170, v171, v172, v173, v174, v175, v176, v177, v178, v179, v180 = deck_frame_numbers(columns, columns2, rates.position, v168.translation)
    local v181 = table.clone(IDENTITY[1])

    v181[1] = v169
    v181[2] = v170
    v181[3] = v171

    local v182 = table.clone(IDENTITY[2])

    v182[1] = v172
    v182[2] = v173
    v182[3] = v174

    local v183 = table.clone(IDENTITY[3])

    v183[1] = v175
    v183[2] = v176
    v183[3] = v177

    return {
        v181,
        v182,
        v183,
        { v178, v179, v180, 0 }
    }
end

function t1.deck_frame_into(p25, p26) -- line: 716
    -- upvalues: IDENTITY (copy), t1 (copy), v79 (copy), deck_frame_numbers (copy)
    if p26 == nil or #p26 ~= 4 then
        return t1.deck_frame(p25)
    end

    local rates = p25.bodies[v79].rates
    local v184 = p25.mass_frames[v79]
    local columns = rates.basis.columns
    local columns2 = v184.basis.columns
    local v185 = p26[1]
    local v186 = p26[2]
    local v187 = p26[3]
    local v188 = p26[4]
    local v189 = IDENTITY[1]
    local v190 = IDENTITY[2]
    local v191 = IDENTITY[3]

    if #columns ~= 3
        or #columns2 ~= 3
        or #IDENTITY ~= 4
        or #v189 ~= 4
        or #v190 ~= 4
        or #v191 ~= 4
        or type(v185) ~= "table"
        or type(v186) ~= "table"
        or type(v187) ~= "table"
        or type(v188) ~= "table"
        or #v185 ~= 4
        or #v186 ~= 4
        or #v187 ~= 4
        or #v188 ~= 4 then
        return t1.deck_frame(p25)
    end

    local v192, v193, v194, v195, v196, v197, v198, v199, v200, v201, v202, v203 = deck_frame_numbers(columns, columns2, rates.position, v184.translation)
    local v204 = v189[4]

    v185[1] = v192
    v185[2] = v193
    v185[3] = v194
    v185[4] = v204

    local v205 = v190[4]

    v186[1] = v195
    v186[2] = v196
    v186[3] = v197
    v186[4] = v205

    local v206 = v191[4]

    v187[1] = v198
    v187[2] = v199
    v187[3] = v200
    v187[4] = v206
    v188[1] = v201
    v188[2] = v202
    v188[3] = v203
    v188[4] = 0

    return p26
end

return t1
