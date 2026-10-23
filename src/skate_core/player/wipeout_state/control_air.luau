--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/control_air.rs (коммит 2e16697)
--
-- Original alternate air-control82D3DD40, including its contact early return.

local rt = require("../../../rt")
local m = require("./math")
local data = require("./data")
local torque = require("./torque")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits

type V = m.V

local control_air = {}

local UP = { 0.0, 1.0, 0.0, 0.0 }
local ZERO = { 0.0, 0.0, 0.0, 0.0 }

function control_air.update(state: data.State, body: any, physical_com: V, input: { number }, contact: boolean): boolean
	local spine = m.normalize_or(m.sub(body.record.pose[12][4], body.record.pose[24][4]), ZERO)
	state.angular_velocity = torque.angular_velocity(body.record, body.definition.animation_masses.fractional)
	if contact then
		return false
	end
	local direction = m.normalize_or(state.velocity, ZERO)
	local sideways = m.normalize_or(m.cross(UP, spine), ZERO)
	sideways[2] = 0.0
	sideways = m.normalize_or(sideways, ZERO)
	local velocity_side = m.cross(UP, direction)
	if m.dot(velocity_side, sideways) < 0.0 then
		sideways = m.scale(sideways, -1.0)
	end
	local plane_normal = m.normalize_or(velocity_side, ZERO)
	local projected = m.sub(spine, m.scale(plane_normal, m.dot(plane_normal, spine)))
	projected = m.normalize_or(projected, ZERO)
	local automatic = m.scale(m.cross(spine, projected), 0.5)
	local hips_up = body.record.pose[24][2]
	if math.abs(input[1]) < 0.5 and hips_up[2] < 0.0 then
		local p2 = m.sub(hips_up, m.scale(plane_normal, m.dot(plane_normal, hips_up)))
		p2 = m.normalize_or(p2, ZERO)
		automatic = m.madd(m.cross(hips_up, p2), 0.5, automatic)
	end
	-- Both original scalar limits820993E8/EC are8 degrees.
	local limit = f32(8.0 * from_bits(0x3C8E_FA35))
	local side = m.scale(sideways, f32(limit * input[2]))
	local negative_spine = {}
	for i = 1, 4 do
		negative_spine[i] = from_bits(bit32.bxor(to_bits(spine[i]), 0x8000_0000))
	end
	local target = m.add(m.madd(negative_spine, f32(limit * input[1]), side), automatic)
	target = m.scale(target, from_bits(0x426F_FFFF))
	local delta = m.scale(m.scale(m.sub(target, state.angular_velocity), from_bits(0x4019_999A)), from_bits(0x3C88_8889))
	torque.apply(body, physical_com, m.limit_length(delta, 0.5))
	return true
end

return control_air
