-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    BODY_COUNT = 7,
    BodyId = {
        RightFrontWheel = 0,
        LeftFrontWheel = 1,
        RightBackWheel = 2,
        LeftBackWheel = 3,
        FrontTruck = 4,
        BackTruck = 5,
        Deck = 6
    }
}

t1.BodyId.ORDER = {
    t1.BodyId.RightFrontWheel,
    t1.BodyId.LeftFrontWheel,
    t1.BodyId.RightBackWheel,
    t1.BodyId.LeftBackWheel,
    t1.BodyId.FrontTruck,
    t1.BodyId.BackTruck,
    t1.BodyId.Deck
}

function t1.BodyId.index(p1) -- line: 34
    return p1
end

t1.RETAIL_WHEEL_RADIUS = 0.03099999949336052
t1.RETAIL_TRUCK_Y_POSITION = -0.05649999901652336
t1.RETAIL_TRUCK_Z_POSITION_BACK = -0.052000001072883606
t1.RETAIL_TRUCK_Z_POSITION_FRONT = -0.052000001072883606
t1.RETAIL_TRUCK_ROTATION_AXIS_ANGLE_DEGREES = 31
t1.RETAIL_DECK_MID_LENGTH = 0.5899999737739563

return t1
