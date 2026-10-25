-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/ground_lifecycle")
local Collections = import("skate_data/collections").Collections
local t1 = {}

local function bool_to_u8(p1) -- line: 17
    if p1 then
        return 1
    end

    return 0
end

t1.StatePublication = {}

function t1.publish_fields(p2, p3) -- line: 30
    -- upvalues: rt (copy), bool_to_u8 (copy)
    local off_board = p3.off_board

    off_board.flag_304 = p2.offboard_flag_304 and 1 or 0
    off_board.kind_88 = p2.offboard_kind_88
    off_board.scalar_112 = p2.offboard_scalar_112
    off_board.flag_329 = p2.offboard_flag_329 and 1 or 0
    off_board.flag_330 = p2.offboard_flag_330 and 1 or 0
    off_board.distance_116 = p2.offboard_distance_116
    off_board.flag_334 = p2.offboard_flag_334 and 1 or 0
    off_board.scalar_32 = p2.offboard_scalar_32
    off_board.flag_328 = p2.offboard_flag_328 and 1 or 0
    off_board.flags_306_307 = rt.map(p2.offboard_hand_flags_306_307, bool_to_u8)
    p3.reckoning.vector_144 = rt.map(p2.animation_vector_144, rt.to_bits)
    p3.reckoning.flag_164 = p2.animation_flag_164 and 1 or 0
    p3.state.counter_36 = p2.physics_counter_36
    p3.state.skitch_value_40 = p2.physics_counter_40

    return {
        word_36 = p2.physics_counter_36,
        word_40 = p2.physics_counter_40,
        flag_86 = p2.physics_flag_86
    }
end

function t1.load_collision_settings(p4) -- line: 54
    -- upvalues: Collections (copy)
    local function value(p5) -- line: 55
        -- upvalues: p4 (copy), Collections (copy)
        return Collections.float(p4, "physics_wipeout", "default", p5)
    end

    return {
        vehicle_scalar = Collections.float(p4, "physics_wipeout", "default", "Wipeout_OB_VehicleScalar"),
        vehicle_contact = Collections.float(p4, "physics_wipeout", "default", "Wipeout_OB_VehicleContact"),
        maximum_displacement = Collections.float(p4, "physics_wipeout", "default", "Wipeout_OB_SkeletonMaxDisp"),
        maximum_arm_contact = Collections.float(p4, "physics_wipeout", "default", "Wipeout_OB_SkeletonMaxContactArms"),
        maximum_body_contact = Collections.float(p4, "physics_wipeout", "default", "Wipeout_OB_SkeletonMaxContact"),
        minimum_speed = Collections.float(p4, "physics_wipeout", "default", "Wipeout_OB_MinSpeed"),
        maximum_squash = Collections.float(p4, "physics_wipeout", "default", "Wipeout_OB_MaxSquash"),
        special_scalar = Collections.float(p4, "physics_wipeout", "default", "Hash_472174920C68FBE3")
    }
end

function t1.post(p6, p7) -- line: 74
    -- upvalues: rt (copy), v1 (copy)
    local processed = p6.player_input.processed
    local biped_ground = p6.biped_ground

    v1.post_physics(biped_ground.ground, p6.wipeout.state, biped_ground.collision_settings, {
        collision = p7,
        processed_flags_2484 = processed.flags_2484,
        processed_velocity_608 = rt.map(processed.vectors_544_560_592_608[4], rt.from_bits),
        skeleton_displacement_16288 = rt.copy(p6.collision_extra_errors[1]),
        skeleton_displacement_16304 = rt.copy(p6.collision_extra_errors[2]),
        ground_kind_356 = biped_ground.contact.kind_164
    })
end

function t1.fill(p8, p9) -- line: 91
    -- upvalues: rt (copy), v1 (copy)
    local biped_ground = p8.biped_ground
    local result = biped_ground.result

    if result == nil then
        error("Ground Fill requires completed Ground motion", 0)
    end

    local geometry_adjustment = biped_ground.geometry_adjustment

    if geometry_adjustment == nil then
        error("Ground Fill requires this tick's real geometry consumption", 0)
    end

    local position = geometry_adjustment.frame_768.position

    return v1.publish(biped_ground.ground, {
        ground_flags_752_to_754 = {
            geometry_adjustment.state_752,
            geometry_adjustment.state_753,
            geometry_adjustment.state_754
        },
        contact_flags_368 = biped_ground.contact.flags_176,
        contact_position_192 = rt.copy(biped_ground.contact.position),
        query_position_816 = {
            position.x,
            position.y,
            position.z,
            0
        },
        processed_flags_2476 = p8.player_input.processed.flags_2476,
        ground_kind_356 = biped_ground.contact.kind_164,
        ground_scalar_360 = biped_ground.contact.distance_168,
        motion_vector_1040 = rt.copy(result.velocity),
        motion_up_864 = rt.copy(result.physical_frame[2]),
        hand_flags = rt.map(p9.hands, function(p10) -- line: 112
            return {
                p10.flags_104_to_107[2],
                p10.flags_104_to_107[3],
                p10.flags_104_to_107[4]
            }
        end)
    })
end

return t1
