--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/input.rs (коммит 2e16697)
--
-- Platform input adapter; no animation or physics state mutation here.
--
-- ROBLOX: InputPlugin (Bevy) не переносится. Системы стали функциями, их
-- вызывает хост (roblox/…) в том же порядке: poll_controllers каждый кадр,
-- publish_actions на каждом фиксированном тике перед симуляцией.
-- ROBLOX: start_controllers (settings/controller.json, падлы, модели SDL) и
-- controller_kind/platform не переносятся: устройство в Roblox одно —
-- клавиатура и мышь, их переводит в XboxState модуль roblox/keyboard_pad.
-- TODO: gesture_catalog, gesture_mapping(_data), gesture_input — читают PAT-
-- данные игры; переносятся вместе со стоковыми данными жестов.

local controllers = require("@self/controllers")
local gameplay_map = require("../skate_core/input/gameplay_map")
local tick_mod = require("../skate_core/input/tick")

local input = {}

input.controllers = controllers
input.ControllerInput = controllers.ControllerInput

-- ROBLOX: Resource PublishedTickInput(pub TickInput) -> таблица { value = TickInput }.
export type PublishedTickInput = { value: tick_mod.TickInput }

function input.published_default(): PublishedTickInput
	return { value = tick_mod.TickInput.new(0, gameplay_map.GameplayActions.from_values(table.create(18, 0.0)), false) }
end

-- ROBLOX: poll_controllers. Сетевой фильтр (multiplayer) и опрос platform
-- заменены готовыми сэмплами от хоста; info!/warn! -> print (warn есть только в Roblox, тесты идут в CLI).
function input.poll_controllers(state: controllers.ControllerInput, samples: { controllers.Sample })
	local previous = table.clone(state.status)
	controllers.ControllerInput.collect(state, samples)
	for index, before in previous do
		local after = state.status[index]
		local changed = before.kind ~= after.kind or (before.error and before.error.kind) ~= (after.error and after.error.kind)
		if changed then
			if after.kind == "Ready" then
				print(string.format("[skateport] Controller %d: ready", index - 1))
			elseif after.kind == "Unavailable" and after.error and after.error.kind == "Disconnected" then
				print(string.format("[skateport] Controller %d: disconnected", index - 1))
			else
				print(string.format("[skateport] WARN Controller %d: %s", index - 1, after.kind))
			end
		end
	end
end

-- ROBLOX: Res<Menu>/DebugCam/CameraRuntime -> флаги blocked и suppress
-- (меню и отладочной камеры в порте нет — хост передаёт false).
-- TODO: modding::override_actions — моды в порт не входят.
function input.publish_actions(state: controllers.ControllerInput, published: PublishedTickInput, blocked: boolean, suppress: boolean)
	if blocked then
		controllers.ControllerInput.discard_gameplay(state)
	end
	controllers.ControllerInput.publish_actions(state)
	local t = controllers.ControllerInput.tick_input(state)
	local values = table.clone(t.actions.values)
	local tick = tick_mod.TickInput.new(t.tick, gameplay_map.GameplayActions.from_values(values), t.controller_available)
	if suppress then
		published.value = tick_mod.TickInput.new(tick.tick, gameplay_map.GameplayActions.from_values(table.create(18, 0.0)), tick.controller_available)
	else
		published.value = tick
	end
end

return input
