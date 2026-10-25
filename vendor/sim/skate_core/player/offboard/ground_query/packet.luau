-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/player/offboard/ground_query/math")
local add, sub, scale, madd = v1.add, v1.sub, v1.scale, v1.madd
local dot, cross, length, safe_unit = v1.dot, v1.cross, v1.length, v1.safe_unit

return {
    prepare_packet = function(p1, p2, p3, p4) -- prepare_packet | line: 19
        -- upvalues: rt (copy), Vector3 (copy), add (copy), sub (copy), scale (copy), madd (copy), dot (copy), cross (copy), length (copy), safe_unit (copy)
        local v2 = rt.copy(p3.edge)
        local v3 = rt.copy(p3.closest)
        local v4 = safe_unit(sub(v2.start, v2["end"]), p1.right)
        local v6 = madd(safe_unit(sub(p1.forward, scale(v4, dot(v4, p1.forward))), p1.forward), 0.2, v3)
        local v7 = sub(v2["end"], v2.start)
        local v8 = cross(v7, cross(Vector3.new(0, 1, 0), v7))
        local v9 = safe_unit(v8, v8)
        local v10 = safe_unit(v7, v7)

        if length(v8) < 9.999999747378752E-06 then
            return nil
        end

        local v12 = sub(v3, sub(v3, (madd(v10, dot(sub(v3, v2.start), v10), v2.start))))
        local v13 = cross(v9, v10)
        local v14 = scale(v9, 0.04)
        local v15 = scale(v13, 0.09)
        local v16 = scale(v13, p4)
        local v17 = scale(v9, p4 * 1.059999942779541)

        local function line(p5, p6, p7) -- line: 39
            -- upvalues: add (copy), sub (copy)
            return {
                start = add(p5, p6),
                ["end"] = sub(p5, p6),
                radius = p7
            }
        end

        local t2 = {
            context = rt.copy(p2),
            center = rt.copy(v12),
            up = rt.copy(v9),
            tangent = rt.copy(v10)
        }
        local v18 = add(v12, v15)
        local t3 = {
            start = add(v18, v14),
            ["end"] = sub(v18, v14),
            radius = 0
        }
        local v19 = sub(v12, v15)
        local t4 = {
            start = add(v19, v14),
            ["end"] = sub(v19, v14),
            radius = 0
        }
        local v20 = add(v12, v16)
        local t5 = {
            start = add(v20, v17),
            ["end"] = sub(v20, v17),
            radius = 0
        }
        local v21 = sub(v12, v16)
        local t6 = {
            start = add(v21, v17),
            ["end"] = sub(v21, v17),
            radius = 0
        }
        local t7 = {
            start = add(v12, v14),
            ["end"] = sub(v12, v14),
            radius = 0
        }
        local v22 = add(v12, scale(v9, 0.09))

        t2.lines = {
            t3,
            t4,
            t5,
            t6,
            t7,
            {
                start = add(v22, v15),
                ["end"] = sub(v22, v15),
                radius = 0.001
            },
            {
                start = rt.copy(v6),
                ["end"] = add(v6, Vector3.new(0, -6, 0)),
                radius = 0
            }
        }

        return t2
    end
}
