--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/drive.rs (коммит 2e16697)
--
-- TU3 drive pass 82AE2E78..82AE30D8, reconstructed from direct disassembly.
-- Finite compiled coefficients are required; exceptional SIMD arithmetic is
-- not claimed to match hardware. Linear/angular softness lanes are retained.

local rt = require("../../../rt")
local data = require("./joint_data")

local f32 = rt.f32
local mul_add = rt.mul_add
local read_column, write_column, xyz = data.read_column, data.write_column, data.xyz
local project_correction = data.project_correction
local ConstraintGeometry, ReactionState = data.ConstraintGeometry, data.ReactionState

local drive = {}

local function symmetric_impulse_limit(candidate: number, limit: number): number
	local upper_limited = if candidate < limit then candidate else limit
	local negative_limit = f32(0.0 - limit)
	return if upper_limited > negative_limit then upper_limited else negative_limit
end

-- pub(super) fn solve(record: &mut [u32], a: &mut [u32], b: &mut [u32])
function drive.solve(record: { number }, a: { number }, b: { number })
	local geometry = ConstraintGeometry.decode(record)
	local body_a = ReactionState.decode(a)
	local body_b = ReactionState.decode(b)
	local relative_point, relative_angular = ConstraintGeometry.relative_corrections(geometry, body_a, body_b)
	local old_linear = read_column(record, 32)
	local old_angular = read_column(record, 48)
	local linear_response = project_correction(geometry.linear_projection, relative_point, old_linear)
	local angular_response = project_correction(geometry.angular_projection, relative_angular, old_angular)
	local linear_target = read_column(record, 160)
	local angular_target = read_column(record, 176)
	local linear_limits = { read_column(record, 96)[4], read_column(record, 112)[4], linear_target[4] }
	local angular_limits = { read_column(record, 128)[4], read_column(record, 144)[4], angular_target[4] }

	local linear_impulse = table.clone(old_linear)
	local angular_impulse = table.clone(old_angular)
	for axis = 1, 3 do
		local linear_candidate = mul_add(linear_response[axis], old_linear[4], linear_target[axis])
		local angular_candidate = mul_add(angular_response[axis], old_angular[4], angular_target[axis])
		linear_impulse[axis] = symmetric_impulse_limit(linear_candidate, linear_limits[axis])
		angular_impulse[axis] = symmetric_impulse_limit(angular_candidate, angular_limits[axis])
	end
	local linear_change = xyz({
		f32(linear_impulse[1] - old_linear[1]),
		f32(linear_impulse[2] - old_linear[2]),
		f32(linear_impulse[3] - old_linear[3]),
	})
	local angular_change = xyz({
		f32(angular_impulse[1] - old_angular[1]),
		f32(angular_impulse[2] - old_angular[2]),
		f32(angular_impulse[3] - old_angular[3]),
	})
	-- 82AE2FB8/2FC4 select XYZ from the new impulses while retaining each
	-- accumulator's fourth (softness) lane from its old value.
	write_column(record, 32, linear_impulse)
	write_column(record, 48, angular_impulse)
	ConstraintGeometry.apply_impulse_changes(geometry, body_a, body_b, linear_change, angular_change)
	data.publish_reactions(body_a, body_b, a, b)
end

return drive
