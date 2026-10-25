-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)

local function skate_map() -- line: 10
    -- upvalues: import (copy)
    return import("skate_data/skate_map")
end

return {
    decode = function(p1, p2, p3) -- decode | line: 17
        -- upvalues: import (copy)
        local StoredBlock = import("skate_data/skate_map").StoredBlock
        local n1 = 0

        for _, v1 in p2 do
            n1 += v1.expected
        end

        local v2 = if n1 < 1048576 then 1 else math.min(math.clamp(p3, 1, 8), (math.max(#p2, 1)))

        if v2 == 1 then
            for i = 1, math.min(#p1, #p2) do
                p1[i].rgba = StoredBlock.decode(p2[i])
            end

            return 1
        end

        local t2 = {}

        for i = 0, #p2 - 1 do
            local decode = StoredBlock.decode
            local v8 = p2[i + 1]
            local ok, result = pcall(decode, v8)

            if not ok then
                error(("Texture %*: %*"):format(i, result), 0)
            end

            table.insert(t2, {
                i,
                result
            })
        end

        for _, v9 in t2 do
            p1[v9[1] + 1].rgba = v9[2]
        end

        return v2
    end
}
