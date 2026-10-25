-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local encode = import("skate_core/animation/skeleton_input/name").encode
local Attributes = import("skate_data/state_graph/attributes").Attributes
local v8 = import("skate_core/input/angle")
local v9

local function motion_animation() -- line: 43
    -- upvalues: import (copy), v9 (ref)
    local v10 = v9

    if v10 == nil then
        v10 = import("skate_game/graph_host/motion_animation")
        v9 = v10
    end

    return v10
end

local v11

local function motion_channels() -- line: 52
    -- upvalues: import (copy), v11 (ref)
    local v12 = v11

    if v12 == nil then
        v12 = import("skate_game/graph_host/motion_channels")
        v11 = v12
    end

    return v12
end

local t1 = {
    ShoveOperation = {}
}

function t1.ShoveOperation.parse(p4) -- line: 67
    -- upvalues: Attributes (copy)
    if Attributes.text(p4, "name") ~= "Shove" then
        return nil
    end

    local Selection = Attributes.text(p4, "Selection")

    if Selection == nil then
        error("Shove requires Selection", 0)
    end

    local SelectionBrd = Attributes.text(p4, "SelectionBrd")

    if SelectionBrd == nil then
        SelectionBrd = ""
    end

    local Antic = Attributes.text(p4, "Antic")

    if Antic == nil then
        error("Shove requires Antic", 0)
    end

    local AnticBrd = Attributes.text(p4, "AnticBrd")

    if AnticBrd == nil then
        AnticBrd = ""
    end

    return {
        selection = Selection,
        selection_board = SelectionBrd,
        anticipation = Antic,
        anticipation_board = AnticBrd
    }
end

t1.ShovePhysical = {}
t1.ShoveState = {}

function t1.ShoveState.new() -- line: 112
    return {
        angle = 0,
        board_anticipation = false
    }
end

function t1.ShoveState.begin(p5) -- line: 119
    p5.angle = 0
    p5.board_anticipation = false
end

function t1.ShoveState.update(p6, p7, p8, p9, p10, p11) -- line: 127
    -- upvalues: import (copy), v9 (ref), v11 (ref), t1 (copy)
    local v13 = v9

    if v13 == nil then
        v13 = import("skate_game/graph_host/motion_animation")
        v9 = v13
    end

    local MotionAnimation = v13.MotionAnimation
    local v14 = v11

    if v14 == nil then
        v14 = import("skate_game/graph_host/motion_channels")
        v11 = v14
    end

    local MotionChannels = v14.MotionChannels
    local RetrieveBoard = MotionChannels.has(p8.channels, "RetrieveBoard")
    local v15 = p9.in_biped_category and p9.board_on_ground

    if MotionAnimation.motion_intent(p8, "GrabWorld") ~= nil and not RetrieveBoard and p10[1] == 0 and p10[2] == 0 then
        if not (MotionChannels.has(p8.channels, "SkitchAntic") or MotionChannels.has(p8.channels, "Shove")) then
            p6.board_anticipation = v15
            t1.start_channel(p8, "SkitchAntic", if v15 then p7.anticipation_board else p7.anticipation, true)
        end
    elseif MotionChannels.has(p8.channels, "SkitchAntic") then
        MotionChannels["end"](p8.channels, "SkitchAntic")
    end

    local Shove = MotionChannels.has(p8.channels, "Shove")

    if not p9.interaction_trigger or RetrieveBoard then
        if Shove then
            if RetrieveBoard then
                MotionChannels["end"](p8.channels, "Shove")
            else
                t1.set(p8, "ShoveDirection", p6.angle)
            end
        end
    else
        p6.angle = t1.direction_angle(p9.direction, p11)

        if MotionChannels.has(p8.channels, "SkitchAntic") then
            MotionChannels["end"](p8.channels, "SkitchAntic")
        end

        if not Shove then
            t1.start_channel(p8, "Shove", if v15 then p7.selection_board else p7.selection, false)
        end

        t1.set(p8, "GstrDistToCog", p9.animation_height)
        t1.set(p8, "ShoveDirection", p6.angle)
    end
end

t1.ShoveState["end"] = function(_, p13, p14) -- line: 186
    -- upvalues: import (copy), v11 (ref)
    if p14 then
        return
    end

    local v17 = v11

    if v17 == nil then
        v17 = import("skate_game/graph_host/motion_channels")
        v11 = v17
    end

    local MotionChannels = v17.MotionChannels

    for _, v18 in { "SkitchAntic", "Shove" } do
        if MotionChannels.has(p13.channels, v18) then
            MotionChannels["end"](p13.channels, v18)
        end
    end
end

function t1.set(p15, p16, p17) -- line: 200
    -- upvalues: import (copy), encode (copy), v9 (ref)
    local v19 = v9

    if v19 == nil then
        v19 = import("skate_game/graph_host/motion_animation")
        v9 = v19
    end

    v19.MotionAnimation.set_attribute(p15, {
        normalized = false,
        sequence_id = -1,
        name = encode(p16),
        value = p17
    })
end

function t1.start_channel(p18, p19, p20, p21) -- line: 210
    -- upvalues: v1 (copy), import (copy), v9 (ref)
    buffer.writeu32(v1, 0, p21 and 1045220557 or 1036831949)

    local v21 = buffer.readf32(v1, 0)
    local t2 = {
        priority = 0,
        mirrored = false,
        speed = 1,
        hold_during_blend_in = false,
        hold_during_blend_out = false,
        use_attributes = false,
        keep_alive = p21,
        blend_in = v21,
        blend_out = v21
    }
    local t3 = {
        kind = 2,
        seconds = 0.10000000149011612,
        under = 0,
        matching = 0,
        use_channels_from_weights = true
    }
    local v22 = v9

    if v22 == nil then
        v22 = import("skate_game/graph_host/motion_animation")
        v9 = v22
    end

    v22.MotionAnimation.transition_channel(p18, p19, p20, t2, t3, true, true)
end

function t1.direction_angle(p22, p23) -- line: 238
    -- upvalues: v1 (copy), v8 (copy)
    local v23 = p22[1]
    local v24 = if not p23 then p22[3] else -p22[3]
    local v25 = 1 / v24
    local v26 = v25 * (-v25 * v24 + 1) + v25
    local v27 = v8.atan(v23 * v26 + 0)
    local v28

    if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
        local v29 = math.abs(v23) * 7.1362384635298E+44
        local v30 = math.floor(v29)
        local v31 = v29 - v30

        v28 = if v31 > 0.5 or v31 == 0.5 and v30 % 2 == 1 then v30 + 1 else v30

        if v23 < 0 then
            v28 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v23)
        v28 = buffer.readu32(v1, 0)
    end

    local v32 = bit32.band(v28, 2147483648)

    if v24 < 0 then
        buffer.writeu32(v1, 0, (bit32.bor(1078530011, v32)))
        v27 += buffer.readf32(v1, 0)
    end

    if v24 == 0 then
        buffer.writeu32(v1, 0, (bit32.bor(1070141403, v32)))
        v27 = buffer.readf32(v1, 0)
    end

    local v35 = v27 * 57.295780181884766

    if v35 < 0 then
        return v35 + 360
    end

    return v35
end

return t1
