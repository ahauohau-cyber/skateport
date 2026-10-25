-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/grind_contact")
local v2 = import("skate_core/physics/grind_contact/arithmetic")
local v3 = import("skate_core/physics/grind_contact/admission")
local v4 = import("skate_core/point_graph")
local dot3, scale, sub = v1.dot3, v1.scale, v1.sub
local PointGraph = v4.PointGraph
local v5
local t1 = {}

function t1.directed_tangent(p1, p2, p3, p4) -- line: 23
    -- upvalues: v2 (copy), dot3 (copy), scale (copy), sub (copy)
    local v6 = sub(p2, p1)
    local v7 = scale(v6, v2.reciprocal(v2.square_root(dot3(v6, v6))))
    local v8 = dot3(v7, p3)

    if v8 < 0 then
        v7 = scale(v7, -1)
    end

    if math.abs(v8) < 0.1 and dot3(p4, v7) < -0.9 then
        v7 = scale(v7, -1)
    end

    return v7
end

t1.GeometryInput = {}
t1.GeometryOutput = {}

function t1.tweak_geometry(p5, p6) -- line: 64
    -- upvalues: rt (copy), dot3 (copy), scale (copy), sub (copy), v5 (ref)
    local t2 = {
        valid = p5.valid,
        family = p5.family,
        flags = p5.flags
    }
    local v9 = p5.geometry_kind ~= 3 and (if p5.family ~= 2 or bit32.band(p5.geometry_flags, 268435456) == 0 or p5.category == 400 then p5.family ~= 1 or bit32.band(p5.geometry_flags, 268435456) == 0 else not (p5.air_frames < 20) and (p5.family ~= 1 or bit32.band(p5.geometry_flags, 268435456) == 0))

    if not v9 then
        t2.valid = false
    end

    if t2.valid and v5(p5) then
        t2.family = 4
    end

    if t2.valid and p5.previous_exit_angle > 0 and p5.geometry_kind ~= 2 and dot3(p5.previous_exit_direction, p5.high_side) < 0 then
        t2.valid = false
    end

    if t2.valid and p5.geometry_kind ~= 0 then
        local v10 = sub(scale(p5.direction, dot3(p5.direction, p5.velocity)), p5.velocity)

        v10[2] = 0

        if dot3(v10, v10) > 12.25 and dot3(p5.velocity, p5.high_side) < 0 then
            t2.valid = false
        end
    end

    local v11

    if t2.family ~= 3 or p5.geometry_kind ~= 2 then
        v11 = p6

        return t2, v11
    end

    v11 = p6

    if rt.to_i32(p6) > 0 then
        t2.valid = false
    else
        local v12 = if bit32.band(t2.flags, 536870912) == 0 then p5.board_forward else scale(p5.board_forward, -1)

        if dot3(v12, p5.high_side) > 0 then
            local v13 = dot3(v12, p5.upmost)

            t2.flags = bit32.bor(bit32.band(t2.flags, 4026531839), v13 < 0.19 and 268435456 or 0)

            if v13 < 0 then
                v11 = 30
                t2.valid = false
            end
        end
    end

    return t2, v11
end

v5 = function(p7) -- line: 119
    -- upvalues: dot3 (copy), sub (copy)
    if p7.family ~= 2 or p7.current_state == 402 then
        return false
    end

    if bit32.band(p7.geometry_flags, 2147483648) == 0 then
        local t3 = {
            sub(p7.far_points[1], p7.point),
            sub(p7.far_points[2], p7.point)
        }
        local t4 = {
            dot3(t3[1], p7.upmost),
            dot3(t3[2], p7.upmost)
        }

        if math.abs(t4[1] - t4[2]) <= p7.deck_to_truck * 0.1 then
            return false
        end

        local v17 = if t4[1] > t4[2] then t3[1] else t3[2]

        return dot3(sub(p7.board_position, p7.point), v17) > 0
    end

    return false
end

t1.is_backslash = v5

function t1.gravity_relief(p8, p9, p10, p11, p12, p13, p14, p15) -- line: 141
    -- upvalues: v3 (copy), dot3 (copy), PointGraph (copy)
    local v21 = (if p9 and p10 == 100 and v3.engagement_slope_sine(p11, p12) > 0.85 then PointGraph.evaluate(p14, p12[2]) * PointGraph.evaluate(p15, (math.abs((dot3(p11, p12))))) else p8) - p13

    if -v21 >= 0 then
        v21 = 0
    end

    return v21, v21
end

t1.JumpGeometry = {}
t1.Jumper = {}

function t1.Jumper.default() -- line: 167
    return {
        launched = false,
        cooldown = 0,
        family = 3,
        energy = 1,
        geometry = {
            geometry_kind = 0,
            high_side = { 1, 0, 0, 0 },
            normal = { 0, 1, 0, 0 },
            direction = { 1, 0, 0, 0 },
            upmost = { 0, 1, 0, 0 },
            point = { 0, 0, 0, 0 }
        }
    }
end

function t1.Jumper.update(p16, p17, p18) -- line: 187
    -- upvalues: rt (copy)
    p16.launched = false

    local v22 = rt.wrapping_sub_u32(p16.cooldown, 1)

    p16.cooldown = if rt.to_i32(v22) < 0 then 0 else v22

    if p17 ~= nil then
        p16.geometry = rt.copy(p17)
    end

    if p18 ~= 4294967295 then
        p16.family = p18
    end

    local v23 = p16.energy + 0.0035

    p16.energy = if not (1 - v23 >= 0) then 1 else v23

    if p16.cooldown > 0 then
        return 33554432
    end

    return 0
end

return t1
