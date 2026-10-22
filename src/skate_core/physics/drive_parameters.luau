--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/drive_parameters.rs (коммит 2e16697)
--
-- Recovered drive parameter layout and TU3 truck/wheel construction branches.

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local retail_f32 = rt.from_bits

local drive_parameters = {}

-- pub enum RetailDriveType (#[repr(u32)])
drive_parameters.RetailDriveType = {
	NoDrive = 0,
	SoftDrive = 1,
	HardDrive = 2,
}
local RetailDriveType = drive_parameters.RetailDriveType

export type RetailDriveParams = {
	spring_or_max_velocity: number,
	damping: number,
	max_strength: number,
	drive_type: number,
}

export type RetailDriveDynamics = {
	linear: RetailDriveParams,
	angular: RetailDriveParams,
}

-- Separate collections read by TU3 CreateDrives and SetTruckDriveDynamics.
-- `physicstrucks_drives.UseSoftDrives` is not read by this TU3 path.
export type RetailTruckDriveSettings = {
	-- physicstrucks layout +0; gates only the linear configuration.
	use_linear_drives: boolean,
	-- physicsdeck full attribute 103FDC19514D4246; read only when enabled.
	use_hard_linear_drives: boolean,
	-- physicstrucks_drives layout +24, +28 and +20 respectively.
	angular_displacement: number,
	angular_damping: number,
	angular_strength: number,
}

local RetailTruckDriveSettings = {}
drive_parameters.RetailTruckDriveSettings = RetailTruckDriveSettings

-- Decoded default collections, not truck geometry/twist-limit fields.
function RetailTruckDriveSettings.STOCK(): RetailTruckDriveSettings
	return {
		use_linear_drives = false,
		use_hard_linear_drives = true,
		angular_displacement = 10.0,
		angular_damping = 0.0,
		angular_strength = 11.0,
	}
end

local RetailDriveParams = {}
drive_parameters.RetailDriveParams = RetailDriveParams

-- pub const DISABLED: Self
function RetailDriveParams.DISABLED(): RetailDriveParams
	return { spring_or_max_velocity = 0.0, damping = 0.0, max_strength = 0.0, drive_type = RetailDriveType.NoDrive }
end

-- ROBLOX: #[derive(PartialEq)].
function RetailDriveParams.eq(a: RetailDriveParams, b: RetailDriveParams): boolean
	return a.spring_or_max_velocity == b.spring_or_max_velocity
		and a.damping == b.damping
		and a.max_strength == b.max_strength
		and a.drive_type == b.drive_type
end

-- Original TU3 82C0B8A8..B8EC: two reciprocal-square-root refinements,
-- multiply by the spring, select zero for zero spring, then multiply by two.
local function soft_linear_damping(): number
	local spring = retail_f32(0x47C3_5000) -- 822F91F0
	local reciprocal_root = native_arithmetic.reciprocal_square_root_estimate(spring)
	for _ = 1, 2 do
		local squared = f32(reciprocal_root * reciprocal_root)
		local half = f32(reciprocal_root * 0.5)
		local residual = mul_add(-spring, squared, 1.0)
		reciprocal_root = mul_add(half, residual, reciprocal_root)
	end
	local root = if spring == 0.0 then 0.0 else f32(spring * reciprocal_root)
	return f32(root * retail_f32(0x4000_0000)) -- 82060C50
end

-- Constructor 82C06298 zeros both halves at +7152/+7168, then CreateDrives
-- 82C0B770 creates the truck pair and applies these settings. Postphysics only
-- refreshes frames in TU3; it does not rerun this parameter setup every tick.
-- pub fn retail_truck_drive_dynamics(settings) -> RetailDriveDynamics
function drive_parameters.retail_truck_drive_dynamics(settings: RetailTruckDriveSettings): RetailDriveDynamics
	local linear: RetailDriveParams
	if not settings.use_linear_drives then
		linear = RetailDriveParams.DISABLED()
	elseif settings.use_hard_linear_drives then
		linear = {
			spring_or_max_velocity = retail_f32(0x45BB_7FFF),
			damping = 0.0,
			max_strength = retail_f32(0x48AF_C7FF),
			drive_type = RetailDriveType.HardDrive,
		}
	else
		linear = {
			spring_or_max_velocity = retail_f32(0x47C3_5000),
			-- 82C0B858..B8EC: native sqrt(100000) refinement, then *2.
			damping = soft_linear_damping(),
			max_strength = retail_f32(0x48AF_C7FF),
			drive_type = RetailDriveType.SoftDrive,
		}
	end
	return {
		linear = linear,
		angular = {
			spring_or_max_velocity = f32(settings.angular_displacement * retail_f32(0x426F_FFFF)),
			damping = settings.angular_damping,
			max_strength = f32(settings.angular_strength * retail_f32(0x4560_FFFE)),
			drive_type = RetailDriveType.HardDrive,
		},
	}
end

-- pub const fn retail_wheel_drive_dynamics(use_hard_drives: bool) -> RetailDriveDynamics
function drive_parameters.retail_wheel_drive_dynamics(use_hard_drives: boolean): RetailDriveDynamics
	local linear: RetailDriveParams
	if use_hard_drives then
		linear = {
			spring_or_max_velocity = retail_f32(0x45BB_7FFF),
			damping = 0.0,
			max_strength = retail_f32(0x48AF_C7FF),
			drive_type = RetailDriveType.HardDrive,
		}
	else
		linear = {
			spring_or_max_velocity = retail_f32(0x4561_0000),
			damping = retail_f32(0x4270_0000),
			max_strength = retail_f32(0x470C_9FFF),
			drive_type = RetailDriveType.SoftDrive,
		}
	end
	return { linear = linear, angular = RetailDriveParams.DISABLED() }
end

-- #[repr(C)] pub struct RetailDriveFrameRaw
export type RetailDriveFrameRaw = {
	-- Retail quaternion in observed `(x, y, z, w)` lane order.
	quaternion_lanes: { number },
	-- Affine translation vector copied from matrix offset `0x30`.
	translation_lanes: { number },
}

-- #[repr(C)] pub struct RetailDriveFramesRaw
export type RetailDriveFramesRaw = {
	-- Frame emitted by helper `0x82BD3A10`.
	body_a: RetailDriveFrameRaw,
	-- Frame emitted by helper `0x82BD3BD0`.
	body_b: RetailDriveFrameRaw,
}

return drive_parameters
