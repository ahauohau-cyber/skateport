-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local Collections = require(sim.import)("skate_data/collections").Collections

return {
    load = function(p1) -- load | line: 16
        -- upvalues: rt (copy), Collections (copy)
        local function f(p2) -- line: 17
            -- upvalues: p1 (copy), Collections (copy)
            return Collections.float(p1, "physics_wipeout", "default", p2)
        end

        local v1 = rt.map(Collections.words(p1, "physics_wipeout", "default", "Hash_4F08D9BAE6831524", 20), rt.from_bits)
        local t2 = {}

        for _, v2 in ipairs({ "easy", "normal", "hardcore", "motorized", "test" }) do
            table.insert(t2, {
                check_squash = Collections.boolean(p1, "physics_mode", v2, "Hash_CC890A3BDCF6290A"),
                check_bad_landing = Collections.boolean(p1, "physics_mode", v2, "WipeoutCheckForBadLanding"),
                ground_xz = Collections.float(p1, "physics_mode", v2, "Wipeout_GroundXZAcceleration"),
                bad_landing_scale = Collections.float(p1, "physics_mode", v2, "Hash_D978550D6DB4E6F7")
            })
        end

        local t4 = {
            ground = {
                vehicle_scalar = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundVehicleScalar"),
                vehicle_contact = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundVehicleContact"),
                skitch_contact = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundSkitchingContact"),
                skitch_scalar = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundSkitchingScalar"),
                skitch_arms_scalar = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundSkitchingScalarArms"),
                skater_scalar = Collections.float(p1, "physics_wipeout", "default", "SkaterSkaterThresholdScalar"),
                max_squash = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundMaxSquash"),
                max_squash_coffin = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundMaxSquashCoffin"),
                max_displacement = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundSkeletonMaxDisp"),
                max_contact = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundSkeletonMaxContact"),
                max_arm_contact = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundSkeletonMaxContactArms"),
                max_deck_error = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundMaxAngularDeckError"),
                opposing_contact = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundOpposingContact"),
                y_acceleration = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundYAcceleration"),
                light_dmo_scalar = Collections.float(p1, "physics_wipeout", "default", "WipeoutGroundLightDMOScalar"),
                player_scalar = Collections.float(p1, "physics_wipeout", "default", "DeckAccPlayerScalar"),
                ai_scalar = Collections.float(p1, "physics_wipeout", "default", "DeckAccAIScalar"),
                skitch_acc_scalar = Collections.float(p1, "physics_wipeout", "default", "DeckAccSkitchScalar"),
                balance_total = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundBalanceTotal"),
                balance_min_speed = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundBalanceMinSpeed"),
                balance_base = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundBalanceBase")
            },
            air = {
                xz_trick = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirXZTrick"),
                y_trick = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirYTrick"),
                xz_acceleration = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirXZAcceleration"),
                y_acceleration = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirYAcceleration"),
                max_squash = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirMaxSquash"),
                max_displacement = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirSkeletonMaxDisp"),
                max_contact = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirSkeletonMaxContact"),
                max_arm_contact = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirSkeletonMaxContactArms"),
                body_flip_scalar = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirBodyFlipScalar"),
                body_flip_acc_scalar = Collections.float(p1, "physics_wipeout", "default", "DeckAccBodyFlipScalar"),
                light_dmo_scalar = Collections.float(p1, "physics_wipeout", "default", "WipeoutAirLightDMOScalar"),
                ignore_danger_frames = rt.to_i32(Collections.integer(p1, "physics_wipeout", "default", "FramesAtStartOfAirToIgnoreDangerZone")),
                max_landing_speed = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirMaxSpeedIntoGround"),
                max_stairs_speed = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirMaxSpeedIntoStairs"),
                max_grind_speed = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirMaxSpeedIntoCollisionNearGrind"),
                max_landing_angle = {
                    x = rt.slice(v1, 4, 12),
                    y = rt.slice(v1, 12, 20)
                }
            },
            lean_contact_y = Collections.float(p1, "physics_wipeout", "default", "Wipeout_GroundLeanContactYThresh")
        }

        if #t2 ~= 5 then
            error("Expected five wipeout physics modes", 0)
        end

        return t4, t2
    end
}
