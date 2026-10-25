-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local Vector3 = require(sim.import)("skate_core/math").Vector3
local xyz
local t1 = {}

t1.GroundBoardSettings = {}
t1.GroundForceFrame = {}
t1.GroundContactFrame = {}
t1.GroundBoardInput = {}
t1.GroundBoardComponents = {}
t1.GroundContactResponse = {}
t1.CollisionForceResponse = {}

function t1.CollisionForceResponse.tagged_force(p1) -- line: 128
    -- upvalues: xyz (ref)
    return {
        tag = 15,
        force_world = xyz(p1.force_2528),
        point_body = xyz(p1.point_2544)
    }
end

t1.GroundBoardStage = {}
t1.GroundBoardError = {}

function xyz(p2) -- line: 178
    -- upvalues: Vector3 (copy)
    return Vector3.new(p2[1], p2[2], p2[3])
end

t1.xyz = xyz

return t1
