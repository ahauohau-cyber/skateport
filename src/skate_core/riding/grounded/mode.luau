--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/mode.rs (коммит 2e16697)
--
-- Mode binding producer, TU3 ProcessInput 82DB4420..447C.
-- Numeric mode identities are preserved without assigning guessed names.

local mode = {}

-- The two fields are deliberately separate: an unsupported request is still
-- published, while the previously selected attribute binding remains active.
export type ProcessedMode = {
	-- ProcessedPhysIn+2528, copied from skeleton+10928 on every update.
	requested_mode: number,
	-- ProcessedPhysIn+2548. Supply actual resource bindings, not host addresses.
	selected_attributes: any,
}

local ProcessedMode = {}
mode.ProcessedMode = ProcessedMode

-- `attributes` correspond in order to player+1408/1424/1440/1456/1472.
-- Their constructor/asset loading is a separate dependency. There is no
-- guessed initial binding and no default-mode fallback for invalid input.
-- ROBLOX: attributes — таблица из 5, индексы с 1; requested_mode с нуля, как в Rust.
function ProcessedMode.update(self: ProcessedMode, requested_mode: number, attributes: { any })
	if requested_mode <= 4 then
		self.selected_attributes = attributes[requested_mode + 1]
	end
	self.requested_mode = requested_mode
end

return mode
