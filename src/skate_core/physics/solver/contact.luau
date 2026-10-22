--!strict
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

return contact
