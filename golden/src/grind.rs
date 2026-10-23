//! Эталон для physics::grind_contact: segment_triangle, контакты тележек/деки/
//! кончиков, upright_normal, within_approach_angle, Admission, семейства
//! (boardslide/50-50/5-0/tipslide/darkslide/backslash), Engagement, Control,
//! investigate, manager и balance. Только синтетические входы — можно коммитить.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::air::trajectory::grind_surface::{GeometryType, GrindSurface};
use skate_core::physics::grind_contact::{
    admission::{approach_slope_sine, engagement_slope_sine, Admission, EntryKind},
    balance::{BalanceContact, BalanceState, BalanceVectors, ExitLeanInput, ForceExitHit, TargetUpInput},
    boardslide_candidate, control, deck_contact, entry, families, fifty_fifty_candidate_on_splines,
    investigator::{investigate, Query},
    manager, segment_triangle, truck_contacts, upright_normal, within_approach_angle, FiftyFiftyCandidate, Primitive,
    TruckContact,
};
use skate_core::point_graph::PointGraph;
use std::fmt::Write as _;

type V = [f32; 4];

fn unit(r: &mut Rng) -> V {
    let v = r.vec(1.0);
    let l = (v.x * v.x + v.y * v.y + v.z * v.z).sqrt().max(1e-3);
    [v.x / l, v.y / l, v.z / l, 0.0]
}
fn v4(r: &mut Rng, span: f32) -> V { let v = r.vec(span); [v.x, v.y, v.z, 0.0] }
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0], 0.0] }
fn norm(a: V) -> V { let l = (a[0] * a[0] + a[1] * a[1] + a[2] * a[2]).sqrt().max(1e-6); [a[0] / l, a[1] / l, a[2] / l, 0.0] }
fn madd(a: V, s: f32, b: V) -> V { [a[0] * s + b[0], a[1] * s + b[1], a[2] * s + b[2], 0.0] }
fn board(r: &mut Rng) -> [V; 4] {
    let mut up = unit(r);
    match r.next() % 6 { 0 | 4 | 5 => up = [0.0, 1.0, 0.0, 0.0], 1 => { up[1] = up[1].abs() + 1.5; up = norm(up) } 2 => { up[1] = -up[1].abs() - 1.0; up = norm(up) } _ => {} }
    let forward = norm(cross(unit(r), up));
    let right = cross(up, forward);
    [right, up, forward, v4(r, 2.0)]
}
/// Ребро, проходящее рядом с доской (под ней), чтобы прямоугольники зондов его пересекали.
fn edge_near(r: &mut Rng, b: &[V; 4]) -> Primitive {
    let mut p = b[3];
    p = madd(b[1], if r.bool() { r.range(-0.07, 0.07) } else { r.range(-0.3, 0.1) }, p);
    p = madd(b[2], r.range(-0.6, 0.6), p);
    p = madd(b[0], r.range(-0.2, 0.2), p);
    let dir = match r.next() % 3 { 0 => b[0], 1 => b[2], _ => norm(madd(b[1], r.range(-0.3, 0.3), unit(r))) };
    let dir = norm(madd(unit(r), r.range(0.0, 0.3), dir));
    let half = r.range(0.3, 2.0);
    Primitive { start: madd(dir, -half, p), end: madd(dir, half, p), owner: r.next() as u64 }
}
fn edges(r: &mut Rng, b: &[V; 4]) -> Vec<Primitive> { (0..1 + r.next() % 4).map(|_| edge_near(r, b)).collect() }
fn graph<const N: usize>(r: &mut Rng, x0: f32, step: f32, lo: f32, hi: f32) -> PointGraph<N> {
    let mut x = [0.0f32; N];
    let mut acc = x0;
    for i in 0..N { x[i] = acc; acc += r.range(step * 0.2, step); }
    PointGraph { x, y: std::array::from_fn(|_| r.range(lo, hi)) }
}
fn prim_l(p: &Primitive) -> Raw { Raw(format!("{{ start = {}, [\"end\"] = {}, owner = {} }}", p.start.l(), p.end.l(), p.owner)) }
fn prims_l(p: &[Primitive]) -> Raw { Raw(format!("{{ {} }}", p.iter().map(|x| prim_l(x).0).collect::<Vec<_>>().join(", "))) }
fn tc_l(t: &Option<TruckContact>) -> Raw { Raw(match t { Some(t) => obj!(position = t.position, primitive = t.primitive), None => "false".into() }) }
fn tcs_l(t: &[Option<TruckContact>; 2]) -> Raw { Raw(format!("{{ {}, {} }}", tc_l(&t[0]).0, tc_l(&t[1]).0)) }
fn ff_l(c: &FiftyFiftyCandidate) -> Raw { Raw(obj!(direction = c.direction, centre = c.centre, front = c.front, rear = c.rear, primitive = c.primitive)) }
fn contact_l(c: &Option<families::Contact>) -> Raw {
    Raw(match c { Some(c) => obj!(some = true, geometry = ff_l(&c.geometry), front = c.front, kind = c.kind, entry_kind = c.entry_kind as u32), None => obj!(some = false) })
}
fn adm_l(a: &Admission) -> Raw { Raw(obj!(category = a.category, state = a.state, speed = a.speed, velocity = a.velocity, threshold_vs_slope = *a.threshold_vs_slope)) }
fn rand_adm<'a>(r: &mut Rng, g: &'a PointGraph<4>) -> Admission<'a> {
    let category = [100u32, 100, 200, 400, 700][(r.next() % 5) as usize];
    let state = [100u32, 400, 401, 402, 403, 404, 405, 701, 201][(r.next() % 9) as usize];
    Admission { category, state, speed: if r.bool() { r.range(0.5, 1.6) } else { r.range(1.0, 8.0) }, velocity: v4(r, 6.0), threshold_vs_slope: g }
}
fn surface(r: &mut Rng) -> GrindSurface {
    let kinds = [GeometryType::ThinRail, GeometryType::FatRail, GeometryType::Ledge, GeometryType::Impossible];
    GrindSurface { center: v4(r, 2.0), far_points: [v4(r, 1.0), v4(r, 1.0)], upmost_normal: if r.bool() { [0.0, 1.0, 0.0, 0.0] } else { unit(r) },
        direction: unit(r), high_side: unit(r), normal_limits: [r.range(0.0, 3.0), r.range(3.0, 6.0)], kind: kinds[(r.next() % 4) as usize],
        audio_surface: r.next() % 20, physics_surface: r.next() % 20, flags: r.next(), tilted_upmost_normal: unit(r) }
}
fn surface_l(s: &GrindSurface) -> Raw {
    Raw(obj!(center = s.center, far_points = s.far_points, upmost_normal = s.upmost_normal, direction = s.direction, high_side = s.high_side, normal_limits = s.normal_limits,
        kind = s.kind as u32, audio_surface = s.audio_surface, physics_surface = s.physics_surface, flags = s.flags, tilted_upmost_normal = s.tilted_upmost_normal))
}
fn entry_kind(r: &mut Rng) -> EntryKind {
    [EntryKind::RideFromAbove, EntryKind::RideFromBelow, EntryKind::RideIntoCoping, EntryKind::StayInGrind, EntryKind::ChangeGrind, EntryKind::AirToGrind, EntryKind::DropIn][(r.next() % 7) as usize]
}
fn bstate_l(s: &BalanceState) -> Raw {
    Raw(obj!(elapsed = s.elapsed, exit_angle_degrees = s.exit_angle_degrees, entry_delay = s.entry_delay, frames_away = s.frames_away, previous_normal = s.previous_normal, exit_direction = s.exit_direction))
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x6c1d_ab31);
    let mut s = format!("-- Сгенерировано golden/src/grind.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");

    // segment_triangle
    s.push_str("\tsegment = {\n");
    for _ in 0..200 {
        let tri = [v4(&mut r, 1.0), v4(&mut r, 1.0), v4(&mut r, 1.0)];
        let (a, b) = if r.next() % 5 == 0 { (tri[0], tri[1]) } else { (v4(&mut r, 1.5), v4(&mut r, 1.5)) };
        let out = segment_triangle(a, b, tri);
        writeln!(s, "\t\t{},", obj!(start = a, finish = b, triangle = tri, some = out.is_some(), out = out)).unwrap();
    }
    s.push_str("\t},\n\tcontacts = {\n");
    for _ in 0..150 {
        let b = board(&mut r);
        let e = edges(&mut r, &b);
        let flags = if r.next() % 5 == 0 { 0x0020_0000 } else { r.next() & 0x0000_ffff };
        let (ttw, dct, above, below) = (r.range(0.05, 0.2), r.range(0.15, 0.3), r.range(0.0, 0.1), r.range(0.0, 0.3));
        let state = [100u32, 402, 404, 401][(r.next() % 4) as usize];
        let f2468 = if r.bool() { 0x200 } else { 0 };
        let trucks = truck_contacts(b, flags, ttw, dct, &e);
        let deck = deck_contact(b, flags, above, below, dct, &e);
        let inv = families::inverted_contact(b, flags, above, below, &e);
        let tips = families::tip_contacts(b, flags, state, f2468, dct, &e);
        writeln!(s, "\t\t{},", obj!(board = b, edges = prims_l(&e), flags = flags, truck_to_wheel = ttw, deck_center_to_truck = dct, above = above, below = below,
            state = state, flags_2468 = f2468, trucks = tcs_l(&trucks), deck = tc_l(&deck), inverted = tc_l(&inv), tips = tcs_l(&tips))).unwrap();
    }
    s.push_str("\t},\n\tupright = {\n");
    for _ in 0..100 {
        let d = if r.next() % 8 == 0 { [0.0, 1.0, 0.0, 0.0] } else { unit(&mut r) };
        let vel = v4(&mut r, 5.0);
        let deg = r.range(0.0, 90.0);
        writeln!(s, "\t\t{},", obj!(direction = d, velocity = vel, degrees = deg, normal = upright_normal(d), within = within_approach_angle(d, vel, deg),
            approach = approach_slope_sine(d, vel), engagement = engagement_slope_sine(d, vel))).unwrap();
    }
    s.push_str("\t},\n\tadmission = {\n");
    for _ in 0..200 {
        let g: PointGraph<4> = graph(&mut r, -1.0, 0.7, 0.0, 2.0);
        let a = rand_adm(&mut r, &g);
        let req = [400u32, 401, 402, 403, 404][(r.next() % 5) as usize];
        let t = unit(&mut r);
        let drop = r.bool();
        let d = a.test(req, t, drop);
        writeln!(s, "\t\t{},", obj!(adm = adm_l(&a), requested = req, tangent = t, drop_in = drop, kind = d.kind as u32, allowed = d.allowed)).unwrap();
    }
    s.push_str("\t},\n\tfamilies = {\n");
    for _ in 0..300 {
        let b = board(&mut r);
        let e = edges(&mut r, &b);
        let g: PointGraph<4> = graph(&mut r, -1.0, 0.7, 0.0, 2.0);
        let a = rand_adm(&mut r, &g);
        let (ttw, dct) = (r.range(0.05, 0.2), r.range(0.15, 0.3));
        let trucks = truck_contacts(b, 0, ttw, dct, &e);
        let tips = families::tip_contacts(b, 0, 100, 0, dct, &e);
        let deck = deck_contact(b, 0, r.range(0.0, 0.1), r.range(0.0, 0.3), dct, &e);
        let inv_board = { let mut ib = b; ib[1] = [-b[1][0], -b[1][1], -b[1][2], 0.0]; ib };
        let inv = families::inverted_contact(b, 0x0020_0000, 0.05, 0.2, &e);
        let vel = a.velocity;
        let (cat, frames, f2476, f2472, gf) = (a.category, r.next() % 20, if r.next() % 6 == 0 { 0x4000_0000 } else { 0 }, if r.bool() { 0x1000 } else { 0 }, r.next() % 60);
        let (tr, nudge, bal) = (r.range(-1.0, 1.0), r.range(-1.0, 1.0), if r.bool() { 0.0 } else { r.range(-1.0, 1.0) });
        let rr = unit(&mut r);
        let slide = deck.and_then(|h| boardslide_candidate(b, h, e[h.primitive], vel, cat, frames as i32, f2476, dct, ttw, &a));
        let ff = fifty_fifty_candidate_on_splines(b, [tr, nudge], trucks, &e);
        let five = families::five_o(b, trucks, &e, vel, f2476, f2472, gf, tr, &a);
        let tip = families::tipslide(b, tips, &e, vel, cat, f2476, f2472, gf, bal, rr, &a);
        let dark = inv.and_then(|h| families::darkslide(inv_board, h, e[h.primitive], vel, cat, frames, &a));
        let fp = [v4(&mut r, 0.5), v4(&mut r, 0.5)];
        let (pt, sup, td, st) = (v4(&mut r, 0.5), unit(&mut r), r.range(0.1, 0.3), [100u32, 402, 404][(r.next() % 3) as usize]);
        let bs = families::is_backslash(b[3], pt, fp, sup, td, st);
        writeln!(s, "\t\t{},", obj!(board = b, inv_board = inv_board, edges = prims_l(&e), adm = adm_l(&a), truck_to_wheel = ttw, deck_center_to_truck = dct,
            trucks = tcs_l(&trucks), tips = tcs_l(&tips), deck = tc_l(&deck), inverted = tc_l(&inv), frames = frames, flags_2476 = f2476, flags_2472 = f2472,
            ground_frames = gf, translation = tr, nudge = nudge, balance = bal, reference_right = rr,
            slide_some = slide.is_some(), slide = slide.as_ref().map(ff_l), ff_some = ff.is_some(), ff = ff.as_ref().map(ff_l),
            five = contact_l(&five), tip = contact_l(&tip), dark = contact_l(&dark),
            bs = Raw(obj!(point = pt, far_points = fp, support = sup, truck_distance = td, state = st, out = bs)))).unwrap();
    }
    s.push_str("\t},\n\tengagement = {\n");
    for _ in 0..40 {
        let help: PointGraph<4> = graph(&mut r, -1.0, 0.7, 0.0, 1.2);
        let mut eng = entry::Engagement::default();
        let mut steps = Vec::new();
        let mut prev = v4(&mut r, 5.0);
        for _ in 0..12 {
            let mut up = if r.bool() { [0.0, 1.0, 0.0, 0.0] } else { unit(&mut r) };
            let dir = norm({ let mut d = unit(&mut r); d[1] *= 0.3; d });
            if r.next() % 4 == 0 { up = dir; }
            let input = entry::Input { valid: r.next() % 5 != 0, kind: r.next() % 7, category: [100u32, 200, 400, 100, 200][(r.next() % 5) as usize],
                previous_state_2504: [701u32, 403, 100][(r.next() % 3) as usize], speed: r.range(0.0, 4.0), balance_2720: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) },
                direction: dir, normal: unit(&mut r), up, board_velocity: v4(&mut r, 9.0), air_velocity: v4(&mut r, 9.0), surface_kind: r.next() % 3,
                high_side: unit(&mut r), vertical_help: &help, max_delta: r.range(0.0, 8.0), flags: r.next(), previous_entry_velocity: prev };
            let out = eng.update(input);
            prev = out.entry_velocity;
            let rej = entry::airborne_rejections(input.direction, input.up, input.board_velocity, input.air_velocity, out.entry_velocity, input.surface_kind, input.high_side, input.max_delta);
            steps.push(obj!(input = Raw(obj!(valid = input.valid, kind = input.kind, category = input.category, previous_state_2504 = input.previous_state_2504, speed = input.speed,
                balance_2720 = input.balance_2720, direction = input.direction, normal = input.normal, up = input.up, board_velocity = input.board_velocity,
                air_velocity = input.air_velocity, surface_kind = input.surface_kind, high_side = input.high_side, max_delta = input.max_delta, flags = input.flags,
                previous_entry_velocity = input.previous_entry_velocity)),
                out = Raw(obj!(valid = out.valid, flags = out.flags, entry_velocity = out.entry_velocity, impact_speed = out.impact_speed, wipeout_reasons = out.wipeout_reasons)),
                frames = eng.tipslide_frames, rejections = rej));
        }
        writeln!(s, "\t\t{{ help = {}, steps = {{ {} }} }},", help.l(), steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tcontrol = {\n");
    for _ in 0..40 {
        let mut c = control::Control::default();
        let mut steps = Vec::new();
        for _ in 0..12 {
            let b = board(&mut r);
            let (kind, normal, front, sw, hb) = ([0u32, 3, 3, 1][(r.next() % 4) as usize], unit(&mut r), r.bool(), r.bool(), r.next() % 3 == 0);
            let (tr, nudge, ud, gmh) = (r.range(-1.0, 1.0), r.range(-1.0, 1.0), if r.next() % 4 == 0 { 0.0 } else { r.range(-1.0, 1.0) }, if r.bool() { 0.0 } else { r.range(-0.3, 0.5) });
            c.update(kind, b[2], normal, front, sw, hb, tr, nudge, ud, gmh);
            let tf = control::truck_frame(b, normal, &c, sw);
            let (dir, pt, bsl) = (unit(&mut r), v4(&mut r, 2.0), r.bool());
            let tip = control::tip_frame(b, dir, normal, pt, bsl);
            steps.push(obj!(board = b, kind = kind, normal = normal, front = front, switched = sw, hanging_back = hb, translation = tr, nudge = nudge, up_down = ud,
                grab_min_height = gmh, yaw = c.yaw, pitch = c.pitch, truck_frame = tf, direction = dir, point = pt, backslash = bsl, tip_frame = tip));
        }
        writeln!(s, "\t\t{{ {} }},", steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tinvestigate = {\n");
    for _ in 0..300 {
        let b = board(&mut r);
        let e = if r.next() % 15 == 0 { Vec::new() } else { edges(&mut r, &b) };
        let g: PointGraph<4> = graph(&mut r, -1.0, 0.7, 0.0, 2.0);
        let a = rand_adm(&mut r, &g);
        let q = Query { board: b, admission: a, flags_2468: if r.bool() { 0x200 } else { 0 }, flags_2472: if r.bool() { 0x1000 } else { 0 },
            flags_2476: if r.next() % 6 == 0 { 0x4000_0000 } else { 0 }, flags_2484: if r.next() % 6 == 0 { 0x0020_0000 } else { 0 },
            tip_state: [100u32, 402, 404][(r.next() % 3) as usize], truck_to_wheel: r.range(0.05, 0.2), deck_to_truck: r.range(0.15, 0.3),
            test_above: r.range(0.0, 0.1), test_below: r.range(0.0, 0.3), translation: r.range(-1.0, 1.0), stability_nudge: r.range(-1.0, 1.0),
            balance: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, reference_right: unit(&mut r), ground_frames: r.next() % 60, low_wheel_frames: r.next() % 20,
            forbidden: r.next() % 8 == 0 };
        let res = investigate(&q, &e);
        let prox = res.proximity.map(|p| Raw(obj!(contact = tc_l(&Some(p.contact)), deck_contact = p.deck_contact)));
        writeln!(s, "\t\t{},", obj!(query = Raw(obj!(board = q.board, admission = adm_l(&q.admission), flags_2468 = q.flags_2468, flags_2472 = q.flags_2472, flags_2476 = q.flags_2476,
            flags_2484 = q.flags_2484, tip_state = q.tip_state, truck_to_wheel = q.truck_to_wheel, deck_to_truck = q.deck_to_truck, test_above = q.test_above,
            test_below = q.test_below, translation = q.translation, stability_nudge = q.stability_nudge, balance = q.balance, reference_right = q.reference_right,
            ground_frames = q.ground_frames, low_wheel_frames = q.low_wheel_frames, forbidden = q.forbidden)), edges = prims_l(&e),
            candidate = contact_l(&res.candidate), has_proximity = prox.is_some(), proximity = prox)).unwrap();
    }
    s.push_str("\t},\n\tmanager = {\n");
    for _ in 0..200 {
        let (st, en, vel, prev) = (v4(&mut r, 2.0), v4(&mut r, 2.0), if r.bool() { v4(&mut r, 0.2) } else { v4(&mut r, 5.0) }, unit(&mut r));
        let dt_out = manager::directed_tangent(st, en, vel, prev);
        let gi = manager::GeometryInput { valid: r.next() % 6 != 0, family: r.next() % 5, current_state: [100u32, 402, 401][(r.next() % 3) as usize],
            category: [100u32, 200, 400][(r.next() % 3) as usize], air_frames: r.next() % 40, geometry_kind: r.next() % 4,
            geometry_flags: [0u32, 0x1000_0000, 0x8000_0000, 0x9000_0000][(r.next() % 4) as usize], far_points: [v4(&mut r, 0.5), v4(&mut r, 0.5)],
            upmost: unit(&mut r), high_side: unit(&mut r), point: v4(&mut r, 0.3), direction: unit(&mut r), board_position: v4(&mut r, 0.5),
            board_forward: unit(&mut r), velocity: v4(&mut r, 6.0), deck_to_truck: r.range(0.1, 0.3), previous_exit_angle: if r.bool() { 0.0 } else { r.range(0.0, 10.0) },
            previous_exit_direction: unit(&mut r), flags: if r.bool() { 0x2000_0000 } else { 0 } | (r.next() & 0x1000_0000) };
        let mut avoid = if r.bool() { 0u32 } else { r.next() % 40 };
        let avoid_in = avoid;
        let go = manager::tweak_geometry(gi, &mut avoid);
        let vg: PointGraph<4> = graph(&mut r, -3.0, 2.0, 0.0, 2.0);
        let lg: PointGraph<4> = graph(&mut r, 0.0, 2.0, 0.0, 1.0);
        let mut timer = if r.bool() { 0.0 } else { r.range(0.0, 1.0) };
        let timer_in = timer;
        let (gv, gc, gt, gvel, gdt) = (r.bool(), [100u32, 200][(r.next() % 2) as usize], unit(&mut r), v4(&mut r, 5.0), r.range(0.0, 0.1));
        let gr = manager::gravity_relief(&mut timer, gv, gc, gt, gvel, gdt, &vg, &lg);
        writeln!(s, "\t\t{},", obj!(start = st, finish = en, velocity = vel, previous = prev, tangent = dt_out,
            gi = Raw(obj!(valid = gi.valid, family = gi.family, current_state = gi.current_state, category = gi.category, air_frames = gi.air_frames,
                geometry_kind = gi.geometry_kind, geometry_flags = gi.geometry_flags, far_points = gi.far_points, upmost = gi.upmost, high_side = gi.high_side,
                point = gi.point, direction = gi.direction, board_position = gi.board_position, board_forward = gi.board_forward, velocity = gi.velocity,
                deck_to_truck = gi.deck_to_truck, previous_exit_angle = gi.previous_exit_angle, previous_exit_direction = gi.previous_exit_direction, flags = gi.flags)),
            avoid_in = avoid_in, avoid = avoid, go = Raw(obj!(valid = go.valid, family = go.family, flags = go.flags)),
            relief = Raw(obj!(timer_in = timer_in, valid = gv, category = gc, tangent = gt, velocity = gvel, dt = gdt, vertical = vg, linear = lg, out = gr, timer = timer)))).unwrap();
    }
    s.push_str("\t},\n\tjumper = {\n");
    for _ in 0..20 {
        let mut j = manager::Jumper::default();
        j.cooldown = r.next() % 4;
        j.energy = r.range(0.9, 1.0);
        let (c0, e0) = (j.cooldown, j.energy);
        let mut steps = Vec::new();
        for _ in 0..10 {
            let geom = if r.bool() { Some(manager::JumpGeometry { geometry_kind: r.next() % 4, high_side: unit(&mut r), normal: unit(&mut r), direction: unit(&mut r), upmost: unit(&mut r), point: v4(&mut r, 2.0) }) } else { None };
            let fam = if r.bool() { u32::MAX } else { r.next() % 6 };
            let out = j.update(geom, fam);
            let gl = geom.map(|g| Raw(obj!(geometry_kind = g.geometry_kind, high_side = g.high_side, normal = g.normal, direction = g.direction, upmost = g.upmost, point = g.point)));
            steps.push(obj!(geometry = gl, family_in = fam, out = out, launched = j.launched, cooldown = j.cooldown, family = j.family, energy = j.energy,
                state_geometry = Raw(obj!(geometry_kind = j.geometry.geometry_kind, high_side = j.geometry.high_side, normal = j.geometry.normal, direction = j.geometry.direction, upmost = j.geometry.upmost, point = j.geometry.point))));
        }
        writeln!(s, "\t\t{{ cooldown = {}, energy = {}, steps = {{ {} }} }},", c0, e0.l(), steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tbalance = {\n");
    for _ in 0..60 {
        let lean: PointGraph<8> = graph(&mut r, 0.0, 0.6, 0.0, 40.0);
        let mut st = BalanceState::default();
        let mut vecs = BalanceVectors { grind_normal: unit(&mut r), target_up: unit(&mut r) };
        let v0 = (vecs.grind_normal, vecs.target_up);
        let mut steps = Vec::new();
        for _ in 0..15 {
            let surf = surface(&mut r);
            let has = r.next() % 4 != 0;
            let (pd, dd, kind, ek) = (unit(&mut r), unit(&mut r), r.next() % 6, entry_kind(&mut r));
            let contact = BalanceContact { surface: &surf, primitive_direction: pd, directed_grind_direction: dd, kind, entry_kind: ek };
            let ti = TargetUpInput { category: [100u32, 200, 400, 400][(r.next() % 4) as usize], previous_state: [400u32, 402, 404, 100][(r.next() % 4) as usize], board_up: if r.next() % 8 == 0 { [0.0, -1.0, 0.0, 0.0] } else { unit(&mut r) } };
            st.update_target_up(ti, if has { Some(&contact) } else { None }, &mut vecs);
            let after_target = (bstate_l(&st), vecs.grind_normal, vecs.target_up);
            let has2 = r.next() % 3 != 0;
            let ei = ExitLeanInput { category: [100u32, 400, 200][(r.next() % 3) as usize], current_state: [100u32, 701, 402][(r.next() % 3) as usize], grind_substate: r.next() % 3, timestep: r.range(0.0, 0.3) };
            let angle = st.update_exit_lean(ei, if has2 { Some(&contact) } else { None }, &lean, &mut vecs);
            let loc = v4(&mut r, 3.0);
            let mut flags = r.next();
            let flags_in = flags;
            let mut calls = Vec::new();
            let fail = r.next() % 10 == 0;
            let hit = if r.bool() { Some(unit(&mut r)) } else { None };
            let res = st.update_force_exit(loc, &mut flags, |p| {
                calls.push(obj!(start = p.start, finish = p.end));
                if fail { return Err("world unavailable".to_string()); }
                Ok(hit.map(|n| ForceExitHit { normal: n }))
            });
            steps.push(obj!(surface = surface_l(&surf), has_contact = has, primitive_direction = pd, directed_grind_direction = dd, kind = kind, entry_kind = ek as u32,
                target_input = Raw(obj!(category = ti.category, previous_state = ti.previous_state, board_up = ti.board_up)),
                after_target = Raw(obj!(state = after_target.0, grind_normal = after_target.1, target_up = after_target.2)),
                has_contact2 = has2, exit_input = Raw(obj!(category = ei.category, current_state = ei.current_state, grind_substate = ei.grind_substate, timestep = ei.timestep)),
                angle = angle, after_exit = Raw(obj!(state = bstate_l(&st), grind_normal = vecs.grind_normal, target_up = vecs.target_up)),
                location = loc, flags_in = flags_in, fail = fail, hit_some = hit.is_some(), hit = hit, calls = Raw(format!("{{ {} }}", calls.join(", "))),
                err = res.err(), flags = flags));
        }
        writeln!(s, "\t\t{{ lean = {}, grind_normal0 = {}, target_up0 = {}, steps = {{ {} }} }},", lean.l(), v0.0.l(), v0.1.l(), steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/grind.luau"), s).unwrap();
}
