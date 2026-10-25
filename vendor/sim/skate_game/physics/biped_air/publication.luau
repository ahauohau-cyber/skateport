-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {}

local function bool_to_u8(p1) -- line: 14
    if p1 then
        return 1
    end

    return 0
end

function t1.publish(p2, p3) -- line: 19
    -- upvalues: rt (copy)
    p3.scalar_32 = p2.scalar_32
    p3.vector_64 = rt.map(p2.vector_64, rt.to_bits)
    p3.scalar_92 = p2.scalar_92
    p3.vector_96 = rt.map(p2.vector_96, rt.to_bits)
    p3.word_144 = p2.word_144
    p3.scalar_148 = p2.scalar_148
    p3.scalar_152 = p2.scalar_152
    p3.scalar_156 = p2.scalar_156
    p3.vector_160 = rt.map(p2.vector_160, rt.to_bits)
    p3.vector_176 = rt.map(p2.vector_176, rt.to_bits)
    p3.vector_192 = rt.map(p2.vector_192, rt.to_bits)
    p3.vector_208 = rt.map(p2.vector_208, rt.to_bits)
    p3.vector_224 = rt.map(p2.vector_224, rt.to_bits)
    p3.vector_240 = rt.map(p2.vector_240, rt.to_bits)
    p3.flag_320 = p2.flag_320 and 1 or 0
    p3.flag_328 = p2.flag_328 and 1 or 0
    p3.trajectory_valid_331 = p2.flag_331 and 1 or 0
end

return t1
