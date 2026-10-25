-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    Mode = {
        Disabled = "Disabled",
        OnDeck = "OnDeck",
        External = "External",
        Local = "Local"
    },
    LimbStatus = {}
}

function t1.LimbStatus.default() -- line: 28
    return {
        mode = "Disabled",
        board_blend = 0,
        external_blend = 0,
        target_blend = 0,
        external_target_set = false,
        local_target_set = false,
        external_target_local_delta = { 0, 0, 0, 0 },
        part_position = { 0, 0, 0, 0 }
    }
end

function t1.update_modes(p1, p2, p3) -- line: 45
    local t2 = {
        p2,
        p2,
        bit32.band(p3, 128) ~= 0,
        bit32.band(p3, 256) ~= 0
    }

    for i = 0, 3 do
        local v3 = p1[i + 1]
        local v4 = if t2[i + 1] then "OnDeck" else "Disabled"
        local mode = v3.mode

        if mode == "Disabled" then
            v3.board_blend = 0

            if v3.external_target_set then
                v3.mode = "External"
                v3.external_blend = v3.target_blend
            elseif v3.local_target_set then
                v3.mode = "Local"
                v3.external_blend = v3.target_blend
                v3.external_target_local_delta = { 0, 0, 0, 0 }
            else
                v3.mode = v4
                v3.external_blend = 0
            end
        elseif mode == "OnDeck" then
            if v3.external_target_set then
                v3.mode = "External"
                v3.external_blend = v3.target_blend
            elseif v3.local_target_set then
                v3.mode = "Local"
                v3.external_blend = v3.target_blend
                v3.external_target_local_delta = { 0, 0, 0, 0 }
            elseif v3.board_blend == 0 then
                v3.mode = v4
                v3.external_blend = 0
            end
        elseif mode == "External" then
            if not v3.external_target_set then
                v3.mode = "Local"
            end
        elseif mode == "Local" then
            if v3.external_target_set then
                v3.mode = "External"
                v3.external_blend = v3.target_blend
            end

            if not v3.local_target_set and v3.external_blend == 0 then
                v3.mode = v4
                v3.external_target_local_delta = { 0, 0, 0, 0 }
            end
        end
    end
end

t1.BlendSettings = {}

local function select_(p4, p5, p6) -- line: 115
    if p4 >= 0 then
        return p5
    end

    return p6
end

local function positive(p7) -- line: 123
    if -p7 >= 0 then
        return 0
    end

    return p7
end

local function approach(p8, p9, p10) -- line: 128
    local v5 = p9 - p8
    local v6 = -p10 - v5
    local v7 = -p10

    if not (v6 >= 0) then
        v7 = v5
    end

    if not (p10 - v7 >= 0) then
        v7 = p10
    end

    return v7 + p8
end

function t1.update_blends(p11, p12, p13, p14, p15) -- line: 136
    local t3 = {
        p12,
        0,
        p13,
        0
    }
    local v8 = table.create(4)

    v8[1] = t3[1] + p15.hand_inner_padding[1]
    v8[2] = t3[2] + p15.hand_inner_padding[2]
    v8[3] = t3[3] + p15.hand_inner_padding[3]
    v8[4] = t3[4] + p15.hand_inner_padding[4]

    local v9 = table.create(4)

    v9[1] = v8[1] + p15.hand_outer_padding[1]
    v9[2] = v8[2] + p15.hand_outer_padding[2]
    v9[3] = v8[3] + p15.hand_outer_padding[3]
    v9[4] = v8[4] + p15.hand_outer_padding[4]

    local board_blend_step = p15.board_blend_step

    for i = 0, 3 do
        local v10 = p11[i + 1]
        local mode = v10.mode

        if mode ~= "Disabled" then
            if mode == "External" then
                v10.external_blend = v10.target_blend

                local v11 = v10.board_blend - board_blend_step

                v10.board_blend = if -v11 >= 0 then 0 else v11
            elseif mode == "Local" then
                if v10.local_target_set then
                    v10.external_blend = 1
                else
                    local v12 = v10.external_blend - p15.external_blend_step

                    v10.external_blend = if -v12 >= 0 then 0 else v12
                end

                local v13 = v10.board_blend - board_blend_step

                v10.board_blend = if -v13 >= 0 then 0 else v13
            elseif mode == "OnDeck" and i < 2 then
                local v14 = if bit32.band(p14, 134217728) == 0 then 1 else 0
                local board_blend = v10.board_blend
                local v15 = v14 - board_blend
                local v16 = -board_blend_step - v15
                local v17 = -board_blend_step

                if not (v16 >= 0) then
                    v17 = v15
                end

                if not (board_blend_step - v17 >= 0) then
                    v17 = board_blend_step
                end

                v10.board_blend = v17 + board_blend
            elseif mode == "OnDeck" then
                local t4 = {
                    math.abs(v10.part_position[1]),
                    math.abs(v10.part_position[2]),
                    math.abs(v10.part_position[3]),
                    (math.abs(v10.part_position[4]))
                }

                if v10.board_blend > 0 or t4[1] < v9[1] and t4[2] < v9[2] and t4[3] < v9[3] then
                    local n1 = 1

                    for _, v25 in { 0, 2, 1 } do
                        if t4[v25 + 1] > v8[v25 + 1] then
                            local v26 = 1 - (t4[v25 + 1] - v8[v25 + 1]) / p15.hand_outer_padding[v25 + 1]

                            if v25 == 0 then
                                n1 = v26
                            elseif v25 == 2 then
                                if n1 - v26 >= 0 then
                                    n1 = v26
                                end
                            elseif not (v26 - n1 >= 0) then
                                n1 = v26
                            end
                        end
                    end

                    if -n1 >= 0 then
                        n1 = 0
                    end

                    if not (1 - n1 >= 0) then
                        n1 = 1
                    end

                    local board_blend = v10.board_blend
                    local v27 = n1 - board_blend
                    local v28 = -board_blend_step - v27
                    local v29 = -board_blend_step

                    if not (v28 >= 0) then
                        v29 = v27
                    end

                    if not (board_blend_step - v29 >= 0) then
                        v29 = board_blend_step
                    end

                    v10.board_blend = v29 + board_blend
                end
            end
        end
    end
end

t1.select = select_
t1.positive = positive
t1.approach = approach

return t1
