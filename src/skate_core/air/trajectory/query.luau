--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/query.rs (коммит 2e16697)
--
-- Complete trajectory-segment walk82770910 and result writer8276DBE0.
-- The host supplies real nearest swept-line hits and intersecting triangles.
-- ROBLOX: Result<_, E> у колбэков -> колбэк вызывает rt.raise(e), ошибка
-- проходит насквозь (как `?`). Option<SurfaceHit> -> SurfaceHit или nil.

local rt = require("../../../rt")
local m = require("./math")
local prediction = require("./prediction")
local native_arithmetic = require("../../physics/native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot, sub, add, scale, cross = m.dot, m.sub, m.add, m.scale, m.cross
local length, inverse_length, normalize = m.length, m.inverse_length, m.normalize
local STEP = m.STEP
local Trajectory = prediction.Trajectory

type Vector = m.Vector
type QueryRequest = prediction.QueryRequest
type QueryResult = prediction.QueryResult

local query = {}

export type SurfaceHit = {
	position: Vector,
	normal: Vector,
	transform: m.Transform,
	surface: number,
	geometry: number,
}

-- fn reciprocal (локальная копия в query.rs).
local function reciprocal(value: number): number
	local inverse = native_arithmetic.reciprocal_estimate(value)
	for _ = 1, 2 do
		inverse = mul_add(inverse, mul_add(-inverse, value, 1.0), inverse)
	end
	return inverse
end
local function step_size(gravity_y: number, error_radius: number): number
	local square = f32(reciprocal(gravity_y) * f32(-8.0 * error_radius))
	if square == 0.0 then
		return 0.0
	end
	return f32(square * inverse_length(square))
end

-- 8276C558 writes both collision seconds and integer frame, including its
-- distinct negligible-gravity branch. A miss is handled by the caller.
local function time_at_contact(request: QueryRequest, position: Vector, time: number): (number, number)
	local EPSILON = from_bits(0x38d1_b717)
	local trajectory = request.trajectory
	if EPSILON >= math.abs(f32(reciprocal(2.0) * trajectory.acceleration[2])) then
		local distance = length(sub(position, trajectory.position))
		if not (math.abs(distance) > EPSILON) then
			return 0.0, 0
		end
		local speed = length(trajectory.velocity)
		if not (math.abs(speed) > EPSILON) then
			return 0.0, 0
		end
		local frames = f32(reciprocal(speed) * distance)
		-- ROBLOX: frames.ceil() as i32 -> rt.float_as_i32(math.ceil(...)).
		return f32(frames * STEP), rt.float_as_i32(math.ceil(frames))
	end
	local closest_square = rt.F32_MAX
	local found = false
	while trajectory.duration >= time do
		local delta = sub(position, Trajectory.position_at(trajectory, time))
		local square = dot(delta, delta)
		if closest_square >= square then
			closest_square = square
		elseif square > closest_square then
			time = f32(time - STEP)
			found = true
			break
		end
		time = f32(time + STEP)
	end
	if not found then
		time = trajectory.duration
	end
	-- 82F4E948 is ceiling (truncate then add1 for a positive remainder).
	return time, rt.float_as_i32(math.ceil(f32(reciprocal(STEP) * time)))
end

-- 82771018, using at most64 triangles retained by82772028 in world order.
local function average_landing_normal(triangles: { { Vector } }, velocity: Vector): Vector
	local accepted = {}
	local most_up = m.zero()
	local highest = -1.0
	for i = 1, math.min(#triangles, 64) do
		local triangle = triangles[i]
		local normal = cross(sub(triangle[2], triangle[1]), sub(triangle[3], triangle[1]))
		-- This first stage uses Normalize, not NormalizeSafe.
		normal = scale(normal, inverse_length(dot(normal, normal)))
		if normal[2] > f32(0.7) or dot(normal, velocity) <= 0.0 then
			local up = dot(normal, m.up())
			if up > highest then
				highest = up
				most_up = normal
			end
			table.insert(accepted, normal)
		end
	end
	if #accepted == 0 then
		return m.up()
	end
	local total = m.zero()
	for _, normal in accepted do
		if dot(most_up, normal) > 0.5 then
			total = add(total, normal)
		end
	end
	return normalize(total)
end

-- ROBLOX: line(start, end, radius) -> SurfaceHit? ; nearby(position, radius) -> { [Vector; 3] }.
-- Ошибки колбэков — через rt.raise и проходят насквозь.
function query.query_trajectory(
	request: QueryRequest,
	line: (Vector, Vector, number) -> SurfaceHit?,
	nearby: (Vector, number) -> { { Vector } }
): QueryResult
	local trajectory = request.trajectory
	local start_step = trajectory.duration
	local end_step = trajectory.duration
	if trajectory.acceleration[2] < 0.0 then
		start_step = step_size(trajectory.acceleration[2], f32(request.start_error * request.radius))
		end_step = step_size(trajectory.acceleration[2], f32(request.end_error * request.radius))
	end
	local minimum_square = f32(f32(f32(request.start_error * request.radius) * request.start_error) * request.radius)
	local time = 0.0
	local start = Trajectory.position_at(trajectory, time)
	local end_ = Trajectory.position_at(trajectory, f32(time + start_step))
	while trajectory.duration > time do
		local delta = sub(end_, start)
		if dot(delta, delta) > minimum_square then
			-- 82770B40 rejects a segment only when all XYZ are tiny.
			local tiny = from_bits(0x3780_0000)
			if math.abs(delta[1]) > tiny or math.abs(delta[2]) > tiny or math.abs(delta[3]) > tiny then
				local hit = line(start, end_, request.radius)
				if hit ~= nil then
					local contact_time, contact_frame = time_at_contact(request, hit.position, time)
					local triangles = nearby(hit.position, request.radius)
					local velocity = Trajectory.velocity_at(trajectory, f32(contact_frame * STEP))
					return {
						contact_position = hit.position,
						contact_normal = hit.normal,
						landing_normal = average_landing_normal(triangles, velocity),
						contact_time = contact_time,
						contact_frame = contact_frame,
						contact_transform = hit.transform,
						surface = hit.surface,
						geometry = hit.geometry,
					}
				end
			end
			start = end_
		end
		local fraction = f32(reciprocal(trajectory.duration) * time)
		local step = mul_add(end_step, fraction, f32(f32(1.0 - fraction) * start_step))
		time = f32(time + step)
		-- The native walk evaluates beyond the horizon; it does not clamp end.
		end_ = Trajectory.position_at(trajectory, f32(time + step))
	end
	return prediction.QueryResult.miss()
end

return query
