//! Эталон для physics: board_animation, board_dynamic_normal, centre_of_mass_filter,
//! deck_angular_correction, filtered_state, foot_physical_output, ground_hang_geometry.
//! Только синтетические входы (данные игры не нужны) — файл можно коммитить.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::animation::skeleton_input::name::encode;
use skate_core::math::{Basis3, Vector3};
use skate_core::physics::{
    board::BODY_COUNT,
    board_animation::{target_velocity, BoardAnimation, BoardAnimationSettings},
    board_dynamic_normal::{BoardDynamicNormal, DynamicNormalSettings},
    board_ground::BoardGroundState,
    centre_of_mass_filter::CentreOfMassFilter,
    deck_angular_correction as dac,
    filtered_state::{FilteredState, FilteredStateInput, GrindState},
    foot_physical_output::{FootPhysicalSettings, FootPhysicalState},
    ground_hang_geometry::{hang_lines, HangGeometryInput},
    rigid_body::{RetailBodyRates, RetailQuaternion},
    skeleton_animation_record::{physics_bone_frame, AnimationPartTransform},
    skeleton_body::SkeletonPhysicalRecord,
};
use skate_core::point_graph::PointGraph;
use std::fmt::Write as _;

type T = AnimationPartTransform;

fn quat(r: &mut Rng) -> [f32; 4] {
    let a = r.vec(1.0);
    let w = r.range(-1.0, 1.0);
    let l = (a.x * a.x + a.y * a.y + a.z * a.z + w * w).sqrt();
    [a.x / l, a.y / l, a.z / l, w / l]
}
fn rigid(r: &mut Rng, span: f32) -> T { let t = r.vec(span); physics_bone_frame(quat(r), [t.x, t.y, t.z, 0.0]) }
fn v4(r: &mut Rng, span: f32) -> [f32; 4] { let v = r.vec(span); [v.x, v.y, v.z, r.range(-span, span)] }
fn graph8(r: &mut Rng, lo: f32, hi: f32) -> PointGraph<8> {
    let mut x = [0.0f32; 8];
    let mut acc = 0.0;
    for i in 0..8 { x[i] = acc; acc += r.range(0.05, 0.6); }
    PointGraph { x, y: std::array::from_fn(|_| r.range(lo, hi)) }
}
fn basis_l(b: Basis3) -> Raw { Raw(format!("{{ columns = {} }}", b.columns.l())) }
fn rates_l(x: &RetailBodyRates) -> Raw {
    Raw(obj!(orientation = Raw(obj!(x = x.orientation.x, y = x.orientation.y, z = x.orientation.z, w = x.orientation.w)), basis = basis_l(x.basis),
        world_inverse_inertia = basis_l(x.world_inverse_inertia), position = x.position, linear_velocity = x.linear_velocity, angular_velocity = x.angular_velocity,
        force_acceleration = x.force_acceleration, torque_acceleration = x.torque_acceleration, kinetic_energy = x.kinetic_energy, cool_down = x.cool_down))
}
fn grind_l(g: &GrindState) -> Raw {
    Raw(obj!(kind = g.kind, scorable_id = g.scorable_id, name = g.name.0, scoring_name = g.scoring_name.0, on_front = g.on_front, crouch = g.crouch,
        pathed_guid = [(g.pathed_guid >> 32) as u32, g.pathed_guid as u32], local_guid = [(g.local_guid >> 32) as u32, g.local_guid as u32]))
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x9a55_e703);
    let mut s = format!("-- Сгенерировано golden/src/phys3.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");

    // board_animation
    s.push_str("\tboard_animation = {\n");
    for _ in 0..30 {
        let st = BoardAnimationSettings { slow: graph8(&mut r, 0.0, 1.0), fast: graph8(&mut r, 0.3, 1.0) };
        let mut a = BoardAnimation::default();
        let mut ops = Vec::new();
        for _ in 0..12 {
            let op = r.next() % 4;
            let t1 = rigid(&mut r, 2.0);
            let t2 = rigid(&mut r, 2.0);
            let fast = r.bool();
            let out = match op { 0 => { a.capture_physics_error(&t1, &t2); None } 1 => { a.reset(); None } _ => Some(a.apply(&t1, fast, &st)) };
            ops.push(obj!(op = op, t1 = t1, t2 = t2, fast = fast, out = out, rotation_error = a.rotation_error, blending = a.blending));
        }
        writeln!(s, "\t\t{{ settings = {}, ops = {{ {} }} }},", obj!(slow = st.slow, fast = st.fast), ops.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n\ttarget_velocity = {\n");
    for _ in 0..30 {
        let (t, p, dt) = (v4(&mut r, 5.0), v4(&mut r, 5.0), [1.0f32 / 60.0, 0.02, 0.5][(r.next() % 3) as usize]);
        writeln!(s, "\t\t{},", obj!(t = t, p = p, dt = dt, out = target_velocity(t, p, dt))).unwrap();
    }
    s.push_str("\t},\n");

    // board_dynamic_normal
    s.push_str("\tdynamic_normal = {\n");
    for _ in 0..30 {
        let st = DynamicNormalSettings { speed_damping: r.range(0.0, 1.0), up_vector_damping: r.range(0.0, 1.0), maximum_delta: r.range(0.0, 0.5), speed_scale: r.range(1.0, 20.0), maximum_delta_vs_speed: graph8(&mut r, 0.0, 2.0) };
        let mut f = BoardDynamicNormal::new();
        let mut steps = Vec::new();
        for _ in 0..10 {
            let mut c = BoardGroundState::default();
            c.wheel_contact_count = (r.next() % 5) as u8;
            for i in 0..BODY_COUNT { c.parts[i].in_contact = r.bool(); }
            let vels: [Vector3; BODY_COUNT] = std::array::from_fn(|_| r.vec(10.0));
            c.sample_accelerations(vels, 1.0 / 60.0);
            c.overall_normal = r.vec(1.0);
            let g = Vector3::new(0.0, -9.81, 0.0);
            let speed = r.range(-20.0, 20.0);
            f.update(&c, g, speed, &st);
            steps.push(obj!(count = c.wheel_contact_count, in_contact = c.parts.iter().map(|p| p.in_contact).collect::<Vec<_>>(), accelerations = c.accelerations, overall = c.overall_normal, speed = speed,
                normal = f.normal, delta = f.delta, acceleration = f.acceleration, last = f.last_contact_normal));
        }
        writeln!(s, "\t\t{{ settings = {}, steps = {{ {} }} }},", obj!(speed_damping = st.speed_damping, up_vector_damping = st.up_vector_damping, maximum_delta = st.maximum_delta, speed_scale = st.speed_scale, maximum_delta_vs_speed = st.maximum_delta_vs_speed), steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n");

    // COM filter
    s.push_str("\tcom_filter = {\n");
    for _ in 0..20 {
        let mut f = CentreOfMassFilter::default();
        let mut steps = Vec::new();
        for i in 0..20 {
            let do_reset = i == 10 && r.bool();
            if do_reset { f.reset(); }
            let (p, v) = (v4(&mut r, 3.0), v4(&mut r, 3.0));
            let o = f.update(p, v);
            steps.push(obj!(reset = do_reset, p = p, v = v, velocity = o.velocity, acceleration = o.acceleration, position = o.position));
        }
        writeln!(s, "\t\t{{ {} }},", steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n");

    // deck angular correction
    s.push_str("\tdeck = {\n");
    for _ in 0..200 {
        let b = { let q = quat(&mut r); skate_core::physics::rigid_body::basis_from_quaternion(RetailQuaternion { x: q[0], y: q[1], z: q[2], w: q[3] }) };
        let d = [r.range(1.0, 4.0), r.range(1.0, 4.0), r.range(1.0, 4.0)];
        let o = [r.range(-0.3, 0.3), r.range(-0.3, 0.3), r.range(-0.3, 0.3)];
        let body = RetailBodyRates { orientation: RetailQuaternion::IDENTITY, basis: b,
            world_inverse_inertia: Basis3 { columns: [[d[0], o[0], o[1]], [o[0], d[1], o[2]], [o[1], o[2], d[2]]] },
            position: r.vec(5.0), linear_velocity: r.vec(5.0), angular_velocity: r.vec(5.0), force_acceleration: r.vec(5.0), torque_acceleration: r.vec(5.0), kinetic_energy: r.unit(), cool_down: r.next() % 40 };
        let op = r.next() % 4;
        let req = if r.next() % 8 == 0 { Vector3::ZERO } else { r.vec(0.05) };
        let mut out = body;
        match op { 0 => dac::apply_axis_displacement(&mut out, req), 1 => dac::apply_limited_displacement(&mut out, req), 2 => dac::apply_angular_displacement(&mut out, req), _ => dac::apply_ground_body_torque(&mut out) }
        writeln!(s, "\t\t{},", obj!(op = op, req = req, body = rates_l(&body), out = rates_l(&out))).unwrap();
    }
    s.push_str("\t},\n");

    // filtered state
    s.push_str("\tfiltered = {\n");
    let states = [100, 101, 103, 105, 602, 200, 200, 200, 201, 202, 600, 601, 300, 400, 403, 405, 500, 502, 501, 503, 702, 701, 999];
    for _ in 0..20 {
        let mut f = FilteredState::default();
        let mut steps = Vec::new();
        for i in 0..40 {
            let do_reset = i == 30 && r.next() % 3 == 0;
            if do_reset { f.reset(); }
            let st = states[(r.next() as usize) % states.len()];
            let mut g = GrindState::default();
            if r.bool() { g = GrindState { kind: (r.next() % 8) as i32, scorable_id: (r.next() % 50) as i32, name: encode(b"fs smith"), scoring_name: encode(b"smith"), on_front: r.bool(), crouch: r.unit(),
                pathed_guid: ((r.next() as u64) << 32) | r.next() as u64, local_guid: ((r.next() as u64) << 32) | r.next() as u64 }; }
            let input = FilteredStateInput { physics_category: st / 100 * 100, physics_state: st, anything_in_contact: r.bool(), physics_surface_type: [0, 8][(r.next() % 2) as usize],
                wall_ride_exit: r.next() % 4 == 0, targeting_grind: r.bool(), offboard_has_landed: r.bool(), offboard_on_deck: r.bool(), grind: g, last_grind_distance: r.unit() };
            let o = f.update(input);
            steps.push(obj!(reset = do_reset, input = Raw(obj!(physics_category = input.physics_category, physics_state = input.physics_state, anything_in_contact = input.anything_in_contact,
                physics_surface_type = input.physics_surface_type, wall_ride_exit = input.wall_ride_exit, targeting_grind = input.targeting_grind, offboard_has_landed = input.offboard_has_landed,
                offboard_on_deck = input.offboard_on_deck, grind = grind_l(&input.grind), last_grind_distance = input.last_grind_distance)),
                out = Raw(obj!(category = o.category as u32, previous_category = o.previous_category as u32, grinding = o.grinding, grind = grind_l(&o.grind), last_grind_distance = o.last_grind_distance)),
                state = Raw(obj!(air_count = f.air_count, nonspecific_count = f.nonspecific_count, nonspecific_collision_free_count = f.nonspecific_collision_free_count,
                    nonspecific_collision_count = f.nonspecific_collision_count, frames_since_ground_stairs = f.frames_since_ground_stairs, must_change = f.must_change, previous_physics_state = f.previous_physics_state))));
        }
        writeln!(s, "\t\t{{ {} }},", steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n");

    // foot physical output
    s.push_str("\tfeet = {\n");
    for _ in 0..20 {
        let st = FootPhysicalSettings { deck_half_width: r.range(0.05, 0.15), deck_total_half_length: r.range(0.3, 0.5), padding: v4(&mut r, 0.1) };
        let mut f = FootPhysicalState::default();
        let mut steps = Vec::new();
        for _ in 0..6 {
            let mut rec = SkeletonPhysicalRecord::default();
            rec.pose[0] = rigid(&mut r, 3.0);
            rec.pose[15] = rigid(&mut r, 3.0);
            rec.pose[19] = rigid(&mut r, 3.0);
            if r.bool() { rec.pose[15][3] = rec.pose[0][3]; }
            rec.velocities[15] = v4(&mut r, 3.0);
            rec.velocities[19] = v4(&mut r, 3.0);
            let dt = [1.0f32 / 60.0, 0.25][(r.next() % 2) as usize];
            let o = f.update(&rec, dt, st);
            steps.push(obj!(board = rec.pose[0], toe1 = rec.pose[15], toe2 = rec.pose[19], v1 = rec.velocities[15], v2 = rec.velocities[19], dt = dt,
                local_velocity = o.local_velocity, world_velocity = o.world_velocity, within = o.within_deck_box));
        }
        writeln!(s, "\t\t{{ settings = {}, steps = {{ {} }} }},", obj!(deck_half_width = st.deck_half_width, deck_total_half_length = st.deck_total_half_length, padding = st.padding), steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n\thang = {\n");
    for i in 0..100 {
        let a = r.vec(3.0);
        let b = if i % 10 == 0 { a } else if i % 10 == 1 { Vector3::new(a.x, a.y + 1.0, a.z) } else { r.vec(3.0) };
        let p = r.vec(3.0);
        let d = r.range(0.1, 0.4);
        let lines = hang_lines(HangGeometryInput { edge_start: a, edge_end: b, reference_point: p }, d);
        writeln!(s, "\t\t{},", obj!(a = a, b = b, p = p, d = d, lines = lines.map(|ls| ls.iter().map(|l| Raw(obj!(start = l.start, end_ = l.end, radius = l.radius))).collect::<Vec<_>>()))).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/phys3.luau"), s).unwrap();
}
