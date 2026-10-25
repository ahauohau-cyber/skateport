--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/logic.rs (коммит 2e16697)
--
-- TU3 PhysicalPlayer Logic phase (`0x82DB5FA8`).
-- ROBLOX: Result<LogicResult, UnknownPhysicalState> -> возврат или rt.raise
-- (ошибка приходит из lifecycle.set_physics_state).

local lifecycle = require("./lifecycle")
local selector = require("./selector")

local logic = {}

-- Player+1876 staging data cleared at the end of every Logic phase.
export type PhysicsOutputStaging = {
	-- Bytes +20 through +53.
	bytes_20_through_53: { number },
	-- Floats +56 through +188.
	scalars_56_through_188: { number },
	-- Word +200.
	word_200: number,
}

local PhysicsOutputStaging = {}
logic.PhysicsOutputStaging = PhysicsOutputStaging

function PhysicsOutputStaging.clear_like_82db6000(self: PhysicsOutputStaging)
	self.word_200 = 0
	table.clear(self.bytes_20_through_53)
	for i = 1, 34 do
		self.bytes_20_through_53[i] = 0
	end
	table.clear(self.scalars_56_through_188)
	for i = 1, 34 do
		self.scalars_56_through_188[i] = 0.0
	end
end

export type LogicResult = {
	previous: lifecycle.StateBinding,
	selected: lifecycle.StateBinding,
	changed: boolean,
}

-- State owned by the exact transition portion of PhysicalPlayer's Logic phase.
export type PhysicalPlayerLogic = {
	selector: selector.StateSelector,
	lifecycle: lifecycle.PhysicalPlayerStateLifecycle,
	-- PhysicalPlayer+1304; native writes 100 only when the concrete state changes.
	frames_since_jump_1304: number,
}

local PhysicalPlayerLogic = {}
logic.PhysicalPlayerLogic = PhysicalPlayerLogic

function PhysicalPlayerLogic.new(initial_state: number): PhysicalPlayerLogic
	return {
		selector = selector.StateSelector.default(),
		lifecycle = lifecycle.PhysicalPlayerStateLifecycle.new(initial_state),
		frames_since_jump_1304 = 0,
	}
end

-- Calls current-state GetType, calculates the suggested state, performs
-- SetPhysicsState only on an edge, then clears the output staging block.
function PhysicalPlayerLogic.run(
	self: PhysicalPlayerLogic,
	selection_input: selector.StateSelectionInput,
	state_change_data: lifecycle.StateChangeData,
	output_staging: PhysicsOutputStaging,
	states: any,
	controller_actions: any
): LogicResult
	local previous = lifecycle.PhysicalPlayerStateLifecycle.active(self.lifecycle)
	local previous_type = states:get_type(previous)
	local suggested = selector.StateSelector.calculate(self.selector, previous_type, selection_input)
	local changed = suggested ~= previous_type
	local selected
	if changed then
		self.frames_since_jump_1304 = 100
		selected = lifecycle.PhysicalPlayerStateLifecycle.set_physics_state(
			self.lifecycle,
			suggested,
			state_change_data,
			states,
			controller_actions
		)
	else
		selected = previous
	end
	PhysicsOutputStaging.clear_like_82db6000(output_staging)
	return { previous = previous, selected = selected, changed = changed }
end

return logic
