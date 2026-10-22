//! Эталон для physics/mass и construction/*.
use crate::collision::{b, v, Rng};
use skate_core::math::{Basis3, Vector3};
use skate_core::physics::mass::{
    aggregate_mass_properties, deck_mass_properties, primitive_mass, primitive_mass_properties,
    retail_deck_mass_properties, retail_truck_mass_properties, retail_wheel_mass_properties,
    DeckGeometry, DeckGeometrySettings, DeckShape, MassMoments, MassShape, PartMassInput,
};
use skate_core::physics::rigid_body::RetailBodyMassProperties;
use std::fmt::Write as _;

fn basis(x: Basis3) -> String {
    let c = x.columns;
    format!(
        "{{ {{ {}, {}, {} }}, {{ {}, {}, {} }}, {{ {}, {}, {} }} }}",
        b(c[0][0]), b(c[0][1]), b(c[0][2]), b(c[1][0]), b(c[1][1]), b(c[1][2]),
        b(c[2][0]), b(c[2][1]), b(c[2][2])
    )
}
fn props(p: &RetailBodyMassProperties) -> String {
    let d = p.dynamics;
    format!(
        "{{ frame = {{ {}, {} }}, dyn = {{ {}, {}, {}, {}, {}, {}, {} }} }}",
        basis(p.local_mass_frame.basis), v(p.local_mass_frame.translation),
        v(d.inverse_tensor), b(d.inverse_mass), b(d.spherical), b(d.maximum_linear_velocity),
        b(d.maximum_angular_velocity), b(d.linear_drag), b(d.angular_drag)
    )
}
fn shape_s(s: MassShape) -> String {
    match s {
        MassShape::Sphere { radius } => format!("{{ kind = \"Sphere\", radius = {} }}", b(radius)),
        MassShape::Capsule { radius, half_length } => format!(
            "{{ kind = \"Capsule\", radius = {}, half_length = {} }}", b(radius), b(half_length)),
        MassShape::RoundedBox { half_extents, radius } => format!(
            "{{ kind = \"RoundedBox\", half_extents = {}, radius = {} }}", v(half_extents), b(radius)),
        MassShape::Cylinder { radius, half_length, padding } => format!(
            "{{ kind = \"Cylinder\", radius = {}, half_length = {}, padding = {} }}",
            b(radius), b(half_length), b(padding)),
        MassShape::Unsupported => "{ kind = \"Unsupported\" }".into(),
    }
}
fn moments_s(m: &MassMoments) -> String {
    let mut s = String::from("{ ");
    for c in m.columns {
        write!(s, "{{ {}, {}, {}, {} }}, ", b(c[0]), b(c[1]), b(c[2]), b(c[3])).unwrap();
    }
    s.push('}');
    s
}
fn rotation(r: &mut Rng) -> Basis3 {
    // случайный поворот: нормализованный кватернион -> матрица (f32)
    let (x, y, z, w) = (r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0));
    let l = (x * x + y * y + z * z + w * w).sqrt();
    let (x, y, z, w) = (x / l, y / l, z / l, w / l);
    Basis3 {
        columns: [
            [1.0 - 2.0 * (y * y + z * z), 2.0 * (x * y + z * w), 2.0 * (x * z - y * w)],
            [2.0 * (x * y - z * w), 1.0 - 2.0 * (x * x + z * z), 2.0 * (y * z + x * w)],
            [2.0 * (x * z + y * w), 2.0 * (y * z - x * w), 1.0 - 2.0 * (x * x + y * y)],
        ],
    }
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x3a55_0001);
    let mut s = String::from("-- Сгенерировано golden/src/mass.rs из настоящего skate-core. Не править.\nreturn {\n");
    write!(
        s,
        "\tstock = {{ wheel = {}, truck = {}, deck = {} }},\n",
        props(&retail_wheel_mass_properties()),
        props(&retail_truck_mass_properties()),
        props(&retail_deck_mass_properties())
    )
    .unwrap();
    s.push_str("\tprimitive = {\n");
    for i in 0..3000 {
        let tiny = i % 9 == 0;
        let span = if tiny { 1e-6 } else { 1.0 };
        let shape = match i % 5 {
            0 => MassShape::Sphere { radius: r.range(0.0, span) },
            1 => MassShape::Capsule { radius: r.range(0.0, span), half_length: r.range(0.0, span) },
            2 => MassShape::RoundedBox {
                half_extents: Vector3::new(r.range(0.0, span), r.range(0.0, span), r.range(0.0, span)),
                radius: if r.bool() { 0.0 } else { r.range(0.0, span * 0.2) },
            },
            3 => MassShape::Cylinder {
                radius: r.range(0.0, span), half_length: r.range(0.0, span), padding: r.range(0.0, 0.05),
            },
            _ => MassShape::Unsupported,
        };
        let requested = match i % 4 {
            0 => 0.0,
            1 => f32::NAN,
            _ => r.range(0.0, 20.0),
        };
        let pm = primitive_mass(shape);
        let pp = primitive_mass_properties(PartMassInput { shape, requested_mass: requested }, r.range(1.0, 100.0), 0.5);
        let pm_s = match pm {
            Some(p) => format!("{{ {}, {} }}", v(p.moments_per_unit_mass), b(p.volume)),
            None => "false".into(),
        };
        let pp_s = match pp { Some(p) => props(&p), None => "false".into() };
        writeln!(s, "\t\t{{ shape = {}, requested = {}, mass = {}, props = {} }},", shape_s(shape), b(requested), pm_s, pp_s).unwrap();
    }
    s.push_str("\t},\n\taggregate = {\n");
    for i in 0..1500 {
        let mut total = MassMoments::ZERO;
        let n = 1 + (r.next() % 4) as usize;
        for _ in 0..n {
            let shape = MassShape::RoundedBox {
                half_extents: Vector3::new(r.range(0.01, 0.5), r.range(0.01, 0.5), r.range(0.01, 0.5)),
                radius: r.range(0.0, 0.02),
            };
            let mut child = MassMoments::from_primitive(primitive_mass(shape).unwrap());
            let rot = if i % 3 == 0 { Basis3 { columns: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]] } } else { rotation(&mut r) };
            let t = if i % 5 == 0 { Vector3::new(r.range(-1e-4, 1e-4), 0.0, 0.0) } else { r.vec(0.6) };
            child.transform(rot, t);
            total.add(child);
        }
        let requested = if i % 6 == 0 { 0.0 } else { r.range(0.1, 10.0) };
        let p = aggregate_mass_properties(total, requested, r.range(1.0, 100.0), r.range(0.0, 2.0));
        writeln!(s, "\t\t{{ moments = {}, requested = {}, props = {} }},", moments_s(&total), b(requested), props(&p)).unwrap();
    }
    s.push_str("\t},\n\tdeck = {\n");
    for i in 0..60 {
        let mut st = DeckGeometrySettings::STOCK;
        if i > 0 {
            st.width = r.range(0.15, 0.3);
            st.mid_length = r.range(0.4, 0.8);
            st.thickness = r.range(0.005, 0.03);
            st.back_end_size = r.range(0.05, 0.25);
            st.front_end_angle_degrees = r.range(0.0, 30.0);
            st.back_end_angle_degrees = r.range(0.0, 30.0);
            st.end_capsule_count = 1 + (r.next() % 8) as i32;
            st.enable_deck_volume_collisions = r.bool();
            st.enable_end_volume_collisions = r.bool();
        }
        let g = DeckGeometry::new(st);
        let mut kids = String::new();
        for c in &g.children {
            let shape = match c.shape {
                DeckShape::RoundedBox { half_extents, radius } => format!("{{ kind = \"RoundedBox\", half_extents = {}, radius = {} }}", v(half_extents), b(radius)),
                DeckShape::Capsule { radius, half_length } => format!("{{ kind = \"Capsule\", radius = {}, half_length = {} }}", b(radius), b(half_length)),
                DeckShape::Sphere { radius } => format!("{{ kind = \"Sphere\", radius = {} }}", b(radius)),
                DeckShape::Triangle { vertices, fatness, edge_cosines, volume_flags } => format!(
                    "{{ kind = \"Triangle\", vertices = {{ {}, {}, {} }}, fatness = {}, edge_cosines = {{ {}, {}, {} }}, volume_flags = {} }}",
                    v(vertices[0]), v(vertices[1]), v(vertices[2]), b(fatness), b(edge_cosines[0]), b(edge_cosines[1]), b(edge_cosines[2]), volume_flags),
            };
            write!(kids, "{{ shape = {}, basis = {}, translation = {}, enabled = {} }}, ", shape, basis(c.transform.basis), v(c.transform.translation), c.collision_enabled).unwrap();
        }
        let dm = r.range(1.0, 10.0);
        let p = deck_mass_properties(&g, dm, 27.0);
        writeln!(
            s,
            "\t\t{{ settings = {{ {}, {}, {}, {}, {}, {}, {}, {}, {} }}, children = {{ {} }}, moments = {}, mass = {}, props = {} }},",
            b(st.width), b(st.mid_length), b(st.thickness), b(st.back_end_size), b(st.front_end_angle_degrees),
            b(st.back_end_angle_degrees), st.end_capsule_count, st.enable_deck_volume_collisions, st.enable_end_volume_collisions,
            kids, moments_s(&g.mass_moments()), b(dm), props(&p)
        )
        .unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/mass.luau"), s).unwrap();
}
