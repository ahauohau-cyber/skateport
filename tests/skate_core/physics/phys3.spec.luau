--!strict
-- Сверка physics: board_animation, board_dynamic_normal, centre_of_mass_filter,
-- deck_angular_correction, filtered_state, foot_physical_output,
-- ground_hang_geometry с Rust (golden/src/phys3.rs) + перенос Rust-тестов.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local name_mod = require("../../../src/skate_core/animation/skeleton_input/name")
local board_animation = require("../../../src/skate_core/physics/board_animation")
local bdn = require("../../../src/skate_core/physics/board_dynamic_normal")
local board_ground = require("../../../src/skate_core/physics/board_ground")
local com = require("../../../src/skate_core/physics/centre_of_mass_filter")
local dac = require("../../../src/skate_core/physics/deck_angular_correction")
local fs = require("../../../src/skate_core/physics/filtered_state")
local fpo = require("../../../src/skate_core/physics/foot_physical_output")
local hang = require("../../../src/skate_core/physics/ground_hang_geometry")
local record = require("../../../src/skate_core/physics/skeleton_body/record")
local golden = require("../../golden/phys3") :: any
assert(type(golden) == "table", tostring(golden))

local f32 = rt.f32
local BoardAnimation = board_animation.BoardAnimation
local BoardDynamicNormal = bdn.BoardDynamicNormal
local BoardGroundState = board_ground.BoardGroundState
local FilteredState = fs.FilteredState
local GrindState = fs.GrindState
local C = fs.FilteredCategory

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

local function filtered_input(state: number, category: number): any
	return {
		physics_state = state, physics_category = category,
		anything_in_contact = false, physics_surface_type = 0,
		wall_ride_exit = false, targeting_grind = false,
		offboard_has_landed = false, offboard_on_deck = false,
		grind = GrindState.default(), last_grind_distance = 0.0,
	}
end

local function body(): any
	return {
		orientation = { x = 0.0, y = 0.0, z = 0.0, w = 1.0 },
		basis = { columns = { { 1.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, { 0.0, 0.0, 1.0 } } },
		world_inverse_inertia = { columns = { { 3.0, f32(0.2), f32(0.1) }, { f32(0.2), 2.0, f32(0.3) }, { f32(0.1), f32(0.3), 1.0 } } },
		position = vector.zero,
		linear_velocity = vector.zero,
		angular_velocity = vector.zero,
		force_acceleration = vector.zero,
		torque_acceleration = vector.zero,
		kinetic_energy = 0.0,
		cool_down = 3,
	}
end

local function dn_settings(): any
	return {
		speed_damping = 0.0,
		up_vector_damping = 1.0,
		maximum_delta = 10.0,
		speed_scale = 1.0,
		maximum_delta_vs_speed = { x = { 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0 }, y = table.create(8, 1.0) },
	}
end

local function filled(v: vector): { vector }
	return table.create(7, v)
end

return function(report: harness.Report)
	-- Rust: deck_angular_correction tests.
	harness.test(report, "deck_angular_correction: thrown_board_correction_brakes_axis_overshoot_without_touching_other_motion", function()
		local state = body()
		state.angular_velocity = vector.create(4, 3, 5)
		dac.apply_axis_displacement(state, vector.create(0, f32(0.02), 0))
		assert(math.abs(state.torque_acceleration.y + 108) < 0.0001)
		assert(math.abs(state.torque_acceleration.x) < 0.0001)
		assert(math.abs(state.torque_acceleration.z) < 0.0001)
		assert(state.angular_velocity == vector.create(4, 3, 5))
		assert(state.cool_down == 0)
		local reverse = body()
		reverse.angular_velocity = vector.create(0, -3, 0)
		dac.apply_axis_displacement(reverse, vector.create(0, f32(0.02), 0))
		assert(math.abs(reverse.torque_acceleration.y - 252) < 0.0001)
	end)

	harness.test(report, "deck_angular_correction: correction_enters_accumulator_and_respects_existing_angular_motion", function()
		local state = body()
		dac.apply_angular_displacement(state, vector.create(f32(0.02), f32(0.01), f32(-0.03)))
		assert(math.abs(state.torque_acceleration.x - 72) < 0.0001)
		assert(math.abs(state.torque_acceleration.y - 36) < 0.0001)
		assert(math.abs(state.torque_acceleration.z + 108) < 0.0001)
		assert(state.cool_down == 0)
		local overshoot = body()
		overshoot.angular_velocity = vector.create(0, 3, 0)
		dac.apply_limited_displacement(overshoot, vector.create(0, f32(0.02), 0))
		assert(overshoot.torque_acceleration == vector.zero)
		local against = body()
		against.angular_velocity = vector.create(0, -3, 0)
		dac.apply_limited_displacement(against, vector.create(0, f32(0.02), 0))
		assert(math.abs(against.torque_acceleration.y - 72) < 0.0001)
		local ground = body()
		ground.basis = { columns = { { 0, -1, 0 }, { 1, 0, 0 }, { 0, 0, 1 } } }
		dac.apply_ground_body_torque(ground)
		assert(math.abs(ground.torque_acceleration.x + 1.815) < 0.00001)
		assert(math.abs(ground.torque_acceleration.y + 0.121) < 0.00001)
		assert(math.abs(ground.torque_acceleration.z + 0.0605) < 0.00001)
		assert(ground.force_acceleration == vector.zero)
	end)

	-- Rust: tests/board_dynamic_normal_history.rs.
	harness.test(report, "board_dynamic_normal: retained_normal_consumes_sampled_acceleration", function()
		local contacts = BoardGroundState.default()
		contacts.wheel_contact_count = 1
		contacts.parts[1].in_contact = true
		BoardGroundState.sample_accelerations(contacts, filled(vector.create(1, 0, 0)), 1.0)
		local filter = BoardDynamicNormal.new()
		BoardDynamicNormal.update(filter, contacts, vector.zero, 0.0, dn_settings())
		assert(filter.normal.x > 0.9999)
		assert(math.abs(filter.normal.y) < 0.0001 and math.abs(filter.normal.z) < 0.0001)
		local once = filter.normal
		BoardDynamicNormal.update(filter, contacts, vector.zero, 0.0, dn_settings())
		assert(math.abs(filter.normal.x - once.x) < 0.0001)
	end)

	harness.test(report, "board_dynamic_normal: body_history_reset_does_not_reset_retained_normal_or_delta", function()
		local contacts = BoardGroundState.default()
		BoardGroundState.sample_accelerations(contacts, filled(vector.create(5, 0, 0)), 1.0)
		local filter = BoardDynamicNormal.new()
		filter.normal = vector.create(0.6, 0.8, 0.0)
		filter.delta = vector.create(0.1, 0.2, 0.3)
		BoardDynamicNormal.update(filter, contacts, vector.zero, 0.0, dn_settings())
		local rn, rd = filter.normal, filter.delta
		contacts = BoardGroundState.default()
		BoardDynamicNormal.update(filter, contacts, vector.zero, 0.0, dn_settings())
		assert(filter.normal == rn and filter.delta == rd)
		contacts.wheel_contact_count = 1
		contacts.parts[1].in_contact = true
		BoardGroundState.sample_accelerations(contacts, filled(vector.create(2, 0, 0)), 1.0)
		BoardDynamicNormal.update(filter, contacts, vector.zero, 0.0, dn_settings())
		assert(filter.normal.x > 0.9999)
		assert(math.abs(filter.normal.y) < 0.0001 and math.abs(filter.normal.z) < 0.0001)
	end)

	harness.test(report, "board_dynamic_normal: fourth_wheel_contact_does_not_enter_native_three_wheel_sum", function()
		local contacts = BoardGroundState.default()
		contacts.wheel_contact_count = 1
		contacts.parts[4].in_contact = true
		contacts.accelerations[4] = vector.create(9, 0, 0)
		local filter = BoardDynamicNormal.new()
		BoardDynamicNormal.update(filter, contacts, vector.zero, 0.0, dn_settings())
		assert(math.abs(filter.normal.x) < 0.0001)
	end)

	-- Rust: tests/filtered_state.rs.
	harness.test(report, "filtered_state: stairs_preserve_ground_then_contact_returns_air_to_ground", function()
		local state = FilteredState.default()
		local stairs = filtered_input(100, 100)
		stairs.physics_surface_type = 8
		assert(FilteredState.update(state, stairs).category == C.Ground)
		for _ = 1, 9 do
			assert(FilteredState.update(state, filtered_input(200, 200)).category == C.Ground)
		end
		assert(FilteredState.update(state, filtered_input(200, 200)).category == C.Air)
		local touching = filtered_input(200, 200)
		touching.anything_in_contact = true
		local output = FilteredState.update(state, touching)
		assert(output.category == C.Ground)
		assert(output.previous_category == C.Air)
		FilteredState.update(state, filtered_input(702, 700))
		assert(FilteredState.update(state, filtered_input(200, 200)).category == C.Air)
	end)

	harness.test(report, "filtered_state: nonspecific_keeps_grind_metadata_and_leaving_clears_only_publication", function()
		local state = FilteredState.default()
		local grinding = filtered_input(403, 400)
		grinding.grind = {
			kind = 3, scorable_id = 21, name = name_mod.encode("fs smith"), scoring_name = name_mod.encode("smith"),
			on_front = true, crouch = 0.25, pathed_guid = { 0x12345678, 0x9abcdef0 }, local_guid = { 0xfedcba98, 0x76543210 },
		}
		local entered = FilteredState.update(state, grinding)
		check(u.diff(entered.grind, grinding.grind), "entered")
		local retained = FilteredState.update(state, filtered_input(701, 700))
		assert(retained.grinding)
		check(u.diff(retained.grind, grinding.grind), "retained")
		local left = FilteredState.update(state, filtered_input(100, 100))
		assert(not left.grinding)
		check(u.diff(left.grind, GrindState.default()), "left")
		check(u.diff(state.cached_grind, grinding.grind), "cached")
		FilteredState.reset(state)
		check(u.diff(state.cached_grind, GrindState.default()), "reset")
	end)

	-- Rust: foot_physical_output tests.
	harness.test(report, "foot_physical_output: moving_board_frame_separates_world_rates_from_relative_foot_motion", function()
		local rec = record.SkeletonPhysicalRecord.default()
		rec.pose[1][4] = { 10.0, 2.0, 3.0, 0.0 }
		rec.pose[16][4] = { f32(10.2), 2.0, f32(3.3), 0.0 }
		rec.pose[20][4] = { f32(9.8), 2.0, f32(2.7), 0.0 }
		rec.velocities[16] = { 4.0, 0.0, 0.0, 0.0 }
		rec.velocities[20] = { 5.0, 0.0, 0.0, 0.0 }
		local settings = { deck_half_width = f32(0.3), deck_total_half_length = 0.5, padding = { 0.0, f32(0.1), 0.0, 0.0 } }
		local state = fpo.FootPhysicalState.default()
		local initial = fpo.FootPhysicalState.update(state, rec, 0.25, settings)
		assert(initial.within_deck_box[1] and initial.within_deck_box[2])
		check(u.diff(initial.world_velocity, { rec.velocities[16], rec.velocities[20] }), "world")
		for _, part in { 1, 16, 20 } do
			rec.pose[part][4][1] = f32(rec.pose[part][4][1] + 1.0)
		end
		local moved = fpo.FootPhysicalState.update(state, rec, 0.25, settings)
		for _, v in moved.local_velocity do
			for _, x in v do
				assert(math.abs(x) < 0.00001)
			end
		end
		local boundaries = record.SkeletonPhysicalRecord.default()
		boundaries.pose[16][4] = { f32(0.3), 0.0, 0.0, 0.0 }
		boundaries.pose[20][4] = { 0.0, f32(0.1), 0.0, 0.0 }
		local b = fpo.FootPhysicalState.update(state, boundaries, 0.25, settings)
		assert(not b.within_deck_box[1] and not b.within_deck_box[2])
	end)

	-- Rust: ground_hang_geometry tests.
	harness.test(report, "ground_hang_geometry: hanging_geometry_distinguishes_rail_side_and_blocked_deck", function()
		local lines = hang.hang_lines({ edge_start = vector.zero, edge_end = vector.create(0, 0, 2), reference_point = vector.create(4, 5, 1) }, f32(0.243)) :: any
		assert(lines[1].start == vector.create(0.09, 0.04, 1))
		assert(lines[1]["end"] == vector.create(0.09, -0.04, 1))
		assert(lines[2].start.x == f32(-0.09))
		assert(lines[6].radius == f32(0.001))
		assert(lines[6].start == vector.create(0.09, 0.09, 1))
		assert(lines[6]["end"] == vector.create(-0.09, 0.09, 1))
		assert(hang.hung_classification({ 0.5, false, false, false, false, false }))
		assert(not hang.hung_classification({ 0.5, false, f32(0.64), false, false, false }))
		assert(not hang.hung_classification({ 0.5, 0.5, false, false, false, false }))
		assert(not hang.hung_classification({ false, false, false, false, 0.5, false }))
	end)

	-- Эталон Rust.
	harness.test(report, "physics/board_animation + target_velocity vs Rust", function()
		for i, seq in golden.board_animation do
			local a = BoardAnimation.default()
			for k, o in seq.ops do
				local out = nil
				if o.op == 0 then
					BoardAnimation.capture_physics_error(a, o.t1, o.t2)
				elseif o.op == 1 then
					BoardAnimation.reset(a)
				else
					out = BoardAnimation.apply(a, o.t1, o.fast, seq.settings)
				end
				local at = "#" .. i .. "/" .. k
				check(u.diff(out, o.out), at .. " out")
				check(u.diff(a.rotation_error, o.rotation_error), at .. " error")
				check(u.diff(a.blending, o.blending), at .. " blending")
			end
		end
		for i, c in golden.target_velocity do
			check(u.diff(board_animation.target_velocity(c.t, c.p, c.dt), c.out), "tv#" .. i)
		end
	end)

	harness.test(report, "physics/board_dynamic_normal vs Rust", function()
		for i, seq in golden.dynamic_normal do
			local f = BoardDynamicNormal.new()
			for k, st in seq.steps do
				local c = BoardGroundState.default()
				c.wheel_contact_count = st.count
				for p, b in st.in_contact do
					c.parts[p].in_contact = b
				end
				c.accelerations = st.accelerations
				c.overall_normal = st.overall
				BoardDynamicNormal.update(f, c, vector.create(0, -9.81, 0), st.speed, seq.settings)
				local at = "#" .. i .. "/" .. k
				check(u.diff(f.normal, st.normal), at .. " normal")
				check(u.diff(f.delta, st.delta), at .. " delta")
				check(u.diff(f.acceleration, st.acceleration), at .. " acceleration")
				check(u.diff(f.last_contact_normal, st.last), at .. " last")
			end
		end
	end)

	harness.test(report, "physics/centre_of_mass_filter vs Rust", function()
		for i, seq in golden.com_filter do
			local f = com.CentreOfMassFilter.default()
			for k, st in ipairs(seq) do
				if st.reset then
					com.CentreOfMassFilter.reset(f)
				end
				local o = com.CentreOfMassFilter.update(f, st.p, st.v)
				check(u.diff(o, { velocity = st.velocity, acceleration = st.acceleration, position = st.position }), "#" .. i .. "/" .. k)
			end
		end
	end)

	harness.test(report, "physics/deck_angular_correction: 200 случаев vs Rust", function()
		for i, c in golden.deck do
			local b = deep(c.body)
			if c.op == 0 then
				dac.apply_axis_displacement(b, c.req)
			elseif c.op == 1 then
				dac.apply_limited_displacement(b, c.req)
			elseif c.op == 2 then
				dac.apply_angular_displacement(b, c.req)
			else
				dac.apply_ground_body_torque(b)
			end
			check(u.diff(b, c.out), "#" .. i .. " op" .. c.op)
		end
	end)

	harness.test(report, "physics/filtered_state: 20 × 40 vs Rust", function()
		for i, seq in golden.filtered do
			local f = FilteredState.default()
			for k, st in ipairs(seq) do
				if st.reset then
					FilteredState.reset(f)
				end
				local o = FilteredState.update(f, deep(st.input))
				local at = "#" .. i .. "/" .. k
				check(u.diff(o, st.out), at .. " out")
				check(u.diff(f, st.state), at .. " state")
			end
		end
	end)

	harness.test(report, "physics/foot_physical_output и ground_hang_geometry vs Rust", function()
		for i, seq in golden.feet do
			local f = fpo.FootPhysicalState.default()
			for k, st in seq.steps do
				local rec = record.SkeletonPhysicalRecord.default()
				rec.pose[1] = st.board
				rec.pose[16] = st.toe1
				rec.pose[20] = st.toe2
				rec.velocities[16] = st.v1
				rec.velocities[20] = st.v2
				local o = fpo.FootPhysicalState.update(f, rec, st.dt, seq.settings)
				check(u.diff(o, { local_velocity = st.local_velocity, world_velocity = st.world_velocity, within_deck_box = st.within }), "feet#" .. i .. "/" .. k)
			end
		end
		for i, c in golden.hang do
			local lines = hang.hang_lines({ edge_start = c.a, edge_end = c.b, reference_point = c.p }, c.d)
			if c.lines == nil then
				assert(lines == nil, "hang#" .. i)
			else
				assert(lines ~= nil, "hang#" .. i)
				for k, l in c.lines do
					local got = (lines :: any)[k]
					check(u.diff({ start = got.start, end_ = got["end"], radius = got.radius }, l), "hang#" .. i .. "/" .. k)
				end
			end
		end
	end)
end
