-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

require(sim.import)

return {
    BoardBodyState = {},
    TwoStageThresholds = {},
    condition_is_off_ground_skitching = function(p4, p5) -- condition_is_off_ground_skitching | line: 44
        if p4.field_856 > p5.field_856_primary then
            return true
        end

        if p4.field_856 > p5.field_856_secondary then
            return p4.field_7692 > p5.field_7692
        end

        return false
    end,
    condition_is_off_ground = function(p6, p7) -- condition_is_off_ground | line: 51
        if p6.field_856 > p7.field_856_primary then
            return true
        end

        if p6.field_856 > p7.field_856_secondary then
            return p6.field_7692 > p7.field_7692
        end

        return false
    end,
    SkeletonAnimationState = {},
    is_skateboard_animated = function(p8) -- is_skateboard_animated | line: 63
        -- upvalues: v1 (copy)
        if p8.mode_16420 == 2 then
            return true
        end

        local back_chain_lane_12656 = p8.back_chain_lane_12656
        local v8

        if back_chain_lane_12656 ~= 0 and back_chain_lane_12656 > -1.1754943508222875E-38 and back_chain_lane_12656 < 1.1754943508222875E-38 then
            local v9 = math.abs(back_chain_lane_12656) * 7.1362384635298E+44
            local v10 = math.floor(v9)
            local v11 = v9 - v10

            v8 = if v11 > 0.5 or v11 == 0.5 and v10 % 2 == 1 then v10 + 1 else v10

            if back_chain_lane_12656 < 0 then
                v8 += 2147483648
            end
        else
            buffer.writef32(v1, 0, back_chain_lane_12656)
            v8 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.band(v8, 2147483647)))

        if buffer.readf32(v1, 0) <= p8.threshold_800 then
            return false
        end

        return p8.mode_16420 ~= 1
    end
}
