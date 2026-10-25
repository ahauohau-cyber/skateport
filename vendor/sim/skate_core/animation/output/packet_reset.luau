-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    AdditionalResetFields = {},
    RESET_POSE = {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 0 }
    }
}

function t1.reset(p1, p2) -- line: 50
    -- upvalues: rt (copy), t1 (copy)
    local v2 = math.max(rt.to_i32(p1.bone_count), 0)

    if #p1.hierarchy < v2 or #p1["local"] < v2 then
        error({
            tag = "RangeOutsideAllocation"
        }, 0)
    end

    p1.timestep = 0.01666666753590107
    p2.external_impulse_active = false
    p2.compression = 0.5
    p2.foot_ik_influence[1] = 0
    p2.external_physics_input_active = false
    p2.foot_ik_influence[2] = 0
    p2.externally_controlled = false
    p2.truck_tightness = 0
    p1.mirrored = false
    p1.riding_switch = false
    p1.riding_fakie = false
    p1.weight_forwards = false
    p1.regular_stance = false
    p2.prevent_manual_respawn = false
    p2.ignore_respawn_reset_button = 0
    p2.force_braking = false
    p1.air_dismount_revert_frames = 0
    p1.board_flipped = false
    p2.next_step_position_valid = false
    p2.actor_flag_1904_bit23 = false
    p1.flags = bit32.band(p1.flags, 20971519)
    p2.actor_flag_1908_bit2 = false
    p1.foot_surface_ids[1] = 0
    p2.wheel_hardness = 0
    p1.foot_surface_ids[2] = 0
    p2.auxiliary_vectors[1] = { 0, 0, 0, 0 }
    p2.requested_physics_mode = 1

    for i = 1, 5 do
        p2.auxiliary_vectors[i + 1] = { 0, 0, 0, 0 }
    end

    for i = 0, v2 - 1 do
        p1["local"][i + 1] = rt.copy(t1.RESET_POSE)
        p1.hierarchy[i + 1] = rt.copy(t1.RESET_POSE)
    end
end

function t1.reset_without_pose(p3, p4) -- line: 99
    -- upvalues: rt (copy)
    local v4 = math.max(rt.to_i32(p3.bone_count), 0)

    if #p3.hierarchy < v4 or #p3["local"] < v4 then
        error({
            tag = "RangeOutsideAllocation"
        }, 0)
    end

    p3.timestep = 0.01666666753590107
    p4.external_impulse_active = false
    p4.compression = 0.5
    p4.foot_ik_influence[1] = 0
    p4.external_physics_input_active = false
    p4.foot_ik_influence[2] = 0
    p4.externally_controlled = false
    p4.truck_tightness = 0
    p3.mirrored = false
    p3.riding_switch = false
    p3.riding_fakie = false
    p3.weight_forwards = false
    p3.regular_stance = false
    p4.prevent_manual_respawn = false
    p4.ignore_respawn_reset_button = 0
    p4.force_braking = false
    p3.air_dismount_revert_frames = 0
    p3.board_flipped = false
    p4.next_step_position_valid = false
    p4.actor_flag_1904_bit23 = false
    p3.flags = bit32.band(p3.flags, 20971519)
    p4.actor_flag_1908_bit2 = false
    p3.foot_surface_ids[1] = 0
    p4.wheel_hardness = 0
    p3.foot_surface_ids[2] = 0
    p4.auxiliary_vectors[1] = { 0, 0, 0, 0 }
    p4.requested_physics_mode = 1

    for i = 1, 5 do
        p4.auxiliary_vectors[i + 1] = { 0, 0, 0, 0 }
    end
end

return t1
