-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_game/physics/offboard/settings/board")
local v2 = import("skate_game/physics/offboard/settings/curves")
local v3 = import("skate_game/physics/offboard/settings/metrics")
local Collections = import("skate_data/collections").Collections
local t1 = {
    Settings = {}
}

function t1.Settings.load(p1, p2) -- line: 31
    -- upvalues: v1 (copy), v2 (copy), v3 (copy), Collections (copy)
    local function biped(p3) -- line: 33
        -- upvalues: p1 (copy), v2 (copy)
        return v2.load(8, p1, "physics_biped", p3)
    end

    local Hash_6B93C51256A30FB4, Hash_6B93C51256A30FB4_2 = v2.load(8, p1, "physics_biped", "Hash_6B93C51256A30FB4")
    local Hash_7209DCFDF3015EBF = v2.load(4, p1, "physics_biped", "Hash_7209DCFDF3015EBF")
    local SpeedVsInput = v2.load(16, p1, "physics_biped", "SpeedVsInput")
    local v4 = Hash_6B93C51256A30FB4_2[3]
    local AutoTurnVsAngle = v2.load(8, p1, "physics_biped", "AutoTurnVsAngle")
    local Hash_31309236050A8F09 = v2.load(8, p1, "physics_biped", "Hash_31309236050A8F09")
    local Hash_CE45C724B30F9134 = v2.load(8, p1, "physics_biped", "Hash_CE45C724B30F9134")
    local TurnVsSpeed = v2.load(8, p1, "physics_biped", "TurnVsSpeed")
    local TurnDeltaVsSpeed = v2.load(8, p1, "physics_biped", "TurnDeltaVsSpeed")
    local SlideVsSlope = v2.load(8, p1, "physics_biped", "SlideVsSlope")
    local SlideVsSpeed = v2.load(8, p1, "physics_biped", "SlideVsSpeed")
    local v5 = v3.load(p2)
    local v6 = v1.load(p1)
    local Hash_DF759B46440F16E9 = v2.load(8, p1, "physics_state_offboard", "Hash_DF759B46440F16E9")
    local TurnVsStickAngle = v2.load(8, p1, "physics_state_offboard", "TurnVsStickAngle")
    local JumpSpeedScalar = Collections.float(p1, "physics_biped", "default", "JumpSpeedScalar")
    local JumpHeight = Collections.float(p1, "physics_biped", "default", "JumpHeight")

    return {
        controller = {
            movement_intent = {
                sprint_speed = Hash_7209DCFDF3015EBF,
                normal_speed = SpeedVsInput,
                sprint_blend = Hash_6B93C51256A30FB4,
                sprint_time_cap = v4,
                slide_steering = AutoTurnVsAngle
            },
            movement_velocity = {
                slope_speed_scalar = Hash_31309236050A8F09,
                slope_mode_speed = Hash_CE45C724B30F9134,
                turn_vs_speed = TurnVsSpeed,
                turn_delta_vs_speed = TurnDeltaVsSpeed
            },
            slide_vs_slope = SlideVsSlope,
            slide_vs_speed = SlideVsSpeed
        },
        metrics = v5,
        board = v6,
        movement_vs_stick_angle = Hash_DF759B46440F16E9,
        turn_vs_stick_angle = TurnVsStickAngle,
        air_launch = {
            jump_speed_scalar = JumpSpeedScalar,
            jump_height = JumpHeight
        }
    }
end

function t1.Settings.into_controller_parts(p4) -- line: 86
    return p4.controller, p4.metrics, p4.movement_vs_stick_angle, p4.turn_vs_stick_angle, p4.air_launch
end

return t1
