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

local import = require(sim.import)
local v2 = import("skate_core/physics/foot_physical_output")
local FootPhysicalOutput, FootPhysicalState = v2.FootPhysicalOutput, v2.FootPhysicalState
local Collections = import("skate_data/collections").Collections
local t1 = {
    FootPhysicalOutputs = {}
}

function t1.FootPhysicalOutputs.load(p2) -- line: 33
    -- upvalues: v1 (copy), FootPhysicalOutput (copy), FootPhysicalState (copy), Collections (copy)
    local v3 = Collections.words(p2, "physics_skeletonik", "default", "FootOnDeckPadding", 4)
    local t2 = {
        state = FootPhysicalState.default(),
        output = FootPhysicalOutput.default()
    }
    local t3 = {
        deck_half_width = Collections.float(p2, "physicsdeck", "default", "DeckWidth") * 0.5,
        deck_total_half_length = Collections.float(p2, "physicsdeck", "default", "DeckFrontEndSize") + Collections.float(p2, "physicsdeck", "default", "DeckMidLength") * 0.5
    }

    buffer.writeu32(v1, 0, v3[1])

    local v5 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[2])

    local v7 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[3])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[4])
    t3.padding = {
        v5,
        v7,
        v9,
        (buffer.readf32(v1, 0))
    }
    t2.settings = t3

    return t2
end

function t1.FootPhysicalOutputs.publish(p3, p4, p5) -- line: 52
    -- upvalues: rt (copy), FootPhysicalState (copy)
    p3.output = FootPhysicalState.update(p3.state, p4, p5, rt.copy(p3.settings))

    return rt.copy(p3.output)
end

return t1
