-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local IDENTITY = import("skate_core/physics/skeleton_animation_record").IDENTITY

local function skeleton_body() -- line: 10
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body")
end

local t1 = {
    SkeletonPhysicalRecord = {}
}

function t1.SkeletonPhysicalRecord.default() -- line: 31
    -- upvalues: rt (copy), import (copy), IDENTITY (copy)
    local PART_COUNT = import("skate_core/physics/skeleton_body").PART_COUNT

    return {
        timestep = 0,
        pose = rt.filled(PART_COUNT, IDENTITY),
        positions = rt.filled(PART_COUNT, table.create(4, 0)),
        velocities = rt.filled(PART_COUNT, table.create(4, 0)),
        velocity_changes = rt.filled(PART_COUNT, table.create(4, 0)),
        centre_of_mass = table.create(4, 0),
        centre_of_mass_velocity = table.create(4, 0)
    }
end

function t1.SkeletonPhysicalRecord.reset(p1, p2) -- line: 48
    -- upvalues: rt (copy)
    p1.pose = rt.copy(p2)

    for i = 0, #p2 - 1 do
        local v1 = p2[i + 1]

        p1.positions[i + 1] = rt.copy(v1[4])
        p1.velocities[i + 1] = table.create(4, 0)
    end
end

function t1.SkeletonPhysicalRecord.update(p3, p4, p5, p6) -- line: 110
    -- upvalues: rt (copy)
    p3.timestep = 0.01666666753590107

    local pose = p3.pose

    for i = 0, #p4 - 1 do
        local v2 = p4[i + 1]

        if i == 0 then
            v2 = p5
        end

        local v3 = pose[i + 1]
        local v4

        if #v2 ~= 4 or type(v3) ~= "table" or v3 == v2 then
            v4 = false
        elseif #v3 == 4 then
            local v5 = v2[1]
            local v6 = v2[2]
            local v7 = v2[3]
            local v8 = v2[4]
            local v9 = v3[1]
            local v10 = v3[2]
            local v11 = v3[3]
            local v12 = v3[4]

            if type(v9) == "table" and type(v10) == "table" and type(v11) == "table" and type(v12) == "table" and #v5 == 4 and #v6 == 4 and #v7 == 4 and #v8 == 4 and #v9 == 4 and #v10 == 4 and #v11 == 4 and #v12 == 4 then
                local v13 = v5[1]
                local v14 = v5[2]
                local v15 = v5[3]
                local v16 = v5[4]

                v9[1] = v13
                v9[2] = v14
                v9[3] = v15
                v9[4] = v16

                local v17 = v6[1]
                local v18 = v6[2]
                local v19 = v6[3]
                local v20 = v6[4]

                v10[1] = v17
                v10[2] = v18
                v10[3] = v19
                v10[4] = v20

                local v21 = v7[1]
                local v22 = v7[2]
                local v23 = v7[3]
                local v24 = v7[4]

                v11[1] = v21
                v11[2] = v22
                v11[3] = v23
                v11[4] = v24

                local v25 = v8[1]
                local v26 = v8[2]
                local v27 = v8[3]
                local v28 = v8[4]

                v12[1] = v25
                v12[2] = v26
                v12[3] = v27
                v4 = true
                v12[4] = v28
            else
                v4 = false
            end
        else
            v4 = false
        end

        if not v4 then
            v3 = if #v2 == 4 then {
                table.clone(v2[1]),
                table.clone(v2[2]),
                table.clone(v2[3]),
                table.clone(v2[4])
            } else rt.copy(v2)
            pose[i + 1] = v3
        end

        local v30 = p3.positions[i + 1]
        local v31 = p3.velocities[i + 1]
        local v32 = p3.velocity_changes[i + 1]
        local v33 = v3[4]
        local v34 = (v33[1] - v30[1]) * 59.999996185302734

        v32[1] = v34 - v31[1]
        v31[1] = v34

        local v35 = (v33[2] - v30[2]) * 59.999996185302734

        v32[2] = v35 - v31[2]
        v31[2] = v35

        local v36 = (v33[3] - v30[3]) * 59.999996185302734

        v32[3] = v36 - v31[3]
        v31[3] = v36

        local v37 = (v33[4] - v30[4]) * 59.999996185302734

        v32[4] = v37 - v31[4]
        v31[4] = v37

        if #v30 == 4 and #v33 == 4 and v30 ~= v33 and v30 ~= v31 and v30 ~= v32 then
            local v38 = v33[1]
            local v39 = v33[2]
            local v40 = v33[3]
            local v41 = v33[4]

            v30[1] = v38
            v30[2] = v39
            v30[3] = v40
            v30[4] = v41
            continue
        end

        p3.positions[i + 1] = table.clone(v33)
    end

    local v42 = #p6 - 1
    local n1 = 0
    local n2 = 0
    local n3 = 0
    local n4 = 0
    local n5 = 0
    local n6 = 0
    local n7 = 0
    local n8 = 0

    for i = 0, v42 do
        local v43 = p6[i + 1]
        local v44 = pose[i + 1][4]
        local v45 = p3.velocities[i + 1]

        n1 = v44[1] * v43 + n1
        n5 = v45[1] * v43 + n5
        n2 = v44[2] * v43 + n2
        n6 = v45[2] * v43 + n6
        n3 = v44[3] * v43 + n3
        n7 = v45[3] * v43 + n7
        n4 = v44[4] * v43 + n4
        n8 = v45[4] * v43 + n8
    end

    local centre_of_mass, centre_of_mass_velocity = p3.centre_of_mass, p3.centre_of_mass_velocity

    if type(centre_of_mass) ~= "table" or type(centre_of_mass_velocity) ~= "table" or centre_of_mass == centre_of_mass_velocity or #centre_of_mass ~= 4 or #centre_of_mass_velocity ~= 4 then
        p3.centre_of_mass = { n1, n2, n3, n4 }
        p3.centre_of_mass_velocity = { n5, n6, n7, n8 }

        return
    end

    centre_of_mass[1] = n1
    centre_of_mass[2] = n2
    centre_of_mass[3] = n3
    centre_of_mass[4] = n4
    centre_of_mass_velocity[1] = n5
    centre_of_mass_velocity[2] = n6
    centre_of_mass_velocity[3] = n7
    centre_of_mass_velocity[4] = n8
end

function t1.SkeletonPhysicalRecord.update_reference(p7, p8, p9, p10) -- line: 214
    -- upvalues: rt (copy)
    p7.timestep = 0.01666666753590107

    for i = 0, #p8 - 1 do
        local v46 = p8[i + 1]
        local v47 = if i == 0 then rt.copy(p9) else rt.copy(v46)

        p7.pose[i + 1] = v47

        local v48 = p7.positions[i + 1]
        local v49 = p7.velocities[i + 1]
        local v50 = p7.velocity_changes[i + 1]
        local v51 = (v47[4][1] - v48[1]) * 59.999996185302734

        v50[1] = v51 - v49[1]
        v49[1] = v51

        local v52 = (v47[4][2] - v48[2]) * 59.999996185302734

        v50[2] = v52 - v49[2]
        v49[2] = v52

        local v53 = (v47[4][3] - v48[3]) * 59.999996185302734

        v50[3] = v53 - v49[3]
        v49[3] = v53

        local v54 = (v47[4][4] - v48[4]) * 59.999996185302734

        v50[4] = v54 - v49[4]
        v49[4] = v54
        p7.positions[i + 1] = rt.copy(v47[4])
    end

    local v55 = table.create(4, 0)
    local v56 = table.create(4, 0)

    for i = 0, #p10 - 1 do
        local v57 = p10[i + 1]

        for j = 0, 3 do
            v55[j + 1] = p7.pose[i + 1][4][j + 1] * v57 + v55[j + 1]
            v56[j + 1] = p7.velocities[i + 1][j + 1] * v57 + v56[j + 1]
        end
    end

    p7.centre_of_mass = v55
    p7.centre_of_mass_velocity = v56
end

return t1
