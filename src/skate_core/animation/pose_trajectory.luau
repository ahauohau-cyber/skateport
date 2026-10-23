--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/pose_trajectory.rs (коммит 2e16697)
--
-- TU3 FetchSys trajectory delta 82D178D8. This modifies only the trajectory SQT.

local rt = require("../../rt")
local native_arithmetic = require("../physics/native_arithmetic")
local sqt = require("./output/sqt")

local f32 = rt.f32
local mul_add = rt.mul_add

local pose_trajectory = {}

export type LoopTransform = { rotation: { number }, translation: { number } }

-- Fused cross arithmetic from 82D17908..17A24, without quaternion normalization.
local function cross(a: { number }, b: { number }): { number }
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
	}
end

-- pub(super) fn rotate
function pose_trajectory.rotate(q: { number }, v: { number }): { number }
	local vector = { v[1], v[2], v[3], 0.0 }
	local first = cross(q, vector)
	local intermediate = { mul_add(q[4], v[1], first[1]), mul_add(q[4], v[2], first[2]), mul_add(q[4], v[3], first[3]), 0.0 }
	local second = cross(q, intermediate)
	return { mul_add(2.0, second[1], v[1]), mul_add(2.0, second[2], v[2]), mul_add(2.0, second[3], v[3]) }
end

-- pub(super) fn multiply
function pose_trajectory.multiply(a: { number }, b: { number }): { number }
	local vector = cross(a, b)
	return {
		mul_add(a[1], b[4], mul_add(b[1], a[4], vector[1])),
		mul_add(a[2], b[4], mul_add(b[2], a[4], vector[2])),
		mul_add(a[3], b[4], mul_add(b[3], a[4], vector[3])),
		f32(f32(a[4] * b[4]) - native_arithmetic.dot3(a, b)),
	}
end

-- BatchFetch 82D20A40 selects the authored transform when the loop argument is
-- nonzero, otherwise identity. It does not exponentiate by the loop count.
function pose_trajectory.delta(current: sqt.Sqt, previous: sqt.Sqt, loop_transform: LoopTransform?): sqt.Sqt
	local lt = loop_transform or { rotation = { 0.0, 0.0, 0.0, 1.0 }, translation = { 0.0, 0.0, 0.0 } }
	local p = previous.rotation
	local inverse_previous = { -p[1], -p[2], -p[3], p[4] }
	local loop_displacement = pose_trajectory.rotate(current.rotation, lt.translation)
	local displacement = {}
	for i = 1, 3 do
		displacement[i] = f32(f32(loop_displacement[i] + current.translation[i]) - previous.translation[i])
	end
	local translation = pose_trajectory.rotate(inverse_previous, displacement)
	local rotation = pose_trajectory.multiply(pose_trajectory.multiply(lt.rotation, current.rotation), inverse_previous)
	return {
		scale = table.clone(current.scale),
		rotation = rotation,
		-- The extractor restores the channel weight separately for channel clips.
		translation = { translation[1], translation[2], translation[3], current.translation[4] },
	}
end

return pose_trajectory
