--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/filtered_state.rs (коммит 2e16697)
--
-- Complete filtered physical-state update82DE5BA0, with reset82DE5588.
-- This conditions the actual selected physics state; collision alone does not
-- select that state. Skate2 named82E2D800 identifies fields; TU3 governs branches.
-- ROBLOX: enum FilteredCategory (#[repr(u32)]) -> числа 0..7 в таблице FilteredCategory;
-- u64 (GUID) -> пара { hi, lo }.

local name_mod = require("../animation/skeleton_input/name")

local encode = name_mod.encode

local filtered_state = {}

filtered_state.FilteredCategory = table.freeze({
	Invalid = 0,
	Ground = 1,
	Air = 2,
	Grind = 3,
	Wipeout = 4,
	Teleport = 5,
	Offboard = 6,
	OffboardAir = 7,
})
local C = filtered_state.FilteredCategory

-- /// PhysOut.Grinds fields copied when the selected state is400..405. Names are
-- /// native five-word strings, never addresses or collection hashes.
export type GrindState = {
	kind: number,
	scorable_id: number,
	name: { number },
	scoring_name: { number },
	on_front: boolean,
	crouch: number,
	pathed_guid: { number },
	local_guid: { number },
}

local GrindState = {}
filtered_state.GrindState = GrindState

function GrindState.default(): GrindState
	return {
		kind = -1,
		scorable_id = -1,
		-- Initializer82F8AF08 encodes NUL text82060799 to830C0D60.
		name = encode(""),
		scoring_name = encode(""),
		on_front = false,
		crouch = 0.0,
		pathed_guid = { 0xffffffff, 0xffffffff },
		local_guid = { 0xffffffff, 0xffffffff },
	}
end

local function copy_grind(g: GrindState): GrindState
	return {
		kind = g.kind,
		scorable_id = g.scorable_id,
		name = table.clone(g.name),
		scoring_name = table.clone(g.scoring_name),
		on_front = g.on_front,
		crouch = g.crouch,
		pathed_guid = table.clone(g.pathed_guid),
		local_guid = table.clone(g.local_guid),
	}
end

export type FilteredStateInput = {
	-- Selected PhysOut.State category12 and state16, not filtered categories.
	physics_category: number,
	physics_state: number,
	-- PhysOut.Collision3477 and16, after actual collision publication.
	anything_in_contact: boolean,
	physics_surface_type: number,
	-- PhysOut.Ground316, owned by ground-state wall-ride exit calculations.
	wall_ride_exit: boolean,
	-- PhysOut.Air443, owned by the trajectory/grind target decision.
	targeting_grind: boolean,
	-- PhysOut.OffBoard320 and315 respectively.
	offboard_has_landed: boolean,
	offboard_on_deck: boolean,
	grind: GrindState,
	-- EmpiricalMeasurements82DE5858 updates conditioner196 before this call.
	last_grind_distance: number,
}

export type FilteredStateOutput = {
	category: number,
	previous_category: number,
	grinding: boolean,
	grind: GrindState,
	last_grind_distance: number,
}

-- ROBLOX: cached_grind в Rust приватное поле.
export type FilteredState = {
	category: number,
	previous_category: number,
	previous_physics_state: number,
	air_count: number,
	nonspecific_count: number,
	nonspecific_collision_free_count: number,
	nonspecific_collision_count: number,
	frames_since_ground_stairs: number,
	must_change: boolean,
	cached_grind: GrindState,
}

local FilteredState = {}
filtered_state.FilteredState = FilteredState

function FilteredState.default(): FilteredState
	return {
		category = C.Invalid,
		previous_category = C.Invalid,
		previous_physics_state = 0,
		air_count = 0,
		nonspecific_count = 0,
		nonspecific_collision_free_count = 0,
		nonspecific_collision_count = 0,
		frames_since_ground_stairs = 0,
		must_change = true,
		cached_grind = GrindState.default(),
	}
end

function FilteredState.reset(self: FilteredState)
	local fresh = FilteredState.default() :: any
	for k, v in fresh do
		(self :: any)[k] = v
	end
end

-- ROBLOX: i32::wrapping_add(1).
local function count(previous: number, active: boolean): number
	if active then
		local n = previous + 1
		return if n > 0x7fffffff then n - 0x1_0000_0000 else n
	end
	return 0
end

function FilteredState.update(self: FilteredState, input: FilteredStateInput): FilteredStateOutput
	local old = self.category
	self.previous_category = old
	self.must_change = old == C.Wipeout or old == C.Invalid or (self.previous_physics_state == 702 and input.physics_state ~= 702)
	self.air_count = count(self.air_count, input.physics_category == 200)
	self.nonspecific_count = count(self.nonspecific_count, input.physics_state == 701)
	self.nonspecific_collision_free_count = count(self.nonspecific_collision_free_count, input.physics_state == 701 and not input.anything_in_contact)
	self.nonspecific_collision_count = count(self.nonspecific_collision_count, input.physics_state == 701 and input.anything_in_contact)
	self.frames_since_ground_stairs = count(self.frames_since_ground_stairs, not (input.physics_category == 100 and input.physics_surface_type == 8))
	local s = input.physics_state
	local category
	if s == 100 then
		category = if input.wall_ride_exit then C.Air else C.Ground
	elseif (s >= 101 and s <= 105) or s == 602 then
		category = C.Ground
	elseif s == 200 then
		local air_delay_passed = self.air_count > 3
		if old == C.Air then
			-- TU3 adds contact return to ground, absent in the named S2 body.
			category = if (air_delay_passed and input.anything_in_contact) or self.must_change then C.Ground else C.Air
		else
			local may_enter_air = air_delay_passed and (old ~= C.Ground or self.frames_since_ground_stairs > 9)
			category = if may_enter_air or self.must_change then C.Air else old
		end
	elseif s == 201 then
		category = if input.anything_in_contact and not input.targeting_grind and self.air_count > 5 then C.Ground else C.Air
	elseif s == 202 or s == 600 or s == 601 then
		category = C.Air
	elseif s == 300 then
		category = C.Wipeout
	elseif s >= 400 and s <= 405 then
		self.cached_grind = copy_grind(input.grind)
		category = C.Grind
	elseif s == 500 or s == 502 then
		category = C.Offboard
	elseif s == 501 then
		category = if input.offboard_has_landed then C.Offboard else C.OffboardAir
	elseif s == 503 then
		category = if input.offboard_on_deck then C.Ground else C.Offboard
	elseif s == 702 then
		category = C.Teleport
	else
		-- Native701 and unrecognized states retain the prior category.
		category = old
	end
	self.category = category
	self.previous_physics_state = input.physics_state
	local grinding = self.category == C.Grind
	return {
		category = self.category,
		previous_category = self.previous_category,
		grinding = grinding,
		grind = if grinding then copy_grind(self.cached_grind) else GrindState.default(),
		last_grind_distance = input.last_grind_distance,
	}
end

return filtered_state
