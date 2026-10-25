-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/animation/output/hierarchy")
local v2 = import("skate_core/animation/output/sqt")
local t1 = {
    compose_hierarchy = v1.compose_hierarchy,
    compose_hierarchy_in_place = v1.compose_hierarchy_in_place,
    Sqt = v2.Sqt,
    sqt_to_local = v2.sqt_to_local,
    sqt_to_matrix = v2.sqt_to_matrix,
    NativeMatrix = {},
    PoseBufferError = {}
}

function t1.PoseBufferError.eq(p1, p2) -- line: 36
    if p1.tag ~= p2.tag then
        return false
    end

    if p1.tag ~= "InvalidParent" then
        return true
    end

    if p1.bone == p2.bone then
        return p1.parent == p2.parent
    end

    return false
end

return t1
