-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_game/physics/ground")
local t1 = {
    MapTransitionSet = {},
    WorldChanged = {},
    CurrentMap = {}
}

function t1.CurrentMap.from_package(p1, p2) -- line: 31
    -- upvalues: rt (copy), v1 (copy)
    return {
        generation = 0,
        path = p1,
        name = if p2 == nil then "Test world" else p2.name,
        spawn = if p2 == nil then {
            0,
            v1.HEIGHT,
            0
        } else rt.copy(p2.spawn),
        heading = if p2 == nil then 0 else p2.heading
    }
end

t1.PreparedWorld = {}
t1.Phase = {}
t1.MapTransition = {}

function t1.MapTransition.default() -- line: 61
    return {
        phase = {
            tag = "Idle"
        }
    }
end

function t1.MapTransition.busy(p3) -- line: 65
    return p3.phase.tag ~= "Idle"
end

function t1.MapTransition.request(p4, p5) -- line: 69
    -- upvalues: t1 (copy)
    if not t1.MapTransition.busy(p4) then
        p4.phase = {
            tag = "Requested",
            p5
        }
    end
end

function t1.MapTransition.label(p6) -- line: 75
    local phase = p6.phase

    if phase.tag == "Idle" then
        return ""
    end

    if phase.tag == "Requested" then
        return "Loading " .. phase[1].label .. " — preparing…"
    end

    if phase.tag ~= "Loading" then
        return "Loading — publishing the new world…"
    end

    local value = phase.progress.value
    local v2 = if value == 0 then "reading and validating map"
        elseif value == 1 then "building collision and rendering"
        elseif value == 2 then "initializing skater, camera and rendering"
        else "finishing meshes, textures and sky"

    return "Loading " .. phase.entry.label .. " — " .. v2 .. "…"
end

t1.MapTransitionPlugin = {}

function t1.MapTransitionPlugin.build(p7) -- line: 108
    -- upvalues: t1 (copy)
    return t1.CurrentMap.from_package(p7.map_path, p7.map), t1.MapTransition.default()
end

return t1
