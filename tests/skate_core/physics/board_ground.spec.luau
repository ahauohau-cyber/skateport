--!strict
-- Сверка physics/board_ground, board_probes, board_toolkit с настоящим skate-core
-- (golden/src/board_ground.rs) и перенос Rust-тестов этих модулей.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local board = require("../../../src/skate_core/physics/board")
local board_ground = require("../../../src/skate_core/physics/board_ground")
local board_probes = require("../../../src/skate_core/physics/board_probes")
local board_toolkit = require("../../../src/skate_core/physics/board_toolkit")
local golden = require("../../golden/board_ground") :: any

local fb, f32, from_bits, to_bits = u.fb, rt.f32, rt.from_bits, rt.to_bits
local BodyId = board.BodyId
local BoardGroundState = board_ground.BoardGroundState
local WheelLineState = board_ground.WheelLineState
local BoardProbeState = board_probes.BoardProbeState
local BoardToolkit = board_toolkit.BoardToolkit
local UP = vector.create(0, 1, 0)

local function F4(t: { number }): { number }
	return { fb(t[1]), fb(t[2]), fb(t[3]), fb(t[4]) }
end
local function same4(a: { number }, t: { number }): boolean
	return u.same(a[1], t[1]) and u.same(a[2], t[2]) and u.same(a[3], t[3]) and u.same(a[4], t[4])
end
local function same44(a: { { number } }, t: any): boolean
	return same4(a[1], t[1]) and same4(a[2], t[2]) and same4(a[3], t[3]) and same4(a[4], t[4])
end

local function same_lines(l: any, t: any): boolean
	for i = 1, 4 do
		if not (u.same_v(l.normals[i], t[1][i]) and u.same(l.distances[i], t[2][i]) and l.physics_surfaces[i] == t[3][i]
			and l.audio_surfaces[i] == t[4][i] and l.seam_patterns[i] == t[5][i]) then
			return false
		end
	end
	return u.same(l.minimum_distance, t[6])
end

local function same_ground(g: any, t: any): string?
	for i = 1, 7 do
		local p, w = g.parts[i], t.parts[i]
		if p.in_contact ~= w[1] or not u.same_v(p.normal, w[2]) or not u.same_v(p.point, w[3]) or not u.same_v(p.relative_velocity, w[4]) then
			return "parts[" .. i .. "]"
		end
		if not u.same_v(g.previous_velocities[i], t.pv[i]) then
			return "previous_velocities"
		end
		if not u.same_v(g.accelerations[i], t.acc[i]) then
			return "accelerations"
		end
	end
	if not u.same_v(g.closing_velocity, t.closing) or not u.same(g.maximum_closing_speed, t.max_closing) then
		return "closing"
	end
	if not u.same(g.opposing_contact, t.opposing) then
		return "opposing"
	end
	if not u.same(g.surface_twelve_height, t.s12) or g.collision_flags ~= t.flags then
		return "flags"
	end
	if not u.same_v(g.overall_normal, t.overall) or not u.same_v(g.wheel_normal, t.wheel) then
		return "normals"
	end
	for i = 1, 4 do
		if g.valid_wheel_normals[i] ~= t.valid[i] or not u.same(g.wheel_angular_drag[i], t.drag[i]) then
			return "valid/drag"
		end
	end
	if g.part_contact_count ~= t.pcount or g.wheel_contact_count ~= t.wcount or not u.same(g.time_without_wheel_contact, t.time) then
		return "counts"
	end
	for i = 1, 3 do
		if g.part_audio_surfaces[i] ~= t.audio[i] then
			return "audio"
		end
	end
	return nil
end

local function report(part: number, normal: vector): any
	return {
		part = part, other = { kind = "StaticWorld" }, is_body_a = true,
		normal = normal, position = vector.zero, relative_linear_velocity = vector.zero,
		other_surface = 0, normal_force_on_a = UP, friction_force_on_a = vector.zero,
		tangents = { vector.zero, vector.zero },
	}
end
local function hits4(h: any): { any }
	return { h, h, h, h }
end

return function(report_: harness.Report)
	harness.test(report_, "board_ground: 80 × 25 шагов publish/update/sample vs Rust", function()
		for ci, case in golden.ground do
			local ground = BoardGroundState.default()
			local lines = WheelLineState.default()
			for si, st in case do
				local hits = {}
				for i, h in st.hits do
					hits[i] = if h == false then false else { fraction = fb(h[1]), normal = u.V(h[2]), surface_tag = h[3] }
				end
				WheelLineState.publish(lines, hits)
				assert(same_lines(lines, st.lines), string.format("случай %d шаг %d: линии", ci, si))
				local reports = {}
				for _, r in st.reports do
					table.insert(reports, { part = r[1], normal = u.V(r[2]), position = u.V(r[3]), relative_linear_velocity = u.V(r[4]), other_surface = r[5] })
				end
				BoardGroundState.update(ground, reports, lines, u.V(st.up), fb(st.angle), st.wipe)
				local vels = {}
				for i, x in st.vels do
					vels[i] = u.V(x)
				end
				BoardGroundState.sample_accelerations(ground, vels, fb(st.dt))
				BoardGroundState.advance_contact_time(ground, fb(st.dt))
				local bad = same_ground(ground, st.out)
				assert(bad == nil, string.format("случай %d шаг %d: %s", ci, si, tostring(bad)))
			end
		end
	end)

	harness.test(report_, "board_ground: 2000 angle_between vs Rust", function()
		for i, c in golden.angle do
			assert(u.same(board_ground.angle_between(u.V(c[1]), u.V(c[2])), c[3]), "случай " .. i)
		end
	end)

	harness.test(report_, "board_probes: 1000 wall_probe/deck_probe и 200 операций состояния vs Rust", function()
		for i, c in golden.wall do
			local line = board_probes.wall_probe({ state = c[1], contact_normal = u.V(c[2]), skater_up = u.V(c[3]), deck_position = u.V(c[4]), time = fb(c[5]) })
			if c[6] == false then
				assert(line == nil, "wall " .. i .. ": лишняя линия")
			else
				assert(line and u.same_v(line.start, c[6][1]) and u.same_v(line.end_, c[6][2]), "wall " .. i)
			end
			local d = board_probes.deck_probe(u.V(c[4]))
			assert(u.same_v(d.start, c[7][1]) and u.same_v(d.end_, c[7][2]), "deck " .. i)
		end
		local p = BoardProbeState.default()
		for i, c in golden.probe do
			if c[1] == 0 then
				BoardProbeState.start(p, u.V(c[2]))
			elseif c[1] == 1 then
				BoardProbeState.publish(p, if c[3] == false then nil else { point = u.V(c[3][1]), normal = u.V(c[3][2]), surface_tag = c[3][3] })
			else
				BoardProbeState.disable(p)
			end
			local w = c[4]
			assert(u.same_v(p.start, w[1]) and u.same_v(p.point, w[2]) and u.same_v(p.normal, w[3]) and p.surface_tag == w[4] and p.hit == w[5], "probe " .. i)
		end
	end)

	harness.test(report_, "board_toolkit: 1000 calculate vs Rust", function()
		for i, c in golden.toolkit do
			local inp = c.input
			local deck = { F4(inp[1][1]), F4(inp[1][2]), F4(inp[1][3]), F4(inp[1][4]) }
			local masses = {}
			for k, m in inp[2] do
				masses[k] = fb(m)
			end
			local t = BoardToolkit.calculate(deck, masses, inp[3], fb(inp[4]), F4(inp[5]), F4(inp[6]))
			local o = c.out
			assert(same44(t.deck, o[1]) and same44(t.effective, o[2]) and same44(t.inverse_effective, o[3]), "toolkit " .. i .. ": матрицы")
			assert(same4(t.side, o[4]) and same4(t.up, o[5]) and same4(t.forward, o[6]) and same4(t.horizontal_forward, o[7])
				and same4(t.transverse_up, o[8]) and same4(t.forward_velocity, o[9]) and same4(t.travel_direction, o[10])
				and same4(t.filtered_normal, o[11]), "toolkit " .. i .. ": оси")
			assert(u.same(t.absolute_speed, o[12]) and u.same(t.control_sign, o[13]) and u.same(t.total_mass, o[14]), "toolkit " .. i .. ": скаляры")
		end
	end)

	-- Перенос Rust-тестов crates/skate-core/src/physics/tests/board_ground.rs
	harness.test(report_, "board_ground: wheel_angular_drag_tracks_physical_contact_and_wipeout", function()
		local ground = BoardGroundState.default()
		local lines = WheelLineState.default()
		WheelLineState.publish(lines, hits4({ fraction = f32(0.1), normal = UP, surface_tag = 0 }))
		local frequency = from_bits(0x426F_FFFF)
		local free = f32(from_bits(0x3BC4_9BA6) * frequency)
		local wiping = f32(from_bits(0x3D23_D70A) * frequency)
		local contacts = { report(BodyId.RightFrontWheel, UP), report(BodyId.LeftBackWheel, UP) }
		local function drag(): string
			return table.concat(ground.wheel_angular_drag, ",")
		end
		BoardGroundState.update(ground, contacts, lines, UP, 80.0, false)
		assert(drag() == table.concat({ 0.0, free, free, 0.0 }, ","))
		BoardGroundState.update(ground, contacts, lines, UP, 80.0, true)
		assert(drag() == table.concat({ wiping, free, free, wiping }, ","))
		BoardGroundState.update(ground, {}, lines, UP, 80.0, true)
		assert(drag() == table.concat({ free, free, free, free }, ","))
	end)

	harness.test(report_, "board_ground: lost_wheel_support_keeps_wheel_normal_but_rebuilds_overall_normal", function()
		local ground = BoardGroundState.default()
		local lines = WheelLineState.default()
		WheelLineState.publish(lines, hits4({ fraction = f32(0.1), normal = UP, surface_tag = 0 }))
		BoardGroundState.update(ground, { report(BodyId.RightFrontWheel, UP) }, lines, UP, 80.0, false)
		assert(ground.wheel_contact_count == 1)
		local retained = ground.wheel_normal
		BoardGroundState.update(ground, { report(BodyId.Deck, vector.create(1, 0, 0)) }, lines, UP, 80.0, false)
		assert(ground.wheel_contact_count == 0 and ground.part_contact_count == 1)
		assert(ground.wheel_normal == retained)
		assert(ground.overall_normal.x > 0.99999 and math.abs(ground.overall_normal.y) < 0.00001)
	end)

	harness.test(report_, "board_ground: no_hit_preserves_line_geometry_and_contact_status_does_not_come_from_lines", function()
		local lines = WheelLineState.default()
		local normal = vector.create(f32(0.6), f32(0.8), 0)
		WheelLineState.publish(lines, hits4({ fraction = f32(0.2), normal = normal, surface_tag = bit32.lshift(3, 7) }))
		local distances = table.clone(lines.distances)
		WheelLineState.publish(lines, { false, false, false, false })
		for i = 1, 4 do
			assert(lines.normals[i] == normal and lines.distances[i] == distances[i] and lines.physics_surfaces[i] == 0)
		end
		assert(lines.minimum_distance == board_ground.WHEEL_LINE_LENGTH)
		local ground = BoardGroundState.default()
		BoardGroundState.update(ground, {}, lines, UP, 80.0, false)
		assert(ground.part_contact_count == 0 and ground.wheel_contact_count == 0)
		assert(ground.wheel_normal == UP and ground.overall_normal == UP)
	end)

	harness.test(report_, "board_ground: per_part_selection_uses_highest_y_and_keeps_first_on_ties", function()
		local first = report(BodyId.Deck, vector.create(f32(0.6), f32(0.8), 0))
		local tied = report(BodyId.Deck, vector.create(f32(-0.6), f32(0.8), 0))
		local lower = report(BodyId.Deck, vector.create(0, f32(0.4), f32(0.9)))
		local ground = BoardGroundState.default()
		BoardGroundState.update(ground, { first, tied, lower }, WheelLineState.default(), UP, 80.0, false)
		assert(ground.parts[7].normal == first.normal and ground.part_contact_count == 1)
	end)

	harness.test(report_, "board_ground: observed_acceleration_retains_each_part_velocity_and_resets_with_collision_info", function()
		local state = BoardGroundState.default()
		local first = {}
		for i = 0, 6 do
			first[i + 1] = vector.create(i, 2.0, -1.0)
		end
		BoardGroundState.sample_accelerations(state, first, 0.5)
		assert(state.accelerations[7] == vector.create(12, 4, -2))
		BoardGroundState.sample_accelerations(state, first, 0.25)
		for i = 1, 7 do
			assert(state.accelerations[i] == vector.zero)
		end
		local nxt = table.clone(first)
		nxt[7] = nxt[7] + vector.create(1, 0, 0)
		BoardGroundState.sample_accelerations(state, nxt, 0.25)
		assert(state.accelerations[7] == vector.create(4, 0, 0) and state.accelerations[6] == vector.zero)
	end)

	harness.test(report_, "board_ground: impact_uses_preceding_velocity_even_after_the_solver_stops_the_board", function()
		local ground = BoardGroundState.default()
		local before = table.create(7, vector.zero)
		before[7] = vector.create(-8, -3, 0)
		local dt = f32(1.0 / 60.0)
		BoardGroundState.sample_accelerations(ground, before, dt)
		BoardGroundState.update(ground, { report(BodyId.Deck, vector.create(1, 0, 0)), report(BodyId.Deck, UP) }, WheelLineState.default(), UP, 80.0, false)
		BoardGroundState.sample_accelerations(ground, table.create(7, vector.zero), dt)
		assert(ground.closing_velocity.x == -8 and to_bits(ground.closing_velocity.y) == 0x80000000 and to_bits(ground.closing_velocity.z) == 0x80000000)
		assert(ground.maximum_closing_speed == 8 and ground.parts[7].normal == UP)
		BoardGroundState.update(ground, {}, WheelLineState.default(), UP, 80.0, false)
		assert(ground.closing_velocity == vector.zero and ground.maximum_closing_speed == 0)
	end)

	harness.test(report_, "board_ground: surface_flags_use_actual_contacts_and_reset_each_frame", function()
		local ground = BoardGroundState.default()
		local first = report(BodyId.Deck, UP)
		first.other_surface = bit32.lshift(12, 7)
		first.position = vector.create(0, 2, 0)
		local last = table.clone(first)
		last.position = vector.create(0, 5, 0)
		last.other_surface = bit32.bor(bit32.lshift(12, 7), 41)
		local lines = WheelLineState.default()
		lines.physics_surfaces[1] = 8
		BoardGroundState.update(ground, { first, last }, lines, UP, 80.0, false)
		assert(ground.collision_flags == bit32.lshift(1, 25) and ground.surface_twelve_height == 5.0)
		assert(ground.part_audio_surfaces[1] == 0 and ground.part_audio_surfaces[2] == 0 and ground.part_audio_surfaces[3] == 41)
		BoardGroundState.update(ground, { report(BodyId.RightFrontWheel, UP) }, lines, UP, 80.0, false)
		assert(ground.collision_flags == bit32.lshift(1, 31))
		BoardGroundState.update(ground, {}, lines, UP, 80.0, false)
		assert(ground.collision_flags == 0 and ground.surface_twelve_height == 0.0)
	end)

	harness.test(report_, "board_ground: opposing_contacts_use_deck_projection_range_and_reset_without_deck_contacts", function()
		local state = BoardGroundState.default()
		local lines = WheelLineState.default()
		local reports = {
			report(BodyId.Deck, vector.create(0, 0.75, 0)),
			report(BodyId.Deck, vector.create(0, -0.5, 0)),
			report(BodyId.FrontTruck, vector.create(0, -1, 0)),
		}
		BoardGroundState.update(state, reports, lines, UP, 80.0, false)
		assert(state.opposing_contact == 1.25)
		BoardGroundState.update(state, reports, lines, vector.create(1, 0, 0), 80.0, false)
		assert(state.opposing_contact == 0.0)
		BoardGroundState.update(state, { reports[3] }, lines, UP, 80.0, false)
		assert(state.opposing_contact == 0.0)
	end)

	harness.test(report_, "board_ground: wheel_lines_keep_audio_and_physics_bits_of_the_same_tag", function()
		local lines = WheelLineState.default()
		local function hit(tag: number): any
			return { fraction = 0.5, normal = UP, surface_tag = tag }
		end
		WheelLineState.publish(lines, { hit(1591), hit(bit32.bor(bit32.lshift(3, 7), 9)), false, hit(0) })
		assert(table.concat(lines.physics_surfaces, ",") == "12,3,0,0")
		assert(table.concat(lines.audio_surfaces, ",") == "55,9,0,0")
		assert(table.concat(lines.seam_patterns, ",") == "0,0,0,0")
		WheelLineState.publish(lines, { hit(bit32.bor(bit32.lshift(11, 12), bit32.lshift(3, 7), 1)), false, false, false })
		assert(lines.audio_surfaces[1] == 1 and lines.physics_surfaces[1] == 3 and lines.seam_patterns[1] == 11)
	end)

	harness.test(report_, "board_probes: wall_probe_gates_and_miss_retention_follow_source", function()
		local input = { state = 100, contact_normal = vector.create(1, 0, 0), skater_up = vector.create(1, 0, 0), deck_position = vector.create(2, 3, 4), time = f32(0.02) }
		local line = assert(board_probes.wall_probe(input))
		assert(line.start == vector.create(f32(2.05), 3, 4) and line.end_ == vector.create(f32(2.05), -1, 4))
		input.state = 200
		assert(board_probes.wall_probe(input) == nil)
		local output = BoardProbeState.default()
		BoardProbeState.start(output, line.start)
		BoardProbeState.publish(output, { point = line.end_, normal = UP, surface_tag = 7 })
		BoardProbeState.start(output, line.start)
		BoardProbeState.publish(output, nil)
		assert(not output.hit and output.point == line.end_ and output.surface_tag == 7)
		BoardProbeState.disable(output)
		assert(BoardProbeState.eq(output, BoardProbeState.default()))
	end)

	harness.test(report_, "board_toolkit: toolkit_absolute_speed_preserves_original_ordered_sign_multiply", function()
		local up = { 0.0, 1.0, 0.0, 0.0 }
		local identity = { { 1.0, 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0, 0.0 }, { 0.0, 0.0, 1.0, 0.0 }, { 0.0, 0.0, 0.0, 1.0 } }
		for _, c in { { 3.0, 3.0 }, { -3.0, 3.0 }, { 0.0, -0.0 }, { -0.0, 0.0 } } do
			local t = BoardToolkit.calculate(identity, table.create(7, 1.0), 0, c[1], up, up)
			assert(to_bits(t.absolute_speed) == to_bits(c[2]))
		end
	end)
end
