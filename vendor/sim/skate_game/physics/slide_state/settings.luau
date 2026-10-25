-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/slide_state")
local Collections = import("skate_data/collections").Collections
local t1 = {
    SlideState = {}
}

function t1.SlideState.load(p1) -- line: 20
    -- upvalues: v1 (copy), Collections (copy), t1 (copy)
    local function f(p2, p3) -- line: 21
        -- upvalues: p1 (copy), Collections (copy)
        return Collections.float(p1, p2, "default", p3)
    end

    local function c(p4) -- line: 24
        -- upvalues: p1 (copy), t1 (copy)
        return t1.curve(p1, "physics_slide", "default", p4)
    end

    local t2 = {}

    for _, v2 in ipairs({ "smooth", "rough", "slow", "slippery", "veryslow" }) do
        local Powerslide_SpeedToForce = t1.curve(p1, "physics_surfaces", v2, "Powerslide_SpeedToForce")
        local Powerslide_YawStrength = Collections.float(p1, "physics_surfaces", v2, "Powerslide_YawStrength")
        local Powerslide_YawDamping = Collections.float(p1, "physics_surfaces", v2, "Powerslide_YawDamping")
        local WheelStaticFriction = Collections.float(p1, "physics_surfaces", v2, "WheelStaticFriction")
        local WheelDynamicFriction = Collections.float(p1, "physics_surfaces", v2, "WheelDynamicFriction")
        local WheelRestitution = Collections.float(p1, "physicswheels", "default", "WheelRestitution")

        table.insert(t2, {
            {
                speed_to_force = Powerslide_SpeedToForce,
                yaw_strength = Powerslide_YawStrength,
                yaw_damping = Powerslide_YawDamping
            },
            {
                static_friction = WheelStaticFriction,
                dynamic_friction = WheelDynamicFriction,
                restitution = WheelRestitution
            }
        })
    end

    local v3 = v1.SlideState.new()
    local slide_input_remap = t1.curve(p1, "physics_slide", "default", "slide_input_remap")
    local Hash_DE162591FD9D91D7 = t1.curve(p1, "physics_slide", "default", "Hash_DE162591FD9D91D7")
    local Hash_91282E2CC4252731 = t1.curve(p1, "physics_slide", "default", "Hash_91282E2CC4252731")
    local Hash_2AD93E5ABA231D2 = t1.curve(p1, "physics_slide", "default", "Hash_2AD93E5ABA231D2")
    local SoftestWheelPowerslideFactor = Collections.float(p1, "physicswheels", "default", "SoftestWheelPowerslideFactor")
    local SoftestWheelPowerslideSpinFactor = Collections.float(p1, "physicswheels", "default", "SoftestWheelPowerslideSpinFactor")
    local AngularForceScalar = Collections.float(p1, "physics_slide", "default", "AngularForceScalar")
    local PowerSlideForceYOffset = Collections.float(p1, "physics_slide", "default", "PowerSlideForceYOffset")
    local PowerSlideScalar = Collections.float(p1, "physics_manual", "default", "PowerSlideScalar")

    return {
        state = v3,
        settings = {
            input_remap = slide_input_remap,
            remap_vs_speed = Hash_DE162591FD9D91D7,
            force_vs_angle = Hash_91282E2CC4252731,
            force_vs_speed = Hash_2AD93E5ABA231D2,
            softest_wheel_force = SoftestWheelPowerslideFactor,
            softest_wheel_spin = SoftestWheelPowerslideSpinFactor,
            angular_force = AngularForceScalar,
            force_y_offset = PowerSlideForceYOffset
        },
        surfaces = t2,
        manual_scalar = PowerSlideScalar
    }
end

function t1.curve(p5, p6, p7, p8) -- line: 78
    -- upvalues: rt (copy), Collections (copy)
    local v4 = rt.map(Collections.words(p5, p6, p7, p8, 20), rt.from_bits)

    return {
        x = rt.slice(v4, 4, 12),
        y = rt.slice(v4, 12, 20)
    }
end

return t1
