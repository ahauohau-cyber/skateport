-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    Observation = {}
}

function t1.Observation.eq(p1, p2) -- line: 18
    if p1.hips_right_angle == p2.hips_right_angle and p1.hips_up_angle == p2.hips_up_angle then
        return p1.mirrored == p2.mirrored
    end

    return false
end

t1.State = {}

function t1.State.default() -- line: 26
    return {
        twist = 0,
        lean = 0
    }
end

function t1.State.eq(p3, p4) -- line: 31
    if p3.twist == p4.twist then
        return p3.lean == p4.lean
    end

    return false
end

function t1.State.begin(p5, p6) -- line: 38
    -- upvalues: rt (copy), t1 (copy)
    if p6 ~= nil then
        rt.assign(p5, t1.read(p6))
    end
end

function t1.State.update(p7, p8, p9) -- line: 47
    -- upvalues: rt (copy), t1 (copy)
    if not p8 then
        return rt.copy(p7)
    end

    if p9 == nil then
        return t1.State.default()
    end

    return t1.read(p9)
end

function t1.read(p10) -- line: 59
    return {
        twist = if not p10.mirrored then p10.hips_up_angle else -p10.hips_up_angle,
        lean = p10.hips_right_angle
    }
end

return t1
