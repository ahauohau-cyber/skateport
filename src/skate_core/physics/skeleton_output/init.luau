--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_output/mod.rs (коммит 2e16697)
--
-- Original TU3 physical pose worker82DB95E8, submitted by82DB6698.
-- Updates the existing animation buffers after the physical solve.

local rt = require("../../rt")
local board = require("@self/board")
local wobble = require("@self/wobble")
local correction = require("@self/correction")
local sar = require("./skeleton_animation_record")
local drive = require("../animation/foot_ik/drive")
local transforms = require("../animation/foot_ik/transforms")

local compose_affine = sar.compose_affine
local inverse_rigid = transforms.inverse_rigid

type Transform = sar.AnimationPartTransform

local skeleton_output = {}
skeleton_output.board = board
skeleton_output.wobble = wobble
skeleton_output.correction = correction

-- /// Stock SkeletonData ids, nearest physical ancestors, and volume inverses.
-- ROBLOX: bone_indices — индексы костей с нуля.
export type SkeletonOutput = {
	bone_indices: { number },
	geometry: drive.Geometry,
	board_bones: board.BoneIndices,
	board_settings: board.Settings,
}

export type Input = {
	-- Skeleton8016, all24 solved physical volume transforms in world space.
	physical_parts: { Transform },
	-- Skeleton11984, captured by82DB66C0 before submitting this worker.
	world_to_animation: Transform,
	board: board.Input,
}

local SkeletonOutput = {}
skeleton_output.SkeletonOutput = SkeletonOutput

-- /// Buffers must contain the evaluated stock animation for this same frame.
-- /// Unrepresented bones retain their animation. Board locals are modified
-- /// after the mapped globals; the worker does not rebuild the full hierarchy.
-- ROBLOX: Result<(), &str> -> rt.raise(строка); globals/locals меняются на месте.
function SkeletonOutput.publish(self: SkeletonOutput, input: Input, globals: { Transform }, locals: { Transform })
	local bad = #globals ~= #locals
	for _, i in self.bone_indices do
		if i >= #globals then
			bad = true
		end
	end
	for _, i in board.BoneIndices.all(self.board_bones) do
		if i >= #locals then
			bad = true
		end
	end
	if bad then
		rt.raise("physical pose output does not match the stock animation hierarchy")
	end
	--82DB96B8..97E4: volume -> animation bone -> animation space.
	for part = 1, 24 do
		local world = compose_affine(input.physical_parts[part], self.geometry.inverse_part_frames[part])
		globals[self.bone_indices[part] + 1] = compose_affine(input.world_to_animation, world)
	end
	--82DB97F4..9938 descends through the physical mapping. This inverse
	--is a rigid transpose, distinct from the authored volume inverse.
	for part = 24, 1, -1 do
		local bone = self.bone_indices[part]
		local parent = self.geometry.parents[part]
		if parent ~= false then
			locals[bone + 1] = compose_affine(inverse_rigid(globals[self.bone_indices[(parent :: number) + 1] + 1]), globals[bone + 1])
		else
			locals[bone + 1] = sar.copy_transform(globals[bone + 1])
		end
	end
	board.publish(input.board, self.board_settings, self.board_bones, locals)
end

return skeleton_output
