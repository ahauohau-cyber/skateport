--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/centre_of_mass_filter.rs (коммит 2e16697)
--
-- Physical-output COM conditioning: original TU3 82DE56B0/82DE5978.
-- Advances once after physical Skeleton publishes position64 and velocity16.

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3

type F4 = { number }

local centre_of_mass_filter = {}

export type CentreOfMassOutput = {
	-- PhysOutSystemReckoning0, used by animation and camera consumers.
	velocity: F4,
	-- PhysOutSystemReckoning32.
	acceleration: F4,
	-- PhysOutSystemReckoning80.
	position: F4,
}

-- ROBLOX: поля в Rust приватные.
export type CentreOfMassFilter = {
	velocity: F4,
	position: F4,
	position_velocity: F4,
	accumulated_error: F4,
	position_valid: boolean,
}

local CentreOfMassFilter = {}
centre_of_mass_filter.CentreOfMassFilter = CentreOfMassFilter

function CentreOfMassFilter.default(): CentreOfMassFilter
	-- Original Reset82DE5588 clears vectors16/96/112/128 and byte191.
	return {
		velocity = { 0.0, 0.0, 0.0, 0.0 },
		position = { 0.0, 0.0, 0.0, 0.0 },
		position_velocity = { 0.0, 0.0, 0.0, 0.0 },
		accumulated_error = { 0.0, 0.0, 0.0, 0.0 },
		position_valid = false,
	}
end

function CentreOfMassFilter.reset(self: CentreOfMassFilter)
	local fresh = CentreOfMassFilter.default() :: any
	for k, v in fresh do
		(self :: any)[k] = v
	end
end

function CentreOfMassFilter.update(self: CentreOfMassFilter, position: F4, velocity: F4): CentreOfMassOutput
	local dt = from_bits(0x3c888889)
	local old_velocity = self.velocity
	local v = {}
	for i = 1, 4 do
		v[i] = mul_add(old_velocity[i], 0.75, f32(velocity[i] * 0.25))
	end
	self.velocity = v
	local inverse_dt = native_arithmetic.reciprocal_estimate(dt)
	inverse_dt = mul_add(inverse_dt, mul_add(-dt, inverse_dt, 1.0), inverse_dt)
	inverse_dt = mul_add(inverse_dt, mul_add(-dt, inverse_dt, 1.0), inverse_dt)
	local acceleration = {}
	for i = 1, 4 do
		acceleration[i] = f32(f32(self.velocity[i] - old_velocity[i]) * inverse_dt)
	end
	if not self.position_valid then
		self.position = table.clone(position)
		self.position_velocity = { 0.0, 0.0, 0.0, 0.0 }
		self.position_valid = true
	else
		local coefficient = { f32(0.05), f32(0.03), f32(0.05), 0.0 }
		local unity = { 1.0, 1.0, 1.0, 0.0 }
		local pv = {}
		for i = 1, 4 do
			pv[i] = mul_add(f32(unity[i] - coefficient[i]), self.position_velocity[i], f32(coefficient[i] * velocity[i]))
		end
		self.position_velocity = pv
		local predicted = {}
		for i = 1, 4 do
			predicted[i] = mul_add(self.position_velocity[i], dt, self.position[i])
		end
		local p = {}
		for i = 1, 4 do
			p[i] = mul_add(f32(unity[i] - coefficient[i]), predicted[i], f32(coefficient[i] * position[i]))
		end
		self.position = p
		local error_ = {}
		for i = 1, 4 do
			error_[i] = f32(position[i] - self.position[i])
		end
		if dot3(error_, self.accumulated_error) > 0.0 then
			local q = {}
			for i = 1, 4 do
				q[i] = mul_add(self.accumulated_error[i], f32(0.08), self.position[i])
			end
			self.position = q
		end
		local acc = {}
		for i = 1, 4 do
			acc[i] = mul_add(self.accumulated_error[i], f32(0.95), f32(f32(position[i] - self.position[i]) * f32(0.05)))
		end
		self.accumulated_error = acc
	end
	return { velocity = table.clone(self.velocity), acceleration = acceleration, position = table.clone(self.position) }
end

return centre_of_mass_filter
