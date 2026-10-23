--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/tick.rs (коммит 2e16697)
--
-- Immutable fixed-tick input boundary.
--
-- The platform adapter owns device polling. Once a `TickInput` exists, all
-- simulation phases consume this value; they do not access a platform device,
-- pad history, or rebuild the gameplay map.

local gameplay_map = require("./gameplay_map")

local tick = {}

export type TickInput = { tick: number, actions: gameplay_map.GameplayActions, controller_available: boolean }

local TickInput = {}
tick.TickInput = TickInput

function TickInput.new(t: number, actions: gameplay_map.GameplayActions, controller_available: boolean): TickInput
	return table.freeze({ tick = t, actions = actions, controller_available = controller_available }) :: any
end

function TickInput.tick(self: TickInput): number
	return self.tick
end
function TickInput.actions(self: TickInput): gameplay_map.GameplayActions
	return self.actions
end
function TickInput.controller_available(self: TickInput): boolean
	return self.controller_available
end

return tick
