--!strict
-- Сверка drive_frames, drive_parameters и construction/authored_transforms
-- с настоящим skate-core (golden/src/drive.rs) и перенос Rust-тестов
-- tests/drive_frames.rs и drive_parameters.rs.

local harness = require("../../harness")
local rt = require("../../../src/rt")
local drive_frames = require("../../../src/skate_core/physics/drive_frames")
local drive_parameters = require("../../../src/skate_core/physics/drive_parameters")
local authored = require("../../../src/skate_core/physics/construction/authored_transforms")
local board = require("../../../src/skate_core/physics/board")
local golden = require("../../golden/drive")

local fb = rt.from_bits
local tb = rt.to_bits

local function V(t: { number }): vector
	return vector.create(fb(t[1]), fb(t[2]), fb(t[3]))
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
local function A(t: any): any
	return { basis = B(t[1]), translation = V(t[2]) }
end
local function same(actual: number, bits: number): boolean
	return tb(actual) == bits or (actual ~= actual and fb(bits) ~= fb(bits))
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
local function same_a(actual: any, t: any): boolean
	return same_b(actual.basis, t[1]) and same_v(actual.translation, t[2])
end
local function same_q(q: any, t: { number }): boolean
	return same(q.x, t[1]) and same(q.y, t[2]) and same(q.z, t[3]) and same(q.w, t[4])
end
local function same_frames(f: any, t: any): boolean
	return same_q(f.body_a.orientation, t[1])
		and same_v(f.body_a.translation, t[2])
		and same_q(f.body_b.orientation, t[3])
		and same_v(f.body_b.translation, t[4])
end
local function same_list(got: { any }, want: { any }, eq: (any, any) -> boolean): boolean
	if #got ~= #want then
		return false
	end
	for i = 1, #want do
		if not eq(got[i], want[i]) then
			return false
		end
	end
	return true
end
local function bits_b(basis: any): { { number } }
	local out = {}
	for c = 1, 3 do
		out[c] = { tb(basis.columns[c][1]), tb(basis.columns[c][2]), tb(basis.columns[c][3]) }
	end
	return out
end
local function eq_words(a: { { number } }, b: { { number } }): boolean
	for c = 1, 3 do
		for r = 1, 3 do
			if a[c][r] ~= b[c][r] then
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
	harness.test(report, "drive_frames: identity_pair_has_bit_exact_identity_matrix_stage", function()
		local I = drive_frames.RetailAffineTransform.IDENTITY
		local f = drive_frames.relative_parent_transform(I(), I())
		harness.check(eq_words(bits_b(f.basis), { { 0x3F80_0000, 0, 0 }, { 0, 0x3F80_0000, 0 }, { 0, 0, 0x3F80_0000 } }), "basis")
		harness.check(tb(f.translation.x) == 0 and tb(f.translation.y) == 0 and tb(f.translation.z) == 0, "translation")
	end)

	harness.test(report, "drive_frames: default_truck_transforms_match_tu3_stock_finite_path_bits", function()
		local t = drive_frames.default_truck_transforms()
		harness.check(eq_words(bits_b(t[1].basis), {
			{ 0xB34B_C7FA, 0x3F03_D987, 0xBF5B_6F50 },
			{ 0, 0x3F5B_6F51, 0x3F03_D988 },
			{ 0x3F7F_FFFF, 0x32D1_E8FB, 0xB32E_ACAF },
		}), "7712 basis")
		harness.check(same_v(t[1].translation, { 0, 0xBD67_6C8B, 0xBE78_D4FD }), "7712 translation")
		harness.check(eq_words(bits_b(t[2].basis), {
			{ 0xB34B_C7FA, 0x3F03_D987, 0x3F5B_6F50 },
			{ 0, 0x3F5B_6F51, 0xBF03_D988 },
			{ 0xBF7F_FFFF, 0xB2D1_E8FB, 0xB32E_ACAF },
		}), "7776 basis")
		harness.check(same_v(t[2].translation, { 0, 0xBD67_6C8B, 0x3E78_D4FD }), "7776 translation")
	end)

	harness.test(report, "drive_frames: matrix_stage_preserves_tu3_vmx_fused_order", function()
		local t = drive_frames.default_truck_transforms()
		local relative = drive_frames.relative_parent_transform(t[1], t[2])
		harness.check(eq_words(bits_b(relative.basis), {
			{ 0xBEF0_5E95, 0x3F62_08D7, 0xB395_B9AE },
			{ 0x3F62_08D7, 0x3EF0_5E96, 0x3333_ED95 },
			{ 0x3395_B9AE, 0xB333_ED95, 0xBF7F_FFFE },
		}), "relative basis")
		local translation = drive_frames.transpose_relative_translation(
			t[1].basis,
			V({ 0x43D5_62ED, 0xC356_E21F, 0x4408_E252 }),
			V({ 0x43FA_50C2, 0xC28B_22BA, 0xC3E6_0F58 })
		)
		harness.check(same_v(translation, { 0x446A_A4A8, 0xC3C5_35F5, 0x4293_B75A }), "translation")
	end)

	harness.test(report, "drive_frames: derived_level_spawn_places_all_four_wheel_spheres_on_y_zero", function()
		local bodies = drive_frames.default_body_transforms()
		for i = 1, 4 do
			local bottom = rt.f32(
				rt.f32(drive_frames.RETAIL_LEVEL_GROUND_DECK_CENTER_HEIGHT + bodies[i].translation.y) - board.RETAIL_WHEEL_RADIUS
			)
			harness.check(math.abs(bottom) <= 2 ^ -23, "wheel " .. i)
		end
	end)

	harness.test(report, "drive_parameters: enabled_soft_linear_trucks_have_critical_damping", function()
		local settings = drive_parameters.RetailTruckDriveSettings.STOCK()
		settings.use_linear_drives = true
		settings.use_hard_linear_drives = false
		local d = drive_parameters.retail_truck_drive_dynamics(settings)
		harness.check(d.linear.drive_type == drive_parameters.RetailDriveType.SoftDrive, "type")
		harness.check(d.linear.spring_or_max_velocity == 100000, "spring")
		harness.check(math.abs(d.linear.damping - 632.4555) < 0.0001, "damping")
		harness.check(tb(d.linear.max_strength) == 0x48AF_C7FF, "strength")
		local stock = drive_parameters.retail_truck_drive_dynamics(drive_parameters.RetailTruckDriveSettings.STOCK())
		harness.check(drive_parameters.RetailDriveParams.eq(d.angular, stock.angular), "angular")
	end)

	harness.test(report, "drive: стоковые кадры, трансформы и динамика приводов vs Rust", function()
		harness.check(same_list(drive_frames.default_truck_transforms(), golden.truck_transforms, same_a), "truck transforms")
		harness.check(same_list(drive_frames.default_body_transforms(), golden.body_transforms, same_a), "body transforms")
		harness.check(same_list(drive_frames.default_live_body_transforms(), golden.live_transforms, same_a), "live transforms")
		harness.check(same_list(drive_frames.default_live_body_orientations(), golden.live_orientations, same_q), "live orientations")
		harness.check(same_list(drive_frames.default_truck_drive_frames(), golden.truck_frames, same_frames), "truck frames")
		harness.check(same_list(drive_frames.default_wheel_drive_frames(), golden.wheel_frames, same_frames), "wheel frames")
		local records = authored.authored_body_pose_records(authored.AuthoredTransformInputs.STOCK())
		for i, words in golden.pose_records do
			for k = 1, 16 do
				harness.check(records[i][k] == words[k], "pose record " .. i .. ":" .. k)
			end
		end
		local got = {}
		for _, case in { { false, false }, { false, true }, { true, false }, { true, true } } do
			local st = drive_parameters.RetailTruckDriveSettings.STOCK()
			st.use_linear_drives, st.use_hard_linear_drives = case[1], case[2]
			table.insert(got, drive_parameters.retail_truck_drive_dynamics(st))
		end
		table.insert(got, drive_parameters.retail_wheel_drive_dynamics(true))
		table.insert(got, drive_parameters.retail_wheel_drive_dynamics(false))
		for i, d in got do
			local w = golden.dynamics[i]
			for k, half in { d.linear, d.angular } do
				local wh = w[k]
				harness.check(
					same(half.spring_or_max_velocity, wh[1]) and same(half.damping, wh[2]) and same(half.max_strength, wh[3]) and half.drive_type == wh[4],
					"dynamics " .. i .. ":" .. k
				)
			end
		end
	end)

	harness.test(report, "drive_frames: retail_quaternion_from_basis vs Rust", function()
		count(report, "quaternion_from_basis", golden.quaternion, function(case)
			return same_q(drive_frames.retail_quaternion_from_basis(B(case[1])), case[2])
		end)
	end)

	harness.test(report, "drive_frames: set_drive_frames_2 vs Rust", function()
		count(report, "set_drive_frames_2", golden.set_frames, function(case)
			return same_frames(drive_frames.set_drive_frames_2(A(case[1]), A(case[2])), case[3])
		end)
	end)

	harness.test(report, "drive_frames: calculate_truck_transforms / authored_body_transforms vs Rust", function()
		count(report, "calculate_truck_transforms", golden.truck_inputs, function(case)
			local i = case[1]
			local t = drive_frames.calculate_truck_transforms({
				deck_mid_length = fb(i[1]),
				truck_z_position_front = fb(i[2]),
				truck_z_position_back = fb(i[3]),
				truck_y_position = fb(i[4]),
				truck_rotation_axis_angle_degrees = fb(i[5]),
			})
			return same_a(t[1], case[2]) and same_a(t[2], case[3])
		end)
		count(report, "authored_body_transforms", golden.authored, function(case)
			local i = case[1]
			local t = authored.authored_body_transforms({
				deck_mid_length = fb(i[1]),
				wheel_x_distance = fb(i[2]),
				truck_z_position_front = fb(i[3]),
				truck_z_position_back = fb(i[4]),
				truck_y_position = fb(i[5]),
			})
			return same_list(t, case[2], same_a)
		end)
	end)
end
