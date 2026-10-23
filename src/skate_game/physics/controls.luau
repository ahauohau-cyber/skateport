--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/physics/controls.rs (коммит 2e16697)
--
-- Controller-derived state is evaluated on the same fixed gameplay tick.

local rt = require("../../rt")
local controller = require("../../skate_core/input/controller")
local riding_intentions = require("../../skate_core/input/riding_intentions")
local manual_intentions = require("../../skate_core/input/manual_intentions")
local gameplay_gestures = require("../../skate_core/input/gameplay_gestures")
local wipeout_intentions = require("../../skate_core/input/wipeout_intentions")
local anticipation_intentions = require("../../skate_core/input/anticipation_intentions")
local trick_intentions = require("../../skate_core/input/trick_intentions")
local intents_mod = require("../../skate_core/graph/intents")
local gameplay_map = require("../../skate_core/input/gameplay_map")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local Derived = controller.DerivedControllerInput
local IntentMap = intents_mod.IntentMap

local controls = {}

export type PlayerControls = {
	controller: controller.DerivedControllerInput,
	offboard_direction: { number }?,
	intents: { riding_intentions.RidingIntent },
	-- Named ActionGraph/gesture intents for the current tick (SDK / observation).
	-- ROBLOX: BTreeMap<String, f32> -> словарь (порядок ключей не используется).
	named_intents: { [string]: number },
	action_intents: intents_mod.IntentMap,
	ticks: number,
	actor_flags: number,
	bumper_state_502: boolean,
	bumper_state_104: boolean,
	preferences: riding_intentions.PushPreferences,
	-- One tick's native PlayerUI 82898D20 result, shared by animation and PhysIn.
	-- None means the native offboard remap gate did not run, not missing camera.
	offboard_axes: { number }?,
	-- TODO: GestureInput (input/gesture_input.rs) — нужны PAT-данные жестов.
	gestures: any?,
}

local PlayerControls = {}
controls.PlayerControls = PlayerControls

function PlayerControls.default(): PlayerControls
	local c = Derived.from_words(rt.zeros(26))
	Derived.initialize(c)
	return {
		controller = c,
		offboard_direction = nil,
		intents = {},
		named_intents = {},
		action_intents = IntentMap.new(),
		ticks = 0,
		actor_flags = 0,
		bumper_state_502 = false,
		bumper_state_104 = false,
		preferences = riding_intentions.default_push_preferences(),
		offboard_axes = nil,
		gestures = nil,
	}
end

-- Borrow the existing action packet; override only the native left-stick pair.
-- ROBLOX: struct SimulationActions<'a> -> таблица с методами value/state.
local SimulationActions = {}
SimulationActions.__index = SimulationActions
controls.SimulationActions = SimulationActions

function SimulationActions.new(source: controller.ActionMap, offboard_axes: { number }?): any
	return setmetatable({ source = source, offboard_axes = offboard_axes }, SimulationActions)
end

function SimulationActions.value(self: any, action: number): number
	local axes = self.offboard_axes
	if axes ~= nil then
		if action == 64 then
			return axes[1]
		elseif action == 65 then
			return axes[2]
		end
	end
	return self.source:value(action)
end

function SimulationActions.state(self: any, action: number): number
	if self.offboard_axes ~= nil and (action == 64 or action == 65) then
		return if SimulationActions.value(self, action) ~= 0.0 then 1 else 0
	end
	return self.source:state(action)
end

local function cross_camera_axis(a: { number }, b: { number }): { number }
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
	}
end

local function normalize_camera_axis(v: { number }): { number }
	local squared = f32(f32(f32(v[1] * v[1]) + f32(v[2] * v[2])) + f32(v[3] * v[3]))
	-- Independent PC rsqrt seed, retaining both native refinement iterations.
	-- No fitted epsilon/fallback and no claim of bit-exact Xenon emulation.
	-- ROBLOX: squared.sqrt().recip() -> f32(1 / f32(sqrt)).
	local inverse = f32(1.0 / f32(math.sqrt(squared)))
	for _ = 1, 2 do
		local correction = mul_add(-squared, f32(inverse * inverse), 1.0)
		inverse = mul_add(f32(inverse * 0.5), correction, inverse)
	end
	return { f32(v[1] * inverse), f32(v[2] * inverse), f32(v[3] * inverse) }
end

local POLE = from_bits(0x3f7d70a4)

-- Complete numerical remap 82898D20; camera is the native XYZ presentation
-- basis, before Bevy's presentation-only two-axis sign conversion.
-- ROBLOX: camera: [[f32; 3]; 3] -> { right, up, forward } (столбцы базиса).
function controls.camera_relative_axes(stick: { number }, camera: { { number } }): { number }
	local right, up, forward = camera[1], camera[2], camera[3]
	-- 82898D98..DB4: ABS(dot(world_up, camera_Z)) < literal 820ED5E8.
	-- Near either vertical pole, native retains ALL original camera axes.
	if math.abs(forward[2]) < POLE then
		right = normalize_camera_axis(cross_camera_axis({ 0.0, 1.0, 0.0 }, forward))
		forward = normalize_camera_axis(cross_camera_axis(right, { 0.0, 1.0, 0.0 }))
		up = normalize_camera_axis(cross_camera_axis(forward, right))
	end
	-- CacheLine includes its count at 0. 82898EE0..F0C reads Buttons 17-16
	-- and Buttons 18-19: [-LeftAnalogStickLR, 0, LeftAnalogStickUD].
	local localv = { -stick[1], 0.0, stick[2] }
	local world = {}
	for i = 1, 3 do
		world[i] = mul_add(forward[i], localv[3], mul_add(up[i], localv[2], f32(right[i] * localv[1])))
	end
	-- 82898F44..FAC splits world X/Z into positive/negative pad channels;
	-- stock actions 64/65 subtract those channels again. Keep that ordering.
	local negative_x = if world[1] >= 0.0 then 0.0 else -world[1]
	local positive_x = if world[1] > 0.0 then world[1] else 0.0
	local negative_z = if world[3] >= 0.0 then 0.0 else -world[3]
	local positive_z = if world[3] <= 0.0 then 0.0 else world[3]
	return { f32(positive_x - negative_x), f32(positive_z - negative_z) }
end

-- ROBLOX: система sample (Bevy) -> функция; ресурсы передаёт хост.
-- input: PublishedTickInput; physics/skater/camera — таблицы с теми же полями.
function controls.sample(input: any, physics: any, skater: any, camera: any, player: PlayerControls)
	-- ROBLOX: input.0.actions() — копия GameplayActions, как ActionMap.
	local map = gameplay_map.GameplayActions.as_map(gameplay_map.GameplayActions.from_values(input.value.actions.values))
	local ok, err = pcall(PlayerControls.update_for_physics, player, map, physics, skater, camera)
	if not ok then
		error("Offboard controller publication: " .. tostring(err))
	end
	PlayerControls.publish_gestures(player, physics.animation_profile.physics_mode, skater.player_input.physical.state.state_16)
end

-- PlayerUI 82898920 transforms the gameplay packet before Raw/Derived input.
-- Only its offboard branch is enabled here; onboard behavior is unchanged.
-- ROBLOX: Result<(), String> -> ошибка через rt.raise.
function PlayerControls.update_for_physics(self: PlayerControls, map: controller.ActionMap, physics: any, skater: any, camera: any)
	local physical = skater.player_input.physical
	-- 82DB7678/7694 writes category and State75 from the same category==500.
	-- 82898B80..BC4 excludes grabbing an object (304) and state 503.
	local remap = physical.state.category_12 == 500 and physical.off_board.flag_304 == 0 and physical.state.state_16 ~= 503
	local axes = nil
	if remap then
		local frame = camera.frame
		if frame == nil then
			rt.raise("Native offboard input requires a completed presentation camera frame")
		end
		axes = controls.camera_relative_axes({ map:value(64), map:value(65) }, frame.basis.columns)
	end
	PlayerControls.update(self, SimulationActions.new(map, axes), physics.settings.step.simulation.time_step, physics.settings.input_magnitude_threshold, physical.scoring.capabilities_204)
	self.offboard_axes = axes
	self.offboard_direction = if axes then { axes[1], 0.0, axes[2], 0.0 } else nil
end

-- Parent must pass this SAME sampled mapping into input_phase::advance.
-- Do not rotate again: the camera/state may have advanced since sampling.
function PlayerControls.simulation_actions(self: PlayerControls, source: controller.ActionMap): any
	return SimulationActions.new(source, if self.offboard_axes then table.clone(self.offboard_axes) else nil)
end

-- TODO: PlayerControls::load читает GestureInput с диска игры (этап жестов).

function PlayerControls.publish_gestures(self: PlayerControls, difficulty: number, physical_state: number)
	local gestures = self.gestures
	if gestures ~= nil then
		local words = self.controller.words
		local axes = { { from_bits(words[8]), from_bits(words[9]) }, { from_bits(words[10]), from_bits(words[11]) } }
		for _, pair in gestures:publish(axes, difficulty, self.actor_flags, physical_state, self.action_intents) do
			if math.abs(pair[2]) > 0.01 then
				self.named_intents[pair[1]] = pair[2]
			end
		end
	end
end

function PlayerControls.update(self: PlayerControls, map: controller.ActionMap, dt: number, magnitude_threshold: number, physical_capabilities: number)
	self.offboard_axes = nil
	Derived.update(self.controller, map, dt, self.bumper_state_502, self.bumper_state_104, {
		attribute = magnitude_threshold,
		-- The validated field is present, so no engine missing-field path runs.
		missing_attribute_value = 0.0,
	})
	local list = riding_intentions.produce(self.controller, self.actor_flags, self.preferences)
	for _, i in manual_intentions.produce(self.controller, self.actor_flags) do
		table.insert(list, i)
	end
	for _, i in gameplay_gestures.produce(self.controller) do
		table.insert(list, i)
	end
	for _, i in wipeout_intentions.produce(self.controller, self.actor_flags, physical_capabilities) do
		-- PC bail steering convention: reverse horizontal control at the
		-- intent boundary, before both the graph and SDK publication.
		-- The recovered Skate 3 producer/torque kernels retain their signs.
		if i.name == "WipeoutControlX" then
			i.value = -i.value
		end
		table.insert(list, i)
	end
	for _, i in anticipation_intentions.produce(self.controller) do
		table.insert(list, i)
	end
	for _, i in trick_intentions.produce(self.controller) do
		table.insert(list, { name = i.name, value = i.value })
	end
	self.intents = list
	-- GenerateActionGraphIntents 82594310 clears the AG map through 82BC1B68
	-- before Listener::Fill. MG lifecycle intents use a different persistent map.
	IntentMap.clear(self.action_intents)
	table.clear(self.named_intents)
	for _, intent in self.intents do
		IntentMap.insert(self.action_intents, intent.name, intent.value)
		if math.abs(intent.value) > 0.01 then
			self.named_intents[intent.name] = intent.value
		end
	end
	self.ticks += 1
end

return controls
