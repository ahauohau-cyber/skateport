--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/grind/candidate.rs (коммит 2e16697)
--
-- Original S3 82D60C80/82D60B98/82D6A398/82D6A168.
-- ROBLOX: индексы примитивов (usize) с нуля, как в Rust: primitives[i + 1].

local rt = require("../../../../rt")
local m = require("../math")
local prediction_mod = require("../prediction")
local native_arithmetic = require("../../../physics/native_arithmetic")
local point_graph = require("../../../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local fmax = rt.fmax
local dot, add, sub, scale, cross, madd = m.dot, m.add, m.sub, m.scale, m.cross, m.madd
local length, inverse_length, normalize, reciprocal, angle_between = m.length, m.inverse_length, m.normalize, m.reciprocal, m.angle_between
local Trajectory = prediction_mod.Trajectory
local evaluate = point_graph.PointGraph.evaluate

type Vector = m.Vector
type Prediction = prediction_mod.Prediction
type Trajectory = prediction_mod.Trajectory

local candidate = {}

export type GrindTrajectoryCandidate = {
	point: Vector,
	trajectory_point: Vector,
	direction: Vector,
	approach: Vector,
	distance: number,
	time: number,
	angle: number,
	frame: number,
	primitive: number,
}

-- 82C1F310 after provider traversal; pairwise rejection preserves global order.
function candidate.trajectory_box_filter(indices: { number }, primitives: any, takeoff: Vector): { number }
	local directions = table.create(#indices) :: any
	for k, i in indices do
		local d = sub(primitives[i + 1]["end"], primitives[i + 1].start)
		directions[k] = scale(d, inverse_length(dot(d, d)))
	end
	local accepted = table.create(#indices) :: any
	for i, index in indices do
		local a: any = primitives[index + 1]
		local keep = true
		for j, other in indices do
			if i == j then
				continue
			end
			local crossed = cross(directions[i], directions[j])
			if not (dot(crossed, crossed) < from_bits(0x38d1_b717)) then
				continue
			end
			local b: any = primitives[other + 1]
			local delta = sub(b.start, a.start)
			local perpendicular = sub(delta, scale(directions[j], dot(directions[j], delta)))
			local distance = dot(perpendicular, perpendicular)
			if not (distance > from_bits(0x38d1_b717) and distance < from_bits(0x3c23_d70b)) then
				continue
			end
			local middle = scale(add(a.start, a["end"]), 0.5)
			local from = sub(b.start, middle)
			if not (dot(from, sub(b["end"], middle)) < 0.0) then
				continue
			end
			local up = normalize(cross(cross(directions[i], m.up()), directions[i]))
			local height = dot(delta, up)
			local alternative = add(middle, sub(from, scale(directions[j], dot(directions[j], from))))
			local first = sub(middle, takeoff)
			local second = sub(alternative, takeoff)
			if (height > -f32(0.02) and dot(first, first) > dot(second, second)) or height > f32(0.02) then
				keep = false
			end
		end
		if keep then
			table.insert(accepted, index)
		end
	end
	return accepted
end

-- 82D60C80's quadratic roots followed by82D60B98's later-root selection.
-- A double root must be strictly positive. The two-root branch takes max;
-- it does not add a positive-time restriction absent from the source.
function candidate.descending_plane_time(t: Trajectory, point: Vector, normal: Vector): number?
	local c = f32(dot(normal, t.position) - dot(point, normal))
	local b = dot(normal, t.velocity)
	local a = dot(normal, scale(t.acceleration, reciprocal(2.0)))
	local discriminant = f32(f32(b * b) - f32(f32(4.0 * a) * c))
	if discriminant < 0.0 then
		return nil
	end
	local inverse = reciprocal(f32(2.0 * a))
	if discriminant > 0.0 then
		local root = f32(discriminant * inverse_length(discriminant))
		return fmax(f32(inverse * f32(-b + root)), f32(inverse * f32(-b - root)))
	end
	local time = f32(inverse * -b)
	return if time > 0.0 then time else nil
end

-- 8296EC98's oriented angle then82E09C80's actual fractional-turn fold.
-- Keep the wrap arithmetic: acos(abs(dot)) is not binary32 equivalent.
local function folded_approach_angle(a: Vector, b: Vector, normal: Vector): number
	local angle = angle_between(a, b)
	local aa = dot(a, a)
	local bb = dot(b, b)
	if aa > from_bits(0x38d1_b717) and bb > from_bits(0x38d1_b717) then
		local function unit(v: Vector, square: number): Vector
			local r = native_arithmetic.reciprocal_square_root_estimate(square)
			return scale(v, mul_add(f32(r * 0.5), mul_add(-square, f32(r * r), 1.0), r))
		end
		if dot(cross(unit(a, aa), unit(b, bb)), normal) < 0.0 then
			angle = f32(from_bits(0x40c9_0fdb) - angle)
		end
	end
	local turns = f32(angle * from_bits(0x3e22_f983))
	local fraction = f32(turns - math.floor(turns))
	local wrapped = f32(f32(fraction - (if fraction > 0.5 then 1.0 else 0.0)) * from_bits(0x40c9_0fdb))
	local sign = if wrapped > 0.0 then 1.0 else -1.0
	local magnitude = f32(wrapped * sign)
	-- ROBLOX: std::f32::consts::PI -> from_bits(0x40490fdb).
	local folded = if magnitude > from_bits(0x3fc9_0fdb) then f32(magnitude - from_bits(0x4049_0fdb)) else magnitude
	return math.abs(f32(sign * folded))
end

-- 82D6A398. The padding is physics_trajectory+516, not a host snap radius.
function candidate.consider_grind_primitive(prediction: Prediction, edge: any, primitive: number, padding: number): GrindTrajectoryCandidate?
	local delta = sub(edge["end"], edge.start)
	local normal_unscaled = cross(delta, cross(m.up(), delta))
	local normal = scale(normal_unscaled, inverse_length(dot(normal_unscaled, normal_unscaled)))
	local rail_length = length(delta)
	-- 830BD320 is initialized to1 by82F825D0. The original endpoints remain
	-- unchanged; only the direction and endpoint overrun vector are capped.
	if rail_length > 1.0 then
		delta = scale(delta, reciprocal(rail_length))
	end
	local offset = madd(normal, prediction.request.radius, scale(normal, padding))
	local time = candidate.descending_plane_time(prediction.request.trajectory, add(edge.start, offset), normal)
	if time == nil then
		return nil
	end
	local trajectory_point = sub(Trajectory.position_at(prediction.request.trajectory, time), offset)
	local direction = normalize(delta)
	local difference = sub(trajectory_point, edge.start)
	local distance = length(cross(difference, direction))
	local point = madd(direction, dot(direction, difference), edge.start)
	local extension = scale(delta, f32(0.1))
	-- Strict endpoint test82D6A708. No closest-point clamping.
	if not (dot(sub(point, sub(edge.start, extension)), sub(point, add(edge["end"], extension))) < 0.0) then
		return nil
	end
	local velocity = prediction.request.trajectory.velocity
	local approach = normalize(sub(velocity, scale(normal, dot(normal, velocity))))
	local horizontal = sub(point, prediction.request.trajectory.position)
	horizontal[2] = 0.0
	local angle = folded_approach_angle(horizontal, direction, normal)
	return {
		point = point,
		trajectory_point = trajectory_point,
		direction = direction,
		approach = approach,
		distance = distance,
		time = time,
		angle = angle,
		frame = rt.float_as_i32(f32(time * from_bits(0x426f_ffff))),
		primitive = primitive,
	}
end

-- 82D6A168 consumes one winner per call. Retrying after a rejected target
-- must retain the remaining insertion order, not sort the list by distance.
-- ROBLOX: &mut Vec -> массив, победитель удаляется table.remove.
function candidate.take_best_grind(
	candidates: { GrindTrajectoryCandidate },
	difficulty_distance: number,
	height_penalty: point_graph.PointGraph
): GrindTrajectoryCandidate?
	local chosen: number? = nil
	local fallback = 1000.0
	local best_angle = from_bits(0x4049_0fdb)
	local height = -10000.0
	for i, c in candidates do
		if c.distance < difficulty_distance then
			local benefit = f32(best_angle - c.angle)
			if benefit > evaluate(height_penalty, f32(c.point[2] - height)) then
				height = c.point[2]
				fallback = -1.0
				best_angle = c.angle
				chosen = i
			end
		elseif c.distance < fallback then
			fallback = c.distance
			chosen = i
		end
	end
	if chosen == nil then
		return nil
	end
	return table.remove(candidates, chosen)
end

return candidate
