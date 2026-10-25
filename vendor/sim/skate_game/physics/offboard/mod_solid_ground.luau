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
local v2 = import("skate_core/player/offboard/ground_query")
local Vector3 = v1.Vector3
local Frame = v2.Frame
local t1 = {
    parry = nil
}

local function compute_aabb(p2, p3) -- line: 34
    -- upvalues: t1 (copy)
    local parry = t1.parry

    if parry == nil then
        error("mod_solid_ground: parry compute_aabb is not available (no M.parry host installed)", 0)
    end

    return parry.compute_aabb(p2, p3)
end

t1.VEHICLE_GROUP = 8

local VEHICLE_GROUP = t1.VEHICLE_GROUP

local function vec3(p4, p5, p6) -- line: 49
    -- upvalues: Vector3 (copy)
    return Vector3.new(p4, p5, p6)
end

local function min_vec(p7, p8) -- line: 54
    -- upvalues: rt (copy), Vector3 (copy)
    return Vector3.new(rt.fmin(p7.x, p8.x), rt.fmin(p7.y, p8.y), rt.fmin(p7.z, p8.z))
end

local function max_vec(p9, p10) -- line: 59
    -- upvalues: rt (copy), Vector3 (copy)
    return Vector3.new(rt.fmax(p9.x, p10.x), rt.fmax(p9.y, p10.y), rt.fmax(p9.z, p10.z))
end

local function dot(p11, p12) -- line: 64
    return p11.x * p12.x + (p11.y * p12.y + p11.z * p12.z)
end

local function vector_finite(p13) -- line: 69
    local x = p13.x
    local v3 = x == x and x ~= 1e999 and x ~= (-1e999)

    if not v3 then
        return v3
    end

    local y = p13.y
    local v4 = y == y and y ~= 1e999 and y ~= (-1e999)

    if not v4 then
        return v4
    end

    local z = p13.z

    if z ~= z or z == 1e999 then
        return false
    end

    return z ~= (-1e999)
end

local function glam_length_squared(p14) -- line: 74
    return p14.x * p14.x + p14.y * p14.y + p14.z * p14.z
end

local function is_moving(p15) -- line: 79
    local linvel, angvel = p15.linvel, p15.angvel

    if linvel.x * linvel.x + linvel.y * linvel.y + linvel.z * linvel.z > 0.0010000000474974513 then
        return true
    end

    return angvel.x * angvel.x + angvel.y * angvel.y + angvel.z * angvel.z > 0.0010000000474974513
end

local function solid_world_aabb(p16) -- line: 87
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy)
    local v5 = Vector3.new(1e999, 1e999, 1e999)
    local v6 = Vector3.new((-1e999), (-1e999), (-1e999))

    for _, v7 in ipairs(p16.colliders) do
        local shape, pose = v7.shape, v7.pose
        local parry = t1.parry

        if parry == nil then
            error("mod_solid_ground: parry compute_aabb is not available (no M.parry host installed)", 0)
        end

        local v8 = parry.compute_aabb(shape, pose)
        local x, y, z = v8.mins.x, v8.mins.y, v8.mins.z
        local v9 = Vector3.new(x, y, z)

        v5 = Vector3.new(rt.fmin(v5.x, v9.x), rt.fmin(v5.y, v9.y), rt.fmin(v5.z, v9.z))

        local x2, y2, z2 = v8.maxs.x, v8.maxs.y, v8.maxs.z
        local v10 = Vector3.new(x2, y2, z2)

        v6 = Vector3.new(rt.fmax(v6.x, v10.x), rt.fmax(v6.y, v10.y), rt.fmax(v6.z, v10.z))
    end

    local x = v5.x
    local v11 = x == x and x ~= 1e999 and x ~= (-1e999)
    local v12

    if v11 then
        local y = v5.y
        local v13 = y == y and y ~= 1e999 and y ~= (-1e999)

        if v13 then
            local z = v5.z

            v12 = z == z and z ~= 1e999 and z ~= (-1e999)
        else
            v12 = v13
        end
    else
        v12 = v11
    end

    if v12 then
        return v5, v6
    end

    local x2, y, z = p16.center_of_mass.x, p16.center_of_mass.y, p16.center_of_mass.z
    local v14 = Vector3.new(x2, y, z)

    return Vector3.new(v14.x - 1, v14.y - 1, v14.z - 1), Vector3.new(v14.x + 1, v14.y + 1, v14.z + 1)
end

local function segment_bounds(p17, p18) -- line: 105
    -- upvalues: rt (copy), Vector3 (copy)
    local v15 = Vector3.new(1e999, 1e999, 1e999)
    local v16 = Vector3.new((-1e999), (-1e999), (-1e999))

    for i = p18, #p17 - 1 do
        local v17 = p17[i + 1]
        local start, v18 = v17.edge.start, v17.edge["end"]
        local v19 = Vector3.new(rt.fmin(start.x, v18.x), rt.fmin(start.y, v18.y), rt.fmin(start.z, v18.z))

        v15 = Vector3.new(rt.fmin(v15.x, v19.x), rt.fmin(v15.y, v19.y), rt.fmin(v15.z, v19.z))

        local start2, v20 = v17.edge.start, v17.edge["end"]
        local v21 = Vector3.new(rt.fmax(start2.x, v20.x), rt.fmax(start2.y, v20.y), rt.fmax(start2.z, v20.z))

        v16 = Vector3.new(rt.fmax(v16.x, v21.x), rt.fmax(v16.y, v21.y), rt.fmax(v16.z, v21.z))
    end

    return v15, v16
end

local function inverse_point(p19, p20) -- line: 117
    -- upvalues: Vector3 (copy)
    local v22 = Vector3.new(p19[1][1], p19[1][2], p19[1][3])
    local v23 = Vector3.new(p19[2][1], p19[2][2], p19[2][3])
    local v24 = Vector3.new(p19[3][1], p19[3][2], p19[3][3])
    local v25 = Vector3.new(p19[4][1], p19[4][2], p19[4][3])
    local v26 = Vector3.new(p20.x - v25.x, p20.y - v25.y, p20.z - v25.z)

    return {
        v22.x * v26.x + (v22.y * v26.y + v22.z * v26.z),
        v23.x * v26.x + (v23.y * v26.y + v23.z * v26.z),
        v24.x * v26.x + (v24.y * v26.y + v24.z * v26.z),
        0
    }
end

t1.VehicleEdgeCache = {}

local VehicleEdgeCache = t1.VehicleEdgeCache

t1.EdgeBodyStorage = {}

function t1.VehicleEdgeCache.push_solid(p21, p22) -- line: 136
    -- upvalues: rt (copy), Vector3 (copy), Frame (copy), t1 (copy), segment_bounds (copy)
    local v27 = #p21.segments

    for _, v28 in ipairs(p22.colliders) do
        local shape, pose = v28.shape, v28.pose
        local parry = t1.parry

        if parry == nil then
            error("mod_solid_ground: parry compute_aabb is not available (no M.parry host installed)", 0)
        end

        local v29 = parry.compute_aabb(shape, pose)
        local x, y, z = v29.mins.x, v29.mins.y, v29.mins.z
        local v30 = Vector3.new(x, y, z)
        local x2, y2, z2 = v29.maxs.x, v29.maxs.y, v29.maxs.z
        local v31 = Vector3.new(x2, y2, z2)
        local y3 = v31.y
        local t2 = {
            {
                Vector3.new(v30.x, y3, v30.z),
                Vector3.new(v31.x, y3, v30.z)
            },
            {
                Vector3.new(v31.x, y3, v30.z),
                Vector3.new(v31.x, y3, v31.z)
            },
            {
                Vector3.new(v31.x, y3, v31.z),
                Vector3.new(v30.x, y3, v31.z)
            },
            {
                Vector3.new(v30.x, y3, v31.z),
                Vector3.new(v30.x, y3, v30.z)
            }
        }

        for _, v32 in ipairs(t2) do
            local v33 = v32[1]
            local v34 = v32[2]
            local v35 = Vector3.new(rt.fmin(v33.x, v34.x), rt.fmin(v33.y, v34.y), rt.fmin(v33.z, v34.z))
            local v36 = Vector3.new(rt.fmax(v33.x, v34.x), rt.fmax(v33.y, v34.y), rt.fmax(v33.z, v34.z))

            table.insert(p21.segments, {
                edge = {
                    start = v33,
                    ["end"] = v34
                },
                local_bounds = {
                    min = v35,
                    max = v36
                }
            })
        end
    end

    if v27 == #p21.segments then
        return
    end

    local v37, v38 = segment_bounds(p21.segments, v27)

    table.insert(p21.bodies, {
        frame = rt.copy(Frame.IDENTITY),
        local_bounds = {
            min = v37,
            max = v38
        },
        segment_range = {
            start = v27,
            ["end"] = #p21.segments
        }
    })
end

function t1.VehicleEdgeCache.build(p23) -- line: 176
    -- upvalues: VEHICLE_GROUP (copy), VehicleEdgeCache (copy)
    local t5 = {
        bodies = {},
        segments = {}
    }

    for _, v39 in ipairs(p23) do
        local v40 = v39[2]

        if v40.contact_group == VEHICLE_GROUP then
            VehicleEdgeCache.push_solid(t5, v40)
        end
    end

    return t5
end

function t1.VehicleEdgeCache.vehicles(p24) -- line: 191
    -- upvalues: rt (copy)
    local v41 = table.create(#p24.bodies)

    for _, v42 in ipairs(p24.bodies) do
        table.insert(v41, {
            local_to_world = rt.copy(v42.frame),
            local_bounds = rt.copy(v42.local_bounds),
            segments = rt.slice(p24.segments, v42.segment_range.start, v42.segment_range["end"])
        })
    end

    return v41
end

function t1.VehicleEdgeCache.primary_edges(_, p26) -- line: 205
    return {
        tag = "Normal",
        dynamic = {},
        vehicles = p26
    }
end

function t1.VehicleEdgeCache.with_primary_edges(p27, p28) -- line: 214
    -- upvalues: VehicleEdgeCache (copy)
    local v43 = VehicleEdgeCache.vehicles(p27)

    return p28(VehicleEdgeCache.primary_edges(p27, v43))
end

t1.VehicleCandidate = {}

function t1.VehicleCandidate.eq(p29, p30) -- line: 223
    return p29.id == p30.id
end

function t1.probe_vehicle(p31, p32) -- line: 228
    -- upvalues: rt (copy), Vector3 (copy), VEHICLE_GROUP (copy), solid_world_aabb (copy)
    local t7 = nil
    local v44 = rt.F32_MAX

    for _, v45 in ipairs(p31) do
        local v46 = v45[2]

        if v46.contact_group == VEHICLE_GROUP then
            local v47, v48 = solid_world_aabb(v46)

            if not (p32[1] < v47.x - 1 or p32[1] > v48.x + 1 or p32[3] < v47.z - 1 or p32[3] > v48.z + 1) then
                local v49 = p32[2] - v48.y

                if not (v49 < -0.6 or v49 > 1.2) then
                    local v50 = Vector3.new((v47.x + v48.x) * 0.5, v48.y, (v47.z + v48.z) * 0.5)
                    local v51 = p32[1] - v50.x
                    local v52 = p32[3] - v50.z
                    local v53 = v51 * v51 + v52 * v52

                    if v53 < v44 then
                        v44 = v53
                        t7 = {
                            id = v46.id
                        }
                    end
                end
            end
        end
    end

    return t7
end

function t1.classify_vehicle(p33, p34, p35, p36) -- line: 263
    -- upvalues: Vector3 (copy), solid_world_aabb (copy), inverse_point (copy)
    local linvel, angvel = p33.linvel, p33.angvel

    if not (linvel.x * linvel.x + linvel.y * linvel.y + linvel.z * linvel.z > 0.0010000000474974513 or angvel.x * angvel.x + angvel.y * angvel.y + angvel.z * angvel.z > 0.0010000000474974513) then
        return false
    end

    local v54, v55 = solid_world_aabb(p33)
    local y = v55.y

    if p34[2] < y - 0.35 or p34[2] > y + 1.5 then
        return false
    end

    local v56 = inverse_point(p35.frame, Vector3.new(p34[1], p34[2], p34[3]))
    local margin = p36.margin
    local v57 = true

    for i = 0, 2 do
        if not (v56[i + 1] + margin >= -p35.extents[i + 1] and v56[i + 1] - margin <= p35.extents[i + 1]) then
            v57 = false
            break
        end
    end

    if v57 then
        v57 = p34[1] >= v54.x - margin and p34[1] <= v55.x + margin and p34[3] >= v54.z - margin and p34[3] <= v55.z + margin
    end

    return v57
end

function t1.solid_by_id(p37, p38) -- line: 290
    for _, v58 in ipairs(p37) do
        local v59 = v58[2]

        if v59.id == p38 then
            return v59
        end
    end

    return nil
end

function t1.candidate_key(p39) -- line: 302
    local id = p39.id
    local v61 = tonumber(string.sub(id, 11, 18), 16)
    local v63 = tonumber(string.sub(id, 3, 10), 16)

    if v61 == nil or v63 == nil or #id ~= 18 then
        error("candidate_key: id is not a 0x%016X u64 string", 0)
    end

    return { v61, v63 }
end

t1.is_moving = is_moving
t1.solid_world_aabb = solid_world_aabb
t1.segment_bounds = segment_bounds
t1.inverse_point = inverse_point
t1.vec3 = vec3
t1.min_vec = min_vec
t1.max_vec = max_vec
t1.dot = dot
t1.vector_finite = vector_finite

return t1
