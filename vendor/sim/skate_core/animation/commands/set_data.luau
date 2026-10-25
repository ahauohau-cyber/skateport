-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local BoneBuffers = require(sim.import)("skate_core/animation/commands/buffers").BoneBuffers
local t1 = {
    InternalUpdate = {},
    CopyCommand = {},
    SetDataCommand = {},
    resolve_set_count = function(p1, p2) -- resolve_set_count | line: 27
        if p1 == 0 then
            return (bit32.band(p2, 255))
        end

        return p1
    end
}

function t1.execute(p3, p4, p5) -- line: 36
    -- upvalues: t1 (copy)
    for _, v1 in ipairs(p5) do
        if v1.tag == "Sqt" then
            t1.copy(p3.sqt, p4, v1[1])
        else
            t1.copy(p3.matrices, p4, v1[1])
        end
    end
end

function t1.copy(p6, p7, p8) -- line: 47
    -- upvalues: BoneBuffers (copy)
    if p8.update.tag == "Set" then
        local source, bone_count = p8.update.source, p8.update.bone_count

        BoneBuffers.copy(p6, source, p8.internal, bone_count)
    end

    local external = p8.external

    if external ~= nil then
        BoneBuffers.copy(p6, p8.internal, external, p7)
    end
end

return t1
