-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/air_launch/math")
local limit_length = import("skate_core/player/wipeout_state/math").limit_length
local projected_angle = import("skate_core/player/wipeout_state/orientation").projected_angle
local v2 = import("skate_core/animation/foot_ik")
local v3 = import("skate_core/player/offboard/controller")

local function recovered() -- line: 14
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/biped_air/recovered")
end

local add, clamp, cross, dot = v1.add, v1.clamp, v1.cross, v1.dot
local length, normalize, normalize_or, scale = v1.length, v1.normalize, v1.normalize_or, v1.scale
local sub, wrap_angle, UP, RADIANS = v1.sub, v1.wrap_angle, v1.UP, v1.RADIANS
local select, flatten, limit_angle, rotate = v1.select, v1.flatten, v1.limit_angle, v1.rotate
local t1 = {
    State = {}
}

function t1.State.animation_adjustment(p1, p2) -- line: 44
    -- upvalues: rt (copy), limit_length (copy), add (copy), dot (copy), sub (copy)
    if p1.flags_544_550[2] then
        if p2[2] > 0.1 then
            local v4 = sub(p2, p1.adjustment_496)

            if dot(v4, v4) > 0.001 then
                p1.adjustment_496 = add(p1.adjustment_496, limit_length(v4, 0.2))

                return rt.copy(p1.adjustment_496)
            end
        end
    elseif p1.flags_544_550[1] and p2[2] > 0.1 then
        p1.flags_544_550[2] = true
        p1.adjustment_496 = rt.copy(p2)

        return rt.copy(p2)
    end

    return nil
end

function t1.State.orient_sample(p3, p4, p5) -- line: 63
    -- upvalues: rt (copy), import (copy), v2 (copy), add (copy), normalize_or (copy), UP (copy), RADIANS (copy), limit_angle (copy), t1 (copy)
    if not p3.flags_544_550[1] and p3.result.valid_404 then
        p3.frame_80 = rt.copy(p3.frame_208)

        local v5 = rt.copy(UP)

        if p3.result.normal_304[2] > 0.85 then
            v5 = limit_angle(normalize_or(add(p3.result.normal_304, UP), p3.frame_80[2]), p3.frame_80[2], p3.result.time_remaining_384 * 180 * RADIANS)
        elseif p3.frame_80[2][2] < 0.71 then
            p3.flags_544_550[6] = true
        end

        t1.State.landing_orientation(p3, rt.copy(p3.result.contact_velocity_320), v5, p3.result.time_remaining_384, p4, p5)
        p3.flags_544_550[1] = true
        p3.flags_544_550[3] = false
    end

    import("skate_core/player/offboard/biped_air/recovered").State.update_times(p3)
    p3.frame_208 = v2.interpolate_native(p3.frame_80, p3.frame_144, p3.blend_440)

    local v6 = table.create(4)

    for i = 1, 4 do
        local v7 = p3.frame_208[i]

        v6[i] = {
            v7[1],
            v7[2],
            v7[3],
            0
        }
    end

    p3.frame_208 = v6
end

function t1.State.landing_orientation(p6, p7, p8, p9, p10, p11) -- line: 103
    -- upvalues: rt (copy), projected_angle (copy), v3 (copy), cross (copy), dot (copy), length (copy), normalize (copy), normalize_or (copy), scale (copy), sub (copy), wrap_angle (copy), UP (copy), flatten (copy), rotate (copy)
    if p6.flags_544_550[7] then
        p6.vector_512 = rt.copy(p6.frame_80[3])

        local v8 = flatten(p7)

        if dot(v8, v8) > 0.01 then
            local v9 = if bit32.band(p11, 4) == 0 then p10 else -p10

            p6.vector_512 = normalize(rotate(normalize(v8), UP, -v9))
        end

        p6.frame_144 = v3.build_frame(p8, p6.vector_512)
    else
        local v11 = math.abs(wrap_angle(projected_angle(p6.frame_208[3], p7, p8)) * 57.295780181884766)
        local v12 = p6.flags_544_550[3]
        local v13

        if v12 then
            p6.frame_80 = rt.copy(p6.frame_208)
            v13 = v11 > 90
        end

        if not v12 or not v13 then
            p6.frame_144 = rt.copy(p6.frame_208)

            if p9 < 0.033 then
                p6.frame_80 = rt.copy(p6.frame_208)
            else
                local v14 = sub(p7, scale(p8, dot(p7, p8)))
                local v15 = if length(v14) > 1 then normalize_or(cross(p8, p7), p6.frame_144[1]) else normalize_or(cross(p8, p6.frame_208[3]), p6.frame_144[1])

                if length(v14) > 1 and v11 > 90 and v11 / p9 > 540 then
                    p6.flags_544_550[6] = true
                    v15 = scale(v15, -1)
                end

                p6.frame_144[1] = rt.copy(v15)
                p6.frame_144[2] = rt.copy(p8)
                p6.frame_144[3] = normalize_or(cross(v15, p8), p6.frame_144[3])
            end
        end
    end
end

function t1.State.landing_assist_limit(p12) -- line: 143
    -- upvalues: clamp (copy), select (copy)
    local v17 = clamp(-(select(-(p12 - 0.034), 0, p12 - 0.034) * 6.25 - 1), 0, 1)

    return (1 - v17) * 0.5 + v17 * 3.5
end

function t1.State.finish_landing_latch(p13) -- line: 149
    if p13.time_remaining_444 <= 0 and p13.result.valid_404 and p13.result.normal_304[2] > 0.1 then
        p13.flags_544_550[5] = false
    end
end

return t1
