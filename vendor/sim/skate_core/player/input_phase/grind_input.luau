-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local t1 = {
    GrindInvestigationFields = {}
}

function t1.GrindInvestigationFields.default() -- line: 15
    -- upvalues: rt (copy)
    return {
        tangent_1104 = table.create(4, 0),
        point_1120 = table.create(4, 0),
        direction_1136 = table.create(4, 0),
        normal_1152 = table.create(4, 0),
        target_up_1168 = table.create(4, 0),
        entry_velocity_1184 = table.create(4, 0),
        front_contact_1200 = table.create(4, 0),
        rear_contact_1216 = table.create(4, 0),
        vector_1232 = table.create(4, 0),
        family_1248 = 0,
        entry_kind_1252 = 0,
        primitive_start_1264 = table.create(4, 0),
        primitive_end_1280 = table.create(4, 0),
        owner_1296 = nil,
        primitive_flags_1300 = 0,
        second_start_1312 = table.create(4, 0),
        second_end_1328 = table.create(4, 0),
        second_owner_1344 = nil,
        second_flags_1348 = 0,
        center_1360 = table.create(4, 0),
        far_points_1376_1392 = rt.filled(2, table.create(4, 0)),
        upmost_normal_1408 = table.create(4, 0),
        surface_direction_1424 = table.create(4, 0),
        high_side_1440 = table.create(4, 0),
        normal_limits_1456_1460 = table.create(2, 0),
        geometry_kind_1464 = 0,
        audio_surface_1468 = 0,
        physics_surface_1472 = 0,
        geometry_flags_1476 = 0,
        valid_1488 = false,
        impact_speed_1492 = 0,
        friction_1496 = 0,
        exit_lean_1500 = 0,
        yaw_1504 = 0,
        pitch_1508 = 0,
        gravity_relief_1512 = 0,
        flags_1516 = 0
    }
end

local v1, t2, t3, t4

local function prepare() -- line: 67
    -- upvalues: import (copy), t1 (copy), v1 (ref), t2 (ref), t3 (ref), t4 (ref)
    v1 = import("skate_core/player/input_phase/types")

    local t5 = {}
    local t6 = {}
    local t7 = {}
    local t8 = {}

    for v2 in t1.GrindInvestigationFields.default() do
        table.insert(t8, v2)
    end

    table.sort(t8)

    local v3 = t1.GrindInvestigationFields.default()

    for _, v4 in t8 do
        local v5 = v3[v4]

        if type(v5) == "table" then
            if #v5 == 4 then
                if type(v5[1]) == "number" then
                    table.insert(t6, v4)
                else
                    table.insert(t7, v4)
                end
            else
                table.insert(t7, v4)
            end
        else
            table.insert(t5, v4)
        end
    end

    table.insert(t5, "owner_1296")
    table.insert(t5, "second_owner_1344")
    t2 = t5
    t3 = t6
    t4 = t7
end

local v7 = false

function t1.GrindInvestigationFields.set_w2(p1) -- line: 107
    -- upvalues: v7 (ref)
    v7 = p1
end

local t9 = {
    "family_1248",
    "entry_kind_1252",
    "primitive_flags_1300",
    "second_flags_1348",
    "geometry_kind_1464",
    "audio_surface_1468",
    "physics_surface_1472",
    "geometry_flags_1476",
    "valid_1488",
    "impact_speed_1492",
    "friction_1496",
    "exit_lean_1500",
    "yaw_1504",
    "pitch_1508",
    "gravity_relief_1512",
    "flags_1516",
    "owner_1296",
    "second_owner_1344"
}
local t10 = {
    "tangent_1104",
    "point_1120",
    "direction_1136",
    "normal_1152",
    "target_up_1168",
    "entry_velocity_1184",
    "front_contact_1200",
    "rear_contact_1216",
    "vector_1232",
    "primitive_start_1264",
    "primitive_end_1280",
    "second_start_1312",
    "second_end_1328",
    "center_1360",
    "upmost_normal_1408",
    "surface_direction_1424",
    "high_side_1440"
}
local t11 = {
    "far_points_1376_1392",
    "normal_limits_1456_1460"
}
local v8 = false

local function check_lists() -- line: 114
    -- upvalues: t2 (ref), t3 (ref), t4 (ref), prepare (copy), t9 (copy), t10 (copy), t11 (copy), v8 (ref)
    if t2 == nil then
        prepare()
    end

    local function same_set(p2, p3, p4) -- line: 118
        local t12 = {}

        for _, v9 in p2 do
            t12[v9] = true
        end

        for _, v10 in p3 do
            if not t12[v10] then
                error("GrindInvestigationFields.assign_into: the written-out " .. p4 .. " list lacks " .. v10, 0)
            end

            t12[v10] = nil
        end

        if next(t12) == nil then
            return
        end

        error("GrindInvestigationFields.assign_into: the written-out " .. p4 .. " list has a key too many: " .. tostring(next(t12)), 0)
    end

    same_set(t9, t2, "scalar")
    same_set(t10, t3, "vector")
    same_set(t11, t4, "table")
    v8 = true
end

function t1.GrindInvestigationFields.assign_into(p5, p6) -- line: 138
    -- upvalues: t1 (copy), v1 (ref), v7 (ref), v8 (ref), check_lists (copy)
    if not v8 then
        check_lists()
    end

    if v7 or v1.general() or p5 == p6 then
        return t1.GrindInvestigationFields.assign_into_w2(p5, p6)
    end

    p5.family_1248 = p6.family_1248
    p5.entry_kind_1252 = p6.entry_kind_1252
    p5.primitive_flags_1300 = p6.primitive_flags_1300
    p5.second_flags_1348 = p6.second_flags_1348
    p5.geometry_kind_1464 = p6.geometry_kind_1464
    p5.audio_surface_1468 = p6.audio_surface_1468
    p5.physics_surface_1472 = p6.physics_surface_1472
    p5.geometry_flags_1476 = p6.geometry_flags_1476
    p5.valid_1488 = p6.valid_1488
    p5.impact_speed_1492 = p6.impact_speed_1492
    p5.friction_1496 = p6.friction_1496
    p5.exit_lean_1500 = p6.exit_lean_1500
    p5.yaw_1504 = p6.yaw_1504
    p5.pitch_1508 = p6.pitch_1508
    p5.gravity_relief_1512 = p6.gravity_relief_1512
    p5.flags_1516 = p6.flags_1516
    p5.owner_1296 = p6.owner_1296
    p5.second_owner_1344 = p6.second_owner_1344

    local copy_into = v1.copy_into
    local tangent_1104 = p5.tangent_1104
    local tangent_1104_2 = p6.tangent_1104

    if type(tangent_1104_2) ~= "table" or type(tangent_1104) ~= "table" or tangent_1104 == tangent_1104_2 then
        copy_into(p5, "tangent_1104", tangent_1104_2)
    elseif #tangent_1104 == 4 and #tangent_1104_2 == 4 then
        if type(tangent_1104_2[1]) == "number" then
            local v12 = tangent_1104_2[1]
            local v13 = tangent_1104_2[2]
            local v14 = tangent_1104_2[3]
            local v15 = tangent_1104_2[4]

            tangent_1104[1] = v12
            tangent_1104[2] = v13
            tangent_1104[3] = v14
            tangent_1104[4] = v15
        else
            copy_into(p5, "tangent_1104", tangent_1104_2)
        end
    else
        copy_into(p5, "tangent_1104", tangent_1104_2)
    end

    local point_1120 = p5.point_1120
    local point_1120_2 = p6.point_1120

    if type(point_1120_2) == "table" and type(point_1120) == "table" and point_1120 ~= point_1120_2 and #point_1120 == 4 and #point_1120_2 == 4 and type(point_1120_2[1]) == "number" then
        local v18 = point_1120_2[1]
        local v19 = point_1120_2[2]
        local v20 = point_1120_2[3]
        local v21 = point_1120_2[4]

        point_1120[1] = v18
        point_1120[2] = v19
        point_1120[3] = v20
        point_1120[4] = v21
    else
        copy_into(p5, "point_1120", point_1120_2)
    end

    local direction_1136 = p5.direction_1136
    local direction_1136_2 = p6.direction_1136

    if type(direction_1136_2) == "table" and type(direction_1136) == "table" and direction_1136 ~= direction_1136_2 and #direction_1136 == 4 and #direction_1136_2 == 4 and type(direction_1136_2[1]) == "number" then
        local v24 = direction_1136_2[1]
        local v25 = direction_1136_2[2]
        local v26 = direction_1136_2[3]
        local v27 = direction_1136_2[4]

        direction_1136[1] = v24
        direction_1136[2] = v25
        direction_1136[3] = v26
        direction_1136[4] = v27
    else
        copy_into(p5, "direction_1136", direction_1136_2)
    end

    local normal_1152 = p5.normal_1152
    local normal_1152_2 = p6.normal_1152

    if type(normal_1152_2) == "table" and type(normal_1152) == "table" and normal_1152 ~= normal_1152_2 and #normal_1152 == 4 and #normal_1152_2 == 4 and type(normal_1152_2[1]) == "number" then
        local v30 = normal_1152_2[1]
        local v31 = normal_1152_2[2]
        local v32 = normal_1152_2[3]
        local v33 = normal_1152_2[4]

        normal_1152[1] = v30
        normal_1152[2] = v31
        normal_1152[3] = v32
        normal_1152[4] = v33
    else
        copy_into(p5, "normal_1152", normal_1152_2)
    end

    local target_up_1168 = p5.target_up_1168
    local target_up_1168_2 = p6.target_up_1168

    if type(target_up_1168_2) == "table" and type(target_up_1168) == "table" and target_up_1168 ~= target_up_1168_2 and #target_up_1168 == 4 and #target_up_1168_2 == 4 and type(target_up_1168_2[1]) == "number" then
        local v36 = target_up_1168_2[1]
        local v37 = target_up_1168_2[2]
        local v38 = target_up_1168_2[3]
        local v39 = target_up_1168_2[4]

        target_up_1168[1] = v36
        target_up_1168[2] = v37
        target_up_1168[3] = v38
        target_up_1168[4] = v39
    else
        copy_into(p5, "target_up_1168", target_up_1168_2)
    end

    local entry_velocity_1184 = p5.entry_velocity_1184
    local entry_velocity_1184_2 = p6.entry_velocity_1184

    if type(entry_velocity_1184_2) == "table" and type(entry_velocity_1184) == "table" and entry_velocity_1184 ~= entry_velocity_1184_2 and #entry_velocity_1184 == 4 and #entry_velocity_1184_2 == 4 and type(entry_velocity_1184_2[1]) == "number" then
        local v42 = entry_velocity_1184_2[1]
        local v43 = entry_velocity_1184_2[2]
        local v44 = entry_velocity_1184_2[3]
        local v45 = entry_velocity_1184_2[4]

        entry_velocity_1184[1] = v42
        entry_velocity_1184[2] = v43
        entry_velocity_1184[3] = v44
        entry_velocity_1184[4] = v45
    else
        copy_into(p5, "entry_velocity_1184", entry_velocity_1184_2)
    end

    local front_contact_1200 = p5.front_contact_1200
    local front_contact_1200_2 = p6.front_contact_1200

    if type(front_contact_1200_2) == "table" and type(front_contact_1200) == "table" and front_contact_1200 ~= front_contact_1200_2 and #front_contact_1200 == 4 and #front_contact_1200_2 == 4 and type(front_contact_1200_2[1]) == "number" then
        local v48 = front_contact_1200_2[1]
        local v49 = front_contact_1200_2[2]
        local v50 = front_contact_1200_2[3]
        local v51 = front_contact_1200_2[4]

        front_contact_1200[1] = v48
        front_contact_1200[2] = v49
        front_contact_1200[3] = v50
        front_contact_1200[4] = v51
    else
        copy_into(p5, "front_contact_1200", front_contact_1200_2)
    end

    local rear_contact_1216 = p5.rear_contact_1216
    local rear_contact_1216_2 = p6.rear_contact_1216

    if type(rear_contact_1216_2) == "table" and type(rear_contact_1216) == "table" and rear_contact_1216 ~= rear_contact_1216_2 and #rear_contact_1216 == 4 and #rear_contact_1216_2 == 4 and type(rear_contact_1216_2[1]) == "number" then
        local v54 = rear_contact_1216_2[1]
        local v55 = rear_contact_1216_2[2]
        local v56 = rear_contact_1216_2[3]
        local v57 = rear_contact_1216_2[4]

        rear_contact_1216[1] = v54
        rear_contact_1216[2] = v55
        rear_contact_1216[3] = v56
        rear_contact_1216[4] = v57
    else
        copy_into(p5, "rear_contact_1216", rear_contact_1216_2)
    end

    local vector_1232 = p5.vector_1232
    local vector_1232_2 = p6.vector_1232

    if type(vector_1232_2) == "table" and type(vector_1232) == "table" and vector_1232 ~= vector_1232_2 and #vector_1232 == 4 and #vector_1232_2 == 4 and type(vector_1232_2[1]) == "number" then
        local v60 = vector_1232_2[1]
        local v61 = vector_1232_2[2]
        local v62 = vector_1232_2[3]
        local v63 = vector_1232_2[4]

        vector_1232[1] = v60
        vector_1232[2] = v61
        vector_1232[3] = v62
        vector_1232[4] = v63
    else
        copy_into(p5, "vector_1232", vector_1232_2)
    end

    local primitive_start_1264 = p5.primitive_start_1264
    local primitive_start_1264_2 = p6.primitive_start_1264

    if type(primitive_start_1264_2) == "table" and type(primitive_start_1264) == "table" and primitive_start_1264 ~= primitive_start_1264_2 and #primitive_start_1264 == 4 and #primitive_start_1264_2 == 4 and type(primitive_start_1264_2[1]) == "number" then
        local v66 = primitive_start_1264_2[1]
        local v67 = primitive_start_1264_2[2]
        local v68 = primitive_start_1264_2[3]
        local v69 = primitive_start_1264_2[4]

        primitive_start_1264[1] = v66
        primitive_start_1264[2] = v67
        primitive_start_1264[3] = v68
        primitive_start_1264[4] = v69
    else
        copy_into(p5, "primitive_start_1264", primitive_start_1264_2)
    end

    local primitive_end_1280 = p5.primitive_end_1280
    local primitive_end_1280_2 = p6.primitive_end_1280

    if type(primitive_end_1280_2) == "table" and type(primitive_end_1280) == "table" and primitive_end_1280 ~= primitive_end_1280_2 and #primitive_end_1280 == 4 and #primitive_end_1280_2 == 4 and type(primitive_end_1280_2[1]) == "number" then
        local v72 = primitive_end_1280_2[1]
        local v73 = primitive_end_1280_2[2]
        local v74 = primitive_end_1280_2[3]
        local v75 = primitive_end_1280_2[4]

        primitive_end_1280[1] = v72
        primitive_end_1280[2] = v73
        primitive_end_1280[3] = v74
        primitive_end_1280[4] = v75
    else
        copy_into(p5, "primitive_end_1280", primitive_end_1280_2)
    end

    local second_start_1312 = p5.second_start_1312
    local second_start_1312_2 = p6.second_start_1312

    if type(second_start_1312_2) == "table" and type(second_start_1312) == "table" and second_start_1312 ~= second_start_1312_2 and #second_start_1312 == 4 and #second_start_1312_2 == 4 and type(second_start_1312_2[1]) == "number" then
        local v78 = second_start_1312_2[1]
        local v79 = second_start_1312_2[2]
        local v80 = second_start_1312_2[3]
        local v81 = second_start_1312_2[4]

        second_start_1312[1] = v78
        second_start_1312[2] = v79
        second_start_1312[3] = v80
        second_start_1312[4] = v81
    else
        copy_into(p5, "second_start_1312", second_start_1312_2)
    end

    local second_end_1328 = p5.second_end_1328
    local second_end_1328_2 = p6.second_end_1328

    if type(second_end_1328_2) == "table" and type(second_end_1328) == "table" and second_end_1328 ~= second_end_1328_2 and #second_end_1328 == 4 and #second_end_1328_2 == 4 and type(second_end_1328_2[1]) == "number" then
        local v84 = second_end_1328_2[1]
        local v85 = second_end_1328_2[2]
        local v86 = second_end_1328_2[3]
        local v87 = second_end_1328_2[4]

        second_end_1328[1] = v84
        second_end_1328[2] = v85
        second_end_1328[3] = v86
        second_end_1328[4] = v87
    else
        copy_into(p5, "second_end_1328", second_end_1328_2)
    end

    local center_1360 = p5.center_1360
    local center_1360_2 = p6.center_1360

    if type(center_1360_2) == "table" and type(center_1360) == "table" and center_1360 ~= center_1360_2 and #center_1360 == 4 and #center_1360_2 == 4 and type(center_1360_2[1]) == "number" then
        local v90 = center_1360_2[1]
        local v91 = center_1360_2[2]
        local v92 = center_1360_2[3]
        local v93 = center_1360_2[4]

        center_1360[1] = v90
        center_1360[2] = v91
        center_1360[3] = v92
        center_1360[4] = v93
    else
        copy_into(p5, "center_1360", center_1360_2)
    end

    local upmost_normal_1408 = p5.upmost_normal_1408
    local upmost_normal_1408_2 = p6.upmost_normal_1408

    if type(upmost_normal_1408_2) == "table" and type(upmost_normal_1408) == "table" and upmost_normal_1408 ~= upmost_normal_1408_2 and #upmost_normal_1408 == 4 and #upmost_normal_1408_2 == 4 and type(upmost_normal_1408_2[1]) == "number" then
        local v96 = upmost_normal_1408_2[1]
        local v97 = upmost_normal_1408_2[2]
        local v98 = upmost_normal_1408_2[3]
        local v99 = upmost_normal_1408_2[4]

        upmost_normal_1408[1] = v96
        upmost_normal_1408[2] = v97
        upmost_normal_1408[3] = v98
        upmost_normal_1408[4] = v99
    else
        copy_into(p5, "upmost_normal_1408", upmost_normal_1408_2)
    end

    local surface_direction_1424 = p5.surface_direction_1424
    local surface_direction_1424_2 = p6.surface_direction_1424

    if type(surface_direction_1424_2) == "table" and type(surface_direction_1424) == "table" and surface_direction_1424 ~= surface_direction_1424_2 and #surface_direction_1424 == 4 and #surface_direction_1424_2 == 4 and type(surface_direction_1424_2[1]) == "number" then
        local v102 = surface_direction_1424_2[1]
        local v103 = surface_direction_1424_2[2]
        local v104 = surface_direction_1424_2[3]
        local v105 = surface_direction_1424_2[4]

        surface_direction_1424[1] = v102
        surface_direction_1424[2] = v103
        surface_direction_1424[3] = v104
        surface_direction_1424[4] = v105
    else
        copy_into(p5, "surface_direction_1424", surface_direction_1424_2)
    end

    local high_side_1440 = p5.high_side_1440
    local high_side_1440_2 = p6.high_side_1440

    if type(high_side_1440_2) == "table" and type(high_side_1440) == "table" and high_side_1440 ~= high_side_1440_2 and #high_side_1440 == 4 and #high_side_1440_2 == 4 and type(high_side_1440_2[1]) == "number" then
        local v108 = high_side_1440_2[1]
        local v109 = high_side_1440_2[2]
        local v110 = high_side_1440_2[3]
        local v111 = high_side_1440_2[4]

        high_side_1440[1] = v108
        high_side_1440[2] = v109
        high_side_1440[3] = v110
        high_side_1440[4] = v111
    else
        copy_into(p5, "high_side_1440", high_side_1440_2)
    end

    copy_into(p5, "far_points_1376_1392", p6.far_points_1376_1392)
    copy_into(p5, "normal_limits_1456_1460", p6.normal_limits_1456_1460)
end

function t1.GrindInvestigationFields.assign_into_w2(p7, p8) -- line: 271
    -- upvalues: v1 (ref), t2 (ref), t3 (ref), t4 (ref), prepare (copy)
    if t2 == nil then
        prepare()
    end

    if not v1.general() and p7 ~= p8 then
        local t13 = t2

        for i = 1, #t13 do
            local v112 = t13[i]

            p7[v112] = p8[v112]
        end

        local copy_into = v1.copy_into
        local t14 = t3

        for i = 1, #t14 do
            local v113 = t14[i]

            copy_into(p7, v113, p8[v113])
        end

        local t15 = t4

        for i = 1, #t15 do
            local v114 = t15[i]

            copy_into(p7, v114, p8[v114])
        end
    elseif p7 ~= p8 then
        v1.assign_into(p7, p8)
    end
end

return t1
