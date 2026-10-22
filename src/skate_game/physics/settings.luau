--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/physics/settings.rs (коммит 2e16697)
--
-- Stock skater XML values bound to the recovered physical calculations.

local rt = require("../../rt")
local collections_mod = require("../../skate_data/collections")
local drive_frames = require("../../skate_core/physics/drive_frames")
local authored = require("../../skate_core/physics/construction/authored_transforms")
local drive_parameters = require("../../skate_core/physics/drive_parameters")
local mass = require("../../skate_core/physics/mass")
local deck_geometry = require("../../skate_core/physics/construction/deck_geometry")
local board_parts = require("../../skate_core/physics/construction/board_parts")
local rigid_body = require("../../skate_core/physics/rigid_body")

local f32 = rt.f32
local from_bits = rt.from_bits
local Collections = collections_mod.Collections

type Collections = collections_mod.Collections

local settings = {}

-- Constraint iterations of the skater's `rw::physics::Simulation` (+176), read by the solver
-- stages `82AE30F0` / `82AE27D0` as their loop count. Measured in TU3 (recomp, Aletown,
-- board + skater pipeline with 28 joints / 53 drives): 50 on every solve. Setup `82DC2840`
-- first copies 25 from the hard-coded config built by `8275DCC8` (`li r27,25`); the value is
-- 50 before the first gameplay solve (the later writer is not identified yet). The stock
-- `physics/default.RWMaxIterations` is 25, equal to the setup value but not the live one;
-- solving with 25 left wheels sinking ~10x faster than retail (-0.012 vs -0.001 m/s at rest)
-- and the ollie pop's deck ~1 cm low by its 4th frame (retail-matching with 50).
settings.SIMULATION_ITERATIONS = 50

export type PhysicsSettings = {
	step: any, -- board_step.BoardStepSettings
	masses: { rigid_body.RetailBodyMassProperties },
	authored: { drive_frames.RetailAffineTransform },
	deck_geometry: deck_geometry.DeckGeometry,
	truck_shape: any, -- MassShape
	truck_collisions: boolean,
	truck_material: any,
	deck_material: any,
	wheel_radius: number,
	wheel_material: any,
	standard_wheel_material: any,
	floor_material: any,
	input_magnitude_threshold: number,
}

local PhysicsSettings = {}
settings.PhysicsSettings = PhysicsSettings

-- pub fn load(data: &Collections) -> Result<Self, String>
-- ROBLOX: ошибка чтения поднимается как ошибка Luau внутри pcall и
-- возвращается как (nil, текст), то есть как Result в Rust.
function PhysicsSettings.load(data: Collections): (PhysicsSettings?, string?)
	local ok, result = pcall(function(): PhysicsSettings
		local expect = collections_mod.expect
		local function f(class: string, field: string): number
			return expect(Collections.float(data, class, "default", field))
		end
		local function b(class: string, field: string): boolean
			return expect(Collections.boolean(data, class, "default", field))
		end
		local mass_factor = f("physics_world", "SkateboardMassFactor")
		local wheel_radius = f("physicswheels", "WheelRadius")
		local wheel_x_distance = f("physicswheels", "WheelXDist")
		local geometry: authored.AuthoredTransformInputs = {
			deck_mid_length = f("physicsdeck", "DeckMidLength"),
			wheel_x_distance = wheel_x_distance,
			truck_z_position_front = f("physicstrucks", "TruckZPosFront"),
			truck_z_position_back = f("physicstrucks", "TruckZPosBack"),
			truck_y_position = f("physicstrucks", "TruckYPos"),
		}
		local wheel = mass.wheel_mass_properties({
			radius = wheel_radius,
			mass = f("physicswheels", "WheelMass"),
			mass_factor = mass_factor,
		})
		local truck_settings: board_parts.TruckMassSettings = {
			wheel_radius = wheel_radius,
			wheel_x_distance = wheel_x_distance,
			mass_factor = mass_factor,
			radius_scalar = f("physicstrucks", "RadiusScalar"),
			half_height_scalar = f("physicstrucks", "HalfHeightScalar"),
			mass = f("physicstrucks", "TruckMass"),
		}
		local truck = mass.truck_mass_properties(truck_settings)
		local gravity = expect(Collections.words(data, "physics", "default", "WorldGravity", 4))
		local simulation = rigid_body.RetailSimulationStep.fixed_60_hz(
			0, -- Our host keeps its single board active; sleeping is not scheduled.
			f("physics", "FreezingEnergy"),
			vector.create(from_bits(gravity[1]), from_bits(gravity[2]), from_bits(gravity[3]))
		)
		local geometry_deck = deck_geometry.DeckGeometry.new({
			width = f("physicsdeck", "DeckWidth"),
			mid_length = geometry.deck_mid_length,
			thickness = f("physicsdeck", "DeckThickness"),
			back_end_size = f("physicsdeck", "DeckBackEndSize"),
			front_end_angle_degrees = f("physicsdeck", "DeckFrontEndAngle"),
			back_end_angle_degrees = f("physicsdeck", "DeckBackEndAngle"),
			-- ROBLOX: `as i32` — u32 со знаком.
			end_capsule_count = rt.to_i32(expect(Collections.integer(data, "physicsdeck", "default", "DeckEndCapsules"))),
			enable_deck_volume_collisions = b("physicsdeck", "DeckEnableDeckVolumeCollisions"),
			enable_end_volume_collisions = b("physicsdeck", "DeckEnableEndVolumeCollisions"),
		})
		local deck = mass.deck_mass_properties(
			geometry_deck,
			f32(f("physicsdeck", "DeckMass") * mass_factor),
			f32(f("physicsdeck", "DeckAngularDrag") * simulation.frequency)
		)
		local step = {
			simulation = simulation,
			iterations = settings.SIMULATION_ITERATIONS,
			base_truck_transforms = drive_frames.calculate_truck_transforms({
				deck_mid_length = geometry.deck_mid_length,
				truck_z_position_front = geometry.truck_z_position_front,
				truck_z_position_back = geometry.truck_z_position_back,
				truck_y_position = geometry.truck_y_position,
				truck_rotation_axis_angle_degrees = f("physicstrucks", "TruckRotationAxisAngle"),
			}),
			truck_dynamics = drive_parameters.retail_truck_drive_dynamics({
				use_linear_drives = b("physicstrucks", "UseTruckDrives"),
				use_hard_linear_drives = b("physicsdeck", "UseHardDrives"),
				angular_displacement = f("physicstrucks_drives", "Angular_Hard_Displacement"),
				angular_damping = f("physicstrucks_drives", "Angular_Hard_Damping"),
				angular_strength = f("physicstrucks_drives", "Angular_Hard_Strength"),
			}),
			force_point_y_offset = f("physicsdeck", "DeckForceYOffset"),
		}
		if wheel_radius <= 0.0 or mass_factor <= 0.0 then
			error("Invalid stock board radius or mass factor")
		end
		local function material(class: string, prefix: string): any
			return {
				static_friction = f(class, prefix .. "StaticFriction"),
				dynamic_friction = f(class, prefix .. "DynamicFriction"),
				restitution = f(class, prefix .. "Restitution"),
			}
		end
		-- ROBLOX: в Rust массив копирует значения; здесь у каждого тела своя таблица.
		local function copy_mass(m: rigid_body.RetailBodyMassProperties): rigid_body.RetailBodyMassProperties
			return {
				local_mass_frame = {
					basis = { columns = table.clone(m.local_mass_frame.basis.columns) },
					translation = m.local_mass_frame.translation,
				},
				dynamics = table.clone(m.dynamics),
			}
		end
		return {
			step = step,
			masses = {
				copy_mass(wheel),
				copy_mass(wheel),
				copy_mass(wheel),
				copy_mass(wheel),
				copy_mass(truck),
				copy_mass(truck),
				deck,
			},
			authored = authored.authored_body_transforms(geometry),
			deck_geometry = geometry_deck,
			truck_shape = board_parts.truck_mass_input(truck_settings).shape,
			truck_collisions = b("physicstrucks", "TruckEnableVolumeCollisions"),
			truck_material = material("physicstrucks", "Truck"),
			deck_material = material("physicsdeck", "Deck"),
			wheel_radius = wheel_radius,
			wheel_material = material("physicswheels", "Wheel"),
			standard_wheel_material = material("physicswheels", "Wheel"),
			floor_material = {
				-- Ground job8277C5D8 uses context83034F34/38/3C. The
				-- max/max/min combine preserves the moving volume material.
				static_friction = 0.0,
				dynamic_friction = 0.0,
				restitution = 1.0,
			},
			input_magnitude_threshold = f("inputlistener", "StickMagnitudeMinToCountHeld"),
		}
	end)
	if not ok then
		return nil, tostring(result)
	end
	return result, nil
end

return settings
