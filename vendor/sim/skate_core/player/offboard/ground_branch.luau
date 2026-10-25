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

local import = require(sim.import)
local v9 = import("skate_core/player/offboard/contact_correction")
local v10 = import("skate_core/player/offboard/position_output")
local v11 = import("skate_core/physics/native_arithmetic")
local inverse_length, magnitude = v9.inverse_length, v9.magnitude
local FrameOutput = v10.FrameOutput
local dot3 = v11.dot3
local t1 = {}

t1.DT = 0.01666666753590107

local DT = t1.DT

t1.BranchInput = {}

function t1.select_alternate(p3) -- line: 52
    -- upvalues: rt (copy), v1 (copy), inverse_length (copy), magnitude (copy), dot3 (copy)
    local v12 = if p3.movement_velocity_480[2] > p3.output_velocity_512[2] then rt.copy(p3.output_velocity_512) else rt.copy(p3.movement_velocity_480)
    local suppressed_317 = p3.suppressed_317
    local v13 = if not suppressed_317 then bit32.band(p3.contact_flags_176, 2) == 0 else nil

    if suppressed_317 or v13 then
        return false
    end

    local t2 = {
        p3.contact_point_96[1] - p3.position_48[1],
        p3.contact_point_96[2] - p3.position_48[2],
        p3.contact_point_96[3] - p3.position_48[3],
        p3.contact_point_96[4] - p3.position_48[4]
    }

    if dot3(t2, t2) <= 0.002500000176951289 then
        return false
    end

    local v14 = rt.copy(p3.right_0)
    local t3 = {
        -t2[3] * v14[2] + t2[2] * v14[3],
        -t2[1] * v14[3] + t2[3] * v14[1],
        -t2[2] * v14[1] + t2[1] * v14[2],
        -t2[4] * v14[4] + t2[4] * v14[4]
    }
    local v15 = dot3(t3, t3)
    local v16 = inverse_length(v15)
    local t4

    if magnitude(v15) > 9.999999974752427E-07 then
        t4 = {}

        local v17 = t3[1] * v16
        local v18

        if v17 == 0 then
            buffer.writef32(v1, 0, v17)
            v18 = buffer.readf32(v1, 0)
        elseif v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
            local v19 = math.abs(v17) * 7.1362384635298E+44
            local v20 = math.floor(v19)
            local v21 = v19 - v20

            if v21 > 0.5 or v21 == 0.5 and v20 % 2 == 1 then
                v20 += 1
            end

            v18 = v20 * 1.401298464324817E-45

            if v17 < 0 then
                v18 = -v18
            end
        else
            buffer.writef32(v1, 0, v17)
            v18 = buffer.readf32(v1, 0)
        end

        local v22 = t3[2] * v16
        local v23

        if v22 ~= 0 and v22 > -1.1754943508222875E-38 and v22 < 1.1754943508222875E-38 then
            local v24 = math.abs(v22) * 7.1362384635298E+44
            local v25 = math.floor(v24)
            local v26 = v24 - v25

            v23 = (if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then v25 + 1 else v25) * 1.401298464324817E-45

            if v22 < 0 then
                v23 = -v23
            end
        else
            buffer.writef32(v1, 0, v22)
            v23 = buffer.readf32(v1, 0)
        end

        local v27 = t3[3] * v16
        local v28

        if v27 ~= 0 and v27 > -1.1754943508222875E-38 and v27 < 1.1754943508222875E-38 then
            local v29 = math.abs(v27) * 7.1362384635298E+44
            local v30 = math.floor(v29)
            local v31 = v29 - v30

            v28 = (if v31 > 0.5 or v31 == 0.5 and v30 % 2 == 1 then v30 + 1 else v30) * 1.401298464324817E-45

            if v27 < 0 then
                v28 = -v28
            end
        else
            buffer.writef32(v1, 0, v27)
            v28 = buffer.readf32(v1, 0)
        end

        local v32 = t3[4] * v16
        local v33

        if v32 ~= 0 and v32 > -1.1754943508222875E-38 and v32 < 1.1754943508222875E-38 then
            local v34 = math.abs(v32) * 7.1362384635298E+44
            local v35 = math.floor(v34)
            local v36 = v34 - v35

            v33 = (if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35) * 1.401298464324817E-45

            if v32 < 0 then
                v33 = -v33
            end
        else
            buffer.writef32(v1, 0, v32)
            v33 = buffer.readf32(v1, 0)
        end

        t4[1] = v18
        t4[2] = v23
        t4[3] = v28
        t4[4] = v33
    else
        t4 = { 0, 0, 0, 0 }
    end

    local v37 = dot3(v12, t4)
    local v38

    if v37 == 0 or not (v37 > -1.1754943508222875E-38) or not (v37 < 1.1754943508222875E-38) then
        buffer.writef32(v1, 0, v37)
        v38 = buffer.readf32(v1, 0)

        return v38 > 4
    end

    local v39 = math.abs(v37) * 7.1362384635298E+44
    local v40 = math.floor(v39)
    local v41 = v39 - v40

    v38 = (if v41 > 0.5 or v41 == 0.5 and v40 % 2 == 1 then v40 + 1 else v40) * 1.401298464324817E-45

    if v37 < 0 then
        v38 = -v38
    end

    return v38 > 4
end

function t1.integrate_alternate(p4, _, p6, p7, p8, p9, p10) -- line: 100
    -- upvalues: rt (copy), magnitude (copy), FrameOutput (copy), dot3 (copy), DT (copy)
    local t5 = {
        0, -9.800000190734863, 0, 0
    }

    rt.assign(p4, {
        t5[1] * DT + p4[1],
        t5[2] * DT + p4[2],
        t5[3] * DT + p4[3],
        t5[4] * DT + p4[4]
    })

    local v42 = magnitude(dot3(p4, p4))

    rt.assign(p6, {
        p4[1] * DT + p6[1],
        p4[2] * DT + p6[2],
        p4[3] * DT + p6[3],
        p4[4] * DT + p6[4]
    })
    FrameOutput.update(p7, p8, p9, p10, rt.copy(p6))

    return v42
end

return t1
