-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    JumpAttributeState = {}
}

function t1.JumpAttributeState.eq(p1, p2) -- line: 20
    if p1.prepared_controls[1] == p2.prepared_controls[1] and p1.prepared_controls[2] == p2.prepared_controls[2] and p1.height_override == p2.height_override then
        return p1.height_override_active == p2.height_override_active
    end

    return false
end

function t1.JumpAttributeState.new() -- line: 28
    return {
        height_override = 0,
        height_override_active = false,
        prepared_controls = { 0, 0 }
    }
end

t1.FinalizationInput = {}

local function clamp_control(p3) -- line: 44
    local v1 = if -1 - p3 >= 0 then -1 else p3

    if 1 - v1 >= 0 then
        return v1
    end

    return 1
end

t1.Accumulator = {}

function t1.Accumulator.new() -- line: 63
    return {
        revert = false,
        revert_direction = 1,
        minimum_jump = 0,
        trick_height = 0,
        has_trick_height = false
    }
end

function t1.Accumulator.dispatch(p4, p5, p6, p7, p8, p9) -- line: 76
    if p5 == "Revert" then
        p4.revert = true
    elseif p5 == "RevertDir" then
        p4.revert_direction = p6()
        p7.flags2472 = bit32.bor(p7.flags2472, 2097152)
    elseif p5 == "MinJump" then
        p4.minimum_jump = p6()
    elseif p5 == "TrickHeight" then
        p4.trick_height = p6()
        p4.has_trick_height = true
    elseif p5 == "PrepareJump" then
        p7.flags2468 = bit32.bor(p7.flags2468, 2097152)

        if p9 ~= nil then
            local v2 = p9.value(p9, 64)

            if -1 - v2 >= 0 then
                v2 = -1
            end

            if not (1 - v2 >= 0) then
                v2 = 1
            end

            local v3 = p9.value(p9, 65)

            if -1 - v3 >= 0 then
                v3 = -1
            end

            if not (1 - v3 >= 0) then
                v3 = 1
            end

            p8.prepared_controls = { v2, v3 }
        end
    else
        if p5 ~= "JumpHeightOverride" then
            return false
        end

        p8.height_override = p6()
        p8.height_override_active = true
    end

    return true
end

function t1.Accumulator.finish(p10, p11, p12, p13, p14, p15) -- line: 105
    -- upvalues: rt (copy)
    if p10.revert then
        p12.revert_direction = p10.revert_direction
    end

    if bit32.band(p11.flags2468, 4194304) ~= 0 then
        if p14.select_jump_extremes and p10.trick_height <= p14.low_jump_threshold then
            p12.jump_strength = p10.minimum_jump
        elseif not (p14.select_jump_extremes and p10.trick_height >= p14.high_jump_threshold) then
            p12.jump_strength = p10.trick_height
        else
            p12.jump_strength = 1
        end
    end

    if not (p10.has_trick_height and p14.allow_height_override) then
        p13.height_override = 0
        p13.height_override_active = false
    elseif p13.height_override_active and p13.height_override - p12.jump_strength >= 0 then
        p12.jump_strength = p13.height_override
    end

    if bit32.band(p12.flags2480, 4096) ~= 0 then
        p12.jump_strength = p10.trick_height
    end

    if p14.use_prepared_controls then
        p12.jump_controls = rt.copy(p13.prepared_controls)
    elseif p15 ~= nil then
        local v4 = p15.value(p15, 64)

        if -1 - v4 >= 0 then
            v4 = -1
        end

        if not (1 - v4 >= 0) then
            v4 = 1
        end

        local v5 = p15.value(p15, 68)

        if -1 - v5 >= 0 then
            v5 = -1
        end

        if not (1 - v5 >= 0) then
            v5 = 1
        end

        p12.jump_controls = { v4, v5 }
    end

    if p14.external_impulse_active then
        p11.flags2468 = bit32.bor(p11.flags2468, 262144)
    end

    p12.flags2480 = bit32.bor(bit32.band(p12.flags2480, 4294967287), (bit32.band(bit32.rshift(p14.animation_flags, 24), 8)))
    p11.flags2484 = bit32.bor(bit32.band(p11.flags2484, 4294967293), (bit32.band(bit32.rshift(p14.animation_flags, 22), 2)))
    p11.flags2484 = bit32.bor(bit32.band(p11.flags2484, 2147483647), (bit32.band(bit32.lshift(p14.animation_flags, 6), 2147483648)))
    p11.flags2484 = bit32.bor(bit32.band(p11.flags2484, 4278190079), (bit32.band(bit32.rshift(p14.animation_flags, 4), 16777216)))

    if bit32.band(p11.flags2476, 1536) ~= 0 then
        p11.flags2476 = bit32.band(p11.flags2476, 4290772991)
    end
end

t1.clamp_control = clamp_control

return t1
