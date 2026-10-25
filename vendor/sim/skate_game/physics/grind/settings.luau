-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Collections = import("skate_data/collections").Collections
local v1 = import("skate_game/physics/grind/substate")
local t1 = {
    Settings = {}
}

function t1.Settings.load(p1) -- line: 22
    -- upvalues: rt (copy), Collections (copy), v1 (copy)
    local v2 = rt.map(Collections.words(p1, "physics_grinds", "default", "PinVsSlope", 8), rt.from_bits)
    local v3 = rt.map(Collections.words(p1, "physics_grinds", "default", "ExitAssistVsLeanAngle", 12), rt.from_bits)

    local function wipeout(p2) -- line: 26
        -- upvalues: p1 (copy), Collections (copy)
        return Collections.float(p1, "physics_wipeout", "default", p2)
    end

    local function graph(p3) -- line: 30
        -- upvalues: p1 (copy), rt (copy), Collections (copy)
        local v4 = rt.map(Collections.words(p1, "physics_reckoning", "default", p3, 16), rt.from_bits)

        return {
            x = rt.slice(v4, 0, 8),
            y = rt.slice(v4, 8)
        }
    end

    return {
        standard_angular_drag = Collections.float(p1, "physicsdeck", "default", "DeckAngularDrag") * 59.999996185302734,
        pin_vs_slope = {
            x = rt.slice(v2, 0, 4),
            y = rt.slice(v2, 4)
        },
        look_ahead = Collections.float(p1, "physics_grinds", "default", "GrindLookAheadScalar"),
        exit_assist = {
            x = rt.slice(v3, 4, 8),
            y = rt.slice(v3, 8)
        },
        post = {
            max_arm_contact_164 = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundSkeletonMaxContactArms"),
            max_body_contact_168 = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundSkeletonMaxContact"),
            xz_acceleration_204 = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GrindXZDeck"),
            max_displacement_208 = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GrindSkeletonMaxDisp"),
            max_angular_deck_error_212 = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GrindMaxAngularDeckError")
        },
        reckoning = {
            ground_normal_smoothing = rt.map(Collections.words(p1, "physics_reckoning", "default", "GroundNormalSmoothing", 4), rt.from_bits),
            tilt_vs_rotation = graph("TiltVsRotGround"),
            tilt_vs_slope = graph("TiltVsSlopeGround")
        },
        substate = v1.Settings.load(p1)
    }
end

return t1
