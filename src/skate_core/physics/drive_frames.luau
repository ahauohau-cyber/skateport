--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/drive_frames.rs (коммит 2e16697)
--
-- Scalar port of Skate 3 TU3's skateboard drive-frame construction.
--
-- `SkateboardBody::SetDriveFrames2` (`0x82C0C088`) writes an identity matrix
-- to the child/second-body frame and writes the computed relative matrix to
-- the parent/first-body frame. The retail matrices are affine column-basis
-- matrices (`Ri`, `Up`, `At`, translation). This module keeps that convention
-- explicit and does not substitute an engine joint.
-- ROBLOX: функции подмодуля authored (construction/authored_transforms) не
-- переэкспортируются — их берут из того файла.

local rt = require("../../rt")
local math_mod = require("../math")
local trigonometry = require("../trigonometry")
local board = require("./board")
local native_arithmetic = require("./native_arithmetic")
local mass = require("./mass")
local rigid_body = require("./rigid_body")
local drive_parameters = require("./drive_parameters")
local authored = require("./construction/authored_transforms")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local BodyId = board.BodyId

type Vector3 = vector
type Basis3 = math_mod.Basis3
type RetailQuaternion = rigid_body.RetailQuaternion

local drive_frames = {}

-- pub mod tu3
drive_frames.tu3 = {
	CALCULATE_TRUCK_TRANSFORMS = 0x82C0_BC90,
	SET_DRIVE_FRAMES_2 = 0x82C0_C088,
	MATRIX_TO_FRAME_A = 0x82BD_3A10,
	MATRIX_TO_FRAME_B = 0x82BD_3BD0,
	PART_SET_TRANSFORM = 0x82BD_4318,
}

export type RetailAffineTransform = {
	-- Column vectors in retail `Ri`, `Up`, `At` order.
	basis: Basis3,
	translation: Vector3,
}

local RetailAffineTransform = {}
drive_frames.RetailAffineTransform = RetailAffineTransform

-- pub const IDENTITY: Self
-- ROBLOX: функция, чтобы каждый получал свою копию таблицы.
function RetailAffineTransform.IDENTITY(): RetailAffineTransform
	return {
		basis = { columns = { { 1.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, { 0.0, 0.0, 1.0 } } },
		translation = vector.create(0, 0, 0),
	}
end

-- ROBLOX: Copy-копия и #[derive(PartialEq)].
function RetailAffineTransform.copy(t: RetailAffineTransform): RetailAffineTransform
	return { basis = math_mod.Basis3.copy(t.basis), translation = t.translation }
end

function RetailAffineTransform.eq(a: RetailAffineTransform, b: RetailAffineTransform): boolean
	return math_mod.Basis3.eq(a.basis, b.basis) and a.translation == b.translation
end

export type RetailDriveFrame = {
	orientation: RetailQuaternion,
	translation: Vector3,
}

export type RetailDriveFrames = {
	-- Native child/second-body record written by `SetChildFrame` at +0/+16.
	body_a: RetailDriveFrame,
	-- Native parent/first-body record written by `SetParentFrame` at +32/+48.
	body_b: RetailDriveFrame,
}

-- Inputs read by TU3 `SkateboardBody::CalculateTruckTransforms`.
-- The two longitudinal fields retain the decoded retail attribute names.
export type RetailTruckTransformInputs = {
	deck_mid_length: number,
	truck_z_position_front: number,
	truck_z_position_back: number,
	truck_y_position: number,
	truck_rotation_axis_angle_degrees: number,
}

-- pub const RETAIL_DEFAULT_TRUCK_TRANSFORM_INPUTS
function drive_frames.RETAIL_DEFAULT_TRUCK_TRANSFORM_INPUTS(): RetailTruckTransformInputs
	return {
		deck_mid_length = board.RETAIL_DECK_MID_LENGTH,
		truck_z_position_front = board.RETAIL_TRUCK_Z_POSITION_FRONT,
		truck_z_position_back = board.RETAIL_TRUCK_Z_POSITION_BACK,
		truck_y_position = board.RETAIL_TRUCK_Y_POSITION,
		truck_rotation_axis_angle_degrees = board.RETAIL_TRUCK_ROTATION_AXIS_ANGLE_DEGREES,
	}
end

-- Deck-center height that places the initialized wheel spheres exactly on a
-- level Y=0 riding surface. Geometry-derived fixture placement.
drive_frames.RETAIL_LEVEL_GROUND_DECK_CENTER_HEIGHT = f32(board.RETAIL_WHEEL_RADIUS - board.RETAIL_TRUCK_Y_POSITION)

local function refined_reciprocal_square_root(value: number): number
	local estimate = native_arithmetic.reciprocal_square_root_estimate(value)
	for _ = 1, 2 do
		local square = f32(estimate * estimate)
		local half_estimate = f32(estimate * 0.5)
		local residual = mul_add(-value, square, 1.0)
		estimate = mul_add(half_estimate, residual, estimate)
	end
	return estimate
end

local function quaternion_candidate(sum: number, companion: { number }, dominant: number): RetailQuaternion
	local inverse_root = refined_reciprocal_square_root(sum)
	local half_inverse_root = f32(inverse_root * 0.5)
	local half_root = f32(f32(sum * inverse_root) * 0.5)
	local lanes = {}
	for i = 1, 4 do
		lanes[i] = f32(companion[i] * half_inverse_root)
	end
	lanes[dominant + 1] = half_root
	return { x = lanes[1], y = lanes[2], z = lanes[3], w = lanes[4] }
end

-- Dominant-component matrix-to-quaternion calculation in TU3 child/parent
-- frame setters `0x82BD3A10` and `0x82BD3BD0`. Selects trace/X/Y/Z with strict
-- comparisons. Matrix storage remains column-major `Ri`, `Up`, `At`.
-- pub fn retail_quaternion_from_basis(basis: Basis3) -> RetailQuaternion
function drive_frames.retail_quaternion_from_basis(basis: Basis3): RetailQuaternion
	local c = basis.columns
	local m00, m01, m02 = c[1][1], c[2][1], c[3][1]
	local m10, m11, m12 = c[1][2], c[2][2], c[3][2]
	local m20, m21, m22 = c[1][3], c[2][3], c[3][3]

	local trace = f32(f32(m00 + m11) + m22)
	if trace > 0.0 then
		return quaternion_candidate(
			f32(f32(m00 + m11) + f32(m22 + 1.0)),
			{ f32(m21 - m12), f32(m02 - m20), f32(m10 - m01), 0.0 },
			3
		)
	elseif m00 > m11 and m00 > m22 then
		return quaternion_candidate(
			f32(f32(m00 - m11) + f32(f32(0.0 - m22) + 1.0)),
			{ 0.0, f32(m01 + m10), f32(m02 + m20), f32(m21 - m12) },
			0
		)
	elseif m11 > m22 then
		return quaternion_candidate(
			f32(f32(f32(0.0 - m00) + m11) + f32(f32(0.0 - m22) + 1.0)),
			{ f32(m01 + m10), 0.0, f32(m12 + m21), f32(m02 - m20) },
			1
		)
	end
	return quaternion_candidate(
		f32(f32(f32(0.0 - m00) - m11) + f32(m22 + 1.0)),
		{ f32(m02 + m20), f32(m12 + m21), 0.0, f32(m10 - m01) },
		2
	)
end

local function multiply_basis_vector(basis: Basis3, v: Vector3): Vector3
	local c = basis.columns
	local function component(lane: number): number
		local first = f32(v.x * c[1][lane])
		local second = mul_add(v.y, c[2][lane], first)
		return mul_add(v.z, c[3][lane], second)
	end
	return vector.create(component(1), component(2), component(3))
end

local function multiply_basis(left: Basis3, right: Basis3): Basis3
	local columns = {}
	for i, column in right.columns do
		local out = {}
		for lane = 1, 3 do
			local first = f32(column[1] * left.columns[1][lane])
			local second = mul_add(column[2], left.columns[2][lane], first)
			out[lane] = mul_add(column[3], left.columns[3][lane], second)
		end
		columns[i] = out
	end
	return { columns = columns }
end

local function inverse_affine(transform: RetailAffineTransform): RetailAffineTransform
	local c = transform.basis.columns
	local inverse_basis = {
		columns = {
			{ c[1][1], c[2][1], c[3][1] },
			{ c[1][2], c[2][2], c[3][2] },
			{ c[1][3], c[2][3], c[3][3] },
		},
	}
	local translated = multiply_basis_vector(inverse_basis, transform.translation)
	return {
		basis = inverse_basis,
		translation = vector.create(f32(0.0 - translated.x), f32(0.0 - translated.y), f32(0.0 - translated.z)),
	}
end

local function compose_affine(parent: RetailAffineTransform, local_t: RetailAffineTransform): RetailAffineTransform
	local translated = multiply_basis_vector(parent.basis, local_t.translation)
	return {
		basis = multiply_basis(parent.basis, local_t.basis),
		translation = vector.create(
			f32(translated.x + parent.translation.x),
			f32(translated.y + parent.translation.y),
			f32(translated.z + parent.translation.z)
		),
	}
end

local function transpose_multiply_basis(parent: Basis3, child: Basis3): Basis3
	local columns = {}
	for column = 1, 3 do
		local child_column = child.columns[column]
		local out = {}
		for lane = 1, 3 do
			local parent_column = parent.columns[lane]
			local first = f32(child_column[1] * parent_column[1])
			local second = mul_add(child_column[2], parent_column[2], first)
			out[lane] = mul_add(child_column[3], parent_column[3], second)
		end
		columns[column] = out
	end
	return { columns = columns }
end

local function transpose_relative_translation(parent_basis: Basis3, parent_translation: Vector3, child_translation: Vector3): Vector3
	local neg_parent = vector.create(
		f32(0.0 - parent_translation.x),
		f32(0.0 - parent_translation.y),
		f32(0.0 - parent_translation.z)
	)
	local function component(parent_column: { number }): number
		local result = f32(neg_parent.z * parent_column[3])
		result = mul_add(neg_parent.y, parent_column[2], result)
		result = mul_add(neg_parent.x, parent_column[1], result)
		result = mul_add(child_translation.x, parent_column[1], result)
		result = mul_add(child_translation.y, parent_column[2], result)
		return mul_add(child_translation.z, parent_column[3], result)
	end
	local c = parent_basis.columns
	return vector.create(component(c[1]), component(c[2]), component(c[3]))
end

local function relative_parent_transform(parent_world: RetailAffineTransform, child_world: RetailAffineTransform): RetailAffineTransform
	return {
		basis = transpose_multiply_basis(parent_world.basis, child_world.basis),
		translation = transpose_relative_translation(parent_world.basis, parent_world.translation, child_world.translation),
	}
end

local function rotation_x(angle: number): Basis3
	local sin, cos = trigonometry.sin_cos(angle)
	return { columns = { { 1.0, 0.0, 0.0 }, { 0.0, cos, sin }, { 0.0, -sin, cos } } }
end

local function rotation_y(angle: number): Basis3
	local sin, cos = trigonometry.sin_cos(angle)
	return { columns = { { cos, 0.0, -sin }, { 0.0, 1.0, 0.0 }, { sin, 0.0, cos } } }
end

-- pub fn calculate_truck_transforms(inputs) -> [RetailAffineTransform; 2]
function drive_frames.calculate_truck_transforms(inputs: RetailTruckTransformInputs): { RetailAffineTransform }
	local DEGREES_TO_RADIANS = from_bits(0x3C8E_FA35)
	local HALF = from_bits(0x3F00_0000)
	local NEGATIVE_HALF_PI = from_bits(0xBFC9_0FDB)
	local POSITIVE_HALF_PI = from_bits(0x3FC9_0FDB)

	local alpha = f32(inputs.truck_rotation_axis_angle_degrees * DEGREES_TO_RADIANS)
	local front_z = mul_add(inputs.deck_mid_length, HALF, inputs.truck_z_position_front)
	local back_z = -mul_add(inputs.deck_mid_length, HALF, inputs.truck_z_position_back)
	return {
		{
			basis = multiply_basis(rotation_x(alpha), rotation_y(POSITIVE_HALF_PI)),
			translation = vector.create(0.0, inputs.truck_y_position, back_z),
		},
		{
			basis = multiply_basis(rotation_x(-alpha), rotation_y(NEGATIVE_HALF_PI)),
			translation = vector.create(0.0, inputs.truck_y_position, front_z),
		},
	}
end

-- TU3 `SkateboardBody::CalculateTruckTransforms` (`0x82C0BC90`) evaluated
-- from the stock skater-collection inputs. Native `+7712`, `+7776` order.
function drive_frames.default_truck_transforms(): { RetailAffineTransform }
	return drive_frames.calculate_truck_transforms(drive_frames.RETAIL_DEFAULT_TRUCK_TRANSFORM_INPUTS())
end

-- Authored part matrices from `82C0ADF0`, evaluated from stock collection inputs.
function drive_frames.default_body_transforms(): { RetailAffineTransform }
	return authored.authored_body_transforms(authored.AuthoredTransformInputs.STOCK())
end

-- Live center-of-mass transforms emitted by TU3 `Part::SetTransform`
-- (`0x82BD4318`) from the seven authored part transforms.
function drive_frames.default_live_body_transforms(): { RetailAffineTransform }
	local transforms = drive_frames.default_body_transforms()
	local deck_mass_frame = mass.retail_deck_mass_properties().local_mass_frame
	local deck = BodyId.Deck + 1
	transforms[deck] = compose_affine(
		transforms[deck],
		inverse_affine({ basis = deck_mass_frame.basis, translation = deck_mass_frame.translation })
	)
	return transforms
end

-- Quaternions written beside the live center-of-mass transforms by `Part::SetTransform`.
function drive_frames.default_live_body_orientations(): { RetailQuaternion }
	local out = {}
	for i, transform in drive_frames.default_live_body_transforms() do
		out[i] = drive_frames.retail_quaternion_from_basis(transform.basis)
	end
	return out
end

-- Matrix stage of `SkateboardBody::SetDriveFrames2`. The first input is the
-- parent/first body's world transform and the second the child's. TU3 writes
-- identity to the child frame (`0x82BD3A10`) and `transpose(parent.basis) *
-- child.basis` with the relative translation to the parent frame (`0x82BD3BD0`).
-- pub fn set_drive_frames_2(parent_world, child_world) -> RetailDriveFrames
function drive_frames.set_drive_frames_2(parent_world: RetailAffineTransform, child_world: RetailAffineTransform): RetailDriveFrames
	local parent_frame = relative_parent_transform(parent_world, child_world)
	return {
		body_a = { orientation = rigid_body.RetailQuaternion.IDENTITY(), translation = vector.create(0, 0, 0) },
		body_b = {
			orientation = drive_frames.retail_quaternion_from_basis(parent_frame.basis),
			translation = parent_frame.translation,
		},
	}
end

-- Zero-steering truck/deck frames in native drive order. TU3 consumes the
-- `+7776` transform before the `+7712` transform.
function drive_frames.default_truck_drive_frames(): { RetailDriveFrames }
	local base = drive_frames.default_truck_transforms()
	return {
		drive_frames.set_drive_frames_2(RetailAffineTransform.IDENTITY(), base[2]),
		drive_frames.set_drive_frames_2(RetailAffineTransform.IDENTITY(), base[1]),
	}
end

local function wheel_drive_frame(z_offset: number): RetailDriveFrames
	return {
		body_a = { orientation = rigid_body.RetailQuaternion.IDENTITY(), translation = vector.create(0, 0, 0) },
		body_b = { orientation = rigid_body.RetailQuaternion.IDENTITY(), translation = vector.create(0.0, 0.0, z_offset) },
	}
end

-- Wheel/truck drive frames emitted by the four `CreateWheelDrives` calls.
function drive_frames.default_wheel_drive_frames(): { RetailDriveFrames }
	local x = authored.AuthoredTransformInputs.STOCK().wheel_x_distance
	return { wheel_drive_frame(x), wheel_drive_frame(-x), wheel_drive_frame(x), wheel_drive_frame(-x) }
end

local function raw_frame(frame: RetailDriveFrame): drive_parameters.RetailDriveFrameRaw
	return {
		quaternion_lanes = {
			to_bits(frame.orientation.x),
			to_bits(frame.orientation.y),
			to_bits(frame.orientation.z),
			to_bits(frame.orientation.w),
		},
		translation_lanes = { to_bits(frame.translation.x), to_bits(frame.translation.y), to_bits(frame.translation.z), 0 },
	}
end

-- impl From<RetailDriveFrames> for RetailDriveFramesRaw
function drive_frames.raw_frames(frames: RetailDriveFrames): drive_parameters.RetailDriveFramesRaw
	return { body_a = raw_frame(frames.body_a), body_b = raw_frame(frames.body_b) }
end

-- ROBLOX: приватные помощники, которые зовут соседние модули в тестах.
drive_frames.inverse_affine = inverse_affine
drive_frames.compose_affine = compose_affine
drive_frames.relative_parent_transform = relative_parent_transform
drive_frames.transpose_relative_translation = transpose_relative_translation

return drive_frames
