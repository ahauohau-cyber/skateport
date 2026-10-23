--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/drive_dynamics.rs (коммит 2e16697)
--
-- BoneDrives::EnableDrive82BECCE0 and mode-five interpolation82BECFB8.
-- A bone shares its interpolation counter between the LOCAL and LOCAL_ROOT
-- channels. Dispatch order is therefore observable even within one tick.

local rt = require("../../../rt")
local drive_parameters = require("../drive_parameters")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local RetailDriveParams = drive_parameters.RetailDriveParams
local RetailDriveType = drive_parameters.RetailDriveType

type RetailDriveParams = drive_parameters.RetailDriveParams
type RetailDriveDynamics = drive_parameters.RetailDriveDynamics

local FREQUENCY = from_bits(0x426F_FFFF)
local FREQUENCY_SQUARED = from_bits(0x4560_FFFE)
local HARD_VELOCITY = from_bits(0x4415_FFFF)
local HARD_STRENGTH = from_bits(0x470C_9FFF)

local drive_dynamics = {}

export type AnimationDriveSettings = {
	linear_strength: number,
	linear_displacement: number,
	angular_strength: number,
	angular_displacement: number,
}

export type DriveInterpolation = {
	spring: { number },
	strength: { number },
	damping: { number },
}

export type BoneDriveSettings = {
	-- ROBLOX: [AnimationDriveSettings; 2] -> канал с нуля -> animation[channel + 1].
	animation: { AnimationDriveSettings },
	collision_soft_displacement: number,
	collision_soft_strength: number,
	ragdoll_soft_displacement: number,
	ragdoll_soft_strength: number,
	transition_linear: DriveInterpolation,
	transition_angular: DriveInterpolation,
	transition_calls: number,
}

export type BoneDriveDynamics = {
	channels: { RetailDriveDynamics },
	mode: number,
	strengths: { number },
	transition_counter: number,
	transition_active: boolean,
}

local BoneDriveDynamics = {}
drive_dynamics.BoneDriveDynamics = BoneDriveDynamics

-- ROBLOX: impl Default.
function BoneDriveDynamics.default(): BoneDriveDynamics
	return {
		channels = {
			{ linear = RetailDriveParams.DISABLED(), angular = RetailDriveParams.DISABLED() },
			{ linear = RetailDriveParams.DISABLED(), angular = RetailDriveParams.DISABLED() },
		},
		mode = 0,
		strengths = { 0.0, 0.0 },
		transition_counter = 0.0,
		transition_active = false,
	}
end

local function hard(velocity: number, strength: number): RetailDriveParams
	return { spring_or_max_velocity = velocity, damping = 0.0, max_strength = strength, drive_type = RetailDriveType.HardDrive }
end

local function soft(spring: number, damping: number, strength: number): RetailDriveParams
	return { spring_or_max_velocity = spring, damping = damping, max_strength = strength, drive_type = RetailDriveType.SoftDrive }
end

local function interpolate(settings: DriveInterpolation, strength: number, progress: number): RetailDriveParams
	-- Original82BED100..114 are scalar fmadds (primary59,extended29).
	-- The retained older pseudocode expands them to multiply+add expressions.
	local spring0 = f32(settings.spring[1] * strength)
	local strength0 = f32(settings.strength[1] * strength)
	local spring = mul_add(f32(f32(settings.spring[2] * strength) - spring0), progress, spring0)
	local force = mul_add(f32(f32(settings.strength[2] * strength) - strength0), progress, strength0)
	local damping = mul_add(f32(settings.damping[2] - settings.damping[1]), progress, settings.damping[1])
	local function nonnegative(value: number): number
		return if value >= 0.0 then value else 0.0
	end
	return {
		spring_or_max_velocity = f32(nonnegative(spring) * FREQUENCY),
		max_strength = f32(nonnegative(force) * FREQUENCY_SQUARED),
		damping = nonnegative(damping),
		drive_type = RetailDriveType.HardDrive,
	}
end

-- ROBLOX: channel — индекс канала с нуля.
function BoneDriveDynamics.enable(self: BoneDriveDynamics, channel: number, strength: number, settings: BoneDriveSettings)
	assert(channel < 2)
	if self.mode > 5 then
		return
	end
	if self.mode ~= 5 then
		self.transition_active = false
	end
	local animation = settings.animation[channel + 1]
	local dynamics: RetailDriveDynamics
	local mode = self.mode
	if mode == 0 then
		dynamics = {
			linear = hard(f32(animation.linear_displacement * FREQUENCY), f32(animation.linear_strength * FREQUENCY_SQUARED)),
			angular = hard(f32(animation.angular_displacement * FREQUENCY), f32(animation.angular_strength * FREQUENCY_SQUARED)),
		}
	elseif mode == 1 then
		dynamics = {
			linear = hard(HARD_VELOCITY, HARD_STRENGTH),
			angular = hard(HARD_VELOCITY, HARD_STRENGTH),
		}
	elseif mode == 2 then
		dynamics = {
			linear = hard(0.0, 0.0),
			angular = hard(f32(animation.angular_displacement * FREQUENCY), f32(animation.angular_strength * FREQUENCY_SQUARED)),
		}
	elseif mode == 3 then
		dynamics = {
			linear = soft(0.0, 0.0, 0.0),
			angular = soft(f32(settings.collision_soft_displacement * strength), 200.0, f32(f32(settings.collision_soft_strength * strength) * FREQUENCY_SQUARED)),
		}
	elseif mode == 4 then
		dynamics = {
			linear = if strength <= 0.5
				then soft(0.0, 0.0, 0.0)
				else soft(f32(f32(settings.ragdoll_soft_displacement * strength) * 0.5), 200.0, f32(f32(strength * settings.ragdoll_soft_strength) * FREQUENCY_SQUARED)),
			angular = soft(f32(settings.ragdoll_soft_displacement * strength), 200.0, f32(f32(strength * settings.ragdoll_soft_strength) * FREQUENCY_SQUARED)),
		}
	elseif mode == 5 then
		if not self.transition_active then
			self.transition_active = true
			self.transition_counter = 1.0
		elseif self.transition_counter < settings.transition_calls then
			self.transition_counter = f32(self.transition_counter + 1.0)
		end
		local progress = f32(self.transition_counter / settings.transition_calls)
		dynamics = {
			linear = interpolate(settings.transition_linear, strength, progress),
			angular = interpolate(settings.transition_angular, strength, progress),
		}
	else
		error("unreachable")
	end
	self.channels[channel + 1] = dynamics
end

return drive_dynamics
