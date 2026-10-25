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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_core/physics/native_arithmetic")
local v9 = import("skate_core/physics/reciprocal_sqrt")
local t1 = {}

function t1.normalize_active_drive_frames(p4, p5) -- line: 46
    -- upvalues: t1 (copy)
    for i = 1, table.maxn(p5) do
        local v10 = p5[i]

        if v10 ~= nil then
            t1.normalize_drive_frames(p4[v10 + 1])
        end
    end
end

function t1.normalize_drive_frames(p6) -- line: 57
    -- upvalues: v1 (copy), v9 (copy), t1 (copy)
    for _, v11 in { 0, 8 } do
        buffer.writeu32(v1, 0, p6[v11 + 0 + 1])

        local v13 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p6[v11 + 1 + 1])

        local v15 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p6[v11 + 2 + 1])

        local v17 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p6[v11 + 3 + 1])

        local t2 = {
            v13,
            v15,
            v17,
            (buffer.readf32(v1, 0))
        }
        local v19 = t1.quaternion_squared_length(t2)
        local v20 = v9.estimate(v19)
        local v21 = v20 * v20
        local v22 = v20 * 0.5 * (-v19 * v21 + 1) + v20
        local v23 = v22 * v22
        local v24 = v22 * 0.5 * (-v19 * v23 + 1) + v22

        for i = 0, 3 do
            local v25 = v11 + i + 1
            local v26 = t2[i + 1] * v24

            if v26 ~= 0 and v26 > -1.1754943508222875E-38 and v26 < 1.1754943508222875E-38 then
                local v27 = math.abs(v26) * 7.1362384635298E+44
                local v28 = math.floor(v27)
                local v29 = v27 - v28
                local v30 = if v29 > 0.5 or v29 == 0.5 and v28 % 2 == 1 then v28 + 1 else v28

                if v26 < 0 then
                    p6[v25] = v30 + 2147483648
                else
                    p6[v25] = v30
                end
            else
                buffer.writef32(v1, 0, v26)
                p6[v25] = buffer.readu32(v1, 0)
            end
        end
    end
end

function t1.quaternion_squared_length(p7) -- line: 78
    -- upvalues: v8 (copy)
    return v8.dot4(p7, p7)
end

return t1
