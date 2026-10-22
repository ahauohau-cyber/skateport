--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_pose.rs (коммит 2e16697)
--
-- Complete TU3 board SetTransform 82C0B2C8 and its part/pose dependencies.
-- This changes poses only; it does not infer startup, settle joints or reset rates.
-- ROBLOX: PartPose, part_transform, set_part_transform — в @self/part;
-- orthonormalize_* — в @self/normalization.

local a = require("@self/arithmetic")
local normalization = require("@self/normalization")
local part = require("@self/part")

local board_pose = {}

-- Guest-order Ri/Up/At/translation vectors, including all packed fourth lanes.
export type PoseMatrix = { number }
export type PartPose = part.PartPose

-- Set deck part 6 to the orthonormalized request, then move parts 0..5 by its
-- common rigid delta. The separate hook receives the ORIGINAL requested pose.
-- ROBLOX: parts[i + 1] для части i; таблицы меняются на месте.
function board_pose.set_board_transform(parts: { PartPose }, hook: PartPose, requested: PoseMatrix)
	local old_deck = a.matrix(part.part_transform(parts[7]))
	local normalized = normalization.orthonormalize_rotation(requested)
	local delta = a.compose(a.matrix(normalized), a.inverse_rigid(old_deck))
	part.set_part_transform(parts[7], normalized)
	for i = 1, 6 do
		local moved = a.compose(delta, a.matrix(part.part_transform(parts[i])))
		part.set_part_transform(parts[i], normalization.orthonormalize_rotation(a.words(moved)))
	end
	part.set_part_transform(hook, requested)
end

return board_pose
