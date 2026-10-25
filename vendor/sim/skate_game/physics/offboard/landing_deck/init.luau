-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/offboard/landing_deck/input")
local v2 = import("skate_game/physics/offboard/landing_deck/output")
local v3 = import("skate_game/physics/offboard/landing_deck/query")
local v4 = import("skate_core/player/offboard/landing_deck")
local v5 = import("skate_data/collections")
local Manager = v4.Manager
local Collections = v5.Collections
local t1 = {
    PublishTargets = v2.PublishTargets,
    Owner = {}
}

function t1.Owner.load(p1) -- line: 33
    -- upvalues: Manager (copy), Collections (copy)
    return {
        completion = nil,
        manager = Manager.default(),
        settings = {
            deck_min_uprightness = Collections.float(p1, "physics_landingondeck", "default", "DeckMinUprightness"),
            approximate_com_height = Collections.float(p1, "physics_landingondeck", "default", "ApproxCOMHeightOnLanding")
        }
    }
end

function t1.Owner.reset(p2) -- line: 50
    -- upvalues: Manager (copy)
    Manager.reset(p2.manager)
end

function t1.Owner.assist(p3, p4, p5, p6) -- line: 57
    -- upvalues: rt (copy), v1 (copy), v3 (copy), Manager (copy)
    local v6 = rt.copy(p3.manager)
    local v7 = v1.processed(p5)
    local v8 = Manager.assist(v6, {
        processed = v7,
        position = v1.position(p5),
        velocity = v1.velocity(p5),
        maximum_velocity_change = p6
    }, p3.settings)
    local v9 = if v8 == nil then nil else v3.execute(p4, v8, p5.processed)

    if v9 ~= nil then
        p3.completion = v9
        Manager.query_submitted(v6)
    end

    p3.manager = v6
end

function t1.Owner.update(p7, p8, p9) -- line: 82
    -- upvalues: rt (copy), v1 (copy), v3 (copy), Manager (copy)
    local v10 = rt.copy(p7.manager)
    local v11 = Manager.update(v10, v1.processed(p9), p7.settings)
    local v12 = if v11.query == nil then nil else v3.execute(p8, rt.copy(v11.query), p9.processed)

    if v12 ~= nil then
        p7.completion = v12
        Manager.query_submitted(v10)
    end

    p7.manager = v10

    return v11
end

function t1.Owner.calculate_accurate_ik_offset(p10, p11, p12, p13, p14) -- line: 102
    -- upvalues: rt (copy), v1 (copy), Manager (copy)
    return Manager.calculate_accurate_ik_offset(p10.manager, {
        processed = v1.processed(p11),
        time_to_land = p14,
        animation_root = rt.copy(p12.roots.animation_to_world),
        animation_com_10960 = rt.copy(p12.record.centre_of_mass),
        mapped_position_12608 = rt.copy(p13)
    })
end

function t1.Owner.fill(p15) -- line: 113
    -- upvalues: Manager (copy)
    return Manager.fill(p15.manager)
end

for v13, v14 in v2.Owner do
    t1.Owner[v13] = v14
end

for v15, v16 in v3.Owner do
    t1.Owner[v15] = v16
end

return t1
