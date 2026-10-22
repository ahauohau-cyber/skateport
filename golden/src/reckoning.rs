//! Эталон для riding/collision_response, physics/skeleton_animation_record,
//! riding/ground_orientation, riding/reckoning_frames.
use crate::collision::{b, v, Rng};
use crate::riding::{graph, gs};
use skate_core::math::Vector3;
use skate_core::physics::skeleton_animation_record::{compose_affine, map_animation_parts, physics_bone_frame, AnimationPartTransform, SkeletonAnimationMasses, SkeletonAnimationRecord, IDENTITY};
use skate_core::riding::collision_response::{collision_response, signed_angle, CollisionResponsePhysical, CollisionResponseSettings};
use skate_core::riding::ground_orientation::{GroundOrientation, GroundOrientationInput, GroundOrientationSettings};
use skate_core::riding::reckoning_frames::ReckoningFrames;
use std::fmt::Write as _;

fn f4(x: [f32; 4]) -> String { format!("{{ {}, {}, {}, {} }}", b(x[0]), b(x[1]), b(x[2]), b(x[3])) }
fn m4(m: &AnimationPartTransform) -> String { format!("{{ {}, {}, {}, {} }}", f4(m[0]), f4(m[1]), f4(m[2]), f4(m[3])) }
fn unit(r: &mut Rng) -> Vector3 { let a = r.vec(1.0); let l = (a.x*a.x+a.y*a.y+a.z*a.z).sqrt().max(1e-3); Vector3::new(a.x/l, a.y/l, a.z/l) }
fn upish(r: &mut Rng) -> Vector3 { match r.next() % 4 { 0 => Vector3::new(0.0, 1.0, 0.0), 1 => unit(r), _ => { let a = Vector3::new(r.range(-0.4,0.4), 1.0, r.range(-0.4,0.4)); let l=(a.x*a.x+a.y*a.y+a.z*a.z).sqrt(); Vector3::new(a.x/l,a.y/l,a.z/l) } } }
fn l4(x: Vector3) -> [f32; 4] { [x.x, x.y, x.z, 0.0] }
fn rand_frame(r: &mut Rng) -> AnimationPartTransform { let q = unit(r); let w = r.range(-1.0, 1.0); let n = (q.x*q.x+q.y*q.y+q.z*q.z+w*w).sqrt(); let t = r.vec(5.0); physics_bone_frame([q.x/n, q.y/n, q.z/n, w/n], [t.x, t.y, t.z, r.range(-1.0, 1.0)]) }

pub fn write(out_dir: &str) {
    let mut r = Rng(0x7ec0_4119);
    let mut s = String::from("-- Сгенерировано golden/src/reckoning.rs из настоящего skate-core. Не править.\nreturn {\n\tresponse = {\n");
    for _ in 0..1500 {
        let st = CollisionResponseSettings { maximum_velocity_delta: r.range(0.0, 10.0), force_y_offset: r.range(-0.1, 0.1), force_scalar: r.range(0.0, 2.0), target_displacement_velocity: r.range(-1.0, 3.0), torque_vs_angle: graph(&mut r) };
        let n = upish(&mut r);
        let disp = if r.next() % 10 == 0 { l4(n) } else { l4(r.vec(2.0)) };
        let input = CollisionResponsePhysical { flags_2472: if r.next() % 8 == 0 { 0 } else { 0x20000 | (r.next() & 0xffff) }, collision_displacement: disp, velocity: l4(r.vec(8.0)),
            forward: l4(unit(&mut r)), up: l4(upish(&mut r)), ground_normal: l4(n), time_step: if r.bool() { 1.0 / 60.0 } else { r.range(0.005, 0.05) }, mass: r.range(0.5, 80.0) };
        let out = match collision_response(&st, input) { Some(o) => format!("{{ {}, {}, {}, {}, {} }}", o.applied, f4(o.force), f4(o.point), f4(o.angular_displacement), f4(o.target_velocity)), None => "false".into() };
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {}, {} }}, {{ {}, {}, {}, {}, {}, {}, {}, {} }}, {} }},", b(st.maximum_velocity_delta), b(st.force_y_offset), b(st.force_scalar), b(st.target_displacement_velocity), gs(&st.torque_vs_angle),
            input.flags_2472, f4(input.collision_displacement), f4(input.velocity), f4(input.forward), f4(input.up), f4(input.ground_normal), b(input.time_step), b(input.mass), out).unwrap();
    }
    s.push_str("\t},\n\tsigned = {\n");
    for _ in 0..1500 {
        let a = if r.next() % 9 == 0 { r.vec(0.005) } else { r.vec(2.0) };
        let c = r.vec(2.0); let u = unit(&mut r);
        writeln!(s, "\t\t{{ {}, {}, {}, {} }},", v(a), v(c), v(u), b(signed_angle(a, c, u))).unwrap();
    }
    s.push_str("\t},\n\tskeleton = {\n");
    for _ in 0..40 {
        let sizes: [Vector3; 24] = core::array::from_fn(|_| Vector3::new(r.range(0.0, 0.5), r.range(0.0, 0.5), r.range(0.0, 0.5)));
        let shapes: [u32; 24] = core::array::from_fn(|_| r.next() % 5);
        let hat = r.bool();
        let masses = SkeletonAnimationMasses::from_bone_data(sizes, shapes, hat);
        let mut rec = SkeletonAnimationRecord::default();
        let mut steps = String::new();
        for _ in 0..6 {
            let pose: [AnimationPartTransform; 24] = core::array::from_fn(|_| rand_frame(&mut r));
            let to_board = rand_frame(&mut r);
            let reset = r.next() % 4 == 0;
            if reset { rec.reset_history(); }
            rec.update(&pose, &to_board, &masses);
            let ps: Vec<String> = pose.iter().map(m4).collect();
            write!(steps, "{{ reset = {}, pose = {{ {} }}, to_board = {}, out = {{ {}, {}, {}, {}, {} }} }}, ", reset, ps.join(", "), m4(&to_board),
                f4(rec.centre_of_mass), f4(rec.centre_of_mass_delta), f4(rec.com_to_deck_world), f4(rec.com_to_deck_world_delta), b(rec.reset_scalar)).unwrap();
        }
        let ss: Vec<String> = sizes.iter().map(|&x| v(x)).collect();
        writeln!(s, "\t\t{{ sizes = {{ {} }}, shapes = {{ {} }}, hat = {}, masses = {{ {{ {} }}, {}, {{ {} }} }}, steps = {{ {} }} }},", ss.join(", "), shapes.map(|x| x.to_string()).join(", "), hat,
            masses.part_weights.map(b).join(", "), b(masses.total), masses.fractional.map(b).join(", "), steps).unwrap();
    }
    s.push_str("\t},\n\tmapping = {\n");
    for _ in 0..30 {
        let globals: Vec<AnimationPartTransform> = (0..(5 + r.next() % 20)).map(|_| rand_frame(&mut r)).collect();
        let idx: [usize; 24] = core::array::from_fn(|_| (r.next() as usize) % (globals.len() + if r.next() % 30 == 0 { 3 } else { 0 }));
        let frames: [AnimationPartTransform; 24] = core::array::from_fn(|_| rand_frame(&mut r));
        let out = match map_animation_parts(&globals, &idx, &frames) { Ok(m) => format!("{{ {} }}", m.iter().map(m4).collect::<Vec<_>>().join(", ")), Err(_) => "false".into() };
        let c = compose_affine(&frames[0], &frames[1]);
        writeln!(s, "\t\t{{ globals = {{ {} }}, idx = {{ {} }}, frames = {{ {} }}, out = {}, compose = {} }},", globals.iter().map(m4).collect::<Vec<_>>().join(", "),
            idx.map(|x| x.to_string()).join(", "), frames.iter().map(m4).collect::<Vec<_>>().join(", "), out, m4(&c)).unwrap();
    }
    s.push_str("\t},\n\torientation = {\n");
    let ctl = |r: &mut Rng| [r.range(0.0, 1.0), r.range(0.0, 0.5), r.range(0.0, 0.5), r.range(0.05, 1.0)];
    for _ in 0..40 {
        let st = GroundOrientationSettings { ground_normal_smoothing: ctl(&mut r), up_vector_smoothing_slow: ctl(&mut r), up_vector_smoothing_fast: ctl(&mut r),
            dynamic_up_vs_ground_y: graph(&mut r), ground_vector_blend: graph(&mut r), deck_angle_usage_vs_speed: graph(&mut r), up_vector_smoothing_vs_speed: graph(&mut r), up_vector_max_delta_vs_speed: graph(&mut r),
            ground_blend_max_delta: r.range(0.0, 0.2), up_vector_max_acceleration: r.range(0.5, 5.0), anti_wobble_damping: r.range(0.0, 1.0), extra_side_damping: r.range(0.0, 1.0), minimum_wheels_for_ground_blend: (r.next() % 4) as i32 };
        let mut g = GroundOrientation::new(&st);
        let mut steps = String::new();
        for _ in 0..60 {
            if r.next() % 30 == 0 { g.reset(); write!(steps, "\"reset\", ").unwrap(); continue; }
            let input = GroundOrientationInput { com_to_deck: r.vec(1.0), ground_normal: upish(&mut r), dynamic_up: upish(&mut r), speed: r.range(-2.0, 12.0), wheel_contact_count: (r.next() % 5) as i32,
                animation_balance: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, deck_angle_curve_input: r.range(0.0, 1.5), board_up: upish(&mut r), board_forward: unit(&mut r),
                effective_board_forward: unit(&mut r), previous_reckoning_right: unit(&mut r), prevent_up_behind_board: r.next() % 3 == 0 };
            g.update(&st, input);
            write!(steps, "{{ {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}, {{ {}, {}, {}, {}, {}, {} }} }}, ",
                v(input.com_to_deck), v(input.ground_normal), v(input.dynamic_up), b(input.speed), input.wheel_contact_count, b(input.animation_balance), b(input.deck_angle_curve_input),
                v(input.board_up), v(input.board_forward), v(input.effective_board_forward), v(input.previous_reckoning_right), input.prevent_up_behind_board,
                v(g.dynamic_up), v(g.up), v(g.target), v(g.up_velocity), v(g.ground_normal), b(g.ground_blend)).unwrap();
        }
        writeln!(s, "\t\t{{ settings = {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}, steps = {{ {} }} }},",
            f4(st.ground_normal_smoothing), f4(st.up_vector_smoothing_slow), f4(st.up_vector_smoothing_fast), gs(&st.dynamic_up_vs_ground_y), gs(&st.ground_vector_blend), gs(&st.deck_angle_usage_vs_speed),
            gs(&st.up_vector_smoothing_vs_speed), gs(&st.up_vector_max_delta_vs_speed), b(st.ground_blend_max_delta), b(st.up_vector_max_acceleration), b(st.anti_wobble_damping), b(st.extra_side_damping),
            st.minimum_wheels_for_ground_blend, steps).unwrap();
    }
    s.push_str("\t},\n\tframes = {\n");
    for _ in 0..60 {
        let mut f = ReckoningFrames::new();
        if r.bool() { f.body_flip = rand_frame(&mut r); }
        let ta = graph(&mut r); let tu = graph(&mut r);
        let mut steps = String::new();
        for _ in 0..30 {
            let up = l4(upish(&mut r)); let gn = l4(upish(&mut r)); let du = l4(upish(&mut r)); let rev = r.bool();
            if r.next() % 10 == 0 { f.heading = l4(unit(&mut r)); }
            let heading_in = f.heading;
            f.calculate_transform(up, gn);
            f.calculate_dynamic_lean(up, du);
            f.calculate_tilt(rev, &ta, &tu);
            write!(steps, "{{ {}, {}, {}, {}, {}, {{ {}, {}, {}, {}, {}, {}, {}, {} }} }}, ", f4(heading_in), f4(up), f4(gn), f4(du), rev,
                m4(&f.ground), m4(&f.system), m4(&f.unflipped), m4(&f.inverse_system), m4(&f.body_flip), f4(f.heading), b(f.target_lean_angle), f4(f.lateral_tilt)).unwrap();
        }
        writeln!(s, "\t\t{{ flip = {}, ta = {}, tu = {}, steps = {{ {} }} }},", m4(&f.body_flip), gs(&ta), gs(&tu), steps).unwrap();
    }
    s.push_str("\t},\n}\n");
    let _ = IDENTITY;
    std::fs::write(format!("{out_dir}/reckoning.luau"), s).unwrap();
}
