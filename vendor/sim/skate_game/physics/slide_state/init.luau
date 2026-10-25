-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/slide_state/settings")
local v2 = import("skate_game/physics/slide_state/update")
local Vector3 = import("skate_core/math").Vector3
local v3 = import("skate_core/physics/board_runtime")
local v4 = import("skate_core/physics/hook_drive")
local v5 = import("skate_core/physics/manual/state")
local v6 = import("skate_core/player/slide_state")
local BoardRuntime = v3.BoardRuntime
local HookDriveState = v4.HookDriveState
local ManualState = v5.ManualState
local SlideState = v6.SlideState

local function input_phase() -- line: 23
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function riding_outputs() -- line: 26
    -- upvalues: import (copy)
    return import("skate_game/physics/riding_outputs")
end

local t1 = {
    SlideState = {}
}

for v7, v8 in v1.SlideState do
    t1.SlideState[v7] = v8
end

function t1.enter(p1, p2) -- line: 47
    -- upvalues: rt (copy), Vector3 (copy), BoardRuntime (copy), HookDriveState (copy), ManualState (copy), SlideState (copy)
    local processed = p2.player_input.processed

    p2.ground_lifecycle.skeleton_elapsed_16505 = true
    p2.air_reckoning.state.spin_angle = 0
    p2.air_reckoning.state.spin_speed = 0
    p2.ground_lifecycle.board_animated_290 = HookDriveState.disable_animation(BoardRuntime.hook_mut(p1.board).drive, p2.ground_lifecycle.board_animated_290)
    BoardRuntime.bodies_mut(p1.board)[7].rates.angular_velocity = rt.copy(Vector3.ZERO)

    for _, v9 in ipairs(BoardRuntime.bodies_mut(p1.board)) do
        v9.inertia.linear_drag = 0
    end

    if processed.category_2516 ~= 100 then
        ManualState.reset(p2.ground.manual)
    end

    if p2.wipeout.state.mode ~= 1 then
        p2.wipeout.state.balance = 0
        p2.wipeout.state.mode = 1
    end

    SlideState.enter(p2.slide_state.state, processed.scalar_2656)
end

function t1.exit(p3, p4) -- line: 73
    -- upvalues: rt (copy), SlideState (copy)
    SlideState.exit(p4.slide_state.state)
    p3.settings.wheel_material = rt.copy(p3.settings.standard_wheel_material)
end

function t1.update(p5, p6) -- line: 80
    -- upvalues: import (copy), v2 (copy)
    local processed, toolkit = p6.player_input.processed, p6.player_input.toolkit

    if toolkit == nil then
        error("Slide requires current BoardToolkit", 0)
    end

    import("skate_game/physics/riding_outputs").RidingOutputs.update_slide_reckoning(p5.riding, processed, toolkit, p6.animation_input.extra.physical_body_spin, p6.animation_input.fields.balance)
    import("skate_game/physics/input_phase").update_ground(p5, p6)

    return v2.board(p5, p6)
end

return t1
