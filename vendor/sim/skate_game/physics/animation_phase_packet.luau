-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local RESET_POSE = import("skate_core/animation/output/packet_reset").RESET_POSE
local Collections = import("skate_data/collections").Collections
local t1 = {}

local function u8_from(p1) -- line: 14
    if p1 then
        return 1
    end

    return 0
end

local function reset_pose_bits() -- line: 19
    -- upvalues: rt (copy), RESET_POSE (copy)
    local t2 = {}

    for v1, v2 in RESET_POSE do
        t2[v1] = rt.map(v2, rt.to_bits)
    end

    return t2
end

local v3 = false
local v4 = reset_pose_bits()

local function inactive_vector() -- line: 39
    return table.freeze(table.create(4, 0))
end

local v5 = table.freeze({
    flags = 0,
    vectors = table.freeze({
        table.freeze(table.create(4, 0)),
        table.freeze(table.create(4, 0)),
        table.freeze(table.create(4, 0)),
        table.freeze(table.create(4, 0)),
        table.freeze(table.create(4, 0)),
        table.freeze(table.create(4, 0)),
        table.freeze(table.create(4, 0)),
        table.freeze(table.create(4, 0)),
        table.freeze(table.create(4, 0)),
        inactive_vector()
    })
})

t1.AnimationProfile = {}

function t1.AnimationProfile.load(p2, p3) -- line: 68
    -- upvalues: Collections (copy)
    local v6

    for v7, v8 in { "easy", "normal", "hardcore", "motorized", "test" } do
        if v8 == p3 then
            v6 = v7 - 1
            break
        end
    end

    if v6 == nil then
        error(string.format("Undefined player physics profile %s", p3), 0)
    end

    return {
        skitch_transition_time = Collections.float(p2, "anim_skitching", "default", "LongSkitchIntoReachTime"),
        maximum_ground_angle_degrees = Collections.float(p2, "anim_motion", "pushing", "disable_push_brake_at_slope"),
        truck_tightness = 0.699999988079071,
        wheel_hardness = 0.699999988079071,
        physics_mode = v6,
        prevent_manual_respawn = false,
        ignore_respawn_reset_button = 0,
        force_braking = false,
        suppress_transition = false,
        gesture_selections = { 0, 1, 2, 3 },
        suppress_up_gesture = false,
        gesture_force_brake_bypass = false
    }
end

t1.AnimationPhaseOutput = {}

function t1.AnimationPhaseOutput.new_reference() -- line: 109
    -- upvalues: rt (copy), reset_pose_bits (copy)
    return {
        mirrored = 0,
        weight_forwards = 0,
        flags = 0,
        reset = {
            compression = 0,
            next_step_position_valid = false,
            actor_flag_1904_bit23 = false,
            actor_flag_1908_bit2 = false,
            external_impulse_active = false,
            external_physics_input_active = false,
            externally_controlled = false,
            prevent_manual_respawn = false,
            ignore_respawn_reset_button = 0,
            force_braking = false,
            truck_tightness = 0,
            wheel_hardness = 0,
            requested_physics_mode = 1,
            foot_ik_influence = table.create(2, 0),
            auxiliary_vectors = rt.filled(6, table.create(4, 0))
        },
        publication = {
            stance_byte = 0,
            timestep = 0,
            scalar_10388 = 0,
            byte_10768 = 0,
            truck_tightness = 0,
            scalar_10792 = 0,
            flag_10371 = 0,
            flags_10375_10496_10784 = table.create(3, 0),
            vector_10480 = table.create(4, 0),
            matrix_10704 = reset_pose_bits()
        },
        external = {
            flags = 0,
            vectors = rt.filled(10, table.create(4, 0))
        }
    }
end

function t1.AnimationPhaseOutput.new() -- line: 154
    -- upvalues: rt (copy), t1 (copy), reset_pose_bits (copy), v3 (ref), v5 (copy)
    if v3 then
        return t1.AnimationPhaseOutput.new_reference()
    end

    return {
        mirrored = 0,
        weight_forwards = 0,
        flags = 0,
        reset = {
            compression = 0,
            next_step_position_valid = false,
            actor_flag_1904_bit23 = false,
            actor_flag_1908_bit2 = false,
            external_impulse_active = false,
            external_physics_input_active = false,
            externally_controlled = false,
            prevent_manual_respawn = false,
            ignore_respawn_reset_button = 0,
            force_braking = false,
            truck_tightness = 0,
            wheel_hardness = 0,
            requested_physics_mode = 1,
            foot_ik_influence = table.create(2, 0),
            auxiliary_vectors = rt.filled(6, table.create(4, 0))
        },
        publication = {
            stance_byte = 0,
            timestep = 0,
            scalar_10388 = 0,
            byte_10768 = 0,
            truck_tightness = 0,
            scalar_10792 = 0,
            flag_10371 = 0,
            flags_10375_10496_10784 = table.create(3, 0),
            vector_10480 = table.create(4, 0),
            matrix_10704 = reset_pose_bits()
        },
        external = v5
    }
end

function t1.AnimationPhaseOutput.publish(p4, p5, p6, p7) -- line: 205
    -- upvalues: t1 (copy), v3 (ref), v4 (copy)
    if v3 then
        return t1.AnimationPhaseOutput.publish_reference(p4, p5, p6, p7)
    end

    local publication = p4.publication
    local v9 = type(publication) == "table"
    local v10, flags_10375_10496_10784, vector_10480, matrix_10704

    if v9 then
        local flags_10375_10496_10784_2, vector_10480_2, matrix_10704_2 = publication.flags_10375_10496_10784, publication.vector_10480, publication.matrix_10704
        local v11 = type(flags_10375_10496_10784_2) == "table" and #flags_10375_10496_10784_2 == 3 and type(vector_10480_2) == "table" and #vector_10480_2 == 4 and type(matrix_10704_2) == "table" and #matrix_10704_2 == #v4

        flags_10375_10496_10784 = flags_10375_10496_10784_2
        vector_10480 = vector_10480_2
        matrix_10704 = matrix_10704_2
        v10 = v11

        if v11 then
            for v12, v13 in v4 do
                local v14 = matrix_10704_2[v12]

                if type(v14) ~= "table" then
                    flags_10375_10496_10784 = flags_10375_10496_10784_2
                    vector_10480 = vector_10480_2
                    matrix_10704 = matrix_10704_2
                    v10 = false
                    break
                end

                if #v14 ~= #v13 then
                    flags_10375_10496_10784 = flags_10375_10496_10784_2
                    vector_10480 = vector_10480_2
                    matrix_10704 = matrix_10704_2
                    v10 = false
                    break
                end

                v10 = v11
                flags_10375_10496_10784 = flags_10375_10496_10784_2
                vector_10480 = vector_10480_2
                matrix_10704 = matrix_10704_2
            end
        end
    else
        v10 = v9
    end

    if not v10 then
        return t1.AnimationPhaseOutput.publish_reference(p4, p5, p6, p7)
    end

    local reset = p4.reset

    reset.actor_flag_1904_bit23 = false
    reset.actor_flag_1908_bit2 = p6.suppress_transition or bit32.band(p7, 4) ~= 0
    reset.truck_tightness = p6.truck_tightness
    reset.wheel_hardness = p6.wheel_hardness
    reset.requested_physics_mode = p6.physics_mode
    reset.prevent_manual_respawn = p6.prevent_manual_respawn
    reset.ignore_respawn_reset_button = p6.ignore_respawn_reset_button
    reset.force_braking = p6.force_braking
    p4.flags = bit32.band(p5.flags, 4273995775)
    p4.mirrored = p5.mirrored and 1 or 0
    p4.weight_forwards = p5.weight_forwards and 1 or 0
    publication.stance_byte = p5.board_flipped and 1 or 0
    publication.timestep = p5.timestep
    publication.scalar_10388 = reset.compression
    flags_10375_10496_10784[1] = reset.actor_flag_1904_bit23 and 1 or 0
    flags_10375_10496_10784[2] = 0
    flags_10375_10496_10784[3] = 0
    vector_10480[1] = 0
    vector_10480[2] = 0
    vector_10480[3] = 0
    vector_10480[4] = 0

    for v15, v16 in v4 do
        local v17 = matrix_10704[v15]

        for v18, v19 in v16 do
            v17[v18] = v19
        end
    end

    publication.byte_10768 = 0
    publication.truck_tightness = reset.truck_tightness
    publication.scalar_10792 = reset.wheel_hardness
    publication.flag_10371 = p5.riding_switch and 1 or 0
end

function t1.AnimationPhaseOutput.publish_reference(p8, p9, p10, p11) -- line: 270
    -- upvalues: reset_pose_bits (copy)
    local reset = p8.reset

    reset.actor_flag_1904_bit23 = false
    reset.actor_flag_1908_bit2 = p10.suppress_transition or bit32.band(p11, 4) ~= 0
    reset.truck_tightness = p10.truck_tightness
    reset.wheel_hardness = p10.wheel_hardness
    reset.requested_physics_mode = p10.physics_mode
    reset.prevent_manual_respawn = p10.prevent_manual_respawn
    reset.ignore_respawn_reset_button = p10.ignore_respawn_reset_button
    reset.force_braking = p10.force_braking
    p8.flags = bit32.band(p9.flags, 4273995775)
    p8.mirrored = p9.mirrored and 1 or 0
    p8.weight_forwards = p9.weight_forwards and 1 or 0
    p8.publication = {
        byte_10768 = 0,
        stance_byte = p9.board_flipped and 1 or 0,
        timestep = p9.timestep,
        scalar_10388 = reset.compression,
        flags_10375_10496_10784 = {
            reset.actor_flag_1904_bit23 and 1 or 0,
            0, 0
        },
        vector_10480 = table.create(4, 0),
        matrix_10704 = reset_pose_bits(),
        truck_tightness = reset.truck_tightness,
        scalar_10792 = reset.wheel_hardness,
        flag_10371 = p9.riding_switch and 1 or 0
    }
end

function t1.AnimationPhaseOutput.publish_external_reset(p12, p13) -- line: 306
    -- upvalues: rt (copy)
    p12.publication.matrix_10704 = rt.copy(p13.transform)
    p12.publication.byte_10768 = p13.byte64
    p12.publication.flags_10375_10496_10784[3] = 1
end

function t1.AnimationPhaseOutput.packet(p14) -- line: 313
    -- upvalues: rt (copy)
    local reset = p14.reset
    local t5 = {}

    for v20, v21 in reset.auxiliary_vectors do
        t5[v20] = rt.map(v21, rt.to_bits)
    end

    return {
        use_external_physics_10688 = 0,
        external_physics_flag_10689 = 0,
        publication = p14.publication,
        external_physics_10512 = p14.external,
        flag_10369 = reset.next_step_position_valid and 1 or 0,
        flag_10370 = p14.mirrored,
        flag_10373 = p14.weight_forwards,
        suppress_transition_10376 = reset.actor_flag_1908_bit2 and 1 or 0,
        flag_10786 = reset.prevent_manual_respawn and 1 or 0,
        flag_10787 = reset.ignore_respawn_reset_button,
        force_braking_10796 = reset.force_braking and 1 or 0,
        vector_10816 = t5[1],
        vector_10832 = t5[2],
        vector_10848 = t5[3],
        vector_10864 = t5[4],
        vector_10880 = t5[5],
        vector_10896 = t5[6],
        scalar_10912 = reset.foot_ik_influence[1],
        scalar_10916 = reset.foot_ik_influence[2],
        state_variant_10928 = reset.requested_physics_mode,
        flags_10932 = p14.flags
    }
end

local t7 = {}
local t8 = {
    {},
    {},
    {},
    {},
    {},
    {}
}
local t9 = {
    "vector_10816",
    "vector_10832",
    "vector_10848",
    "vector_10864",
    "vector_10880",
    "vector_10896"
}
local to_bits = rt.to_bits

function t1.AnimationPhaseOutput.packet_view(p15) -- line: 358
    -- upvalues: t1 (copy), v3 (ref), t7 (copy), t8 (copy), t9 (copy), to_bits (copy)
    if v3 then
        return t1.AnimationPhaseOutput.packet(p15)
    end

    local reset = p15.reset
    local auxiliary_vectors = reset.auxiliary_vectors

    if #auxiliary_vectors > 6 then
        return t1.AnimationPhaseOutput.packet(p15)
    end

    for i = 1, 6 do
        local v22 = auxiliary_vectors[i]

        if type(v22) == "table" then
            local v23 = t8[i]
            local v24 = #v22

            for j = 1, v24 do
                v23[j] = to_bits(v22[j])
            end

            for k = #v23, v24 + 1, -1 do
                v23[k] = nil
            end

            t7[t9[i]] = v23
        else
            if v22 ~= nil then
                return t1.AnimationPhaseOutput.packet(p15)
            end

            t7[t9[i]] = nil
        end
    end

    t7.publication = p15.publication
    t7.external_physics_10512 = p15.external
    t7.flag_10369 = reset.next_step_position_valid and 1 or 0
    t7.flag_10370 = p15.mirrored
    t7.flag_10373 = p15.weight_forwards
    t7.suppress_transition_10376 = reset.actor_flag_1908_bit2 and 1 or 0
    t7.use_external_physics_10688 = 0
    t7.external_physics_flag_10689 = 0
    t7.flag_10786 = reset.prevent_manual_respawn and 1 or 0
    t7.flag_10787 = reset.ignore_respawn_reset_button
    t7.force_braking_10796 = reset.force_braking and 1 or 0
    t7.scalar_10912 = reset.foot_ik_influence[1]
    t7.scalar_10916 = reset.foot_ik_influence[2]
    t7.state_variant_10928 = reset.requested_physics_mode
    t7.flags_10932 = p15.flags

    return t7
end

function t1.set_reference(p16) -- line: 405
    -- upvalues: v3 (ref)
    v3 = p16
end

return t1
