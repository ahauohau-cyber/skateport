-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_core/animation/skeleton_input/name")
local v10 = import("skate_data/state_graph/attributes")
local v11 = import("skate_game/graph_host/motion_channels")
local Attributes = v10.Attributes
local encode = v9.encode
local MotionChannels = v11.MotionChannels
local t1 = {}
local v12

local function motion() -- line: 46
    -- upvalues: import (copy), v12 (ref)
    local v13 = v12

    if v13 == nil then
        v13 = import("skate_game/graph_host/motion")
        v12 = v13
    end

    return v13
end

t1.CHANNEL = "AirBodyTweak"

local CHANNEL = t1.CHANNEL
local set_flag, transition

t1.Settings = {}

function t1.Settings.eq(p3, p4) -- line: 65
    if p3.nb_cycle == p4.nb_cycle and p3.nb_into == p4.nb_into and p3.br_cycle == p4.br_cycle then
        return p3.br_into == p4.br_into
    end

    return false
end

function t1.Settings.parse(p5) -- line: 73
    -- upvalues: Attributes (copy)
    local NbCycAnim = Attributes.text(p5, "NbCycAnim")

    if NbCycAnim == nil then
        NbCycAnim = "B_OBAIR_BODYTWEAK_NB_CYC"
    end

    local NbIntoAnim = Attributes.text(p5, "NbIntoAnim")

    if NbIntoAnim == nil then
        NbIntoAnim = "B_OBAIR_BODYTWEAK_NB_INTO"
    end

    local BrCycAnim = Attributes.text(p5, "BrCycAnim")

    if BrCycAnim == nil then
        BrCycAnim = "B_OBAIR_BODYTWEAK_BR_CYC"
    end

    local BrIntoAnim = Attributes.text(p5, "BrIntoAnim")

    if BrIntoAnim == nil then
        BrIntoAnim = "B_OBAIR_BODYTWEAK_BR_INTO"
    end

    return {
        nb_cycle = NbCycAnim,
        nb_into = NbIntoAnim,
        br_cycle = BrCycAnim,
        br_into = BrIntoAnim
    }
end

t1.Physical = {}
t1.State = {}

function t1.State.default() -- line: 104
    return {
        ticks = 0,
        into_started = false,
        cycle_started = false,
        released = false,
        axes = { 0, 0 }
    }
end

function t1.State.begin(p6) -- line: 114
    p6.ticks = 0
    p6.into_started = false
    p6.cycle_started = false
    p6.released = false
end

function t1.State.update(p7, p8, p9, p10, p11) -- line: 124
    -- upvalues: rt (copy), import (copy), encode (copy), MotionChannels (copy), t1 (copy), v12 (ref), CHANNEL (copy), set_flag (ref), transition (ref)
    local v14 = v12

    if v14 == nil then
        v14 = import("skate_game/graph_host/motion")
        v12 = v14
    end

    local MotionAnimation = v14.MotionAnimation
    local OB_AirBodyTweakX = MotionAnimation.motion_intent(p9, "OB_AirBodyTweakX")
    local OB_AirBodyTweakY = MotionAnimation.motion_intent(p9, "OB_AirBodyTweakY")
    local v15 = MotionAnimation.motion_intent(p9, "OB_DoAirBodyTweak") ~= nil
    local v16, v17 = t1.State.gates(p7, OB_AirBodyTweakX, OB_AirBodyTweakY, v15, p11.scalar_92)
    local v18 = v16 or v17

    if not v18 or p11.time_to_land < 0.1 then
        local v21 = if v18 then p11.time_to_land >= 0.1 else nil

        if not v18 or v21 then
            if MotionChannels.has(p9.channels, CHANNEL) then
                local v22 = if p11.time_to_land - 0.3 >= 0 then 0.3 else p11.time_to_land

                MotionChannels.end_with(p9.channels, CHANNEL, v22, true)
                p10.seed_from_air_tweak = false
                set_flag(p9, 32768, false)
            end
        else
            set_flag(p9, 65536, true)
        end
    else
        local v20 = MotionChannels.remaining(p9.channels, CHANNEL)

        if MotionChannels.has(p9.channels, CHANNEL) or p7.into_started then
            if not (v20 > 0.01) and not p7.cycle_started then
                local transition2 = transition

                transition2(p9, p8, p11.board_held, true)
                p7.cycle_started = true
            end
        else
            transition(p9, p8, p11.board_held, false)
            p7.into_started = true
        end

        local filter = t1.State.filter

        if OB_AirBodyTweakX == nil then
            OB_AirBodyTweakX = 0
        end

        if OB_AirBodyTweakY == nil then
            OB_AirBodyTweakY = 0
        end

        filter(p7, OB_AirBodyTweakX, OB_AirBodyTweakY, v17)

        local v23 = p7.axes[1]
        local v24 = p7.axes[2]

        MotionAnimation.set_attribute(p9, {
            normalized = false,
            sequence_id = -1,
            name = encode("bodytweakx"),
            value = v23
        })
        MotionAnimation.set_attribute(p9, {
            normalized = false,
            sequence_id = -1,
            name = encode("bodytweaky"),
            value = v24
        })
        p10.seed_from_air_tweak = true
        set_flag(p9, 32768, true)
    end

    p7.ticks = rt.wrapping_add_u32(p7.ticks, 1)
end

function t1.State.gates(p12, p13, p14, p15, p16) -- line: 180
    -- upvalues: rt (copy), v1 (copy)
    if rt.to_i32(p12.ticks) > 80 then
        p12.released = true
    end

    if not p12.released and p13 ~= nil and not (p13 >= 0.1) and p14 ~= nil and not (p14 >= 0.1) then
        p12.released = true
    end

    local v25 = if p13 == nil then 0 else p13
    local v26 = if p14 == nil then 0 else p14
    local v27 = v26 * v26 + v25 * v25
    local v28

    if v27 ~= 0 and v27 > -1.1754943508222875E-38 and v27 < 1.1754943508222875E-38 then
        local v29 = math.abs(v27) * 7.1362384635298E+44
        local v30 = math.floor(v29)
        local v31 = v29 - v30

        v28 = (if v31 > 0.5 or v31 == 0.5 and v30 % 2 == 1 then v30 + 1 else v30) * 1.401298464324817E-45

        if v27 < 0 then
            v28 = -v28
        end
    else
        buffer.writef32(v1, 0, v27)
        v28 = buffer.readf32(v1, 0)
    end

    local v32 = 1 / math.sqrt(v28)
    local v33 = -v28 * (v32 * v32) + 1
    local v34 = v32 * 0.5 * v33 + v32
    local v35 = -v28 * (v34 * v34) + 1
    local v36 = v34 * 0.5 * v35 + v34
    local v37 = if v28 == 0 then 0 else v28 * v36
    local v38 = p12.released and v37 >= 0.1

    return v38, p15 or not (p16 <= 4) and not v38
end

function t1.State.filter(p17, p18, p19, p20) -- line: 205
    if p20 then
        p17.axes = {
            p17.axes[1] * 0.85,
            p17.axes[2] * 0.85
        }
    else
        p17.axes = {
            p18 * 0.15 + p17.axes[1] * 0.85,
            p17.axes[2] * 0.85 + p19 * 0.15
        }
    end
end

t1.State["end"] = function(_, p22) -- line: 215
    -- upvalues: MotionChannels (copy), CHANNEL (copy)
    if MotionChannels.has(p22.channels, CHANNEL) then
        MotionChannels.end_with(p22.channels, CHANNEL, 0.1, true)
    end
end

function set_flag(p23, p24, p25) -- line: 223
    local skater_animation_flags = p23.skater_animation_flags

    if skater_animation_flags == nil then
        error("OffboardBodyTweakBlend requires SkaterAnim flag owner", 0)
    end

    p23.skater_animation_flags = bit32.bor(bit32.band(skater_animation_flags, (bit32.bnot(p24))), if p25 then p24 else 0)
end

t1.set_flag = set_flag

function transition(p26, p27, p28, p29) -- line: 234
    -- upvalues: import (copy), v12 (ref), CHANNEL (copy)
    local v42 = if not p28 and not p29 then p27.nb_into
        elseif not p28 and p29 then p27.nb_cycle
        elseif not p28 or p29 then p27.br_cycle
        else p27.br_into
    local v43 = v12

    if v43 == nil then
        v43 = import("skate_game/graph_host/motion")
        v12 = v43
    end

    v43.MotionAnimation.transition_channel(p26, CHANNEL, v42, {
        priority = 0,
        mirrored = false,
        speed = 1,
        hold_during_blend_in = false,
        hold_during_blend_out = false,
        use_attributes = true,
        keep_alive = p29,
        blend_in = p29 and 0.5 or 0.15,
        blend_out = p29 and 0.3 or 0
    }, {
        kind = 1,
        under = 0,
        matching = 0,
        use_channels_from_weights = false,
        seconds = p29 and 0.1 or 0.15
    }, false, true)
end

t1.transition = transition

return t1
