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
local v2 = import("skate_core/air/trajectory/grind_surface")
local v3 = import("skate_core/physics/skeleton_animation_record")
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local SkeletonCollisionMode = import("skate_core/physics/skeleton_body").SkeletonCollisionMode
local PointGraph = import("skate_core/point_graph").PointGraph
local v4 = import("skate_game/physics/footplant/math")
local v5 = import("skate_game/physics/handplant/contact")
local v6 = import("skate_game/physics/handplant/ik")
local v7 = import("skate_game/physics/handplant/settings")
local v8 = import("skate_game/physics/handplant/trajectory")
local Settings = v7.Settings
local IDENTITY, compose_affine = v3.IDENTITY, v3.compose_affine
local GeometryType = v2.GeometryType
local STEP, dot, cross, normalize = v4.STEP, v4.dot, v4.cross, v4.normalize
local reciprocal = v4.reciprocal
local t1 = {}

local function plant_skeleton() -- line: 43
    -- upvalues: import (copy)
    return import("skate_game/physics/plant_skeleton")
end

local function grind_world_query() -- line: 46
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input/grind/world")
end

local function grind_world() -- line: 49
    -- upvalues: import (copy)
    return import("skate_game/grind_world")
end

local function air_reckoning() -- line: 52
    -- upvalues: import (copy)
    return import("skate_game/physics/air_reckoning")
end

local function from_bits4(p2) -- line: 56
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2[1])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[2])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[3])

    local v14 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[4])

    return {
        v10,
        v12,
        v14,
        (buffer.readf32(v1, 0))
    }
end

t1.UP = { 0, 1, 0, 0 }

local UP = t1.UP

t1.GRAVITY = { 0, -9.800000190734863, 0, 0 }

local GRAVITY = t1.GRAVITY

t1.EMPTY = {
    duration = -1,
    position = { 0, 0, 0, 0 },
    velocity = { 0, 0, 0, 0 },
    acceleration = { 0, 0, 0, 0 }
}

local EMPTY = t1.EMPTY

t1.Handplant = {}

function t1.Handplant.load(p3) -- line: 104
    -- upvalues: rt (copy), Settings (copy), IDENTITY (copy), EMPTY (copy)
    return {
        flags = 0,
        pending = nil,
        candidate = nil,
        travel_sign = 0,
        elapsed = -1,
        warped = -1,
        apex = -1,
        estimated_phase = -1,
        out_duration = 0,
        continuation = true,
        direction_hint = 0,
        direction_count = 0,
        ik_blend = 0,
        ik_distance = -1,
        ik_released = false,
        ik_latched = false,
        settings = Settings.load(p3),
        phase = rt.F32_MAX,
        anchor = { 0, 0, 0, 0 },
        previous_candidate_point = { 0, 0, 0, 0 },
        initial = rt.copy(EMPTY),
        entry = rt.copy(EMPTY),
        outgoing = {
            rt.copy(EMPTY),
            rt.copy(EMPTY)
        },
        curve = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        },
        rotations = rt.filled(4, IDENTITY),
        direction = { 0, 0, 0, 0 }
    }
end

function t1.Handplant.animation_thresholds(p4) -- line: 140
    -- upvalues: rt (copy)
    return rt.copy(p4.settings.animation)
end

function t1.Handplant.reset(p5) -- line: 145
    -- upvalues: rt (copy)
    p5.flags = bit32.band(p5.flags, 1342177279)
    p5.phase = rt.F32_MAX
    p5.anchor = { 0, 0, 0, 0 }
    p5.pending = nil
    p5.candidate = nil
    p5.elapsed = -1
    p5.warped = -1
    p5.apex = -1
    p5.estimated_phase = -1
    p5.out_duration = 0
    p5.direction = { 0, 0, 0, 0 }
    p5.continuation = true
end

function t1.Handplant.full_reset(p6) -- line: 160
    -- upvalues: t1 (copy)
    t1.Handplant.reset(p6)
    t1.Handplant.reset_ik(p6)
    p6.direction_hint = 0
    p6.direction_count = 0
end

function t1.Handplant.reset_ik(p7) -- line: 168
    p7.ik_blend = 0
    p7.ik_distance = -1
    p7.ik_released = false
    p7.ik_latched = false
end

function t1.Handplant.estimate_apex(p8) -- line: 176
    -- upvalues: PointGraph (copy)
    local v16 = p8.warped - p8.apex
    local v18 = math.abs(v16 * 0.3333333432674408)
    local n1 = 0

    for i = 0, 3 do
        n1 += 1 + PointGraph.evaluate(p8.settings.time_warp, v16 + i * v18)
    end

    local v19 = n1 * 0.25

    if v19 ~= 0 then
        p8.estimated_phase = -1 / v19 * v16
    end

    p8.phase = p8.estimated_phase
end

function t1.apex_time(p9) -- line: 192
    -- upvalues: reciprocal (copy)
    if p9.velocity[2] < 0 or p9.acceleration[2] >= 0 then
        return 0
    end

    return p9.velocity[2] * reciprocal(-p9.acceleration[2])
end

function t1.ground_update(p10, p11) -- line: 202
    -- upvalues: rt (copy), import (copy), v2 (copy), v6 (copy), GeometryType (copy), t1 (copy)
    local processed = p11.player_input.processed

    if bit32.band(processed.flags_2476, 4194304) == 0 then
        t1.Handplant.full_reset(p11.handplant)
    else
        local pending = p11.handplant.pending

        p11.handplant.pending = nil

        if pending ~= nil then
            local v20 = pending[1]
            local v21 = pending[2]
            local v22 = pending[3]
            local v23 = pending[4]
            local v24 = pending[5]
            local t2 = {
                start = rt.copy(v20.edge.start),
                ["end"] = rt.copy(v20.edge["end"]),
                reference = rt.copy(v20.point),
                optional_probe = nil,
                deck_center_to_truck = p11.handplant.settings.truck_distance
            }
            local v25 = v2.investigate(t2, function(p12, p13) -- line: 221
                -- upvalues: p10 (copy), processed (copy), import (copy)
                return import("skate_game/physics/player_input/grind/world").surface_probe(p10.world, {
                    processed.actor_query_2948,
                    processed.actor_query_2952
                }, p12, p13)
            end)

            if v2.prepare(t2) ~= nil and v25.kind ~= GeometryType.Impossible then
                t1.Handplant.launch(p11.handplant, v20, v21, v22, v23, v24, rt.copy(p10.riding.reckoning_frames.heading))
            end
        end

        if bit32.band(p11.handplant.flags, 2147483648) ~= 0 then
            v6.update(p11, true)
        end
    end
end

function t1.trace_solved(_, _) -- line: 250
end

function t1.ground_query(p16, p17) -- line: 258
    -- upvalues: rt (copy), import (copy), v5 (copy), dot (copy), cross (copy), normalize (copy), t1 (copy), from_bits4 (copy), UP (copy)
    local processed = p17.player_input.processed

    if bit32.band(processed.flags_2476, 4194304) == 0 then
        t1.Handplant.full_reset(p17.handplant)
    else
        local handplant = p17.handplant
        local v26 = from_bits4(processed.vectors_544_560_592_608[3])
        local v27 = from_bits4(processed.vectors_400_416[1])
        local v28 = from_bits4(processed.vectors_464_480_496_512_528[1])
        local v29 = from_bits4(processed.vectors_544_560_592_608[2])
        local v30 = bit32.band(processed.flags_2480, 536870912) == 0
        local v31 = if v30 then bit32.band(processed.flags_2480, 268435456) == 0 else nil

        if not v30 or v31 then
            handplant.direction_hint = 0
            handplant.direction_count = 0
        elseif v28[2] < 0.95 then
            if handplant.direction_hint == 0 then
                if handplant.candidate ~= nil then
                    handplant.direction_hint = handplant.candidate.side
                else
                    handplant.direction_hint = 0
                end
            end

            local v32 = if dot(v27, normalize(cross(UP, v28))) > 0 then 1 else 2

            if handplant.direction_hint == v32 then
                handplant.direction_count = 0
            else
                handplant.direction_count += 1

                if handplant.direction_count > handplant.settings.direction_frames then
                    handplant.direction_hint = 0
                end
            end
        else
            handplant.direction_hint = 0
            handplant.direction_count = 0
        end

        local v33 = v5.select(handplant.settings, v26, v27, v28, handplant.direction_hint, import("skate_game/grind_world").StaticProvider.primitives(p16.grind_world))
        local v34 = if handplant.candidate == nil then { 0, 0, 0, 0 } else rt.copy(handplant.candidate.point)
        local direction_hint, direction_count = handplant.direction_hint, handplant.direction_count

        t1.Handplant.reset(handplant)
        handplant.previous_candidate_point = v34
        handplant.direction_hint = direction_hint
        handplant.direction_count = direction_count
        handplant.candidate = v33

        if v33 ~= nil then
            handplant.pending = {
                rt.copy(v33),
                v26,
                v27,
                v28,
                v29
            }
        else
            handplant.pending = nil
        end
    end
end

function t1.enter(p18, p19) -- line: 319
    -- upvalues: rt (copy), BoardRuntime (copy), HookDriveState (copy), t1 (copy), from_bits4 (copy), GRAVITY (copy)
    p19.ground_lifecycle.board_animated_290 = HookDriveState.enable_angular_only(BoardRuntime.hook_mut(p18.board).drive, p19.ground_lifecycle.board_animated_290)

    local processed = p19.player_input.processed
    local handplant = p19.handplant

    handplant.entry = {
        duration = -1,
        position = from_bits4(processed.vectors_544_560_592_608[3]),
        velocity = from_bits4(processed.vectors_544_560_592_608[4]),
        acceleration = rt.copy(GRAVITY)
    }
    handplant.warped = 0
    handplant.elapsed = 0
    handplant.continuation = true
    t1.Handplant.select_outgoing(handplant, p18.world)
end

function t1.update(p20, p21) -- line: 339
    -- upvalues: import (copy), SkeletonCollisionMode (copy), PointGraph (copy), v6 (copy), compose_affine (copy), STEP (copy), t1 (copy), from_bits4 (copy)
    SkeletonCollisionMode.disable_handplant_contacts(p21.skeleton_collision, 2)

    local handplant = p21.handplant

    handplant.warped += (1 + PointGraph.evaluate(handplant.settings.time_warp, handplant.warped - handplant.apex)) * STEP
    t1.Handplant.estimate_apex(handplant)
    handplant.elapsed += STEP

    local animation_to_world = p21.animated_skeleton.roots.animation_to_world
    local pose = p21.animated_skeleton.record.pose
    local v35 = table.create(#pose)

    for v36, v37 in pose do
        v35[v36] = compose_affine(animation_to_world, v37)
    end

    local v38, v39, v40 = t1.Handplant.values(handplant, v35, (from_bits4(p21.player_input.processed.vectors_544_560_592_608[3])))

    import("skate_game/physics/air_reckoning").AirReckoning.update_plant(p21.air_reckoning, p20.riding, p21.player_input.processed, v39, v40)
    v6.update(p21, false)
    import("skate_game/physics/plant_skeleton").advance(p20, p21, v38, nil)
end

for v41, v42 in v8.Handplant do
    t1.Handplant[v41] = v42
end

return t1
