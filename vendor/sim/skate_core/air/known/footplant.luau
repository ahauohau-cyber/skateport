-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    MIN_FOOTPLANT_TIME = 0.10000000149011612
}
local MIN_FOOTPLANT_TIME = t1.MIN_FOOTPLANT_TIME

function t1.update_footplant(p1, p2, p3) -- line: 15
    -- upvalues: rt (copy), MIN_FOOTPLANT_TIME (copy)
    if bit32.band(p2.flags_2480, 67108864) ~= 0 and bit32.band(p2.flags_2476, 67108864) == 0 and not (p1.time_in_state_180 <= MIN_FOOTPLANT_TIME) then
        local t2 = {
            trajectory = rt.copy(p3.selector_trajectory_2704(p3)),
            remaining_collision_time = p1.collision_time_196 - p1.time_in_state_180,
            collision_position = rt.copy(p1.collision_position_112),
            landing_normal = rt.copy(p1.landing_normal_64)
        }

        p3.shift_footplant_trajectory_to_index(p3, t2.trajectory, p1.trajectory_index_216)
        p3.update_footplant_prediction(p3, t2)
        p3.update_footplant_lock(p3, t2)
        p3.update_footplant_pose(p3, t2)

        return
    end

    p3.reset_footplants(p3)
end

return t1
