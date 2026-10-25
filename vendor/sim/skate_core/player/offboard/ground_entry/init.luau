-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/ground_entry/math")
local v2 = import("skate_core/player/offboard/controller")
local TAU, IDENTITY, dot, scale = v1.TAU, v1.IDENTITY, v1.dot, v1.scale
local sub, length, wrap, signed_angle = v1.sub, v1.length, v1.wrap, v1.signed_angle
local rotate = v1.rotate
local t1 = {}

t1.State = {}

local State = t1.State

function t1.State.default() -- line: 43
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        counter_152 = 0,
        counter_156 = 0,
        elapsed_160 = 0,
        distance_164 = 1E+10,
        elapsed_168 = 0,
        angle_172 = 0,
        angular_velocity_176 = 0,
        duration_180 = 0,
        frame_80 = rt.copy(IDENTITY),
        flags_144_to_150 = table.create(7, false)
    }
end

t1.Input = {}
t1.Placement = {}

function t1.State.enter(p1, p2) -- line: 75
    -- upvalues: rt (copy), v2 (copy), TAU (copy), dot (copy), scale (copy), sub (copy), length (copy), wrap (copy), signed_angle (copy), rotate (copy), State (copy)
    rt.assign(p1, State.default())
    p1.flags_144_to_150[5] = p2.previous_state_2504 == 502

    local v3 = rt.copy(p2.animation_frame[2])
    local v4 = rt.copy(p2.processed_velocity_608)
    local v5 = sub(v4, scale(v3, dot(v3, v4)))
    local v6 = rt.copy(p2.animation_frame)

    if bit32.band(p2.processed_flags_2484, 16384) ~= 0 then
        p1.flags_144_to_150[7] = true
        p1.duration_180 = p2.requested_duration_2896

        local requested_angle_2936 = p2.requested_angle_2936

        if bit32.band(p2.processed_flags_2476, 4) ~= 0 then
            requested_angle_2936 *= -1
        end

        local v7 = if length(v5) < 0.10000000149011612 then rt.copy(p2.animation_frame[3]) else rt.copy(v5)
        local v8 = v2.build_frame(v3, v7)

        v6[1] = rt.copy(v8[1])
        v6[2] = rt.copy(v8[2])
        v6[3] = rt.copy(v8[3])
        p1.angle_172 = wrap(signed_angle(v7, rotate(p2.animation_frame[3], v3, requested_angle_2936), v3))

        local v10 = wrap(signed_angle(p2.animation_frame[3], v7, v3))

        if not (math.abs(requested_angle_2936) <= 1.5707963705062866) and not (v10 * requested_angle_2936 >= 0) then
            v10 += if not (v10 > 0) then TAU else -TAU
        end

        p1.angular_velocity_176 = (p1.angle_172 + v10) / p1.duration_180
    end

    p1.frame_80 = rt.copy(v6)
    p1.flags_144_to_150[6] = true

    if p2.previous_state_2504 == 501 then
        p1.flags_144_to_150[2] = p2.previous_frame_up_208[2] < 0.7099999785423279
    end

    return {
        frame = v6,
        planar_velocity = v5,
        body_position = rt.copy(p2.body_position_15872)
    }
end

return t1
