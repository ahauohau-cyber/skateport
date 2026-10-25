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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

require(sim.import)

local t1 = {
    ContactRows = {}
}

function t1.ContactRows.read(p4) -- line: 43
    -- upvalues: v1 (copy), t1 (copy)
    if #p4 ~= 64 then
        error("assertion `left == right` failed\n  left: " .. #p4 .. "\n right: 64", 0)
    end

    local t2 = {
        arm_a = t1.read(p4, 0),
        arm_b = t1.read(p4, 1),
        correction_columns = {
            t1.read(p4, 2),
            t1.read(p4, 3),
            t1.read(p4, 4)
        }
    }

    buffer.writeu32(v1, 0, p4[16])
    t2.static_friction = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p4[20])
    t2.dynamic_friction = buffer.readf32(v1, 0)
    t2.accumulated = t1.read(p4, 5)
    t2.target = t1.read(p4, 6)
    t2.axes = {
        t1.read(p4, 7),
        t1.read(p4, 10),
        t1.read(p4, 13)
    }
    t2.angular_a = {
        t1.read(p4, 8),
        t1.read(p4, 11),
        t1.read(p4, 14)
    }
    t2.angular_b = {
        t1.read(p4, 9),
        t1.read(p4, 12),
        t1.read(p4, 15)
    }

    return t2
end

function t1.ContactRows.publish_impulses(_, p6, p7) -- line: 61
    -- upvalues: t1 (copy)
    t1.write(p6, 5, p7)
end

t1.Reaction = {}

function t1.Reaction.read(p8) -- line: 68
    -- upvalues: t1 (copy)
    if #p8 ~= 16 then
        error("assertion `left == right` failed\n  left: " .. #p8 .. "\n right: 16", 0)
    end

    return {
        linear = t1.read(p8, 0),
        position = t1.read(p8, 1),
        angular = t1.read(p8, 2),
        orientation = t1.read(p8, 3)
    }
end

function t1.Reaction.point_position(p9, p10) -- line: 80
    -- upvalues: t1 (copy)
    return t1.point_correction(p10, p9.position, p9.orientation)
end

function t1.Reaction.point_velocity(p11, p12) -- line: 84
    -- upvalues: t1 (copy)
    return t1.point_correction(p12, p11.linear, p11.angular)
end

function t1.Reaction.apply_contact(p13, p14, p15, p16) -- line: 88
    local v10 = if p16 then p14.angular_a else p14.angular_b
    local v11 = v10[1][4]

    for i = 0, 3 do
        local v12 = p14.axes[1][i + 1] * p15[1] + 0
        local v13 = p14.axes[2][i + 1] * p15[2] + v12
        local v14 = p14.axes[3][i + 1] * p15[3] + v13
        local v15 = p14.axes[1][i + 1] * p15[4] + 0

        if p16 then
            for j = 0, 2 do
                local v16 = p15[j + 1]

                p13.angular[i + 1] = v10[j + 1][i + 1] * v16 + p13.angular[i + 1]
            end

            p13.orientation[i + 1] = v10[1][i + 1] * p15[4] + p13.orientation[i + 1]
            p13.linear[i + 1] = v14 * v11 + p13.linear[i + 1]
            p13.position[i + 1] = v15 * v11 + p13.position[i + 1]
        else
            for k = 0, 2 do
                local v17 = p15[k + 1]

                p13.angular[i + 1] = -v10[k + 1][i + 1] * v17 + p13.angular[i + 1]
            end

            p13.orientation[i + 1] = -v10[1][i + 1] * p15[4] + p13.orientation[i + 1]
            p13.linear[i + 1] = -v14 * v11 + p13.linear[i + 1]
            p13.position[i + 1] = -v15 * v11 + p13.position[i + 1]
        end
    end
end

function t1.Reaction.write(p17, p18) -- line: 121
    -- upvalues: t1 (copy)
    local t3 = {
        p17.linear,
        p17.position,
        p17.angular,
        p17.orientation
    }

    t1.write(p18, 0, t3[1])
    t1.write(p18, 1, t3[2])
    t1.write(p18, 2, t3[3])
    t1.write(p18, 3, t3[4])
end

function t1.point_correction(p19, p20, p21) -- line: 130
    -- upvalues: rt (copy)
    return rt.from_fn(4, function(p22) -- line: 131
        -- upvalues: p19 (copy), p20 (copy), p21 (copy)
        local v18 = if p22 == 3 then 3 else (p22 + 1) % 3
        local v19 = if p22 == 3 then 3 else (p22 + 2) % 3
        local v20 = p21[v18 + 1] * p19[v19 + 1] + p20[p22 + 1]

        return -p21[v19 + 1] * p19[v18 + 1] + v20
    end)
end

function t1.read(p23, p24) -- line: 139
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p23[p24 * 4 + 0 + 1])

    local v22 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p23[p24 * 4 + 1 + 1])

    local v24 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p23[p24 * 4 + 2 + 1])

    local v26 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p23[p24 * 4 + 3 + 1])

    return {
        v22,
        v24,
        v26,
        (buffer.readf32(v1, 0))
    }
end

function t1.write(p25, p26, p27) -- line: 148
    -- upvalues: v1 (copy)
    for i = 0, 3 do
        local v28 = p26 * 4 + i + 1
        local v29 = p27[i + 1]

        if v29 ~= 0 and v29 > -1.1754943508222875E-38 and v29 < 1.1754943508222875E-38 then
            local v30 = math.abs(v29) * 7.1362384635298E+44
            local v31 = math.floor(v30)
            local v32 = v30 - v31
            local v33 = if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31

            if v29 < 0 then
                p25[v28] = v33 + 2147483648
            else
                p25[v28] = v33
            end
        else
            buffer.writef32(v1, 0, v29)
            p25[v28] = buffer.readu32(v1, 0)
        end
    end
end

return t1
