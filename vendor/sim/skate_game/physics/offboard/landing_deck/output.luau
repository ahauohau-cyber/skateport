-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
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

local Manager = require(sim.import)("skate_core/player/offboard/landing_deck").Manager
local t1 = {
    PublishTargets = {},
    Owner = {}
}

function t1.Owner.publish(p3, p4) -- line: 49
    -- upvalues: rt (copy), v1 (copy), Manager (copy)
    local v8 = Manager.fill(p3.manager)

    p4.off_board.flag_316 = v8.can_land_316 and 1 or 0
    p4.off_board.hippy_hurdling_317 = v8.hippy_hurdling_317 and 1 or 0

    local moving_contact = v8.moving_contact

    if moving_contact == nil then
        return
    end

    p4.skeleton_flag_3482 = 1

    local assign = rt.assign
    local skeleton_position_48 = p4.skeleton_position_48
    local v9 = moving_contact[1]
    local v10

    if v9 == 0 then
        buffer.writef32(v1, 0, v9)
        v10 = buffer.readu32(v1, 0)
    elseif v9 > -1.1754943508222875E-38 and v9 < 1.1754943508222875E-38 then
        local v11 = math.abs(v9) * 7.1362384635298E+44

        v10 = math.floor(v11)

        local v12 = v11 - v10

        if v12 > 0.5 or v12 == 0.5 and v10 % 2 == 1 then
            v10 += 1
        end

        if v9 < 0 then
            v10 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v9)
        v10 = buffer.readu32(v1, 0)
    end

    local v13 = moving_contact[2]
    local v14

    if v13 ~= 0 and v13 > -1.1754943508222875E-38 and v13 < 1.1754943508222875E-38 then
        local v15 = math.abs(v13) * 7.1362384635298E+44
        local v16 = math.floor(v15)
        local v17 = v15 - v16

        v14 = if v17 > 0.5 or v17 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16

        if v13 < 0 then
            v14 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v13)
        v14 = buffer.readu32(v1, 0)
    end

    local v18 = moving_contact[3]
    local v19

    if v18 ~= 0 and v18 > -1.1754943508222875E-38 and v18 < 1.1754943508222875E-38 then
        local v20 = math.abs(v18) * 7.1362384635298E+44
        local v21 = math.floor(v20)
        local v22 = v20 - v21

        v19 = if v22 > 0.5 or v22 == 0.5 and v21 % 2 == 1 then v21 + 1 else v21

        if v18 < 0 then
            v19 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v18)
        v19 = buffer.readu32(v1, 0)
    end

    local v23 = moving_contact[4]
    local v24

    if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
        local v25 = math.abs(v23) * 7.1362384635298E+44
        local v26 = math.floor(v25)
        local v27 = v25 - v26

        v24 = if v27 > 0.5 or v27 == 0.5 and v26 % 2 == 1 then v26 + 1 else v26

        if v23 < 0 then
            v24 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v23)
        v24 = buffer.readu32(v1, 0)
    end

    assign(skeleton_position_48, {
        v10,
        v14,
        v19,
        v24
    })
end

return t1
