-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/board_possession/math")
local v2 = import("skate_core/player/offboard/board_possession/lifecycle")
local v3 = import("skate_core/player/offboard/board_possession/motion")
local t1 = {
    IDENTITY = {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 0 }
    }
}
local IDENTITY = t1.IDENTITY

t1.Retrieval = {}

function t1.Retrieval.default() -- line: 28
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        elapsed_192 = 0,
        duration_196 = 0,
        progress_200 = 0,
        weight_204 = 0,
        initial_0 = rt.copy(IDENTITY),
        target_64 = rt.copy(IDENTITY),
        current_128 = rt.copy(IDENTITY)
    }
end

t1.HandDrive = {}

function t1.HandDrive.default() -- line: 46
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        child = rt.copy(IDENTITY),
        parent = rt.copy(IDENTITY),
        dynamics = {
            { 0, 0, 0, 2 },
            { 0, 0, 0, 2 }
        }
    }
end

t1.State = {}

for _, v4 in {
        v2.State,
        v3.State
    } do
    for v5, v6 in v4 do
        t1.State[v5] = v6
    end
end

function t1.State.default() -- line: 64
    -- upvalues: t1 (copy)
    return {
        selected_hand_424 = 2,
        retrieval = t1.Retrieval.default(),
        hands = {
            t1.HandDrive.default(),
            t1.HandDrive.default()
        }
    }
end

t1.Processed = {}
t1.Fill = {}

function t1.fill(p1, p2, p3, p4) -- line: 87
    -- upvalues: rt (copy), v1 (copy)
    local v7 = rt.copy(p3.player_frame_192)
    local v8 = v1.madd(v7[2], v1.dot(v1.sub(p4[4], v7[4]), v7[2]), v7[4])
    local v9 = if p1.state_448 == 3 then rt.copy(p2.retrieval.initial_0[4]) else rt.copy(p3.board_frame_64[4])
    local v10 = v1.sub(v9, v8)
    local v11 = v1.quadrant_angle(v1.dot(v10, v7[1]), v1.dot(v10, v7[3]))
    local state_448 = p1.state_448
    local flags_2476 = p3.flags_2476

    return {
        angle_40 = 0,
        angle_36 = v11,
        held_311 = state_448 == 1,
        free_312 = state_448 == 2 or state_448 == 3 or state_448 == 4,
        returning_313 = state_448 == 4,
        hiding_321 = state_448 == 3,
        flag_322 = bit32.band(flags_2476, 512) ~= 0,
        flag_323 = bit32.band(flags_2476, 1024) ~= 0 or state_448 == 4,
        flag_324 = bit32.band(flags_2476, 1024) ~= 0 or bit32.band(flags_2476, 2048) ~= 0 and state_448 == 4
    }
end

return t1
