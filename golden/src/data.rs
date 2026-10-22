//! Эталон для skate-data: attrib_hash и чтение настроек из skater-collections.json.
use skate_data::attrib_hash::{hash, numeric_name};
use skate_data::collections::Collections;
use std::fmt::Write as _;

pub fn write(out_dir: &str) {
    let mut s = String::from("-- Сгенерировано golden/src/data.rs из настоящего skate-data. Не править.\nreturn {\n\thash = {\n");
    let mut texts: Vec<String> = vec!["".into(), "a".into(), "physicswheels".into(), "WheelRadius".into(), "default".into(),
        "Hash_00000000000000FF".into(), "0xabc".into(), "Hash_zz".into(), "0x".into()];
    let mut state: u32 = 0x1234;
    for len in 1..=60 {
        let mut t = String::new();
        for _ in 0..len {
            state = state.wrapping_mul(1_664_525).wrapping_add(1_013_904_223);
            t.push((b'a' + ((state >> 24) % 26) as u8) as char);
        }
        texts.push(t);
    }
    for t in &texts {
        let h = hash(t);
        writeln!(s, "\t\t{{ {:?}, 0x{:08X}, 0x{:08X}, {:?} }},", t, h >> 32, h & 0xFFFF_FFFF, numeric_name(t)).unwrap();
    }
    s.push_str("\t},\n\tvalues = {\n");
    if let Ok(root) = std::env::var("SKATE3_ASSET_ROOT") {
        let data = Collections::load(std::path::Path::new(&root)).expect("collections");
        let floats = [
            ("physicswheels", "WheelStaticFriction"), ("physicswheels", "WheelDynamicFriction"), ("physicswheels", "WheelRestitution"),
            ("physicswheels", "WheelRadius"), ("physicswheels", "WheelMass"), ("physicswheels", "WheelXDist"),
            ("physics", "FreezingEnergy"), ("physicsdeck", "DeckForceYOffset"), ("physicsdeck", "DeckMass"),
            ("physicsdeck", "DeckAngularDrag"), ("physicsdeck", "DeckWidth"), ("physicstrucks", "TruckYPos"),
            ("physics_world", "SkateboardMassFactor"), ("physicstrucks_drives", "Angular_Hard_Strength"),
        ];
        for (c, f) in floats {
            writeln!(s, "\t\t{{ \"float\", {:?}, {:?}, 0x{:08X} }},", c, f, data.float(c, "default", f).unwrap().to_bits()).unwrap();
        }
        for (c, f) in [("physicstrucks", "UseTruckDrives"), ("physicsdeck", "UseHardDrives"), ("physicsdeck", "DeckEnableDeckVolumeCollisions")] {
            writeln!(s, "\t\t{{ \"bool\", {:?}, {:?}, {} }},", c, f, data.boolean(c, "default", f).unwrap()).unwrap();
        }
        writeln!(s, "\t\t{{ \"int\", \"physicsdeck\", \"DeckEndCapsules\", {} }},", data.integer("physicsdeck", "default", "DeckEndCapsules").unwrap()).unwrap();
        let g = data.words::<4>("physics", "default", "WorldGravity").unwrap();
        writeln!(s, "\t\t{{ \"words4\", \"physics\", \"WorldGravity\", {{ {}, {}, {}, {} }} }},", g[0], g[1], g[2], g[3]).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/data.luau"), s).unwrap();
}

/// Копия PhysicsSettings::load из skate-game (там pub(crate)), только числа.
pub fn write_settings(out_dir: &str) {
    use skate_core::math::Vector3;
    use skate_core::physics::drive_frames::{authored_body_transforms, calculate_truck_transforms, AuthoredTransformInputs, RetailTruckTransformInputs};
    use skate_core::physics::drive_parameters::{retail_truck_drive_dynamics, RetailTruckDriveSettings};
    use skate_core::physics::mass::{deck_mass_properties, truck_mass_properties, wheel_mass_properties, DeckGeometry, DeckGeometrySettings, TruckMassSettings, WheelMassSettings};
    use skate_core::physics::rigid_body::{RetailBodyMassProperties, RetailSimulationStep};
    use crate::collision::{b, v};
    let Ok(root) = std::env::var("SKATE3_ASSET_ROOT") else { return };
    let data = Collections::load(std::path::Path::new(&root)).unwrap();
    let f = |class, field| data.float(class, "default", field).unwrap();
    let bo = |class, field| data.boolean(class, "default", field).unwrap();
    let mass_factor = f("physics_world", "SkateboardMassFactor");
    let wheel_radius = f("physicswheels", "WheelRadius");
    let wheel_x_distance = f("physicswheels", "WheelXDist");
    let geometry = AuthoredTransformInputs {
        deck_mid_length: f("physicsdeck", "DeckMidLength"), wheel_x_distance,
        truck_z_position_front: f("physicstrucks", "TruckZPosFront"), truck_z_position_back: f("physicstrucks", "TruckZPosBack"),
        truck_y_position: f("physicstrucks", "TruckYPos"),
    };
    let wheel = wheel_mass_properties(WheelMassSettings { radius: wheel_radius, mass: f("physicswheels", "WheelMass"), mass_factor });
    let truck = truck_mass_properties(TruckMassSettings { wheel_radius, wheel_x_distance, mass_factor,
        radius_scalar: f("physicstrucks", "RadiusScalar"), half_height_scalar: f("physicstrucks", "HalfHeightScalar"), mass: f("physicstrucks", "TruckMass") });
    let gravity = data.words::<4>("physics", "default", "WorldGravity").unwrap().map(f32::from_bits);
    let simulation = RetailSimulationStep::fixed_60_hz(0, f("physics", "FreezingEnergy"), Vector3::new(gravity[0], gravity[1], gravity[2]));
    let deck_geometry = DeckGeometry::new(DeckGeometrySettings {
        width: f("physicsdeck", "DeckWidth"), mid_length: geometry.deck_mid_length, thickness: f("physicsdeck", "DeckThickness"),
        back_end_size: f("physicsdeck", "DeckBackEndSize"), front_end_angle_degrees: f("physicsdeck", "DeckFrontEndAngle"),
        back_end_angle_degrees: f("physicsdeck", "DeckBackEndAngle"),
        end_capsule_count: data.integer("physicsdeck", "default", "DeckEndCapsules").unwrap() as i32,
        enable_deck_volume_collisions: bo("physicsdeck", "DeckEnableDeckVolumeCollisions"),
        enable_end_volume_collisions: bo("physicsdeck", "DeckEnableEndVolumeCollisions"),
    });
    let deck = deck_mass_properties(&deck_geometry, f("physicsdeck", "DeckMass") * mass_factor, f("physicsdeck", "DeckAngularDrag") * simulation.frequency);
    let trucks = calculate_truck_transforms(RetailTruckTransformInputs {
        deck_mid_length: geometry.deck_mid_length, truck_z_position_front: geometry.truck_z_position_front,
        truck_z_position_back: geometry.truck_z_position_back, truck_y_position: geometry.truck_y_position,
        truck_rotation_axis_angle_degrees: f("physicstrucks", "TruckRotationAxisAngle"),
    });
    let dynamics = retail_truck_drive_dynamics(RetailTruckDriveSettings {
        use_linear_drives: bo("physicstrucks", "UseTruckDrives"), use_hard_linear_drives: bo("physicsdeck", "UseHardDrives"),
        angular_displacement: f("physicstrucks_drives", "Angular_Hard_Displacement"),
        angular_damping: f("physicstrucks_drives", "Angular_Hard_Damping"), angular_strength: f("physicstrucks_drives", "Angular_Hard_Strength"),
    });
    let authored = authored_body_transforms(geometry);
    let m = |p: &RetailBodyMassProperties| {
        let d = p.dynamics;
        let c = p.local_mass_frame.basis.columns;
        format!("{{ {{ {}, {}, {}, {}, {}, {}, {}, {}, {} }}, {}, {}, {}, {}, {}, {}, {}, {} }}",
            b(c[0][0]), b(c[0][1]), b(c[0][2]), b(c[1][0]), b(c[1][1]), b(c[1][2]), b(c[2][0]), b(c[2][1]), b(c[2][2]),
            v(p.local_mass_frame.translation), v(d.inverse_tensor), b(d.inverse_mass), b(d.spherical), b(d.maximum_linear_velocity),
            b(d.maximum_angular_velocity), b(d.linear_drag), b(d.angular_drag))
    };
    let t = |x: skate_core::physics::drive_frames::RetailAffineTransform| {
        let c = x.basis.columns;
        format!("{{ {{ {}, {}, {}, {}, {}, {}, {}, {}, {} }}, {} }}", b(c[0][0]), b(c[0][1]), b(c[0][2]), b(c[1][0]), b(c[1][1]), b(c[1][2]), b(c[2][0]), b(c[2][1]), b(c[2][2]), v(x.translation))
    };
    let s = format!(
        "-- Сгенерировано golden/src/data.rs (копия PhysicsSettings::load). Не править.\nreturn {{\n\twheel = {},\n\ttruck = {},\n\tdeck = {},\n\tsim = {{ {}, {}, {}, {} }},\n\ttrucks = {{ {}, {} }},\n\tdynamics = {{ {}, {}, {}, {}, {}, {} }},\n\tauthored = {{ {} }},\n\ty_offset = {},\n}}\n",
        m(&wheel), m(&truck), m(&deck), b(simulation.time_step), b(simulation.frequency), b(simulation.minimum_energy), v(simulation.gravity_acceleration),
        t(trucks[0]), t(trucks[1]),
        b(dynamics.linear.spring_or_max_velocity), b(dynamics.linear.max_strength), dynamics.linear.drive_type as u32,
        b(dynamics.angular.spring_or_max_velocity), b(dynamics.angular.max_strength), dynamics.angular.drive_type as u32,
        authored.map(t).join(", "), b(f("physicsdeck", "DeckForceYOffset"))
    );
    std::fs::write(format!("{out_dir}/settings.luau"), s).unwrap();
}
