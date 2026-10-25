-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/wipeout_states/ragdoll")
local v2 = import("skate_core/player/wipeout_state/contact_response")
local RagdollSetup = v1.RagdollSetup
local ContactResponse = v2.ContactResponse

return {
    update = function(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12) -- update | line: 21
        -- upvalues: rt (copy), RagdollSetup (copy), ContactResponse (copy)
        local v3 = ContactResponse.update(p2, p3, {
            com_velocity_608 = p10,
            material10_normal = if p4.flags.material_10 then rt.copy(p4.material_normals[1]) else nil,
            material11_normal = if p4.flags.material_11 then rt.copy(p4.material_normals[2]) else nil,
            effective_axis_224 = p11,
            wipeout_control_2824_2828 = p12
        })

        p1.material_ten_response = v3.material10_finished_77

        local v4 = not p9 and not (p1.predicted_time <= 0.3)
        local v5 = p1.air_collision_mode ~= v4

        p1.air_collision_mode = v4

        local v6 = p1.material_eleven_response ~= v3.material11_active_73

        p1.material_eleven_response = v3.material11_active_73

        if not p1.special_surface and (v5 or v6) then
            local v7 = if p1.material_eleven_response then 9 elseif v4 then 11 else 8

            RagdollSetup.request(p8, p5, v7, p3, p7, p6)
        end
    end
}
