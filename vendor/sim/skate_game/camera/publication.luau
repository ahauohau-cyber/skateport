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
local Anchors = import("skate_core/camera").Anchors
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime

local function ground_runtime() -- line: 20
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local PERF = import("skate_core/camera/tracker").PERF
local effective_skeleton_root
local t1 = {}

t1.CameraStateOutput = {}
t1.CameraAnimationOutput = {}
t1.CameraAirOutput = {}
t1.CameraOffboardOutput = {}
t1.CameraGrindOutput = {}
t1.CameraEventsOutput = {}
t1.CameraPreferences = {}
t1.CameraPublicationInputs = {}

local function map_bits(p2) -- line: 96
    -- upvalues: rt (copy)
    return rt.map(p2, rt.from_bits)
end

local function debug_list(p3) -- line: 101
    local v1 = table.create(#p3)

    for v2, v3 in p3 do
        v1[v2] = tostring(v3)
    end

    return "[" .. table.concat(v1, ", ") .. "]"
end

function t1.snapshot(p4, p5, p6) -- line: 114
    -- upvalues: rt (copy), import (copy), Anchors (copy), BodyId (copy), BoardRuntime (copy), PERF (copy), effective_skeleton_root (ref)
    local physical, processed, toolkit = p5.player_input.physical, p5.player_input.processed, p5.player_input.toolkit

    if toolkit == nil then
        error("Camera publication requires the completed player input toolkit", 0)
    end

    local v4 = import("skate_game/physics/ground_runtime").GroundState.output(p5.ground, processed, p5.animation_input, toolkit)
    local v5, v6, v7

    if PERF.reference then
        local v8 = rt.copy(BoardRuntime.part_transforms(p4.board)[BodyId.index(BodyId.Deck) + 1])

        v5 = v8.translation.x
        v6 = v8.translation.y
        v7 = v8.translation.z
    else
        v5, v6, v7 = BoardRuntime.part_translation(p4.board, BodyId.index(BodyId.Deck))
    end

    local v9 = rt.filled(4, table.create(4, 0))

    for i = 0, 2 do
        local v10 = p4.riding.motion.effective_basis.columns[i + 1]

        v9[i + 1][1] = v10[1]
        v9[i + 1][2] = v10[2]
        v9[i + 1][3] = v10[3]
    end

    v9[4] = { v5, v6, v7, 0 }

    local v11 = effective_skeleton_root(rt.copy(p5.animated_skeleton.roots.animation_to_world), processed.flags_2476)
    local record = p5.skeleton.record
    local vector_64 = physical.reckoning.vector_64
    local v12 = rt.map(vector_64, rt.from_bits)
    local vector_96 = physical.reckoning.vector_96
    local v13 = rt.map(vector_96, rt.from_bits)
    local vector_80 = physical.skateboard.vector_80
    local v14 = rt.map(vector_80, rt.from_bits)
    local vector_64_2 = physical.skateboard.vector_64
    local v15 = rt.map(vector_64_2, rt.from_bits)

    local function finite(p7, p8) -- line: 163
        -- upvalues: processed (copy)
        local v16 = p8[1]

        if v16 == v16 and v16 ~= 1e999 and v16 ~= (-1e999) then
            local v17 = p8[2]

            if v17 == v17 and v17 ~= 1e999 and v17 ~= (-1e999) then
                local v18 = p8[3]

                if v18 == v18 and v18 ~= 1e999 and v18 ~= (-1e999) then
                    return
                end
            end
        end

        local _error = error
        local format = string.format
        local v19 = "Camera subject owner published non-finite %s: %s; state=%s; category=%s"
        local v20 = table.create(#p8)

        for v21, v22 in p8 do
            v20[v21] = tostring(v22)
        end

        _error(format(v19, p7, "[" .. table.concat(v20, ", ") .. "]", tostring(processed.state_2508), (tostring(processed.category_2512))), 0)
    end

    finite("centre_of_mass", v12)
    finite("reckoning_up", v13)
    finite("damped_centre_of_mass", p6.damped_com_80)
    finite("ground_up", p6.ground_up_80)

    for _, v25 in v11 do
        finite("skeleton_root", v25)
    end

    for _, v26 in { 1, 15, 19, 23 } do
        local v27 = record.pose[v26 + 1][4]

        finite(if v26 == 1 then "head"
            elseif v26 == 15 then "left_foot"
            elseif v26 == 19 then "right_foot"
            else "hips", v27)
    end

    local v28 = v14[1]
    local v29 = not (v28 == v28 and v28 ~= 1e999 and v28 ~= (-1e999))
    local v30 = v14[2]

    if v30 ~= v30 or v30 == 1e999 or v30 == (-1e999) then
        v29 = true
    end

    local v31 = v14[3]

    if v31 ~= v31 or v31 == 1e999 or v31 == (-1e999) then
        v29 = true
    end

    local v32 = v15[1]

    if v32 ~= v32 or v32 == 1e999 or v32 == (-1e999) then
        v29 = true
    end

    local v33 = v15[2]

    if v33 ~= v33 or v33 == 1e999 or v33 == (-1e999) then
        v29 = true
    end

    local v34 = v15[3]

    if v34 ~= v34 or v34 == 1e999 or v34 == (-1e999) or v29 then
        local _error = error
        local format = string.format
        local v35 = "Camera received non-finite board motion publication: velocity=%s; acceleration=%s; raw_velocity=%s; raw_acceleration=%s"
        local v36 = table.create(#v14)

        for v37, v38 in v14 do
            v36[v37] = tostring(v38)
        end

        local v39 = "[" .. table.concat(v36, ", ") .. "]"
        local v40 = table.create(#v15)

        for v41, v42 in v15 do
            v40[v41] = tostring(v42)
        end

        local v43 = "[" .. table.concat(v40, ", ") .. "]"
        local vector_80 = physical.skateboard.vector_80
        local v44 = table.create(#vector_80)

        for v45, v46 in vector_80 do
            v44[v45] = tostring(v46)
        end

        local v47 = "[" .. table.concat(v44, ", ") .. "]"
        local vector_64 = physical.skateboard.vector_64
        local v48 = table.create(#vector_64)

        for v49, v50 in vector_64 do
            v48[v49] = tostring(v50)
        end

        _error(format(v35, v39, v43, v47, "[" .. table.concat(v48, ", ") .. "]"), 0)
    end

    local vector_96_2 = physical.ground.vector_96
    local v51 = rt.map(vector_96_2, rt.from_bits)
    local category_12, state_16 = physical.state.category_12, physical.state.state_16
    local offboard, air = p6.offboard, p6.air
    local v52 = offboard.use_trajectory_331 ~= 0
    local v53 = if v52 then rt.copy(offboard.launch_position_176) else rt.copy(air.launch_position_48)
    local v54 = if v52 then rt.copy(offboard.launch_normal_160) else rt.copy(v51)
    local v55 = if v52 then rt.copy(offboard.landing_position_208) else rt.copy(air.landing_position_16)
    local v56 = if v52 then rt.copy(offboard.landing_normal_192) else rt.copy(air.landing_normal_32)
    local v57 = if v52 then rt.copy(offboard.apex_240) else rt.copy(air.apex_0)
    local v61 = if v52 then rt.copy(offboard.heading_224) else rt.copy(air.heading_80)
    local v58 = if v52 then offboard.time_152 else air.time_176
    local v59 = if v52 then offboard.duration_92 else air.duration_180
    local v60 = if v52 then offboard.apex_time_156 else air.apex_time_196
    local grinding_316 = p6.grinds.grinding_316
    local v62 = rt.from_fn(2, function(p9) -- line: 256
        -- upvalues: p6 (copy)
        if p6.preferences.invert_look[p9 + 1] then
            return -p6.look_552_556[p9 + 1]
        end

        return p6.look_552_556[p9 + 1]
    end)
    local t2 = {
        special_effect = 0
    }
    local t3 = {
        subject_flag_328 = 0,
        transform = rt.copy(v9),
        skeleton_root = rt.copy(v11),
        hips_position = rt.copy(record.pose[24][4]),
        last_valid_ground_up = rt.copy(v51),
        reference_positions = rt.filled(10, table.create(4, 0)),
        context = p6.context,
        pumping_acceleration = p5.ground.pumping.pump_acceleration,
        state_height_32 = p6.state.height_32,
        in_ground_physics = category_12 == 100 and 1 or 0,
        grinding = grinding_316,
        trajectory_valid = if v52 then 1 else physical.air.known_air_valid_437,
        wiping_out = p6.state.wiping_out_59,
        physically_pushing = p6.state.physically_pushing_55,
        at_pushable_speed = v4.skateboard_motion_4.is_at_pushable_speed and 1 or 0,
        off_board = category_12 == 500 and 1 or 0,
        air_flag_452 = physical.air.use_air_reckoning_452,
        state_flag_81 = p6.state.flag_81
    }
    local v63 = p6.events.broken_bone_duration_200 > 0
    local v64 = if v63 then bit32.band(p6.events.capabilities_204, 4) == 0 else nil

    t3.broken_bone_slowmo = (not v63 or v64) and 0 or 1
    t2.rig = t3
    t2.anchors = Anchors.new().entries
    t2.compass = table.create(9, 0)
    t2.board_offset_direction = rt.copy(v13)
    t2.ground_normal = rt.copy(p6.ground_up_80)
    t2.launch_position = v53
    t2.launch_normal = v54
    t2.landing_position = v55
    t2.landing_normal = v56
    t2.apex_position = v57
    t2.direction_424 = rt.copy(p6.grinds.direction_0)
    t2.look = v62
    t2.steering = {
        p6.animation.conditioned_turn[5],
        p6.animation.conditioned_turn[4],
        p6.animation.input_turn_64,
        p6.animation.input_kickturn_68
    }
    t2.trajectory_time = v58
    t2.trajectory_duration = v59
    t2.apex_time = v60
    t2.value_512 = p6.preferences.value_32
    t2.value_516 = p6.ground_scalar_288
    t2.reset = p6.state.reset_62
    t2.flag_556 = air.flag_440
    t2.stance_560 = p6.animation.stance_155
    t2.stance_592 = p6.animation.skater_animation_stance
    t2.flag_652 = p6.state.flag_79
    t2.shake_variant = p6.preferences.shake_variant
    t2.flag_684 = offboard.object_held_304

    return {
        tick = p6.tick,
        subject = t2,
        pose = {
            physical_transform = rt.copy(v9),
            skeleton_root = rt.copy(v11),
            center_of_mass = rt.copy(v12),
            reckoned_center_of_mass = rt.copy(p6.damped_com_80),
            wiping_out = p6.state.wiping_out_59 ~= 0,
            state_flag_75 = p6.state.use_skeleton_root_75 ~= 0
        },
        anchors = {
            board_position = rt.copy(v9[4]),
            board_velocity = rt.copy(v14),
            board_acceleration = rt.copy(v15),
            board_offset_direction = rt.copy(v13),
            center_of_mass = rt.copy(v12),
            damped_center_of_mass = rt.copy(p6.damped_com_80),
            skeleton_root_up = rt.copy(v11[2]),
            grind_point = rt.copy(p6.grinds.camera_target_96),
            grinding = grinding_316 ~= 0,
            reset = p6.state.reset_62 ~= 0
        },
        reference_points = {
            head = rt.copy(record.pose[2][4]),
            hips = rt.copy(record.pose[24][4]),
            left_foot = rt.copy(record.pose[16][4]),
            right_foot = rt.copy(record.pose[20][4]),
            board = rt.copy(v11[4]),
            centre_of_mass = rt.copy(v12),
            damped_centre_of_mass = rt.copy(p6.damped_com_80),
            grind_position = rt.copy(p6.grinds.camera_target_96),
            tracked_anchor = table.create(4, 0),
            incline_normal = table.create(4, 0),
            grinding = grinding_316
        },
        compass = {
            skeleton_direction = rt.copy(v11[3]),
            look_target = rt.copy(p6.collision_look_target_64),
            board_velocity = rt.copy(v14),
            trajectory_direction = v61,
            state_103 = state_16 == 103
        },
        graph = {
            time_since_player_input = p6.animation.time_since_input_128,
            wipeout_tweak = p6.animation.wipeout_tweak_148,
            onboard_air = category_12 == 200,
            preparing_to_jump = p6.events.preparing_52 ~= 0,
            manual = p6.state.manual_60 ~= 0 and p6.events.intent_51 == 0,
            offboard_air = state_16 == 501,
            running_out = p6.animation.running_out_160 ~= 0,
            footplant = state_16 == 601,
            handplant = state_16 == 600,
            hippy_jump = p6.events.hippy_jump_322 ~= 0,
            hippy_hurdle = offboard.hurdle_317 ~= 0,
            boneless = p6.events.trick_125 ~= 0,
            moving_object = state_16 == 502,
            skitching = state_16 == 104,
            dropping_in = p6.events.dropping_in_63 ~= 0 and offboard.dropping_in_334 ~= 0,
            slow_motion_air_duration = physical.air.scalar_184
        }
    }
end

function t1.effective_skeleton_root(p10, p11) -- line: 389
    -- upvalues: rt (copy)
    if bit32.band(p11, 4) ~= 0 then
        p10[1] = rt.map(p10[1], function(p12) -- line: 391
            return -p12
        end)
        p10[3] = rt.map(p10[3], function(p13) -- line: 394
            return -p13
        end)
    end

    return p10
end

effective_skeleton_root = t1.effective_skeleton_root

local self = setmetatable({}, {
    __mode = "k"
})
local v66 = buffer.create(4)

local function from_bits(p14) -- line: 433
    -- upvalues: v66 (copy)
    buffer.writeu32(v66, 0, p14)

    return (buffer.readf32(v66, 0))
end

local is_finite = rt.is_finite

local function finite3(p15) -- line: 440
    -- upvalues: is_finite (copy)
    return is_finite(p15[1]) and is_finite(p15[2]) and is_finite(p15[3])
end

local function copy4(p16, p17) -- line: 444
    local v67 = p17[1]
    local v68 = p17[2]
    local v69 = p17[3]
    local v70 = p17[4]

    p16[1] = v67
    p16[2] = v68
    p16[3] = v69
    p16[4] = v70
end

function t1.snapshot_into(p18, p19, p20, p21) -- line: 448
    -- upvalues: import (copy), BodyId (copy), BoardRuntime (copy), t1 (copy), PERF (copy), self (copy), v66 (copy), is_finite (copy)
    local player_input, physical, columns, offboard

    if not PERF.reference and p21 ~= nil and self[p21] then
        player_input = p19.player_input
        physical = player_input.physical
        offboard = player_input.processed
        columns = player_input.toolkit

        if columns == nil then
            error("Camera publication requires the completed player input toolkit", 0)
        end

        local v71 = import("skate_game/physics/ground_runtime").GroundState.output(p19.ground, offboard, p19.animation_input, columns)
        local v72, v73, v74 = BoardRuntime.part_translation(p18.board, BodyId.index(BodyId.Deck))

        columns = p18.riding.motion.effective_basis.columns

        local animation_to_world = p19.animated_skeleton.roots.animation_to_world
        local v76 = bit32.band(offboard.flags_2476, 4) ~= 0

        offboard = p19.skeleton.record.pose

        local v77 = offboard[2][4]
        local v75 = offboard[16][4]
        local v78 = offboard[20][4]
        local v79 = offboard[24][4]
        local state_16, category_12 = physical.reckoning, physical.skateboard

        offboard = state_16.vector_64
        buffer.writeu32(v66, 0, offboard[1])

        local v81 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[2])

        local v82 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[3])

        local v83 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[4])

        local v84 = buffer.readf32(v66, 0)

        offboard = state_16.vector_96
        buffer.writeu32(v66, 0, offboard[1])

        local v86 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[2])

        local v87 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[3])

        local v88 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[4])

        local v89 = buffer.readf32(v66, 0)

        offboard = category_12.vector_80
        buffer.writeu32(v66, 0, offboard[1])

        local v91 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[2])

        local v92 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[3])

        local v93 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[4])

        local v94 = buffer.readf32(v66, 0)

        offboard = category_12.vector_64
        buffer.writeu32(v66, 0, offboard[1])

        local v95 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[2])

        local v96 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[3])

        local v97 = buffer.readf32(v66, 0)

        buffer.writeu32(v66, 0, offboard[4])

        local v98 = buffer.readf32(v66, 0)
        local damped_com_80 = p20.damped_com_80
        local ground_up_80 = p20.ground_up_80

        if is_finite(v81) and is_finite(v82) and is_finite(v83) and is_finite(v86) and is_finite(v87) and is_finite(v88) and is_finite(damped_com_80[1]) and is_finite(damped_com_80[2]) and is_finite(damped_com_80[3]) and is_finite(ground_up_80[1]) and is_finite(ground_up_80[2]) and is_finite(ground_up_80[3]) then
            local v99 = animation_to_world[1]

            if is_finite(v99[1]) and is_finite(v99[2]) and is_finite(v99[3]) then
                v99 = animation_to_world[2]

                if is_finite(v99[1]) and is_finite(v99[2]) and is_finite(v99[3]) then
                    v99 = animation_to_world[3]

                    if is_finite(v99[1]) and is_finite(v99[2]) and is_finite(v99[3]) then
                        v99 = animation_to_world[4]

                        if is_finite(v99[1]) and is_finite(v99[2]) and is_finite(v99[3]) and is_finite(v77[1]) and is_finite(v77[2]) and is_finite(v77[3]) and is_finite(v75[1]) and is_finite(v75[2]) and is_finite(v75[3]) and is_finite(v78[1]) and is_finite(v78[2]) and is_finite(v78[3]) then
                            local v100 = is_finite(v79[1]) and is_finite(v79[2]) and is_finite(v79[3])

                            if v100 and is_finite(v91) and is_finite(v92) and is_finite(v93) and is_finite(v95) and is_finite(v96) and is_finite(v97) then
                                local v101, air

                                if p20.tick <= p21.tick then
                                    v100 = error
                                    v99 = string.format
                                    air = p21.tick

                                    local v102 = tostring(air)

                                    v101 = p20.tick
                                    v100(v99("Camera received non-monotonic subject tick: previous=%s, current=%s", v102, (tostring(v101))), 0)
                                end

                                offboard = physical.ground.vector_96
                                buffer.writeu32(v66, 0, offboard[1])
                                v101 = buffer.readf32(v66, 0)
                                buffer.writeu32(v66, 0, offboard[2])

                                local v103 = buffer.readf32(v66, 0)

                                buffer.writeu32(v66, 0, offboard[3])

                                local v104 = buffer.readf32(v66, 0)

                                buffer.writeu32(v66, 0, offboard[4])

                                local v105 = buffer.readf32(v66, 0)

                                category_12 = physical.state.category_12
                                state_16 = physical.state.state_16
                                offboard = p20.offboard
                                air = p20.air

                                local v106 = offboard.use_trajectory_331 ~= 0
                                local state, animation, events, grinds = p20.state, p20.animation, p20.events, p20.grinds
                                local preferences = p20.preferences
                                local grinding_316 = grinds.grinding_316
                                local wiping_out_59, reset_62 = state.wiping_out_59, state.reset_62
                                local air2 = physical.air

                                p21.tick = p20.tick
                                physical = p21.subject

                                local rig = physical.rig
                                local heading_224 = rig.transform
                                local physical_transform = p21.pose.physical_transform
                                local v107, v108, v109, v110

                                for i = 1, 3 do
                                    v110 = columns[i]
                                    v107 = v110[1]
                                    v108 = v110[2]
                                    v109 = v110[3]
                                    v110 = heading_224[i]
                                    v110[1] = v107
                                    v110[2] = v108
                                    v110[3] = v109
                                    v110[4] = 0
                                    v110 = physical_transform[i]
                                    v110[1] = v107
                                    v110[2] = v108
                                    v110[3] = v109
                                    v110[4] = 0
                                end

                                local v111 = heading_224[4]

                                v111[1] = v72
                                v111[2] = v73
                                v111[3] = v74
                                v111[4] = 0
                                v111 = physical_transform[4]
                                v111[1] = v72
                                v111[2] = v73
                                v111[3] = v74
                                v111[4] = 0
                                v111 = p21.anchors.board_position
                                v111[1] = v72
                                v111[2] = v73
                                v111[3] = v74
                                v111[4] = 0
                                heading_224 = rig.skeleton_root
                                physical_transform = p21.pose.skeleton_root

                                local v112, v113

                                for i = 1, 4 do
                                    v74 = animation_to_world[i]
                                    v110 = v74[1]
                                    v107 = v74[2]
                                    v108 = v74[3]
                                    v109 = v74[4]

                                    local v114, v115

                                    if v76 and (i == 1 or i == 3) then
                                        v112 = -v110
                                        v113 = -v107
                                        v114 = -v108
                                        v115 = -v109
                                    else
                                        v115 = v109
                                        v112 = v110
                                        v113 = v107
                                        v114 = v108
                                    end

                                    v74 = heading_224[i]
                                    v74[1] = v112
                                    v74[2] = v113
                                    v74[3] = v114
                                    v74[4] = v115
                                    v74 = physical_transform[i]
                                    v74[1] = v112
                                    v74[2] = v113
                                    v74[3] = v114
                                    v74[4] = v115

                                    if i == 2 then
                                        v74 = p21.anchors.skeleton_root_up
                                        v74[1] = v112
                                        v74[2] = v113
                                        v74[3] = v114
                                        v74[4] = v115
                                    elseif i == 3 then
                                        v74 = p21.compass.skeleton_direction
                                        v74[1] = v112
                                        v74[2] = v113
                                        v74[3] = v114
                                        v74[4] = v115
                                    elseif i == 4 then
                                        v74 = p21.reference_points.board
                                        v74[1] = v112
                                        v74[2] = v113
                                        v74[3] = v114
                                        v74[4] = v115
                                    end
                                end

                                heading_224 = rig.hips_position
                                physical_transform = v79[1]
                                v111 = v79[2]

                                local v116 = v79[3]
                                local v117 = v79[4]

                                heading_224[1] = physical_transform
                                heading_224[2] = v111
                                heading_224[3] = v116
                                heading_224[4] = v117
                                v76 = rig.last_valid_ground_up
                                v76[1] = v101
                                v76[2] = v103
                                v76[3] = v104
                                v76[4] = v105
                                rig.context = p20.context
                                rig.pumping_acceleration = p19.ground.pumping.pump_acceleration
                                rig.state_height_32 = state.height_32
                                rig.in_ground_physics = category_12 == 100 and 1 or 0
                                rig.grinding = grinding_316

                                if v106 then
                                    rig.trajectory_valid = 1
                                else
                                    rig.trajectory_valid = air2.known_air_valid_437
                                end

                                rig.wiping_out = wiping_out_59
                                rig.physically_pushing = state.physically_pushing_55
                                rig.at_pushable_speed = v71.skateboard_motion_4.is_at_pushable_speed and 1 or 0
                                rig.off_board = category_12 == 500 and 1 or 0
                                rig.air_flag_452 = air2.use_air_reckoning_452
                                rig.state_flag_81 = state.flag_81

                                local v118 = events.broken_bone_duration_200 > 0
                                local v119

                                if v118 then
                                    v111 = events.capabilities_204
                                    v119 = bit32.band(v111, 4) == 0
                                end

                                if not v118 or v119 then
                                    rig.broken_bone_slowmo = 0
                                else
                                    rig.broken_bone_slowmo = 1
                                end

                                v76 = physical.board_offset_direction
                                v76[1] = v86
                                v76[2] = v87
                                v76[3] = v88
                                v76[4] = v89
                                heading_224 = physical.ground_normal
                                physical_transform = ground_up_80[1]
                                v111 = ground_up_80[2]
                                v116 = ground_up_80[3]
                                v117 = ground_up_80[4]
                                heading_224[1] = physical_transform
                                heading_224[2] = v111
                                heading_224[3] = v116
                                heading_224[4] = v117
                                physical_transform = physical.launch_position

                                if v106 then
                                    v111 = offboard.launch_position_176
                                    v116 = v111[1]
                                    v117 = v111[2]
                                    v112 = v111[3]
                                    v113 = v111[4]
                                    physical_transform[1] = v116
                                    physical_transform[2] = v117
                                    physical_transform[3] = v112
                                    physical_transform[4] = v113
                                    physical_transform = physical.launch_normal
                                    v111 = offboard.launch_normal_160
                                    v116 = v111[1]
                                    v117 = v111[2]
                                    v112 = v111[3]
                                    v113 = v111[4]
                                    physical_transform[1] = v116
                                    physical_transform[2] = v117
                                    physical_transform[3] = v112
                                    physical_transform[4] = v113
                                    physical_transform = physical.landing_position
                                    v111 = offboard.landing_position_208
                                    v116 = v111[1]
                                    v117 = v111[2]
                                    v112 = v111[3]
                                    v113 = v111[4]
                                    physical_transform[1] = v116
                                    physical_transform[2] = v117
                                    physical_transform[3] = v112
                                    physical_transform[4] = v113
                                    physical_transform = physical.landing_normal
                                    v111 = offboard.landing_normal_192
                                    v116 = v111[1]
                                    v117 = v111[2]
                                    v112 = v111[3]
                                    v113 = v111[4]
                                    physical_transform[1] = v116
                                    physical_transform[2] = v117
                                    physical_transform[3] = v112
                                    physical_transform[4] = v113
                                    physical_transform = physical.apex_position
                                    v111 = offboard.apex_240
                                    v116 = v111[1]
                                    v117 = v111[2]
                                    v112 = v111[3]
                                    v113 = v111[4]
                                    physical_transform[1] = v116
                                    physical_transform[2] = v117
                                    physical_transform[3] = v112
                                    physical_transform[4] = v113
                                    heading_224 = offboard.heading_224
                                    physical.trajectory_time = offboard.time_152
                                    physical.trajectory_duration = offboard.duration_92
                                    physical.apex_time = offboard.apex_time_156
                                else
                                    v111 = air.launch_position_48
                                    v116 = v111[1]
                                    v117 = v111[2]
                                    v112 = v111[3]
                                    v113 = v111[4]
                                    physical_transform[1] = v116
                                    physical_transform[2] = v117
                                    physical_transform[3] = v112
                                    physical_transform[4] = v113
                                    v76 = physical.launch_normal
                                    v76[1] = v101
                                    v76[2] = v103
                                    v76[3] = v104
                                    v76[4] = v105
                                    physical_transform = physical.landing_position
                                    v111 = air.landing_position_16
                                    v116 = v111[1]
                                    v117 = v111[2]
                                    v112 = v111[3]
                                    v113 = v111[4]
                                    physical_transform[1] = v116
                                    physical_transform[2] = v117
                                    physical_transform[3] = v112
                                    physical_transform[4] = v113
                                    physical_transform = physical.landing_normal
                                    v111 = air.landing_normal_32
                                    v116 = v111[1]
                                    v117 = v111[2]
                                    v112 = v111[3]
                                    v113 = v111[4]
                                    physical_transform[1] = v116
                                    physical_transform[2] = v117
                                    physical_transform[3] = v112
                                    physical_transform[4] = v113
                                    physical_transform = physical.apex_position
                                    v111 = air.apex_0
                                    v116 = v111[1]
                                    v117 = v111[2]
                                    v112 = v111[3]
                                    v113 = v111[4]
                                    physical_transform[1] = v116
                                    physical_transform[2] = v117
                                    physical_transform[3] = v112
                                    physical_transform[4] = v113
                                    heading_224 = air.heading_80
                                    physical.trajectory_time = air.time_176
                                    physical.trajectory_duration = air.duration_180
                                    physical.apex_time = air.apex_time_196
                                end

                                physical_transform = physical.direction_424
                                v111 = grinds.direction_0
                                v116 = v111[1]
                                v117 = v111[2]
                                v112 = v111[3]
                                v113 = v111[4]
                                physical_transform[1] = v116
                                physical_transform[2] = v117
                                physical_transform[3] = v112
                                physical_transform[4] = v113
                                physical_transform = physical.look
                                v111 = p20.look_552_556
                                v116 = preferences.invert_look

                                if v116[1] then
                                    physical_transform[1] = -v111[1]
                                else
                                    physical_transform[1] = v111[1]
                                end

                                if v116[2] then
                                    physical_transform[2] = -v111[2]
                                else
                                    physical_transform[2] = v111[2]
                                end

                                physical_transform = physical.steering
                                v111 = animation.conditioned_turn
                                v116 = v111[5]
                                v117 = v111[4]
                                v112 = animation.input_turn_64
                                v113 = animation.input_kickturn_68
                                physical_transform[1] = v116
                                physical_transform[2] = v117
                                physical_transform[3] = v112
                                physical_transform[4] = v113
                                physical.value_512 = preferences.value_32
                                physical.value_516 = p20.ground_scalar_288
                                physical.reset = reset_62
                                physical.flag_556 = air.flag_440
                                physical.stance_560 = animation.stance_155
                                physical.stance_592 = animation.skater_animation_stance
                                physical.flag_652 = state.flag_79
                                physical.shake_variant = preferences.shake_variant
                                physical.flag_684 = offboard.object_held_304
                                rig = p21.pose
                                v76 = rig.center_of_mass
                                v76[1] = v81
                                v76[2] = v82
                                v76[3] = v83
                                v76[4] = v84
                                physical_transform = rig.reckoned_center_of_mass
                                v111 = damped_com_80[1]
                                v116 = damped_com_80[2]
                                v117 = damped_com_80[3]
                                v112 = damped_com_80[4]
                                physical_transform[1] = v111
                                physical_transform[2] = v116
                                physical_transform[3] = v117
                                physical_transform[4] = v112
                                rig.wiping_out = wiping_out_59 ~= 0
                                rig.state_flag_75 = state.use_skeleton_root_75 ~= 0
                                rig = p21.anchors
                                v76 = rig.board_velocity
                                v76[1] = v91
                                v76[2] = v92
                                v76[3] = v93
                                v76[4] = v94
                                v76 = rig.board_acceleration
                                v76[1] = v95
                                v76[2] = v96
                                v76[3] = v97
                                v76[4] = v98
                                v76 = rig.board_offset_direction
                                v76[1] = v86
                                v76[2] = v87
                                v76[3] = v88
                                v76[4] = v89
                                v76 = rig.center_of_mass
                                v76[1] = v81
                                v76[2] = v82
                                v76[3] = v83
                                v76[4] = v84
                                physical_transform = rig.damped_center_of_mass
                                v111 = damped_com_80[1]
                                v116 = damped_com_80[2]
                                v117 = damped_com_80[3]
                                v112 = damped_com_80[4]
                                physical_transform[1] = v111
                                physical_transform[2] = v116
                                physical_transform[3] = v117
                                physical_transform[4] = v112
                                physical_transform = rig.grind_point
                                v111 = grinds.camera_target_96
                                v116 = v111[1]
                                v117 = v111[2]
                                v112 = v111[3]
                                v113 = v111[4]
                                physical_transform[1] = v116
                                physical_transform[2] = v117
                                physical_transform[3] = v112
                                physical_transform[4] = v113
                                rig.grinding = grinding_316 ~= 0
                                rig.reset = reset_62 ~= 0
                                rig = p21.reference_points
                                physical_transform = rig.head
                                v111 = v77[1]
                                v116 = v77[2]
                                v117 = v77[3]
                                v112 = v77[4]
                                physical_transform[1] = v111
                                physical_transform[2] = v116
                                physical_transform[3] = v117
                                physical_transform[4] = v112
                                physical_transform = rig.hips
                                v111 = v79[1]
                                v116 = v79[2]
                                v117 = v79[3]
                                v112 = v79[4]
                                physical_transform[1] = v111
                                physical_transform[2] = v116
                                physical_transform[3] = v117
                                physical_transform[4] = v112
                                physical_transform = rig.left_foot
                                v111 = v75[1]
                                v116 = v75[2]
                                v117 = v75[3]
                                v112 = v75[4]
                                physical_transform[1] = v111
                                physical_transform[2] = v116
                                physical_transform[3] = v117
                                physical_transform[4] = v112
                                physical_transform = rig.right_foot
                                v111 = v78[1]
                                v116 = v78[2]
                                v117 = v78[3]
                                v112 = v78[4]
                                physical_transform[1] = v111
                                physical_transform[2] = v116
                                physical_transform[3] = v117
                                physical_transform[4] = v112
                                v76 = rig.centre_of_mass
                                v76[1] = v81
                                v76[2] = v82
                                v76[3] = v83
                                v76[4] = v84
                                physical_transform = rig.damped_centre_of_mass
                                v111 = damped_com_80[1]
                                v116 = damped_com_80[2]
                                v117 = damped_com_80[3]
                                v112 = damped_com_80[4]
                                physical_transform[1] = v111
                                physical_transform[2] = v116
                                physical_transform[3] = v117
                                physical_transform[4] = v112
                                physical_transform = rig.grind_position
                                v111 = grinds.camera_target_96
                                v116 = v111[1]
                                v117 = v111[2]
                                v112 = v111[3]
                                v113 = v111[4]
                                physical_transform[1] = v116
                                physical_transform[2] = v117
                                physical_transform[3] = v112
                                physical_transform[4] = v113
                                rig.grinding = grinding_316
                                rig = p21.compass
                                physical_transform = rig.look_target
                                v111 = p20.collision_look_target_64
                                v116 = v111[1]
                                v117 = v111[2]
                                v112 = v111[3]
                                v113 = v111[4]
                                physical_transform[1] = v116
                                physical_transform[2] = v117
                                physical_transform[3] = v112
                                physical_transform[4] = v113
                                v76 = rig.board_velocity
                                v76[1] = v91
                                v76[2] = v92
                                v76[3] = v93
                                v76[4] = v94
                                physical_transform = rig.trajectory_direction
                                v116 = heading_224[1]
                                v117 = heading_224[2]
                                v112 = heading_224[3]
                                v113 = heading_224[4]
                                physical_transform[1] = v116
                                physical_transform[2] = v117
                                physical_transform[3] = v112
                                physical_transform[4] = v113
                                rig.state_103 = state_16 == 103
                                heading_224 = p21.graph
                                heading_224.time_since_player_input = animation.time_since_input_128
                                heading_224.wipeout_tweak = animation.wipeout_tweak_148
                                heading_224.onboard_air = category_12 == 200
                                heading_224.preparing_to_jump = events.preparing_52 ~= 0

                                if state.manual_60 == 0 then
                                    heading_224.manual = false
                                else
                                    heading_224.manual = events.intent_51 == 0
                                end

                                heading_224.offboard_air = state_16 == 501
                                heading_224.running_out = animation.running_out_160 ~= 0
                                heading_224.footplant = state_16 == 601
                                heading_224.handplant = state_16 == 600
                                heading_224.hippy_jump = events.hippy_jump_322 ~= 0
                                heading_224.hippy_hurdle = offboard.hurdle_317 ~= 0
                                heading_224.boneless = events.trick_125 ~= 0
                                heading_224.moving_object = state_16 == 502
                                heading_224.skitching = state_16 == 104

                                if events.dropping_in_63 == 0 then
                                    heading_224.dropping_in = false
                                else
                                    heading_224.dropping_in = offboard.dropping_in_334 ~= 0
                                end

                                heading_224.slow_motion_air_duration = air2.scalar_184

                                return p21
                            end
                        end
                    end
                end
            end
        end

        return t1.snapshot(p18, p19, p20)
    end

    player_input = t1.snapshot(p18, p19, p20)

    if not PERF.reference then
        self[player_input] = true
    end

    return player_input
end

return t1
