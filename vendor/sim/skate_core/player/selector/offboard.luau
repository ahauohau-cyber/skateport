-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local ProcessedStateInput = import("skate_core/player/selector/input").ProcessedStateInput
local PhysicalStateId = import("skate_core/player/state").PhysicalStateId
local t1 = {
    HANDPLANT_GROUND_DELAY_SECONDS = 0.20000000298023224,
    StateSelector = {}
}

function t1.StateSelector.select_biped_or_plant(_, p2, p3, p4) -- line: 20
    -- upvalues: rt (copy), ProcessedStateInput (copy), PhysicalStateId (copy), t1 (copy)
    local v1 = ProcessedStateInput.read(p3.processed)

    if p2 == PhysicalStateId.BipedGround then
        if p4.wipeout then
            return PhysicalStateId.WipeoutGround
        end

        if ProcessedStateInput.has_2484(v1, 65536) then
            return PhysicalStateId.BipedAir
        end

        if ProcessedStateInput.has_2476(v1, 2097152) then
            return PhysicalStateId.OffBoardPushing
        end

        if ProcessedStateInput.has_2476(v1, 32768) or ProcessedStateInput.has_2480(v1, 262144) then
            return p2
        end

        if not ProcessedStateInput.has_2484(v1, 1) and not ProcessedStateInput.has_2488(v1, 268435456) and not ProcessedStateInput.has_2488(v1, 2147483648) then
            return PhysicalStateId.PhysicsAir
        end

        return PhysicalStateId.PhysicsGround
    end

    if p2 == PhysicalStateId.BipedAir then
        if p4.wipeout then
            return PhysicalStateId.WipeoutGround
        end

        if ProcessedStateInput.has_2480(v1, 16) then
            return PhysicalStateId.LandingOnDeck
        end

        if not ProcessedStateInput.has_2484(v1, 65536) then
            return PhysicalStateId.BipedGround
        end

        if ProcessedStateInput.has_2476(v1, 32768) or ProcessedStateInput.has_2476(v1, 128) then
            return p2
        end

        return PhysicalStateId.PhysicsAir
    end

    if p2 == PhysicalStateId.OffBoardPushing then
        if p4.wipeout then
            return PhysicalStateId.WipeoutGround
        end

        if ProcessedStateInput.has_2476(v1, 2097152) then
            return p2
        end

        return PhysicalStateId.BipedGround
    end

    if p2 == PhysicalStateId.LandingOnDeck then
        if p4.wipeout then
            return PhysicalStateId.WipeoutGround
        end

        if ProcessedStateInput.has_2476(v1, 65536) then
            return PhysicalStateId.PhysicsGround
        end

        if ProcessedStateInput.has_2476(v1, 128) then
            return PhysicalStateId.BipedAir
        end

        return p2
    end

    if p2 == PhysicalStateId.HandPlant then
        if p4.wipeout then
            return PhysicalStateId.WipeoutGround
        end

        if not (p4.colliding and v1.state_timer_2664 > t1.HANDPLANT_GROUND_DELAY_SECONDS) and not (rt.to_i32(v1.flags_2480) >= 0) then
            return p2
        end

        return PhysicalStateId.PhysicsGround
    end

    if p2 == PhysicalStateId.FootPlant then
        if p4.wipeout then
            return PhysicalStateId.WipeoutGround
        end

        if ProcessedStateInput.has_2480(v1, 16777216) then
            return p2
        end

        return ProcessedStateInput.air_variant_from_2468(v1)
    end

    if p2 == PhysicalStateId.Boneless then
        if p4.wipeout then
            return PhysicalStateId.WipeoutGround
        end

        if ProcessedStateInput.has_2468(v1, 1024) then
            return PhysicalStateId.KnownAir
        end

        if ProcessedStateInput.has_2476(v1, 128) then
            return PhysicalStateId.BipedAir
        end

        if ProcessedStateInput.has_2480(v1, 16384) or ProcessedStateInput.has_2480(v1, 8192) then
            return p2
        end

        return PhysicalStateId.PhysicsAir
    end

    error("off-board/plant dispatch received another state", 0)
end

return t1
