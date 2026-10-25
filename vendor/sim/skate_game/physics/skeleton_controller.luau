-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local SkeletonCollisionMode = require(sim.import)("skate_core/physics/skeleton_body").SkeletonCollisionMode
local t1 = {
    SkeletonControllerState = {}
}
local SkeletonControllerState = t1.SkeletonControllerState

function t1.SkeletonControllerState.new() -- line: 24
    return {
        effective = 0,
        requested = 0,
        has_request = false,
        override_enabled = false,
        flag_18 = false
    }
end

function t1.SkeletonControllerState.request_ground(p1, p2) -- line: 36
    -- upvalues: SkeletonControllerState (copy)
    SkeletonControllerState.request(p1, 6, p2)
end

function t1.SkeletonControllerState.request(p3, p4, p5) -- line: 41
    -- upvalues: SkeletonCollisionMode (copy), SkeletonControllerState (copy)
    local v1 = SkeletonControllerState.select_request(p3, p4)

    if v1 ~= nil then
        SkeletonCollisionMode.select_driven(p5, v1)
    end
end

function t1.SkeletonControllerState.select_request(p6, p7) -- line: 51
    -- upvalues: rt (copy)
    if p6.has_request and p6.requested == p7 then
        return nil
    end

    local v2

    if p6.override_enabled then
        p6.requested = p7
        p6.has_request = true

        if p7 == 4 then
            v2 = 1
        elseif p7 >= 5 and p7 <= 7 then
            v2 = 2
        elseif p7 == 8 then
            v2 = 3
        else
            if not (p7 >= 9 and p7 <= 11) then
                return nil
            end

            v2 = p7
        end
    else
        if p6.effective >= 1 and p6.effective <= 2 then
            return nil
        end

        v2 = p7
    end

    p6.effective = v2

    local v3 = rt.wrapping_sub_u32(v2, 1)

    return if not (v3 > 10) then v3 else nil
end

function t1.SkeletonControllerState.update_air(p8, p9, p10, p11) -- line: 87
    -- upvalues: SkeletonControllerState (copy)
    local v4 = bit32.band(p9, 32768) ~= 0 or p10 > 0

    if p8.flag_18 == v4 then
        return
    end

    p8.flag_18 = v4
    SkeletonControllerState.request(p8, v4 and 7 or 6, p11)
end

return t1
