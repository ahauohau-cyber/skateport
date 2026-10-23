//! Эталон для physics::grind_forces (кроме post/reckoning) и physics::grind_air.
//! Только синтетические входы — файл можно коммитить.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::air::trajectory::grind_surface::{GeometryType, LandingOrientation};
use skate_core::physics::grind_air::{self, DeckDimensions, GrindAir, PoseInput};
use skate_core::physics::grind_contact::{manager::{JumpGeometry, Jumper}, Primitive};
use skate_core::physics::grind_forces::{
    friction, friction_applies, lateral_pin, launch, material_multiplier, noise, orientation, pin_slope, release, slide, support,
};
use skate_core::point_graph::PointGraph;
use std::fmt::Write as _;

type V = [f32; 4];

fn unit(r: &mut Rng) -> V {
    let v = r.vec(1.0);
    let l = (v.x * v.x + v.y * v.y + v.z * v.z).sqrt().max(1e-3);
    [v.x / l, v.y / l, v.z / l, 0.0]
}
fn v4(r: &mut Rng, span: f32) -> V { let v = r.vec(span); [v.x, v.y, v.z, if r.next() % 4 == 0 { r.range(-1.0, 1.0) } else { 0.0 }] }
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0], 0.0] }
fn norm(a: V) -> V { let l = (a[0] * a[0] + a[1] * a[1] + a[2] * a[2]).sqrt().max(1e-6); [a[0] / l, a[1] / l, a[2] / l, 0.0] }
fn frame(r: &mut Rng) -> [V; 4] {
    let mut up = unit(r);
    if r.bool() { up = norm([up[0] * 0.3, 1.0, up[2] * 0.3, 0.0]); }
    let forward = norm(cross(unit(r), up));
    let right = cross(up, forward);
    [right, up, forward, v4(r, 2.0)]
}
fn graph<const N: usize>(r: &mut Rng, x0: f32, step: f32, lo: f32, hi: f32) -> PointGraph<N> {
    let mut x = [0.0f32; N];
    let mut acc = x0;
    for i in 0..N { x[i] = acc; acc += r.range(step * 0.2, step); }
    PointGraph { x, y: std::array::from_fn(|_| r.range(lo, hi)) }
}
fn orient(r: &mut Rng) -> LandingOrientation {
    LandingOrientation { kind: [GeometryType::ThinRail, GeometryType::FatRail, GeometryType::Ledge, GeometryType::Impossible][(r.next() % 4) as usize],
        garbage: r.bool(), boardslide_dir: unit(r), tipslide_dir: unit(r), backslash_dir: unit(r), high_side: unit(r) }
}
fn orient_l(o: &LandingOrientation) -> Raw {
    Raw(obj!(kind = o.kind as u32, garbage = o.garbage, boardslide_dir = o.boardslide_dir, tipslide_dir = o.tipslide_dir, backslash_dir = o.backslash_dir, high_side = o.high_side))
}
fn jg_l(g: &JumpGeometry) -> Raw { Raw(obj!(geometry_kind = g.geometry_kind, high_side = g.high_side, normal = g.normal, direction = g.direction, upmost = g.upmost, point = g.point)) }
fn jumper_l(j: &Jumper) -> Raw { Raw(obj!(launched = j.launched, cooldown = j.cooldown, family = j.family, energy = j.energy, geometry = jg_l(&j.geometry))) }

pub fn write(out_dir: &str) {
    let mut r = Rng(0x51de_f0c3);
    let mut s = format!("-- Сгенерировано golden/src/gforce.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");

    s.push_str("\tforces = {\n");
    for _ in 0..200 {
        let b = frame(&mut r);
        let (point, across, vel) = (v4(&mut r, 2.0), unit(&mut r), v4(&mut r, 6.0));
        let (st, fo, uo, fs, sm) = (r.range(0.0, 900.0), r.range(-0.3, 0.3), r.range(0.0, 0.1), r.bool(), r.range(0.0, 1.5));
        let pin_point = if r.next() % 10 == 0 { b[3] } else { point };
        let pin = lateral_pin(b, pin_point, across, vel, st, fo, uo, fs, sm);
        let (gn, sup, tm, flag, mat, kind) = (unit(&mut r), v4(&mut r, 1.0), r.range(0.0, 2.0), r.bool(), r.next() % 16, r.next() % 4);
        let strengths = [r.range(0.0, 60.0), r.range(0.0, 60.0), r.range(0.0, 60.0)];
        let fr_vel = if r.next() % 10 == 0 { gn } else { vel };
        let fr = friction(fr_vel, gn, sup, tm, flag, material_multiplier(mat), kind, strengths);
        let pg: PointGraph<4> = graph(&mut r, -1.0, 0.7, 0.0, 1.0);
        let (relief, pitch, angle) = (if r.bool() { 0.0 } else { r.range(0.0, 1.0) }, r.range(-1.0, 1.0), if r.bool() { 0.0 } else { r.range(0.0, 40.0) });
        let lean: PointGraph<4> = graph(&mut r, 0.0, 15.0, 0.0, 1.0);
        writeln!(s, "\t\t{},", obj!(board = b, point = point, across = across, velocity = vel, strength = st, forward_offset = fo, up_offset = uo,
            forward_selected = fs, slope_multiplier = sm, pin_point = pin_point, friction_velocity = fr_vel, pin = pin, pin_some = pin.is_some(),
            grind_normal = gn, support = sup, time_multiplier = tm, flagged = flag, material = mat, material_multiplier = material_multiplier(mat), kind = kind,
            strengths = strengths, friction = fr, friction_applies = friction_applies(vel, gn), pin_graph = pg, relief = relief,
            pin_slope = pin_slope(gn, across, relief, &pg), support_pin = support::pin(gn, relief), support_pin_some = support::pin(gn, relief).is_some(),
            coping = support::coping(across, vel, relief), coping_some = support::coping(across, vel, relief).is_some(),
            exit_angle = angle, lean_graph = lean, exit_lean = support::exit_lean(across, angle, &lean), exit_lean_some = support::exit_lean(across, angle, &lean).is_some(),
            pitch = pitch, truck_compensation = support::truck_compensation(gn, pitch))).unwrap();
    }
    s.push_str("\t},\n\tnoise = {\n");
    for _ in 0..80 {
        let f = frame(&mut r);
        let (speed, amount, samples) = (r.range(0.0, 5.0), r.range(0.0, 2.0), [r.next(), r.next(), r.next()]);
        writeln!(s, "\t\t{},", obj!(frame = f, speed = speed, amount = amount, samples = samples, angles = noise::angles(speed, amount, samples), out = noise::apply(f, speed, amount, samples))).unwrap();
    }
    s.push_str("\t},\n\trelease = {\n");
    for _ in 0..100 {
        let i = release::Input { position: v4(&mut r, 1.0), point: v4(&mut r, 1.0), across: unit(&mut r), normal: unit(&mut r), velocity: v4(&mut r, 3.0),
            geometry_kind: r.next() % 3, high_side: unit(&mut r), force_across: r.bool(), enable_lift: r.bool(), strength: r.range(0.0, 100.0),
            speed_limit: r.range(-1.0, 2.0), lift: r.range(0.0, 150.0) };
        let out = release::force(i);
        writeln!(s, "\t\t{},", obj!(input = Raw(obj!(position = i.position, point = i.point, across = i.across, normal = i.normal, velocity = i.velocity,
            geometry_kind = i.geometry_kind, high_side = i.high_side, force_across = i.force_across, enable_lift = i.enable_lift, strength = i.strength,
            speed_limit = i.speed_limit, lift = i.lift)), some = out.is_some(), out = out)).unwrap();
    }
    s.push_str("\t},\n\tslide = {\n");
    for _ in 0..120 {
        let i = slide::Input { position: v4(&mut r, 0.3), point: v4(&mut r, 0.3), direction: unit(&mut r), across: unit(&mut r), velocity: v4(&mut r, 4.0),
            translation_2796: r.range(-1.0, 1.0), total_mass_2660: r.range(1.0, 80.0), update_frequency: [30.0f32, 60.0][(r.next() % 2) as usize],
            preparing_jump: r.next() % 5 == 0, geometry_kind: r.next() % 3 };
        let kind = if r.bool() { slide::Slide::Boardslide } else { slide::Slide::Darkslide };
        let out = slide::control(kind, i);
        writeln!(s, "\t\t{},", obj!(kind = if kind == slide::Slide::Boardslide { "Boardslide" } else { "Darkslide" }, input = Raw(obj!(position = i.position, point = i.point,
            direction = i.direction, across = i.across, velocity = i.velocity, translation_2796 = i.translation_2796, total_mass_2660 = i.total_mass_2660,
            update_frequency = i.update_frequency, preparing_jump = i.preparing_jump, geometry_kind = i.geometry_kind)), out = out)).unwrap();
    }
    s.push_str("\t},\n\tlaunch = {\n");
    for _ in 0..120 {
        let mut j = Jumper::default();
        j.family = r.next() % 6;
        j.cooldown = r.next() % 5;
        j.energy = if r.bool() { r.range(0.0, 0.31) } else { r.range(0.3, 1.0) };
        j.geometry = JumpGeometry { geometry_kind: r.next() % 3, high_side: unit(&mut r), normal: unit(&mut r), direction: unit(&mut r), upmost: unit(&mut r), point: v4(&mut r, 1.0) };
        let i = launch::Input { velocity_400: v4(&mut r, 6.0), position_112: v4(&mut r, 1.0), current_point_1120: v4(&mut r, 1.0),
            balance_2800: [0.0, r.range(-1.0, 1.0), -0.42, 0.42, r.range(-0.5, 0.5)][(r.next() % 5) as usize], geometry_side_jump: r.range(-2.0, 2.0), vertical_jump: r.range(0.0, 6.0) };
        let out = launch::launch(j, i);
        writeln!(s, "\t\t{},", obj!(jumper = jumper_l(&j), input = Raw(obj!(velocity_400 = i.velocity_400, position_112 = i.position_112, current_point_1120 = i.current_point_1120,
            balance_2800 = i.balance_2800, geometry_side_jump = i.geometry_side_jump, vertical_jump = i.vertical_jump)),
            out = Raw(obj!(velocity = out.velocity, jumper = jumper_l(&out.jumper), flags_2476_to_or = out.flags_2476_to_or)))).unwrap();
    }
    s.push_str("\t},\n\torientation = {\n");
    for _ in 0..150 {
        let i = orientation::Input { board: frame(&mut r), direction: unit(&mut r), normal: unit(&mut r), point: v4(&mut r, 1.0),
            yaw_1504: if r.next() % 4 == 0 { 0.0 } else { r.range(-1.0, 1.0) }, pitch_1508: if r.next() % 4 == 0 { 0.0 } else { r.range(-1.0, 1.0) }, switched: r.bool() };
        let family = r.next() % 7;
        let out = orientation::target(family, i);
        let cur = frame(&mut r);
        let out_l = match &out { Ok(t) => obj!(frame = t.frame, noise_amount = t.noise_amount), Err(e) => obj!(err = *e) };
        let blend = out.as_ref().ok().map(|t| orientation::blend(cur, t.frame));
        writeln!(s, "\t\t{},", obj!(family = family, input = Raw(obj!(board = i.board, direction = i.direction, normal = i.normal, point = i.point,
            yaw_1504 = i.yaw_1504, pitch_1508 = i.pitch_1508, switched = i.switched)), out = Raw(out_l), current = cur, blend = blend)).unwrap();
    }
    s.push_str("\t},\n\tgrind_air = {\n");
    for case in 0..60 {
        let dims = DeckDimensions { middle_length: r.range(0.4, 0.6), front_end_size: r.range(0.1, 0.2), front_end_angle_degrees: r.range(10.0, 30.0),
            truck_z_front: r.range(-0.1, 0.0), truck_y: r.range(-0.1, -0.05) };
        let tip = r.range(0.0, 1.0);
        let settings = grind_air::Settings { frames: if case % 17 == 3 { 13 } else { 6 + (r.next() % 7) as usize }, stomp: r.range(0.0, 20.0), points: dims.contact_points(tip),
            ranges: std::array::from_fn(|_| r.range(20.0, 95.0)), distances: std::array::from_fn(|_| r.range(0.3, 3.0)), yaw_assist: std::array::from_fn(|_| r.range(0.0, 2.0)),
            max_offset: r.range(0.1, 1.0), max_delta: r.range(0.01, 0.3), max_angle: r.range(1.0, 20.0) };
        let rail_dir = norm([r.range(-1.0, 1.0), r.range(-0.2, 0.2), r.range(-1.0, 1.0), 0.0]);
        let rail_p = v4(&mut r, 1.0);
        let edge = Primitive { start: [rail_p[0] - rail_dir[0] * 3.0, rail_p[1] - rail_dir[1] * 3.0, rail_p[2] - rail_dir[2] * 3.0, 0.0],
            end: [rail_p[0] + rail_dir[0] * 3.0, rail_p[1] + rail_dir[1] * 3.0, rail_p[2] + rail_dir[2] * 3.0, 0.0], owner: 3 };
        let target = grind_air::Target { edge, primitive_flags: r.next(), orientation: orient(&mut r) };
        let mut ga = GrindAir::default();
        let start = r.next() % 6 != 0;
        if start { ga.start(target); }
        let mut steps = Vec::new();
        let mut b = frame(&mut r);
        b[3] = [rail_p[0] + r.range(-0.3, 0.3), rail_p[1] + r.range(0.3, 1.2), rail_p[2] + r.range(-0.3, 0.3), 0.0];
        if r.bool() { b[2] = norm([rail_dir[0] + r.range(-0.3, 0.3), 0.0, rail_dir[2] + r.range(-0.3, 0.3), 0.0]); b[1] = [0.0, 1.0, 0.0, 0.0]; b[0] = cross(b[1], b[2]); }
        for _ in 0..8 {
            let input = grind_air::Input { active: r.next() % 8 != 0, board: b, velocity: [r.range(-1.0, 1.0), r.range(-5.0, -1.0), r.range(-1.0, 1.0), 0.0],
                angular_velocity: if r.bool() { [0.0; 4] } else { v4(&mut r, 3.0) }, up: if r.bool() { [0.0, 1.0, 0.0, 0.0] } else { unit(&mut r) }, timestep: 1.0 / 30.0,
                flags_2468: if r.next() % 10 == 0 { 8 } else { 0 }, flags_2472: if r.next() % 10 == 0 { 0x8000 } else { 0 }, flags_2480: if r.next() % 10 == 0 { 0x0400_0000 } else { 0 },
                flags_2484: if r.next() % 4 == 0 { 0x0020_0000 } else { 0 } };
            let out = ga.update(input, &settings);
            let pose_in = PoseInput { animation_to_world: frame(&mut r), world_to_animation: frame(&mut r), physical_forward: unit(&mut r), animation_board_position: v4(&mut r, 2.0) };
            let (out_l, local) = match &out {
                Ok(Some(a)) => (obj!(some = true, axis = a.axis, offset = a.offset, angles = a.angles), Some(a.local_transform(pose_in))),
                Ok(None) => (obj!(some = false), None),
                Err(e) => (obj!(err = e.clone()), None),
            };
            steps.push(obj!(input = Raw(obj!(active = input.active, board = input.board, velocity = input.velocity, angular_velocity = input.angular_velocity, up = input.up,
                timestep = input.timestep, flags_2468 = input.flags_2468, flags_2472 = input.flags_2472, flags_2480 = input.flags_2480, flags_2484 = input.flags_2484)),
                out = Raw(out_l), pose = Raw(obj!(animation_to_world = pose_in.animation_to_world, world_to_animation = pose_in.world_to_animation,
                    physical_forward = pose_in.physical_forward, animation_board_position = pose_in.animation_board_position)), local_transform = local));
            b[3] = [b[3][0], b[3][1] - r.range(0.0, 0.15), b[3][2], 0.0];
        }
        writeln!(s, "\t\t{{ dims = {}, tip = {}, points = {}, settings = {}, target = {}, started = {}, steps = {{ {} }} }},",
            obj!(middle_length = dims.middle_length, front_end_size = dims.front_end_size, front_end_angle_degrees = dims.front_end_angle_degrees, truck_z_front = dims.truck_z_front, truck_y = dims.truck_y),
            tip.l(), dims.contact_points(tip).l(),
            obj!(frames = settings.frames, stomp = settings.stomp, points = settings.points, ranges = settings.ranges, distances = settings.distances,
                yaw_assist = settings.yaw_assist, max_offset = settings.max_offset, max_delta = settings.max_delta, max_angle = settings.max_angle),
            obj!(edge = Raw(format!("{{ start = {}, [\"end\"] = {}, owner = 3 }}", edge.start.l(), edge.end.l())), primitive_flags = target.primitive_flags, orientation = orient_l(&target.orientation)),
            start, steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/gforce.luau"), s).unwrap();
}
