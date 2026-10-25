-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/foot_ik/blend")
local ContactState = import("skate_core/animation/foot_ik/contact").ContactState
local v2 = import("skate_core/animation/foot_ik/drive")
local v3 = import("skate_core/animation/foot_ik/external")
local ExternalTarget = v3.ExternalTarget
local v4 = import("skate_core/animation/foot_ik/status")
local LimbStatus = v4.LimbStatus
local v5 = import("skate_core/animation/foot_ik/transforms")
local LimbFrames = v5.LimbFrames
local t1 = {
    LIMBS = {
        {
            part = 15,
            parent_part = 16
        },
        {
            part = 19,
            parent_part = 20
        },
        {
            part = 3,
            parent_part = nil
        },
        {
            part = 7,
            parent_part = nil
        }
    }
}
local LIMBS = t1.LIMBS

t1.FootIkState = {}

local FootIkState = t1.FootIkState

function t1.FootIkState.default() -- line: 42
    -- upvalues: rt (copy), ContactState (copy), ExternalTarget (copy), LimbStatus (copy), LimbFrames (copy)
    return {
        feet_enabled = true,
        limbs = rt.filled(4, LimbStatus.default()),
        frames = rt.filled(4, LimbFrames.default()),
        external_targets = rt.filled(4, ExternalTarget.default()),
        contacts = ContactState.default()
    }
end

t1.UpdateInput = {}

function t1.FootIkState.reset(p1) -- line: 74
    -- upvalues: rt (copy), FootIkState (copy)
    rt.assign(p1, FootIkState.default())
end

function t1.FootIkState.enable_feet(p2, p3) -- line: 79
    p2.feet_enabled = p3
end

function t1.FootIkState.feet_enabled(p4) -- line: 83
    return p4.feet_enabled
end

function t1.FootIkState.mark_support_failed_this_update(p5) -- line: 88
    p5.contacts.support_failed_this_update = true
end

function t1.FootIkState.update(p6, p7, p8, p9, p10) -- line: 95
    -- upvalues: rt (copy), v1 (copy), ContactState (copy), v2 (copy), v3 (copy), v4 (copy), v5 (copy), LIMBS (copy)
    for i = 0, 3 do
        p6.frames[i + 1].target = rt.copy(p7.targets[i + 1])
    end

    v4.update_modes(p6.limbs, p6.feet_enabled, p7.flags_2472)
    v4.update_blends(p6.limbs, p9.deck_half_width, p9.deck_total_half_length, p7.flags_2480, p9.blend)

    local v6 = v5.inverse_rigid(p7.animation[1])

    for i = 0, 3 do
        p6.frames[i + 1].within_contact_bounds = false

        local mode = p6.limbs[i + 1].mode

        if mode == "External" or mode == "Local" then
            v3.update(p6.external_targets[i + 1], p6.limbs[i + 1], p6.frames[i + 1], rt.copy(LIMBS[i + 1]), p7.animation, p7.animation_to_world, p7.world_to_animation)
        end

        v5.prepare_animation_target(p6.limbs[i + 1], p6.frames[i + 1], rt.copy(LIMBS[i + 1]), p7.animation, p7.animation_to_world, v6, rt.copy(p9.contact_bounds))
    end

    v1.update(p6.limbs, p6.frames, LIMBS, p7.physical_board, p7.animation_to_world, p7.animation[1])
    ContactState.update(p6.contacts, p6.limbs, p6.frames, {
        flags_2468 = p7.flags_2468,
        contact_bone = p7.contact_bone,
        foot_bones = rt.copy(p7.foot_bones),
        hips_world_position = rt.copy(p7.hips_world_position),
        inverse_board = p7.inverse_contact_board,
        board = p7.contact_board,
        current_contacts = rt.copy(p7.current_contacts)
    })

    return v2.update(p6.limbs, p6.frames, LIMBS, p8, p7.original_animation, p10, p7.world_to_animation, rt.copy(p9.angle_limits))
end

return t1
