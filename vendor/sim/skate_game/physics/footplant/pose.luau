-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/trigonometry")
local v2 = import("skate_game/physics/footplant/math")
local STEP, dot, add, sub = v2.STEP, v2.dot, v2.add, v2.sub
local scale, madd, length, point = v2.scale, v2.madd, v2.length, v2.point
local rotate, clamp_length, clamp01 = v2.rotate, v2.clamp_length, v2.clamp01
local t1 = {
    Footplant = {}
}

function t1.Footplant.update_pose(p1, p2, p3, p4, p5) -- line: 32
    -- upvalues: rt (copy), v1 (copy), STEP (copy), dot (copy), add (copy), sub (copy), scale (copy), madd (copy), length (copy), point (copy), rotate (copy), clamp_length (copy), clamp01 (copy)
    local v3 = v1.acos(dot(p1.launch_direction, p1.leg_direction)) * 0.15915493667125702
    local v4 = v3 - math.floor(v3)
    local v5 = (v4 - (if v4 > 0.5 then 1 else 0)) * 6.2831854820251465

    if p1.requested and p1.candidate and p1.contact_time < 0.3 then
        local v6 = length(sub(p1.adjusted_contact, p1.animation_com))
        local v7 = length(sub(p1.selected_world, p1.animation_com))

        if not (v7 < v6) then
            v7 = v6
        end

        local world_to_animation = p3.roots.world_to_animation
        local v8 = point(world_to_animation, p1.animation_com)
        local v9 = rotate(world_to_animation, scale(p2.trajectory.velocity, -STEP))
        local v11 = madd(rotate(world_to_animation, p1.launch_direction), v7, add(v8, v9))

        if p1.lock_valid then
            v11 = add(p1.locked_target, clamp_length(sub(v11, p1.locked_target), 0.15))
        end

        p1.locked_target = rt.copy(v11)
        p1.lock_valid = true

        local v12 = if p1.selected_toe == 15 then 0 else 1

        p4.state.external_targets[v12 + 1].animation_position = v11
        p4.state.limbs[v12 + 1].local_target_set = true
        p4.state.limbs[v12 + 1].target_blend = p1.target_blend
        p1.target_blend = clamp01(p1.target_blend + 0.12)

        if p1.contact_time < 0.2 then
            local t2 = if v12 == 0 then { 15, 16, 17 } else { 19, 20, 21 }

            for _, v13 in t2 do
                p5.pending_reenable = true
                p5.disable_count[v13 + 1] = 2
                p5.parts[v13 + 1].enabled = false
            end
        end
    end

    if p1.requested then
        p1.perform = p1.hit and not (p1.contact_time > 0.017) and v5 < p1.settings.max_leg_angle_error * 0.01745329238474369
    else
        p1.target_blend = 0
        p1.perform = false
    end
end

return t1
