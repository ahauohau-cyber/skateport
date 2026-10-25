-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    Verification = {}
}

function t1.Verification.default() -- line: 18
    return {
        elapsed = 0,
        requested = false,
        captured = false
    }
end

t1.VerificationPlugin = {}

function t1.verify(p1, p2, p3, p4, p5, p6) -- line: 45
    local t2 = {}

    if p2.verification_capture ~= nil then
        p1.elapsed += p3

        if p4 then
            if p1.elapsed > 2 and not p5.active and p6 then
                table.insert(t2, "enter_replay")
            end

            if p1.elapsed > 4 and not p1.requested then
                table.insert(t2, "screenshot")
                p1.requested = true
            end
        end

        if p1.captured and p1.elapsed > 6 then
            table.insert(t2, "report_ok")
        elseif p1.elapsed > 45 then
            table.insert(t2, "timeout")
        end
    end

    return t2
end

return t1
