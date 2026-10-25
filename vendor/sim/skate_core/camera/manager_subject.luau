-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/camera/orientation_math")
local v2 = import("skate_core/camera/direction")
local t1 = {
    ManagerSubject = {}
}

function t1.ManagerSubject.is_ground_camera(p1, p2) -- line: 43
    if p2 == 2 then
        return true
    end

    if p1.flag_556 == 0 and p1.rig.trajectory_valid == 0 then
        return p1.trajectory_duration <= 0.4000000059604645
    end

    return false
end

function t1.ManagerSubject.steering_for_turn(p3, p4) -- line: 54
    -- upvalues: t1 (copy)
    local v3 = p3.steering[1]
    local v4 = p3.steering[3]
    local v5 = p3.steering[4]

    if not (math.abs(v5) > math.abs(v4)) then
        v5 = v4
    end

    if t1.sign(v5) == t1.sign(v3) and not (math.abs(v5) < math.abs(v3)) then
        v3 = v5
    end

    if (if p4 then 1 else 0) == p3.stance_560 then
        return v3
    end

    return -v3
end

function t1.ManagerSubject.steering_for_blend(p5, p6) -- line: 69
    -- upvalues: t1 (copy)
    local v6 = p5.steering[2]
    local v7 = p5.steering[3]
    local v8 = p5.steering[4]

    if not (math.abs(v8) > math.abs(v7)) then
        v8 = v7
    end

    if t1.sign(v6) == t1.sign(v8) and not (math.abs(v6) < math.abs(v8)) then
        v8 = v6
    end

    if (if p6 then 1 else 0) == p5.stance_560 then
        return v8
    end

    return -v8
end

function t1.ManagerSubject.valid_trajectory_duration(p7) -- line: 86
    if p7.rig.trajectory_valid == 0 then
        return 0
    end

    return p7.trajectory_duration
end

function t1.ManagerSubject.look_heading(p8) -- line: 95
    -- upvalues: v1 (copy), v2 (copy)
    local v9 = v1.normalize({
        p8.look[1],
        0,
        p8.look[2],
        0
    })

    return -v2.direction_to_angles(v9)[2]
end

function t1.sign(p9) -- line: 101
    if p9 >= 0 then
        if p9 > 0 then
            return 1
        end

        return 0
    end

    return -1
end

return t1
