--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/gameplay_map.rs (коммит 2e16697)
--
-- Specialization of the 18 stock gameplay expressions registered by82697740.
-- Config identity and VM operand semantics are recorded in STEERING_INPUT.md.

local rt = require("../../rt")

local f32 = rt.f32
local from_bits = rt.from_bits

local gameplay_map = {}

-- One mapped gameplay action as the retail `input.cfg` registers it.
export type ActionInfo = {
	-- cInputMap index, the ID `sdk.input.override_action` takes.
	id: number,
	-- Retail `input.cfg` name.
	name: string,
	-- Retail expression over the 24 native pad slots.
	expression: string,
	-- Stable snake_case key for mods (`sdk.input.action_ids`).
	key: string,
	-- Value range the expression produces.
	range: { number },
}

local function action(id: number, name: string, expression: string, key: string, range: { number }): ActionInfo
	return { id = id, name = name, expression = expression, key = key, range = range }
end

local AXIS = { -1.0, 1.0 }
local UNIT = { 0.0, 1.0 }

-- The eighteen actions TU3 82697740 registers at 64..81, in index order.
-- Meanings (listener intents) are documented in `sdk/GENERAL_API.md` and
-- checked by `gameplay_map_tests.rs`.
gameplay_map.ACTIONS = {
	action(64, "GP_LStickX", "LStickR-LStickL", "left_stick_x", AXIS),
	action(65, "GP_LStickY", "LStickU-LStickD", "left_stick_y", AXIS),
	action(66, "GP_LStickIn", "LStick", "left_stick_click", UNIT),
	action(67, "GP_RStickX", "RStickR-RStickL", "right_stick_x", AXIS),
	action(68, "GP_RStickY", "RStickU-RStickD", "right_stick_y", AXIS),
	action(69, "GP_RStickIn", "RStick", "right_stick_click", UNIT),
	action(70, "GP_LTrigger", "LTrigger", "left_trigger", UNIT),
	action(71, "GP_RTrigger", "RTrigger", "right_trigger", UNIT),
	action(72, "GP_LBumper", "LBumper", "left_bumper", UNIT),
	action(73, "GP_RBumper", "RBumper", "right_bumper", UNIT),
	action(74, "GP_UDPad", "DPadU", "dpad_up", UNIT),
	action(75, "GP_DDPad", "DPadD", "dpad_down", UNIT),
	action(76, "GP_LDPad", "DPadL", "dpad_left", UNIT),
	action(77, "GP_RDPad", "DPadR", "dpad_right", UNIT),
	action(78, "GP_XFace", "X", "x", UNIT),
	action(79, "GP_YFace", "Y", "y", UNIT),
	action(80, "GP_AFace", "A", "a", UNIT),
	action(81, "GP_BFace", "B", "b", UNIT),
}

-- Looks an action up by its mod key (`"a"`, `"left_stick_x"`, ...).
function gameplay_map.action_by_key(key: string): ActionInfo?
	for _, a in gameplay_map.ACTIONS do
		if a.key == key then
			return a
		end
	end
	return nil
end

-- ROBLOX: values: [f32; 18] -> таблица, индексы с 1.
export type GameplayActions = { values: { number } }

local GameplayActions = {}
gameplay_map.GameplayActions = GameplayActions

function GameplayActions.from_values(values: { number }): GameplayActions
	assert(#values == 18)
	return { values = table.clone(values) }
end

function GameplayActions.values(self: GameplayActions): { number }
	return self.values
end

-- The native pad retains storage even while count is zero. With a nonzero
-- count, stock Button operands read their fixed index, without a per-index
-- count check; the caller must provide the native 24-button storage.
function GameplayActions.from_pad(p: any): GameplayActions
	local function value(slot: number): number
		if p.count == 0 then
			return 0.0
		end
		return from_bits(p.records[slot + 1][1])
	end
	return {
		values = {
			f32(value(16) - value(17)),
			f32(value(18) - value(19)),
			value(6),
			f32(value(20) - value(21)),
			f32(value(22) - value(23)),
			value(7),
			value(10),
			value(11),
			value(8),
			value(9),
			value(0),
			value(1),
			value(2),
			value(3),
			value(14),
			value(15),
			value(12),
			value(13),
		},
	}
end

-- impl ActionMap for GameplayActions
function GameplayActions.value(self: GameplayActions, a: number): number
	local index = a - 64
	assert(index >= 0, "gameplay action below 64")
	return self.values[index + 1]
end

function GameplayActions.state(self: GameplayActions, a: number): number
	return if GameplayActions.value(self, a) ~= 0.0 then 1 else 0
end

-- ROBLOX: ActionMap вызывается как map:value(..)/map:state(..) — метатаблица.
local actions_mt = { __index = GameplayActions }
function GameplayActions.as_map(self: GameplayActions): any
	return setmetatable(self :: any, actions_mt)
end

return gameplay_map
