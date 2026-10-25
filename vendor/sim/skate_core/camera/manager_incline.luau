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
local v8 = import("skate_core/camera/direction")
local v9 = import("skate_core/camera/vector_tracker")
local v10 = import("skate_core/camera/orientation_math")
local v11 = import("skate_core/camera/angle_tracker")
local Vector3 = import("skate_core/math").Vector3
local v12 = import("skate_core/physics/board_ground")
local v13 = import("skate_core/physics/native_arithmetic")
local v14 = import("skate_core/input/angle")

local function manager_state() -- line: 42
    -- upvalues: import (copy)
    return import("skate_core/camera/manager_state")
end

local direction_to_angles = v8.direction_to_angles
local dot, length = v9.dot, v9.length
local t1 = {
    ManagerState = {}
}

function t1.ManagerState.update_incline_reference(p4, p5) -- line: 57
    -- upvalues: rt (copy), import (copy), v10 (copy), v11 (copy), direction_to_angles (copy), dot (copy), length (copy), t1 (copy)
    local v15 = import("skate_core/camera/manager_state")
    local HALF_PI, UP = v15.HALF_PI, v15.UP

    p4.ground_normal = rt.copy(p5.ground_normal)

    local v16 = rt.copy(p5.rig.last_valid_ground_up)

    if not (v16[2] > 0.9999899864196777) or p5.rig.grinding ~= 0 then
        local v17 = if length(p4.anchor_velocity) > 9.999999974752427E-07 then v10.normalize(p4.anchor_velocity) else rt.copy(p5.rig.transform[3])

        p4.velocity_incline = HALF_PI - t1.angle_between(UP, v17)

        if p4.velocity_incline < 0 then
            p4.absolute_velocity_incline = -p4.velocity_incline
        else
            p4.absolute_velocity_incline = p4.velocity_incline
        end

        p4.ground_heading = direction_to_angles(v16)[2]

        local t2 = {}

        t2[1] = v16[1] * dot(UP, v16)
        t2[2] = v16[2] * dot(UP, v16)
        t2[3] = v16[3] * dot(UP, v16)
        t2[4] = v16[4] * dot(UP, v16)

        local v18 = v10.normalize({
            UP[1] - t2[1],
            UP[2] - t2[2],
            UP[3] - t2[3],
            UP[4] - t2[4]
        })
        local t3 = {
            -v16[3] * v18[2] + v16[2] * v18[3],
            -v16[1] * v18[3] + v16[3] * v18[1],
            -v16[2] * v18[1] + v16[1] * v18[2],
            0
        }
        local v19 = dot(v17, v18)
        local v20 = dot(v17, t3)

        p4.frontside_angle = t1.atan_ratio(v20, v19)
        p4.flags = bit32.bor(bit32.band(p4.flags, 4294967263), (bit32.lshift(if p4.frontside_angle > 0 then 1 else 0, 5)))

        if v15.ManagerState.mirrored(p4) then
            p4.frontside_angle *= -1
        end

        local v24 = p4.anchor_velocity[1]

        if math.abs(v24) > 1.1920928955078125E-07 or math.abs(p4.anchor_velocity[2]) > 1.1920928955078125E-07 or math.abs(p4.anchor_velocity[3]) > 1.1920928955078125E-07 then
            p4.direction_incline = v11.normalize_angle(HALF_PI - t1.angle_between(p5.direction_424, UP))
        end
    else
        p4.velocity_incline = 0
        p4.absolute_velocity_incline = 0
        p4.frontside_angle = 0
        p4.ground_heading = 0
        p4.direction_incline = 0
        p4.flags = bit32.band(p4.flags, 4294967263)
    end
end

function t1.angle_between(p6, p7) -- line: 127
    -- upvalues: Vector3 (copy), v12 (copy)
    local function to_vector(p8) -- line: 128
        -- upvalues: Vector3 (copy)
        return Vector3.new(p8[1], p8[2], p8[3])
    end

    return v12.angle_between(Vector3.new(p6[1], p6[2], p6[3]), to_vector(p7))
end

function t1.atan_ratio_reference(p9, p10) -- line: 136
    -- upvalues: v1 (copy), v13 (copy), v14 (copy)
    local v28 = v13.reciprocal_estimate(p10)
    local v29 = v28 * (-v28 * p10 + 1) + v28
    local v30 = v14.atan(p9 * v29 + 0)
    local v31

    if p9 ~= 0 and p9 > -1.1754943508222875E-38 and p9 < 1.1754943508222875E-38 then
        local v32 = math.abs(p9) * 7.1362384635298E+44
        local v33 = math.floor(v32)
        local v34 = v32 - v33

        v31 = if v34 > 0.5 or v34 == 0.5 and v33 % 2 == 1 then v33 + 1 else v33

        if p9 < 0 then
            v31 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p9)
        v31 = buffer.readu32(v1, 0)
    end

    local v35 = bit32.band(v31, 2147483648)

    if p10 < 0 then
        buffer.writeu32(v1, 0, (bit32.bor(1078530011, v35)))
        v30 = buffer.readf32(v1, 0) + v30
    end

    if p10 == 0 then
        buffer.writeu32(v1, 0, (bit32.bor(1070141403, v35)))
        v30 = buffer.readf32(v1, 0)
    end

    return v30
end

local atan = v14.atan

function t1.atan_ratio(p11, p12) -- line: 158
    -- upvalues: v1 (copy), atan (copy)
    local v38 = 1 / p12
    local v40 = atan(p11 * (v38 * (-v38 * p12 + 1) + v38) + 0)
    local v41

    if p12 < 0 then
        local v42

        if p11 == 0 then
            buffer.writef32(v1, 0, p11)
            v42 = buffer.readu32(v1, 0)
        elseif p11 > -1.1754943508222875E-38 and p11 < 1.1754943508222875E-38 then
            local v43 = math.abs(p11) * 7.1362384635298E+44

            v42 = math.floor(v43)

            local v44 = v43 - v42

            if v44 > 0.5 or v44 == 0.5 and v42 % 2 == 1 then
                v42 += 1
            end

            if p11 < 0 then
                v42 += 2147483648
            end
        else
            buffer.writef32(v1, 0, p11)
            v42 = buffer.readu32(v1, 0)
        end

        v41 = if bit32.band(v42, 2147483648) == 0 then 3.1415927410125732 + v40 else -3.1415927410125732 + v40
    else
        v41 = v40
    end

    if p12 ~= 0 then
        return v41
    end

    local v45

    if p11 == 0 then
        buffer.writef32(v1, 0, p11)
        v45 = buffer.readu32(v1, 0)
    elseif p11 > -1.1754943508222875E-38 and p11 < 1.1754943508222875E-38 then
        local v46 = math.abs(p11) * 7.1362384635298E+44

        v45 = math.floor(v46)

        local v47 = v46 - v45

        if v47 > 0.5 or v47 == 0.5 and v45 % 2 == 1 then
            v45 += 1
        end

        if p11 < 0 then
            v45 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p11)
        v45 = buffer.readu32(v1, 0)
    end

    if bit32.band(v45, 2147483648) ~= 0 then
        return -1.5707963705062866
    end

    return 1.5707963705062866
end

local PERF = import("skate_core/camera/tracker").PERF
local length3 = v9.length3
local direction_heading = v8.direction_heading
local normalize3 = v10.normalize3

function t1.ManagerState.update_incline(p13, p14) -- line: 197
    -- upvalues: import (copy), v11 (copy), t1 (copy), PERF (copy), length3 (copy), direction_heading (copy), normalize3 (copy)
    if PERF.reference then
        return t1.ManagerState.update_incline_reference(p13, p14)
    end

    local v48 = import("skate_core/camera/manager_state")
    local HALF_PI, UP = v48.HALF_PI, v48.UP
    local ground_normal = p14.ground_normal
    local ground_normal2 = p13.ground_normal
    local v49 = ground_normal[1]
    local v50 = ground_normal[2]
    local v51 = ground_normal[3]
    local v52 = ground_normal[4]

    ground_normal2[1] = v49
    ground_normal2[2] = v50
    ground_normal2[3] = v51
    ground_normal2[4] = v52

    local rig = p14.rig
    local last_valid_ground_up = rig.last_valid_ground_up
    local v53 = last_valid_ground_up[1]
    local v54 = last_valid_ground_up[2]
    local v55 = last_valid_ground_up[3]

    if not (v54 > 0.9999899864196777) or rig.grinding ~= 0 then
        local anchor_velocity = p13.anchor_velocity
        local v56 = anchor_velocity[1]
        local v57 = anchor_velocity[2]
        local v58 = anchor_velocity[3]
        local v59, v60, v61

        if length3(v56, v57, v58) > 9.999999974752427E-07 then
            v59, v60, v61 = normalize3(v56, v57, v58)
        else
            local v62 = rig.transform[3]

            v59 = v62[1]
            v60 = v62[2]
            v61 = v62[3]
        end

        p13.velocity_incline = HALF_PI - t1.angle_between(UP, { v59, v60, v61 })

        if p13.velocity_incline < 0 then
            p13.absolute_velocity_incline = -p13.velocity_incline
        else
            p13.absolute_velocity_incline = p13.velocity_incline
        end

        p13.ground_heading = direction_heading(v53, v55)

        local v63 = UP[1] * v53 + UP[2] * v54 + UP[3] * v55
        local v64, v65, v66 = normalize3(UP[1] - v53 * v63, UP[2] - v54 * v63, UP[3] - v55 * v63)
        local v67 = -v55 * v65 + v54 * v66
        local v68 = -v53 * v66 + v55 * v64
        local v69 = -v54 * v64 + v53 * v65
        local v70 = v59 * v64 + v60 * v65 + v61 * v66
        local v71 = v59 * v67 + v60 * v68 + v61 * v69

        p13.frontside_angle = t1.atan_ratio(v71, v70)
        p13.flags = bit32.bor(bit32.band(p13.flags, 4294967263), (bit32.lshift(if p13.frontside_angle > 0 then 1 else 0, 5)))

        if v48.ManagerState.mirrored(p13) then
            p13.frontside_angle *= -1
        end

        if math.abs(v56) > 1.1920928955078125E-07 or math.abs(v57) > 1.1920928955078125E-07 or math.abs(v58) > 1.1920928955078125E-07 then
            p13.direction_incline = v11.normalize_angle(HALF_PI - t1.angle_between(p14.direction_424, UP))
        end
    else
        p13.velocity_incline = 0
        p13.absolute_velocity_incline = 0
        p13.frontside_angle = 0
        p13.ground_heading = 0
        p13.direction_incline = 0
        p13.flags = bit32.band(p13.flags, 4294967263)
    end
end

return t1
