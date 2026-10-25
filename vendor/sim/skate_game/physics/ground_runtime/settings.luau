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
local v2 = import("skate_game/physics/ground_runtime/input")
local v3 = import("skate_game/difficulty")
local Collections = import("skate_data/collections").Collections

local function parent() -- line: 26
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local manual_settings, curve8, curve16
local t1 = {}

t1.GroundProfiles = {}

function t1.GroundProfiles.load(p2) -- line: 43
    -- upvalues: import (copy), v3 (copy), t1 (copy)
    local t2 = {}

    for _, v4 in v3.NATIVE_MODES do
        local t3 = {}

        for i = 1, 5 do
            table.insert(t3, t1.GroundSettings.load(p2, v4, import("skate_game/physics/ground_runtime").surface_key(i)))
        end

        table.insert(t2, t3)
    end

    return { t2 }
end

function t1.GroundProfiles.select(p3, p4, p5) -- line: 56
    local v5

    if p5 >= 1 then
        local v6 = p5 - 1
        local v7 = p3[1][p4 + 1]

        if v7 ~= nil then
            v5 = v7[v6 + 1]
        end
    end

    if v5 == nil then
        error(string.format("Invalid processed physics mode/surface %d/%d", p4, p5), 0)
    end

    return v5
end

t1.GroundSettings = {}

function t1.GroundSettings.load(p6, p7, p8) -- line: 100
    -- upvalues: rt (copy), Collections (copy), manual_settings (ref), curve8 (ref), curve16 (ref)
    local function f(p9, p10) -- line: 101
        -- upvalues: p6 (copy), Collections (copy)
        return Collections.float(p6, p9, "default", p10)
    end

    local function m(p11) -- line: 104
        -- upvalues: p6 (copy), p7 (copy), Collections (copy)
        return Collections.float(p6, "physics_mode", p7, p11)
    end

    local function s(p12) -- line: 107
        -- upvalues: p6 (copy), p8 (copy), Collections (copy)
        return Collections.float(p6, "physics_surfaces", p8, p12)
    end

    local function c8(p13, p14) -- line: 110
        -- upvalues: p6 (copy), curve8 (ref)
        return curve8(p6, p13, "default", p14)
    end

    local function c16(p15, p16) -- line: 113
        -- upvalues: p6 (copy), curve16 (ref)
        return curve16(p6, p15, "default", p16)
    end

    local v8 = rt.filled(4, 9.999999974752427E-07)
    local v9 = p7 == "test"
    local HostPushStrength

    if v9 then
        local field = Collections.field

        HostPushStrength = pcall(field, p6, "physics_mode", p7, "HostPushStrength")
    end

    return {
        push_target_multiplier = if not v9 or not HostPushStrength then 1 else Collections.float(p6, "physics_mode", p7, "HostPushStrength"),
        foot_force_offset = Collections.float(p6, "physics_feet", "default", "FootForceOffset"),
        absorption_front = Collections.float(p6, "physics_feet", "default", "AbsorptionFootForceScalar"),
        absorption_rear = Collections.float(p6, "physics_feet", "default", "AbsorptionFootForceRearScalar"),
        surface_braking_factor = Collections.float(p6, "physics_surfaces", p8, "BrakingScalar"),
        steering = {
            hard_turn_increase = Collections.float(p6, "physics_steering", "default", "HardTurnIncrease"),
            damping = Collections.float(p6, "physics_steering", "default", "Damping"),
            speed_graph_max_speed = Collections.float(p6, "physics_steering", "default", "SteeringVsSpeedMaxSpeed"),
            push_scalar_increment = Collections.float(p6, "physics_steering", "default", "PushScalarIncriment"),
            push_scalar_decrement = Collections.float(p6, "physics_steering", "default", "PushScalarDecriment"),
            push_scalar_min = Collections.float(p6, "physics_steering", "default", "PushScalarMin"),
            manual_scalar = Collections.float(p6, "physics_manual", "default", "Tilt_TiltScalar"),
            general_scalar = Collections.float(p6, "physics_steering", "default", "GeneralScalar"),
            tight_trucks_scalar = Collections.float(p6, "physics_steering", "default", "SteeringScalar_TightTrucks"),
            speed_graph = curve8(p6, "physics_steering", "default", "SteeringVsSpeed"),
            input_graph = curve8(p6, "physics_steering", "default", "SteeringVsInput"),
            tilt_blending = Collections.float(p6, "physics_steering", "default", "SteeringTiltBlending")
        },
        wobble = {
            frequency_time = curve8(p6, "physics_speed_wobble", "default", "FrequencyVsTime"),
            frequency_speed = curve8(p6, "physics_speed_wobble", "default", "FrequencyVsSpeed"),
            amplitude_time = curve8(p6, "physics_speed_wobble", "default", "AmplitudeVsTime"),
            amplitude_speed = curve8(p6, "physics_speed_wobble", "default", "AmplitudeVsSpeed"),
            tightness_threshold = Collections.float(p6, "physics_speed_wobble", "default", "TruckTightnessSpeedMaxAdjust"),
            time_range = Collections.float(p6, "physics_speed_wobble", "default", "TimeMax"),
            speed_range = Collections.float(p6, "physics_speed_wobble", "default", "SpeedRange"),
            frequency_scale = Collections.float(p6, "physics_speed_wobble", "default", "MaxFrequency"),
            amplitude_scale = Collections.float(p6, "physics_speed_wobble", "default", "MaxAmplitude"),
            crouch_threshold = Collections.float(p6, "physics_speed_wobble", "default", "CrouchStartSpeedMaxAdjust"),
            height_min = Collections.float(p6, "physics_speed_wobble", "default", "CrouchMin"),
            height_max = Collections.float(p6, "physics_speed_wobble", "default", "CrouchMax")
        },
        propulsion = {
            braking = {
                input_force = Collections.float(p6, "physics_brakes", "default", "FootBrakeForce"),
                override_force = Collections.float(p6, "physics_brakes", "default", "TailBrakeForce"),
                minimum_speed = Collections.float(p6, "physics_brakes", "default", "SlowSpeed")
            },
            maximum_pushable_speed = Collections.float(p6, "physics_push", "default", "MaxPushableSpeed"),
            mode_speed_changes = {
                Collections.float(p6, "physics_mode", p7, "MaxPushDVStart"),
                (Collections.float(p6, "physics_mode", p7, "MaxPushDVEnd"))
            }
        },
        force = {
            range_1220 = Collections.float(p6, "physics_feet", "default", "LandingForceTime"),
            speed_scale_1224 = Collections.float(p6, "physics_feet", "default", "MinForce"),
            scale_1228 = Collections.float(p6, "physics_feet", "default", "MaxLandingForce"),
            normal_threshold = rt.copy(v8)
        },
        speed = {
            negative_gain = Collections.float(p6, "physics_speed_conservation", "default", "NegativeGeneralAmount"),
            maximum_gravity_acceleration = Collections.float(p6, "physics_speed_conservation", "default", "MaxGravityAcceleration"),
            gravity = Collections.float(p6, "physics_speed_conservation", "default", "Gravity"),
            positive_gain = Collections.float(p6, "physics_speed_conservation", "default", "GeneralAmount"),
            coffin_acceleration = Collections.float(p6, "physics_speed_conservation", "default", "CoffinAcceleration"),
            speed_error_bound = Collections.float(p6, "physics_surfaces", p8, "Friction_MaxSpeedChange"),
            surface_friction = curve8(p6, "physics_surfaces", p8, "FrictionVsSpeedNew"),
            manual_acceleration = Collections.float(p6, "physics_manual", "default", "SpinCorrectiveForce"),
            negative_manual_angle_limit = Collections.float(p6, "physics_manual", "default", "MinSpeedForCorrection"),
            manual_angle_limit = Collections.float(p6, "physics_manual", "default", "MaxSpeedForCorrection"),
            no_input_delay = Collections.float(p6, "physics_friction", "default", "NoInputTime"),
            no_input_friction = curve8(p6, "physics_friction", "default", "FrictionVsSpeed_NoInput"),
            manual_friction = curve8(p6, "physics_friction", "default", "FrictionVsSpeed_Manual"),
            override_enabled = Collections.boolean(p6, "physics_mode", p7, "MotorEnabled"),
            override_speed = Collections.float(p6, "physics_mode", p7, "MotorTopSpeed"),
            normal_threshold = rt.copy(v8),
            override_direction_threshold = { 0, 0, 0, 0 }
        },
        slide = {
            angle_response = curve16(p6, "physics_friction", "default", "SlideVsNormal"),
            speed_response = curve8(p6, "physics_friction", "default", "SlideVsSpeed"),
            time_response = curve16(p6, "physics_heading", "default", "SideFrictionFactor"),
            scalar_516 = Collections.float(p6, "physicswheels", "default", "SoftestWheelSideFrictionScalar"),
            heading_time_limit = Collections.float(p6, "physics_surfaces", p8, "StraightenOut_ForceTime"),
            friction = Collections.float(p6, "physics_surfaces", p8, "SideFriction_Scalar")
        },
        straighten = {
            time_response = curve16(p6, "physics_heading", "default", "StraightenOutForce"),
            opposite_turn_limit = Collections.float(p6, "physics_heading", "default", "StraightenMaxTurnInput"),
            time_scalar = Collections.float(p6, "physicswheels", "default", "SoftestWheelStraightenOutTimeScalar"),
            heading_time_limit = Collections.float(p6, "physics_surfaces", p8, "StraightenOut_ForceTime"),
            strength = Collections.float(p6, "physics_surfaces", p8, "StraightenOut_Scalar")
        },
        heading = {
            manual_wrong_wheel_scalar = Collections.float(p6, "physics_manual", "default", "SpinNoLiftScalar"),
            manual_damping = Collections.float(p6, "physics_manual", "default", "ManualSpinBlendSpeed"),
            speed_max = Collections.float(p6, "physics_heading", "default", "HeadingAdjustMaxSpeed"),
            heading_strength = Collections.float(p6, "physics_heading", "default", "HeadingAdjustFactor"),
            turn_strength = Collections.float(p6, "physics_heading", "default", "TurnTorqueScalar"),
            angular_response = curve8(p6, "physics_heading", "default", "TurnTorqueVsNegAngVel"),
            manual_response = curve8(p6, "physics_manual", "default", "SpinVsSpeed"),
            inclination_response = curve8(p6, "physics_heading", "default", "HeadingAdjustVsSlope"),
            speed_response = curve8(p6, "physics_heading", "default", "HeadingAdjustVsSpeed"),
            normal_threshold = rt.copy(v8)
        },
        anti_flip = {
            axis_96_response = curve8(p6, "physics_feet", "default", "AntiFlipTorqueX"),
            axis_64_response = curve8(p6, "physics_feet", "default", "AntiFlipTorqueZ"),
            normal_threshold = rt.copy(v8)
        },
        manual = manual_settings(p6),
        manual_mode = {
            correction_angular_speed_threshold = Collections.float(p6, "physics_mode", p7, "Hash_84CB2F459F3FC811"),
            corrective_force_enabled = Collections.boolean(p6, "physics_mode", p7, "Hash_F8CBC0F5FEF2240E")
        },
        drag = {
            brake_speed = Collections.float(p6, "physics_brakes", "default", "SlowSpeed"),
            balance_speed = Collections.float(p6, "physics_brakes", "default", "ManualSpinDragSpeed"),
            comparison_threshold = Collections.float(p6, "physics_brakes", "default", "ManualSpinDragNormal"),
            balance_drag = Collections.float(p6, "physics_brakes", "default", "ManualSpinDrag")
        },
        collision_duration = Collections.float(p6, "physics_collision", "default", "CollisionTorqueMaxTime"),
        collision_scale = Collections.float(p6, "physics_collision", "default", "CollisionTorqueFadeoff"),
        contact_force_time = Collections.float(p6, "physics_feet", "default", "MaxTimeWallRidingForFootForce"),
        wheel_material = {
            static_friction = Collections.float(p6, "physics_surfaces", p8, "WheelStaticFriction"),
            dynamic_friction = Collections.float(p6, "physics_surfaces", p8, "WheelDynamicFriction"),
            restitution = Collections.float(p6, "physicswheels", "default", "WheelRestitution")
        },
        wobble_activation = Collections.float(p6, "physics_mode", p7, "Hash_77AFCE78FE1206CA"),
        wobble_amplitude = Collections.float(p6, "physics_mode", p7, "Hash_5B57F2CCCCEEF430")
    }
end

function t1.GroundSettings.board(p17) -- line: 278
    -- upvalues: rt (copy)
    return {
        speed_model_reset_force_squared = 1.52587890625E-05,
        steering = p17.steering,
        speed_wobble = p17.wobble,
        propulsion = rt.copy(p17.propulsion),
        ground_force = p17.force,
        speed_model = p17.speed,
        slide_friction = p17.slide,
        straighten = p17.straighten,
        heading = p17.heading,
        anti_flip = p17.anti_flip,
        manual = p17.manual,
        manual_mode = rt.copy(p17.manual_mode),
        linear_drag = rt.copy(p17.drag),
        collision_response_duration = p17.collision_duration,
        collision_response_scale = p17.collision_scale,
        ground_force_contact_time_limit = p17.contact_force_time
    }
end

function manual_settings(p18) -- line: 300
    -- upvalues: Collections (copy), curve8 (ref)
    local function f(p19) -- line: 301
        -- upvalues: p18 (copy), Collections (copy)
        return Collections.float(p18, "physics_manual", "default", p19)
    end

    local function gains(p20, p21, p22) -- line: 304
        -- upvalues: p18 (copy), Collections (copy)
        return {
            proportional = Collections.float(p18, "physics_manual", "default", p20),
            integral = Collections.float(p18, "physics_manual", "default", p21),
            derivative = Collections.float(p18, "physics_manual", "default", p22)
        }
    end

    return {
        noise_vs_speed = curve8(p18, "physics_manual", "default", "NoiseVsSpeed"),
        torque_scale_without_contact = Collections.float(p18, "physics_manual", "default", "TorqueScalarWithNoContact"),
        torque_bleed_without_contact = Collections.float(p18, "physics_manual", "default", "TorqueBleedOffWithNoContact"),
        start_torque_scale = Collections.float(p18, "physics_manual", "default", "StartTorqueScalar"),
        procedural_noise_scale = Collections.float(p18, "physics_manual", "default", "ProceduralNoiseScalar"),
        procedural_noise_frequency = Collections.float(p18, "physics_manual", "default", "ProceduralNoiseFreq"),
        powerslide = {
            proportional = Collections.float(p18, "physics_manual", "default", "PowerScalar_P"),
            integral = Collections.float(p18, "physics_manual", "default", "PowerScalar_I"),
            derivative = Collections.float(p18, "physics_manual", "default", "PowerScalar_D")
        },
        manual = {
            proportional = Collections.float(p18, "physics_manual", "default", "ManualScalar_P"),
            integral = Collections.float(p18, "physics_manual", "default", "ManualScalar_I"),
            derivative = Collections.float(p18, "physics_manual", "default", "ManualScalar_D")
        },
        maximum_tilt_degrees = Collections.float(p18, "physics_manual", "default", "MaxTiltAngle"),
        maximum_angle_error = Collections.float(p18, "physics_manual", "default", "MaxAngleDiff"),
        derivative_limit = Collections.float(p18, "physics_manual", "default", "D_Scalar_Limit"),
        brake_tilt_degrees = Collections.float(p18, "physics_manual", "default", "BrakeTiltAngle"),
        animation_noise_scale = Collections.float(p18, "physics_manual", "default", "AnimationNoiseScalar")
    }
end

t1.manual_settings = manual_settings

function curve8(p23, p24, p25, p26) -- line: 330
    -- upvalues: v1 (copy), Collections (copy)
    local v10 = #Collections.field(p23, p24, p25, p26).data

    if v10 == 128 then
        local v11 = Collections.words(p23, p24, p25, p26, 16)
        local t5 = {}

        buffer.writeu32(v1, 0, v11[1])

        local v13 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[2])

        local v15 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[3])

        local v17 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[4])

        local v19 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[5])

        local v21 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[6])

        local v23 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[7])

        local v25 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[8])
        t5.x = {
            v13,
            v15,
            v17,
            v19,
            v21,
            v23,
            v25,
            (buffer.readf32(v1, 0))
        }
        buffer.writeu32(v1, 0, v11[9])

        local v28 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[10])

        local v30 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[11])

        local v32 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[12])

        local v34 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[13])

        local v36 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[14])

        local v38 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[15])

        local v40 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[16])
        t5.y = {
            v28,
            v30,
            v32,
            v34,
            v36,
            v38,
            v40,
            (buffer.readf32(v1, 0))
        }

        return t5
    end

    if v10 == 160 then
        local v42 = Collections.words(p23, p24, p25, p26, 20)
        local t6 = {}

        buffer.writeu32(v1, 0, v42[5])

        local v44 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[6])

        local v46 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[7])

        local v48 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[8])

        local v50 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[9])

        local v52 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[10])

        local v54 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[11])

        local v56 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[12])
        t6.x = {
            v44,
            v46,
            v48,
            v50,
            v52,
            v54,
            v56,
            (buffer.readf32(v1, 0))
        }
        buffer.writeu32(v1, 0, v42[13])

        local v59 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[14])

        local v61 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[15])

        local v63 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[16])

        local v65 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[17])

        local v67 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[18])

        local v69 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[19])

        local v71 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v42[20])
        t6.y = {
            v59,
            v61,
            v63,
            v65,
            v67,
            v69,
            v71,
            (buffer.readf32(v1, 0))
        }

        return t6
    end

    error(string.format("Invalid native eight-point graph %s/%s/%s", p24, p25, p26), 0)
end

t1.curve8 = curve8

function curve16(p27, p28, p29, p30) -- line: 388
    -- upvalues: v1 (copy), Collections (copy)
    local v73 = Collections.words(p27, p28, p29, p30, 32)
    local t7 = {}

    buffer.writeu32(v1, 0, v73[1])

    local v75 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[2])

    local v77 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[3])

    local v79 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[4])

    local v81 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[5])

    local v83 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[6])

    local v85 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[7])

    local v87 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[8])

    local v89 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[9])

    local v91 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[10])

    local v93 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[11])

    local v95 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[12])

    local v97 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[13])

    local v99 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[14])

    local v101 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[15])

    local v103 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[16])
    t7.x = {
        v75,
        v77,
        v79,
        v81,
        v83,
        v85,
        v87,
        v89,
        v91,
        v93,
        v95,
        v97,
        v99,
        v101,
        v103,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v73[17])

    local v106 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[18])

    local v108 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[19])

    local v110 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[20])

    local v112 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[21])

    local v114 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[22])

    local v116 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[23])

    local v118 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[24])

    local v120 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[25])

    local v122 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[26])

    local v124 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[27])

    local v126 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[28])

    local v128 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[29])

    local v130 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[30])

    local v132 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[31])

    local v134 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v73[32])
    t7.y = {
        v106,
        v108,
        v110,
        v112,
        v114,
        v116,
        v118,
        v120,
        v122,
        v124,
        v126,
        v128,
        v130,
        v132,
        v134,
        (buffer.readf32(v1, 0))
    }

    return t7
end

t1.curve16 = curve16

for v136, v137 in v2.GroundSettings do
    t1.GroundSettings[v136] = v137
end

return t1
