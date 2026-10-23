//! Эталон для animation (часть 2): grind_control, ground_acceleration,
//! intent_filter, kickturn, manual, landing_quality, playback_attributes,
//! playback_clip, деревья воспроизведения (Clip/PhaseBlend/BlendSpace/
//! SelectionSpace/Transition/BindPose), pose_*, pumping_channel, riding_fakie.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::animation::{grind_control as gc, ground_acceleration as ga, intent_filter as inf, kickturn as kt, manual, landing_quality as lq,
    playback_attributes as pa, playback_clip::{self as pc, ClipAttribute, PlaybackClip}, playback_tree::{self as ptree, PlaybackTree, PoseCommand, Evaluation, blend_space::{BlendSpace, Simplex}, selection_space::{SelectionSpace, Parameter, Candidate}},
    playback_transition::PlaybackTransition, playback::TransitionSettings, phase_blend::PhaseBlend, posture::PosturePose, playback_parameters::SettableAttribute,
    pose_add, pose_blend, pose_mirror, pose_sample, pose_trajectory, pumping_channel as pch, riding_fakie as rf, clip_clock::AdvanceResult};
use skate_core::animation::output::{Sqt, attributes::{AnimationAttribute, AttributeName, AttributePayload}};
use skate_core::point_graph::PointGraph;
use std::fmt::Write as _;
use std::sync::Arc;

macro_rules! pick { ($r:expr, [$($x:expr),*]) => {{ let a: Vec<f32> = vec![$($x),*]; let i = ($r.next() as usize) % a.len(); a[i] }} }
fn gn<const N: usize>(r: &mut Rng, lo: f32, a: f32, b: f32, ys: f32) -> PointGraph<N> {
    let mut x = [0f32; N]; let mut acc = lo;
    for k in 0..N { x[k] = acc; acc += r.range(a, b); }
    PointGraph { x, y: core::array::from_fn(|_| r.range(-ys, ys)) }
}
fn v4(r: &mut Rng, s: f32) -> [f32; 4] { [r.range(-s, s), r.range(-s, s), r.range(-s, s), r.range(-s, s)] }
macro_rules! opt { ($r:expr, $v:expr) => {{ let v: f32 = $v; if $r.bool() { Some(v) } else { None } }} }
fn name(k: u32) -> AttributeName { AttributeName([k, 0, 0, 0, 0]) }
fn attr_l(a: &AnimationAttribute) -> Raw {
    let p: Vec<Raw> = a.payload.0.iter().map(|x| Raw(match x { Some(v) => v.to_string(), None => "false".into() })).collect();
    Raw(obj!(payload = p, begin_time = a.begin_time, end_time = a.end_time, name = a.name.0, status = a.status, kind = a.kind, sequence_id = a.sequence_id))
}
fn rattr(r: &mut Rng, k: u32) -> AnimationAttribute {
    AnimationAttribute { payload: AttributePayload(core::array::from_fn(|_| if r.next() % 10 == 0 { None } else { Some(r.range(-2.0, 2.0).to_bits()) })),
        begin_time: r.range(0.0, 1.0), end_time: r.range(0.0, 1.0), name: name(k), status: (r.next() % 20) as u8, kind: (r.next() % 5) as u8, sequence_id: -1 }
}
fn sqt(r: &mut Rng) -> Sqt { Sqt { scale: v4(r, 2.0), rotation: v4(r, 1.0), translation: v4(r, 3.0) } }
fn sqt_l(q: &Sqt) -> Raw { Raw(obj!(scale = q.scale, rotation = q.rotation, translation = q.translation)) }
fn res_l(p: &AdvanceResult) -> Raw { Raw(obj!(crossed_end = p.crossed_end, overshoot = p.overshoot, remaining_before_wrap = p.remaining_before_wrap)) }
fn err<T>(r: &Result<T, String>) -> bool { r.is_err() }

fn cmd_l(c: &PoseCommand) -> Raw {
    Raw(match c {
        PoseCommand::Clip { name, previous_time, time, loops } => obj!(kind = "Clip", name = name.clone(), previous_time = *previous_time, time = *time, loops = *loops),
        PoseCommand::Blend { weight } => obj!(kind = "Blend", weight = *weight),
        PoseCommand::WeightedBlend { weights } => obj!(kind = "WeightedBlend", weights = weights.clone()),
        PoseCommand::ChannelBlend { weight, use_channels_from_weights } => obj!(kind = "ChannelBlend", weight = *weight, use_channels_from_weights = *use_channels_from_weights),
        PoseCommand::Pose { name } => obj!(kind = "Pose", name = name.clone()),
        PoseCommand::Add { motion_is_a } => obj!(kind = "Add", motion_is_a = *motion_is_a),
        PoseCommand::Mirror { trajectory_mode } => obj!(kind = "Mirror", trajectory_mode = *trajectory_mode),
    })
}

/// Случайное дерево и его описание для Luau-сборки.
fn clip_tree(r: &mut Rng, id: &mut u32) -> (PlaybackTree, String) {
    *id += 1;
    let frames = (2 + r.next() % 60) as f32; let fps = pick!(r, [30.0, 60.0]); let base = r.range(0.5, 1.5);
    let flags = [0u32, 0x1000_0000, 0x4000_0000, 0x5000_0000][(r.next() % 4) as usize];
    let mut attrs = Vec::new(); let mut al = Vec::new();
    let mut names: Vec<u32> = (0..(r.next() % 4)).map(|_| r.next() % 4).collect(); names.sort();
    for k in names {
        let kind = (r.next() % 4) as u8;
        let begin = if r.next() % 4 == 0 { -1.0 } else { r.range(0.0, 1.0) };
        let end = r.range(0.0, 1.0);
        let payload: Vec<u32> = if kind == 2 {
            let n = 1 + r.next() % 4; let mut v = vec![r.next(), n]; let mut x = r.range(-1.0, 5.0);
            for _ in 0..n { v.push(x.to_bits()); v.push(r.range(-2.0, 2.0).to_bits()); x += r.range(0.0, 20.0); } v
        } else { (0..6).map(|_| r.range(-2.0, 2.0).to_bits()).collect() };
        al.push(obj!(name = name(k).0, kind = kind as u32, begin = begin, end_ = end, payload = payload.clone()));
        attrs.push(ClipAttribute { name: name(k), kind, begin, end, payload });
    }
    let nm = format!("C{id}");
    let d = obj!(kind = "Clip", name = nm.clone(), frames = frames, fps = fps, base = base, flags = flags, attrs = Raw(format!("{{ {} }}", al.join(", "))));
    (PlaybackTree::Clip { name: nm, clip: PlaybackClip::new(frames, fps, base, flags, attrs) }, d)
}
fn tree(r: &mut Rng, depth: u32, id: &mut u32) -> (PlaybackTree, String) {
    let k = if depth == 0 { 0 } else { r.next() % 7 };
    match k {
        1 => { let n = 2 + (r.next() % 2) as usize; let mut ch = Vec::new(); let mut ds = Vec::new();
            for _ in 0..n { let (t, d) = tree(r, depth - 1, id); ch.push(t); ds.push(Raw(d)); }
            let p = name(r.next() % 4);
            (PlaybackTree::PhaseBlend(PhaseBlend::new(p, ch).unwrap()), obj!(kind = "Phase", parameter = p.0, children = ds)) }
        2 => { let d = 1 + (r.next() % 2) as usize; let n = d + 1 + (r.next() % 2) as usize;
            let mut ch = Vec::new(); let mut ds = Vec::new();
            for _ in 0..n { let (t, dd) = tree(r, depth - 1, id); ch.push(t); ds.push(Raw(dd)); }
            let ns = 1 + r.next() % 2;
            let mut ss = Vec::new(); let mut sl = Vec::new();
            for _ in 0..ns {
                let mut idx: Vec<usize> = (0..n).collect(); for i in (1..n).rev() { let j = (r.next() as usize) % (i + 1); idx.swap(i, j); } idx.truncate(d + 1);
                let vs: Vec<Vec<f32>> = (0..=d).map(|_| (0..d).map(|_| r.range(-1.0, 1.0)).collect()).collect();
                let nsx: Vec<Vec<f32>> = (0..=d).map(|_| (0..d).map(|_| r.range(-1.0, 1.0)).collect()).collect();
                let sc: Vec<f32> = (0..=d).map(|_| r.range(0.5, 2.0)).collect();
                sl.push(Raw(obj!(children = idx.clone(), vertices = vs.clone(), normals = nsx.clone(), scales = sc.clone())));
                ss.push(Simplex { children: idx, vertices: vs, normals: nsx, scales: sc });
            }
            let ps: Vec<AttributeName> = (0..d).map(|i| name(i as u32)).collect();
            (PlaybackTree::BlendSpace(BlendSpace::new(ps.clone(), ch, ss).unwrap()), obj!(kind = "Blend", parameters = ps.iter().map(|p| p.0).collect::<Vec<_>>(), children = ds, simplexes = sl)) }
        3 => { let np = (r.next() % 3) as usize; let nc = 1 + (r.next() % 3) as usize;
            let params: Vec<Parameter> = (0..np).map(|i| Parameter { name: name(i as u32), mode: r.next() % 3, weight: r.range(0.0, 2.0), minimum: r.range(-1.0, 0.0), maximum: r.range(0.0, 1.0) }).collect();
            let pl: Vec<Raw> = params.iter().map(|p| Raw(obj!(name = p.name.0, mode = p.mode, weight = p.weight, minimum = p.minimum, maximum = p.maximum))).collect();
            let mut cs = Vec::new(); let mut cl = Vec::new();
            for c in 0..nc { let (t, d) = tree(r, depth - 1, id); let vals: Vec<f32> = (0..np).map(|_| r.range(-1.0, 1.0)).collect();
                let nm = format!("S{}", c % 2); cl.push(Raw(obj!(name = nm.clone(), values = vals.clone(), tree = Raw(d)))); cs.push(Candidate { name: nm, values: vals, tree: t }); }
            (PlaybackTree::SelectionSpace(SelectionSpace::new(params, cs).unwrap()), obj!(kind = "Select", parameters = pl, candidates = cl)) }
        4 => { let (a, da) = tree(r, depth - 1, id); let (b, db) = tree(r, depth - 1, id);
            let s = TransitionSettings { kind: 1 + r.next() % 4, seconds: pick!(r, [0.0, 0.03, r.range(0.0, 1.0)]), under: 0, matching: r.next() % 4, use_channels_from_weights: r.bool() };
            (PlaybackTree::Transition(PlaybackTransition::new(a, b, s)), obj!(kind = "Trans", from = Raw(da), to = Raw(db), settings = Raw(obj!(kind = s.kind, seconds = s.seconds, under = s.under, matching = s.matching, use_channels_from_weights = s.use_channels_from_weights)))) }
        5 => { let (m, dm) = tree(r, depth - 1, id);
            let posture = [None, Some(PosturePose::Stiff), Some(PosturePose::Slouch), Some(PosturePose::Buff)][(r.next() % 4) as usize];
            let bb = r.bool(); let modes: Vec<u32> = (0..(r.next() % 3)).map(|_| 1 + r.next() % 2).collect();
            let pairs: Vec<(AttributeName, AttributeName)> = (0..4).map(|i| (AttributeName([i, 0, 0, 0, 0]), AttributeName([(i + 1) % 4, 0, 0, 0, 0]))).collect();
            let pl: Vec<Raw> = pairs.iter().map(|(a, b)| Raw(format!("{{ {}, {} }}", a.0.l(), b.0.l()))).collect();
            (PlaybackTree::BindPose { motion: Box::new(m), posture, board_backwards: bb, mirror_modes: modes.clone(), attribute_mirror: Arc::new(pa::AttributeMirror(pairs)) },
             obj!(kind = "Bind", motion = Raw(dm), posture = posture.map(|p| format!("{:?}", p)), board_backwards = bb, mirror_modes = modes, mirror_pairs = pl)) }
        _ => clip_tree(r, id),
    }
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0xa1e0_0002);
    let mut s = format!("-- Сгенерировано golden/src/anim2.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");
    // grind_control
    s.push_str("\tfade = {\n");
    for _ in 0..20 {
        let st = gc::FadeSettings { response: r.range(0.0, 1.0), input_scale: r.range(0.0, 1.0), acceleration: r.range(0.0, 0.3), maximum_step: r.range(0.0, 0.6) };
        let mut f = gc::Fade::default(); let mut steps = Vec::new();
        for _ in 0..30 {
            if r.next() % 8 == 0 { let (a, b, t) = (r.range(-2.0, 0.0), r.range(0.0, 2.0), r.range(-3.0, 3.0)); let v = f.begin(a, b, t); steps.push(obj!(op = "begin", a = a, b = b, t = t, out = v)); }
            else { let (dt, i) = (r.range(0.0, 0.1), r.range(-1.0, 1.0)); let v = f.update(dt, i, st); steps.push(obj!(op = "update", dt = dt, intent = i, out = v, value = f.value, target = f.target, step = f.step, elapsed = f.elapsed)); }
        }
        writeln!(s, "\t\t{{ settings = {}, steps = {{ {} }} }},", obj!(response = st.response, input_scale = st.input_scale, acceleration = st.acceleration, maximum_step = st.maximum_step), steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tgrind_misc = {\n");
    for _ in 0..300 {
        let a: [f32; 7] = [r.range(0.0, 1.0), r.range(-0.5, 1.5), r.range(-0.5, 1.5), r.range(0.0, 0.5), r.range(0.5, 1.0), r.range(0.0, 10.0), r.range(0.0, 0.1)];
        let n = [r.range(-2.0, 2.0), r.range(-2.0, 2.0), r.range(-2.0, 2.0)]; let b = [r.range(-2.0, 2.0), r.range(-2.0, 2.0), if r.next() % 8 == 0 { 0.0 } else { r.range(-2.0, 2.0) }];
        let (g, m) = (r.bool(), r.bool()); let t = r.range(-3.2, 3.2);
        writeln!(s, "\t\t{},", obj!(a = a, crouch = gc::crouch(a[0], a[1], a[2], a[3], a[4], a[5], a[6]), n = n, b = b, ground = g, mirrored = m, backwards = gc::facing::backwards(n, b, g, m), twist = t, mirrored_twist = gc::mirrored_twist(t, m))).unwrap();
    }
    s.push_str("\t},\n\tground_acc = {\n");
    let frame = |r: &mut Rng| -> [[f32; 4]; 4] { core::array::from_fn(|_| v4(r, 1.0)) };
    for _ in 0..300 {
        let i = ga::Input { deck: frame(&mut r), ground: frame(&mut r), world_acceleration: v4(&mut r, 20.0) };
        let st = ga::Settings { scale_x_acc: r.range(0.5, 3.0), min_bump_mag: r.range(0.0, 20.0) };
        let o = ga::publish(i, &st);
        writeln!(s, "\t\t{},", obj!(deck = i.deck, ground = i.ground, world_acceleration = i.world_acceleration, scale_x_acc = st.scale_x_acc, min_bump_mag = st.min_bump_mag, acceleration = o.acceleration, bumped = o.bumped)).unwrap();
    }
    s.push_str("\t},\n\tintent_filter = {\n");
    for _ in 0..30 {
        let st = inf::Settings { starting_value: r.range(-1.0, 1.0), default_value: r.range(-1.0, 1.0), scale: r.range(-2.0, 2.0), filters: core::array::from_fn(|_| r.next() % 10), ramp_time: opt!(r, pick!(r, [0.0, r.range(0.0, 1.0)])), blend_rising: r.range(0.0, 1.0), blend_falling: r.range(0.0, 1.0), blend_out: opt!(r, r.range(0.0, 1.0)), clamp_velocity: opt!(r, r.range(0.0, 0.5)), clamp_acceleration: opt!(r, r.range(0.0, 0.3)) };
        let mut state = inf::State::default(); let mut steps = Vec::new();
        for k in 0..40 {
            if k == 0 || r.next() % 10 == 0 { let v = state.begin(&st); steps.push(obj!(op = "begin", out = v)); continue; }
            let i = opt!(r, r.range(-2.0, 2.0)); let dt = pick!(r, [-0.01, r.range(0.0, 0.2)]); let stance = (r.bool(), r.bool());
            let v = state.update(&st, i, dt, stance);
            steps.push(obj!(op = "update", input = i, dt = dt, stance = [stance.0, stance.1], out = v, elapsed = state.elapsed, previous_delta = state.previous_delta));
        }
        writeln!(s, "\t\t{{ settings = {}, steps = {{ {} }} }},", obj!(starting_value = st.starting_value, default_value = st.default_value, scale = st.scale, filters = st.filters, ramp_time = st.ramp_time, blend_rising = st.blend_rising, blend_falling = st.blend_falling, blend_out = st.blend_out, clamp_velocity = st.clamp_velocity, clamp_acceleration = st.clamp_acceleration), steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tkickturn = {\n");
    for _ in 0..20 {
        let st = kt::Settings { spin: gn::<8>(&mut r, 0.0, 0.05, 0.2, 1.0), height: gn::<8>(&mut r, 0.0, 0.05, 0.2, 1.0) };
        let mut state = kt::State::new(); state.begin(&st); let mut steps = Vec::new();
        for _ in 0..30 {
            if r.next() % 12 == 0 { state.begin(&st); steps.push("{ op = \"begin\" }".to_string()); continue; }
            let need = state.needs_animation_length(); let len = pick!(r, [0.0, r.range(0.1, 2.0)]);
            if need { state.capture_animation_length(len); }
            let p = kt::Parameters { max_height: r.range(0.0, 1.0), spin_scale: r.range(-1.0, 1.0) };
            let (dt, i) = (r.range(0.0, 0.2), pick!(r, [0.0, -0.0, r.range(-1.0, 1.0)]));
            let o = state.update(dt, i, p, &st);
            steps.push(obj!(op = "update", need = need, length = len, max_height = p.max_height, spin_scale = p.spin_scale, dt = dt, intent = i, balance = o.balance, spin = o.spin));
        }
        writeln!(s, "\t\t{{ settings = {}, steps = {{ {} }} }},", obj!(spin = st.spin, height = st.height), steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tmanual = {\n");
    for _ in 0..20 {
        let st = manual::Settings { balance: gn::<8>(&mut r, 0.0, 0.05, 0.2, 1.0), velocity_limit: r.range(0.0, 0.2), acceleration_limit: r.range(0.0, 0.05) };
        let mut state = manual::State::default(); let mut steps = Vec::new();
        for _ in 0..30 {
            if r.next() % 15 == 0 { state.begin(); steps.push("{ op = \"begin\" }".to_string()); continue; }
            let m = opt!(r, pick!(r, [-0.0, r.range(-1.0, 1.0)]));
            let v = state.update(m, &st); steps.push(obj!(op = "update", manual = m, out = v, velocity = state.velocity));
        }
        writeln!(s, "\t\t{{ settings = {}, steps = {{ {} }} }},", obj!(balance = st.balance, velocity_limit = st.velocity_limit, acceleration_limit = st.acceleration_limit), steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tlanding = {\n");
    for _ in 0..400 {
        let st = lq::Settings { twist_spin: gn::<4>(&mut r, 0.0, 0.1, 0.5, 1.0), side_speed: gn::<4>(&mut r, 0.0, 0.1, 0.5, 1.0) };
        let mut o = lq::Output { landing_adjust_80: r.range(-1.0, 1.0), sideways_speed_84: r.range(0.0, 1.0), forward_speed_88: 0.0, spin_92: 0.0, landing_type_96: 7, landing_data_167: r.bool() };
        let o0 = o;
        let mut nrm = v4(&mut r, 1.0); nrm[3] = 0.0;
        let i = lq::Input { previous_filtered_state: [0, 1, 2][(r.next() % 3) as usize], filtered_state: [1, 1, 2][(r.next() % 3) as usize], ground_normal: nrm, deck_velocity: if r.next() % 8 == 0 { [0.0; 4] } else { v4(&mut r, 8.0) }, flipped: r.bool(), reckoning_forward: v4(&mut r, 1.0), air_spin: pick!(r, [0.0, 0.05, r.range(-12.0, 12.0)]) };
        o.update(i, &st);
        let ol = |o: &lq::Output| Raw(obj!(landing_adjust_80 = o.landing_adjust_80, sideways_speed_84 = o.sideways_speed_84, forward_speed_88 = o.forward_speed_88, spin_92 = o.spin_92, landing_type_96 = o.landing_type_96, landing_data_167 = o.landing_data_167));
        writeln!(s, "\t\t{},", obj!(settings = Raw(obj!(twist_spin = st.twist_spin, side_speed = st.side_speed)), start = ol(&o0), input = Raw(obj!(previous_filtered_state = i.previous_filtered_state, filtered_state = i.filtered_state, ground_normal = i.ground_normal, deck_velocity = i.deck_velocity, flipped = i.flipped, reckoning_forward = i.reckoning_forward, air_spin = i.air_spin)), out = ol(&o))).unwrap();
    }
    // playback_attributes
    s.push_str("\t},\n\tpattr = {\n");
    for _ in 0..200 {
        let a = { let k = r.next() % 3; rattr(&mut r, k) }; let mut b = { let k = r.next() % 3; rattr(&mut r, k) }; b.kind = a.kind; let w = r.range(-0.5, 1.5);
        let mut x = a; let e1 = pa::blend(&mut x, &b, w).is_err();
        let mut y = a; let e2 = pa::scale(&mut y, w).is_err();
        let mut z = a; let e3 = pa::add_weighted(&mut z, &b, w).is_err();
        let pairs: Vec<(AttributeName, AttributeName)> = (0..3).map(|i| (name(i), name(2 - i))).collect();
        let mut m = a; let mut pay = m.payload.0; for k in 1..5 { if pay[k].is_some() { pay[k] = Some(0); } } if r.bool() { pay[0] = Some(r.next() % 3); } m.payload = AttributePayload(pay);
        let m0 = m; let e4 = pa::AttributeMirror(pairs.clone()).apply(&mut m).is_err();
        let mut left: Vec<AnimationAttribute> = (0..(r.next() % 5)).map(|_| { let k = r.next() % 5; rattr(&mut r, k) }).collect(); left.sort_by(|p, q| p.name.0.cmp(&q.name.0));
        let mut right: Vec<AnimationAttribute> = (0..(r.next() % 5)).map(|_| { let k = r.next() % 5; rattr(&mut r, k) }).collect(); right.sort_by(|p, q| p.name.0.cmp(&q.name.0));
        let inter = pa::intersection(left.clone(), &right, w);
        let il: Raw = match &inter { Ok(v) => Raw(v.iter().map(attr_l).collect::<Vec<_>>().l()), Err(_) => Raw("\"err\"".into()) };
        writeln!(s, "\t\t{},", obj!(a = attr_l(&a), b = attr_l(&b), w = w, blend = if e1 { Raw("\"err\"".into()) } else { attr_l(&x) }, scale = if e2 { Raw("\"err\"".into()) } else { attr_l(&y) }, add = if e3 { Raw("\"err\"".into()) } else { attr_l(&z) },
            m = attr_l(&m0), pairs = pairs.iter().map(|(p, q)| Raw(format!("{{ {}, {} }}", p.0.l(), q.0.l()))).collect::<Vec<_>>(), mirror = if e4 { Raw("\"err\"".into()) } else { attr_l(&m) },
            left = left.iter().map(attr_l).collect::<Vec<_>>(), right = right.iter().map(attr_l).collect::<Vec<_>>(), inter = il)).unwrap();
    }
    s.push_str("\t},\n\tcurve = {\n");
    for _ in 0..300 {
        let n = r.next() % 6; let mut w = vec![r.next(), n]; let mut x = r.range(-2.0, 2.0);
        for _ in 0..n { w.push(x.to_bits()); w.push(r.range(-2.0, 2.0).to_bits()); x += pick!(r, [0.0, r.range(0.0, 2.0)]); }
        if r.next() % 10 == 0 { w.pop(); }
        let t = r.range(-3.0, 12.0);
        let o = pc::sample_curve(&w, t);
        writeln!(s, "\t\t{},", obj!(words = w, t = t, out = o.as_ref().ok().copied(), err = o.is_err())).unwrap();
    }
    // trees
    s.push_str("\t},\n\ttrees = {\n");
    for _ in 0..60 {
        let mut id = 0;
        let depth = 1 + r.next() % 3; let (mut t, d) = tree(&mut r, depth, &mut id);
        let mut ops = Vec::new();
        for _ in 0..30 {
            let op = r.next() % 9;
            let line = match op {
                0 => { let attrs: Vec<SettableAttribute> = (0..(r.next() % 4)).map(|_| SettableAttribute { name: name(r.next() % 4), value: r.range(-1.0, 1.0), normalized: r.bool(), sequence_id: -1 }).collect();
                    let res = t.set_attributes(&attrs); obj!(op = "set_attributes", attrs = attrs.iter().map(|a| Raw(obj!(name = a.name.0, value = a.value, normalized = a.normalized, sequence_id = a.sequence_id))).collect::<Vec<_>>(), out = res.as_ref().ok().copied(), err = err(&res)) }
                1 => { let mut p = AdvanceResult { crossed_end: false, overshoot: -1.0, remaining_before_wrap: -1.0 }; let (dt, ph) = (r.range(0.0, 0.3), r.range(0.0, 1.0)); t.advance(dt, ph, &mut p); obj!(op = "advance", dt = dt, phase = ph, res = res_l(&p)) }
                2 => { let v = r.range(0.0, 2.0); t.set_time(v); obj!(op = "set_time", v = v) }
                3 => { let v = r.range(0.5, 2.0); t.set_speed(v); obj!(op = "set_speed", v = v) }
                4 | 5 => { let e = Evaluation { cull_threshold: pick!(r, [0.0, 0.01, 0.2]), update_history: r.bool() }; let en = r.next() % 4 != 0; let mut out = Vec::new();
                    let res = t.evaluate(e, en, &mut out); obj!(op = "evaluate", cull = e.cull_threshold, history = e.update_history, enabled = en, out = res.as_ref().ok().copied(), err = err(&res), cmds = if res.is_ok() { out.iter().map(cmd_l).collect::<Vec<_>>() } else { vec![] }) }
                6 => { let m = [31u32, 15, 0x1d, 0x13][(r.next() % 4) as usize]; let res = t.attributes(m); obj!(op = "attributes", mask = m, err = err(&res), out = res.map(|v| v.iter().map(attr_l).collect::<Vec<_>>()).unwrap_or_default()) }
                7 => { let (n, m) = (name(r.next() % 4), [31u32, 15][(r.next() % 2) as usize]); let res = t.attribute(n, m); obj!(op = "attribute", name = n.0, mask = m, err = err(&res), out = res.ok().flatten().map(|a| attr_l(&a))) }
                _ => obj!(op = "query", length = t.length(), time = t.time()),
            };
            ops.push(line);
            if ops.last().unwrap().contains("err = true") { break; }
        }
        writeln!(s, "\t\t{{ tree = {}, ops = {{\n\t\t\t{}\n\t\t}} }},", d, ops.join(",\n\t\t\t")).unwrap();
    }
    // poses
    s.push_str("\t},\n\tposes = {\n");
    for _ in 0..300 {
        let (a, b) = (sqt(&mut r), sqt(&mut r)); let w = r.range(-0.2, 1.2); let m = r.bool();
        let lt = if r.bool() { Some(pose_trajectory::LoopTransform { rotation: v4(&mut r, 1.0), translation: [r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0)] }) } else { None };
        let sel = pose_sample::FrameSelection { first: (r.next() % 20) as usize, second: (r.next() % 20) as usize, coefficient: r.range(0.0, 1.0) };
        writeln!(s, "\t\t{},", obj!(a = sqt_l(&a), b = sqt_l(&b), w = w, m = m, add = sqt_l(&pose_add::add(a, b, m)), blend = sqt_l(&pose_blend::blend_sample(a, b, w)), channel = sqt_l(&pose_blend::channel_blend_sample(a, b, w, m)),
            lt = lt.map(|l| Raw(obj!(rotation = l.rotation, translation = l.translation))), delta = sqt_l(&pose_trajectory::delta(a, b, lt)),
            sel = Raw(obj!(first = sel.first, second = sel.second, coefficient = sel.coefficient)), key = sqt_l(&pose_sample::sample_key(a, b, sel)), key_vbr = sqt_l(&pose_sample::sample_key_vbr(a, b, sel)))).unwrap();
    }
    s.push_str("\t},\n\tweighted = {\n");
    for _ in 0..60 {
        let n = (r.next() % 4) as usize; let bones = 1 + (r.next() % 3) as usize;
        let poses: Vec<Vec<Sqt>> = (0..n).map(|_| (0..bones).map(|_| sqt(&mut r)).collect()).collect();
        let weights: Vec<f32> = (0..n).map(|_| pick!(r, [r.range(-0.5, 1.5), f32::NAN, 0.0])).collect();
        let out = pose_blend::weighted(&poses, &weights);
        writeln!(s, "\t\t{},", obj!(poses = poses.iter().map(|p| p.iter().map(sqt_l).collect::<Vec<_>>()).collect::<Vec<_>>(), weights = weights, err = out.as_ref().err().map(|e| format!("{e:?}")), out = out.map(|v| v.iter().map(sqt_l).collect::<Vec<_>>()).unwrap_or_default())).unwrap();
    }
    s.push_str("\t},\n\tmirror = {\n");
    for _ in 0..60 {
        let n = 1 + (r.next() % 6) as usize;
        let pose: Vec<Sqt> = (0..n).map(|_| sqt(&mut r)).collect();
        let parents: Vec<i32> = (0..n).map(|i| if i == 0 { -1 } else { (r.next() % i as u32) as i32 }).collect();
        let partners: Vec<i32> = (0..n).map(|_| (r.next() % (n as u32 + 2)) as i32 - 1).collect();
        let mode = r.next() % 3;
        let mut p = pose.clone(); let e = pose_mirror::mirror(&mut p, &parents, &partners, mode).is_err();
        writeln!(s, "\t\t{},", obj!(pose = pose.iter().map(sqt_l).collect::<Vec<_>>(), parents = parents, partners = partners, mode = mode, err = e, out = p.iter().map(sqt_l).collect::<Vec<_>>())).unwrap();
    }
    s.push_str("\t},\n\tselect_frames = {\n");
    for _ in 0..400 {
        let t = pick!(r, [-0.1, 0.0, f32::NAN, r.range(0.0, 3.0)]); let fps = pick!(r, [30.0, 0.0, r.range(1.0, 60.0)]); let frames = (r.next() % 50) as usize; let bf = r.bool(); let off = pick!(r, [0.0, 0.5, r.range(0.0, 1.0)]);
        let o = pose_sample::select_frames(t, fps, frames, bf, off);
        writeln!(s, "\t\t{},", obj!(t = t, fps = fps, frames = frames, blend = bf, offset = off, err = o.is_err(), out = o.ok().map(|x| Raw(obj!(first = x.first, second = x.second, coefficient = x.coefficient))))).unwrap();
    }
    s.push_str("\t},\n\tpumping = {\n");
    for _ in 0..20 {
        let st = pch::Settings { amplify: gn::<8>(&mut r, 0.0, 0.05, 0.2, 1.5), input_blend: r.range(0.0, 1.0), maximum_physics_pump: r.range(0.5, 3.0), new_pump_threshold: r.range(0.0, 0.8), blend_in: 0.1, blend_out: 0.1 };
        let mut state = pch::State::default(); let mut steps = Vec::new();
        for _ in 0..40 {
            let p = r.range(-1.0, 3.0); let occ: [bool; 5] = core::array::from_fn(|_| r.next() % 3 == 0);
            let u = state.update(p, occ, &st);
            steps.push(obj!(pump = p, occupied = occ, start = u.start, influence = u.influence.map(|(i, v)| Raw(format!("{{ {}, {} }}", i, v.l())))));
        }
        writeln!(s, "\t\t{{ settings = {}, steps = {{ {} }} }},", obj!(amplify = st.amplify, input_blend = st.input_blend, maximum_physics_pump = st.maximum_physics_pump, new_pump_threshold = st.new_pump_threshold, blend_in = st.blend_in, blend_out = st.blend_out), steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tfakie = {\n");
    for _ in 0..20 {
        let st = rf::Settings { high_speed: r.range(2.0, 6.0), low_speed: r.range(0.0, 2.0), slowly_backwards_seconds: r.range(0.0, 0.5), after_teleport_seconds: r.range(0.0, 0.3) };
        let mut state = rf::State::default(); let mut steps = Vec::new();
        for _ in 0..40 {
            let p = rf::Physical { category: [1, 1, 2, 5, 6, 3][(r.next() % 6) as usize], grind_state: [503, 0][(r.next() % 2) as usize], doing_trick: r.next() % 5 == 0, board_axis: v4(&mut r, 1.0), deck_velocity: v4(&mut r, 6.0), external_velocity: v4(&mut r, 6.0), ground_projected_speed: r.range(0.0, 8.0) };
            let dt = r.range(0.0, 0.1);
            let o = state.update(p, dt, st);
            steps.push(obj!(p = Raw(obj!(category = p.category, grind_state = p.grind_state, doing_trick = p.doing_trick, board_axis = p.board_axis, deck_velocity = p.deck_velocity, external_velocity = p.external_velocity, ground_projected_speed = p.ground_projected_speed)), dt = dt, out = o));
        }
        writeln!(s, "\t\t{{ settings = {}, steps = {{ {} }} }},", obj!(high_speed = st.high_speed, low_speed = st.low_speed, slowly_backwards_seconds = st.slowly_backwards_seconds, after_teleport_seconds = st.after_teleport_seconds), steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/anim2.luau"), s).unwrap();
    let _ = ptree::PoseCommand::Blend { weight: 0.0 };
}
