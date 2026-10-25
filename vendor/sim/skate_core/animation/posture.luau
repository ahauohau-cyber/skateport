-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    PosturePose = {}
}

function t1.PosturePose.from_profile(p1) -- line: 18
    if p1 == 1 then
        return "Stiff"
    end

    if p1 == 2 then
        return "Slouch"
    end

    return if p1 == 3 then "Buff" else nil
end

function t1.PosturePose.name(p2) -- line: 30
    if p2 == "Stiff" then
        return "POSTURE_STIFF_POSE"
    end

    if p2 == "Slouch" then
        return "POSTURE_SLOUCH_POSE"
    end

    return "POSTURE_BUFF_POSE"
end

t1.PendingPosture = {}

function t1.PendingPosture.default() -- line: 45
    return {
        profile = 0,
        pending = false
    }
end

function t1.PendingPosture.eq(p3, p4) -- line: 50
    if p3.profile == p4.profile then
        return p3.pending == p4.pending
    end

    return false
end

function t1.PendingPosture.set_profile(p5, p6) -- line: 55
    p5.profile = p6
end

function t1.PendingPosture.profile(p7) -- line: 59
    return p7.profile
end

function t1.PendingPosture.set_requested(p8, p9) -- line: 64
    p8.pending = p9
end

function t1.PendingPosture.is_pending(p10) -- line: 68
    return p10.pending
end

function t1.PendingPosture.selected_pose(p11) -- line: 73
    -- upvalues: t1 (copy)
    if p11.pending then
        return t1.PosturePose.from_profile(p11.profile)
    end

    return nil
end

function t1.PendingPosture.apply(p12, p13, p14) -- line: 86
    -- upvalues: t1 (copy)
    local v1 = t1.PendingPosture.selected_pose(p12)

    if v1 == nil then
        return p13
    end

    local v2 = p14(p13, v1)

    p12.pending = false

    return v2
end

return t1
