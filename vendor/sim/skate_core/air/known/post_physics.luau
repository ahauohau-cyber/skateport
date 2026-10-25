-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {}

function t1.update_post_physics(p1, p2, p3, p4, p5, p6) -- line: 12
    -- upvalues: t1 (copy)
    if not p1.reached_apex_208 and p6.board_body_velocity(p6)[2] < 0 then
        p1.reached_apex_208 = true
    end

    p6.check_for_air_wipeout(p6, true)
    t1.check_upside_down_falling_wipeout(p1, p2, p3, p4, p5, p6)
end

function t1.check_upside_down_falling_wipeout(p7, p8, p9, p10, p11, p12) -- line: 24
    -- upvalues: rt (copy)
    if p9.upside_down_falling_wipeout_enabled_2 and bit32.band(p8.flags_2468, 32) == 0 and p8.skater_up_544[2] < p10.air_falling_min_up_y_260 and p12.dot3(p12, p7.landing_normal_64, p8.skater_up_544) < p10.air_falling_max_angle_264 then
        p11.requested_35 = true
        p11.scalar_116 = 0
        p11.counter_200 = rt.wrapping_add_u32(p11.counter_200, 1)
    end
end

return t1
