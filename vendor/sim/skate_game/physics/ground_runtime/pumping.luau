-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/ground_runtime/settings")
local Vector3 = import("skate_core/math").Vector3
local v2 = import("skate_core/physics/board_ground")
local signed_angle = import("skate_core/riding/collision_response").signed_angle
local dot_product = import("skate_core/riding/ground_correction_math").dot_product
local v3 = import("skate_core/riding/pumping/controller")
local NativePumpingGeometry = import("skate_core/riding/pumping/geometry").NativePumpingGeometry
local Collections = import("skate_data/collections").Collections
local t1 = {}
local wrap, xyz, v

local function pumping_geometry() -- line: 28
    -- upvalues: NativePumpingGeometry (copy)
    local t2 = {}

    return {
        height = function(_, ...) -- height | line: 31
            -- upvalues: t2 (copy), NativePumpingGeometry (copy)
            return NativePumpingGeometry.height(t2, ...)
        end,
        speed = function(_, ...) -- speed | line: 34
            -- upvalues: t2 (copy), NativePumpingGeometry (copy)
            return NativePumpingGeometry.speed(t2, ...)
        end,
        angular_speed = function(_, ...) -- angular_speed | line: 37
            -- upvalues: t2 (copy), NativePumpingGeometry (copy)
            return NativePumpingGeometry.angular_speed(t2, ...)
        end,
        inclination_radians = function(_, ...) -- inclination_radians | line: 40
            -- upvalues: t2 (copy), NativePumpingGeometry (copy)
            return NativePumpingGeometry.inclination_radians(t2, ...)
        end
    }
end

t1.GroundPumping = {}
t1.GroundPumpingMode = {}

function t1.GroundPumping.update_revert(p5, p6, p7, p8, p9, p10, p11) -- line: 59
    -- upvalues: rt (copy), v2 (copy), v3 (copy), t1 (copy), xyz (ref), v (ref), pumping_geometry (copy)
    local v4 = if p11 == 0 then math.abs(math.abs((v2.angle_between(xyz(p7.deck[3]), p8.reckoning.up))) - 1.5707963267948966) else 0
    local t4 = {
        position = rt.copy(p7.deck[4]),
        normal = v(p8.reckoning.ground_normal),
        com_to_deck_world = rt.copy(p9.record.com_to_deck_world),
        deck_angle = v4,
        intentional_pumping = bit32.band(bit32.rshift(p10.flags_2472, 16), 1)
    }

    v3.update(p6, p5.settings, t1.GroundPumping.mode(p5, p10.state_variant_index_2528).controller, t4, p10.timestep_2604, (pumping_geometry()))
end

function t1.GroundPumping.load(p12) -- line: 86
    -- upvalues: v1 (copy), Collections (copy)
    local function f(p13) -- line: 87
        -- upvalues: p12 (copy), Collections (copy)
        return Collections.float(p12, "physics_pumping", "default", p13)
    end

    local function c(p14) -- line: 90
        -- upvalues: p12 (copy), v1 (copy)
        return v1.curve8(p12, "physics_pumping", "default", p14)
    end

    local function mode(p15) -- line: 93
        -- upvalues: p12 (copy), Collections (copy)
        local function m(p16) -- line: 94
            -- upvalues: p15 (copy), p12 (copy), Collections (copy)
            return Collections.float(p12, "physics_mode", p15, p16)
        end

        return {
            controller = {
                maximum_absorption_per_second = Collections.float(p12, "physics_mode", p15, "Hash_9D1AEE3D7D8A4A7"),
                maximum_acceleration_per_second = Collections.float(p12, "physics_mode", p15, "Hash_D77AFD320B6241C5"),
                absorption_factor = Collections.float(p12, "physics_mode", p15, "PumpEffectFactorAbsorption"),
                acceleration_factor = Collections.float(p12, "physics_mode", p15, "PumpEffectFactor")
            },
            unintentional_scalar = Collections.float(p12, "physics_mode", p15, "UnintentionalPumpScalar")
        }
    end

    local t5 = {
        pump_vs_speed = v1.curve8(p12, "physics_pumping", "default", "PumpVsVel"),
        pump_vs_time = v1.curve8(p12, "physics_pumping", "default", "PumpVsTime"),
        min_crouch_vs_ground_angle = v1.curve8(p12, "physics_pumping", "default", "MinCrouchVsGroundAngle"),
        compression_vs_ground_angle = v1.curve8(p12, "physics_pumping", "default", "CompressionVsGroundAngle"),
        compression_vs_deck_angle = v1.curve8(p12, "physics_pumping", "default", "CompressionVsDeckAngle"),
        height_change_damping = Collections.float(p12, "physics_pumping", "default", "PumpEffectDamping"),
        minimum_height_change = Collections.float(p12, "physics_pumping", "default", "MinChangeInCOMBeforePumping"),
        maximum_height_change = Collections.float(p12, "physics_pumping", "default", "MaxDeltaHeightAllowedPerFrame"),
        ground_compression_scale = Collections.float(p12, "physics_pumping", "default", "CompressionGroundScalar"),
        deck_compression_scale = Collections.float(p12, "physics_pumping", "default", "CompressionDeckScalar"),
        angular_speed_damping = Collections.float(p12, "physics_pumping", "default", "AngularSpeedDamping")
    }
    local v8 = table.create(5)

    v8[1] = mode("easy")
    v8[2] = mode("normal")
    v8[3] = mode("hardcore")
    v8[4] = mode("motorized")
    v8[5] = mode("test")

    return {
        settings = t5,
        modes = v8
    }
end

function t1.GroundPumping.mode(p17, p18) -- line: 133
    -- upvalues: rt (copy)
    local v9 = p17.modes[p18 + 1]

    if v9 == nil then
        error(string.format("Invalid pumping physics mode %d", p18), 0)
    end

    return rt.copy(v9)
end

local signed_angle_xyz = import("skate_core/riding/collision_response").signed_angle_xyz
local v10

function t1.GroundPumping.mode_ref(p19, p20) -- line: 153
    local v11 = p19.modes[p20 + 1]

    if v11 == nil then
        error(string.format("Invalid pumping physics mode %d", p20), 0)
    end

    return v11
end

function t1.GroundPumping.update(p21, p22, p23, p24, p25, p26, p27) -- line: 172
    -- upvalues: dot_product (copy), v3 (copy), NativePumpingGeometry (copy), wrap (ref), v (ref), signed_angle_xyz (copy), v10 (ref)
    local v12 = v(p24.reckoning.up)
    local v13 = p25.board_frames.animation_target[3]
    local v14 = p23.deck[3]
    local v16 = math.abs((dot_product(v14, v12)))
    local v17 = dot_product(v13, v12)
    local v18 = 0

    if math.abs(v17) < v16 then
        local v19 = p24.reckoning_frames.ground[1]
        local v20 = v19[1]
        local v21 = v19[2]
        local v22 = v19[3]
        local v23 = v12[1]
        local v24 = v12[2]
        local v25 = v12[3]

        v18 = math.abs(wrap(signed_angle_xyz(v14[1], v14[2], v14[3], v23, v24, v25, v20, v21, v22)) - wrap(signed_angle_xyz(v13[1], v13[2], v13[3], v23, v24, v25, v20, v21, v22)))
    end

    local t6 = {
        position = p23.deck[4],
        normal = v(p24.reckoning.ground_normal),
        com_to_deck_world = p25.record.com_to_deck_world,
        deck_angle = v18,
        intentional_pumping = bit32.band(bit32.rshift(p26, 1), 1)
    }
    local v28 = v10

    if v28 == nil then
        v28 = {
            height = NativePumpingGeometry.height,
            speed = NativePumpingGeometry.speed,
            angular_speed = NativePumpingGeometry.angular_speed,
            inclination_radians = NativePumpingGeometry.inclination_radians
        }
        v10 = v28
    end

    v3.update_ground(p22, p21.settings, p27.controller, t6, v28)
end

function t1.GroundPumping.update_reference(p28, p29, p30, p31, p32, p33, p34) -- line: 212
    -- upvalues: rt (copy), signed_angle (copy), dot_product (copy), v3 (copy), wrap (ref), xyz (ref), v (ref), pumping_geometry (copy)
    local v29 = v(p31.reckoning.up)
    local v30 = rt.copy(p32.board_frames.animation_target[3])
    local v32 = math.abs((dot_product(p30.deck[3], v29)))
    local v33 = dot_product(v30, v29)
    local v34 = 0

    if math.abs(v33) < v32 then
        local v35 = xyz(p31.reckoning_frames.ground[1])

        v34 = math.abs(wrap(signed_angle(xyz(p30.deck[3]), xyz(v29), v35)) - wrap(signed_angle(xyz(v30), xyz(v29), v35)))
    end

    local t7 = {
        position = rt.copy(p30.deck[4]),
        normal = v(p31.reckoning.ground_normal),
        com_to_deck_world = rt.copy(p32.record.com_to_deck_world),
        deck_angle = v34,
        intentional_pumping = bit32.band(bit32.rshift(p33, 1), 1)
    }

    v3.update_ground(p29, p28.settings, rt.copy(p34.controller), t7, (pumping_geometry()))
end

function wrap(p35) -- line: 235
    local v38 = p35 * 0.15915493667125702
    local v39 = v38 - math.floor(v38)

    return (v39 - (if v39 > 0.5 then 1 else 0)) * 6.2831854820251465
end

t1.wrap = wrap

function xyz(p36) -- line: 243
    -- upvalues: Vector3 (copy)
    return Vector3.new(p36[1], p36[2], p36[3])
end

t1.xyz = xyz

function v(p37) -- line: 248
    return {
        p37.x,
        p37.y,
        p37.z,
        0
    }
end

t1.v = v

return t1
