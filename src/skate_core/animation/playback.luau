--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/playback.rs (коммит 2e16697)
--
-- MotionGraph PlayAnimation ctor 82BB4B38, Begin 82BB5188, Update 82BB5670.
-- End is the verified no-op 82B61BB8; leaving a graph state does not stop a tree.

local rt = require("../../rt")
local name = require("./skeleton_input/name")
local playback_parameters = require("./playback_parameters")

local playback = {}

export type TransitionSettings = {
	-- 1 play, 2 blend, 3 channelblend, 4 sequence. Zero means no graph override.
	kind: number,
	seconds: number,
	under: number,
	-- 0 default, 1 current frame, 2 match phase, 3 match frame.
	matching: number,
	use_channels_from_weights: boolean,
}

export type PlayAnimation = {
	animation: string,
	switch_animation: string?,
	mirror_animation: string?,
	no_board_animation: string?,
	playback_speed: number,
	apply_posture: boolean,
	transition: TransitionSettings,
	parameters: { playback_parameters.PlaybackParameter },
}

export type PlaybackRequest = { animation: string, speed: number, start_time: number, transition: TransitionSettings }

-- Values published by the actual skater-animation/physical interfaces. The
-- no-board bit is PhysOut+72's byte 311, not a contact-derived guess.
export type PlaybackContext = {
	is_switch: boolean?,
	is_mirrored: boolean?,
	board_available: boolean?,
	pro_skater: { number },
	transition_override: TransitionSettings?,
}

-- ROBLOX: трейт PlaybackService: ParameterInputs + AttributeSink -> таблица методов:
-- motion_intent, filtered_intent, last_attribute, set_attribute,
-- set_construction_value(name, value), set_posture_enabled(enabled),
-- play(request) -> (bool) или (nil, ошибка). Return false only when the native
-- controller's Play/Blend/Sequence request fails. Unimplemented evaluation is an error, never false.

export type PlayAnimationInstance = { first_update: boolean }

local PlayAnimationInstance = {}
playback.PlayAnimationInstance = PlayAnimationInstance

function PlayAnimationInstance.default(): PlayAnimationInstance
	return { first_update = false }
end

local function refresh_parameters(parameters: { playback_parameters.PlaybackParameter }, beginning: boolean, service: any)
	-- Keep read/write effects interleaved across parameters while avoiding two
	-- mutable borrows of the same concrete animation service.
	for _, parameter in parameters do
		local one = { value = nil :: any }
		function one:set_attribute(v: any)
			self.value = v
		end
		playback_parameters.PlaybackParameter.update(parameter, beginning, service, one :: any)
		if one.value ~= nil then
			service:set_attribute(one.value)
		end
	end
end

local function play(service: any, request: PlaybackRequest): boolean
	local ok, err = service:play(request)
	if err ~= nil then
		rt.raise(err)
	end
	return ok :: boolean
end

-- ROBLOX: Result<(), String> -> rt.raise(строка).
function PlayAnimationInstance.begin(self: PlayAnimationInstance, operation: PlayAnimation, context: PlaybackContext, service: any)
	self.first_update = true
	refresh_parameters(operation.parameters, true, service)
	service:set_construction_value(name.encode("ProSkater"), context.pro_skater)
	-- The graph override is consumed/reset before variant choice or play.
	local override = context.transition_override
	context.transition_override = nil
	local transition = if override ~= nil and override.kind ~= 0 then override else operation.transition
	local animation = operation.animation
	if operation.switch_animation ~= nil then
		if context.is_switch == nil then
			rt.raise("PlayAnimation needs skater switch state")
		end
		if context.is_switch then
			animation = operation.switch_animation
		end
	end
	if operation.mirror_animation ~= nil then
		if context.is_mirrored == nil then
			rt.raise("PlayAnimation needs skater mirror state")
		end
		if context.is_mirrored then
			animation = operation.mirror_animation
		end
	end
	if operation.no_board_animation ~= nil then
		if context.board_available == nil then
			rt.raise("PlayAnimation needs PhysOut board availability")
		end
		if not context.board_available then
			animation = operation.no_board_animation
		end
	end
	service:set_posture_enabled(operation.apply_posture)
	local played = false
	if transition.kind >= 1 and transition.kind <= 4 then
		played = play(service, { animation = animation, speed = operation.playback_speed, start_time = 0.0, transition = transition })
	end
	if not played then
		-- This fallback is present in native Begin 82BB5630..5660. The
		-- service must not use it to conceal missing tree implementations.
		local fallback = table.clone(operation.transition)
		fallback.kind = 1
		play(service, { animation = "KeepDefaultAnim", speed = 1.0, start_time = 0.0, transition = fallback })
	end
end

function PlayAnimationInstance.update(self: PlayAnimationInstance, operation: PlayAnimation, service: any)
	if not self.first_update then
		refresh_parameters(operation.parameters, false, service)
	end
	self.first_update = false
end

PlayAnimationInstance["end"] = function(self: PlayAnimationInstance) end

return playback
