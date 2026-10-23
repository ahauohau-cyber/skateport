--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/scoring.rs (коммит 2e16697)
--
-- TU3 scoring82D68FE8/82D68AF0/82D69790 for a world with no grind edges.
-- That topology is supplied by the authored BoardWorld, not inferred from a
-- failed collision. Every wall probe still queries real world geometry.
-- ROBLOX: Result<_, String> колбэков -> rt.raise; Option -> значение или nil.

local rt = require("../../../rt")
local m = require("./math")
local types = require("./types")
local prediction = require("./prediction")
local launch = require("./launch")
local grind = require("./grind")
local query = require("./query")
local point_graph = require("../../point_graph")

local f32 = rt.f32
local from_bits = rt.from_bits
local dot, sub, add, cross, madd = m.dot, m.sub, m.add, m.cross, m.madd
local length, normalize, reciprocal = m.length, m.normalize, m.reciprocal
local evaluate = point_graph.PointGraph.evaluate
local Prediction = prediction.Prediction
local QueryResult = prediction.QueryResult

type Vector = m.Vector
type SelectorInput = types.SelectorInput
type SelectorSettings = types.SelectorSettings
type Prediction = prediction.Prediction

local scoring = {}

export type Candidate = {
	prediction: Prediction,
	start_velocity: Vector, -- candidate64+0, before wall adjustment
	normal: Vector, -- +16
	collision_velocity: Vector, -- +32, before wall adjustment
	collision_position: Vector, -- +48, before wall adjustment
	score: number,
	wall_score: number,
	wall_ride: boolean,
	grind: grind.GrindTarget?,
}

local Candidate = {}
scoring.Candidate = Candidate

-- ROBLOX: Copy.
function Candidate.clone(self: Candidate): Candidate
	local c = table.clone(self)
	c.prediction = Prediction.clone(self.prediction)
	return c
end

local function apex_time(p: Prediction): number
	local v = p.request.trajectory.velocity[2]
	local g = p.request.trajectory.acceleration[2]
	if v < 0.0 or g >= 0.0 then
		return 0.0
	end
	return f32(v * reciprocal(-g))
end

-- ROBLOX: highest: &mut f32 -> ячейка { value = }.
local function wall_score(
	p: Prediction,
	reject_grind: boolean,
	s: SelectorSettings,
	highest: { value: number },
	line: (Vector, Vector, number) -> query.SurfaceHit?
): number
	local normal = p.result.contact_normal
	if not (math.abs(normal[2]) < 0.5) then
		return 0.0
	end
	local start = madd(normal, s.wall_ride_test_distance, p.result.contact_position)
	local end_ = add(start, { 0.0, -10.0, 0.0, 0.0 })
	local hit = line(start, end_, 0.0)
	if hit == nil then
		return 0.0
	end
	if not (dot(hit.normal, normal) < s.wall_ride_normal_dot_limit) then
		return 0.0
	end
	local height = math.abs(f32(hit.position[2] - start[2]))
	if reject_grind then
		return f32(f32(height * s.wall_ride_height_score) - 1000.0)
	end
	local position = Prediction.collision_position(p)
	local delta = sub(p.request.trajectory.position, position)
	local slope = delta[2]
	delta[2] = 0.0
	local horizontal = length(delta)
	if horizontal > from_bits(0x3c23_d70a) then
		slope = f32(slope * reciprocal(horizontal))
	end
	if slope > s.wall_ride_angle_allow_landing then
		return f32(f32(height * s.wall_ride_height_score) - 1000.0)
	end
	if height < s.wall_ride_minimum_height then
		return f32(height - 1000.0)
	end
	local boost = evaluate(s.wall_ride_boost, height)
	if position[2] > highest.value then
		highest.value = position[2]
	end
	launch.adjust_trajectory(
		p.request.trajectory,
		p.result.contact_frame,
		{ 0.0, boost, 0.0, 0.0 },
		s.maximum_trajectory_adjust
	)
	return f32(height * s.wall_ride_height_score)
end

-- ROBLOX: candidates: &mut [Candidate] -> массив, меняется на месте; count —
-- длина среза (&mut self.candidates[..count]). Возвращает all_miss.
function scoring.score(
	candidates: { Candidate },
	count: number,
	pass: number,
	adjusted_on_vert: boolean,
	input: SelectorInput,
	s: SelectorSettings,
	grind_fn: (Prediction, boolean) -> grind.GrindEvaluation,
	line: (Vector, Vector, number) -> query.SurfaceHit?
): boolean
	local all_miss = true -- selector9662, consumed by PhysicsAir COM latch
	local highest_wall = { value = -1000000.0 }
	for index1 = 1, count do
		local index = index1 - 1
		local c = candidates[index1]
		c.score = 0.0
		c.wall_score = 0.0
		c.wall_ride = false
		c.grind = nil
		if not QueryResult.valid(c.prediction.result) then
			continue
		end
		all_miss = false
		if c.prediction.result.contact_frame < s.minimum_trajectory_frames then
			continue
		end
		local middle = index == 0 and pass == 1
		local middle_bonus = if middle and not adjusted_on_vert then s.score_middle_bonus else 0.0
		c.collision_position = Prediction.collision_position(c.prediction)
		c.normal = QueryResult.suggested_normal(c.prediction.result)
		c.prediction.result.contact_normal = c.normal
		c.collision_velocity = Prediction.collision_velocity(c.prediction)
		local force_dot = dot(c.normal, c.collision_velocity)
		local sideways = length(cross(c.normal, normalize(c.collision_velocity)))
		local scalar = evaluate(s.landing_force_scalar, math.abs(force_dot))
		local force_score = f32(f32(force_dot * s.score_landing_force) * scalar)
		local direction_score = f32(f32(sideways * s.score_landing_direction) * scalar)

		local evaluation = grind_fn(
			c.prediction,
			middle
				and not (
					bit32.btest(input.flags_2472, 0x2000_0000)
					and bit32.btest(input.offboard_flags_1776, 0x0400_0000)
					and not bit32.btest(input.offboard_flags_1776, 0x0800_0000)
				)
		)
		c.grind = evaluation.target
		local grind_score
		if bit32.btest(input.flags_2476, 0x0200_0000) then
			grind_score = 0.0
		elseif evaluation.score ~= 0.0 then
			grind_score = evaluation.score
		elseif input.grind_lock_distance > 0.5 or not middle then
			grind_score = evaluate(s.grind_penalty_vs_distance, grind.GrindEvaluation.penalty_input(evaluation))
		else
			grind_score = 0.0
		end
		if grind_score <= 0.0 then
			c.wall_score = wall_score(c.prediction, grind_score < 0.0, s, highest_wall, line)
			c.wall_ride = c.wall_score > 0.0
			if c.wall_score < 0.0 then
				c.prediction.result.contact_normal = m.up()
			end
		end
		local surface_score = 0.0
		if grind_score <= 1.0 then
			local category = bit32.band(bit32.rshift(c.prediction.result.surface, 7), 31)
			if category == 6 then
				surface_score = s.surface_unrideable_score
				c.prediction.result.contact_normal = input.reference_up
			elseif category == 7 then
				surface_score = s.surface_dont_align_score
				c.prediction.result.contact_normal = input.reference_up
			elseif category == 8 then
				surface_score = s.surface_dont_align_score
			end
		end
		c.normal = c.prediction.result.contact_normal
		local transition = 0.0
		if adjusted_on_vert then
			if input.directional_input < 0.5 and grind_score > 0.0 then
				c.grind = nil
				grind_score = evaluate(s.grind_penalty_vs_distance, 0.0)
			end
			local sign = if input.directional_input >= 0.5 then 1.0 else -1.0
			local heading = m.copy(input.heading_direction)
			heading[2] = 0.0
			local since_apex = math.abs(f32(c.prediction.result.contact_time - apex_time(c.prediction)))
			local penalty = if since_apex >= s.minimum_time_after_apex then 0.0 else -500.0
			local coefficient = f32(f32(f32(1.0 - math.abs(input.ground_normal[2])) * sign) * s.score_transition)
			transition = f32(f32(dot(c.normal, normalize(heading)) * coefficient) + penalty)
		end
		c.score = f32(
			evaluate(s.landing_time_bonus, c.prediction.result.contact_time)
				+ f32(f32(f32(f32(f32(direction_score + 1.0) + force_score) + middle_bonus) + grind_score) + transition)
		)
		c.score = f32(c.score + surface_score)
	end
	-- AddWallRideScores runs after ALL candidates, using the final highest Y.
	for index1 = 1, count do
		local c = candidates[index1]
		if QueryResult.valid(c.prediction.result) and c.prediction.result.contact_frame >= s.minimum_trajectory_frames then
			if c.wall_score == 0.0 and Prediction.collision_position(c.prediction)[2] > highest_wall.value then
				c.wall_score = 2000.0
			end
			c.score = f32(c.score + c.wall_score)
		end
	end
	return all_miss
end

return scoring
