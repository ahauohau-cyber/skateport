-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    SCORABLE_COUNT = 332,
    SCORE_TYPE_COUNT = 14,
    Scorable = {}
}
local Scorable = t1.Scorable

function t1.Scorable.eq(p1, p2) -- line: 25
    if p1.id == p2.id and p1.class == p2.class then
        return p1.score_type == p2.score_type
    end

    return false
end

function t1.Scorable.valid(p3) -- line: 29
    -- upvalues: t1 (copy)
    if p3.id < t1.SCORABLE_COUNT then
        return p3.score_type < t1.SCORE_TYPE_COUNT
    end

    return false
end

function t1.Scorable.repetition_applies(p4) -- line: 34
    -- upvalues: Scorable (copy)
    return Scorable.valid(p4) and p4.class ~= 5 and p4.class ~= 6
end

t1.Snapshot = {}

local Snapshot = t1.Snapshot

function t1.Snapshot.default() -- line: 50
    return {
        completed_lines = 0,
        line = 0,
        accumulated = 0,
        last_reward = 0,
        general_pending = 0,
        fingerflip_pending = 0,
        grind_reward = 0
    }
end

function t1.Snapshot.eq(p5, p6) -- line: 63
    if p5.completed_lines == p6.completed_lines and p5.line == p6.line and p5.accumulated == p6.accumulated and p5.last_reward == p6.last_reward and p5.general_pending == p6.general_pending and p5.fingerflip_pending == p6.fingerflip_pending then
        return p5.grind_reward == p6.grind_reward
    end

    return false
end

t1.ScoreHolder = {}

local ScoreHolder = t1.ScoreHolder

function t1.ScoreHolder.default() -- line: 84
    -- upvalues: t1 (copy), Snapshot (copy)
    return {
        pending_sequence = false,
        suppressed = false,
        snapshot = Snapshot.default(),
        repetitions = table.create(t1.SCORABLE_COUNT, 0),
        sequence_history = table.create(t1.SCORABLE_COUNT, 0),
        type_history = table.create(t1.SCORE_TYPE_COUNT, 0)
    }
end

local function saturating_add_1_i8(p7) -- line: 96
    local v1 = p7 + 1

    if v1 > 127 then
        return 127
    end

    return v1
end

function t1.ScoreHolder.has_pending_sequence(p8) -- line: 101
    return p8.pending_sequence
end

function t1.ScoreHolder.credit_trick(p9, p10, p11) -- line: 106
    -- upvalues: Scorable (copy), ScoreHolder (copy)
    if Scorable.valid(p10) and not p9.suppressed then
        ScoreHolder.count_trick(p9, p10)
        p9.snapshot.accumulated += p11
    end
end

function t1.ScoreHolder.count_trick(p12, p13) -- line: 114
    local repetitions = p12.repetitions
    local v2 = p13.id + 1
    local v3 = p12.repetitions[p13.id + 1] + 1

    if v3 > 127 then
        v3 = 127
    end

    repetitions[v2] = v3

    if p13.score_type == 0 then
        return
    end

    local sequence_history = p12.sequence_history
    local v4 = p13.id + 1
    local v5 = p12.sequence_history[p13.id + 1] + 1

    if v5 > 127 then
        v5 = 127
    end

    sequence_history[v4] = v5

    local type_history = p12.type_history
    local v6 = p13.score_type + 1
    local v7 = p12.type_history[p13.score_type + 1] + 1

    if v7 > 127 then
        v7 = 127
    end

    type_history[v6] = v7
end

function t1.ScoreHolder.set_suppressed(p14, p15) -- line: 122
    p14.suppressed = p15
end

function t1.ScoreHolder.repetition_count(p16, p17) -- line: 127
    -- upvalues: Scorable (copy)
    return if Scorable.valid(p17) then p16.repetitions[p17.id + 1] else nil
end

function t1.ScoreHolder.end_trick(p18, p19, p20) -- line: 135
    -- upvalues: Scorable (copy), ScoreHolder (copy)
    if Scorable.valid(p19) and not p18.suppressed then
        ScoreHolder.count_trick(p18, p19)

        local snapshot = p18.snapshot

        if p19.class ~= 5 then
            snapshot.general_pending += snapshot.fingerflip_pending
            snapshot.fingerflip_pending = 0
        end

        if p19.class == 3 then
            snapshot.fingerflip_pending += p20
        else
            snapshot.general_pending += p20
        end
    end
end

function t1.ScoreHolder.finish_collector(p21) -- line: 153
    p21.pending_sequence = true
end

function t1.ScoreHolder.cancel_pending(p22) -- line: 157
    if p22.pending_sequence then
        p22.snapshot.general_pending = 0
        p22.snapshot.fingerflip_pending = 0
    end
end

function t1.ScoreHolder.reward_sequence(p23, p24) -- line: 165
    if p23.pending_sequence then
        local snapshot = p23.snapshot

        snapshot.accumulated += (snapshot.general_pending + snapshot.fingerflip_pending) * p24
        snapshot.general_pending = 0
        snapshot.fingerflip_pending = 0
        p23.pending_sequence = false
    end
end

function t1.ScoreHolder.publish(p25, p26, p27) -- line: 178
    -- upvalues: ScoreHolder (copy)
    local snapshot = p25.snapshot

    if p27 then
        snapshot.line += p26
    end

    snapshot.last_reward = p26
    snapshot.accumulated = 0
    snapshot.general_pending = 0
    snapshot.fingerflip_pending = 0
    ScoreHolder.clear_sequence_history(p25)
end

function t1.ScoreHolder.clear_sequence_history(p28) -- line: 190
    for i = 1, #p28.sequence_history do
        p28.sequence_history[i] = 0
    end

    for i = 1, #p28.type_history do
        p28.type_history[i] = 0
    end

    p28.snapshot.grind_reward = 0
end

function t1.ScoreHolder.finish_line(p29) -- line: 201
    -- upvalues: ScoreHolder (copy)
    ScoreHolder.bank_line(p29, true)
end

function t1.ScoreHolder.bank_line(p30, p31) -- line: 207
    p30.snapshot.completed_lines += p30.snapshot.line
    p30.snapshot.line = 0

    if p31 then
        for i = 1, #p30.repetitions do
            p30.repetitions[i] = 0
        end
    end
end

function t1.ScoreHolder.reset(p32) -- line: 218
    -- upvalues: rt (copy), ScoreHolder (copy)
    local completed_lines = p32.snapshot.completed_lines

    rt.assign(p32, ScoreHolder.default())
    p32.snapshot.completed_lines = completed_lines
end

return t1
