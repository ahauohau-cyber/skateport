--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/joint_records.rs (коммит 2e16697)
--
-- TU3 skateboard joint definitions reconstructed from stock collection data.
--
-- `SkateboardBody::CreateJoints` (`0x82C0C268`) builds two deck/truck joints
-- followed by four truck/wheel joints. This module emits the native parameter
-- and frame payloads that `Assembly::Initialize` consumes; it does not replace
-- them with a third-party constraint type.

local rt = require("../../rt")
local trigonometry = require("../trigonometry")
local board = require("./board")
local drive_frames = require("./drive_frames")
local authored = require("./construction/authored_transforms")
local rigid_body = require("./rigid_body")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local BodyId = board.BodyId

type Vector3 = vector
type RetailQuaternion = rigid_body.RetailQuaternion

local joint_records = {}

joint_records.tu3 = {
	CREATE_JOINTS = 0x82C0_C268,
	ASSEMBLY_INITIALIZE = 0x82AD_FAF8,
	ASSEMBLY_POPULATE = 0x82AD_FBB8,
	FRAME_PACK_0 = 0x82C0_0940,
	FRAME_PACK_1 = 0x82C0_0AF0,
	FRAME_PACK_2 = 0x82BD_3858,
}

joint_records.JOINT_COUNT = 6

local DEGREES_TO_RADIANS = from_bits(0x3C8E_FA35)
local SIMULATION_FREQUENCY = from_bits(0x426F_FFFF)
local HALF_PI = from_bits(0x3FC9_0FDB)

export type RetailJointSettings = {
	truck_twist_limit_degrees: number,
	truck_twist_angle_degrees: number,
	wheel_swing_limit_degrees: number,
}

local RetailJointSettings = {}
joint_records.RetailJointSettings = RetailJointSettings

-- Values decoded from the stock `physicstrucks` and `physicswheels`
-- collection XMLs read by `CreateJoints`.
function RetailJointSettings.STOCK(): RetailJointSettings
	return {
		truck_twist_limit_degrees = from_bits(0x42AC_3333),
		truck_twist_angle_degrees = from_bits(0x4160_0000),
		wheel_swing_limit_degrees = from_bits(0x4974_2400),
	}
end

-- #[repr(C)] pub struct RetailJointParametersRaw { words: [u32; 16] }
export type RetailJointParametersRaw = { words: { number } }
-- #[repr(C)] pub struct RetailJointFramesRaw { words: [u32; 20] }
export type RetailJointFramesRaw = { words: { number } }

-- ROBLOX: BodyId — число (с нуля).
export type RetailJointRecord = {
	definition_body_0: number,
	definition_body_1: number,
	parameters: RetailJointParametersRaw,
	frames: RetailJointFramesRaw,
}

local RetailJointRecord = {}
joint_records.RetailJointRecord = RetailJointRecord

-- Body written to live `Joint+0x10` by assembly activation.
function RetailJointRecord.live_body_a(self: RetailJointRecord): number
	return self.definition_body_1
end

-- Body written to live `Joint+0x14` by assembly activation.
function RetailJointRecord.live_body_b(self: RetailJointRecord): number
	return self.definition_body_0
end

local function truck_parameters(settings: RetailJointSettings): RetailJointParametersRaw
	local angle_radians = f32(settings.truck_twist_angle_degrees * DEGREES_TO_RADIANS)
	local _, angle_cosine = trigonometry.sin_cos(angle_radians)
	local twist_velocity = f32(f32(settings.truck_twist_limit_degrees * DEGREES_TO_RADIANS) * SIMULATION_FREQUENCY)
	local words = rt.zeros(16)
	words[9] = to_bits(twist_velocity)
	-- The native parameter block retains the angular boundary in its spare
	-- fourth lane while the solver consumes cos(angle) from word 13.
	words[12] = to_bits(angle_radians)
	words[13] = to_bits(1.0)
	words[14] = to_bits(angle_cosine)
	words[15] = 0
	words[16] = 1
	return { words = words }
end

local function wheel_parameters(settings: RetailJointSettings): RetailJointParametersRaw
	local swing_velocity = f32(f32(settings.wheel_swing_limit_degrees * DEGREES_TO_RADIANS) * SIMULATION_FREQUENCY)
	local words = rt.zeros(16)
	words[10] = to_bits(swing_velocity)
	words[13] = to_bits(1.0)
	words[14] = to_bits(1.0)
	words[15] = 3
	words[16] = 0
	return { words = words }
end

local function write_quaternion(words: { number }, offset: number, value: RetailQuaternion)
	words[offset + 1] = to_bits(value.x)
	words[offset + 2] = to_bits(value.y)
	words[offset + 3] = to_bits(value.z)
	words[offset + 4] = to_bits(value.w)
end

local function write_vector(words: { number }, offset: number, value: Vector3)
	words[offset + 1] = to_bits(value.x)
	words[offset + 2] = to_bits(value.y)
	words[offset + 3] = to_bits(value.z)
end

local function pack_frames(
	body_a: drive_frames.RetailDriveFrame,
	body_b: drive_frames.RetailDriveFrame,
	linear_orientation_b: RetailQuaternion
): RetailJointFramesRaw
	local words = rt.zeros(20)
	write_quaternion(words, 0, body_a.orientation)
	write_vector(words, 4, body_a.translation)
	write_quaternion(words, 8, body_b.orientation)
	write_vector(words, 12, body_b.translation)
	write_quaternion(words, 16, linear_orientation_b)
	return { words = words }
end

local function truck_joint_frames(frames: drive_frames.RetailDriveFrames): RetailJointFramesRaw
	return pack_frames(frames.body_a, frames.body_b, frames.body_b.orientation)
end

local function wheel_joint_orientation(): RetailQuaternion
	local sin, cos = trigonometry.sin_cos(HALF_PI)
	return drive_frames.retail_quaternion_from_basis({
		columns = { { 1.0, 0.0, 0.0 }, { 0.0, cos, sin }, { 0.0, -sin, cos } },
	})
end

local function wheel_joint_frames(orientation: RetailQuaternion, z_offset: number): RetailJointFramesRaw
	return pack_frames(
		{ orientation = orientation, translation = vector.create(0, 0, 0) },
		{ orientation = orientation, translation = vector.create(0.0, 0.0, z_offset) },
		orientation
	)
end

-- ROBLOX: Rust копирует Copy-записи; здесь — явные копии таблиц слов.
local function joint(
	definition_body_0: number,
	definition_body_1: number,
	parameters: RetailJointParametersRaw,
	frames: RetailJointFramesRaw
): RetailJointRecord
	return {
		definition_body_0 = definition_body_0,
		definition_body_1 = definition_body_1,
		parameters = { words = table.clone(parameters.words) },
		frames = { words = table.clone(frames.words) },
	}
end

-- pub fn joint_records(settings: RetailJointSettings) -> [RetailJointRecord; JOINT_COUNT]
function joint_records.joint_records(settings: RetailJointSettings): { RetailJointRecord }
	local truck = truck_parameters(settings)
	local wheel = wheel_parameters(settings)
	local truck_drive = drive_frames.default_truck_drive_frames()
	local truck_frames = { truck_joint_frames(truck_drive[1]), truck_joint_frames(truck_drive[2]) }
	local wheel_orientation = wheel_joint_orientation()
	local wheel_offset = authored.AuthoredTransformInputs.STOCK().wheel_x_distance
	local positive_wheel_frames = wheel_joint_frames(wheel_orientation, wheel_offset)
	local negative_wheel_frames = wheel_joint_frames(wheel_orientation, -wheel_offset)
	return {
		joint(BodyId.Deck, BodyId.FrontTruck, truck, truck_frames[1]),
		joint(BodyId.Deck, BodyId.BackTruck, truck, truck_frames[2]),
		joint(BodyId.FrontTruck, BodyId.RightFrontWheel, wheel, positive_wheel_frames),
		joint(BodyId.FrontTruck, BodyId.LeftFrontWheel, wheel, negative_wheel_frames),
		joint(BodyId.BackTruck, BodyId.RightBackWheel, wheel, positive_wheel_frames),
		joint(BodyId.BackTruck, BodyId.LeftBackWheel, wheel, negative_wheel_frames),
	}
end

-- Complete stock record set in the unrolled write order of TU3
-- `SkateboardBody::CreateJoints`.
function joint_records.default_joint_records(): { RetailJointRecord }
	return joint_records.joint_records(RetailJointSettings.STOCK())
end

return joint_records
