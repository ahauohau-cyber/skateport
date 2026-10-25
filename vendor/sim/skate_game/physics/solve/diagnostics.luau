-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local SkeletonBody = import("skate_core/physics/skeleton_body").SkeletonBody
local is_finite = rt.is_finite
local t1 = {}

local function debug_fmt(p2) -- line: 23
    -- upvalues: debug_fmt (copy)
    if type(p2) ~= "table" then
        return (tostring(p2))
    end

    local t2 = {}

    if #p2 > 0 then
        for _, v1 in ipairs(p2) do
            table.insert(t2, debug_fmt(v1))
        end

        return "[" .. table.concat(t2, ", ") .. "]"
    end

    local t3 = {}

    for v2 in p2 do
        table.insert(t3, (tostring(v2)))
    end

    table.sort(t3)

    for _, v4 in ipairs(t3) do
        local v5 = p2[v4]

        if v5 == nil then
            v5 = p2[tonumber(v4)]
        end

        table.insert(t2, v4 .. ": " .. debug_fmt(v5))
    end

    return "{ " .. table.concat(t2, ", ") .. " }"
end

function t1.snapshot(p3, p4) -- line: 50
    -- upvalues: rt (copy), BoardRuntime (copy), SkeletonBody (copy)
    local t4 = {}

    for _, v7 in ipairs(BoardRuntime.bodies(p3.board)) do
        table.insert(t4, rt.copy(v7))
    end

    table.insert(t4, rt.copy(BoardRuntime.hook(p3.board).body))

    for _, v8 in ipairs(SkeletonBody.bodies(p4.skeleton)) do
        table.insert(t4, rt.copy(v8))
    end

    for _, v9 in ipairs(p4.skeleton_drives.targets.bodies) do
        table.insert(t4, rt.copy(v9))
    end

    return t4
end

local t5 = {
    orientation = 3,
    basis = 4,
    world_inverse_inertia = 4,
    position = 2,
    linear_velocity = 2,
    angular_velocity = 2,
    force_acceleration = 2,
    torque_acceleration = 2,
    kinetic_energy = 1,
    cool_down = 1
}
local t6 = {
    inverse_tensor = 2,
    inverse_mass = 1,
    spherical = 1,
    maximum_linear_velocity = 1,
    maximum_angular_velocity = 1,
    linear_drag = 1,
    angular_drag = 1
}

local function fill_vector(p5, p6) -- line: 107
    if type(p6) ~= "table" then
        return false
    end

    local n1 = 0

    for v10, v11 in p6 do
        if v10 ~= "x" and v10 ~= "y" and v10 ~= "z" or type(v11) == "table" then
            return false
        end

        p5[v10] = v11
        n1 += 1
    end

    return n1 == 3
end

local function fill_quaternion(p7, p8) -- line: 123
    if type(p8) ~= "table" then
        return false
    end

    local n2 = 0

    for v12, v13 in p8 do
        if v12 ~= "x" and v12 ~= "y" and v12 ~= "z" and v12 ~= "w" or type(v13) == "table" then
            return false
        end

        p7[v12] = v13
        n2 += 1
    end

    return n2 == 4
end

local function fill_column(p9, p10) -- line: 139
    if type(p10) ~= "table" then
        return false
    end

    local n3 = 0

    for v14, v15 in p10 do
        if v14 ~= 1 and v14 ~= 2 and v14 ~= 3 or type(v15) == "table" then
            return false
        end

        p9[v14] = v15
        n3 += 1
    end

    return n3 == 3
end

local function fill_basis(p11, p12) -- line: 155
    -- upvalues: fill_column (copy)
    if type(p12) ~= "table" then
        return false
    end

    local n4 = 0

    for v16, v17 in p12 do
        if v16 ~= "columns" or type(v17) ~= "table" then
            return false
        end

        n4 += 1

        local columns = p11.columns
        local n5 = 0

        for v18, v19 in v17 do
            if v18 ~= 1 and v18 ~= 2 and v18 ~= 3 or not fill_column(columns[v18], v19) then
                return false
            end

            n5 += 1
        end

        if n5 ~= 3 then
            return false
        end
    end

    return n4 == 1
end

local function fill_struct(p13, p14, p15, p16) -- line: 183
    -- upvalues: fill_vector (copy), fill_quaternion (copy), fill_basis (copy)
    if type(p14) ~= "table" then
        return false
    end

    local n6 = 0

    for v20, v21 in p14 do
        local v22 = p15[v20]

        if v22 == 1 then
            if type(v21) == "table" then
                return false
            end

            p13[v20] = v21
        elseif v22 == 2 then
            if not fill_vector(p13[v20], v21) then
                return false
            end
        elseif v22 == 3 then
            if not fill_quaternion(p13[v20], v21) then
                return false
            end
        elseif v22 ~= 4 or not fill_basis(p13[v20], v21) then
            return false
        end

        n6 += 1
    end

    return n6 == p16
end

local function fill_body(p17, p18) -- line: 215
    -- upvalues: t5 (copy), t6 (copy), fill_struct (copy)
    if type(p18) ~= "table" then
        return false
    end

    local n7 = 0

    for v23, v24 in p18 do
        if v23 == "state_flags" then
            if type(v24) == "table" then
                return false
            end

            p17.state_flags = v24
        elseif v23 == "rates" then
            if not fill_struct(p17.rates, v24, t5, 10) then
                return false
            end
        elseif v23 ~= "inertia" or not fill_struct(p17.inertia, v24, t6, 7) then
            return false
        end

        n7 += 1
    end

    return n7 == 3
end

local function new_slot() -- line: 242
    return {
        rates = {
            orientation = {},
            basis = {
                columns = {
                    {},
                    {},
                    {}
                }
            },
            world_inverse_inertia = {
                columns = {
                    {},
                    {},
                    {}
                }
            },
            position = {},
            linear_velocity = {},
            angular_velocity = {},
            force_acceleration = {},
            torque_acceleration = {}
        },
        inertia = {
            inverse_tensor = {}
        }
    }
end

local t7 = {}

local function snapshot_body(p19, p20) -- line: 260
    -- upvalues: rt (copy), fill_body (copy), new_slot (copy), t7 (copy)
    local v25 = t7[p19]

    if v25 == nil then
        v25 = new_slot()
        t7[p19] = v25
    end

    if fill_body(v25, p20) then
        return v25
    end

    return rt.copy(p20)
end

function t1.snapshot_scratch(p21, p22) -- line: 272
    -- upvalues: BoardRuntime (copy), SkeletonBody (copy), snapshot_body (copy)
    local t8 = {}
    local n8 = 0

    for _, v26 in ipairs(BoardRuntime.bodies(p21.board)) do
        n8 += 1
        table.insert(t8, snapshot_body(n8, v26))
    end

    local v27 = n8 + 1

    table.insert(t8, snapshot_body(v27, BoardRuntime.hook(p21.board).body))

    for _, v28 in ipairs(SkeletonBody.bodies(p22.skeleton)) do
        v27 += 1
        table.insert(t8, snapshot_body(v27, v28))
    end

    for _, v29 in ipairs(p22.skeleton_drives.targets.bodies) do
        v27 += 1
        table.insert(t8, snapshot_body(v27, v29))
    end

    return t8
end

local t9 = {}
local n9 = 0

local function capture_body(p23, p24) -- line: 330
    local rates = p24.rates
    local orientation = rates.orientation
    local x, y, z, w = orientation.x, orientation.y, orientation.z, orientation.w
    local columns = rates.basis.columns
    local v30 = columns[1]
    local v31 = columns[2]
    local v32 = columns[3]

    if #columns ~= 3 or #v30 ~= 3 or #v31 ~= 3 or #v32 ~= 3 then
        return false
    end

    local v33 = v30[1]
    local v34 = v30[2]
    local v35 = v30[3]
    local v36 = v31[1]
    local v37 = v31[2]
    local v38 = v31[3]
    local v39 = v32[1]
    local v40 = v32[2]
    local v41 = v32[3]
    local columns2 = rates.world_inverse_inertia.columns
    local v42 = columns2[1]
    local v43 = columns2[2]
    local v44 = columns2[3]

    if #columns2 ~= 3 or #v42 ~= 3 or #v43 ~= 3 or #v44 ~= 3 then
        return false
    end

    local v45 = v42[1]
    local v46 = v42[2]
    local v47 = v42[3]
    local v48 = v43[1]
    local v49 = v43[2]
    local v50 = v43[3]
    local v51 = v44[1]
    local v52 = v44[2]
    local v53 = v44[3]
    local position = rates.position
    local x2, y2, z2 = position.x, position.y, position.z
    local linear_velocity = rates.linear_velocity
    local x3, y3, z3 = linear_velocity.x, linear_velocity.y, linear_velocity.z
    local angular_velocity = rates.angular_velocity
    local x4, y4, z4 = angular_velocity.x, angular_velocity.y, angular_velocity.z
    local force_acceleration = rates.force_acceleration
    local x5, y5, z5 = force_acceleration.x, force_acceleration.y, force_acceleration.z
    local torque_acceleration = rates.torque_acceleration
    local x6, y6, z6 = torque_acceleration.x, torque_acceleration.y, torque_acceleration.z
    local inertia = p24.inertia
    local inverse_tensor = inertia.inverse_tensor

    p23[1] = p24.state_flags
    p23[2] = x
    p23[3] = y
    p23[4] = z
    p23[5] = w
    p23[6] = v33
    p23[7] = v34
    p23[8] = v35
    p23[9] = v36
    p23[10] = v37
    p23[11] = v38
    p23[12] = v39
    p23[13] = v40
    p23[14] = v41
    p23[15] = v45
    p23[16] = v46
    p23[17] = v47
    p23[18] = v48
    p23[19] = v49
    p23[20] = v50
    p23[21] = v51
    p23[22] = v52
    p23[23] = v53
    p23[24] = x2
    p23[25] = y2
    p23[26] = z2
    p23[27] = x3
    p23[28] = y3
    p23[29] = z3
    p23[30] = x4
    p23[31] = y4
    p23[32] = z4
    p23[33] = x5
    p23[34] = y5
    p23[35] = z5
    p23[36] = x6
    p23[37] = y6
    p23[38] = z6
    p23[39] = rates.kinetic_energy
    p23[40] = rates.cool_down

    local x7, y7, z7 = inverse_tensor.x, inverse_tensor.y, inverse_tensor.z

    p23[41] = x7
    p23[42] = y7
    p23[43] = z7
    p23[44] = inertia.inverse_mass
    p23[45] = inertia.spherical
    p23[46] = inertia.maximum_linear_velocity
    p23[47] = inertia.maximum_angular_velocity
    p23[48] = inertia.linear_drag
    p23[49] = inertia.angular_drag

    local v54 = x2 + y2 + z2 + x3 + y3 + z3 + x4 + y4 + z4 + x5 + y5 + z5 + x6 + y6 + z6 + x + y + z + w + (v33 + v34 + v35 + v36 + v37 + v38 + v39 + v40 + v41) + (v45 + v46 + v47 + v48 + v49 + v50 + v51 + v52 + v53)

    return v54 - v54 == 0
end

local function capture_slot(p25) -- line: 390
    -- upvalues: t9 (copy)
    local v55 = t9[p25]

    if v55 == nil then
        v55 = table.create(49)
        t9[p25] = v55
    end

    return v55
end

local function capture_inner(p26, p27) -- line: 399
    -- upvalues: BoardRuntime (copy), SkeletonBody (copy), t9 (copy), n9 (ref), capture_body (copy)
    n9 = 0

    local n10 = 0

    for _, v56 in ipairs(BoardRuntime.bodies(p26.board)) do
        n10 += 1

        local v57 = t9[n10]

        if v57 == nil then
            v57 = table.create(49)
            t9[n10] = v57
        end

        if not capture_body(v57, v56) then
            return false
        end
    end

    local v58 = n10 + 1
    local v59 = t9[v58]

    if v59 == nil then
        v59 = table.create(49)
        t9[v58] = v59
    end

    if not capture_body(v59, BoardRuntime.hook(p26.board).body) then
        return false
    end

    for _, v60 in ipairs(SkeletonBody.bodies(p27.skeleton)) do
        v58 += 1

        local v61 = t9[v58]

        if v61 == nil then
            v61 = table.create(49)
            t9[v58] = v61
        end

        if not capture_body(v61, v60) then
            return false
        end
    end

    for _, v62 in ipairs(p27.skeleton_drives.targets.bodies) do
        v58 += 1

        local v63 = t9[v58]

        if v63 == nil then
            v63 = table.create(49)
            t9[v58] = v63
        end

        if not capture_body(v63, v62) then
            return false
        end
    end

    n9 = v58

    return true
end

function t1.capture(p28, p29) -- line: 430
    -- upvalues: n9 (ref), capture_inner (copy)
    local ok, result = pcall(capture_inner, p28, p29)

    if ok and result == true then
        return true
    end

    n9 = 0

    return false
end

function t1.captured_bodies() -- line: 443
    -- upvalues: t9 (copy), n9 (ref)
    local v64 = table.create(n9)

    for i = 1, n9 do
        local v66 = t9[i]

        v64[i] = {
            state_flags = v66[1],
            rates = {
                orientation = {
                    x = v66[2],
                    y = v66[3],
                    z = v66[4],
                    w = v66[5]
                },
                basis = {
                    columns = {
                        {
                            v66[6],
                            v66[7],
                            v66[8]
                        },
                        {
                            v66[9],
                            v66[10],
                            v66[11]
                        },
                        {
                            v66[12],
                            v66[13],
                            v66[14]
                        }
                    }
                },
                world_inverse_inertia = {
                    columns = {
                        {
                            v66[15],
                            v66[16],
                            v66[17]
                        },
                        {
                            v66[18],
                            v66[19],
                            v66[20]
                        },
                        {
                            v66[21],
                            v66[22],
                            v66[23]
                        }
                    }
                },
                position = {
                    x = v66[24],
                    y = v66[25],
                    z = v66[26]
                },
                linear_velocity = {
                    x = v66[27],
                    y = v66[28],
                    z = v66[29]
                },
                angular_velocity = {
                    x = v66[30],
                    y = v66[31],
                    z = v66[32]
                },
                force_acceleration = {
                    x = v66[33],
                    y = v66[34],
                    z = v66[35]
                },
                torque_acceleration = {
                    x = v66[36],
                    y = v66[37],
                    z = v66[38]
                },
                kinetic_energy = v66[39],
                cool_down = v66[40]
            },
            inertia = {
                inverse_tensor = {
                    x = v66[41],
                    y = v66[42],
                    z = v66[43]
                },
                inverse_mass = v66[44],
                spherical = v66[45],
                maximum_linear_velocity = v66[46],
                maximum_angular_velocity = v66[47],
                linear_drag = v66[48],
                angular_drag = v66[49]
            }
        }
    end

    return v64
end

local function finite_body(p30) -- line: 477
    local rates = p30.rates
    local orientation = rates.orientation
    local v67 = orientation.x + orientation.y + orientation.z + orientation.w
    local columns = rates.basis.columns
    local v68 = columns[1]
    local v69 = columns[2]
    local v70 = columns[3]

    if #columns ~= 3 or #v68 ~= 3 or #v69 ~= 3 or #v70 ~= 3 then
        return false
    end

    local v71 = v67 + (v68[1] + v68[2] + v68[3] + v69[1] + v69[2] + v69[3] + v70[1] + v70[2] + v70[3])
    local columns2 = rates.world_inverse_inertia.columns
    local v72 = columns2[1]
    local v73 = columns2[2]
    local v74 = columns2[3]

    if #columns2 ~= 3 or #v72 ~= 3 or #v73 ~= 3 or #v74 ~= 3 then
        return false
    end

    local v75 = v71 + (v72[1] + v72[2] + v72[3] + v73[1] + v73[2] + v73[3] + v74[1] + v74[2] + v74[3])
    local position = rates.position
    local v76 = v75 + (position.x + position.y + position.z)
    local linear_velocity = rates.linear_velocity
    local v77 = v76 + (linear_velocity.x + linear_velocity.y + linear_velocity.z)
    local angular_velocity = rates.angular_velocity
    local v78 = v77 + (angular_velocity.x + angular_velocity.y + angular_velocity.z)
    local force_acceleration = rates.force_acceleration
    local v79 = v78 + (force_acceleration.x + force_acceleration.y + force_acceleration.z)
    local torque_acceleration = rates.torque_acceleration
    local v80 = v79 + (torque_acceleration.x + torque_acceleration.y + torque_acceleration.z)

    return v80 - v80 == 0
end

local function live_finite_inner(p31, p32) -- line: 506
    -- upvalues: BoardRuntime (copy), SkeletonBody (copy), finite_body (copy)
    for _, v81 in ipairs(BoardRuntime.bodies(p31.board)) do
        if not finite_body(v81) then
            return false
        end
    end

    if not finite_body(BoardRuntime.hook(p31.board).body) then
        return false
    end

    for _, v82 in ipairs(SkeletonBody.bodies(p32.skeleton)) do
        if not finite_body(v82) then
            return false
        end
    end

    for _, v83 in ipairs(p32.skeleton_drives.targets.bodies) do
        if not finite_body(v83) then
            return false
        end
    end

    return true
end

function t1.live_finite(p33, p34) -- line: 530
    -- upvalues: live_finite_inner (copy)
    local ok, result = pcall(live_finite_inner, p33, p34)

    return ok and result == true
end

function t1.snapshot_refs(p35, p36) -- line: 540
    -- upvalues: BoardRuntime (copy), SkeletonBody (copy)
    local t10 = {}

    for _, v84 in ipairs(BoardRuntime.bodies(p35.board)) do
        table.insert(t10, v84)
    end

    table.insert(t10, BoardRuntime.hook(p35.board).body)

    for _, v85 in ipairs(SkeletonBody.bodies(p36.skeleton)) do
        table.insert(t10, v85)
    end

    for _, v86 in ipairs(p36.skeleton_drives.targets.bodies) do
        table.insert(t10, v86)
    end

    return t10
end

function t1.validate_reference(p37, p38) -- line: 557
    -- upvalues: debug_fmt (copy)
    for v87, v88 in ipairs(p37) do
        local v89 = v87 - 1
        local rates = v88.rates
        local t11 = {
            {
                "position",
                rates.position
            },
            {
                "linear_velocity",
                rates.linear_velocity
            },
            {
                "angular_velocity",
                rates.angular_velocity
            },
            {
                "force_acceleration",
                rates.force_acceleration
            },
            {
                "torque_acceleration",
                rates.torque_acceleration
            }
        }

        for _, v90 in ipairs(t11) do
            local v91 = v90[1]
            local v92 = v90[2]
            local x = v92.x

            if x == x and x ~= 1e999 and x ~= (-1e999) then
                local y = v92.y

                if y == y and y ~= 1e999 and y ~= (-1e999) then
                    local z = v92.z

                    if z ~= z or z == 1e999 or z == (-1e999) then
                        error(string.format("Non-finite %s %s; reaction_body=%d; body=%s", v91, p38, v89, (debug_fmt(v88))), 0)
                    end
                else
                    error(string.format("Non-finite %s %s; reaction_body=%d; body=%s", v91, p38, v89, (debug_fmt(v88))), 0)
                end
            else
                error(string.format("Non-finite %s %s; reaction_body=%d; body=%s", v91, p38, v89, (debug_fmt(v88))), 0)
            end
        end

        local orientation = rates.orientation
        local x = orientation.x
        local v93 = x == x and x ~= 1e999 and x ~= (-1e999)

        if v93 then
            local y = orientation.y

            v93 = y == y and y ~= 1e999 and y ~= (-1e999)

            if v93 then
                local z = orientation.z

                v93 = z == z and z ~= 1e999 and z ~= (-1e999)

                if v93 then
                    local w = orientation.w

                    v93 = w == w and w ~= 1e999 and w ~= (-1e999)
                end
            end
        end

        if v93 then
            local v94 = v93

            for _, v95 in ipairs(rates.basis.columns) do
                for _, v96 in ipairs(v95) do
                    if v96 ~= v96 or v96 == 1e999 or v96 == (-1e999) then
                        v94 = false
                        break
                    end
                end

                if not v94 then
                    v93 = v94
                    break
                end

                v93 = v94
            end
        end

        if v93 then
            local v97 = v93

            for _, v98 in ipairs(rates.world_inverse_inertia.columns) do
                for _, v99 in ipairs(v98) do
                    if v99 ~= v99 or v99 == 1e999 or v99 == (-1e999) then
                        v97 = false
                        break
                    end
                end

                if not v97 then
                    v93 = v97
                    break
                end

                v93 = v97
            end
        end

        if not v93 then
            error(string.format("Non-finite orientation/inertia %s; reaction_body=%d; body=%s", p38, v89, (debug_fmt(v88))), 0)
        end
    end
end

local function non_finite_vector(p39, p40, p41, p42) -- line: 625
    -- upvalues: debug_fmt (copy)
    error(string.format("Non-finite %s %s; reaction_body=%d; body=%s", p39, p40, p41, (debug_fmt(p42))), 0)
end

function t1.validate(p43, p44) -- line: 633
    -- upvalues: is_finite (copy), debug_fmt (copy)
    for v100, v101 in ipairs(p43) do
        local v102 = v100 - 1
        local rates = v101.rates
        local position = rates.position

        if not is_finite(position.x) or not is_finite(position.y) or not is_finite(position.z) then
            error(string.format("Non-finite %s %s; reaction_body=%d; body=%s", "position", p44, v102, (debug_fmt(v101))), 0)
        end

        local linear_velocity = rates.linear_velocity

        if not is_finite(linear_velocity.x) or not is_finite(linear_velocity.y) or not is_finite(linear_velocity.z) then
            error(string.format("Non-finite %s %s; reaction_body=%d; body=%s", "linear_velocity", p44, v102, (debug_fmt(v101))), 0)
        end

        local angular_velocity = rates.angular_velocity

        if not is_finite(angular_velocity.x) or not is_finite(angular_velocity.y) or not is_finite(angular_velocity.z) then
            error(string.format("Non-finite %s %s; reaction_body=%d; body=%s", "angular_velocity", p44, v102, (debug_fmt(v101))), 0)
        end

        local force_acceleration = rates.force_acceleration

        if not is_finite(force_acceleration.x) or not is_finite(force_acceleration.y) or not is_finite(force_acceleration.z) then
            error(string.format("Non-finite %s %s; reaction_body=%d; body=%s", "force_acceleration", p44, v102, (debug_fmt(v101))), 0)
        end

        local torque_acceleration = rates.torque_acceleration

        if not is_finite(torque_acceleration.x) or not is_finite(torque_acceleration.y) or not is_finite(torque_acceleration.z) then
            error(string.format("Non-finite %s %s; reaction_body=%d; body=%s", "torque_acceleration", p44, v102, (debug_fmt(v101))), 0)
        end

        local orientation = rates.orientation
        local v103 = is_finite(orientation.x) and is_finite(orientation.y) and is_finite(orientation.z) and is_finite(orientation.w)

        if v103 then
            local v104 = v103

            for _, v105 in ipairs(rates.basis.columns) do
                for _, v106 in ipairs(v105) do
                    if not is_finite(v106) then
                        v104 = false
                        break
                    end
                end

                if not v104 then
                    v103 = v104
                    break
                end

                v103 = v104
            end
        end

        if v103 then
            local v107 = v103

            for _, v108 in ipairs(rates.world_inverse_inertia.columns) do
                for _, v109 in ipairs(v108) do
                    if not is_finite(v109) then
                        v107 = false
                        break
                    end
                end

                if not v107 then
                    v103 = v107
                    break
                end

                v103 = v107
            end
        end

        if not v103 then
            error(string.format("Non-finite orientation/inertia %s; reaction_body=%d; body=%s", p44, v102, (debug_fmt(v101))), 0)
        end
    end
end

return t1
