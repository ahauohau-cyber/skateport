--!strict
-- Сверка physics::grind_forces (без post/reckoning) и physics::grind_air с
-- настоящим Rust (golden/src/gforce.rs) + перенос grind_forces/tests.rs.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local gf = require("../../../src/skate_core/physics/grind_forces")
local grind_air = require("../../../src/skate_core/physics/grind_air")
local native_arithmetic = require("../../../src/skate_core/physics/native_arithmetic")
local golden = require("../../golden/gforce") :: any
assert(type(golden) == "table", tostring(golden))

local f32 = rt.f32
local dot3 = native_arithmetic.dot3
local X = { 1.0, 0.0, 0.0, 0.0 }
local Y = { 0.0, 1.0, 0.0, 0.0 }
local Z = { 0.0, 0.0, 1.0, 0.0 }
local O = { 0.0, 0.0, 0.0, 0.0 }

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end
local function near(a: number, b: number)
	assert(math.abs(a - b) < 0.0001, string.format("%g != %g", a, b))
end
-- ROBLOX: assert_eq! в Rust сравнивает f32 через ==, где -0.0 == 0.0.
local function eq(a: any, b: any): string?
	if type(b) == "table" then
		if type(a) ~= "table" or #a ~= #b then
			return ": форма"
		end
		for k, v in b do
			local d = eq(a[k], v)
			if d then
				return "." .. tostring(k) .. d
			end
		end
		return nil
	end
	if a ~= b then
		return string.format(": %s vs %s", tostring(a), tostring(b))
	end
	return nil
end
local function deep(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = deep(v)
	end
	return c
end

return function(report: harness.Report)
	harness.test(report, "grind_forces: material_and_geometry_are_independent_and_support_is_not_the_grind_normal", function()
		assert(gf.material_multiplier(13) == gf.material_multiplier(2))
		assert(gf.material_multiplier(999) == f32(1.3))
		for _, c in { { 0, 50.0 }, { 1, 40.0 }, { 2, 30.0 }, { 99, 30.0 } } do
			local force = gf.friction({ 4.0, 9.0, 0.0, 0.0 }, Y, { 0.0, 0.25, 0.0, 0.0 }, 0.5, true, gf.material_multiplier(4), c[1], { 50.0, 40.0, 30.0 })
			near(force[1], -0.25 * 0.5 * 1.9 * 0.6 * c[2] * 0.48)
			near(force[2], 0.0)
		end
		assert(not gf.friction_applies({ f32(0.001), 10.0, 0.0, 0.0 }, Y))
		assert(gf.friction_applies({ f32(0.002), 10.0, 0.0, 0.0 }, Y))
	end)
	harness.test(report, "grind_forces: pin_uses_signed_reference_and_skips_zero_error_instead_of_waking_body", function()
		assert(gf.lateral_pin({ X, Y, Z, O }, O, X, X, 800.0, 0.0, 0.0, true, 1.0) == nil)
		local force = gf.lateral_pin({ X, Y, Z, O }, X, X, { 2.0, 0.0, 0.0, 0.0 }, 100.0, 0.0, 0.0, true, 0.5) :: any
		near(force[1], (100.0 - 100.0 * 0.133 * 2.0) * 0.5)
		local graph = { x = { -1.0, 0.0, 0.5, 1.0 }, y = { 0.0, 0.0, 0.5, 0.75 } }
		assert(gf.pin_slope(Y, Y, 0.0, graph) == 0.75)
		assert(gf.pin_slope(Y, Y, f32(0.01), graph) == 1.0)
	end)
	local function slide_input(): any
		return {
			position = { 0.0, 0.0, 0.0, 0.0 }, point = O, direction = Z, across = X,
			velocity = { 2.0, 3.0, 4.0, 0.0 }, translation_2796 = 0.5,
			total_mass_2660 = 10.0, update_frequency = 30.0,
			preparing_jump = false, geometry_kind = 0,
		}
	end
	harness.test(report, "grind_forces: slide_force_order_mass_frequency_and_darkslide_translation", function()
		local input = slide_input()
		check(eq(gf.slide.control("Boardslide", input), { { 12.5, 0.0, 0.0, 0.0 }, { -40.0, 0.0, 0.0, 0.0 } }), "board")
		input.position[1] = f32(0.08)
		near(gf.slide.control("Darkslide", input)[1][1], 10.0)
		input.position[1] = f32(0.2)
		local f = gf.slide.control("Boardslide", input)
		near(f[1][1], -10.0)
		near(f[2][1], -600.0)
		near(f[2][2], 0.0)
		input.preparing_jump = true
		input.position[1] = f32(0.12)
		assert(#gf.slide.control("Boardslide", input) == 0)
	end)
	harness.test(report, "grind_forces: exit_lift_flag_is_independent_and_speed_equality_skips_force", function()
		local input: any = {
			position = X, point = O, across = X, normal = Y, velocity = O, geometry_kind = 2, high_side = Z,
			force_across = false, enable_lift = false, strength = 90.0, speed_limit = 0.75, lift = 125.0,
		}
		check(eq(gf.release.force(input), { 0.0, 0.0, -90.0, 0.0 }), "plain")
		input.enable_lift = true
		check(eq(gf.release.force(input), { 0.0, 125.0, -90.0, 0.0 }), "lift")
		input.force_across = true
		input.velocity = { 0.75, 0.0, 0.0, 0.0 }
		assert(gf.release.force(input) == nil)
	end)
	harness.test(report, "grind_forces: noise_preserves_draw_order_modulo_speed_cap_and_position", function()
		local a = gf.noise.angles(2.0, 1.0, { 0, 50000, 99999 })
		near(a[1], -0.06)
		near(a[2], 0.0)
		near(a[3], 0.0599988)
		check(u.diff(a, gf.noise.angles(20.0, 1.0, { 100000, 150000, 199999 })), "cap")
		local frame = { X, Y, Z, { 8.0, 9.0, 10.0, 1.0 } }
		local n = gf.noise.apply(frame, 2.0, 1.0, { 12345, 54321, 87654 })
		check(u.diff(n[4], frame[4]), "position")
		for i = 1, 3 do
			near(dot3(n[i], n[i]), 1.0)
		end
		near(dot3(n[1], n[2]), 0.0)
		check(u.diff(gf.noise.apply(frame, 0.0, 1.0, { 0, 1, 2 }), frame), "zero")
	end)

	harness.test(report, "grind_forces: pin, friction, support, noise, release, slide vs Rust", function()
		for n, c in golden.forces do
			local w = "forces#" .. n
			local pin = gf.lateral_pin(c.board, c.pin_point, c.across, c.velocity, c.strength, c.forward_offset, c.up_offset, c.forward_selected, c.slope_multiplier)
			assert((pin ~= nil) == c.pin_some, w .. " pin some")
			if pin then
				check(u.diff(pin, c.pin), w .. " pin")
			end
			check(u.diff(gf.material_multiplier(c.material), c.material_multiplier), w .. " material")
			check(u.diff(gf.friction(c.friction_velocity, c.grind_normal, c.support, c.time_multiplier, c.flagged, c.material_multiplier, c.kind, c.strengths), c.friction), w .. " friction")
			assert(gf.friction_applies(c.velocity, c.grind_normal) == c.friction_applies, w .. " applies")
			check(u.diff(gf.pin_slope(c.grind_normal, c.across, c.relief, c.pin_graph), c.pin_slope), w .. " pin_slope")
			local sp = gf.support.pin(c.grind_normal, c.relief)
			assert((sp ~= nil) == c.support_pin_some, w .. " support pin")
			check(u.diff(sp, c.support_pin), w .. " support pin")
			local cp = gf.support.coping(c.across, c.velocity, c.relief)
			assert((cp ~= nil) == c.coping_some, w .. " coping")
			check(u.diff(cp, c.coping), w .. " coping")
			local el = gf.support.exit_lean(c.across, c.exit_angle, c.lean_graph)
			assert((el ~= nil) == c.exit_lean_some, w .. " exit lean")
			check(u.diff(el, c.exit_lean), w .. " exit lean")
			check(u.diff(gf.support.truck_compensation(c.grind_normal, c.pitch), c.truck_compensation), w .. " truck")
		end
		for n, c in golden.noise do
			check(u.diff(gf.noise.angles(c.speed, c.amount, c.samples), c.angles), "noise#" .. n .. " angles")
			check(u.diff(gf.noise.apply(c.frame, c.speed, c.amount, c.samples), c.out), "noise#" .. n)
		end
		for n, c in golden.release do
			local out = gf.release.force(c.input)
			assert((out ~= nil) == c.some, "release#" .. n)
			check(u.diff(out, c.out), "release#" .. n)
		end
		for n, c in golden.slide do
			check(u.diff(gf.slide.control(c.kind, c.input), c.out), "slide#" .. n)
		end
	end)
	harness.test(report, "grind_forces: launch, orientation target/blend vs Rust", function()
		for n, c in golden.launch do
			local before = deep(c.jumper)
			local out = gf.launch.launch(c.jumper, c.input)
			check(u.diff(out, c.out), "launch#" .. n)
			check(u.diff(c.jumper, before), "launch#" .. n .. " входной jumper изменён")
		end
		for n, c in golden.orientation do
			local out, err = rt.catch(gf.orientation.target, c.family, c.input)
			if c.out.err ~= nil then
				check(u.diff(err, c.out.err), "orientation#" .. n .. " err")
			else
				assert(err == nil, tostring(err))
				check(u.diff(out, c.out), "orientation#" .. n)
				check(u.diff(gf.orientation.blend(c.current, out.frame), c.blend), "orientation#" .. n .. " blend")
			end
		end
	end)
	harness.test(report, "grind_air: contact_points, update (прогноз, выбор, углы), local_transform vs Rust", function()
		local adjusted = 0
		for n, c in golden.grind_air do
			check(u.diff(grind_air.DeckDimensions.contact_points(c.dims, c.tip), c.points), "grind_air#" .. n .. " points")
			local ga = grind_air.GrindAir.default()
			if c.started then
				grind_air.GrindAir.start(ga, c.target)
			end
			for k, st in c.steps do
				local w = string.format("grind_air#%d step#%d", n, k)
				local out, err = rt.catch(grind_air.GrindAir.update, ga, st.input, c.settings)
				if st.out.err ~= nil then
					check(u.diff(err, st.out.err), w .. " err")
				else
					assert(err == nil, w .. ": " .. tostring(err))
					assert((out ~= nil) == st.out.some, w .. " some")
					if out then
						adjusted += 1
						check(u.diff({ some = true, axis = out.axis, offset = out.offset, angles = out.angles }, st.out), w)
						check(u.diff(grind_air.pose.Adjustment.local_transform(out, st.pose), st.local_transform), w .. " local")
					end
				end
			end
		end
		table.insert(report.lines, string.format("      grind_air: %d случаев, корректировок %d", #golden.grind_air, adjusted))
	end)
end
