--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/skeleton.rs (коммит 2e16697)
--
-- Original Skeleton::UpdateRootTransformsWipeout82BDFBE8.

local rt = require("../../../rt")
local sar = require("../../physics/skeleton_animation_record")
local skeleton_root = require("../../physics/skeleton_root")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local inverse_rigid = skeleton_root.inverse_rigid

type Transform = sar.AnimationPartTransform

local skeleton = {}

local DT = from_bits(0x3C88_8889)

-- Reconstruct the root from the cached physical hips and animated hips,
-- then blend its predicted position toward the actual weighted physical COM.
-- This updates animation roots; it does not overwrite any solved body rates.
function skeleton.update_roots(
	roots: skeleton_root.SkeletonRootFrames,
	animation_hips: Transform,
	physical_hips: Transform,
	hips_velocity: { number },
	physical_com: { number },
	com_velocity: { number },
	state_time: number
)
	local inverse_hips = inverse_rigid(animation_hips)
	local predicted_hips = sar.copy_transform(physical_hips)
	local p = {}
	for i = 1, 4 do
		p[i] = mul_add(hips_velocity[i], DT, physical_hips[4][i])
	end
	predicted_hips[4] = p
	local root = sar.compose_affine(predicted_hips, inverse_hips)
	local weight = f32(state_time + DT)
	weight = if -weight >= 0.0 then 0.0 else weight
	weight = if f32(1.0 - weight) >= 0.0 then weight else 1.0
	local desired = table.clone(physical_com)
	desired[2] = f32(desired[2] + from_bits(0xBF4C_CCCD))
	local t = {}
	for i = 1, 4 do
		local predicted = mul_add(com_velocity[i], DT, root[4][i])
		t[i] = mul_add(desired[i], weight, f32(predicted * f32(1.0 - weight)))
	end
	root[4] = t
	roots.animation_to_world = root
	roots.world_to_animation = inverse_rigid(root)
end

return skeleton
