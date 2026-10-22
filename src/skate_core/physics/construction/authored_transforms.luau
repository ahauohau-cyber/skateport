--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/construction/authored_transforms.rs (коммит 2e16697)
--
-- Authored seven-part matrices passed to Part::SetTransform by TU3 82C0ADF0.
-- This function is called by construction/reset before world-pose publication.
-- ROBLOX: в Rust это подмодуль drive_frames (`#[path]`, `use super::RetailAffineTransform`).

local rt = require("../../../rt")
local trigonometry = require("../../trigonometry")

local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

local authored_transforms = {}

-- Resolved stock attributes read by InitializeTransforms. Attribute lookup
-- failure selects the engine's runtime fallback scalar at830D0850; callers
-- resolving absent attributes must supply that actual initialized value.
export type AuthoredTransformInputs = {
	-- physicsdeck.DeckMidLength; full attribute key C94D65091DCB828B.
	deck_mid_length: number,
	-- physicswheels.WheelXDist; full attribute key 5A84C435DC340AF8.
	wheel_x_distance: number,
	-- physicstrucks layout+4, +8, +16.
	truck_z_position_front: number,
	truck_z_position_back: number,
	truck_y_position: number,
}

local AuthoredTransformInputs = {}
authored_transforms.AuthoredTransformInputs = AuthoredTransformInputs

-- Actual stock XML scalar words, not constructor output snapshots.
function AuthoredTransformInputs.STOCK(): AuthoredTransformInputs
	return {
		deck_mid_length = from_bits(0x3f17_0a3d),
		wheel_x_distance = from_bits(0x3dc2_8f5c),
		truck_z_position_front = from_bits(0xbd54_fdf4),
		truck_z_position_back = from_bits(0xbd54_fdf4),
		truck_y_position = from_bits(0xbd67_6c8b),
	}
end

-- Complete authored matrix calculation, in body order wheels0..3, trucks4..5,
-- deck6. Native publication order is deck6 first, then bodies0..5. Front truck
-- is identity; back truck uses the actual SinCos(pi/2) result about Y. The
-- tiny polynomial cosine residual is retained, never replaced by exact zero.
-- pub fn authored_body_transforms(input) -> [RetailAffineTransform; 7]
function authored_transforms.authored_body_transforms(input: AuthoredTransformInputs): { any }
	-- ROBLOX: подключение внутри функции — drive_frames подключает этот файл.
	local drive_frames = require("../drive_frames") :: any
	-- fmadds82C0AEE4 and fnmsubs82C0AF60: one rounded multiply/add each.
	local front_z = mul_add(input.deck_mid_length, 0.5, input.truck_z_position_front)
	local back_z = -mul_add(input.deck_mid_length, 0.5, input.truck_z_position_back)
	local y = input.truck_y_position
	local x = input.wheel_x_distance
	local transforms = {}
	for part = 1, 7 do
		transforms[part] = drive_frames.RetailAffineTransform.IDENTITY()
	end
	local translations = {
		vector.create(-x, y, front_z),
		vector.create(x, y, front_z),
		vector.create(-x, y, back_z),
		vector.create(x, y, back_z),
		vector.create(0.0, y, front_z),
		vector.create(0.0, y, back_z),
	}
	for part, translation in translations do
		transforms[part].translation = translation
	end
	-- Literal pi/2 word at820C69C8. Shared polynomial82473A08 was re-audited
	-- against fresh disassembly and constants822F97C0..822F985F for this path.
	local sin, cos = trigonometry.sin_cos(from_bits(0x3fc9_0fdb))
	transforms[6].basis = { columns = { { cos, 0.0, -sin }, { 0.0, 1.0, 0.0 }, { sin, 0.0, cos } } }
	return transforms
end

-- Native affine rows, ready for reset_skateboard's `authored` argument. All
-- fourth lanes are zero, including the affine translation:82C0ADF0 explicitly
-- clears them. This does not perform the downstream COM/quaternion conversion.
-- pub fn authored_body_pose_records(input) -> [[u32; 16]; 7]
function authored_transforms.authored_body_pose_records(input: AuthoredTransformInputs): { { number } }
	local out = {}
	for i, transform in authored_transforms.authored_body_transforms(input) do
		local words = rt.zeros(16)
		for axis = 0, 2 do
			for component = 0, 2 do
				words[axis * 4 + component + 1] = to_bits(transform.basis.columns[axis + 1][component + 1])
			end
		end
		words[13] = to_bits(transform.translation.x)
		words[14] = to_bits(transform.translation.y)
		words[15] = to_bits(transform.translation.z)
		out[i] = words
	end
	return out
end

return authored_transforms
