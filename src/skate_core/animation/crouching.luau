--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/crouching.rs (коммит 2e16697)
--
-- Stock riding crouch/absorption and auto-pump, TU3 82BB7DA0/82BB8818.

local rt = require("../../rt")
local point_graph = require("../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local evaluate = point_graph.PointGraph.evaluate

local crouching = {}

export type AutoPumpSettings = {
	maximum_crouch: point_graph.PointGraph,
	sufficient_crouch: number,
	standing_threshold: number,
	rise_speed: number,
	pump_speed: number,
	potential_threshold: number,
	potential_blend: number,
	intent_magnitude_start: number,
	intent_angle_region: number,
	crouch_time: number,
	crouch_speed: number,
}

export type Settings = {
	maximum_height: point_graph.PointGraph,
	absorption_upforce: point_graph.PointGraph,
	pump_maxspeed: point_graph.PointGraph,
	minimum_height: number,
	maximum_ratio: number,
	maximum_delta_delta: number,
	maximum_delta: number,
	input_blend: number,
	pump_vertical_speed: number,
	maximum_crouch_from_deck: number,
	skateboard_damping: number,
	maximum_force: number,
	maximum_ground_force: number,
	absorption_factor: number,
	auto_pump: AutoPumpSettings,
}

-- Resolved physical publication fields. Offsets stay explicit until the
-- producer's domain identity is verified; callers must publish actual values.
export type Physical = {
	body_84: number,
	body_164: number,
	body_188: number,
	force_516: number,
	ground_force_520: number,
	minimum_crouch_528: number,
	deck_angle_532: number,
	animation_height_72: number,
}

export type Intents = {
	auto_pump_angle: number?,
	auto_pump_magnitude: number?,
	crouch: number?,
	hard_turn_crouch: number?,
	manual: number?,
	-- SkaterMotionGraph interface+108, used by both manual-crouch branches.
	motion_flag_108: boolean,
}

export type State = {
	absorbed_velocity: number,
	filtered_input: number,
	fraction: number,
	delta_fraction: number,
	player_pumping: boolean,
	auto_fraction: number,
	auto_state: number,
	auto_time: number,
	previous_angle: number,
	previous_magnitude: number,
	filtered_potential: number,
	pump_idle_time: number,
}

export type Output = { height: number, new_auto_pump: boolean, player_controlled_pump: boolean }

local function minimum(a: number, b: number): number
	return if f32(a - b) >= 0.0 then b else a
end
local function maximum(a: number, b: number): number
	return if f32(a - b) >= 0.0 then a else b
end
local function bound(v: number, lo: number, hi: number): number
	return minimum(hi, maximum(lo, v))
end
local function nonnegative(v: number): number
	return if -v >= 0.0 then 0.0 else v
end
local function unit(v: number): number
	return minimum(1.0, nonnegative(v))
end

local State = {}
crouching.State = State

function State.begin(physical: Physical, settings: Settings): State
	local maximum_ = evaluate(settings.maximum_height, physical.body_164)
	local fraction = f32(1.0 - unit(f32(f32(physical.animation_height_72 - settings.minimum_height) / f32(maximum_ - settings.minimum_height))))
	return {
		absorbed_velocity = 0.0,
		filtered_input = 0.0,
		fraction = fraction,
		delta_fraction = 0.0,
		player_pumping = false,
		auto_fraction = 0.0,
		auto_state = 0,
		auto_time = 0.0,
		previous_angle = 0.0,
		previous_magnitude = 0.0,
		filtered_potential = 0.0,
		pump_idle_time = 0.5,
	}
end

local K_3ecccccd = from_bits(0x3ecccccd)
local K_3ba3d70a = from_bits(0x3ba3d70a)
local K_3c888889 = from_bits(0x3c888889)

function State.update(self: State, p: Physical, intents: Intents, dt: number, s: Settings): Output
	local restoring = -evaluate(s.absorption_upforce, f32(1.0 - self.fraction))
	local board = bound(f32(-p.force_516 / s.maximum_force), -1.0, 1.0)
	self.absorbed_velocity = f32(self.absorbed_velocity + p.body_84)
	self.absorbed_velocity = f32(s.skateboard_damping * self.absorbed_velocity)
	if self.absorbed_velocity < 0.0 then
		board = -board
	end
	local ground = bound(f32(-p.ground_force_520 / s.maximum_ground_force), -1.0, 1.0)
	local absorption
	if board < 0.0 then
		absorption = if ground > 0.0 then f32(ground + board) else board
	else
		absorption = maximum(board, ground)
	end
	if absorption < 0.0 then
		if not (absorption < restoring) then
			absorption = restoring
		end
	else
		absorption = f32(absorption + restoring)
	end
	local angle = intents.auto_pump_angle or 0.0
	local magnitude = intents.auto_pump_magnitude or 0.0
	local a = s.auto_pump
	local started = math.abs(self.previous_angle) < a.intent_angle_region and self.previous_magnitude < a.intent_magnitude_start and math.abs(angle) < a.intent_angle_region and magnitude > a.intent_magnitude_start
	self.previous_angle = angle
	self.previous_magnitude = magnitude
	self.filtered_potential = mul_add(p.body_188, a.potential_blend, f32(f32(1.0 - a.potential_blend) * self.filtered_potential))
	local sufficient_potential = not (self.filtered_potential < a.potential_threshold)
	if started then
		self.auto_time = 0.0
		self.auto_state = 1
	end
	if self.auto_state == 1 and self.auto_time > a.crouch_time then
		self.auto_state = 2
	end
	local new_auto_pump = (self.auto_state == 1 or self.auto_state == 2) and self.fraction > a.sufficient_crouch and sufficient_potential
	if new_auto_pump then
		self.auto_state = 3
	end
	if (self.auto_state == 2 or self.auto_state == 3) and not (self.fraction > f32(a.standing_threshold + p.minimum_crouch_528)) then
		self.auto_state = 0
	end
	local st = self.auto_state
	if st == 0 then
		self.auto_fraction = 0.0
	elseif st == 1 then
		self.auto_fraction = minimum(evaluate(a.maximum_crouch, p.body_164), f32(a.crouch_speed + self.auto_fraction))
		self.auto_time = minimum(f32(a.crouch_time + 1.0), f32(dt + self.auto_time))
	elseif st == 2 then
		self.auto_fraction = nonnegative(f32(self.auto_fraction - a.rise_speed))
	elseif st == 3 then
		self.auto_fraction = nonnegative(f32(self.auto_fraction - a.pump_speed))
	end
	local crouch = intents.crouch or 0.0
	if not intents.motion_flag_108 then
		crouch = maximum(crouch, intents.hard_turn_crouch or 0.0)
	end
	if intents.motion_flag_108 and intents.manual ~= nil and intents.manual < 0.0 then
		crouch = maximum(crouch, K_3ecccccd)
	end
	local blend = unit(s.input_blend)
	self.filtered_input = mul_add(maximum(crouch, self.auto_fraction), blend, f32(f32(1.0 - blend) * self.filtered_input))
	if math.abs(self.filtered_input) < K_3ba3d70a then
		self.filtered_input = 0.0
	end
	local delta = f32(s.absorption_factor * absorption)
	if crouch > 0.0 or self.auto_fraction > 0.0 or (self.player_pumping and self.fraction > p.minimum_crouch_528) then
		self.player_pumping = true
		delta = maximum(f32(minimum(1.0, maximum(p.minimum_crouch_528, self.filtered_input)) - self.fraction), -s.maximum_delta)
		self.pump_idle_time = 0.0
	else
		self.player_pumping = false
		-- Native literal 820849C8, deliberately not graph delta time.
		self.pump_idle_time = f32(self.pump_idle_time + K_3c888889)
	end
	local player_controlled_pump = self.pump_idle_time < 0.5
	local minimum_delta = -f32(evaluate(s.pump_maxspeed, f32(1.0 - self.fraction)) * s.pump_vertical_speed)
	local maximum_delta = f32(evaluate(s.pump_maxspeed, self.fraction) * s.pump_vertical_speed)
	delta = bound(delta, minimum_delta, maximum_delta)
	self.delta_fraction = bound(delta, f32(self.delta_fraction - s.maximum_delta_delta), f32(s.maximum_delta_delta + self.delta_fraction))
	self.fraction = bound(f32(self.fraction + self.delta_fraction), p.minimum_crouch_528, 1.0)
	local from_deck = f32(s.maximum_crouch_from_deck * p.deck_angle_532)
	if from_deck > self.fraction then
		self.fraction = from_deck
	end
	local height_ratio = unit(mul_add(-s.maximum_ratio, self.fraction, 1.0))
	local maximum_height = evaluate(s.maximum_height, p.body_164)
	return {
		height = mul_add(f32(maximum_height - s.minimum_height), height_ratio, s.minimum_height),
		new_auto_pump = new_auto_pump,
		player_controlled_pump = player_controlled_pump,
	}
end

return crouching
