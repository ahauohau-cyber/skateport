-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/grind_contact")
local v2 = import("skate_core/physics/grind_contact/arithmetic")
local v3 = import("skate_core/physics/grind_contact/admission")
local v4 = import("skate_core/air/trajectory/grind_surface")
local v5 = import("skate_core/point_graph")
local v6 = import("skate_core/trigonometry")
local EntryKind = v3.EntryKind
local cross, dot3, scale, sub = v1.cross, v1.dot3, v1.scale, v1.sub
local GeometryType = v4.GeometryType
local PointGraph = v5.PointGraph
local v7, v8, v9, v10, v11
local t1 = {}

t1.BalanceState = {}

function t1.BalanceState.default() -- line: 41
    return {
        elapsed = 0,
        exit_angle_degrees = 0,
        entry_delay = 2,
        frames_away = 21,
        previous_normal = { 0, 1, 0, 0 },
        exit_direction = { 1, 0, 0, 0 }
    }
end

t1.BalanceContact = {}
t1.TargetUpInput = {}
t1.ExitLeanInput = {}
t1.BalanceVectors = {}
t1.ForceExitProbe = {}
t1.ForceExitHit = {}

function t1.BalanceState.update_target_up(p1, p2, p3, p4) -- line: 89
    -- upvalues: rt (copy), v2 (copy), v6 (copy), cross (copy), dot3 (copy), scale (copy), v7 (ref), v8 (ref), v11 (ref)
    if p3 == nil then
        return
    end

    local surface = p3.surface
    local v12 = if p2.category ~= 400 then p2.board_up elseif p2.previous_state == 402 or p2.previous_state == 404 then v8(p1.previous_normal, 0.85, surface.upmost_normal, 0.1499999761581421) else v8(p1.previous_normal, 0.925, surface.tilted_upmost_normal, 0.07499998807907104)
    local directed_grind_direction = p3.directed_grind_direction
    local v13 = cross(cross(directed_grind_direction, v12), directed_grind_direction)
    local v14 = v7(v13)

    if v14 <= 0.001 then
        p4.grind_normal = rt.copy(surface.upmost_normal)
    else
        p4.grind_normal = scale(v13, v2.reciprocal(v14))
    end

    p1.previous_normal = rt.copy(p4.grind_normal)

    local v15 = v8(p2.board_up, 0.8, surface.upmost_normal, 0.19999998807907104)

    p4.target_up = scale(v15, v2.reciprocal(v7(v15)))

    local v16 = rt.fmin(rt.fmax(dot3(p4.grind_normal, p4.target_up), -1), 1)

    if not (v6.acos(v16) > 0.24434609711170197) then
        return
    end

    local v17 = cross(p4.grind_normal, p4.target_up)
    local v18 = v7(v17)

    if v18 <= 0.001 then
        p4.target_up = rt.copy(p4.grind_normal)
    else
        p4.target_up = v11(scale(v17, v2.reciprocal(v18)), p4.grind_normal, 0.24434609711170197)
    end
end

function t1.BalanceState.update_exit_lean(p5, p6, p7, p8, p9) -- line: 132
    -- upvalues: rt (copy), EntryKind (copy), cross (copy), GeometryType (copy), PointGraph (copy), v9 (ref), v10 (ref), v11 (ref)
    local v19 = p6.category == 400 or p6.current_state == 701 or p7 ~= nil

    if v19 then
        p5.frames_away = 0
    else
        p5.frames_away = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p5.frames_away), rt.to_u32(1)))
    end

    local v20 = p7 ~= nil and (if p7.kind == 2 then v19 and p7.surface.kind ~= GeometryType.ThinRail else p7.surface.kind == GeometryType.Ledge)
    local v21

    if p5.frames_away > 20 then
        p5.exit_angle_degrees = 0
        p5.elapsed = 0
        v21 = false
        p5.entry_delay = 2
    else
        local v22 = false

        if p5.elapsed > 0 then
        elseif not v19 or not v20 or p7 == nil then
            v21 = false
            v22 = true
        end

        if not v22 then
            local v23 = false

            if p5.elapsed == 0 then
                if p7 ~= nil then
                    if p7.entry_kind == EntryKind.RideFromBelow then
                        p5.entry_delay = 0.8
                    elseif p7.entry_kind == EntryKind.RideIntoCoping then
                        p5.entry_delay = 0.1
                    else
                        p5.entry_delay = 2
                    end
                end

                v23 = true
            end

            v21 = v23

            if p6.grind_substate ~= 2 then
                p5.elapsed = p6.timestep + p5.elapsed
            end
        end
    end

    if not (p5.elapsed <= 0) then
        local v24 = p5.elapsed - p5.entry_delay

        if v24 <= 0 then
            p5.exit_angle_degrees = 0
        else
            p5.exit_angle_degrees = PointGraph.evaluate(p8, v24)
        end

        if p7 ~= nil then
            local surface = p7.surface

            if surface.kind == GeometryType.ThinRail then
                p5.exit_direction = v10(p5.exit_direction, cross(surface.upmost_normal, p7.primitive_direction))
            elseif v21 then
                p5.exit_direction = rt.copy(surface.high_side)
            else
                p5.exit_direction = v10(p5.exit_direction, surface.high_side)
            end

            if p5.exit_angle_degrees > 0 then
                local directed_grind_direction = p7.directed_grind_direction

                if not (cross(directed_grind_direction, p5.exit_direction)[2] > 0) then
                    directed_grind_direction = v9(directed_grind_direction)
                end

                local v25 = p5.exit_angle_degrees * 0.01745329238474369

                p9.target_up = v11(directed_grind_direction, p9.target_up, v25)
                p9.grind_normal = v11(directed_grind_direction, p9.grind_normal, v25)
            end
        end
    end

    return p5.exit_angle_degrees
end

function t1.BalanceState.update_force_exit(p10, p11, p12, p13) -- line: 214
    -- upvalues: v1 (copy), dot3 (copy), scale (copy), sub (copy)
    local v26 = false

    if p10.exit_angle_degrees > 28 then
        v26 = true
    elseif p10.exit_angle_degrees > 15 then
        local v27 = sub(p11, scale(p10.exit_direction, 0.1))
        local v28 = p13({
            start = v27,
            ["end"] = v1.add(v27, { 0, -5, 0, 0 })
        })

        v26 = v28 == nil or dot3(p10.exit_direction, v28.normal) > -0.1
    end

    return (bit32.bor(bit32.band(p12, 2147483647), (bit32.lshift(if v26 then 1 else 0, 31))))
end

v7 = function(p14) -- line: 240
    -- upvalues: v2 (copy), dot3 (copy)
    return v2.square_root(dot3(p14, p14))
end

t1.magnitude = v7

v8 = function(p15, p16, p17, p18) -- line: 245
    return {
        p15[1] * p16 + p17[1] * p18,
        p15[2] * p16 + p17[2] * p18,
        p15[3] * p16 + p17[3] * p18,
        p15[4] * p16 + p17[4] * p18
    }
end

t1.blend = v8

v9 = function(p19) -- line: 255
    return {
        -p19[1],
        -p19[2],
        -p19[3],
        -p19[4]
    }
end

t1.negate = v9

v10 = function(p20, p21) -- line: 260
    -- upvalues: rt (copy), dot3 (copy), v9 (ref)
    if dot3(p20, p21) > 0 then
        return rt.copy(p21)
    end

    return v9(p21)
end

t1.retain_side = v10

v11 = function(p22, p23, p24) -- line: 271
    -- upvalues: v6 (copy), cross (copy), scale (copy)
    local v32, v33 = v6.sin_cos(p24 * 0.5)
    local v34 = scale(p22, v32)
    local v35 = cross(v34, p23)
    local v36 = cross(v34, {
        p23[1] * v33 + v35[1],
        p23[2] * v33 + v35[2],
        p23[3] * v33 + v35[3],
        p23[4] * v33 + v35[4]
    })

    return {
        v36[1] * 2 + p23[1],
        v36[2] * 2 + p23[2],
        v36[3] * 2 + p23[3],
        v36[4] * 2 + p23[4]
    }
end

t1.rotate = v11

return t1
