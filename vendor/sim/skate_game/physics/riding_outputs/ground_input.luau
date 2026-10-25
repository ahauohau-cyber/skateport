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

local Vector3 = require(sim.import)("skate_core/math").Vector3
local t1 = {
    GroundPacketInputs = {}
}
local from_bits = rt.from_bits

function t1.GroundPacketInputs.from_processed(p2) -- line: 30
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy), from_bits (copy)
    local vectors_464_480_496_512_528 = p2.vectors_464_480_496_512_528
    local v2 = vectors_464_480_496_512_528[1]
    local v3 = vectors_464_480_496_512_528[5]

    if #v2 ~= 4 or #v3 ~= 4 then
        return t1.GroundPacketInputs.from_processed_reference(p2)
    end

    return {
        wheel_normal = Vector3.new(from_bits(v2[1]), from_bits(v2[2]), from_bits(v2[3])),
        dynamic_up = Vector3.new(from_bits(v3[1]), from_bits(v3[2]), from_bits(v3[3])),
        speed = p2.scalar_2652,
        absolute_speed = p2.scalar_2616,
        wheel_count = rt.to_i32(p2.wheel_count_2556)
    }
end

function t1.GroundPacketInputs.from_processed_reference(p3) -- line: 49
    -- upvalues: rt (copy), v1 (copy), Vector3 (copy)
    local function vector(p4) -- line: 50
        -- upvalues: v1 (copy), Vector3 (copy)
        buffer.writeu32(v1, 0, p4[1])

        local v5 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p4[2])

        local v7 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p4[3])

        local v9 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p4[4])

        local t2 = {
            v5,
            v7,
            v9,
            (buffer.readf32(v1, 0))
        }

        return Vector3.new(t2[1], t2[2], t2[3])
    end

    return {
        wheel_normal = vector(p3.vectors_464_480_496_512_528[1]),
        dynamic_up = vector(p3.vectors_464_480_496_512_528[5]),
        speed = p3.scalar_2652,
        absolute_speed = p3.scalar_2616,
        wheel_count = rt.to_i32(p3.wheel_count_2556)
    }
end

return t1
