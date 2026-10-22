--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/joint.rs (коммит 2e16697)
--
-- TU3 joint pass 82AE2BC8..82AE2E44, reconstructed from direct disassembly.
-- Finite compiled coefficients are required; exceptional SIMD arithmetic is
-- not claimed to match hardware. The packed public boundary remains unchanged.

local rt = require("../../../rt")
local data = require("./joint_data")

local f32 = rt.f32
local read_column, write_column, xyz = data.read_column, data.write_column, data.xyz
local project_correction = data.project_correction
local ConstraintGeometry, ReactionState = data.ConstraintGeometry, data.ReactionState

local joint = {}

-- Native two-sided limit projection at 82AE2CCC..82AE2D00. These offsets are
-- preconditioned limit errors from the builder, not impulse min/max bounds.
-- An error inside the permitted interval produces zero correction.
local function joint_limit_correction(candidate: number, low: number, high: number): number
	local high_error = f32(high + candidate)
	local low_error = f32(low + candidate)
	local negative_correction = if high_error < 0.0 then high_error else 0.0
	local positive_correction = if low_error > 0.0 then low_error else 0.0
	return f32(positive_correction + negative_correction)
end

-- pub(super) fn solve(record: &mut [u32], a: &mut [u32], b: &mut [u32])
function joint.solve(record: { number }, a: { number }, b: { number })
	local geometry = ConstraintGeometry.decode(record)
	local body_a = ReactionState.decode(a)
	local body_b = ReactionState.decode(b)
	local relative_point, relative_angular = ConstraintGeometry.relative_corrections(geometry, body_a, body_b)
	local old_linear = read_column(record, 32)
	local old_angular = read_column(record, 48)
	local linear_candidate = project_correction(geometry.linear_projection, relative_point, old_linear)
	local angular_candidate = project_correction(geometry.angular_projection, relative_angular, old_angular)

	local linear_low = read_column(record, 160)
	local linear_high = read_column(record, 176)
	-- 82AE2C90..2CAC gathers angular bounds from packed fourth lanes. The
	-- fourth output duplicates the Z bound; joint accumulators store all lanes.
	local angular_low = { read_column(record, 96)[4], read_column(record, 112)[4], linear_low[4], linear_low[4] }
	local angular_high = { read_column(record, 128)[4], read_column(record, 144)[4], linear_high[4], linear_high[4] }
	local angular_impulse, linear_impulse = {}, {}
	for axis = 1, 4 do
		angular_impulse[axis] = joint_limit_correction(angular_candidate[axis], angular_low[axis], angular_high[axis])
	end
	for axis = 1, 4 do
		linear_impulse[axis] = joint_limit_correction(linear_candidate[axis], linear_low[axis], linear_high[axis])
	end
	local angular_change = xyz({
		f32(angular_impulse[1] - old_angular[1]),
		f32(angular_impulse[2] - old_angular[2]),
		f32(angular_impulse[3] - old_angular[3]),
	})
	local linear_change = xyz({
		f32(linear_impulse[1] - old_linear[1]),
		f32(linear_impulse[2] - old_linear[2]),
		f32(linear_impulse[3] - old_linear[3]),
	})

	-- The two candidates above used the same incoming body corrections. Native
	-- stores angular accumulation first, then linear accumulation, then applies
	-- the changes through both bodies' inverse mass and inertia.
	write_column(record, 48, angular_impulse)
	write_column(record, 32, linear_impulse)
	ConstraintGeometry.apply_impulse_changes(geometry, body_a, body_b, linear_change, angular_change)
	data.publish_reactions(body_a, body_b, a, b)
end


-- ROBLOX: та же итерация над записью в числах (см. joint_data.project_f).
local LC = table.create(4, 0)
local AC = table.create(4, 0)

function joint.solve_floats(r: { number }, a: { number }, b: { number })
	local px, py, pz, gx, gy, gz = data.relative_corrections_f(r, a, b)
	-- old_linear: слова 8..11, old_angular: 12..15; проекции: 16/24/32 и 20/28/36
	data.project_f(r, 16, 24, 32, px, py, pz, r, 8, LC, 0)
	data.project_f(r, 20, 28, 36, gx, gy, gz, r, 12, AC, 0)
	-- linear_low: слова 40..43, linear_high: 44..47
	local ll4, lh4 = r[44], r[48]
	local angular_low = { r[28], r[32], ll4, ll4 }
	local angular_high = { r[36], r[40], lh4, lh4 }
	local ol1, ol2, ol3 = r[9], r[10], r[11]
	local oa1, oa2, oa3 = r[13], r[14], r[15]
	for axis = 1, 4 do
		local ai = joint_limit_correction(AC[axis], angular_low[axis], angular_high[axis])
		local li = joint_limit_correction(LC[axis], r[40 + axis], r[44 + axis])
		-- Native stores angular accumulation first, then linear accumulation.
		r[12 + axis] = ai
		r[8 + axis] = li
	end
	data.apply_impulse_changes_f(
		r,
		a,
		b,
		f32(r[9] - ol1),
		f32(r[10] - ol2),
		f32(r[11] - ol3),
		f32(r[13] - oa1),
		f32(r[14] - oa2),
		f32(r[15] - oa3)
	)
end

return joint
