//! Эталон для решателя: contact_build, contact/joint/drive проходы, drive_solver::builder.
use crate::collision::{b, v, Rng};
use skate_core::math::{Basis3, Vector3};
use skate_core::physics::contact::{generate_contact, RetailContactBodyState, RetailContactInput};
use skate_core::physics::contact_solver::{build_contact_jacobian, RetailContactJacobian};
use skate_core::physics::drive_frames::{RetailDriveFrame, RetailDriveFrames};
use skate_core::physics::drive_parameters::{RetailDriveDynamics, RetailDriveParams, RetailDriveType};
use skate_core::physics::drive_preparation::normalize_drive_frames;
use skate_core::physics::drive_solver::{build_drive_rows, RetailDriveBodyState, RetailDriveRows};
use skate_core::physics::joint_solver::RetailJointJacobian;
use skate_core::physics::rigid_body::{
    RetailPackedWorldInverseInertia, RetailQuaternion, RetailReactionCorrections,
};
use skate_core::physics::solver::{solve_constraints, JointConstraint};
use std::fmt::Write as _;

const DT: f32 = f32::from_bits(0x3C88_8889);

fn words(w: &[u32]) -> String {
    let mut s = String::from("{ ");
    for x in w {
        write!(s, "{}, ", x).unwrap();
    }
    s.push('}');
    s
}
fn f3(x: [f32; 3]) -> String {
    format!("{{ {}, {}, {} }}", b(x[0]), b(x[1]), b(x[2]))
}
fn q(x: RetailQuaternion) -> String {
    format!("{{ {}, {}, {}, {} }}", b(x.x), b(x.y), b(x.z), b(x.w))
}
fn basis(x: Basis3) -> String {
    let c = x.columns;
    format!("{{ {}, {}, {} }}", f3(c[0]), f3(c[1]), f3(c[2]))
}
fn reaction(r: &RetailReactionCorrections) -> String {
    format!("{{ {}, {}, {}, {} }}", v(r.linear_displacement), v(r.position_displacement), v(r.angular_displacement), v(r.orientation_displacement))
}
fn quat(r: &mut Rng) -> RetailQuaternion {
    let a = r.vec(1.0);
    let w = r.range(-1.0, 1.0);
    let l = (a.x * a.x + a.y * a.y + a.z * a.z + w * w).sqrt();
    RetailQuaternion { x: a.x / l, y: a.y / l, z: a.z / l, w: w / l }
}
fn rot(qq: RetailQuaternion) -> Basis3 {
    let (x, y, z, w) = (qq.x, qq.y, qq.z, qq.w);
    Basis3 {
        columns: [
            [1.0 - 2.0 * (y * y + z * z), 2.0 * (x * y + z * w), 2.0 * (x * z - y * w)],
            [2.0 * (x * y - z * w), 1.0 - 2.0 * (x * x + z * z), 2.0 * (y * z + x * w)],
            [2.0 * (x * z + y * w), 2.0 * (y * z - x * w), 1.0 - 2.0 * (x * x + y * y)],
        ],
    }
}
fn rand_reactions(r: &mut Rng, n: usize) -> Vec<RetailReactionCorrections> {
    (0..n)
        .map(|_| {
            if r.bool() {
                RetailReactionCorrections::default()
            } else {
                RetailReactionCorrections {
                    linear_displacement: r.vec(0.05),
                    position_displacement: r.vec(0.05),
                    angular_displacement: r.vec(0.05),
                    orientation_displacement: r.vec(0.05),
                }
            }
        })
        .collect()
}
fn contact_body(r: &mut Rng, reaction: u32) -> RetailContactBodyState {
    let state = match r.next() % 3 { 0 => 0, 1 => 4, _ => 4 | 8 };
    RetailContactBodyState {
        contact_body_id: r.next(),
        center_of_mass: r.vec(1.0),
        reaction_id: reaction,
        inverse_inertia_full: Vector3::new(r.range(0.0, 50.0), r.range(-5.0, 5.0), r.range(-5.0, 5.0)),
        inverse_mass: r.range(0.0, 3.0),
        inverse_inertia_split: Vector3::new(r.range(0.0, 50.0), r.range(0.0, 50.0), r.range(-5.0, 5.0)),
        state,
        force_acceleration: Vector3::new(r.range(-3.0, 3.0), -9.81, r.range(-3.0, 3.0)),
        kinetic_energy: r.range(0.0, 3.0),
        torque_acceleration: r.vec(5.0),
        cool_down: r.next() % 9,
        linear_velocity: r.vec(4.0),
        angular_velocity: r.vec(4.0),
    }
}
fn cbody(x: &RetailContactBodyState) -> String {
    format!(
        "{{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}",
        x.contact_body_id, v(x.center_of_mass), x.reaction_id, v(x.inverse_inertia_full),
        b(x.inverse_mass), v(x.inverse_inertia_split), x.state, v(x.force_acceleration),
        b(x.kinetic_energy), v(x.torque_acceleration), x.cool_down, v(x.linear_velocity),
        v(x.angular_velocity)
    )
}
fn unit(r: &mut Rng) -> Vector3 {
    loop {
        let p = r.vec(1.0);
        let l = (p.x * p.x + p.y * p.y + p.z * p.z).sqrt();
        if l > 0.1 { return Vector3::new(p.x / l, p.y / l, p.z / l); }
    }
}
fn random_contact(r: &mut Rng, n: usize) -> RetailContactJacobian {
    let a = (r.next() as usize) % n;
    let mut bb = (r.next() as usize) % n;
    if bb == a { bb = (a + 1) % n; }
    let body_a = contact_body(r, a as u32);
    let body_b = contact_body(r, bb as u32);
    let pa = r.vec(1.0);
    let input = RetailContactInput {
        position_on_a: pa,
        position_on_b: Vector3::new(pa.x + r.range(-0.02, 0.02), pa.y + r.range(-0.02, 0.02), pa.z + r.range(-0.02, 0.02)),
        normal: unit(r),
        restitution: r.range(0.0, 1.0),
        static_friction: r.range(0.0, 1.5),
        dynamic_friction: r.range(0.0, 1.5),
        tag: r.next(),
    };
    build_contact_jacobian(generate_contact(input, body_a, body_b), DT)
}
fn drive_body(r: &mut Rng, reaction: usize) -> RetailDriveBodyState {
    let o = quat(r);
    RetailDriveBodyState {
        reaction_index: reaction,
        state: if r.next() % 5 == 0 { 0 } else { 4 },
        orientation: o,
        basis: rot(o),
        center_of_mass: r.vec(1.0),
        linear_velocity: r.vec(3.0),
        angular_velocity: r.vec(3.0),
        force_acceleration: Vector3::new(0.0, -9.81, 0.0),
        torque_acceleration: r.vec(4.0),
        inverse_mass: r.range(0.1, 3.0),
        world_inverse_inertia: RetailPackedWorldInverseInertia {
            full: Vector3::new(r.range(1.0, 80.0), r.range(-3.0, 3.0), r.range(-3.0, 3.0)),
            split: Vector3::new(r.range(1.0, 80.0), r.range(1.0, 80.0), r.range(-3.0, 3.0)),
        },
    }
}
fn params(r: &mut Rng) -> RetailDriveParams {
    match r.next() % 3 {
        0 => RetailDriveParams { spring_or_max_velocity: 0.0, damping: 0.0, max_strength: 0.0, drive_type: RetailDriveType::NoDrive },
        1 => RetailDriveParams { spring_or_max_velocity: r.range(100.0, 5000.0), damping: r.range(0.0, 100.0), max_strength: r.range(100.0, 50000.0), drive_type: RetailDriveType::SoftDrive },
        _ => RetailDriveParams { spring_or_max_velocity: r.range(0.1, 6000.0), damping: 0.0, max_strength: r.range(100.0, 360000.0), drive_type: RetailDriveType::HardDrive },
    }
}
fn random_drive(r: &mut Rng, n: usize) -> RetailDriveRows {
    let a = (r.next() as usize) % n;
    let mut bb = (r.next() as usize) % n;
    if bb == a { bb = (a + 1) % n; }
    let fa = drive_body(r, a);
    let fb = drive_body(r, bb);
    let frames = RetailDriveFrames {
        body_a: RetailDriveFrame { orientation: if r.bool() { RetailQuaternion::IDENTITY } else { quat(r) }, translation: r.vec(0.3) },
        body_b: RetailDriveFrame { orientation: if r.bool() { RetailQuaternion::IDENTITY } else { quat(r) }, translation: r.vec(0.3) },
    };
    let dynamics = RetailDriveDynamics { linear: params(r), angular: params(r) };
    build_drive_rows(fa, fb, frames, dynamics, DT)
}
fn drive_body_s(x: &RetailDriveBodyState) -> String {
    format!(
        "{{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}",
        x.reaction_index, x.state, q(x.orientation), basis(x.basis), v(x.center_of_mass), v(x.linear_velocity),
        v(x.angular_velocity), v(x.force_acceleration), v(x.torque_acceleration), b(x.inverse_mass),
        v(x.world_inverse_inertia.full), v(x.world_inverse_inertia.split)
    )
}
fn rows_s(d: &RetailDriveRows) -> String {
    format!(
        "{{ {}, {}, {{ {}, {}, {} }}, {{ {}, {}, {} }}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}",
        v(d.arm_a), v(d.arm_b), v(d.linear_axes[0]), v(d.linear_axes[1]), v(d.linear_axes[2]),
        v(d.angular_axes[0]), v(d.angular_axes[1]), v(d.angular_axes[2]),
        f3(d.linear_inverse_effective_mass), f3(d.angular_inverse_effective_mass), b(d.linear_softness), b(d.angular_softness),
        f3(d.linear_target_impulse), f3(d.angular_target_impulse), f3(d.linear_maximum_impulse), f3(d.angular_maximum_impulse),
        f3(d.accumulated_linear_impulse), f3(d.accumulated_angular_impulse)
    )
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x501e_e001);
    let mut s = String::from("-- Сгенерировано golden/src/solver.rs из настоящего skate-core. Не править.\nreturn {\n\tdrive_rows = {\n");
    for _ in 0..1500 {
        let a = (r.next() as usize) % 7;
        let fa = drive_body(&mut r, a);
        let fb = drive_body(&mut r, (a + 1) % 7);
        let frames = RetailDriveFrames {
            body_a: RetailDriveFrame { orientation: if r.bool() { RetailQuaternion::IDENTITY } else { quat(&mut r) }, translation: r.vec(0.3) },
            body_b: RetailDriveFrame { orientation: if r.bool() { RetailQuaternion::IDENTITY } else { quat(&mut r) }, translation: r.vec(0.3) },
        };
        let dynamics = RetailDriveDynamics { linear: params(&mut r), angular: params(&mut r) };
        let d = build_drive_rows(fa, fb, frames, dynamics, DT);
        let p = |x: RetailDriveParams| format!("{{ {}, {}, {}, {} }}", b(x.spring_or_max_velocity), b(x.damping), b(x.max_strength), x.drive_type as u32);
        writeln!(
            s,
            "\t\t{{ a = {}, b = {}, frames = {{ {}, {}, {}, {} }}, dynamics = {{ {}, {} }}, rows = {} }},",
            drive_body_s(&fa), drive_body_s(&fb), q(frames.body_a.orientation), v(frames.body_a.translation),
            q(frames.body_b.orientation), v(frames.body_b.translation), p(dynamics.linear), p(dynamics.angular), rows_s(&d)
        )
        .unwrap();
    }
    s.push_str("\t},\n\tcontacts = {\n");
    for _ in 0..1500 {
        let a = (r.next() % 7) as u32;
        let body_a = contact_body(&mut r, a);
        let body_b = contact_body(&mut r, (a + 1) % 7);
        let pa = r.vec(1.0);
        let input = RetailContactInput {
            position_on_a: pa,
            position_on_b: Vector3::new(pa.x + r.range(-0.02, 0.02), pa.y + r.range(-0.02, 0.02), pa.z + r.range(-0.02, 0.02)),
            normal: unit(&mut r),
            restitution: r.range(0.0, 1.0),
            static_friction: r.range(0.0, 1.5),
            dynamic_friction: r.range(0.0, 1.5),
            tag: r.next(),
        };
        let c = build_contact_jacobian(generate_contact(input, body_a, body_b), DT);
        writeln!(
            s,
            "\t\t{{ input = {{ {}, {}, {}, {}, {}, {}, {} }}, a = {}, b = {}, words = {}, ra = {}, rb = {} }},",
            v(input.position_on_a), v(input.position_on_b), v(input.normal), b(input.restitution), b(input.static_friction),
            b(input.dynamic_friction), input.tag, cbody(&body_a), cbody(&body_b), words(c.words()), c.reaction_index_a, c.reaction_index_b
        )
        .unwrap();
    }
    s.push_str("\t},\n\tsolve = {\n");
    for i in 0..400 {
        let n = 2 + (r.next() % 6) as usize;
        let mut contacts: Vec<RetailContactJacobian> = (0..(r.next() % 5)).map(|_| random_contact(&mut r, n)).collect();
        let mut joints: Vec<JointConstraint> = (0..(r.next() % 4))
            .map(|_| {
                let a = (r.next() as usize) % n;
                let bb = (a + 1 + (r.next() as usize) % (n - 1)) % n;
                let mut w = [0u32; 96];
                for x in w.iter_mut() {
                    *x = r.range(-2.0, 2.0).to_bits();
                }
                JointConstraint { jacobian: RetailJointJacobian { words: w }, reaction_a: a, reaction_b: bb }
            })
            .collect();
        let mut drives: Vec<RetailDriveRows> = (0..(r.next() % 4)).map(|_| random_drive(&mut r, n)).collect();
        let mut reactions = rand_reactions(&mut r, n);
        let iterations = if i % 10 == 0 { 0 } else { 1 + r.next() % 8 };
        let mut c_in = String::new();
        for c in &contacts { write!(c_in, "{{ {}, {}, {} }}, ", words(c.words()), c.reaction_index_a, c.reaction_index_b).unwrap(); }
        let mut j_in = String::new();
        for j in &joints { write!(j_in, "{{ {}, {}, {} }}, ", words(&j.jacobian.words), j.reaction_a, j.reaction_b).unwrap(); }
        let mut d_in = String::new();
        for d in &drives { write!(d_in, "{{ fa = {}, fb = {}, rows = {} }}, ", drive_body_s(&d.frame_a_body), drive_body_s(&d.frame_b_body), rows_s(d)).unwrap(); }
        let mut r_in = String::new();
        for x in &reactions { write!(r_in, "{}, ", reaction(x)).unwrap(); }
        solve_constraints(&mut contacts, &mut joints, &mut drives, &mut reactions, iterations);
        let mut c_out = String::new();
        for c in &contacts { write!(c_out, "{}, ", words(c.words())).unwrap(); }
        let mut j_out = String::new();
        for j in &joints { write!(j_out, "{}, ", words(&j.jacobian.words)).unwrap(); }
        let mut d_out = String::new();
        for d in &drives { write!(d_out, "{{ {}, {} }}, ", f3(d.accumulated_linear_impulse), f3(d.accumulated_angular_impulse)).unwrap(); }
        let mut r_out = String::new();
        for x in &reactions { write!(r_out, "{}, ", reaction(x)).unwrap(); }
        writeln!(
            s,
            "\t\t{{ iterations = {}, contacts = {{ {} }}, joints = {{ {} }}, drives = {{ {} }}, reactions = {{ {} }}, out = {{ contacts = {{ {} }}, joints = {{ {} }}, drives = {{ {} }}, reactions = {{ {} }} }} }},",
            iterations, c_in, j_in, d_in, r_in, c_out, j_out, d_out, r_out
        )
        .unwrap();
    }
    s.push_str("\t},\n\tnormalize = {\n");
    for _ in 0..500 {
        let mut w = [0u32; 16];
        for x in w.iter_mut() { *x = r.range(-2.0, 2.0).to_bits(); }
        let input = w;
        normalize_drive_frames(&mut w);
        writeln!(s, "\t\t{{ {}, {} }},", words(&input), words(&w)).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/solver.luau"), s).unwrap();
}
