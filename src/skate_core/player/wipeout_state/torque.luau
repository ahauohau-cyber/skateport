--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/torque.rs (коммит 2e16697)
--
-- Original SkeletonState angular estimate82BEC0E8 and torque82BE3B58.

local rt = require("../../../rt")
local m = require("./math")
local skeleton_body = require("../../physics/skeleton_body")

local from_bits = rt.from_bits
local SkeletonBody = skeleton_body.SkeletonBody

type V = m.V

local torque = {}

-- 4656 contains the same fractional masses used by physical COM publication:
-- original Init82BEBAA8 divides each4560 mass by total5216 at82BEBB80.
function torque.angular_velocity(record: any, fractional: { number }): V
	local result = { 0.0, 0.0, 0.0, 0.0 }
	for part = 1, 23 do
		local radial = m.sub(record.positions[part + 1], record.centre_of_mass)
		local velocity = m.sub(record.velocities[part + 1], record.centre_of_mass_velocity)
		local squared = m.dot(radial, radial)
		if squared > from_bits(0x38D1_B717) then
			local term = m.scale(m.cross(radial, velocity), m.reciprocal(squared))
			result = m.madd(term, fractional[part + 1], result)
		end
	end
	return result
end

-- 82BE3B58 converts the control magnitude and direction into original
-- per-part displacement accumulators. Actual solved velocities remain intact.
function torque.apply(body: any, physical_com: V, control: V)
	local magnitude = m.length(control)
	for part = 1, 23 do
		local radial = m.sub(body.record.pose[part + 1][4], physical_com)
		if m.dot(radial, radial) > rt.f32(0.001) then
			local tangent = m.normalize_or(m.cross(control, radial), { 0.0, 0.0, 0.0, 0.0 })
			SkeletonBody.apply_part_displacement(body, part, m.scale(tangent, magnitude))
		end
	end
end

return torque
