--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_forces/slide.rs (коммит 2e16697)
--
-- Translation branches82D419A0/82D41438; S2 boardslide82D90970.
-- ROBLOX: enum Slide -> строка "Boardslide" | "Darkslide"; Vec<V> -> массив.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")

local f32 = rt.f32
local dot3 = native_arithmetic.dot3

type V = { number }

local slide = {}

export type Slide = "Boardslide" | "Darkslide"

-- All vectors are the physical-state/processed observations. Preparing-jump
-- is the retained state byte241, not a newly sampled analog input.
export type Input = {
	position: V,
	point: V,
	direction: V,
	across: V,
	velocity: V,
	translation_2796: number,
	total_mass_2660: number,
	-- Source global update frequency, not an invented fixed60 or render rate.
	update_frequency: number,
	preparing_jump: boolean,
	geometry_kind: number,
}

local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end

-- Forces at the processed deck position, in original application order.
-- The caller applies these directly, not through the21-entry tagged queue.
function slide.control(kind: Slide, input: Input): { V }
	local position, point, direction, across, velocity = input.position, input.point, input.direction, input.across, input.velocity
	local translation, mass = input.translation_2796, input.total_mass_2660
	local offset = dot3(sub(position, point), across)
	local inward = scale(across, if offset > 0.0 then -1.0 else 1.0)
	if input.preparing_jump then
		if math.abs(offset) > f32(0.12) then
			return { scale(inward, 201.0) }
		end
		return {}
	end
	local translation_strength
	if kind == "Boardslide" then
		translation_strength = 25.0
	else
		translation_strength = f32(f32(1.0 - f32(math.abs(offset) * 6.25)) * 40.0)
	end
	local translate = scale(across, f32(translation * translation_strength))
	if input.geometry_kind == 2 then
		return { translate }
	end
	local perpendicular = sub(velocity, scale(direction, dot3(velocity, direction)))
	if math.abs(offset) > f32(0.16) then
		local forces = { scale(inward, 10.0) }
		if dot3(inward, perpendicular) < 0.0 then
			local stop = scale(perpendicular, -f32(mass * input.update_frequency))
			stop[2] = 0.0
			table.insert(forces, stop)
		end
		return forces
	end
	local damping = scale(perpendicular, -20.0)
	damping[2] = 0.0
	return { translate, damping }
end

return slide
