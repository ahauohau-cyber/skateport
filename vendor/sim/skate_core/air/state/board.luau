-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/state/data")
local v2 = import("skate_core/air/state/jump_velocity")
local AirBoardForce = v1.AirBoardForce
local calculate_velocity_from_jump = v2.calculate_velocity_from_jump
local t1 = {
    AIR_COLLISION_FORCE_TAG = 15
}
local AIR_COLLISION_FORCE_TAG = t1.AIR_COLLISION_FORCE_TAG

function t1.update_skateboard(p1, p2, p3, p4) -- line: 19
    -- upvalues: rt (copy), AirBoardForce (copy), calculate_velocity_from_jump (copy), AIR_COLLISION_FORCE_TAG (copy)
    p4.update_board_steering_tilt(p4, 0)

    local v3 = rt.copy(AirBoardForce.ZERO)

    if p4.calculate_air_collision_force(p4, rt.copy(p3.collision_reference_normal_1216), v3) then
        p4.enqueue_board_force(p4, AIR_COLLISION_FORCE_TAG, v3)
    elseif not p1.use_centre_of_mass_velocity and p2.frames_since_jump_correction_2576 < 12 then
        local v4 = calculate_velocity_from_jump(p2, p2.frames_since_jump_correction_2576, p4)

        p4.set_board_velocity(p4, v4)
    end
end

return t1
