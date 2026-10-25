-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/biped_air/height")
local v2 = import("skate_core/player/offboard/biped_air/post")
local v3 = import("skate_core/player/offboard/biped_air/result")

import("skate_core/player/offboard/biped_air/sampling")
import("skate_core/player/offboard/biped_air/selection")

local v4 = import("skate_core/player/offboard/biped_air/collision")

import("skate_core/player/offboard/biped_air/feet")
import("skate_core/player/offboard/air_launch/math")

local v5 = import("skate_core/player/offboard/biped_air/orientation")
local v6 = import("skate_core/player/offboard/air_launch")
local v7 = import("skate_core/player/offboard/cadence")
local BipedCadence, BipedPhase = v7.BipedCadence, v7.BipedPhase
local TrajectoryResult = v3.TrajectoryResult
local dot, select, sub = v1.dot, v1.select, v1.sub
local t1 = {
    OffBoardOutput = v3.OffBoardOutput,
    TrajectoryResult = v3.TrajectoryResult,
    DT = 0.01666666753590107,
    IDENTITY = {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 0 }
    }
}
local DT, IDENTITY = t1.DT, t1.IDENTITY

t1.State = {}

for _, v8 in {
        v1.State,
        v2.State,
        v4.State,
        v5.State
    } do
    for v9, v10 in v8 do
        t1.State[v9] = v10
    end
end

function t1.State.default() -- line: 78
    -- upvalues: rt (copy), BipedCadence (copy), TrajectoryResult (copy), t1 (copy), IDENTITY (copy)
    local t2 = {
        height_432 = 0,
        body_offset_436 = 0,
        blend_440 = 0,
        time_remaining_444 = 0,
        duration_448 = -1,
        frame_452 = 0,
        active = false,
        frame_80 = rt.copy(IDENTITY),
        frame_144 = rt.copy(IDENTITY),
        frame_208 = rt.copy(IDENTITY),
        result = TrajectoryResult.default(),
        body_target_416 = { 0, 0, 0, 0 },
        local_contact_464 = { 0, 0, 0, 0 },
        initial_up_480 = { 0, 0, 0, 0 },
        adjustment_496 = { 0, 0, 0, 0 },
        vector_512 = { 0, 0, 0, 0 },
        restart_normal_528 = { 0, 0, 0, 0 },
        flags_544_550 = table.create(7, false),
        cadence = BipedCadence.default()
    }

    t1.State.reset(t2)

    return t2
end

t1.EnterInput = {}

function t1.State.reset(p1) -- line: 115
    -- upvalues: TrajectoryResult (copy)
    p1.flags_544_550 = { false, false, false, false, true, false, false }
    p1.height_432 = 0
    p1.body_offset_436 = 0
    p1.blend_440 = 0
    p1.time_remaining_444 = 0
    p1.duration_448 = -1
    p1.frame_452 = 0
    p1.body_target_416 = { 0, 0, 0, 0 }
    TrajectoryResult.reset(p1.result)
    p1.local_contact_464 = { 0, 0, 0, 0 }
    p1.adjustment_496 = { 0, 0, 0, 0 }
    p1.vector_512 = { 0, 0, 1, 0 }
    p1.restart_normal_528 = { 0, 0, 1, 0 }
end

function t1.State.begin_enter(p2, p3) -- line: 133
    -- upvalues: t1 (copy)
    t1.State.reset(p2)
    t1.State.begin_enter_after_reset(p2, p3)
end

function t1.State.begin_enter_after_reset(p4, p5) -- line: 139
    -- upvalues: rt (copy), IDENTITY (copy)
    p4.frame_80 = rt.copy(p5.animation_frame)
    p4.flags_544_550[7] = bit32.band(p5.flags_2484, 16384) ~= 0
    p4.frame_144 = rt.copy(IDENTITY)
    p4.frame_208 = rt.copy(p5.animation_frame)
    p4.initial_up_480 = rt.copy(p5.animation_frame[2])
    p4.active = true
end

function t1.State.finish_enter(p6, p7) -- line: 148
    -- upvalues: rt (copy), dot (copy), sub (copy)
    p6.body_target_416 = rt.copy(p7.body_position_15872)
    p6.height_432 = dot(sub(p7.body_position_15872, p7.position_592), p7.up_544)
    p6.body_offset_436 = dot(sub(p7.body_position_15936, p7.body_position_15872), p7.up_544)
end

function t1.State.launch_packet(_, p9, p10, p11, p12) -- line: 156
    -- upvalues: v6 (copy)
    local v11 = v6.Packet.initialized(0)

    v6.produce(v11, p10, p11, p12, p9, false)

    return v11
end

function t1.State.exit(p13, p14) -- line: 165
    p14.pending_8492 = false
    p14.preinitialized_8494 = false
    p13.active = false
end

function t1.State.begin_update(p15) -- line: 171
    -- upvalues: rt (copy)
    p15.frame_452 = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p15.frame_452), rt.to_u32(1)))

    return p15.frame_452
end

function t1.State.update_times(p16) -- line: 177
    -- upvalues: select (copy), DT (copy)
    local duration_388 = p16.result.duration_388

    p16.duration_448 = select(duration_388 - DT, duration_388, DT)

    if p16.result.valid_404 then
        p16.time_remaining_444 = p16.result.time_remaining_384

        local v12 = 1 - p16.time_remaining_444 / p16.duration_448
        local v13 = select(-v12, 0, v12)

        p16.blend_440 = select(1 - v13, v13, 1)
    else
        p16.blend_440 = 0
        p16.time_remaining_444 = 10
        p16.duration_448 = 10
    end
end

function t1.State.update_cadence(p17, p18, p19) -- line: 194
    -- upvalues: rt (copy), BipedPhase (copy), dot (copy), sub (copy)
    if p17.result.valid_404 then
        p18.correction_target_592 = rt.copy(p17.result.contact_position_336)

        local phase = p18.cadence.phase

        if p19 >= 0 and p17.time_remaining_444 > 0 then
            phase.forward_target = true

            local v14 = p19 - phase.phase

            phase.target = p19
            phase.duration = p17.time_remaining_444

            if v14 < 0 then
                phase.rate = (v14 + 1) / p17.time_remaining_444
            else
                phase.rate = v14 / p17.time_remaining_444
            end
        end

        BipedPhase.advance(phase)

        local v15 = rt.copy(p18.motion.frame_0)
        local v16 = sub(p17.result.contact_position_336, v15[4])

        p17.local_contact_464 = {
            dot(v15[1], v16),
            dot(v15[2], v16),
            dot(v15[3], v16),
            0
        }
    else
        p17.local_contact_464 = { 0, 0, 1, 0 }
    end

    p17.cadence = rt.copy(p18.cadence)
end

function t1.State.output(p20) -- line: 224
    -- upvalues: rt (copy), DT (copy)
    return {
        flag_331 = true,
        scalar_32 = p20.time_remaining_444,
        vector_64 = rt.copy(p20.result.velocity_288),
        scalar_92 = p20.duration_448,
        vector_96 = rt.copy(p20.local_contact_464),
        word_144 = p20.result.word_408,
        scalar_148 = p20.result.scalar_392,
        scalar_152 = p20.frame_452 * DT,
        scalar_156 = p20.result.apex_time_396,
        vector_160 = rt.copy(p20.initial_up_480),
        vector_176 = rt.copy(p20.frame_80[4]),
        vector_192 = rt.copy(p20.result.normal_304),
        vector_208 = rt.copy(p20.result.contact_position_336),
        vector_224 = rt.copy(p20.frame_144[3]),
        vector_240 = rt.copy(p20.result.apex_368),
        flag_320 = p20.time_remaining_444 <= DT,
        flag_328 = p20.flags_544_550[5]
    }
end

return t1
