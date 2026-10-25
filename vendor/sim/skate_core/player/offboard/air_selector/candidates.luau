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
local v1 = import("skate_core/player/offboard/air_selector/math")
local v2 = import("skate_core/player/offboard/air_launch/math")
local Candidate = import("skate_core/player/offboard/biped_air/selection").Candidate
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local v3 = import("skate_core/trigonometry")

local function air_selector() -- line: 18
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/air_selector")
end

local add, cross, length, madd = v1.add, v1.cross, v1.length, v1.madd
local normalize_or, reciprocal, scale, sub = v1.normalize_or, v1.reciprocal, v1.scale, v1.sub
local UP, flatten, shift = v1.UP, v1.flatten, v1.shift
local sanitize_w_lane, xyz_finite = v2.sanitize_w_lane, v2.xyz_finite
local t1 = {}

function t1.sanitize_packet(p2) -- line: 32
    -- upvalues: rt (copy), sanitize_w_lane (copy)
    local v4 = rt.copy(p2)

    v4.velocity_0 = sanitize_w_lane(v4.velocity_0)
    v4.secondary_velocity_16 = sanitize_w_lane(v4.secondary_velocity_16)
    v4.position_32 = sanitize_w_lane(v4.position_32)
    v4.up_48 = sanitize_w_lane(v4.up_48)
    v4.forward_64 = sanitize_w_lane(v4.forward_64)
    v4.board_position_80 = sanitize_w_lane(v4.board_position_80)

    return v4
end

function t1.prepare(p3, p4, p5) -- line: 45
    -- upvalues: rt (copy), import (copy), Candidate (copy), inverse_length_squared (copy), v3 (copy), add (copy), cross (copy), length (copy), madd (copy), normalize_or (copy), reciprocal (copy), scale (copy), sub (copy), UP (copy), flatten (copy), shift (copy), sanitize_w_lane (copy), xyz_finite (copy), t1 (copy)
    local v5 = import("skate_core/player/offboard/air_selector")
    local DT, MAX_CANDIDATES = v5.DT, v5.MAX_CANDIDATES
    local v6 = t1.sanitize_packet(p3)
    local v7 = sanitize_w_lane(p4)
    local v8 = v6.kind_108 + v6.kind_112

    if v8 > 4294967295 then
        error("BipedAir candidate count overflow", 0)
    end

    local v9 = false
    local v10 = false
    local v11 = false
    local v12 = false
    local v13 = false

    if v6.kind_108 == 0 then
    else
        v9 = true
    end

    if v9 then
        if MAX_CANDIDATES < v8 then
            v13 = false
        else
            v10 = true
        end
    end

    v9 = false

    local height, v14

    if v10 then
        height = p5.height

        if height == height then
            v9 = true
        else
            v14 = false
            v11 = true
        end
    end

    v10 = false

    if v9 then
        if height == 1e999 then
            v14 = false
            v11 = true
        else
            v10 = true
        end
    end

    v9 = false

    if v10 then
        if height == (-1e999) then
            v12 = true
        else
            v9 = true
        end
    end

    v10 = false

    if v9 then
        v14 = true
        v11 = true
    end

    v9 = false

    if v12 then
        v14 = false
        v11 = true
    end

    v12 = false

    if v11 then
        if v14 then
            v12 = true
        else
            v13 = false
        end
    end

    v11 = false

    local sphere_radius, v15

    if v12 then
        sphere_radius = p5.sphere_radius

        if sphere_radius == sphere_radius then
            v11 = true
        else
            v15 = false
            v9 = true
        end
    end

    v12 = false

    if v11 then
        if sphere_radius == 1e999 then
            v15 = false
            v9 = true
        else
            v12 = true
        end
    end

    v11 = false

    if v12 then
        if sphere_radius == (-1e999) then
            v10 = true
        else
            v11 = true
        end
    end

    if v11 then
        v15 = true
        v9 = true
    end

    if v10 then
        v15 = false
        v9 = true
    end

    v10 = false

    if v9 then
        if v15 then
            v10 = true
        else
            v13 = false
        end
    end

    if v10 then
        v13 = not (p5.sphere_radius <= 0)
    end

    if not v13 then
        error("Invalid authored BipedAir selector settings", 0)
    end

    local scalar_96 = v6.scalar_96
    local v16 = not (scalar_96 == scalar_96 and scalar_96 ~= 1e999 and scalar_96 ~= (-1e999))
    local v17

    if v16 then
        v17 = v16
    else
        local scalar_100 = v6.scalar_100
        local v18 = not (scalar_100 == scalar_100 and scalar_100 ~= 1e999 and scalar_100 ~= (-1e999))

        if v18 then
            v17 = v18
        else
            local scalar_104 = v6.scalar_104

            v17 = not (scalar_104 == scalar_104 and scalar_104 ~= 1e999 and scalar_104 ~= (-1e999))
        end
    end

    local v19 = true

    if not v17 then
        for _, v20 in {
                v6.velocity_0,
                v6.secondary_velocity_16,
                v6.position_32,
                v6.up_48,
                v6.forward_64,
                v6.board_position_80,
                v7
            } do
            if not xyz_finite(v20) then
                v19 = false
                break
            end

            v19 = true
        end
    end

    if v17 or not v19 then
        error("Nonfinite BipedAir launch packet", 0)
    end

    local v21 = scale(UP, -(p5.height - p5.sphere_radius))
    local v22 = {
        0, 0.1, 0, 0
    }

    if v6.has_board_position_116 then
        v22 = add(v22, sub(v6.board_position_80, add(v6.position_32, v21)))
    end

    local v23 = add(v21, v22)
    local v24 = sub(v6.velocity_0, scale(v22, reciprocal(1)))
    local v25 = rt.filled(v8, v24)

    if v8 > 1 then
        local v26 = length(v6.velocity_0)
        local v27, v28

        if v26 >= 0.001 then
            v27 = scale(v6.velocity_0, reciprocal(v26))

            local v29 = cross(UP, v27)

            if length(v29) < 0.1 then
                v29 = cross(v27, v6.forward_64)
            end

            v28 = scale(v29, reciprocal(length(v29)))
        else
            v27 = rt.copy(UP)
            v28 = scale(v6.forward_64, -1)
        end

        local v30 = cross(v27, v28)
        local t2 = {
            math.tan(v6.scalar_96),
            math.tan(v6.scalar_100),
            (math.tan(v6.scalar_104))
        }
        local v33 = length(v24)
        local v34 = length(flatten(v6.velocity_0))

        for i = 1, v6.kind_108 - 1 do
            local v35 = (1 - i / (v6.kind_108 - 1) * 2) * 3.141592653589793
            local v36 = v3.sin(v35)
            local v37 = v3.cos(v35)
            local v39 = madd(v30, v37 * (if v37 <= 0 then t2[2] else t2[3]), madd(v28, v36 * t2[1], v24))

            v25[i + 1] = scale(v39, v33 * reciprocal(length(v39)))
            v34 = rt.fmin(v34, length(flatten(v25[i + 1])))
        end

        if v6.kind_112 > 0 then
            local v40 = flatten(v6.secondary_velocity_16)
            local v41 = length(v40)
            local v42 = if v41 > 0.01 then scale(v40, reciprocal(v41)) else normalize_or(v6.forward_64, { 0, 0, 0, 0 })
            local v43 = rt.fmin(rt.fmax(v34, 1), 4) / (v6.kind_112 + 1)
            local v44 = 21.168001174926758 * inverse_length_squared(21.168001174926758, 2)
            local kind_108 = v6.kind_108
            local v45 = v8 - 1
            local n1 = 0

            for i = kind_108, v45 do
                n1 += v43
                v25[i + 1] = madd(v42, n1, { 0, v44, 0, 0 })
            end
        end
    end

    local v46 = table.create(v8)

    for _, v47 in v25 do
        local t3 = {
            duration = 2,
            position = add(v6.position_32, v23),
            velocity = rt.copy(v47),
            acceleration = rt.copy(v7)
        }

        shift(t3, p5.start_index * DT)
        v5.validate_request(v5.request(t3, p5.sphere_radius))

        local v48 = Candidate.reset()

        v48.trajectory = rt.copy(t3)
        v48.start_frame_112 = p5.start_index
        table.insert(v46, v48)
    end

    return v46, v23, v21
end

return t1
