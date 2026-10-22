//! Эталон для skate_game/physics/colliders: стоковая доска (настройки из данных
//! игры) катится по рампе из world.rs, коллайдеры — копия colliders.rs.
use crate::collision::{b, v, Rng};
use skate_core::math::{Basis3, Vector3};
use skate_core::physics::board::BodyId;
use skate_core::physics::board_runtime::{BoardMotion, BoardRuntime};
use skate_core::physics::board_step::{BoardStepSettings, CollisionBody};
use skate_core::physics::board_world::{BoardWorldVolume, ContactRetentionSettings, VolumeMotion};
use skate_core::physics::collision::{Sphere, WorldContactSettings};
use skate_core::physics::contact::RetailContactMaterial;
use skate_core::physics::drive_frames::{authored_body_transforms, calculate_truck_transforms, AuthoredTransformInputs, RetailAffineTransform, RetailTruckTransformInputs};
use skate_core::physics::drive_parameters::{retail_truck_drive_dynamics, RetailTruckDriveSettings};
use skate_core::physics::force_queue::QueuedPointForce;
use skate_core::physics::mass::{deck_mass_properties, truck_mass_input, truck_mass_properties, wheel_mass_properties, DeckGeometry, DeckGeometrySettings, DeckShape, MassShape, TruckMassSettings, WheelMassSettings};
use skate_core::physics::rigid_body::RetailSimulationStep;
use skate_core::physics::world_contact::{transform_triangle_volume, ContactPrimitive};
use skate_data::collections::Collections;
use std::fmt::Write as _;

struct S { deck_geometry: DeckGeometry, truck_collisions: bool, truck_shape: MassShape, wheel_radius: f32,
    deck_material: RetailContactMaterial, truck_material: RetailContactMaterial, wheel_material: RetailContactMaterial }

// ---- дословная копия crates/skate-game/src/physics/colliders.rs ----
fn world_volumes(board: &BoardRuntime, settings: &S) -> Vec<BoardWorldVolume> {
    let poses = board.part_transforms();
    let mut volumes = Vec::new();
    for id in BodyId::ORDER {
        let body = &board.bodies()[id.index()];
        if body.state_flags == 1 { continue; }
        let pose = poses[id.index()];
        let mut add = |primitive, material: RetailContactMaterial| {
            volumes.push(BoardWorldVolume { collision_group: board.collision_group(), body: CollisionBody::Board(id), primitive, material, motion: VolumeMotion::of(&body.rates) });
        };
        match id {
            BodyId::Deck => {
                for child in &settings.deck_geometry.children {
                    if !child.collision_enabled { continue; }
                    let world = compose(pose, child.transform);
                    let primitive = match child.shape {
                        DeckShape::Sphere { radius } => ContactPrimitive::Sphere(Sphere { center: world.translation, radius }),
                        DeckShape::Capsule { radius, half_length } => capsule(world, radius, half_length),
                        DeckShape::RoundedBox { half_extents, radius } => ContactPrimitive::RoundedBox { center: world.translation, basis: world.basis, half_extents, radius },
                        DeckShape::Triangle { vertices, fatness, edge_cosines, volume_flags } => ContactPrimitive::Triangle(transform_triangle_volume(vertices, fatness, edge_cosines, volume_flags, world.basis, world.translation)),
                    };
                    add(primitive, settings.deck_material);
                }
            }
            BodyId::FrontTruck | BodyId::BackTruck => {
                if settings.truck_collisions {
                    let MassShape::Capsule { radius, half_length } = settings.truck_shape else { unreachable!() };
                    add(capsule(pose, radius, half_length), settings.truck_material);
                }
            }
            _ => add(ContactPrimitive::Sphere(Sphere { center: pose.translation, radius: settings.wheel_radius }), settings.wheel_material),
        }
    }
    volumes
}
fn capsule(pose: RetailAffineTransform, radius: f32, half_length: f32) -> ContactPrimitive {
    let z = pose.basis.columns[2];
    ContactPrimitive::Capsule { center: pose.translation, axis: Vector3::new(z[0], z[1], z[2]), half_length, radius }
}
fn transform(basis: Basis3, point: Vector3, origin: Vector3) -> Vector3 {
    let translation = [origin.x, origin.y, origin.z];
    let component = |row| point.z.mul_add(basis.columns[2][row], point.y.mul_add(basis.columns[1][row], point.x.mul_add(basis.columns[0][row], translation[row])));
    Vector3::new(component(0), component(1), component(2))
}
fn compose(parent: RetailAffineTransform, child: RetailAffineTransform) -> RetailAffineTransform {
    RetailAffineTransform {
        basis: Basis3 { columns: child.basis.columns.map(|c| core::array::from_fn(|row| c[2].mul_add(parent.basis.columns[2][row], c[1].mul_add(parent.basis.columns[1][row], c[0] * parent.basis.columns[0][row])))) },
        translation: transform(parent.basis, child.translation, parent.translation),
    }
}
// ---- конец копии ----

fn prim_s(p: &ContactPrimitive) -> String {
    match p {
        ContactPrimitive::Sphere(s) => format!("{{ \"Sphere\", {}, {} }}", v(s.center), b(s.radius)),
        ContactPrimitive::Capsule { center, axis, half_length, radius } => format!("{{ \"Capsule\", {}, {}, {}, {} }}", v(*center), v(*axis), b(*half_length), b(*radius)),
        ContactPrimitive::RoundedBox { center, basis, half_extents, radius } => format!("{{ \"RoundedBox\", {}, {}, {}, {}, {}, {} }}", v(*center),
            v(Vector3::new(basis.columns[0][0], basis.columns[0][1], basis.columns[0][2])), v(Vector3::new(basis.columns[1][0], basis.columns[1][1], basis.columns[1][2])),
            v(Vector3::new(basis.columns[2][0], basis.columns[2][1], basis.columns[2][2])), v(*half_extents), b(*radius)),
        ContactPrimitive::Triangle(t) => format!("{{ \"Triangle\", {}, {}, {}, {} }}", v(t.vertices[0]), v(t.vertices[1]), v(t.vertices[2]), v(t.feature.normal)),
    }
}

pub fn write(out_dir: &str) {
    let Ok(root) = std::env::var("SKATE3_ASSET_ROOT") else { return };
    let data = Collections::load(std::path::Path::new(&root)).unwrap();
    let f = |class, field| data.float(class, "default", field).unwrap();
    let bo = |class, field| data.boolean(class, "default", field).unwrap();
    let mass_factor = f("physics_world", "SkateboardMassFactor");
    let wheel_radius = f("physicswheels", "WheelRadius");
    let wheel_x_distance = f("physicswheels", "WheelXDist");
    let geometry = AuthoredTransformInputs { deck_mid_length: f("physicsdeck", "DeckMidLength"), wheel_x_distance,
        truck_z_position_front: f("physicstrucks", "TruckZPosFront"), truck_z_position_back: f("physicstrucks", "TruckZPosBack"), truck_y_position: f("physicstrucks", "TruckYPos") };
    let wheel = wheel_mass_properties(WheelMassSettings { radius: wheel_radius, mass: f("physicswheels", "WheelMass"), mass_factor });
    let ts = TruckMassSettings { wheel_radius, wheel_x_distance, mass_factor, radius_scalar: f("physicstrucks", "RadiusScalar"), half_height_scalar: f("physicstrucks", "HalfHeightScalar"), mass: f("physicstrucks", "TruckMass") };
    let truck = truck_mass_properties(ts);
    let gravity = data.words::<4>("physics", "default", "WorldGravity").unwrap().map(f32::from_bits);
    let simulation = RetailSimulationStep::fixed_60_hz(0, f("physics", "FreezingEnergy"), Vector3::new(gravity[0], gravity[1], gravity[2]));
    let deck_geometry = DeckGeometry::new(DeckGeometrySettings { width: f("physicsdeck", "DeckWidth"), mid_length: geometry.deck_mid_length, thickness: f("physicsdeck", "DeckThickness"),
        back_end_size: f("physicsdeck", "DeckBackEndSize"), front_end_angle_degrees: f("physicsdeck", "DeckFrontEndAngle"), back_end_angle_degrees: f("physicsdeck", "DeckBackEndAngle"),
        end_capsule_count: data.integer("physicsdeck", "default", "DeckEndCapsules").unwrap() as i32,
        enable_deck_volume_collisions: bo("physicsdeck", "DeckEnableDeckVolumeCollisions"), enable_end_volume_collisions: bo("physicsdeck", "DeckEnableEndVolumeCollisions") });
    let deck = deck_mass_properties(&deck_geometry, f("physicsdeck", "DeckMass") * mass_factor, f("physicsdeck", "DeckAngularDrag") * simulation.frequency);
    let step = BoardStepSettings { simulation, iterations: 50,
        base_truck_transforms: calculate_truck_transforms(RetailTruckTransformInputs { deck_mid_length: geometry.deck_mid_length, truck_z_position_front: geometry.truck_z_position_front,
            truck_z_position_back: geometry.truck_z_position_back, truck_y_position: geometry.truck_y_position, truck_rotation_axis_angle_degrees: f("physicstrucks", "TruckRotationAxisAngle") }),
        truck_dynamics: retail_truck_drive_dynamics(RetailTruckDriveSettings { use_linear_drives: bo("physicstrucks", "UseTruckDrives"), use_hard_linear_drives: bo("physicsdeck", "UseHardDrives"),
            angular_displacement: f("physicstrucks_drives", "Angular_Hard_Displacement"), angular_damping: f("physicstrucks_drives", "Angular_Hard_Damping"), angular_strength: f("physicstrucks_drives", "Angular_Hard_Strength") }),
        force_point_y_offset: f("physicsdeck", "DeckForceYOffset") };
    let mat = |class: &str, p: &str| RetailContactMaterial { static_friction: data.float(class, "default", &format!("{p}StaticFriction")).unwrap(), dynamic_friction: data.float(class, "default", &format!("{p}DynamicFriction")).unwrap(), restitution: data.float(class, "default", &format!("{p}Restitution")).unwrap() };
    let settings = S { truck_shape: truck_mass_input(ts).shape, deck_geometry, truck_collisions: bo("physicstrucks", "TruckEnableVolumeCollisions"), wheel_radius,
        deck_material: mat("physicsdeck", "Deck"), truck_material: mat("physicstrucks", "Truck"), wheel_material: mat("physicswheels", "Wheel") };
    let masses = [wheel, wheel, wheel, wheel, truck, truck, deck];
    let authored = authored_body_transforms(geometry);
    let (mut world, _, h) = crate::world::ramp();
    let query = WorldContactSettings { volume_padding: 0.05, maximum_separating_distance: 0.5, edge_cos_bend_normal_threshold: 0.999, convexity_epsilon: 0.01, is_object: false };
    let retention = ContactRetentionSettings { capacity: u32::MAX, duplicate_distance_squared: -1.0, deferred_reduction: true };
    let mut r = Rng(0xc011_1de5);
    let mut s = String::from("-- Сгенерировано golden/src/colliders.rs из настоящего skate-core. Не править.\nreturn {\n");
    for (si, spawn_y) in [(0, h + 0.3), (1, h + 0.6)] {
        let spawn = RetailAffineTransform { translation: Vector3::new(0.0, spawn_y, 11.0), ..RetailAffineTransform::IDENTITY };
        let mut board = BoardRuntime::new(masses, authored, spawn, simulation, BoardMotion::Active);
        writeln!(s, "\t{{ spawn = {}, ticks = {{", v(spawn.translation)).unwrap();
        for tick in 0..200 {
            board.clear_forces();
            if tick < 30 { board.forces_mut().append(QueuedPointForce { tag: 1, force_world: Vector3::new(0.0, 0.0, -20.0 - 10.0 * si as f32), point_body: Vector3::ZERO }); }
            let volumes = world_volumes(&board, &settings);
            let collisions = world.query_primitives(&volumes, query, retention).to_vec();
            let targets = [r.range(-0.2, 0.2), r.range(-0.2, 0.2)];
            board.advance(&collisions, targets, step);
            let mut vs = String::new();
            for vol in &volumes { write!(vs, "{}, ", prim_s(&vol.primitive)).unwrap(); }
            let d = board.bodies()[6].rates;
            writeln!(s, "\t\t{{ targets = {{ {}, {} }}, volumes = {{ {} }}, count = {}, deck = {{ {}, {}, {{ {}, {}, {}, {} }} }} }},", b(targets[0]), b(targets[1]), vs, collisions.len(),
                v(d.position), v(d.linear_velocity), b(d.orientation.x), b(d.orientation.y), b(d.orientation.z), b(d.orientation.w)).unwrap();
        }
        s.push_str("\t} },\n");
    }
    s.push_str("}\n");
    std::fs::write(format!("{out_dir}/colliders.luau"), s).unwrap();
}
