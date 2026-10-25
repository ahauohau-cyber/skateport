-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_core/animation/kickturn")
local encode = import("skate_core/animation/skeleton_input/name").encode
local Collections = import("skate_data/collections").Collections
local Attributes = import("skate_data/state_graph/attributes").Attributes
local v3

local function motion_animation() -- line: 26
    -- upvalues: import (copy), v3 (ref)
    local v4 = v3

    if v4 == nil then
        v4 = import("skate_game/graph_host/motion_animation")
        v3 = v4
    end

    return v4
end

local t1 = {
    Operation = {}
}

function t1.Operation.parse(p2) -- line: 42
    -- upvalues: v1 (copy), Attributes (copy)
    local name = Attributes.text(p2, "name")

    if name == nil then
        return nil
    end

    if name == "ResetTimeSinceKickturn" then
        return {
            tag = "ResetTimer"
        }
    end

    if name ~= "KickTurnSteering" then
        return nil
    end

    local t3 = {}

    buffer.writeu32(v1, 0, (Attributes.float_bits(p2, "maxHeight", 1056964608)))
    t3.max_height = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, (Attributes.float_bits(p2, "spinScale", 1056964608)))
    t3.spin_scale = buffer.readf32(v1, 0)

    return {
        tag = "Steering",
        t3
    }
end

function t1.load_settings(p3) -- line: 64
    -- upvalues: v1 (copy), Collections (copy)
    local function curve(p4) -- line: 67
        -- upvalues: p3 (copy), v1 (copy), Collections (copy)
        local v7 = Collections.words(p3, "anim_motion", "kickturn", p4, 20)
        local t4 = {}

        buffer.writeu32(v1, 0, v7[5])

        local v9 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[6])

        local v11 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[7])

        local v13 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[8])

        local v15 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[9])

        local v17 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[10])

        local v19 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[11])

        local v21 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[12])
        t4.x = {
            v9,
            v11,
            v13,
            v15,
            v17,
            v19,
            v21,
            (buffer.readf32(v1, 0))
        }
        buffer.writeu32(v1, 0, v7[13])

        local v24 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[14])

        local v26 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[15])

        local v28 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[16])

        local v30 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[17])

        local v32 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[18])

        local v34 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[19])

        local v36 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v7[20])
        t4.y = {
            v24,
            v26,
            v28,
            v30,
            v32,
            v34,
            v36,
            (buffer.readf32(v1, 0))
        }

        return t4
    end

    return {
        spin = curve("kickturn_spin"),
        height = curve("kickturn_balance")
    }
end

function t1.execute(p5, p6, p7, p8, p9, p10) -- line: 102
    -- upvalues: rt (copy), import (copy), v2 (copy), encode (copy), v3 (ref)
    if p10 == 0 then
        v2.State.begin(p5, p7)
    elseif p10 == 1 then
        local v38 = v3

        if v38 == nil then
            v38 = import("skate_game/graph_host/motion_animation")
            v3 = v38
        end

        local MotionAnimation = v38.MotionAnimation

        if v2.State.needs_animation_length(p5) then
            MotionAnimation.apply_parameters(p8)
            v2.State.capture_animation_length(p5, MotionAnimation.current_length(p8))
        end

        local KickTurn = MotionAnimation.motion_intent(p8, "KickTurn")

        if KickTurn == nil then
            KickTurn = 0
        end

        local v39 = v2.State.update(p5, p9, KickTurn, rt.copy(p6), p7)

        MotionAnimation.emit_packet(p8, encode("Balance"), v39.balance)
        MotionAnimation.emit_packet(p8, encode("Spin"), v39.spin)
    end
end

return t1
