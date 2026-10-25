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

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_core/math")
local v9 = import("skate_core/trigonometry")

local function drive_frames() -- line: 34
    -- upvalues: import (copy)
    return import("skate_core/physics/drive_frames")
end

local Vector3 = v8.Vector3
local t1 = {
    AuthoredTransformInputs = {}
}

function t1.AuthoredTransformInputs.eq(p3, p4) -- line: 51
    if p3.deck_mid_length == p4.deck_mid_length and p3.wheel_x_distance == p4.wheel_x_distance and p3.truck_z_position_front == p4.truck_z_position_front and p3.truck_z_position_back == p4.truck_z_position_back then
        return p3.truck_y_position == p4.truck_y_position
    end

    return false
end

t1.AuthoredTransformInputs.STOCK = {
    deck_mid_length = 0.5899999737739563,
    wheel_x_distance = 0.0949999988079071,
    truck_z_position_front = -0.052000001072883606,
    truck_z_position_back = -0.052000001072883606,
    truck_y_position = -0.05649999901652336
}

function t1.authored_body_transforms(p5) -- line: 72
    -- upvalues: rt (copy), import (copy), v9 (copy), Vector3 (copy)
    local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
    local v10 = p5.deck_mid_length * 0.5 + p5.truck_z_position_front
    local v11 = -(p5.deck_mid_length * 0.5 + p5.truck_z_position_back)
    local truck_y_position, wheel_x_distance = p5.truck_y_position, p5.wheel_x_distance
    local v12 = rt.filled(7, RetailAffineTransform.IDENTITY)
    local t2 = {
        Vector3.new(-wheel_x_distance, truck_y_position, v10),
        Vector3.new(wheel_x_distance, truck_y_position, v10),
        Vector3.new(-wheel_x_distance, truck_y_position, v11),
        Vector3.new(wheel_x_distance, truck_y_position, v11),
        Vector3.new(0, truck_y_position, v10),
        Vector3.new(0, truck_y_position, v11)
    }

    for i = 0, #t2 - 1 do
        v12[i + 1].translation = t2[i + 1]
    end

    local v13, v14 = v9.sin_cos(1.5707963705062866)

    v12[6].basis = {
        columns = {
            { v14, 0, -v13 },
            { 0, 1, 0 },
            { v13, 0, v14 }
        }
    }

    return v12
end

function t1.authored_body_pose_records(p6) -- line: 103
    -- upvalues: v1 (copy), t1 (copy)
    local v15 = t1.authored_body_transforms(p6)
    local v16 = table.create(#v15)

    for i = 1, #v15 do
        local v17 = v15[i]
        local v18 = table.create(16, 0)

        for j = 0, 2 do
            local v19 = v17.basis.columns[j + 1]
            local v20 = j * 4 + 0 + 1
            local v21 = v19[1]

            if v21 ~= 0 and v21 > -1.1754943508222875E-38 and v21 < 1.1754943508222875E-38 then
                local v22 = math.abs(v21) * 7.1362384635298E+44
                local v23 = math.floor(v22)
                local v24 = v22 - v23
                local v25 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

                if v21 < 0 then
                    v18[v20] = v25 + 2147483648
                else
                    v18[v20] = v25
                end
            else
                buffer.writef32(v1, 0, v21)
                v18[v20] = buffer.readu32(v1, 0)
            end

            local v26 = j * 4 + 1 + 1
            local v27 = v19[2]

            if v27 ~= 0 and v27 > -1.1754943508222875E-38 and v27 < 1.1754943508222875E-38 then
                local v28 = math.abs(v27) * 7.1362384635298E+44
                local v29 = math.floor(v28)
                local v30 = v28 - v29
                local v31 = if v30 > 0.5 or v30 == 0.5 and v29 % 2 == 1 then v29 + 1 else v29

                if v27 < 0 then
                    v18[v26] = v31 + 2147483648
                else
                    v18[v26] = v31
                end
            else
                buffer.writef32(v1, 0, v27)
                v18[v26] = buffer.readu32(v1, 0)
            end

            local v32 = j * 4 + 2 + 1
            local v33 = v19[3]

            if v33 ~= 0 and v33 > -1.1754943508222875E-38 and v33 < 1.1754943508222875E-38 then
                local v34 = math.abs(v33) * 7.1362384635298E+44
                local v35 = math.floor(v34)
                local v36 = v34 - v35
                local v37 = if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35

                if v33 < 0 then
                    v18[v32] = v37 + 2147483648
                else
                    v18[v32] = v37
                end
            else
                buffer.writef32(v1, 0, v33)
                v18[v32] = buffer.readu32(v1, 0)
            end
        end

        local x = v17.translation.x

        if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
            local v38 = math.abs(x) * 7.1362384635298E+44
            local v39 = math.floor(v38)
            local v40 = v38 - v39
            local v41 = if v40 > 0.5 or v40 == 0.5 and v39 % 2 == 1 then v39 + 1 else v39

            if x < 0 then
                v18[13] = v41 + 2147483648
            else
                v18[13] = v41
            end
        else
            buffer.writef32(v1, 0, x)
            v18[13] = buffer.readu32(v1, 0)
        end

        local y = v17.translation.y

        if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
            local v42 = math.abs(y) * 7.1362384635298E+44
            local v43 = math.floor(v42)
            local v44 = v42 - v43
            local v45 = if v44 > 0.5 or v44 == 0.5 and v43 % 2 == 1 then v43 + 1 else v43

            if y < 0 then
                v18[14] = v45 + 2147483648
            else
                v18[14] = v45
            end
        else
            buffer.writef32(v1, 0, y)
            v18[14] = buffer.readu32(v1, 0)
        end

        local z = v17.translation.z

        if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
            local v46 = math.abs(z) * 7.1362384635298E+44
            local v47 = math.floor(v46)
            local v48 = v46 - v47
            local v49 = if v48 > 0.5 or v48 == 0.5 and v47 % 2 == 1 then v47 + 1 else v47

            if z < 0 then
                v18[15] = v49 + 2147483648
            else
                v18[15] = v49
            end
        else
            buffer.writef32(v1, 0, z)
            v18[15] = buffer.readu32(v1, 0)
        end

        v16[i] = v18
    end

    return v16
end

return t1
