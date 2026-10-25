-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_core/player/input_phase")
local Collections = import("skate_data/collections").Collections
local PlayerInputState = v8.PlayerInputState

return {
    player = function(p3) -- player | line: 38
        -- upvalues: rt (copy), v1 (copy), Collections (copy), PlayerInputState (copy)
        local v9 = PlayerInputState.default()

        v9.flags_1296 = 3758882816
        v9.ground_history_frames_1304 = 100

        local vectors = v9.external_physics_cache_1008.vectors
        local filled = rt.filled

        buffer.writef32(v1, 0, -1)
        vectors[9] = filled(4, (buffer.readu32(v1, 0)))

        local t2 = {
            "easy",
            "normal",
            "hardcore",
            "motorized",
            "test"
        }

        for i = 0, #t2 - 1 do
            local v10 = t2[i + 1]

            v9.state_variants_1408[i + 1] = {
                surface_override_enabled_60 = Collections.boolean(p3, "physics_mode", v10, "Hash_5548109D7B0CB70C") and 1 or 0
            }
        end

        return v9
    end
}
