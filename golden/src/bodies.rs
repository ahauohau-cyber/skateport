//! Эталон для physics/contact, physics/point_force и physics/rigid_body.
use crate::collision::{b, v, Rng};
use skate_core::math::{Basis3, Vector3};
use skate_core::physics::contact::{
    combine_contact_materials, generate_contact, RetailContactBodyState, RetailContactInput,
    RetailContactMaterial, RetailContactWorkspace,
};
use skate_core::physics::point_force::{accumulate_point_force, RetailForceAccumulator};
use skate_core::physics::rigid_body::{
    basis_from_quaternion, integrate_body_rates, integrate_orientation,
    multiply_packed_world_inverse_inertia, pack_world_inverse_inertia, world_inverse_inertia,
    RetailBodyRates, RetailInertiaDynamics, RetailQuaternion, RetailReactionCorrections,
    RetailSimulationStep,
};
use std::fmt::Write as _;

fn unit(r: &mut Rng) -> Vector3 {
    loop {
        let p = r.vec(1.0);
        let l = (p.x * p.x + p.y * p.y + p.z * p.z).sqrt();
        if l > 0.1 {
            return Vector3::new(p.x / l, p.y / l, p.z / l);
        }
    }
}
fn quat(r: &mut Rng) -> RetailQuaternion {
    let a = r.vec(1.0);
    let w = r.range(-1.0, 1.0);
    let l = (a.x * a.x + a.y * a.y + a.z * a.z + w * w).sqrt();
    RetailQuaternion { x: a.x / l, y: a.y / l, z: a.z / l, w: w / l }
}
fn q(x: RetailQuaternion) -> String {
    format!("{{ {}, {}, {}, {} }}", b(x.x), b(x.y), b(x.z), b(x.w))
}
fn basis(x: Basis3) -> String {
    let c = x.columns;
    format!(
        "{{ {{ {}, {}, {} }}, {{ {}, {}, {} }}, {{ {}, {}, {} }} }}",
        b(c[0][0]), b(c[0][1]), b(c[0][2]), b(c[1][0]), b(c[1][1]), b(c[1][2]),
        b(c[2][0]), b(c[2][1]), b(c[2][2])
    )
}
fn rand_basis(r: &mut Rng) -> Basis3 {
    let a = r.vec(2.0);
    let c = r.vec(2.0);
    let d = r.vec(2.0);
    Basis3 { columns: [[a.x, a.y, a.z], [c.x, c.y, c.z], [d.x, d.y, d.z]] }
}
fn body(r: &mut Rng) -> RetailContactBodyState {
    let still = r.next() % 4 == 0;
    RetailContactBodyState {
        contact_body_id: r.next(),
        center_of_mass: r.vec(3.0),
        reaction_id: r.next(),
        inverse_inertia_full: r.vec(5.0),
        inverse_mass: r.range(0.0, 2.0),
        inverse_inertia_split: r.vec(5.0),
        state: r.next(),
        force_acceleration: r.vec(9.0),
        kinetic_energy: r.range(0.0, 10.0),
        torque_acceleration: r.vec(9.0),
        cool_down: r.next() % 100,
        linear_velocity: if still { Vector3::ZERO } else { r.vec(6.0) },
        angular_velocity: if still { Vector3::ZERO } else { r.vec(6.0) },
    }
}
fn body_s(x: &RetailContactBodyState) -> String {
    format!(
        "{{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}",
        x.contact_body_id, v(x.center_of_mass), x.reaction_id, v(x.inverse_inertia_full),
        b(x.inverse_mass), v(x.inverse_inertia_split), x.state, v(x.force_acceleration),
        b(x.kinetic_energy), v(x.torque_acceleration), x.cool_down, v(x.linear_velocity),
        v(x.angular_velocity)
    )
}
fn ws(x: &RetailContactWorkspace) -> String {
    format!(
        "{{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}",
        v(x.center_of_mass), x.reaction_id, v(x.inverse_inertia_full), b(x.inverse_mass),
        v(x.inverse_inertia_split), x.state, v(x.force_acceleration), b(x.kinetic_energy),
        v(x.torque_acceleration), x.cool_down
    )
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0xb0d1_e5);
    let mut s = String::from("-- Сгенерировано golden/src/bodies.rs из настоящего skate-core. Не править.\nreturn {\n\tcontact = {\n");
    for i in 0..3000 {
        let normal = match i % 10 {
            0 => Vector3::new(0.0, 1.0, 0.0),
            1 => Vector3::new(1.0, 0.0, 0.0),
            2 => Vector3::new(-0.8, 0.6, 0.0),
            _ => unit(&mut r),
        };
        let a = body(&mut r);
        let mut bb = body(&mut r);
        let pa = r.vec(4.0);
        let pb = if r.bool() { pa } else { r.vec(4.0) };
        if i % 7 == 0 {
            // одинаковые скорости точек -> запасная касательная
            bb.linear_velocity = a.linear_velocity;
            bb.angular_velocity = a.angular_velocity;
            bb.center_of_mass = a.center_of_mass;
        }
        let input = RetailContactInput {
            position_on_a: pa,
            position_on_b: pb,
            normal,
            restitution: r.range(0.0, 1.0),
            static_friction: r.range(0.0, 1.5),
            dynamic_friction: r.range(0.0, 1.5),
            tag: r.next(),
        };
        let c = generate_contact(input, a, bb);
        writeln!(
            s,
            "\t\t{{ input = {{ {}, {}, {}, {}, {}, {}, {} }}, a = {}, b = {}, out = {{ t0 = {}, t1 = {}, rv = {}, wa = {}, wb = {} }} }},",
            v(pa), v(pb), v(normal), b(input.restitution), b(input.static_friction),
            b(input.dynamic_friction), input.tag, body_s(&a), body_s(&bb),
            v(c.tangent_0), v(c.tangent_1), v(c.relative_velocity),
            ws(&c.body_a_workspace), ws(&c.body_b_workspace)
        )
        .unwrap();
    }
    s.push_str("\t},\n\tmaterial = {\n");
    let specials = [f32::NAN, f32::from_bits(0x7F80_0001), 0.0, -0.0, f32::INFINITY];
    for i in 0..1000 {
        let m = |r: &mut Rng| {
            let pick = |r: &mut Rng| {
                if r.next() % 8 == 0 { specials[(r.next() % 5) as usize] } else { r.range(0.0, 1.0) }
            };
            RetailContactMaterial { static_friction: pick(r), dynamic_friction: pick(r), restitution: pick(r) }
        };
        let a = m(&mut r);
        let bb = if i % 5 == 0 { a } else { m(&mut r) };
        let c = combine_contact_materials(a, bb);
        writeln!(
            s,
            "\t\t{{ {{ {}, {}, {} }}, {{ {}, {}, {} }}, {{ {}, {}, {} }} }},",
            b(a.static_friction), b(a.dynamic_friction), b(a.restitution),
            b(bb.static_friction), b(bb.dynamic_friction), b(bb.restitution),
            b(c.static_friction), b(c.dynamic_friction), b(c.restitution)
        )
        .unwrap();
    }
    s.push_str("\t},\n\tpoint_force = {\n");
    for _ in 0..2000 {
        let acc = RetailForceAccumulator {
            force_acceleration: r.vec(10.0),
            torque_acceleration: r.vec(10.0),
            cool_down: r.next() % 50,
        };
        let force = r.vec(200.0);
        let point = r.vec(0.5);
        let deck = rand_basis(&mut r);
        let inv_mass = r.range(0.0, 1.0);
        let inertia = rand_basis(&mut r);
        let out = accumulate_point_force(acc, force, point, deck, inv_mass, inertia);
        writeln!(
            s,
            "\t\t{{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }},",
            v(acc.force_acceleration), v(acc.torque_acceleration), acc.cool_down, v(force),
            v(point), basis(deck), b(inv_mass), basis(inertia),
            v(out.force_acceleration), v(out.torque_acceleration)
        )
        .unwrap();
    }
    s.push_str("\t},\n\tintegrate = {\n");
    for i in 0..3000 {
        let orientation = if i % 11 == 0 { RetailQuaternion::IDENTITY } else { quat(&mut r) };
        let fast = i % 3 == 0;
        let body = RetailBodyRates {
            orientation,
            basis: rand_basis(&mut r),
            world_inverse_inertia: rand_basis(&mut r),
            position: r.vec(50.0),
            linear_velocity: r.vec(if fast { 60.0 } else { 5.0 }),
            angular_velocity: r.vec(if fast { 80.0 } else { 3.0 }),
            force_acceleration: r.vec(20.0),
            torque_acceleration: r.vec(20.0),
            kinetic_energy: r.range(0.0, 5.0),
            cool_down: r.next() % 20,
        };
        let inertia = RetailInertiaDynamics {
            inverse_tensor: Vector3::new(r.range(0.0, 50.0), r.range(0.0, 50.0), r.range(0.0, 50.0)),
            inverse_mass: r.range(0.0, 1.0),
            spherical: r.range(0.0, 1.0),
            maximum_linear_velocity: r.range(5.0, 40.0),
            maximum_angular_velocity: r.range(5.0, 60.0),
            linear_drag: r.range(0.0, if i % 13 == 0 { 100.0 } else { 2.0 }),
            angular_drag: r.range(0.0, 2.0),
        };
        let cool = r.next() % 30;
        let hi = if r.bool() { 0.01 } else { 50.0 };
        let sim = RetailSimulationStep::fixed_60_hz(
            cool,
            r.range(0.0, hi),
            Vector3::new(0.0, -9.81, 0.0),
        );
        let reactions = if r.bool() {
            RetailReactionCorrections::default()
        } else {
            RetailReactionCorrections {
                linear_displacement: r.vec(0.05),
                position_displacement: r.vec(0.05),
                angular_displacement: r.vec(0.05),
                orientation_displacement: r.vec(0.05),
            }
        };
        let out = integrate_body_rates(body, inertia, sim, reactions);
        let st = out.state;
        writeln!(
            s,
            "\t\t{{ body = {{ {}, {}, {}, {}, {}, {}, {}, {}, {} }}, inertia = {{ {}, {}, {}, {}, {}, {}, {} }}, sim = {{ {}, {}, {}, {}, {} }}, reactions = {{ {}, {}, {}, {} }}, out = {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }} }},",
            q(body.orientation), v(body.position), v(body.linear_velocity), v(body.angular_velocity),
            v(body.force_acceleration), v(body.torque_acceleration), b(body.kinetic_energy), body.cool_down,
            basis(body.basis),
            v(inertia.inverse_tensor), b(inertia.inverse_mass), b(inertia.spherical),
            b(inertia.maximum_linear_velocity), b(inertia.maximum_angular_velocity),
            b(inertia.linear_drag), b(inertia.angular_drag),
            b(sim.time_step), b(sim.frequency), sim.cool_down, b(sim.minimum_energy), v(sim.gravity_acceleration),
            v(reactions.linear_displacement), v(reactions.position_displacement),
            v(reactions.angular_displacement), v(reactions.orientation_displacement),
            q(st.orientation), basis(st.basis), basis(st.world_inverse_inertia), v(st.position),
            v(st.linear_velocity), v(st.angular_velocity), v(st.force_acceleration),
            v(st.torque_acceleration), b(st.kinetic_energy), st.cool_down,
            v(out.orientation_displacement), b(out.linear_speed_squared), b(out.angular_speed_squared),
            b(sim.frequency)
        )
        .unwrap();
    }
    s.push_str("\t},\n\torientation = {\n");
    for _ in 0..2000 {
        let o = quat(&mut r);
        let d = r.vec(0.3);
        let out = integrate_orientation(o, d);
        let bq = basis_from_quaternion(out);
        let tensor = r.vec(30.0);
        let wi = world_inverse_inertia(bq, tensor);
        let packed = pack_world_inverse_inertia(wi);
        let x = r.vec(4.0);
        let m = multiply_packed_world_inverse_inertia(packed, x);
        writeln!(
            s,
            "\t\t{{ {}, {}, {}, {}, {}, {}, {}, {} }},",
            q(o), v(d), q(out), basis(bq), v(tensor), basis(wi), v(x), v(m)
        )
        .unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/bodies.luau"), s).unwrap();
}
