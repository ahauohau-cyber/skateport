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

local Collections = require(sim.import)("skate_data/collections").Collections
local t1 = {}

local function map_from_bits(p2) -- line: 22
    -- upvalues: v1 (copy)
    local v2 = table.create(#p2)

    for i = 1, #p2 do
        buffer.writeu32(v1, 0, p2[i])
        v2[i] = buffer.readf32(v1, 0)
    end

    return v2
end

function t1.load(p3) -- line: 31
    -- upvalues: rt (copy), v1 (copy), Collections (copy)
    local function coefficients(p4) -- line: 32
        -- upvalues: p3 (copy), v1 (copy), Collections (copy)
        local v4 = Collections.words(p3, "physics_animation", "default", p4, 4)
        local v5 = table.create(#v4)

        for i = 1, #v4 do
            buffer.writeu32(v1, 0, v4[i])
            v5[i] = buffer.readf32(v1, 0)
        end

        return v5
    end

    local function plain(p5) -- line: 35
        -- upvalues: p3 (copy), rt (copy), v1 (copy), Collections (copy)
        local v7 = Collections.words(p3, "physics_animation", "default", p5, 16)
        local v8 = table.create(#v7)

        for i = 1, #v7 do
            buffer.writeu32(v1, 0, v7[i])
            v8[i] = buffer.readf32(v1, 0)
        end

        return {
            x = rt.slice(v8, 0, 8),
            y = rt.slice(v8, 8)
        }
    end

    local v10 = Collections.words(p3, "physics_animation", "default", "ScaleQuicknessAtSpeed", 20)
    local v11 = table.create(#v10)

    for i = 1, #v10 do
        buffer.writeu32(v1, 0, v10[i])
        v11[i] = buffer.readf32(v1, 0)
    end

    local v13 = Collections.words(p3, "physics_animation", "default", "SpeedWobbleTurnBlend", 12)
    local v14 = table.create(#v13)

    for i = 1, #v13 do
        buffer.writeu32(v1, 0, v13[i])
        v14[i] = buffer.readf32(v1, 0)
    end

    local v16 = table.create(13, 0)
    local t2 = {
        "QuicknessMaxDelta",
        "InputQuicknessMax",
        "InputQuicknessBlendVal",
        "HoldingMinVal",
        "HoldingMaxAcceleration",
        "HoldingIntegralBlend",
        "HoldingBlendUp",
        "HoldingBlendDown",
        "AnimationTurnWobbleScalar",
        "AnimationTurnPhysicsWeight",
        "AnimationTurnMaxLean",
        "AnimationTurnGraphX",
        "AnimationTurnDirMax"
    }

    for i = 1, 13 do
        v16[i] = Collections.float(p3, "physics_animation", "default", t2[i])
    end

    local t3 = {}
    local v17 = Collections.words(p3, "physics_animation", "default", "AnimationTurnLeanFilterSlow", 4)
    local v18 = table.create(#v17)

    for i = 1, #v17 do
        buffer.writeu32(v1, 0, v17[i])
        v18[i] = buffer.readf32(v1, 0)
    end

    local v20 = Collections.words(p3, "physics_animation", "default", "AnimationTurnLeanFilter", 4)
    local v21 = table.create(#v20)

    for i = 1, #v20 do
        buffer.writeu32(v1, 0, v20[i])
        v21[i] = buffer.readf32(v1, 0)
    end

    local v23 = Collections.words(p3, "physics_animation", "default", "AnimationTurnDirFilter", 4)
    local v24 = table.create(#v23)

    for i = 1, #v23 do
        buffer.writeu32(v1, 0, v23[i])
        v24[i] = buffer.readf32(v1, 0)
    end

    t3.filter_coefficients = { v18, v21, v24 }
    t3.input_curve = plain("AnimationTurnSpeedGraph")
    t3.quickness_curve = plain("QuicknessVsQuickness")
    t3.speed_curve = {
        x = rt.slice(v11, 4, 12),
        y = rt.slice(v11, 12, 20)
    }
    t3.smoothing_curve = {
        x = rt.slice(v14, 4, 8),
        y = rt.slice(v14, 8, 12)
    }
    t3.parameters = v16

    return t3
end

return t1
