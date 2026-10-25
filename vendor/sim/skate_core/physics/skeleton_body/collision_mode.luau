-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local world_inverse_inertia = import("skate_core/physics/rigid_body").world_inverse_inertia

local function skeleton_body() -- line: 11
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body")
end

local t1 = {
    SkeletonCollisionSettings = {},
    SkeletonPartCollision = {},
    SkeletonCollisionMode = {}
}
local SkeletonCollisionMode = t1.SkeletonCollisionMode

function t1.SkeletonCollisionMode.disable_handplant_contacts(p1, p2) -- line: 44
    p1.pending_reenable = true

    for _, v1 in { 7, 3, 8, 4, 1 } do
        p1.disable_count[v1 + 1] = p2
        p1.parts[v1 + 1].enabled = false
    end
end

function t1.SkeletonCollisionMode.reset_body_state(p3, p4) -- line: 54
    -- upvalues: import (copy)
    local v2 = import("skate_core/physics/skeleton_body")

    p3.is_ragdoll = false
    v2.SkeletonCollisionFeedback.reset(p4)
    p3.disable_count = table.create(v2.ANIMATION_PART_COUNT, 0)
    p3.pending_reenable = false
end

function t1.SkeletonCollisionMode.new_normal(p5, p6) -- line: 64
    -- upvalues: rt (copy), import (copy), SkeletonCollisionMode (copy)
    local v3 = import("skate_core/physics/skeleton_body")
    local PART_COUNT, ANIMATION_PART_COUNT = v3.PART_COUNT, v3.ANIMATION_PART_COUNT
    local t2 = {
        static_friction = 0,
        dynamic_friction = 0,
        restitution = 0
    }
    local t3 = {
        pending_reenable = false,
        assembly_group = 5,
        partial_ragdoll = false,
        is_ragdoll = false,
        parts = rt.from_fn(PART_COUNT, function(p7) -- line: 75
            -- upvalues: p5 (copy), t2 (copy), rt (copy)
            return {
                enabled = false,
                part_group = 5,
                volume_group = p7 == 0 and 4 or 0,
                material = if not (p7 >= 1 and p7 < 24) then rt.copy(t2) else rt.copy(p5.normal_material)
            }
        end),
        disable_count = table.create(ANIMATION_PART_COUNT, 0),
        settings = rt.copy(p5),
        self_culling = rt.filled(PART_COUNT, table.create(PART_COUNT, true)),
        normal_self_culling = rt.filled(PART_COUNT, table.create(PART_COUNT, true))
    }

    if not p6 then
        for _, v4 in {
                { 14, 4 },
                { 14, 8 },
                { 23, 4 },
                { 23, 8 },
                { 4, 18 },
                { 8, 22 }
            } do
            local v5 = v4[1]
            local v6 = v4[2]

            t3.self_culling[v5 + 1][v6 + 1] = false
            t3.self_culling[v6 + 1][v5 + 1] = false
        end
    end

    if p5.enabled then
        SkeletonCollisionMode.normal_collision(t3)
    else
        SkeletonCollisionMode.disable_all(t3, true)
    end

    t3.normal_self_culling = rt.copy(t3.self_culling)

    return t3
end

function t1.SkeletonCollisionMode.select_driven(p8, p9) -- line: 111
    -- upvalues: SkeletonCollisionMode (copy)
    if p9 == 3 then
        SkeletonCollisionMode.select_biped(p8)
    else
        if p9 == 5 or p9 == 6 then
            SkeletonCollisionMode.normal_collision(p8)
        elseif p9 == 1 then
            SkeletonCollisionMode.enable_eligible_bones(p8)
            SkeletonCollisionMode.set_group(p8, 3)
        else
            error("Skeleton collision selector requires its non-driven physical setup", 0)
        end

        p8.partial_ragdoll = false
        SkeletonCollisionMode.disable_root(p8)
        p8.parts[25].enabled = false
        p8.parts[26].enabled = false
    end
end

function t1.SkeletonCollisionMode.normal_collision(p10) -- line: 132
    -- upvalues: SkeletonCollisionMode (copy)
    SkeletonCollisionMode.set_group(p10, 5)
    SkeletonCollisionMode.disable_root(p10)
    SkeletonCollisionMode.enable_eligible_bones(p10)
end

function t1.SkeletonCollisionMode.disable_all(p11, p12) -- line: 139
    -- upvalues: SkeletonCollisionMode (copy)
    SkeletonCollisionMode.disable_root(p11)
    p11.parts[25].enabled = false
    p11.parts[26].enabled = false

    for i = 1, 23 do
        p11.parts[i + 1].enabled = false

        if p12 then
            p11.disable_count[i + 1] = 0
        end
    end
end

function t1.SkeletonCollisionMode.enable_bone(p13, p14) -- line: 152
    if p13.disable_count[p14 + 1] == 0 then
        p13.parts[p14 + 1].enabled = true
        p13.parts[p14 + 1].volume_group = 0
    end

    p13.parts[p14 + 1].part_group = 5
end

function t1.SkeletonCollisionMode.finish_contact_frame(p15) -- line: 162
    -- upvalues: rt (copy), import (copy)
    if p15.pending_reenable then
        local v7 = import("skate_core/physics/skeleton_body").ANIMATION_PART_COUNT - 1
        local v8 = false

        for i = 0, v7 do
            if rt.to_i32(p15.disable_count[i + 1]) > 0 then
                p15.disable_count[i + 1] -= 1

                local v9 = p15.disable_count[i + 1] == 0

                p15.parts[i + 1].enabled = v9
                v8 = v8 or not v9
            end
        end

        p15.pending_reenable = v8
    end
end

function t1.SkeletonCollisionMode.normal_bone(p16, p17, p18) -- line: 180
    local v10

    if p18 then
        v10 = p16.disable_count[p17 + 1] == 0
    else
        p16.parts[p17 + 1].enabled = false
        p16.parts[p17 + 1].volume_group = 4
        p16.disable_count[p17 + 1] = 0
    end

    if (not p18 or v10) and p18 then
        p16.parts[p17 + 1].enabled = true
        p16.parts[p17 + 1].volume_group = 0
    end
end

function t1.SkeletonCollisionMode.restore_normal_properties(p19, p20) -- line: 196
    -- upvalues: rt (copy), import (copy), world_inverse_inertia (copy), SkeletonCollisionMode (copy)
    local v11 = import("skate_core/physics/skeleton_body")
    local PART_COUNT, SkeletonBody = v11.PART_COUNT, v11.SkeletonBody

    p19.self_culling = rt.copy(p19.normal_self_culling)
    SkeletonCollisionMode.set_group(p19, 5)

    for i = 0, PART_COUNT - 1 do
        local v12 = rt.copy(p20.definition.parts[i + 1])
        local v13 = SkeletonBody.bodies_mut(p20)[i + 1]

        v13.inertia.linear_drag = 0
        v13.inertia.angular_drag = 0

        if i >= 1 and i < 24 then
            v13.inertia.inverse_mass = v12.inverse_mass_animated
            v13.inertia.inverse_tensor = rt.copy(v12.animated.dynamics.inverse_tensor)

            local v14 = rt.copy(v13.inertia.inverse_tensor)
            local x = v14.x

            if v14.y <= x then
                x = v14.y
            end

            local v15 = if v14.z <= x then v14.z else x

            v13.inertia.spherical = 1 / v15
            v13.rates.world_inverse_inertia = world_inverse_inertia(v13.rates.basis, v14)
            p19.parts[i + 1].material = rt.copy(p19.settings.normal_material)
        end
    end

    if p19.settings.enabled then
        SkeletonCollisionMode.normal_collision(p19)
    else
        SkeletonCollisionMode.disable_all(p19, true)
    end

    p19.is_ragdoll = false
end

local t5 = {
    67108863, 67105863, 67107911, 60523641, 62620793, 60785785, 67108863, 62490561,
    62621633, 66684865, 67108863, 67107909, 67107911, 67107911, 67107911, 67108863,
    59768831, 59768191, 63962215, 67108863, 66650111, 66650071, 66911815, 67108863,
    67108863, 67108863
}

function t1.SkeletonCollisionMode.apply_ragdoll_properties(p21, p22, p23, p24, p25, p26) -- line: 263
    -- upvalues: rt (copy), import (copy), world_inverse_inertia (copy), SkeletonCollisionMode (copy), t5 (copy)
    local v16 = import("skate_core/physics/skeleton_body")
    local PART_COUNT, SkeletonBody = v16.PART_COUNT, v16.SkeletonBody
    local v17 = true

    for i = 1, PART_COUNT do
        local v18 = p21.normal_self_culling[i]

        for j = 1, PART_COUNT do
            if not v18[j] then
                v17 = false
                break
            end
        end

        if not v17 then
            break
        end
    end

    if v17 then
        p21.self_culling = rt.filled(PART_COUNT, table.create(PART_COUNT, true))
    else
        p21.self_culling = rt.from_fn(PART_COUNT, function(p27) -- line: 291
            -- upvalues: PART_COUNT (copy), rt (copy), t5 (copy)
            return rt.from_fn(PART_COUNT, function(p28) -- line: 292
                -- upvalues: p27 (copy), t5 (copy)
                return bit32.band(t5[p27 + 1], (bit32.lshift(1, p28))) ~= 0
            end)
        end)
    end

    SkeletonCollisionMode.set_group(p21, 6)

    for _, v21 in ipairs(SkeletonBody.bodies_mut(p22)) do
        v21.inertia.linear_drag = p25[1]
        v21.inertia.angular_drag = p25[2]
    end

    for i = 1, 23 do
        local v22 = rt.copy(p22.definition.parts[i + 1])
        local v23 = SkeletonBody.bodies_mut(p22)[i + 1]

        p21.disable_count[i + 1] = 0
        p21.parts[i + 1].enabled = true
        p21.pending_reenable = false

        local v24 = i ~= 1 and i ~= 3 and i ~= 7 and 0 or 1

        p21.parts[i + 1].material = rt.copy(p26[v24 + 1])

        if p23 then
            v23.inertia.inverse_mass = v22.inverse_mass_ragdoll
        end

        if p24 then
            local v25 = rt.copy(v22.ragdoll.dynamics.inverse_tensor)

            v23.inertia.inverse_tensor = rt.copy(v25)

            local x = v25.x

            if v25.y <= x then
                x = v25.y
            end

            local v26 = if v25.z <= x then v25.z else x

            v23.inertia.spherical = 1 / v26
        end

        v23.rates.world_inverse_inertia = world_inverse_inertia(v23.rates.basis, v23.inertia.inverse_tensor)
    end

    p21.is_ragdoll = true
end

function t1.SkeletonCollisionMode.finish_ragdoll_request(p29, p30) -- line: 331
    -- upvalues: SkeletonCollisionMode (copy)
    if p30 == 7 or p30 == 10 then
        p29.partial_ragdoll = false
        SkeletonCollisionMode.disable_root(p29)
        p29.parts[25].enabled = false
        p29.parts[26].enabled = false
    elseif p30 == 8 then
        for i = 1, 23 do
            p29.parts[i + 1].material = {
                static_friction = 0.5,
                dynamic_friction = 0.3,
                restitution = 0.4
            }
        end
    elseif p30 == 9 then
        SkeletonCollisionMode.set_group(p29, 7)
    else
        error("internal error: entered unreachable code: Only original Wipeout requests8..11 enter this adapter", 0)
    end
end

function t1.SkeletonCollisionMode.set_group(p31, p32) -- line: 354
    p31.assembly_group = p32

    for _, v27 in ipairs(p31.parts) do
        v27.part_group = p32
    end
end

function t1.SkeletonCollisionMode.select_biped(p33) -- line: 363
    -- upvalues: SkeletonCollisionMode (copy)
    SkeletonCollisionMode.set_group(p33, 6)
    SkeletonCollisionMode.disable_all(p33, false)

    for _, v28 in { 17, 21, 15, 19, 16, 20 } do
        SkeletonCollisionMode.enable_bone(p33, v28)
        p33.parts[v28 + 1].part_group = 17
    end

    for _, v29 in { 5, 4, 3, 9, 8, 7, 2, 1 } do
        SkeletonCollisionMode.enable_bone(p33, v29)
    end

    for _, v30 in { 6, 10, 11, 12, 13, 14, 23 } do
        SkeletonCollisionMode.enable_bone(p33, v30)
        p33.parts[v30 + 1].part_group = 18
    end

    p33.partial_ragdoll = true

    for _, v31 in { 24, 25 } do
        p33.parts[v31 + 1].part_group = 20
        p33.parts[v31 + 1].enabled = true
    end
end

function t1.SkeletonCollisionMode.disable_root(p34) -- line: 384
    p34.parts[1].volume_group = 4
    p34.parts[1].enabled = false
    p34.disable_count[1] = 0
end

function t1.SkeletonCollisionMode.enable_eligible_bones(p35) -- line: 390
    for i = 1, 23 do
        if p35.disable_count[i + 1] == 0 then
            p35.parts[i + 1].enabled = true
            p35.parts[i + 1].volume_group = 0
        end
    end
end

return t1
