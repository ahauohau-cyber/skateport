-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    GroundPostPhysicsStage = {},
    GroundPostPhysicsError = {}
}

local function finish(p1, p2, ...) -- line: 22
    if p2 then
        return ...
    end

    error({
        stage = p1,
        source = ...
    }, 0)

    return ...
end

function t1.update_post_physics(p3, p4) -- line: 30
    -- upvalues: finish (copy)
    local check_for_ground_wipeout_82d8f9e0 = p4.check_for_ground_wipeout_82d8f9e0

    finish("CheckForGroundWipeout", pcall(check_for_ground_wipeout_82d8f9e0, p4))

    if p3 < 0 then
        local update_board_path_82c05ec0 = p4.update_board_path_82c05ec0

        finish("UpdateBoardPath", pcall(update_board_path_82c05ec0, p4))
    end
end

return t1
