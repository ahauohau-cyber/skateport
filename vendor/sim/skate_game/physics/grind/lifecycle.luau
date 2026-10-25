-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local SkeletonCollisionMode = import("skate_core/physics/skeleton_body").SkeletonCollisionMode
local t1 = {
    FEET = { 19, 15, 20, 16 }
}
local FEET = t1.FEET

function t1.enter(p1, p2, _, p4) -- line: 23
    -- upvalues: BodyId (copy), BoardRuntime (copy), HookDriveState (copy), FEET (copy)
    local v1 = HookDriveState.disable_animation(BoardRuntime.hook_mut(p1).drive, p2)

    for _, v2 in ipairs(FEET) do
        p4.parts[v2 + 1].volume_group = 4
        p4.parts[v2 + 1].enabled = false
        p4.disable_count[v2 + 1] = 0
    end

    BoardRuntime.bodies_mut(p1)[BodyId.index(BodyId.Deck) + 1].inertia.angular_drag = 3.5999996662139893

    return v1, true
end

function t1.exit(p5, p6, p7, p8, p9) -- line: 42
    -- upvalues: BodyId (copy), BoardRuntime (copy), HookDriveState (copy), SkeletonCollisionMode (copy), t1 (copy), FEET (copy)
    for i = 1, 4 do
        local v3 = FEET[i]
        local v4 = p8[i]

        SkeletonCollisionMode.normal_bone(p7, v3, v4)
    end

    BoardRuntime.bodies_mut(p5)[BodyId.index(BodyId.Deck) + 1].inertia.angular_drag = p9

    local v5 = HookDriveState.disable_animation(BoardRuntime.hook_mut(p5).drive, p6)

    t1.clear_wheel_spin(p5)

    return v5
end

function t1.manage_wheel_spin(p10, p11) -- line: 61
    -- upvalues: BoardRuntime (copy)
    local v6 = BoardRuntime.bodies_mut(p10)

    v6[1].inertia.angular_drag = (p11[1] and 0.5 or 0) * 59.999996185302734
    v6[2].inertia.angular_drag = (p11[2] and 0.5 or 0) * 59.999996185302734
    v6[3].inertia.angular_drag = (p11[3] and 0.5 or 0) * 59.999996185302734
    v6[4].inertia.angular_drag = (p11[4] and 0.5 or 0) * 59.999996185302734
end

function t1.clear_wheel_spin(p12) -- line: 70
    -- upvalues: BoardRuntime (copy)
    local v7 = BoardRuntime.bodies_mut(p12)

    v7[1].inertia.angular_drag = 0
    v7[2].inertia.angular_drag = 0
    v7[3].inertia.angular_drag = 0
    v7[4].inertia.angular_drag = 0
end

return t1
