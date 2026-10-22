//! Эталон для air/body_spin, air/ground_normal, riding/speed_and_slope.
use crate::collision::{b, Rng};
use skate_core::air::body_spin::{self, BodySpinSettings, BodySpinState};
use skate_core::air::ground_normal::GroundNormalFilter;
use skate_core::point_graph::PointGraph;
use skate_core::riding::speed_and_slope::SpeedAndSlopeSettings;
use std::fmt::Write as _;

pub fn graph(r: &mut Rng) -> PointGraph<8> {
    let mut x = [0f32; 8];
    let mut acc = r.range(-1.0, 0.0);
    for k in 0..8 { x[k] = acc; acc += r.range(0.01, 0.4); }
    let y = core::array::from_fn(|_| r.range(-3.0, 3.0));
    PointGraph { x, y }
}
pub fn gs(g: &PointGraph<8>) -> String {
    let xs: Vec<String> = g.x.iter().map(|&v| b(v)).collect();
    let ys: Vec<String> = g.y.iter().map(|&v| b(v)).collect();
    format!("{{ {{ {} }}, {{ {} }} }}", xs.join(", "), ys.join(", "))
}
fn words<const N: usize>(w: &[u32; N]) -> String {
    let s: Vec<String> = w.iter().map(|x| format!("0x{x:08x}")).collect();
    format!("{{ {} }}", s.join(", "))
}
fn f4(v: [f32; 4]) -> String { format!("{{ {}, {}, {}, {} }}", b(v[0]), b(v[1]), b(v[2]), b(v[3])) }

pub fn write(out_dir: &str) {
    let mut r = Rng(0xb0d7_5917);
    let mut s = String::from("-- Сгенерировано golden/src/riding.rs из настоящего skate-core. Не править.\nreturn {\n\tbody_spin = {\n");
    for _ in 0..60 {
        let settings = BodySpinSettings {
            derivative_floor: r.range(0.0, 1.0), acceleration_limit: r.range(0.0, 0.5),
            curves: core::array::from_fn(|_| graph(&mut r)),
            input_fade_threshold: core::array::from_fn(|_| r.range(0.0, 0.3)),
        };
        let cs: Vec<String> = settings.curves.iter().map(gs).collect();
        let mut state = BodySpinState::new();
        let mut steps = String::new();
        for _ in 0..80 {
            let input = if r.next() % 4 == 0 { 0.0 } else { r.range(-1.5, 1.5) };
            let auto = if r.next() % 3 == 0 { r.range(-3.0, 3.0) } else { 0.0 };
            let air = r.next() % 3 != 0;
            let mode = (r.next() % 3) as u8;
            let ground_only = r.next() % 5 == 0;
            if ground_only { body_spin::update_ground(&mut state, input); } else { body_spin::update(&mut state, &settings, input, auto, air, mode); }
            write!(steps, "{{ {}, {}, {}, {}, {}, {} }}, ", b(input), b(auto), air, mode, ground_only, words(state.words())).unwrap();
        }
        writeln!(s, "\t\t{{ settings = {{ {}, {}, {{ {} }}, {} }}, steps = {{ {} }} }},", b(settings.derivative_floor), b(settings.acceleration_limit),
            cs.join(", "), f4(settings.input_fade_threshold), steps).unwrap();
    }
    s.push_str("\t},\n\tground_normal = {\n");
    for _ in 0..80 {
        let control = [r.range(0.0, 1.0), r.range(0.0, 1.0), r.range(0.0, 1.0), r.range(0.0, 1.0)];
        let init = [r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0), 0.0];
        let mut f = GroundNormalFilter::initialized(control, init);
        let mut steps = String::new();
        for _ in 0..40 {
            let c = [r.range(0.0, 1.0), r.range(0.0, 1.0), r.range(0.0, 1.0), r.range(0.0, 1.0)];
            let i = [r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-0.1, 0.1)];
            let op = r.next() % 3;
            let out = match op { 0 => f.update(c, i), 1 => f.filter_raw(c, i), _ => { f.publish_current(i); [0.0; 4] } };
            write!(steps, "{{ {}, {}, {}, {}, {} }}, ", op, f4(c), f4(i), f4(out), words(f.words())).unwrap();
        }
        writeln!(s, "\t\t{{ control = {}, init = {}, steps = {{ {} }} }},", f4(control), f4(init), steps).unwrap();
    }
    s.push_str("\t},\n\tspeed_and_slope = {\n");
    for _ in 0..300 {
        let st = SpeedAndSlopeSettings { turn_torque_vs_speed: graph(&mut r), turn_torque_vs_slope: graph(&mut r), heading_adjust_max_speed: r.range(0.5, 12.0) };
        let mut calls = String::new();
        for _ in 0..10 {
            let y = r.range(-1.3, 1.3); let sp = r.range(-20.0, 20.0);
            write!(calls, "{{ {}, {}, {} }}, ", b(y), b(sp), b(st.calculate(y, sp))).unwrap();
        }
        writeln!(s, "\t\t{{ {}, {}, {}, {{ {} }} }},", gs(&st.turn_torque_vs_speed), gs(&st.turn_torque_vs_slope), b(st.heading_adjust_max_speed), calls).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/riding.luau"), s).unwrap();
}
