-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    ConstMgIntent = {}
}

function t1.ConstMgIntent.eq(p1, p2) -- line: 24
    if p1.value == p2.value and p1.on_update == p2.on_update then
        return p1.created == p2.created
    end

    return false
end

function t1.ConstMgIntent.new(p3, p4) -- line: 28
    return {
        created = false,
        value = p3,
        on_update = p4
    }
end

function t1.ConstMgIntent.begin(p5) -- line: 37
    p5.created = true

    return {
        tag = "Set",
        p5.value
    }
end

function t1.ConstMgIntent.update(p6) -- line: 45
    local t2 = if p6.on_update or p6.created then {
        tag = "None"
    } else {
        tag = "Remove"
    }

    p6.created = false

    return t2
end

t1.ConstMgIntent["end"] = function(_) -- line: 58
    return {
        tag = "Remove"
    }
end

t1.TimeMgIntent = {}

function t1.TimeMgIntent.default() -- line: 68
    return {
        elapsed = 0
    }
end

function t1.TimeMgIntent.eq(p8, p9) -- line: 73
    return p8.elapsed == p9.elapsed
end

function t1.TimeMgIntent.update(p10, p11, p12) -- line: 80
    if p11 == nil then
        p10.elapsed = 0

        return {
            tag = "Remove"
        }
    end

    p10.elapsed += p12

    return {
        tag = "Set",
        p10.elapsed
    }
end

t1.TimeMgIntent["end"] = function(_) -- line: 91
    return {
        tag = "Remove"
    }
end

return t1
