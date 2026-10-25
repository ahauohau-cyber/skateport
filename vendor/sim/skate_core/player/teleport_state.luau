-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    Target = {},
    Update = {},
    Output = {},
    TeleportState = {}
}

function t1.TeleportState.default() -- line: 31
    -- upvalues: rt (copy)
    return {
        ready = false,
        received = false,
        on_board = true,
        target = rt.filled(4, table.create(4, 0))
    }
end

function t1.TeleportState.enter(p1) -- line: 42
    p1.ready = false
    p1.received = false
    p1.on_board = true
end

function t1.TeleportState.update(p2, p3, p4, p5) -- line: 48
    -- upvalues: rt (copy)
    if bit32.band(p3, 2) == 0 then
        return "RequestCheckpoint"
    end

    p2.received = true
    p2.target = rt.copy(p4)
    p2.ready = true
    p2.on_board = bit32.band(p5, 1) ~= 0

    return "Captured"
end

function t1.TeleportState.output(p6) -- line: 62
    -- upvalues: rt (copy)
    return if p6.ready then {
        state_61 = 1,
        board_272 = 1,
        transform = rt.copy(p6.target),
        next_state = p6.on_board and 100 or 500
    } else nil
end

return t1
