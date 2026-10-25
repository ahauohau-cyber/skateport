-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_from_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p3) -- line: 20
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v6 = math.abs(p3) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p3 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local v9 = import("skate_core/physics/manual/controller")
local PointGraph = import("skate_core/point_graph").PointGraph
local v10 = import("skate_core/riding/anti_flip")
local signed_angle = import("skate_core/riding/collision_response").signed_angle
local v11 = import("skate_core/riding/pumping")
local Requests = import("skate_core/player/wipeout").Requests
local Collections = import("skate_data/collections").Collections

local function ground_runtime() -- line: 49
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local function input_phase() -- line: 52
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function riding_outputs() -- line: 55
    -- upvalues: import (copy)
    return import("skate_game/physics/riding_outputs")
end

local t1 = {}
local dot, xyz

local function map_from_bits(p4) -- line: 66
    -- upvalues: v1 (copy)
    local v12 = table.create(#p4)

    for i = 1, #p4 do
        buffer.writeu32(v1, 0, p4[i])
        v12[i] = buffer.readf32(v1, 0)
    end

    return v12
end

local function debug_fmt(p5) -- line: 75
    -- upvalues: debug_fmt (copy)
    if type(p5) ~= "table" or p5.tag == nil then
        return (tostring(p5))
    end

    local t2 = {}

    for _, v14 in ipairs(p5) do
        table.insert(t2, debug_fmt(v14))
    end

    if #t2 > 0 then
        return p5.tag .. "(" .. table.concat(t2, ", ") .. ")"
    end

    return p5.tag
end

buffer.writef32(v1, 0, 3.141592653589793)

local v15 = buffer.readf32(v1, 0)

buffer.writef32(v1, 0, 6.283185307179586)

local v16 = buffer.readf32(v1, 0)

t1.RevertState = {}

function t1.RevertState.load(p6) -- line: 100
    -- upvalues: rt (copy), v1 (copy), Collections (copy)
    local v17 = Collections.words(p6, "Hash_018E8A2E5028AB3F", "default", "Hash_DAA990E803A782A1", 20)
    local v18 = table.create(#v17)

    for i = 1, #v17 do
        buffer.writeu32(v1, 0, v17[i])
        v18[i] = buffer.readf32(v1, 0)
    end

    local v20 = Collections.words(p6, "Hash_018E8A2E5028AB3F", "default", "Hash_3387562E9BEA0AF6", 12)
    local v21 = table.create(#v20)

    for i = 1, #v20 do
        buffer.writeu32(v1, 0, v20[i])
        v21[i] = buffer.readf32(v1, 0)
    end

    return {
        direction = 0,
        travel_sign = 1,
        elapsed = 0,
        captured = false,
        active = false,
        speed = {
            x = rt.slice(v18, 4, 12),
            y = rt.slice(v18, 12, 20)
        },
        tolerance = {
            x = rt.slice(v21, 4, 8),
            y = rt.slice(v21, 8, 12)
        },
        gain = Collections.float(p6, "Hash_018E8A2E5028AB3F", "default", "Hash_0E5B939FD4ECDBAA"),
        delay = Collections.float(p6, "Hash_018E8A2E5028AB3F", "default", "Hash_6BF6544475D2A5AD"),
        duration = Collections.float(p6, "Hash_018E8A2E5028AB3F", "default", "Hash_035D9805EB9E2EE2"),
        velocity = { 0, 0, 0, 0 }
    }
end

function t1.RevertState.correction(p7, p8, p9, p10) -- line: 132
    -- upvalues: v1 (copy), PointGraph (copy), signed_angle (copy), dot (ref), xyz (ref), v15 (copy), v16 (copy)
    if not p7.captured then
        return { 0, 0, 0, 0 }
    end

    local t3 = {
        p8[1] * p7.travel_sign,
        p8[2] * p7.travel_sign,
        p8[3] * p7.travel_sign,
        p8[4] * p7.travel_sign
    }

    local function project(p11) -- line: 143
        -- upvalues: p9 (copy), dot (ref)
        local v23 = dot(p11, p9)

        return {
            p11[1] - p11[1] * v23,
            p11[2] - p11[2] * v23,
            p11[3] - p11[3] * v23,
            p11[4] - p11[4] * v23
        }
    end

    local v24 = project(p7.velocity)
    local v25 = project(t3)

    if dot(v24, v24) * dot(v25, v25) <= 1.52587890625E-05 then
        return { 0, 0, 0, 0 }
    end

    local function normalize(p12) -- line: 152
        -- upvalues: dot (ref)
        local v27 = math.sqrt((dot(p12, p12)))

        return {
            p12[1] / v27,
            p12[2] / v27,
            p12[3] / v27,
            p12[4] / v27
        }
    end

    local v28 = signed_angle(xyz((normalize(v24))), xyz((normalize(v25))), xyz(p9))
    local v29

    if v28 ~= 0 and v28 > -1.1754943508222875E-38 and v28 < 1.1754943508222875E-38 then
        local v30 = math.abs(v28) * 7.1362384635298E+44
        local v31 = math.floor(v30)
        local v32 = v30 - v31

        v29 = (if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31) * 1.401298464324817E-45

        if v28 < 0 then
            v29 = -v29
        end
    else
        buffer.writef32(v1, 0, v28)
        v29 = buffer.readf32(v1, 0)
    end

    if v15 <= v29 then
        local v33 = v29 - v16

        if v33 ~= 0 and v33 > -1.1754943508222875E-38 and v33 < 1.1754943508222875E-38 then
            local v34 = math.abs(v33) * 7.1362384635298E+44
            local v35 = math.floor(v34)
            local v36 = v34 - v35

            v29 = (if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35) * 1.401298464324817E-45

            if v33 < 0 then
                v29 = -v29
            end
        else
            buffer.writef32(v1, 0, v33)
            v29 = buffer.readf32(v1, 0)
        end
    end

    if v29 * p7.direction > 0 then
        local v37 = v29 - p7.direction * v16

        if v37 ~= 0 and v37 > -1.1754943508222875E-38 and v37 < 1.1754943508222875E-38 then
            local v38 = math.abs(v37) * 7.1362384635298E+44
            local v39 = math.floor(v38)
            local v40 = v38 - v39

            v29 = (if v40 > 0.5 or v40 == 0.5 and v39 % 2 == 1 then v39 + 1 else v39) * 1.401298464324817E-45

            if v37 < 0 then
                v29 = -v29
            end
        else
            buffer.writef32(v1, 0, v37)
            v29 = buffer.readf32(v1, 0)
        end
    end

    local v41 = PointGraph.evaluate(p7.speed, (math.abs(v29))) * p7.direction

    if math.abs(v29) < PointGraph.evaluate(p7.tolerance, p9[2]) * 0.01745329238474369 or math.abs(v29) > 4.5 then
        p7.active = false
    end

    local v42 = dot(p10, p9)
    local v43 = if not (v42 * v41 > 0 and math.abs(v42) > math.abs(v41)) then (v41 - v42) * p7.gain else 0

    return {
        p9[1] * v43,
        p9[2] * v43,
        p9[3] * v43,
        p9[4] * v43
    }
end

function t1.enter(p13, p14) -- line: 183
    -- upvalues: BoardRuntime (copy), HookDriveState (copy), Requests (copy)
    p14.ground_lifecycle.skeleton_elapsed_16505 = true
    p14.ground_lifecycle.board_animated_290 = HookDriveState.disable_animation(BoardRuntime.hook_mut(p13.board).drive, p14.ground_lifecycle.board_animated_290)

    local revert_state = p14.revert_state

    revert_state.direction = p14.animation_input.extra.revert_direction
    revert_state.velocity = { 0, 0, 0, 0 }
    revert_state.elapsed = 0
    revert_state.captured = false
    revert_state.active = true
    Requests.enter_ground(p14.wipeout.state)
end

function t1.update(p15, p16) -- line: 201
    -- upvalues: rt (copy), v1 (copy), import (copy), Vector3 (copy), BoardRuntime (copy), BoardForceQueue (copy), v9 (copy), v10 (copy), v11 (copy), t1 (copy), dot (ref), debug_fmt (copy)
    local processed, toolkit = p16.player_input.processed, p16.player_input.toolkit

    if toolkit == nil then
        error("Revert requires current BoardToolkit", 0)
    end

    local revert_state = p16.revert_state

    if not revert_state.captured and revert_state.elapsed >= revert_state.delay then
        revert_state.captured = true

        local v44 = processed.vectors_400_416[1]
        local v45 = table.create(#v44)

        for i = 1, #v44 do
            buffer.writeu32(v1, 0, v44[i])
            v45[i] = buffer.readf32(v1, 0)
        end

        revert_state.velocity = v45
        revert_state.travel_sign = dot(revert_state.velocity, toolkit.deck[3]) > 0 and -1 or 1
    end

    import("skate_game/physics/riding_outputs").RidingOutputs.update_slide_reckoning(p15.riding, processed, toolkit, p16.animation_input.extra.physical_body_spin, p16.animation_input.fields.balance)
    import("skate_game/physics/input_phase").update_ground(p15, p16)

    local processed2, toolkit2 = p16.player_input.processed, p16.player_input.toolkit

    if toolkit2 == nil then
        error("Revert requires current BoardToolkit", 0)
    end

    local GroundPumping = import("skate_game/physics/ground_runtime").GroundPumping

    GroundPumping.update_revert(p16.ground.pumping_settings, p16.ground.pumping, toolkit2, p15.riding, p16.animated_skeleton, processed2, p16.animation_input.fields.balance)

    local GroundSettings = import("skate_game/physics/ground_runtime").GroundSettings
    local v47 = GroundSettings.input(p16.ground_settings, toolkit2, processed2, p16.animation_input, p16.ground.pumping, GroundPumping.mode(p16.ground.pumping_settings, processed2.state_variant_index_2528).unintentional_scalar, p15.riding, p16.animated_skeleton, rt.copy(p15.settings.step.base_truck_transforms), {
        edge_flags = 0,
        manual_drag_2724 = p16.ground_lifecycle.manual_drag_2724,
        trajectory_state_bits = processed2.external_physics_1616.flags,
        edge_point = { 0, 0, 0, 0 }
    })
    local v48 = GroundSettings.board(p16.ground_settings)
    local correction = t1.RevertState.correction
    local revert_state2 = p16.revert_state
    local v49 = rt.copy(toolkit2.deck[3])
    local v50 = processed2.vectors_464_480_496_512_528[1]
    local v51 = table.create(#v50)

    for i = 1, #v50 do
        buffer.writeu32(v1, 0, v50[i])
        v51[i] = buffer.readf32(v1, 0)
    end

    local v53 = processed2.vectors_720_784_800_816_832_864[1]
    local v54 = table.create(#v53)

    for i = 1, #v53 do
        buffer.writeu32(v1, 0, v53[i])
        v54[i] = buffer.readf32(v1, 0)
    end

    local v56 = correction(revert_state2, v49, v51, v54)

    for _, v57 in BoardRuntime.bodies_mut(p15.board) do
        v57.inertia.linear_drag = 0
    end

    local v58 = v10.calculate(v48.anti_flip, v47.anti_flip)
    local v59 = v11.calculate(v47.pump_force)
    local GroundRuntime = import("skate_game/physics/ground_runtime").GroundRuntime
    local ground_runtime = p16.ground_runtime
    local t4 = {
        angle_between = function(_, p18, p19, p20) -- angle_between | line: 272
            -- upvalues: GroundRuntime (copy), ground_runtime (copy)
            return GroundRuntime.angle_between(ground_runtime, p18, p19, p20)
        end
    }
    local calculate = v9.calculate
    local manual = p16.ground.manual
    local manual2, manual_mode = v48.manual, v48.manual_mode
    local manual3 = v47.manual
    local ok, result = pcall(calculate, manual, manual2, manual_mode, manual3, t4)

    if not ok then
        error(string.format("Revert manual: %s", (debug_fmt(result))), 0)
    end

    for _, v60 in {
            v56,
            rt.copy(result.angular_displacement),
            v58
        } do
        GroundRuntime.apply_angular_displacement(p16.ground_runtime, p15.board, v60)
    end

    BoardForceQueue.append(BoardRuntime.forces_mut(p15.board), {
        tag = 8,
        force_world = Vector3.new(v59[1], v59[2], v59[3]),
        point_body = Vector3.new(v59[5], v59[6], v59[7])
    })
    p16.revert_state.elapsed += processed2.timestep_2604

    if p16.revert_state.elapsed > p16.revert_state.duration then
        p16.revert_state.active = false
    end
end

function dot(p21, p22) -- line: 297
    return p21[3] * p22[3] + (p21[2] * p22[2] + p21[1] * p22[1])
end

t1.dot = dot

function xyz(p23) -- line: 303
    -- upvalues: Vector3 (copy)
    return Vector3.new(p23[1], p23[2], p23[3])
end

t1.xyz = xyz

return t1
