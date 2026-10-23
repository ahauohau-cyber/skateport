--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/speed_model.rs (коммит 2e16697)
--
-- TU3 Skateboard::UpdateSpeedModel 82C04F68, including its force-enable gate.
-- The caller supplies GetEffectiveTransform and GetMass outputs, not a guessed
-- direction or mass. Ground submits this result as force tag 6.

local rt = require("../../rt")
local point_graph = require("../point_graph")
local vector_mod = require("./vector")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local PointGraph = point_graph.PointGraph
local clamp, dot3, normalize = vector_mod.clamp, vector_mod.dot3, vector_mod.normalize

type F4 = { number }

local speed_model = {}

export type SpeedModelSettings = {
	-- physics_speedmodel layout +0,+8,+16,+20,+24.
	negative_gain: number,
	maximum_gravity_acceleration: number,
	gravity: number,
	positive_gain: number,
	coffin_acceleration: number,
	-- Surface layout +260 and curve +96/+128.
	speed_error_bound: number,
	surface_friction: point_graph.PointGraph,
	-- physics_manual layout +180,+212,+220.
	manual_acceleration: number,
	negative_manual_angle_limit: number,
	manual_angle_limit: number,
	-- Global +184 layout +356 and curves +144/+176,+224/+256.
	no_input_delay: number,
	no_input_friction: point_graph.PointGraph,
	manual_friction: point_graph.PointGraph,
	-- Selected-mode layout +44 and +40.
	override_enabled: boolean,
	override_speed: number,
	-- Live constants 830BD350 and 830BD380 (four native lanes each).
	normal_threshold: F4,
	override_direction_threshold: F4,
}

export type SpeedModelState = {
	target_speed: number, -- Board +260
	flags_1360: number,
}

export type SpeedModelInput = {
	flags_2468: number,
	flags_2476: number,
	wheel_contact_count: number, -- +2556
	frames_2580: number,
	timestep: number, -- +2604
	signed_speed: number, -- +2612
	angle_2652: number,
	surface_speed: number, -- +2656
	turn_2672: number,
	balance: number, -- +2720
	elapsed_without_input: number, -- +2748
	manual_state_276: number, -- Board +276
	vector_160: F4,
	vector_352: F4,
	velocity_416: F4,
	normal_464: F4,
	-- Z column of 82C01BF8's result; stance correction has already happened.
	effective_forward: F4,
	-- 82C06F58 result, whose two-accumulator summation is implemented in mass.
	mass: number,
}

-- Force vector followed by zeroed local application point, all four lanes.
function speed_model.update(state: SpeedModelState, settings: SpeedModelSettings, input: SpeedModelInput): { number }
	local speed = math.abs(input.signed_speed)
	local dt = input.timestep
	local bound = settings.speed_error_bound
	local lower = f32(speed - bound)
	lower = if -lower >= 0.0 then 0.0 else lower
	local target
	if bit32.btest(state.flags_1360, 0x8000_0000) then
		state.flags_1360 = bit32.band(state.flags_1360, 0x7fff_ffff)
		target = speed
	else
		target = clamp(state.target_speed, lower, f32(bound + speed))
	end
	local coffin = if bit32.btest(input.flags_2476, 0x4000_0000) then f32(settings.coffin_acceleration * dt) else 0.0
	local projection = dot3(input.velocity_416, input.effective_forward)
	local projected = {}
	for i = 1, 4 do
		projected[i] = f32(input.effective_forward[i] * projection)
	end
	local normal_speed = dot3(projected, input.normal_464)
	local t = {}
	for i = 1, 4 do
		t[i] = f32(projected[i] - f32(input.normal_464[i] * normal_speed))
	end
	local tangent = normalize(t, settings.normal_threshold)
	local gravity = f32(clamp(f32(-tangent[2] * settings.gravity), -settings.maximum_gravity_acceleration, settings.maximum_gravity_acceleration) * dt)

	if input.frames_2580 < 30 then
		local active = if input.manual_state_276 == 0.0 then 0.0 else 1.0
		local direction = if input.balance > 0.0 then 1.0 else -1.0
		if 0.0 > dot3(input.vector_352, tangent) then
			direction = -direction
		end
		local angle = math.abs(input.angle_2652)
		local within = if angle > settings.manual_angle_limit then 0.0 else 1.0
		local negative_within = if angle > settings.negative_manual_angle_limit then 0.0 else 1.0
		local acceleration = f32(f32(f32(f32(f32(input.turn_2672 * input.turn_2672) * settings.manual_acceleration) * within) * direction) * active)
		if acceleration < 0.0 then
			acceleration = f32(acceleration * negative_within)
		end
		target = f32(acceleration + target)
	end
	local friction = f32(-PointGraph.evaluate(settings.surface_friction, input.surface_speed) * dt)
	local surface_delta
	if gravity > 0.0 then
		surface_delta = f32(friction + gravity)
	elseif f32(friction - gravity) >= 0.0 then
		surface_delta = gravity
	else
		surface_delta = friction
	end
	target = f32(f32(surface_delta + coffin) + target)
	if input.elapsed_without_input > settings.no_input_delay then
		-- ROBLOX: в Rust `-x.mul_add(..)` = `-(x.mul_add(..))`.
		target = -mul_add(PointGraph.evaluate(settings.no_input_friction, input.surface_speed), dt, -target)
	end
	if input.balance ~= 0.0 then
		target = -mul_add(PointGraph.evaluate(settings.manual_friction, input.surface_speed), dt, -target)
	end
	state.target_speed = if target >= 0.0 then target else 0.0
	local error = clamp(f32(state.target_speed - speed), -bound, bound)
	if settings.override_enabled and bit32.btest(input.flags_2476, 0x0040_0000) and input.normal_464[2] > f32(0.65) then
		local goal = f32(settings.override_speed * from_bits(0x3E8E_38E4))
		local along = dot3(input.velocity_416, input.vector_160)
		local all = true
		for _, th in settings.override_direction_threshold do
			if not (th > along) then
				all = false
				break
			end
		end
		if all and 1.0 > input.surface_speed then
			goal = -goal
		end
		error = clamp(f32(goal - speed), f32(-0.4), f32(0.4))
	end
	local enabled = bit32.band(input.flags_2468, 0x6201_0000) == 0
		and bit32.band(input.flags_2476, 0x0800_0000) == 0
		and input.wheel_contact_count >= 2
	local gain = if not enabled then 0.0 elseif error < 0.0 then settings.negative_gain else settings.positive_gain
	local scalar = f32(f32(f32(input.mass * gain) * error) / dt)
	local forward = dot3(input.effective_forward, tangent) > 0.0
	local output = table.create(8, 0.0)
	for i = 1, 4 do
		local axis = if forward then input.effective_forward[i] else -input.effective_forward[i]
		output[i] = f32(axis * scalar)
	end
	return output
end

return speed_model
