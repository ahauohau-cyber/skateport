--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_biped_air.rs (коммит 2e16697)
--
-- Biped Skeleton82BDDD70: COM-constrained animation root, not a body teleport.
-- Original S3 SHA431b8eba...0395a; ordinary PC arithmetic, not Xenon parity.

local rt = require("../../rt")
local sar = require("./skeleton_animation_record")
local skeleton_root = require("./skeleton_root")

local f32 = rt.f32
local mul_add = rt.mul_add
local compose_affine = sar.compose_affine
local copy_transform = sar.copy_transform
local orthonormalize = skeleton_root.orthonormalize
local SkeletonRootFrames = skeleton_root.SkeletonRootFrames

type Frame = sar.AnimationPartTransform
type F4 = { number }

local skeleton_biped_air = {}

-- ///82BDDDC8..DF54. The frame's translation is replaced by the trajectory COM
-- ///minus the rotated LOCAL animation COM10960. Mapped board12624 is independent.
-- ROBLOX: `mut frame` по значению -> копия; flags_2468: &mut u32 -> ячейка { value }.
function skeleton_biped_air.prepare(roots: skeleton_root.SkeletonRootFrames, frame_in: Frame, trajectory_position: F4, local_com: F4, mapped_board: Frame, flags_2476: number, flags_2468: { value: number }): Frame
	local frame = copy_transform(frame_in)
	roots.initialize_heading = true
	if bit32.band(flags_2476, 4) ~= 0 then
		for _, axis in { 1, 3 } do
			local c = frame[axis]
			frame[axis] = { -c[1], -c[2], -c[3], -c[4] }
		end
	end
	local t = {}
	for lane = 1, 4 do
		local x = f32(frame[1][lane] * local_com[1])
		local y = mul_add(frame[2][lane], local_com[2], x)
		t[lane] = f32(trajectory_position[lane] - mul_add(frame[3][lane], local_com[3], y))
	end
	frame[4] = t
	SkeletonRootFrames.reset_initial_alignment(roots, orthonormalize(frame))
	flags_2468.value = bit32.bor(flags_2468.value, 0x80000)
	return compose_affine(roots.animation_to_world, mapped_board)
end

return skeleton_biped_air
