-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/trajectory/math")
local v2 = import("skate_core/trigonometry")
local v3 = import("skate_core/air/trajectory/grind_surface/orientation")
local UP, dot, sub, scale = v1.UP, v1.dot, v1.sub, v1.scale
local cross, inverse_length, reciprocal, length = v1.cross, v1.inverse_length, v1.reciprocal, v1.length
local normalize = v1.normalize

local function grind_surface() -- line: 15
    -- upvalues: import (copy)
    return import("skate_core/air/trajectory/grind_surface")
end

local t1 = {}

function t1.resolve(p1, p2, p3) -- line: 24
    -- upvalues: rt (copy), import (copy), v2 (copy), v3 (copy), UP (copy), dot (copy), sub (copy), scale (copy), cross (copy), inverse_length (copy), reciprocal (copy), length (copy), t1 (copy)
    local v4 = import("skate_core/air/trajectory/grind_surface")
    local GeometryType, GrindSurface = v4.GeometryType, v4.GrindSurface
    local v5 = rt.copy(p2[1])
    local v6 = rt.copy(p2[2])
    local v7 = rt.copy(p2[3])
    local v8 = rt.copy(p2[4])
    local v9 = rt.copy(p2[5])
    local v10 = rt.copy(p2[6])
    local v11 = rt.copy(p2[7])

    if #p1.probes ~= 7 then
        v11 = nil
    end

    local v12 = v5 ~= nil and v6 ~= nil or v10 ~= nil
    local v13 = if v12 then GeometryType.Impossible
        elseif v5 == nil then if v6 == nil then GeometryType.ThinRail elseif v8 == nil or not (v8.fraction < 0.6499999761581421) then GeometryType.FatRail else GeometryType.Ledge
        elseif v7 == nil or not (v7.fraction < 0.6499999761581421) then GeometryType.FatRail
        else GeometryType.Ledge
    local v14 = cross(UP, p1.direction)
    local v15 = scale(v14, inverse_length(dot(v14, v14)))

    if not v12 and v5 == nil and v6 ~= nil then
        v15 = scale(v15, -1)
    end

    local v16 = v13 == GeometryType.Ledge and t1.is_curb(v7, v8, p1.upmost_normal, p1.center)
    local v17 = v5 == nil
    local v18 = if not v17 then bit32.band(v5.packed_surface, 3968) == 1024 else nil
    local v19 = not not (not v17 and v18) or v6 ~= nil and bit32.band(v6.packed_surface, 3968) == 1024
    local v20 = v11 ~= nil and t1.optional_normal_test(v11, p1.center, p1.direction)
    local v21 = v11 == nil or not (v11.position[2] - p1.center[2] > -1)
    local v24 = bit32.band(p3, (bit32.bnot((bit32.bor(GrindSurface.INVALID, GrindSurface.CURB, GrindSurface.STAIR, GrindSurface.OPTIONAL_NORMAL_TEST, GrindSurface.OPTIONAL_DROP_TEST)))))

    if v12 then
        v24 = bit32.bor(v24, GrindSurface.BLOCKED_CROSS_SECTION)
    end

    if v16 then
        v24 = bit32.bor(v24, GrindSurface.CURB)
    end

    if v19 then
        v24 = bit32.bor(v24, GrindSurface.STAIR)
    end

    if v20 then
        v24 = bit32.bor(v24, GrindSurface.OPTIONAL_NORMAL_TEST)
    end

    if v21 then
        v24 = bit32.bor(v24, GrindSurface.OPTIONAL_DROP_TEST)
    end

    local v25, v26 = t1.surface_info(v13, v16, { v5, v6, v7, v8, v9 })
    local t2 = {
        if v7 == nil then rt.copy(p1.probes[3]["end"]) else rt.copy(v7.position),
        if v8 == nil then rt.copy(p1.probes[4]["end"]) else rt.copy(v8.position)
    }
    local v29 = scale(p1.upmost_normal, -1)
    local t3 = {}

    for i = 1, 2 do
        local v30 = sub(t2[i], p1.center)
        local v31 = scale(v30, reciprocal(length(v30)))

        t3[i] = v2.acos(rt.fmin(rt.fmax(dot(v29, v31), -1), 1))
    end

    local t4 = {
        t3[1] + 1.5707963705062866 + 0.27925267815589905,
        6.2831854820251465 - t3[2] - 1.5707963705062866 - 0.27925267815589905
    }
    local v32 = v3.tilted_normal(p1.direction, p1.upmost_normal, t4)

    return {
        center = rt.copy(p1.center),
        far_points = t2,
        upmost_normal = rt.copy(p1.upmost_normal),
        direction = rt.copy(p1.direction),
        high_side = v15,
        normal_limits = t4,
        kind = v13,
        audio_surface = v25,
        physics_surface = v26,
        flags = v24,
        tilted_upmost_normal = v32
    }
end

function t1.is_curb(p4, p5, p6, p7) -- line: 131
    -- upvalues: dot (copy), sub (copy)
    if p4 == nil or p5 == nil or not (dot(p6, p4.normal) > 0.99 and dot(p6, p5.normal) > 0.99) then
        return false
    end

    local v33 = dot(sub(p4.position, p7), p6)
    local v34 = dot(sub(p5.position, p7), p6)

    if not (v34 <= v33) then
        v33, v34 = v34, v33
    end

    if v33 > -0.035 and v33 < 0.035 and v34 > -0.24 then
        return v34 < -0.2
    end

    return false
end

function t1.optional_normal_test(p8, p9, p10) -- line: 149
    -- upvalues: dot (copy), sub (copy), scale (copy), normalize (copy)
    local v35 = dot(p8.normal, normalize(p10))
    local v37 = normalize(if v35 > 0 then sub(p8.normal, scale(p10, v35)) else p8.normal)

    if v37[2] < 0.8999999761581421 then
        local v38 = sub(p8.position, p9)

        v38[2] = 0

        return dot(v38, v37) > 0
    end

    return false
end

function t1.surface_info(p11, p12, p13) -- line: 164
    -- upvalues: import (copy), t1 (copy)
    if p12 then
        return 4, 2
    end

    if p11 == import("skate_core/air/trajectory/grind_surface").GeometryType.ThinRail then
        return if p13[5] == nil then 11 else bit32.band(p13[5].packed_surface, 127), 4
    end

    for _, v40 in { 0, 2 } do
        local v41 = p13[v40 + 1]
        local v42 = p13[v40 + 2]

        if v41 == nil or v42 == nil then
            if v41 ~= nil then
                v42 = v41
            end
        elseif v41.position[2] > v42.position[2] then
            v42 = v41
        end

        if v42 ~= nil then
            return t1.unpack(v42.packed_surface)
        end
    end

    if p13[5] == nil then
        return 3, 1
    end

    return t1.unpack(p13[5].packed_surface)
end

function t1.unpack(p14) -- line: 193
    return bit32.band(p14, 127), (bit32.band(bit32.rshift(p14, 7), 31))
end

return t1
