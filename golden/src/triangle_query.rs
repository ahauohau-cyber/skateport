//! Эталон для physics/triangle_query (+ sweep, closest, roots, walk).
use crate::collision::{b, random_triangle, v, Rng};
use skate_core::math::Vector3;
use skate_core::physics::triangle_query::{thin_triangle, triangle_segment, TriangleLineHit};
use std::fmt::Write as _;

fn hit(h: &TriangleLineHit) -> String {
    format!("{{ position = {}, normal = {}, fraction = {}, vp = {{ {}, {}, {} }} }}",
        v(h.position), v(h.normal), b(h.fraction), b(h.volume_parameter[0]), b(h.volume_parameter[1]), b(h.volume_parameter[2]))
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x7a1e_9001);
    let mut s = String::from("-- Сгенерировано golden/src/triangle_query.rs из настоящего skate-core. Не править.\nreturn {\n\tsegment = {\n");
    for i in 0..15000 {
        let t = random_triangle(&mut r);
        let [a, c, d] = t.vertices;
        let target = Vector3::new((a.x + c.x + d.x) / 3.0, (a.y + c.y + d.y) / 3.0, (a.z + c.z + d.z) / 3.0);
        let n = t.feature.normal;
        let (start, direction) = if i % 10 < 7 {
            let h = r.range(0.2, 3.0) * if r.bool() { 1.0 } else { -1.0 };
            let lat = r.vec(0.6);
            let start = Vector3::new(target.x + n.x * h + lat.x, target.y + n.y * h + lat.y, target.z + n.z * h + lat.z);
            let goal = r.vec(1.2);
            let k = r.range(0.5, 2.5);
            (start, Vector3::new((target.x + goal.x - start.x) * k, (target.y + goal.y - start.y) * k, (target.z + goal.z - start.z) * k))
        } else {
            let start = Vector3::new(target.x + r.range(-3.0, 3.0), target.y + r.range(-3.0, 3.0), target.z + r.range(-3.0, 3.0));
            (start, r.vec(5.0))
        };
        let line_radius = match i % 4 { 0 => 0.0, 1 => r.range(0.0, 0.05), _ => r.range(0.0, 0.6) };
        let fatness = if i % 4 == 0 { 0.0 } else { t.fatness };
        let mut result = TriangleLineHit {
            position: Vector3::new(9.0, 9.0, 9.0),
            normal: Vector3::new(0.0, 0.0, 1.0),
            fraction: 0.5,
            volume_parameter: [0.1, 0.2, 0.3],
        };
        let ok = triangle_segment(&mut result, start, direction, t.vertices, line_radius, fatness);
        write!(s, "\t\t{{ vertices = {{ {}, {}, {} }}, start = {}, direction = {}, line_radius = {}, fatness = {}, ok = {}, result = {} }},\n",
            v(t.vertices[0]), v(t.vertices[1]), v(t.vertices[2]), v(start), v(direction), b(line_radius), b(fatness), ok, hit(&result)).unwrap();
    }
    s.push_str("\t},\n\tthin = {\n");
    for _ in 0..3000 {
        let t = random_triangle(&mut r);
        let [a, c, d] = t.vertices;
        let w = [r.unit(), r.unit(), r.unit()];
        let sum = w[0] + w[1] + w[2];
        let inside = Vector3::new((a.x * w[0] + c.x * w[1] + d.x * w[2]) / sum, (a.y * w[0] + c.y * w[1] + d.y * w[2]) / sum, (a.z * w[0] + c.z * w[1] + d.z * w[2]) / sum);
        let start = r.vec(4.0);
        let k = r.range(0.8, 2.0);
        let direction = if r.bool() { r.vec(6.0) } else { Vector3::new((inside.x - start.x) * k, (inside.y - start.y) * k, (inside.z - start.z) * k) };
        match thin_triangle(start, direction, t.vertices) {
            Some(h) => write!(s, "\t\t{{ vertices = {{ {}, {}, {} }}, start = {}, direction = {}, hit = {} }},\n",
                v(t.vertices[0]), v(t.vertices[1]), v(t.vertices[2]), v(start), v(direction), hit(&h)).unwrap(),
            None => write!(s, "\t\t{{ vertices = {{ {}, {}, {} }}, start = {}, direction = {}, hit = false }},\n",
                v(t.vertices[0]), v(t.vertices[1]), v(t.vertices[2]), v(start), v(direction)).unwrap(),
        }
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/triangle_query.luau"), s).unwrap();
}
