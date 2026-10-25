-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local v1 = import("skate_core/physics/ground_hang_geometry")
local signed_angle = import("skate_core/riding/collision_response").signed_angle
local v2 = import("skate_core/riding/ground_correction_math")

local function parent() -- line: 19
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local t1 = {}
local xyz

local function deck_position(p1) -- line: 31
    -- upvalues: BodyId (copy), BoardRuntime (copy)
    return BoardRuntime.part_translation(p1, BodyId.index(BodyId.Deck))
end

t1.GroundRuntime = {}

function t1.GroundRuntime.angle_between(_, p3, p4, p5) -- line: 44
    -- upvalues: signed_angle (copy), xyz (ref)
    return signed_angle(xyz(p3), xyz(p4), xyz(p5))
end

function t1.GroundRuntime.dot3(_, p7, p8) -- line: 49
    -- upvalues: v2 (copy)
    return v2.dot_product(p7, p8)
end

function t1.GroundRuntime.scale_to_magnitude(_, p10, p11, p12) -- line: 53
    -- upvalues: v2 (copy)
    return v2.scale_to_magnitude(p10, p11, p12)
end

function t1.GroundRuntime.detect_hung_up_geometry(p13, p14, p15) -- line: 58
    -- upvalues: v1 (copy)
    return v1.detect_hung_geometry(p14, p15, p13.deck_center_to_truck)
end

function t1.GroundRuntime.collision_force_projection(_, p17, p18) -- line: 63
    -- upvalues: v2 (copy)
    return v2.collision_force_projection(p17, p18)
end

function t1.GroundRuntime.build_hang_force(_, p20, p21, p22) -- line: 67
    -- upvalues: BodyId (copy), BoardRuntime (copy), v2 (copy)
    local v3, v4, v5 = BoardRuntime.part_translation(p20, BodyId.index(BodyId.Deck))

    return v2.hang_force(p21, p22, { v3, v4, v5, 0 })
end

function t1.GroundRuntime.apply_hang_force(_, p24, p25) -- line: 72
    -- upvalues: rt (copy), Vector3 (copy), BodyId (copy), BoardRuntime (copy), v2 (copy), xyz (ref)
    local v6, v7, v8 = BoardRuntime.part_translation(p24, BodyId.index(BodyId.Deck))
    local v9 = Vector3.new(v6, v7, v8)

    v2.apply_world_force(BoardRuntime.bodies_mut(p24)[BodyId.index(BodyId.Deck) + 1], v9, xyz(p25), rt.copy(v9))
end

function t1.GroundRuntime.pin_to_position(p26, p27, p28, p29, p30) -- line: 84
    -- upvalues: import (copy), BodyId (copy), BoardRuntime (copy), v2 (copy)
    local v10, v11, v12 = BoardRuntime.part_translation(p27, BodyId.index(BodyId.Deck))
    local v13 = v2.pinning_velocity({ v10, v11, v12, 0 }, p28, p29, p30)

    import("skate_game/physics/ground_runtime").GroundRuntime.set_animated_velocity(p26, p27, v13)
end

function xyz(p31) -- line: 90
    -- upvalues: Vector3 (copy)
    return Vector3.new(p31[1], p31[2], p31[3])
end

t1.xyz = xyz

return t1
