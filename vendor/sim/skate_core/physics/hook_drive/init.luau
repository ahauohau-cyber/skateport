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

local import = require(sim.import)
local v8 = import("skate_core/physics/hook_drive/frames")
local RetailDriveType = import("skate_core/physics/drive_parameters").RetailDriveType
local t1 = {
    set_child_angular_frame = v8.set_child_angular_frame,
    set_parent_angular_frame = v8.set_parent_angular_frame,
    HookDriveState = {}
}

function t1.HookDriveState.eq(p4, p5) -- line: 51
    for i = 1, 16 do
        if p4.frames[i] ~= p5.frames[i] then
            return false
        end
    end

    for i = 1, 8 do
        if p4.dynamics[i] ~= p5.dynamics[i] then
            return false
        end
    end

    return true
end

function t1.HookDriveState.initial() -- line: 67
    -- upvalues: rt (copy), t1 (copy)
    local t2 = {
        frames = table.create(16, 0),
        dynamics = table.create(8, 0)
    }
    local v9 = rt.map({
        1, 0, 0, 0, 0, 1, 0, 0,
        0, 0, 1, 0
    }, rt.to_bits)

    t1.set_child_angular_frame(t2.frames, rt.copy(v9))
    t1.set_parent_angular_frame(t2.frames, rt.copy(v9))
    t1.HookDriveState.disable_linear(t2)
    t1.HookDriveState.disable_angular(t2)

    return t2
end

function t1.HookDriveState.enable_animation_soft(p6, _) -- line: 83
    -- upvalues: t1 (copy)
    local v10 = t1.soft(5000, 1799.999755859375)

    p6.dynamics[1] = v10[1]
    p6.dynamics[2] = v10[2]
    p6.dynamics[3] = v10[3]
    p6.dynamics[4] = v10[4]
    t1.HookDriveState.enable_angular_soft(p6)

    return 1
end

function t1.HookDriveState.enable_angular_soft(p8) -- line: 94
    -- upvalues: t1 (copy)
    local v11 = t1.soft(20000, 35999.99609375)

    p8.dynamics[5] = v11[1]
    p8.dynamics[6] = v11[2]
    p8.dynamics[7] = v11[3]
    p8.dynamics[8] = v11[4]
end

function t1.HookDriveState.enable_angular_only(p9, _) -- line: 103
    -- upvalues: t1 (copy)
    t1.HookDriveState.enable_angular_soft(p9)
    t1.HookDriveState.disable_linear(p9)

    return 1
end

function t1.HookDriveState.disable_animation(p11, _) -- line: 113
    -- upvalues: t1 (copy)
    t1.HookDriveState.disable_linear(p11)
    t1.HookDriveState.disable_angular(p11)

    return 0
end

function t1.HookDriveState.disable_linear(p13) -- line: 120
    local t3 = {
        0, 0, 0, 2
    }

    p13.dynamics[1] = t3[1]
    p13.dynamics[2] = t3[2]
    p13.dynamics[3] = t3[3]
    p13.dynamics[4] = t3[4]
end

function t1.HookDriveState.disable_angular(p14) -- line: 126
    local t4 = {
        0, 0, 0, 2
    }

    p14.dynamics[5] = t4[1]
    p14.dynamics[6] = t4[2]
    p14.dynamics[7] = t4[3]
    p14.dynamics[8] = t4[4]
end

function t1.HookDriveState.solver_dynamics(p15) -- line: 133
    -- upvalues: v1 (copy), RetailDriveType (copy)
    local function params(p16) -- line: 134
        -- upvalues: p15 (copy), v1 (copy), RetailDriveType (copy)
        local v12 = p15.dynamics[p16 + 3 + 1]
        local v13 = if v12 == 1 then RetailDriveType.SoftDrive elseif v12 == 2 then RetailDriveType.HardDrive else RetailDriveType.NoDrive
        local t5 = {}

        buffer.writeu32(v1, 0, p15.dynamics[p16 + 1])
        t5.spring_or_max_velocity = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, p15.dynamics[p16 + 1 + 1])
        t5.damping = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, p15.dynamics[p16 + 2 + 1])
        t5.max_strength = buffer.readf32(v1, 0)
        t5.drive_type = v13

        return t5
    end

    return {
        linear = params(0),
        angular = params(4)
    }
end

function t1.soft(p17, p18) -- line: 157
    -- upvalues: v1 (copy), v8 (copy)
    local v17 = p17 * v8.rsqrt(p17) * 2
    local v18

    if p17 ~= 0 and p17 > -1.1754943508222875E-38 and p17 < 1.1754943508222875E-38 then
        local v19 = math.abs(p17) * 7.1362384635298E+44
        local v20 = math.floor(v19)
        local v21 = v19 - v20

        v18 = if v21 > 0.5 or v21 == 0.5 and v20 % 2 == 1 then v20 + 1 else v20

        if p17 < 0 then
            v18 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p17)
        v18 = buffer.readu32(v1, 0)
    end

    local v22

    if v17 ~= 0 and v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
        local v23 = math.abs(v17) * 7.1362384635298E+44
        local v24 = math.floor(v23)
        local v25 = v23 - v24

        v22 = if v25 > 0.5 or v25 == 0.5 and v24 % 2 == 1 then v24 + 1 else v24

        if v17 < 0 then
            v22 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v17)
        v22 = buffer.readu32(v1, 0)
    end

    local v26

    if p18 ~= 0 and p18 > -1.1754943508222875E-38 and p18 < 1.1754943508222875E-38 then
        local v27 = math.abs(p18) * 7.1362384635298E+44
        local v28 = math.floor(v27)
        local v29 = v27 - v28

        v26 = if v29 > 0.5 or v29 == 0.5 and v28 % 2 == 1 then v28 + 1 else v28

        if p18 < 0 then
            v26 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p18)
        v26 = buffer.readu32(v1, 0)
    end

    return {
        v18,
        v22,
        v26,
        1
    }
end

return t1
