-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local AttributeName = import("skate_core/animation/output/attributes").AttributeName
local encode = import("skate_core/animation/skeleton_input/name").encode
local t1 = {
    AnimationState = {}
}

function t1.AnimationState.new(p2) -- line: 27
    return {
        phase = 0,
        flags = bit32.bor(bit32.lshift(if p2 then 1 else 0, 27), 131072),
        publication = {
            orientation_bit31 = false,
            mirrored = false,
            riding_fakie = false,
            weight_on_nose = false,
            natural_stance = 1,
            relative_stance = 0,
            request_bit16 = false,
            request_bit15 = false,
            air_dismount_revert_requested = false,
            air_dismount_revert_frames = 0,
            signal = nil
        }
    }
end

function t1.AnimationState.mirrored(p3) -- line: 51
    return bit32.band(p3.flags, 1073741824) ~= 0
end

function t1.AnimationState.fakie(p4) -- line: 55
    return bit32.band(p4.flags, 536870912) ~= 0
end

function t1.AnimationState.switch(p5) -- line: 59
    return p5.publication.relative_stance == 1
end

function t1.AnimationState.apply_stance_events(p6, p7) -- line: 66
    -- upvalues: AttributeName (copy), encode (copy)
    local function present(p8) -- line: 67
        -- upvalues: p7 (copy), AttributeName (copy), encode (copy)
        local v4 = encode(p8)

        for _, v5 in ipairs(p7) do
            if AttributeName.eq(v5.name, v4) then
                return true
            end
        end

        return false
    end

    if present("animboardbackward") then
        p6.flags = bit32.bxor(p6.flags, 2147483648)
    end

    if present("mirrored") then
        p6.flags = bit32.bxor(p6.flags, 1073741824)
    end

    if not present("switch") then
        return
    end

    p6.publication.relative_stance = p6.publication.relative_stance == 0 and 1 or 0
end

function t1.AnimationState.prepare_publication(p9) -- line: 87
    local publication = p9.publication

    publication.orientation_bit31 = bit32.band(p9.flags, 2147483648) ~= 0
    publication.mirrored = bit32.band(p9.flags, 1073741824) ~= 0
    publication.riding_fakie = bit32.band(p9.flags, 536870912) ~= 0
    publication.weight_on_nose = bit32.band(p9.flags, 268435456) ~= 0
    publication.request_bit16 = bit32.band(p9.flags, 65536) ~= 0
    publication.request_bit15 = bit32.band(p9.flags, 32768) ~= 0
    publication.air_dismount_revert_requested = bit32.band(p9.flags, 1048576) ~= 0
end

function t1.AnimationState.finish_publication(p10) -- line: 98
    p10.flags = bit32.band(p10.flags, 4293820415)
end

function t1.AnimationState.cull_threshold(p11) -- line: 103
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, bit32.band(p11.flags, 134217728) == 0 and 1036831949 or 1008981770)

    return (buffer.readf32(v1, 0))
end

return t1
