--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/grind_surface.rs (коммит 2e16697)
--
-- Static geometry investigation from original S3 TU3 82C20728/82C20C08.
-- Query execution is supplied by the world owner; a miss is not missing data.
-- No moving-object observations or authored material codes are synthesized.
-- ROBLOX: Option<ProbeHit> внутри массива hits -> ProbeHit или false;
-- enum GeometryType (repr u32) -> числа 0..3 (GeometryType.ThinRail и т.д.).

local rt = require("../../../rt")
local m = require("./math")
local classify = require("@self/classify")
local orientation = require("@self/orientation")
local landing = require("@self/landing")

local f32 = rt.f32
local from_bits = rt.from_bits
local dot, sub, add, scale, cross, madd = m.dot, m.sub, m.add, m.scale, m.cross, m.madd
local length, inverse_length = m.length, m.inverse_length

local grind_surface = {}

grind_surface.update_landing_orientation = landing.update_landing_orientation
grind_surface.LandingOrientation = landing.LandingOrientation
export type LandingOrientation = landing.LandingOrientation

export type V = { number }

export type InvestigationInput = {
	start: V,
	["end"]: V,
	reference: V,
	-- Input +48, enabled by input byte +64: a six-unit world-down probe.
	optional_probe: V?,
	-- physics_grinds layout +636, supplied from the stock collection.
	deck_center_to_truck: number,
}

export type Probe = { start: V, ["end"]: V, radius: number }

export type ProbeHit = {
	fraction: number,
	position: V,
	normal: V,
	-- Original query result +100, NOT a rendering tag or triangle index.
	packed_surface: number,
}

export type Investigation = {
	center: V,
	upmost_normal: V,
	direction: V,
	probes: { Probe },
}

grind_surface.GeometryType = classify.GeometryType
export type GeometryType = number

export type GrindSurface = classify.GrindSurface

local GrindSurface = {}
grind_surface.GrindSurface = GrindSurface
GrindSurface.INVALID = classify.FLAGS.INVALID
GrindSurface.CURB = classify.FLAGS.CURB
GrindSurface.BLOCKED_CROSS_SECTION = classify.FLAGS.BLOCKED_CROSS_SECTION
GrindSurface.STAIR = classify.FLAGS.STAIR
GrindSurface.OPTIONAL_NORMAL_TEST = classify.FLAGS.OPTIONAL_NORMAL_TEST
GrindSurface.OPTIONAL_DROP_TEST = classify.FLAGS.OPTIONAL_DROP_TEST

-- 82C20C08's no-submission output; not an artificial startup blocker.
local function not_submitted(input: InvestigationInput): GrindSurface
	local distance = input.deck_center_to_truck
	local x = { 1.0, 0.0, 0.0, 0.0 }
	local z = { 0.0, 0.0, 1.0, 0.0 }
	return {
		center = input.reference,
		far_points = { madd(x, distance, input.reference), sub(input.reference, scale(x, distance)) },
		upmost_normal = z,
		direction = z,
		high_side = z,
		normal_limits = { 0.0, 0.0 },
		kind = classify.GeometryType.Impossible,
		audio_surface = 3,
		physics_surface = 1,
		flags = GrindSurface.INVALID,
		tilted_upmost_normal = orientation.tilted_normal(z, z, { 0.0, 0.0 }),
	}
end
GrindSurface.not_submitted = not_submitted

-- 82C20728: six fixed descriptors and the optional seventh descriptor.
-- Returns None exactly for the native inadequate-up-vector gate.
-- ROBLOX: None -> nil.
function grind_surface.prepare(input: InvestigationInput): Investigation?
	local delta = sub(input["end"], input.start)
	local raw_up = cross(delta, cross(m.up(), delta))
	local up_length = length(raw_up)
	local function retain_normalized(v: V): V
		local square = dot(v, v)
		local inverse = inverse_length(square)
		local magnitude = if square == 0.0 then 0.0 else f32(square * inverse)
		if magnitude > from_bits(0x3586_37bd) then
			return scale(v, inverse)
		end
		return v
	end
	local up = retain_normalized(raw_up)
	local direction = retain_normalized(delta)
	if up_length < from_bits(0x3727_c5ac) then
		return nil
	end
	local projected = madd(direction, dot(sub(input.reference, input.start), direction), input.start)
	local center = sub(input.reference, sub(input.reference, projected))
	local side = cross(up, direction)
	local short_up = scale(up, from_bits(0x3d23_d70a))
	local near_side = scale(side, from_bits(0x3db8_51ec))
	local far_side = scale(side, input.deck_center_to_truck)
	local far_up = scale(up, f32(input.deck_center_to_truck * from_bits(0x3f87_ae14)))
	local raised = scale(up, from_bits(0x3db8_51ec))
	local function line(at: V, half: V, radius: number): Probe
		return { start = add(at, half), ["end"] = sub(at, half), radius = radius }
	end
	local probes = {
		line(add(center, near_side), short_up, 0.0),
		line(sub(center, near_side), short_up, 0.0),
		line(add(center, far_side), far_up, 0.0),
		line(sub(center, far_side), far_up, 0.0),
		line(center, short_up, 0.0),
		line(add(center, raised), near_side, from_bits(0x3a83_126f)),
	}
	local start = input.optional_probe
	if start ~= nil then
		table.insert(probes, { start = start, ["end"] = add(start, { 0.0, -6.0, 0.0, 0.0 }), radius = 0.0 })
	end
	return { center = center, upmost_normal = up, direction = direction, probes = probes }
end

-- Full synchronous host equivalent of prepare/submit/wait/read/classify.
-- The callback must provide the original nearest-hit contract and packed
-- surface code for each probe, honoring its world-query filtering context.
-- ROBLOX: query(index, probe) -> ProbeHit? (индекс с нуля); ошибки — rt.raise.
function grind_surface.investigate(input: InvestigationInput, query: (number, Probe) -> ProbeHit?): GrindSurface
	local plan = grind_surface.prepare(input)
	if plan == nil then
		return not_submitted(input)
	end
	local hits: { ProbeHit | false } = table.create(7, false)
	for index, probe in plan.probes do
		hits[index] = query(index - 1, probe) or false
	end
	return classify.resolve(plan, hits, 0)
end

-- Explicit result processing also permits a native-style reused output flag
-- word. Bit29 is set on obstruction, not cleared on the other native branch.
function grind_surface.resolve(plan: Investigation, hits: { ProbeHit | false }, previous_flags: number): GrindSurface
	return classify.resolve(plan, hits, previous_flags)
end

-- ROBLOX: доступ к приватным модулям для тестов (#[cfg(test)] mod tests).
grind_surface.orientation = orientation

return grind_surface
