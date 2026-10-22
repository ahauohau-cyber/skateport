//! Эталон для board_world: мир из треугольников с метаданными (кластеры по 64),
//! запросы лучом, query_primitives и доска 150 тиков на рампе с колёсами-сферами.
use crate::collision::{b, v, Rng};
use skate_core::math::{Basis3, Vector3};
use skate_core::physics::board::{BodyId, RETAIL_WHEEL_RADIUS};
use skate_core::physics::board_runtime::{BoardMotion, BoardRuntime};
use skate_core::physics::board_step::{BoardStepSettings, CollisionBody};
use skate_core::physics::board_world::query_metadata::{Bounds, QueryMesh, QueryMetadata, QueryPool};
use skate_core::physics::board_world::{BoardWorld, BoardWorldVolume, ContactRetentionSettings, VolumeMotion, WheelWorldSettings, WorldTriangle};
use skate_core::physics::collision::{Sphere, WorldContactSettings};
use skate_core::physics::contact::RetailContactMaterial;
use skate_core::physics::drive_frames::{default_body_transforms, default_truck_transforms, RetailAffineTransform};
use skate_core::physics::drive_parameters::{retail_truck_drive_dynamics, RetailTruckDriveSettings};
use skate_core::physics::force_queue::QueuedPointForce;
use skate_core::physics::mass::default_skateboard_mass_properties;
use skate_core::physics::rigid_body::RetailSimulationStep;
use skate_core::physics::world_contact::ContactPrimitive;
use std::fmt::Write as _;

fn tri_s(vs: [Vector3; 3], tag: u32, flags: u32, cos: [f32; 3], fat: f32) -> String {
    format!("{{ {}, {}, {}, {}, {}, {{ {}, {}, {} }}, {} }}", v(vs[0]), v(vs[1]), v(vs[2]), tag, flags, b(cos[0]), b(cos[1]), b(cos[2]), b(fat))
}
fn coll_s(c: &skate_core::physics::board_step::BoardCollision) -> String {
    let body = match c.body_a { CollisionBody::Board(id) => id as u32, _ => 99 };
    format!("{{ {}, {}, {}, {}, {}, {}, {}, {} }}", body, v(c.contact.position_on_a), v(c.contact.position_on_b), v(c.contact.normal),
        b(c.contact.restitution), b(c.contact.static_friction), b(c.contact.dynamic_friction), c.contact.tag)
}

pub fn ramp() -> (BoardWorld, String, f32) {
    let material = RetailContactMaterial { static_friction: 0.0, dynamic_friction: 0.0, restitution: 1.0 };
    // Пол, рампа 20° и коробка, квады разбиты (0,2,1),(0,3,2) как в ground.rs.
    let mut quads: Vec<[Vector3; 4]> = vec![];
    let n = Vector3::new;
    for gx in -4..4 {
        for gz in -4..4 {
            let (x0, z0) = (gx as f32 * 5.0, gz as f32 * 5.0);
            quads.push([n(x0, 0.0, z0), n(x0 + 5.0, 0.0, z0), n(x0 + 5.0, 0.0, z0 + 5.0), n(x0, 0.0, z0 + 5.0)]);
        }
    }
    let h = 20f32.to_radians().tan() * 4.0;
    quads.push([n(-2.0, 0.0, 6.0), n(2.0, 0.0, 6.0), n(2.0, h, 10.0), n(-2.0, h, 10.0)]);
    quads.push([n(-2.0, h, 10.0), n(2.0, h, 10.0), n(2.0, h, 12.0), n(-2.0, h, 12.0)]);
    quads.push([n(4.0, 0.3, -1.0), n(6.0, 0.3, -1.0), n(6.0, 0.3, 1.0), n(4.0, 0.3, 1.0)]);
    let mut tris = vec![];
    let mut ts = String::new();
    for (qi, q) in quads.iter().enumerate() {
        for idx in [[0, 2, 1], [0, 3, 2]] {
            let vs = idx.map(|i| q[i]);
            let tag = if qi == quads.len() - 1 { 0x600 } else { qi as u32 };
            let flags = 0x10 | 0x100 | 0xe0;
            let cos = [1.0, 1.0, 1.0];
            let fat = if qi % 7 == 0 { 0.01 } else { 0.0 };
            if let Some(t) = WorldTriangle::from_vertices(vs, material, tag, flags, cos, fat) {
                tris.push(t);
                write!(ts, "{}, ", tri_s(vs, tag, flags, cos, fat)).unwrap();
            }
        }
    }
    let mut meshes = vec![];
    for start in (0..tris.len()).step_by(16) {
        let end = (start + 16).min(tris.len());
        meshes.push(QueryMesh {
            geometry: 0, rejection_flags: 0, triangle_range: start..end,
            local_to_world: RetailAffineTransform::IDENTITY, world_to_local: RetailAffineTransform::IDENTITY,
            local_bounds: Bounds::from_points(tris[start..end].iter().flat_map(|t| t.triangle.vertices)).unwrap(),
            matching_group: -1, pool: QueryPool::Ground,
        });
    }
    let world = BoardWorld::with_query_metadata(tris.clone(), QueryMetadata { packed_surfaces: vec![0; tris.len()], meshes, static_edges: vec![], island_flags: 0 }).unwrap();
    (world, ts, h)
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x30a1_d001);
    let (mut world, ts, h) = ramp();
    let mut s = String::from("-- Сгенерировано golden/src/world.rs из настоящего skate-core. Не править.\nreturn {\n");
    writeln!(s, "\ttriangles = {{ {} }},", ts).unwrap();
    // лучи
    s.push_str("\tlines = {\n");
    for _ in 0..400 {
        let start = Vector3::new(r.range(-20.0, 20.0), r.range(0.5, 3.0), r.range(-20.0, 14.0));
        let end = Vector3::new(start.x + r.range(-1.0, 1.0), r.range(-1.0, 0.2), start.z + r.range(-1.0, 1.0));
        let radius = if r.bool() { 0.0 } else { r.range(0.0, 0.2) };
        let hit = world.query_swept_line(start, end, radius).unwrap();
        let hs = match hit { Some(h) => format!("{{ {}, {}, {}, {} }}", v(h.geometry.position), v(h.geometry.normal), b(h.geometry.fraction), h.tag), None => "false".into() };
        writeln!(s, "\t\t{{ {}, {}, {}, {} }},", v(start), v(end), b(radius), hs).unwrap();
    }
    s.push_str("\t},\n\twater = {\n");
    for _ in 0..100 {
        let p = Vector3::new(r.range(3.0, 7.0), r.range(-0.5, 1.0), r.range(-2.0, 2.0));
        let w = world.water_surface_at(p, 0.2, 1.0);
        writeln!(s, "\t\t{{ {}, {} }},", v(p), match w { Some(x) => b(x), None => "false".into() }).unwrap();
    }
    // query_primitives
    let query = WorldContactSettings { volume_padding: 0.05, maximum_separating_distance: 0.5, edge_cos_bend_normal_threshold: 0.999, convexity_epsilon: 0.01, is_object: false };
    let retention = ContactRetentionSettings { capacity: u32::MAX, duplicate_distance_squared: -1.0, deferred_reduction: true };
    s.push_str("\t},\n\tprimitives = {\n");
    for _ in 0..300 {
        let mut vols = vec![];
        let mut vs = String::new();
        for k in 0..(1 + r.next() % 4) {
            let c = Vector3::new(r.range(-6.0, 7.0), r.range(-0.05, 0.6), r.range(-3.0, 12.0));
            let prim = match k % 3 {
                0 => ContactPrimitive::Sphere(Sphere { center: c, radius: r.range(0.02, 0.2) }),
                1 => ContactPrimitive::Capsule { center: c, axis: Vector3::new(0.0, 0.0, 1.0), half_length: r.range(0.05, 0.3), radius: r.range(0.01, 0.05) },
                _ => ContactPrimitive::RoundedBox { center: c, basis: Basis3 { columns: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]] }, half_extents: Vector3::new(0.1, 0.01, 0.3), radius: 0.005 },
            };
            let motion = VolumeMotion { linear_velocity: r.vec(3.0), angular_velocity: r.vec(2.0), force_acceleration: Vector3::new(0.0, -9.8, 0.0), torque_acceleration: Vector3::ZERO };
            let group = if r.next() % 5 == 0 { 7 } else { 4 };
            let body = CollisionBody::Board(BodyId::ORDER[(k as usize) % 7]);
            let mat = RetailContactMaterial { static_friction: r.range(0.0, 1.0), dynamic_friction: r.range(0.0, 1.0), restitution: r.range(0.0, 0.5) };
            let ps = match prim {
                ContactPrimitive::Sphere(sp) => format!("{{ kind = \"Sphere\", center = {}, radius = {} }}", v(sp.center), b(sp.radius)),
                ContactPrimitive::Capsule { center, axis, half_length, radius } => format!("{{ kind = \"Capsule\", center = {}, axis = {}, half_length = {}, radius = {} }}", v(center), v(axis), b(half_length), b(radius)),
                ContactPrimitive::RoundedBox { center, half_extents, radius, .. } => format!("{{ kind = \"RoundedBox\", center = {}, half_extents = {}, radius = {} }}", v(center), v(half_extents), b(radius)),
                _ => unreachable!(),
            };
            write!(vs, "{{ group = {}, body = {}, prim = {}, motion = {{ {}, {}, {}, {} }}, mat = {{ {}, {}, {} }} }}, ", group, (k as usize) % 7, ps,
                v(motion.linear_velocity), v(motion.angular_velocity), v(motion.force_acceleration), v(motion.torque_acceleration),
                b(mat.static_friction), b(mat.dynamic_friction), b(mat.restitution)).unwrap();
            vols.push(BoardWorldVolume { collision_group: group, body, primitive: prim, motion, material: mat });
        }
        let out = world.query_primitives(&vols, query, retention);
        let mut os = String::new();
        for c in out { write!(os, "{}, ", coll_s(c)).unwrap(); }
        writeln!(s, "\t\t{{ volumes = {{ {} }}, out = {{ {} }} }},", vs, os).unwrap();
    }
    // доска на рампе
    s.push_str("\t},\n\tride = {\n");
    let gravity = Vector3::new(0.0, -9.81, 0.0);
    let simulation = RetailSimulationStep::fixed_60_hz(0, 0.001, gravity);
    let settings = BoardStepSettings { simulation, iterations: 50, base_truck_transforms: default_truck_transforms(),
        truck_dynamics: retail_truck_drive_dynamics(RetailTruckDriveSettings::STOCK), force_point_y_offset: 0.05 };
    let height = RETAIL_WHEEL_RADIUS - default_body_transforms()[0].translation.y;
    let spawn = RetailAffineTransform { translation: Vector3::new(0.0, height + h + 0.02, 11.0), ..RetailAffineTransform::IDENTITY };
    let mut board = BoardRuntime::new(default_skateboard_mass_properties(), default_body_transforms(), spawn, simulation, BoardMotion::Active);
    let wheel = WheelWorldSettings { radius: RETAIL_WHEEL_RADIUS, material: RetailContactMaterial { static_friction: 0.8, dynamic_friction: 0.7, restitution: 0.0 }, query, retention };
    for tick in 0..150 {
        board.clear_forces();
        if tick < 20 {
            board.forces_mut().append(QueuedPointForce { tag: 1, force_world: Vector3::new(0.0, 0.0, -25.0), point_body: Vector3::ZERO });
        }
        let collisions = world.query(&board, wheel).to_vec();
        let targets = [r.range(-0.1, 0.1), r.range(-0.1, 0.1)];
        board.advance(&collisions, targets, settings);
        let deck = board.bodies()[6].rates;
        let mut cs = String::new();
        for c in &collisions { write!(cs, "{}, ", coll_s(c)).unwrap(); }
        writeln!(s, "\t\t{{ targets = {{ {}, {} }}, collisions = {{ {} }}, deck = {{ {}, {}, {}, {{ {}, {}, {}, {} }} }} }},", b(targets[0]), b(targets[1]), cs,
            v(deck.position), v(deck.linear_velocity), v(deck.angular_velocity), b(deck.orientation.x), b(deck.orientation.y), b(deck.orientation.z), b(deck.orientation.w)).unwrap();
    }
    writeln!(s, "\t}},\n\tride_spawn = {},\n}}", v(spawn.translation)).unwrap();
    std::fs::write(format!("{out_dir}/world.luau"), s).unwrap();
}
