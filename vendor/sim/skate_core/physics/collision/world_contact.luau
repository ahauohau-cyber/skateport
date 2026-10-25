-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/physics/collision/arithmetic")
local fix_up_triangle = import("skate_core/physics/collision/fixup").fix_up_triangle
local build_prism = import("skate_core/physics/collision/sphere_triangle").build_prism
local dot, scale, neg, sub = v1.dot, v1.scale, v1.neg, v1.sub
local t1 = {
    WorldContactSettings = {},
    WorldContact = {},
    world_separation_limit = function(p1, p2, p3, p4) -- world_separation_limit | line: 34
        -- upvalues: dot (copy), scale (copy), neg (copy)
        local v2 = dot(neg(p2), scale(p1, 0.01666666753590107))

        if -v2 >= 0 then
            v2 = 0
        end

        if not (p4 - v2 >= 0) then
            v2 = p4
        end

        return v2 + p3
    end
}

function t1.sphere_triangle_world_contact(p5, p6, p7, p8) -- line: 45
    -- upvalues: rt (copy), Vector3 (copy), fix_up_triangle (copy), build_prism (copy), scale (copy), neg (copy), sub (copy), t1 (copy)
    local v4 = build_prism(p5, p6, t1.world_separation_limit(p7, p6.feature.normal, p8.volume_padding, p8.maximum_separating_distance), false, true)

    if v4 == nil then
        return nil
    end

    local v5 = rt.copy(v4.normal)
    local t2 = { rt.copy(v4.raw_points) }

    if not fix_up_triangle(p6.feature, v5, t2, {
        reverse = true,
        edge_cos_bend_normal_threshold = p8.edge_cos_bend_normal_threshold,
        convexity_epsilon = p8.convexity_epsilon,
        is_object = p8.is_object
    }) then
        return nil
    end

    local v6 = scale(v5, p5.radius)

    return {
        normal = neg(v5),
        points = {
            a = Vector3.new(t2[1].a.x + v6.x, t2[1].a.y + v6.y, t2[1].a.z + v6.z),
            b = sub(t2[1].b, scale(v5, p6.fatness))
        }
    }
end

return t1
