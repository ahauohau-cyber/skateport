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
local v2 = import("skate_core/trigonometry")
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local PointGraph = import("skate_core/point_graph").PointGraph
local Requests = import("skate_core/player/wipeout").Requests
local v3 = import("skate_game/physics/footplant/math")
local STEP, dot, cross, add = v3.STEP, v3.dot, v3.cross, v3.add
local sub, scale, madd, reciprocal = v3.sub, v3.scale, v3.madd, v3.reciprocal
local length, normalize = v3.length, v3.normalize
local t1 = {}

local function footplant() -- line: 39
    -- upvalues: import (copy)
    return import("skate_game/physics/footplant")
end

local function air_phase() -- line: 42
    -- upvalues: import (copy)
    return import("skate_game/physics/air_phase")
end

local function plant_skeleton() -- line: 45
    -- upvalues: import (copy)
    return import("skate_game/physics/plant_skeleton")
end

local function air_trajectory() -- line: 48
    -- upvalues: import (copy)
    return import("skate_game/physics/air_trajectory")
end

local function solve() -- line: 51
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local function from_bits4(p2) -- line: 55
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2[1])

    local v5 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[2])

    local v7 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[3])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[4])

    return {
        v5,
        v7,
        v9,
        (buffer.readf32(v1, 0))
    }
end

function t1.enter(p3, p4) -- line: 60
    -- upvalues: import (copy), BoardRuntime (copy), HookDriveState (copy), from_bits4 (copy)
    p4.ground_lifecycle.board_animated_290 = HookDriveState.enable_angular_only(BoardRuntime.hook_mut(p3.board).drive, p4.ground_lifecycle.board_animated_290)

    for _, v11 in { 15, 16, 19, 20 } do
        p4.skeleton_collision.parts[v11 + 1].volume_group = 4
        p4.skeleton_collision.parts[v11 + 1].enabled = false
        p4.skeleton_collision.disable_count[v11 + 1] = 0
    end

    local processed = p4.player_input.processed
    local v12 = import("skate_game/physics/footplant").Footplant.start(p4.footplant, from_bits4(processed.vectors_544_560_592_608[3]), (from_bits4(processed.vectors_544_560_592_608[4])))

    if v12 == 0 then
        return
    end

    local t2 = if p4.footplant.selected_toe == 19 then { 19, 20, 21 } else { 15, 16, 17 }

    for _, v13 in t2 do
        p4.skeleton_collision.pending_reenable = true
        p4.skeleton_collision.disable_count[v13 + 1] = v12
        p4.skeleton_collision.parts[v13 + 1].enabled = false
    end
end

t1.Footplant = {}

function t1.Footplant.start(p5, p6, p7) -- line: 92
    -- upvalues: rt (copy), v2 (copy), PointGraph (copy), dot (copy), cross (copy), add (copy), sub (copy), scale (copy), madd (copy), reciprocal (copy), length (copy), normalize (copy)
    p5.perform = false
    p5.scalar_600 = 0
    p5.flag_627 = true

    local v14 = rt.copy(p5.adjusted_contact)

    p5.vectors_352_368[2] = rt.copy(v14)

    local v15 = sub(p6, v14)
    local v16 = normalize(v15)
    local v17 = PointGraph.evaluate(p5.settings.radial_speed_scale, length(scale(v16, dot(p7, v16))))
    local v18 = cross(v15, p7)
    local v19 = length(v18)

    if not (v19 > 1.52587890625E-05) then
        return 0
    end

    local v20 = scale(v18, reciprocal(v19))
    local v21 = v19 * v17
    local v22 = scale(v20, -1)
    local t3 = {
        0, 1, 0, 0
    }
    local v23 = normalize(sub(t3, scale(v22, dot(t3, v22))))
    local v24 = if length(v23) == 0 then 0 else v2.acos(rt.clamp(dot(v16, v23), -1, 1))

    if dot(cross(v16, v23), v22) < 0 then
        v24 = -v24
    end

    local v25 = v24 + v21 * p5.settings.min_duration
    local v26 = v24 + v21 * p5.settings.max_duration
    local v27 = rt.fmin(rt.fmax(v25, p5.settings.end_angle * 0.01745329238474369), v26) - v24

    p5.scalar_596 = v27 / v21

    local v28, v29 = v2.sin_cos(v27 * 0.5)
    local v30 = scale(v20, v28)
    local v31 = madd(cross(v30, madd(v16, v29, cross(v30, v16))), 2, v16)
    local v32 = madd(v31, p5.settings.end_leg_length, v14)
    local v33 = normalize(add(v31, v16))
    local v34 = madd(sub(p7, scale(v33, dot(p7, v33))), v17, scale(v33, p5.settings.release_outward_speed))

    p5.scalar_612 = length(v34)
    p5.vectors_352_368[1] = scale(v34, reciprocal(p5.scalar_612))
    p5.curve = {
        rt.copy(p6),
        madd(scale(p7, v17), p5.scalar_596 * p5.settings.start_handle, p6),
        sub(v32, scale(v34, p5.scalar_596 * p5.settings.end_handle)),
        v32
    }

    return rt.to_u32(4 - rt.f_to_i32(p5.scalar_596 * -59.999996185302734))
end

function t1.Footplant.adjust(p8, p9, p10) -- line: 153
    -- upvalues: rt (copy), dot (copy), add (copy), sub (copy), scale (copy), length (copy), normalize (copy)
    local v35 = (1 - p9) * 0.02 + p9 * 0.01
    local v36 = {
        p10[1] * v35,
        0,
        p10[2] * v35,
        0
    }
    local v37 = dot(v36, normalize(p8.current_up))

    if v37 > 0 then
        v36 = sub(v36, scale(p8.current_up, v37))
    end

    local v38 = rt.copy(p8.curve[4])

    p8.curve[4] = add(v38, v36)

    local v39 = normalize(sub(p8.curve[4], p8.curve[3]))

    p8.curve[3] = sub(p8.curve[4], scale(v39, length(sub(p8.curve[3], v38))))
    p8.vectors_352_368[1] = v39
end

function t1.update(p11, p12) -- line: 168
    -- upvalues: rt (copy), import (copy), STEP (copy), add (copy), scale (copy), madd (copy)
    local footplant = p12.footplant

    footplant.scalar_600 += STEP

    local v40 = footplant.scalar_600 / footplant.scalar_596

    import("skate_game/physics/footplant").Footplant.adjust(footplant, v40, rt.copy(p12.animation_input.extra.body_adjust))

    local v41 = 1 - v40
    local v42 = madd(footplant.curve[4], v40 * v40 * v40, madd(footplant.curve[3], 3 * v40 * v40 * v41, madd(footplant.curve[1], v41 * v41 * v41, scale(footplant.curve[2], 3 * v40 * v41 * v41))))
    local v43 = footplant.scalar_600 > footplant.scalar_596

    if v43 then
        footplant.flag_627 = false
    end

    local v44 = rt.copy(footplant.vectors_352_368[2])
    local v45 = scale(footplant.vectors_352_368[1], footplant.scalar_612)
    local v46 = footplant.selected_toe ~= 15

    import("skate_game/physics/plant_skeleton").hold_foot(p12, v46, v44, 0)
    import("skate_game/physics/plant_skeleton").advance(p11, p12, v42, nil)

    if not v43 then
        return
    end

    local v47 = import("skate_game/physics/air_phase").launch_info(p11, p12)

    v47.start_velocity = v45
    v47.start_position_override = add(v44, { 0, 0.2, 0, 0 })
    v47.board_position_override = add(v47.start_position_override, { 0, -0.1, 0, 0 })
    v47.use_position_override = true
    v47.player_jumped = true

    local v48 = import("skate_game/physics/air_phase").selector_input(p11, p12)
    local AirTrajectoryRuntime = import("skate_game/physics/air_trajectory").AirTrajectoryRuntime

    AirTrajectoryRuntime.launch(p12.trajectory, v47, rt.copy(v48), p11.world)
    AirTrajectoryRuntime.update(p12.trajectory, v48, p11.world, import("skate_game/physics/air_trajectory").GrindContext.from_processed(p12.player_input.processed, rt.copy(import("skate_game/physics/solve").deck_frame(p11.board)[4])))
end

function t1.post_physics(p13) -- line: 212
    -- upvalues: Requests (copy), dot (copy), sub (copy), scale (copy), length (copy), from_bits4 (copy)
    local processed = p13.player_input.processed
    local v49 = scale(from_bits4(processed.vectors_544_560_592_608[1]), -1)
    local v50 = from_bits4(processed.vectors_544_560_592_608[4])
    local v51 = dot(v50, v49)
    local v52 = length(sub(v50, scale(v49, v51)))

    if p13.footplant.settings.max_descending_speed < v51 then
        Requests.request(p13.wipeout.state, 6, v51)
    end

    if p13.footplant.settings.max_horizontal_speed < v52 then
        Requests.request(p13.wipeout.state, 23, 0)
    end
end

return t1
