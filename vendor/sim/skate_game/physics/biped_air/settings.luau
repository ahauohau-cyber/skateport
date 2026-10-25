-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local Collections = require(sim.import)("skate_data/collections").Collections

return {
    load = function(p1) -- load | line: 15
        -- upvalues: Collections (copy)
        local function f(p2) -- line: 16
            -- upvalues: p1 (copy), Collections (copy)
            return Collections.float(p1, "physics_wipeout", "default", p2)
        end

        return {
            skeleton_air = {
                squash = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirMaxSquash"),
                displacement = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirSkeletonMaxDisp"),
                body_contact = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirSkeletonMaxContact"),
                arm_contact = Collections.float(p1, "physics_wipeout", "default", "Wipeout_AirSkeletonMaxContactArms")
            },
            offboard_air = {
                squash = Collections.float(p1, "physics_wipeout", "default", "Wipeout_OB_MaxSquash"),
                displacement = Collections.float(p1, "physics_wipeout", "default", "Wipeout_OB_Air_SkelMaxDisp"),
                body_contact = Collections.float(p1, "physics_wipeout", "default", "Wipeout_OB_Air_SkelMaxContact"),
                arm_contact = Collections.float(p1, "physics_wipeout", "default", "Wipeout_OB_SkeletonMaxContactArms")
            },
            offboard_min_speed = Collections.float(p1, "physics_wipeout", "default", "Wipeout_OB_Air_MinSpeed")
        }
    end
}
