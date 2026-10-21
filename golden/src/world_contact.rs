//! Эталон для physics/world_contact: запросы примитивов, пары, сокращение, буфер.
use crate::collision::{b, random_triangle, v, Rng};
use skate_core::math::{Basis3, Vector3};
use skate_core::physics::collision::{Sphere, Triangle, WorldContactSettings};
use skate_core::physics::world_contact::{
    coplanar_contacts, primitive_pair_contacts, primitive_triangle_world_contacts,
    select_contact_points, ContactBuffer, ContactPrimitive, ContactRecord, PrimitiveContactManifold,
    PrimitivePairSettings,
};
use std::fmt::Write as _;

fn tri(t: &Triangle) -> String {
    format!(
        "{{ vertices = {{ {}, {}, {} }}, normal = {}, edges = {{ {}, {}, {} }}, flags = {}, edge_cosines = {{ {}, {}, {} }}, edge_lengths = {{ {}, {}, {} }}, fatness = {} }}",
        v(t.vertices[0]), v(t.vertices[1]), v(t.vertices[2]), v(t.feature.normal),
        v(t.feature.edges[0]), v(t.feature.edges[1]), v(t.feature.edges[2]), t.feature.flags,
        b(t.feature.edge_cosines[0]), b(t.feature.edge_cosines[1]), b(t.feature.edge_cosines[2]),
        b(t.edge_lengths[0]), b(t.edge_lengths[1]), b(t.edge_lengths[2]), b(t.fatness)
    )
}

fn basis(r: &mut Rng) -> Basis3 {
    let (mut x, mut y, mut z, mut w) = (r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0));
    let n = (x * x + y * y + z * z + w * w).sqrt().max(1e-3);
    x /= n; y /= n; z /= n; w /= n;
    Basis3 { columns: [
        [1.0 - 2.0 * (y * y + z * z), 2.0 * (x * y + w * z), 2.0 * (x * z - w * y)],
        [2.0 * (x * y - w * z), 1.0 - 2.0 * (x * x + z * z), 2.0 * (y * z + w * x)],
        [2.0 * (x * z + w * y), 2.0 * (y * z - w * x), 1.0 - 2.0 * (x * x + y * y)],
    ] }
}

fn unit(r: &mut Rng) -> Vector3 {
    let a = r.vec(1.0);
    let n = (a.x * a.x + a.y * a.y + a.z * a.z).sqrt().max(1e-3);
    Vector3::new(a.x / n, a.y / n, a.z / n)
}

fn primitive(r: &mut Rng, center: Vector3, kind: u32) -> ContactPrimitive {
    match kind {
        0 => ContactPrimitive::Sphere(Sphere { center, radius: r.range(0.05, 0.6) }),
        1 => ContactPrimitive::Capsule { center, axis: unit(r), half_length: r.range(0.1, 0.8), radius: r.range(0.03, 0.4) },
        2 => {
            let t = random_triangle(r);
            let d = Vector3::new(center.x - t.vertices[0].x, center.y - t.vertices[0].y, center.z - t.vertices[0].z);
            let vs = t.vertices.map(|p| Vector3::new(p.x + d.x, p.y + d.y, p.z + d.z));
            ContactPrimitive::Triangle(skate_core::physics::world_contact::triangle_from_volume(vs, t.fatness, t.feature.edge_cosines, t.feature.flags))
        }
        _ => ContactPrimitive::RoundedBox {
            center,
            basis: if r.next() % 4 == 0 { Basis3 { columns: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]] } } else { basis(r) },
            half_extents: Vector3::new(r.range(0.05, 0.9), r.range(0.05, 0.9), r.range(0.05, 0.9)),
            radius: if r.bool() { 0.0 } else { r.range(0.0, 0.1) },
        },
    }
}

fn prim(p: &ContactPrimitive) -> String {
    match p {
        ContactPrimitive::Sphere(s) => format!("{{ kind = \"Sphere\", center = {}, radius = {} }}", v(s.center), b(s.radius)),
        ContactPrimitive::Capsule { center, axis, half_length, radius } => format!(
            "{{ kind = \"Capsule\", center = {}, axis = {}, half_length = {}, radius = {} }}", v(*center), v(*axis), b(*half_length), b(*radius)),
        ContactPrimitive::Triangle(t) => format!("{{ kind = \"Triangle\", triangle = {} }}", tri(t)),
        ContactPrimitive::RoundedBox { center, basis, half_extents, radius } => format!(
            "{{ kind = \"RoundedBox\", center = {}, basis = {{ {{ {}, {}, {} }}, {{ {}, {}, {} }}, {{ {}, {}, {} }} }}, half_extents = {}, radius = {} }}",
            v(*center),
            b(basis.columns[0][0]), b(basis.columns[0][1]), b(basis.columns[0][2]),
            b(basis.columns[1][0]), b(basis.columns[1][1]), b(basis.columns[1][2]),
            b(basis.columns[2][0]), b(basis.columns[2][1]), b(basis.columns[2][2]),
            v(*half_extents), b(*radius)),
    }
}

fn manifold(m: &Option<PrimitiveContactManifold>) -> String {
    match m {
        None => "false".into(),
        Some(m) => {
            let mut s = format!("{{ normal = {}, count = {}, points = {{ ", v(m.normal), m.count);
            for p in &m.points[..m.count] {
                write!(s, "{{ a = {}, b = {} }}, ", v(p.a), v(p.b)).unwrap();
            }
            s.push_str("} }");
            s
        }
    }
}

fn centroid(t: &Triangle) -> Vector3 {
    let [a, c, d] = t.vertices;
    Vector3::new((a.x + c.x + d.x) / 3.0, (a.y + c.y + d.y) / 3.0, (a.z + c.z + d.z) / 3.0)
}

fn record_words(r: &mut Rng, a: Vector3, bpt: Vector3, n: Vector3, ida: u32, idb: u32) -> ContactRecord {
    let mut rec = [0u32; 64];
    for w in rec.iter_mut() {
        *w = r.range(-10.0, 10.0).to_bits();
    }
    if r.next() % 7 == 0 { rec[(r.next() % 64) as usize] = 0x7f80_0001; }
    rec[0] = a.x.to_bits(); rec[1] = a.y.to_bits(); rec[2] = a.z.to_bits(); rec[3] = ida;
    rec[4] = bpt.x.to_bits(); rec[5] = bpt.y.to_bits(); rec[6] = bpt.z.to_bits(); rec[7] = idb;
    rec[8] = n.x.to_bits(); rec[9] = n.y.to_bits(); rec[10] = n.z.to_bits();
    rec[23] = r.next() % 5;
    rec
}

fn words(rec: &ContactRecord) -> String {
    let mut s = String::from("{ ");
    for w in rec { write!(s, "{}, ", w).unwrap(); }
    s.push('}');
    s
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x0c0f_fee5);
    let mut s = String::from("-- Сгенерировано golden/src/world_contact.rs из настоящего skate-core. Не править.\nreturn {\n\tworld = {\n");
    for i in 0..6000u32 {
        let t = random_triangle(&mut r);
        let c = centroid(&t);
        let n = t.feature.normal;
        let h = r.range(-0.6, 0.9);
        let lat = r.vec(0.8);
        let center = Vector3::new(c.x + n.x * h + lat.x, c.y + n.y * h + lat.y, c.z + n.z * h + lat.z);
        let p = primitive(&mut r, center, i % 4);
        let velocity = r.vec(6.0);
        let settings = WorldContactSettings {
            volume_padding: r.range(0.0, 0.05),
            maximum_separating_distance: r.range(0.0, 0.5),
            edge_cos_bend_normal_threshold: r.range(-1.0, 1.0),
            convexity_epsilon: r.range(0.0, 0.05),
            is_object: r.bool(),
        };
        let m = primitive_triangle_world_contacts(p, t, velocity, settings);
        write!(s, "\t\t{{ primitive = {}, tri = {}, velocity = {}, settings = {{ {}, {}, {}, {}, {} }}, result = {} }},\n",
            prim(&p), tri(&t), v(velocity), b(settings.volume_padding), b(settings.maximum_separating_distance),
            b(settings.edge_cos_bend_normal_threshold), b(settings.convexity_epsilon), settings.is_object, manifold(&m)).unwrap();
    }
    // Прицельные случаи: коробка лежит гранью на треугольнике (грань/грань).
    for _ in 0..3000u32 {
        let t = random_triangle(&mut r);
        let c = centroid(&t);
        let n = t.feature.normal;
        let e0 = t.feature.edges[0];
        let e2 = Vector3::new(n.y * e0.z - n.z * e0.y, n.z * e0.x - n.x * e0.z, n.x * e0.y - n.y * e0.x);
        let half = Vector3::new(r.range(0.05, 0.5), r.range(0.05, 0.4), r.range(0.05, 0.5));
        let gap = r.range(-0.03, 0.05);
        let shift = r.vec(0.3);
        let center = Vector3::new(c.x + n.x * (half.y + gap) + shift.x * 0.3, c.y + n.y * (half.y + gap) + shift.y * 0.3, c.z + n.z * (half.y + gap) + shift.z * 0.3);
        let tilt = r.range(-0.02, 0.02);
        let up = Vector3::new(n.x + e0.x * tilt, n.y + e0.y * tilt, n.z + e0.z * tilt);
        let p = ContactPrimitive::RoundedBox {
            center,
            basis: Basis3 { columns: [[e0.x, e0.y, e0.z], [up.x, up.y, up.z], [e2.x, e2.y, e2.z]] },
            half_extents: half,
            radius: if r.bool() { 0.0 } else { r.range(0.0, 0.05) },
        };
        let velocity = r.vec(3.0);
        let settings = WorldContactSettings {
            volume_padding: r.range(0.0, 0.05),
            maximum_separating_distance: r.range(0.0, 0.5),
            edge_cos_bend_normal_threshold: r.range(-1.0, 1.0),
            convexity_epsilon: r.range(0.0, 0.05),
            is_object: r.bool(),
        };
        let m = primitive_triangle_world_contacts(p, t, velocity, settings);
        write!(s, "\t\t{{ primitive = {}, tri = {}, velocity = {}, settings = {{ {}, {}, {}, {}, {} }}, result = {} }},\n",
            prim(&p), tri(&t), v(velocity), b(settings.volume_padding), b(settings.maximum_separating_distance),
            b(settings.edge_cos_bend_normal_threshold), b(settings.convexity_epsilon), settings.is_object, manifold(&m)).unwrap();
    }
    s.push_str("\t},\n\tpair = {\n");
    // Прицельные случаи: коробки друг на друге (четырёхугольник/четырёхугольник).
    for _ in 0..3000u32 {
        let ca = r.vec(2.0);
        let ha = Vector3::new(r.range(0.1, 0.6), r.range(0.1, 0.6), r.range(0.1, 0.6));
        let hb = Vector3::new(r.range(0.1, 0.6), r.range(0.1, 0.6), r.range(0.1, 0.6));
        let gap = r.range(-0.03, 0.05);
        let cb = Vector3::new(ca.x + r.range(-0.3, 0.3), ca.y + ha.y + hb.y + gap, ca.z + r.range(-0.3, 0.3));
        let ang = r.range(-0.8, 0.8);
        let tilt = r.range(-0.02, 0.02);
        let (sn, cs) = ang.sin_cos();
        let ident = Basis3 { columns: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]] };
        let turned = Basis3 { columns: [[cs, tilt, -sn], [-tilt * cs, 1.0, tilt * sn], [sn, 0.0, cs]] };
        let pa = ContactPrimitive::RoundedBox { center: ca, basis: ident, half_extents: ha, radius: if r.bool() { 0.0 } else { 0.03 } };
        let pb = ContactPrimitive::RoundedBox { center: cb, basis: if r.bool() { ident } else { turned }, half_extents: hb, radius: if r.bool() { 0.0 } else { 0.03 } };
        let (pa, pb) = if r.bool() { (pa, pb) } else { (pb, pa) };
        let settings = PrimitivePairSettings::skater_self_collision();
        let m = primitive_pair_contacts(pa, pb, settings);
        write!(s, "\t\t{{ a = {}, b = {}, settings = {{ {}, {}, {}, {}, {} }}, result = {} }},\n",
            prim(&pa), prim(&pb), b(settings.padding_a), b(settings.padding_b), b(settings.additional_padding),
            b(settings.edge_cos_bend_normal_threshold), b(settings.convexity_epsilon), manifold(&m)).unwrap();
    }
    for i in 0..6000u32 {
        let ka = i % 4;
        let kb = (i / 4) % 4;
        let ca = r.vec(2.0);
        let cb = Vector3::new(ca.x + r.range(-1.2, 1.2), ca.y + r.range(-1.2, 1.2), ca.z + r.range(-1.2, 1.2));
        let pa = primitive(&mut r, ca, ka);
        let pb = primitive(&mut r, cb, kb);
        let settings = if r.bool() { PrimitivePairSettings::skater_self_collision() } else {
            PrimitivePairSettings {
                padding_a: r.range(0.0, 0.1), padding_b: r.range(0.0, 0.1), additional_padding: r.range(0.0, 0.05),
                edge_cos_bend_normal_threshold: r.range(-1.0, 1.0), convexity_epsilon: r.range(0.0, 0.05),
            }
        };
        let m = primitive_pair_contacts(pa, pb, settings);
        write!(s, "\t\t{{ a = {}, b = {}, settings = {{ {}, {}, {}, {}, {} }}, result = {} }},\n",
            prim(&pa), prim(&pb), b(settings.padding_a), b(settings.padding_b), b(settings.additional_padding),
            b(settings.edge_cos_bend_normal_threshold), b(settings.convexity_epsilon), manifold(&m)).unwrap();
    }
    s.push_str("\t},\n\tselect = {\n");
    for _ in 0..1500 {
        let count = 1 + (r.next() % 9) as usize;
        let normal = unit(&mut r);
        let pa: Vec<[f32; 3]> = (0..count).map(|_| { let p = r.vec(2.0); [p.x, p.y, p.z] }).collect();
        let pb: Vec<[f32; 3]> = (0..count).map(|_| { let p = r.vec(2.0); [p.x, p.y, p.z] }).collect();
        let mut out = [0u32, 1, 2, 3];
        let n = select_contact_points(&pa, &pb, [normal.x, normal.y, normal.z], &mut out);
        s.push_str("\t\t{ a = { ");
        for p in &pa { write!(s, "{{ {}, {}, {} }}, ", b(p[0]), b(p[1]), b(p[2])).unwrap(); }
        s.push_str("}, b = { ");
        for p in &pb { write!(s, "{{ {}, {}, {} }}, ", b(p[0]), b(p[1]), b(p[2])).unwrap(); }
        write!(s, "}}, normal = {}, count = {}, out = {{ {}, {}, {}, {} }} }},\n", v(normal), n, out[0], out[1], out[2], out[3]).unwrap();
    }
    s.push_str("\t},\n\tbuffer = {\n");
    for case in 0..300 {
        let mut buf = ContactBuffer {
            count: 0,
            flushed: 0,
            capacity: 20 + r.next() % 80,
            dropped: 0,
            distance_squared_threshold: if r.next() % 4 == 0 { -1.0 } else { r.range(0.0, 0.05) },
            allow_flush: (r.next() % 2) as u8,
            deferred_reduction: (r.next() % 2) as u8,
            full: 0,
            records: [[0; 64]; 50],
        };
        let start = (buf.capacity, buf.distance_squared_threshold, buf.allow_flush, buf.deferred_reduction);
        let mut ops = String::new();
        let mut flushed = String::new();
        let clusters = 1 + r.next() % 4;
        let normals: Vec<Vector3> = (0..clusters).map(|_| unit(&mut r)).collect();
        let anchors: Vec<Vector3> = (0..clusters).map(|_| r.vec(1.0)).collect();
        let steps = 10 + r.next() % 90;
        for _ in 0..steps {
            let c = (r.next() % clusters) as usize;
            let n = normals[c];
            let jitter = if r.next() % 3 == 0 { 0.0 } else { 0.003 };
            let nn = Vector3::new(n.x + r.range(-jitter, jitter), n.y + r.range(-jitter, jitter), n.z + r.range(-jitter, jitter));
            let off = r.vec(0.4);
            let along = r.range(-0.005, 0.005);
            let base = anchors[c];
            let a = Vector3::new(base.x + off.x - n.x * (off.x * n.x + off.y * n.y + off.z * n.z) + n.x * along, base.y + off.y - n.y * (off.x * n.x + off.y * n.y + off.z * n.z) + n.y * along, base.z + off.z - n.z * (off.x * n.x + off.y * n.y + off.z * n.z) + n.z * along);
            let depth = r.range(-0.02, 0.02);
            let bp = Vector3::new(a.x - n.x * depth, a.y - n.y * depth, a.z - n.z * depth);
            let rec = record_words(&mut r, a, bp, nn, c as u32 % 2, 7 + (c as u32 / 2));
            let mut sink_calls = Vec::new();
            let slot = buf.allocate(&mut |recs: &[ContactRecord]| sink_calls.push(recs.to_vec()));
            for call in &sink_calls {
                flushed.push_str("{ ");
                for rr in call { write!(flushed, "{}, ", words(rr)).unwrap(); }
                flushed.push_str("}, ");
            }
            let mut dup = false;
            if let Some(index) = slot {
                buf.records[index] = rec;
                dup = buf.last_is_duplicate();
                if dup { buf.count -= 1; }
            }
            write!(ops, "{{ rec = {}, slot = {}, dup = {} }}, ", words(&rec), slot.map(|x| x as i64).unwrap_or(-1), dup).unwrap();
        }
        let mut final_flush = Vec::new();
        buf.flush(&mut |recs: &[ContactRecord]| final_flush.push(recs.to_vec()));
        for call in &final_flush {
            flushed.push_str("{ ");
            for rr in call { write!(flushed, "{}, ", words(rr)).unwrap(); }
            flushed.push_str("}, ");
        }
        let _ = case;
        write!(s, "\t\t{{ capacity = {}, threshold = {}, allow_flush = {}, deferred = {}, ops = {{ {} }}, flushed = {{ {} }}, count = {}, flushed_count = {}, dropped = {}, full = {} }},\n",
            start.0, b(start.1), start.2, start.3, ops, flushed, buf.count, buf.flushed, buf.dropped, buf.full).unwrap();
    }
    s.push_str("\t},\n\tcoplanar = {\n");
    for _ in 0..2000 {
        let n = unit(&mut r);
        let jitter = if r.bool() { 0.0 } else { r.range(0.0, 0.05) };
        let n2 = Vector3::new(n.x + r.range(-jitter, jitter), n.y + r.range(-jitter, jitter), n.z + r.range(-jitter, jitter));
        let p = r.vec(1.0);
        let q = r.vec(1.0);
        let along = r.range(-0.03, 0.03);
        let q2 = Vector3::new(q.x + n.x * along, q.y + n.y * along, q.z + n.z * along);
        let ra = record_words(&mut r, p, q, n, 1, 2);
        let shift = r.range(-0.2, 0.2);
        let rb = record_words(&mut r, Vector3::new(p.x + shift, p.y, p.z), q2, n2, 1, 2);
        write!(s, "\t\t{{ a = {}, b = {}, result = {} }},\n", words(&ra), words(&rb), coplanar_contacts(&ra, &rb)).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/world_contact.luau"), s).unwrap();
}
