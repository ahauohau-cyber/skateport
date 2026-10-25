-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/wipeout/air")
local v2 = import("skate_core/player/wipeout/common")
local v3 = import("skate_core/player/wipeout/data")
local v4 = import("skate_core/player/wipeout/ground")
local v5 = import("skate_core/player/wipeout/requests")

return {
    check_air = v1.check,
    check_air_collision = v1.check_collision,
    AirSettings = v3.AirSettings,
    Frame = v3.Frame,
    GroundSettings = v3.GroundSettings,
    Mode = v3.Mode,
    RequestInput = v3.RequestInput,
    Settings = v3.Settings,
    check_ground = v4.check,
    check_ground_animation = v4.check_animation,
    check_plant = v4.check_plant,
    Requests = v5.Requests,
    regional_force = v2.force
}
