-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/physics/point_force")
local t1 = {
    FORCE_CAPACITY = 21,
    QueuedPointForce = {}
}

function t1.QueuedPointForce.default() -- line: 21
    -- upvalues: Vector3 (copy)
    return {
        tag = 0,
        force_world = Vector3.default(),
        point_body = Vector3.default()
    }
end

t1.BoardForceQueue = {}

function t1.BoardForceQueue.default() -- line: 32
    -- upvalues: rt (copy), t1 (copy)
    return {
        count = 0,
        entries = rt.filled(t1.FORCE_CAPACITY, t1.QueuedPointForce.default())
    }
end

local v2 = rt.filled(t1.FORCE_CAPACITY, t1.QueuedPointForce.default())

local function is_xyz(p1) -- line: 67
    local n1 = 0

    for v3 in p1 do
        if v3 ~= "x" and v3 ~= "y" and v3 ~= "z" then
            return false
        end

        n1 += 1
    end

    return n1 == 3
end

function t1.BoardForceQueue.append(p2, p3) -- line: 78
    -- upvalues: rt (copy), t1 (copy), v2 (copy)
    local count = p2.count

    if count == t1.FORCE_CAPACITY then
        return false
    end

    local entries = p2.entries

    if entries == v2 then
        entries = rt.filled(t1.FORCE_CAPACITY, t1.QueuedPointForce.default())
        p2.entries = entries
    end

    local v4 = entries[count + 1]
    local force_world, point_body

    if type(p3) == "table" then
        force_world = p3.force_world
        point_body = p3.point_body
    end

    local force_world2, point_body2

    if type(v4) == "table" then
        force_world2 = v4.force_world
        point_body2 = v4.point_body
    end

    local v5

    if type(force_world2) ~= "table"
        or type(point_body2) ~= "table"
        or type(force_world) ~= "table"
        or type(point_body) ~= "table"
        or v4 == p3
        or force_world2 == force_world
        or force_world2 == point_body
        or point_body2 == force_world
        or point_body2 == point_body
        or force_world2 == point_body2 then
        v5 = false
    else
        local n2 = 0
        local v6 = false
        local v7

        for v8 in force_world do
            if v8 ~= "x" and v8 ~= "y" and v8 ~= "z" then
                v7 = false
                v6 = true
                break
            end

            n2 += 1
        end

        if not v6 then
            v7 = n2 == 3
        end

        if v7 then
            local n3 = 0
            local v9 = false
            local v10

            for v11 in point_body do
                if v11 ~= "x" and v11 ~= "y" and v11 ~= "z" then
                    v10 = false
                    v9 = true
                    break
                end

                n3 += 1
            end

            if not v9 then
                v10 = n3 == 3
            end

            if v10 then
                local n4 = 0
                local v12 = false
                local v13

                for v14 in force_world2 do
                    if v14 ~= "x" and v14 ~= "y" and v14 ~= "z" then
                        v13 = false
                        v12 = true
                        break
                    end

                    n4 += 1
                end

                if not v12 then
                    v13 = n4 == 3
                end

                if v13 then
                    local n5 = 0
                    local v15 = false

                    for v16 in point_body2 do
                        if v16 ~= "x" and v16 ~= "y" and v16 ~= "z" then
                            v5 = false
                            v15 = true
                            break
                        end

                        n5 += 1
                    end

                    if not v15 then
                        v5 = n5 == 3
                    end
                else
                    v5 = v13
                end
            else
                v5 = v10
            end
        else
            v5 = v7
        end
    end

    if v5 then
        for v17 in p3 do
            if v17 ~= "tag" and v17 ~= "force_world" and v17 ~= "point_body" then
                v5 = false
                break
            end
        end
    end

    if v5 then
        for v18 in v4 do
            if v18 ~= "tag" and v18 ~= "force_world" and v18 ~= "point_body" then
                v5 = false
                break
            end
        end
    end

    if v5 then
        v4.tag = p3.tag

        local x, y, z = force_world.x, force_world.y, force_world.z

        force_world2.x = x
        force_world2.y = y
        force_world2.z = z

        local x2, y2, z2 = point_body.x, point_body.y, point_body.z

        point_body2.x = x2
        point_body2.y = y2
        point_body2.z = z2
    else
        entries[count + 1] = rt.copy(p3)
    end

    p2.count = count + 1

    return true
end

function t1.BoardForceQueue.append_reference(p4, p5) -- line: 142
    -- upvalues: rt (copy), t1 (copy), v2 (copy)
    if p4.count == t1.FORCE_CAPACITY then
        return false
    end

    if p4.entries == v2 then
        p4.entries = rt.filled(t1.FORCE_CAPACITY, t1.QueuedPointForce.default())
    end

    p4.entries[p4.count + 1] = rt.copy(p5)
    p4.count += 1

    return true
end

function t1.BoardForceQueue.entries(p6) -- line: 155
    -- upvalues: rt (copy)
    return rt.slice(p6.entries, 0, p6.count)
end

function t1.BoardForceQueue.take(p7) -- line: 164
    -- upvalues: v2 (copy)
    local t2 = {
        entries = p7.entries,
        count = p7.count
    }

    p7.entries = v2
    p7.count = 0

    return t2
end

function t1.BoardForceQueue.restore(p8, p9) -- line: 176
    p8.entries = p9.entries
    p8.count = p9.count
end

function t1.BoardForceQueue.is_emptied(p10) -- line: 182
    -- upvalues: v2 (copy)
    return p10.entries == v2
end

function t1.BoardForceQueue.apply_to_deck(p11, p12, p13, p14, p15, p16) -- line: 200
    -- upvalues: rt (copy)
    local v19 = rt.copy(p12)
    local count = p11.count

    if count ~= 0 then
        local force_acceleration, torque_acceleration = v19.force_acceleration, v19.torque_acceleration
        local v20, v21, v22 = force_acceleration.x, force_acceleration.y, force_acceleration.z
        local v23, v24, v25 = torque_acceleration.x, torque_acceleration.y, torque_acceleration.z
        local columns = p13.columns
        local v26 = columns[1]
        local v27 = columns[2]
        local v28 = columns[3]
        local v29 = v26[1]
        local v30 = v26[2]
        local v31 = v26[3]
        local v32 = v27[1]
        local v33 = v27[2]
        local v34 = v27[3]
        local v35 = v28[1]
        local v36 = v28[2]
        local v37 = v28[3]
        local columns2 = p15.columns
        local v38 = columns2[1]
        local v39 = columns2[2]
        local v40 = columns2[3]
        local v41 = v38[1]
        local v42 = v38[2]
        local v43 = v38[3]
        local v44 = v39[1]
        local v45 = v39[2]
        local v46 = v39[3]
        local v47 = v40[1]
        local v48 = v40[2]
        local v49 = v40[3]
        local entries = p11.entries

        for i = 1, count do
            local v50 = entries[i]
            local force_world, point_body = v50.force_world, v50.point_body
            local x, y, z = force_world.x, force_world.y, force_world.z
            local v51 = point_body.x + 0
            local v52 = point_body.y + p16
            local v53 = point_body.z + 0

            v20 += x * p14
            v21 += y * p14
            v22 += z * p14

            local v54 = v35 * v53 + (v32 * v52 + v29 * v51)
            local v55 = v36 * v53 + (v33 * v52 + v30 * v51)
            local v56 = v37 * v53 + (v34 * v52 + v31 * v51)
            local v57 = -v56 * y + v55 * z
            local v58 = -v54 * z + v56 * x
            local v59 = -v55 * x + v54 * y

            v23 += v47 * v59 + (v44 * v58 + v41 * v57)
            v24 += v48 * v59 + (v45 * v58 + v42 * v57)
            v25 += v49 * v59 + (v46 * v58 + v43 * v57)
        end

        force_acceleration.x = v20
        force_acceleration.y = v21
        force_acceleration.z = v22
        torque_acceleration.x = v23
        torque_acceleration.y = v24
        torque_acceleration.z = v25
        v19.cool_down = 0
    end

    return v19
end

function t1.BoardForceQueue.apply_to_deck_reference(p17, p18, p19, p20, p21, p22) -- line: 262
    -- upvalues: rt (copy), Vector3 (copy), v1 (copy), t1 (copy)
    local v60 = rt.copy(p18)

    for _, v61 in ipairs(t1.BoardForceQueue.entries(p17)) do
        local v62 = Vector3.new(v61.point_body.x + 0, v61.point_body.y + p22, v61.point_body.z + 0)

        v60 = v1.accumulate_point_force_reference(v60, v61.force_world, v62, p19, p20, p21)
    end

    return v60
end

function t1.BoardForceQueue.clear(p23) -- line: 291
    p23.count = 0
end

function t1.total_body_mass(p24) -- line: 298
    -- upvalues: rt (copy)
    local v63 = #p24
    local v64 = rt.idiv(v63, 2)
    local v65 = v64 - 1
    local n6 = 0
    local n7 = 0

    for i = 0, v65 do
        n6 = 1 / p24[i * 2 + 1] + n6
        n7 = 1 / p24[i * 2 + 2] + n7
    end

    return n7 + n6 + (if v64 * 2 < v63 then 1 / p24[v64 * 2 + 1] else 0)
end

return t1
