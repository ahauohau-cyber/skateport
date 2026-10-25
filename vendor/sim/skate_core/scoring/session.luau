-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local ScoreHolder = import("skate_core/scoring").ScoreHolder
local v1 = import("skate_core/scoring/timer")
local ComboTimer, PointTimer = v1.ComboTimer, v1.PointTimer
local t1 = {
    Rules = {},
    Session = {}
}

function t1.Session.default() -- line: 28
    -- upvalues: ScoreHolder (copy), ComboTimer (copy), PointTimer (copy)
    return {
        holder = ScoreHolder.default(),
        combo = ComboTimer.default(),
        line = PointTimer.default()
    }
end

function t1.Session.publish_sequence(p1, p2, p3, p4, p5) -- line: 39
    -- upvalues: ScoreHolder (copy), ComboTimer (copy), PointTimer (copy)
    ScoreHolder.reward_sequence(p1.holder, p3)

    local snapshot = p1.holder.snapshot
    local v2 = snapshot.fingerflip_pending + snapshot.general_pending + snapshot.accumulated

    if p4 and p2.bail_factor < 1 then
        v2 *= p2.bail_factor
    end

    local v3

    if p5 then
        v3 = p1.combo.multiplier
        ComboTimer.credit(p1.combo, v2, p2.combo_capacity, p2.combo_levels, p2.combo_refresh_threshold)

        if p1.combo.multiplier > 1.0099999904632568 then
            PointTimer.credit(p1.line, v2, p2.line_capacity)
        end
    else
        v3 = 1
    end

    local v4 = v3 * v2

    ScoreHolder.publish(p1.holder, v4, p5 and p1.line.points > 0)

    return v4
end

function t1.Session.settle_line(p6, p7, p8) -- line: 66
    -- upvalues: ScoreHolder (copy), PointTimer (copy)
    if not (p7 or p6.line.expired) then
        if p6.line.points <= 0 then
            ScoreHolder.bank_line(p6.holder, not p8)
        end
    else
        p6.line = PointTimer.default()
        p6.combo.multiplier = 1
        ScoreHolder.finish_line(p6.holder)
    end
end

return t1
