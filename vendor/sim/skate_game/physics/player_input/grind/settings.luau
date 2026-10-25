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
local t1 = {
    Settings = {}
}

local function floats(p2) -- line: 27
    -- upvalues: v1 (copy)
    local v2 = table.create(#p2)

    for i = 1, #p2 do
        buffer.writeu32(v1, 0, p2[i])
        v2[i] = buffer.readf32(v1, 0)
    end

    return v2
end

function t1.Settings.load(p3) -- line: 36
    -- upvalues: rt (copy), v1 (copy), Collections (copy), t1 (copy)
    local function f(p4) -- line: 37
        -- upvalues: p3 (copy), Collections (copy)
        return Collections.float(p3, "physics_grinds", "default", p4)
    end

    local v4 = Collections.words(p3, "physics_grinds", "default", "ExitLeanAngleVsTime", 20)
    local v5 = table.create(#v4)

    for i = 1, #v4 do
        buffer.writeu32(v1, 0, v4[i])
        v5[i] = buffer.readf32(v1, 0)
    end

    return {
        friction = t1.graph4(p3, "FrictionVsTime"),
        slope_threshold = t1.graph4(p3, "DVEntryThreshScalarVsSinSlope"),
        vertical_help = t1.graph4(p3, "VertEngagementHelpVsVelY"),
        gravity_vertical = t1.graph4(p3, "TimeOfGravityReliefVsVerticalSpeed"),
        gravity_linear = t1.graph4(p3, "GravityReliefTimeVsLinearSpeed"),
        exit_lean = {
            x = rt.slice(v5, 4, 12),
            y = rt.slice(v5, 12, 20)
        },
        truck_to_wheel = Collections.float(p3, "physics_grinds", "default", "TruckToWheel"),
        deck_to_truck = Collections.float(p3, "physics_grinds", "default", "DeckCenterToTruck"),
        test_above = Collections.float(p3, "physics_grinds", "default", "TestDepthEpsilon"),
        test_below = Collections.float(p3, "physics_grinds", "default", "TestDepth"),
        max_impact = Collections.float(p3, "physics_wipeout", "default", "Wipeout_AirMaxSpeedIntoCollisionNearGrind")
    }
end

function t1.graph4(p5, p6) -- line: 61
    -- upvalues: rt (copy), v1 (copy), Collections (copy)
    local v7 = Collections.words(p5, "physics_grinds", "default", p6, 12)
    local v8 = table.create(#v7)

    for i = 1, #v7 do
        buffer.writeu32(v1, 0, v7[i])
        v8[i] = buffer.readf32(v1, 0)
    end

    return {
        x = rt.slice(v8, 4, 8),
        y = rt.slice(v8, 8, 12)
    }
end

return t1
