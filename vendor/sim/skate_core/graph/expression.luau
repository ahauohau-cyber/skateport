-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

return {
    parse_operator = function(p1) -- parse_operator | line: 14
        if p1 == "and" then
            return 1
        end

        if p1 == "or" then
            return 2
        end

        if p1 == "not" then
            return 3
        end

        return 0
    end,
    evaluate_operator = function(p2, p3, p4, p5) -- evaluate_operator | line: 34
        if p2 > 3 then
            return 1, p4
        end

        if p2 == 3 then
            if not (p3 > 0) then
                error("stock NOT expression requires a child", 0)
            end

            local v1, v2 = p5(0, 1)
            local v3 = bit32.band(v1, 255)

            if v2 ~= 0 then
                return 1, v2
            end

            return if v3 == 0 then 1 else 0, v2
        end

        local v4 = p2 == 2
        local v5 = if v4 then 0 else 1
        local v6 = p3 - 1
        local n1 = 1

        for i = 0, v6 do
            local v7 = if v4 then bit32.band(v5, 255) == 0 else nil

            if v4 and not v7 then
                break
            end

            local v8 = if not v4 then bit32.band(v5, 255) == 0 else nil

            if not v4 and v8 then
                break
            end

            local v9, v10 = p5(i, 1)

            if v10 == 0 then
                v5 = if v4 then v9 else bit32.band(bit32.band(v9, 255), (bit32.band(v5, 255)))
                n1 = 0
            end
        end

        if n1 == 0 then
            return v5, n1
        end

        return 1, n1
    end
}
