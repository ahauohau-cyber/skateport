-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_game/physics/offboard/grab_scene/collision")
local v2 = import("skate_core/player/offboard/grab_scene")
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local t1 = {
    Descriptor = v2.Descriptor,
    Hit = v2.Hit,
    Line = v2.Line,
    Object = v2.Object,
    Query = v2.Query,
    Record = v2.Record,
    MeshAssembly = {},
    Registry = {}
}

function t1.Registry.new(p1, p2, p3) -- line: 33
    -- upvalues: v2 (copy), BoardWorld (copy)
    local v3 = BoardWorld.query_metadata(p1)
    local v4 = v2.Registry.new(p2)

    for i = 0, #p3 - 1 do
        local v5 = p3[i + 1]
        local v6 = false

        if v5.assembly ~= 0 then
            for _, v7 in v3.meshes do
                if v7.geometry == v5.mesh then
                    v6 = true
                    break
                end

                v6 = false
            end
        end

        if v5.assembly == 0 or not v6 then
            error("Grab collision binding must name an existing mesh and nonzero physical assembly", 0)
        end

        for j = 1, i do
            if p3[j].mesh == v5.mesh then
                error("One canonical collision mesh cannot name two assemblies", 0)
            end
        end
    end

    return {
        objects = v4,
        mesh_assemblies = p3
    }
end

function t1.Registry.assembly(p4, p5) -- line: 64
    for _, v8 in p4.mesh_assemblies do
        if v8.mesh == p5 then
            return v8.assembly
        end
    end

    return nil
end

t1.Scene = {}

function t1.Scene.new(p6, p7) -- line: 76
    return {
        world = p6,
        registry = p7
    }
end

function t1.Scene.query(p8, p9) -- line: 81
    -- upvalues: v2 (copy)
    return v2.query(p8.registry.objects, p9)
end

function t1.Scene.resolve(p10, p11) -- line: 88
    -- upvalues: v2 (copy)
    if p11.kind ~= 1 and p11.kind ~= 2 then
        return nil
    end

    for _, v9 in p10.registry.objects.objects do
        for _, v10 in v9.splines do
            if v10.descriptor.kind == p11.kind and v10.descriptor.id == p11.id then
                return v2.Object.record(v9, v10)
            end
        end
    end

    return nil
end

function t1.Scene.line(p12, p13) -- line: 104
    -- upvalues: v1 (copy)
    return v1.line(p12, p13)
end

function t1.Scene.eligible_object(p14, p15) -- line: 108
    -- upvalues: v2 (copy)
    return v2.Registry.eligible_object(p14.registry.objects, p15)
end

return t1
