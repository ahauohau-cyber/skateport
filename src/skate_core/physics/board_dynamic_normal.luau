--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_dynamic_normal.rs (коммит 2e16697)
--
-- Dynamic wheel-response normal, original TU3 82C02388, with acceleration
-- history from82C082AC..8348. This is Ground64, distinct from wheel normals.

local rt = require("../../rt")
local board_ground = require("./board_ground")
local bmo = require("./board_motion_output")
local point_graph = require("../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local add, dot, inverse_length_squared, scale, subtract = bmo.add, bmo.dot, bmo.inverse_length_squared, bmo.scale, bmo.subtract
local PointGraph = point_graph.PointGraph

type Vector3 = vector

local UP = vector.create(0.0, 1.0, 0.0)
local ZERO = vector.zero

local board_dynamic_normal = {}

export type DynamicNormalSettings = {
	speed_damping: number,
	up_vector_damping: number,
	maximum_delta: number,
	speed_scale: number,
	maximum_delta_vs_speed: point_graph.PointGraph,
}

export type BoardDynamicNormal = {
	-- Skateboard112, published to Ground64.
	normal: Vector3,
	-- Skateboard128. The constructor really initializes this to UP.
	delta: Vector3,
	-- Skateboard144 and160, retained independently by the source.
	acceleration: Vector3,
	last_contact_normal: Vector3,
}

local BoardDynamicNormal = {}
board_dynamic_normal.BoardDynamicNormal = BoardDynamicNormal

-- ///82C00ED0 initializes112/128 to UP and144/160 to zero. The full board
-- ///reset82C0D680 ->82C00D68 clears all seven previous velocities.
function BoardDynamicNormal.new(): BoardDynamicNormal
	return { normal = UP, delta = UP, acceleration = ZERO, last_contact_normal = ZERO }
end

local function normalize_length(v: Vector3): (Vector3, number)
	local squared = dot(v, v)
	local inverse = inverse_length_squared(squared, 2)
	local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
	--830BD350's verified initializer is float1e-6. Source compares length.
	local normal = if length > from_bits(0x3586_37bd) then scale(v, inverse) else ZERO
	return normal, length
end

local function normalize(v: Vector3): Vector3
	local n = normalize_length(v)
	return n
end

function BoardDynamicNormal.update(self: BoardDynamicNormal, contacts: board_ground.BoardGroundState, gravity: Vector3, previous_ground_speed: number, settings: DynamicNormalSettings)
	--82C02344 runs Body::UpdatePostPhysics before82C0234C calls this
	--filter.82C02444/60/7C read the existing Body432/448/464 array.
	if contacts.wheel_contact_count == 0 then
		self.acceleration = ZERO
		return
	end
	local sum = ZERO
	--The original body tests780,781,782, then normalizes. There is no
	--fourth-wheel accumulation in this function; retain that distinction.
	for i = 1, 3 do
		if contacts.parts[i].in_contact then
			sum = subtract(add(sum, contacts.accelerations[i]), gravity)
		end
	end
	local target = normalize(sum)
	self.delta = scale(self.delta, settings.speed_damping)
	local error_ = scale(subtract(target, self.normal), settings.up_vector_damping)
	local direction, magnitude = normalize_length(error_)
	local maximum = f32(PointGraph.evaluate(settings.maximum_delta_vs_speed, f32(math.abs(previous_ground_speed) / settings.speed_scale)) * settings.maximum_delta)
	local nonnegative = if -magnitude >= -0.0 then 0.0 else magnitude
	local amount = if f32(maximum - nonnegative) >= -0.0 then nonnegative else maximum
	self.delta = vector.create(mul_add(direction.x, amount, self.delta.x), mul_add(direction.y, amount, self.delta.y), mul_add(direction.z, amount, self.delta.z))
	self.normal = normalize(add(self.normal, self.delta))
	self.last_contact_normal = contacts.overall_normal
end

return board_dynamic_normal
