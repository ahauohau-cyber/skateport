-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    TrickIdentifier = {}
}

function t1.TrickIdentifier.eq(p1, p2) -- line: 20
    local v1 = p1[1]
    local v2 = p2[1]

    if v1[1] == v2[1] and v1[2] == v2[2] and v1[3] == v2[3] and v1[4] == v2[4] and v1[5] == v2[5] then
        return v1[6] == v2[6]
    end

    return false
end

t1.TrickData = {}

function t1.TrickData.eq(p3, p4) -- line: 37
    -- upvalues: t1 (copy)
    return t1.TrickIdentifier.eq(p3.identifiers[1], p4.identifiers[1]) and t1.TrickIdentifier.eq(p3.identifiers[2], p4.identifiers[2]) and p3.word48 == p4.word48 and p3.scalars52_56[1] == p4.scalars52_56[1] and p3.scalars52_56[2] == p4.scalars52_56[2]
end

t1.GestureData = {}

function t1.GestureData.eq(p5, p6) -- line: 51
    if p5.gesture == p6.gesture and p5.flag_bytes[1] == p6.flag_bytes[1] and p5.flag_bytes[2] == p6.flag_bytes[2] and p5.flag_bytes[3] == p6.flag_bytes[3] then
        return p5.flag_bytes[4] == p6.flag_bytes[4]
    end

    return false
end

t1.MotionGraphPacket = {}

function t1.MotionGraphPacket.eq(p7, p8) -- line: 70
    -- upvalues: t1 (copy)
    return t1.TrickData.eq(p7.trick, p8.trick) and t1.GestureData.eq(p7.gesture, p8.gesture) and p7.wipeout_gesture[1] == p8.wipeout_gesture[1] and p7.wipeout_gesture[2] == p8.wipeout_gesture[2]
end

function t1.publish(p9, p10) -- line: 79
    -- upvalues: rt (copy)
    p10.trick = rt.copy(p9.trick)
    p10.gesture.gesture = p9.gesture.gesture
    p10.gesture.flag_bytes = rt.copy(p9.gesture.flag_bytes)
    p10.wipeout_gesture[1] = p9.wipeout_gesture[1]
    p10.wipeout_gesture[2] = p9.wipeout_gesture[2]
end

return t1
