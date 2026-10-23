//! Эталон для air::ground_jump::calculate и air::state математики
//! (AirMath, clamp_jump_velocity, angle_between_vectors, calculate_velocity_from_jump,
//! integrate_trajectory_fixed_step, wrap_signed_angle). Синтетика — можно коммитить.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::air::ground_jump::{calculate, GroundJumpInput, GroundJumpMode, GroundJumpSettings};
use skate_core::air::state::{
    angle_between_vectors, calculate_velocity_from_jump, clamp_jump_velocity, integrate_trajectory_fixed_step, wrap_signed_angle,
    AirMath, AirTrajectory, PhysicsAirFrame, PhysicsAirMath,
};
use skate_core::point_graph::PointGraph;
use std::fmt::Write as _;

type V = [f32; 4];

fn unit(r: &mut Rng) -> V {
    let v = r.vec(1.0);
    let l = (v.x * v.x + v.y * v.y + v.z * v.z).sqrt().max(1e-3);
    [v.x / l, v.y / l, v.z / l, 0.0]
}
fn v4(r: &mut Rng, span: f32) -> V { let v = r.vec(span); [v.x, v.y, v.z, if r.next() % 4 == 0 { r.range(-1.0, 1.0) } else { 0.0 }] }
fn graph<const N: usize>(r: &mut Rng, x0: f32, step: f32, lo: f32, hi: f32) -> PointGraph<N> {
    let mut x = [0.0f32; N];
    let mut acc = x0;
    for i in 0..N { x[i] = acc; acc += r.range(step * 0.2, step); }
    PointGraph { x, y: std::array::from_fn(|_| r.range(lo, hi)) }
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x93a1_c0de);
    let mut s = format!("-- Сгенерировано golden/src/gjump.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n\tjump = {{\n");
    for _ in 0..300 {
        let st = GroundJumpSettings { vertical_response: graph(&mut r, 0.0, 0.1, 0.0, 1.5), y_scalar_vs_normal_y: graph(&mut r, 0.0, 0.2, 0.5, 2.0),
            speed_scalar_vs_angle: graph(&mut r, 0.0, 0.2, 0.0, 1.2), minimum_height_vs_speed: graph(&mut r, 0.0, 0.2, 0.0, 1.0),
            maximum_height_vs_speed: graph(&mut r, 0.0, 0.2, 0.0, 1.0), speed_response_max_speed: r.range(2.0, 12.0), minimum_scalar: r.range(0.0, 1.0),
            maximum_y_bonus: r.range(0.0, 3.0), adjust_z_factor: r.range(0.0, 1.0), adjust_x_factor: r.range(0.0, 1.0), absolute_minimum_height: r.range(0.0, 0.3),
            hippy_minimum_height: r.range(0.2, 0.5), hippy_maximum_height: r.range(0.5, 1.5) };
        let mode = GroundJumpMode { minimum_height_64: r.range(0.1, 0.5), minimum_height_68: r.range(0.1, 0.5), maximum_height: r.range(0.5, 1.5) };
        let mut gn = unit(&mut r);
        if r.bool() { gn = [gn[0] * 0.2, 1.0, gn[2] * 0.2, 0.0]; let l = (gn[0] * gn[0] + 1.0 + gn[2] * gn[2]).sqrt(); gn = [gn[0] / l, gn[1] / l, gn[2] / l, 0.0]; }
        let i = GroundJumpInput { flags_2468: if r.next() % 6 == 0 { 0 } else { 0x0040_0000 }, flags_2480: if r.next() % 5 == 0 { 0x1000 } else { 0 },
            flags_2484: if r.bool() { 0x800 } else { 0 }, flags_2488: if r.next() % 6 == 0 { 0x1000_0000 } else { 0 }, effective_forward: unit(&mut r), forward: unit(&mut r),
            current_velocity: v4(&mut r, 8.0), ground_reference_position: v4(&mut r, 1.0), reference_up: unit(&mut r), filtered_ground_normal: gn,
            animation_com_position: v4(&mut r, 1.5), prepared_velocity: v4(&mut r, 8.0), jump_strength: r.range(0.0, 1.0), jump_controls: [r.range(-1.0, 1.0), r.range(-1.0, 1.0)],
            gravity_y: r.range(-12.0, -6.0), surface_speed: r.range(0.0, 15.0) };
        let out = calculate(i, mode, &st);
        writeln!(s, "\t\t{},", obj!(settings = Raw(obj!(vertical_response = st.vertical_response, y_scalar_vs_normal_y = st.y_scalar_vs_normal_y,
            speed_scalar_vs_angle = st.speed_scalar_vs_angle, minimum_height_vs_speed = st.minimum_height_vs_speed, maximum_height_vs_speed = st.maximum_height_vs_speed,
            speed_response_max_speed = st.speed_response_max_speed, minimum_scalar = st.minimum_scalar, maximum_y_bonus = st.maximum_y_bonus, adjust_z_factor = st.adjust_z_factor,
            adjust_x_factor = st.adjust_x_factor, absolute_minimum_height = st.absolute_minimum_height, hippy_minimum_height = st.hippy_minimum_height,
            hippy_maximum_height = st.hippy_maximum_height)),
            mode = Raw(obj!(minimum_height_64 = mode.minimum_height_64, minimum_height_68 = mode.minimum_height_68, maximum_height = mode.maximum_height)),
            input = Raw(obj!(flags_2468 = i.flags_2468, flags_2480 = i.flags_2480, flags_2484 = i.flags_2484, flags_2488 = i.flags_2488, effective_forward = i.effective_forward,
                forward = i.forward, current_velocity = i.current_velocity, ground_reference_position = i.ground_reference_position, reference_up = i.reference_up,
                filtered_ground_normal = i.filtered_ground_normal, animation_com_position = i.animation_com_position, prepared_velocity = i.prepared_velocity,
                jump_strength = i.jump_strength, jump_controls = i.jump_controls, gravity_y = i.gravity_y, surface_speed = i.surface_speed)),
            out = Raw(obj!(velocity = out.velocity, scalar_16 = out.scalar_16, active = out.active)))).unwrap();
    }
    s.push_str("\t},\n\tmath = {\n");
    for _ in 0..300 {
        let (a, b, m) = (if r.next() % 8 == 0 { [0.0; 4] } else { v4(&mut r, 5.0) }, v4(&mut r, 5.0), r.range(-1.0, 6.0));
        let frame = PhysicsAirFrame { current_velocity_400: v4(&mut r, 8.0), ground_position_y_500: 0.0, trajectory_position_592: [0.0; 4], trajectory_velocity_608: [0.0; 4],
            jump_velocity_848: v4(&mut r, 8.0), flags_2468: 0, previous_physics_state_2504: 0, previous_physics_category_2516: 0, frames_since_jump_correction_2576: 0,
            delta_time_2604: r.range(0.0, 0.05), body_spin_input_2640: 0.0, gravity_y_2648: r.range(-12.0, -6.0), state_timer_2664: 0.0 };
        let frames = (r.next() % 14) as i32 - 1;
        let mut t = AirTrajectory { position: v4(&mut r, 3.0), velocity: v4(&mut r, 6.0), acceleration: v4(&mut r, 10.0), scalar_48: -1.0 };
        let t_in = t;
        integrate_trajectory_fixed_step(&mut t);
        let ang = r.range(-20.0, 20.0);
        writeln!(s, "\t\t{},", obj!(a = a, b = b, maximum = m, min = AirMath.minimum_vminfp(m, ang), length_squared = AirMath.length_squared_vmsum3fp(a),
            length = AirMath.length_vmsum3fp_vrsqrte(a), clamp = AirMath.clamp_vector_within_max_length(a, m), clamp_jump = clamp_jump_velocity(a, b),
            angle = angle_between_vectors(a, b), angle_in = ang, wrap = wrap_signed_angle(ang),
            frame = Raw(obj!(current_velocity_400 = frame.current_velocity_400, jump_velocity_848 = frame.jump_velocity_848, delta_time_2604 = frame.delta_time_2604,
                gravity_y_2648 = frame.gravity_y_2648)), frames = frames, from_jump = calculate_velocity_from_jump(&frame, frames, &mut AirMath),
            trajectory_in = Raw(obj!(position = t_in.position, velocity = t_in.velocity, acceleration = t_in.acceleration, scalar_48 = t_in.scalar_48)),
            trajectory_out = Raw(obj!(position = t.position, velocity = t.velocity, acceleration = t.acceleration, scalar_48 = t.scalar_48)))).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/gjump.luau"), s).unwrap();
}
