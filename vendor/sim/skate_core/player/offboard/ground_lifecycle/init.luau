-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/reciprocal_sqrt")
local v2 = import("skate_core/player/offboard/ground_lifecycle/collision")
local v3 = import("skate_core/player/offboard/ground_lifecycle/exit")
local v4 = import("skate_core/player/offboard/ground_lifecycle/post")
local v5 = import("skate_core/player/offboard/ground_lifecycle/publication")
local t1 = {
    CollisionInput = v2.CollisionInput,
    CollisionSettings = v2.CollisionSettings,
    check_collision = v2.check_collision,
    ExitServices = v3.ExitServices,
    exit = v3.exit,
    PostInput = v4.PostInput,
    post_physics = v4.post_physics,
    Publication = v5.Publication,
    PublicationInput = v5.PublicationInput,
    publish = v5.publish,
    dot = function(p1, p2) -- dot | line: 35
        return p1[1] * p2[1] + p1[2] * p2[2] + p1[3] * p2[3]
    end
}
local dot = t1.dot

function t1.length(p3) -- line: 41
    -- upvalues: v1 (copy), dot (copy)
    local v6 = dot(p3, p3)
    local v7 = v1.estimate(v6)
    local v8 = v7 * 0.5 * (-v6 * (v7 * v7) + 1) + v7
    local v9 = v8 * 0.5 * (-v6 * (v8 * v8) + 1) + v8

    if v6 == 0 then
        return 0
    end

    return v6 * v9
end

return t1
