--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/ground_contact_response.rs (коммит 2e16697)
--
-- Wall-ride contact response, TU3 82D93DF0. Inputs are the native published
-- board contact record and processed physical observations, not ray guesses.

local rt = require("../../rt")
local bmo = require("../physics/board_motion_output")
local point_graph = require("../point_graph")
local board_types = require("./grounded/state/board_types")

local f32 = rt.f32
local mul_add = rt.mul_add
local dot = bmo.dot
local PointGraph = point_graph.PointGraph

type F4 = { number }
type Vector3 = vector

local ground_contact_response = {}

export type WallRideSettings = {
	anti_gravity_vs_time: point_graph.PointGraph,
	max_dot_floor_wall: number,
	foot_force_time: number,
	auto_jump_height: number,
	max_time: number,
	velocity_time_to_consider: number,
	auto_jump_y_down_scalar: number,
	auto_jump_force: number,
}

export type WallRidePhysical = {
	-- Processed464,544 and400 respectively.
	board_normal: F4,
	up: F4,
	velocity: F4,
	-- Processed2660,2648,2652,2556.
	board_mass: number,
	gravity: number,
	speed: number,
	contact_count: number,
}

local function xyz(v: F4): Vector3
	return vector.create(v[1], v[2], v[3])
end

local F32_0_71 = f32(0.71)

function ground_contact_response.wall_ride_response(
	settings: WallRideSettings,
	physical: WallRidePhysical,
	frame: board_types.GroundContactFrame,
	previous_velocity: F4
): board_types.GroundContactResponse
	local response: board_types.GroundContactResponse = {
		active_2731 = false,
		tag_16_force = { tag = 16, force_world = vector.zero, point_body = vector.zero },
		vector_2688 = table.clone(previous_velocity),
		scalar_2704 = 0.0,
		animated_board_2708 = false,
	}
	-- 82D94C10 installs literal .5 and .71 in the two first gates.
	if not frame.flag_8084 or not (math.abs(physical.board_normal[2]) < 0.5) or not (dot(xyz(physical.up), xyz(physical.board_normal)) > F32_0_71) then
		return response
	end
	response.active_2731 = true
	local acceleration = PointGraph.evaluate(settings.anti_gravity_vs_time, frame.scalar_2752)
	response.tag_16_force.force_world = vector.create(0.0, -f32(f32(acceleration * physical.board_mass) * physical.gravity), 0.0)
	local time = frame.scalar_2756
	local consider = (time < 0.0 and time > -1.0) or (physical.speed < 3.0 and time > f32(0.1))
	if not (consider or (frame.scalar_2752 > f32(0.01) and physical.contact_count > 0) or frame.scalar_2752 > settings.foot_force_time) then
		return response
	end
	-- The dot is loaded BEFORE the temporary slot is overwritten by the
	-- height/velocity expression at82D94044. Older decompiles alias the two.
	local floor_wall = dot(xyz(frame.vector_8064), xyz(physical.board_normal))
	local height = math.abs(f32(frame.vector_8048[2] - frame.vector_8032[2]))
	local predicted_height = mul_add(physical.velocity[2], settings.velocity_time_to_consider, height)
	if not (floor_wall < settings.max_dot_floor_wall and (consider or predicted_height < settings.auto_jump_height or time > settings.max_time)) then
		return response
	end
	response.animated_board_2708 = true
	local into_normal = dot(xyz(physical.board_normal), xyz(physical.velocity))
	local tangent = {}
	for i = 1, 4 do
		tangent[i] = f32(physical.velocity[i] - f32(physical.board_normal[i] * into_normal))
	end
	if tangent[2] < 0.0 and tangent[2] > -6.0 then
		tangent[2] = f32(tangent[2] * settings.auto_jump_y_down_scalar)
	end
	local out = {}
	for i = 1, 4 do
		out[i] = mul_add(physical.board_normal[i], settings.auto_jump_force, tangent[i])
	end
	response.vector_2688 = out
	return response
end

return ground_contact_response
