-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local t1 = {
    UNITS = 6,
    MAX = 3,
    per_tick = 0
}

function t1.set(p1) -- line: 28
    -- upvalues: t1 (copy)
    local v2 = math.floor(tonumber(p1) or 0)

    if v2 <= 1 then
        v2 = 0
    elseif t1.MAX < v2 then
        v2 = t1.MAX
    end

    t1.per_tick = v2
end

function t1.pick(p2, p3, p4) -- line: 42
    table.clear(p4)

    if not (p2 < 2 or p3 < 2) then
        local v3 = p3 - 1
        local n1 = 0

        for i = 1, v3 do
            local v5 = math.floor(p2 * i / p3 + 0.5)

            if v5 < 1 then
                v5 = 1
            end

            if p2 - 1 < v5 then
                v5 = p2 - 1
            end

            if n1 < v5 then
                n1 = v5
                table.insert(p4, v5)
            end
        end
    end

    return p4
end

return t1
