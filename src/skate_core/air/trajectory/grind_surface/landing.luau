--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/grind_surface/landing.rs (коммит 2e16697)
--
-- Original S3 TU3 82C21930 after six-query completion, not the S2 type3 gate.
-- Query ownership stays with the caller; None means actual failed completion.

local rt = require("../../../../rt")
local m = require("../math")
local orientation = require("./orientation")
local classify = require("./classify")

local from_bits, to_bits = rt.from_bits, rt.to_bits
local dot, sub, scale, cross = m.dot, m.sub, m.scale, m.cross
local GeometryType = classify.GeometryType

type V = { number }

local landing = {}

-- Native PossibleGrindOrientations output offsets. The returned up-vector is
-- separate: 82C21930 can leave it and these vectors untouched on failure.
export type LandingOrientation = {
	kind: number, -- +0
	garbage: boolean, -- +4
	boardslide_dir: V, -- +16
	tipslide_dir: V, -- +32
	backslash_dir: V, -- +48
	high_side: V, -- +64
}

-- ROBLOX: в Rust у LandingOrientation нет конструктора; это помощник для копии (Copy).
landing.LandingOrientation = {
	clone = function(self: LandingOrientation): LandingOrientation
		return table.clone(self)
	end,
}

-- Native XOR toggles every sign bit, including W and signed zero.
local function negate(v: V): V
	local out = table.create(4) :: any
	for i = 1, 4 do
		out[i] = from_bits(bit32.bxor(to_bits(v[i]), 0x8000_0000))
	end
	return out
end

-- 82C21930: primitive endpoints and grind_position form a six-probe geometry
-- investigation (optional_probe=None). Pass its completed surface as Some;
-- when prepare returns None, pass None and retain the caller's cached vectors.
-- takeoff_position is original r5, grind_position r6; neither is a velocity.
-- Completed kind3 is deliberately NOT rejected here; the analyzer owns its
-- later type3 rejection. Do not replace it with S2 82CFCA88's early type gate.
-- ROBLOX: up: &mut V -> четыре элемента таблицы up переписываются на месте;
-- out: &mut LandingOrientation -> поля out меняются на месте.
function landing.update_landing_orientation(
	surface: classify.GrindSurface?,
	takeoff_position: V,
	grind_position: V,
	up: V,
	out: LandingOrientation
)
	if surface == nil then
		out.kind = GeometryType.Impossible
		out.garbage = true
		return
	end
	if bit32.btest(surface.flags, classify.FLAGS.INVALID) then
		-- 82C21A10..82C21A5C: completed but invalid geometry has its own
		-- fully written fallback, distinct from the no-completion branch.
		local x = { 1.0, 0.0, 0.0, 0.0 }
		up[1], up[2], up[3], up[4] = 0.0, 1.0, 0.0, 0.0
		out.kind = GeometryType.ThinRail
		out.garbage = true
		out.boardslide_dir = x
		out.tipslide_dir = x
		out.backslash_dir = negate(x)
		out.high_side = x
		return
	end

	local tilted = orientation.tilted_normal(surface.direction, surface.upmost_normal, surface.normal_limits)
	up[1], up[2], up[3], up[4] = tilted[1], tilted[2], tilted[3], tilted[4]
	out.kind = surface.kind
	out.garbage = false
	out.high_side = surface.high_side
	-- Original cross products are not followed by normalization.
	local side = cross(surface.upmost_normal, surface.direction)
	local tipslide_angle = from_bits(0x3eb2_b8c3) -- 822F8618
	if surface.kind == GeometryType.ThinRail then
		out.boardslide_dir = side
		local oriented = if dot(side, sub(takeoff_position, grind_position)) > 0.0 then side else negate(side)
		local axis = cross(oriented, surface.upmost_normal)
		out.tipslide_dir = orientation.rotate(axis, oriented, tipslide_angle)
		out.backslash_dir = orientation.rotate(axis, oriented, from_bits(0x401a_25c2)) -- 822F93B8, stored pi-minus-backslash
	else
		local axis = cross(side, surface.upmost_normal)
		out.boardslide_dir = if surface.kind == GeometryType.FatRail then side else cross(m.copy(up), surface.direction)
		local sign = if dot(side, surface.high_side) > 0.0 then 1.0 else -1.0
		-- Original sign vectors broadcast across all four lanes. These are
		-- multiplies, unlike the XOR sign inversion in the thin-rail branch.
		out.backslash_dir = orientation.rotate(scale(axis, sign), scale(side, sign), from_bits(0x3f3b_a866)) -- 822F8614
		out.tipslide_dir = orientation.rotate(scale(axis, -sign), scale(side, -sign), tipslide_angle)
	end
end

return landing
