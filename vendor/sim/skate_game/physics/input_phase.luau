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
local v8 = import("skate_game/physics/input_teleport")

local function player_input() -- line: 37
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input")
end

local function player_input_grind() -- line: 40
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input/grind")
end

local function grind_host() -- line: 43
    -- upvalues: import (copy)
    return import("skate_game/physics/grind_host")
end

local function skeleton_input_runtime() -- line: 46
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

local function skeleton_air() -- line: 49
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_air")
end

local function animation_input() -- line: 52
    -- upvalues: import (copy)
    return import("skate_game/physics/animation_input")
end

local function solve() -- line: 55
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local function board_manager_runtime() -- line: 58
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager/runtime")
end

local function air_selector() -- line: 61
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/air_selector")
end

local function contact_toolkit() -- line: 64
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/contact_toolkit")
end

local function trajectory() -- line: 67
    -- upvalues: import (copy)
    return import("skate_core/air/trajectory")
end

local function packet_attributes() -- line: 70
    -- upvalues: import (copy)
    return import("skate_core/animation/output/attributes")
end

local t1 = {
    facing_from_visual = v8.facing_from_visual,
    transition_action = function(p4) -- transition_action | line: 88
        return p4.value(p4, 65)
    end
}

local function from_bits4(p5) -- line: 92
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p5[1])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5[2])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5[3])

    local v14 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5[4])

    return {
        v10,
        v12,
        v14,
        (buffer.readf32(v1, 0))
    }
end

local function to_bits4(p6) -- line: 95
    -- upvalues: v1 (copy)
    local v16 = p6[1]
    local v17

    if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
        local v18 = math.abs(v16) * 7.1362384635298E+44
        local v19 = math.floor(v18)
        local v20 = v18 - v19

        v17 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

        if v16 < 0 then
            v17 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v16)
        v17 = buffer.readu32(v1, 0)
    end

    local v21 = p6[2]
    local v22

    if v21 ~= 0 and v21 > -1.1754943508222875E-38 and v21 < 1.1754943508222875E-38 then
        local v23 = math.abs(v21) * 7.1362384635298E+44
        local v24 = math.floor(v23)
        local v25 = v23 - v24

        v22 = if v25 > 0.5 or v25 == 0.5 and v24 % 2 == 1 then v24 + 1 else v24

        if v21 < 0 then
            v22 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v21)
        v22 = buffer.readu32(v1, 0)
    end

    local v26 = p6[3]
    local v27

    if v26 ~= 0 and v26 > -1.1754943508222875E-38 and v26 < 1.1754943508222875E-38 then
        local v28 = math.abs(v26) * 7.1362384635298E+44
        local v29 = math.floor(v28)
        local v30 = v28 - v29

        v27 = if v30 > 0.5 or v30 == 0.5 and v29 % 2 == 1 then v29 + 1 else v29

        if v26 < 0 then
            v27 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v26)
        v27 = buffer.readu32(v1, 0)
    end

    local v31 = p6[4]
    local v32

    if v31 ~= 0 and v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
        local v33 = math.abs(v31) * 7.1362384635298E+44
        local v34 = math.floor(v33)
        local v35 = v33 - v34

        v32 = if v35 > 0.5 or v35 == 0.5 and v34 % 2 == 1 then v34 + 1 else v34

        if v31 < 0 then
            v32 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v31)
        v32 = buffer.readu32(v1, 0)
    end

    return {
        v17,
        v22,
        v27,
        v32
    }
end

local v36 = false

function t1.set_reference(p7) -- line: 101
    -- upvalues: v36 (ref)
    v36 = p7
end

local assign_into = import("skate_core/player/input_phase").assign_into
local copy_into = import("skate_core/player/input_phase/publication").copy_into
local t3 = {
    0, 0, 0, 0
}
local v37 = table.freeze({
    tag = "ThroughTeleport"
})

local function run_stages(p8, p9, p10, p11, p12, p13, p14) -- line: 118
    -- upvalues: v37 (copy)
    local v38 = p8.process_stage(p10.player_input, p9.board, p10.ground_runtime, p11, p12, p13, p14, v37, p9.world, p9.grind_world)

    if v38 ~= nil then
        p8.process_stage(p10.player_input, p9.board, p10.ground_runtime, p11, p12, p13, p14, {
            tag = "AfterTeleport",
            v38
        }, p9.world, p9.grind_world)
    end
end

local t4 = {
    "skeleton_input",
    "animated",
    "skeleton_air",
    "footplant",
    "handplant",
    "body",
    "drives",
    "ik",
    "animation_input",
    "output",
    "pose_errors",
    "collision_mode",
    "feedback",
    "collision",
    "ground",
    "life",
    "offboard_grab",
    "wipeout",
    "riding",
    "wiping_out",
    "settings",
    "grind_materials",
    "air_targeting_grind",
    "globals",
    "attributes",
    "actions",
    "packet",
    "teleported"
}
local v39
local v40 = false

local function new_pool() -- line: 182
    -- upvalues: t1 (copy)
    return {
        callbacks = {
            prepare_grind = t1.Callbacks.prepare_grind,
            process_skeleton = t1.Callbacks.process_skeleton,
            teleport = t1.Callbacks.teleport
        },
        host = {
            actor_query_56 = 0,
            actor_query_44 = 0,
            input_available = false,
            transition_action = 0,
            air_counter_40 = 0
        },
        ground_frame = {}
    }
end

function t1.advance(p15, p16, p17, p18, p19) -- line: 222
    -- upvalues: v1 (copy), import (copy), t1 (copy), from_bits4 (copy), v36 (ref), assign_into (copy), copy_into (copy), t3 (copy), run_stages (copy), t4 (copy), v39 (ref), v40 (ref), new_pool (copy)
    if v36 then
        return t1.advance_reference(p15, p16, p17, p18, p19)
    end

    local reset_for_teleport = import("skate_game/physics/offboard/board_manager/runtime").reset_for_teleport

    import("skate_core/player/offboard/contact_toolkit").Owner.begin_input(p16.offboard_contact)
    p16.landing_deck.manager.can_land_256 = false

    local ik_offset_176 = p16.landing_deck.manager.ik_offset_176
    local v41 = ik_offset_176[1]
    local v42

    if v41 ~= 0 and v41 > -1.1754943508222875E-38 and v41 < 1.1754943508222875E-38 then
        local v43 = math.abs(v41) * 7.1362384635298E+44
        local v44 = math.floor(v43)
        local v45 = v43 - v44

        v42 = if v45 > 0.5 or v45 == 0.5 and v44 % 2 == 1 then v44 + 1 else v44

        if v41 < 0 then
            v42 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v41)
        v42 = buffer.readu32(v1, 0)
    end

    local v46 = ik_offset_176[2]
    local v47

    if v46 ~= 0 and v46 > -1.1754943508222875E-38 and v46 < 1.1754943508222875E-38 then
        local v48 = math.abs(v46) * 7.1362384635298E+44
        local v49 = math.floor(v48)
        local v50 = v48 - v49

        v47 = if v50 > 0.5 or v50 == 0.5 and v49 % 2 == 1 then v49 + 1 else v49

        if v46 < 0 then
            v47 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v46)
        v47 = buffer.readu32(v1, 0)
    end

    local v51 = ik_offset_176[3]
    local v52

    if v51 ~= 0 and v51 > -1.1754943508222875E-38 and v51 < 1.1754943508222875E-38 then
        local v53 = math.abs(v51) * 7.1362384635298E+44
        local v54 = math.floor(v53)
        local v55 = v53 - v54

        v52 = if v55 > 0.5 or v55 == 0.5 and v54 % 2 == 1 then v54 + 1 else v54

        if v51 < 0 then
            v52 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v51)
        v52 = buffer.readu32(v1, 0)
    end

    local v56 = ik_offset_176[4]
    local v57

    if v56 ~= 0 and v56 > -1.1754943508222875E-38 and v56 < 1.1754943508222875E-38 then
        local v58 = math.abs(v56) * 7.1362384635298E+44
        local v59 = math.floor(v58)
        local v60 = v58 - v59

        v57 = if v60 > 0.5 or v60 == 0.5 and v59 % 2 == 1 then v59 + 1 else v59

        if v56 < 0 then
            v57 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v56)
        v57 = buffer.readu32(v1, 0)
    end

    t3[1] = v42
    t3[2] = v47
    t3[3] = v52
    t3[4] = v57
    copy_into(p16.player_input.player, "manager_1852_vector_176", t3)

    local v61 = t1.transition_action(p18)
    local t5

    if p16.player_input.physical.state.flag_61 ~= 0 then
        local teleport_output = p16.player_input.physical.teleport_output

        if teleport_output == nil then
            error("Teleport State61 requires its published reset transform", 0)
        end

        local transform = teleport_output.transform

        t5 = {
            from_bits4(transform[1]),
            from_bits4(transform[2]),
            from_bits4(transform[3]),
            (from_bits4(transform[4]))
        }
    end

    local post_grind_jump_counter = p16.player_state.selector.post_grind_jump_counter
    local PlayerInputRuntime = import("skate_game/physics/player_input").PlayerInputRuntime

    if p16.player_input.physical.state.flag_61 ~= 0 or bit32.band(p16.player_input.player.flags_1296, 524288) ~= 0 or p16.player_input.pending_teleport ~= nil then
        import("skate_game/physics/offboard/air_selector").AirSelector.reset(p16.offboard_air_selector)
        reset_for_teleport(p15, p16)
    end

    local v63 = t1.collision(p16)
    local riding = p15.riding
    local v64 = import("skate_core/air/trajectory").TrajectorySelector.grind_locked_to_middle(p16.trajectory.selector)
    local hierarchy = p16.animation.packet.hierarchy
    local v65 = import("skate_core/animation/output/attributes").PacketAttributes.entries(p16.animation.attributes)
    local ground = riding.reckoning_frames.ground
    local v66

    if v40 then
        v66 = new_pool()
    else
        v66 = v39

        if v66 == nil then
            v66 = new_pool()
            v39 = v66
        end

        v40 = true
    end

    local host = v66.host

    host.input_available = p19
    host.transition_action = v61
    host.published_board_transform = t5
    host.air_counter_40 = post_grind_jump_counter

    local callbacks = v66.callbacks

    callbacks.skeleton_input = p16.skeleton_input
    callbacks.animated = p16.animated_skeleton
    callbacks.skeleton_air = p16.skeleton_air
    callbacks.footplant = p16.footplant
    callbacks.handplant = p16.handplant
    callbacks.body = p16.skeleton
    callbacks.drives = p16.skeleton_drives
    callbacks.ik = p16.foot_ik
    callbacks.animation_input = p16.animation_input
    callbacks.output = p16.skeleton_output
    callbacks.pose_errors = p16.pose_errors
    callbacks.collision_mode = p16.skeleton_collision
    callbacks.feedback = p16.collision_feedback
    callbacks.collision = v63
    callbacks.ground = p16.ground
    callbacks.life = p16.ground_lifecycle
    callbacks.offboard_grab = p16.offboard_grab
    callbacks.wipeout = p16.wipeout
    callbacks.riding = riding
    callbacks.wiping_out = p15.board_wiping_out
    callbacks.settings = p15.settings
    callbacks.grind_materials = p15.grind_materials
    callbacks.air_targeting_grind = v64
    callbacks.globals = hierarchy
    callbacks.attributes = v65
    callbacks.actions = p18
    callbacks.packet = p17
    callbacks.teleported = false

    local ground_frame = v66.ground_frame

    if type(ground) == "table" then
        assign_into(ground_frame, ground)
    else
        ground_frame = ground
    end

    local ok, result = pcall(run_stages, PlayerInputRuntime, p15, p16, ground_frame, p17, host, callbacks)

    p15.board_wiping_out = callbacks.wiping_out

    local teleported = callbacks.teleported

    for _, v67 in t4 do
        callbacks[v67] = nil
    end

    host.published_board_transform = nil

    if v66 == v39 then
        v40 = false
    end

    if not ok then
        error(result, 0)
    end

    if teleported then
        reset_for_teleport(p15, p16)
    end

    p15.processed_flags_2468 = p16.player_input.processed.flags_2468

    return teleported
end

function t1.advance_reference(p20, p21, p22, p23, p24) -- line: 337
    -- upvalues: rt (copy), import (copy), t1 (copy), from_bits4 (copy), to_bits4 (copy)
    local reset_for_teleport = import("skate_game/physics/offboard/board_manager/runtime").reset_for_teleport

    import("skate_core/player/offboard/contact_toolkit").Owner.begin_input(p21.offboard_contact)
    p21.landing_deck.manager.can_land_256 = false
    p21.player_input.player.manager_1852_vector_176 = to_bits4(p21.landing_deck.manager.ik_offset_176)

    local v68 = t1.transition_action(p23)
    local v69

    if p21.player_input.physical.state.flag_61 == 0 then
        v69 = import("skate_game/physics/solve").deck_frame(p20.board)
    else
        local teleport_output = p21.player_input.physical.teleport_output

        if teleport_output == nil then
            error("Teleport State61 requires its published reset transform", 0)
        end

        local transform = teleport_output.transform

        v69 = {
            from_bits4(transform[1]),
            from_bits4(transform[2]),
            from_bits4(transform[3]),
            (from_bits4(transform[4]))
        }
    end

    local t6 = {
        actor_query_56 = 0,
        actor_query_44 = 0,
        input_available = p24,
        transition_action = v68,
        published_board_transform = v69,
        air_counter_40 = p21.player_state.selector.post_grind_jump_counter
    }
    local PlayerInputRuntime = import("skate_game/physics/player_input").PlayerInputRuntime

    if p21.player_input.physical.state.flag_61 ~= 0 or bit32.band(p21.player_input.player.flags_1296, 524288) ~= 0 or PlayerInputRuntime.pending_teleport(p21.player_input) ~= nil then
        import("skate_game/physics/offboard/air_selector").AirSelector.reset(p21.offboard_air_selector)
        reset_for_teleport(p20, p21)
    end

    local v71 = t1.collision(p21)
    local t7 = {
        teleported = false,
        skeleton_input = p21.skeleton_input,
        animated = p21.animated_skeleton,
        skeleton_air = p21.skeleton_air,
        footplant = p21.footplant,
        handplant = p21.handplant,
        body = p21.skeleton,
        drives = p21.skeleton_drives,
        ik = p21.foot_ik,
        animation_input = p21.animation_input,
        output = p21.skeleton_output,
        pose_errors = p21.pose_errors,
        collision_mode = p21.skeleton_collision,
        feedback = p21.collision_feedback,
        collision = v71,
        ground = p21.ground,
        life = p21.ground_lifecycle,
        offboard_grab = p21.offboard_grab,
        wipeout = p21.wipeout,
        riding = p20.riding,
        wiping_out = p20.board_wiping_out,
        settings = p20.settings,
        grind_materials = p20.grind_materials,
        air_targeting_grind = import("skate_core/air/trajectory").TrajectorySelector.grind_locked_to_middle(p21.trajectory.selector),
        globals = p21.animation.packet.hierarchy,
        attributes = import("skate_core/animation/output/attributes").PacketAttributes.entries(p21.animation.attributes),
        actions = p23,
        packet = p22
    }
    local t8 = {
        prepare_grind = function(_, ...) -- prepare_grind | line: 412
            -- upvalues: t7 (copy), t1 (copy)
            return t1.Callbacks.prepare_grind(t7, ...)
        end,
        process_skeleton = function(_, ...) -- process_skeleton | line: 415
            -- upvalues: t7 (copy), t1 (copy)
            return t1.Callbacks.process_skeleton(t7, ...)
        end,
        teleport = function(_, ...) -- teleport | line: 418
            -- upvalues: t7 (copy), t1 (copy)
            return t1.Callbacks.teleport(t7, ...)
        end
    }
    local v72 = rt.copy(t7.riding.reckoning_frames.ground)

    local function v73() -- line: 423
        -- upvalues: p20 (copy), p21 (copy), p22 (copy), t6 (copy), PlayerInputRuntime (copy), t8 (copy), v72 (copy), rt (copy)
        local v74 = PlayerInputRuntime.process_stage(p21.player_input, p20.board, p21.ground_runtime, rt.copy(v72), p22, rt.copy(t6), t8, {
            tag = "ThroughTeleport"
        }, p20.world, p20.grind_world)

        if v74 ~= nil then
            PlayerInputRuntime.process_stage(p21.player_input, p20.board, p21.ground_runtime, rt.copy(v72), p22, rt.copy(t6), t8, {
                tag = "AfterTeleport",
                v74
            }, p20.world, p20.grind_world)
        end
    end

    local ok, result = pcall(v73)

    p20.board_wiping_out = t7.wiping_out

    if not ok then
        error(result, 0)
    end

    local teleported = t7.teleported

    if teleported then
        reset_for_teleport(p20, p21)
    end

    p20.processed_flags_2468 = p21.player_input.processed.flags_2468

    return teleported
end

function t1.update_ground(p28, p29) -- line: 465
    -- upvalues: import (copy), t1 (copy)
    local v75 = t1.collision(p29)
    local t9 = {
        animated = p29.animated_skeleton,
        body = p29.skeleton,
        drives = p29.skeleton_drives,
        ik = p29.foot_ik,
        animation_input = p29.animation_input,
        correction = p29.skeleton_output.correction,
        pose_errors = p29.pose_errors
    }
    local v76 = import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.update_ground(p29.skeleton_input, p28.board, p28.riding.reckoning_frames.system, p29.player_input.processed, t9, p29.animation.packet.hierarchy, v75, p28.settings.step.simulation)

    import("skate_game/physics/skeleton_air").SkeletonAir.capture_physics_error(p29.skeleton_air, p28.board, v76)
end

function t1.collision(p30) -- line: 492
    -- upvalues: rt (copy)
    return {
        contact_4070 = p30.collision_feedback.flags.compliant,
        has_pose_error_4077 = p30.collision_feedback.flags.has_impulse,
        pose_error_16272 = rt.copy(p30.collision_pose_error),
        partial_ragdoll = p30.skeleton_collision.partial_ragdoll,
        drive_weight_4028 = p30.collision_feedback.drive_weight
    }
end

t1.Callbacks = {}

local v77, v78

function t1.Callbacks.prepare_grind(p31, p32, p33, p34, p35, p36, p37) -- line: 548
    -- upvalues: import (copy), t1 (copy), v36 (ref), v77 (ref), v78 (ref)
    if v36 then
        return t1.Callbacks.prepare_grind_reference(p31, p32, p33, p34, p35, p36, p37)
    end

    local extra = p31.animation_input.extra
    local v79 = v77

    if v79 == nil then
        v79 = {}
        v77 = v79
    end

    v79.board = import("skate_game/physics/solve").deck_frame(p32)
    v79.air_counter = p37
    v79.tip_state = p34.state_2504
    v79.air_targeting_grind_9653 = p31.air_targeting_grind
    v79.balance_2720 = p31.animation_input.fields.balance
    v79.translation_2796 = extra.grind_translation
    v79.stability_nudge_2800 = extra.grind_stability_nudge

    local v80 = v78

    if v80 == nil then
        local LiveHost = import("skate_game/physics/grind_host").LiveHost

        v80 = {
            apply_material_mode = LiveHost.apply_material_mode,
            surface_probe = LiveHost.surface_probe,
            force_exit_line = LiveHost.force_exit_line
        }
        v78 = v80
    end

    v80.board = p32
    v80.settings = p31.settings
    v80.materials = p31.grind_materials

    local v81 = import("skate_game/physics/player_input/grind").GrindInputState.pre_update(p33, p34, p36, p35, v79, v80)

    v79.board = nil
    v80.board = nil
    v80.settings = nil
    v80.materials = nil

    return v81
end

function t1.Callbacks.prepare_grind_reference(p38, p39, p40, p41, p42, p43, p44) -- line: 588
    -- upvalues: import (copy)
    local extra = p38.animation_input.extra
    local t10 = {
        board = import("skate_game/physics/solve").deck_frame(p39),
        air_counter = p44,
        tip_state = p41.state_2504,
        air_targeting_grind_9653 = p38.air_targeting_grind,
        balance_2720 = p38.animation_input.fields.balance,
        translation_2796 = extra.grind_translation,
        stability_nudge_2800 = extra.grind_stability_nudge
    }
    local LiveHost = import("skate_game/physics/grind_host").LiveHost
    local t11 = {
        board = p39,
        settings = p38.settings,
        materials = p38.grind_materials
    }
    local t12 = {
        apply_material_mode = function(_, ...) -- apply_material_mode | line: 608
            -- upvalues: LiveHost (copy), t11 (copy)
            return LiveHost.apply_material_mode(t11, ...)
        end,
        surface_probe = function(_, ...) -- surface_probe | line: 611
            -- upvalues: LiveHost (copy), t11 (copy)
            return LiveHost.surface_probe(t11, ...)
        end,
        force_exit_line = function(_, ...) -- force_exit_line | line: 614
            -- upvalues: LiveHost (copy), t11 (copy)
            return LiveHost.force_exit_line(t11, ...)
        end
    }

    return import("skate_game/physics/player_input/grind").GrindInputState.pre_update(p40, p41, p43, p42, t10, t12)
end

function t1.Callbacks.process_skeleton(p48, p49, p50, p51, p52, p53) -- line: 622
    -- upvalues: import (copy)
    import("skate_game/physics/animation_input").AnimationInput.select_physics_mode(p48.animation_input, p53.state_variant_index_2528)

    return import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.process_data(p48.skeleton_input, p49, p50, p51, p52, p53, {
        animated = p48.animated,
        body = p48.body,
        drives = p48.drives,
        ik = p48.ik,
        animation_input = p48.animation_input,
        correction = p48.output.correction,
        pose_errors = p48.pose_errors
    }, {
        globals = p48.globals,
        attributes = p48.attributes,
        actions = p48.actions
    }, p48.collision)
end

function t1.Callbacks.teleport(p54, p55, p56, p57, p58, p59, p60) -- line: 650
    -- upvalues: t1 (copy)
    return t1.Callbacks.reset_player(p54, p55, p56, p57, p58, p59, p60)
end

for v82, v83 in v8.Callbacks do
    t1.Callbacks[v82] = v83
end

return t1
