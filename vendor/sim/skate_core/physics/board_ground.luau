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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v9 = import("skate_core/trigonometry")
local v10 = import("skate_core/physics/board")
local BodyId, BODY_COUNT = v10.BodyId, v10.BODY_COUNT
local v11 = import("skate_core/physics/board_motion_output")
local add, dot, inverse_length_squared, length = v11.add, v11.dot, v11.inverse_length_squared, v11.length
local scale, subtract = v11.scale, v11.subtract
local v12 = import("skate_core/physics/native_arithmetic")
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local t1 = {
    UP = Vector3.new(0, 1, 0),
    WHEEL_LINE_LENGTH = 0.20000000298023224,
    WheelLine = {}
}

function t1.WheelLine.eq(p3, p4) -- line: 61
    -- upvalues: Vector3 (copy)
    return Vector3.eq(p3.start, p4.start) and Vector3.eq(p3["end"], p4["end"])
end

function t1.wheel_lines_reference(p5, p6) -- line: 67
    -- upvalues: rt (copy), scale (copy), subtract (copy), BoardRuntime (copy), t1 (copy)
    local v13 = BoardRuntime.part_transforms(p5)
    local v14 = scale(p6, t1.WHEEL_LINE_LENGTH)

    return rt.from_fn(4, function(p7) -- line: 70
        -- upvalues: v13 (copy), v14 (copy), rt (copy), subtract (copy)
        return {
            start = rt.copy(v13[p7 + 1].translation),
            ["end"] = subtract(v13[p7 + 1].translation, v14)
        }
    end)
end

function t1.wheel_lines(p8, p9) -- line: 85
    -- upvalues: Vector3 (copy), scale (copy), subtract (copy), BoardRuntime (copy), t1 (copy)
    local part_translation = BoardRuntime.part_translation
    local v15, v16, v17 = part_translation(p8, 0)
    local v18, v19, v20 = part_translation(p8, 1)
    local v21, v22, v23 = part_translation(p8, 2)
    local v24, v25, v26 = part_translation(p8, 3)
    local v27 = scale(p9, t1.WHEEL_LINE_LENGTH)
    local v28 = Vector3.new(v15, v16, v17)
    local v29 = subtract(v28, v27)
    local v30 = Vector3.new(v18, v19, v20)
    local v31 = subtract(v30, v27)
    local v32 = Vector3.new(v21, v22, v23)
    local v33 = subtract(v32, v27)
    local v34 = Vector3.new(v24, v25, v26)
    local v35 = subtract(v34, v27)

    return {
        {
            start = v28,
            ["end"] = v29
        },
        {
            start = v30,
            ["end"] = v31
        },
        {
            start = v32,
            ["end"] = v33
        },
        {
            start = v34,
            ["end"] = v35
        }
    }
end

t1.WheelLineHit = {}
t1.WheelLineState = {}

function t1.WheelLineState.default() -- line: 121
    -- upvalues: rt (copy), t1 (copy)
    return {
        minimum_distance = 0,
        normals = rt.filled(4, t1.UP),
        distances = table.create(4, 0),
        physics_surfaces = table.create(4, 0)
    }
end

function t1.WheelLineState.publish(p10, p11) -- line: 134
    -- upvalues: rt (copy), t1 (copy)
    p10.minimum_distance = t1.WHEEL_LINE_LENGTH

    for i = 0, 3 do
        local v36 = p11[i + 1]

        p10.physics_surfaces[i + 1] = 0

        if v36 ~= nil then
            local v37 = v36.fraction * t1.WHEEL_LINE_LENGTH

            if v37 - p10.minimum_distance >= -0 then
                p10.minimum_distance = p10.minimum_distance
            else
                p10.minimum_distance = v37
            end

            p10.normals[i + 1] = rt.copy(v36.normal)
            p10.distances[i + 1] = v37

            local physics_surfaces = p10.physics_surfaces
            local v38 = bit32.rshift(v36.surface_tag, 7)

            physics_surfaces[i + 1] = bit32.band(v38, 31)
        end
    end
end

t1.PartGroundContact = {}
t1.EMPTY_PART = {
    in_contact = false,
    normal = rt.copy(t1.UP),
    point = rt.copy(Vector3.ZERO),
    relative_velocity = rt.copy(Vector3.ZERO)
}
t1.BoardGroundState = {}

function t1.BoardGroundState.default() -- line: 176
    -- upvalues: rt (copy), Vector3 (copy), BODY_COUNT (copy), t1 (copy)
    return {
        maximum_closing_speed = 0,
        opposing_contact = 0,
        surface_twelve_height = 0,
        collision_flags = 0,
        part_contact_count = 0,
        wheel_contact_count = 0,
        time_without_wheel_contact = 0,
        parts = rt.filled(BODY_COUNT, t1.EMPTY_PART),
        overall_normal = rt.copy(t1.UP),
        wheel_normal = rt.copy(t1.UP),
        previous_velocities = rt.filled(BODY_COUNT, Vector3.ZERO),
        accelerations = rt.filled(BODY_COUNT, Vector3.ZERO),
        closing_velocity = rt.copy(Vector3.ZERO),
        valid_wheel_normals = table.create(4, false),
        wheel_angular_drag = table.create(4, 0)
    }
end

function t1.BoardGroundState.sample_accelerations(p12, p13, p14) -- line: 203
    -- upvalues: Vector3 (copy), BODY_COUNT (copy)
    local v39 = 1 / p14
    local accelerations, previous_velocities = p12.accelerations, p12.previous_velocities

    for i = 1, BODY_COUNT do
        local v40 = table.clone(p13[i])
        local v41 = previous_velocities[i]

        accelerations[i] = Vector3.new((v40.x - v41.x) * v39, (v40.y - v41.y) * v39, (v40.z - v41.z) * v39)
        previous_velocities[i] = v40
    end
end

function t1.BoardGroundState.sample_body_accelerations(p15, p16, p17) -- line: 225
    -- upvalues: rt (copy), Vector3 (copy), BODY_COUNT (copy), t1 (copy)
    if #p16 ~= BODY_COUNT then
        return t1.BoardGroundState.sample_accelerations_reference(p15, rt.from_fn(#p16, function(p18) -- line: 229
            -- upvalues: p16 (copy), rt (copy)
            return rt.copy(p16[p18 + 1].rates.linear_velocity)
        end), p17)
    end

    local v42 = 1 / p17
    local accelerations, previous_velocities = p15.accelerations, p15.previous_velocities

    for i = 1, BODY_COUNT do
        local v43 = table.clone(p16[i].rates.linear_velocity)
        local v44 = previous_velocities[i]

        accelerations[i] = Vector3.new((v43.x - v44.x) * v42, (v43.y - v44.y) * v42, (v43.z - v44.z) * v42)
        previous_velocities[i] = v43
    end
end

function t1.BoardGroundState.sample_accelerations_reference(p19, p20, p21) -- line: 250
    -- upvalues: rt (copy), BODY_COUNT (copy), scale (copy), subtract (copy)
    local v45 = 1 / p21

    for i = 0, BODY_COUNT - 1 do
        local v46 = rt.copy(p20[i + 1])

        p19.accelerations[i + 1] = scale(subtract(v46, p19.previous_velocities[i + 1]), v45)
        p19.previous_velocities[i + 1] = v46
    end
end

function t1.BoardGroundState.advance_contact_time(p22, p23) -- line: 261
    if p22.wheel_contact_count == 0 then
        p22.time_without_wheel_contact += p23
    else
        p22.time_without_wheel_contact = 0
    end
end

local v47 = table.create(BODY_COUNT, 0)
local v48 = BodyId.index(BodyId.Deck)
local v49 = BodyId.index(BodyId.FrontTruck)
local v50 = BodyId.index(BodyId.BackTruck)
local angle_between_xyz

function t1.BoardGroundState.update(p24, p25, p26, p27, p28, p29) -- line: 293
    -- upvalues: v1 (copy), Vector3 (copy), v9 (copy), BODY_COUNT (copy), inverse_length_squared (copy), v12 (copy), t1 (copy), v47 (copy), v48 (copy), v49 (copy), v50 (copy), angle_between_xyz (ref)
    local parts = p24.parts

    for i = 1, BODY_COUNT do
        local v51 = parts[i]
        local normal, point, relative_velocity

        if type(v51) == "table" then
            normal = v51.normal
            point = v51.point
            relative_velocity = v51.relative_velocity
        end

        if type(normal) ~= "table" or type(point) ~= "table" or type(relative_velocity) ~= "table" then
            return t1.BoardGroundState.update_reference(p24, p25, p26, p27, p28, p29)
        end
    end

    for i = 1, BODY_COUNT do
        local v52 = parts[i]

        v52.in_contact = false

        local normal = v52.normal

        normal.x = 0
        normal.y = 1
        normal.z = 0

        local point = v52.point

        point.x = 0
        point.y = 0
        point.z = 0

        local relative_velocity = v52.relative_velocity

        relative_velocity.x = 0
        relative_velocity.y = 0
        relative_velocity.z = 0
    end

    p24.closing_velocity = Vector3.new(0, 0, 0)
    p24.maximum_closing_speed = 0
    p24.surface_twelve_height = 0
    p24.collision_flags = bit32.band(p24.collision_flags, 33554431)
    p24.overall_normal = Vector3.new(0, 1, 0)

    local valid_wheel_normals = p24.valid_wheel_normals

    valid_wheel_normals[1] = true
    valid_wheel_normals[2] = true
    valid_wheel_normals[3] = true
    valid_wheel_normals[4] = true

    local x, y, z = p27.x, p27.y, p27.z
    local physics_surfaces = p26.physics_surfaces
    local v53 = physics_surfaces[1]
    local v54 = physics_surfaces[2]
    local v55 = physics_surfaces[3]
    local v56 = physics_surfaces[4]

    v47[1] = v53
    v47[2] = v54
    v47[3] = v55
    v47[4] = v56
    v47[5] = 0
    v47[6] = 0
    v47[7] = 0

    local previous_velocities = p24.previous_velocities
    local n1 = -2
    local n2 = 1
    local n3 = -1
    local part

    for _, v57 in p25 do
        local part2, normal = v57.part, v57.normal
        local x2, y2, z2 = normal.x, normal.y, normal.z

        if part2 == v48 then
            local v58 = x2 * x + y2 * y + z2 * z

            if n2 - v58 >= 0 then
                n2 = v58
            end

            if not (n3 - v58 >= 0) then
                n3 = v58
            end
        end

        local v59 = previous_velocities[part2 + 1]
        local v60 = -(x2 * v59.x + y2 * v59.y + z2 * v59.z)

        if not (v60 <= p24.maximum_closing_speed) then
            p24.maximum_closing_speed = v60

            local v61 = -v60

            p24.closing_velocity = Vector3.new(x2 * v61, y2 * v61, z2 * v61)
        end

        local v63 = bit32.band(bit32.rshift(v57.other_surface, 7), 31)

        if v63 == 12 then
            p24.collision_flags = bit32.bor(p24.collision_flags, 33554432)
            p24.surface_twelve_height = v57.position.y
        end

        if part2 >= 4 then
            v47[part2 + 1] = v63
        end

        local v64 = parts[part2 + 1]
        local normal2 = v64.normal

        if not v64.in_contact or normal2.y < y2 then
            normal2.x = x2
            normal2.y = y2
            normal2.z = z2

            local position = v57.position
            local point = v64.point
            local x, y, z = position.x, position.y, position.z

            point.x = x
            point.y = y
            point.z = z

            local relative_linear_velocity = v57.relative_linear_velocity
            local relative_velocity = v64.relative_velocity
            local x3, y3, z3 = relative_linear_velocity.x, relative_linear_velocity.y, relative_linear_velocity.z

            relative_velocity.x = x3
            relative_velocity.y = y3
            relative_velocity.z = z3
        end

        local y3 = normal2.y

        if n1 < y3 then
            part = part2
            n1 = y3
        end

        v64.in_contact = true
    end

    local v65 = n3 - n2

    p24.opposing_contact = if -v65 >= 0 then 0 else v65

    for i = 1, BODY_COUNT do
        if parts[i].in_contact and v47[i] == 8 then
            p24.collision_flags = bit32.bor(p24.collision_flags, 2147483648)
        end
    end

    local v66 = if part == nil then p24.wheel_normal else parts[part + 1].normal
    local x2, y2, z2 = v66.x, v66.y, v66.z
    local distances, normals = p26.distances, p26.normals

    for i = 1, 4 do
        local v67 = parts[i]

        if not v67.in_contact then
            if distances[i] < 0.07000000029802322 then
                local v68 = normals[i]
                local normal = v67.normal
                local x, y, z = v68.x, v68.y, v68.z

                normal.x = x
                normal.y = y
                normal.z = z
            else
                valid_wheel_normals[i] = false
            end
        end
    end

    local n4 = 0

    for i = 1, BODY_COUNT do
        if parts[i].in_contact then
            n4 += 1
        end
    end

    p24.part_contact_count = n4

    local v69 = if parts[1].in_contact then 0 + 1 else 0

    if parts[2].in_contact then
        v69 += 1
    end

    if parts[3].in_contact then
        v69 += 1
    end

    if parts[4].in_contact then
        v69 += 1
    end

    p24.wheel_contact_count = v69

    local v70 = p28 * 0.01745329238474369
    local v71 = v9.cos(v70)
    local wheel_angular_drag = p24.wheel_angular_drag
    local n5 = 0
    local n6 = 0
    local n7 = 0

    for i = 1, 4 do
        local v72 = parts[i]
        local normal = v72.normal
        local x3, y3, z3 = normal.x, normal.y, normal.z

        if valid_wheel_normals[i] and v71 < x3 * x + y3 * y + z3 * z and angle_between_xyz(x2, y2, z2, x3, y3, z3) < 0.7853981852531433 then
            n5 += x3
            n6 += y3
            n7 += z3
        end

        wheel_angular_drag[i] = (if not v72.in_contact then 0.006000000052154064 elseif p29 then 0.03999999910593033 else 0) * 59.999996185302734
    end

    local v73 = n5 * n5 + n6 * n6 + n7 * n7

    if p24.wheel_contact_count > 0 and v73 > 1.52587890625E-05 then
        local v74 = inverse_length_squared(v73, 2)
        local v75 = n5 * v74
        local v76 = n6 * v74
        local v77 = n7 * v74

        p24.overall_normal = Vector3.new(v75, v76, v77)
        p24.wheel_normal = Vector3.new(v75, v76, v77)
    else
        local v78 = parts[v48 + 1]
        local v79, v80, v81

        if v78.in_contact then
            local normal = v78.normal

            v79 = 0 + normal.x
            v80 = 0 + normal.y
            v81 = 0 + normal.z
        else
            v79 = 0
            v80 = 0
            v81 = 0
        end

        local v82 = parts[v49 + 1]

        if v82.in_contact then
            local normal = v82.normal

            v79 += normal.x
            v80 += normal.y
            v81 += normal.z
        end

        local v83 = parts[v50 + 1]

        if v83.in_contact then
            local normal = v83.normal

            v79 += normal.x
            v80 += normal.y
            v81 += normal.z
        end

        local v84 = v79 * v79 + v80 * v80 + v81 * v81
        local v85

        if v84 == 0 then
            buffer.writef32(v1, 0, v84)
            v85 = buffer.readf32(v1, 0)
        elseif v84 > -1.1754943508222875E-38 and v84 < 1.1754943508222875E-38 then
            local v86 = math.abs(v84) * 7.1362384635298E+44
            local v87 = math.floor(v86)
            local v88 = v86 - v87

            if v88 > 0.5 or v88 == 0.5 and v87 % 2 == 1 then
                v87 += 1
            end

            v85 = v87 * 1.401298464324817E-45

            if v84 < 0 then
                v85 = -v85
            end
        else
            buffer.writef32(v1, 0, v84)
            v85 = buffer.readf32(v1, 0)
        end

        local v89 = v85 * inverse_length_squared(v85, 2)

        if v85 == 0 then
            v89 = 0
        end

        if not (v89 > 0.009999999776482582) then
            return
        end

        local v90 = v12.reciprocal_estimate(v89)
        local v91 = v90 * (-v90 * v89 + 1) + v90
        local v92 = v91 * (-v91 * v89 + 1) + v91

        p24.overall_normal = Vector3.new(v79 * v92, v80 * v92, v81 * v92)
    end
end

function t1.BoardGroundState.update_reference(p30, p31, p32, p33, p34, p35) -- line: 506
    -- upvalues: rt (copy), Vector3 (copy), v9 (copy), BodyId (copy), BODY_COUNT (copy), add (copy), dot (copy), inverse_length_squared (copy), length (copy), scale (copy), v12 (copy), t1 (copy)
    for i = 1, BODY_COUNT do
        p30.parts[i] = rt.copy(t1.EMPTY_PART)
    end

    p30.closing_velocity = rt.copy(Vector3.ZERO)
    p30.maximum_closing_speed = 0
    p30.surface_twelve_height = 0
    p30.collision_flags = bit32.band(p30.collision_flags, 33554431)
    p30.overall_normal = rt.copy(t1.UP)
    p30.valid_wheel_normals[1] = true
    p30.valid_wheel_normals[2] = true
    p30.valid_wheel_normals[3] = true
    p30.valid_wheel_normals[4] = true

    local v93 = table.create(BODY_COUNT, 0)

    v93[1] = p32.physics_surfaces[1]
    v93[2] = p32.physics_surfaces[2]
    v93[3] = p32.physics_surfaces[3]
    v93[4] = p32.physics_surfaces[4]

    local n8 = -2
    local n9 = 1
    local n10 = -1
    local v94

    for _, v95 in p31 do
        local v96 = BodyId.index(v95.part)

        if v95.part == BodyId.Deck then
            local v97 = dot(v95.normal, p33)

            if n9 - v97 >= 0 then
                n9 = v97
            end

            if not (n10 - v97 >= 0) then
                n10 = v97
            end
        end

        local v98 = -dot(v95.normal, p30.previous_velocities[v96 + 1])

        if not (v98 <= p30.maximum_closing_speed) then
            p30.maximum_closing_speed = v98
            p30.closing_velocity = scale(v95.normal, -v98)
        end

        local v100 = bit32.band(bit32.rshift(v95.other_surface, 7), 31)

        if v100 == 12 then
            p30.collision_flags = bit32.bor(p30.collision_flags, 33554432)
            p30.surface_twelve_height = v95.position.y
        end

        if v96 >= 4 then
            v93[v96 + 1] = v100
        end

        local v101 = p30.parts[v96 + 1]

        if not v101.in_contact or v95.normal.y > v101.normal.y then
            v101.normal = rt.copy(v95.normal)
            v101.point = rt.copy(v95.position)
            v101.relative_velocity = rt.copy(v95.relative_linear_velocity)
        end

        if n8 < v101.normal.y then
            v94 = v96
            n8 = v101.normal.y
        end

        v101.in_contact = true
    end

    local v102 = n10 - n9

    p30.opposing_contact = if -v102 >= 0 then 0 else v102

    for i = 1, BODY_COUNT do
        local v103 = p30.parts[i]
        local v104 = v93[i]

        if v103.in_contact and v104 == 8 then
            p30.collision_flags = bit32.bor(p30.collision_flags, 2147483648)
        end
    end

    local v105 = if v94 == nil then rt.copy(p30.wheel_normal) else rt.copy(p30.parts[v94 + 1].normal)

    for i = 0, 3 do
        if not p30.parts[i + 1].in_contact then
            if p32.distances[i + 1] < 0.07000000029802322 then
                p30.parts[i + 1].normal = rt.copy(p32.normals[i + 1])
            else
                p30.valid_wheel_normals[i + 1] = false
            end
        end
    end

    local n11 = 0

    for i = 1, BODY_COUNT do
        if p30.parts[i].in_contact then
            n11 += 1
        end
    end

    p30.part_contact_count = n11

    local v106 = if p30.parts[1].in_contact then 0 + 1 else 0

    if p30.parts[2].in_contact then
        v106 += 1
    end

    if p30.parts[3].in_contact then
        v106 += 1
    end

    if p30.parts[4].in_contact then
        v106 += 1
    end

    p30.wheel_contact_count = v106

    local v107 = p34 * 0.01745329238474369
    local v108 = v9.cos(v107)
    local v109 = rt.copy(Vector3.ZERO)

    for i = 0, 3 do
        local v110 = p30.parts[i + 1]

        if p30.valid_wheel_normals[i + 1] and v108 < dot(v110.normal, p33) and t1.angle_between_reference(v105, v110.normal) < 0.7853981852531433 then
            v109 = add(v109, v110.normal)
        end

        local v111 = if not v110.in_contact then 0.006000000052154064 elseif p35 then 0.03999999910593033 else 0

        p30.wheel_angular_drag[i + 1] = v111 * 59.999996185302734
    end

    local v112 = dot(v109, v109)

    if p30.wheel_contact_count > 0 and v112 > 1.52587890625E-05 then
        p30.overall_normal = scale(v109, inverse_length_squared(v112, 2))
        p30.wheel_normal = rt.copy(p30.overall_normal)

        return
    end

    local v113 = rt.copy(Vector3.ZERO)

    for _, v114 in {
            BodyId.index(BodyId.Deck),
            BodyId.index(BodyId.FrontTruck),
            BodyId.index(BodyId.BackTruck)
        } do
        if p30.parts[v114 + 1].in_contact then
            v113 = add(v113, p30.parts[v114 + 1].normal)
        end
    end

    local v115 = length(v113)

    if v115 > 0.009999999776482582 then
        local v116 = v12.reciprocal_estimate(v115)
        local v117 = v116 * (-v116 * v115 + 1) + v116

        p30.overall_normal = scale(v113, v117 * (-v117 * v115 + 1) + v117)
    end
end

function angle_between_xyz(p36, p37, p38, p39, p40, p41) -- line: 663
    -- upvalues: v9 (copy), inverse_length_squared (copy), v12 (copy)
    local v119 = p36 * p36 + p37 * p37 + p38 * p38
    local v120 = p39 * p39 + p40 * p40 + p41 * p41

    if v119 > 9.999999747378752E-05 and v120 > 9.999999747378752E-05 then
        local v121 = inverse_length_squared(v119, 1)
        local v122 = inverse_length_squared(v120, 1)
        local v123 = v12.vector_min(v12.vector_max(p36 * v121 * (p39 * v122) + p37 * v121 * (p40 * v122) + p38 * v121 * (p41 * v122), -1), 1)

        return v9.acos(v123)
    end

    return 0
end

t1.angle_between_xyz = angle_between_xyz

function t1.angle_between(p42, p43) -- line: 683
    -- upvalues: angle_between_xyz (ref)
    return angle_between_xyz(p42.x, p42.y, p42.z, p43.x, p43.y, p43.z)
end

function t1.angle_between_reference(p44, p45) -- line: 691
    -- upvalues: v9 (copy), dot (copy), inverse_length_squared (copy), scale (copy), v12 (copy)
    local v124 = dot(p44, p44)
    local v125 = dot(p45, p45)

    if v124 > 9.999999747378752E-05 and v125 > 9.999999747378752E-05 then
        local v126 = scale(p44, inverse_length_squared(v124, 1))
        local v127 = scale(p45, inverse_length_squared(v125, 1))
        local v128 = v12.vector_min(v12.vector_max(dot(v126, v127), -1), 1)

        return v9.acos(v128)
    end

    return 0
end

return t1
