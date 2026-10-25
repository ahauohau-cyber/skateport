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
local StaticProvider = import("skate_game/grind_world").StaticProvider
local Prediction = import("skate_core/air/trajectory").Prediction
local v2 = import("skate_core/air/trajectory/grind")
local v3 = import("skate_core/air/trajectory/grind_surface")
local Collections = import("skate_data/collections").Collections
local GeometryType = v3.GeometryType
local trajectory_box_filter, consider_grind_primitive, take_best_grind, admitted_displacement = v2.trajectory_box_filter, v2.consider_grind_primitive, v2.take_best_grind, v2.admitted_displacement
local apply_admitted_target = v2.apply_admitted_target

local function player_input_grind_world() -- line: 30
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input/grind/world")
end

local dot, graph8, sub, scale, cross, length_square, unit
local t1 = {}

t1.GrindContext = {}

function t1.GrindContext.from_processed(p2, p3) -- line: 42
    -- upvalues: rt (copy)
    return {
        board_position = p3,
        body_position = rt.map(p2.vectors_544_560_592_608[3], rt.from_bits),
        actor = {
            p2.actor_query_2948,
            p2.actor_query_2952
        }
    }
end

t1.Settings = {}

function t1.Settings.load(p4) -- line: 55
    -- upvalues: v1 (copy), Collections (copy), graph8 (ref)
    local function t(p5) -- line: 56
        -- upvalues: p4 (copy), Collections (copy)
        return Collections.float(p4, "physics_trajectory", "default", p5)
    end

    local t2 = {
        lock_distance = 0
    }

    t2.max_speed_squared_ledge = Collections.float(p4, "physics_trajectory", "default", "GrindMaxSpeedSqrIntoLedge")
    t2.max_speed_squared_rail = Collections.float(p4, "physics_trajectory", "default", "GrindMaxSpeedSqrIntoGrind")
    t2.max_downward_speed = Collections.float(p4, "physics_trajectory", "default", "GrindMaxSpeedDownOntoGrind")
    t2.ledge_scalars = {
        Collections.float(p4, "physics_trajectory", "default", "GrindLockLedgeScalar2"),
        Collections.float(p4, "physics_trajectory", "default", "GrindLockLedgeScalar"),
        Collections.float(p4, "physics_trajectory", "default", "GrindLockLedgeLowSideScalar2"),
        (Collections.float(p4, "physics_trajectory", "default", "GrindLockLedgeLowSideScalar"))
    }
    t2.tip_scalar = Collections.float(p4, "physics_trajectory", "default", "GrindTipScalar")
    t2.maximum_adjust_angle = Collections.float(p4, "physics_trajectory", "default", "GrindAdjustMaxAngle")
    t2.deck_dimensions = {
        Collections.float(p4, "physicsdeck", "default", "DeckMidLength"),
        (Collections.float(p4, "physicsdeck", "default", "DeckFrontEndSize"))
    }

    local t3 = {
        limits = t2
    }

    t3.height = graph8(p4, "physics_trajectory", "RequiredAngleVsHeight", true)
    t3.padding = Collections.float(p4, "physics_trajectory", "default", "GrindOffset")
    t3.maximum_adjust = Collections.float(p4, "physics_trajectory", "default", "MaxTrajectoryAdjust")
    t3.velocity_scalar = Collections.float(p4, "physics_trajectory", "default", "GrindLandingVelScalar")
    t3.max_angle = Collections.float(p4, "physics_trajectory", "default", "GrindLandingMaxAngle")
    t3.score = Collections.float(p4, "physics_trajectory", "default", "ScoreGrind")
    t3.truck_distance = Collections.float(p4, "physics_grinds", "default", "DeckCenterToTruck")
    buffer.writeu32(v1, 0, Collections.words(p4, 20, "physics_trajectory", "default", "GrindPenaltyVsDistToGrind")[3])
    t3.penalty_domain = buffer.readf32(v1, 0)

    return t3
end

function t1.Settings.evaluate(p6, p7, p8, p9, p10, p11, p12, p13) -- line: 92
    -- upvalues: rt (copy), import (copy), StaticProvider (copy), Prediction (copy), v3 (copy), GeometryType (copy), trajectory_box_filter (copy), consider_grind_primitive (copy), take_best_grind (copy), admitted_displacement (copy), apply_admitted_target (copy), dot (ref), sub (ref), scale (ref), cross (ref), length_square (ref), unit (ref)
    local v5 = Prediction.collision_position(p7)
    local v6 = Prediction.collision_velocity(p7)

    if p8 then
        local t4 = {
            v5[1] - 2,
            v5[2] - 0.5,
            v5[3] - 2
        }
        local t5 = {
            v5[1] + 2,
            v5[2] + 4,
            v5[3] + 2
        }
        local v7 = StaticProvider.query(p10, t4, t5)

        rt.assign(p11, trajectory_box_filter(v7, StaticProvider.primitives(p10), rt.copy(p13.board_position)))
    end

    local t6 = {
        target = nil,
        score = 0,
        distance = 1000,
        effective_lock_distance = nil,
        penalty_domain = p6.penalty_domain
    }
    local n1 = 1E+06

    for _, v8 in p11 do
        local v9 = StaticProvider.primitives(p10)[v8 + 1]
        local v10 = unit(sub(v9["end"], v9.start))
        local v11 = sub(v5, v9.start)
        local v12 = sub(v5, v9["end"])
        local v13 = sub(v11, scale(v10, dot(v10, v11)))

        n1 = rt.fmin(rt.fmin(rt.fmin(dot(v13, v13), dot(v11, v11)), dot(v12, v12)), n1)
    end

    if #p11 ~= 0 then
        t6.distance = length_square(n1)
    end

    if not p8 or #p11 == 0 then
        return t6
    end

    local t7 = {}

    for _, v14 in p11 do
        local v15 = consider_grind_primitive(rt.copy(p7), StaticProvider.primitives(p10)[v14 + 1], v14, p6.padding)

        if v15 ~= nil then
            table.insert(t7, v15)
        end
    end

    local v16 = rt.copy(p6.limits)

    v16.lock_distance = p12

    while true do
        local v17 = take_best_grind(t7, p12, p6.height)

        if v17 == nil then
            break
        end

        local v18 = rt.copy(StaticProvider.primitives(p10)[v17.primitive + 1])
        local t8 = {
            start = rt.copy(v18.start),
            ["end"] = rt.copy(v18["end"]),
            reference = rt.copy(v17.point),
            optional_probe = nil,
            deck_center_to_truck = p6.truck_distance
        }
        local t9, v19

        if v3.prepare(t8) ~= nil then
            local v20 = v3.investigate(t8, function(p14, p15) -- line: 172
                -- upvalues: p9 (copy), p13 (copy), import (copy)
                return import("skate_game/physics/player_input/grind/world").surface_probe(p9, p13.actor, p14, p15)
            end)

            t9 = {
                garbage = false,
                kind = GeometryType.Impossible,
                boardslide_dir = table.create(4, 0),
                tipslide_dir = table.create(4, 0),
                backslash_dir = table.create(4, 0),
                high_side = table.create(4, 0)
            }

            local v21 = table.create(4, 0)

            v3.update_landing_orientation(v20, p13.board_position, v17.point, v21, t9)

            local v22, v23 = admitted_displacement(rt.copy(p7), v17, v18, v6, p13.body_position, {
                kind = t9.kind,
                side = rt.copy(t9.high_side)
            }, v16, t6.effective_lock_distance)

            t6.effective_lock_distance = v23

            if v22 ~= nil then
                apply_admitted_target(p7, v17, v22, v21, rt.copy(p7.request.trajectory.velocity), p6.maximum_adjust, p6.velocity_scalar, p6.max_angle)
                v19 = cross(cross(v17.direction, { 0, 1, 0, 0 }), v17.direction)

                if v19[2] < 0 then
                    v19 = scale(v19, -1)
                end

                local v25 = if length_square(dot(v19, v19)) > 9.999999974752427E-07 then unit(v19) else { 0, 1, 0, 0 }
                local v26 = StaticProvider.metadata(p10, v17.primitive)

                if v26 == nil then
                    error("Accepted grind primitive lacks native metadata", 0)
                end

                local flags = v26.flags

                t6.target = {
                    edge = v18,
                    provider_index = v17.primitive,
                    primitive_flags = flags,
                    orientation = t9,
                    point = rt.copy(v17.point),
                    vertical_normal = v25
                }
                t6.score = p6.score

                return t6
            end
        end
    end

    return t6
end

function dot(p16, p17) -- line: 244
    return p16[1] * p17[1] + p16[2] * p17[2] + p16[3] * p17[3]
end

t1.dot = dot

function graph8(p18, p19, p20, p21) -- line: 250
    -- upvalues: v1 (copy), Collections (copy)
    local v27 = if p21 then "Sk8::PointNegGraphData8" else "Sk8::PointGraphData8"

    if Collections.field(p18, p19, "default", p20).type_name ~= v27 then
        error(string.format("Wrong stock graph type %s/%s", p19, p20), 0)
    end

    local v28 = Collections.words(p18, 20, p19, "default", p20)
    local t10 = {}

    buffer.writeu32(v1, 0, v28[5])

    local v30 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[6])

    local v32 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[7])

    local v34 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[8])

    local v36 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[9])

    local v38 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[10])

    local v40 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[11])

    local v42 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[12])
    t10.x = {
        v30,
        v32,
        v34,
        v36,
        v38,
        v40,
        v42,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v28[13])

    local v45 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[14])

    local v47 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[15])

    local v49 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[16])

    local v51 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[17])

    local v53 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[18])

    local v55 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[19])

    local v57 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v28[20])
    t10.y = {
        v45,
        v47,
        v49,
        v51,
        v53,
        v55,
        v57,
        (buffer.readf32(v1, 0))
    }

    return t10
end

t1.graph8 = graph8

function sub(p22, p23) -- line: 281
    return {
        p22[1] - p23[1],
        p22[2] - p23[2],
        p22[3] - p23[3],
        p22[4] - p23[4]
    }
end

t1.sub = sub

function scale(p24, p25) -- line: 286
    return {
        p24[1] * p25,
        p24[2] * p25,
        p24[3] * p25,
        p24[4] * p25
    }
end

t1.scale = scale

function cross(p26, p27) -- line: 291
    return {
        -p26[3] * p27[2] + p26[2] * p27[3],
        -p26[1] * p27[3] + p26[3] * p27[1],
        -p26[2] * p27[1] + p26[1] * p27[2],
        0
    }
end

t1.cross = cross

local function inverse(p28) -- line: 301
    local v59 = 1 / math.sqrt(p28)
    local v60 = v59 * 0.5 * (-p28 * (v59 * v59) + 1) + v59

    return v60 * 0.5 * (-p28 * (v60 * v60) + 1) + v60
end

t1.inverse = inverse

function length_square(p29) -- line: 310
    -- upvalues: inverse (copy)
    if p29 == 0 then
        return 0
    end

    return p29 * inverse(p29)
end

t1.length_square = length_square

function unit(p30) -- line: 319
    -- upvalues: dot (ref), scale (ref), length_square (ref), inverse (copy)
    local v61 = dot(p30, p30)

    if length_square(v61) > 9.999999974752427E-07 then
        return scale(p30, inverse(v61))
    end

    return table.create(4, 0)
end

t1.unit = unit

return t1
