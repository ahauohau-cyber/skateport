-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

local function grab_scene() -- line: 8
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/grab_scene")
end

local t1 = {
    Provider = {},
    Spline = {},
    Object = {}
}

function t1.Object.record(p1, p2) -- line: 40
    -- upvalues: rt (copy), import (copy)
    return import("skate_core/player/offboard/grab_scene").Record.from_geometry({
        descriptor = rt.copy(p2.descriptor),
        geometry = p2.geometry,
        frame = rt.copy(p1.frame),
        object_vector_128 = rt.copy(p1.object_vector_128),
        assembly = p1.assembly,
        word_272 = p2.word_272
    })
end

t1.Registry = {}

function t1.Registry.new(p3) -- line: 55
    -- upvalues: t1 (copy)
    for i = 0, #p3 - 1 do
        local v1 = p3[i + 1]

        if v1.id == 0 then
            error("Interactable object ID zero is reserved for none", 0)
        end

        if v1.provider.tag == "Dmo" and v1.provider.selection_variant > 1 then
            error("Dmo body selection is a single bit", 0)
        end

        for _, v2 in v1.splines do
            if v2.descriptor.kind ~= 1 and v2.descriptor.kind ~= 2 then
                error("Unknown native grab descriptor kind", 0)
            end

            t1.Object.record(v1, v2)
        end

        for j = 1, i do
            if p3[j].id == v1.id then
                error("Duplicate authored interactable object ID", 0)
            end
        end
    end

    return {
        objects = p3
    }
end

function t1.Registry.eligible_object(p4, p5) -- line: 82
    if p5.fraction == 0 then
        return nil
    end

    local assembly = p5.assembly

    if assembly ~= nil then
        for _, v3 in p4.objects do
            if not v3.disabled and v3.assembly ~= nil and v3.assembly.identity == assembly then
                return v3.id
            end
        end
    end

    return nil
end

return t1
