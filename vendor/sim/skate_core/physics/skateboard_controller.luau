-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    SkateboardController = {}
}

function t1.SkateboardController.default() -- line: 20
    -- upvalues: t1 (copy)
    return t1.SkateboardController.new()
end

function t1.SkateboardController.new() -- line: 24
    return {
        fields = {
            word_444 = 0,
            state_448 = 0,
            system_on_452 = false
        }
    }
end

function t1.SkateboardController.stop(p1, p2) -- line: 38
    if p1.fields.system_on_452 then
        local state_448 = p1.fields.state_448

        p1.fields.word_444 = 0

        if state_448 ~= 0 then
            p2.let_go_of_skateboard(p2)
            p1.fields.state_448 = 0
        end

        p1.fields.system_on_452 = false
    end
end

function t1.SkateboardController.request_partial_ragdoll(p3, p4) -- line: 53
    if p3.fields.state_448 == 1 then
        return p4 ~= 0
    end

    return false
end

return t1
