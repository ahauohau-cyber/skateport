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

require(sim.import)

local t1 = {}

local function from_bits4(p2) -- line: 19
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2[1])

    local v3 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[2])

    local v5 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[3])

    local v7 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[4])

    return {
        v3,
        v5,
        v7,
        (buffer.readf32(v1, 0))
    }
end

function t1.processed(p3) -- line: 25
    -- upvalues: rt (copy), from_bits4 (copy)
    local processed, toolkit = p3.processed, p3.toolkit

    if toolkit == nil then
        error("Landing manager requires the current processed BoardToolkit", 0)
    end

    return {
        board_up_80 = rt.copy(toolkit.deck[2]),
        board_position_112 = rt.copy(toolkit.deck[4]),
        board_velocity_400 = from_bits4(processed.vectors_400_416[1]),
        up_544 = from_bits4(processed.vectors_544_560_592_608[1]),
        support_1776 = rt.to_i32(processed.external_physics_1616.flags),
        flags_2480 = processed.flags_2480,
        mode_2540 = processed.surface_mode_2540,
        wheel_contacts_2556 = processed.wheel_count_2556
    }
end

function t1.position(p4) -- line: 44
    -- upvalues: from_bits4 (copy)
    return (from_bits4(p4.processed.vectors_544_560_592_608[3]))
end

function t1.velocity(p5) -- line: 49
    -- upvalues: from_bits4 (copy)
    return (from_bits4(p5.processed.vectors_544_560_592_608[4]))
end

return t1
