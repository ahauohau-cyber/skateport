-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/air/trajectory/math")
local IDENTITY, ZERO = v1.IDENTITY, v1.ZERO
local t1 = {
    LaunchInfo = {}
}

function t1.LaunchInfo.default() -- line: 34
    -- upvalues: rt (copy), IDENTITY (copy), ZERO (copy)
    return {
        cone_angle_x = 0,
        cone_angle_z = 0,
        timestep = 0,
        player_jumped = false,
        use_position_override = false,
        trajectory_count = 0,
        reckoning_transform = rt.copy(IDENTITY),
        reckoning_inverse = rt.copy(IDENTITY),
        start_velocity = rt.copy(ZERO),
        com_velocity = rt.copy(ZERO),
        skeleton_vector_160 = rt.copy(ZERO),
        skeleton_vector_176 = rt.copy(ZERO),
        board_position = rt.copy(ZERO),
        animation_com_position = rt.copy(ZERO),
        start_position_override = rt.copy(ZERO),
        board_position_override = rt.copy(ZERO)
    }
end

t1.SelectorInput = {}
t1.SelectorSettings = {}

return t1
