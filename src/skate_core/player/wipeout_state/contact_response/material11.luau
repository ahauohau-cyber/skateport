--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/contact_response/material11.rs (коммит 2e16697)
--
-- Second helper's Reset91BF8, Update91C98, response91DF8 and controls92160.
-- ROBLOX: super::{apply_velocity_delta, reject} продублированы здесь.

local rt = require("../../../../rt")
local m = require("../math")
local native_arithmetic = require("../../../physics/native_arithmetic")
local skeleton_body = require("../../../physics/skeleton_body")

local f32 = rt.f32
local from_bits = rt.from_bits
local SkeletonBody = skeleton_body.SkeletonBody
local sub, add, scale, dot, cross, length, normalize_or, reciprocal = m.sub, m.add, m.scale, m.dot, m.cross, m.length, m.normalize_or, m.reciprocal

type V = m.V

local material11 = {}

local ZERO = { 0.0, 0.0, 0.0, 0.0 }

-- 82E0A4E8: reject the component along the safely normalized direction.
local function reject(value: V, direction: V): V
	local normal = normalize_or(direction, ZERO)
	return sub(value, scale(normal, dot(value, normal)))
end
local function apply_velocity_delta(body: any, delta: V)
	local bodies = SkeletonBody.bodies_mut(body)
	for i = 2, 24 do
		local v = bodies[i].rates.linear_velocity
		bodies[i].rates.linear_velocity = vector.create(f32(v.x + delta[1]), f32(v.y + delta[2]), f32(v.z + delta[3]))
	end
end

export type Response = {
	normal: V, -- 16
	previous_velocity: V, -- 32
	velocity: V, -- 48
	frames_since_contact: number, -- 64
	active_frames: number, -- 68
	contact_latched: boolean, -- 72, reset-owned, not cleared each update
	active: boolean, -- 73, explicitly preserved by native Reset
}

local Response = {}
material11.Response = Response

function Response.new(): Response
	-- The original constructors/reset omit initialization of byte73. Host
	-- storage begins false; subsequent native resets preserve its value.
	return {
		normal = { 0.0, 1.0, 0.0, 0.0 },
		previous_velocity = { 0.0, 0.0, 0.0, 0.0 },
		velocity = { 0.0, 0.0, 0.0, 0.0 },
		frames_since_contact = 100,
		active_frames = 0,
		contact_latched = false,
		active = false,
	}
end
function Response.reset(self: Response)
	local active = self.active
	local fresh = Response.new()
	for k, v in fresh :: any do
		(self :: any)[k] = v
	end
	self.active = active
end

local function apply_response(self: Response, body: any)
	local retained_delta = ZERO
	if self.active_frames < 3 then
		local difference = reject(sub(self.previous_velocity, self.velocity), self.normal)
		if dot(difference, self.velocity) > 0.0 then
			retained_delta = scale(difference, from_bits(0x3f66_6666))
		end
	end
	local friction = reject(scale(self.velocity, from_bits(0xbb03_126f)), self.normal)
	local slope_delta = ZERO
	-- 91F9C bge skips the slope term at/above original normal.y limit0.97.
	if self.normal[2] < from_bits(0x3f78_51ec) then
		local across = cross({ 0.0, 1.0, 0.0, 0.0 }, self.normal)
		local direction = normalize_or(cross(across, self.normal), ZERO)
		if direction[2] > 0.0 then
			direction = scale(direction, -1.0)
		end
		-- 92058 loads retained NORMAL; only its Y is zeroed before length.
		local horizontal_normal = table.clone(self.normal)
		horizontal_normal[2] = 0.0
		local candidate = scale(direction, f32(length(horizontal_normal) * from_bits(0x3dcc_cccd)))
		if dot(candidate, self.velocity) > 0.0 then
			slope_delta = candidate
		end
	end
	apply_velocity_delta(body, add(add(friction, retained_delta), slope_delta))
end

local function apply_control(self: Response, body: any, effective_axis: V, control: { number })
	local planar_velocity = reject(self.velocity, self.normal)
	local planar_direction = normalize_or(planar_velocity, ZERO)
	if from_bits(0x3f7f_be77) > dot({ 0.0, 1.0, 0.0, 0.0 }, effective_axis) then
		local fraction = f32(reciprocal(10.0) * native_arithmetic.vector_min(10.0, length(planar_velocity)))
		local input = { control[1], 0.0, control[2], 0.0 }
		local tangent = reject(input, self.normal)
		local lateral = reject(tangent, planar_direction)
		apply_velocity_delta(body, scale(lateral, f32(fraction * from_bits(0x3d4c_cccd))))
	end
end

function Response.update(self: Response, body: any, input: any)
	self.velocity = input.com_velocity_608
	if dot(self.velocity, self.velocity) > 0.25 then
		local normal = input.material11_normal
		if normal ~= nil then
			self.frames_since_contact = 0
			self.contact_latched = true
			self.normal = normal
			if not self.active then
				self.previous_velocity = reject(self.previous_velocity, self.normal)
			end
		end
	end
	self.active = self.contact_latched or self.frames_since_contact < 3
	if self.active then
		apply_response(self, body)
		apply_control(self, body, input.effective_axis_224, input.wipeout_control_2824_2828)
		self.active_frames = rt.to_i32(self.active_frames + 1)
	else
		self.previous_velocity = self.velocity
		self.active_frames = 0
	end
	-- Native signed comparison intentionally alternates100->101->100.
	self.frames_since_contact = if self.frames_since_contact <= 100 then rt.to_i32(self.frames_since_contact + 1) else 100
end

return material11
