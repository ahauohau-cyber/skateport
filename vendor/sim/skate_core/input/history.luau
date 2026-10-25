-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local Pad = require(sim.import)("skate_core/input/pad").Pad
local t1 = {}

t1.HISTORY_CAPACITY = 30
t1.DEVICE_SLOTS = 4
t1.MAX_VALUES = 24
t1.HistoryRecord = {}

function t1.HistoryRecord.new(p1) -- line: 25
    -- upvalues: t1 (copy)
    if not (#p1 <= t1.MAX_VALUES) then
        error("assertion failed: values.len() <= MAX_VALUES", 0)
    end

    local t2 = {
        values = table.create(t1.MAX_VALUES, 0),
        count = #p1
    }

    for i = 0, #p1 - 1 do
        t2.values[i + 1] = p1[i + 1]
    end

    return t2
end

function t1.HistoryRecord.count(p2) -- line: 39
    return p2.count
end

function t1.HistoryRecord.values(p3) -- line: 44
    -- upvalues: rt (copy)
    return rt.slice(p3.values, 0, p3.count)
end

function t1.HistoryRecord.clear_count(p4) -- line: 49
    p4.count = 0
end

function t1.HistoryRecord.eq(p5, p6) -- line: 54
    -- upvalues: t1 (copy)
    if p5.count ~= p6.count then
        return false
    end

    for i = 1, t1.MAX_VALUES do
        if p5.values[i] ~= p6.values[i] then
            return false
        end
    end

    return true
end

t1.PadHistory = {}

function t1.PadHistory.new() -- line: 70
    -- upvalues: rt (copy), t1 (copy)
    local v2 = t1.HistoryRecord.new({})

    return {
        read = 0,
        write = 1,
        batches = rt.filled(t1.HISTORY_CAPACITY, rt.filled(t1.DEVICE_SLOTS, v2))
    }
end

function t1.PadHistory.read_index(p7) -- line: 79
    return p7.read
end

function t1.PadHistory.write_index(p8) -- line: 83
    return p8.write
end

function t1.PadHistory.eq(p9, p10) -- line: 88
    -- upvalues: t1 (copy)
    if p9.read ~= p10.read or p9.write ~= p10.write then
        return false
    end

    for i = 1, t1.HISTORY_CAPACITY do
        for j = 1, t1.DEVICE_SLOTS do
            if not t1.HistoryRecord.eq(p9.batches[i][j], p10.batches[i][j]) then
                return false
            end
        end
    end

    return true
end

function t1.PadHistory.publish(p11, p12) -- line: 105
    -- upvalues: rt (copy), t1 (copy)
    if not (#p12 <= t1.DEVICE_SLOTS) then
        error("assertion failed: records.len() <= DEVICE_SLOTS", 0)
    end

    local v3 = p11.batches[p11.write + 1]

    for i = 0, #p12 - 1 do
        v3[i + 1] = rt.copy(p12[i + 1])
    end

    p11.write = rt.irem(p11.write + 1, t1.HISTORY_CAPACITY)
end

function t1.PadHistory.drain_to_latest(p13, p14) -- line: 119
    -- upvalues: rt (copy), t1 (copy), Pad (copy)
    if t1.PadHistory.is_empty(p13) then
        return false
    end

    local read = p13.read

    while rt.irem(p13.read + 1, t1.HISTORY_CAPACITY) ~= p13.write do
        p13.read = rt.irem(p13.read + 1, t1.HISTORY_CAPACITY)
        read = p13.read
    end

    local v4 = p13.batches[read + 1]

    for i = 1, math.min(#p14, #v4) do
        Pad.update(p14[i], t1.HistoryRecord.values(v4[i]))
    end

    return true
end

function t1.PadHistory.is_empty(p15) -- line: 135
    -- upvalues: rt (copy), t1 (copy)
    return rt.irem(p15.read + 1, t1.HISTORY_CAPACITY) == p15.write
end

return t1
