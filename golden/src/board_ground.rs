//! Эталон для physics/board_ground, board_probes, board_toolkit.
use crate::collision::{b, v, Rng};
use skate_core::math::Vector3;
use skate_core::physics::board::BodyId;
use skate_core::physics::board_ground::{angle_between, BoardGroundState, WheelLineHit, WheelLineState};
use skate_core::physics::board_probes::{deck_probe, wall_probe, BoardProbeHit, BoardProbeState, WallLineInput};
use skate_core::physics::board_step::CollisionBody;
use skate_core::physics::board_toolkit::BoardToolkit;
use skate_core::physics::contact_feedback::BoardContactReport;
use std::fmt::Write as _;

fn unitish(r: &mut Rng) -> Vector3 {
    let k = r.next() % 4;
    match k { 0 => Vector3::new(0.0, 1.0, 0.0), 1 => { let a = r.vec(1.0); let l = (a.x*a.x+a.y*a.y+a.z*a.z).sqrt().max(1e-3); Vector3::new(a.x/l, a.y/l, a.z/l) }, 2 => r.vec(1.2), _ => Vector3::new(r.range(-0.3,0.3), r.range(0.6,1.0), r.range(-0.3,0.3)) }
}
fn f4(x: [f32; 4]) -> String { format!("{{ {}, {}, {}, {} }}", b(x[0]), b(x[1]), b(x[2]), b(x[3])) }
fn lines_s(l: &WheelLineState) -> String {
    let n: Vec<String> = l.normals.iter().map(|&x| v(x)).collect();
    let d: Vec<String> = l.distances.iter().map(|&x| b(x)).collect();
    format!("{{ {{ {} }}, {{ {} }}, {{ {} }}, {{ {} }}, {{ {} }}, {} }}", n.join(", "), d.join(", "),
        l.physics_surfaces.map(|x| x.to_string()).join(", "), l.audio_surfaces.map(|x| x.to_string()).join(", "), l.seam_patterns.map(|x| x.to_string()).join(", "), b(l.minimum_distance))
}
fn ground_s(g: &BoardGroundState) -> String {
    let parts: Vec<String> = g.parts.iter().map(|p| format!("{{ {}, {}, {}, {} }}", p.in_contact, v(p.normal), v(p.point), v(p.relative_velocity))).collect();
    let pv: Vec<String> = g.previous_velocities.iter().map(|&x| v(x)).collect();
    let ac: Vec<String> = g.accelerations.iter().map(|&x| v(x)).collect();
    format!("{{ parts = {{ {} }}, pv = {{ {} }}, acc = {{ {} }}, closing = {}, max_closing = {}, opposing = {}, s12 = {}, flags = {}, overall = {}, wheel = {}, valid = {{ {} }}, pcount = {}, wcount = {}, time = {}, drag = {{ {} }}, audio = {{ {} }} }}",
        parts.join(", "), pv.join(", "), ac.join(", "), v(g.closing_velocity), b(g.maximum_closing_speed), b(g.opposing_contact), b(g.surface_twelve_height), g.collision_flags,
        v(g.overall_normal), v(g.wheel_normal), g.valid_wheel_normals.map(|x| x.to_string()).join(", "), g.part_contact_count, g.wheel_contact_count, b(g.time_without_wheel_contact),
        g.wheel_angular_drag.map(b).join(", "), g.part_audio_surfaces.map(|x| x.to_string()).join(", "))
}
fn probe_s(p: &BoardProbeState) -> String { format!("{{ {}, {}, {}, {}, {} }}", v(p.start), v(p.point), v(p.normal), p.surface_tag, p.hit) }

pub fn write(out_dir: &str) {
    let mut r = Rng(0x6a0d_b0a2);
    let mut s = String::from("-- Сгенерировано golden/src/board_ground.rs из настоящего skate-core. Не править.\nreturn {\n\tground = {\n");
    let tag = |r: &mut Rng| -> u32 { match r.next() % 5 { 0 => 12 << 7 | (r.next() & 0x7f), 1 => 8 << 7 | 3, 2 => r.next() & 0xffff, _ => (r.next() % 32) << 7 | (r.next() & 0x7f) | ((r.next() & 0xf) << 12) } };
    for _ in 0..80 {
        let mut ground = BoardGroundState::default();
        let mut lines = WheelLineState::default();
        let mut steps = String::new();
        for _ in 0..25 {
            let hits: [Option<WheelLineHit>; 4] = core::array::from_fn(|_| if r.next() % 3 == 0 { None } else { Some(WheelLineHit { fraction: r.range(0.0, 1.0), normal: unitish(&mut r), surface_tag: tag(&mut r) }) });
            let hs: Vec<String> = hits.iter().map(|h| match h { Some(h) => format!("{{ {}, {}, {} }}", b(h.fraction), v(h.normal), h.surface_tag), None => "false".into() }).collect();
            lines.publish(hits);
            let n = r.next() % 9;
            let mut reports = vec![];
            let mut rs = String::new();
            for _ in 0..n {
                let part = BodyId::ORDER[(r.next() % 7) as usize];
                let rep = BoardContactReport { part, other: CollisionBody::StaticWorld, is_body_a: true, normal: unitish(&mut r), position: r.vec(5.0),
                    relative_linear_velocity: r.vec(3.0), other_surface: tag(&mut r) as u16, normal_force_on_a: Vector3::ZERO, friction_force_on_a: Vector3::ZERO, tangents: [Vector3::ZERO; 2] };
                write!(rs, "{{ {}, {}, {}, {}, {} }}, ", part as u32, v(rep.normal), v(rep.position), v(rep.relative_linear_velocity), rep.other_surface).unwrap();
                reports.push(rep);
            }
            let up = unitish(&mut r);
            let angle = r.range(10.0, 90.0);
            let wipe = r.bool();
            ground.update(&reports, &lines, up, angle, wipe);
            let vels: [Vector3; 7] = core::array::from_fn(|_| r.vec(4.0));
            let dt = if r.bool() { 1.0 / 60.0 } else { r.range(0.005, 0.05) };
            ground.sample_accelerations(vels, dt);
            ground.advance_contact_time(dt);
            let vs: Vec<String> = vels.iter().map(|&x| v(x)).collect();
            writeln!(steps, "\t\t\t{{ hits = {{ {} }}, lines = {}, reports = {{ {} }}, up = {}, angle = {}, wipe = {}, vels = {{ {} }}, dt = {}, out = {} }},",
                hs.join(", "), lines_s(&lines), rs, v(up), b(angle), wipe, vs.join(", "), b(dt), ground_s(&ground)).unwrap();
        }
        writeln!(s, "\t\t{{\n{}\t\t}},", steps).unwrap();
    }
    s.push_str("\t},\n\tangle = {\n");
    for _ in 0..2000 {
        let a = if r.next() % 10 == 0 { r.vec(0.001) } else { r.vec(3.0) };
        let c = if r.next() % 7 == 0 { a } else { r.vec(3.0) };
        writeln!(s, "\t\t{{ {}, {}, {} }},", v(a), v(c), b(angle_between(a, c))).unwrap();
    }
    s.push_str("\t},\n\twall = {\n");
    for _ in 0..1000 {
        let input = WallLineInput { state: [100, 101, 99, 200][(r.next() % 4) as usize], contact_normal: unitish(&mut r), skater_up: unitish(&mut r), deck_position: r.vec(10.0), time: r.range(0.0, 0.05) };
        let out = match wall_probe(input) { Some(l) => format!("{{ {}, {} }}", v(l.start), v(l.end)), None => "false".into() };
        let d = deck_probe(input.deck_position);
        writeln!(s, "\t\t{{ {}, {}, {}, {}, {}, {}, {{ {}, {} }} }},", input.state, v(input.contact_normal), v(input.skater_up), v(input.deck_position), b(input.time), out, v(d.start), v(d.end)).unwrap();
    }
    s.push_str("\t},\n\tprobe = {\n");
    let mut p = BoardProbeState::default();
    for _ in 0..200 {
        let op = r.next() % 3;
        let pos = r.vec(5.0);
        let hit = if r.bool() { Some(BoardProbeHit { point: r.vec(5.0), normal: unitish(&mut r), surface_tag: r.next() & 0xffff }) } else { None };
        match op { 0 => p.start(pos), 1 => p.publish(hit), _ => p.disable() }
        let hs = match hit { Some(h) => format!("{{ {}, {}, {} }}", v(h.point), v(h.normal), h.surface_tag), None => "false".into() };
        writeln!(s, "\t\t{{ {}, {}, {}, {} }},", op, v(pos), hs, probe_s(&p)).unwrap();
    }
    s.push_str("\t},\n\ttoolkit = {\n");
    for _ in 0..1000 {
        let deck: [[f32; 4]; 4] = core::array::from_fn(|i| if i < 3 { let a = unitish(&mut r); [a.x, a.y, a.z, 0.0] } else { let t = r.vec(20.0); [t.x, t.y, t.z, 1.0] });
        let masses: [f32; 7] = core::array::from_fn(|_| r.range(0.0, 3.0));
        let flags = if r.bool() { 0x0010_0000 } else { r.next() & 0x000f_ffff };
        let speed = match r.next() % 5 { 0 => 0.0, 1 => -0.0, _ => r.range(-15.0, 15.0) };
        let n = unitish(&mut r); let rn = unitish(&mut r);
        let normal = [n.x, n.y, n.z, 0.0];
        let retained = if r.next() % 4 == 0 { normal } else { [rn.x, rn.y, rn.z, 0.0] };
        let t = BoardToolkit::calculate(deck, &masses, flags, speed, normal, retained);
        let m4 = |m: [[f32; 4]; 4]| format!("{{ {}, {}, {}, {} }}", f4(m[0]), f4(m[1]), f4(m[2]), f4(m[3]));
        writeln!(s, "\t\t{{ input = {{ {}, {{ {} }}, {}, {}, {}, {} }}, out = {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }} }},",
            m4(deck), masses.map(b).join(", "), flags, b(speed), f4(normal), f4(retained),
            m4(t.deck), m4(t.effective), m4(t.inverse_effective), f4(t.side), f4(t.up), f4(t.forward), f4(t.horizontal_forward), f4(t.transverse_up),
            f4(t.forward_velocity), f4(t.travel_direction), f4(t.filtered_normal), b(t.absolute_speed), b(t.control_sign), b(t.total_mass)).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/board_ground.luau"), s).unwrap();
}
