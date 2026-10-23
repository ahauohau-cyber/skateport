--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/recovery.rs (коммит 2e16697)
--
-- Original recovery82D3EAE0, request82D3E980, scalar82D3E5E8 and post82D3ED30.
-- ROBLOX: impl State -> функции recovery.*(state, ...).

local rt = require("../../../rt")
local native_arithmetic = require("../../physics/native_arithmetic")
local data = require("./data")

local f32 = rt.f32
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3

local recovery = {}

local DT = from_bits(0x3C88_8889)

export type Settings = {
	minimum_time: number, -- physics_wipeout280
	minimum_settled: number, -- 284
	maximum_time: number, -- 292
	fade_time: number, -- 296
	over_speed: number, -- 80
	over_minimum_time: number, -- 84
}

function recovery.response_strength(self: data.State): number
	local speed = f32(self.maximum_speed * f32(0.1))
	-- ROBLOX: (4u32.wrapping_sub(count) as i32) as f32.
	local count = f32(rt.to_i32(rt.wrapping_sub_u32(4, self.response_count)))
	local remaining = f32(f32(count + 1.0) * 0.5)
	local result = if f32(speed - remaining) >= 0.0 then speed else remaining
	if self.slow_time > 1.0 or result <= f32(0.2) or self.special_surface or self.below_surface then
		return 0.0
	end
	return result
end

local function should_teleport(self: data.State, flags2472: number, flags2484: number, timestep: number, settings: Settings): boolean
	if self.ever_impaled then
		self.impaled_time = f32(self.impaled_time + DT)
	end
	if bit32.btest(flags2484, 0x0040_0000) then
		self.ever_impaled = true
		if self.impaled_time > 0.5 then
			return true
		end
	end
	if self.prevent_manual then
		return false
	end
	if self.recovery_eligible and self.reset_ever and not self.ignore_reset then
		return true
	end
	if self.teleport_pending then
		self.time_until_teleport = f32(self.time_until_teleport - timestep)
		return self.time_until_teleport <= 0.0
	end
	local automatic
	if bit32.btest(flags2472, 0x1000_0000) then
		automatic = self.time > 8.0
	else
		automatic = (self.time > settings.maximum_time and self.response_time > settings.maximum_time)
			or (self.time > settings.minimum_time and self.settled_time > settings.minimum_settled and self.response_time > settings.minimum_settled)
	end
	if automatic then
		self.teleport_pending = true
		self.time_until_teleport = settings.fade_time
	end
	return false
end

function recovery.manage_recovery(self: data.State, flags2468: number, flags2472: number, flags2484: number, timestep: number, settings: Settings)
	self.prevent_manual = self.prevent_manual or bit32.btest(flags2468, 1)
	self.ignore_reset = self.ignore_reset or bit32.btest(flags2472, 0x8000_0000)
	self.reset_ever = self.reset_ever or bit32.btest(flags2472, 0x0010_0000)
	self.ever_settled = self.ever_settled or self.over
	self.recovery_eligible = self.recovery_eligible or self.ever_settled or self.time > f32(1.6)
	self.settled_time = if self.over then f32(self.settled_time + DT) else 0.0
	if self.teleport_countdown < 0 and should_teleport(self, flags2472, flags2484, timestep, settings) then
		self.teleport_countdown = 2
	end
	if self.teleport_countdown == 0 then
		self.request_teleport = true
	elseif self.teleport_countdown > 0 then
		self.teleport_countdown -= 1
	end
end

function recovery.post_physics(self: data.State, hips_velocity: { number }, neck_velocity: { number }, support_contact: boolean, settings: Settings)
	local bypass_neck = self.extra_weight_zero_time > 0.5
	local speed = if bypass_neck then f32(settings.over_speed * 2.0) else settings.over_speed
	local minimum_time = self.time > settings.over_minimum_time
	local hips_squared = dot3(hips_velocity, hips_velocity)
	local neck_squared = dot3(neck_velocity, neck_velocity)
	local speed_sq = f32(speed * speed)
	self.over = hips_squared < speed_sq and (neck_squared < speed_sq or bypass_neck) and minimum_time and recovery.response_strength(self) == 0.0
	self.slow = hips_squared < 1.0 and minimum_time
	self.no_support_time = if support_contact then 0.0 else f32(self.no_support_time + DT)
end

return recovery
