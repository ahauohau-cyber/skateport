//! Эталон для air::body_flip, air::reckoning (update, update_plant, limit_angle)
//! и physics::grind_forces::reckoning. Только синтетические входы — можно коммитить.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::air::body_flip::{self, BodyFlipInput, BodyFlipSettings, BodyFlipState};
use skate_core::air::body_spin::{BodySpinSettings, BodySpinState};
use skate_core::air::reckoning::{self, AirState, Input, Settings};
use skate_core::physics::grind_forces::reckoning as grind_reckoning;
use skate_core::physics::skeleton_animation_record::IDENTITY;
use skate_core::point_graph::PointGraph;
use skate_core::riding::ground_orientation::{GroundOrientation, GroundOrientationSettings};
use skate_core::riding::reckoning_frames::ReckoningFrames;
use std::fmt::Write as _;

type V = [f32; 4];

fn unit(r: &mut Rng) -> V {
    let v = r.vec(1.0);
    let l = (v.x * v.x + v.y * v.y + v.z * v.z).sqrt().max(1e-3);
    [v.x / l, v.y / l, v.z / l, 0.0]
}
fn upish(r: &mut Rng) -> V {
    match r.next() % 4 {
        0 => [0.0, 1.0, 0.0, 0.0],
        1 => unit(r),
        _ => { let a = [r.range(-0.5, 0.5), 1.0, r.range(-0.5, 0.5)]; let l = (a[0] * a[0] + a[1] * a[1] + a[2] * a[2]).sqrt(); [a[0] / l, a[1] / l, a[2] / l, 0.0] }
    }
}
fn graph(r: &mut Rng, x0: f32, step: f32, lo: f32, hi: f32) -> PointGraph<8> {
    let mut x = [0.0f32; 8];
    let mut acc = x0;
    for i in 0..8 { x[i] = acc; acc += r.range(step * 0.2, step); }
    PointGraph { x, y: std::array::from_fn(|_| r.range(lo, hi)) }
}
fn ctl(r: &mut Rng) -> V { [r.range(0.0, 1.0), r.range(0.0, 0.5), r.range(0.0, 0.5), r.range(0.05, 1.0)] }
fn opt(r: &mut Rng, lo: f32, hi: f32) -> Option<f32> { if r.next() % 5 == 0 { None } else { Some(r.range(lo, hi)) } }
fn flip_settings(r: &mut Rng) -> BodyFlipSettings {
    BodyFlipSettings { smoothing: opt(r, 0.0, 1.0), maximum_speed: opt(r, 1.0, 20.0), spin_scale: opt(r, 0.0, 1.5), missing_attribute_value: r.range(0.0, 1.0) }
}
fn flip_settings_l(s: &BodyFlipSettings) -> Raw {
    Raw(obj!(smoothing = s.smoothing, maximum_speed = s.maximum_speed, spin_scale = s.spin_scale, missing_attribute_value = s.missing_attribute_value))
}
fn spin_settings(r: &mut Rng) -> BodySpinSettings {
    BodySpinSettings { derivative_floor: r.range(0.0, 1.0), acceleration_limit: r.range(0.0, 1.0),
        curves: std::array::from_fn(|_| graph(r, -2.0, 1.0, 0.0, 2.0)), input_fade_threshold: [r.range(0.0, 0.01), r.range(0.0, 0.01), r.range(0.0, 0.01), r.range(0.0, 0.01)] }
}
fn orientation_l(g: &GroundOrientation) -> Raw {
    Raw(obj!(dynamic_up = g.dynamic_up, up = g.up, target = g.target, up_velocity = g.up_velocity, ground_normal = g.ground_normal, ground_blend = g.ground_blend))
}
fn frames_l(f: &ReckoningFrames) -> Raw {
    Raw(obj!(ground = f.ground, system = f.system, unflipped = f.unflipped, inverse_system = f.inverse_system, body_flip = f.body_flip, heading = f.heading,
        target_lean_angle = f.target_lean_angle, lateral_tilt = f.lateral_tilt))
}
fn air_l(a: &AirState) -> Raw {
    Raw(obj!(spin_angle = a.spin_angle, spin_speed = a.spin_speed, secondary_lean_angle = a.secondary_lean_angle, flip_angle = a.flip_angle, flip_speed = a.flip_speed,
        flip_requested_speed = a.flip_requested_speed, spin_transform = a.spin_transform, flip_axis = a.flip_axis, flip_active = a.flip_active, flip_side = a.flip_side))
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x0a1c_7e55);
    let mut s = format!("-- Сгенерировано golden/src/airrk.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");

    s.push_str("\tflip = {\n");
    for _ in 0..60 {
        let st = flip_settings(&mut r);
        let mut state = BodyFlipState { angle: r.range(-6.0, 6.0), speed: r.range(-10.0, 10.0), requested_speed: 0.0, spin_transform: IDENTITY, combined_transform: IDENTITY };
        let init = obj!(angle = state.angle, speed = state.speed);
        let mut steps = Vec::new();
        for _ in 0..10 {
            let input = BodyFlipInput { requested_speed: if r.next() % 5 == 0 { 0.0 } else { r.range(-15.0, 15.0) }, spin_angle: r.range(-7.0, 7.0), normal: upish(&mut r),
                flip_axis: unit(&mut r), timestep: r.range(0.0, 0.05), perfect_body_flips: r.bool() };
            body_flip::update(&mut state, &st, &input);
            steps.push(obj!(input = Raw(obj!(requested_speed = input.requested_speed, spin_angle = input.spin_angle, normal = input.normal, flip_axis = input.flip_axis,
                timestep = input.timestep, perfect_body_flips = input.perfect_body_flips)), angle = state.angle, speed = state.speed, requested_speed = state.requested_speed,
                spin_transform = state.spin_transform, combined_transform = state.combined_transform));
        }
        writeln!(s, "\t\t{{ settings = {}, init = {}, steps = {{ {} }} }},", flip_settings_l(&st).0, init, steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tlimit = {\n");
    for _ in 0..200 {
        let (t, f, m) = (if r.next() % 8 == 0 { [0.0; 4] } else { [r.range(-3.0, 3.0), r.range(-3.0, 3.0), r.range(-3.0, 3.0), r.range(-1.0, 1.0)] }, unit(&mut r), r.range(0.0, 3.5));
        writeln!(s, "\t\t{},", obj!(target = t, from = f, maximum = m, out = reckoning::clamp_vector_within_max_angle(t, f, m))).unwrap();
    }
    s.push_str("\t},\n\treckoning = {\n");
    for _ in 0..50 {
        let go = GroundOrientationSettings { ground_normal_smoothing: ctl(&mut r), up_vector_smoothing_slow: ctl(&mut r), up_vector_smoothing_fast: ctl(&mut r),
            dynamic_up_vs_ground_y: graph(&mut r, -1.0, 0.3, 0.0, 1.0), ground_vector_blend: graph(&mut r, -1.0, 0.3, 0.0, 1.0), deck_angle_usage_vs_speed: graph(&mut r, 0.0, 2.0, 0.0, 1.0),
            up_vector_smoothing_vs_speed: graph(&mut r, 0.0, 2.0, 0.0, 1.0), up_vector_max_delta_vs_speed: graph(&mut r, 0.0, 2.0, 0.0, 1.0), ground_blend_max_delta: r.range(0.0, 0.2),
            up_vector_max_acceleration: r.range(0.5, 5.0), anti_wobble_damping: r.range(0.0, 1.0), extra_side_damping: r.range(0.0, 1.0), minimum_wheels_for_ground_blend: (r.next() % 4) as i32 };
        let st = Settings { ground_normal_smoothing: ctl(&mut r), max_up_angle_delta: graph(&mut r, 0.0, 0.3, 0.0, 1.0), tilt_vs_rotation: graph(&mut r, -3.0, 1.0, -0.5, 0.5),
            tilt_vs_slope: graph(&mut r, -1.0, 0.3, -0.5, 0.5), body_spin: spin_settings(&mut r), body_flip: flip_settings(&mut r) };
        let gst = grind_reckoning::Settings { ground_normal_smoothing: ctl(&mut r), tilt_vs_rotation: graph(&mut r, -3.0, 1.0, -0.5, 0.5), tilt_vs_slope: graph(&mut r, -1.0, 0.3, -0.5, 0.5) };
        let mut g = GroundOrientation::new(&go);
        let mut f = ReckoningFrames::new();
        f.heading = unit(&mut r);
        let heading0 = f.heading;
        let mut spin = BodySpinState::new();
        let mut air = AirState::new();
        air.flip_active = r.bool();
        air.flip_axis = unit(&mut r);
        let air0 = air_l(&air);
        let mut steps = Vec::new();
        for _ in 0..12 {
            let kind = [0u32, 0, 0, 0, 1, 2][(r.next() % 6) as usize];
            match kind {
                0 => {
                    let input = Input { landing_normal: upish(&mut r), normal_blend: r.range(0.0, 1.0), target_spin: r.range(-8.0, 8.0), flip_request: r.range(-10.0, 10.0),
                        com_to_deck: [r.range(-1.0, 1.0), r.range(0.0, 2.0), r.range(-1.0, 1.0), 0.0], timestep: r.range(0.005, 0.05), physical_body_spin: r.range(-1.0, 1.0),
                        grind_adjusted_body_spin: r.range(-3.0, 3.0), additive_spin: r.next() % 4 == 0, direct_spin: r.next() % 3 == 0, reverse_stance: r.bool(),
                        easy_body_spins: r.bool(), perfect_body_flips: r.bool() };
                    reckoning::update(&mut g, &mut f, &mut spin, &mut air, &st, &input);
                    steps.push(obj!(kind = "update", input = Raw(obj!(landing_normal = input.landing_normal, normal_blend = input.normal_blend, target_spin = input.target_spin,
                        flip_request = input.flip_request, com_to_deck = input.com_to_deck, timestep = input.timestep, physical_body_spin = input.physical_body_spin,
                        grind_adjusted_body_spin = input.grind_adjusted_body_spin, additive_spin = input.additive_spin, direct_spin = input.direct_spin,
                        reverse_stance = input.reverse_stance, easy_body_spins = input.easy_body_spins, perfect_body_flips = input.perfect_body_flips)),
                        orientation = orientation_l(&g), frames = frames_l(&f), spin = *spin.words(), air = air_l(&air)));
                }
                1 => {
                    let (up, heading, rev) = (upish(&mut r), unit(&mut r), r.bool());
                    reckoning::update_plant(&mut g, &mut f, &mut spin, &mut air, &st, up, heading, rev);
                    steps.push(obj!(kind = "plant", up = up, heading = heading, reverse = rev, orientation = orientation_l(&g), frames = frames_l(&f), spin = *spin.words(), air = air_l(&air)));
                }
                _ => {
                    let (normal, heading, smoothing, rev, pbs) = (upish(&mut r), unit(&mut r), r.range(0.0, 1.0), r.bool(), r.range(-1.0, 1.0));
                    grind_reckoning::update(&mut g, &mut f, &mut spin, &mut air, &gst, normal, heading, smoothing, rev, pbs);
                    steps.push(obj!(kind = "grind", normal = normal, heading = heading, smoothing = smoothing, reverse = rev, physical_body_spin = pbs,
                        orientation = orientation_l(&g), frames = frames_l(&f), spin = *spin.words(), air = air_l(&air)));
                }
            }
        }
        writeln!(s, "\t\t{{ go = {}, settings = {}, grind_settings = {}, heading0 = {}, air0 = {}, steps = {{ {} }} }},",
            obj!(ground_normal_smoothing = go.ground_normal_smoothing, up_vector_smoothing_slow = go.up_vector_smoothing_slow, up_vector_smoothing_fast = go.up_vector_smoothing_fast,
                dynamic_up_vs_ground_y = go.dynamic_up_vs_ground_y, ground_vector_blend = go.ground_vector_blend, deck_angle_usage_vs_speed = go.deck_angle_usage_vs_speed,
                up_vector_smoothing_vs_speed = go.up_vector_smoothing_vs_speed, up_vector_max_delta_vs_speed = go.up_vector_max_delta_vs_speed, ground_blend_max_delta = go.ground_blend_max_delta,
                up_vector_max_acceleration = go.up_vector_max_acceleration, anti_wobble_damping = go.anti_wobble_damping, extra_side_damping = go.extra_side_damping,
                minimum_wheels_for_ground_blend = go.minimum_wheels_for_ground_blend),
            obj!(ground_normal_smoothing = st.ground_normal_smoothing, max_up_angle_delta = st.max_up_angle_delta, tilt_vs_rotation = st.tilt_vs_rotation, tilt_vs_slope = st.tilt_vs_slope,
                body_spin = Raw(obj!(derivative_floor = st.body_spin.derivative_floor, acceleration_limit = st.body_spin.acceleration_limit, curves = st.body_spin.curves,
                    input_fade_threshold = st.body_spin.input_fade_threshold)), body_flip = flip_settings_l(&st.body_flip)),
            obj!(ground_normal_smoothing = gst.ground_normal_smoothing, tilt_vs_rotation = gst.tilt_vs_rotation, tilt_vs_slope = gst.tilt_vs_slope),
            heading0.l(), air0.0, steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/airrk.luau"), s).unwrap();
}
