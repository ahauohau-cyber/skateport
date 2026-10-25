-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local import = require(sim.import)
local State = import("skate_core/player/offboard/landing_state").State

local function landing_deck() -- line: 32
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/landing_deck")
end

local t1 = {}

local function map_to_bits(p3) -- line: 38
    -- upvalues: v1 (copy)
    local v8 = table.create(#p3)

    for i = 1, #p3 do
        local v9 = p3[i]

        if v9 ~= 0 and v9 > -1.1754943508222875E-38 and v9 < 1.1754943508222875E-38 then
            local v10 = math.abs(v9) * 7.1362384635298E+44
            local v11 = math.floor(v10)
            local v12 = v10 - v11
            local v13 = if v12 > 0.5 or v12 == 0.5 and v11 % 2 == 1 then v11 + 1 else v11

            if v9 < 0 then
                v8[i] = v13 + 2147483648
            else
                v8[i] = v13
            end
        else
            buffer.writef32(v1, 0, v9)
            v8[i] = buffer.readu32(v1, 0)
        end
    end

    return v8
end

local function u8_from(p4) -- line: 46
    if p4 then
        return 1
    end

    return 0
end

function t1.fill(p5) -- line: 51
    -- upvalues: v1 (copy), import (copy), State (copy)
    local state = p5.landing_on_deck.state
    local output = state.output

    if output == nil then
        error("Landing Fill requires its completed Update", 0)
    end

    local physical = p5.player_input.physical
    local off_board = physical.off_board

    off_board.trajectory_valid_331 = output.trajectory_valid and 1 or 0
    off_board.scalar_152 = output.elapsed

    local launch_position = output.launch_position
    local v14 = table.create(#launch_position)

    for i = 1, #launch_position do
        local v15 = launch_position[i]

        if v15 ~= 0 and v15 > -1.1754943508222875E-38 and v15 < 1.1754943508222875E-38 then
            local v16 = math.abs(v15) * 7.1362384635298E+44
            local v17 = math.floor(v16)
            local v18 = v16 - v17
            local v19 = if v18 > 0.5 or v18 == 0.5 and v17 % 2 == 1 then v17 + 1 else v17

            if v15 < 0 then
                v14[i] = v19 + 2147483648
            else
                v14[i] = v19
            end
        else
            buffer.writef32(v1, 0, v15)
            v14[i] = buffer.readu32(v1, 0)
        end
    end

    off_board.vector_176 = v14

    local landing_position = output.landing_position
    local v20 = table.create(#landing_position)

    for i = 1, #landing_position do
        local v21 = landing_position[i]

        if v21 ~= 0 and v21 > -1.1754943508222875E-38 and v21 < 1.1754943508222875E-38 then
            local v22 = math.abs(v21) * 7.1362384635298E+44
            local v23 = math.floor(v22)
            local v24 = v22 - v23
            local v25 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

            if v21 < 0 then
                v20[i] = v25 + 2147483648
            else
                v20[i] = v25
            end
        else
            buffer.writef32(v1, 0, v21)
            v20[i] = buffer.readu32(v1, 0)
        end
    end

    off_board.vector_208 = v20
    off_board.scalar_92 = output.landing_time

    local normal = output.normal
    local v26 = table.create(#normal)

    for i = 1, #normal do
        local v27 = normal[i]

        if v27 ~= 0 and v27 > -1.1754943508222875E-38 and v27 < 1.1754943508222875E-38 then
            local v28 = math.abs(v27) * 7.1362384635298E+44
            local v29 = math.floor(v28)
            local v30 = v28 - v29
            local v31 = if v30 > 0.5 or v30 == 0.5 and v29 % 2 == 1 then v29 + 1 else v29

            if v27 < 0 then
                v26[i] = v31 + 2147483648
            else
                v26[i] = v31
            end
        else
            buffer.writef32(v1, 0, v27)
            v26[i] = buffer.readu32(v1, 0)
        end
    end

    off_board.vector_192 = v26

    local apex_position = output.apex_position
    local v32 = table.create(#apex_position)

    for i = 1, #apex_position do
        local v33 = apex_position[i]

        if v33 ~= 0 and v33 > -1.1754943508222875E-38 and v33 < 1.1754943508222875E-38 then
            local v34 = math.abs(v33) * 7.1362384635298E+44
            local v35 = math.floor(v34)
            local v36 = v34 - v35
            local v37 = if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35

            if v33 < 0 then
                v32[i] = v37 + 2147483648
            else
                v32[i] = v37
            end
        else
            buffer.writef32(v1, 0, v33)
            v32[i] = buffer.readu32(v1, 0)
        end
    end

    off_board.vector_240 = v32
    off_board.scalar_156 = output.apex_time

    local direction = output.direction
    local v38 = table.create(#direction)

    for i = 1, #direction do
        local v39 = direction[i]

        if v39 ~= 0 and v39 > -1.1754943508222875E-38 and v39 < 1.1754943508222875E-38 then
            local v40 = math.abs(v39) * 7.1362384635298E+44
            local v41 = math.floor(v40)
            local v42 = v40 - v41
            local v43 = if v42 > 0.5 or v42 == 0.5 and v41 % 2 == 1 then v41 + 1 else v41

            if v39 < 0 then
                v38[i] = v43 + 2147483648
            else
                v38[i] = v43
            end
        else
            buffer.writef32(v1, 0, v39)
            v38[i] = buffer.readu32(v1, 0)
        end
    end

    off_board.vector_224 = v38

    local up = output.up
    local v44 = table.create(#up)

    for i = 1, #up do
        local v45 = up[i]

        if v45 ~= 0 and v45 > -1.1754943508222875E-38 and v45 < 1.1754943508222875E-38 then
            local v46 = math.abs(v45) * 7.1362384635298E+44
            local v47 = math.floor(v46)
            local v48 = v46 - v47
            local v49 = if v48 > 0.5 or v48 == 0.5 and v47 % 2 == 1 then v47 + 1 else v47

            if v45 < 0 then
                v44[i] = v49 + 2147483648
            else
                v44[i] = v49
            end
        else
            buffer.writef32(v1, 0, v45)
            v44[i] = buffer.readu32(v1, 0)
        end
    end

    off_board.vector_160 = v44
    off_board.scalar_32 = state.time_to_land
    off_board.flag_315 = state.near_deck and 1 or 0
    off_board.flag_318 = state.turning and 1 or 0
    physical.ground.hippy_takeoff_323 = state.takeoff_frames > 0 and 1 or 0
    physical.ground.hippy_jumping_322 = state.hippy and 1 or 0
    physical.ground.landing_half_turns_312 = State.landing_half_turns(state)

    local t2 = {
        off_board = off_board,
        skeleton_position_48 = physical.collision.vector_48,
        skeleton_flag_3482 = physical.collision.flag_3482
    }

    import("skate_game/physics/offboard/landing_deck").Owner.publish(p5.landing_deck, t2)
    physical.collision.flag_3482 = t2.skeleton_flag_3482
end

return t1
