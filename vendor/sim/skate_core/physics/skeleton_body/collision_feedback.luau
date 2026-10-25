-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/skeleton_body/collision_update")
local v2 = import("skate_core/physics/skeleton_body/collision_filter")
local t1 = {
    SkeletonFeedbackSettings = {},
    SkeletonContactBody = {},
    SkeletonContactReport = {},
    SkeletonCollisionInput = {},
    BoneContact = {}
}

function t1.BoneContact.default() -- line: 53
    return {
        force = 0,
        specific_force = 0,
        tag = 0,
        specific_tag = 0,
        normal = table.create(4, 0),
        specific_normal = table.create(4, 0),
        tangent = table.create(4, 0),
        specific_tangent = table.create(4, 0),
        point = table.create(4, 0),
        groups = table.create(4, false)
    }
end

t1.ContactRegion = {}

function t1.ContactRegion.default() -- line: 72
    return {
        force = 0,
        weighted_force = 0,
        tangent_speed = 0,
        material_flags = 0,
        part = nil,
        normal = table.create(4, 0)
    }
end

t1.ContactPlane = {}

function t1.ContactPlane.default() -- line: 86
    return {
        part = 0,
        normal = table.create(4, 0)
    }
end

t1.SpecificContact = {}
t1.SkeletonContactFlags = {}

function t1.SkeletonContactFlags.default() -- line: 103
    return {
        material_6 = false,
        noncompliant = false,
        compliant = false,
        recovering = false,
        group_8 = false,
        nonboard = false,
        ragdoll = false,
        conflicting = false,
        impaled = false,
        has_impulse = false,
        foot_board = false,
        material_10 = false,
        material_11 = false,
        material_12 = false,
        any = false
    }
end

t1.SkeletonCollisionFeedback = {}

function t1.SkeletonCollisionFeedback.new(p1) -- line: 136
    -- upvalues: rt (copy), t1 (copy)
    local t2 = {
        {
            part = 23,
            current = false,
            recent = false,
            local_point = rt.copy(p1.groin_offset),
            world_point = table.create(4, 0),
            radius_squared = p1.groin_radius * p1.groin_radius
        },
        {
            part = 1,
            current = false,
            recent = false,
            local_point = rt.copy(p1.face_offset),
            world_point = table.create(4, 0),
            radius_squared = p1.face_radius * p1.face_radius
        }
    }

    return {
        timer = 0,
        drive_weight = 0,
        maximum_priority = 0,
        maximum_skater_force = 0,
        other_skater = -1,
        maximum_group_8_force = 0,
        maximum_group_11_force = 0,
        material_12_height = 0,
        settings = rt.copy(p1),
        contact_age = table.create(24, 0),
        priority = table.create(24, 0),
        compliant = rt.copy(p1.body.compliant),
        current = table.create(24, false),
        bones = rt.from_fn(24, function(_) -- line: 161
            -- upvalues: t1 (copy)
            return t1.BoneContact.default()
        end),
        regions = {
            t1.ContactRegion.default(),
            t1.ContactRegion.default(),
            t1.ContactRegion.default(),
            t1.ContactRegion.default(),
            t1.ContactRegion.default(),
            t1.ContactRegion.default(),
            t1.ContactRegion.default(),
            t1.ContactRegion.default()
        },
        planes = table.create(20),
        specific = t2,
        highest_normal = { 0, 1, 0, 0 },
        foot_normal = { 0, 1, 0, 0 },
        material_normals = rt.filled(2, table.create(4, 0)),
        wipeout_times = table.create(3, 0),
        flags = t1.SkeletonContactFlags.default()
    }
end

function t1.SkeletonCollisionFeedback.reset(p3) -- line: 193
    -- upvalues: rt (copy), t1 (copy)
    local v3 = rt.copy(p3.specific)
    local v4 = rt.copy(p3.compliant)
    local any = p3.flags.any

    rt.assign(p3, t1.SkeletonCollisionFeedback.new(p3.settings))
    p3.specific = v3
    p3.compliant = v4
    p3.flags.any = any
end

function t1.SkeletonCollisionFeedback.set_up_normal(p4) -- line: 205
    -- upvalues: rt (copy), t1 (copy)
    t1.SkeletonCollisionFeedback.reset(p4)
    p4.priority = rt.copy(p4.settings.body.priority)
    p4.compliant = rt.copy(p4.settings.body.compliant)
end

for v5, v6 in v1.SkeletonCollisionFeedback do
    t1.SkeletonCollisionFeedback[v5] = v6
end

for v7, v8 in v2.SkeletonCollisionFeedback do
    t1.SkeletonCollisionFeedback[v7] = v8
end

return t1
