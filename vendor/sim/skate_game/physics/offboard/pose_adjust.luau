-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/offboard/pose_adjust")
local SkateboardOffset = import("skate_core/physics/skeleton_board_offset").SkateboardOffset

return {
    update = function(p1, p2, p3, p4) -- update | line: 18
        -- upvalues: v1 (copy), SkateboardOffset (copy)
        local v2, v3

        if p4.category_2512 ~= 500 or p4.state_2508 == 503 then
            return
        else
            v2 = v1.selected_hand(p4.flags_2476)
            v3 = p2[p1.bone_indices[({ 3, 7 })[v2 + 1] + 1] + 1]

            if v3 == nil then
                error("Off-board pose missing actual animation hand", 0)
            end
        end

        local v5 = p2[p3[v2 + 1] + 1]

        if v5 == nil then
            error("Off-board pose missing board-parented animation hand", 0)
        end

        SkateboardOffset.refresh_transform(p1.board_offset, v1.adjustment(v3, v5))
    end
}
