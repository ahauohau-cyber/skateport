-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local Noise = require(sim.import)("skate_game/session_marker/noise").Noise
local t1 = {
    Params = {}
}
local Params = t1.Params

function t1.Params.bits(p1) -- line: 23
    -- upvalues: rt (copy)
    return rt.map({
        p1.scroll,
        p1.first,
        p1.second,
        p1.fade
    }, function(p2) -- line: 24
        -- upvalues: rt (copy)
        return rt.map(p2, rt.to_bits)
    end)
end

t1.Effect = {}
t1.Runtime = {}
t1.Screen = {}

local function bits_equal(p3, p4) -- line: 46
    for i = 1, 4 do
        if p3[i][1] ~= p4[i][1] or p3[i][2] ~= p4[i][2] or p3[i][3] ~= p4[i][3] or p3[i][4] ~= p4[i][4] then
            return false
        end
    end

    return true
end

function t1.load() -- line: 62
    -- upvalues: Noise (copy)
    local v1 = Noise.default()

    return {
        time = 0,
        noise = v1,
        material = {
            texture = Noise.texture(v1),
            params = {
                scroll = { 0, 0, 0, 0 },
                first = { 1, 0, 0, 0 },
                second = { 1, 0, 0, 0 },
                fade = { 0, 0, 0, 0 }
            }
        }
    }
end

function t1.present(p5, p6, p7, p8) -- line: 90
    -- upvalues: rt (copy), Noise (copy), Params (copy), bits_equal (copy)
    p5.time += p7

    while p5.time >= 0.016666666666666666 do
        p5.time -= 0.016666666666666666
        Noise.advance(p5.noise)
    end

    local v2

    if p6.progress > 0 then
        local t2 = {
            scroll = rt.copy(p5.noise.scroll),
            first = Noise.weights(p5.noise.phases[1]),
            second = Noise.weights(p5.noise.phases[2]),
            fade = {
                p6.progress,
                0, 0, 0
            }
        }
        local material = p5.material

        if material == nil or bits_equal(Params.bits(material.params), Params.bits(t2)) then
            v2 = false
        else
            v2 = true
            material.params = t2
        end
    else
        v2 = false
    end

    local t3 = {
        p8.width,
        p8.height,
        1
    }

    return p6.progress > 0, t3, v2
end

return t1
