-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local GroundPumping = import("skate_game/physics/ground_runtime/pumping").GroundPumping
local GroundSettings = import("skate_game/physics/ground_runtime/settings").GroundSettings
local Owner = import("skate_game/physics/biped_ground/grab_runtime").Owner
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local PhysicsGroundState = import("skate_core/riding/grounded/state").PhysicsGroundState
local v2 = import("skate_core/riding/grounded/state/motion")

local function parent() -- line: 30
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local t1 = {}

local function from_bits4(p2) -- line: 36
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2[1])

    local v4 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[2])

    local v6 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[3])

    local v8 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[4])

    return {
        v4,
        v6,
        v8,
        (buffer.readf32(v1, 0))
    }
end

t1.GroundUpdateFrame = {}
t1.GroundUpdateTargets = {}
t1.GroundState = {}

function t1.GroundState.update(p3, p4, p5, p6, p7, p8, p9, p10) -- line: 69
    -- upvalues: rt (copy), import (copy), GroundPumping (copy), GroundSettings (copy), Owner (copy), BoardRuntime (copy), PhysicsGroundState (copy), v2 (copy), from_bits4 (copy)
    if not p3.entered then
        error("Ground::Enter must finish before Ground::Update", 0)
    end

    local processed = p8.processed

    if PhysicsGroundState.begin_update_at(p3.state, rt.to_i32(processed.wheel_count_2556), rt.copy(p8.toolkit.deck[4])).set_skeleton_flag_16505 then
        p10.skeleton_elapsed_16505 = true
    end

    local v10 = GroundPumping.mode_ref(p3.pumping_settings, processed.state_variant_index_2528)

    GroundPumping.update(p3.pumping_settings, p3.pumping, p8.toolkit, p8.riding, p8.skeleton, processed.flags_2476, v10)

    local v11 = GroundSettings.input(p7, p8.toolkit, processed, p8.animation, p3.pumping, v10.unintentional_scalar, p8.riding, p8.skeleton, p8.base_trucks, p8.extra)
    local t2 = {
        speed_wobble = p3.wobble,
        truck_steering = p3.steering,
        speed_model = p3.speed,
        manual = p3.manual,
        heading_previous = p3.heading_previous
    }
    local update_board = import("skate_game/physics/ground_runtime").GroundRuntime.update_board
    local state = p3.state
    local ok, result = pcall(update_board, p4, p5, p6, p7, state, t2, v11, p9)

    p3.heading_previous = t2.heading_previous

    if not ok then
        error(result, 0)
    end

    local v12 = from_bits4(processed.vectors_464_480_496_512_528[1])
    local v13 = v2.future_deck_displacement(BoardRuntime.forces(p5), p8.toolkit.total_mass, processed.timestep_2604, v12, p3.state.flag_2720, p3.state.manual_correction_2732)

    if v13 ~= nil then
        p10.move_future_deck(v13)
    end

    if p3.state.flag_2722 then
        p10.foot_ik.state.contacts.support_failed_this_update = true
    end

    p10.board_correction_pending = true
    PhysicsGroundState.finish_update(p3.state, processed.timestep_2604)
    Owner.invalidate(p10.offboard_grab)

    return result
end

return t1
