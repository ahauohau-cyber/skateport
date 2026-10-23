--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/contact_response/material10.rs (коммит 2e16697)
--
-- First helper's Reset91708, Select917A0, Update91908 and response kernels.
-- ROBLOX: super::{apply_velocity_delta, reject_positive} продублированы здесь.

local rt = require("../../../../rt")
local m = require("../math")
local skeleton_body = require("../../../physics/skeleton_body")

local f32 = rt.f32
local from_bits = rt.from_bits
local SkeletonBody = skeleton_body.SkeletonBody
local sub, scale, madd, dot, normalize_or = m.sub, m.scale, m.madd, m.dot, m.normalize_or

type V = m.V

local material10 = {}

local STEP = from_bits(0x3c88_8889) -- 820849C8
local PHASE_DURATION = from_bits(0x3d07_2b02) -- 8208F5C0:0.033

-- 82C1E170 differs: positive component test uses the normalized direction,
-- but its subtraction multiplies the ORIGINAL direction, even if nonunit.
local function reject_positive(value: V, direction: V): V
	local projection = dot(value, normalize_or(direction, { 0.0, 0.0, 0.0, 0.0 }))
	if projection > 0.0 then
		return sub(value, scale(direction, projection))
	end
	return value
end
local function apply_velocity_delta(body: any, delta: V)
	-- All original loops start at part1 and execute23 stores; root0/extras24/25
	-- and angular velocities remain untouched. The host stores XYZ explicitly.
	local bodies = SkeletonBody.bodies_mut(body)
	for i = 2, 24 do
		local v = bodies[i].rates.linear_velocity
		bodies[i].rates.linear_velocity = vector.create(f32(v.x + delta[1]), f32(v.y + delta[2]), f32(v.z + delta[3]))
	end
end

export type Response = {
	previous_velocity: V, -- 16
	normal: V, -- 32
	target_velocity: V, -- 48
	time: number, -- 64
	phase: number, -- 72
	finished: boolean, -- 77, cleared by caller before Select
}

local Response = {}
material10.Response = Response

function Response.new(): Response
	return {
		previous_velocity = { 0.0, 0.0, 0.0, 0.0 },
		normal = { 0.0, 1.0, 0.0, 0.0 },
		target_velocity = { 0.0, 0.0, 0.0, 0.0 },
		time = 0.0,
		phase = 0,
		finished = false,
	}
end
function Response.reset(self: Response)
	local fresh = Response.new()
	for k, v in fresh :: any do
		(self :: any)[k] = v
	end
end

local function select(self: Response, contact: boolean)
	local nxt = self.phase
	if self.phase == 0 and contact then
		nxt = if -dot(self.previous_velocity, self.normal) > 2.0 then 1 else 4
	elseif self.phase == 1 and self.time > PHASE_DURATION then
		local twice_normal = scale(self.normal, 2.0)
		self.target_velocity = scale(sub(self.previous_velocity, scale(twice_normal, dot(self.previous_velocity, self.normal))), from_bits(0x3f66_6666))
		nxt = 2
	elseif self.phase == 2 and self.time > PHASE_DURATION then
		self.finished = true
		nxt = 3
	elseif self.phase == 3 and not contact then
		nxt = 0
	end
	-- Native unsigned phase>3 bypasses transitions, including phase4.
	if nxt ~= self.phase then
		self.phase = nxt
		self.time = 0.0
	end
end

function Response.update(self: Response, body: any, velocity: V, contact: V?)
	if contact ~= nil then
		self.normal = contact
	end
	self.finished = false
	select(self, contact ~= nil)
	if self.phase == 0 then
		local difference = sub(velocity, self.previous_velocity)
		-- Both original branches require the ordered greater-than bit.
		if self.time > from_bits(0x3c75_c28f) and dot(difference, difference) > 1.0 then
			self.previous_velocity = madd(velocity, from_bits(0x3d4c_cccd), scale(self.previous_velocity, from_bits(0x3f73_3333)))
		else
			self.previous_velocity = velocity
		end
	elseif self.phase == 1 then
		-- 91A40: half-opposite COM velocity, conditional plane rejection,
		-- then an additional -normal term. This is a velocity delta.
		local rejected = reject_positive(scale(velocity, -0.5), self.normal)
		apply_velocity_delta(body, madd(self.normal, -1.0, rejected))
	elseif self.phase == 2 then
		-- 91B28 preserves the Processed608 snapshot used by phase1.
		apply_velocity_delta(body, scale(sub(self.target_velocity, velocity), 1.0))
		-- Global830BD330 initializer82F826B0 loads -9.8 from822F8B40.
		self.target_velocity = madd({ 0.0, from_bits(0xc11c_cccd), 0.0, 0.0 }, STEP, self.target_velocity)
	end
	self.time = f32(self.time + STEP)
end

return material10
