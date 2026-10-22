--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/contact.rs (коммит 2e16697)
--
-- Contact iteration, TU3 82AE2914..82AE2B8C.
--
-- The compiled row boundary is decoded once. Calculations preserve the source
-- operation order for finite inputs; console exceptional-float behavior has
-- not been established by hardware captures.

local rt = require("../../../rt")
local data = require("./contact_data")

local f32 = rt.f32
local mul_add = rt.mul_add
local ContactRows = data.ContactRows
local Reaction = data.Reaction

local contact = {}

-- ROBLOX: `&mut [u32]` — таблицы слов меняются на месте.
-- pub(super) fn solve(record: &mut [u32], a: &mut [u32], b: &mut [u32])
function contact.solve(record: { number }, a: { number }, b: { number })
	local rows = ContactRows.read(record)
	local reaction_a = Reaction.read(a)
	local reaction_b = Reaction.read(b)
	local position_a = Reaction.point_position(reaction_a, rows.arm_a)
	local position_b = Reaction.point_position(reaction_b, rows.arm_b)
	local velocity_a = Reaction.point_velocity(reaction_a, rows.arm_a)
	local velocity_b = Reaction.point_velocity(reaction_b, rows.arm_b)
	local position_error, total_error = {}, {}
	for i = 1, 4 do
		position_error[i] = f32(position_b[i] - position_a[i])
	end
	for i = 1, 4 do
		total_error[i] = f32(f32(velocity_b[i] - velocity_a[i]) + position_error[i])
	end

	-- 82AE2A94..2ABC: the first three impulses respond to combined position
	-- and velocity correction. The fourth responds only to position error.
	local candidate = {}
	for lane = 0, 3 do
		local err = if lane == 3 then position_error else total_error
		local impulse = f32(rows.accumulated[lane + 1] + rows.target[lane + 1])
		local coefficient_lane = if lane == 3 then 0 else lane
		for component = 1, 3 do
			impulse = mul_add(rows.correction_columns[component][coefficient_lane + 1], err[component], impulse)
		end
		candidate[lane + 1] = impulse
	end

	-- 82AE2AC4..2B08: friction uses the preceding normal impulse. Crossing
	-- the static limit selects the dynamic limit. The two normal lanes use
	-- [0, f32::MAX]. Ordered comparisons also preserve the native selectors.
	local next_impulse = {}
	for lane = 0, 3 do
		local normal = if lane == 1 or lane == 2 then rows.accumulated[1] else 0.0
		local upper_offset = if lane == 0 or lane == 3 then rt.F32_MAX else 0.0
		local static_low = mul_add(-rows.static_friction, normal, 0.0)
		local static_high = mul_add(rows.static_friction, normal, upper_offset)
		local dynamic_low = mul_add(-rows.dynamic_friction, normal, 0.0)
		local dynamic_high = mul_add(rows.dynamic_friction, normal, upper_offset)
		local c = candidate[lane + 1]
		local lower_selected = if c >= static_low then c else dynamic_low
		next_impulse[lane + 1] = if static_high >= c then lower_selected else dynamic_high
	end
	local change = {}
	for lane = 1, 4 do
		change[lane] = f32(next_impulse[lane] - rows.accumulated[lane])
	end
	ContactRows.publish_impulses(rows, record, next_impulse)
	Reaction.apply_contact(reaction_a, rows, change, true)
	Reaction.apply_contact(reaction_b, rows, change, false)
	Reaction.write(reaction_a, a)
	Reaction.write(reaction_b, b)
end


-- ROBLOX: та же итерация над записью, уже переведённой в числа (r[k + 1] =
-- f32::from_bits(words[k])). Решатель (packed.solve) переводит записи один раз
-- до итераций и обратно один раз после: в Rust from_bits/to_bits бесплатны, в
-- Luau нет. Порядок операций и округлений тот же, что в solve выше.
local PA, PB, VA, VB = table.create(4, 0), table.create(4, 0), table.create(4, 0), table.create(4, 0)
local POS_ERR, TOT_ERR, CAND, NEXT, CHANGE =
	table.create(4, 0), table.create(4, 0), table.create(4, 0), table.create(4, 0), table.create(4, 0)
local NEXT_LANE = { 1, 2, 0, 3 }
local PREV_LANE = { 2, 0, 1, 3 }

-- point_correction(arm, linear, angular): arm — в r с смещения ao,
-- linear/angular — в реакции x со смещений lo/go (смещения в словах).
local function point_correction_f(r: { number }, ao: number, x: { number }, lo: number, go: number, out: { number })
	for lane = 0, 3 do
		local n, p = NEXT_LANE[lane + 1], PREV_LANE[lane + 1]
		local first = mul_add(x[go + n + 1], r[ao + p + 1], x[lo + lane + 1])
		out[lane + 1] = mul_add(-x[go + p + 1], r[ao + n + 1], first)
	end
end

local function apply_contact_f(r: { number }, x: { number }, body_a: boolean)
	-- angular_a[axis] — строка 8 + 3·axis, angular_b[axis] — строка 9 + 3·axis
	local base = if body_a then 32 else 36
	local inverse_mass = r[base + 4]
	local c1, c2, c3, c4 = CHANGE[1], CHANGE[2], CHANGE[3], CHANGE[4]
	for lane = 1, 4 do
		local linear_impulse = mul_add(r[28 + lane], c1, 0.0)
		linear_impulse = mul_add(r[40 + lane], c2, linear_impulse)
		linear_impulse = mul_add(r[52 + lane], c3, linear_impulse)
		local position_impulse = mul_add(r[28 + lane], c4, 0.0)
		local r0, r1, r2 = r[base + lane], r[base + 12 + lane], r[base + 24 + lane]
		if body_a then
			local ang = mul_add(r0, c1, x[8 + lane])
			ang = mul_add(r1, c2, ang)
			x[8 + lane] = mul_add(r2, c3, ang)
			x[12 + lane] = mul_add(r0, c4, x[12 + lane])
			x[lane] = mul_add(linear_impulse, inverse_mass, x[lane])
			x[4 + lane] = mul_add(position_impulse, inverse_mass, x[4 + lane])
		else
			local ang = mul_add(-r0, c1, x[8 + lane])
			ang = mul_add(-r1, c2, ang)
			x[8 + lane] = mul_add(-r2, c3, ang)
			x[12 + lane] = mul_add(-r0, c4, x[12 + lane])
			x[lane] = mul_add(-linear_impulse, inverse_mass, x[lane])
			x[4 + lane] = mul_add(-position_impulse, inverse_mass, x[4 + lane])
		end
	end
end

-- ROBLOX: r — 64 числа записи, a/b — 16 чисел реакций; меняются на месте.
function contact.solve_floats(r: { number }, a: { number }, b: { number })
	-- позиции: arm + position/orientation (строки 1 и 3), скорости: linear/angular (0 и 2)
	point_correction_f(r, 0, a, 4, 12, PA)
	point_correction_f(r, 4, b, 4, 12, PB)
	point_correction_f(r, 0, a, 0, 8, VA)
	point_correction_f(r, 4, b, 0, 8, VB)
	for i = 1, 4 do
		POS_ERR[i] = f32(PB[i] - PA[i])
	end
	for i = 1, 4 do
		TOT_ERR[i] = f32(f32(VB[i] - VA[i]) + POS_ERR[i])
	end
	for lane = 0, 3 do
		local err = if lane == 3 then POS_ERR else TOT_ERR
		local impulse = f32(r[21 + lane] + r[25 + lane])
		local coefficient_lane = if lane == 3 then 0 else lane
		for component = 0, 2 do
			impulse = mul_add(r[(2 + component) * 4 + coefficient_lane + 1], err[component + 1], impulse)
		end
		CAND[lane + 1] = impulse
	end
	local static_friction, dynamic_friction = r[16], r[20]
	local accumulated_normal = r[21]
	for lane = 0, 3 do
		local normal = if lane == 1 or lane == 2 then accumulated_normal else 0.0
		local upper_offset = if lane == 0 or lane == 3 then rt.F32_MAX else 0.0
		local static_low = mul_add(-static_friction, normal, 0.0)
		local static_high = mul_add(static_friction, normal, upper_offset)
		local dynamic_low = mul_add(-dynamic_friction, normal, 0.0)
		local dynamic_high = mul_add(dynamic_friction, normal, upper_offset)
		local c = CAND[lane + 1]
		local lower_selected = if c >= static_low then c else dynamic_low
		NEXT[lane + 1] = if static_high >= c then lower_selected else dynamic_high
	end
	for lane = 1, 4 do
		CHANGE[lane] = f32(NEXT[lane] - r[20 + lane])
		r[20 + lane] = NEXT[lane]
	end
	apply_contact_f(r, a, true)
	apply_contact_f(r, b, false)
end

return contact
