--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/selector/mod.rs (коммит 2e16697)
--
-- Readable port of TU3 `PhysicalPlayerStateChanger::CalcSuggestedState`
-- (`0x82D8ADE8`) and its directly-called predicates.
-- ROBLOX: Option<PhysicalStateId> -> число или nil; i32::wrapping_add ->
-- rt.to_i32(x + 1); методы StateSelector из ground/air/offboard — функции
-- этих модулей с self первым аргументом.

local rt = require("../../rt")
local state = require("./state")
local air = require("@self/air")
local conditions = require("@self/conditions")
local ground = require("@self/ground")
local input_mod = require("@self/input")
local offboard = require("@self/offboard")

local S = state.PhysicalStateId
local P = input_mod.ProcessedStateInput
local to_i32 = rt.to_i32

local selector = {}

selector.conditions = conditions
selector.input = input_mod
selector.ProcessedStateInput = input_mod.ProcessedStateInput

export type ProcessedStateInput = input_mod.ProcessedStateInput
export type StateSelectionInput = input_mod.StateSelectionInput

export type StateSelector = {
	current_state: number?,
	nonspecific_collision_free_frames: number,
	nonspecific_collision_frames: number,
	something_colliding_frames: number,
	two_wheel_counter: number,
	three_wheel_counter: number,
	post_grind_jump_counter: number,
	air_frames: number,
	teleport_countdown: number,
	skitch_exit_countdown: number,
	revert_exited_normally: boolean,
	request_teleport: boolean,
}

-- ROBLOX: pub(super) struct FrameFacts; grind: число или nil.
export type FrameFacts = {
	colliding: boolean,
	wipeout: boolean,
	force_known_air: boolean,
	skateboard_animated: boolean,
	off_ground: boolean,
	off_ground_skitching: boolean,
	grind: number?,
}

local StateSelector = {}
selector.StateSelector = StateSelector

-- ROBLOX: #[derive(Default)].
function StateSelector.default(): StateSelector
	return {
		current_state = nil,
		nonspecific_collision_free_frames = 0,
		nonspecific_collision_frames = 0,
		something_colliding_frames = 0,
		two_wheel_counter = 0,
		three_wheel_counter = 0,
		post_grind_jump_counter = 0,
		air_frames = 0,
		teleport_countdown = 0,
		skitch_exit_countdown = 0,
		revert_exited_normally = false,
		request_teleport = false,
	}
end

local function check_for_grind(input: ProcessedStateInput): number?
	if not input.grind_candidate_1488 or P.has_2480(input, 0x20000) or P.has_2480(input, 0x4000000) then
		return nil
	end
	local t = input.grind_type_1248
	if t == 0 then
		return S.GrindFiftyFifty
	elseif t == 1 then
		return S.GrindBoardslide
	elseif t == 2 then
		return S.GrindTipslide
	elseif t == 3 then
		return S.GrindFiveO
	elseif t == 4 then
		return S.GrindBackslash
	elseif t == 5 then
		return S.GrindDarkslide
	end
	return nil
end

local function select_nonspecific(self: StateSelector, current: number, input: StateSelectionInput, facts: FrameFacts): number
	local p = input.processed
	if P.has_2484(p, 0x100000) then
		return S.PhysicsAirSecondary
	end
	if facts.wipeout then
		return S.WipeoutGround
	end
	if P.has_2468(p, 0x100) then
		return P.air_variant_from_2468(p)
	end
	if P.has_2468(p, 0x400000) then
		return current
	end
	if P.has_2472(p, 8) then
		return if P.has_2484(p, 0x200000) then S.WipeoutGround else S.PhysicsAir
	end
	if P.has_2472(p, 4) then
		return current
	end
	if facts.grind ~= nil then
		return facts.grind
	end
	if bit32.band(p.grind_investigation_flags_1516, 0x8000000) ~= 0 then
		if self.three_wheel_counter > 10 then
			return S.PhysicsGround
		end
	elseif self.two_wheel_counter > 2 then
		return if facts.skateboard_animated then S.GroundAnimation else S.PhysicsGround
	end
	if self.nonspecific_collision_free_frames > 2 then
		return S.PhysicsAir
	end
	local collision_exit_frames = if P.has_2484(p, 0x200000) then 30 else 60
	if self.nonspecific_collision_frames > collision_exit_frames then
		return S.PhysicsGround
	else
		return current
	end
end

-- Executes the complete state decision tree and all state-changer-local
-- counter/flag writes performed by TU3 `0x82D8ADE8`.
function StateSelector.calculate(self: StateSelector, current: number, input: StateSelectionInput): number
	local p = input.processed
	if self.teleport_countdown > 0 then
		self.teleport_countdown = to_i32(self.teleport_countdown - 1)
	end
	self.current_state = current
	self.revert_exited_normally = false
	self.request_teleport = false

	local colliding = p.wheel_contact_count_2556 > 0 or P.has_2468(p, 0x10000) or P.has_2468(p, 0x20000)
	self.nonspecific_collision_free_frames = if current == S.Nonspecific and not colliding
		then to_i32(self.nonspecific_collision_free_frames + 1)
		else 0
	self.nonspecific_collision_frames = if current == S.Nonspecific and colliding
		then to_i32(self.nonspecific_collision_frames + 1)
		else 0
	self.two_wheel_counter = if input.skateboard_contact_count_869 > 1 then to_i32(self.two_wheel_counter + 1) else 0
	self.three_wheel_counter = if input.skateboard_contact_count_869 > 2 then to_i32(self.three_wheel_counter + 1) else 0
	self.something_colliding_frames = if colliding then to_i32(self.something_colliding_frames + 1) else 0
	local special_grind = p.category_2512 == 400 and P.has_2468(p, 0x400000)
	self.post_grind_jump_counter = if special_grind then 0 else to_i32(self.post_grind_jump_counter + 1)
	if p.category_2512 == 200 then
		if not P.has_2468(p, 8) then
			self.air_frames = to_i32(self.air_frames + 1)
		end
	else
		self.air_frames = 0
	end
	if current == S.Skitching then
		self.skitch_exit_countdown = 10
	elseif self.skitch_exit_countdown > 0 then
		self.skitch_exit_countdown = to_i32(self.skitch_exit_countdown - 1)
	else
		self.skitch_exit_countdown = 0
	end

	if P.has_2468(p, 2) or P.has_2472(p, 0x40000) then
		return S.Teleporting
	end
	if self.air_frames > 300 then
		self.request_teleport = true
		return current
	end
	-- ROBLOX: field_1776 as u32 -> по модулю 2^32.
	if p.field_1776 < 0 and bit32.band(p.field_1776 % 0x100000000, 0x2000000) == 0 and self.teleport_countdown == 0 then
		return S.FollowPath
	end

	local facts: FrameFacts = {
		colliding = colliding,
		wipeout = P.has_2468(p, 0x40000),
		force_known_air = P.has_2472(p, 0x40),
		skateboard_animated = conditions.is_skateboard_animated(input.skeleton),
		off_ground = conditions.condition_is_off_ground(input.board_body, input.normal_off_ground),
		off_ground_skitching = conditions.condition_is_off_ground_skitching(input.board_body, input.skitching_off_ground),
		grind = check_for_grind(p),
	}

	if current >= 100 and current <= 105 then
		return ground.select_ground_family(self, current, input, facts)
	elseif current == S.PhysicsAir then
		return air.select_physics_air(self, current, input, facts)
	elseif current == S.KnownAir then
		return air.select_known_air(self, current, input, facts)
	elseif current == S.PhysicsAirSecondary then
		if facts.wipeout then
			return S.WipeoutGround
		elseif not P.has_2484(p, 0x100000) then
			return S.PhysicsAir
		else
			return current
		end
	elseif current == S.WipeoutGround or current == S.Sleeping or current == S.Teleporting then
		return current
	elseif current >= 400 and current <= 405 then
		return air.select_grind(self, current, input, facts)
	elseif (current >= 500 and current <= 503) or (current >= 600 and current <= 602) then
		return offboard.select_biped_or_plant(self, current, input, facts)
	elseif current == S.Nonspecific then
		return select_nonspecific(self, current, input, facts)
	end
	-- ROBLOX: в Rust match по enum исчерпывающий; сюда попадает только
	-- число, не являющееся PhysicalStateId.
	error("unknown PhysicalStateId " .. tostring(current))
end

return selector
