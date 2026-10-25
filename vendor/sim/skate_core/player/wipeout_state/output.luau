-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/wipeout_state/math")
local v2 = import("skate_core/player/wipeout_state/orientation")
local t1 = {
    Output = {},
    State = {}
}

function t1.State.output(p1, p2, p3) -- line: 47
    -- upvalues: rt (copy), v1 (copy), v2 (copy)
    local v3 = p2[1]
    local v4 = v1.sub(p3, v1.scale(v3, v1.dot(p3, v3)))
    local v5 = v2.signed_angle(v3, p3, { 0, 0, 0, 0 })
    local v6 = v1.wrap_angle(v2.signed_angle(v4, p2[2], v3) + 3.1415927410125732)

    return {
        surface_height_valid_83 = true,
        over_599 = p1.over,
        scalar_544 = p1.orientation,
        no_support_time_548 = p1.no_support_time,
        can_leave_72 = p1.recovery_eligible and not p1.prevent_manual and not p1.ignore_reset,
        special_surface_81 = p1.special_surface,
        below_surface_82 = p1.below_surface,
        surface_height_32 = p1.surface_height,
        collision_time_144 = p1.predicted_time,
        profile_148 = p1.profile,
        response_strength_580 = p1.response_scalar,
        extra_weight_584 = p1.extra_weight,
        time_until_teleport_576 = p1.time_until_teleport,
        teleport_pending_604 = p1.teleport_pending,
        material_ten_3479 = p1.material_ten_response,
        material_eleven_3480 = p1.material_eleven_response,
        imminent_surface_twelve_3483 = p1.imminent_surface_twelve,
        predicted_position_64 = rt.copy(p1.predicted_position),
        retained_air_velocity_160 = if p1.retained_velocity_active then rt.copy(p1.retained_velocity) else nil,
        response_change_588 = if p1.response_finished then p1.response_change else nil,
        teleport_countdown_68 = p1.teleport_countdown >= 0,
        request_teleport_69 = p1.request_teleport,
        hips_right_angle_496 = v5,
        hips_up_angle_500 = v6
    }
end

return t1
