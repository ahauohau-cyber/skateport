-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local RetailContactJacobian = import("skate_core/physics/contact_solver").RetailContactJacobian

local function board_step() -- line: 18
    -- upvalues: import (copy)
    return import("skate_core/physics/board_step")
end

local from_bits = rt.from_bits
local t1 = {
    BoardContactReport = {}
}

local function center_xyz(p2, p3, p4, p5) -- line: 56
    -- upvalues: BodyId (copy)
    if p2 == 1 then
        local position = p4[BodyId.index(p3) + 1].rates.position

        return position.x, position.y, position.z
    end

    if p2 == 0 then
        return 0, 0, 0
    end

    local v2 = p5[p3 + 1]

    if v2 == nil then
        return 0, 0, 0
    end

    local position = v2.rates.position

    return position.x, position.y, position.z
end

local function velocity_xyz(p6, p7, p8, p9) -- line: 72
    -- upvalues: BodyId (copy)
    if p6 == 1 then
        local linear_velocity = p8[BodyId.index(p7) + 1].rates.linear_velocity

        return linear_velocity.x, linear_velocity.y, linear_velocity.z
    end

    if p6 == 0 then
        return 0, 0, 0
    end

    local v3 = p9[p7 + 1]

    if v3 == nil then
        return 0, 0, 0
    end

    local linear_velocity = v3.rates.linear_velocity

    return linear_velocity.x, linear_velocity.y, linear_velocity.z
end

function t1.collect(p10, p11, p12, p13, p14) -- line: 105
    -- upvalues: import (copy), Vector3 (copy), BodyId (copy), RetailContactJacobian (copy), from_bits (copy)
    local decode_contact_id = import("skate_core/physics/board_step").CollisionBody.decode_contact_id

    table.clear(p10)

    local v4 = p14 * p14
    local n1 = 0

    for _, v5 in p11 do
        local v6 = RetailContactJacobian.words(v5)
        local v7 = from_bits(v6[21])
        local v8 = v6[12]

        if bit32.band(v8, 8) ~= 0 and v7 > 0 then
            local v9 = from_bits(v6[22])

            v8 = from_bits(v6[23])

            local v10, v11 = decode_contact_id(v6[32])
            local v12, v13 = decode_contact_id(v6[44])

            if v10 == 1 and v12 == 0 then
                local v14 = v11
                local v15 = v12
                local v16 = v13
                local v17 = true

                if n1 == 16 then
                    break
                end

                local v18 = from_bits(v6[29])
                local v19 = from_bits(v6[30])
                local v20 = from_bits(v6[31])
                local v21 = from_bits(v6[41])
                local v22 = from_bits(v6[42])
                local v23 = from_bits(v6[43])
                local v24 = from_bits(v6[53])
                local v25 = from_bits(v6[54])
                local v26 = from_bits(v6[55])
                local x, y, z, v27, v28

                if v10 == 1 then
                    v27 = p12[BodyId.index(v11) + 1].rates.position
                    x = v27.x
                    y = v27.y
                    z = v27.z
                elseif v10 == 0 then
                    x = 0
                    y = 0
                    z = 0
                else
                    v27 = p13[v11 + 1]

                    if v27 ~= nil then
                        v28 = v27.rates.position
                        x = v28.x
                        y = v28.y
                        z = v28.z
                    else
                        x = 0
                        y = 0
                        z = 0
                    end
                end

                v27 = x + from_bits(v6[1])
                v28 = y + from_bits(v6[2])

                local v29 = z + from_bits(v6[3])
                local v30, v31, v32

                if v12 == 1 then
                    z = p12[BodyId.index(v13) + 1].rates.position
                    v30 = z.x
                    v32 = z.y
                    v31 = z.z
                elseif v12 == 0 then
                    v30 = 0
                    v32 = 0
                    v31 = 0
                else
                    y = p13[v13 + 1]

                    if y ~= nil then
                        x = y.rates.position
                        v30 = x.x
                        v32 = x.y
                        v31 = x.z
                    else
                        v30 = 0
                        v32 = 0
                        v31 = 0
                    end
                end

                local v33 = v30 + from_bits(v6[5])
                local v34 = v32 + from_bits(v6[6])
                local v35 = v31 + from_bits(v6[7])
                local v36 = from_bits(v6[36])
                local v37 = from_bits(v6[40])

                v30 = 1 / (v37 + v36)
                v13 = v27 * v36 + v33 * v37
                v33 = v28 * v36 + v34 * v37
                v34 = v29 * v36 + v35 * v37
                v35 = v21 * v9 + v24 * v8
                v31 = v22 * v9 + v25 * v8
                v32 = v23 * v9 + v26 * v8
                v29 = 1

                local v38 = bit32.band(v6[56], 65535)

                v28 = p12[BodyId.index(v11) + 1].rates.linear_velocity

                local x2 = v28.x
                local y2 = v28.y
                local z2 = v28.z
                local x3, y3, z3

                if v12 == 1 then
                    v27 = p12[BodyId.index(v16) + 1].rates.linear_velocity
                    x3 = v27.x
                    y3 = v27.y
                    z3 = v27.z
                elseif v12 == 0 then
                    x3 = 0
                    y3 = 0
                    z3 = 0
                else
                    v12 = p13[v16 + 1]

                    if v12 ~= nil then
                        v11 = v12.rates.linear_velocity
                        x3 = v11.x
                        y3 = v11.y
                        z3 = v11.z
                    else
                        x3 = 0
                        y3 = 0
                        z3 = 0
                    end
                end

                n1 += 1
                p10[n1] = {
                    part = v14,
                    other = if v15 == 0 then {
                        tag = "StaticWorld"
                    } else {
                        tag = "Attached",
                        v16
                    },
                    is_body_a = v17,
                    normal = Vector3.new(v18 * v29, v19 * v29, v20 * v29),
                    position = Vector3.new(v13 * v30, v33 * v30, v34 * v30),
                    relative_linear_velocity = Vector3.new(x2 - x3, y2 - y3, z2 - z3),
                    other_surface = v38,
                    normal_force_on_a = Vector3.new(v18 * v7 * v4, v19 * v7 * v4, v20 * v7 * v4),
                    friction_force_on_a = Vector3.new(v35 * v4, v31 * v4, v32 * v4),
                    tangents = {
                        Vector3.new(v21, v22, v23),
                        Vector3.new(v24, v25, v26)
                    }
                }
            elseif v10 == 0 and v12 == 1 then
                local v39 = v13
                local v40 = v11
                local v41 = false

                if n1 == 16 then
                    break
                end

                local v42 = from_bits(v6[29])
                local v43 = from_bits(v6[30])
                local v44 = from_bits(v6[31])
                local v45 = from_bits(v6[41])
                local v46 = from_bits(v6[42])
                local v47 = from_bits(v6[43])
                local v48 = from_bits(v6[53])
                local v49 = from_bits(v6[54])
                local v50 = from_bits(v6[55])
                local x, y, z, v51, v52

                if v10 == 1 then
                    v51 = p12[BodyId.index(v11) + 1].rates.position
                    x = v51.x
                    y = v51.y
                    z = v51.z
                elseif v10 == 0 then
                    x = 0
                    y = 0
                    z = 0
                else
                    v51 = p13[v11 + 1]

                    if v51 ~= nil then
                        v52 = v51.rates.position
                        x = v52.x
                        y = v52.y
                        z = v52.z
                    else
                        x = 0
                        y = 0
                        z = 0
                    end
                end

                v51 = x + from_bits(v6[1])
                v52 = y + from_bits(v6[2])

                local v53 = z + from_bits(v6[3])
                local v54, v55, v56

                if v12 == 1 then
                    z = p12[BodyId.index(v13) + 1].rates.position
                    v54 = z.x
                    v56 = z.y
                    v55 = z.z
                elseif v12 == 0 then
                    v54 = 0
                    v56 = 0
                    v55 = 0
                else
                    y = p13[v13 + 1]

                    if y ~= nil then
                        x = y.rates.position
                        v54 = x.x
                        v56 = x.y
                        v55 = x.z
                    else
                        v54 = 0
                        v56 = 0
                        v55 = 0
                    end
                end

                local v57 = v54 + from_bits(v6[5])
                local v58 = v56 + from_bits(v6[6])
                local v59 = v55 + from_bits(v6[7])
                local v60 = from_bits(v6[36])
                local v61 = from_bits(v6[40])

                v54 = 1 / (v61 + v60)
                v13 = v51 * v60 + v57 * v61
                v57 = v52 * v60 + v58 * v61
                v58 = v53 * v60 + v59 * v61
                v59 = v45 * v9 + v48 * v8
                v55 = v46 * v9 + v49 * v8
                v56 = v47 * v9 + v50 * v8
                v53 = -1

                local v62 = bit32.band(bit32.rshift(v6[56], 16), 65535)

                v52 = p12[BodyId.index(v39) + 1].rates.linear_velocity

                local x2 = v52.x
                local y2 = v52.y
                local z2 = v52.z
                local x3, y3, z3

                if v10 == 1 then
                    v51 = p12[BodyId.index(v11) + 1].rates.linear_velocity
                    x3 = v51.x
                    y3 = v51.y
                    z3 = v51.z
                elseif v10 == 0 then
                    x3 = 0
                    y3 = 0
                    z3 = 0
                else
                    v12 = p13[v11 + 1]

                    if v12 ~= nil then
                        v11 = v12.rates.linear_velocity
                        x3 = v11.x
                        y3 = v11.y
                        z3 = v11.z
                    else
                        x3 = 0
                        y3 = 0
                        z3 = 0
                    end
                end

                n1 += 1
                p10[n1] = {
                    part = v39,
                    other = if v10 == 0 then {
                        tag = "StaticWorld"
                    } else {
                        tag = "Attached",
                        v40
                    },
                    is_body_a = v41,
                    normal = Vector3.new(v42 * v53, v43 * v53, v44 * v53),
                    position = Vector3.new(v13 * v54, v57 * v54, v58 * v54),
                    relative_linear_velocity = Vector3.new(x2 - x3, y2 - y3, z2 - z3),
                    other_surface = v62,
                    normal_force_on_a = Vector3.new(v42 * v7 * v4, v43 * v7 * v4, v44 * v7 * v4),
                    friction_force_on_a = Vector3.new(v59 * v4, v55 * v4, v56 * v4),
                    tangents = {
                        Vector3.new(v45, v46, v47),
                        Vector3.new(v48, v49, v50)
                    }
                }
            elseif v10 == 1 and v12 == 2 then
                local v63 = v11
                local v64 = v12
                local v65 = v13
                local v66 = true

                if n1 == 16 then
                    break
                end

                local v67 = from_bits(v6[29])
                local v68 = from_bits(v6[30])
                local v69 = from_bits(v6[31])
                local v70 = from_bits(v6[41])
                local v71 = from_bits(v6[42])
                local v72 = from_bits(v6[43])
                local v73 = from_bits(v6[53])
                local v74 = from_bits(v6[54])
                local v75 = from_bits(v6[55])
                local x, y, z, v76, v77

                if v10 == 1 then
                    v76 = p12[BodyId.index(v11) + 1].rates.position
                    x = v76.x
                    y = v76.y
                    z = v76.z
                elseif v10 == 0 then
                    x = 0
                    y = 0
                    z = 0
                else
                    v76 = p13[v11 + 1]

                    if v76 ~= nil then
                        v77 = v76.rates.position
                        x = v77.x
                        y = v77.y
                        z = v77.z
                    else
                        x = 0
                        y = 0
                        z = 0
                    end
                end

                v76 = x + from_bits(v6[1])
                v77 = y + from_bits(v6[2])

                local v78 = z + from_bits(v6[3])
                local v79, v80, v81

                if v12 == 1 then
                    z = p12[BodyId.index(v13) + 1].rates.position
                    v79 = z.x
                    v81 = z.y
                    v80 = z.z
                elseif v12 == 0 then
                    v79 = 0
                    v81 = 0
                    v80 = 0
                else
                    y = p13[v13 + 1]

                    if y ~= nil then
                        x = y.rates.position
                        v79 = x.x
                        v81 = x.y
                        v80 = x.z
                    else
                        v79 = 0
                        v81 = 0
                        v80 = 0
                    end
                end

                local v82 = v79 + from_bits(v6[5])
                local v83 = v81 + from_bits(v6[6])
                local v84 = v80 + from_bits(v6[7])
                local v85 = from_bits(v6[36])
                local v86 = from_bits(v6[40])

                v79 = 1 / (v86 + v85)
                v13 = v76 * v85 + v82 * v86
                v82 = v77 * v85 + v83 * v86
                v83 = v78 * v85 + v84 * v86
                v84 = v70 * v9 + v73 * v8
                v80 = v71 * v9 + v74 * v8
                v81 = v72 * v9 + v75 * v8
                v78 = 1

                local v87 = bit32.band(v6[56], 65535)

                v77 = p12[BodyId.index(v11) + 1].rates.linear_velocity

                local x2 = v77.x
                local y2 = v77.y
                local z2 = v77.z
                local x3, y3, z3

                if v12 == 1 then
                    v76 = p12[BodyId.index(v65) + 1].rates.linear_velocity
                    x3 = v76.x
                    y3 = v76.y
                    z3 = v76.z
                elseif v12 == 0 then
                    x3 = 0
                    y3 = 0
                    z3 = 0
                else
                    v12 = p13[v65 + 1]

                    if v12 ~= nil then
                        v11 = v12.rates.linear_velocity
                        x3 = v11.x
                        y3 = v11.y
                        z3 = v11.z
                    else
                        x3 = 0
                        y3 = 0
                        z3 = 0
                    end
                end

                n1 += 1
                p10[n1] = {
                    part = v63,
                    other = if v64 == 0 then {
                        tag = "StaticWorld"
                    } else {
                        tag = "Attached",
                        v65
                    },
                    is_body_a = v66,
                    normal = Vector3.new(v67 * v78, v68 * v78, v69 * v78),
                    position = Vector3.new(v13 * v79, v82 * v79, v83 * v79),
                    relative_linear_velocity = Vector3.new(x2 - x3, y2 - y3, z2 - z3),
                    other_surface = v87,
                    normal_force_on_a = Vector3.new(v67 * v7 * v4, v68 * v7 * v4, v69 * v7 * v4),
                    friction_force_on_a = Vector3.new(v84 * v4, v80 * v4, v81 * v4),
                    tangents = {
                        Vector3.new(v70, v71, v72),
                        Vector3.new(v73, v74, v75)
                    }
                }
            elseif v10 == 2 and v12 == 1 then
                local v88 = v13
                local v89 = v11
                local v90 = false

                if n1 == 16 then
                    break
                end

                local v91 = from_bits(v6[29])
                local v92 = from_bits(v6[30])
                local v93 = from_bits(v6[31])
                local v94 = from_bits(v6[41])
                local v95 = from_bits(v6[42])
                local v96 = from_bits(v6[43])
                local v97 = from_bits(v6[53])
                local v98 = from_bits(v6[54])
                local v99 = from_bits(v6[55])
                local x, y, z, v100, v101

                if v10 == 1 then
                    v100 = p12[BodyId.index(v11) + 1].rates.position
                    x = v100.x
                    y = v100.y
                    z = v100.z
                elseif v10 == 0 then
                    x = 0
                    y = 0
                    z = 0
                else
                    v100 = p13[v11 + 1]

                    if v100 ~= nil then
                        v101 = v100.rates.position
                        x = v101.x
                        y = v101.y
                        z = v101.z
                    else
                        x = 0
                        y = 0
                        z = 0
                    end
                end

                v100 = x + from_bits(v6[1])
                v101 = y + from_bits(v6[2])

                local v102 = z + from_bits(v6[3])
                local v103, v104, v105

                if v12 == 1 then
                    z = p12[BodyId.index(v13) + 1].rates.position
                    v103 = z.x
                    v105 = z.y
                    v104 = z.z
                elseif v12 == 0 then
                    v103 = 0
                    v105 = 0
                    v104 = 0
                else
                    y = p13[v13 + 1]

                    if y ~= nil then
                        x = y.rates.position
                        v103 = x.x
                        v105 = x.y
                        v104 = x.z
                    else
                        v103 = 0
                        v105 = 0
                        v104 = 0
                    end
                end

                local v106 = v103 + from_bits(v6[5])
                local v107 = v105 + from_bits(v6[6])
                local v108 = v104 + from_bits(v6[7])
                local v109 = from_bits(v6[36])
                local v110 = from_bits(v6[40])

                v103 = 1 / (v110 + v109)
                v13 = v100 * v109 + v106 * v110
                v106 = v101 * v109 + v107 * v110
                v107 = v102 * v109 + v108 * v110
                v108 = v94 * v9 + v97 * v8
                v104 = v95 * v9 + v98 * v8
                v105 = v96 * v9 + v99 * v8
                v102 = -1

                local v111 = bit32.band(bit32.rshift(v6[56], 16), 65535)

                v101 = p12[BodyId.index(v88) + 1].rates.linear_velocity

                local x2 = v101.x
                local y2 = v101.y
                local z2 = v101.z
                local x3, y3, z3

                if v10 == 1 then
                    v100 = p12[BodyId.index(v11) + 1].rates.linear_velocity
                    x3 = v100.x
                    y3 = v100.y
                    z3 = v100.z
                elseif v10 == 0 then
                    x3 = 0
                    y3 = 0
                    z3 = 0
                else
                    v12 = p13[v11 + 1]

                    if v12 ~= nil then
                        v11 = v12.rates.linear_velocity
                        x3 = v11.x
                        y3 = v11.y
                        z3 = v11.z
                    else
                        x3 = 0
                        y3 = 0
                        z3 = 0
                    end
                end

                n1 += 1
                p10[n1] = {
                    part = v88,
                    other = if v10 == 0 then {
                        tag = "StaticWorld"
                    } else {
                        tag = "Attached",
                        v89
                    },
                    is_body_a = v90,
                    normal = Vector3.new(v91 * v102, v92 * v102, v93 * v102),
                    position = Vector3.new(v13 * v103, v106 * v103, v107 * v103),
                    relative_linear_velocity = Vector3.new(x2 - x3, y2 - y3, z2 - z3),
                    other_surface = v111,
                    normal_force_on_a = Vector3.new(v91 * v7 * v4, v92 * v7 * v4, v93 * v7 * v4),
                    friction_force_on_a = Vector3.new(v108 * v4, v104 * v4, v105 * v4),
                    tangents = {
                        Vector3.new(v94, v95, v96),
                        Vector3.new(v97, v98, v99)
                    }
                }
            end
        end
    end
end

function t1.collect_reference(p15, p16, p17, p18, p19) -- line: 186
    -- upvalues: rt (copy), v1 (copy), import (copy), RetailContactJacobian (copy), t1 (copy)
    local CollisionBody = import("skate_core/physics/board_step").CollisionBody

    table.clear(p15)

    local v112 = p19 * p19

    for _, v113 in p16 do
        local v114 = RetailContactJacobian.words(v113)
        local v115 = RetailContactJacobian.accumulated_impulse(v113)

        if bit32.band(v114[12], 8) ~= 0 and v115[1] > 0 then
            local v117 = CollisionBody.from_contact_id(v114[32])
            local v118 = CollisionBody.from_contact_id(v114[44])

            if v117.tag == "Board" and v118.tag == "StaticWorld" then
                local v119 = v117[1]
                local v120 = true

                if #p15 == 16 then
                    break
                end

                local v121 = t1.vector(v114, 28)
                local t6 = {
                    t1.vector(v114, 40),
                    t1.vector(v114, 52)
                }
                local v122 = t1.add(t1.center(v117, p17, p18), t1.vector(v114, 0))
                local v123 = t1.add(t1.center(v118, p17, p18), t1.vector(v114, 4))

                buffer.writeu32(v1, 0, v114[36])

                local v125 = buffer.readf32(v1, 0)

                buffer.writeu32(v1, 0, v114[40])

                local v127 = buffer.readf32(v1, 0)
                local v128 = 1 / (v127 + v125)
                local v129 = t1.combine(v122, v125, t1.scale(v123, v127))
                local v130 = t1.combine(t6[1], v115[2], t1.scale(t6[2], v115[3]))
                local n2 = 1
                local t7 = {
                    tag = "Board",
                    v119
                }
                local v132 = bit32.band(v114[56], 65535)

                table.insert(p15, {
                    part = v119,
                    other = rt.copy(v118),
                    is_body_a = v120,
                    normal = t1.scale(v121, n2),
                    position = t1.scale(v129, v128),
                    relative_linear_velocity = t1.subtract(t1.velocity(t7, p17, p18), t1.velocity(v118, p17, p18)),
                    other_surface = v132,
                    normal_force_on_a = t1.scale(t1.scale(v121, v115[1]), v112),
                    friction_force_on_a = t1.scale(v130, v112),
                    tangents = t6
                })
            elseif v117.tag == "StaticWorld" and v118.tag == "Board" then
                local v133 = v118[1]
                local v134 = false

                if #p15 == 16 then
                    break
                end

                local v135 = t1.vector(v114, 28)
                local t9 = {
                    t1.vector(v114, 40),
                    t1.vector(v114, 52)
                }
                local v136 = t1.add(t1.center(v117, p17, p18), t1.vector(v114, 0))
                local v137 = t1.add(t1.center(v118, p17, p18), t1.vector(v114, 4))

                buffer.writeu32(v1, 0, v114[36])

                local v139 = buffer.readf32(v1, 0)

                buffer.writeu32(v1, 0, v114[40])

                local v141 = buffer.readf32(v1, 0)
                local v142 = 1 / (v141 + v139)
                local v143 = t1.combine(v136, v139, t1.scale(v137, v141))
                local v144 = t1.combine(t9[1], v115[2], t1.scale(t9[2], v115[3]))
                local n3 = -1
                local t10 = {
                    tag = "Board",
                    v133
                }
                local v147 = bit32.band(bit32.rshift(v114[56], 16), 65535)

                table.insert(p15, {
                    part = v133,
                    other = rt.copy(v117),
                    is_body_a = v134,
                    normal = t1.scale(v135, n3),
                    position = t1.scale(v143, v142),
                    relative_linear_velocity = t1.subtract(t1.velocity(t10, p17, p18), t1.velocity(v117, p17, p18)),
                    other_surface = v147,
                    normal_force_on_a = t1.scale(t1.scale(v135, v115[1]), v112),
                    friction_force_on_a = t1.scale(v144, v112),
                    tangents = t9
                })
            elseif v117.tag == "Board" and v118.tag == "Attached" then
                local v148 = v117[1]
                local v149 = true

                if #p15 == 16 then
                    break
                end

                local v150 = t1.vector(v114, 28)
                local t12 = {
                    t1.vector(v114, 40),
                    t1.vector(v114, 52)
                }
                local v151 = t1.add(t1.center(v117, p17, p18), t1.vector(v114, 0))
                local v152 = t1.add(t1.center(v118, p17, p18), t1.vector(v114, 4))

                buffer.writeu32(v1, 0, v114[36])

                local v154 = buffer.readf32(v1, 0)

                buffer.writeu32(v1, 0, v114[40])

                local v156 = buffer.readf32(v1, 0)
                local v157 = 1 / (v156 + v154)
                local v158 = t1.combine(v151, v154, t1.scale(v152, v156))
                local v159 = t1.combine(t12[1], v115[2], t1.scale(t12[2], v115[3]))
                local n4 = 1
                local t13 = {
                    tag = "Board",
                    v148
                }
                local v161 = bit32.band(v114[56], 65535)

                table.insert(p15, {
                    part = v148,
                    other = rt.copy(v118),
                    is_body_a = v149,
                    normal = t1.scale(v150, n4),
                    position = t1.scale(v158, v157),
                    relative_linear_velocity = t1.subtract(t1.velocity(t13, p17, p18), t1.velocity(v118, p17, p18)),
                    other_surface = v161,
                    normal_force_on_a = t1.scale(t1.scale(v150, v115[1]), v112),
                    friction_force_on_a = t1.scale(v159, v112),
                    tangents = t12
                })
            elseif v117.tag == "Attached" and v118.tag == "Board" then
                local v162 = v118[1]
                local v163 = false

                if #p15 == 16 then
                    break
                end

                local v164 = t1.vector(v114, 28)
                local t15 = {
                    t1.vector(v114, 40),
                    t1.vector(v114, 52)
                }
                local v165 = t1.add(t1.center(v117, p17, p18), t1.vector(v114, 0))
                local v166 = t1.add(t1.center(v118, p17, p18), t1.vector(v114, 4))

                buffer.writeu32(v1, 0, v114[36])

                local v168 = buffer.readf32(v1, 0)

                buffer.writeu32(v1, 0, v114[40])

                local v170 = buffer.readf32(v1, 0)
                local v171 = 1 / (v170 + v168)
                local v172 = t1.combine(v165, v168, t1.scale(v166, v170))
                local v173 = t1.combine(t15[1], v115[2], t1.scale(t15[2], v115[3]))
                local n5 = -1
                local t16 = {
                    tag = "Board",
                    v162
                }
                local v176 = bit32.band(bit32.rshift(v114[56], 16), 65535)

                table.insert(p15, {
                    part = v162,
                    other = rt.copy(v117),
                    is_body_a = v163,
                    normal = t1.scale(v164, n5),
                    position = t1.scale(v172, v171),
                    relative_linear_velocity = t1.subtract(t1.velocity(t16, p17, p18), t1.velocity(v117, p17, p18)),
                    other_surface = v176,
                    normal_force_on_a = t1.scale(t1.scale(v164, v115[1]), v112),
                    friction_force_on_a = t1.scale(v173, v112),
                    tangents = t15
                })
            end
        end
    end
end

function t1.center(p20, p21, p22) -- line: 251
    -- upvalues: rt (copy), Vector3 (copy), BodyId (copy)
    if p20.tag == "Board" then
        return rt.copy(p21[BodyId.index(p20[1]) + 1].rates.position)
    end

    if p20.tag == "StaticWorld" then
        return rt.copy(Vector3.ZERO)
    end

    local v177 = p22[p20[1] + 1]

    if v177 == nil then
        return rt.copy(Vector3.ZERO)
    end

    return rt.copy(v177.rates.position)
end

function t1.velocity(p23, p24, p25) -- line: 265
    -- upvalues: rt (copy), Vector3 (copy), BodyId (copy)
    if p23.tag == "Board" then
        return rt.copy(p24[BodyId.index(p23[1]) + 1].rates.linear_velocity)
    end

    if p23.tag == "StaticWorld" then
        return rt.copy(Vector3.ZERO)
    end

    local v178 = p25[p23[1] + 1]

    if v178 == nil then
        return rt.copy(Vector3.ZERO)
    end

    return rt.copy(v178.rates.linear_velocity)
end

function t1.vector(p26, p27) -- line: 280
    -- upvalues: v1 (copy), Vector3 (copy)
    local new = Vector3.new

    buffer.writeu32(v1, 0, p26[p27 + 1])

    local v180 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p26[p27 + 2])

    local v182 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p26[p27 + 3])

    return new(v180, v182, (buffer.readf32(v1, 0)))
end

function t1.scale(p28, p29) -- line: 288
    -- upvalues: Vector3 (copy)
    return Vector3.new(p28.x * p29, p28.y * p29, p28.z * p29)
end

function t1.add(p30, p31) -- line: 292
    -- upvalues: Vector3 (copy)
    return Vector3.new(p30.x + p31.x, p30.y + p31.y, p30.z + p31.z)
end

function t1.subtract(p32, p33) -- line: 296
    -- upvalues: Vector3 (copy)
    return Vector3.new(p32.x - p33.x, p32.y - p33.y, p32.z - p33.z)
end

function t1.combine(p34, p35, p36) -- line: 300
    -- upvalues: Vector3 (copy)
    return Vector3.new(p34.x * p35 + p36.x, p34.y * p35 + p36.y, p34.z * p35 + p36.z)
end

return t1
