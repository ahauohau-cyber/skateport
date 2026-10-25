-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/wipeout_states/drive_settings")
local v2 = import("skate_game/physics/wipeout_states/lifecycle")
local v3 = import("skate_game/physics/wipeout_states/output")
local v4 = import("skate_game/physics/wipeout_states/prediction")
local v5 = import("skate_game/physics/wipeout_states/ragdoll")
local v6 = import("skate_game/physics/wipeout_states/settings")
local v7 = import("skate_game/physics/wipeout_states/update")
local v8 = import("skate_core/player/wipeout_state")
local v9 = import("skate_core/player/wipeout_state/contact_response")
local State = v8.State
local ContactResponse = v9.ContactResponse
local t1 = {
    WipeoutState = {}
}

function t1.WipeoutState.load(p1, p2, p3) -- line: 37
    -- upvalues: rt (copy), v1 (copy), v4 (copy), v5 (copy), v6 (copy), State (copy), ContactResponse (copy)
    local t2 = {
        "free_fall",
        "cannon_ball",
        "judo_kick",
        "swan_dive",
        "torpedo"
    }
    local v10 = rt.map(t2, function(p4) -- line: 48
        -- upvalues: p1 (copy), v6 (copy)
        local load_profile = v6.load_profile
        local ok, result = pcall(load_profile, p1, p4)

        return { ok, result }
    end)
    local v11 = v5.RagdollSetup.load(p1, p2, p3)
    local v12 = State.default()
    local v13 = v6.Settings.load(p1)
    local v14 = v1.load(p1, p2, p3)
    local v15 = table.create(5)

    for i = 1, 5 do
        local v16 = v10[i]

        if not v16[1] then
            error(v16[2], 0)
        end

        v15[i] = v16[2]
    end

    return {
        ragdoll = v11,
        state = v12,
        settings = v13,
        drives = v14,
        profiles = v15,
        contact = ContactResponse.new(),
        prediction = v4.Prediction.new()
    }
end

t1.enter = v2.enter
t1.exit = v2.exit
t1.post_physics = v2.post_physics
t1.fill = v3.fill
t1.advance = v7.advance

return t1
