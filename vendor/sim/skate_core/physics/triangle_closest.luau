-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local v2 = require(sim.import)("skate_core/physics/triangle_query")
local dot, madd, sub = v2.dot, v2.madd, v2.sub
local t1 = {
    ClosestTrianglePoint = {}
}

function t1.closest(p2, p3) -- line: 28
    -- upvalues: v1 (copy), dot (copy), madd (copy), sub (copy)
    local v3 = p3[1]
    local v4 = p3[2]
    local v5 = p3[3]
    local v6 = sub(v4, v3)
    local v7 = sub(v5, v3)
    local v8 = sub(v3, p2)
    local v9 = dot(v6, v6)
    local v10 = dot(v7, v7)
    local v11 = dot(v6, v7)
    local v12 = dot(v6, v8)
    local v13 = dot(v7, v8)
    local v14 = v10 * v9 + -(v11 * v11)
    local v15 = v13 * v11 + -(v12 * v10)
    local v16 = v12 * v11 + -(v13 * v9)
    local v17 = -v11 * 2 + v9 + v10

    buffer.writeu32(v1, 0, 2097152)

    local v18 = if v14 < buffer.readf32(v1, 0) then if v10 < v9 then if v17 < v9 then 0 else 2 elseif v17 < v10 then 1 else 2
        elseif v14 < v15 + v16 then if v15 < 0 then if v13 + v10 < v12 + v11 then 1 else 2 elseif v16 < 0 and v12 + v9 < v13 + v11 then 0 else 2
        elseif v15 < 0 then if -v13 > 0 then 1 else 0
        elseif not (v16 < 0) then 3
        elseif -v12 > 0 then 0
        else 1
    local v19, v20, v21

    if v18 == 0 then
        if v12 < 0 then
            if -v12 < v9 then
                v20 = -(v12 / v9)
                v19 = 0
                v21 = 3
            else
                v20 = 1
                v19 = 0
                v21 = 1
            end
        else
            v20 = 0
            v19 = 0
            v21 = 0
        end
    elseif v18 == 1 then
        v20 = 0

        if v13 < 0 then
            if -v13 < v10 then
                v19 = -(v13 / v10)
                v21 = 4
            else
                v19 = 1
                v21 = 2
            end
        else
            v19 = 0
            v21 = 0
        end
    elseif v18 == 2 then
        local v22 = v13 + v10 - v11 - v12

        if v22 > 0 then
            if v22 < v17 then
                v20 = v22 / v17
                v19 = 1 - v20
                v21 = 5
            else
                v20 = 1
                v19 = 0
                v21 = 1
            end
        else
            v20 = 0
            v19 = 1
            v21 = 2
        end
    else
        local v23 = 1 / v14

        v20 = v23 * v15
        v19 = v23 * v16
        v21 = 6
    end

    return {
        point = madd(v7, v19, madd(v6, v20, v3)),
        region = v21,
        u = v20,
        v = v19
    }
end

buffer.writeu32(v1, 0, 2097152)

local v24 = buffer.readf32(v1, 0)

function t1.closest_xyz(p4, p5, p6, p7) -- line: 130
    -- upvalues: v24 (copy)
    local v25 = p7[1]
    local v26 = p7[2]
    local v27 = p7[3]
    local x, y, z = v25.x, v25.y, v25.z
    local v28 = v26.x - x
    local v29 = v26.y - y
    local v30 = v26.z - z
    local v31 = v27.x - x
    local v32 = v27.y - y
    local v33 = v27.z - z
    local v34 = x - p4
    local v35 = y - p5
    local v36 = z - p6
    local v37 = v28 * v28 + v29 * v29 + v30 * v30
    local v38 = v31 * v31 + v32 * v32 + v33 * v33
    local v39 = v28 * v31 + v29 * v32 + v30 * v33
    local v40 = v28 * v34 + v29 * v35 + v30 * v36
    local v41 = v31 * v34 + v32 * v35 + v33 * v36
    local v42 = v38 * v37 + -(v39 * v39)
    local v43 = v41 * v39 + -(v40 * v38)
    local v44 = v40 * v39 + -(v41 * v37)
    local v45 = -v39 * 2 + v37 + v38
    local v46 = if v42 < v24 then if v38 < v37 then if v45 < v37 then 0 else 2 elseif v45 < v38 then 1 else 2
        elseif v42 < v43 + v44 then if v43 < 0 then if v41 + v38 < v40 + v39 then 1 else 2 elseif v44 < 0 and v40 + v37 < v41 + v39 then 0 else 2
        elseif v43 < 0 then if -v41 > 0 then 1 else 0
        elseif not (v44 < 0) then 3
        elseif -v40 > 0 then 0
        else 1
    local v47, v48, v49

    if v46 == 0 then
        if v40 < 0 then
            if -v40 < v37 then
                v48 = -(v40 / v37)
                v47 = 0
                v49 = 3
            else
                v48 = 1
                v47 = 0
                v49 = 1
            end
        else
            v48 = 0
            v47 = 0
            v49 = 0
        end
    elseif v46 == 1 then
        v48 = 0

        if v41 < 0 then
            if -v41 < v38 then
                v47 = -(v41 / v38)
                v49 = 4
            else
                v47 = 1
                v49 = 2
            end
        else
            v47 = 0
            v49 = 0
        end
    elseif v46 == 2 then
        local v50 = v41 + v38 - v39 - v40

        if v50 > 0 then
            if v50 < v45 then
                v48 = v50 / v45
                v47 = 1 - v48
                v49 = 5
            else
                v48 = 1
                v47 = 0
                v49 = 1
            end
        else
            v48 = 0
            v47 = 1
            v49 = 2
        end
    else
        local v51 = 1 / v42

        v48 = v51 * v43
        v47 = v51 * v44
        v49 = 6
    end

    return v31 * v47 + (v28 * v48 + x), v32 * v47 + (v29 * v48 + y), v33 * v47 + (v30 * v48 + z), v49, v48, v47
end

return t1
