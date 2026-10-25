-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    AnimationPacketFields = {},
    ProcessedPacketFields = {}
}

function t1.publish(p1, p2) -- line: 37
    -- upvalues: rt (copy), t1 (copy)
    p2.flags_2468 = t1.replace_bit(p2.flags_2468, 20, p1.stance_byte)
    p2.timestep = p1.timestep
    p2.scalar_2668 = p1.scalar_10388
    p2.flags_2468 = t1.replace_bit(p2.flags_2468, 3, p1.flags_10375_10496_10784[1])
    p2.flags_2468 = t1.replace_bit(p2.flags_2468, 2, p1.flags_10375_10496_10784[2])
    p2.vector_1520 = rt.copy(p1.vector_10480)
    p2.flags_2468 = t1.replace_bit(p2.flags_2468, 1, p1.flags_10375_10496_10784[3])
    p2.matrix_1536 = rt.copy(p1.matrix_10704)
    p2.byte_1600 = p1.byte_10768
    p2.truck_tightness = p1.truck_tightness
    p2.scalar_2764 = p1.scalar_10792
    p2.flags_2476 = t1.replace_bit(p2.flags_2476, 20, p1.flag_10371)
end

function t1.replace_bit(p3, p4, p5) -- line: 54
    return (bit32.bor(bit32.band(p3, (bit32.bnot((bit32.lshift(1, p4))))), (bit32.lshift(bit32.band(p5, 1), p4))))
end

return t1
