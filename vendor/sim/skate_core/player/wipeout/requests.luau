-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    Requests = {}
}
local Requests = t1.Requests

function t1.Requests.eq(p1, p2) -- line: 24
    for i = 1, 34 do
        if p1.reasons[i] ~= p2.reasons[i] or p1.values[i] ~= p2.values[i] then
            return false
        end
    end

    if p1.count == p2.count and p1.cooldown == p2.cooldown and p1.contact_frames == p2.contact_frames and p1.balance == p2.balance then
        return p1.mode == p2.mode
    end

    return false
end

function t1.Requests.new() -- line: 38
    return {
        count = 0,
        cooldown = 0,
        contact_frames = 0,
        balance = 0,
        mode = 0,
        reasons = table.create(34, false),
        values = table.create(34, 0)
    }
end

function t1.Requests.initialize_player(p3) -- line: 51
    p3.cooldown = 0.03999999910593033
end

function t1.Requests.teleport(p4) -- line: 56
    p4.cooldown = 0.4000000059604645
end

function t1.Requests.enter_ground(p5) -- line: 61
    if p5.mode ~= 1 then
        p5.balance = 0
        p5.mode = 1
    end
end

function t1.Requests.request(p6, p7, p8) -- line: 70
    -- upvalues: rt (copy)
    p6.reasons[p7 + 1] = true
    p6.values[p7 + 1] = p8
    p6.count = rt.wrapping_add_u32(p6.count, 1)
end

function t1.Requests.clear_after_selection(p9) -- line: 77
    for i = 1, #p9.reasons do
        p9.reasons[i] = false
    end

    for i = 1, #p9.values do
        p9.values[i] = 0
    end

    p9.count = 0
end

function t1.Requests.reset_systems(p10) -- line: 88
    p10.mode = 0
    p10.count = 0
end

function t1.Requests.requests_runout(p11, p12) -- line: 95
    local v1, v2

    if p11.count == 1 and (p11.reasons[3] or p11.reasons[25] or p11.reasons[11]) then
        if bit32.band(p12.flags_2468, 32) == 0 then
            if bit32.band(p12.flags_2476, 67108864) == 0 then
                if math.abs(p12.animation_up_y) > 0.8100000023841858 then
                    v1 = true
                    v2 = true
                else
                    v2 = false
                end
            else
                v2 = false
            end
        else
            v2 = false
        end
    else
        v2 = false
    end

    if not v2 then
        v1 = bit32.band(p12.flags_2484, 4096) ~= 0 and p12.category == 400
    end

    return v1
end

function t1.Requests.requests_wipeout(p13, p14) -- line: 106
    -- upvalues: Requests (copy)
    if Requests.requests_runout(p13, p14) then
        return false
    end

    local v4 = false

    for i = 1, #p13.reasons do
        if p13.reasons[i] then
            v4 = true
            break
        end
    end

    if not v4 then
        v4 = bit32.band(p14.flags_2480, 8) ~= 0
    end

    return v4
end

return t1
