--!strict
-- Сверка physics/contact, physics/point_force и physics/rigid_body
-- с настоящим skate-core (эталон golden/src/bodies.rs).

local harness = require("../../harness")
local rt = require("../../../src/rt")
local contact = require("../../../src/skate_core/physics/contact")
local point_force = require("../../../src/skate_core/physics/point_force")
local rigid_body = require("../../../src/skate_core/physics/rigid_body")
local golden = require("../../golden/bodies")

local fb = rt.from_bits

local function V(t: { number }): vector
	return vector.create(fb(t[1]), fb(t[2]), fb(t[3]))
end

local function same(actual: number, bits: number): boolean
	return rt.to_bits(actual) == bits or (actual ~= actual and fb(bits) ~= fb(bits))
end

local function same_v(actual: vector, bits: { number }): boolean
	return same(actual.x, bits[1]) and same(actual.y, bits[2]) and same(actual.z, bits[3])
end

local function B(t: { { number } }): any
	return {
		columns = {
			{ fb(t[1][1]), fb(t[1][2]), fb(t[1][3]) },
			{ fb(t[2][1]), fb(t[2][2]), fb(t[2][3]) },
			{ fb(t[3][1]), fb(t[3][2]), fb(t[3][3]) },
		},
	}
end

local function same_b(actual: any, bits: { { number } }): boolean
	for c = 1, 3 do
		for r = 1, 3 do
			if not same(actual.columns[c][r], bits[c][r]) then
				return false
			end
		end
	end
	return true
end

local function Q(t: { number }): any
	return { x = fb(t[1]), y = fb(t[2]), z = fb(t[3]), w = fb(t[4]) }
end

local function same_q(actual: any, bits: { number }): boolean
	return same(actual.x, bits[1]) and same(actual.y, bits[2]) and same(actual.z, bits[3]) and same(actual.w, bits[4])
end

local function body(t: { any }): contact.RetailContactBodyState
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

local function same_ws(w: contact.RetailContactWorkspace, t: { any }): boolean
	return same_v(w.center_of_mass, t[1])
		and w.reaction_id == t[2]
		and same_v(w.inverse_inertia_full, t[3])
		and same(w.inverse_mass, t[4])
		and same_v(w.inverse_inertia_split, t[5])
		and w.state == t[6]
		and same_v(w.force_acceleration, t[7])
		and same(w.kinetic_energy, t[8])
		and same_v(w.torque_acceleration, t[9])
		and w.cool_down == t[10]
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
	harness.test(report, "contact: generate_contact vs Rust", function()
		count(report, "generate_contact", golden.contact, function(case)
			local i = case.input
			local c = contact.generate_contact({
				position_on_a = V(i[1]),
				position_on_b = V(i[2]),
				normal = V(i[3]),
				restitution = fb(i[4]),
				static_friction = fb(i[5]),
				dynamic_friction = fb(i[6]),
				tag = i[7],
			}, body(case.a), body(case.b))
			local o = case.out
			return same_v(c.tangent_0, o.t0)
				and same_v(c.tangent_1, o.t1)
				and same_v(c.relative_velocity, o.rv)
				and same_ws(c.body_a_workspace, o.wa)
				and same_ws(c.body_b_workspace, o.wb)
				and c.body_a_id == case.a[1]
				and c.body_b_id == case.b[1]
				and c.tag == i[7]
		end)
	end)

	harness.test(report, "contact: combine_contact_materials vs Rust", function()
		count(report, "combine_contact_materials", golden.material, function(case)
			local function m(t: { number }): contact.RetailContactMaterial
				return { static_friction = fb(t[1]), dynamic_friction = fb(t[2]), restitution = fb(t[3]) }
			end
			local c = contact.combine_contact_materials(m(case[1]), m(case[2]))
			local w = case[3]
			-- ROBLOX: биты полезной нагрузки NaN в f64 не сравниваем — только «это NaN».
			return same(c.static_friction, w[1]) and same(c.dynamic_friction, w[2]) and same(c.restitution, w[3])
		end)
	end)

	harness.test(report, "point_force: accumulate_point_force vs Rust", function()
		count(report, "accumulate_point_force", golden.point_force, function(case)
			local out = point_force.accumulate_point_force(
				{ force_acceleration = V(case[1]), torque_acceleration = V(case[2]), cool_down = case[3] },
				V(case[4]),
				V(case[5]),
				B(case[6]),
				fb(case[7]),
				B(case[8])
			)
			return same_v(out.force_acceleration, case[9]) and same_v(out.torque_acceleration, case[10]) and out.cool_down == 0
		end)
	end)

	harness.test(report, "rigid_body: integrate_body_rates vs Rust", function()
		count(report, "integrate_body_rates", golden.integrate, function(case)
			local b, n, s, r, o = case.body, case.inertia, case.sim, case.reactions, case.out
			local input: rigid_body.RetailBodyRates = {
				orientation = Q(b[1]),
				basis = B(b[9]),
				world_inverse_inertia = B(b[9]),
				position = V(b[2]),
				linear_velocity = V(b[3]),
				angular_velocity = V(b[4]),
				force_acceleration = V(b[5]),
				torque_acceleration = V(b[6]),
				kinetic_energy = fb(b[7]),
				cool_down = b[8],
			}
			local sim = rigid_body.RetailSimulationStep.fixed_60_hz(s[3], fb(s[4]), V(s[5]))
			if not same(sim.time_step, s[1]) or not same(sim.frequency, s[2]) then
				return false
			end
			local step = rigid_body.integrate_body_rates(input, {
				inverse_tensor = V(n[1]),
				inverse_mass = fb(n[2]),
				spherical = fb(n[3]),
				maximum_linear_velocity = fb(n[4]),
				maximum_angular_velocity = fb(n[5]),
				linear_drag = fb(n[6]),
				angular_drag = fb(n[7]),
			}, sim, {
				linear_displacement = V(r[1]),
				position_displacement = V(r[2]),
				angular_displacement = V(r[3]),
				orientation_displacement = V(r[4]),
			})
			local st = step.state
			return same_q(st.orientation, o[1])
				and same_b(st.basis, o[2])
				and same_b(st.world_inverse_inertia, o[3])
				and same_v(st.position, o[4])
				and same_v(st.linear_velocity, o[5])
				and same_v(st.angular_velocity, o[6])
				and same_v(st.force_acceleration, o[7])
				and same_v(st.torque_acceleration, o[8])
				and same(st.kinetic_energy, o[9])
				and st.cool_down == o[10]
				and same_v(step.orientation_displacement, o[11])
				and same(step.linear_speed_squared, o[12])
				and same(step.angular_speed_squared, o[13])
		end)
	end)

	harness.test(report, "rigid_body: orientation/basis/inertia helpers vs Rust", function()
		count(report, "integrate_orientation + basis + inertia", golden.orientation, function(case)
			local q = rigid_body.integrate_orientation(Q(case[1]), V(case[2]))
			local basis = rigid_body.basis_from_quaternion(Q(case[3]))
			local wi = rigid_body.world_inverse_inertia(B(case[4]), V(case[5]))
			local m = rigid_body.multiply_packed_world_inverse_inertia(rigid_body.pack_world_inverse_inertia(B(case[6])), V(case[7]))
			return same_q(q, case[3]) and same_b(basis, case[4]) and same_b(wi, case[6]) and same_v(m, case[8])
		end)
	end)
end
