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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local ManualState = require(sim.import)("skate_core/physics/manual/state").ManualState
local t1 = {
    ManualGroundInput = {}
}
local remove_part

function t1.enter_ground(p3, p4, p5, p6, p7, p8) -- line: 58
    -- upvalues: ManualState (copy), t1 (copy)
    if ManualState.enter_ground(p3, p4, p5) == "RemoveVelocityIntoGround" then
        t1.remove_velocity_into_ground(p6, p7, p8)
    end
end

function t1.remove_velocity_into_ground(p9, p10, p11) -- line: 67
    -- upvalues: remove_part (ref)
    if p9.balance == 0 then
        return
    end

    remove_part(6, p9.ground_normal, p10, p11)

    local v9 = bit32.band(p9.flags_2468, 1048576) ~= 0
    local v10 = bit32.band(p9.flags_2472, 67108864) ~= 0
    local v11 = bit32.band(p9.flags_2472, 134217728) ~= 0

    if not v9 then
        v10, v11 = v11, v10
    end

    if v10 then
        remove_part(0, p9.ground_normal, p10, p11)
        remove_part(1, p9.ground_normal, p10, p11)
        remove_part(4, p9.ground_normal, p10, p11)
    end

    if not v11 then
        return
    end

    remove_part(2, p9.ground_normal, p10, p11)
    remove_part(3, p9.ground_normal, p10, p11)
    remove_part(5, p9.ground_normal, p10, p11)
end

function remove_part(p12, p13, p14, p15) -- line: 95
    -- upvalues: rt (copy), v1 (copy)
    local v12 = p14.linear_velocity(p14, p12)
    local v13 = p15.normal_speed(p15, p13, v12)
    local v14 = rt.copy(v12)
    local v15 = p13[1] * v13
    local v16

    if v15 ~= 0 and v15 > -1.1754943508222875E-38 and v15 < 1.1754943508222875E-38 then
        local v17 = math.abs(v15) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = (if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18) * 1.401298464324817E-45

        if v15 < 0 then
            v16 = -v16
        end
    else
        buffer.writef32(v1, 0, v15)
        v16 = buffer.readf32(v1, 0)
    end

    v14[1] = v12[1] - v16

    local v20 = p13[2] * v13
    local v21

    if v20 ~= 0 and v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
        local v22 = math.abs(v20) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = (if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23) * 1.401298464324817E-45

        if v20 < 0 then
            v21 = -v21
        end
    else
        buffer.writef32(v1, 0, v20)
        v21 = buffer.readf32(v1, 0)
    end

    v14[2] = v12[2] - v21

    local v25 = p13[3] * v13
    local v26

    if v25 ~= 0 and v25 > -1.1754943508222875E-38 and v25 < 1.1754943508222875E-38 then
        local v27 = math.abs(v25) * 7.1362384635298E+44
        local v28 = math.floor(v27)
        local v29 = v27 - v28

        v26 = (if v29 > 0.5 or v29 == 0.5 and v28 % 2 == 1 then v28 + 1 else v28) * 1.401298464324817E-45

        if v25 < 0 then
            v26 = -v26
        end
    else
        buffer.writef32(v1, 0, v25)
        v26 = buffer.readf32(v1, 0)
    end

    v14[3] = v12[3] - v26
    p14.set_linear_velocity(p14, p12, v14)
end

t1.remove_part = remove_part

return t1
