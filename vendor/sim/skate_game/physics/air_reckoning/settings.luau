-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local Collections = require(sim.import)("skate_data/collections").Collections
local t1 = {
    Mode = {}
}
local negative_graph, graph

function t1.load(p1) -- line: 20
    -- upvalues: rt (copy), Collections (copy), negative_graph (ref), graph (ref)
    local function float(p2, p3) -- line: 21
        -- upvalues: p1 (copy), Collections (copy)
        return Collections.float(p1, p2, "default", p3)
    end

    local v1 = rt.map(Collections.words(p1, 4, "physics_reckoning", "default", "GroundNormalSmoothing"), rt.from_bits)
    local t2 = {}

    for _, v2 in { "easy", "normal", "hardcore", "motorized", "test" } do
        table.insert(t2, {
            easy_body_spins = Collections.boolean(p1, "physics_mode", v2, "EasyBodySpins"),
            perfect_body_flips = Collections.boolean(p1, "physics_mode", v2, "PerfectBodyFlips")
        })
    end

    local t4 = {
        ground_normal_smoothing = v1
    }

    t4.max_up_angle_delta = negative_graph(p1, "physics_reckoning", "Air_MaxUpVectAngleDelta")
    t4.tilt_vs_rotation = graph(p1, "TiltVsRotAir")
    t4.tilt_vs_slope = graph(p1, "TiltVsSlopeAir")
    t4.body_spin = {
        derivative_floor = Collections.float(p1, "physics_bodyspin", "default", "MinDerivativeScalar"),
        acceleration_limit = Collections.float(p1, "physics_bodyspin", "default", "MaxDeltaOppositeDirection"),
        curves = {
            negative_graph(p1, "physics_bodyspin", "Hash_BEA30B5DC6AFF26A"),
            negative_graph(p1, "physics_bodyspin", "MaxDeltaVsTime"),
            negative_graph(p1, "physics_bodyspin", "MaxDeltaForAutoVsTime"),
            negative_graph(p1, "physics_bodyspin", "Hash_3974F0228331EB22"),
            negative_graph(p1, "physics_bodyspin", "DerivativeBodySpinVsTime"),
            negative_graph(p1, "physics_bodyspin", "Hash_D7C6855B7814D048"),
            (negative_graph(p1, "physics_bodyspin", "PropBodySpinVsTime"))
        },
        input_fade_threshold = rt.filled(4, 1.52587890625E-05)
    }
    t4.body_flip = {
        smoothing = Collections.float(p1, "physics_reckoning", "default", "FlipSpeedSmoothingFactor"),
        maximum_speed = Collections.float(p1, "physics_reckoning", "default", "FlipMaxSpeed"),
        spin_scale = Collections.float(p1, "physics_reckoning", "default", "FlipBodySpinScalar"),
        missing_attribute_value = 0
    }

    if #t2 ~= 5 then
        error("Expected five physics modes", 0)
    end

    return t4, t2
end

function negative_graph(p4, p5, p6) -- line: 75
    -- upvalues: rt (copy), Collections (copy)
    local v3 = rt.map(Collections.words(p4, 20, p5, "default", p6), rt.from_bits)

    return {
        x = rt.slice(v3, 4, 12),
        y = rt.slice(v3, 12, 20)
    }
end

t1.negative_graph = negative_graph

function graph(p7, p8) -- line: 86
    -- upvalues: rt (copy), Collections (copy)
    local v4 = rt.map(Collections.words(p7, 16, "physics_reckoning", "default", p8), rt.from_bits)

    return {
        x = rt.slice(v4, 0, 8),
        y = rt.slice(v4, 8)
    }
end

t1.graph = graph

return t1
