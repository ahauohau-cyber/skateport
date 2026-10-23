--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/steering.rs (коммит 2e16697)
--
-- TU3 steering tilt (`0x82D92440`) and truck targets (`0x82C040F0`).

local rt = require("../../rt")
local point_graph = require("../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local PointGraph = point_graph.PointGraph

local steering = {}

export type SteeringSettings = {
	hard_turn_increase: number,
	damping: number,
	speed_graph_max_speed: number,
	push_scalar_increment: number,
	push_scalar_decrement: number,
	push_scalar_min: number,
	manual_scalar: number,
	general_scalar: number,
	tight_trucks_scalar: number,
	speed_graph: point_graph.PointGraph,
	input_graph: point_graph.PointGraph,
	tilt_blending: number,
}

-- Field names describe the reads from `ProcessedPhysIn`. No yaw-rate or
-- bicycle steering interpretation is applied to the returned tilt.
export type SteeringInput = {
	turn: number,
	hard_turn: number,
	absolute_body_speed: number,
	flipped_controls_scalar: number,
	balance: number,
	truck_tightness: number,
	-- `ProcessedPhysIn+2468`, bit 27 (distinct from push-force bit 25).
	pushing: boolean,
}

function steering.default_input(): SteeringInput
	return { turn = 0.0, hard_turn = 0.0, absolute_body_speed = 0.0, flipped_controls_scalar = 0.0, balance = 0.0, truck_tightness = 0.0, pushing = false }
end

-- ROBLOX: Option<&mut f32> -> ячейка { value: number } или nil.
export type Cell = { value: number }

-- Optional pointers in the native function are represented independently.
-- Updates are per physics call; the native routine has no timestep argument.
function steering.calculate_tilt(settings: SteeringSettings, input: SteeringInput, push_scalar: Cell?, damped_turn: Cell?): number
	local hard_scalar = mul_add(math.abs(input.hard_turn), settings.hard_turn_increase, 1.0)
	local turn = input.turn
	if input.hard_turn ~= 0.0 then
		turn = if turn >= 0.0 then 1.0 else -1.0
	end
	if damped_turn then
		turn = mul_add(f32(1.0 - settings.damping), damped_turn.value, f32(settings.damping * turn))
		damped_turn.value = turn
	end
	local speed_scalar = PointGraph.evaluate(settings.speed_graph, rt.fclamp(f32(input.absolute_body_speed / settings.speed_graph_max_speed), 0.0, 1.0))
	local input_scalar = PointGraph.evaluate(settings.input_graph, math.abs(turn))
	local push = 1.0
	if push_scalar then
		local nxt = if input.pushing
			then f32(push_scalar.value - settings.push_scalar_decrement)
			else f32(settings.push_scalar_increment + push_scalar.value)
		push_scalar.value = rt.fclamp(nxt, settings.push_scalar_min, 1.0)
		push = push_scalar.value
	end
	local manual = if input.balance ~= 0.0 then settings.manual_scalar else 1.0
	local tightness = f32(mul_add(settings.tight_trucks_scalar, input.truck_tightness, 1.0) - input.truck_tightness)
	local r = f32(input.flipped_controls_scalar * settings.general_scalar)
	r = f32(r * manual)
	r = f32(r * tightness)
	r = f32(r * push)
	r = f32(r * input_scalar)
	r = f32(r * speed_scalar)
	r = f32(r * hard_scalar)
	return f32(r * turn)
end

export type TruckSteeringState = {
	deck_tilt: number,
	-- Native `SkateboardBody+7680/+7684` order, not stance-relative labels.
	targets: { number },
	activation_time: { number },
}

local TruckSteeringState = {}
steering.TruckSteeringState = TruckSteeringState

function TruckSteeringState.default(): TruckSteeringState
	return { deck_tilt = 0.0, targets = { 0.0, 0.0 }, activation_time = { 0.0, 0.0 } }
end

function TruckSteeringState.clone(self: TruckSteeringState): TruckSteeringState
	return { deck_tilt = self.deck_tilt, targets = table.clone(self.targets), activation_time = table.clone(self.activation_time) }
end

local ACTIVATION_LIMIT = f32(0.16500001)
local ACTIVATION_RATE = f32(6.060606)
local DECAY = f32(0.983)
local STEP = from_bits(0x3C88_8889)

-- Flags are retained in their native words to make stance-dependent
-- contact ownership explicit (`+2468` bit 20, `+2472` bits 26 and 27).
function TruckSteeringState.update(self: TruckSteeringState, target: number, blend: number, flags_2468: number, flags_2472: number)
	self.deck_tilt = mul_add(f32(1.0 - blend), self.deck_tilt, f32(blend * target))
	local active = { bit32.btest(flags_2472, bit32.lshift(1, 27)), bit32.btest(flags_2472, bit32.lshift(1, 26)) }
	if bit32.btest(flags_2468, bit32.lshift(1, 20)) then
		active[1], active[2] = active[2], active[1]
	end
	for index = 1, 2 do
		if active[index] then
			if self.activation_time[index] <= ACTIVATION_LIMIT then
				self.activation_time[index] = f32(self.activation_time[index] + STEP)
				local fraction = rt.fclamp(f32(self.activation_time[index] * ACTIVATION_RATE), 0.0, 1.0)
				self.targets[index] = mul_add(f32(1.0 - fraction), self.targets[index], f32(fraction * self.deck_tilt))
			else
				self.targets[index] = self.deck_tilt
			end
		else
			-- The first inactive frame holds the angle; subsequent frames decay.
			if self.activation_time[index] == 0.0 then
				self.targets[index] = f32(self.targets[index] * DECAY)
			end
			self.activation_time[index] = 0.0
		end
	end
end

return steering
