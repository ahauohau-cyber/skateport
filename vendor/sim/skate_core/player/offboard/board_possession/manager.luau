-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    Hand = {}
}

function t1.Hand.default() -- line: 20
    return {
        word_80 = 0,
        flag_84 = false,
        vectors_0_to_64 = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 1, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        },
        scalars_96_100 = { 0, 0 },
        flags_104_to_107 = { false, false, false, false }
    }
end

t1.State = {}

function t1.State.default() -- line: 46
    -- upvalues: rt (copy), t1 (copy)
    return {
        word_300 = 2,
        hands = {
            t1.Hand.default(),
            t1.Hand.default()
        },
        vectors_224_to_272 = rt.filled(4, { 0, 0, 0, 0 }),
        scalars_288_to_296 = { 0, 0, 0 },
        flags_304_to_307 = { false, false, false, false },
        words_308_to_316 = { 0, 0, 0 }
    }
end

t1.SkeletonReset = {}

function t1.State.reset(p1) -- line: 71
    -- upvalues: rt (copy), t1 (copy)
    rt.assign(p1, t1.State.default())
end

function t1.State.enter(p2, p3, p4, p5) -- line: 77
    -- upvalues: rt (copy), t1 (copy)
    if p3 ~= 500 and p3 ~= 501 and p3 ~= 502 then
        t1.State.reset(p2)
        rt.assign(p5.values_468, { 0, 0, 0, 0 })
        rt.assign(p5.values_484, { 0, 0, 0, 0 })
        rt.assign(p5.words_500, { 0, 0, 0, 0 })
        p5.enabled_464 = false
    end

    p2.flags_304_to_307[1] = p4 == 502

    return p5.enabled_464
end

return t1
