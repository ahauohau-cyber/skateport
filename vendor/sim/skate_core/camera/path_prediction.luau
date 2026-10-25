-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/camera/vector_tracker")

return {
    PathObstacle = {},
    PredictionPath = {},
    candidate_collision_time = function(p1, p2) -- candidate_collision_time | line: 24
        -- upvalues: rt (copy), v1 (copy)
        local v2 = rt.F32_MAX

        for _, v3 in ipairs(p2) do
            local t2 = {}

            t2[1] = v3.position[1] - p1.position[1]
            t2[2] = v3.position[2] - p1.position[2]
            t2[3] = v3.position[3] - p1.position[3]
            t2[4] = v3.position[4] - p1.position[4]

            local t3 = {}

            t3[1] = v3.velocity[1] - p1.velocity[1]
            t3[2] = v3.velocity[2] - p1.velocity[2]
            t3[3] = v3.velocity[3] - p1.velocity[3]
            t3[4] = v3.velocity[4] - p1.velocity[4]

            local v4 = v3.radius + p1.radius
            local v5 = v1.dot(t2, t2) - v4 * v4

            if v5 < 0 then
                local n1 = 0

                if n1 < p1.horizon and n1 < v2 then
                    v2 = n1
                end
            else
                local v6 = v1.dot(t2, t3)

                if v6 < 0 then
                    local v7 = -1 / v1.dot(t3, t3) * v6

                    if v6 * v7 + v5 < 0 and v7 < p1.horizon and v7 < v2 then
                        v2 = v7
                    end
                end
            end
        end

        return v2
    end
}
