-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local GrindMaterials = import("skate_game/physics/grind_materials").GrindMaterials

local function grind_world() -- line: 13
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input/grind/world")
end

local t1 = {
    LiveHost = {}
}

function t1.LiveHost.apply_material_mode(p1, p2) -- line: 26
    -- upvalues: GrindMaterials (copy)
    GrindMaterials.apply(p1.materials, p2, p1.board, p1.settings)
end

function t1.LiveHost.surface_probe(_, p4, p5, p6, p7) -- line: 32
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input/grind/world").surface_probe(p4, p5, p6, p7)
end

function t1.LiveHost.force_exit_line(_, p9, p10, p11) -- line: 38
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input/grind/world").force_exit_line(p9, p10, p11)
end

return t1
