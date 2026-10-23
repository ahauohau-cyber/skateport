--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/push.rs (коммит 2e16697)
--
-- TU3 Toolkit_CalcPushAcceleration (`0x82D948B8`). Despite the native name,
-- the returned vector includes total body mass and is a force-queue payload.
-- It is queued with tag 3; deck inverse mass is applied by `0x82C03718`.

local rt = require("../../rt")
local force_queue = require("../physics/force_queue")

local f32 = rt.f32
local mul_add = rt.mul_add

type Vector3 = vector

local push = {}

export type PushInput = {
	flags_2468: number,
	flags_2472: number,
	target_speed: number,
	current_speed: number,
	absolute_body_speed: number,
	-- Input +2660, populated at 0x82C0140C by 0x82C06F58's sum of body
	-- masses. This is not a tunable push strength or direct velocity scale.
	scale: number,
	delta_seconds: number,
	direction: Vector3,
}

export type PushLimits = {
	maximum_pushable_speed: number,
	low_speed_change: number,
	high_speed_change: number,
}

export type PushAcceleration = {
	vector: Vector3,
	local_point: Vector3,
	-- Native output byte; set only when push is requested and flag 0x200 is set.
	suppressed: boolean,
}

local function default_acceleration(): PushAcceleration
	return { vector = vector.zero, local_point = vector.zero, suppressed = false }
end
push.default_acceleration = default_acceleration

function push.calculate_acceleration(input: PushInput, limits: PushLimits): PushAcceleration
	if bit32.band(input.flags_2468, 0x0200_0000) == 0 then
		return default_acceleration()
	end
	if bit32.band(input.flags_2472, 0x200) ~= 0 then
		local a = default_acceleration()
		a.suppressed = true
		return a
	end
	local gap = f32(input.target_speed - input.current_speed)
	-- 82D94930 bgt: unordered and both signed zeros take the zero branch.
	local speed_change = if gap > 0.0 then gap else 0.0
	local speed_fraction = f32(input.current_speed / limits.maximum_pushable_speed)
	-- 82D94960/68 are ordered fsel tests, not host clamp. Unordered ratios
	-- select the original ratio first, then1 on the upper test.
	local nonnegative = if -speed_fraction >= 0.0 then 0.0 else speed_fraction
	local fraction = if f32(1.0 - nonnegative) >= 0.0 then nonnegative else 1.0
	-- Skate 3 blends two limits here. Skate 2 uses a single limit.
	local limit = mul_add(f32(1.0 - fraction), limits.low_speed_change, f32(fraction * limits.high_speed_change))
	local below_lower = speed_change < -limit
	if speed_change > limit then
		speed_change = limit
	end
	if below_lower then
		speed_change = -limit
	end
	if f32(input.absolute_body_speed + speed_change) > limits.maximum_pushable_speed then
		local remaining = f32(limits.maximum_pushable_speed - input.absolute_body_speed)
		speed_change = if remaining >= 0.0 then remaining else 0.0
	end
	local force_magnitude = f32(f32(input.scale * speed_change) / input.delta_seconds)
	local a = default_acceleration()
	a.vector = vector.create(f32(input.direction.x * force_magnitude), f32(input.direction.y * force_magnitude), f32(input.direction.z * force_magnitude))
	return a
end

-- Standalone convenience for callers that explicitly need a fresh mass sum.
-- Input +2660 is populated by 0x82C0140C, and 0x82D391B0 appends the result.
-- The input scale is overwritten with the live body mass sum. No direct
-- velocity adjustment is made; the force consumer and solver own its effect.
-- Ground82D38800 instead consumes the already-produced Processed+2660 and
-- defers submission until after the manual branch; use grounded::propulsion
-- for that caller. This convenience does not reproduce Ground's scheduling.
function push.enqueue_push(input: PushInput, limits: PushLimits, inverse_masses: { number }, queue: any): PushAcceleration
	local copy = table.clone(input)
	copy.scale = force_queue.total_body_mass(inverse_masses)
	local output = push.calculate_acceleration(copy, limits)
	force_queue.BoardForceQueue.append(queue, { tag = 3, force_world = output.vector, point_body = output.local_point })
	return output
end

return push
