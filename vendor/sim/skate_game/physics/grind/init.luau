-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local t1 = {
    Family = {
        FiftyFifty = 0,
        Boardslide = 1,
        Tipslide = 2,
        FiveO = 3,
        Backslash = 4,
        Darkslide = 5
    }
}

function t1.Family.from_physical_state(p1) -- line: 26
    -- upvalues: t1 (copy)
    if p1 == 400 then
        return t1.Family.Boardslide
    end

    if p1 == 401 then
        return t1.Family.FiftyFifty
    end

    if p1 == 402 then
        return t1.Family.Tipslide
    end

    if p1 == 403 then
        return t1.Family.FiveO
    end

    if p1 == 404 then
        return t1.Family.Backslash
    end

    return if p1 == 405 then t1.Family.Darkslide else nil
end

local v1 = import("skate_game/physics/grind/advance")
local v2 = import("skate_game/physics/grind/condition")
local v3 = import("skate_game/physics/grind/phase")
local v4 = import("skate_game/physics/grind/runtime")
local v5 = import("skate_game/physics/grind/observation")

t1.advance = v1.advance
t1.condition = v2.condition
t1.enter = v3.enter
t1.exit = v3.exit
t1.fill = v3.fill
t1.post = v3.post
t1.Runtime = v4.Runtime
t1.ManagerObservation = v5.ManagerObservation

return t1
