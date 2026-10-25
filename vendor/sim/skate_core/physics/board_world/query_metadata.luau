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
local v1 = import("skate_core/math")
local Vector3, Basis3 = v1.Vector3, v1.Basis3
local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
local t1 = {}

local function affine_eq(p2, p3) -- line: 24
    -- upvalues: Vector3 (copy), Basis3 (copy)
    return Basis3.eq(p2.basis, p3.basis) and Vector3.eq(p2.translation, p3.translation)
end

t1.QueryPool = {}
t1.Bounds = {}

function t1.Bounds.expanded(p4, p5) -- line: 34
    -- upvalues: Vector3 (copy)
    return {
        min = Vector3.new(p4.min.x - p5, p4.min.y - p5, p4.min.z - p5),
        max = Vector3.new(p4.max.x + p5, p4.max.y + p5, p4.max.z + p5)
    }
end

function t1.Bounds.overlaps(p6, p7) -- line: 41
    return not (p6.max.x < p7.min.x
        or p6.min.x > p7.max.x
        or p6.max.y < p7.min.y
        or p6.min.y > p7.max.y
        or p6.max.z < p7.min.z
        or p6.min.z > p7.max.z)
end

function t1.Bounds.from_points(p8) -- line: 53
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy)
    local v2 = p8[1]

    if v2 == nil or not t1.finite(v2) then
        return nil
    end

    local t2 = {
        min = rt.copy(v2),
        max = rt.copy(v2)
    }

    for i = 2, #p8 do
        local v3 = p8[i]

        if not t1.finite(v3) then
            return nil
        end

        t2.min = Vector3.new(rt.fmin(t2.min.x, v3.x), rt.fmin(t2.min.y, v3.y), rt.fmin(t2.min.z, v3.z))
        t2.max = Vector3.new(rt.fmax(t2.max.x, v3.x), rt.fmax(t2.max.y, v3.y), rt.fmax(t2.max.z, v3.z))
    end

    return t2
end

function t1.Bounds.contains(p9, p10) -- line: 84
    -- upvalues: t1 (copy)
    return t1.finite(p10) and p10.x >= p9.min.x and p10.x <= p9.max.x and p10.y >= p9.min.y and p10.y <= p9.max.y and p10.z >= p9.min.z and p10.z <= p9.max.z
end

function t1.Bounds.valid(p11) -- line: 94
    -- upvalues: t1 (copy)
    return t1.finite(p11.min) and t1.finite(p11.max) and p11.min.x <= p11.max.x and p11.min.y <= p11.max.y and p11.min.z <= p11.max.z
end

t1.EdgeSegment = {}
t1.QueryMesh = {}
t1.QueryMetadata = {}

function t1.QueryMetadata.validate(p12, p13) -- line: 125
    -- upvalues: Vector3 (copy), Basis3 (copy), RetailAffineTransform (copy), t1 (copy)
    if #p12.packed_surfaces ~= #p13 then
        error("Query surface count must equal canonical triangle count", 0)
    end

    local n1 = 0

    for _, v5 in p12.meshes do
        if v5.triangle_range.start ~= n1 or v5.triangle_range["end"] <= n1 or v5.triangle_range["end"] > #p13 then
            error("Query meshes must partition canonical triangles in supplied order", 0)
        end

        local local_to_world = v5.local_to_world
        local IDENTITY = RetailAffineTransform.IDENTITY

        if Basis3.eq(local_to_world.basis, IDENTITY.basis) and Vector3.eq(local_to_world.translation, IDENTITY.translation) then
            local world_to_local = v5.world_to_local
            local IDENTITY = RetailAffineTransform.IDENTITY

            if not (Basis3.eq(world_to_local.basis, IDENTITY.basis) and Vector3.eq(world_to_local.translation, IDENTITY.translation)) then
                error("BoardWorld static query meshes require identity transforms", 0)
            end
        else
            error("BoardWorld static query meshes require identity transforms", 0)
        end

        if not t1.Bounds.valid(v5.local_bounds) then
            error("Invalid query mesh bounds", 0)
        end

        for i = v5.triangle_range.start, v5.triangle_range["end"] - 1 do
            for _, v6 in p13[i + 1].triangle.vertices do
                if not t1.Bounds.contains(v5.local_bounds, v6) then
                    error("Query mesh bounds exclude canonical triangle geometry", 0)
                end
            end
        end

        n1 = v5.triangle_range["end"]
    end

    if n1 ~= #p13 then
        error("Query metadata leaves canonical triangles unassigned", 0)
    end

    for _, v7 in p12.static_edges do
        if not t1.Bounds.valid(v7.local_bounds) or not t1.Bounds.contains(v7.local_bounds, v7.start) or not t1.Bounds.contains(v7.local_bounds, v7["end"]) then
            error("Invalid authored query edge", 0)
        end
    end
end

function t1.finite(p14) -- line: 173
    local x = p14.x
    local v8 = x == x and x ~= 1e999 and x ~= (-1e999)

    if not v8 then
        return v8
    end

    local y = p14.y
    local v9 = y == y and y ~= 1e999 and y ~= (-1e999)

    if not v9 then
        return v9
    end

    local z = p14.z

    if z ~= z or z == 1e999 then
        return false
    end

    return z ~= (-1e999)
end

return t1
