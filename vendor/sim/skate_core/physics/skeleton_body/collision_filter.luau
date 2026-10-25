-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local signed_angle = import("skate_core/riding/collision_response").signed_angle
local v1 = import("skate_core/trigonometry")
local cos, sin = v1.cos, v1.sin
local v2 = import("skate_core/physics/skeleton_body/collision_vector")
local dot, scale, sub, normalize = v2.dot, v2.scale, v2.sub, v2.normalize
local t1 = {
    SkeletonCollisionFeedback = {}
}

function t1.SkeletonCollisionFeedback.filter_error(p1, p2, p3) -- line: 30
    -- upvalues: signed_angle (copy), cos (copy), sin (copy), dot (copy), scale (copy), sub (copy), normalize (copy), t1 (copy)
    local v3 = sub(p2, scale(p3, dot(p2, p3)))
    local v4 = normalize(v3)

    if dot(v4, v4) < 0.1 then
        return v3
    end

    local n1 = 1.5707963705062866
    local n2 = -1.5707963705062866
    local v5 = false

    for _, v6 in ipairs(p1.planes) do
        local v7 = normalize(sub(v6.normal, scale(p3, dot(v6.normal, p3))))

        if not (dot(v7, v7) < 0.1) then
            local v8 = signed_angle(t1.vector(v4), t1.vector(v7), t1.vector(p3)) * 0.15915493667125702
            local v9 = v8 - math.floor(v8)
            local v10 = (v9 - (if v9 > 0.5 then 1 else 0)) * 6.2831854820251465

            if v10 > -1.5707963705062866 and v10 < 1.5707963705062866 then
                if v10 < n1 then
                    n1 = v10
                end

                if n2 < v10 then
                    n2 = v10
                end

                v5 = true
            end
        end
    end

    local v11 = (n2 + n1) * 0.5
    local v12 = if v5 then cos(v11) else 0
    local v13 = cos(v11)
    local v14 = sin(v11)
    local v15 = p3[1]
    local v16 = p3[2]
    local v17 = p3[3]
    local v18 = v14 * v15
    local v19 = v14 * v16
    local v20 = v14 * v17
    local v21 = 1 - v13
    local v22 = v21 * v15
    local v23 = v21 * v16
    local v24 = v21 * v17
    local t2 = {
        {
            v15 * v22 + v13,
            v22 * v16 + v20,
            v22 * v17 - v19
        },
        {
            v23 * v15 - v20,
            v23 * v16 + v13,
            v23 * v17 + v18
        },
        {
            v24 * v15 + v19,
            v24 * v16 - v18,
            v17 * v24 + v13
        }
    }
    local v25 = table.create(4, 0)

    for i = 0, 2 do
        v25[i + 1] = (t2[3][i + 1] * v3[3] + (t2[2][i + 1] * v3[2] + t2[1][i + 1] * v3[1])) * v12
    end

    return v25
end

function t1.vector(p4) -- line: 89
    -- upvalues: Vector3 (copy)
    return Vector3.new(p4[1], p4[2], p4[3])
end

return t1
