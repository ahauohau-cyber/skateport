-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/collision/fixup")
local v2 = import("skate_core/physics/collision/sphere_triangle")
local v3 = import("skate_core/physics/collision/world_contact")

return {
    ContactPair = v1.ContactPair,
    TriangleFeature = v1.TriangleFeature,
    TriangleFixup = v1.TriangleFixup,
    TriangleRegion = v1.TriangleRegion,
    fix_up_triangle = v1.fix_up_triangle,
    Sphere = v2.Sphere,
    SphereTrianglePair = v2.SphereTrianglePair,
    Triangle = v2.Triangle,
    intersect_sphere_triangle = v2.intersect_sphere_triangle,
    WorldContact = v3.WorldContact,
    WorldContactSettings = v3.WorldContactSettings,
    sphere_triangle_world_contact = v3.sphere_triangle_world_contact,
    world_separation_limit = v3.world_separation_limit
}
