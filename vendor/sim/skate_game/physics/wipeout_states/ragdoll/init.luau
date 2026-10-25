-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/wipeout_states/ragdoll/settings")
local v2 = import("skate_game/physics/skeleton_controller")
local v3 = import("skate_core/physics/skeleton_body")
local SkeletonControllerState = v2.SkeletonControllerState
local SkeletonCollisionFeedback, SkeletonCollisionMode = v3.SkeletonCollisionFeedback, v3.SkeletonCollisionMode
local t1 = {
    RagdollSetup = {}
}

local function write_limits(p1, p2) -- line: 23
    for i = 1, math.min(#p1.records, #p2) do
        local words = p1.records[i].parameters.words
        local v6 = p2[i]

        words[11] = v6[1]
        words[12] = v6[2]
        words[13] = v6[3]
        words[14] = v6[4]
    end
end

function t1.RagdollSetup.load(p3, p4, p5) -- line: 36
    -- upvalues: v1 (copy)
    return {
        settings = v1.Settings.load(p3, p4, p5)
    }
end

function t1.RagdollSetup.request(p6, p7, p8, p9, p10, p11) -- line: 44
    -- upvalues: rt (copy), SkeletonControllerState (copy), SkeletonCollisionMode (copy), write_limits (copy)
    local v7 = SkeletonControllerState.select_request(p7, p8)

    if v7 == nil then
        return
    end

    if not (v7 >= 7 and v7 <= 10) then
        return SkeletonCollisionMode.select_driven(p11, v7)
    end

    write_limits(p10, if v7 == 10 then p6.settings.normal_limits else p6.settings.ragdoll_limits)
    SkeletonCollisionMode.apply_ragdoll_properties(p11, p9, p6.settings.inverse_mass, p6.settings.inverse_inertia, rt.copy(p6.settings.drag), rt.copy(p6.settings.materials))
    SkeletonCollisionMode.finish_ragdoll_request(p11, v7)
end

function t1.RagdollSetup.restore_normal(p12, p13, p14, p15, p16) -- line: 78
    -- upvalues: SkeletonCollisionFeedback (copy), SkeletonCollisionMode (copy), write_limits (copy)
    write_limits(p14, p12.settings.normal_limits)
    SkeletonCollisionFeedback.set_up_normal(p16)
    SkeletonCollisionMode.restore_normal_properties(p15, p13)
end

return t1
