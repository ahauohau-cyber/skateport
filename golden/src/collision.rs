//! Эталон для physics/collision: случайные треугольники, сферы и нормали.
use skate_core::math::Vector3;
use skate_core::physics::collision::{
    fix_up_triangle, intersect_sphere_triangle, sphere_triangle_world_contact, ContactPair, Sphere,
    Triangle, TriangleFixup, WorldContactSettings,
};
use skate_core::physics::world_contact::triangle_from_volume;
use std::fmt::Write as _;

pub struct Rng(pub u64);
impl Rng {
    pub fn next(&mut self) -> u32 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.0 >> 33) as u32
    }
    pub fn unit(&mut self) -> f32 {
        (self.next() >> 8) as f32 / (1u32 << 24) as f32
    }
    pub fn range(&mut self, lo: f32, hi: f32) -> f32 {
        lo + (hi - lo) * self.unit()
    }
    pub fn vec(&mut self, span: f32) -> Vector3 {
        Vector3::new(self.range(-span, span), self.range(-span, span), self.range(-span, span))
    }
    pub fn bool(&mut self) -> bool {
        self.next() & 1 == 1
    }
}

pub fn b(x: f32) -> String {
    format!("0x{:08x}", x.to_bits())
}
pub fn v(x: Vector3) -> String {
    format!("{{ {}, {}, {} }}", b(x.x), b(x.y), b(x.z))
}
fn pair(p: ContactPair) -> String {
    format!("{{ a = {}, b = {} }}", v(p.a), v(p.b))
}
fn triangle(t: &Triangle) -> String {
    format!(
        "{{ vertices = {{ {}, {}, {} }}, normal = {}, edges = {{ {}, {}, {} }}, flags = {}, edge_cosines = {{ {}, {}, {} }}, edge_lengths = {{ {}, {}, {} }}, fatness = {} }}",
        v(t.vertices[0]), v(t.vertices[1]), v(t.vertices[2]), v(t.feature.normal),
        v(t.feature.edges[0]), v(t.feature.edges[1]), v(t.feature.edges[2]), t.feature.flags,
        b(t.feature.edge_cosines[0]), b(t.feature.edge_cosines[1]), b(t.feature.edge_cosines[2]),
        b(t.edge_lengths[0]), b(t.edge_lengths[1]), b(t.edge_lengths[2]), b(t.fatness)
    )
}

pub fn random_triangle(r: &mut Rng) -> Triangle {
    let base = r.vec(3.0);
    let vertices = [base, add(base, r.vec(2.0)), add(base, r.vec(2.0))];
    let mut flags = 0u32;
    for bit in [0x10, 0x100, 0x20, 0x40, 0x80, 0x200, 0x400, 0x800] {
        if r.bool() {
            flags |= bit;
        }
    }
    let cos = [r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0)];
    let fatness = if r.bool() { 0.0 } else { r.range(0.0, 0.1) };
    triangle_from_volume(vertices, fatness, cos, flags)
}
fn add(a: Vector3, c: Vector3) -> Vector3 {
    Vector3::new(a.x + c.x, a.y + c.y, a.z + c.z)
}
fn centroid(t: &Triangle) -> Vector3 {
    let [a, c, d] = t.vertices;
    Vector3::new((a.x + c.x + d.x) / 3.0, (a.y + c.y + d.y) / 3.0, (a.z + c.z + d.z) / 3.0)
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x5eed_1234);
    let mut s = String::from("-- Сгенерировано golden/src/collision.rs из настоящего skate-core. Не править.\nreturn {\n\tsphere = {\n");
    for _ in 0..3000 {
        let t = random_triangle(&mut r);
        let near = if r.bool() { 0.6 } else { 2.5 };
        let center = add(centroid(&t), r.vec(near));
        let sphere = Sphere { center, radius: r.range(0.05, 0.6) };
        let min_sep = r.range(0.0, 0.3);
        let is_a = r.bool();
        let velocity = r.vec(8.0);
        let settings = WorldContactSettings {
            volume_padding: r.range(0.0, 0.05),
            maximum_separating_distance: r.range(0.0, 0.5),
            edge_cos_bend_normal_threshold: r.range(-1.0, 1.0),
            convexity_epsilon: r.range(0.0, 0.05),
            is_object: r.bool(),
        };
        write!(s, "\t\t{{ tri = {}, center = {}, radius = {}, min_sep = {}, is_a = {}, velocity = {}, settings = {{ {}, {}, {}, {}, {} }},",
            triangle(&t), v(center), b(sphere.radius), b(min_sep), is_a, v(velocity),
            b(settings.volume_padding), b(settings.maximum_separating_distance),
            b(settings.edge_cos_bend_normal_threshold), b(settings.convexity_epsilon), settings.is_object).unwrap();
        match intersect_sphere_triangle(sphere, t, min_sep, is_a) {
            Some(p) => write!(s, " pair = {{ sdir = {}, sdist = {}, normal = {}, points = {}, distance = {}, region = {} }},",
                v(p.separating_direction), b(p.separating_distance), v(p.normal), pair(p.points), b(p.distance), p.triangle_region).unwrap(),
            None => s.push_str(" pair = false,"),
        }
        match sphere_triangle_world_contact(sphere, t, velocity, settings) {
            Some(c) => write!(s, " world = {{ normal = {}, points = {} }} }},\n", v(c.normal), pair(c.points)).unwrap(),
            None => s.push_str(" world = false },\n"),
        }
    }
    s.push_str("\t},\n\tfixup = {\n");
    for _ in 0..4000 {
        let t = random_triangle(&mut r);
        let mut normal = if r.bool() { r.vec(1.0) } else {
            let n = t.feature.normal;
            let d = r.vec(0.4);
            Vector3::new(n.x + d.x, n.y + d.y, n.z + d.z)
        };
        let len = (normal.x * normal.x + normal.y * normal.y + normal.z * normal.z).sqrt();
        if len > 1e-6 { normal = Vector3::new(normal.x / len, normal.y / len, normal.z / len); }
        let count = 1 + (r.next() % 3) as usize;
        let mut contacts: Vec<ContactPair> = (0..count).map(|_| ContactPair { a: r.vec(3.0), b: r.vec(3.0) }).collect();
        let settings = TriangleFixup {
            reverse: r.bool(),
            edge_cos_bend_normal_threshold: r.range(-1.0, 1.0),
            convexity_epsilon: r.range(0.0, 0.05),
            is_object: r.bool(),
        };
        write!(s, "\t\t{{ tri = {}, normal = {}, contacts = {{ ", triangle(&t), v(normal)).unwrap();
        for c in &contacts { write!(s, "{}, ", pair(*c)).unwrap(); }
        write!(s, "}}, settings = {{ {}, {}, {}, {} }},", settings.reverse, b(settings.edge_cos_bend_normal_threshold), b(settings.convexity_epsilon), settings.is_object).unwrap();
        let ok = fix_up_triangle(t.feature, &mut normal, &mut contacts, settings);
        write!(s, " ok = {}, out_normal = {}, out_contacts = {{ ", ok, v(normal)).unwrap();
        for c in &contacts { write!(s, "{}, ", pair(*c)).unwrap(); }
        s.push_str("} },\n");
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/collision.luau"), s).unwrap();
}
