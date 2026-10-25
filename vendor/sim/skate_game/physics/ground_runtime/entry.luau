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
local FootIk = import("skate_game/physics/foot_ik").FootIk
local Vector3 = import("skate_core/math").Vector3
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local dot_product = import("skate_core/riding/ground_correction_math").dot_product
local v2 = import("skate_core/riding/grounded/manual_entry")
local v3 = import("skate_core/riding/grounded/state/motion")
local PhysicsGroundState = import("skate_core/riding/grounded/state").PhysicsGroundState
local PumpingState = import("skate_core/riding/pumping/state").PumpingState
local SpeedWobbleState = import("skate_core/riding/speed_wobble").SpeedWobbleState
local Collections = import("skate_data/collections").Collections
local t1 = {}
local restore_standard_board_fields

local function from_bits4(p2) -- line: 37
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2[1])

    local v5 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[2])

    local v7 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[3])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[4])

    return {
        v5,
        v7,
        v9,
        (buffer.readf32(v1, 0))
    }
end

t1.EntrySettings = {}

function t1.EntrySettings.load(p3) -- line: 49
    -- upvalues: Collections (copy)
    return {
        deck_angular_drag = Collections.float(p3, "physicsdeck", "default", "DeckAngularDrag") * 59.999996185302734,
        powerslide_exit = Collections.float(p3, "physics_manual", "default", "PowerslideExitScalar"),
        landing_strength = Collections.float(p3, "physics_feet", "default", "LandingOnDeckEffectScalar"),
        landing_offset = Collections.float(p3, "physics_feet", "default", "LandingOnDeckOffset")
    }
end

t1.GroundEntryTargets = {}
t1.GroundState = {}

function t1.GroundState.enter(p4, p5, p6, p7, p8, p9) -- line: 85
    -- upvalues: rt (copy), FootIk (copy), BoardRuntime (copy), BoardForceQueue (copy), HookDriveState (copy), v2 (copy), v3 (copy), PhysicsGroundState (copy), PumpingState (copy), SpeedWobbleState (copy), t1 (copy), restore_standard_board_fields (ref), from_bits4 (copy)
    p9.board_flags_8384 = restore_standard_board_fields(p5, p9.board_flags_8384, p4.entry_settings.deck_angular_drag)
    FootIk.enable_feet(p9.foot_ik, true)
    p9.skeleton_elapsed_16505 = false
    p9.set_skeleton_collision_state(6)
    PhysicsGroundState.begin_entry(p4.state)
    p9.reckoning_spin_angle = 0
    p9.reckoning_spin_speed = 0
    p9.board_animated_290 = HookDriveState.disable_animation(BoardRuntime.hook_mut(p5).drive, p9.board_animated_290)

    local v11 = from_bits4(p6.vectors_464_480_496_512_528[1])
    local v12 = from_bits4(p6.vectors_720_784_800_816_832_864[1])

    BoardRuntime.bodies_mut(p5)[7].rates.angular_velocity = v3.entry_angular_velocity(v11, v12)
    p4.speed.target_speed = v3.entry_target_speed(BoardRuntime.bodies(p5)[7].rates.linear_velocity, v11, p8.forward)
    SpeedWobbleState.reset(p4.wobble)

    local t2 = {
        p5
    }
    local t3 = {}

    v2.enter_ground(p4.manual, p6.category_2516, p4.entry_settings.powerslide_exit, {
        balance = p7.fields.balance,
        ground_normal = rt.copy(v11),
        flags_2468 = p6.flags_2468,
        flags_2472 = p6.flags_2472
    }, {
        linear_velocity = function(_, p11) -- linear_velocity | line: 117
            -- upvalues: t2 (copy), t1 (copy)
            return t1.ManualBodies.linear_velocity(t2, p11)
        end,
        set_linear_velocity = function(_, p13, p14) -- set_linear_velocity | line: 120
            -- upvalues: t2 (copy), t1 (copy)
            return t1.ManualBodies.set_linear_velocity(t2, p13, p14)
        end
    }, {
        normal_speed = function(_, p16, p17) -- normal_speed | line: 125
            -- upvalues: t3 (copy), t1 (copy)
            return t1.Projection.normal_speed(t3, p16, p17)
        end
    })

    if p6.category_2516 == 200 then
        local v16 = bit32.band(bit32.bxor(bit32.rshift(p6.flags_2468, 20), (bit32.rshift(p6.flags_2476, 2))), 1) ~= 0

        p9.enter_air_landing_modifier(v16)
    end

    if p6.state_2504 == 503 then
        local v17 = v3.landing_on_deck_force(from_bits4(p6.vectors_400_416[1]), from_bits4(p6.vectors_544_560_592_608[4]), from_bits4(p6.vectors_544_560_592_608[1]), p8.total_mass, p4.entry_settings.landing_strength, p4.entry_settings.landing_offset)

        BoardForceQueue.append(BoardRuntime.forces_mut(p5), v17)
    end

    if p6.state_2504 == 101 then
        p4.state.straighten_scale_2672 = 0.1599999964237213
    else
        p4.state.straighten_scale_2672 = 1
    end

    PumpingState.reset(p4.pumping)

    if p9.wipeout_mode ~= 1 then
        p9.wipeout_timer = 0
        p9.wipeout_mode = 1
    end

    PhysicsGroundState.finish_entry(p4.state, p6.state_2504)
    p4.entered = true
end

function restore_standard_board_fields(p18, p19, p20) -- line: 169
    -- upvalues: BoardRuntime (copy)
    local v18 = bit32.band(p19, 127)

    BoardRuntime.bodies_mut(p18)[7].inertia.angular_drag = p20
    BoardRuntime.set_collision_group(p18, 4)

    return v18
end

t1.restore_standard_board_fields = restore_standard_board_fields
t1.ManualBodies = {}

function t1.ManualBodies.linear_velocity(p21, p22) -- line: 181
    -- upvalues: BoardRuntime (copy)
    local linear_velocity = BoardRuntime.bodies(p21[1])[p22 + 1].rates.linear_velocity

    return {
        linear_velocity.x,
        linear_velocity.y,
        linear_velocity.z,
        0
    }
end

function t1.ManualBodies.set_linear_velocity(p23, p24, p25) -- line: 186
    -- upvalues: Vector3 (copy), BoardRuntime (copy)
    BoardRuntime.bodies_mut(p23[1])[p24 + 1].rates.linear_velocity = Vector3.new(p25[1], p25[2], p25[3])
end

t1.Projection = {}

function t1.Projection.normal_speed(_, p27, p28) -- line: 194
    -- upvalues: dot_product (copy)
    return dot_product(p27, p28)
end

return t1
