--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/physical_solve.rs (коммит 2e16697)
--
-- SkeletonIK::SolvePhysical82BF1480. Physical joint centers, not drive targets.

local rt = require("../../../rt")
local drive = require("./drive")
local m = require("./math")
local two_bone = require("./two_bone")
local sar = require("../../physics/skeleton_animation_record")
local skeleton_body = require("../../physics/skeleton_body")

local f32 = rt.f32
local line_mapping, normalize_safe = drive.line_mapping, drive.normalize_safe
local cross = m.cross
local compose_affine = sar.compose_affine
local transform_point = sar.transform_point
local SkeletonBody = skeleton_body.SkeletonBody

type F4 = { number }

local physical_solve = {}

local function sub(a: F4, b: F4): F4
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end

function physical_solve.solve(body: skeleton_body.SkeletonBody, geometry: drive.Geometry, end_part: number, offset: F4): boolean
	local middle_part = geometry.parents[end_part + 1]
	if middle_part == false then
		return false
	end
	local root_part = geometry.parents[(middle_part :: number) + 1]
	if root_part == false then
		return false
	end
	local mp, rp = middle_part :: number, root_part :: number
	local function point(part: number): F4
		return transform_point(body.record.pose[part + 1], geometry.inverse_part_frames[part + 1][4])
	end
	local root, middle, end_ = point(rp), point(mp), point(end_part)
	local t = {}
	for i = 1, 4 do
		t[i] = f32(end_[i] + offset[i])
	end
	local target = { value = t }
	local solved_middle = { value = { 0.0, 0.0, 0.0, 0.0 } }
	--Literal0 and180, no original-angle override and recursion budget1.
	--The source requires return0; its extended/invalid paths BOTH reject.
	if two_bone.solve(root, middle, end_, solved_middle, target, { minimum_degrees = 0.0, maximum_degrees = 180.0 }, false, 1) ~= "Solved" then
		return false
	end
	local original_normal = cross(sub(root, middle), sub(end_, middle))
	local solved_normal = cross(sub(root, solved_middle.value), sub(target.value, solved_middle.value))
	local sum = {}
	for i = 1, 4 do
		sum[i] = f32(original_normal[i] + solved_normal[i])
	end
	local normal = normalize_safe(sum)
	local mid_map = line_mapping(middle, end_, normal, solved_middle.value, target.value, normal)
	if mid_map == nil then
		return false
	end
	local root_map = line_mapping(root, middle, normal, root, solved_middle.value, normal)
	if root_map == nil then
		return false
	end
	local middle_frame = compose_affine(mid_map, body.record.pose[mp + 1])
	local root_frame = compose_affine(root_map, body.record.pose[rp + 1])
	--Unlike pre-physics drive solving, no extra orthonormalization precedes
	--the setter. The live body normalizes; the record keeps these frames.
	SkeletonBody.set_part_transform(body, mp, middle_frame)
	SkeletonBody.set_part_transform(body, rp, root_frame)
	return true
end

return physical_solve
