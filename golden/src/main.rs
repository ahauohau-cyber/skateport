//! Генератор эталонных значений для тестов Luau-порта (GPL-3.0).
//! Пишет tests/golden/<модуль>.luau: входы и ожидаемые биты f32.
use skate_core::{point_graph::PointGraph, trigonometry};
use std::fmt::Write as _;
mod collision;
mod triangle_query;
mod world_contact;
mod bodies;
mod mass;
mod drive;
mod solver;
mod assembly;
mod board;
mod data;
mod world;
mod colliders;
mod riding;
mod board_ground;

fn angles() -> Vec<f32> {
    let mut v = vec![
        0.0, -0.0, 1.0e-30, -1.0e-30, 1.0e-7, 0.5, 1.0, -1.0, 1.5707964, 3.1415927, -3.1415927,
        6.2831855, 100.0, -100.0, 1000.5, 12345.678, -98765.43,
    ];
    let mut state: u32 = 0x1234_5678;
    for i in 0..4000 {
        state = state.wrapping_mul(1_664_525).wrapping_add(1_013_904_223);
        let unit = (state >> 8) as f32 / (1u32 << 24) as f32;
        let span = if i % 4 == 0 { 50.0 } else { 7.0 };
        v.push((unit * 2.0 - 1.0) * span);
    }
    v
}

fn unit_values() -> Vec<f32> {
    let mut v = vec![0.0, -0.0, 1.0, -1.0, 0.5, -0.5, 0.999_999, -0.999_999, 1.0e-6];
    for i in 0..=2000 {
        v.push(-1.0 + 2.0 * i as f32 / 2000.0);
    }
    v
}

fn bits(x: f32) -> String {
    format!("0x{:08x}", x.to_bits())
}

fn main() {
    let out_dir = std::env::args().nth(1).expect("output dir");
    std::fs::create_dir_all(&out_dir).unwrap();

    // trigonometry
    let mut s = String::from("-- Сгенерировано golden/src/main.rs из настоящего skate-core. Не править.\nreturn {\n");
    s.push_str("\tsin_cos = {\n");
    for a in angles() {
        let (sn, cs) = trigonometry::sin_cos(a);
        writeln!(s, "\t\t{{ {}, {}, {} }},", bits(a), bits(sn), bits(cs)).unwrap();
    }
    s.push_str("\t},\n\tsin = {\n");
    for a in angles() {
        writeln!(s, "\t\t{{ {}, {} }},", bits(a), bits(trigonometry::sin(a))).unwrap();
    }
    s.push_str("\t},\n\tcos = {\n");
    for a in angles() {
        writeln!(s, "\t\t{{ {}, {} }},", bits(a), bits(trigonometry::cos(a))).unwrap();
    }
    s.push_str("\t},\n\tasin = {\n");
    for a in unit_values() {
        writeln!(s, "\t\t{{ {}, {} }},", bits(a), bits(trigonometry::asin(a))).unwrap();
    }
    s.push_str("\t},\n\tacos = {\n");
    for a in unit_values() {
        writeln!(s, "\t\t{{ {}, {} }},", bits(a), bits(trigonometry::acos(a))).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/trigonometry.luau"), s).unwrap();

    // point_graph
    let graphs: Vec<(Vec<f32>, Vec<f32>)> = vec![
        (vec![0.0, 1.0, 4.0, 9.0], vec![2.0, -1.0, 0.5, 7.25]),
        (vec![-5.0, -5.0, 0.0, 3.0, 3.0, 10.0], vec![1.0, 9.0, 3.0, -2.0, 4.0, 4.5]),
        (vec![0.3], vec![1.7]),
        (vec![0.0, f32::NAN], vec![1.0, 2.0]),
    ];
    let mut s = String::from("-- Сгенерировано golden/src/main.rs из настоящего skate-core. Не править.\nreturn {\n");
    for (x, y) in &graphs {
        s.push_str("\t{\n\t\tx = { ");
        for v in x { write!(s, "{}, ", bits(*v)).unwrap(); }
        s.push_str("},\n\t\ty = { ");
        for v in y { write!(s, "{}, ", bits(*v)).unwrap(); }
        s.push_str("},\n\t\tcases = {\n");
        let mut inputs: Vec<f32> = vec![f32::NAN, f32::INFINITY, f32::NEG_INFINITY, -100.0, 100.0];
        for i in 0..=240 { inputs.push(-6.0 + i as f32 * 0.07); }
        inputs.extend_from_slice(x);
        for input in inputs {
            let value = evaluate_dyn(x, y, input);
            writeln!(s, "\t\t\t{{ {}, {} }},", bits(input), bits(value)).unwrap();
        }
        s.push_str("\t\t},\n\t},\n");
    }
    s.push_str("}\n");
    std::fs::write(format!("{out_dir}/point_graph.luau"), s).unwrap();

    collision::write(&out_dir);
    triangle_query::write(&out_dir);
    world_contact::write(&out_dir);
    bodies::write(&out_dir);
    mass::write(&out_dir);
    drive::write(&out_dir);
    solver::write(&out_dir);
    assembly::write(&out_dir);
    board::write(&out_dir);
    data::write(&out_dir);
    data::write_settings(&out_dir);
    world::write(&out_dir);
    colliders::write(&out_dir);
    riding::write(&out_dir);
    board_ground::write(&out_dir);
}

// PointGraph параметризован длиной N, поэтому вызываем его для каждой длины отдельно.
fn evaluate_dyn(x: &[f32], y: &[f32], input: f32) -> f32 {
    macro_rules! go {
        ($n:literal) => {{
            let g = PointGraph::<$n> { x: x.try_into().unwrap(), y: y.try_into().unwrap() };
            g.evaluate(input)
        }};
    }
    match x.len() {
        1 => go!(1),
        2 => go!(2),
        4 => go!(4),
        6 => go!(6),
        n => panic!("no graph length {n}"),
    }
}
