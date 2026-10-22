//! Эталон для board_step / board_runtime / board_pose / force_queue / contact_feedback:
//! несколько тиков доски на плоскости y = 0 с контактами колёс.
use crate::collision::{b, v, Rng};
use skate_core::math::{Basis3, Vector3};
use skate_core::physics::assembly::BodySnapshot;
use skate_core::physics::board::{BodyId, RETAIL_WHEEL_RADIUS};
use skate_core::physics::board_runtime::{BoardMotion, BoardRuntime};
use skate_core::physics::board_step::{BoardCollision, BoardStepSettings, CollisionBody};
use skate_core::physics::contact::{combine_contact_materials, RetailContactInput, RetailContactMaterial};
use skate_core::physics::contact_feedback::{average_wheel_compressions, choose_surface};
use skate_core::physics::drive_frames::{default_body_transforms, default_truck_transforms, RetailAffineTransform};
use skate_core::physics::drive_parameters::{retail_truck_drive_dynamics, RetailTruckDriveSettings};
use skate_core::physics::force_queue::{total_body_mass, QueuedPointForce};
use skate_core::physics::mass::default_skateboard_mass_properties;
use skate_core::physics::rigid_body::RetailSimulationStep;
use std::fmt::Write as _;

fn f3(x: [f32; 3]) -> String {
    format!("{{ {}, {}, {} }}", b(x[0]), b(x[1]), b(x[2]))
}
fn basis(x: Basis3) -> String {
    let c = x.columns;
    format!("{{ {}, {}, {} }}", f3(c[0]), f3(c[1]), f3(c[2]))
}
fn aff(t: RetailAffineTransform) -> String {
    format!("{{ {}, {} }}", basis(t.basis), v(t.translation))
}
fn snap(s: &BodySnapshot) -> String {
    let r = s.rates;
    format!(
        "{{ {}, {{ {}, {}, {}, {} }}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}",
        s.state_flags, b(r.orientation.x), b(r.orientation.y), b(r.orientation.z), b(r.orientation.w),
        basis(r.basis), basis(r.world_inverse_inertia), v(r.position), v(r.linear_velocity), v(r.angular_velocity),
        v(r.force_acceleration), v(r.torque_acceleration), b(r.kinetic_energy), r.cool_down
    )
}
fn rot_y(a: f32) -> Basis3 {
    let (s, c) = (a.sin(), a.cos());
    Basis3 { columns: [[c, 0.0, -s], [0.0, 1.0, 0.0], [s, 0.0, c]] }
}
fn body_s(c: CollisionBody) -> String {
    match c {
        CollisionBody::Board(id) => format!("{{ kind = \"Board\", id = {} }}", id as u8),
        CollisionBody::Attached(i) => format!("{{ kind = \"Attached\", index = {} }}", i),
        CollisionBody::StaticWorld => "{ kind = \"StaticWorld\" }".into(),
    }
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0xb0a2_d001);
    let mut s = String::from("-- Сгенерировано golden/src/board.rs из настоящего skate-core. Не править.\nreturn {\n\tscenarios = {\n");
    let wheel = RetailContactMaterial { static_friction: 0.9, dynamic_friction: 0.8, restitution: 0.0 };
    let floor = RetailContactMaterial { static_friction: 0.0, dynamic_friction: 0.0, restitution: 1.0 };
    let material = combine_contact_materials(wheel, floor);
    for scenario in 0..6 {
        let gravity = Vector3::new(0.0, -9.81, 0.0);
        let simulation = RetailSimulationStep::fixed_60_hz(0, 0.001, gravity);
        let settings = BoardStepSettings {
            simulation,
            iterations: if scenario == 0 { 50 } else { 10 + r.next() % 41 },
            base_truck_transforms: default_truck_transforms(),
            truck_dynamics: retail_truck_drive_dynamics(RetailTruckDriveSettings::STOCK),
            force_point_y_offset: r.range(-0.05, 0.05),
        };
        let heading = if scenario == 0 { 0.0 } else { r.range(-3.0, 3.0) };
        let height = RETAIL_WHEEL_RADIUS - default_body_transforms()[0].translation.y + r.range(0.0, 0.08);
        let spawn = RetailAffineTransform { basis: rot_y(heading), translation: Vector3::new(r.range(-5.0, 5.0), height, r.range(-5.0, 5.0)) };
        let mut board = BoardRuntime::new(default_skateboard_mass_properties(), default_body_transforms(), spawn, simulation, BoardMotion::Active);
        let mut ticks = String::new();
        let mut init = String::new();
        for body in board.bodies() { write!(init, "{}, ", snap(body)).unwrap(); }
        let init_hook = snap(&board.hook().body);
        for tick in 0..90 {
            // команды вне шага
            let mut op = String::from("nil");
            if tick == 40 && scenario % 3 == 1 {
                let t = RetailAffineTransform { basis: rot_y(r.range(-1.0, 1.0)), translation: Vector3::new(r.range(-1.0, 1.0), height + 0.05, r.range(-1.0, 1.0)) };
                board.set_transform(t);
                op = format!("{{ kind = \"set_transform\", t = {} }}", aff(t));
            } else if tick == 60 && scenario % 3 == 2 {
                let t = RetailAffineTransform { basis: rot_y(r.range(-1.0, 1.0)), translation: Vector3::new(0.0, height, 0.0) };
                let flags = if r.bool() { 0x0010_0000 } else { 0 };
                board.reset_physical(default_body_transforms(), t, flags, gravity);
                op = format!("{{ kind = \"reset_physical\", t = {}, flags = {} }}", aff(t), flags);
            }
            // силы
            board.clear_forces();
            let mut forces = String::new();
            let n = if tick % 4 == 0 { r.next() % 3 } else { 0 };
            for _ in 0..n {
                let f = QueuedPointForce { tag: r.next() % 100, force_world: r.vec(30.0), point_body: r.vec(0.3) };
                board.forces_mut().append(f);
                write!(forces, "{{ {}, {}, {} }}, ", f.tag, v(f.force_world), v(f.point_body)).unwrap();
            }
            // контакты колёс с плоскостью y = 0
            let mut collisions = Vec::new();
            let mut cs = String::new();
            for wheel_id in [BodyId::RightFrontWheel, BodyId::LeftFrontWheel, BodyId::RightBackWheel, BodyId::LeftBackWheel] {
                let p = board.bodies()[wheel_id.index()].rates.position;
                let bottom = p.y - RETAIL_WHEEL_RADIUS;
                if bottom < 0.02 {
                    let c = BoardCollision {
                        body_a: CollisionBody::Board(wheel_id),
                        body_b: CollisionBody::StaticWorld,
                        contact: RetailContactInput {
                            position_on_a: Vector3::new(p.x, bottom, p.z),
                            position_on_b: Vector3::new(p.x, 0.0, p.z),
                            normal: Vector3::new(0.0, 1.0, 0.0),
                            restitution: material.restitution,
                            static_friction: material.static_friction,
                            dynamic_friction: material.dynamic_friction,
                            tag: (wheel_id as u32) | (5 << 16),
                        },
                    };
                    write!(cs, "{{ a = {}, b = {}, input = {{ {}, {}, {}, {}, {}, {}, {} }} }}, ", body_s(c.body_a), body_s(c.body_b),
                        v(c.contact.position_on_a), v(c.contact.position_on_b), v(c.contact.normal), b(c.contact.restitution),
                        b(c.contact.static_friction), b(c.contact.dynamic_friction), c.contact.tag).unwrap();
                    collisions.push(c);
                }
            }
            let targets = [r.range(-0.2, 0.2), r.range(-0.2, 0.2)];
            board.advance(&collisions, targets, settings);
            let mut bs = String::new();
            for body in board.bodies() { write!(bs, "{}, ", snap(body)).unwrap(); }
            let mut ps = String::new();
            for t in board.part_transforms() { write!(ps, "{}, ", aff(t)).unwrap(); }
            let mut rs = String::new();
            for rep in board.contact_reports() {
                write!(rs, "{{ part = {}, other = {}, is_a = {}, normal = {}, position = {}, rel = {}, surface = {}, nf = {}, ff = {}, t0 = {}, t1 = {} }}, ",
                    rep.part as u8, body_s(rep.other), rep.is_body_a, v(rep.normal), v(rep.position), v(rep.relative_linear_velocity),
                    rep.other_surface, v(rep.normal_force_on_a), v(rep.friction_force_on_a), v(rep.tangents[0]), v(rep.tangents[1])).unwrap();
            }
            writeln!(s_tick(&mut ticks), "\t\t\t\t{{ op = {}, forces = {{ {} }}, collisions = {{ {} }}, targets = {{ {}, {} }}, bodies = {{ {} }}, hook = {}, parts = {{ {} }}, reports = {{ {} }} }},",
                op, forces, cs, b(targets[0]), b(targets[1]), bs, snap(&board.hook().body), ps, rs).unwrap();
        }
        writeln!(
            s,
            "\t\t{{ iterations = {}, y_offset = {}, spawn = {}, init = {{ {} }}, init_hook = {}, ticks = {{\n{}\t\t}} }},",
            settings.iterations, b(settings.force_point_y_offset), aff(spawn), init, init_hook, ticks
        )
        .unwrap();
    }
    s.push_str("\t},\n\tsurfaces = {\n");
    for _ in 0..500 {
        let surfaces = [r.next() % 16, r.next() % 16, r.next() % 16, r.next() % 16];
        let contacts = [r.bool(), r.bool(), r.bool(), r.bool()];
        let forced = r.next() % 8 == 0;
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {} }}, {{ {}, {}, {}, {} }}, {}, {} }},", surfaces[0], surfaces[1], surfaces[2], surfaces[3],
            contacts[0], contacts[1], contacts[2], contacts[3], forced, choose_surface(surfaces, contacts, forced)).unwrap();
    }
    s.push_str("\t},\n\tcompressions = {\n");
    for _ in 0..500 {
        let m: [[f32; 4]; 4] = core::array::from_fn(|_| [r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0)]);
        let w: [[f32; 4]; 4] = core::array::from_fn(|_| [r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0), 0.0]);
        let rest = r.range(-0.1, 0.0);
        let h = average_wheel_compressions(m, w, rest);
        let row = |x: [f32; 4]| format!("{{ {}, {}, {}, {} }}", b(x[0]), b(x[1]), b(x[2]), b(x[3]));
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {} }}, {{ {}, {}, {}, {} }}, {}, {}, {} }},", row(m[0]), row(m[1]), row(m[2]), row(m[3]),
            row(w[0]), row(w[1]), row(w[2]), row(w[3]), b(rest), b(h[0]), b(h[1])).unwrap();
    }
    s.push_str("\t},\n\ttotal_mass = {\n");
    for _ in 0..300 {
        let n = 1 + (r.next() % 9) as usize;
        let xs: Vec<f32> = (0..n).map(|_| r.range(0.01, 5.0)).collect();
        let mut l = String::new();
        for x in &xs { write!(l, "{}, ", b(*x)).unwrap(); }
        writeln!(s, "\t\t{{ {{ {} }}, {} }},", l, b(total_body_mass(&xs))).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/board.luau"), s).unwrap();
}

fn s_tick(s: &mut String) -> &mut String { s }
