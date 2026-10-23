--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/drive_frames.rs (коммит 2e16697)
--
-- BoneDrives::SetDriveFrames82BD6FD0. A common animation-space frame is
-- expressed in the child and parent coordinates before quaternion packing.

local rt = require("../../../rt")
local df = require("../drive_frames")
local drive_preparation = require("../drive_preparation")
local sar = require("../skeleton_animation_record")

local from_bits = rt.from_bits
local to_bits = rt.to_bits
local IDENTITY = sar.IDENTITY
local compose_affine = sar.compose_affine

type AnimationPartTransform = sar.AnimationPartTransform
type RetailDriveFrame = df.RetailDriveFrame
type RetailDriveFrames = df.RetailDriveFrames

local drive_frames = {}

local function pack(frame: AnimationPartTransform): RetailDriveFrame
	return {
		orientation = df.retail_quaternion_from_basis({
			columns = {
				{ frame[1][1], frame[1][2], frame[1][3] },
				{ frame[2][1], frame[2][2], frame[2][3] },
				{ frame[3][1], frame[3][2], frame[3][3] },
			},
		}),
		translation = vector.create(frame[4][1], frame[4][2], frame[4][3]),
	}
end

function drive_frames.bone_drive_frames(child_animation: AnimationPartTransform, inverse_child: AnimationPartTransform, inverse_parent: AnimationPartTransform): RetailDriveFrames
	local common = IDENTITY()
	common[4] = table.clone(child_animation[4])
	local child = compose_affine(inverse_child, common)
	local parent = compose_affine(inverse_parent, common)
	return { body_a = pack(child), body_b = pack(parent) }
end

-- /// Step_Solver2 normalizes each active pair before building the drive rows.
function drive_frames.prepare_bone_drive_frames(frames: RetailDriveFrames): RetailDriveFrames
	local words = table.create(16, 0)
	for i, frame in { frames.body_a, frames.body_b } do
		local q = frame.orientation
		local p = frame.translation
		local base = (i - 1) * 8
		local values = { q.x, q.y, q.z, q.w, p.x, p.y, p.z, 0.0 }
		for k = 1, 8 do
			words[base + k] = to_bits(values[k])
		end
	end
	drive_preparation.normalize_drive_frames(words)
	local function frame(offset: number): RetailDriveFrame
		local function f(i: number): number
			return from_bits(words[offset + i + 1])
		end
		return {
			orientation = { x = f(0), y = f(1), z = f(2), w = f(3) },
			translation = vector.create(f(4), f(5), f(6)),
		}
	end
	return { body_a = frame(0), body_b = frame(8) }
end

return drive_frames
