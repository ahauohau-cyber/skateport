--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_forces/release.rs (коммит 2e16697)
--
-- Exit nudge82D3F850 / S2 82D85330. Family dispatch remains separate.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local dot3 = native_arithmetic.dot3

type V = { number }

local release = {}

export type Input = {
	position: V,
	point: V,
	across: V,
	normal: V,
	velocity: V,
	geometry_kind: number,
	high_side: V,
	force_across: boolean,
	-- Original r7. It is independent of r8/force_across; slides suppress lift.
	enable_lift: boolean,
	strength: number,
	speed_limit: number,
	lift: number,
}

local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end

-- None means no AddForce call, including no accumulator wakeup.
function release.force(input: Input): V?
	local outward
	if input.force_across or input.geometry_kind == 0 then
		outward = scale(input.across, if dot3(input.across, sub(input.position, input.point)) > 0.0 then 1.0 else -1.0)
	else
		outward = scale(input.high_side, -1.0)
	end
	if not (dot3(input.velocity, outward) < input.speed_limit) then
		return nil
	end
	local lateral = scale(outward, input.strength)
	if not input.enable_lift then
		return lateral
	end
	local upward = f32(rt.fmax(input.normal[2], 0.0) * input.lift)
	local out = {}
	for i = 1, 4 do
		out[i] = mul_add(input.normal[i], upward, lateral[i])
	end
	return out
end

return release
