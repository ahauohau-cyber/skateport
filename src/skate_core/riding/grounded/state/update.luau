--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/update.rs (коммит 2e16697)
--
-- `PhysState_PhysicsGround::Update` (`82D37C88`) call composition.

local rt = require("../../../../rt")
local pumping_controller = require("../../pumping/controller")
local contact_state = require("./contact_state")
local data = require("./data")

local update_mod = {}

-- ROBLOX: enum GroundUpdateStage -> строки; GroundUpdateError -> { stage, source }.
update_mod.GroundUpdateStage = {
	SetElapsedSkeletonFlag = "SetElapsedSkeletonFlag",
	UpdateContactState = "UpdateContactState",
	LoadPumpingFrame = "LoadPumpingFrame",
	UpdatePumping = "UpdatePumping",
	UpdateSkateboard = "UpdateSkateboard",
	PredictFutureDeck = "PredictFutureDeck",
	SetCollisionSkeletonFlag = "SetCollisionSkeletonFlag",
	SetGroundSkeletonFlag = "SetGroundSkeletonFlag",
	UpdateSpecialState = "UpdateSpecialState",
	UpdateTrajectory = "UpdateTrajectory",
}
local Stage = update_mod.GroundUpdateStage

-- Required engine-facing operations in the exact `82D37C88` order. This
-- trait has no default implementation because each call mutates stock-owned
-- objects that are outside `skate-core`.
-- ROBLOX: services — одна таблица: методы PumpingGeometry, GroundContactServices и
--   set_elapsed_skeleton_flag(), pumping_frame() -> (settings, mode, sample) упакованы
--   как { settings, mode, sample }, update_skateboard(state), predict_future_deck(),
--   set_collision_skeleton_flag(), set_ground_skeleton_flag(), update_special_state(),
--   update_trajectory().

local function call(stage: string, value: any, err: any): any
	if err ~= nil then
		rt.raise({ stage = stage, source = err })
	end
	return value
end

-- Runs the full recovered outer Ground update. State writes before a failing
-- service remain visible, matching the native non-transactional execution.
function update_mod.update(state: data.PhysicsGroundState, pumping: any, contacts: data.GroundContactHistory, input: data.GroundUpdateInput, services: any): (boolean?, any)
	return rt.catch(function(): boolean
		local signals = data.PhysicsGroundState.begin_update(state, input)
		if signals.set_skeleton_flag_16505 then
			call(Stage.SetElapsedSkeletonFlag, services:set_elapsed_skeleton_flag())
		end
		call(Stage.UpdateContactState, contact_state.update(contacts, input.contact_state, services))
		local frame = call(Stage.LoadPumpingFrame, services:pumping_frame())
		call(Stage.UpdatePumping, pumping_controller.update_ground(pumping, frame.settings, frame.mode, frame.sample, services))
		call(Stage.UpdateSkateboard, services:update_skateboard(state))
		call(Stage.PredictFutureDeck, services:predict_future_deck())
		if state.flag_2722 then
			call(Stage.SetCollisionSkeletonFlag, services:set_collision_skeleton_flag())
		end
		call(Stage.SetGroundSkeletonFlag, services:set_ground_skeleton_flag())
		data.PhysicsGroundState.finish_update(state, input.timestep_2604)
		if bit32.btest(input.contact_state.flags_2476, 0x0040_0000) then
			call(Stage.UpdateSpecialState, services:update_special_state())
		else
			call(Stage.UpdateTrajectory, services:update_trajectory())
		end
		return true
	end)
end

return update_mod
