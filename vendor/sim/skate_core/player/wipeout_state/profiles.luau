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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_core/player/wipeout_state/math")
local SkeletonBody = import("skate_core/physics/skeleton_body").SkeletonBody

return {
    Profile = {},
    prepare = function(p4, p5, p6, p7) -- prepare | line: 64
        -- upvalues: rt (copy), v8 (copy)
        local v9 = p6[1]
        local v10 = p6[2]
        local v11 = if math.abs(v9) < 0.2 and math.abs(v10) < 0.2 then 0
            elseif math.abs(v9) <= math.abs(v10) then if v10 <= 0 then 3 else 1
            elseif v9 <= 0 then 4
            else 2

        p4.control_time += 0.01666666753590107

        if v11 ~= p4.profile then
            p4.control_time = 0
            p4.profile = v11
            p4.retained_sideways_input = 0
            p4.retained_forward_input = 0
        end

        local v12 = rt.copy(p4.velocity)

        v12[2] = 0

        local v13 = v8.normalize_or(v12, { 0, 0, 0, 0 })

        if p4.direction_initialized then
            local direction_follow = p5[v11 + 1].direction_follow

            p4.forward = v8.normalize_or(v8.madd(v13, direction_follow, v8.scale(p4.forward, 1 - direction_follow)), { 0, 0, 0, 0 })
        else
            p4.direction_initialized = true
            p4.forward = v13
        end

        p4.right = v8.cross({ 0, 1, 0, 0 }, p4.forward)

        local t2 = {
            p7[1],
            0,
            p7[2],
            0
        }

        p4.forward_input = v8.dot(t2, p4.forward)
        p4.sideways_input = v8.dot(t2, p4.right)
    end,
    drift = function(p8, p9, p10) -- drift | line: 107
        -- upvalues: v1 (copy), v8 (copy), SkeletonBody (copy)
        if p8.retained_velocity_active then
            return
        end

        local v14 = v8.madd(p8.right, p10.drift_sideways * p8.sideways_input, v8.scale(p8.forward, p10.drift_forward * p8.forward_input))
        local velocity = p8.velocity
        local v16 = velocity[1]
        local v17

        if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
            local v18 = math.abs(v16) * 7.1362384635298E+44
            local v19 = math.floor(v18)
            local v20 = v18 - v19

            v17 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

            if v16 < 0 then
                v17 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v16)
            v17 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v17, 2147483648)))

        local v22 = buffer.readf32(v1, 0) * p10.drift_drag
        local v23 = velocity[2]
        local v24

        if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
            local v25 = math.abs(v23) * 7.1362384635298E+44
            local v26 = math.floor(v25)
            local v27 = v25 - v26

            v24 = if v27 > 0.5 or v27 == 0.5 and v26 % 2 == 1 then v26 + 1 else v26

            if v23 < 0 then
                v24 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v23)
            v24 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v24, 2147483648)))

        local v29 = buffer.readf32(v1, 0) * p10.drift_drag
        local v30 = velocity[3]
        local v31

        if v30 ~= 0 and v30 > -1.1754943508222875E-38 and v30 < 1.1754943508222875E-38 then
            local v32 = math.abs(v30) * 7.1362384635298E+44
            local v33 = math.floor(v32)
            local v34 = v32 - v33

            v31 = if v34 > 0.5 or v34 == 0.5 and v33 % 2 == 1 then v33 + 1 else v33

            if v30 < 0 then
                v31 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v30)
            v31 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v31, 2147483648)))

        local v36 = buffer.readf32(v1, 0) * p10.drift_drag
        local v37 = velocity[4]
        local v38

        if v37 ~= 0 and v37 > -1.1754943508222875E-38 and v37 < 1.1754943508222875E-38 then
            local v39 = math.abs(v37) * 7.1362384635298E+44
            local v40 = math.floor(v39)
            local v41 = v39 - v40

            v38 = if v41 > 0.5 or v41 == 0.5 and v40 % 2 == 1 then v40 + 1 else v40

            if v37 < 0 then
                v38 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v37)
            v38 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v38, 2147483648)))

        local v15 = {
            v22,
            v29,
            v36,
            buffer.readf32(v1, 0) * p10.drift_drag
        }

        v15[1] *= 0.02
        v15[3] *= 0.02

        if v8.dot(p8.velocity, v8.normalize_or(v14, { 0, 0, 0, 0 })) < p10.drift_maximum_speed then
            v15 = v8.add(v15, v14)
        end

        local v44 = v8.scale(v15, 0.01666666753590107)
        local v45 = SkeletonBody.bodies_mut(p9)

        for i = 1, 23 do
            local v46 = v45[i + 1]

            v46.rates.linear_velocity.x += v44[1]
            v46.rates.linear_velocity.y += v44[2]
            v46.rates.linear_velocity.z += v44[3]
        end
    end
}
