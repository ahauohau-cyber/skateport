//! Эталон для air::trajectory: query_trajectory, TrajectorySelector (launch +
//! scoring + selector), grind_surface (prepare/investigate/resolve/landing) и
//! grind (box filter, plane time, candidates, admission). Только синтетические
//! входы — файл можно коммитить. Колбэки мира записываются и воспроизводятся.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::air::trajectory::{
    grind::{
        admitted_displacement, apply_admitted_target, consider_grind_primitive, descending_plane_time,
        take_best_grind, trajectory_box_filter, GrindAssistLimits, GrindEvaluation, GrindSurfaceEvidence,
        GrindTarget, GrindTrajectoryCandidate,
    },
    grind_surface::{self, GeometryType, GrindSurface, InvestigationInput, LandingOrientation, Probe, ProbeHit},
    query_trajectory, LaunchInfo, Prediction, QueryRequest, QueryResult, SelectorInput, SelectorSettings,
    SurfaceHit, Trajectory, TrajectorySelector,
};
use skate_core::physics::grind_contact::Primitive;
use skate_core::point_graph::PointGraph;
use std::cell::RefCell;
use std::fmt::Write as _;

type V = [f32; 4];

fn v4(r: &mut Rng, span: f32) -> V { let v = r.vec(span); [v.x, v.y, v.z, if r.bool() { 0.0 } else { r.range(-span, span) }] }
fn unit(r: &mut Rng) -> V {
    let v = r.vec(1.0);
    let l = (v.x * v.x + v.y * v.y + v.z * v.z).sqrt().max(1e-3);
    [v.x / l, v.y / l, v.z / l, 0.0]
}
fn graph<const N: usize>(r: &mut Rng, x0: f32, step: f32, lo: f32, hi: f32) -> PointGraph<N> {
    let mut x = [0.0f32; N];
    let mut acc = x0;
    for i in 0..N { x[i] = acc; acc += r.range(step * 0.2, step); }
    PointGraph { x, y: std::array::from_fn(|_| r.range(lo, hi)) }
}

fn traj_l(t: &Trajectory) -> Raw { Raw(obj!(position = t.position, velocity = t.velocity, acceleration = t.acceleration, duration = t.duration)) }
fn req_l(q: &QueryRequest) -> Raw { Raw(obj!(trajectory = traj_l(&q.trajectory), radius = q.radius, start_error = q.start_error, end_error = q.end_error)) }
fn res_l(q: &QueryResult) -> Raw {
    Raw(obj!(contact_position = q.contact_position, contact_normal = q.contact_normal, landing_normal = q.landing_normal, contact_time = q.contact_time,
        contact_transform = q.contact_transform, contact_frame = q.contact_frame, surface = q.surface, geometry = q.geometry))
}
fn pred_l(p: &Prediction) -> Raw { Raw(obj!(result = res_l(&p.result), request = req_l(&p.request))) }
fn hit_l(h: &Option<SurfaceHit>) -> Raw {
    Raw(match h { Some(h) => obj!(some = true, position = h.position, normal = h.normal, transform = h.transform, surface = h.surface, geometry = h.geometry), None => obj!(some = false) })
}
fn orient_l(o: &LandingOrientation) -> Raw {
    Raw(obj!(kind = o.kind as u32, garbage = o.garbage, boardslide_dir = o.boardslide_dir, tipslide_dir = o.tipslide_dir, backslash_dir = o.backslash_dir, high_side = o.high_side))
}
fn prim_l(p: &Primitive) -> Raw { Raw(format!("{{ start = {}, [\"end\"] = {}, owner = {} }}", p.start.l(), p.end.l(), p.owner)) }
fn target_l(t: &GrindTarget) -> Raw {
    Raw(obj!(edge = prim_l(&t.edge), provider_index = t.provider_index, primitive_flags = t.primitive_flags, orientation = orient_l(&t.orientation), point = t.point, vertical_normal = t.vertical_normal))
}
fn eval_l(e: &GrindEvaluation) -> Raw {
    Raw(obj!(has_target = e.target.is_some(), target = e.target.as_ref().map(target_l), score = e.score, distance = e.distance,
        has_lock = e.effective_lock_distance.is_some(), effective_lock_distance = e.effective_lock_distance, penalty_domain = e.penalty_domain))
}
fn cand_l(c: &GrindTrajectoryCandidate) -> Raw {
    Raw(obj!(point = c.point, trajectory_point = c.trajectory_point, direction = c.direction, approach = c.approach, distance = c.distance, time = c.time, angle = c.angle, frame = c.frame, primitive = c.primitive))
}
fn surface_l(s: &GrindSurface) -> Raw {
    Raw(obj!(center = s.center, far_points = s.far_points, upmost_normal = s.upmost_normal, direction = s.direction, high_side = s.high_side, normal_limits = s.normal_limits,
        kind = s.kind as u32, audio_surface = s.audio_surface, physics_surface = s.physics_surface, flags = s.flags, tilted_upmost_normal = s.tilted_upmost_normal))
}
fn probe_l(p: &Probe) -> Raw { Raw(format!("{{ start = {}, [\"end\"] = {}, radius = {} }}", p.start.l(), p.end.l(), p.radius.l())) }

fn settings(r: &mut Rng) -> SelectorSettings {
    SelectorSettings {
        cone_x: r.range(5.0, 30.0), cone_z: r.range(5.0, 30.0),
        trajectory_max_time: r.range(1.0, 3.0), trajectory_max_drop: r.range(3.0, 20.0),
        trajectory_error_start: r.range(0.5, 2.0), trajectory_error_end: r.range(1.0, 4.0),
        speed_factor_min: r.range(1.0, 5.0), speed_factor_max: r.range(6.0, 15.0),
        cone_angle_z_vs_speed: graph(r, 0.0, 0.3, 0.2, 1.2),
        cone_x_second_pass: r.range(2.0, 15.0), cone_z_second_pass: r.range(2.0, 15.0),
        landing_time_bonus: graph(r, 0.0, 0.3, -5.0, 10.0),
        landing_com_scalar_vs_slope: graph(r, -1.0, 0.3, 0.0, 1.5),
        landing_force_scalar: graph(r, 0.0, 2.0, 0.0, 1.5),
        grind_penalty_vs_distance: graph(r, 0.0, 0.3, -20.0, 5.0),
        score_middle_bonus: r.range(0.0, 50.0), score_landing_force: r.range(-5.0, 5.0),
        score_landing_direction: r.range(-20.0, 0.0), score_transition: r.range(-50.0, 50.0),
        surface_unrideable_score: r.range(-500.0, 0.0), surface_dont_align_score: r.range(-100.0, 0.0),
        natural_air_off_verts_scalar: r.range(0.0, 1.0),
        minimum_valid_time: r.range(0.0, 0.3), minimum_time_after_apex: r.range(0.0, 0.5),
        minimum_normal_delta_second_pass: r.range(0.0, 0.6), maximum_trajectory_adjust: r.range(0.5, 10.0),
        wall_ride_test_distance: r.range(0.1, 1.0), wall_ride_minimum_height: r.range(0.0, 3.0),
        wall_ride_angle_allow_landing: r.range(-1.0, 20.0), wall_ride_height_score: if r.bool() { r.range(0.0, 50.0) } else { r.range(400.0, 900.0) },
        wall_ride_boost: graph(r, 0.0, 2.0, 0.0, 5.0), wall_ride_normal_dot_limit: if r.bool() { 1.0 } else { r.range(-0.5, 0.5) },
        displacement_vs_speed: graph(r, -1.0, 0.5, 0.0, 1.0), displacement_vs_ground_normal: graph(r, 0.0, 0.15, 0.0, 1.0),
        trajectory_radius: r.range(0.1, 0.5), trajectory_displacement: r.range(0.0, 1.0),
        minimum_trajectory_frames: (r.next() % 6) as i32,
        vert_jump_align_factor: r.range(0.0, 1.0), vert_jump_align_max_ground_normal_y: r.range(0.3, 1.0),
        vert_jump_align_min_direction_y: r.range(-0.5, 0.9), vert_jump_align_max_angle: r.range(0.0, 1.0),
    }
}
fn settings_l(s: &SelectorSettings) -> Raw {
    Raw(obj!(cone_x = s.cone_x, cone_z = s.cone_z, trajectory_max_time = s.trajectory_max_time, trajectory_max_drop = s.trajectory_max_drop,
        trajectory_error_start = s.trajectory_error_start, trajectory_error_end = s.trajectory_error_end, speed_factor_min = s.speed_factor_min,
        speed_factor_max = s.speed_factor_max, cone_angle_z_vs_speed = s.cone_angle_z_vs_speed, cone_x_second_pass = s.cone_x_second_pass,
        cone_z_second_pass = s.cone_z_second_pass, landing_time_bonus = s.landing_time_bonus, landing_com_scalar_vs_slope = s.landing_com_scalar_vs_slope,
        landing_force_scalar = s.landing_force_scalar, grind_penalty_vs_distance = s.grind_penalty_vs_distance, score_middle_bonus = s.score_middle_bonus,
        score_landing_force = s.score_landing_force, score_landing_direction = s.score_landing_direction, score_transition = s.score_transition,
        surface_unrideable_score = s.surface_unrideable_score, surface_dont_align_score = s.surface_dont_align_score,
        natural_air_off_verts_scalar = s.natural_air_off_verts_scalar, minimum_valid_time = s.minimum_valid_time,
        minimum_time_after_apex = s.minimum_time_after_apex, minimum_normal_delta_second_pass = s.minimum_normal_delta_second_pass,
        maximum_trajectory_adjust = s.maximum_trajectory_adjust, wall_ride_test_distance = s.wall_ride_test_distance,
        wall_ride_minimum_height = s.wall_ride_minimum_height, wall_ride_angle_allow_landing = s.wall_ride_angle_allow_landing,
        wall_ride_height_score = s.wall_ride_height_score, wall_ride_boost = s.wall_ride_boost, wall_ride_normal_dot_limit = s.wall_ride_normal_dot_limit,
        displacement_vs_speed = s.displacement_vs_speed, displacement_vs_ground_normal = s.displacement_vs_ground_normal,
        trajectory_radius = s.trajectory_radius, trajectory_displacement = s.trajectory_displacement, minimum_trajectory_frames = s.minimum_trajectory_frames,
        vert_jump_align_factor = s.vert_jump_align_factor, vert_jump_align_max_ground_normal_y = s.vert_jump_align_max_ground_normal_y,
        vert_jump_align_min_direction_y = s.vert_jump_align_min_direction_y, vert_jump_align_max_angle = s.vert_jump_align_max_angle))
}
fn sel_input(r: &mut Rng) -> SelectorInput {
    let mut gn = unit(r);
    if r.bool() { gn[1] = gn[1].abs(); }
    SelectorInput {
        gravity: [0.0, if r.next() % 8 == 0 { r.range(-1e-4, 1.0) } else { r.range(-12.0, -6.0) }, 0.0, 0.0],
        ground_normal: gn,
        contact_position: v4(r, 2.0), heading_direction: unit(r), reference_up: unit(r),
        board_vertical_velocity: r.range(-5.0, 10.0), directional_input: r.range(-1.0, 1.5),
        previous_physics_state: if r.bool() { 200 } else { r.next() % 300 },
        flags_2472: r.next() & 0x3000_0000, flags_2476: if r.next() % 2 == 0 { 0x0200_0000 } else { 0 },
        offboard_flags_1776: r.next() & 0x0c00_0000, grind_lock_distance: r.range(0.0, 1.0),
    }
}
fn input_l(i: &SelectorInput) -> Raw {
    Raw(obj!(gravity = i.gravity, ground_normal = i.ground_normal, contact_position = i.contact_position, heading_direction = i.heading_direction,
        reference_up = i.reference_up, board_vertical_velocity = i.board_vertical_velocity, directional_input = i.directional_input,
        previous_physics_state = i.previous_physics_state, flags_2472 = i.flags_2472, flags_2476 = i.flags_2476,
        offboard_flags_1776 = i.offboard_flags_1776, grind_lock_distance = i.grind_lock_distance))
}
fn transform(r: &mut Rng) -> [V; 4] { [unit(r), unit(r), unit(r), v4(r, 3.0)] }
fn launch_info(r: &mut Rng) -> LaunchInfo {
    LaunchInfo {
        reckoning_transform: transform(r), reckoning_inverse: transform(r),
        start_velocity: { let mut v = v4(r, 8.0); v[1] = r.range(-2.0, 9.0); v },
        com_velocity: v4(r, 8.0), skeleton_vector_160: v4(r, 1.0), skeleton_vector_176: v4(r, 1.0),
        board_position: v4(r, 3.0), animation_com_position: v4(r, 3.0),
        start_position_override: v4(r, 3.0), board_position_override: v4(r, 3.0),
        cone_angle_x: r.range(0.0, 30.0), cone_angle_z: r.range(0.0, 30.0), timestep: r.range(0.0, 0.05),
        player_jumped: r.bool(), use_position_override: r.next() % 4 == 0,
        trajectory_count: [1u16, 7, 7, 3, 9][(r.next() % 5) as usize],
    }
}
fn info_l(i: &LaunchInfo) -> Raw {
    Raw(obj!(reckoning_transform = i.reckoning_transform, reckoning_inverse = i.reckoning_inverse, start_velocity = i.start_velocity,
        com_velocity = i.com_velocity, skeleton_vector_160 = i.skeleton_vector_160, skeleton_vector_176 = i.skeleton_vector_176,
        board_position = i.board_position, animation_com_position = i.animation_com_position, start_position_override = i.start_position_override,
        board_position_override = i.board_position_override, cone_angle_x = i.cone_angle_x, cone_angle_z = i.cone_angle_z, timestep = i.timestep,
        player_jumped = i.player_jumped, use_position_override = i.use_position_override, trajectory_count = i.trajectory_count as u32))
}
fn orientation(r: &mut Rng) -> LandingOrientation {
    LandingOrientation { kind: [GeometryType::ThinRail, GeometryType::FatRail, GeometryType::Ledge, GeometryType::Impossible][(r.next() % 4) as usize],
        garbage: r.bool(), boardslide_dir: unit(r), tipslide_dir: unit(r), backslash_dir: unit(r), high_side: unit(r) }
}
fn primitive(r: &mut Rng) -> Primitive { Primitive { start: v4(r, 3.0), end: v4(r, 3.0), owner: r.next() as u64 } }
fn target(r: &mut Rng) -> GrindTarget {
    GrindTarget { edge: primitive(r), provider_index: (r.next() % 5) as usize, primitive_flags: r.next(), orientation: orientation(r), point: v4(r, 3.0), vertical_normal: unit(r) }
}
fn gcand(r: &mut Rng) -> GrindTrajectoryCandidate {
    GrindTrajectoryCandidate { point: v4(r, 3.0), trajectory_point: v4(r, 3.0), direction: unit(r), approach: unit(r), distance: r.range(0.0, 1.0),
        time: r.range(0.05, 1.5), angle: r.range(0.0, 1.6), frame: (r.next() % 40) as i32 - 3, primitive: (r.next() % 9) as usize }
}
fn result(r: &mut Rng) -> QueryResult {
    if r.next() % 4 == 0 { return QueryResult::miss(); }
    let mut n = unit(r);
    match r.next() % 3 { 0 => n[1] = n[1].abs() + 0.5, 1 => n[1] *= 0.2, _ => {} }
    let cat = [0u32, 0, 3, 6, 7, 8][(r.next() % 6) as usize];
    QueryResult { contact_position: v4(r, 5.0), contact_normal: unit(r), landing_normal: n, contact_time: r.range(0.0, 1.5),
        contact_transform: transform(r), contact_frame: (r.next() % 40) as i32, surface: (cat << 7) | (r.next() & 0x7f), geometry: r.next() % 100 }
}
fn limits(r: &mut Rng) -> GrindAssistLimits {
    GrindAssistLimits { lock_distance: r.range(0.0, 1.0), max_speed_squared_ledge: r.range(0.0, 50.0), max_speed_squared_rail: r.range(0.0, 50.0),
        max_downward_speed: r.range(0.0, 8.0), ledge_scalars: std::array::from_fn(|_| r.range(0.0, 2.0)), tip_scalar: r.range(0.0, 1.0),
        maximum_adjust_angle: r.range(0.0, 60.0), deck_dimensions: [r.range(0.1, 0.3), r.range(0.6, 0.9)] }
}
fn limits_l(l: &GrindAssistLimits) -> Raw {
    Raw(obj!(lock_distance = l.lock_distance, max_speed_squared_ledge = l.max_speed_squared_ledge, max_speed_squared_rail = l.max_speed_squared_rail,
        max_downward_speed = l.max_downward_speed, ledge_scalars = l.ledge_scalars, tip_scalar = l.tip_scalar, maximum_adjust_angle = l.maximum_adjust_angle,
        deck_dimensions = l.deck_dimensions))
}
fn falling_prediction(r: &mut Rng) -> Prediction {
    let t = Trajectory { position: [r.range(-2.0, 2.0), r.range(1.0, 4.0), r.range(-2.0, 2.0), 0.0], velocity: { let mut v = v4(r, 5.0); v[1] = r.range(-2.0, 6.0); v },
        acceleration: [0.0, r.range(-12.0, -6.0), 0.0, 0.0], duration: r.range(0.5, 3.0) };
    let mut res = result(r);
    res.contact_time = r.range(0.0, 1.5);
    Prediction { request: QueryRequest { trajectory: t, radius: r.range(0.1, 0.5), start_error: r.range(0.5, 2.0), end_error: r.range(1.0, 4.0) }, result: res }
}

fn selector_state(sel: &TrajectorySelector) -> String {
    let selection = sel.selection().map(|x| Raw(obj!(candidate_index = x.candidate_index, prediction = pred_l(&x.prediction), start_velocity = x.start_velocity,
        landing_normal = x.landing_normal, collision_velocity = x.collision_velocity, collision_position = x.collision_position,
        com_trajectory = traj_l(&x.com_trajectory), surface_category = x.surface_category, wall_ride = x.wall_ride,
        has_grind = x.grind.is_some(), grind = x.grind.as_ref().map(target_l))));
    obj!(pending = sel.pending(), valid = sel.valid(), just_changed = sel.just_changed(), all_predictions_missed = sel.all_predictions_missed(),
        has_suggested = sel.suggested_normal().is_some(), suggested_normal = sel.suggested_normal(), has_selection = selection.is_some(), selection = selection,
        has_selected_index = sel.selected_index().is_some(), selected_index = sel.selected_index(), grind_locked_to_middle = sel.grind_locked_to_middle(),
        has_grind_normal = sel.grind_normal().is_some(), grind_normal = sel.grind_normal(), launch_info = sel.launch_info().map(info_l),
        requests = sel.requests().iter().map(req_l).collect::<Vec<_>>(), com_displacement = sel.com_displacement(), local_com_position = sel.local_com_position(),
        local_board_position = sel.local_board_position(), board_position = sel.board_position(), query_origin = sel.query_origin())
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x7a1e_c70f);
    let mut s = format!("-- Сгенерировано golden/src/traj.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");

    // --- query_trajectory
    s.push_str("\tquery = {\n");
    for _ in 0..60 {
        let gy = match r.next() % 6 { 0 => r.range(-1e-4, 1e-4), 1 => r.range(0.0, 3.0), _ => r.range(-12.0, -4.0) };
        let request = QueryRequest {
            trajectory: Trajectory { position: v4(&mut r, 2.0), velocity: v4(&mut r, 6.0), acceleration: [r.range(-0.5, 0.5), gy, r.range(-0.5, 0.5), 0.0], duration: r.range(0.2, 3.0) },
            radius: r.range(0.1, 0.5), start_error: r.range(0.3, 2.0), end_error: r.range(0.5, 4.0),
        };
        let floor = r.range(-6.0, 1.0);
        let fail = r.next() % 15 == 0;
        let rl = RefCell::new(Rng(r.next() as u64 + 1));
        let lines = RefCell::new(Vec::new());
        let nearby = RefCell::new(Vec::new());
        let out = query_trajectory(request,
            |a, b, radius| {
                let mut rr = rl.borrow_mut();
                let hit = if b[1] < floor || rr.next() % 13 == 0 {
                    Some(SurfaceHit { position: [b[0], floor.max(b[1]), b[2], 0.0], normal: unit(&mut rr), transform: transform(&mut rr), surface: rr.next(), geometry: rr.next() % 50 })
                } else { None };
                lines.borrow_mut().push(obj!(start = a, finish = b, radius = radius, hit = hit_l(&hit)));
                if fail && lines.borrow().len() > 2 { return Err("line failed".to_string()); }
                Ok(hit)
            },
            |p, radius| {
                let mut rr = rl.borrow_mut();
                let n = [0usize, 1, 3, 10, 70][(rr.next() % 5) as usize];
                let tris: Vec<[V; 3]> = (0..n).map(|_| {
                    let a = v4(&mut rr, 1.0);
                    let up = rr.bool();
                    let b = [a[0] + rr.range(0.1, 1.0), a[1] + if up { 0.0 } else { rr.range(-1.0, 1.0) }, a[2], a[3]];
                    let c = [a[0], a[1] + if up { 0.0 } else { rr.range(-1.0, 1.0) }, a[2] - rr.range(0.1, 1.0), a[3]];
                    [a, b, c]
                }).collect();
                nearby.borrow_mut().push(obj!(position = p, radius = radius, triangles = tris.clone()));
                Ok::<_, String>(tris)
            });
        let out = match out { Ok(q) => obj!(ok = res_l(&q)), Err(e) => obj!(err = e) };
        writeln!(s, "\t\t{{ request = {}, lines = {{ {} }}, nearby = {{ {} }}, out = {} }},", req_l(&request).0, lines.borrow().join(", "), nearby.borrow().join(", "), out).unwrap();
    }
    s.push_str("\t},\n");

    // --- selector
    s.push_str("\tselector = {\n");
    for case in 0..120 {
        let st = settings(&mut r);
        let input = sel_input(&mut r);
        let mut info = launch_info(&mut r);
        if case % 23 == 5 { info.trajectory_count = 0; }
        let mut sel = TrajectorySelector::new();
        let mut steps = Vec::new();
        for step in 0..5 {
            let action = if step == 0 { 0 } else { [1u32, 1, 1, 0, 2, 3, 4][(r.next() % 7) as usize] };
            match action {
                0 => {
                    let mut li = info;
                    if step > 0 { li = launch_info(&mut r); }
                    let res = sel.launch(li, input, &st);
                    steps.push(obj!(action = "launch", info = info_l(&li), out = Raw(match res { Ok(b) => obj!(ok = b), Err(e) => obj!(err = e) }), state = Raw(selector_state(&sel))));
                }
                1 => {
                    let mut results: Vec<QueryResult> = sel.requests().iter().map(|_| result(&mut r)).collect();
                    if r.next() % 30 == 0 { results.push(QueryResult::miss()); }
                    let rg = RefCell::new(Rng(r.next() as u64 + 7));
                    let rl = RefCell::new(Rng(r.next() as u64 + 9));
                    let fail = r.next() % 25 == 0;
                    let grinds = RefCell::new(Vec::new());
                    let lines = RefCell::new(Vec::new());
                    let res = sel.complete_batch(&results, input, &st,
                        |p, middle| {
                            let mut rr = rg.borrow_mut();
                            let before = pred_l(p);
                            let mutation = if rr.next() % 3 == 0 {
                                let c = gcand(&mut rr);
                                let (corr, sup, refv) = (v4(&mut rr, 1.0), unit(&mut rr), v4(&mut rr, 5.0));
                                let (ma, ls, lm) = (rr.range(0.5, 5.0), rr.range(0.0, 1.0), rr.range(0.0, 60.0));
                                apply_admitted_target(p, c, corr, sup, refv, ma, ls, lm);
                                Raw(obj!(candidate = cand_l(&c), correction = corr, support = sup, reference_velocity = refv, maximum_adjust = ma, landing_velocity_scalar = ls, landing_max_angle = lm))
                            } else { Raw("nil".into()) };
                            let e = GrindEvaluation {
                                target: if rr.next() % 3 == 0 { Some(target(&mut rr)) } else { None },
                                score: [0.0, 0.0, 2.5, -0.5, 0.75][(rr.next() % 5) as usize],
                                distance: rr.range(0.0, 2.0),
                                effective_lock_distance: if rr.bool() { Some(rr.range(0.0, 1.0)) } else { None },
                                penalty_domain: rr.range(0.0, 2.0),
                            };
                            grinds.borrow_mut().push(obj!(before = before, middle = middle, mutation = mutation, eval = eval_l(&e)));
                            Ok(e)
                        },
                        |a, b, radius| {
                            let mut rr = rl.borrow_mut();
                            let hit = if rr.next() % 3 != 0 {
                                let mut n = unit(&mut rr);
                                if rr.bool() { n[1] = n[1].abs(); }
                                Some(SurfaceHit { position: [a[0], a[1] - rr.range(0.0, 8.0), a[2], 0.0], normal: n, transform: transform(&mut rr), surface: rr.next(), geometry: rr.next() % 50 })
                            } else { None };
                            lines.borrow_mut().push(obj!(start = a, finish = b, radius = radius, hit = hit_l(&hit)));
                            if fail { return Err("wall line failed".to_string()); }
                            Ok(hit)
                        });
                    let out = match res { Ok(b) => obj!(ok = b), Err(e) => obj!(err = e) };
                    steps.push(obj!(action = "complete", results = results.iter().map(res_l).collect::<Vec<_>>(), grinds = Raw(format!("{{ {} }}", grinds.borrow().join(", "))),
                        lines = Raw(format!("{{ {} }}", lines.borrow().join(", "))), out = Raw(out), state = Raw(selector_state(&sel))));
                }
                2 => { sel.reset(); steps.push(obj!(action = "reset", state = Raw(selector_state(&sel)))); }
                3 => { sel.cancel_pending(); steps.push(obj!(action = "cancel", state = Raw(selector_state(&sel)))); }
                _ => { let v = sel.update_without_completion(); steps.push(obj!(action = "update", out = v, state = Raw(selector_state(&sel)))); }
            }
        }
        writeln!(s, "\t\t{{ settings = {}, input = {}, steps = {{ {} }} }},", settings_l(&st).0, input_l(&input).0, steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n");

    // --- grind_surface
    s.push_str("\tsurface = {\n");
    for _ in 0..80 {
        let start = v4(&mut r, 3.0);
        let end = if r.next() % 8 == 0 { [start[0], start[1] + r.range(0.5, 2.0), start[2], start[3]] } else { let mut e = v4(&mut r, 3.0); e[1] = start[1] + r.range(-1.0, 1.0); e };
        let input = InvestigationInput { start, end, reference: v4(&mut r, 3.0), optional_probe: if r.bool() { Some(v4(&mut r, 3.0)) } else { None }, deck_center_to_truck: r.range(0.2, 0.3) };
        let plan = grind_surface::prepare(input);
        let rq = RefCell::new(Rng(r.next() as u64 + 3));
        let calls = RefCell::new(Vec::new());
        let fail = r.next() % 20 == 0;
        let res = grind_surface::investigate(input, |i, probe| {
            let mut rr = rq.borrow_mut();
            let hit = if rr.bool() {
                let f = rr.range(0.0, 1.0);
                let pos = [probe.start[0] + (probe.end[0] - probe.start[0]) * f, probe.start[1] + (probe.end[1] - probe.start[1]) * f + [0.0, -0.22, 0.02, -1.5][(rr.next() % 4) as usize], probe.start[2], probe.start[3]];
                let normal = if rr.bool() { [0.0, 1.0, 0.0, 0.0] } else { unit(&mut rr) };
                let packed = [0x400 | 5, 17, 23 | (8 << 7), rr.next()][(rr.next() % 4) as usize];
                Some(ProbeHit { fraction: if rr.bool() { f } else { [0.65, 0.6499999][(rr.next() % 2) as usize] }, position: pos, normal, packed_surface: packed })
            } else { None };
            let hl = match &hit { Some(h) => obj!(some = true, fraction = h.fraction, position = h.position, normal = h.normal, packed_surface = h.packed_surface), None => obj!(some = false) };
            calls.borrow_mut().push(obj!(index = i, probe = probe_l(&probe), hit = Raw(hl)));
            if fail { return Err("probe failed".to_string()); }
            Ok(hit)
        });
        let prev = if r.bool() { 0 } else { r.next() };
        let resolved = plan.as_ref().map(|p| {
            let hits: [Option<ProbeHit>; 7] = std::array::from_fn(|_| if r.bool() { Some(ProbeHit { fraction: r.range(0.0, 1.0), position: v4(&mut r, 3.0), normal: if r.bool() { [0.0, 1.0, 0.0, 0.0] } else { unit(&mut r) }, packed_surface: r.next() }) } else { None });
            let out = grind_surface::resolve(p, &hits, prev);
            let hl: Vec<Raw> = hits.iter().map(|h| Raw(match h { Some(h) => obj!(fraction = h.fraction, position = h.position, normal = h.normal, packed_surface = h.packed_surface), None => "false".into() })).collect();
            Raw(obj!(hits = hl, out = surface_l(&out)))
        });
        // landing orientation on investigate result or None
        let mut up = unit(&mut r);
        let mut o = orientation(&mut r);
        let (take, gp) = (v4(&mut r, 3.0), v4(&mut r, 3.0));
        let (up0, o0) = (up, o);
        let use_none = r.next() % 6 == 0;
        let surf = res.as_ref().ok().copied();
        let mut lsurf = surf;
        if let Some(sx) = lsurf.as_mut() { if r.next() % 5 == 0 { sx.flags |= GrindSurface::INVALID; } if r.bool() { sx.kind = [GeometryType::ThinRail, GeometryType::FatRail, GeometryType::Ledge, GeometryType::Impossible][(r.next() % 4) as usize]; } }
        let landing_surface = if use_none { None } else { lsurf };
        grind_surface::update_landing_orientation(landing_surface.as_ref(), take, gp, &mut up, &mut o);
        let plan_l = plan.map(|p| Raw(obj!(center = p.center, upmost_normal = p.upmost_normal, direction = p.direction, probes = p.probes.iter().map(probe_l).collect::<Vec<_>>())));
        let out = match &res { Ok(x) => obj!(ok = surface_l(x)), Err(e) => obj!(err = e.clone()) };
        writeln!(s, "\t\t{{ input = {}, has_plan = {}, plan = {}, calls = {{ {} }}, out = {}, prev = {}, resolved = {}, landing = {} }},",
            obj!(start = input.start, finish = input.end, reference = input.reference, optional_probe = input.optional_probe, deck_center_to_truck = input.deck_center_to_truck),
            plan_l.is_some(), plan_l.l(), calls.borrow().join(", "), out, prev, resolved.l(),
            obj!(surface = landing_surface.as_ref().map(surface_l), has_surface = landing_surface.is_some(), takeoff = take, grind_position = gp, up_in = up0, out_in = orient_l(&o0), up = up, out = orient_l(&o))).unwrap();
    }
    s.push_str("\t},\n");

    // --- grind
    s.push_str("\tbox_filter = {\n");
    for _ in 0..40 {
        let mut prims: Vec<Primitive> = Vec::new();
        let n = 2 + (r.next() % 6) as usize;
        for _ in 0..n {
            if !prims.is_empty() && r.next() % 2 == 0 {
                let b = prims[(r.next() as usize) % prims.len()];
                let off = [r.range(-0.08, 0.08), r.range(-0.08, 0.08), r.range(-0.08, 0.08), 0.0];
                let k = r.range(-0.3, 0.3);
                let d = [b.end[0] - b.start[0], b.end[1] - b.start[1], b.end[2] - b.start[2], 0.0];
                prims.push(Primitive { start: [b.start[0] + off[0] + d[0] * k, b.start[1] + off[1] + d[1] * k, b.start[2] + off[2] + d[2] * k, 0.0],
                    end: [b.end[0] + off[0] + d[0] * k, b.end[1] + off[1] + d[1] * k, b.end[2] + off[2] + d[2] * k, 0.0], owner: r.next() as u64 });
            } else { prims.push(primitive(&mut r)); }
        }
        let indices: Vec<usize> = (0..prims.len()).filter(|_| r.next() % 5 != 0).collect();
        let takeoff = v4(&mut r, 3.0);
        let out = trajectory_box_filter(&indices, &prims, takeoff);
        writeln!(s, "\t\t{{ primitives = {{ {} }}, indices = {}, takeoff = {}, out = {} }},", prims.iter().map(|p| prim_l(p).0).collect::<Vec<_>>().join(", "), indices.l(), takeoff.l(), out.l()).unwrap();
    }
    s.push_str("\t},\n\tplane_time = {\n");
    for _ in 0..80 {
        let t = Trajectory { position: v4(&mut r, 3.0), velocity: v4(&mut r, 5.0), acceleration: if r.next() % 7 == 0 { [0.0; 4] } else { v4(&mut r, 10.0) }, duration: 1.0 };
        let (p, n) = (v4(&mut r, 3.0), unit(&mut r));
        let out = descending_plane_time(t, p, n);
        writeln!(s, "\t\t{{ t = {}, point = {}, normal = {}, some = {}, out = {} }},", traj_l(&t).0, p.l(), n.l(), out.is_some(), out.l()).unwrap();
    }
    s.push_str("\t},\n\tconsider = {\n");
    for _ in 0..40 {
        let pred = falling_prediction(&mut r);
        let mut cands: Vec<GrindTrajectoryCandidate> = Vec::new();
        let mut lines = Vec::new();
        for k in 0..8 {
            let mut e = Primitive { start: [r.range(-3.0, 3.0), r.range(-1.0, 2.0), r.range(-3.0, 3.0), 0.0], end: [0.0; 4], owner: k };
            e.end = [e.start[0] + r.range(-3.0, 3.0), e.start[1] + r.range(-0.5, 0.5), e.start[2] + r.range(-3.0, 3.0), 0.0];
            if r.next() % 6 == 0 { e.end = [e.start[0] + 0.3, e.start[1], e.start[2], 0.0]; }
            let pad = r.range(0.0, 0.1);
            let c = consider_grind_primitive(pred, e, k as usize, pad);
            if let Some(c) = c { cands.push(c); }
            lines.push(obj!(edge = prim_l(&e), padding = pad, some = c.is_some(), out = c.as_ref().map(cand_l)));
        }
        for _ in 0..3 { cands.push(gcand(&mut r)); }
        let list_in: Vec<Raw> = cands.iter().map(cand_l).collect();
        let dd = r.range(0.0, 1.0);
        let hp: PointGraph<8> = graph(&mut r, -2.0, 0.6, -0.5, 1.0);
        let mut picks = Vec::new();
        while let Some(c) = take_best_grind(&mut cands, dd, &hp) { picks.push(c.primitive); }
        writeln!(s, "\t\t{{ prediction = {}, edges = {{ {} }}, list = {}, difficulty = {}, penalty = {}, picks = {} }},", pred_l(&pred).0, lines.join(", "), list_in.l(), dd.l(), hp.l(), picks.l()).unwrap();
    }
    s.push_str("\t},\n\tadmission = {\n");
    for _ in 0..120 {
        let mut pred = falling_prediction(&mut r);
        let mut c = gcand(&mut r);
        if r.bool() { c.point[1] = pred.request.trajectory.position_at(pred.result.contact_time)[1] + r.range(-0.5, 0.5); c.direction[1] *= 0.2; }
        let refv = { let mut v = v4(&mut r, 4.0); if r.bool() { v[1] *= 0.1; } v };
        let p592 = v4(&mut r, 3.0);
        let surf = GrindSurfaceEvidence { kind: r.next() % 4, side: unit(&mut r) };
        let mut lim = limits(&mut r);
        if r.bool() {
            // Дружественный случай: проходим все ворота до коррекции.
            c.point[1] = pred.request.trajectory.position_at(pred.result.contact_time)[1] + r.range(-0.3, 0.5);
            c.direction = { let d = unit(&mut r); let h = (d[0] * d[0] + d[2] * d[2]).sqrt().max(1e-3); [d[0] / h, 0.0, d[2] / h, 0.0] };
            c.distance = r.range(0.0, 0.3);
            c.time = r.range(0.3, 1.5);
            c.trajectory_point = [c.point[0] + r.range(-0.3, 0.3), c.point[1] + r.range(-0.3, 0.3), c.point[2] + r.range(-0.3, 0.3), 0.0];
            lim.lock_distance = r.range(0.3, 1.0);
            lim.ledge_scalars = std::array::from_fn(|_| r.range(0.8, 2.0));
            lim.max_speed_squared_ledge = 100.0;
            lim.max_speed_squared_rail = 100.0;
            lim.max_downward_speed = 8.0;
            lim.maximum_adjust_angle = r.range(10.0, 90.0);
        }
        let edge = Primitive { start: c.point, end: [c.point[0] + c.direction[0], c.point[1] + c.direction[1], c.point[2] + c.direction[2], 0.0], owner: 5 };
        let mut eld = if r.bool() { Some(0.25f32) } else { None };
        let (pred_in, lock_in) = (pred_l(&pred), eld);
        let out = admitted_displacement(pred, c, edge, refv, p592, surf, &lim, &mut eld);
        let applied = out.map(|corr| {
            let (sup, ma, ls, lm) = (unit(&mut r), r.range(0.5, 5.0), r.range(0.0, 1.0), r.range(0.0, 60.0));
            apply_admitted_target(&mut pred, c, corr, sup, refv, ma, ls, lm);
            Raw(obj!(support = sup, maximum_adjust = ma, landing_velocity_scalar = ls, landing_max_angle = lm, after = pred_l(&pred)))
        });
        writeln!(s, "\t\t{{ prediction = {}, candidate = {}, edge = {}, reference_velocity = {}, processed_592 = {}, surface = {}, limits = {}, lock_in = {}, some = {}, out = {}, has_lock = {}, lock = {}, applied = {} }},",
            pred_in.0, cand_l(&c).0, prim_l(&edge).0, refv.l(), p592.l(), obj!(kind = surf.kind, side = surf.side), limits_l(&lim).0,
            obj!(some = lock_in.is_some(), value = lock_in), out.is_some(), out.l(), eld.is_some(), eld.l(), applied.l()).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/traj.luau"), s).unwrap();
}
