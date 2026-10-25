-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local transform_point = require(sim.import)("skate_core/physics/skeleton_animation_record").transform_point
local t1 = {
    FootContact = {}
}

function t1.FootContact.default() -- line: 20
    return {
        query_state = 0,
        desired_offset = 0,
        offset = 0,
        position = { 0, 0, 0, 0 }
    }
end

t1.ContactState = {}

function t1.ContactState.default() -- line: 31
    -- upvalues: t1 (copy)
    return {
        support_failed = false,
        support_failed_this_update = false,
        feet = {
            t1.FootContact.default(),
            t1.FootContact.default()
        }
    }
end

t1.ContactInput = {}

local function contact_offset(p1, p2) -- line: 54
    local v1 = table.create(4)

    for i = 0, 3 do
        local v2 = p1[1][i + 1] * 0
        local v3 = p1[2][i + 1] * p2 + v2

        v1[i + 1] = p1[3][i + 1] * 0 + v3
    end

    return v1
end

local function distance_to_contact(p3, p4, p5, p6) -- line: 66
    -- upvalues: transform_point (copy), contact_offset (copy)
    local v4 = transform_point(p6, p3.position)
    local v5 = contact_offset(p5, p3.offset)
    local v6 = table.create(4)

    v6[1] = p4.world[4][1] + v5[1]
    v6[2] = p4.world[4][2] + v5[2]
    v6[3] = p4.world[4][3] + v5[3]
    v6[4] = p4.world[4][4] + v5[4]

    return transform_point(p6, v6)[2] - 0.02500000037252903 - v4[2]
end

local function add_offset(p7, p8, p9) -- line: 77
    -- upvalues: contact_offset (copy)
    local v7 = contact_offset(p8, p9)

    for i = 0, 3 do
        local v8 = v7[i + 1]

        p7.world[4][i + 1] += v8
        p7.parent_world[4][i + 1] += v8
    end
end

local function select_(p10, p11, p12) -- line: 86
    if p10 >= 0 then
        return p11
    end

    return p12
end

local function limit_offset(p13) -- line: 94
    local v9 = if -0.10000000149011612 - p13 >= 0 then -0.10000000149011612 else p13

    if 0.10000000149011612 - v9 >= 0 then
        return v9
    end

    return 0.10000000149011612
end

local function approach(p14) -- line: 101
    local v10 = p14.desired_offset - p14.offset

    if -0.014999999664723873 - v10 >= 0 then
        v10 = -0.014999999664723873
    end

    if not (0.014999999664723873 - v10 >= 0) then
        v10 = 0.014999999664723873
    end

    p14.offset = v10 + p14.offset
end

function t1.ContactState.update(p15, p16, p17, p18) -- line: 109
    -- upvalues: rt (copy), transform_point (copy), distance_to_contact (copy), add_offset (copy)
    p15.support_failed_this_update = false

    local v11 = bit32.band(p18.flags_2468, 1107296256) ~= 0

    for i = 0, 1 do
        local v12 = p15.feet[i + 1]
        local v13 = p17[i + 1]

        if p16[i + 1].mode == "OnDeck" and p18.contact_bone == p18.foot_bones[i + 1] then
            local query_state = v12.query_state
            local v14 = v11

            if query_state == 1 then
                local v15 = transform_point(p18.inverse_board, v12.position)[2] + 0.08250000327825546

                if v15 <= 0.30000001192092896 then
                    if bit32.band(p18.flags_2468, 25165824) == 0 then
                        if -0.10000000149011612 - v15 >= 0 then
                            v15 = -0.10000000149011612
                        end

                        if not (0.10000000149011612 - v15 >= 0) then
                            v15 = 0.10000000149011612
                        end

                        v12.desired_offset = v15
                    else
                        v12.desired_offset = 0
                    end

                    local v16 = v12.desired_offset - v12.offset

                    if -0.014999999664723873 - v16 >= 0 then
                        v16 = -0.014999999664723873
                    end

                    if not (0.014999999664723873 - v16 >= 0) then
                        v16 = 0.014999999664723873
                    end

                    v12.offset = v16 + v12.offset

                    local v17 = distance_to_contact(v12, v13, p18.board, p18.inverse_board)

                    if v17 < 0 and v17 > -0.30000001192092896 then
                        v12.offset -= v17
                    end

                    add_offset(v13, p18.board, v12.offset)

                    if v11 then
                        v14 = v17 > 0.029999999329447746 and v12.offset < -0.009999999776482582
                    end
                else
                    local desired_offset = v12.desired_offset

                    if -0.10000000149011612 - desired_offset >= 0 then
                        desired_offset = -0.10000000149011612
                    end

                    v12.desired_offset = if not (0.10000000149011612 - desired_offset >= 0) then 0.10000000149011612 else desired_offset

                    local v18 = v12.desired_offset - v12.offset

                    if -0.014999999664723873 - v18 >= 0 then
                        v18 = -0.014999999664723873
                    end

                    if not (0.014999999664723873 - v18 >= 0) then
                        v18 = 0.014999999664723873
                    end

                    v12.offset = v18 + v12.offset
                    add_offset(v13, p18.board, v12.offset)
                    v14 = v11 or p18.hips_world_position[2] > 0.699999988079071
                end
            elseif query_state == 0 or query_state == 2 then
                local desired_offset = v12.desired_offset

                if -0.10000000149011612 - desired_offset >= 0 then
                    desired_offset = -0.10000000149011612
                end

                if 0.10000000149011612 - desired_offset >= 0 then
                    v12.desired_offset = desired_offset
                else
                    v12.desired_offset = 0.10000000149011612
                end

                local v19 = v12.desired_offset - v12.offset

                if -0.014999999664723873 - v19 >= 0 then
                    v19 = -0.014999999664723873
                end

                if not (0.014999999664723873 - v19 >= 0) then
                    v19 = 0.014999999664723873
                end

                v12.offset = v19 + v12.offset
                add_offset(v13, p18.board, v12.offset)

                if v12.query_state ~= 2 then
                    v14 = false
                end
            else
                v14 = false
            end

            local v20 = p18.current_contacts[i + 1]

            if v20 ~= nil then
                v12.position = rt.copy(v20)
                v12.query_state = 1
            else
                v12.query_state = 2
            end

            if v14 then
                p15.support_failed = true
                p15.support_failed_this_update = true
            end
        else
            v12.query_state = 0
            v12.desired_offset = 0

            local v21 = v12.desired_offset - v12.offset

            if -0.014999999664723873 - v21 >= 0 then
                v21 = -0.014999999664723873
            end

            v12.offset = (if 0.014999999664723873 - v21 >= 0 then v21 else 0.014999999664723873) + v12.offset
            add_offset(v13, p18.board, v12.offset)
        end
    end
end

t1.distance_to_contact = distance_to_contact
t1.add_offset = add_offset
t1.contact_offset = contact_offset
t1.select = select_
t1.limit_offset = limit_offset
t1.approach = approach

return t1
