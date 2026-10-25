-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/wipeout_state/output")
local v2 = import("skate_core/player/wipeout_state/recovery")
local t1 = {
    State = {}
}

function t1.State.default() -- line: 77
    -- upvalues: rt (copy)
    return {
        time = 0,
        settled_time = 0,
        time_until_teleport = 0,
        impaled_time = 0,
        no_support_time = 0,
        response_time = 0,
        extra_weight_zero_time = 0,
        slow_time = 0,
        surface_height = 0,
        board_offset = { 0, 0, 0, 0 },
        forward = { 0, 0, 0, 0 },
        right = { 0, 0, 0, 0 },
        angular_velocity = { 0, 0, 0, 0 },
        retained_tilt = { 0, 0, 0, 0 },
        velocity = { 0, 0, 0, 0 },
        retained_velocity = { 0, 0, 0, 0 },
        predicted_position = { 0, 0, 0, 0 },
        over = false,
        slow = false,
        material_eleven_response = false,
        air_collision_mode = false,
        request_teleport = false,
        move_board = false,
        special_surface = false,
        below_surface = false,
        retained_velocity_active = false,
        sideways_input = 0,
        forward_input = 0,
        orientation = 0,
        collision_weight = 0,
        controlled_weight = 0,
        control_time = 0,
        retained_sideways_input = 0,
        retained_forward_input = 0,
        response_scalar = 0,
        extra_weight = 1,
        maximum_speed = 10,
        response_start_speed = 0,
        response_change = 0,
        board_move_frames = 0,
        response_count = 0,
        response_frames = -1,
        airborne_frames = -1,
        teleport_countdown = -1,
        prevent_manual = false,
        ignore_reset = false,
        reset_ever = false,
        ever_settled = false,
        recovery_eligible = false,
        teleport_pending = false,
        ever_impaled = false,
        direction_initialized = false,
        material_ten_response = false,
        imminent_surface_twelve = false,
        allow_retained_velocity = true,
        response_finished = false,
        surface_query = false,
        profile = 0,
        predicted_time = rt.F32_MAX
    }
end

for v3, v4 in v1.State do
    t1.State[v3] = v4
end

for v5, v6 in v2.State do
    t1.State[v5] = v6
end

return t1
