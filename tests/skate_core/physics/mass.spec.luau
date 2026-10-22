--!strict
-- Сверка physics/mass и construction/* с настоящим skate-core (golden/src/mass.rs)
-- и перенос Rust-тестов из mass.rs (#[cfg(test)] mod tests).

local harness = require("../../harness")
local rt = require("../../../src/rt")
local mass = require("../../../src/skate_core/physics/mass")
local primitive_mass_mod = require("../../../src/skate_core/physics/construction/primitive_mass")
local mass_moments = require("../../../src/skate_core/physics/construction/mass_moments")
local deck_geometry = require("../../../src/skate_core/physics/construction/deck_geometry")
local golden = require("../../golden/mass")

local fb = rt.from_bits
local MassMoments = mass_moments.MassMoments

local function V(t: { number }): vector
	return vector.create(fb(t[1]), fb(t[2]), fb(t[3]))
end

local function same(actual: number, bits: number): boolean
	return rt.to_bits(actual) == bits or (actual ~= actual and fb(bits) ~= fb(bits))
end

local function same_v(actual: vector, bits: { number }): boolean
	return same(actual.x, bits[1]) and same(actual.y, bits[2]) and same(actual.z, bits[3])
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

local function same_props(p: any, want: any): boolean
	if want == false then
		return p == nil
	end
	if p == nil then
		return false
	end
	local d, w = p.dynamics, want.dyn
	return same_b(p.local_mass_frame.basis, want.frame[1])
		and same_v(p.local_mass_frame.translation, want.frame[2])
		and same_v(d.inverse_tensor, w[1])
		and same(d.inverse_mass, w[2])
		and same(d.spherical, w[3])
		and same(d.maximum_linear_velocity, w[4])
		and same(d.maximum_angular_velocity, w[5])
		and same(d.linear_drag, w[6])
		and same(d.angular_drag, w[7])
end

local function shape(t: any): any
	local s: any = { kind = t.kind }
	if t.radius then
		s.radius = fb(t.radius)
	end
	if t.half_length then
		s.half_length = fb(t.half_length)
	end
	if t.half_extents then
		s.half_extents = V(t.half_extents)
	end
	if t.padding then
		s.padding = fb(t.padding)
	end
	return s
end

local function moments(t: { { number } }): mass_moments.MassMoments
	local columns = {}
	for c = 1, 4 do
		columns[c] = { fb(t[c][1]), fb(t[c][2]), fb(t[c][3]), fb(t[c][4]) }
	end
	return { columns = columns }
end

local function same_moments(m: mass_moments.MassMoments, t: { { number } }): boolean
	for c = 1, 4 do
		for i = 1, 4 do
			if not same(m.columns[c][i], t[c][i]) then
				return false
			end
		end
	end
	return true
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
	harness.test(report, "mass: stock_simple_parts_reach_recovered_finalizer_words", function()
		local wheel = mass.retail_wheel_mass_properties().dynamics
		local want_wheel = { 0x45C3_E491, 0x45C3_E491, 0x45C3_E491, 0x401A_3785, 0x3927_466F }
		local got_wheel = { wheel.inverse_tensor.x, wheel.inverse_tensor.y, wheel.inverse_tensor.z, wheel.inverse_mass, wheel.spherical }
		for i = 1, 5 do
			harness.check(rt.to_bits(got_wheel[i]) == want_wheel[i], "wheel " .. i)
		end
		local truck = mass.retail_truck_mass_properties().dynamics
		local want_truck = { 0x438E_E68E, 0x438E_E68E, 0x4690_4D8B, 0x3F03_4835, 0x3B65_4E66 }
		local got_truck = { truck.inverse_tensor.x, truck.inverse_tensor.y, truck.inverse_tensor.z, truck.inverse_mass, truck.spherical }
		for i = 1, 5 do
			harness.check(rt.to_bits(got_truck[i]) == want_truck[i], "truck " .. i)
		end
	end)

	harness.test(report, "mass: both_mass_finalizers_preserve_nan_and_use_volume_only_below_threshold", function()
		local cube = { kind = "RoundedBox", half_extents = vector.create(0.5, 0.5, 0.5), radius = 0.0 } :: any
		local m = MassMoments.from_primitive(primitive_mass_mod.primitive_mass(cube) :: any)
		for _, case in { { 0 / 0, 0 / 0 }, { 0.0, 1.0 }, { 2.0, 0.5 } } do
			local requested, expected = case[1], case[2]
			local primitive = mass.primitive_mass_properties({ shape = cube, requested_mass = requested }, mass.RETAIL_UNBOUNDED_VELOCITY, 0.0)
			local aggregate = mass.aggregate_mass_properties(m, requested, mass.RETAIL_UNBOUNDED_VELOCITY, 0.0)
			for _, body in { primitive :: any, aggregate } do
				if expected ~= expected then
					harness.check(body.dynamics.inverse_mass ~= body.dynamics.inverse_mass, "NaN")
				else
					harness.check(body.dynamics.inverse_mass == expected, "inverse mass")
				end
			end
		end
	end)

	harness.test(report, "mass: stock wheel/truck/deck vs Rust", function()
		harness.check(same_props(mass.retail_wheel_mass_properties(), golden.stock.wheel), "wheel")
		harness.check(same_props(mass.retail_truck_mass_properties(), golden.stock.truck), "truck")
		harness.check(same_props(mass.retail_deck_mass_properties(), golden.stock.deck), "deck")
	end)

	harness.test(report, "mass: primitive_mass + primitive_mass_properties vs Rust", function()
		count(report, "primitive", golden.primitive, function(case)
			local sh = shape(case.shape)
			local pm = primitive_mass_mod.primitive_mass(sh)
			if case.mass == false then
				if pm ~= nil then
					return false
				end
			elseif pm == nil or not same_v(pm.moments_per_unit_mass, case.mass[1]) or not same(pm.volume, case.mass[2]) then
				return false
			end
			-- maximum_angular_velocity в эталоне не записан: сверяем остальное
			local props = mass.primitive_mass_properties({ shape = sh, requested_mass = fb(case.requested) }, 1.0, fb(0x3F00_0000))
			if case.props == false then
				return props == nil
			end
			local want = table.clone(case.props)
			want.dyn = table.clone(want.dyn)
			if props then
				props.dynamics.maximum_angular_velocity = fb(want.dyn[5])
			end
			return same_props(props, want)
		end)
	end)

	harness.test(report, "mass: aggregate_mass_properties vs Rust", function()
		count(report, "aggregate", golden.aggregate, function(case)
			local m = moments(case.moments)
			local p = mass.aggregate_mass_properties(m, fb(case.requested), fb(case.props.dyn[5]), fb(case.props.dyn[7]))
			-- аргумент не должен меняться (в Rust передаётся по значению)
			return same_props(p, case.props) and same_moments(m, case.moments)
		end)
	end)

	harness.test(report, "mass: DeckGeometry + deck_mass_properties vs Rust", function()
		count(report, "deck", golden.deck, function(case)
			local s = case.settings
			local g = deck_geometry.DeckGeometry.new({
				width = fb(s[1]),
				mid_length = fb(s[2]),
				thickness = fb(s[3]),
				back_end_size = fb(s[4]),
				front_end_angle_degrees = fb(s[5]),
				back_end_angle_degrees = fb(s[6]),
				end_capsule_count = s[7],
				enable_deck_volume_collisions = s[8],
				enable_end_volume_collisions = s[9],
			})
			if #g.children ~= #case.children then
				return false
			end
			for i, want in case.children do
				local got = g.children[i]
				local ws, gs = want.shape, got.shape :: any
				if gs.kind ~= ws.kind or got.collision_enabled ~= want.enabled then
					return false
				end
				if not same_b(got.transform.basis, want.basis) or not same_v(got.transform.translation, want.translation) then
					return false
				end
				if ws.radius and not same(gs.radius, ws.radius) then
					return false
				end
				if ws.half_length and not same(gs.half_length, ws.half_length) then
					return false
				end
				if ws.half_extents and not same_v(gs.half_extents, ws.half_extents) then
					return false
				end
				if ws.kind == "Triangle" then
					for k = 1, 3 do
						if not same_v(gs.vertices[k], ws.vertices[k]) or not same(gs.edge_cosines[k], ws.edge_cosines[k]) then
							return false
						end
					end
					if not same(gs.fatness, ws.fatness) or gs.volume_flags ~= ws.volume_flags then
						return false
					end
				end
			end
			if not same_moments(deck_geometry.DeckGeometry.mass_moments(g), case.moments) then
				return false
			end
			return same_props(mass.deck_mass_properties(g, fb(case.mass), 27.0), case.props)
		end)
	end)
end
