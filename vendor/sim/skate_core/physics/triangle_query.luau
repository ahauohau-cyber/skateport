-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local Vector3 = import("skate_core/math").Vector3

local function triangle_sweep() -- line: 14
    -- upvalues: import (copy)
    return import("skate_core/physics/triangle_sweep")
end

local t1 = {
    TriangleLineHit = {}
}

function t1.TriangleLineHit.eq(p1, p2) -- line: 28
    -- upvalues: Vector3 (copy)
    return Vector3.eq(p1.position, p2.position) and Vector3.eq(p1.normal, p2.normal) and p1.fraction == p2.fraction and p1.volume_parameter[1] == p2.volume_parameter[1] and p1.volume_parameter[2] == p2.volume_parameter[2] and p1.volume_parameter[3] == p2.volume_parameter[3]
end

local dot, sub, scale, madd, cross, inverse_length, thin_triangle_reference

local function triangle_segment_reference(p3, p4, p5, p6, p7, p8) -- line: 44
    -- upvalues: rt (copy), import (copy), dot (ref), sub (ref), scale (ref), cross (ref), inverse_length (ref), thin_triangle_reference (ref)
    local v3 = p7 + p8

    if v3 == 0 then
        local v4 = thin_triangle_reference(p4, p5, p6)

        if v4 == nil then
            return false
        end

        rt.assign(p3, v4)
    else
        local v5 = cross(sub(p6[1], p6[2]), sub(p6[1], p6[3]))

        p3.normal = scale(v5, inverse_length(dot(v5, v5)))

        if not import("skate_core/physics/triangle_sweep").sweep_reference(p3, p4, p5, p6, v3) then
            return false
        end

        p3.position = sub(p3.position, scale(p3.normal, p7))
    end

    return true
end

function thin_triangle_reference(p9, p10, p11) -- line: 68
    -- upvalues: dot (ref), sub (ref), scale (ref), madd (ref), cross (ref), inverse_length (ref)
    local v6 = p11[1]
    local v7 = p11[2]
    local v8 = p11[3]
    local v9 = sub(v8, v6)
    local v10 = sub(v7, v6)
    local v11 = cross(p10, v9)
    local v12 = dot(v10, v11)

    if not (v12 > 9.99999993922529E-09) then
        return nil
    end

    local v13 = sub(p9, v6)
    local v14 = v12 * -9.999999747378752E-06
    local v15 = v12 - v14
    local v16 = dot(v13, v11)

    if v16 < v14 or v15 < v16 then
        return nil
    end

    local v17 = cross(v13, v10)
    local v18 = dot(p10, v17)

    if v18 < v14 or v15 < v18 + v16 then
        return nil
    end

    local v19 = dot(v9, v17)

    if v19 < v14 or v15 < v19 then
        return nil
    end

    local v20 = 1 / v12
    local v21 = v19 * v20
    local v22 = cross(sub(v6, v7), sub(v6, v8))

    return {
        position = madd(p10, v21, p9),
        normal = scale(v22, inverse_length(dot(v22, v22))),
        fraction = v21,
        volume_parameter = {
            v16 * v20,
            v18 * v20,
            0
        }
    }
end

t1.triangle_segment_reference = triangle_segment_reference
t1.thin_triangle_reference = thin_triangle_reference

function t1.thin_triangle(p12, p13, p14) -- line: 115
    -- upvalues: Vector3 (copy), inverse_length (ref)
    local v23 = p14[1]
    local v24 = p14[2]
    local v25 = p14[3]
    local x, y, z = v23.x, v23.y, v23.z
    local x2, y2, z2 = v24.x, v24.y, v24.z
    local x3, y3, z3 = v25.x, v25.y, v25.z
    local v26 = x3 - x
    local v27 = y3 - y
    local v28 = z3 - z
    local v29 = x2 - x
    local v30 = y2 - y
    local v31 = z2 - z
    local x4, y4, z4 = p13.x, p13.y, p13.z
    local v32 = -z4 * v27 + y4 * v28
    local v33 = -x4 * v28 + z4 * v26
    local v34 = -y4 * v26 + x4 * v27
    local v35 = v29 * v32 + v30 * v33 + v31 * v34

    if not (v35 > 9.99999993922529E-09) then
        return nil
    end

    local x5, y5, z5 = p12.x, p12.y, p12.z
    local v36 = x5 - x
    local v37 = y5 - y
    local v38 = z5 - z
    local v39 = v35 * -9.999999747378752E-06
    local v40 = v35 - v39
    local v41 = v36 * v32 + v37 * v33 + v38 * v34

    if v41 < v39 or v40 < v41 then
        return nil
    end

    local v42 = -v38 * v30 + v37 * v31
    local v43 = -v36 * v31 + v38 * v29
    local v44 = -v37 * v29 + v36 * v30
    local v45 = x4 * v42 + y4 * v43 + z4 * v44

    if v45 < v39 or v40 < v45 + v41 then
        return nil
    end

    local v46 = v26 * v42 + v27 * v43 + v28 * v44

    if v46 < v39 or v40 < v46 then
        return nil
    end

    local v47 = 1 / v35
    local v48 = v46 * v47
    local v49 = x - x2
    local v50 = y - y2
    local v51 = z - z2
    local v52 = x - x3
    local v53 = y - y3
    local v54 = z - z3
    local v55 = -v51 * v53 + v50 * v54
    local v56 = -v49 * v54 + v51 * v52
    local v57 = -v50 * v52 + v49 * v53
    local v58 = inverse_length(v55 * v55 + v56 * v56 + v57 * v57)

    return {
        position = Vector3.new(x4 * v48 + x5, y4 * v48 + y5, z4 * v48 + z5),
        normal = Vector3.new(v55 * v58, v56 * v58, v57 * v58),
        fraction = v48,
        volume_parameter = {
            v41 * v47,
            v45 * v47,
            0
        }
    }
end

function t1.triangle_segment(p15, p16, p17, p18, p19, p20) -- line: 175
    -- upvalues: rt (copy), import (copy), Vector3 (copy), t1 (copy), inverse_length (ref)
    local v59 = p19 + p20

    if v59 == 0 then
        local v60 = t1.thin_triangle(p16, p17, p18)

        if v60 == nil then
            return false
        end

        rt.assign(p15, v60)
    else
        local v61 = p18[1]
        local v62 = p18[2]
        local v63 = p18[3]
        local x, y, z = v61.x, v61.y, v61.z
        local v64 = x - v62.x
        local v65 = y - v62.y
        local v66 = z - v62.z
        local v67 = x - v63.x
        local v68 = y - v63.y
        local v69 = z - v63.z
        local v70 = -v66 * v68 + v65 * v69
        local v71 = -v64 * v69 + v66 * v67
        local v72 = -v65 * v67 + v64 * v68
        local v73 = inverse_length(v70 * v70 + v71 * v71 + v72 * v72)

        p15.normal = Vector3.new(v70 * v73, v71 * v73, v72 * v73)

        if not import("skate_core/physics/triangle_sweep").sweep(p15, p16, p17, p18, v59) then
            return false
        end

        local position, normal = p15.position, p15.normal

        p15.position = Vector3.new(position.x - normal.x * p19, position.y - normal.y * p19, position.z - normal.z * p19)
    end

    return true
end

function t1.triangle_segment_transient(p21, p22, p23, p24, p25, p26) -- line: 222
    -- upvalues: import (copy), Vector3 (copy), t1 (copy)
    local v74 = p25 + p26

    if v74 == 0 then
        local v75 = t1.thin_triangle(p22, p23, p24)

        if v75 == nil then
            return false
        end

        p21.position = v75.position
        p21.normal = v75.normal
        p21.fraction = v75.fraction
        p21.volume_parameter = v75.volume_parameter
    else
        if not import("skate_core/physics/triangle_sweep").sweep_lazy_normal(p21, p22, p23, p24, v74) then
            return false
        end

        local position, normal = p21.position, p21.normal

        p21.position = Vector3.new(position.x - normal.x * p25, position.y - normal.y * p25, position.z - normal.z * p25)
    end

    return true
end

function dot(p27, p28) -- line: 254
    return p27.x * p28.x + p27.y * p28.y + p27.z * p28.z
end

t1.dot = dot

function sub(p29, p30) -- line: 258
    -- upvalues: Vector3 (copy)
    return Vector3.new(p29.x - p30.x, p29.y - p30.y, p29.z - p30.z)
end

t1.sub = sub

function scale(p31, p32) -- line: 262
    -- upvalues: Vector3 (copy)
    return Vector3.new(p31.x * p32, p31.y * p32, p31.z * p32)
end

t1.scale = scale

function madd(p33, p34, p35) -- line: 266
    -- upvalues: Vector3 (copy)
    return Vector3.new(p33.x * p34 + p35.x, p33.y * p34 + p35.y, p33.z * p34 + p35.z)
end

t1.madd = madd

function cross(p36, p37) -- line: 270
    -- upvalues: Vector3 (copy)
    return Vector3.new(-p36.z * p37.y + p36.y * p37.z, -p36.x * p37.z + p36.z * p37.x, -p36.y * p37.x + p36.x * p37.y)
end

t1.cross = cross

function inverse_length(p38) -- line: 274
    -- upvalues: v1 (copy)
    local v76 = v1.reciprocal_square_root_estimate(p38)
    local v77 = v76 * 0.5 * (-p38 * (v76 * v76) + 1) + v76

    return v77 * 0.5 * (-p38 * (v77 * v77) + 1) + v77
end

t1.inverse_length = inverse_length

return t1
