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
local v8 = import("skate_core/physics/solver/contact_build")
local v9 = import("skate_core/physics/solver/joint")
local v10 = import("skate_core/physics/solver/packed")
local v11 = import("skate_core/physics/solver/packing")
local t1 = {}

function t1.compile_contact(p3, p4) -- line: 44
    -- upvalues: v8 (copy)
    v8.build(p3, p4)
end

function t1.solve_joint_record(p5, p6, p7) -- line: 49
    -- upvalues: v9 (copy)
    v9.solve(p5, p6, p7)
end

t1.JointConstraint = {}

local to_bits, from_bits = rt.to_bits, rt.from_bits

buffer.writef32(v1, 0, 0)

local v12 = buffer.readu32(v1, 0)
local t2 = {
    linear_displacement = true,
    position_displacement = true,
    angular_displacement = true,
    orientation_displacement = true
}
local t3 = {}
local t4 = {}
local t5 = {}
local t6 = {}
local t7 = {}
local t8 = {}
local t9 = {}
local ZERO = import("skate_core/math").Vector3.ZERO
local n1 = 0

local function solve_constraints_r4(p8, p9, p10, p11, p12) -- line: 126
    -- upvalues: v10 (copy), v11 (copy), to_bits (copy), from_bits (copy), v12 (copy), t2 (copy), t3 (copy), t4 (copy), t5 (copy), t6 (copy), t7 (copy), t8 (copy), t9 (copy), ZERO (copy), n1 (ref)
    table.clear(t3)
    table.clear(t4)
    table.clear(t5)
    table.clear(t6)
    n1 += 1

    local v13 = n1

    for v14, v15 in ipairs(p8) do
        if v14 <= 256 then
            local v16 = t7[v14]

            if v16 == nil then
                v16 = {
                    words = false,
                    reaction_a = 0,
                    reaction_b = 0
                }
                t7[v14] = v16
            end

            t3[v14] = v11.contact_into(v16, v15)
        else
            t3[v14] = v11.contact(v15)
        end
    end

    for v17, v18 in ipairs(p9) do
        t4[v17] = v11.joint(v18, v13)
    end

    for v19, v20 in ipairs(p10) do
        t5[v19] = v11.drive(v20)
    end

    for v21, v22 in ipairs(p11) do
        local linear_displacement, position_displacement, angular_displacement, orientation_displacement = v22.linear_displacement, v22.position_displacement, v22.angular_displacement, v22.orientation_displacement
        local v23

        if v21 <= 256 then
            v23 = t8[v21]

            if v23 == nil then
                v23 = table.create(16, 0)
                t8[v21] = v23
            end
        else
            v23 = table.create(16, 0)
        end

        local v24 = to_bits(linear_displacement.x)
        local v25 = to_bits(linear_displacement.y)
        local v26 = to_bits(linear_displacement.z)

        v23[1] = v24
        v23[2] = v25
        v23[3] = v26
        v23[4] = v12

        local v27 = to_bits(position_displacement.x)
        local v28 = to_bits(position_displacement.y)
        local v29 = to_bits(position_displacement.z)

        v23[5] = v27
        v23[6] = v28
        v23[7] = v29
        v23[8] = v12

        local v30 = to_bits(angular_displacement.x)
        local v31 = to_bits(angular_displacement.y)
        local v32 = to_bits(angular_displacement.z)

        v23[9] = v30
        v23[10] = v31
        v23[11] = v32
        v23[12] = v12

        local v33 = to_bits(orientation_displacement.x)
        local v34 = to_bits(orientation_displacement.y)
        local v35 = to_bits(orientation_displacement.z)

        v23[13] = v33
        v23[14] = v34
        v23[15] = v35
        v23[16] = v12
        t6[v21] = v23
    end

    v10.solve_xyz(t3, t4, t5, t6, p12)

    for v36, v37 in ipairs(p8) do
        local v38 = t3[v36]

        v37.words = v38.words

        if v36 <= 256 then
            v38.words = false
        end
    end

    for v39, v40 in ipairs(p9) do
        local v41 = t4[v39]

        v40.jacobian.words = v41.words
    end

    table.clear(t9)

    for v42, v43 in ipairs(p10) do
        local words = t5[v42].words
        local accumulated_linear_impulse, accumulated_angular_impulse = v43.accumulated_linear_impulse, v43.accumulated_angular_impulse

        if type(accumulated_linear_impulse) ~= "table" or type(accumulated_angular_impulse) ~= "table" or accumulated_linear_impulse == accumulated_angular_impulse then
            v43.accumulated_linear_impulse = {
                from_bits(words[9]),
                from_bits(words[10]),
                from_bits(words[11])
            }
            v43.accumulated_angular_impulse = {
                from_bits(words[13]),
                from_bits(words[14]),
                from_bits(words[15])
            }
        elseif #accumulated_linear_impulse ~= 3 or #accumulated_angular_impulse ~= 3 or t9[accumulated_linear_impulse] or t9[accumulated_angular_impulse] then
            v43.accumulated_linear_impulse = {
                from_bits(words[9]),
                from_bits(words[10]),
                from_bits(words[11])
            }
            v43.accumulated_angular_impulse = {
                from_bits(words[13]),
                from_bits(words[14]),
                from_bits(words[15])
            }
        else
            t9[accumulated_linear_impulse] = true
            t9[accumulated_angular_impulse] = true

            local v44 = from_bits(words[9])
            local v45 = from_bits(words[10])
            local v46 = from_bits(words[11])

            accumulated_linear_impulse[1] = v44
            accumulated_linear_impulse[2] = v45
            accumulated_linear_impulse[3] = v46

            local v47 = from_bits(words[13])
            local v48 = from_bits(words[14])
            local v49 = from_bits(words[15])

            accumulated_angular_impulse[1] = v47
            accumulated_angular_impulse[2] = v48
            accumulated_angular_impulse[3] = v49
        end
    end

    for v50, v51 in ipairs(p11) do
        local v52 = t6[v50]

        for v53 in v51 do
            if not t2[v53] then
                v51[v53] = nil
            end
        end

        local linear_displacement, position_displacement, angular_displacement, orientation_displacement = v51.linear_displacement, v51.position_displacement, v51.angular_displacement, v51.orientation_displacement

        if type(linear_displacement) ~= "table"
            or type(position_displacement) ~= "table"
            or type(angular_displacement) ~= "table"
            or type(orientation_displacement) ~= "table"
            or linear_displacement == position_displacement
            or linear_displacement == angular_displacement
            or linear_displacement == orientation_displacement
            or position_displacement == angular_displacement
            or position_displacement == orientation_displacement
            or angular_displacement == orientation_displacement
            or linear_displacement == ZERO
            or position_displacement == ZERO
            or angular_displacement == ZERO
            or orientation_displacement == ZERO
            or t9[linear_displacement]
            or t9[position_displacement]
            or t9[angular_displacement]
            or t9[orientation_displacement] then
            v51.linear_displacement = {
                x = from_bits(v52[1]),
                y = from_bits(v52[2]),
                z = from_bits(v52[3])
            }
            v51.position_displacement = {
                x = from_bits(v52[5]),
                y = from_bits(v52[6]),
                z = from_bits(v52[7])
            }
            v51.angular_displacement = {
                x = from_bits(v52[9]),
                y = from_bits(v52[10]),
                z = from_bits(v52[11])
            }
            v51.orientation_displacement = {
                x = from_bits(v52[13]),
                y = from_bits(v52[14]),
                z = from_bits(v52[15])
            }
        else
            t9[linear_displacement] = true
            t9[position_displacement] = true
            t9[angular_displacement] = true
            t9[orientation_displacement] = true

            local v54 = from_bits(v52[1])
            local v55 = from_bits(v52[2])
            local v56 = from_bits(v52[3])

            linear_displacement.x = v54
            linear_displacement.y = v55
            linear_displacement.z = v56

            local v57 = from_bits(v52[5])
            local v58 = from_bits(v52[6])
            local v59 = from_bits(v52[7])

            position_displacement.x = v57
            position_displacement.y = v58
            position_displacement.z = v59

            local v60 = from_bits(v52[9])
            local v61 = from_bits(v52[10])
            local v62 = from_bits(v52[11])

            angular_displacement.x = v60
            angular_displacement.y = v61
            angular_displacement.z = v62

            local v63 = from_bits(v52[13])
            local v64 = from_bits(v52[14])
            local v65 = from_bits(v52[15])

            orientation_displacement.x = v63
            orientation_displacement.y = v64
            orientation_displacement.z = v65
        end
    end

    table.clear(t9)
    table.clear(t3)
    table.clear(t4)
    table.clear(t5)
    table.clear(t6)
end

t1.solve_constraints_r4 = solve_constraints_r4

local v66 = true

function t1.set_w3(p13) -- line: 307
    -- upvalues: v66 (ref)
    local v67 = v66

    v66 = p13

    return v67
end

local passes, v68, v69

function t1.set_mode(p14) -- line: 324
    -- upvalues: import (copy), passes (ref), v68 (ref), v69 (ref)
    local v70 = v68
    local v71 = false

    if type(p14) == "table" and (p14.rider_passes or p14.vector_kernels) then
        if v69 == nil then
            v69 = import("skate_core/physics/solver/lite")
        end

        v71 = v69.configure(p14)
    end

    if v71 then
        v68 = table.clone(p14)
        passes = v69.passes
    else
        v68 = nil
        passes = nil
    end

    return v70
end

function t1.mode() -- line: 343
    -- upvalues: v68 (ref)
    return v68
end

local drive_rows, reaction_rows = v10.drive_rows, v10.reaction_rows
local t18 = {}
local t19 = {}
local t20 = {}
local t21 = {}
local t22 = {}
local t23 = {}
local t24 = {}
local t25 = {}
local t26 = {}
local create = vector.create
local v72 = buffer.create(8)

local function tiny(p15) -- line: 360
    -- upvalues: to_bits (copy), v72 (copy)
    buffer.writeu32(v72, 0, to_bits(p15))

    return (buffer.readf32(v72, 0))
end

function t1.solve_constraints(p16, p17, p18, p19, p20, p21, p22) -- line: 365
    -- upvalues: v10 (copy), v11 (copy), to_bits (copy), t2 (copy), t9 (copy), ZERO (copy), n1 (ref), solve_constraints_r4 (copy), v66 (ref), passes (ref), drive_rows (copy), reaction_rows (copy), t18 (copy), t19 (copy), t20 (copy), t21 (copy), t22 (copy), t23 (copy), t24 (copy), t25 (copy), t26 (copy), create (copy), v72 (copy)
    if not v66 then
        return solve_constraints_r4(p16, p17, p18, p19, p20)
    end

    table.clear(t18)
    table.clear(t21)
    table.clear(t22)
    n1 += 1

    local v73 = n1
    local v74 = p21 == true
    local n2 = 0

    for v75, v76 in ipairs(p16) do
        n2 = v75

        local words = v76.words

        if not v74 then
            words = table.clone(words)
        end

        t18[v75] = words
        t19[v75] = v76.reaction_index_a
        t20[v75] = v76.reaction_index_b
    end

    local n3 = 0
    local linear_displacement, position_displacement

    for v77, v78 in ipairs(p17) do
        n3 = v77
        linear_displacement, position_displacement = v11.joint(v78, v73)
        t21[v77] = linear_displacement.words
        t22[v77] = position_displacement or false
        t23[v77] = linear_displacement.reaction_a
        t24[v77] = linear_displacement.reaction_b
    end

    v73 = if v10.lanes_first() then v11.drive_into_b3 else v11.drive_into

    local n4 = 0
    local angular_displacement

    for v79, v80 in ipairs(p18) do
        n4 = v79
        linear_displacement = drive_rows[v79]

        if linear_displacement == nil then
            linear_displacement = table.create(106, 0)
            drive_rows[v79] = linear_displacement
        end

        position_displacement, angular_displacement = v73(linear_displacement, v80)
        t25[v79] = position_displacement
        t26[v79] = angular_displacement
    end

    local n5 = 0
    local orientation_displacement, x, y, z, x2

    for v81, v82 in ipairs(p19) do
        n5 = v81
        v73 = reaction_rows[v81]

        if v73 == nil then
            v73 = table.create(16, 0)
            reaction_rows[v81] = v73
        end

        linear_displacement = v82.linear_displacement
        position_displacement = v82.position_displacement
        angular_displacement = v82.angular_displacement
        orientation_displacement = v82.orientation_displacement
        x = linear_displacement.x
        y = linear_displacement.y
        z = linear_displacement.z

        local x3, y2

        if x == 0 and y == 0 and z == 0 then
            v73[1] = x
            v73[2] = y
            v73[3] = z
        else
            x2 = create(x, y, z)
            x3 = x2.x
            y2 = x2.y

            local z2 = x2.z

            if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
                buffer.writeu32(v72, 0, to_bits(x))
                x3 = buffer.readf32(v72, 0)
            end

            if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
                buffer.writeu32(v72, 0, to_bits(y))
                y2 = buffer.readf32(v72, 0)
            end

            if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
                buffer.writeu32(v72, 0, to_bits(z))
                z2 = buffer.readf32(v72, 0)
            end

            v73[1] = x3
            v73[2] = y2
            v73[3] = z2
        end

        x = position_displacement.x
        y = position_displacement.y
        z = position_displacement.z

        local v83

        if x == 0 and y == 0 and z == 0 then
            v73[5] = x
            v73[6] = y
            v73[7] = z
        else
            v83 = create(x, y, z)
            x2 = v83.x
            x3 = v83.y
            y2 = v83.z

            if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
                buffer.writeu32(v72, 0, to_bits(x))
                x2 = buffer.readf32(v72, 0)
            end

            if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
                buffer.writeu32(v72, 0, to_bits(y))
                x3 = buffer.readf32(v72, 0)
            end

            if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
                buffer.writeu32(v72, 0, to_bits(z))
                y2 = buffer.readf32(v72, 0)
            end

            v73[5] = x2
            v73[6] = x3
            v73[7] = y2
        end

        x = angular_displacement.x
        y = angular_displacement.y
        z = angular_displacement.z

        if x == 0 and y == 0 and z == 0 then
            v73[9] = x
            v73[10] = y
            v73[11] = z
        else
            v83 = create(x, y, z)
            x2 = v83.x
            x3 = v83.y
            y2 = v83.z

            if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
                buffer.writeu32(v72, 0, to_bits(x))
                x2 = buffer.readf32(v72, 0)
            end

            if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
                buffer.writeu32(v72, 0, to_bits(y))
                x3 = buffer.readf32(v72, 0)
            end

            if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
                buffer.writeu32(v72, 0, to_bits(z))
                y2 = buffer.readf32(v72, 0)
            end

            v73[9] = x2
            v73[10] = x3
            v73[11] = y2
        end

        x = orientation_displacement.x
        y = orientation_displacement.y
        z = orientation_displacement.z

        if x == 0 and y == 0 and z == 0 then
            v73[13] = x
            v73[14] = y
            v73[15] = z
        else
            v83 = create(x, y, z)
            x2 = v83.x
            x3 = v83.y
            y2 = v83.z

            if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
                buffer.writeu32(v72, 0, to_bits(x))
                x2 = buffer.readf32(v72, 0)
            end

            if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
                buffer.writeu32(v72, 0, to_bits(y))
                x3 = buffer.readf32(v72, 0)
            end

            if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
                buffer.writeu32(v72, 0, to_bits(z))
                y2 = buffer.readf32(v72, 0)
            end

            v73[13] = x2
            v73[14] = x3
            v73[15] = y2
        end

        v73[4] = 0
        v73[8] = 0
        v73[12] = 0
        v73[16] = 0
    end

    local v84 = if p22 == nil then 0 else math.min(p22, n2)

    if passes == nil or not v74 then
        v10.solve_rows(n2, v84, t18, t19, t20, n3, t21, t23, t24, n4, t25, t26, n5, p20, nil, t22)
    else
        v10.solve_rows(n2, v84, t18, t19, t20, n3, t21, t23, t24, n4, t25, t26, n5, p20, passes, t22)
    end

    if not v74 then
        for v85, v86 in ipairs(p16) do
            v86.words = t18[v85]
        end
    end

    for v87, v88 in ipairs(p17) do
        v88.jacobian.words = t21[v87]
    end

    table.clear(t9)

    for v89, v90 in ipairs(p18) do
        v74 = drive_rows[v89]
        position_displacement = v90.accumulated_linear_impulse
        angular_displacement = v90.accumulated_angular_impulse

        if type(position_displacement) ~= "table" or type(angular_displacement) ~= "table" or position_displacement == angular_displacement then
            v90.accumulated_linear_impulse = {
                v74[9],
                v74[10],
                v74[11]
            }
            v90.accumulated_angular_impulse = {
                v74[13],
                v74[14],
                v74[15]
            }
        elseif #position_displacement ~= 3 or #angular_displacement ~= 3 or t9[position_displacement] or t9[angular_displacement] then
            v90.accumulated_linear_impulse = {
                v74[9],
                v74[10],
                v74[11]
            }
            v90.accumulated_angular_impulse = {
                v74[13],
                v74[14],
                v74[15]
            }
        else
            t9[position_displacement] = true
            t9[angular_displacement] = true
            orientation_displacement = v74[9]
            x = v74[10]
            y = v74[11]
            position_displacement[1] = orientation_displacement
            position_displacement[2] = x
            position_displacement[3] = y
            orientation_displacement = v74[13]
            x = v74[14]
            y = v74[15]
            angular_displacement[1] = orientation_displacement
            angular_displacement[2] = x
            angular_displacement[3] = y
        end
    end

    for v91, v92 in ipairs(p19) do
        n5 = reaction_rows[v91]

        for v93 in v92 do
            if not t2[v93] then
                v92[v93] = nil
            end
        end

        position_displacement = v92.linear_displacement
        angular_displacement = v92.position_displacement
        orientation_displacement = v92.angular_displacement
        x = v92.orientation_displacement

        if type(position_displacement) ~= "table"
            or type(angular_displacement) ~= "table"
            or type(orientation_displacement) ~= "table"
            or type(x) ~= "table"
            or position_displacement == angular_displacement
            or position_displacement == orientation_displacement
            or position_displacement == x
            or angular_displacement == orientation_displacement
            or angular_displacement == x
            or orientation_displacement == x
            or position_displacement == ZERO
            or angular_displacement == ZERO
            or orientation_displacement == ZERO
            or x == ZERO
            or t9[position_displacement]
            or t9[angular_displacement]
            or t9[orientation_displacement]
            or t9[x] then
            y = {}
            y.x = n5[1]
            y.y = n5[2]
            y.z = n5[3]
            v92.linear_displacement = y
            y = {}
            y.x = n5[5]
            y.y = n5[6]
            y.z = n5[7]
            v92.position_displacement = y
            y = {}
            y.x = n5[9]
            y.y = n5[10]
            y.z = n5[11]
            v92.angular_displacement = y
            y = {}
            y.x = n5[13]
            y.y = n5[14]
            y.z = n5[15]
            v92.orientation_displacement = y
        else
            t9[position_displacement] = true
            t9[angular_displacement] = true
            t9[orientation_displacement] = true
            t9[x] = true
            y = n5[1]
            z = n5[2]
            x2 = n5[3]
            position_displacement.x = y
            position_displacement.y = z
            position_displacement.z = x2
            y = n5[5]
            z = n5[6]
            x2 = n5[7]
            angular_displacement.x = y
            angular_displacement.y = z
            angular_displacement.z = x2
            y = n5[9]
            z = n5[10]
            x2 = n5[11]
            orientation_displacement.x = y
            orientation_displacement.y = z
            orientation_displacement.z = x2
            y = n5[13]
            z = n5[14]
            x2 = n5[15]
            x.x = y
            x.y = z
            x.z = x2
        end
    end

    table.clear(t9)
    table.clear(t18)
    table.clear(t21)
    table.clear(t22)
end

function t1.solve_constraints_reference(p23, p24, p25, p26, p27) -- line: 610
    -- upvalues: rt (copy), v10 (copy), v11 (copy)
    local t27 = {}

    for v94, v95 in ipairs(p23) do
        t27[v94] = v11.contact(v95)
    end

    local t28 = {}

    for v96, v97 in ipairs(p24) do
        t28[v96] = {
            words = table.clone(v97.jacobian.words),
            reaction_a = v97.reaction_a,
            reaction_b = v97.reaction_b
        }
    end

    local t29 = {}

    for v98, v99 in ipairs(p25) do
        t29[v98] = v11.drive(v99)
    end

    local t30 = {}

    for v100, v101 in ipairs(p26) do
        t30[v100] = v11.reaction(v101)
    end

    v10.solve(t27, t28, t29, t30, p27)

    for v102, v103 in ipairs(p23) do
        v103.words = t27[v102].words
    end

    for v104, v105 in ipairs(p24) do
        local v106 = t28[v104]

        v105.jacobian.words = v106.words
    end

    for v107, v108 in ipairs(p25) do
        local v109 = t29[v107]

        v108.accumulated_linear_impulse = v11.read_xyz(v109.words, 2)
        v108.accumulated_angular_impulse = v11.read_xyz(v109.words, 3)
    end

    for v110, v111 in ipairs(p26) do
        local v112 = t30[v110]

        rt.assign(v111, v11.unpack_reaction(v112))
    end
end

return t1
