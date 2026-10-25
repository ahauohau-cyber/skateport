-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local Collections = require(sim.import)("skate_data/collections").Collections
local t1 = {}

function t1.standard_angular_drag(p2) -- line: 21
    -- upvalues: Collections (copy)
    return Collections.float(p2, "physicsdeck", "default", "DeckAngularDrag") * 59.999996185302734
end

function t1.load(p3) -- line: 26
    -- upvalues: Collections (copy), t1 (copy)
    local function float(p4) -- line: 27
        -- upvalues: p3 (copy), Collections (copy)
        return Collections.float(p3, "physics_skatecontroller", "default", p4)
    end

    return {
        hide_distance = Collections.float(p3, "physics_skatecontroller", "default", "MaxDistance"),
        hide_offset = Collections.float(p3, "physics_skatecontroller", "default", "DistanceToHideSkateboard"),
        return_distance = Collections.float(p3, "physics_skatecontroller", "default", "DistanceForBoardReturn"),
        mounted_return_distance = Collections.float(p3, "physics_skatecontroller", "default", "DistanceForMountedReturn"),
        mounting_time = Collections.float(p3, "physics_skatecontroller", "default", "MinTimeToRetrieveBoardWhileMounting"),
        retrieval_time = t1.curve(p3, "RetrievalTimeVsDist"),
        retrieval_weight = t1.curve(p3, "RetrievalSpeedCurve"),
        throw_pitch = Collections.float(p3, "physics_skatecontroller", "default", "ThrownSkateboardLaunchPitch"),
        throw_velocity = t1.curve(p3, "ThrownSkateboardVelocity"),
        throw_target_pitch = Collections.float(p3, "physics_skatecontroller", "default", "ThrownSkateboardPitchTarget"),
        throw_pitch_scalar = Collections.float(p3, "physics_skatecontroller", "default", "ThrownSkateboardPitchScalar"),
        throw_roll_scalar = Collections.float(p3, "physics_skatecontroller", "default", "ThrownSkateboardRollScalar"),
        throw_yaw_scalar = Collections.float(p3, "physics_skatecontroller", "default", "ThrownSkateboardYawScalar")
    }
end

function t1.curve(p5, p6) -- line: 61
    -- upvalues: rt (copy), Collections (copy)
    if Collections.field(p5, "physics_skatecontroller", "default", p6).type_name ~= "Sk8::PointNegGraphData8" then
        error(string.format("%s: expected PointNegGraphData8", p6), 0)
    end

    local v1 = rt.map(Collections.words(p5, "physics_skatecontroller", "default", p6, 20), rt.from_bits)

    for _, v2 in v1 do
        if v2 ~= v2 or v2 == 1e999 or v2 == (-1e999) then
            error(string.format("%s: nonfinite stock graph", p6), 0)
        end
    end

    local t2 = {
        v1[5],
        v1[6],
        v1[7],
        v1[8],
        v1[9],
        v1[10],
        v1[11],
        v1[12]
    }

    for i = 1, #t2 - 1 do
        if t2[i] > t2[i + 1] then
            error(string.format("%s: unordered stock knots", p6), 0)
        end
    end

    return {
        x = t2,
        y = {
            v1[13],
            v1[14],
            v1[15],
            v1[16],
            v1[17],
            v1[18],
            v1[19],
            v1[20]
        }
    }
end

return t1
