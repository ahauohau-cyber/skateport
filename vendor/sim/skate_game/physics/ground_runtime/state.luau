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
local v2 = import("skate_game/physics/ground_runtime/entry")
local v3 = import("skate_game/physics/ground_runtime/update")
local GroundPumping = import("skate_game/physics/ground_runtime/pumping").GroundPumping
local v4 = import("skate_game/difficulty")
local PhysicsGroundState = import("skate_core/riding/grounded/state").PhysicsGroundState
local v5 = import("skate_core/riding/grounded/state/output")
local PumpingState = import("skate_core/riding/pumping/state").PumpingState
local TruckSteeringState = import("skate_core/riding/steering").TruckSteeringState
local Collections = import("skate_data/collections").Collections
local t1 = {}

local function from_bits4(p2) -- line: 32
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2[1])

    local v7 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[2])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[3])

    local v11 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[4])

    return {
        v7,
        v9,
        v11,
        (buffer.readf32(v1, 0))
    }
end

t1.GroundState = {}

function t1.GroundState.adopt_mode_settings(p3, p4) -- line: 54
    p3.auto_push_enabled = p4.auto_push_enabled
    p3.pumping_settings = p4.pumping_settings
end

function t1.GroundState.load(p5, _, p7) -- line: 59
    -- upvalues: v2 (copy), GroundPumping (copy), v4 (copy), PhysicsGroundState (copy), PumpingState (copy), TruckSteeringState (copy), Collections (copy)
    local function push(p8) -- line: 60
        -- upvalues: p5 (copy), Collections (copy)
        return Collections.float(p5, "physics_push", "default", p8)
    end

    local t2 = {
        state = PhysicsGroundState.before_first_enter(p7),
        pumping = PumpingState.reset_state(),
        wobble = { table.create(8, 0) },
        manual = {
            filtered_angle_error = 0,
            target_angle = 0,
            measured_angle = 0,
            angular_correction = 0,
            elapsed = 0
        },
        steering = TruckSteeringState.default(),
        speed = {
            target_speed = 0,
            flags_1360 = 0
        },
        heading_previous = 0,
        pumping_settings = GroundPumping.load(p5),
        output_settings = {
            pushable_speed_terms_4_8 = {
                Collections.float(p5, "physics_push", "default", "MaxPushableSpeed_CameraDelta"),
                (Collections.float(p5, "physics_push", "default", "MaxPushableSpeed"))
            },
            mode_speed_threshold_0 = Collections.float(p5, "physics_push", "default", "Hash_501D5581043D7D3C")
        },
        entry_settings = v2.EntrySettings.load(p5)
    }
    local v13 = table.create(5)

    for v14, v15 in v4.NATIVE_MODES do
        local boolean = Collections.boolean
        local AutoPushEnabled, AutoPushEnabled2 = pcall(boolean, p5, "physics_mode", v15, "AutoPushEnabled")

        v13[v14] = { AutoPushEnabled, AutoPushEnabled2 }
    end

    local v16 = table.create(5)

    for v17, v18 in v13 do
        if not v18[1] then
            error(v18[2], 0)
        end

        v16[v17] = v18[2]
    end

    t2.auto_push_enabled = v16
    t2.entered = false

    return t2
end

function t1.GroundState.output(p9, p10, p11, p12) -- line: 113
    -- upvalues: rt (copy), v5 (copy), from_bits4 (copy)
    local v19 = p9.auto_push_enabled[p10.state_variant_index_2528 + 1]

    if v19 == nil then
        error(string.format("index out of bounds: the len is %d but the index is %d", #p9.auto_push_enabled, p10.state_variant_index_2528), 0)
    end

    return v5.fill_physics_output(p9.state, {
        axis_464 = from_bits4(p10.vectors_464_480_496_512_528[1]),
        velocity_608 = from_bits4(p10.vectors_544_560_592_608[4]),
        absolute_body_speed_2616 = p12.absolute_speed,
        deck_speed_2652 = p10.scalar_2652,
        state_timer_2664 = p10.state_timer_2664,
        scalar_2720 = p11.fields.balance,
        flags_2476 = p10.flags_2476,
        flags_2484 = p10.flags_2484,
        selected_mode_flag_109 = v19
    }, rt.copy(p9.output_settings))
end

for v20, v21 in v2.GroundState do
    t1.GroundState[v20] = v21
end

for v22, v23 in v3.GroundState do
    t1.GroundState[v22] = v23
end

return t1
