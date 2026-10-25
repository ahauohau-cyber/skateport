-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local TeleportState = require(sim.import)("skate_core/player/teleport_state").TeleportState
local t1 = {
    Checkpoint = {},
    Runtime = {}
}

local function transform_to_bits(p1) -- line: 32
    -- upvalues: rt (copy)
    return rt.map(p1, function(p2) -- line: 33
        -- upvalues: rt (copy)
        return rt.map(p2, rt.to_bits)
    end)
end

function t1.Runtime.request_manual(p3, p4, p5) -- line: 41
    -- upvalues: rt (copy)
    p3.pending_reply = {
        transform = rt.map(p4, function(p6) -- line: 33
            -- upvalues: rt (copy)
            return rt.map(p6, rt.to_bits)
        end),
        on_board = p5
    }
    p3.manual_on_board = p5
end

function t1.Runtime.take_manual_on_board(p7) -- line: 47
    local manual_on_board = p7.manual_on_board

    p7.manual_on_board = nil

    return manual_on_board
end

function t1.Runtime.new(p8) -- line: 56
    -- upvalues: rt (copy), TeleportState (copy)
    return {
        pending_reply = nil,
        manual_on_board = nil,
        state = TeleportState.default(),
        checkpoint = rt.copy(p8)
    }
end

function t1.Runtime.enter(p9) -- line: 65
    -- upvalues: TeleportState (copy)
    TeleportState.enter(p9.state)
end

function t1.Runtime.update(p10, p11) -- line: 72
    -- upvalues: rt (copy), TeleportState (copy)
    return TeleportState.update(p10.state, p11.flags_2468, rt.copy(p11.matrix_1536), p11.byte_1600) == "RequestCheckpoint"
end

function t1.Runtime.request_checkpoint(p12) -- line: 80
    -- upvalues: rt (copy), t1 (copy)
    t1.Runtime.reply(p12, rt.copy(p12.checkpoint))
end

function t1.Runtime.reply(p13, p14) -- line: 85
    -- upvalues: rt (copy)
    local transform = p14.transform

    p13.pending_reply = {
        transform = rt.map(transform, function(p15) -- line: 33
            -- upvalues: rt (copy)
            return rt.map(p15, rt.to_bits)
        end),
        on_board = p14.on_board
    }
end

function t1.Runtime.take_reply(p16) -- line: 96
    local pending_reply = p16.pending_reply

    p16.pending_reply = nil

    return if pending_reply ~= nil then {
        transform = pending_reply.transform,
        byte64 = pending_reply.on_board and 1 or 0
    } else nil
end

function t1.Runtime.publish_output(p17, p18) -- line: 111
    -- upvalues: rt (copy), TeleportState (copy)
    local v1 = TeleportState.output(p17.state)

    if v1 == nil then
        return nil
    end

    p18.teleport_output = rt.copy(v1)
    p18.state.identifier_8 = v1.next_state
    p18.state.flag_61 = v1.state_61

    return v1
end

return t1
