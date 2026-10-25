-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local PhysicalStateId = require(sim.import)("skate_core/player/state").PhysicalStateId
local t1 = {
    StateCapability = {}
}

function t1.StateCapability.eq(p1, p2) -- line: 22
    if p1.id == p2.id and p1.supported == p2.supported and p1.has_enter == p2.has_enter then
        return p1.has_exit == p2.has_exit
    end

    return false
end

t1.StateRegistry = {}

function t1.StateRegistry.default() -- line: 29
    return {}
end

function t1.StateRegistry.new() -- line: 33
    return {}
end

local function is_connected_state(p3) -- line: 38
    -- upvalues: PhysicalStateId (copy)
    if p3 == PhysicalStateId.PhysicsGround
        or p3 == PhysicalStateId.PhysicsAir
        or p3 == PhysicalStateId.PhysicsAirSecondary
        or p3 == PhysicalStateId.FootPlant
        or p3 == PhysicalStateId.Boneless
        or p3 == PhysicalStateId.HandPlant
        or p3 == PhysicalStateId.RevertGround
        or p3 == PhysicalStateId.KnownAir
        or p3 == PhysicalStateId.BipedAir
        or p3 == PhysicalStateId.BipedGround
        or p3 == PhysicalStateId.OffBoardPushing
        or p3 == PhysicalStateId.GroundAnimation
        or p3 == PhysicalStateId.SlideGround
        or p3 == PhysicalStateId.WipeoutGround
        or p3 == PhysicalStateId.Teleporting then
        return true
    end

    return p3 == PhysicalStateId.LandingOnDeck
end

function t1.StateRegistry.capability(_, p5) -- line: 57
    -- upvalues: PhysicalStateId (copy), is_connected_state (copy)
    local v1 = PhysicalStateId.is_grind(p5)

    if not v1 then
        v1 = p5 == PhysicalStateId.Nonspecific or p5 == PhysicalStateId.Sleeping or is_connected_state(p5)
    end

    return {
        id = p5,
        supported = v1,
        has_enter = v1 and p5 ~= PhysicalStateId.Sleeping,
        has_exit = v1
    }
end

function t1.StateRegistry.can_transition(p6, p7, p8) -- line: 70
    -- upvalues: PhysicalStateId (copy), t1 (copy), is_connected_state (copy)
    if t1.StateRegistry.capability(p6, p7).supported and t1.StateRegistry.capability(p6, p8).supported then
        if p7 ~= PhysicalStateId.Sleeping and (PhysicalStateId.is_grind(p7) or PhysicalStateId.is_grind(p8) or p7 == PhysicalStateId.Nonspecific or p8 == PhysicalStateId.Nonspecific) then
            return true
        end

        if p7 ~= PhysicalStateId.Sleeping or p8 ~= PhysicalStateId.PhysicsGround then
            return is_connected_state(p7) and is_connected_state(p8)
        end

        return true
    end

    return false
end

return t1
