--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_forces/launch.rs (коммит 2e16697)
--
-- LaunchSkateboard82D73AB0; S2 named counterpart82DCB3A8.
-- S3 replaces tunables with literals; energy cost is0.6, not ZIP's0.2.
-- ROBLOX: `use super::{length, reciprocal, scale, sub}` -> launch.parent.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local manager = require("../grind_contact/manager")

local f32 = rt.f32
local mul_add = rt.mul_add
local dot3 = native_arithmetic.dot3

type V = { number }

local launch = {}
launch.parent = (nil :: any)

export type Input = {
	velocity_400: V,
	position_112: V,
	-- Low-energy zero-balance side selection uses CURRENT1120, not cache96.
	current_point_1120: V,
	balance_2800: number,
	geometry_side_jump: number,
	vertical_jump: number,
}

export type Output = {
	velocity: V,
	-- Complete retained cache, to replace the SAME owner updated by82D739D8.
	jumper: manager.Jumper,
	flags_2476_to_or: number,
}

local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end

-- ROBLOX: jumper передаётся по значению (Copy) -> копия таблицы.
function launch.launch(jumper_in: manager.Jumper, input: Input): Output
	local P = launch.parent
	local sub, scale, length, reciprocal = P.sub, P.scale, P.length, P.reciprocal
	local jumper = table.clone(jumper_in)
	local geometry = jumper.geometry
	local normal = geometry.normal
	local candidate = {}
	if jumper.family == 2 or jumper.family == 4 then
		local across = cross(normal, geometry.direction)
		local outward = if dot3(across, sub(input.position_112, geometry.point)) > 0.0 then across else scale(across, -1.0)
		local amount = if jumper.family == 4 then -f32(0.1093) else f32(0.291)
		for i = 1, 4 do
			candidate[i] = f32(normal[i] + f32(outward[i] * amount))
		end
	else
		for i = 1, 4 do
			candidate[i] = mul_add(geometry.upmost[i], 0.5, f32(normal[i] * 0.5))
		end
	end
	local magnitude = length(candidate)
	if magnitude > f32(0.1) then
		normal = scale(candidate, reciprocal(magnitude))
	end
	local planar = sub(input.velocity_400, scale(normal, dot3(input.velocity_400, normal)))
	local vertical = f32(input.vertical_jump * f32(1.03))
	local base = {}
	for i = 1, 4 do
		base[i] = mul_add(normal[i], vertical, planar[i])
	end
	local across = cross(geometry.direction, normal)
	local balance = input.balance_2800
	local low_energy = jumper.energy < f32(0.31)
	local k = f32(0.42)
	if low_energy then
		if balance < 0.0 then
			if f32(balance - -k) >= 0.0 then
				balance = -k
			end
		elseif balance > 0.0 then
			if not (f32(balance - k) >= 0.0) then
				balance = k
			end
		else
			balance = if dot3(sub(input.position_112, input.current_point_1120), across) > 0.0 then k else -k
		end
		jumper.cooldown = 10
	end
	local side = if geometry.geometry_kind ~= 0 then input.geometry_side_jump else 0.0
	local lateral = sub(scale(across, f32(balance * f32(1.8))), scale(geometry.high_side, side))
	local m2 = length(lateral)
	if m2 > f32(1.8) then
		lateral = scale(lateral, f32(f32(1.8) / m2))
	end
	local velocity = {}
	for i = 1, 4 do
		velocity[i] = f32(base[i] + lateral[i])
	end
	jumper.launched = true
	local energy = f32(jumper.energy - f32(0.6))
	jumper.energy = if -energy >= 0.0 then 0.0 else energy
	return { velocity = velocity, jumper = jumper, flags_2476_to_or = if low_energy then 0x0200_0000 else 0 }
end

return launch
