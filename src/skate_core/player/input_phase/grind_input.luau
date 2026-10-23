--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/input_phase/grind_input.rs (коммит 2e16697)
--
-- Value snapshot copied by82D87E80 into Processed1104..1519 after manager post.
-- Native pointers are stable host identities; all geometry/control values are
-- retained independently. Zero is the native416-byte investigation reset.
-- ROBLOX: Option<u64> -> number или nil (только идентичность хоста, не арифметика).

local grind_input = {}

export type RawVector = { number }

export type GrindInvestigationFields = {
	tangent_1104: RawVector,
	point_1120: RawVector,
	direction_1136: RawVector,
	normal_1152: RawVector,
	target_up_1168: RawVector,
	entry_velocity_1184: RawVector,
	front_contact_1200: RawVector,
	rear_contact_1216: RawVector,
	vector_1232: RawVector,
	family_1248: number,
	entry_kind_1252: number,
	primitive_start_1264: RawVector,
	primitive_end_1280: RawVector,
	owner_1296: number?,
	primitive_flags_1300: number,
	second_start_1312: RawVector,
	second_end_1328: RawVector,
	second_owner_1344: number?,
	second_flags_1348: number,
	center_1360: RawVector,
	far_points_1376_1392: { RawVector },
	upmost_normal_1408: RawVector,
	surface_direction_1424: RawVector,
	high_side_1440: RawVector,
	normal_limits_1456_1460: { number },
	geometry_kind_1464: number,
	audio_surface_1468: number,
	physics_surface_1472: number,
	geometry_flags_1476: number,
	valid_1488: boolean,
	impact_speed_1492: number,
	friction_1496: number,
	exit_lean_1500: number,
	yaw_1504: number,
	pitch_1508: number,
	gravity_relief_1512: number,
	flags_1516: number,
}

local function z4(): RawVector
	return { 0, 0, 0, 0 }
end

local GrindInvestigationFields = {}
grind_input.GrindInvestigationFields = GrindInvestigationFields

-- ROBLOX: #[derive(Default)] -> конструктор с нулями.
function GrindInvestigationFields.default(): GrindInvestigationFields
	return {
		tangent_1104 = z4(),
		point_1120 = z4(),
		direction_1136 = z4(),
		normal_1152 = z4(),
		target_up_1168 = z4(),
		entry_velocity_1184 = z4(),
		front_contact_1200 = z4(),
		rear_contact_1216 = z4(),
		vector_1232 = z4(),
		family_1248 = 0,
		entry_kind_1252 = 0,
		primitive_start_1264 = z4(),
		primitive_end_1280 = z4(),
		owner_1296 = nil,
		primitive_flags_1300 = 0,
		second_start_1312 = z4(),
		second_end_1328 = z4(),
		second_owner_1344 = nil,
		second_flags_1348 = 0,
		center_1360 = z4(),
		far_points_1376_1392 = { z4(), z4() },
		upmost_normal_1408 = z4(),
		surface_direction_1424 = z4(),
		high_side_1440 = z4(),
		normal_limits_1456_1460 = { 0, 0 },
		geometry_kind_1464 = 0,
		audio_surface_1468 = 0,
		physics_surface_1472 = 0,
		geometry_flags_1476 = 0,
		valid_1488 = false,
		impact_speed_1492 = 0,
		friction_1496 = 0,
		exit_lean_1500 = 0,
		yaw_1504 = 0,
		pitch_1508 = 0,
		gravity_relief_1512 = 0,
		flags_1516 = 0,
	}
end

return grind_input
