--!strict
-- Сверка skate_game/physics/settings (PhysicsSettings.load) с копией Rust-кода
-- в golden/src/data.rs на настоящих данных skater-collections.json.

local harness = require("../../harness")
local u = require("../../util")
local collections = require("../../../src/skate_data/collections")
local settings_mod = require("../../../src/skate_game/physics/settings")

local fb = u.fb

local function same_mass(p: any, t: { any }): boolean
	local c = p.local_mass_frame.basis.columns
	local flat = { c[1][1], c[1][2], c[1][3], c[2][1], c[2][2], c[2][3], c[3][1], c[3][2], c[3][3] }
	for i = 1, 9 do
		if not u.same(flat[i], t[1][i]) then
			return false
		end
	end
	local d = p.dynamics
	return u.same_v(p.local_mass_frame.translation, t[2])
		and u.same_v(d.inverse_tensor, t[3])
		and u.same(d.inverse_mass, t[4])
		and u.same(d.spherical, t[5])
		and u.same(d.maximum_linear_velocity, t[6])
		and u.same(d.maximum_angular_velocity, t[7])
		and u.same(d.linear_drag, t[8])
		and u.same(d.angular_drag, t[9])
end

local function same_t(x: any, t: { any }): boolean
	local c = x.basis.columns
	local flat = { c[1][1], c[1][2], c[1][3], c[2][1], c[2][2], c[2][3], c[3][1], c[3][2], c[3][3] }
	for i = 1, 9 do
		if not u.same(flat[i], t[1][i]) then
			return false
		end
	end
	return u.same_v(x.translation, t[2])
end

return function(report: harness.Report)
	harness.test(report, "settings: PhysicsSettings.load на данных игры vs Rust", function()
		local ok_stock, stock = pcall(require, "../../../src/skate_data/stock")
		local ok_golden, golden = pcall(require, "../../golden/settings")
		if not ok_stock or not ok_golden then
			table.insert(report.lines, "      пропуск: нет данных игры (src/skate_data/stock)")
			return
		end
		local data = collections.expect(collections.Collections.from_data(stock :: any))
		local s, err = settings_mod.PhysicsSettings.load(data)
		harness.check(s ~= nil, tostring(err))
		assert(s)
		harness.check(same_mass(s.masses[1], golden.wheel), "wheel")
		harness.check(same_mass(s.masses[5], golden.truck), "truck")
		harness.check(same_mass(s.masses[7], golden.deck), "deck")
		local sim = s.step.simulation
		harness.check(
			u.same(sim.time_step, golden.sim[1]) and u.same(sim.frequency, golden.sim[2]) and u.same(sim.minimum_energy, golden.sim[3])
				and u.same_v(sim.gravity_acceleration, golden.sim[4]),
			"simulation"
		)
		harness.check(same_t(s.step.base_truck_transforms[1], golden.trucks[1]) and same_t(s.step.base_truck_transforms[2], golden.trucks[2]), "trucks")
		local d, g = s.step.truck_dynamics, golden.dynamics
		harness.check(
			u.same(d.linear.spring_or_max_velocity, g[1]) and u.same(d.linear.max_strength, g[2]) and d.linear.drive_type == g[3]
				and u.same(d.angular.spring_or_max_velocity, g[4]) and u.same(d.angular.max_strength, g[5]) and d.angular.drive_type == g[6],
			"truck dynamics"
		)
		for i, t in golden.authored do
			harness.check(same_t(s.authored[i], t), "authored " .. i)
		end
		harness.check(u.same(s.step.force_point_y_offset, golden.y_offset), "y offset")
		harness.check(s.step.iterations == 50, "iterations")
		local _ = fb
	end)
end
