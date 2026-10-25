-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    VERTICAL_ERROR_FLOOR = -3,
    HORIZONTAL_ERROR_LIMIT_SQUARED = 9
}
local VERTICAL_ERROR_FLOOR, HORIZONTAL_ERROR_LIMIT_SQUARED = t1.VERTICAL_ERROR_FLOOR, t1.HORIZONTAL_ERROR_LIMIT_SQUARED

t1.PhysicsAirMath = {}

function t1.calculate_velocity_from_jump(p1, p2, p3) -- line: 31
    -- upvalues: rt (copy), VERTICAL_ERROR_FLOOR (copy), HORIZONTAL_ERROR_LIMIT_SQUARED (copy)
    local v1 = p1.delta_time_2604 * p2 * p1.gravity_y_2648
    local v2 = rt.copy(p1.jump_velocity_848)

    v2[1] += 0
    v2[2] += v1
    v2[3] += 0
    v2[4] += 0

    local v3 = rt.copy(p1.current_velocity_400)
    local t2 = {
        v3[1] - v2[1],
        v3[2] - v2[2],
        v3[3] - v2[3],
        v3[4] - v2[4]
    }
    local v4 = rt.copy(v2)

    if not (t2[2] > VERTICAL_ERROR_FLOOR) then
        v4[2] = v3[2]
    end

    t2[2] = 0

    if not (p3.length_squared_vmsum3fp(p3, rt.copy(t2)) < HORIZONTAL_ERROR_LIMIT_SQUARED) then
        local v5 = rt.copy(v4)

        v5[2] = 0

        local v6 = p3.length_vmsum3fp_vrsqrte(p3, v5)
        local v7 = rt.copy(v3)

        v7[2] = 0

        local v8 = p3.clamp_vector_within_max_length(p3, v7, v6)

        v4[1] = v8[1]
        v4[3] = v8[3]
    end

    return v4
end

return t1
