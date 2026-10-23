--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/launch.rs (коммит 2e16697)
--
-- Original TU3 trajectory launch calculations82D67D08/82D67320/82D682E8.
-- ROBLOX: &mut LaunchInfo / &mut Trajectory -> таблица меняется на месте.

local rt = require("../../../rt")
local m = require("./math")
local types = require("./types")
local prediction = require("./prediction")
local point_graph = require("../../point_graph")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local fmin, fmax = rt.fmin, rt.fmax
local dot, sub, add, scale, cross, madd = m.dot, m.sub, m.add, m.scale, m.cross, m.madd
local length, inverse_length, normalize, transform, reciprocal = m.length, m.inverse_length, m.normalize, m.transform, m.reciprocal
local STEP = m.STEP
local evaluate = point_graph.PointGraph.evaluate

type Vector = m.Vector
type LaunchInfo = types.LaunchInfo
type SelectorInput = types.SelectorInput
type SelectorSettings = types.SelectorSettings
type QueryRequest = prediction.QueryRequest
type Trajectory = prediction.Trajectory

local launch = {}

function launch.adjust_velocity(info: LaunchInfo, input: SelectorInput, s: SelectorSettings): boolean
	local n = input.ground_normal
	local v = info.start_velocity
	local normal = scale(n, dot(v, n))
	normal[2] = 0.0
	local combined = add({ 0.0, v[2], 0.0, 0.0 }, normal)
	local residual = sub(v, combined)
	local lean = fmin(fmax(f32(input.directional_input - f32(0.25)), -1.0), 1.0)
	local aligned = normalize(sub(m.up(), scale(n, f32(lean * s.vert_jump_align_max_angle))))
	if n[2] >= s.vert_jump_align_max_ground_normal_y then
		return false
	end
	if normalize(combined)[2] > s.vert_jump_align_min_direction_y then
		-- The second term really uses UNIT velocity, not the original speed.
		local left = scale(add(scale(aligned, length(combined)), residual), s.vert_jump_align_factor)
		local right = scale(normalize(v), f32(1.0 - s.vert_jump_align_factor))
		info.start_velocity = scale(normalize(add(left, right)), length(v))
		return true
	else
		if not info.player_jumped and input.previous_physics_state ~= 200 then
			local normal2 = scale(n, dot(v, n))
			info.start_velocity = add(scale(normal2, s.natural_air_off_verts_scalar), sub(v, normal2))
		end
		return false
	end
end

function launch.candidate_velocities(info: LaunchInfo, s: SelectorSettings): { Vector }
	local count = math.min(info.trajectory_count, 7)
	local velocities = table.create(count) :: any
	if count == 0 then
		return velocities
	end
	local v = info.start_velocity
	table.insert(velocities, v)
	local right = normalize(cross(m.up(), v))
	local forward = normalize(cross(right, m.up()))
	local speed = length(v)
	local cone_speed = if info.player_jumped then length(info.com_velocity) else speed
	local radians = from_bits(0x3c8e_fa35)
	local x = f32(info.cone_angle_x * radians)
	local z = f32(f32(evaluate(s.cone_angle_z_vs_speed, f32(cone_speed * f32(0.05))) * info.cone_angle_z) * radians)
	cone_speed = fmin(fmax(cone_speed, s.speed_factor_min), s.speed_factor_max)
	right = scale(right, f32(trigonometry.sin(x) * cone_speed))
	forward = scale(forward, f32(trigonometry.sin(z) * cone_speed))
	if count > 1 then
		local step = f32(from_bits(0x40c9_0fdb) / f32(count - 1))
		local angle = 0.0
		for _ = 1, count - 1 do
			local candidate = madd(forward, trigonometry.cos(angle), madd(right, trigonometry.sin(angle), v))
			table.insert(velocities, scale(normalize(candidate), fmin(length(candidate), speed)))
			angle = f32(angle + step)
		end
	end
	return velocities
end

export type LaunchBatch = {
	requests: { QueryRequest },
	velocities: { Vector },
	origin: Vector, -- 2864
	board_position: Vector, -- 2848
	local_board_position: Vector, -- 2832
	local_com_position: Vector, -- 2784
	com_displacement: Vector, -- 2768
}

-- 82D68698 deliberately uses the original -19.6 and -1/9.8 coefficients.
local function max_time(velocity: Vector, s: SelectorSettings): number
	local square = mul_add(velocity[2], velocity[2], -f32(s.trajectory_max_drop * from_bits(0xc19c_cccd)))
	local root = if square == 0.0 then 0.0 else f32(square * inverse_length(square))
	return fmin(f32(f32(-velocity[2] - root) * from_bits(0xbdd0_fac6)), s.trajectory_max_time)
end

function launch.batch(info: LaunchInfo, input: SelectorInput, s: SelectorSettings): LaunchBatch
	local velocities = launch.candidate_velocities(info, s)
	local ground = evaluate(s.displacement_vs_ground_normal, math.abs(input.ground_normal[2]))
	local speed = evaluate(s.displacement_vs_speed, f32(input.board_vertical_velocity * f32(0.1)))
	local blend = fmax(speed, ground)
	local height = f32(dot(sub(info.animation_com_position, input.contact_position), info.reckoning_transform[2]) - s.trajectory_radius)
	local displacement = f32(
		f32(fmin(height, s.trajectory_displacement) * f32(1.0 - blend)) + f32(s.trajectory_displacement * blend)
	)
	local origin = sub(info.animation_com_position, scale(info.reckoning_transform[2], displacement))
	local board_position = info.board_position
	if info.use_position_override then
		origin = info.start_position_override
		board_position = info.board_position_override
	end
	local com_displacement = sub(info.animation_com_position, origin)
	local duration = max_time(info.start_velocity, s)
	local requests = table.create(#velocities) :: any
	for i, velocity in velocities do
		requests[i] = {
			trajectory = {
				position = madd(velocity, info.timestep, origin),
				velocity = velocity,
				acceleration = input.gravity,
				duration = duration,
			},
			radius = s.trajectory_radius,
			start_error = s.trajectory_error_start,
			end_error = s.trajectory_error_end,
		}
	end
	return {
		requests = requests,
		velocities = velocities,
		origin = origin,
		board_position = board_position,
		com_displacement = com_displacement,
		local_board_position = transform(info.reckoning_inverse, sub(info.board_position, origin)),
		local_com_position = transform(info.reckoning_inverse, com_displacement),
	}
end

-- tTrajectory::AdjustTrajectory82D609E0 changes velocity only.
function launch.adjust_trajectory(trajectory: Trajectory, frame: number, adjustment: Vector, maximum: number)
	if frame <= 0 then
		return
	end
	local correction = scale(adjustment, reciprocal(f32(f32(frame) * STEP)))
	local scalar = if dot(correction, correction) > f32(maximum * maximum)
		then f32(maximum / length(correction))
		else 1.0
	trajectory.velocity = madd(correction, scalar, trajectory.velocity)
end

return launch
