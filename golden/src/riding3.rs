//! Эталон для riding: push, push_animation, push_behaviors, pumping,
//! ground_correction_math.
use crate::collision::{b, v, Rng};
use crate::riding::{graph, gs};
use crate::riding2::{f4, r4, thr, u4, up4};
use skate_core::math::Vector3;
use skate_core::physics::board_runtime::{BoardMotion, BoardRuntime};
use skate_core::physics::drive_frames::{default_body_transforms, RetailAffineTransform};
use skate_core::physics::mass::default_skateboard_mass_properties;
use skate_core::physics::rigid_body::RetailSimulationStep;
use skate_core::riding::ground_correction_math as gcm;
use skate_core::riding::pumping::{self, controller, geometry::NativePumpingGeometry, settings::{PumpingMode, PumpingSettings}, state::PumpingState, PumpForceInput};
use skate_core::riding::push::{calculate_acceleration, PushInput, PushLimits};
use skate_core::riding::push_animation::{PushAnimationCurves, PushBlendParameters};
use skate_core::riding::push_behaviors::{FirstPushStrength, PushAttributes, PushClipMetrics, PushCycle, PushFootFrame, PushIntents, PushState};
use std::fmt::Write as _;

fn pb(p: &PushBlendParameters) -> String { format!("{{ {}, {}, {} }}", b(p.hstr_vel_b), b(p.lstr_vel_b), b(p.vel_e)) }
fn curves(r: &mut Rng) -> PushAnimationCurves {
    let mut pos = |r: &mut Rng| { let mut g = graph(r); for y in g.y.iter_mut() { *y = y.abs() + 0.05; } g };
    PushAnimationCurves { button_time_max: pos(r), button_time_to_dv: graph(r), blend_speed_over_frames: pos(r), blend_acc_over_frames: pos(r) }
}
fn cs(c: &PushAnimationCurves) -> String { format!("{{ {}, {}, {}, {} }}", gs(&c.button_time_max), gs(&c.button_time_to_dv), gs(&c.blend_speed_over_frames), gs(&c.blend_acc_over_frames)) }
fn ps(s: &PushState) -> String { format!("{{ {}, {}, {}, {}, {} }}", b(s.out_factor), b(s.current_push_dv), pb(&s.current), pb(&s.target), s.continue_push) }
fn opt(x: Option<f32>) -> String { match x { Some(v) => b(v), None => "false".into() } }

pub fn write(out_dir: &str) {
    let mut r = Rng(0x9a5b_3333);
    let mut s = String::from("-- Сгенерировано golden/src/riding3.rs из настоящего skate-core. Не править.\nreturn {\n\tpush = {\n");
    for _ in 0..1500 {
        let inp = PushInput { flags_2468: if r.next() % 5 == 0 { 0 } else { 0x0200_0000 }, flags_2472: if r.next() % 6 == 0 { 0x200 } else { 0 }, target_speed: r.range(-2.0, 12.0), current_speed: r.range(-1.0, 10.0),
            absolute_body_speed: r.range(0.0, 10.0), scale: r.range(1.0, 90.0), delta_seconds: if r.bool() { 1.0 / 60.0 } else { r.range(0.005, 0.2) }, direction: r.vec(1.0) };
        let lim = PushLimits { maximum_pushable_speed: r.range(1.0, 10.0), low_speed_change: r.range(0.0, 3.0), high_speed_change: r.range(0.0, 3.0) };
        let o = calculate_acceleration(inp, lim);
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {}, {}, {}, {}, {} }}, {{ {}, {}, {} }}, {{ {}, {}, {} }} }},", inp.flags_2468, inp.flags_2472, b(inp.target_speed), b(inp.current_speed), b(inp.absolute_body_speed), b(inp.scale), b(inp.delta_seconds), v(inp.direction),
            b(lim.maximum_pushable_speed), b(lim.low_speed_change), b(lim.high_speed_change), v(o.vector), v(o.local_point), o.suppressed).unwrap();
    }
    s.push_str("\t},\n\tanimation = {\n");
    for _ in 0..200 {
        let c = curves(&mut r);
        let mut steps = String::new();
        let mut cur = PushBlendParameters { hstr_vel_b: r.range(-1.0, 1.0), lstr_vel_b: r.range(0.0, 1.0), vel_e: if r.bool() { -1.0 } else { r.range(0.0, 1.0) } };
        let init = cur;
        for _ in 0..10 {
            let held = r.range(0.0, 2.0); let speed = r.range(-2.0, 10.0);
            let st = c.strength(held, speed);
            let target = PushBlendParameters { hstr_vel_b: r.range(-0.2, 1.2), lstr_vel_b: r.range(-0.2, 1.2), vel_e: r.range(-0.2, 1.2) };
            let dt = if r.bool() { 1.0 / 60.0 } else { r.range(0.0, 0.1) };
            cur = c.update_blend(cur, target, speed, dt);
            write!(steps, "{{ {}, {}, {}, {}, {}, {} }}, ", b(held), b(speed), b(st), pb(&target), b(dt), pb(&cur)).unwrap();
        }
        writeln!(s, "\t\t{{ curves = {}, init = {}, steps = {{ {} }} }},", cs(&c), pb(&init), steps).unwrap();
    }
    s.push_str("\t},\n\tbehaviors = {\n");
    for _ in 0..150 {
        let clips: [PushClipMetrics; 4] = core::array::from_fn(|_| PushClipMetrics { length: r.range(0.2, 1.5), begin_velocity: r.range(0.0, 6.0), end_velocity: r.range(0.5, 9.0) });
        let a = PushAttributes::from_clips(clips);
        let c = curves(&mut r);
        let mut tgt = String::new();
        for _ in 0..8 {
            let fs = r.range(-1.0, 10.0); let st = r.range(-1.0, 6.0); let w = r.range(0.0, 1.0); let mo = r.range(0.0, 1.0);
            let t = a.target(fs, st); let of = a.out_factor(fs, st, w, mo);
            write!(tgt, "{{ {}, {}, {}, {}, {}, {} }}, ", b(fs), b(st), b(w), b(mo), pb(&t), b(of)).unwrap();
        }
        let mut state = PushState { out_factor: r.range(0.0, 1.0), current_push_dv: r.range(0.0, 3.0), current: PushBlendParameters { hstr_vel_b: 0.3, lstr_vel_b: 0.2, vel_e: 0.1 }, target: PushBlendParameters { hstr_vel_b: 0.5, lstr_vel_b: 0.4, vel_e: 0.6 }, continue_push: true };
        state.initialize_push();
        let after_init = ps(&state);
        let tst = r.range(0.0, 2.0); let tw = r.range(0.0, 2.0);
        let mut first = FirstPushStrength::begin(tst, tw);
        let mut seq = String::new();
        let mut held = 0.0f32;
        for _ in 0..12 {
            let pushing = if r.next() % 4 == 0 { None } else { held += 1.0 / 60.0; Some(held) };
            let fs = r.range(-1.0, 8.0); let dt = 1.0 / 60.0;
            first.update(&mut state, &c, pushing, fs, dt);
            write!(seq, "{{ {}, {}, {}, {{ {}, {}, {}, {} }} }}, ", opt(pushing), b(fs), ps(&state), b(first.simulated_held_seconds), first.push_from_teleport, first.first_push, first.first_update).unwrap();
        }
        let intents0 = PushIntents { pushing: if r.bool() { Some(r.range(0.0, 1.0)) } else { None }, new_push: r.bool(), configured_foot: r.bool() };
        let mut cycle = PushCycle::begin(&mut state, &c, intents0);
        let mut cyc = format!("{{ {}, {}, {} }}, ", cycle.phase as u32, b(cycle.next_push_dv), ps(&state));
        for _ in 0..12 {
            let it = PushIntents { pushing: if r.bool() { Some(r.range(0.0, 1.5)) } else { None }, new_push: r.bool(), configured_foot: r.next() % 3 != 0 };
            let fs = r.range(-1.0, 8.0); let mh = r.range(0.0, 3.0);
            cycle.update(&mut state, &c, it, fs, mh);
            write!(cyc, "{{ {{ {}, {}, {} }}, {}, {}, {}, {}, {} }}, ", opt(it.pushing), it.new_push, it.configured_foot, b(fs), b(mh), cycle.phase as u32, b(cycle.next_push_dv), ps(&state)).unwrap();
        }
        let ff = PushFootFrame { left_foot: r4(&mut r, 2.0), right_foot: r4(&mut r, 2.0), deck_position: r4(&mut r, 2.0), deck_y: up4(&mut r), deck_z: u4(&mut r), skateboard_flipped: r.bool() };
        let od = [ff.out_distance(false), ff.out_distance(true)];
        writeln!(s, "\t\t{{ clips = {{ {} }}, attrs = {{ {}, {}, {}, {} }}, curves = {}, targets = {{ {} }}, after_init = {}, first = {{ {}, {}, {{ {} }} }}, intents0 = {{ {}, {}, {} }}, cycle = {{ {} }}, foot = {{ {}, {}, {}, {}, {}, {} }}, out = {{ {}, {}, {}, {} }} }},",
            clips.iter().map(|c| format!("{{ {}, {}, {} }}", b(c.length), b(c.begin_velocity), b(c.end_velocity))).collect::<Vec<_>>().join(", "),
            b(a.minimum_begin_velocity), b(a.maximum_begin_velocity), b(a.minimum_delta_velocity), b(a.maximum_delta_velocity), cs(&c), tgt, after_init,
            b(tst), b(tw), seq, opt(intents0.pushing), intents0.new_push, intents0.configured_foot, cyc,
            f4(ff.left_foot), f4(ff.right_foot), f4(ff.deck_position), f4(ff.deck_y), f4(ff.deck_z), ff.skateboard_flipped, b(od[0][0]), b(od[0][1]), b(od[1][0]), b(od[1][1])).unwrap();
    }
    s.push_str("\t},\n\tpumping = {\n");
    for _ in 0..80 {
        let st = PumpingSettings { pump_vs_speed: graph(&mut r), pump_vs_time: graph(&mut r), min_crouch_vs_ground_angle: graph(&mut r), compression_vs_ground_angle: graph(&mut r), compression_vs_deck_angle: graph(&mut r),
            height_change_damping: r.range(0.0, 1.0), minimum_height_change: r.range(0.0, 0.01), maximum_height_change: r.range(0.0, 0.05), ground_compression_scale: r.range(0.0, 2.0), deck_compression_scale: r.range(0.0, 2.0), angular_speed_damping: r.range(0.0, 1.0) };
        let mode = PumpingMode { maximum_absorption_per_second: r.range(0.0, 5.0), maximum_acceleration_per_second: r.range(0.0, 5.0), absorption_factor: r.range(0.0, 50.0), acceleration_factor: r.range(0.0, 50.0) };
        let mut state = PumpingState::reset_state();
        let mut steps = String::new();
        let mut pos = [0.0f32, 0.0, 0.0, 0.0];
        for k in 0..40 {
            pos = [pos[0] + r.range(-0.1, 0.1), pos[1] + r.range(-0.05, 0.05), pos[2] + r.range(0.0, 0.15), 0.0];
            let sample = controller::PumpingSample { position: pos, normal: up4(&mut r), com_to_deck_world: [r.range(-0.1, 0.1), r.range(0.4, 1.0), r.range(-0.1, 0.1), 0.0], deck_angle: r.range(0.0, 1.0), intentional_pumping: (r.next() % 2) as u8 };
            let ground = r.bool();
            let ts = r.range(0.005, 0.05);
            if k == 20 { state.reset(); }
            if ground { controller::update_ground(&mut state, &st, mode, sample, &mut NativePumpingGeometry).unwrap(); } else { controller::update(&mut state, &st, mode, sample, ts, &mut NativePumpingGeometry).unwrap(); }
            let o = state.physics_output();
            write!(steps, "{{ {}, {}, {}, {}, {}, {}, {}, {}, {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}, {{ {}, {}, {}, {}, {}, {}, {} }} }}, ",
                f4(sample.position), f4(sample.normal), f4(sample.com_to_deck_world), b(sample.deck_angle), sample.intentional_pumping, ground, b(ts), k == 20,
                f4(state.previous_position), f4(state.previous_normal), b(state.smoothed_height_change), b(state.pumping_time), b(state.previous_height), b(state.pumping), b(state.pump_acceleration), b(state.angular_speed),
                b(state.absorption), b(state.ground_normal_absorption), b(state.minimum_crouch), b(state.deck_angle_absorption), b(state.reset_only_scalar), state.record_valid, state.intentional_pumping,
                b(o.compression), b(o.absorption), b(o.ground_normal_absorption), b(o.minimum_crouch), b(o.deck_angle_absorption), b(o.pump_acceleration), o.intentional_pumping).unwrap();
        }
        writeln!(s, "\t\t{{ settings = {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}, mode = {{ {}, {}, {}, {} }}, steps = {{ {} }} }},",
            gs(&st.pump_vs_speed), gs(&st.pump_vs_time), gs(&st.min_crouch_vs_ground_angle), gs(&st.compression_vs_ground_angle), gs(&st.compression_vs_deck_angle),
            b(st.height_change_damping), b(st.minimum_height_change), b(st.maximum_height_change), b(st.ground_compression_scale), b(st.deck_compression_scale), b(st.angular_speed_damping),
            b(mode.maximum_absorption_per_second), b(mode.maximum_acceleration_per_second), b(mode.absorption_factor), b(mode.acceleration_factor), steps).unwrap();
    }
    s.push_str("\t},\n\tpump_force = {\n");
    for _ in 0..800 {
        let i = PumpForceInput { flags_2476: if r.bool() { 2 } else { 0 } | (r.next() & 0xf0), mode_multiplier: r.range(0.0, 3.0), pumping_scalar: r.range(-2.0, 2.0), input_scalar_2660: r.range(1.0, 90.0), timestep: if r.bool() { 1.0 / 60.0 } else { r.range(0.005, 0.05) },
            direction_432: if r.next() % 8 == 0 { [0.0; 4] } else { r4(&mut r, 5.0) }, normal_threshold: thr(&mut r) };
        let o = pumping::calculate(&i);
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {}, {}, {}, {} }}, {{ {} }} }},", i.flags_2476, b(i.mode_multiplier), b(i.pumping_scalar), b(i.input_scalar_2660), b(i.timestep), f4(i.direction_432), f4(i.normal_threshold), o.map(b).join(", ")).unwrap();
    }
    s.push_str("\t},\n\tcorrections = {\n");
    for _ in 0..1000 {
        let a = r4(&mut r, 3.0); let c = r4(&mut r, 3.0); let d = r4(&mut r, 3.0);
        let edge_end = if r.next() % 10 == 0 { a } else { c };
        let dir = if r.next() % 10 == 0 { [0.0, 1.0, 0.0, 0.0] } else { u4(&mut r) };
        let sq = r.range(0.0, 4.0); let mg = r.range(0.0, 60.0);
        let px = r.range(-5.0, 5.0); let pz = r.range(-5.0, 5.0); let dt = r.range(0.005, 0.05);
        let dy = up4(&mut r); let dz = if r.bool() { u4(&mut r) } else { [0.0, -0.5, 0.8, 0.0] };
        let zero_force = r.next() % 8 == 0;
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}, {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }} }},",
            f4(a), f4(c), f4(d), f4(edge_end), f4(dir), b(sq), b(mg), b(px), b(pz), b(dt), f4(dy), f4(dz),
            b(gcm::center_of_mass_height(a)), b(gcm::dot_product(a, c)), b(gcm::collision_force_projection(if zero_force { [0.0; 4] } else { a }, c)),
            f4(gcm::edge_direction(a, edge_end)), f4(gcm::edge_up(dir)), f4(gcm::hang_force(a, edge_end, d)), f4(gcm::wheel_catch_displacement(dy, dz)),
            f4(gcm::pinning_velocity(d, px, pz, dt)), f4(gcm::scale_to_magnitude(a, sq, mg)), zero_force).unwrap();
    }
    s.push_str("\t},\n\tworld_force = {\n");
    let sim = RetailSimulationStep::fixed_60_hz(0, 0.001, Vector3::new(0.0, -9.81, 0.0));
    let mut board = BoardRuntime::new(default_skateboard_mass_properties(), default_body_transforms(), RetailAffineTransform::IDENTITY, sim, BoardMotion::Active);
    for _ in 0..300 {
        let deck_part = r.vec(2.0); let force = r.vec(50.0); let point = r.vec(2.0);
        let body = &mut board.bodies_mut()[6];
        gcm::apply_world_force(body, deck_part, force, point);
        let rr = body.rates;
        writeln!(s, "\t\t{{ {}, {}, {}, {}, {}, {} }},", v(deck_part), v(force), v(point), v(rr.force_acceleration), v(rr.torque_acceleration), rr.cool_down).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/riding3.luau"), s).unwrap();
}
