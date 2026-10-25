-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    FadeSettings = {},
    Fade = {}
}

function t1.Fade.default() -- line: 25
    return {
        just_began = false,
        elapsed = 0,
        value = 0,
        target = 0,
        step = 0,
        minimum = 0,
        maximum = 0
    }
end

local bound

function t1.Fade.begin(p1, p2, p3, p4) -- line: 40
    -- upvalues: rt (copy), t1 (copy), bound (ref)
    local v1 = bound(p4, p2, p3)
    local v2 = t1.Fade.default()

    v2.just_began = true
    v2.minimum = p2
    v2.maximum = p3
    v2.value = v1
    v2.target = v1
    rt.assign(p1, v2)

    return v1
end

function t1.Fade.update(p5, p6, p7, p8) -- line: 54
    -- upvalues: bound (ref)
    if p5.just_began then
        p5.just_began = false

        return nil
    end

    p5.elapsed += p6
    p5.target = bound(p8.input_scale * p7 + p5.target, p5.minimum, p5.maximum)

    local v3 = (1 - p8.response) * p5.value + p5.target * p8.response
    local v4 = bound(v3 - p5.value, p5.step - p8.acceleration, p5.step + p8.acceleration)

    p5.step = bound(v4, -p8.maximum_step, p8.maximum_step)
    p5.value = bound(p5.value + p5.step, p5.minimum, p5.maximum)

    return p5.value
end

function t1.crouch(p9, p10, p11, p12, p13, p14, p15) -- line: 70
    -- upvalues: bound (ref)
    local v5 = bound(1 - p10, p12, p13)
    local v6 = bound(1 - p11, p12, p13)

    if not (v5 - v6 >= 0) then
        v6 = v5
    end

    local v7 = p15 * p14

    return bound(v6, p9 - v7, p9 + v7)
end

function t1.mirrored_twist(p16, p17) -- line: 92
    if not p17 then
        return p16
    end

    if p16 >= 0 then
        return 3.141592653589793 - p16
    end

    return -3.141592653589793 - p16
end

function t1.bound(p18, p19, p20) -- line: 103
    local v8 = if p19 - p18 >= 0 then p19 else p18

    if p20 - v8 >= 0 then
        return v8
    end

    return p20
end

bound = t1.bound

return t1
