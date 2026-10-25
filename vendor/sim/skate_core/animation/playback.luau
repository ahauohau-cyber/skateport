-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/playback_parameters")
local v2 = import("skate_core/animation/skeleton_input/name")
local PlaybackParameter = v1.PlaybackParameter
local t1 = {
    TransitionSettings = {}
}

function t1.TransitionSettings.eq(p1, p2) -- line: 25
    if p1.kind == p2.kind and p1.seconds == p2.seconds and p1.under == p2.under and p1.matching == p2.matching then
        return p1.use_channels_from_weights == p2.use_channels_from_weights
    end

    return false
end

t1.PlayAnimation = {}
t1.PlaybackRequest = {}

function t1.PlaybackRequest.eq(p3, p4) -- line: 44
    -- upvalues: t1 (copy)
    if p3.animation == p4.animation and p3.speed == p4.speed and p3.start_time == p4.start_time then
        return (t1.TransitionSettings.eq(p3.transition, p4.transition))
    end

    return false
end

t1.PlaybackContext = {}
t1.PlaybackService = {}
t1.PlayAnimationInstance = {}

function t1.PlayAnimationInstance.default() -- line: 74
    return {
        first_update = false
    }
end

local refresh_parameters

function t1.PlayAnimationInstance.begin(p5, p6, p7, p8) -- line: 81
    -- upvalues: rt (copy), v2 (copy), refresh_parameters (ref)
    p5.first_update = true
    refresh_parameters(p6.parameters, true, p8)
    p8.set_construction_value(p8, v2.encode("ProSkater"), rt.copy(p7.pro_skater))

    local transition_override = p7.transition_override

    p7.transition_override = nil

    if transition_override ~= nil and transition_override.kind == 0 then
        transition_override = nil
    end

    if transition_override == nil then
        transition_override = rt.copy(p6.transition)
    end

    local animation = p6.animation
    local v3 = animation

    if p6.switch_animation ~= nil then
        local switch_animation = p6.switch_animation

        if p7.is_switch == nil then
            error("PlayAnimation needs skater switch state", 0)
        end

        if p7.is_switch then
            v3 = switch_animation
        end
    end

    local v4 = v3

    if p6.mirror_animation ~= nil then
        local mirror_animation = p6.mirror_animation

        if p7.is_mirrored == nil then
            error("PlayAnimation needs skater mirror state", 0)
        end

        if p7.is_mirrored then
            v4 = mirror_animation
        end
    end

    local v5 = v4

    if p6.no_board_animation ~= nil then
        local no_board_animation = p6.no_board_animation

        if p7.board_available == nil then
            error("PlayAnimation needs PhysOut board availability", 0)
        end

        if not p7.board_available then
            v5 = no_board_animation
        end
    end

    p8.set_posture_enabled(p8, p6.apply_posture)

    if transition_override.kind >= 1 and transition_override.kind <= 4 and p8.play(p8, {
        start_time = 0,
        animation = v5,
        speed = p6.playback_speed,
        transition = transition_override
    }) then
        return
    end

    local v6 = rt.copy(p6.transition)

    v6.kind = 1
    p8.play(p8, {
        animation = "KeepDefaultAnim",
        speed = 1,
        start_time = 0,
        transition = v6
    })
end

function t1.PlayAnimationInstance.update(p9, p10, p11) -- line: 146
    -- upvalues: refresh_parameters (ref)
    if not p9.first_update then
        refresh_parameters(p10.parameters, false, p11)
    end

    p9.first_update = false
end

t1.PlayAnimationInstance["end"] = function(_) -- line: 153
end

function t1.refresh_parameters(p13, p14, p15) -- line: 156
    -- upvalues: PlaybackParameter (copy)
    for _, v7 in p13 do
        local t2 = {
            nil
        }
        local t3 = {
            set_attribute = function(_, p17) -- set_attribute | line: 164
                -- upvalues: t2 (copy)
                t2[1] = p17
            end
        }

        PlaybackParameter.update(v7, p14, p15, t3)

        local v8 = t2[1]

        if v8 ~= nil then
            p15.set_attribute(p15, v8)
        end
    end
end

refresh_parameters = t1.refresh_parameters

return t1
