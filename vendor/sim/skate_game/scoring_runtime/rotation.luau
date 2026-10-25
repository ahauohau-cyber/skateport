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

require(sim.import)

local t1 = {
    Basis = {},
    IDENTITY = {
        { 1, 0, 0 },
        { 0, 1, 0 },
        { 0, 0, 1 }
    }
}
local IDENTITY = t1.IDENTITY

function t1.dot(p2, p3) -- line: 25
    return 0 + p2[1] * p3[1] + p2[2] * p3[2] + p2[3] * p3[3]
end

local dot = t1.dot

function t1.cross(p4, p5) -- line: 36
    return {
        p4[2] * p5[3] - p4[3] * p5[2],
        p4[3] * p5[1] - p4[1] * p5[3],
        p4[1] * p5[2] - p4[2] * p5[1]
    }
end

local cross = t1.cross

function t1.normalized(p6) -- line: 46
    -- upvalues: dot (copy)
    local v2 = math.sqrt((dot(p6, p6)))

    return if v2 > 1E-06 and v2 == v2 and v2 ~= 1e999 and v2 ~= (-1e999) then {
        p6[1] / v2,
        p6[2] / v2,
        p6[3] / v2
    } else nil
end

local normalized = t1.normalized

t1.Tracker = {}

local Tracker = t1.Tracker

function t1.Tracker.reset(p7, p8) -- line: 60
    -- upvalues: rt (copy)
    p7.previous = rt.copy(p8)
    p7.angle = 0
end

function t1.Tracker.update(p9, p10) -- line: 65
    -- upvalues: rt (copy), dot (copy), cross (copy), normalized (copy)
    local v3 = rt.copy(p9.previous[2])
    local v4 = normalized(cross(cross(v3, p10[3]), v3))

    if v4 ~= nil then
        local v5 = dot(v4, p9.previous[3])

        if v5 >= 0 then
            p9.angle = p9.angle + math.atan2(dot(cross(p9.previous[3], v4), v3), v5)
        end
    end

    p9.previous = rt.copy(p10)
end

t1.Rotation = {}

function t1.Rotation.default() -- line: 83
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        banked = 0,
        both = false,
        player = {
            angle = 0,
            previous = rt.copy(IDENTITY)
        },
        board = {
            angle = 0,
            previous = rt.copy(IDENTITY)
        }
    }
end

function t1.Rotation.reset(p11, p12, p13) -- line: 99
    -- upvalues: Tracker (copy)
    Tracker.reset(p11.player, p12)
    Tracker.reset(p11.board, p13)
    p11.banked = 0
    p11.both = false
end

function t1.Rotation.update(p14, p15, p16, p17, p18) -- line: 107
    -- upvalues: rt (copy), cross (copy), normalized (copy), Tracker (copy)
    Tracker.update(p14.player, p15)

    if p18 then
        if p14.both then
            p14.banked += p14.player.angle
            Tracker.reset(p14.player, p15)
            p14.both = false
        end

        Tracker.reset(p14.board, p16)
    elseif p14.both then
        local v7 = normalized(cross(p17, p16[3]))

        if v7 ~= nil then
            local v8 = normalized(cross(v7, p17))

            if v8 ~= nil then
                Tracker.update(p14.board, {
                    v7,
                    rt.copy(p17),
                    v8
                })
            end
        end
    else
        p14.banked += p14.player.angle
        Tracker.reset(p14.player, p15)
        Tracker.reset(p14.board, p16)
        p14.both = true
    end

    return p14.banked + p14.board.angle + (if p14.both then 0 else p14.player.angle)
end

return t1
