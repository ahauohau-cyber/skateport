--!strict
--!native
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


-- ROBLOX: та же итерация над записью в числах (см. joint_data.project_f).
local LR = table.create(4, 0)
local AR = table.create(4, 0)

function drive.solve_floats(r: { number }, a: { number }, b: { number })
	local px, py, pz, gx, gy, gz = data.relative_corrections_f(r, a, b)
	data.project_f(r, 16, 24, 32, px, py, pz, r, 8, LR, 0)
	data.project_f(r, 20, 28, 36, gx, gy, gz, r, 12, AR, 0)
	-- linear_target: слова 40..43, angular_target: 44..47
	local linear_limits1, linear_limits2, linear_limits3 = r[28], r[32], r[44]
	local angular_limits1, angular_limits2, angular_limits3 = r[36], r[40], r[48]
	local ol1, ol2, ol3, ol4 = r[9], r[10], r[11], r[12]
	local oa1, oa2, oa3, oa4 = r[13], r[14], r[15], r[16]
	local l1 = symmetric_impulse_limit(mul_add(LR[1], ol4, r[41]), linear_limits1)
	local g1 = symmetric_impulse_limit(mul_add(AR[1], oa4, r[45]), angular_limits1)
	local l2 = symmetric_impulse_limit(mul_add(LR[2], ol4, r[42]), linear_limits2)
	local g2 = symmetric_impulse_limit(mul_add(AR[2], oa4, r[46]), angular_limits2)
	local l3 = symmetric_impulse_limit(mul_add(LR[3], ol4, r[43]), linear_limits3)
	local g3 = symmetric_impulse_limit(mul_add(AR[3], oa4, r[47]), angular_limits3)
	-- 82AE2FB8/2FC4: XYZ из новых импульсов, четвёртая полоса (мягкость) — старая.
	r[9], r[10], r[11], r[12] = l1, l2, l3, ol4
	r[13], r[14], r[15], r[16] = g1, g2, g3, oa4
	data.apply_impulse_changes_f(
		r,
		a,
		b,
		f32(l1 - ol1),
		f32(l2 - ol2),
		f32(l3 - ol3),
		f32(g1 - oa1),
		f32(g2 - oa2),
		f32(g3 - oa3)
	)
end

return drive
