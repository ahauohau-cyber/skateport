-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/physics/reciprocal_sqrt")
local v3 = import("skate_core/air/trajectory")
local v4

local function toolkit() -- line: 14
    -- upvalues: import (copy), v4 (ref)
    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v4
end

local function cross(p1, p2) -- line: 20
    -- upvalues: import (copy), v4 (ref)
    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v4.cross(p1, p2)
end

local function dot(p3, p4) -- line: 23
    -- upvalues: import (copy), v4 (ref)
    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v4.dot(p3, p4)
end

local function length(p5) -- line: 26
    -- upvalues: import (copy), v4 (ref)
    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v4.length(p5)
end

local function scale(p6, p7) -- line: 29
    -- upvalues: import (copy), v4 (ref)
    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v4.scale(p6, p7)
end

local function sub(p8, p9) -- line: 32
    -- upvalues: import (copy), v4 (ref)
    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v4.sub(p8, p9)
end

local QueryResult = v3.QueryResult
local estimate = import("skate_core/physics/reciprocal_sqrt").estimate
local reciprocal, landing_normal
local t1 = {}

function t1.query_sweep(p10, p11, p12) -- line: 50
    -- upvalues: rt (copy), import (copy), v4 (ref), QueryResult (copy), reciprocal (ref), landing_normal (ref)
    local v5, start = p10["end"], p10.start

    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v6 = v4.sub(v5, start)

    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v7 = v4.dot(v6, v6) > 0 and (math.abs(v6[1]) > 1.52587890625E-05 or math.abs(v6[2]) > 1.52587890625E-05 or math.abs(v6[3]) > 1.52587890625E-05)

    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    if not (v4.dot(v6, v6) > 0 and v7) then
        return QueryResult.miss()
    end

    local v11 = p11(rt.copy(p10))

    if v11 == nil then
        return QueryResult.miss()
    end

    local position = v11.position
    local start2 = p10.start

    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v12 = v4.sub(position, start2)

    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v13 = v4.length(v12)

    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v14 = v4.length(v6)
    local v15 = if not (math.abs(v13) > 9.999999747378752E-05 and math.abs(v14) > 9.999999747378752E-05) then 0 else reciprocal(v14) * v13
    local v16 = rt.f_to_i32((math.floor(v15)))
    local v17 = p12(rt.copy(v11.position), p10.radius)

    return {
        contact_position = rt.copy(v11.position),
        contact_normal = rt.copy(v11.normal),
        landing_normal = landing_normal(v17, v6),
        contact_time = v15 * 0.01666666753590107,
        contact_frame = v16,
        contact_transform = rt.copy(v11.mesh_frame),
        surface = v11.surface,
        geometry = v11.geometry
    }
end

function t1.reciprocal(p13) -- line: 95
    -- upvalues: v1 (copy)
    local v18 = v1.reciprocal_estimate(p13)
    local v19 = v18 * (-v18 * p13 + 1) + v18

    return v19 * (-v19 * p13 + 1) + v19
end

reciprocal = t1.reciprocal

function t1.inverse_length(p14) -- line: 105
    -- upvalues: v2 (copy)
    local v20 = v2.estimate(p14)
    local v21 = v20 * 0.5 * (-p14 * (v20 * v20) + 1) + v20

    return v21 * 0.5 * (-p14 * (v21 * v21) + 1) + v21
end

local inverse_length = t1.inverse_length
local v22 = false

function t1.set_reference(p15) -- line: 119
    -- upvalues: v22 (ref)
    v22 = p15
end

local v23 = table.create(64, 0)
local v24 = table.create(64, 0)
local v25 = table.create(64, 0)
local v26 = table.create(64, 0)

function t1.landing_normal(p16, p17) -- line: 133
    -- upvalues: rt (copy), import (copy), v4 (ref), estimate (copy), t1 (copy), v22 (ref), v23 (copy), v24 (copy), v25 (copy), v26 (copy)
    if v22 then
        return t1.landing_normal_reference(p16, p17)
    end

    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v27 = v4
    local ZERO = v27.ZERO
    local v28 = p17[1]
    local v29 = p17[2]
    local v30 = p17[3]
    local v31 = ZERO[1]
    local v32 = ZERO[2]
    local v33 = ZERO[3]
    local n1 = 0
    local n2 = -1

    for i = 1, math.min(#p16, 64) do
        local v36 = p16[i]
        local v37 = v36[1]
        local v38 = v36[2]
        local v39 = v36[3]
        local v40 = v37[1]
        local v41 = v37[2]
        local v42 = v37[3]
        local v43 = v38[1] - v40
        local v44 = v38[2] - v41
        local v45 = v38[3] - v42
        local v46 = v39[1] - v40
        local v47 = v39[2] - v41
        local v48 = v39[3] - v42
        local v49 = -v45 * v47 + v44 * v48
        local v50 = -v43 * v48 + v45 * v46
        local v51 = -v44 * v46 + v43 * v47
        local v52 = v49 * v49 + v50 * v50 + v51 * v51
        local v53 = estimate(v52)
        local v54 = v53 * 0.5 * (-v52 * (v53 * v53) + 1) + v53
        local v55 = v54 * 0.5 * (-v52 * (v54 * v54) + 1) + v54
        local v56 = v49 * v55
        local v57 = v50 * v55
        local v58 = v51 * v55
        local v59 = 0 * v55
        local v60, v61, v62, v63, v64

        if v57 > 0.7 or v56 * v28 + v57 * v29 + v58 * v30 <= 0 then
            local v65, v66, v67, v68

            if n2 < v57 then
                v65 = v57
                v66 = v56
                v67 = v57
                v68 = v58
            else
                v65 = n2
                v66 = v31
                v67 = v32
                v68 = v33
            end

            v61 = v65
            v60 = n1 + 1
            v23[v60] = v56
            v24[v60] = v57
            v25[v60] = v58
            v26[v60] = v59
            v62 = v66
            v63 = v67
            v64 = v68
        else
            v61 = n2
            v60 = n1
            v62 = v31
            v63 = v32
            v64 = v33
        end

        n2 = v61
        n1 = v60
        v31 = v62
        v32 = v63
        v33 = v64
    end

    if n1 == 0 then
        return rt.copy(v27.UP)
    end

    local v69 = ZERO[1]
    local v70 = ZERO[2]
    local v71 = ZERO[3]
    local v72 = ZERO[4]

    for i = 1, n1 do
        local v73 = v23[i]
        local v74 = v24[i]
        local v75 = v25[i]

        if v31 * v73 + v32 * v74 + v33 * v75 > 0.5 then
            v69 += v73
            v70 += v74
            v71 += v75
            v72 += v26[i]
        end
    end

    local v76 = v69 * v69 + v70 * v70 + v71 * v71
    local v77 = estimate(v76)
    local v78 = v77 * 0.5 * (-v76 * (v77 * v77) + 1) + v77
    local v79 = v78 * 0.5 * (-v76 * (v78 * v78) + 1) + v78

    if (if v76 == 0 then 0 else v76 * v79) > 9.999999974752427E-07 then
        return {
            v69 * v79,
            v70 * v79,
            v71 * v79,
            v72 * v79
        }
    end

    return rt.copy(v27.ZERO)
end

function t1.landing_normal_reference(p18, p19) -- line: 191
    -- upvalues: rt (copy), import (copy), v4 (ref), dot (copy), scale (copy), inverse_length (copy)
    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v80 = v4
    local t2 = {}
    local v81 = rt.copy(v80.ZERO)
    local n3 = -1

    for i = 1, math.min(#p18, 64) do
        local v84 = p18[i]
        local v85 = v84[1]
        local v86 = v84[2]
        local v87 = v84[3]

        if v4 == nil then
            v4 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v88 = v4.sub(v86, v85)

        if v4 == nil then
            v4 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v89 = v4.sub(v87, v85)

        if v4 == nil then
            v4 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v90 = v4.cross(v88, v89)
        local v91 = inverse_length(dot(v90, v90))

        if v4 == nil then
            v4 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v92 = v4.scale(v90, v91)
        local v93, v94, v95

        if v92[2] > 0.7 then
            v95 = false
        else
            if v4 == nil then
                v4 = import("skate_core/player/offboard/contact_toolkit")
            end

            if v4.dot(v92, p19) <= 0 then
                v95 = false
            else
                v94 = v81
                v93 = n3
                v95 = true
            end
        end

        if not v95 then
            if n3 < v92[2] then
                v94 = rt.copy(v92)
                v93 = v92[2]
            else
                v93 = n3
                v94 = v81
            end

            table.insert(t2, v92)
        end

        n3 = v93
        v81 = v94
    end

    if #t2 == 0 then
        return rt.copy(v80.UP)
    end

    local v97 = rt.copy(v80.ZERO)

    for _, v98 in t2 do
        if v4 == nil then
            v4 = import("skate_core/player/offboard/contact_toolkit")
        end

        if v4.dot(v81, v98) > 0.5 then
            v97[1] += v98[1]
            v97[2] += v98[2]
            v97[3] += v98[3]
            v97[4] += v98[4]
        end
    end

    if v4 == nil then
        v4 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v99 = v4.dot(v97, v97)
    local v100 = inverse_length(v99)

    if (if v99 == 0 then 0 else v99 * v100) > 9.999999974752427E-07 then
        return scale(v97, v100)
    end

    return rt.copy(v80.ZERO)
end

landing_normal = t1.landing_normal

return t1
