-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/angle_tracker")
local v2 = import("skate_core/camera/vector_tracker")
local v3 = import("skate_core/physics/reciprocal_sqrt")
local t1 = {}

function t1.direction_to_angles_reference(p1) -- line: 16
    -- upvalues: v1 (copy), v2 (copy), t1 (copy)
    local t2 = {
        p1[1],
        0,
        p1[3],
        0
    }
    local v4 = v2.length(t2)

    if not (v4 > 9.999999747378752E-05) then
        return { 0, 0, 0, 0 }
    end

    local v5 = v2.refined_reciprocal(v4)
    local v6 = v5 * t2[1]
    local v7 = v5 * t2[3]
    local n1 = 4.71238899230957

    if v6 >= 0 then
        if v7 >= 0 then
            n1 = 0
        else
            v6 = -v7
            n1 = 1.5707963705062866
        end
    elseif v7 <= 0 then
        v6 = -v6
        n1 = 3.1415927410125732
    else
        v6 = v7
    end

    local v8 = v1.normalize_angle(t1.asin_lane(t1.clamp(v6)) + n1)

    return {
        t1.asin_lane(t1.clamp(p1[2])),
        v8,
        0, 0
    }
end

function t1.clamp(p2) -- line: 41
    local v9 = if p2 < -1 then -1 else p2

    if v9 > 1 then
        return 1
    end

    return v9
end

function t1.asin_lane_reference(p3) -- line: 48
    -- upvalues: rt (copy), v3 (copy)
    local v10 = math.abs(p3)
    local v11 = p3 * p3 * v10
    local from_bits = rt.from_bits
    local v12 = from_bits(1074469001) * v10 + from_bits(3234936334)
    local v13 = from_bits(1046884934) * v10 + from_bits(3214425903)
    local v14 = from_bits(3201717587) * v10 + from_bits(1082753213)
    local v15 = from_bits(3178091565) * v10 + from_bits(1058920374)
    local v16 = v12 * v10 + from_bits(1085237976)
    local v17 = v13 * v10 + from_bits(1068860549)
    local v18 = v14 * v10 + from_bits(3230624473)
    local v19 = v15 * v10 + from_bits(3215934488)
    local v20 = v17 * v11 + v16
    local v21 = v19 * v11 + v18
    local v22 = from_bits(1065353217) - v10
    local v23 = v3.estimate(v22)
    local v24 = v23 * (-(v22 * 0.5) * (v23 * v23) + 0.5) + v23

    return (-v10 * p3 + p3) * v21 * v24 + p3 * v20
end

local length3, refined_reciprocal = v2.length3, v2.refined_reciprocal
local normalize_angle = v1.normalize_angle

function t1.asin_lane(p4) -- line: 96
    local v25 = math.abs(p4)
    local v26 = p4 * p4 * v25
    local v27 = v25 * 2.173372507095337 + -6.537848472595215
    local v28 = v25 * 0.22480115294456482 + -1.1894282102584839
    local v29 = v25 * -0.41861972212791443 + 4.2969651222229
    local v30 = v25 * -0.058063674718141556 + 0.6165727376937866
    local v31 = v27 * v25 + 5.481792449951172
    local v32 = v28 * v25 + 1.4181066751480103
    local v33 = v29 * v25 + -4.48179292678833
    local v34 = v30 * v25 + -1.3692655563354492
    local v35 = v32 * v26 + v31
    local v36 = v34 * v26 + v33
    local v37 = 1.0000001192092896 - v25
    local v38 = 1 / math.sqrt(v37)
    local v39 = v38 * (-(v37 * 0.5) * (v38 * v38) + 0.5) + v38

    return (-v25 * p4 + p4) * v36 * v39 + p4 * v35
end

local asin_lane2 = t1.asin_lane

local function heading_of(p5, p6) -- line: 120
    -- upvalues: length3 (copy), refined_reciprocal (copy), normalize_angle (copy), asin_lane2 (copy)
    local v40 = length3(p5, 0, p6)

    if not (v40 > 9.999999747378752E-05) then
        return nil
    end

    local v41 = refined_reciprocal(v40)
    local v42 = v41 * p5
    local v43 = v41 * p6
    local n2 = 4.71238899230957

    if v42 >= 0 then
        if v43 >= 0 then
            n2 = 0
        else
            v42 = -v43
            n2 = 1.5707963705062866
        end
    elseif v43 <= 0 then
        v42 = -v42
        n2 = 3.1415927410125732
    else
        v42 = v43
    end

    if v42 < -1 then
        v42 = -1
    end

    if v42 > 1 then
        v42 = 1
    end

    return normalize_angle(asin_lane2(v42) + n2)
end

function t1.direction_heading(p7, p8) -- line: 145
    -- upvalues: heading_of (copy)
    local v44 = heading_of(p7, p8)

    if v44 == nil then
        return 0
    end

    return v44
end

function t1.direction_to_angles_lanes(p9, p10, p11) -- line: 154
    -- upvalues: asin_lane2 (copy), heading_of (copy)
    local v45 = heading_of(p9, p11)

    if v45 == nil then
        return 0, 0
    end

    local v46 = if p10 < -1 then -1 else p10

    if v46 > 1 then
        v46 = 1
    end

    return asin_lane2(v46), v45
end

function t1.direction_to_angles(p12) -- line: 163
    -- upvalues: t1 (copy)
    local v47, v48 = t1.direction_to_angles_lanes(p12[1], p12[2], p12[3])

    return { v47, v48, 0, 0 }
end

return t1
