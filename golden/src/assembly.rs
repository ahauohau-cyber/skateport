//! Эталон для joint_records, joint_builder, hook_drive, truck_frames и assembly.
use crate::collision::{b, v, Rng};
use skate_core::math::{Basis3, Vector3};
use skate_core::physics::assembly::{prepare_drive_frames, BoardConstraints, BoardHook, BodySnapshot};
use skate_core::physics::drive_frames::{
    default_live_body_orientations, default_live_body_transforms, default_truck_transforms,
    RetailAffineTransform, RetailDriveFrames,
};
use skate_core::physics::drive_parameters::{retail_truck_drive_dynamics, RetailTruckDriveSettings};
use skate_core::physics::hook_drive::HookDriveState;
use skate_core::physics::joint_builder::{build_retail_joint_jacobian, RetailJointBodyInput, RetailJointBuildInput};
use skate_core::physics::joint_records::{default_joint_records, joint_records, RetailJointFramesRaw, RetailJointParametersRaw, RetailJointSettings};
use skate_core::physics::mass::default_skateboard_mass_properties;
use skate_core::physics::rigid_body::{
    basis_from_quaternion, world_inverse_inertia, RetailBodyRates, RetailPackedWorldInverseInertia,
    RetailQuaternion, RetailReactionCorrections,
};
use skate_core::physics::solver::solve_constraints;
use skate_core::physics::truck_frames::{steering_drive_frames, steering_truck_transforms};
use std::fmt::Write as _;

const DT: f32 = f32::from_bits(0x3C88_8889);

fn words(w: &[u32]) -> String {
    let mut s = String::from("{ ");
    for x in w { write!(s, "{}, ", x).unwrap(); }
    s.push('}');
    s
}
fn q(x: RetailQuaternion) -> String {
    format!("{{ {}, {}, {}, {} }}", b(x.x), b(x.y), b(x.z), b(x.w))
}
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
fn frames_s(f: RetailDriveFrames) -> String {
    format!("{{ {}, {}, {}, {} }}", q(f.body_a.orientation), v(f.body_a.translation), q(f.body_b.orientation), v(f.body_b.translation))
}
fn quat(r: &mut Rng) -> RetailQuaternion {
    let a = r.vec(1.0);
    let w = r.range(-1.0, 1.0);
    let l = (a.x * a.x + a.y * a.y + a.z * a.z + w * w).sqrt();
    RetailQuaternion { x: a.x / l, y: a.y / l, z: a.z / l, w: w / l }
}
fn reaction(x: &RetailReactionCorrections) -> String {
    format!("{{ {}, {}, {}, {} }}", v(x.linear_displacement), v(x.position_displacement), v(x.angular_displacement), v(x.orientation_displacement))
}
fn snapshot_s(s: &BodySnapshot) -> String {
    let r = s.rates;
    let i = s.inertia;
    format!(
        "{{ flags = {}, rates = {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}, inertia = {{ {}, {}, {}, {}, {}, {}, {} }} }}",
        s.state_flags, q(r.orientation), basis(r.basis), basis(r.world_inverse_inertia), v(r.position),
        v(r.linear_velocity), v(r.angular_velocity), v(r.force_acceleration), v(r.torque_acceleration),
        b(r.kinetic_energy), r.cool_down,
        v(i.inverse_tensor), b(i.inverse_mass), b(i.spherical), b(i.maximum_linear_velocity),
        b(i.maximum_angular_velocity), b(i.linear_drag), b(i.angular_drag)
    )
}
fn stock_bodies() -> [BodySnapshot; 7] {
    let poses = default_live_body_transforms();
    let orientations = default_live_body_orientations();
    let masses = default_skateboard_mass_properties();
    core::array::from_fn(|i| {
        let basis = basis_from_quaternion(orientations[i]);
        BodySnapshot {
            state_flags: 4,
            inertia: masses[i].dynamics,
            rates: RetailBodyRates {
                orientation: orientations[i],
                basis,
                world_inverse_inertia: world_inverse_inertia(basis, masses[i].dynamics.inverse_tensor),
                position: poses[i].translation,
                linear_velocity: Vector3::ZERO,
                angular_velocity: Vector3::ZERO,
                force_acceleration: Vector3::ZERO,
                torque_acceleration: Vector3::ZERO,
                kinetic_energy: 0.0,
                cool_down: 0,
            },
        }
    })
}
fn joint_body(r: &mut Rng) -> RetailJointBodyInput {
    let o = quat(r);
    RetailJointBodyInput {
        reaction_guest_address: if r.bool() { 0 } else { r.next() },
        state: if r.next() % 5 == 0 { 0 } else { 4 },
        orientation: o,
        center_of_mass: r.vec(1.0),
        basis: basis_from_quaternion(o),
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
fn jbody_s(x: &RetailJointBodyInput) -> String {
    format!(
        "{{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}",
        x.reaction_guest_address, x.state, q(x.orientation), v(x.center_of_mass), basis(x.basis), v(x.linear_velocity),
        v(x.angular_velocity), v(x.force_acceleration), v(x.torque_acceleration), b(x.inverse_mass),
        v(x.world_inverse_inertia.full), v(x.world_inverse_inertia.split)
    )
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0xa55e_b1e5);
    let mut s = String::from("-- Сгенерировано golden/src/assembly.rs из настоящего skate-core. Не править.\nreturn {\n");
    // joint_records
    s.push_str("\trecords = {\n");
    for i in 0..60 {
        let st = if i == 0 { RetailJointSettings::STOCK } else {
            RetailJointSettings { truck_twist_limit_degrees: r.range(10.0, 180.0), truck_twist_angle_degrees: r.range(0.0, 45.0), wheel_swing_limit_degrees: r.range(1.0, 1e6) }
        };
        let recs = joint_records(st);
        let mut rs = String::new();
        for rec in recs {
            write!(rs, "{{ {}, {}, {}, {} }}, ", rec.definition_body_0 as u8, rec.definition_body_1 as u8, words(&rec.parameters.words), words(&rec.frames.words)).unwrap();
        }
        writeln!(s, "\t\t{{ settings = {{ {}, {}, {} }}, records = {{ {} }} }},", b(st.truck_twist_limit_degrees), b(st.truck_twist_angle_degrees), b(st.wheel_swing_limit_degrees), rs).unwrap();
    }
    let _ = default_joint_records();
    // joint_builder
    s.push_str("\t},\n\tjoints = {\n");
    for i in 0..3000 {
        let mut p = [0u32; 16];
        for k in 0..8 { if k % 4 != 3 { p[k] = r.range(0.0, 0.05).to_bits(); } }
        p[8] = r.range(0.0, 20.0).to_bits();
        p[9] = r.range(0.0, 20.0).to_bits();
        p[12] = r.range(-1.0, 1.0).to_bits();
        p[13] = r.range(-1.0, 1.0).to_bits();
        p[14] = (i % 5) as u32; // swing_mode 0..4
        p[15] = ((i / 5) % 3) as u32; // twist_mode 0..2
        let mut f = [0u32; 20];
        let (qa, qb, ql) = (quat(&mut r), quat(&mut r), quat(&mut r));
        let (ta, tb) = (r.vec(0.3), r.vec(0.3));
        for (off, qq) in [(0, qa), (8, qb), (16, ql)] { f[off..off + 4].copy_from_slice(&[qq.x, qq.y, qq.z, qq.w].map(f32::to_bits)); }
        for (off, t) in [(4, ta), (12, tb)] { f[off..off + 3].copy_from_slice(&[t.x, t.y, t.z].map(f32::to_bits)); }
        let mut ba = joint_body(&mut r);
        let bb = joint_body(&mut r);
        if i % 13 == 0 { ba.orientation = bb.orientation; ba.basis = bb.basis; }
        let addr = if r.bool() { 0 } else { r.next() };
        let jac = build_retail_joint_jacobian(RetailJointBuildInput {
            parameters: RetailJointParametersRaw { words: p },
            frames: RetailJointFramesRaw { words: f },
            body_a: ba,
            body_b: bb,
            time_step: DT,
            joint_guest_address: addr,
        });
        writeln!(s, "\t\t{{ p = {}, f = {}, a = {}, b = {}, addr = {}, out = {} }},", words(&p), words(&f), jbody_s(&ba), jbody_s(&bb), addr, words(&jac.words)).unwrap();
    }
    // hook_drive
    s.push_str("\t},\n\thook = {\n");
    {
        let mut h = HookDriveState::initial();
        let mut animated = 0u8;
        let mut steps = String::new();
        write!(steps, "{{ {}, {}, {} }}, ", words(&h.frames), words(&h.dynamics), animated).unwrap();
        for op in [0, 1, 2, 3, 0, 2, 1, 3] {
            match op {
                0 => h.enable_animation_soft(&mut animated),
                1 => h.enable_angular_soft(),
                2 => h.enable_angular_only(&mut animated),
                _ => h.disable_animation(&mut animated),
            }
            write!(steps, "{{ {}, {}, {} }}, ", words(&h.frames), words(&h.dynamics), animated).unwrap();
        }
        writeln!(s, "\t\t{}", steps).unwrap();
    }
    // truck_frames
    s.push_str("\t},\n\ttrucks = {\n");
    for _ in 0..500 {
        let base = default_truck_transforms();
        let t = [r.range(-0.5, 0.5), r.range(-0.5, 0.5)];
        let tr = steering_truck_transforms(base, t);
        let fr = steering_drive_frames(base, t);
        writeln!(s, "\t\t{{ {{ {}, {} }}, {}, {}, {}, {} }},", b(t[0]), b(t[1]), aff(tr[0]), aff(tr[1]), frames_s(fr[0]), frames_s(fr[1])).unwrap();
    }
    // assembly: build + solve
    s.push_str("\t},\n\tassembly = {\n");
    for i in 0..300 {
        let mut bodies = stock_bodies();
        for body in bodies.iter_mut() {
            if i > 0 {
                body.rates.position.x += r.range(-0.003, 0.003);
                body.rates.position.y += r.range(-0.003, 0.003);
                body.rates.linear_velocity = r.vec(3.0);
                body.rates.angular_velocity = r.vec(2.0);
                body.rates.force_acceleration = Vector3::new(0.0, -9.81, 0.0);
                body.rates.torque_acceleration = r.vec(1.0);
                if r.next() % 10 == 0 { body.state_flags = 0; }
            }
        }
        let mut hook_body = bodies[6];
        hook_body.state_flags = if i % 3 == 0 { 4 } else { 0 };
        let mut hook = BoardHook { body: hook_body, drive: HookDriveState::initial() };
        let mut animated = 0u8;
        if i % 3 == 0 { hook.drive.enable_animation_soft(&mut animated); }
        let targets = if i == 0 { [0.0, 0.0] } else { [r.range(-0.3, 0.3), r.range(-0.3, 0.3)] };
        let hook_in = words(&hook.drive.frames);
        let hook_dyn = words(&hook.drive.dynamics);
        let frames = prepare_drive_frames(default_truck_transforms(), targets, &mut hook);
        let mut c = BoardConstraints::build(&bodies, &hook, frames, retail_truck_drive_dynamics(RetailTruckDriveSettings::STOCK), DT);
        let mut jw = String::new();
        for j in &c.joints { write!(jw, "{{ {}, {}, {} }}, ", words(&j.jacobian.words), j.reaction_a, j.reaction_b).unwrap(); }
        let drives_before = c.drives.len();
        let mut reactions = [RetailReactionCorrections::default(); 8];
        let iterations = if i == 0 { 25 } else { 1 + r.next() % 25 };
        solve_constraints(&mut [], &mut c.joints, &mut c.drives, &mut reactions, iterations);
        let mut bs = String::new();
        for body in &bodies { write!(bs, "{}, ", snapshot_s(body)).unwrap(); }
        let mut fs = String::new();
        for f in frames { write!(fs, "{}, ", frames_s(f)).unwrap(); }
        let mut rs = String::new();
        for x in &reactions { write!(rs, "{}, ", reaction(x)).unwrap(); }
        let mut ds = String::new();
        for d in &c.drives { write!(ds, "{{ {}, {} }}, ", f3(d.accumulated_linear_impulse), f3(d.accumulated_angular_impulse)).unwrap(); }
        writeln!(
            s,
            "\t\t{{ bodies = {{ {} }}, hook = {{ body = {}, frames = {}, dynamics = {} }}, targets = {{ {}, {} }}, iterations = {}, frames = {{ {} }}, hook_frames_after = {}, joints = {{ {} }}, drive_count = {}, drives = {{ {} }}, reactions = {{ {} }} }},",
            bs, snapshot_s(&hook.body), hook_in, hook_dyn, b(targets[0]), b(targets[1]), iterations, fs, words(&hook.drive.frames), jw, drives_before, ds, rs
        )
        .unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/assembly.luau"), s).unwrap();
}
