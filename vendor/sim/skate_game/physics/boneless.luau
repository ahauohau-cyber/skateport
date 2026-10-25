-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/footplant/math")
local v2 = import("skate_game/physics/air_phase")
local v3 = import("skate_game/physics/air_trajectory")
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local PointGraph = import("skate_core/point_graph").PointGraph
local Collections = import("skate_data/collections").Collections
local sub, scale, dot, length = v1.sub, v1.scale, v1.dot, v1.length
local madd, normalize = v1.madd, v1.normalize
local AirTrajectoryRuntime = v3.AirTrajectoryRuntime

local function plant_skeleton() -- line: 28
    -- upvalues: import (copy)
    return import("skate_game/physics/plant_skeleton")
end

local function solve() -- line: 31
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local launch
local t1 = {}

t1.Boneless = {}

function t1.Boneless.load(p1) -- line: 47
    -- upvalues: rt (copy), Collections (copy)
    local function graph(p2) -- line: 48
        -- upvalues: p1 (copy), rt (copy), Collections (copy)
        local v4 = rt.map(Collections.words(p1, 20, "Hash_CCB95A83C78B4FF9", "default", p2), rt.from_bits)

        return {
            x = rt.slice(v4, 4, 12),
            y = rt.slice(v4, 12, 20)
        }
    end

    local t2 = {
        graph("Hash_6D781EFAF01E707D"),
        graph("Hash_C9112CCD0BCB1850"),
        graph("Hash_88D0CDEFA38A36D6"),
        (graph("Hash_9228B7F18C223F9C"))
    }

    return {
        toe = 15,
        right = false,
        anchor = table.create(4, 0),
        curves = t2
    }
end

function t1.enter(p3, p4) -- line: 70
    -- upvalues: rt (copy), BoardRuntime (copy), HookDriveState (copy)
    p4.ground_lifecycle.board_animated_290 = 1

    local drive = BoardRuntime.hook_mut(p3.board).drive

    drive.dynamics[1] = 1114636287
    drive.dynamics[2] = 0
    drive.dynamics[3] = 1163984894
    drive.dynamics[4] = 2
    HookDriveState.enable_angular_soft(drive)

    local v5 = bit32.band(p4.player_input.processed.flags_2468, 67108864) ~= 0

    p4.boneless.toe = v5 and 19 or 15
    p4.boneless.anchor = rt.copy(p4.skeleton.record.pose[p4.boneless.toe + 1][4])
    p4.boneless.right = v5
end

function t1.update(p5, p6) -- line: 87
    -- upvalues: rt (copy), import (copy), launch (ref)
    import("skate_game/physics/plant_skeleton").advance(p5, p6, rt.copy(p6.boneless.anchor), p6.boneless.toe)
    import("skate_game/physics/plant_skeleton").hold_foot(p6, p6.boneless.right, rt.copy(p6.boneless.anchor), 3)

    if bit32.band(p6.player_input.processed.flags_2480, 8192) ~= 0 then
        launch(p5, p6)
    end
end

function launch(p7, p8) -- line: 97
    -- upvalues: rt (copy), import (copy), v2 (copy), v3 (copy), PointGraph (copy), sub (copy), scale (copy), dot (copy), length (copy), madd (copy), normalize (copy), AirTrajectoryRuntime (copy)
    local processed = p8.player_input.processed
    local v6 = rt.map(processed.vectors_544_560_592_608[1], rt.from_bits)
    local v7 = rt.map(processed.vectors_544_560_592_608[4], rt.from_bits)
    local v8 = rt.map(processed.prepared_jump_704, rt.from_bits)
    local v9 = sub(v8, scale(v6, dot(v8, v6)))
    local v10 = length(v9)
    local curves = p8.boneless.curves
    local v11 = PointGraph.evaluate(curves[1], v6[2]) * PointGraph.evaluate(curves[2], v10)
    local v12 = PointGraph.evaluate(curves[3], v10) * v10
    local v13 = madd(v6, v11 - dot(v7, v6), v7)
    local v14 = madd(normalize(v9), v12, scale(v6, v11))
    local v15 = PointGraph.evaluate(curves[4], v6[2])
    local v16 = madd(v14, v15, scale(v13, 1 - v15))

    if math.abs(length(v16) - length(v7)) > 10 then
        v16 = rt.copy(v7)
    end

    local v18 = rt.map(processed.effective_anim_transform_192[3], rt.from_bits)
    local v19 = rt.fmax(dot(v16, v18), 0)

    if v19 < 1.92 then
        v16 = madd(v18, 1.92 - v19, v16)
    end

    local v20 = rt.map(processed.vectors_544_560_592_608[3], rt.from_bits)
    local v21 = madd(v6, dot(sub(p8.boneless.anchor, v20), v6) + 0.25, v20)
    local v22 = v2.launch_info(p7, p8)

    v22.start_velocity = v16
    v22.start_position_override = rt.copy(v21)
    v22.board_position_override = rt.copy(v21)
    v22.use_position_override = true
    v22.player_jumped = true

    local v23 = v2.selector_input(p7, p8)

    AirTrajectoryRuntime.launch(p8.trajectory, v22, rt.copy(v23), p7.world)
    AirTrajectoryRuntime.update(p8.trajectory, v23, p7.world, v3.GrindContext.from_processed(p8.player_input.processed, rt.copy(import("skate_game/physics/solve").deck_frame(p7.board)[4])))
end

t1.launch = launch

return t1
