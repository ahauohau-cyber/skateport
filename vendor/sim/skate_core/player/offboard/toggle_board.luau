-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    Phase = {}
}

function t1.Phase.default() -- line: 17
    return "Idle"
end

t1.Input = {}

function t1.Input.default() -- line: 29
    return {
        grabbing_object = false,
        holding_board = false,
        retrieval_blocked = false,
        retrieval_active = false,
        drop_requested = false,
        throw_requested = false,
        retrieve_requested = false,
        yaw_radians = 0,
        pitch_radians = 0,
        mirrored = false
    }
end

t1.Channel = {}

function t1.Channel.default() -- line: 47
    return {
        exists = false,
        remaining = 0,
        elapsed = 0
    }
end

t1.Clip = {}

function t1.Clip.name(p1) -- line: 56
    if p1 == "Throw" then
        return "OFB_THROW_0"
    end

    if p1 == "Drop" then
        return "OFB_THROW_90"
    end

    if p1 == "FrontInto" then
        return "OFB_RETRIEVE_HIGH_FRONT_INTO"
    end

    if p1 == "FrontCycle" then
        return "OFB_RETRIEVE_HIGH_FRONT_CYC"
    end

    if p1 == "FrontOut" then
        return "OFB_RETRIEVE_HIGH_FRONT_OUT"
    end

    if p1 == "BackInto" then
        return "OFB_RETRIEVE_HIGH_BACK_INTO"
    end

    if p1 == "BackCycle" then
        return "OFB_RETRIEVE_HIGH_BACK_CYC"
    end

    if p1 == "BackOut" then
        return "OFB_RETRIEVE_HIGH_BACK_OUT"
    end

    error("unreachable Clip variant", 0)
end

t1.Command = {}

function t1.Command.eq(p2, p3) -- line: 82
    if p2.tag ~= p3.tag then
        return false
    end

    if p2.tag == "Stop" then
        return p2.blend_seconds == p3.blend_seconds
    end

    return p2[1] == p3[1]
end

t1.Output = {}

function t1.Output.default() -- line: 100
    return {
        retrieving = false,
        dropping = false,
        retrieve = false,
        yaw_pitch = nil,
        channel = nil
    }
end

function t1.Output.eq(p4, p5) -- line: 111
    -- upvalues: t1 (copy)
    if p4.retrieving ~= p5.retrieving
        or p4.dropping ~= p5.dropping
        or p4.retrieve ~= p5.retrieve
        or p4.yaw_pitch == nil ~= (p5.yaw_pitch == nil)
        or p4.yaw_pitch ~= nil and (p4.yaw_pitch[1] ~= p5.yaw_pitch[1] or p4.yaw_pitch[2] ~= p5.yaw_pitch[2])
        or p4.channel == nil ~= (p5.channel == nil) then
        return false
    end

    return not not (p4.channel == nil or t1.Command.eq(p4.channel, p5.channel))
end

t1.State = {}

function t1.State.default() -- line: 135
    return {
        phase = "Idle",
        previous_yaw = 0,
        yaw = 0,
        pitch = 0,
        initialized_yaw = false,
        back = false,
        throwing = false
    }
end

function t1.State.begin(p6) -- line: 148
    -- upvalues: t1 (copy)
    p6.phase = "Idle"
    t1.State.reset_orientation(p6)
end

function t1.State.reset_orientation(p7) -- line: 153
    p7.previous_yaw = 0
    p7.yaw = 0
    p7.pitch = 0
    p7.initialized_yaw = false
    p7.back = false
end

function t1.State.orientation(p8, p9) -- line: 162
    local v1 = p9.yaw_radians * -57.295776

    if p9.mirrored then
        v1 = -v1
    end

    if v1 < -90 then
        v1 = if p8.initialized_yaw then if p8.yaw >= 0 then 180 else -90 elseif v1 >= -135 then -90 else 180
    end

    if p9.mirrored then
        v1 = -v1
    end

    if p8.initialized_yaw then
        local v2 = v1 - p8.previous_yaw

        if -5 - v2 >= 0 then
            v2 = -5
        end

        if not (5 - v2 >= 0) then
            v2 = 5
        end

        v1 = v2 + p8.previous_yaw
    end

    p8.previous_yaw = v1
    p8.yaw = if not p9.mirrored then v1 else -v1
    p8.pitch = p9.pitch_radians * 57.295776
    p8.initialized_yaw = true
    p8.back = math.abs(p8.yaw) > 90
end

function t1.State.update(p10, p11, p12) -- line: 203
    -- upvalues: t1 (copy)
    if not p11.grabbing_object and p10.phase == "Idle" then
        if p11.drop_requested and p11.holding_board then
            p10.phase = "DropStart"
            p10.throwing = false
        elseif p11.throw_requested and p11.holding_board then
            p10.phase = "DropStart"
            p10.throwing = true
        elseif p11.retrieve_requested and not p11.holding_board and not p11.retrieval_blocked then
            p10.phase = "RetrieveStart"
        end
    end

    local v3 = t1.Output.default()
    local phase = p10.phase

    if phase == "Idle" then
        t1.State.reset_orientation(p10)
    elseif phase == "DropStart" then
        v3.dropping = true
        p10.phase = "DropPlaying"
        v3.channel = {
            tag = "BlendTo",
            p10.throwing and "Throw" or "Drop"
        }
    elseif phase == "DropPlaying" then
        v3.dropping = true

        if not p12.exists or p12.remaining <= 0 or p12.elapsed > 0.5 then
            t1.State.stop(p10, v3)

            return v3
        end
    else
        v3.retrieving = true

        if phase == "RetrieveStart" then
            t1.State.orientation(p10, p11)
            p10.phase = "RetrieveInto"
            v3.channel = {
                tag = "BlendTo",
                p10.back and "BackInto" or "FrontInto"
            }
        elseif phase == "RetrieveInto" then
            t1.State.orientation(p10, p11)

            if not p12.exists or p12.remaining <= 0 then
                p10.phase = "Idle"
            elseif p12.remaining <= 0.25 then
                t1.State.cycle(p10, v3)
            end
        elseif phase == "RetrieveCycle" then
            t1.State.orientation(p10, p11)

            if p11.retrieval_active then
                if not p12.exists or p12.remaining <= 0 then
                    p10.phase = "Idle"
                elseif p11.holding_board then
                    p10.phase = "RetrieveOut"
                    v3.channel = {
                        tag = "BlendTo",
                        p10.back and "BackOut" or "FrontOut"
                    }
                elseif p12.remaining <= 0.25 then
                    t1.State.cycle(p10, v3)
                end
            else
                t1.State.stop(p10, v3)
            end
        elseif phase == "RetrieveOut" then
            if not p12.exists or p12.remaining <= 0 or p12.elapsed > 0.16666667 then
                t1.State.stop(p10, v3)
            end
        else
            error("internal error: entered unreachable code", 0)
        end

        v3.yaw_pitch = {
            p10.yaw,
            p10.pitch
        }
    end

    return v3
end

function t1.State.cycle(p13, p14) -- line: 265
    p13.phase = "RetrieveCycle"
    p14.channel = {
        tag = "SequenceTo",
        p13.back and "BackCycle" or "FrontCycle"
    }
    p14.retrieve = true
end

function t1.State.stop(p15, p16) -- line: 271
    p15.phase = "Idle"
    p16.channel = {
        tag = "Stop",
        blend_seconds = 0.16666667
    }
end

return t1
