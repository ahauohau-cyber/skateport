--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/playback_tree.rs (коммит 2e16697)
--
-- Owned animation tree evaluation; stock data constructs this topology.
--
-- ROBLOX: enum PlaybackTree -> таблицы с полем kind:
--   { kind = "Clip", name = string, clip = PlaybackClip }
--   { kind = "PhaseBlend", value = PhaseBlend }
--   { kind = "BlendSpace", value = BlendSpace }
--   { kind = "SelectionSpace", value = SelectionSpace }
--   { kind = "Transition", value = PlaybackTransition }
--   { kind = "BindPose", motion, posture?, board_backwards, mirror_modes, attribute_mirror }
--     (SkaterAnim::AddBindPose 82B98118, latched when a named tree is created).
-- enum PoseCommand -> { kind = "Clip" | "Blend" | "WeightedBlend" | "ChannelBlend"
--   | "Pose" | "Add" | "Mirror", поля варианта }.
-- Модули узлов (phase_blend, blend_space, selection_space, playback_transition)
-- получают методы дерева через поле .tree — цикл require в Luau запрещён.

local rt = require("../../rt")
local attributes = require("./output/attributes")
local clip_clock = require("./clip_clock")
local playback_clip = require("./playback_clip")
local playback_attributes = require("./playback_attributes")
local phase_blend = require("./phase_blend")
local posture = require("./posture")
local selection_space = require("@self/selection_space")
local blend_space = require("@self/blend_space")
local playback_transition = require("./playback_transition")

local f32 = rt.f32

local playback_tree = {}
playback_tree.selection_space = selection_space
playback_tree.blend_space = blend_space

export type PlaybackTree = { kind: string, [string]: any }
export type PoseCommand = { kind: string, [string]: any }
export type Evaluation = { cull_threshold: number, update_history: boolean }

local PhaseBlend = phase_blend.PhaseBlend
local BlendSpace = blend_space.BlendSpace
local SelectionSpace = selection_space.SelectionSpace
local PlaybackTransition = playback_transition.PlaybackTransition
local ClipClock = clip_clock.ClipClock
local PlaybackClip = playback_clip.PlaybackClip

local PlaybackTree = {}
playback_tree.PlaybackTree = PlaybackTree

function PlaybackTree.length(self: PlaybackTree): number
	local k = self.kind
	if k == "Clip" then
		return self.clip.clock.length
	elseif k == "PhaseBlend" then
		return self.value.length
	elseif k == "BlendSpace" then
		return BlendSpace.length(self.value)
	elseif k == "SelectionSpace" then
		local c = SelectionSpace.current(self.value)
		return if c ~= nil then PlaybackTree.length(c) else 0.0
	elseif k == "Transition" then
		return PlaybackTree.length(self.value.to)
	end
	return PlaybackTree.length(self.motion)
end

function PlaybackTree.time(self: PlaybackTree): number
	local k = self.kind
	if k == "Clip" then
		return ClipClock.sample_time(self.clip.clock)
	elseif k == "PhaseBlend" or k == "BlendSpace" then
		return self.value.time
	elseif k == "SelectionSpace" then
		local c = SelectionSpace.current(self.value)
		return if c ~= nil then PlaybackTree.time(c) else 0.0
	elseif k == "Transition" then
		return PlaybackTree.time(self.value.to)
	end
	return PlaybackTree.time(self.motion)
end

function PlaybackTree.set_time(self: PlaybackTree, time: number)
	local k = self.kind
	if k == "Clip" then
		ClipClock.set_time(self.clip.clock, time)
	elseif k == "PhaseBlend" then
		PhaseBlend.set_time(self.value, time)
	elseif k == "BlendSpace" then
		BlendSpace.set_time(self.value, time)
	elseif k == "SelectionSpace" then
		SelectionSpace.set_time(self.value, time)
	elseif k == "Transition" then
		PlaybackTree.set_time(self.value.to, time)
	else
		PlaybackTree.set_time(self.motion, time)
	end
end

function PlaybackTree.set_speed(self: PlaybackTree, speed: number)
	local k = self.kind
	if k == "Clip" then
		ClipClock.set_speed(self.clip.clock, speed)
	elseif k == "PhaseBlend" then
		PhaseBlend.set_speed(self.value, speed)
	elseif k == "BlendSpace" then
		BlendSpace.set_speed(self.value, speed)
	elseif k == "SelectionSpace" then
		SelectionSpace.set_speed(self.value, speed)
	elseif k == "Transition" then
		PlaybackTree.set_speed(self.value.to, speed)
	else
		PlaybackTree.set_speed(self.motion, speed)
	end
end

function PlaybackTree.advance(self: PlaybackTree, dt: number, phase: number, property: clip_clock.AdvanceResult)
	local k = self.kind
	if k == "Clip" then
		ClipClock.advance(self.clip.clock, dt, phase, property)
	elseif k == "PhaseBlend" then
		PhaseBlend.advance(self.value, dt, phase, property)
	elseif k == "BlendSpace" then
		BlendSpace.advance(self.value, dt, phase, property)
	elseif k == "SelectionSpace" then
		local c = SelectionSpace.current(self.value)
		if c ~= nil then
			PlaybackTree.advance(c, dt, phase, property)
		end
	elseif k == "Transition" then
		PlaybackTransition.advance(self.value, dt, phase, property)
	else
		PlaybackTree.advance(self.motion, dt, phase, property)
	end
end

-- ROBLOX: Result<bool, String> -> bool или rt.raise.
function PlaybackTree.set_attributes(self: PlaybackTree, attrs: { any }): boolean
	local k = self.kind
	if k == "Clip" then
		return false
	elseif k == "PhaseBlend" then
		return PhaseBlend.set_attributes(self.value, attrs)
	elseif k == "BlendSpace" then
		return BlendSpace.set_attributes(self.value, attrs)
	elseif k == "SelectionSpace" then
		return SelectionSpace.set_attributes(self.value, attrs)
	elseif k == "Transition" then
		return PlaybackTransition.set_attributes(self.value, attrs)
	end
	return PlaybackTree.set_attributes(self.motion, attrs)
end

function PlaybackTree.attributes(self: PlaybackTree, mask: number): { attributes.AnimationAttribute }
	local k = self.kind
	if k == "Clip" then
		return PlaybackClip.attributes(self.clip, mask)
	elseif k == "PhaseBlend" then
		return PhaseBlend.attributes(self.value, mask)
	elseif k == "BlendSpace" then
		return BlendSpace.attributes(self.value, mask)
	elseif k == "SelectionSpace" then
		local c = SelectionSpace.current(self.value)
		if c == nil then
			rt.raise("SelectionSpace attributes requested before native selection")
		end
		return PlaybackTree.attributes(c, mask)
	elseif k == "Transition" then
		return PlaybackTransition.attributes(self.value, mask)
	end
	local out = PlaybackTree.attributes(self.motion, mask)
	for _ in self.mirror_modes do
		for _, attribute in out do
			playback_attributes.AttributeMirror.apply(self.attribute_mirror, attribute)
		end
	end
	return out
end

function PlaybackTree.query_attribute(self: PlaybackTree, name: attributes.AttributeName, mask: number, output: attributes.AnimationAttribute): boolean
	local k = self.kind
	if k == "PhaseBlend" then
		return PhaseBlend.query_attribute(self.value, name, mask, output)
	elseif k == "BlendSpace" then
		return BlendSpace.query_attribute(self.value, name, mask, output)
	elseif k == "SelectionSpace" then
		local c = SelectionSpace.current(self.value)
		if c == nil then
			rt.raise("SelectionSpace attribute requested before native selection")
		end
		return PlaybackTree.query_attribute(c, name, mask, output)
	elseif k == "Transition" then
		return PlaybackTransition.query_attribute(self.value, name, mask, output)
	elseif k == "BindPose" then
		-- 825476D0 leaves a child's partial output untouched on false.
		local found = PlaybackTree.query_attribute(self.motion, name, mask, output)
		if found then
			for _ in self.mirror_modes do
				playback_attributes.AttributeMirror.apply(self.attribute_mirror, output)
			end
		end
		return found
	end
	local attribute = PlaybackClip.attribute(self.clip, name, mask)
	if attribute ~= nil then
		attributes.AnimationAttribute.copy_from(output, attribute)
		return true
	end
	return false
end

function PlaybackTree.attribute(self: PlaybackTree, name: attributes.AttributeName, mask: number): attributes.AnimationAttribute?
	local output = attributes.MotionGraphAttribute.to_animation({ name = name, value = 0.0 })
	return if PlaybackTree.query_attribute(self, name, mask, output) then output else nil
end

function PlaybackTree.evaluate(self: PlaybackTree, parameters: Evaluation, enabled: boolean, output: { any }): boolean
	local k = self.kind
	if k == "PhaseBlend" then
		return PhaseBlend.evaluate(self.value, parameters, enabled, output)
	elseif k == "BlendSpace" then
		return BlendSpace.evaluate(self.value, parameters, enabled, output)
	elseif k == "SelectionSpace" then
		if not enabled then
			return false
		end
		local c = SelectionSpace.current(self.value)
		if c == nil then
			rt.raise("SelectionSpace evaluated before native selection")
		end
		return PlaybackTree.evaluate(c, parameters, true, output)
	elseif k == "Transition" then
		return PlaybackTransition.evaluate(self.value, parameters, enabled, output)
	elseif k == "BindPose" then
		local produced = PlaybackTree.evaluate(self.motion, parameters, enabled, output)
		if produced then
			if self.posture ~= nil then
				table.insert(output, { kind = "Pose", name = posture.PosturePose.name(self.posture) })
				table.insert(output, { kind = "Add", motion_is_a = true })
			end
			table.insert(output, { kind = "Pose", name = "RIG_TPOSE" })
			table.insert(output, { kind = "Add", motion_is_a = true })
			if self.board_backwards then
				table.insert(output, { kind = "Pose", name = "BOARD_BACKWARDS" })
				table.insert(output, { kind = "Add", motion_is_a = false })
				table.insert(output, { kind = "Pose", name = "BOARD_BACKWARDS_IK" })
				table.insert(output, { kind = "Add", motion_is_a = true })
			end
			for _, trajectory_mode in self.mirror_modes do
				table.insert(output, { kind = "Mirror", trajectory_mode = trajectory_mode })
			end
		end
		return produced
	end
	-- Clip
	local clock = self.clip.clock
	local rate = f32(clock.base_speed * clock.speed)
	local limit = f32(f32(clock.frames - 1.0) / clock.fps)
	local function bound(time: number): number
		local lower = if -time >= 0.0 then 0.0 else time
		return if f32(limit - lower) >= 0.0 then lower else limit
	end
	local previous_time = bound(f32(clock.previous_time * rate))
	local time = bound(f32(ClipClock.sample_time(clock) * rate))
	if clock.loops_since_evaluation == 0 and previous_time > time then
		previous_time = time
	end
	if enabled then
		table.insert(output, { kind = "Clip", name = self.name, previous_time = previous_time, time = time, loops = clock.loops_since_evaluation })
	end
	if parameters.update_history then
		ClipClock.commit_evaluation(clock)
	end
	return enabled
end

-- ROBLOX: замыкаем ссылки узлов на методы дерева (см. шапку).
phase_blend.tree = PlaybackTree
selection_space.tree = PlaybackTree
blend_space.tree = PlaybackTree
playback_transition.tree = PlaybackTree

return playback_tree
