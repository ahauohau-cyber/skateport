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

local import = require(sim.import)
local v8 = import("skate_core/physics/board")
local v9 = import("skate_core/physics/drive_frames")
local v10 = import("skate_core/math")
local v11 = import("skate_core/trigonometry")
local BodyId = v8.BodyId
local AuthoredTransformInputs = v9.AuthoredTransformInputs
local Vector3 = v10.Vector3
local t1 = {}

local function struct_eq(p3, p4) -- line: 44
    -- upvalues: struct_eq (copy)
    if type(p3) ~= "table" or type(p4) ~= "table" then
        return p3 == p4
    end

    for v12, v13 in p3 do
        if not struct_eq(v13, p4[v12]) then
            return false
        end
    end

    for v14 in p4 do
        if p3[v14] == nil then
            return false
        end
    end

    return true
end

t1.tu3 = {
    CREATE_JOINTS = 2193670760,
    ASSEMBLY_INITIALIZE = 2192440056,
    ASSEMBLY_POPULATE = 2192440248,
    FRAME_PACK_0 = 2193623360,
    FRAME_PACK_1 = 2193623792,
    FRAME_PACK_2 = 2193438808
}
t1.JOINT_COUNT = 6
t1.DEGREES_TO_RADIANS = 0.01745329238474369
t1.SIMULATION_FREQUENCY = 59.999996185302734
t1.HALF_PI = 1.5707963705062866
t1.RetailJointSettings = {}
t1.RetailJointSettings.eq = struct_eq
t1.RetailJointSettings.STOCK = {
    truck_twist_limit_degrees = 86.0999984741211,
    truck_twist_angle_degrees = 14,
    wheel_swing_limit_degrees = 1E+06
}
t1.RetailJointParametersRaw = {}
t1.RetailJointParametersRaw.eq = struct_eq
t1.RetailJointFramesRaw = {}
t1.RetailJointFramesRaw.eq = struct_eq
t1.RetailJointRecord = {}
t1.RetailJointRecord.eq = struct_eq

function t1.RetailJointRecord.live_body_a(p5) -- line: 101
    return p5.definition_body_1
end

function t1.RetailJointRecord.live_body_b(p6) -- line: 106
    return p6.definition_body_0
end

function t1.default_joint_records() -- line: 111
    -- upvalues: rt (copy), t1 (copy)
    return t1.joint_records(rt.copy(t1.RetailJointSettings.STOCK))
end

function t1.joint_records(p7) -- line: 115
    -- upvalues: rt (copy), v9 (copy), BodyId (copy), AuthoredTransformInputs (copy), t1 (copy)
    local v15 = t1.truck_parameters(p7)
    local v16 = t1.wheel_parameters(p7)
    local v17 = rt.map(v9.default_truck_drive_frames(), t1.truck_joint_frames)
    local v18 = t1.wheel_joint_orientation()
    local wheel_x_distance = AuthoredTransformInputs.STOCK.wheel_x_distance
    local v19 = t1.wheel_joint_frames(v18, wheel_x_distance)
    local v20 = t1.wheel_joint_frames(v18, -wheel_x_distance)

    return {
        t1.joint(BodyId.Deck, BodyId.FrontTruck, rt.copy(v15), rt.copy(v17[1])),
        t1.joint(BodyId.Deck, BodyId.BackTruck, rt.copy(v15), rt.copy(v17[2])),
        t1.joint(BodyId.FrontTruck, BodyId.RightFrontWheel, rt.copy(v16), rt.copy(v19)),
        t1.joint(BodyId.FrontTruck, BodyId.LeftFrontWheel, rt.copy(v16), rt.copy(v20)),
        t1.joint(BodyId.BackTruck, BodyId.RightBackWheel, rt.copy(v16), rt.copy(v19)),
        t1.joint(BodyId.BackTruck, BodyId.LeftBackWheel, rt.copy(v16), rt.copy(v20))
    }
end

function t1.truck_parameters(p8) -- line: 154
    -- upvalues: v1 (copy), v11 (copy), t1 (copy)
    local v21 = p8.truck_twist_angle_degrees * t1.DEGREES_TO_RADIANS
    local _, v22 = v11.sin_cos(v21)
    local v23 = p8.truck_twist_limit_degrees * t1.DEGREES_TO_RADIANS * t1.SIMULATION_FREQUENCY
    local v24 = table.create(16, 0)
    local v25

    if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
        local v26 = math.abs(v23) * 7.1362384635298E+44
        local v27 = math.floor(v26)
        local v28 = v26 - v27

        v25 = if v28 > 0.5 or v28 == 0.5 and v27 % 2 == 1 then v27 + 1 else v27

        if v23 < 0 then
            v25 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v23)
        v25 = buffer.readu32(v1, 0)
    end

    v24[9] = v25

    local v29

    if v21 ~= 0 and v21 > -1.1754943508222875E-38 and v21 < 1.1754943508222875E-38 then
        local v30 = math.abs(v21) * 7.1362384635298E+44
        local v31 = math.floor(v30)
        local v32 = v30 - v31

        v29 = if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31

        if v21 < 0 then
            v29 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v21)
        v29 = buffer.readu32(v1, 0)
    end

    v24[12] = v29
    buffer.writef32(v1, 0, 1)
    v24[13] = buffer.readu32(v1, 0)

    local v33

    if v22 ~= 0 and v22 > -1.1754943508222875E-38 and v22 < 1.1754943508222875E-38 then
        local v34 = math.abs(v22) * 7.1362384635298E+44
        local v35 = math.floor(v34)
        local v36 = v34 - v35

        v33 = if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35

        if v22 < 0 then
            v33 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v22)
        v33 = buffer.readu32(v1, 0)
    end

    v24[14] = v33
    v24[15] = 0
    v24[16] = 1

    return {
        words = v24
    }
end

function t1.wheel_parameters(p9) -- line: 170
    -- upvalues: v1 (copy), t1 (copy)
    local v37 = p9.wheel_swing_limit_degrees * t1.DEGREES_TO_RADIANS * t1.SIMULATION_FREQUENCY
    local v38 = table.create(16, 0)
    local v39

    if v37 ~= 0 and v37 > -1.1754943508222875E-38 and v37 < 1.1754943508222875E-38 then
        local v40 = math.abs(v37) * 7.1362384635298E+44
        local v41 = math.floor(v40)
        local v42 = v40 - v41

        v39 = if v42 > 0.5 or v42 == 0.5 and v41 % 2 == 1 then v41 + 1 else v41

        if v37 < 0 then
            v39 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v37)
        v39 = buffer.readu32(v1, 0)
    end

    v38[10] = v39
    buffer.writef32(v1, 0, 1)
    v38[13] = buffer.readu32(v1, 0)
    buffer.writef32(v1, 0, 1)
    v38[14] = buffer.readu32(v1, 0)
    v38[15] = 3
    v38[16] = 0

    return {
        words = v38
    }
end

function t1.truck_joint_frames(p10) -- line: 181
    -- upvalues: t1 (copy)
    return t1.pack_frames(p10.body_a, p10.body_b, p10.body_b.orientation)
end

function t1.wheel_joint_orientation() -- line: 185
    -- upvalues: v9 (copy), v11 (copy), t1 (copy)
    local v43, v44 = v11.sin_cos(t1.HALF_PI)

    return v9.retail_quaternion_from_basis({
        columns = {
            { 1, 0, 0 },
            { 0, v44, v43 },
            { 0, -v43, v44 }
        }
    })
end

function t1.wheel_joint_frames(p11, p12) -- line: 192
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy)
    return t1.pack_frames({
        orientation = rt.copy(p11),
        translation = rt.copy(Vector3.ZERO)
    }, {
        orientation = rt.copy(p11),
        translation = Vector3.new(0, 0, p12)
    }, p11)
end

function t1.pack_frames(p13, p14, p15) -- line: 202
    -- upvalues: t1 (copy)
    local v45 = table.create(20, 0)

    t1.write_quaternion(v45, 0, p13.orientation)
    t1.write_vector(v45, 4, p13.translation)
    t1.write_quaternion(v45, 8, p14.orientation)
    t1.write_vector(v45, 12, p14.translation)
    t1.write_quaternion(v45, 16, p15)

    return {
        words = v45
    }
end

function t1.write_quaternion(p16, p17, p18) -- line: 212
    -- upvalues: v1 (copy)
    local v46 = p17 + 1
    local x = p18.x
    local v47

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v48 = math.abs(x) * 7.1362384635298E+44
        local v49 = math.floor(v48)
        local v50 = v48 - v49

        v47 = if v50 > 0.5 or v50 == 0.5 and v49 % 2 == 1 then v49 + 1 else v49

        if x < 0 then
            v47 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v47 = buffer.readu32(v1, 0)
    end

    p16[v46] = v47

    local v51 = p17 + 2
    local y = p18.y
    local v52

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v53 = math.abs(y) * 7.1362384635298E+44
        local v54 = math.floor(v53)
        local v55 = v53 - v54

        v52 = if v55 > 0.5 or v55 == 0.5 and v54 % 2 == 1 then v54 + 1 else v54

        if y < 0 then
            v52 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v52 = buffer.readu32(v1, 0)
    end

    p16[v51] = v52

    local v56 = p17 + 3
    local z = p18.z
    local v57

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v58 = math.abs(z) * 7.1362384635298E+44
        local v59 = math.floor(v58)
        local v60 = v58 - v59

        v57 = if v60 > 0.5 or v60 == 0.5 and v59 % 2 == 1 then v59 + 1 else v59

        if z < 0 then
            v57 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v57 = buffer.readu32(v1, 0)
    end

    p16[v56] = v57

    local v61 = p17 + 4
    local w = p18.w
    local v62

    if w ~= 0 and w > -1.1754943508222875E-38 and w < 1.1754943508222875E-38 then
        local v63 = math.abs(w) * 7.1362384635298E+44
        local v64 = math.floor(v63)
        local v65 = v63 - v64

        v62 = if v65 > 0.5 or v65 == 0.5 and v64 % 2 == 1 then v64 + 1 else v64

        if w < 0 then
            v62 += 2147483648
        end
    else
        buffer.writef32(v1, 0, w)
        v62 = buffer.readu32(v1, 0)
    end

    p16[v61] = v62
end

function t1.write_vector(p19, p20, p21) -- line: 219
    -- upvalues: v1 (copy)
    local v66 = p20 + 1
    local x = p21.x
    local v67

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v68 = math.abs(x) * 7.1362384635298E+44
        local v69 = math.floor(v68)
        local v70 = v68 - v69

        v67 = if v70 > 0.5 or v70 == 0.5 and v69 % 2 == 1 then v69 + 1 else v69

        if x < 0 then
            v67 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v67 = buffer.readu32(v1, 0)
    end

    p19[v66] = v67

    local v71 = p20 + 2
    local y = p21.y
    local v72

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v73 = math.abs(y) * 7.1362384635298E+44
        local v74 = math.floor(v73)
        local v75 = v73 - v74

        v72 = if v75 > 0.5 or v75 == 0.5 and v74 % 2 == 1 then v74 + 1 else v74

        if y < 0 then
            v72 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v72 = buffer.readu32(v1, 0)
    end

    p19[v71] = v72

    local v76 = p20 + 3
    local z = p21.z
    local v77

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v78 = math.abs(z) * 7.1362384635298E+44
        local v79 = math.floor(v78)
        local v80 = v78 - v79

        v77 = if v80 > 0.5 or v80 == 0.5 and v79 % 2 == 1 then v79 + 1 else v79

        if z < 0 then
            v77 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v77 = buffer.readu32(v1, 0)
    end

    p19[v76] = v77
end

function t1.joint(p22, p23, p24, p25) -- line: 225
    return {
        definition_body_0 = p22,
        definition_body_1 = p23,
        parameters = p24,
        frames = p25
    }
end

return t1
