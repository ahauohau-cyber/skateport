-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local v1 = import("skate_game/physics/offboard/settings/curves")
local Collections = import("skate_data/collections").Collections
local t1 = {
    Settings = {}
}

function t1.Settings.load(p2) -- line: 29
    -- upvalues: rt (copy), v1 (copy), Collections (copy)
    local t2 = {
        height = Collections.float(p2, "physics_state_offboard_air", "default", "Hash_AB0D9EAEBFC584E9"),
        sphere_radius = Collections.float(p2, "physics_state_offboard_air", "default", "TrajectorySphereRadius"),
        start_index = rt.to_i32(Collections.integer(p2, "physics_state_offboard_air", "default", "TrajectoryStartIndex"))
    }
    local height = t2.height
    local v2 = false

    if height == height and height ~= 1e999 and height ~= (-1e999) then
        local sphere_radius = t2.sphere_radius

        v2 = sphere_radius == sphere_radius and sphere_radius ~= 1e999 and sphere_radius ~= (-1e999) and not (t2.sphere_radius <= 0)
    end

    if not v2 then
        error("Invalid stock BipedAir height/radius", 0)
    end

    local TrajBlendAmountVsTime = v1.load(8, p2, "physics_state_offboard_air", "TrajBlendAmountVsTime")
    local DeckCenterToTruck = Collections.float(p2, "physics_grinds", "default", "DeckCenterToTruck")

    if not (DeckCenterToTruck == DeckCenterToTruck and DeckCenterToTruck ~= 1e999 and DeckCenterToTruck ~= (-1e999)) or DeckCenterToTruck <= 0 then
        error("Invalid stock DeckCenterToTruck", 0)
    end

    return {
        query = t2,
        blend = TrajBlendAmountVsTime,
        deck_center_to_truck = DeckCenterToTruck
    }
end

return t1
