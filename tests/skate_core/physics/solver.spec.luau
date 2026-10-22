--!strict
-- Сверка решателя (contact_build, проходы contact/joint/drive, drive_solver::builder,
-- drive_preparation) с настоящим skate-core (golden/src/solver.rs).

local harness = require("../../harness")
local rt = require("../../../src/rt")
local contact = require("../../../src/skate_core/physics/contact")
local contact_solver = require("../../../src/skate_core/physics/contact_solver")
local drive_solver = require("../../../src/skate_core/physics/drive_solver")
local drive_preparation = require("../../../src/skate_core/physics/drive_preparation")
local solver = require("../../../src/skate_core/physics/solver")
local golden = require("../../golden/solver")

local fb = rt.from_bits
local tb = rt.to_bits
local DT = fb(0x3C88_8889)

local function V(t: { number }): vector
	return vector.create(fb(t[1]), fb(t[2]), fb(t[3]))
end
local function F3(t: { number }): { number }
	return { fb(t[1]), fb(t[2]), fb(t[3]) }
end
local function Q(t: { number }): any
	return { x = fb(t[1]), y = fb(t[2]), z = fb(t[3]), w = fb(t[4]) }
end
local function B(t: { { number } }): any
	return { columns = { F3(t[1]), F3(t[2]), F3(t[3]) } }
end
local function same(actual: number, bits: number): boolean
	return tb(actual) == bits or (actual ~= actual and fb(bits) ~= fb(bits))
end
local function same_v(actual: vector, bits: { number }): boolean
	return same(actual.x, bits[1]) and same(actual.y, bits[2]) and same(actual.z, bits[3])
end
local function same_f3(actual: { number }, bits: { number }): boolean
	return same(actual[1], bits[1]) and same(actual[2], bits[2]) and same(actual[3], bits[3])
end
local function same_words(a: { number }, b: { number }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #b do
		if a[i] ~= b[i] then
			-- NaN с другой полезной нагрузкой считаем совпадением
			local x, y = fb(a[i]), fb(b[i])
			if not (x ~= x and y ~= y) then
				return false
			end
		end
	end
	return true
end

local function contact_body(t: { any }): contact.RetailContactBodyState
	return {
		contact_body_id = t[1],
		center_of_mass = V(t[2]),
		reaction_id = t[3],
		inverse_inertia_full = V(t[4]),
		inverse_mass = fb(t[5]),
		inverse_inertia_split = V(t[6]),
		state = t[7],
		force_acceleration = V(t[8]),
		kinetic_energy = fb(t[9]),
		torque_acceleration = V(t[10]),
		cool_down = t[11],
		linear_velocity = V(t[12]),
		angular_velocity = V(t[13]),
	}
end

local function drive_body(t: { any }): any
	return {
		reaction_index = t[1],
		state = t[2],
		orientation = Q(t[3]),
		basis = B(t[4]),
		center_of_mass = V(t[5]),
		linear_velocity = V(t[6]),
		angular_velocity = V(t[7]),
		force_acceleration = V(t[8]),
		torque_acceleration = V(t[9]),
		inverse_mass = fb(t[10]),
		world_inverse_inertia = { full = V(t[11]), split = V(t[12]) },
	}
end

local function drive_params(t: { number }): any
	return { spring_or_max_velocity = fb(t[1]), damping = fb(t[2]), max_strength = fb(t[3]), drive_type = t[4] }
end

local function rows_from(t: { any }, fa: any, fbb: any): any
	return {
		frame_a_body = fa,
		frame_b_body = fbb,
		arm_a = V(t[1]),
		arm_b = V(t[2]),
		linear_axes = { V(t[3][1]), V(t[3][2]), V(t[3][3]) },
		angular_axes = { V(t[4][1]), V(t[4][2]), V(t[4][3]) },
		linear_inverse_effective_mass = F3(t[5]),
		angular_inverse_effective_mass = F3(t[6]),
		linear_softness = fb(t[7]),
		angular_softness = fb(t[8]),
		linear_target_impulse = F3(t[9]),
		angular_target_impulse = F3(t[10]),
		linear_maximum_impulse = F3(t[11]),
		angular_maximum_impulse = F3(t[12]),
		accumulated_linear_impulse = F3(t[13]),
		accumulated_angular_impulse = F3(t[14]),
	}
end

local function same_rows(d: any, t: { any }): boolean
	return same_v(d.arm_a, t[1])
		and same_v(d.arm_b, t[2])
		and same_v(d.linear_axes[1], t[3][1])
		and same_v(d.linear_axes[2], t[3][2])
		and same_v(d.linear_axes[3], t[3][3])
		and same_v(d.angular_axes[1], t[4][1])
		and same_v(d.angular_axes[2], t[4][2])
		and same_v(d.angular_axes[3], t[4][3])
		and same_f3(d.linear_inverse_effective_mass, t[5])
		and same_f3(d.angular_inverse_effective_mass, t[6])
		and same(d.linear_softness, t[7])
		and same(d.angular_softness, t[8])
		and same_f3(d.linear_target_impulse, t[9])
		and same_f3(d.angular_target_impulse, t[10])
		and same_f3(d.linear_maximum_impulse, t[11])
		and same_f3(d.angular_maximum_impulse, t[12])
		and same_f3(d.accumulated_linear_impulse, t[13])
		and same_f3(d.accumulated_angular_impulse, t[14])
end

local function reaction(t: { { number } }): any
	return {
		linear_displacement = V(t[1]),
		position_displacement = V(t[2]),
		angular_displacement = V(t[3]),
		orientation_displacement = V(t[4]),
	}
end

local function same_reaction(r: any, t: { { number } }): boolean
	return same_v(r.linear_displacement, t[1])
		and same_v(r.position_displacement, t[2])
		and same_v(r.angular_displacement, t[3])
		and same_v(r.orientation_displacement, t[4])
end

local function count(report: harness.Report, name: string, cases: { any }, check: (any) -> boolean)
	local bad, first = 0, nil
	for index, case in cases do
		if not check(case) then
			bad += 1
			first = first or index
		end
	end
	table.insert(report.lines, string.format("      %s: %d случаев, расхождений %d", name, #cases, bad))
	harness.check(bad == 0, "первое расхождение в случае " .. tostring(first))
end

return function(report: harness.Report)
	harness.test(report, "drive_solver: build_drive_rows vs Rust", function()
		count(report, "build_drive_rows", golden.drive_rows, function(case)
			local f = case.frames
			local d = drive_solver.build_drive_rows(drive_body(case.a), drive_body(case.b), {
				body_a = { orientation = Q(f[1]), translation = V(f[2]) },
				body_b = { orientation = Q(f[3]), translation = V(f[4]) },
			}, { linear = drive_params(case.dynamics[1]), angular = drive_params(case.dynamics[2]) }, DT)
			return same_rows(d, case.rows)
		end)
	end)

	harness.test(report, "contact_solver: build_contact_jacobian vs Rust", function()
		count(report, "build_contact_jacobian", golden.contacts, function(case)
			local i = case.input
			local c = contact.generate_contact({
				position_on_a = V(i[1]),
				position_on_b = V(i[2]),
				normal = V(i[3]),
				restitution = fb(i[4]),
				static_friction = fb(i[5]),
				dynamic_friction = fb(i[6]),
				tag = i[7],
			}, contact_body(case.a), contact_body(case.b))
			local j = contact_solver.build_contact_jacobian(c, DT)
			return same_words(j.words, case.words) and j.reaction_index_a == case.ra and j.reaction_index_b == case.rb
		end)
	end)

	harness.test(report, "solver: solve_constraints (contact → joint → drive) vs Rust", function()
		count(report, "solve_constraints", golden.solve, function(case)
			local contacts = {}
			for k, c in case.contacts do
				contacts[k] = { words = table.clone(c[1]), reaction_index_a = c[2], reaction_index_b = c[3] }
			end
			local joints = {}
			for k, j in case.joints do
				joints[k] = { jacobian = { words = table.clone(j[1]) }, reaction_a = j[2], reaction_b = j[3] }
			end
			local drives = {}
			for k, d in case.drives do
				drives[k] = rows_from(d.rows, drive_body(d.fa), drive_body(d.fb))
			end
			local reactions = {}
			for k, r in case.reactions do
				reactions[k] = reaction(r)
			end
			solver.solve_constraints(contacts, joints, drives, reactions, case.iterations)
			local o = case.out
			for k, c in contacts do
				if not same_words(c.words, o.contacts[k]) then
					return false
				end
			end
			for k, j in joints do
				if not same_words(j.jacobian.words, o.joints[k]) then
					return false
				end
			end
			for k, d in drives do
				if not same_f3(d.accumulated_linear_impulse, o.drives[k][1]) or not same_f3(d.accumulated_angular_impulse, o.drives[k][2]) then
					return false
				end
			end
			for k, r in reactions do
				if not same_reaction(r, o.reactions[k]) then
					return false
				end
			end
			return true
		end)
	end)

	harness.test(report, "drive_preparation: normalize_drive_frames vs Rust", function()
		count(report, "normalize_drive_frames", golden.normalize, function(case)
			local w = table.clone(case[1])
			drive_preparation.normalize_drive_frames(w)
			return same_words(w, case[2])
		end)
	end)
end
