--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/ground_orientation.rs (коммит 2e16697)
--
-- Riding up-vector and ground-normal calculation in TU3 Reckoning82D8C8F0.
-- Inputs are assembled by82D8E5C0; this module owns the three persistent
-- filters, target, acceleration and damping. Transform/tilt publication is a
-- separate downstream calculation. Numerical primitives remain unverified
-- against independent hardware captures.

local rt = require("../../rt")
local ground_normal_mod = require("../air/ground_normal")
local point_graph = require("../point_graph")
local board_ground = require("../physics/board_ground")
local bmo = require("../physics/board_motion_output")
local native_arithmetic = require("../physics/native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local GroundNormalFilter = ground_normal_mod.GroundNormalFilter
local PointGraph = point_graph.PointGraph
local angle_between = board_ground.angle_between
local add, subtract, scale, dot, inverse_length_squared, length =
	bmo.add, bmo.subtract, bmo.scale, bmo.dot, bmo.inverse_length_squared, bmo.length

type Vector3 = vector
type F4 = { number }

local ground_orientation = {}

local UP = vector.create(0.0, 1.0, 0.0)
local EPSILON = from_bits(0x3586_37BD) -- 82F826F8 installs82181A88 at830BD350.

export type GroundOrientationSettings = {
	ground_normal_smoothing: F4,
	up_vector_smoothing_slow: F4,
	up_vector_smoothing_fast: F4,
	dynamic_up_vs_ground_y: point_graph.PointGraph,
	ground_vector_blend: point_graph.PointGraph,
	-- The eight x/y pairs inside PointNegGraphData8 at layout256+16.
	-- 82D8CF10 calls ordinary PointGraphEval directly, ignoring its sign mode.
	deck_angle_usage_vs_speed: point_graph.PointGraph,
	up_vector_smoothing_vs_speed: point_graph.PointGraph,
	up_vector_max_delta_vs_speed: point_graph.PointGraph,
	ground_blend_max_delta: number,
	up_vector_max_acceleration: number,
	anti_wobble_damping: number,
	extra_side_damping: number,
	minimum_wheels_for_ground_blend: number,
}

export type GroundOrientationInput = {
	-- Processed752, copied from Skeleton11008 in82BD8918.
	com_to_deck: Vector3,
	-- Processed464 <- Ground96 (retained wheel normal).
	ground_normal: Vector3,
	-- Processed528 <- Ground64 (overall normal).
	dynamic_up: Vector3,
	-- Processed2652 <- SkateboardMotion160 (raw deck speed).
	speed: number,
	wheel_contact_count: number,
	-- Processed2720; the native deck-angle gate tests exact zero.
	animation_balance: number,
	-- Processed2616 input to DeckAngleUsageVsSpeed.
	deck_angle_curve_input: number,
	-- Processed80/96: current board transform Y/Z.
	board_up: Vector3,
	board_forward: Vector3,
	-- Processed160: effective board transform Z.
	effective_board_forward: Vector3,
	-- The previous complete Reckoning transform X (native816), including flip.
	previous_reckoning_right: Vector3,
	-- Processed2476 bit30, the coffin restriction.
	prevent_up_behind_board: boolean,
}

export type GroundOrientation = {
	dynamic_up: Vector3,
	up: Vector3,
	target: Vector3,
	up_velocity: Vector3,
	ground_normal: Vector3,
	ground_blend: number,
	ground_filter: ground_normal_mod.GroundNormalFilter,
	slow_filter: ground_normal_mod.GroundNormalFilter,
	fast_filter: ground_normal_mod.GroundNormalFilter,
}

local GroundOrientation = {}
ground_orientation.GroundOrientation = GroundOrientation

local function lanes(v: Vector3): F4
	return { v.x, v.y, v.z, 0.0 }
end
local function to_vector(v: F4): Vector3
	return vector.create(v[1], v[2], v[3])
end
local function fsel(test: number, positive: number, negative: number): number
	if test >= -0.0 then
		return positive
	end
	return negative
end
local function unit_saturate(value: number): number
	value = fsel(-value, 0.0, value)
	return fsel(f32(1.0 - value), value, 1.0)
end
local function madd(v: Vector3, factor: number, offset: Vector3): Vector3
	return vector.create(mul_add(v.x, factor, offset.x), mul_add(v.y, factor, offset.y), mul_add(v.z, factor, offset.z))
end
local function blend(from: Vector3, to: Vector3, amount: number): Vector3
	return madd(to, amount, scale(from, f32(1.0 - amount)))
end
local function cross(a: Vector3, b: Vector3): Vector3
	return vector.create(
		mul_add(-a.z, b.y, f32(a.y * b.z)),
		mul_add(-a.x, b.z, f32(a.z * b.x)),
		mul_add(-a.y, b.x, f32(a.x * b.y))
	)
end
local function normalize_safe(value: Vector3, fallback: Vector3): Vector3
	local squared = dot(value, value)
	local inverse = inverse_length_squared(squared, 2)
	local magnitude = if squared == 0.0 then 0.0 else f32(squared * inverse)
	if magnitude > EPSILON then
		return scale(value, inverse)
	end
	return fallback
end

-- Complete ClampVectorWithinMaxLength82BD3D90.
-- pub(crate) fn clamp_length(value: Vector3, maximum: f32) -> Vector3
function ground_orientation.clamp_length(value: Vector3, maximum: number): Vector3
	local magnitude = length(value)
	if magnitude < from_bits(0x3780_0000) then
		return value
	end
	local bounded = fsel(f32(maximum - magnitude), magnitude, maximum)
	local inverse = native_arithmetic.reciprocal_estimate(magnitude)
	for _ = 1, 2 do
		local error = mul_add(-inverse, magnitude, 1.0)
		inverse = mul_add(inverse, error, inverse)
	end
	return scale(scale(value, bounded), inverse)
end
local clamp_length = ground_orientation.clamp_length

-- Native82D8DA68 filter history and82D8C3A8/82D8BE38 vector seeds.
function GroundOrientation.new(settings: GroundOrientationSettings): GroundOrientation
	return {
		dynamic_up = UP,
		up = UP,
		target = UP,
		up_velocity = vector.zero,
		ground_normal = UP,
		ground_blend = 0.0,
		ground_filter = GroundNormalFilter.initialized(settings.ground_normal_smoothing, lanes(UP)),
		slow_filter = GroundNormalFilter.initialized(settings.up_vector_smoothing_slow, lanes(UP)),
		fast_filter = GroundNormalFilter.initialized(settings.up_vector_smoothing_fast, lanes(UP)),
	}
end

-- Reset82D8C3A8 resets these vectors/scalars but preserves filter history.
function GroundOrientation.reset(self: GroundOrientation)
	self.dynamic_up = UP
	self.up = UP
	self.target = UP
	self.up_velocity = vector.zero
	self.ground_normal = UP
	self.ground_blend = 0.0
end

local F32_0_5 = 0.5
local ALPHA_SCALE = from_bits(0x3A83_126F)

-- Complete up/normal branch82D8C934..82D8D650, before CalculateTransform,
-- CalculateDynamicLean and CalculateTilt. BodySpin runs before this stage.
function GroundOrientation.update(self: GroundOrientation, settings: GroundOrientationSettings, input: GroundOrientationInput)
	local normalized_com = normalize_safe(input.com_to_deck, vector.zero)
	local amount = PointGraph.evaluate(settings.dynamic_up_vs_ground_y, input.ground_normal.y)
	local prediction = normalize_safe(blend(self.ground_normal, add(UP, subtract(input.dynamic_up, normalized_com)), amount), vector.zero)
	self.dynamic_up = input.dynamic_up
	self.ground_normal = to_vector(GroundNormalFilter.update(self.ground_filter, settings.ground_normal_smoothing, lanes(input.ground_normal)))
	local horizontal_axis = cross(UP, self.ground_normal)
	if dot(horizontal_axis, horizontal_axis) > ALPHA_SCALE then
		local axis = scale(horizontal_axis, inverse_length_squared(dot(horizontal_axis, horizontal_axis), 2))
		local projected = subtract(prediction, scale(axis, dot(axis, prediction)))
		local prediction_to_ground = angle_between(projected, self.ground_normal)
		local prediction_to_up = angle_between(projected, UP)
		local ground_to_up = angle_between(self.ground_normal, UP)
		local old_up_to_up = angle_between(self.up, UP)
		local candidate = if prediction_to_ground < prediction_to_up then self.ground_normal else UP
		if prediction_to_ground < ground_to_up and prediction_to_up < ground_to_up then
			candidate = projected
		end
		local alpha = f32(f32(input.speed + 1.0) * ALPHA_SCALE)
		if not (old_up_to_up > ground_to_up or prediction_to_up > old_up_to_up) then
			candidate = madd(self.up, f32(1.0 - alpha), scale(candidate, alpha))
		end
		local slope = unit_saturate(f32(ground_to_up * from_bits(0x3EA2_F983)))
		local target_blend = PointGraph.evaluate(settings.ground_vector_blend, slope)
		if input.wheel_contact_count <= settings.minimum_wheels_for_ground_blend then
			target_blend = 0.0
		end
		local delta = f32(target_blend - self.ground_blend)
		local lower = fsel(f32(-settings.ground_blend_max_delta - delta), -settings.ground_blend_max_delta, delta)
		self.ground_blend = f32(self.ground_blend + fsel(f32(settings.ground_blend_max_delta - lower), lower, settings.ground_blend_max_delta))
		self.target = normalize_safe(blend(candidate, self.ground_normal, self.ground_blend), vector.zero)
	else
		self.target = self.ground_normal
	end
	if input.wheel_contact_count >= 2 and input.animation_balance == 0.0 then
		local usage = PointGraph.evaluate(settings.deck_angle_usage_vs_speed, input.deck_angle_curve_input)
		local axis = normalize_safe(cross(input.board_forward, self.ground_normal), vector.zero)
		local deck_up = normalize_safe(subtract(input.board_up, scale(axis, dot(input.board_up, axis))), vector.zero)
		self.target = normalize_safe(blend(self.target, deck_up, usage), vector.zero)
	end
	local slow = normalize_safe(to_vector(GroundNormalFilter.filter_raw(self.slow_filter, settings.up_vector_smoothing_slow, lanes(self.target))), vector.zero)
	local fast = normalize_safe(to_vector(GroundNormalFilter.filter_raw(self.fast_filter, settings.up_vector_smoothing_fast, lanes(self.target))), vector.zero)
	local speed_fraction = f32(input.speed * from_bits(0x3DCC_CCCD))
	local mix = PointGraph.evaluate(settings.up_vector_smoothing_vs_speed, speed_fraction)
	local filtered = normalize_safe(blend(slow, fast, mix), vector.zero)
	local max_delta = f32(PointGraph.evaluate(settings.up_vector_max_delta_vs_speed, speed_fraction) * from_bits(0x3E4C_CCCD))
	local difference = subtract(filtered, self.up)
	local magnitude = length(difference)
	local bounded = fsel(f32(magnitude - max_delta), max_delta, magnitude)
	local stepped = normalize_safe(madd(normalize_safe(difference, vector.zero), bounded, self.up), vector.zero)
	local desired_velocity = subtract(stepped, self.up)
	local acceleration = clamp_length(
		subtract(desired_velocity, self.up_velocity),
		f32(settings.up_vector_max_acceleration * from_bits(0x3C88_8889))
	)
	self.up_velocity = add(self.up_velocity, acceleration)
	local side = scale(input.previous_reckoning_right, dot(self.up_velocity, input.previous_reckoning_right))
	self.up_velocity = madd(side, settings.extra_side_damping, subtract(self.up_velocity, side))
	local unnormalized = add(self.up, self.up_velocity)
	self.up = normalize_safe(unnormalized, unnormalized)
	if 0.0 > dot(self.up_velocity, desired_velocity) then
		self.up_velocity = scale(self.up_velocity, settings.anti_wobble_damping)
	end
	if input.prevent_up_behind_board and dot(self.up, input.effective_board_forward) < 0.0 then
		local s = cross(self.up, input.effective_board_forward)
		self.up = normalize_safe(cross(input.effective_board_forward, s), self.up)
		self.up_velocity = scale(self.up_velocity, F32_0_5)
	end
	GroundNormalFilter.publish_current(self.slow_filter, lanes(self.up))
	GroundNormalFilter.publish_current(self.fast_filter, lanes(self.up))
end

-- ROBLOX: #[derive(Clone)].
function GroundOrientation.clone(self: GroundOrientation): GroundOrientation
	local c = table.clone(self)
	c.ground_filter = GroundNormalFilter.clone(self.ground_filter)
	c.slow_filter = GroundNormalFilter.clone(self.slow_filter)
	c.fast_filter = GroundNormalFilter.clone(self.fast_filter)
	return c
end

return ground_orientation
