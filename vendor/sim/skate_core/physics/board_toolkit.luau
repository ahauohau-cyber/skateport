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
local BodyId = import("skate_core/physics/board").BodyId
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local total_body_mass = import("skate_core/physics/force_queue").total_body_mass
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local v9 = BoardRuntime.transform_scratch()
local t1 = {
    BoardToolkit = {}
}

function t1.BoardToolkit.from_board(p3, p4, p5, p6, p7) -- line: 53
    -- upvalues: BodyId (copy), BoardRuntime (copy), t1 (copy), v9 (copy)
    local v10 = BoardRuntime.part_transform_into(p3, BodyId.index(BodyId.Deck), v9)
    local columns = v10.basis.columns
    local translation = v10.translation
    local v11 = columns[1]
    local v12 = columns[2]
    local v13 = columns[3]
    local t2 = {
        {
            v11[1],
            v11[2],
            v11[3],
            0
        },
        {
            v12[1],
            v12[2],
            v12[3],
            0
        },
        {
            v13[1],
            v13[2],
            v13[3],
            0
        },
        {
            translation.x,
            translation.y,
            translation.z,
            1
        }
    }
    local v14 = BoardRuntime.bodies(p3)
    local v15 = table.create(#v14)

    for v16, v17 in v14 do
        v15[v16] = v17.inertia.inverse_mass
    end

    return t1.BoardToolkit.calculate(t2, v15, p4, p5, p6, p7)
end

function t1.BoardToolkit.calculate(p8, p9, p10, p11, p12, p13) -- line: 99
    -- upvalues: v1 (copy), inverse_length_squared (copy), total_body_mass (copy), t1 (copy)
    local v18 = p8[1]
    local v19 = p8[2]
    local v20 = p8[3]
    local v21 = p8[4]

    if #p8 ~= 4
        or #v18 ~= 4
        or #v19 ~= 4
        or #v20 ~= 4
        or #v21 ~= 4
        or #p12 ~= 4
        or #p13 ~= 4 then
        return t1.BoardToolkit.calculate_reference(p8, p9, p10, p11, p12, p13)
    end

    local v22 = if bit32.band(p10, 1048576) == 0 then 1 else -1
    local v23 = v18[1]
    local v24 = v18[2]
    local v25 = v18[3]
    local v26 = v18[4]
    local v27 = v19[1]
    local v28 = v19[2]
    local v29 = v19[3]
    local v30 = v19[4]
    local v31 = v20[1]
    local v32 = v20[2]
    local v33 = v20[3]
    local v34 = v20[4]
    local v35 = v21[1]
    local v36 = v21[2]
    local v37 = v21[3]
    local v38 = v21[4]
    local v39 = v23 * v22
    local v40 = v24 * v22
    local v41 = v25 * v22
    local v42 = v26 * v22
    local v43 = v31 * v22
    local v44 = v32 * v22
    local v45 = v33 * v22
    local v46 = v34 * v22
    local v47 = 0 - v35
    local v48 = 0 - v36
    local v49 = 0 - v37
    local v50 = v47 * v39 + (v48 * v40 + v49 * v41)
    local v51 = v47 * v27 + (v48 * v28 + v49 * v29)
    local v52 = v47 * v43 + (v48 * v44 + v49 * v45)
    local v53 = v47 * 0 + (v48 * 0 + v49 * 0)
    local v54 = v43 * v43 + 0 * 0 + v45 * v45
    local v55, v56, v57, v58

    if v54 > 9.999999747378752E-06 then
        local v59 = inverse_length_squared(v54, 2)

        v55 = v43 * v59
        v56 = 0 * v59
        v57 = v45 * v59
        v58 = v46 * v59
    else
        v58 = v46
        v55 = v43
        v56 = 0
        v57 = v45
    end

    local v60 = v27 * v55 + v28 * v56 + v29 * v57
    local v61 = v27 - v55 * v60
    local v62 = v28 - v56 * v60
    local v63 = v29 - v57 * v60
    local v64 = v30 - v58 * v60
    local v65 = inverse_length_squared(v61 * v61 + v62 * v62 + v63 * v63, 2)
    local v66 = if p11 > 0 then 1 else -1
    local v67 = p13[1]
    local v68 = p13[2]
    local v69 = p13[3]
    local v70 = p13[4]
    local v71 = p12[1]
    local v72 = p12[2]
    local v73 = p12[3]
    local v74 = p12[4]
    local t3

    if not (v67 * v71 + v68 * v72 + v69 * v73 <= 0.9350000023841858) then
        t3 = { v71, v72, v73, v74 }

        return {
            deck = {
                { v23, v24, v25, v26 },
                { v27, v28, v29, v30 },
                { v31, v32, v33, v34 },
                { v35, v36, v37, v38 }
            },
            effective = {
                { v39, v40, v41, v42 },
                { v27, v28, v29, v30 },
                { v43, v44, v45, v46 },
                { v35, v36, v37, v38 }
            },
            inverse_effective = {
                { v39, v27, v43, 0 },
                { v40, v28, v44, 0 },
                { v41, v29, v45, 0 },
                { v50, v51, v52, v53 }
            },
            side = { v39, v40, v41, v42 },
            up = { v27, v28, v29, v30 },
            forward = { v43, v44, v45, v46 },
            horizontal_forward = { v55, v56, v57, v58 },
            transverse_up = {
                v61 * v65,
                v62 * v65,
                v63 * v65,
                v64 * v65
            },
            forward_velocity = {
                v43 * p11,
                v44 * p11,
                v45 * p11,
                v46 * p11
            },
            travel_direction = {
                v43 * v66,
                v44 * v66,
                v45 * v66,
                v46 * v66
            },
            filtered_normal = t3,
            absolute_speed = p11 * v66,
            control_sign = v22,
            total_mass = total_body_mass(p9)
        }
    end

    local v75 = v67 * 0.8999999761581421 + v71 * 0.10000000149011612
    local v76 = v68 * 0.8999999761581421 + v72 * 0.10000000149011612
    local v77 = v69 * 0.8999999761581421 + v73 * 0.10000000149011612
    local v78 = v70 * 0.8999999761581421 + v74 * 0.10000000149011612
    local v79 = v75 * v75 + v76 * v76 + v77 * v77
    local v80

    if v79 == 0 then
        buffer.writef32(v1, 0, v79)
        v80 = buffer.readf32(v1, 0)
    elseif v79 > -1.1754943508222875E-38 and v79 < 1.1754943508222875E-38 then
        local v81 = math.abs(v79) * 7.1362384635298E+44
        local v82 = math.floor(v81)
        local v83 = v81 - v82

        if v83 > 0.5 or v83 == 0.5 and v82 % 2 == 1 then
            v82 += 1
        end

        v80 = v82 * 1.401298464324817E-45

        if v79 < 0 then
            v80 = -v80
        end
    else
        buffer.writef32(v1, 0, v79)
        v80 = buffer.readf32(v1, 0)
    end

    local v84 = inverse_length_squared(v80, 2)

    if (if v80 == 0 then 0 else v80 * v84) > 9.999999974752427E-07 then
        t3 = {
            v75 * v84,
            v76 * v84,
            v77 * v84,
            v78 * v84
        }
    else
        t3 = { 0, 0, 0, 0 }
    end

    return {
        deck = {
            { v23, v24, v25, v26 },
            { v27, v28, v29, v30 },
            { v31, v32, v33, v34 },
            { v35, v36, v37, v38 }
        },
        effective = {
            { v39, v40, v41, v42 },
            { v27, v28, v29, v30 },
            { v43, v44, v45, v46 },
            { v35, v36, v37, v38 }
        },
        inverse_effective = {
            { v39, v27, v43, 0 },
            { v40, v28, v44, 0 },
            { v41, v29, v45, 0 },
            { v50, v51, v52, v53 }
        },
        side = { v39, v40, v41, v42 },
        up = { v27, v28, v29, v30 },
        forward = { v43, v44, v45, v46 },
        horizontal_forward = { v55, v56, v57, v58 },
        transverse_up = {
            v61 * v65,
            v62 * v65,
            v63 * v65,
            v64 * v65
        },
        forward_velocity = {
            v43 * p11,
            v44 * p11,
            v45 * p11,
            v46 * p11
        },
        travel_direction = {
            v43 * v66,
            v44 * v66,
            v45 * v66,
            v46 * v66
        },
        filtered_normal = t3,
        absolute_speed = p11 * v66,
        control_sign = v22,
        total_mass = total_body_mass(p9)
    }
end

function t1.BoardToolkit.calculate_reference(p14, p15, p16, p17, p18, p19) -- line: 190
    -- upvalues: rt (copy), v1 (copy), inverse_length_squared (copy), total_body_mass (copy), dot3 (copy)
    local v85 = if bit32.band(p16, 1048576) == 0 then 1 else -1
    local v86 = rt.copy(p14)

    for _, v87 in { 0, 2 } do
        v86[v87 + 1] = rt.map(p14[v87 + 1], function(p20) -- line: 201
            -- upvalues: v85 (copy)
            return p20 * v85
        end)
    end

    local v90 = rt.filled(4, table.create(4, 0))

    for i = 0, 2 do
        v90[i + 1][1] = v86[1][i + 1]
        v90[i + 1][2] = v86[2][i + 1]
        v90[i + 1][3] = v86[3][i + 1]
    end

    for i = 0, 3 do
        local v91 = (0 - v86[4][3]) * v90[3][i + 1]
        local v92 = (0 - v86[4][2]) * v90[2][i + 1] + v91

        v90[4][i + 1] = (0 - v86[4][1]) * v90[1][i + 1] + v92
    end

    local v93 = rt.copy(v86[1])
    local v94 = rt.copy(p14[2])
    local v95 = rt.copy(v86[3])
    local v96 = rt.copy(v95)

    v96[2] = 0

    local v97 = dot3(v96, v96)

    if v97 > 9.999999747378752E-06 then
        v96 = rt.map(v96, function(p21) -- line: 225
            -- upvalues: v97 (copy), inverse_length_squared (copy)
            return p21 * inverse_length_squared(v97, 2)
        end)
    end

    local v98 = dot3(v94, v96)
    local t4 = {
        v94[1] - v96[1] * v98,
        v94[2] - v96[2] * v98,
        v94[3] - v96[3] * v98,
        v94[4] - v96[4] * v98
    }
    local v99 = inverse_length_squared(dot3(t4, t4), 2)
    local v100 = rt.map(t4, function(p22) -- line: 237
        -- upvalues: v99 (copy)
        return p22 * v99
    end)
    local v101 = if p17 > 0 then 1 else -1
    local v102

    if dot3(p19, p18) <= 0.9350000023841858 then
        local t5 = {
            p19[1] * 0.8999999761581421 + p18[1] * 0.10000000149011612,
            p19[2] * 0.8999999761581421 + p18[2] * 0.10000000149011612,
            p19[3] * 0.8999999761581421 + p18[3] * 0.10000000149011612,
            p19[4] * 0.8999999761581421 + p18[4] * 0.10000000149011612
        }
        local v103 = dot3(t5, t5)
        local v104

        if v103 == 0 then
            buffer.writef32(v1, 0, v103)
            v104 = buffer.readf32(v1, 0)
        elseif v103 > -1.1754943508222875E-38 and v103 < 1.1754943508222875E-38 then
            local v105 = math.abs(v103) * 7.1362384635298E+44
            local v106 = math.floor(v105)
            local v107 = v105 - v106

            if v107 > 0.5 or v107 == 0.5 and v106 % 2 == 1 then
                v106 += 1
            end

            v104 = v106 * 1.401298464324817E-45

            if v103 < 0 then
                v104 = -v104
            end
        else
            buffer.writef32(v1, 0, v103)
            v104 = buffer.readf32(v1, 0)
        end

        local v108 = inverse_length_squared(v104, 2)

        if (if v104 == 0 then 0 else v104 * v108) > 9.999999974752427E-07 then
            v102 = rt.map(t5, function(p23) -- line: 256
                -- upvalues: v108 (copy)
                return p23 * v108
            end)
        else
            v102 = table.create(4, 0)
        end
    else
        v102 = rt.copy(p18)
    end

    return {
        deck = rt.copy(p14),
        effective = v86,
        inverse_effective = v90,
        side = v93,
        up = v94,
        forward = v95,
        horizontal_forward = v96,
        transverse_up = v100,
        forward_velocity = rt.map(v95, function(p24) -- line: 272
            -- upvalues: p17 (copy)
            return p24 * p17
        end),
        travel_direction = rt.map(v95, function(p25) -- line: 275
            -- upvalues: v101 (copy)
            return p25 * v101
        end),
        filtered_normal = v102,
        absolute_speed = p17 * v101,
        control_sign = v85,
        total_mass = total_body_mass(p15)
    }
end

return t1
