--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/selector.rs (коммит 2e16697)
--
-- Original selector Launch82D67848 and Update82D68800 with typed batch ownership.
-- ROBLOX: методы -> TrajectorySelector.fn(self, ...); Option -> значение или nil;
-- Result<_, String> -> rt.raise(строка); индексы кандидатов с нуля, как в Rust.

local rt = require("../../../rt")
local m = require("./math")
local types = require("./types")
local prediction = require("./prediction")
local launch = require("./launch")
local scoring = require("./scoring")
local grind = require("./grind")
local query = require("./query")
local point_graph = require("../../point_graph")

local f32 = rt.f32
local dot, sub, add, scale = m.dot, m.sub, m.add, m.scale
local angle_between = m.angle_between
local evaluate = point_graph.PointGraph.evaluate
local QueryResult = prediction.QueryResult
local QueryRequest = prediction.QueryRequest
local Trajectory = prediction.Trajectory
local Candidate = scoring.Candidate
local LaunchInfo = types.LaunchInfo

type Vector = m.Vector
type SelectorInput = types.SelectorInput
type SelectorSettings = types.SelectorSettings
type Prediction = prediction.Prediction
type Trajectory = prediction.Trajectory
type QueryRequest = prediction.QueryRequest
type QueryResult = prediction.QueryResult

local selector = {}

-- The current authored world contains collision triangles and no grind edges.
-- Pass this only after querying that actual world's topology. It is not a
-- replacement for a grind result when a world contains grind primitives.
-- ROBLOX: unit struct -> пустая таблица-маркер.
selector.WorldWithoutGrindEdges = table.freeze({})

export type Selection = {
	candidate_index: number, -- 9636
	prediction: Prediction, -- owning copy at1696, pointer1680
	start_velocity: Vector, -- 2640
	landing_normal: Vector, -- 2656
	collision_velocity: Vector, -- 2672
	collision_position: Vector, -- 2688
	com_trajectory: Trajectory, -- 2704
	surface_category: number, -- 9640
	wall_ride: boolean, -- 9661
	grind: grind.GrindTarget?,
}

export type TrajectorySelector = {
	launch_info: types.LaunchInfo?,
	batch: launch.LaunchBatch?,
	candidates: { scoring.Candidate },
	selection: Selection?,
	selected_index: number?,
	grind_locked_to_middle: boolean, -- 9653
	grind_normal: Vector?, -- 9656/2896
	pass: number, -- 9632
	adjusted_on_vert: boolean, -- 9651
	pending: boolean, -- 9657
	valid: boolean, -- 9658
	just_changed: boolean, -- 9660
	all_predictions_missed: boolean, -- 9662
	suggested_normal: Vector?, -- 9655/2880
}

local TrajectorySelector = {}
selector.TrajectorySelector = TrajectorySelector

-- ROBLOX: #[derive(Default)].
function TrajectorySelector.default(): TrajectorySelector
	return {
		launch_info = nil,
		batch = nil,
		candidates = {},
		selection = nil,
		selected_index = nil,
		grind_locked_to_middle = false,
		grind_normal = nil,
		pass = 0,
		adjusted_on_vert = false,
		pending = false,
		valid = false,
		just_changed = false,
		all_predictions_missed = false,
		suggested_normal = nil,
	}
end
function TrajectorySelector.new(): TrajectorySelector
	return TrajectorySelector.default()
end
function TrajectorySelector.pending(self: TrajectorySelector): boolean
	return self.pending
end
function TrajectorySelector.valid(self: TrajectorySelector): boolean
	return self.valid
end
function TrajectorySelector.just_changed(self: TrajectorySelector): boolean
	return self.just_changed
end
function TrajectorySelector.all_predictions_missed(self: TrajectorySelector): boolean
	return self.all_predictions_missed
end
function TrajectorySelector.suggested_normal(self: TrajectorySelector): Vector?
	return self.suggested_normal
end
function TrajectorySelector.selection(self: TrajectorySelector): Selection?
	return self.selection
end
function TrajectorySelector.selected_index(self: TrajectorySelector): number?
	return self.selected_index
end
function TrajectorySelector.grind_locked_to_middle(self: TrajectorySelector): boolean
	return self.grind_locked_to_middle
end
function TrajectorySelector.grind_normal(self: TrajectorySelector): Vector?
	return self.grind_normal
end
function TrajectorySelector.launch_info(self: TrajectorySelector): types.LaunchInfo?
	return self.launch_info
end
function TrajectorySelector.requests(self: TrajectorySelector): { QueryRequest }
	local batch = self.batch
	return if batch then batch.requests else {}
end
function TrajectorySelector.com_displacement(self: TrajectorySelector): Vector?
	local batch = self.batch
	return if batch then batch.com_displacement else nil
end
function TrajectorySelector.local_com_position(self: TrajectorySelector): Vector?
	local batch = self.batch
	return if batch then batch.local_com_position else nil
end
function TrajectorySelector.local_board_position(self: TrajectorySelector): Vector?
	local batch = self.batch
	return if batch then batch.local_board_position else nil
end
function TrajectorySelector.board_position(self: TrajectorySelector): Vector?
	local batch = self.batch
	return if batch then batch.board_position else nil
end
function TrajectorySelector.query_origin(self: TrajectorySelector): Vector?
	local batch = self.batch
	return if batch then batch.origin else nil
end
-- Update82D68800 always clears9660 even if no batch is ready.
function TrajectorySelector.update_without_completion(self: TrajectorySelector): boolean
	self.just_changed = false
	return self.valid
end
-- Ground's explicit cancellation writes9657 only; cached observations stay.
function TrajectorySelector.cancel_pending(self: TrajectorySelector)
	self.pending = false
end

local function empty_trajectory(): Trajectory
	return { position = m.zero(), velocity = m.zero(), acceleration = m.zero(), duration = -1.0 }
end

-- Reset82D67228 invalidates landing observations, while retaining the
-- in-flight request9657, winning result1680 and selected index9636.
function TrajectorySelector.reset(self: TrajectorySelector)
	self.valid = false
	self.suggested_normal = nil
	self.grind_normal = nil
	self.just_changed = false
	self.all_predictions_missed = false
	self.pass = 0
	self.grind_locked_to_middle = false
	local selection = self.selection
	if selection then
		selection.com_trajectory = empty_trajectory()
	end
	-- The reset's remaining slots are not represented by this selector's
	-- player-owned, triangle-world observations.
end

local function launch_pass(self: TrajectorySelector, input: SelectorInput, s: SelectorSettings)
	local info = self.launch_info
	assert(info, "Launch owns the packet before its batch")
	self.all_predictions_missed = false
	local sel = self.selection
	if sel then
		sel.wall_ride = false
	end
	local batch = launch.batch(info, input, s)
	-- Only velocities are written by InitTrajectoryInfo. Retain the other
	-- candidate fields across passes until scoring writes a valid result.
	local target = math.max(#self.candidates, #batch.requests)
	while #self.candidates < target do
		table.insert(self.candidates, {
			prediction = {
				request = QueryRequest.clone(batch.requests[1]),
				result = QueryResult.miss(),
			},
			start_velocity = m.zero(),
			normal = m.zero(),
			collision_velocity = m.zero(),
			collision_position = m.zero(),
			score = 0.0,
			wall_score = 0.0,
			wall_ride = false,
			grind = nil,
		})
	end
	for i = 1, #batch.requests do
		local c = self.candidates[i]
		c.start_velocity = batch.velocities[i]
		c.prediction = {
			request = QueryRequest.clone(batch.requests[i]),
			result = QueryResult.miss(),
		}
	end
	self.batch = batch
	self.pending = true
end

-- ROBLOX: Result<bool, String> -> bool или rt.raise(строка).
-- info передаётся по значению (Copy), поэтому копируем его перед изменением.
function TrajectorySelector.launch(self: TrajectorySelector, info_in: types.LaunchInfo, input: SelectorInput, s: SelectorSettings): boolean
	if self.pending then
		return false
	end
	if info_in.trajectory_count == 0 then
		rt.raise("GetLaunchInfo supplied zero trajectory candidates")
	end
	local info = LaunchInfo.clone(info_in)
	self.pass = 0
	self.valid = false
	-- Launch invalidates9636 but retains the cached winning result and COM.
	self.selected_index = nil
	self.grind_normal = nil
	self.adjusted_on_vert = launch.adjust_velocity(info, input, s)
	self.launch_info = info
	launch_pass(self, input, s)
	return true
end

local function com_trajectory(self: TrajectorySelector, selection: Selection, input: SelectorInput, s: SelectorSettings): Trajectory
	local info = self.launch_info
	assert(info, "completed launch packet")
	local batch = self.batch
	assert(batch, "completed query batch")
	local trajectory = Trajectory.clone(selection.prediction.request.trajectory)
	local scalar = evaluate(s.landing_com_scalar_vs_slope, selection.landing_normal[2])
	local delta = sub(info.animation_com_position, trajectory.position)
	local height = f32(math.abs(dot(input.reference_up, sub(batch.origin, info.animation_com_position))) * scalar)
	local offset = scale(selection.landing_normal, height)
	if selection.prediction.result.contact_frame > 0 then
		trajectory.position = add(trajectory.position, delta)
		launch.adjust_trajectory(
			trajectory,
			selection.prediction.result.contact_frame,
			sub(offset, delta),
			s.maximum_trajectory_adjust
		)
	end
	return trajectory
end

-- Complete a real world query batch in order. A second pass is exposed by
-- pending()/requests(); host scheduling preserves its next Update boundary.
-- ROBLOX: колбэки grind/line сообщают об ошибке через rt.raise.
function TrajectorySelector.complete_batch(
	self: TrajectorySelector,
	results: { QueryResult },
	input: SelectorInput,
	s: SelectorSettings,
	grind_fn: (Prediction, boolean) -> grind.GrindEvaluation,
	line: (Vector, Vector, number) -> query.SurfaceHit?
): boolean
	self.just_changed = false
	if not self.pending then
		return self.valid
	end
	local count = #TrajectorySelector.requests(self)
	if #results ~= count then
		rt.raise("Trajectory completion count differs from submitted batch")
	end
	self.just_changed = self.pass == 2
	self.pending = false
	self.pass += 1
	for i = 1, math.min(#self.candidates, #results) do
		self.candidates[i].prediction.result = QueryResult.clone(results[i])
	end
	self.all_predictions_missed = scoring.score(self.candidates, count, self.pass, self.adjusted_on_vert, input, s, grind_fn, line)
	local index = 0
	local best = -100000000.0
	for i = 1, count do
		local c = self.candidates[i]
		if c.score > best then
			best = c.score
			index = i - 1
		end
	end
	local c = Candidate.clone(self.candidates[index + 1])
	for i = 1, count do
		local target = self.candidates[i].grind
		if target ~= nil then
			self.grind_normal = target.vertical_normal
			break
		end
	end
	self.selected_index = index
	-- The copied COM trajectory is only recalculated on a valid-time result.
	local old = self.selection
	local selection: Selection = {
		candidate_index = index,
		prediction = c.prediction,
		start_velocity = c.start_velocity,
		landing_normal = c.normal,
		collision_velocity = c.collision_velocity,
		collision_position = c.collision_position,
		-- Ctor82D66DC0 initializes2704/2720/2736=zero,2752=-1.
		com_trajectory = if old then old.com_trajectory else empty_trajectory(),
		surface_category = if old then old.surface_category else 0,
		wall_ride = c.wall_ride,
		grind = c.grind,
	}
	if c.prediction.result.contact_time < s.minimum_valid_time then
		self.suggested_normal = c.prediction.result.contact_normal
		self.valid = false
		self.just_changed = false
		self.selection = selection
		return false
	end
	selection.surface_category = bit32.band(bit32.rshift(c.prediction.result.surface, 7), 31)
	selection.com_trajectory = com_trajectory(self, selection, input, s)
	-- 82D68C80: only a winning centre acquisition locks the grind.
	self.grind_locked_to_middle = index == 0 and c.grind ~= nil
	local second_pass = self.pass == 1
		and count >= 2
		and not self.grind_locked_to_middle
		and not (angle_between(selection.landing_normal, input.ground_normal) < s.minimum_normal_delta_second_pass)
	self.selection = selection
	self.valid = true
	if second_pass then
		local info = self.launch_info
		assert(info, "completed launch packet")
		info.start_velocity = selection.start_velocity
		info.cone_angle_x = s.cone_x_second_pass
		info.cone_angle_z = s.cone_z_second_pass
		launch_pass(self, input, s)
		self.pass = 2
	end
	return self.valid
end

return selector
