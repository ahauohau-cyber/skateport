--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/post_physics.rs (коммит 2e16697)
--
-- `PhysState_PhysicsGround::UpdatePostPhysics` (`82D387A8`).

local post_physics = {}

-- ROBLOX: enum GroundPostPhysicsStage -> строки; ошибка — { stage, source }.
post_physics.GroundPostPhysicsStage = { CheckForGroundWipeout = "CheckForGroundWipeout", UpdateBoardPath = "UpdateBoardPath" }

-- Wipeout::CheckForGroundWipeout82D8F9E0 and board path82C05EC0.
-- There is deliberately no empty implementation.
-- services: check_for_ground_wipeout_82d8f9e0(), update_board_path_82c05ec0().
function post_physics.update_post_physics(offboard_trajectory_state_1776: number, services: any): (boolean?, any)
	local _, e1 = services:check_for_ground_wipeout_82d8f9e0()
	if e1 ~= nil then
		return nil, { stage = post_physics.GroundPostPhysicsStage.CheckForGroundWipeout, source = e1 }
	end
	if offboard_trajectory_state_1776 < 0 then
		local _, e2 = services:update_board_path_82c05ec0()
		if e2 ~= nil then
			return nil, { stage = post_physics.GroundPostPhysicsStage.UpdateBoardPath, source = e2 }
		end
	end
	return true, nil
end

return post_physics
