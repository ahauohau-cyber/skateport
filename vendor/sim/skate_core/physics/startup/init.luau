-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/startup/reset")
local v2 = import("skate_core/physics/startup/skateboard")

return {
    reset_board_body = v1.reset_board_body,
    reset_collision_info = v1.reset_collision_info,
    reset_skateboard = v2.reset_skateboard
}
