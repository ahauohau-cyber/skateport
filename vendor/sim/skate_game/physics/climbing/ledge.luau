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
local Vector3 = import("skate_core/math").Vector3
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local t1 = {}
local t2 = {
    0, 1, 0
}
local t3 = {
    0, 0, 0
}

local function glam_vec3(p2, p3, p4) -- line: 24
    return { p2, p3, p4 }
end

local function glam_add(p5, p6) -- line: 27
    return {
        p5[1] + p6[1],
        p5[2] + p6[2],
        p5[3] + p6[3]
    }
end

local function glam_sub(p7, p8) -- line: 30
    return {
        p7[1] - p8[1],
        p7[2] - p8[2],
        p7[3] - p8[3]
    }
end

local function glam_scale(p9, p10) -- line: 33
    return {
        p9[1] * p10,
        p9[2] * p10,
        p9[3] * p10
    }
end

local function glam_neg(p11) -- line: 36
    return {
        -p11[1],
        -p11[2],
        -p11[3]
    }
end

local function glam_dot(p12, p13) -- line: 39
    return p12[1] * p13[1] + p12[2] * p13[2] + p12[3] * p13[3]
end

local function glam_cross(p14, p15) -- line: 42
    return {
        p14[2] * p15[3] - p15[2] * p14[3],
        p14[3] * p15[1] - p15[3] * p14[1],
        p14[1] * p15[2] - p15[1] * p14[2]
    }
end

local function glam_normalize(p16) -- line: 50
    local v2 = 1 / math.sqrt(p16[1] * p16[1] + p16[2] * p16[2] + p16[3] * p16[3])

    return {
        p16[1] * v2,
        p16[2] * v2,
        p16[3] * v2
    }
end

local function glam_try_normalize(p17) -- line: 54
    local v4 = 1 / math.sqrt(p17[1] * p17[1] + p17[2] * p17[2] + p17[3] * p17[3])

    return if v4 == v4 and v4 ~= 1e999 and v4 ~= (-1e999) and v4 > 0 then {
        p17[1] * v4,
        p17[2] * v4,
        p17[3] * v4
    } else nil
end

t1.Ledge = {}

local find_range

function t1.v(p18) -- line: 71
    -- upvalues: Vector3 (copy)
    return Vector3.new(p18[1], p18[2], p18[3])
end

local v = t1.v

function t1.hit(p19, p20, p21, p22) -- line: 78
    -- upvalues: BoardWorld (copy), v (copy)
    local query_swept_line = BoardWorld.query_swept_line
    local v5 = v(p20)
    local v6 = v(p21)
    local ok, result = pcall(query_swept_line, p19, v5, v6, p22)

    if not ok or result == nil then
        return nil
    end

    local geometry = result.geometry

    return {
        geometry.position.x,
        geometry.position.y,
        geometry.position.z
    }, {
        geometry.normal.x,
        geometry.normal.y,
        geometry.normal.z
    }
end

local hit = t1.hit

function t1.find_air(p23, p24, p25) -- line: 93
    -- upvalues: find_range (ref)
    return find_range(p23, p24, p25, 1.25, 2.6)
end

function t1.find_range(p26, p27, p28, p29, p30) -- line: 98
    -- upvalues: rt (copy), t1 (copy), t2 (copy), t3 (copy), glam_cross (copy), hit (copy)
    local t4 = {
        p28[1],
        0,
        p28[3]
    }
    local v8 = 1 / math.sqrt(t4[1] * t4[1] + t4[2] * t4[2] + t4[3] * t4[3])
    local t5 = if not (v8 == v8 and v8 ~= 1e999 and v8 ~= (-1e999) and v8 > 0) then nil else {
        t4[1] * v8,
        t4[2] * v8,
        t4[3] * v8
    }

    if t5 ~= nil then
        local t6 = {
            t2[1] * 1.15,
            t2[2] * 1.15,
            t2[3] * 1.15
        }
        local t7 = {
            p27[1] + t6[1],
            p27[2] + t6[2],
            p27[3] + t6[3]
        }
        local t8 = {
            t5[1] * p30,
            t5[2] * p30,
            t5[3] * p30
        }
        local v9, v10 = hit(p26, t7, {
            t7[1] + t8[1],
            t7[2] + t8[2],
            t7[3] + t8[3]
        }, 0)

        if v9 ~= nil and not (math.abs(v10[2]) > 0.2 or v10[1] * t5[1] + v10[2] * t5[2] + v10[3] * t5[3] > -0.65) then
            local t9 = {
                v10[1],
                0,
                v10[3]
            }
            local v13 = 1 / math.sqrt(t9[1] * t9[1] + t9[2] * t9[2] + t9[3] * t9[3])
            local t10 = {
                t9[1] * v13,
                t9[2] * v13,
                t9[3] * v13
            }
            local t11 = {
                -t10[1],
                -t10[2],
                -t10[3]
            }
            local v14 = glam_cross(t2, t11)
            local t12 = {
                t11[1] * 0.12,
                t11[2] * 0.12,
                t11[3] * 0.12
            }
            local t13 = {
                v9[1] + t12[1],
                v9[2] + t12[2],
                v9[3] + t12[3]
            }
            local v15, v16 = hit(p26, {
                t13[1],
                p27[2] + 2.75,
                t13[3]
            }, {
                t13[1],
                p27[2] + p29,
                t13[3]
            }, 0)

            if v15 ~= nil and not (v16[2] < 0.95) then
                local t14 = {
                    v9[1],
                    v15[2] + 0.025,
                    v9[3]
                }
                local t15 = {
                    t11[1] * 0.055,
                    t11[2] * 0.055,
                    t11[3] * 0.055
                }
                local t16 = {
                    t14[1] + t15[1],
                    t14[2] + t15[2],
                    t14[3] + t15[3]
                }
                local t17 = {
                    rt.copy(t3),
                    rt.copy(t3)
                }
                local t18 = {
                    rt.copy(t2),
                    rt.copy(t2)
                }

                for v17, v18 in ipairs({ 0.3, -0.3 }) do
                    local v19 = v17 - 1
                    local t19 = {
                        t11[1] * 0.08,
                        t11[2] * 0.08,
                        t11[3] * 0.08
                    }
                    local t20 = {
                        v9[1] + t19[1],
                        v9[2] + t19[2],
                        v9[3] + t19[3]
                    }
                    local t21 = {
                        v14[1] * v18,
                        v14[2] * v18,
                        v14[3] * v18
                    }
                    local t22 = {
                        t20[1] + t21[1],
                        t20[2] + t21[2],
                        t20[3] + t21[3]
                    }
                    local v20, v21 = hit(p26, {
                        t22[1],
                        v15[2] + 0.15,
                        t22[3]
                    }, {
                        t22[1],
                        v15[2] - 0.15,
                        t22[3]
                    }, 0)

                    if v20 == nil then
                        return nil
                    end

                    local v22 = v19 + 1
                    local t23 = {
                        v21[1] * 0.005,
                        v21[2] * 0.005,
                        v21[3] * 0.005
                    }

                    t17[v22] = {
                        v20[1] + t23[1],
                        v20[2] + t23[2],
                        v20[3] + t23[3]
                    }
                    t18[v19 + 1] = v21

                    if math.abs(v20[2] - v15[2]) > 0.06 or v21[2] < 0.95 then
                        return nil
                    end
                end

                local t24 = {
                    anchor = t16
                }
                local t25 = {
                    v9[1],
                    v15[2] + 0.015,
                    v9[3]
                }
                local t26 = {
                    t11[1] * 0.62,
                    t11[2] * 0.62,
                    t11[3] * 0.62
                }

                t24.landing = {
                    t25[1] + t26[1],
                    t25[2] + t26[2],
                    t25[3] + t26[3]
                }
                t24.forward = t11
                t24.palms = t17
                t24.normals = t18

                if t1.clear(p26, t24) then
                    local t27 = {
                        t11[1] * 0.32,
                        t11[2] * 0.32,
                        t11[3] * 0.32
                    }
                    local t28 = {
                        t16[1] - t27[1],
                        t16[2] - t27[2],
                        t16[3] - t27[3]
                    }
                    local t29 = {
                        t2[1] * 1.25,
                        t2[2] * 1.25,
                        t2[3] * 1.25
                    }
                    local t30 = {
                        t28[1] - t29[1],
                        t28[2] - t29[2],
                        t28[3] - t29[3]
                    }
                    local t31 = {
                        t2[1] * 0.55,
                        t2[2] * 0.55,
                        t2[3] * 0.55
                    }

                    if hit(p26, t30, {
                        t28[1] + t31[1],
                        t28[2] + t31[2],
                        t28[3] + t31[3]
                    }, 0.2) == nil then
                        return t24
                    end
                end
            end
        end
    end

    return nil
end

find_range = t1.find_range

function t1.clear(p31, p32) -- line: 165
    -- upvalues: rt (copy), t2 (copy), t3 (copy), glam_cross (copy), hit (copy)
    local v24 = glam_cross(t2, p32.forward)
    local _ipairs = ipairs
    local v25 = rt.copy(t3)
    local t32 = {
        v24[1] * 0.25,
        v24[2] * 0.25,
        v24[3] * 0.25
    }
    local t33 = {
        -v24[1],
        -v24[2],
        -v24[3]
    }
    local t34 = {
        t33[1] * 0.25,
        t33[2] * 0.25,
        t33[3] * 0.25
    }
    local forward = p32.forward
    local t35 = {
        forward[1] * 0.25,
        forward[2] * 0.25,
        forward[3] * 0.25
    }
    local forward2 = p32.forward
    local t36 = {
        -forward2[1],
        -forward2[2],
        -forward2[3]
    }

    for _, v26 in _ipairs({
            v25,
            t32,
            t34,
            t35,
            {
                t36[1] * 0.25,
                t36[2] * 0.25,
                t36[3] * 0.25
            }
        }) do
        local landing = p32.landing
        local t37 = {
            landing[1] + v26[1],
            landing[2] + v26[2],
            landing[3] + v26[3]
        }
        local t38 = {
            t2[1] * 0.15,
            t2[2] * 0.15,
            t2[3] * 0.15
        }
        local t39 = {
            t37[1] + t38[1],
            t37[2] + t38[2],
            t37[3] + t38[3]
        }
        local t40 = {
            t2[1] * 0.15,
            t2[2] * 0.15,
            t2[3] * 0.15
        }
        local v27, v28 = hit(p31, t39, {
            t37[1] - t40[1],
            t37[2] - t40[2],
            t37[3] - t40[3]
        }, 0)

        if v27 == nil or math.abs(v27[2] - p32.landing[2]) > 0.06 or v28[2] < 0.95 then
            return false
        end

        local t41 = {
            t2[1] * 0.35,
            t2[2] * 0.35,
            t2[3] * 0.35
        }
        local t42 = {
            t37[1] + t41[1],
            t37[2] + t41[2],
            t37[3] + t41[3]
        }
        local t43 = {
            t2[1] * 1.55,
            t2[2] * 1.55,
            t2[3] * 1.55
        }

        if hit(p31, t42, {
            t37[1] + t43[1],
            t37[2] + t43[2],
            t37[3] + t43[3]
        }, 0.28) ~= nil then
            return false
        end
    end

    local anchor = p32.anchor
    local t44 = {
        t2[1] * 0.65,
        t2[2] * 0.65,
        t2[3] * 0.65
    }
    local t45 = {
        anchor[1] + t44[1],
        anchor[2] + t44[2],
        anchor[3] + t44[3]
    }
    local forward3 = p32.forward
    local t46 = {
        forward3[1] * 0.32,
        forward3[2] * 0.32,
        forward3[3] * 0.32
    }
    local t47 = {
        t45[1] - t46[1],
        t45[2] - t46[2],
        t45[3] - t46[3]
    }
    local landing = p32.landing
    local t48 = {
        t2[1] * 0.65,
        t2[2] * 0.65,
        t2[3] * 0.65
    }

    return hit(p31, t47, {
        landing[1] + t48[1],
        landing[2] + t48[2],
        landing[3] + t48[3]
    }, 0.22) == nil
end

return t1
