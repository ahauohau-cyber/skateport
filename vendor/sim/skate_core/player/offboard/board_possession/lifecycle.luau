-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/board_possession/math")
local PointGraph = import("skate_core/point_graph").PointGraph

local function board_possession() -- line: 11
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/board_possession")
end

local function motion() -- line: 14
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/board_possession/motion")
end

local dot, length, madd, reciprocal = v1.dot, v1.length, v1.madd, v1.reciprocal
local scale, sub, unit = v1.scale, v1.sub, v1.unit
local t1 = {
    Settings = {},
    Observation = {},
    Alignment = {},
    Effects = {},
    State = {}
}
local State = t1.State

function t1.State.stop(p1, p2, p3, p4, p5) -- line: 67
    -- upvalues: State (copy)
    if p2.system_on_452 then
        p2.word_444 = 0

        if p2.state_448 ~= 0 then
            State.let_go(p1, p2, p3, p4, p5)
            p2.state_448 = 0
        end

        p2.system_on_452 = false
    end
end

function t1.State.hold(p6, p7, p8, p9) -- line: 79
    -- upvalues: import (copy)
    p9.enable_animation_soft(p9)
    p9.standard_board(p9)
    p9.collision_volumes(p9, true)
    p7.state_448 = 1
    p6.selected_hand_424 = bit32.band(bit32.rshift(bit32.bnot(p8.processed.flags_2476), 2), 1)
    p6.hands[p6.selected_hand_424 + 1].dynamics = {
        { 1133903871, 0, 1183621119, 2 },
        { 1133903871, 0, 1183621119, 2 }
    }
    import("skate_core/player/offboard/board_possession").State.update_drive_frames(p6, p8)
end

function t1.State.disable_hand(p10) -- line: 93
    if p10.selected_hand_424 ~= 2 then
        p10.hands[p10.selected_hand_424 + 1].dynamics = {
            { 0, 0, 0, 2 },
            { 0, 0, 0, 2 }
        }
        p10.selected_hand_424 = 2
    end
end

function t1.State.let_go(p11, p12, p13, p14, p15) -- line: 101
    -- upvalues: import (copy), State (copy)
    p15.disable_animation(p15)
    p15.released_board(p15)
    p15.collision_volumes(p15, true)
    p15.clear_alignment(p15)
    State.disable_hand(p11)

    if p12.state_448 == 4 then
        p15.velocity(p15, { 0, 0, 0, 0 })
    end

    p12.word_444 = 0

    if bit32.band(p13.processed.flags_2476, 4096) ~= 0 then
        p12.word_444 = 8
        p15.velocity(p15, import("skate_core/player/offboard/board_possession/motion").throw_velocity(p13.processed, p14))
    end
end

function t1.State.hide(p16, p17, p18) -- line: 117
    -- upvalues: rt (copy), import (copy), State (copy)
    p18.collision_volumes(p18, false)
    p18.disable_linear_drive(p18)
    p18.clear_alignment(p18)
    State.disable_hand(p16)
    p16.retrieval = import("skate_core/player/offboard/board_possession").Retrieval.default()
    p16.retrieval.initial_0 = rt.copy(p17.processed.board_frame_64)
    p16.retrieval.elapsed_192 = 0
    p18.enable_animation_angular_only(p18)
end

function t1.State.retrieve(p19, p20, p21, p22, p23) -- line: 128
    -- upvalues: rt (copy), import (copy), PointGraph (copy), length (copy), madd (copy), reciprocal (copy), scale (copy), sub (copy)
    p23.collision_volumes(p23, false)
    p23.clear_alignment(p23)
    p23.enable_animation_angular_only(p23)

    local v4 = rt.copy(p19.retrieval.initial_0[4])

    p19.retrieval = import("skate_core/player/offboard/board_possession").Retrieval.default()
    p19.retrieval.initial_0 = rt.copy(p21.processed.board_frame_64)

    if p20.state_448 == 3 then
        p19.retrieval.initial_0[4] = v4
    end

    p19.retrieval.target_64 = rt.copy(p21.attachment_frame_0)

    local v5 = sub(p19.retrieval.initial_0[4], p19.retrieval.target_64[4])
    local v6 = length(v5)

    if not (v6 >= 0.0010000000474974513) then
        v5 = scale(p21.processed.player_frame_192[3], 0.0010000000474974513)
        v6 = 0.0010000000474974513
    end

    local v7 = bit32.band(p21.processed.flags_2480, 524288) ~= 0
    local v8 = if v7 then p22.mounted_return_distance else p22.return_distance

    if v8 < v6 or p20.state_448 == 3 then
        p19.retrieval.initial_0[4] = madd(scale(v5, v8), reciprocal(v6, 2), p19.retrieval.target_64[4])
        p23.position(p23, rt.copy(p19.retrieval.initial_0[4]))
    else
        v8 = v6
    end

    p19.retrieval.duration_196 = PointGraph.evaluate(p22.retrieval_time, v8)
    p19.retrieval.elapsed_192 = 0

    if not v7 then
        return
    end

    local duration_196 = p19.retrieval.duration_196

    p19.retrieval.duration_196 = if not (p22.mounting_time - duration_196 >= 0) then p22.mounting_time else duration_196
end

function t1.State.update_state(p24, p25, p26, p27, p28) -- line: 162
    -- upvalues: rt (copy), dot (copy), sub (copy), unit (copy), State (copy)
    local processed = p26.processed

    if p25.state_448 == 1 then
        local v9 = bit32.band(processed.flags_2480, 524288) == 0 and bit32.band(processed.flags_2488, 134217728) == 0
        local flags_2476 = processed.flags_2476

        if bit32.band(flags_2476, 8192) ~= 0 or v9 and bit32.band(p26.board_collision_flags_872, 67108864) ~= 0 then
            p25.word_444 = 0
            State.let_go(p24, p25, p26, p27, p28)
            p25.state_448 = 2
        else
            local v11 = p24.selected_hand_424 == 0 and 0 or 1

            p28.alignment(p28, {
                factor_1040 = 0.800000011920929,
                flag_1044 = true,
                first_1008 = unit(sub(p26.physical_hand_positions[v11 + 1], processed.board_frame_64[4]), { 0, 0, 0, 0 }),
                second_1024 = unit(sub(processed.position_592, processed.board_frame_64[4]), { 0, 0, 0, 0 })
            })
        end
    elseif p25.state_448 == 2 then
        local v12 = sub(processed.board_frame_64[4], processed.position_592)
        local v13 = dot(v12, v12) > p27.hide_distance * p27.hide_distance

        if not (bit32.band(processed.flags_2480, 524288) == 0 and bit32.band(processed.flags_2476, 2048) == 0) then
            p25.word_444 = 0
            State.retrieve(p24, p25, p26, p27, p28)
            p25.state_448 = 4
        elseif v13 or p26.board_state_840 == 6 then
            p25.word_444 = 0
            State.hide(p24, p26, p28)
            p25.state_448 = 3
        end
    elseif p25.state_448 == 3 then
        if not (bit32.band(processed.flags_2480, 524288) == 0 and bit32.band(processed.flags_2476, 2048) == 0) then
            p25.word_444 = 0
            State.retrieve(p24, p25, p26, p27, p28)
            p25.state_448 = 4
        end
    elseif p25.state_448 == 4 then
        local v20 = bit32.band(bit32.rshift(bit32.bnot(processed.flags_2476), 2), 1)

        if bit32.band(processed.flags_2480, 524288) == 0 and p26.hand_contacts[v20 + 1] then
            p25.word_444 = 0
            State.let_go(p24, p25, p26, p27, p28)
            p25.state_448 = 2
        elseif not (p24.retrieval.progress_200 < 1) then
            p28.velocity(p28, { 0, 0, 0, 0 })
            p25.word_444 = 0
            State.hold(p24, p25, p26, p28)
            p25.state_448 = 1
        end
    elseif p25.state_448 == 5 then
        if bit32.band(p26.board_collision_flags_872, 67108864) ~= 0 then
            p25.word_444 = 0
            State.let_go(p24, p25, p26, p27, p28)
            p25.state_448 = 2
        else
            p28.alignment(p28, {
                factor_1040 = 0.949999988079071,
                flag_1044 = false,
                first_1008 = rt.copy(processed.board_frame_64[3]),
                second_1024 = rt.copy(processed.board_frame_64[3])
            })
        end
    end
end

return t1
