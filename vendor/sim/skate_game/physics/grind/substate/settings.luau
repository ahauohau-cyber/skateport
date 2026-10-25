-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Collections = import("skate_data/collections").Collections

local function grind() -- line: 11
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local t1 = {
    Settings = {}
}

function t1.Settings.load(p1) -- line: 26
    -- upvalues: rt (copy), Collections (copy)
    local function f(p2) -- line: 27
        -- upvalues: p1 (copy), Collections (copy)
        return Collections.float(p1, "physics_collision", "default", p2)
    end

    local v1 = rt.map(Collections.words(p1, "physics_collision", "default", "CollisionTorqueVsAngle", 20), rt.from_bits)
    local v2 = rt.filled(5, rt.filled(3, { 0, 0 }))
    local t2 = {
        "easy",
        "normal",
        "hardcore",
        "motorized",
        "test"
    }
    local t3 = {
        { "Hash_3097A69281990652", "Hash_FA4CDBAE0DFD1FAD" },
        { "Hash_B2B1170AFFC8AC69", "Hash_1B3E9F9C836D287D" },
        { "Hash_703829BD711E54DE", "Hash_F2473E9125079F0" }
    }

    for i = 0, #t2 - 1 do
        local v3 = t2[i + 1]

        for j = 0, #t3 - 1 do
            local v4 = t3[j + 1]
            local v5 = Collections.float(p1, "physics_mode", v3, v4[1])
            local v6 = Collections.float(p1, "physics_mode", v3, v4[2])

            v2[i + 1][j + 1] = { v5, v6 }
        end
    end

    local MaxDeckZAxisYForAnimatedDeck = Collections.float(p1, "physics_animation", "default", "MaxDeckZAxisYForAnimatedDeck")

    return {
        collision = {
            maximum_velocity_delta = Collections.float(p1, "physics_collision", "default", "MaxVelDelta"),
            force_y_offset = Collections.float(p1, "physics_collision", "default", "ForceYOffset"),
            force_scalar = Collections.float(p1, "physics_collision", "default", "CollisionForceScalar"),
            target_displacement_velocity = Collections.float(p1, "physics_collision", "default", "TargetDisplacementVel"),
            torque_vs_angle = {
                x = rt.slice(v1, 4, 12),
                y = rt.slice(v1, 12, 20)
            }
        },
        animated_board_threshold = MaxDeckZAxisYForAnimatedDeck,
        vertical = v2
    }
end

function t1.Settings.vertical(p3, p4, p5, p6) -- line: 68
    -- upvalues: import (copy)
    local Family = import("skate_game/physics/grind").Family
    local v7 = p3.vertical[p5 + 1]

    if v7 == nil then
        error(string.format("Invalid grind jump physics mode %d", p5), 0)
    end

    local v8 = if p4 == Family.Boardslide then 1 elseif p4 == Family.Tipslide then 2 else 0
    local v9 = v7[v8 + 1][1]
    local v10 = v7[v8 + 1][2]

    return (1 - p6) * v9 + v10 * p6
end

function t1.side(p7, p8) -- line: 89
    -- upvalues: import (copy)
    local Family = import("skate_game/physics/grind").Family

    if p7 == Family.Boardslide or p7 == Family.Darkslide then
        if p8 == 2 then
            return 0.8999999761581421
        end

        return 0
    end

    if p7 == Family.Backslash then
        return 0.8999999761581421
    end

    return 0.5
end

return t1
