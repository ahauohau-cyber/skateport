-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/trigonometry")
local Collections = import("skate_data/collections").Collections

return {
    load = function(p1) -- load | line: 16
        -- upvalues: v1 (copy), Collections (copy)
        local function air(p2) -- line: 17
            -- upvalues: p1 (copy), Collections (copy)
            return Collections.float(p1, "physics_grinds_air", "default", p2)
        end

        local function deck(p3) -- line: 20
            -- upvalues: p1 (copy), Collections (copy)
            return Collections.float(p1, "physicsdeck", "default", p3)
        end

        local v2 = Collections.float(p1, "physicsdeck", "default", "DeckMidLength") * 0.5
        local v3 = Collections.float(p1, "physicsdeck", "default", "DeckFrontEndSize") * Collections.float(p1, "physics_grinds_air", "default", "TipOffsetFraction")
        local v4 = Collections.float(p1, "physicsdeck", "default", "DeckFrontEndAngle") * 3.141592653589793 / 180
        local v5 = v2 + Collections.float(p1, "physicstrucks", "default", "TruckZPosFront")
        local TruckYPos = Collections.float(p1, "physicstrucks", "default", "TruckYPos")
        local NumFramesToTest = Collections.integer(p1, "physics_grinds_air", "default", "NumFramesToTest")

        if not (NumFramesToTest >= 2 and NumFramesToTest <= 12) then
            error("GrindAir NumFramesToTest exceeds native12-frame storage", 0)
        end

        local StompAccelerationAdjust = Collections.float(p1, "physics_grinds_air", "default", "StompAccelerationAdjust")
        local v6 = v1.sin_cos(v4)
        local v7 = v1.sin_cos(v4)

        return {
            frames = NumFramesToTest,
            stomp = StompAccelerationAdjust,
            points = {
                { 0, 0, 0, 0 },
                {
                    0,
                    v3 * v6,
                    v2 + v3,
                    0
                },
                { 0, TruckYPos, v5, 0 },
                { 0, TruckYPos, -v5, 0 },
                {
                    0,
                    v3 * v7,
                    -v2 - v3,
                    0
                }
            },
            ranges = {
                90,
                Collections.float(p1, "physics_grinds_air", "default", "AngleRangeTipSlide"),
                Collections.float(p1, "physics_grinds_air", "default", "AngleRangeTipSlide"),
                Collections.float(p1, "physics_grinds_air", "default", "AngleRangeBoardSlide"),
                Collections.float(p1, "physics_grinds_air", "default", "AngleRange50_50"),
                Collections.float(p1, "physics_grinds_air", "default", "AngleRange5_0"),
                air("AngleRange5_0")
            },
            distances = {
                v5,
                v5 * Collections.float(p1, "physics_grinds_air", "default", "MaxDistTipSlide"),
                v5 * Collections.float(p1, "physics_grinds_air", "default", "MaxDistTipSlide"),
                v5 * Collections.float(p1, "physics_grinds_air", "default", "MaxDistBoardSlide"),
                v5 * Collections.float(p1, "physics_grinds_air", "default", "MaxDist50_50"),
                v5 * Collections.float(p1, "physics_grinds_air", "default", "MaxDist5_0"),
                v5 * Collections.float(p1, "physics_grinds_air", "default", "MaxDist5_0")
            },
            yaw_assist = {
                Collections.float(p1, "physics_grinds_air", "default", "AngleYAssistBoardSlide"),
                Collections.float(p1, "physics_grinds_air", "default", "AngleYAssistTipSlide"),
                Collections.float(p1, "physics_grinds_air", "default", "AngleYAssistTipSlide"),
                Collections.float(p1, "physics_grinds_air", "default", "AngleYAssistBoardSlide"),
                Collections.float(p1, "physics_grinds_air", "default", "AngleYAssist50_50"),
                Collections.float(p1, "physics_grinds_air", "default", "AngleYAssist5_0"),
                air("AngleYAssist5_0")
            },
            max_offset = Collections.float(p1, "physics_grinds_air", "default", "MaxOffsetDist"),
            max_delta = Collections.float(p1, "physics_grinds_air", "default", "MaxOffsetDeltaPerFrame"),
            max_angle = Collections.float(p1, "physics_grinds_air", "default", "MaxAngleDeltaPerFrame")
        }
    end
}
