-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

return {
    AdjustFields = {},
    AdjustServices = {},
    run_adjust = function(p1, p2) -- run_adjust | line: 37
        -- upvalues: rt (copy)
        if p2.board_condition_82c02138(p2) == 1 and p1.processed_word_2512 ~= 500 then
            p1.output_flag_42 = true
            p1.output_scalar_144 = 0
            p1.output_counter_200 = rt.wrapping_add_u32(p1.output_counter_200, 1)
        end

        local v1 = p1.controller_state_448 == 1 and p2.controller_mode_one_board_flag_868(p2)

        p2.adjust_skeleton_82bd80d8(p2, v1, p1.timestep_2604)
        p2.update_current_state_post_physics_vtable_40(p2)

        local v2 = p2.player_output_selector_82db9100(p2)

        p2.finish_skeleton_adjustment_82bd83e0(p2, v2)
    end
}
