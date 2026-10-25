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

local Collections = require(sim.import)("skate_data/collections").Collections

return {
    load = function(p2) -- load | line: 23
        -- upvalues: rt (copy), v1 (copy), Collections (copy)
        local function scalar(p3) -- line: 24
            -- upvalues: p2 (copy), Collections (copy)
            return Collections.float(p2, "physics_airstates", "default", p3)
        end

        local function graph(p4) -- line: 28
            -- upvalues: p2 (copy), rt (copy), v1 (copy), Collections (copy)
            local v2 = Collections.words(p2, "physics_airstates", "default", p4, 20)
            local v3 = table.create(20)

            for i = 1, 20 do
                buffer.writeu32(v1, 0, v2[i])
                v3[i] = buffer.readf32(v1, 0)
            end

            return {
                x = rt.slice(v3, 4, 12),
                y = rt.slice(v3, 12, 20)
            }
        end

        local t2 = {
            max_heading_adjust_vs_up_y_160 = graph("MaxHeadingAdjustVsUpY"),
            landing_speed_scalar_vs_ground_normal_y_240 = graph("LandingSpeedScalarVsGroundNormalY"),
            flip_start_collision_time_vs_normal_y = graph("Hash_AA79C93673533C5B"),
            trajectory_error_blend_away_time_384 = Collections.float(p2, "physics_airstates", "default", "TrajErrorBlendAwayTime"),
            min_target_heading_velocity_420 = Collections.float(p2, "physics_airstates", "default", "MinTargetHeadingVel"),
            min_auto_body_speed_424 = Collections.float(p2, "physics_airstates", "default", "MinAutoBodySpeed"),
            max_spin_speed_428 = Collections.float(p2, "physics_airstates", "default", "MaxSpinSpeed"),
            frames_for_grind_air_assist_436 = Collections.float(p2, "physics_airstates", "default", "FramesForGrindAirAssist"),
            body_flip_min_grab_time_fraction_456 = Collections.float(p2, "physics_airstates", "default", "BodyFlipMinGrabTimeFraction"),
            flip_scalar = Collections.float(p2, "physics_reckoning", "default", "FlipScalar")
        }
        local v5 = table.create(5)

        for _, v6 in { "easy", "normal", "hardcore", "motorized", "test" } do
            table.insert(v5, {
                upside_down_falling_wipeout_enabled_2 = Collections.boolean(p2, "physics_mode", v6, "Hash_2B913C786BEFF4CD"),
                perfect_body_flips_28 = Collections.boolean(p2, "physics_mode", v6, "PerfectBodyFlips"),
                body_spin_speed_limit_56 = Collections.float(p2, "physics_mode", v6, "MaxAutoBodySpinSpeed")
            })
        end

        if #v5 ~= 5 then
            error("Expected five physics modes", 0)
        end

        return t2, v5
    end
}
