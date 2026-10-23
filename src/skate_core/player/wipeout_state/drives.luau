--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/drives.rs (коммит 2e16697)
--
-- Original SkeletonDrives::UpdateRagdoll82BEB0C8 and root softness82BEB790.
-- ROBLOX: bone: [[f32; 5]; 24] -> bone[part + 1][k + 1]; bones[part] (Option) -> bones[part + 1] или false.

local rt = require("../../../rt")
local foot_ik = require("../../animation/foot_ik")
local board_motion_output = require("../../physics/board_motion_output")
local drive_parameters = require("../../physics/drive_parameters")
local sar = require("../../physics/skeleton_animation_record")
local drive_frames = require("../../physics/skeleton_body/drive_frames")
local drive_dynamics = require("../../physics/skeleton_body/drive_dynamics")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local RetailDriveType = drive_parameters.RetailDriveType
local BoneDriveDynamics = drive_dynamics.BoneDriveDynamics

local drives = {}

local FREQUENCY_SQUARED = from_bits(0x4560_FFFE)

export type Settings = {
	-- Original SkeletonBody748+36*part: start, normal, controlled, end, extra.
	bone: { { number } },
	-- The four full64 root_drive_* stock scalars, in the same first-four order.
	root: { number },
	-- animation/default: layout424 DriveStrengthLocal,420 DriveStrengthRootLocal.
	strength: { number },
	-- physics_animation/default HookSoftDsp888, HookSoftStr884, HookSoftDmp892.
	hook_spring: number,
	hook_strength: number,
	hook_damping: number,
}

export type Weights = {
	start: number,
	["end"]: number,
	controlled: number,
	-- Processed2484 bits5 and4 select the two independently supplied weights.
	upper_extra: number,
	lower_extra: number,
}

-- Returns original retained residual16. It is not clamped or renormalized.
function drives.update(d: any, pose: { sar.AnimationPartTransform }, settings: Settings, weights: Weights): number
	local inverses = {}
	inverses[1] = sar.IDENTITY()
	for part = 1, 23 do
		inverses[part + 1] = foot_ik.inverse_affine(pose[part + 1])
	end
	local residual = f32(f32(f32(1.0 - weights.start) - weights["end"]) - weights.controlled)
	for part = 1, 22 do
		local bone = d.bones[part + 1]
		assert(bone, "Original22 bone drives exist")
		local coefficients = settings.bone[part + 1]
		local upper = part >= 3 and part <= 10
		local lower = part >= 15 and part <= 22
		local strengths
		if (upper and weights.upper_extra > 0.0) or (lower and weights.lower_extra > 0.0) then
			bone.dynamics.mode = 5
			local extra = if upper then weights.upper_extra else weights.lower_extra
			local value = f32(extra * coefficients[5])
			strengths = { f32(value * settings.strength[1]), f32(value * settings.strength[2]) }
		else
			bone.dynamics.mode = 4
			local start, normal, controlled, end_ = coefficients[1], coefficients[2], coefficients[3], coefficients[4]
			-- 82BEB424..444 preserves two distinct FMA accumulation orders.
			local loc = mul_add(controlled, weights.controlled, mul_add(start, weights.start, mul_add(normal, residual, f32(end_ * weights["end"]))))
			local root_start = f32(settings.root[1] * start)
			local root_normal = f32(settings.root[2] * normal)
			local root_controlled = f32(settings.root[3] * controlled)
			local root_end = f32(settings.root[4] * end_)
			local root = mul_add(root_controlled, weights.controlled, mul_add(root_start, weights.start, mul_add(root_end, weights["end"], f32(root_normal * residual))))
			strengths = { f32(loc * settings.strength[1]), f32(root * settings.strength[2]) }
		end
		bone.dynamics.strengths = strengths
		for channel = 0, 1 do
			if not bone.active[channel + 1] then
				continue
			end
			bone.frames[channel + 1] = drive_frames.bone_drive_frames(pose[part + 1], inverses[part + 1], inverses[bone.parent[channel + 1] + 1])
			BoneDriveDynamics.enable(bone.dynamics, channel, strengths[channel + 1], d.settings.bone)
		end
	end
	return residual
end

local function clamp(v: number): number
	local lower = if -v >= 0.0 then 0.0 else v
	if f32(1.0 - lower) >= 0.0 then
		return lower
	end
	return 1.0
end

-- 82BEB790 changes only target0's linear drive; damping uses the unscaled spring.
function drives.set_linear_root(d: any, s: Settings, weight_in: number)
	local weight = clamp(weight_in)
	local spring = s.hook_spring
	local root = if spring == 0.0 then 0.0 else f32(spring * board_motion_output.inverse_length_squared(spring, 2))
	d.targets.dynamics[1].linear = {
		spring_or_max_velocity = f32(spring * weight),
		damping = f32(f32(root * 2.0) - f32(spring * from_bits(0x3C83_126F))),
		max_strength = f32(f32(s.hook_strength * weight) * FREQUENCY_SQUARED),
		drive_type = RetailDriveType.SoftDrive,
	}
end

-- 82D3BE98..BF24 uses the same target0 angular fields set during Enter.
-- Enter uses spring*0.5 and strength*1799.9998; Update uses the supplied weight.
function drives.set_angular_root(d: any, s: Settings, weight_in: number)
	local weight = clamp(weight_in)
	d.targets.dynamics[1].angular = {
		spring_or_max_velocity = f32(s.hook_spring * weight),
		damping = s.hook_damping,
		max_strength = f32(f32(s.hook_strength * weight) * FREQUENCY_SQUARED),
		drive_type = RetailDriveType.SoftDrive,
	}
end

return drives
