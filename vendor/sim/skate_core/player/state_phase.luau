-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

return {
    StatePhaseFields = {},
    StatePhaseServices = {},
    run_state_phase = function(p1, p2) -- run_state_phase | line: 35
        p2.update_current_state_vtable_8(p2)

        if p1.controller_system_on_452 then
            p2.update_controller_82d75f00(p2)

            local controller_state_448 = p1.controller_state_448

            if controller_state_448 == 1 then
                p2.update_controller_mode_1_82d751d8(p2)
            elseif controller_state_448 == 2 then
                p2.update_controller_mode_2_82d750f0(p2)
            elseif controller_state_448 == 3 then
                p2.update_controller_mode_3_82d75bb8(p2)
            elseif controller_state_448 == 4 then
                p2.update_controller_mode_4_82d75d58(p2)
            end
        end

        p2.touch_skateboard_vtable_116(p2)
        p2.apply_skateboard_force_queue_82c03718(p2)
        p2.update_skateboard_fixed_step_cache_82db61f0(p2)
        p1.elapsed_1344 += p1.timestep_2604
    end
}
