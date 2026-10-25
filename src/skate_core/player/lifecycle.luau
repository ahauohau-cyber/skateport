--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/lifecycle.rs (коммит 2e16697)
--
-- Physical-player state changes recovered from TU3 `0x82DB8540`.
--
-- The selected state objects remain owned by `PhysicalPlayer`; changing state
-- selects one of those objects, rather than constructing a replacement.
-- ROBLOX: traits SkateboardControllerActions / PhysicalStateCalls -> таблицы
-- с методами (obj:method()). Result<_, UnknownPhysicalState> -> rt.raise.

local state = require("./state")

local S = state.PhysicalStateId

local lifecycle = {}

-- The state object selected from one of `PhysicalPlayer`'s owned pointers.
export type StateBinding = {
	state: number,
	owner_offset: number,
}

local StateBinding = {}
lifecycle.StateBinding = StateBinding

function StateBinding.new(st: number): StateBinding
	return { state = st, owner_offset = S.native_owner_offset(st) }
end

-- State-change fields owned directly by `PhysicalPlayer`.
export type PlayerStateChangeFields = {
	-- Player+1312. `SetPhysicsState` clears it before publishing state history.
	word_1312: number,
	-- Player+1336. Updated to the previous category only across a category edge.
	previous_category_latch_1336: number,
	-- Player+1344. `SetPhysicsState` clears it on every accepted transition.
	scalar_1344: number,
}

-- The exact `ProcessedPhysIn` fields read or written by `0x82DB8540`.
export type ProcessedStateChangeFields = {
	-- +2480; bits 7 and 8 choose free-board controller mode on off-board entry.
	flags_2480: number,
	-- +2500; requested state.
	requested_state_2500: number,
	-- +2504; type reported by the old state's vtable slot +28.
	previous_state_2504: number,
	-- +2508; current concrete state published before old-state Exit.
	current_state_2508: number,
	-- +2512; category of `current_state_2508`.
	current_category_2512: number,
	-- +2516; category of `previous_state_2504`.
	previous_category_2516: number,
	-- +2520; copy of Player+1336 after its conditional update.
	previous_category_latch_2520: number,
	-- +2564; reset before the old state's Exit call.
	word_2564: number,
	-- +2664; reset before the old state's Exit call.
	scalar_2664: number,
}

-- Fields at `PhysicalPlayer+1844`'s `SkateboardController`.
export type SkateboardControllerFields = {
	-- Controller+444. Its wider meaning is unresolved; every mode change here
	-- resets it with a 32-bit zero.
	word_444: number,
	-- Controller+448. Values used by this path are stopped=0, held=1, free=2.
	state_448: number,
	-- Controller+452, identified by `StopController` as the system-on byte.
	system_on_452: boolean,
}

-- Complete mutable data touched by the state-change function itself.
export type StateChangeData = {
	player: PlayerStateChangeFields,
	processed: ProcessedStateChangeFields,
	skateboard_controller: SkateboardControllerFields,
}

-- Board and drive operations called by the controller branch. Their complete
-- implementations are `HoldSkateboard` `0x82D75370` and
-- `LetGoOfSkateboard` `0x82D75440`; this lifecycle never replaces them.
export type SkateboardControllerActions = {
	hold_skateboard: (self: any) -> (),
	let_go_of_skateboard: (self: any) -> (),
}

-- Context supplied to an owned state's Enter or Exit implementation.
-- `active` makes the pointer-switch boundary observable without exposing a
-- native pointer in engine-independent code.
export type StateCall = {
	state: StateBinding,
	active: StateBinding,
}

-- Calls corresponding to the recovered state vtable slots used here.
export type PhysicalStateCalls = {
	-- Vtable +28 on the currently selected state.
	get_type: (self: any, st: StateBinding) -> number,
	-- Vtable +20 on the old state.
	exit: (self: any, call: StateCall) -> (),
	-- Vtable +16 on the newly selected state.
	enter: (self: any, call: StateCall) -> (),
}

export type PhysicalPlayerStateLifecycle = {
	active_binding: StateBinding,
}

local PhysicalPlayerStateLifecycle = {}
lifecycle.PhysicalPlayerStateLifecycle = PhysicalPlayerStateLifecycle

-- ROBLOX: приватное поле active -> active_binding (имя active занято методом).
function PhysicalPlayerStateLifecycle.new(initial_state: number): PhysicalPlayerStateLifecycle
	return { active_binding = StateBinding.new(initial_state) }
end

function PhysicalPlayerStateLifecycle.active(self: PhysicalPlayerStateLifecycle): StateBinding
	-- ROBLOX: Copy -> копия.
	return table.clone(self.active_binding)
end

-- `StopController` `0x82D75EA0`, called directly by `SetPhysicsState` for
-- every requested state outside 500..=502.
local function stop_skateboard_controller(controller: SkateboardControllerFields, actions: any)
	if not controller.system_on_452 then
		return
	end
	local previous_state = controller.state_448
	controller.word_444 = 0
	if previous_state ~= 0 then
		actions:let_go_of_skateboard()
		controller.state_448 = 0
	end
	controller.system_on_452 = false
end

local function prepare_skateboard_controller(
	requested: number,
	controller: SkateboardControllerFields,
	processed_flags_2480: number,
	actions: any
)
	if not (requested == S.BipedGround or requested == S.BipedAir or requested == S.OffBoardPushing) then
		stop_skateboard_controller(controller, actions)
		return
	end

	if controller.system_on_452 then
		return
	end

	controller.word_444 = 0
	if bit32.band(processed_flags_2480, bit32.bor(0x80, 0x100)) ~= 0 then
		if controller.state_448 ~= 2 then
			actions:let_go_of_skateboard()
			controller.state_448 = 2
		end
	elseif controller.state_448 ~= 1 then
		actions:hold_skateboard()
		controller.state_448 = 1
	end
	controller.system_on_452 = true
end

-- Port of `PhysicalPlayerHiLOD::SetPhysicsState` `0x82DB8540`.
--
-- Unknown numeric IDs are rejected before any callbacks or field writes.
-- The native default branches exit and re-enter the existing pointer for
-- such values, but no recovered caller contract establishes them as valid
-- states; making that case an error prevents a silent false transition.
function PhysicalPlayerStateLifecycle.set_physics_state(
	self: PhysicalPlayerStateLifecycle,
	requested_raw: number,
	data: StateChangeData,
	states: any,
	controller_actions: any
): StateBinding
	local requested = S.try_from(requested_raw)

	prepare_skateboard_controller(requested, data.skateboard_controller, data.processed.flags_2480, controller_actions)

	data.player.word_1312 = 0
	data.player.scalar_1344 = 0.0
	data.processed.scalar_2664 = 0.0
	data.processed.word_2564 = 0

	local previous = states:get_type(table.clone(self.active_binding))
	local previous_category = S.category(previous)
	local current_category = S.category(requested)
	data.processed.previous_state_2504 = previous
	data.processed.previous_category_2516 = previous_category
	data.processed.requested_state_2500 = requested
	data.processed.current_state_2508 = requested
	data.processed.current_category_2512 = current_category
	if current_category ~= previous_category then
		data.player.previous_category_latch_1336 = previous_category
	end
	data.processed.previous_category_latch_2520 = data.player.previous_category_latch_1336

	states:exit({ state = table.clone(self.active_binding), active = table.clone(self.active_binding) })
	self.active_binding = StateBinding.new(requested)
	states:enter({ state = table.clone(self.active_binding), active = table.clone(self.active_binding) })
	return table.clone(self.active_binding)
end

return lifecycle
