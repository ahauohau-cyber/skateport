--!strict
-- Сверка air::trajectory (query, launch, scoring, selector, grind_surface,
-- grind) с настоящим Rust (golden/src/traj.rs) + перенос Rust-тестов
-- grind_surface/tests.rs. Колбэки мира воспроизводятся по записи из Rust.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local trajectory = require("../../../src/skate_core/air/trajectory")
local golden = require("../../golden/traj") :: any
assert(type(golden) == "table", tostring(golden))

local gs = trajectory.grind_surface
local grind = trajectory.grind
local TrajectorySelector = trajectory.TrajectorySelector
local GrindSurface = gs.GrindSurface
local GeometryType = gs.GeometryType
local UP = { 0.0, 1.0, 0.0, 0.0 }

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

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end

local function input(): any
	return { start = { 0.0, 0.0, 0.0, 0.0 }, ["end"] = { 0.0, 0.0, 2.0, 0.0 }, reference = { 4.0, 5.0, 1.0, 0.0 }, optional_probe = nil, deck_center_to_truck = rt.f32(0.243) }
end
local function hit(y: number, fraction: number, surface: number): any
	return { position = { rt.f32(0.243), rt.f32(y), 1.0, 0.0 }, normal = UP, fraction = rt.f32(fraction), packed_surface = surface }
end
local function nones(): { any }
	return { false, false, false, false, false, false, false }
end

local function same_vec(a: { number }, b: { number }): boolean
	return u.diff(a, b) == nil
end

local function hit_from(rec: any): any
	if not rec.some then
		return nil
	end
	return { position = rec.position, normal = rec.normal, transform = rec.transform, surface = rec.surface, geometry = rec.geometry }
end

local function selector_state(sel: any): any
	local selection = sel.selection
	local st: any = {
		pending = sel.pending,
		valid = sel.valid,
		just_changed = sel.just_changed,
		all_predictions_missed = sel.all_predictions_missed,
		has_suggested = sel.suggested_normal ~= nil,
		suggested_normal = sel.suggested_normal,
		has_selection = selection ~= nil,
		has_selected_index = sel.selected_index ~= nil,
		selected_index = sel.selected_index,
		grind_locked_to_middle = sel.grind_locked_to_middle,
		has_grind_normal = sel.grind_normal ~= nil,
		grind_normal = sel.grind_normal,
		launch_info = sel.launch_info,
		requests = TrajectorySelector.requests(sel),
		com_displacement = TrajectorySelector.com_displacement(sel),
		local_com_position = TrajectorySelector.local_com_position(sel),
		local_board_position = TrajectorySelector.local_board_position(sel),
		board_position = TrajectorySelector.board_position(sel),
		query_origin = TrajectorySelector.query_origin(sel),
	}
	if selection then
		local x = table.clone(selection) :: any
		x.has_grind = selection.grind ~= nil
		st.selection = x
	end
	return st
end

return function(report: harness.Report)
	-- grind_surface/tests.rs
	harness.test(report, "grind_surface: seven_descriptors_preserve_native_index_and_world_down_probe", function()
		local value = input()
		value.optional_probe = { 2.0, 3.0, 4.0, 0.0 }
		local plan = gs.prepare(value) :: any
		assert(#plan.probes == 7)
		check(u.diff(plan.center, { 0.0, 0.0, 1.0, 0.0 }), "center")
		check(u.diff(plan.probes[1].start, { rt.f32(0.09), rt.f32(0.04), 1.0, 0.0 }), "p0")
		check(u.diff(plan.probes[5].start, { 0.0, rt.f32(0.04), 1.0, 0.0 }), "p4")
		check(u.diff(plan.probes[6].start, { rt.f32(0.09), rt.f32(0.09), 1.0, 0.0 }), "p5")
		assert(rt.to_bits(plan.probes[6].radius) == 0x3a83_126f)
		check(u.diff(plan.probes[7], { start = { 2.0, 3.0, 4.0, 0.0 }, ["end"] = { 2.0, -3.0, 4.0, 0.0 }, radius = 0.0 }), "p6")
		local called = {}
		gs.investigate(value, function(i, _)
			table.insert(called, i)
			return nil
		end)
		check(u.diff(called, { 0, 1, 2, 3, 4, 5, 6 }), "called")
	end)
	harness.test(report, "grind_surface: raised_cross_probe_not_center_probe_blocks_geometry", function()
		local plan = gs.prepare(input()) :: any
		local hits = nones()
		hits[5] = hit(0.0, 0.5, 17)
		local result = gs.resolve(plan, hits, 0)
		assert(result.kind == GeometryType.ThinRail)
		assert(result.audio_surface == 17 and result.physics_surface == 4)
		hits[6] = hit(0.0, 0.5, 17)
		result = gs.resolve(plan, hits, 0)
		assert(result.kind == GeometryType.Impossible)
		assert(bit32.btest(result.flags, GrindSurface.BLOCKED_CROSS_SECTION))
		assert(not bit32.btest(result.flags, GrindSurface.INVALID))
	end)
	harness.test(report, "grind_surface: strict_coarse_boundary_high_side_and_surface_codes", function()
		local plan = gs.prepare(input()) :: any
		local hits = nones()
		hits[2] = hit(0.0, 0.5, bit32.bor(23, bit32.lshift(8, 7)))
		hits[4] = hit(-0.1, 0.65, 9)
		local result = gs.resolve(plan, hits, 0)
		assert(result.kind == GeometryType.FatRail)
		assert(result.high_side[1] == -1.0)
		assert(result.audio_surface == 23 and result.physics_surface == 8)
		assert(bit32.btest(result.flags, GrindSurface.STAIR))
		hits[4].fraction = rt.from_bits(rt.to_bits(rt.f32(0.65)) - 1)
		assert(gs.resolve(plan, hits, 0).kind == GeometryType.Ledge)
	end)
	harness.test(report, "grind_surface: curb_requires_two_coarse_normals_and_strict_height_ranges", function()
		local plan = gs.prepare(input()) :: any
		local hits = nones()
		hits[1] = hit(0.0, 0.5, 17)
		hits[3] = hit(0.0, 0.5, 17)
		hits[4] = hit(-0.22, 0.9, 17)
		local result = gs.resolve(plan, hits, 0)
		assert(bit32.btest(result.flags, GrindSurface.CURB))
		assert(result.audio_surface == 4 and result.physics_surface == 2)
		hits[4].position[2] = rt.f32(-0.2)
		assert(not bit32.btest(gs.resolve(plan, hits, 0).flags, GrindSurface.CURB))
		hits[4].position[2] = rt.f32(-0.22)
		hits[4].normal = { 0.0, rt.f32(0.99), 0.0, 0.0 }
		assert(not bit32.btest(gs.resolve(plan, hits, 0).flags, GrindSurface.CURB))
	end)
	harness.test(report, "grind_surface: optional_query_flags_use_seventh_result_and_strict_drop_test", function()
		local value = input()
		value.optional_probe = { 0.0, 2.0, 1.0, 0.0 }
		local plan = gs.prepare(value) :: any
		local hits = nones()
		hits[7] = { position = { 1.0, -1.0, 1.0, 0.0 }, normal = { 1.0, 0.0, 0.0, 0.0 }, fraction = 0.5, packed_surface = 0 }
		local result = gs.resolve(plan, hits, 0)
		assert(bit32.btest(result.flags, GrindSurface.OPTIONAL_NORMAL_TEST))
		assert(bit32.btest(result.flags, GrindSurface.OPTIONAL_DROP_TEST))
		hits[7].position[2] = rt.f32(-0.99)
		assert(not bit32.btest(gs.resolve(plan, hits, 0).flags, GrindSurface.OPTIONAL_DROP_TEST))
	end)
	harness.test(report, "grind_surface: output_reuse_preserves_unassigned_bits_and_native_blocked_latch", function()
		local plan = gs.prepare(input()) :: any
		local old = bit32.bor(GrindSurface.INVALID, GrindSurface.CURB, GrindSurface.BLOCKED_CROSS_SECTION, 7)
		local result = gs.resolve(plan, nones(), old)
		assert(bit32.band(result.flags, 7) == 7)
		assert(bit32.btest(result.flags, GrindSurface.BLOCKED_CROSS_SECTION))
		assert(bit32.band(result.flags, bit32.bor(GrindSurface.INVALID, GrindSurface.CURB)) == 0)
	end)
	harness.test(report, "grind_surface: vertical_query_uses_native_no_submission_result", function()
		local value = input()
		value["end"] = { 0.0, 2.0, 0.0, 0.0 }
		local result = gs.investigate(value, function(_, _)
			error("native gate should not submit")
		end)
		assert(bit32.btest(result.flags, GrindSurface.INVALID))
		assert(result.audio_surface == 3 and result.physics_surface == 1)
		assert(result.kind == GeometryType.Impossible)
		assert(result.tilted_upmost_normal[3] == -1.0)
	end)
	harness.test(report, "grind_surface: tilted_normal_is_distinct_from_unrotated_upmost", function()
		local rail = { 0.0, 0.0, 1.0, 0.0 }
		check(u.diff(gs.orientation.tilted_normal(rail, UP, { 2.0, 4.0 }), UP), "straddle")
		local tilted = gs.orientation.tilted_normal(rail, UP, { 0.0, 0.0 })
		assert(tilted[2] == -1.0)
		assert(tilted[1] == 0.0)
	end)

	harness.test(report, "trajectory/query_trajectory: шаги, касание и средняя нормаль vs Rust", function()
		for n, case in golden.query do
			local k, j = 0, 0
			local out, err = rt.catch(trajectory.query_trajectory, deep(case.request), function(a, b, radius)
				k += 1
				local rec = case.lines[k]
				assert(rec, "лишний вызов line, случай " .. n)
				check(u.diff({ start = a, finish = b, radius = radius }, { start = rec.start, finish = rec.finish, radius = rec.radius }), "query#" .. n .. " line#" .. k)
				if case.out.err ~= nil and k == #case.lines then
					rt.raise(case.out.err)
				end
				return hit_from(rec.hit)
			end, function(p, radius)
				j += 1
				local rec = case.nearby[j]
				check(u.diff({ p, radius }, { rec.position, rec.radius }), "query#" .. n .. " nearby#" .. j)
				return deep(rec.triangles)
			end)
			assert(k == #case.lines and j == #case.nearby, "число вызовов, случай " .. n)
			if case.out.err ~= nil then
				check(u.diff(err, case.out.err), "query#" .. n .. " err")
			else
				assert(err == nil, tostring(err))
				check(u.diff(out, case.out.ok), "query#" .. n)
			end
		end
	end)

	harness.test(report, "trajectory/TrajectorySelector: launch, scoring, второй проход, reset vs Rust", function()
		local steps_total = 0
		for n, case in golden.selector do
			local s = case.settings
			local inp = case.input
			local sel = TrajectorySelector.new() :: any
			for si, step in case.steps do
				steps_total += 1
				local where = string.format("selector#%d step#%d (%s)", n, si, step.action)
				if step.action == "launch" then
					local out, err = rt.catch(TrajectorySelector.launch, sel, deep(step.info), inp, s)
					if step.out.err ~= nil then
						check(u.diff(err, step.out.err), where .. " err")
					else
						assert(err == nil, tostring(err))
						check(u.diff(out, step.out.ok), where .. " out")
					end
				elseif step.action == "complete" then
					local g, l = 0, 0
					local out, err = rt.catch(TrajectorySelector.complete_batch, sel, deep(step.results), inp, s, function(p, middle)
						g += 1
						local rec = step.grinds[g]
						assert(rec, where .. " лишний вызов grind")
						check(u.diff(p, rec.before), where .. " grind#" .. g .. " prediction")
						assert(middle == rec.middle, where .. " middle")
						local mu = rec.mutation
						if mu ~= nil then
							grind.apply_admitted_target(p, mu.candidate, mu.correction, mu.support, mu.reference_velocity, mu.maximum_adjust, mu.landing_velocity_scalar, mu.landing_max_angle)
						end
						local e = rec.eval
						return {
							target = if e.has_target then deep(e.target) else nil,
							score = e.score,
							distance = e.distance,
							effective_lock_distance = if e.has_lock then e.effective_lock_distance else nil,
							penalty_domain = e.penalty_domain,
						}
					end, function(a, b, radius)
						l += 1
						local rec = step.lines[l]
						assert(rec, where .. " лишний вызов line")
						check(u.diff({ start = a, finish = b, radius = radius }, { start = rec.start, finish = rec.finish, radius = rec.radius }), where .. " line#" .. l)
						if step.out.err ~= nil and l == #step.lines then
							rt.raise(step.out.err)
						end
						return hit_from(rec.hit)
					end)
					assert(g == #step.grinds and l == #step.lines, where .. " число вызовов колбэков")
					if step.out.err ~= nil then
						check(u.diff(err, step.out.err), where .. " err")
					else
						assert(err == nil, tostring(err))
						check(u.diff(out, step.out.ok), where .. " out")
					end
				elseif step.action == "reset" then
					TrajectorySelector.reset(sel)
				elseif step.action == "cancel" then
					TrajectorySelector.cancel_pending(sel)
				else
					check(u.diff(TrajectorySelector.update_without_completion(sel), step.out), where .. " out")
				end
				check(u.diff(selector_state(sel), step.state), where .. " state")
			end
		end
		table.insert(report.lines, string.format("      selector: %d случаев, %d шагов", #golden.selector, steps_total))
	end)

	harness.test(report, "trajectory/grind_surface: prepare, investigate, resolve, landing vs Rust", function()
		for n, case in golden.surface do
			local where = "surface#" .. n
			local ci = case.input
			local value = { start = ci.start, ["end"] = ci.finish, reference = ci.reference, optional_probe = ci.optional_probe, deck_center_to_truck = ci.deck_center_to_truck }
			local plan = gs.prepare(value)
			assert((plan ~= nil) == case.has_plan, where .. " has_plan")
			if plan then
				check(u.diff(plan, case.plan), where .. " plan")
			end
			local k = 0
			local out, err = rt.catch(gs.investigate, value, function(i, probe): any
				k += 1
				local rec = case.calls[k]
				assert(rec, where .. " лишний probe")
				assert(i == rec.index, where .. " index")
				check(u.diff(probe, rec.probe), where .. " probe#" .. k)
				if case.out.err ~= nil and k == #case.calls then
					rt.raise(case.out.err)
				end
				local h = rec.hit
				if not h.some then
					return nil
				end
				return { fraction = h.fraction, position = h.position, normal = h.normal, packed_surface = h.packed_surface }
			end)
			assert(k == #case.calls, where .. " число probe")
			if case.out.err ~= nil then
				check(u.diff(err, case.out.err), where .. " err")
			else
				assert(err == nil, tostring(err))
				check(u.diff(out, case.out.ok), where .. " out")
			end
			if case.resolved ~= nil then
				check(u.diff(gs.resolve(plan :: any, case.resolved.hits, case.prev), case.resolved.out), where .. " resolve")
			end
			local ld = case.landing
			local up = deep(ld.up_in)
			local o = deep(ld.out_in)
			gs.update_landing_orientation(if ld.has_surface then ld.surface else nil, ld.takeoff, ld.grind_position, up, o)
			check(u.diff(up, ld.up), where .. " landing up")
			check(u.diff(o, ld.out), where .. " landing out")
		end
	end)

	harness.test(report, "trajectory/grind: box filter, plane time, candidates, take_best, admission vs Rust", function()
		for n, case in golden.box_filter do
			check(u.diff(grind.trajectory_box_filter(case.indices, case.primitives, case.takeoff), case.out), "box#" .. n)
		end
		for n, case in golden.plane_time do
			local out = grind.descending_plane_time(case.t, case.point, case.normal)
			assert((out ~= nil) == case.some, "plane#" .. n .. " some")
			if out ~= nil then
				check(u.diff(out, case.out), "plane#" .. n)
			end
		end
		for n, case in golden.consider do
			for k, e in case.edges do
				local c = grind.consider_grind_primitive(case.prediction, e.edge, k - 1, e.padding)
				assert((c ~= nil) == e.some, "consider#" .. n .. " edge#" .. k .. " some")
				if c ~= nil then
					check(u.diff(c, e.out), "consider#" .. n .. " edge#" .. k)
				end
			end
			local list = deep(case.list)
			local picks = {}
			while true do
				local c = grind.take_best_grind(list, case.difficulty, case.penalty)
				if c == nil then
					break
				end
				table.insert(picks, c.primitive)
			end
			check(u.diff(picks, case.picks), "take_best#" .. n)
		end
		for n, case in golden.admission do
			local where = "admission#" .. n
			local pred = deep(case.prediction)
			local cell = { value = if case.lock_in.some then case.lock_in.value else nil }
			local out = grind.admitted_displacement(pred, case.candidate, case.edge, case.reference_velocity, case.processed_592, case.surface, case.limits, cell)
			assert((out ~= nil) == case.some, where .. " some")
			if out ~= nil then
				check(u.diff(out, case.out), where .. " out")
			end
			assert((cell.value ~= nil) == case.has_lock, where .. " has_lock")
			if cell.value ~= nil then
				check(u.diff(cell.value, case.lock), where .. " lock")
			end
			local ap = case.applied
			if ap ~= nil then
				grind.apply_admitted_target(pred, case.candidate, out :: any, ap.support, case.reference_velocity, ap.maximum_adjust, ap.landing_velocity_scalar, ap.landing_max_angle)
				check(u.diff(pred, ap.after), where .. " applied")
			end
		end
	end)
	local _ = same_vec
end
