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
local v1 = import("skate_core/math")
local v2 = import("skate_core/physics/board_runtime")
local v3 = import("skate_core/physics/board")
local v4 = import("skate_core/physics/contact")
local v5 = import("skate_core/physics/skeleton_body")
local Vector3 = v1.Vector3
local BoardRuntime = v2.BoardRuntime
local BodyId = v3.BodyId
local SkeletonBody = v5.SkeletonBody
local combine_contact_materials = v4.combine_contact_materials

local function skate_dynamics() -- line: 39
    -- upvalues: import (copy)
    return import("skate_dynamics")
end

local t1 = {}

local function glam_vec3(p2, p3, p4) -- line: 49
    return {
        x = p2,
        y = p3,
        z = p4
    }
end

local function glam_add(p5, p6) -- line: 52
    return {
        x = p5.x + p6.x,
        y = p5.y + p6.y,
        z = p5.z + p6.z
    }
end

local function glam_sub(p7, p8) -- line: 55
    return {
        x = p7.x - p8.x,
        y = p7.y - p8.y,
        z = p7.z - p8.z
    }
end

local function glam_scale(p9, p10) -- line: 58
    return {
        x = p9.x * p10,
        y = p9.y * p10,
        z = p9.z * p10
    }
end

local function glam_dot(p11, p12) -- line: 61
    return p11.x * p12.x + p11.y * p12.y + p11.z * p12.z
end

local function glam_cross(p13, p14) -- line: 64
    return {
        x = p13.y * p14.z - p14.y * p13.z,
        y = p13.z * p14.x - p14.z * p13.x,
        z = p13.x * p14.y - p14.x * p13.y
    }
end

local function glam_length_squared(p15) -- line: 71
    return p15.x * p15.x + p15.y * p15.y + p15.z * p15.z
end

local function glam_is_finite(p16) -- line: 74
    local x = p16.x
    local v6 = x == x and x ~= 1e999 and x ~= (-1e999)

    if not v6 then
        return v6
    end

    local y = p16.y
    local v7 = y == y and y ~= 1e999 and y ~= (-1e999)

    if not v7 then
        return v7
    end

    local z = p16.z

    if z ~= z or z == 1e999 then
        return false
    end

    return z ~= (-1e999)
end

local function glam_try_normalize(p17) -- line: 78
    local v9 = 1 / math.sqrt(p17.x * p17.x + p17.y * p17.y + p17.z * p17.z)

    return if v9 == v9 and v9 ~= 1e999 and v9 ~= (-1e999) and v9 > 0 then {
        x = p17.x * v9,
        y = p17.y * v9,
        z = p17.z * v9
    } else nil
end

local function glam_any_orthonormal_vector(p18) -- line: 86
    -- upvalues: rt (copy)
    local v10 = rt.signum(p18.z)
    local v11 = -1 / (v10 + p18.z)

    return {
        x = p18.x * p18.y * v11,
        y = v10 + p18.y * p18.y * v11,
        z = -p18.y
    }
end

local function glam_quat_normalize(p19) -- line: 92
    local v13 = 1 / math.sqrt(p19.x * p19.x + p19.y * p19.y + p19.z * p19.z + p19.w * p19.w)

    return {
        x = p19.x * v13,
        y = p19.y * v13,
        z = p19.z * v13,
        w = p19.w * v13
    }
end

local function glam_quat_from_axis_angle(p20, p21) -- line: 97
    local v15 = math.sin(p21 * 0.5)
    local v17 = math.cos(p21 * 0.5)

    return {
        x = p20.x * v15,
        y = p20.y * v15,
        z = p20.z * v15,
        w = v17
    }
end

local function glam_quat_from_rotation_arc(p22, p23) -- line: 102
    -- upvalues: rt (copy), glam_cross (copy), glam_quat_normalize (copy)
    local v18 = 1 - 2 * rt.F32_EPSILON
    local v19 = p22.x * p23.x + p22.y * p23.y + p22.z * p23.z

    if v18 < v19 then
        return {
            x = 0,
            y = 0,
            z = 0,
            w = 1
        }
    end

    if v19 < -v18 then
        local v20 = rt.signum(p22.z)
        local v21 = -1 / (v20 + p22.z)
        local t2 = {
            x = p22.x * p22.y * v21,
            y = v20 + p22.y * p22.y * v21,
            z = -p22.y
        }

        return {
            w = 6.123233995736766E-17,
            x = t2.x * 1,
            y = t2.y * 1,
            z = t2.z * 1
        }
    end

    local v22 = glam_cross(p22, p23)

    return (glam_quat_normalize({
        x = v22.x,
        y = v22.y,
        z = v22.z,
        w = v19 + 1
    }))
end

local function glam_quat_from_mat3(p24) -- line: 117
    local v23 = p24[1][1]
    local v24 = p24[1][2]
    local v25 = p24[1][3]
    local v26 = p24[2][1]
    local v27 = p24[2][2]
    local v28 = p24[2][3]
    local v29 = p24[3][1]
    local v30 = p24[3][2]
    local v31 = p24[3][3]

    if v31 <= 0 then
        local v32 = v27 - v23
        local v33 = 1 - v31

        if v32 <= 0 then
            local v34 = v33 - v32
            local v35 = 0.5 / math.sqrt(v34)

            return {
                x = v34 * v35,
                y = (v24 + v26) * v35,
                z = (v25 + v29) * v35,
                w = (v28 - v30) * v35
            }
        end

        local v36 = v33 + v32
        local v37 = 0.5 / math.sqrt(v36)

        return {
            x = (v24 + v26) * v37,
            y = v36 * v37,
            z = (v28 + v30) * v37,
            w = (v29 - v25) * v37
        }
    end

    local v38 = v27 + v23
    local v39 = 1 + v31

    if v38 <= 0 then
        local v40 = v39 - v38
        local v41 = 0.5 / math.sqrt(v40)

        return {
            x = (v25 + v29) * v41,
            y = (v28 + v30) * v41,
            z = v40 * v41,
            w = (v24 - v26) * v41
        }
    end

    local v42 = v39 + v38
    local v43 = 0.5 / math.sqrt(v42)

    return {
        x = (v28 - v30) * v43,
        y = (v29 - v25) * v43,
        z = (v24 - v26) * v43,
        w = v42 * v43
    }
end

local function glam_quat_mul_vec3(p25, p26) -- line: 154
    -- upvalues: glam_cross (copy)
    local t3 = {
        x = p25.x,
        y = p25.y,
        z = p25.z
    }
    local v44 = t3.x * t3.x + t3.y * t3.y + t3.z * t3.z
    local v45 = p25.w * p25.w - v44
    local t4 = {
        x = p26.x * v45,
        y = p26.y * v45,
        z = p26.z * v45
    }
    local v46 = (p26.x * t3.x + p26.y * t3.y + p26.z * t3.z) * 2
    local t5 = {
        x = t3.x * v46,
        y = t3.y * v46,
        z = t3.z * v46
    }
    local t6 = {
        x = t4.x + t5.x,
        y = t4.y + t5.y,
        z = t4.z + t5.z
    }
    local v47 = glam_cross(t3, p26)
    local v48 = p25.w * 2
    local t7 = {
        x = v47.x * v48,
        y = v47.y * v48,
        z = v47.z * v48
    }

    return {
        x = t6.x + t7.x,
        y = t6.y + t7.y,
        z = t6.z + t7.z
    }
end

function t1.vector(p27) -- line: 162
    return {
        x = p27.x,
        y = p27.y,
        z = p27.z
    }
end

function t1.native(p28) -- line: 167
    -- upvalues: Vector3 (copy)
    return Vector3.new(p28.x, p28.y, p28.z)
end

function t1.shape(p29) -- line: 173
    -- upvalues: t1 (copy), glam_quat_normalize (copy), glam_quat_from_rotation_arc (copy), glam_quat_from_mat3 (copy)
    local t8, center, v49

    if p29.tag == "Sphere" then
        local v50 = p29[1]

        t8 = {
            tag = "ball",
            radius = v50.radius
        }
        center = v50.center
        v49 = {
            x = 0,
            y = 0,
            z = 0,
            w = 1
        }
    elseif p29.tag == "Capsule" then
        local t9 = {
            x = p29.axis.x,
            y = p29.axis.y,
            z = p29.axis.z
        }
        local v52 = 1 / math.sqrt(t9.x * t9.x + t9.y * t9.y + t9.z * t9.z)
        local t10 = if not (v52 == v52 and v52 ~= 1e999 and v52 ~= (-1e999) and v52 > 0) then nil else {
            x = t9.x * v52,
            y = t9.y * v52,
            z = t9.z * v52
        }

        if t10 == nil then
            return nil
        end

        t8 = {
            tag = "capsule_y",
            half_height = p29.half_length,
            radius = p29.radius
        }
        center = p29.center
        v49 = glam_quat_from_rotation_arc({
            x = 0,
            y = 1,
            z = 0
        }, t10)
    else
        if p29.tag ~= "RoundedBox" then
            return nil
        end

        local half_extents = p29.half_extents

        t8 = {
            tag = "round_cuboid",
            hx = half_extents.x,
            hy = half_extents.y,
            hz = half_extents.z,
            border_radius = p29.radius
        }
        center = p29.center
        v49 = glam_quat_normalize((glam_quat_from_mat3(p29.basis.columns)))
    end

    return t8, {
        translation = t1.vector(center),
        rotation = {
            x = v49.x,
            y = v49.y,
            z = v49.z,
            w = v49.w
        }
    }
end

function t1.append(p30, p31, p32, p33, p34) -- line: 220
    -- upvalues: t1 (copy)
    if p32[1] == nil then
        return
    end

    return t1.append_reference(p30, p31, p32, p33, p34)
end

function t1.append_reference(p35, p36, p37, p38, p39) -- line: 231
    -- upvalues: rt (copy), import (copy), BoardRuntime (copy), BodyId (copy), SkeletonBody (copy), combine_contact_materials (copy), t1 (copy)
    local time_step = p38.settings.step.simulation.time_step

    for _, v53 in ipairs(p36) do
        local v54, v55 = t1.shape(v53.primitive)

        if v54 ~= nil then
            local v56 = if v53.body.tag == "Board" then BoardRuntime.bodies(p38.board)[BodyId.index(v53.body[1]) + 1] elseif v53.body.tag == "Attached" then SkeletonBody.bodies(p39.skeleton)[v53.body[1] + 1] else nil

            if v56 ~= nil then
                for _, v57 in ipairs(p37) do
                    local v58 = v57[1]
                    local v59 = v57[2]

                    for _, v60 in ipairs(v59.colliders) do
                        local v61 = import("skate_dynamics").SolidBody.contact(v59, v60, v54, v55, t1.vector(v56.rates.position), t1.vector(v56.rates.linear_velocity), t1.vector(v56.rates.angular_velocity), time_step, 0.025)

                        if v61 ~= nil then
                            local v62 = combine_contact_materials(v53.material, {
                                restitution = 0,
                                static_friction = v60.friction,
                                dynamic_friction = v60.friction * 0.75
                            })

                            table.insert(p35, {
                                body_a = rt.copy(v53.body),
                                body_b = {
                                    tag = "Attached",
                                    v58
                                },
                                contact = {
                                    tag = 0,
                                    position_on_a = t1.native(v61.point_a),
                                    position_on_b = t1.native(v61.point_b),
                                    normal = t1.native(v61.normal),
                                    restitution = v62.restitution,
                                    static_friction = v62.static_friction,
                                    dynamic_friction = v62.dynamic_friction
                                }
                            })
                        end
                    end
                end
            end
        end
    end
end

function t1.constrained_position(p40, p41, p42, p43) -- line: 299
    -- upvalues: rt (copy), glam_quat_mul_vec3 (copy)
    if #p40 == 0 then
        return p42
    end

    local x = p41.x
    local v63 = x == x and x ~= 1e999 and x ~= (-1e999)
    local v64

    if v63 then
        local y = p41.y
        local v65 = y == y and y ~= 1e999 and y ~= (-1e999)

        if v65 then
            local z = p41.z

            v64 = z == z and z ~= 1e999 and z ~= (-1e999)
        else
            v64 = v65
        end
    else
        v64 = v63
    end

    if v64 then
        local x = p42.x
        local v66 = x == x and x ~= 1e999 and x ~= (-1e999)
        local v67

        if v66 then
            local y = p42.y
            local v68 = y == y and y ~= 1e999 and y ~= (-1e999)

            if v68 then
                local z = p42.z

                v67 = z == z and z ~= 1e999 and z ~= (-1e999)
            else
                v67 = v68
            end
        else
            v67 = v66
        end

        if v67 then
            local t12 = {
                tag = "capsule_y",
                half_height = 0.55,
                radius = 0.28
            }
            local t13 = {
                x = p41.x,
                y = p41.y,
                z = p41.z
            }
            local t14 = {
                x = p42.x - p41.x,
                y = p42.y - p41.y,
                z = p42.z - p41.z
            }

            if p43 == nil then
                error("constrained_position: mod solids require the host parry queries (not translated)", 0)
            end

            local t15 = {
                x = 0,
                y = 0,
                z = 0,
                w = 1
            }

            for _ = 0, 7 do
                local t16 = {
                    translation = t13,
                    rotation = t15
                }
                local v69

                for _, v70 in ipairs(p40) do
                    local v71 = v70[2]

                    for _, v73 in ipairs(v71.colliders) do
                        local contact = p43.contact
                        local pose, shape = v73.pose, v73.shape
                        local ok, result = pcall(contact, t16, t12, pose, shape, 0.015)

                        if ok and result ~= nil and result.dist < 0 and (v69 == nil or result.dist < v69[1]) then
                            v69 = {
                                result.dist,
                                result.normal2
                            }
                        end
                    end
                end

                if v69 == nil then
                    break
                end

                local v74 = v69[1]
                local v75 = v69[2]
                local x = v75.x
                local v76 = x == x and x ~= 1e999 and x ~= (-1e999)
                local v77

                if v76 then
                    local y = v75.y
                    local v78 = y == y and y ~= 1e999 and y ~= (-1e999)

                    if v78 then
                        local z = v75.z

                        v77 = z == z and z ~= 1e999 and z ~= (-1e999)
                    else
                        v77 = v78
                    end
                else
                    v77 = v76
                end

                if not v77 or v74 ~= v74 or v74 == 1e999 or v74 == (-1e999) then
                    break
                end

                local v79 = -v74 + 0.015
                local t17 = {
                    x = v75.x * v79,
                    y = v75.y * v79,
                    z = v75.z * v79
                }

                t13 = {
                    x = t13.x + t17.x,
                    y = t13.y + t17.y,
                    z = t13.z + t17.z
                }
            end

            for _ = 0, 4 do
                if t14.x * t14.x + t14.y * t14.y + t14.z * t14.z < 1E-10 then
                    break
                end

                local t18 = {
                    translation = t13,
                    rotation = t15
                }
                local v80

                for _, v81 in ipairs(p40) do
                    local v82 = v81[2]

                    for _, v84 in ipairs(v82.colliders) do
                        local t19 = {
                            max_time_of_impact = 1,
                            target_distance = 0.015,
                            stop_at_penetration = true,
                            compute_impact_geometry_on_penetration = true
                        }
                        local cast_shapes = p43.cast_shapes
                        local pose = v84.pose
                        local t20 = {
                            x = 0,
                            y = 0,
                            z = 0
                        }
                        local shape = v84.shape
                        local ok, result = pcall(cast_shapes, t18, t14, t12, pose, t20, shape, t19)

                        if ok and result ~= nil then
                            local v85 = glam_quat_mul_vec3(v84.pose.rotation, result.normal2)

                            if not (v85.x * t14.x + v85.y * t14.y + v85.z * t14.z >= -1E-07) and (v80 == nil or result.time_of_impact < v80[1]) then
                                v80 = {
                                    result.time_of_impact,
                                    v85
                                }
                            end
                        end
                    end
                end

                if v80 == nil then
                    t13 = {
                        x = t13.x + t14.x,
                        y = t13.y + t14.y,
                        z = t13.z + t14.z
                    }
                    break
                end

                local v86 = v80[1]
                local v87 = v80[2]
                local v88 = rt.clamp(v86, 0, 1)
                local t21 = {
                    x = t14.x * v88,
                    y = t14.y * v88,
                    z = t14.z * v88
                }
                local t22 = {
                    x = t13.x + t21.x,
                    y = t13.y + t21.y,
                    z = t13.z + t21.z
                }
                local t23 = {
                    x = v87.x * 0.001,
                    y = v87.y * 0.001,
                    z = v87.z * 0.001
                }

                t13 = {
                    x = t22.x + t23.x,
                    y = t22.y + t23.y,
                    z = t22.z + t23.z
                }

                local v89 = 1 - rt.clamp(v86, 0, 1)
                local t24 = {
                    x = t14.x * v89,
                    y = t14.y * v89,
                    z = t14.z * v89
                }
                local v90 = rt.fmin(t24.x * v87.x + t24.y * v87.y + t24.z * v87.z, 0)
                local t25 = {
                    x = v87.x * v90,
                    y = v87.y * v90,
                    z = v87.z * v90
                }

                t14 = {
                    x = t24.x - t25.x,
                    y = t24.y - t25.y,
                    z = t24.z - t25.z
                }
            end

            return {
                x = t13.x,
                y = t13.y,
                z = t13.z
            }
        end
    end

    return p42
end

function t1.constrain_ground(p44, p45, p46, p47, p48) -- line: 388
    -- upvalues: rt (copy), t1 (copy)
    local t26 = {
        x = p46[1],
        y = p46[2],
        z = p46[3]
    }
    local t27 = {
        x = p45.position[1],
        y = p45.position[2],
        z = p45.position[3]
    }
    local v91 = t1.constrained_position(p47, t26, t27, p48)
    local t28 = {
        x = v91.x - t27.x,
        y = v91.y - t27.y,
        z = v91.z - t27.z
    }

    if t28.x * t28.x + t28.y * t28.y + t28.z * t28.z < 1E-12 then
        return
    end

    local x = t28.x
    local v92 = x == x and x ~= 1e999 and x ~= (-1e999)
    local v93

    if v92 then
        local y = t28.y
        local v94 = y == y and y ~= 1e999 and y ~= (-1e999)

        if v94 then
            local z = t28.z

            v93 = z == z and z ~= 1e999 and z ~= (-1e999)
        else
            v93 = v94
        end
    else
        v93 = v92
    end

    if not v93 then
        return
    end

    local function shift(p49) -- line: 395
        -- upvalues: t28 (copy)
        p49[1] += t28.x
        p49[2] += t28.y
        p49[3] += t28.z
    end

    local position = p45.position

    position[1] += t28.x
    position[2] += t28.y
    position[3] += t28.z

    local v95 = p45.physical_frame[4]

    v95[1] += t28.x
    v95[2] += t28.y
    v95[3] += t28.z

    local v96 = p45.animation_frame[4]

    v96[1] += t28.x
    v96[2] += t28.y
    v96[3] += t28.z

    local state = p44.controller.state
    local position_368 = state.position_368

    position_368[1] += t28.x
    position_368[2] += t28.y
    position_368[3] += t28.z

    local v97 = state.motion.frame_0[4]

    v97[1] += t28.x
    v97[2] += t28.y
    v97[3] += t28.z

    local v98 = state.motion.published_frame_64[4]

    v98[1] += t28.x
    v98[2] += t28.y
    v98[3] += t28.z

    local v99 = state.frame_output.frame[4]

    v99[1] += t28.x
    v99[2] += t28.y
    v99[3] += t28.z

    local correction_target_592 = state.correction_target_592

    correction_target_592[1] += t28.x
    correction_target_592[2] += t28.y
    correction_target_592[3] += t28.z
    p44.result = rt.copy(p45)
end

return t1
