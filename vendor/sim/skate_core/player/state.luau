-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    PhysicalStateId = {
        PhysicsGround = 100,
        SlideGround = 101,
        RevertGround = 102,
        GroundAnimation = 103,
        Skitching = 104,
        FollowPath = 105,
        PhysicsAir = 200,
        KnownAir = 201,
        PhysicsAirSecondary = 202,
        WipeoutGround = 300,
        GrindBoardslide = 400,
        GrindFiftyFifty = 401,
        GrindTipslide = 402,
        GrindFiveO = 403,
        GrindBackslash = 404,
        GrindDarkslide = 405,
        BipedGround = 500,
        BipedAir = 501,
        OffBoardPushing = 502,
        LandingOnDeck = 503,
        HandPlant = 600,
        FootPlant = 601,
        Boneless = 602,
        Sleeping = 700,
        Nonspecific = 701,
        Teleporting = 702
    }
}
local PhysicalStateId = t1.PhysicalStateId

t1.UnknownPhysicalState = {}

function t1.PhysicalStateId.try_from(p1) -- line: 50
    -- upvalues: PhysicalStateId (copy)
    if p1 == 100 then
        return PhysicalStateId.PhysicsGround
    end

    if p1 == 101 then
        return PhysicalStateId.SlideGround
    end

    if p1 == 102 then
        return PhysicalStateId.RevertGround
    end

    if p1 == 103 then
        return PhysicalStateId.GroundAnimation
    end

    if p1 == 104 then
        return PhysicalStateId.Skitching
    end

    if p1 == 105 then
        return PhysicalStateId.FollowPath
    end

    if p1 == 200 then
        return PhysicalStateId.PhysicsAir
    end

    if p1 == 201 then
        return PhysicalStateId.KnownAir
    end

    if p1 == 202 then
        return PhysicalStateId.PhysicsAirSecondary
    end

    if p1 == 300 then
        return PhysicalStateId.WipeoutGround
    end

    if p1 == 400 then
        return PhysicalStateId.GrindBoardslide
    end

    if p1 == 401 then
        return PhysicalStateId.GrindFiftyFifty
    end

    if p1 == 402 then
        return PhysicalStateId.GrindTipslide
    end

    if p1 == 403 then
        return PhysicalStateId.GrindFiveO
    end

    if p1 == 404 then
        return PhysicalStateId.GrindBackslash
    end

    if p1 == 405 then
        return PhysicalStateId.GrindDarkslide
    end

    if p1 == 500 then
        return PhysicalStateId.BipedGround
    end

    if p1 == 501 then
        return PhysicalStateId.BipedAir
    end

    if p1 == 502 then
        return PhysicalStateId.OffBoardPushing
    end

    if p1 == 503 then
        return PhysicalStateId.LandingOnDeck
    end

    if p1 == 600 then
        return PhysicalStateId.HandPlant
    end

    if p1 == 601 then
        return PhysicalStateId.FootPlant
    end

    if p1 == 602 then
        return PhysicalStateId.Boneless
    end

    if p1 == 700 then
        return PhysicalStateId.Sleeping
    end

    if p1 == 701 then
        return PhysicalStateId.Nonspecific
    end

    if p1 == 702 then
        return PhysicalStateId.Teleporting
    end

    error({ p1 }, 0)

    return nil
end

t1.PhysicalStateId.ALL = {
    PhysicalStateId.PhysicsGround,
    PhysicalStateId.SlideGround,
    PhysicalStateId.RevertGround,
    PhysicalStateId.GroundAnimation,
    PhysicalStateId.Skitching,
    PhysicalStateId.FollowPath,
    PhysicalStateId.PhysicsAir,
    PhysicalStateId.KnownAir,
    PhysicalStateId.PhysicsAirSecondary,
    PhysicalStateId.WipeoutGround,
    PhysicalStateId.GrindBoardslide,
    PhysicalStateId.GrindFiftyFifty,
    PhysicalStateId.GrindTipslide,
    PhysicalStateId.GrindFiveO,
    PhysicalStateId.GrindBackslash,
    PhysicalStateId.GrindDarkslide,
    PhysicalStateId.BipedGround,
    PhysicalStateId.BipedAir,
    PhysicalStateId.OffBoardPushing,
    PhysicalStateId.LandingOnDeck,
    PhysicalStateId.HandPlant,
    PhysicalStateId.FootPlant,
    PhysicalStateId.Boneless,
    PhysicalStateId.Sleeping,
    PhysicalStateId.Nonspecific,
    PhysicalStateId.Teleporting
}

function t1.PhysicalStateId.native_owner_offset(p2) -- line: 141
    -- upvalues: PhysicalStateId (copy)
    if p2 == PhysicalStateId.Sleeping then
        return 1692
    end

    if p2 == PhysicalStateId.PhysicsGround then
        return 1696
    end

    if p2 == PhysicalStateId.SlideGround then
        return 1700
    end

    if p2 == PhysicalStateId.RevertGround then
        return 1704
    end

    if p2 == PhysicalStateId.GroundAnimation then
        return 1708
    end

    if p2 == PhysicalStateId.PhysicsAir then
        return 1712
    end

    if p2 == PhysicalStateId.PhysicsAirSecondary then
        return 1716
    end

    if p2 == PhysicalStateId.KnownAir then
        return 1720
    end

    if p2 == PhysicalStateId.GrindDarkslide then
        return 1724
    end

    if p2 == PhysicalStateId.GrindBoardslide then
        return 1728
    end

    if p2 == PhysicalStateId.GrindFiftyFifty then
        return 1732
    end

    if p2 == PhysicalStateId.GrindTipslide then
        return 1736
    end

    if p2 == PhysicalStateId.GrindFiveO then
        return 1740
    end

    if p2 == PhysicalStateId.GrindBackslash then
        return 1744
    end

    if p2 == PhysicalStateId.WipeoutGround then
        return 1748
    end

    if p2 == PhysicalStateId.Nonspecific then
        return 1752
    end

    if p2 == PhysicalStateId.Teleporting then
        return 1756
    end

    if p2 == PhysicalStateId.FollowPath then
        return 1760
    end

    if p2 == PhysicalStateId.BipedGround then
        return 1764
    end

    if p2 == PhysicalStateId.BipedAir then
        return 1768
    end

    if p2 == PhysicalStateId.Skitching then
        return 1772
    end

    if p2 == PhysicalStateId.OffBoardPushing then
        return 1776
    end

    if p2 == PhysicalStateId.HandPlant then
        return 1780
    end

    if p2 == PhysicalStateId.FootPlant then
        return 1784
    end

    if p2 == PhysicalStateId.Boneless then
        return 1788
    end

    if p2 == PhysicalStateId.LandingOnDeck then
        return 1792
    end

    error("PhysicalStateId::native_owner_offset: not a PhysicalStateId", 0)
end

function t1.PhysicalStateId.category(p3) -- line: 200
    -- upvalues: rt (copy)
    return rt.idiv(p3, 100) * 100
end

function t1.PhysicalStateId.is_grind(p4) -- line: 204
    -- upvalues: PhysicalStateId (copy)
    if p4 == PhysicalStateId.GrindBoardslide or p4 == PhysicalStateId.GrindFiftyFifty or p4 == PhysicalStateId.GrindTipslide or p4 == PhysicalStateId.GrindFiveO or p4 == PhysicalStateId.GrindBackslash then
        return true
    end

    return p4 == PhysicalStateId.GrindDarkslide
end

return t1
