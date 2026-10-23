--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/grind_surface/classify.rs (коммит 2e16697)
--
-- ROBLOX: `use super::*` -> типы GeometryType/GrindSurface и флаги объявлены
-- здесь и переэкспортируются из grind_surface/init.luau (иначе круговой require).

local rt = require("../../../../rt")
local m = require("../math")
local orientation = require("./orientation")
local trigonometry = require("../../../trigonometry")

local f32 = rt.f32
local from_bits = rt.from_bits
local fmin, fmax = rt.fmin, rt.fmax
local dot, sub, scale, cross = m.dot, m.sub, m.scale, m.cross
local length, inverse_length, normalize, reciprocal = m.length, m.inverse_length, m.normalize, m.reciprocal

type V = { number }

local classify = {}

-- ROBLOX: enum GeometryType (repr u32) -> числа.
classify.GeometryType = table.freeze({
	ThinRail = 0,
	FatRail = 1,
	Ledge = 2,
	Impossible = 3,
})
local GeometryType = classify.GeometryType

-- ROBLOX: impl GrindSurface { pub const ... }.
classify.FLAGS = table.freeze({
	INVALID = 0x8000_0000,
	CURB = 0x4000_0000,
	BLOCKED_CROSS_SECTION = 0x2000_0000,
	STAIR = 0x1000_0000,
	OPTIONAL_NORMAL_TEST = 0x0800_0000,
	OPTIONAL_DROP_TEST = 0x0400_0000,
})
local FLAGS = classify.FLAGS

export type GrindSurface = {
	center: V,
	far_points: { V },
	upmost_normal: V,
	direction: V,
	high_side: V,
	normal_limits: { number },
	kind: number,
	audio_surface: number,
	physics_surface: number,
	-- Native output +116. Preserve unnamed bits, rather than invent meaning.
	flags: number,
	-- 82C21828 evaluated from the geometric limits; distinct from +48 upmost.
	tilted_upmost_normal: V,
}

type ProbeHit = { fraction: number, position: V, normal: V, packed_surface: number }
type Hit = ProbeHit | false

local function is_curb(a: Hit, b: Hit, up: V, center: V): boolean
	if not a or not b then
		return false
	end
	if not (dot(up, a.normal) > f32(0.99) and dot(up, b.normal) > f32(0.99)) then
		return false
	end
	local ah = dot(sub(a.position, center), up)
	local bh = dot(sub(b.position, center), up)
	local high, low
	if ah >= bh then
		high, low = ah, bh
	else
		high, low = bh, ah
	end
	return high > -f32(0.035) and high < f32(0.035) and low > -f32(0.24) and low < -f32(0.2)
end

local function optional_normal_test(hit: ProbeHit, center: V, direction: V): boolean
	-- 82C1E170 subtracts ORIGINAL direction times a positive normalized dot.
	local component = dot(hit.normal, normalize(direction))
	local projected = if component > 0.0 then sub(hit.normal, scale(direction, component)) else hit.normal
	local normal = normalize(projected)
	if not (from_bits(0x3f66_6666) > normal[2]) then
		return false
	end
	local offset = sub(hit.position, center)
	offset[2] = 0.0
	return dot(offset, normal) > 0.0
end

local function unpack(surface: number): (number, number)
	return bit32.band(surface, 0x7f), bit32.band(bit32.rshift(surface, 7), 0x1f)
end

-- ROBLOX: кортеж (u32, u32) -> два значения; hits: [Option<ProbeHit>; 5] -> массив с false.
local function surface_info(kind: number, curb: boolean, hits: { Hit }): (number, number)
	if curb then
		return 4, 2
	end
	if kind == GeometryType.ThinRail then
		local h = hits[5]
		return (if h then bit32.band(h.packed_surface, 0x7f) else 11), 4
	end
	-- Pair priority 0/1, then 2/3, then 4. Equal heights select the second.
	for _, pair in { 1, 3 } do
		local a, b = hits[pair], hits[pair + 1]
		local selected: Hit
		if a and b then
			selected = if a.position[2] > b.position[2] then a else b
		else
			selected = a or b
		end
		if selected then
			return unpack(selected.packed_surface)
		end
	end
	local h = hits[5]
	if h then
		return unpack(h.packed_surface)
	end
	return 3, 1
end

-- 82C20ED4..82C213F4, including the helpers 82C21410/21558/216A0.
function classify.resolve(plan: any, hits: { Hit }, previous_flags: number): GrindSurface
	local h0, h1, h2, h3, h4, h5, supplied_h6 = hits[1], hits[2], hits[3], hits[4], hits[5], hits[6], hits[7]
	local h6: Hit = if #plan.probes == 7 then supplied_h6 else false
	local blocked = (if h0 and h1 then true else false) or (if h5 then true else false)
	local kind
	if blocked then
		kind = GeometryType.Impossible
	elseif h0 then
		kind = if h2 and h2.fraction < from_bits(0x3f26_6666) then GeometryType.Ledge else GeometryType.FatRail
	elseif h1 then
		kind = if h3 and h3.fraction < from_bits(0x3f26_6666) then GeometryType.Ledge else GeometryType.FatRail
	else
		kind = GeometryType.ThinRail
	end
	-- Native result high side uses unguarded normalization, not NormalizeSafe.
	local side = cross(m.up(), plan.direction)
	side = scale(side, inverse_length(dot(side, side)))
	local high_side = if not blocked and not h0 and h1 then scale(side, -1.0) else side
	local curb = kind == GeometryType.Ledge and is_curb(h2, h3, plan.upmost_normal, plan.center)
	local stair = false
	for _, h in { h0, h1 } do
		if h and bit32.band(h.packed_surface, 0xf80) == 0x400 then
			stair = true
		end
	end
	local optional_normal = if h6 then optional_normal_test(h6, plan.center, plan.direction) else false
	local optional_drop = if h6 then not (f32(h6.position[2] - plan.center[2]) > -1.0) else true
	local flags = bit32.band(
		previous_flags,
		bit32.bnot(bit32.bor(FLAGS.INVALID, FLAGS.CURB, FLAGS.STAIR, FLAGS.OPTIONAL_NORMAL_TEST, FLAGS.OPTIONAL_DROP_TEST))
	)
	if blocked then
		flags = bit32.bor(flags, FLAGS.BLOCKED_CROSS_SECTION)
	end
	if curb then
		flags = bit32.bor(flags, FLAGS.CURB)
	end
	if stair then
		flags = bit32.bor(flags, FLAGS.STAIR)
	end
	if optional_normal then
		flags = bit32.bor(flags, FLAGS.OPTIONAL_NORMAL_TEST)
	end
	if optional_drop then
		flags = bit32.bor(flags, FLAGS.OPTIONAL_DROP_TEST)
	end
	local audio_surface, physics_surface = surface_info(kind, curb, { h0, h1, h2, h3, h4 })
	local far_points = {
		if h2 then h2.position else plan.probes[3]["end"],
		if h3 then h3.position else plan.probes[4]["end"],
	}
	local negative_up = scale(plan.upmost_normal, -1.0)
	-- Native first computes lengths, then separately refines their reciprocals.
	-- No safe-normalize epsilon is introduced for the far-point directions.
	local angles = {}
	for i, point in far_points do
		local delta = sub(point, plan.center)
		local unit = scale(delta, reciprocal(length(delta)))
		angles[i] = trigonometry.acos(fmin(fmax(dot(negative_up, unit), -1.0), 1.0))
	end
	local half_pi = from_bits(0x3fc9_0fdb)
	local clearance = from_bits(0x3e8e_fa35)
	local normal_limits = {
		f32(f32(angles[1] + half_pi) + clearance),
		f32(f32(f32(from_bits(0x40c9_0fdb) - angles[2]) - half_pi) - clearance),
	}
	local tilted_upmost_normal = orientation.tilted_normal(plan.direction, plan.upmost_normal, normal_limits)
	return {
		center = plan.center,
		far_points = far_points,
		upmost_normal = plan.upmost_normal,
		direction = plan.direction,
		high_side = high_side,
		normal_limits = normal_limits,
		kind = kind,
		audio_surface = audio_surface,
		physics_surface = physics_surface,
		flags = flags,
		tilted_upmost_normal = tilted_upmost_normal,
	}
end

return classify
