//! Эталон для animation (часть 1): air_leg_extension, body_tilt, bump,
//! clip_clock, channel_playback, crouching, output (sqt, hierarchy, intents,
//! packet_reset, physics_packet, actor_packet), commands (SetData).
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::animation::{air_leg_extension as ale, body_tilt, bump, channel_playback as cp, clip_clock::{AdvanceResult, ClipClock}, crouching};
use skate_core::animation::output::{self, attributes::{AnimationAttribute, AttributeName, AttributePayload}, intents::{Intent, IntentMap, IntentName}, packet_reset, physics_packet as pp, actor_packet as ap, Sqt};
use skate_core::animation::commands::{batch::SetDataQueue, buffers::{PoseBuffers, BoneSlice}, set_data::{CopyCommand, InternalUpdate, SetDataCommand}};
use skate_core::point_graph::PointGraph;
use std::fmt::Write as _;

fn gn<const N: usize>(r: &mut Rng, lo: f32, a: f32, b: f32, ys: f32) -> PointGraph<N> {
    let mut x = [0f32; N]; let mut acc = lo;
    for k in 0..N { x[k] = acc; acc += r.range(a, b); }
    PointGraph { x, y: core::array::from_fn(|_| r.range(-ys, ys)) }
}
fn v4(r: &mut Rng, s: f32) -> [f32; 4] { [r.range(-s, s), r.range(-s, s), r.range(-s, s), r.range(-s, s)] }
macro_rules! pick { ($r:expr, [$($x:expr),*]) => {{ let a: Vec<f32> = vec![$($x),*]; let i = ($r.next() as usize) % a.len(); a[i] }} }
fn attr_l(a: &AnimationAttribute) -> Raw {
    let p: Vec<Raw> = a.payload.0.iter().map(|x| Raw(match x { Some(v) => v.to_string(), None => "false".into() })).collect();
    Raw(obj!(payload = p, begin_time = a.begin_time, end_time = a.end_time, name = a.name.0, status = a.status, kind = a.kind, sequence_id = a.sequence_id))
}
fn attr(r: &mut Rng) -> AnimationAttribute {
    AnimationAttribute { payload: AttributePayload(core::array::from_fn(|_| if r.next() % 4 == 0 { None } else { Some(r.range(-2.0, 2.0).to_bits()) })),
        begin_time: r.range(0.0, 1.0), end_time: r.range(0.0, 1.0), name: AttributeName(core::array::from_fn(|_| r.next() % 3)), status: (r.next() % 20) as u8, kind: (r.next() % 5) as u8, sequence_id: (r.next() % 5) as i32 - 1 }
}
fn m_l(m: &[[f32; 4]; 4]) -> Raw { Raw(m.l()) }

pub fn write(out_dir: &str) {
    let mut r = Rng(0xa1e0_0001);
    let mut s = format!("-- Сгенерировано golden/src/anim1.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");

    // air_leg_extension
    s.push_str("\tair_leg = {\n");
    for _ in 0..30 {
        let st = ale::Settings { going_up_speed: r.range(0.0, 2.0), going_down_speed: r.range(0.0, 3.0), minimum_height: r.range(0.0, 0.5), preland_velocity: r.range(-2.0, 2.0), preland_final_height: r.range(0.0, 1.0), offboard_multiplier: r.range(0.5, 1.5), arm_extension: gn::<4>(&mut r, 0.0, 0.05, 0.5, 1.0) };
        let bone = [ale::Bone::Board, ale::Bone::LeftToe, ale::Bone::RightToe][(r.next() % 3) as usize];
        let mut state = ale::State::default();
        let mut steps = Vec::new();
        for _ in 0..40 {
            let p = ale::Physical { com_velocity: v4(&mut r, 4.0), com_position: v4(&mut r, 2.0), system_up: v4(&mut r, 1.0), right_toe: v4(&mut r, 2.0), left_toe: v4(&mut r, 2.0), animation_height: r.range(0.0, 1.5), offboard_316: r.next() % 4 == 0, remaining_air_time: r.range(0.0, 1.0) };
            let dt = if r.bool() { 1.0 / 60.0 } else { r.range(0.0, 0.1) };
            let initial = if r.bool() { Some(attr(&mut r)) } else { None };
            let full = if r.bool() { Some(attr(&mut r)) } else { None };
            let query = r.bool();
            let need_init = state.needs_initial_attribute();
            let need_pre = state.needs_prelanding_query(p);
            let prep = ale::prepare_to_land(query, full, p, &st);
            let out = state.update(bone, p, &st, dt, initial, prep);
            steps.push(obj!(p = Raw(obj!(com_velocity = p.com_velocity, com_position = p.com_position, system_up = p.system_up, right_toe = p.right_toe, left_toe = p.left_toe, animation_height = p.animation_height, offboard_316 = p.offboard_316, remaining_air_time = p.remaining_air_time)),
                dt = dt, initial = initial.as_ref().map(attr_l), full = full.as_ref().map(attr_l), query = query, need_init = need_init, need_pre = need_pre, prep = prep, out = out));
        }
        let b = format!("{:?}", bone);
        writeln!(s, "\t\t{{ bone = {:?}, settings = {}, steps = {{\n\t\t\t{}\n\t\t}} }},", b, obj!(going_up_speed = st.going_up_speed, going_down_speed = st.going_down_speed, minimum_height = st.minimum_height, preland_velocity = st.preland_velocity, preland_final_height = st.preland_final_height, offboard_multiplier = st.offboard_multiplier, arm_extension = st.arm_extension), steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n\tbody_tilt = {\n");
    for _ in 0..20 {
        let st = body_tilt::Settings { body_spin_factor: gn::<4>(&mut r, 0.0, 0.2, 2.0, 1.0), ground_velocity: r.range(0.0, 0.2), ground_acceleration: r.range(0.0, 0.05), air_velocity: r.range(0.0, 0.2), air_acceleration: r.range(0.0, 0.05) };
        let mut state = body_tilt::State::default();
        let mut steps = Vec::new();
        for _ in 0..40 {
            let p = body_tilt::Physical { lateral_tilt: r.range(-1.0, 1.0), body_spin_speed: r.range(-6.0, 6.0), filtered_category: r.next() % 4 };
            let (en, mir) = (r.next() % 6 != 0, r.bool());
            let dis = r.next() % 15 == 0;
            if dis { state.disable(); }
            let out = state.update(en, mir, p, &st);
            steps.push(obj!(disable = dis, enabled = en, mirrored = mir, p = Raw(obj!(lateral_tilt = p.lateral_tilt, body_spin_speed = p.body_spin_speed, filtered_category = p.filtered_category)), out = out));
        }
        writeln!(s, "\t\t{{ settings = {}, steps = {{ {} }} }},", obj!(body_spin_factor = st.body_spin_factor, ground_velocity = st.ground_velocity, ground_acceleration = st.ground_acceleration, air_velocity = st.air_velocity, air_acceleration = st.air_acceleration), steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tbump = {\n");
    for _ in 0..400 {
        let st = bump::Settings { scale_x_acc: r.range(0.5, 3.0), min_bump_mag: r.range(0.0, 10.0), min_bump_blend_value: r.range(0.0, 1.0), max_bump_mag: r.range(10.0, 40.0) };
        let a = if r.next() % 8 == 0 { [0.0; 4] } else { v4(&mut r, 40.0) };
        let m = r.bool();
        writeln!(s, "\t\t{},", obj!(a = a, mirrored = m, settings = Raw(obj!(scale_x_acc = st.scale_x_acc, min_bump_mag = st.min_bump_mag, min_bump_blend_value = st.min_bump_blend_value, max_bump_mag = st.max_bump_mag)), out = bump::coefficients(a, m, &st))).unwrap();
    }
    s.push_str("\t},\n\tclip = {\n");
    for _ in 0..40 {
        let frames = (2 + r.next() % 100) as f32;
        let fps = pick!(r, [30.0, 60.0, 15.0]);
        let base = r.range(0.5, 2.0);
        let mut c = ClipClock { frames, fps, base_speed: base, speed: 1.0, length: (frames - 1.0) / (fps * base), time: 0.0, previous_time: 0.0, loops_since_evaluation: 0, looping: r.bool(), phase_controlled: r.next() % 4 == 0 };
        let c0 = c;
        let mut steps = Vec::new();
        for _ in 0..40 {
            let op = r.next() % 10;
            let mut res = AdvanceResult { crossed_end: r.bool(), overshoot: r.range(0.0, 1.0), remaining_before_wrap: r.range(0.0, 1.0) };
            let res0 = res;
            let (dt, ph) = (r.range(0.0, 0.3), r.range(-0.2, 1.2));
            let (b, e) = (if r.next() % 6 == 0 { -1.0 } else { r.range(0.0, 1.0) }, r.range(0.0, 1.0));
            let a1 = r.range(0.25, 2.0);
            let t = r.range(0.0, 2.0);
            let mut status = 0u8;
            match op {
                0 => c.set_speed(a1),
                1 => c.set_time(t),
                2 => c.commit_evaluation(),
                _ => { c.advance(dt, ph, &mut res); status = c.attribute_status(b, e); }
            }
            steps.push(obj!(op = op, dt = dt, phase = ph, begin = b, end_ = e, speed = a1, time = t, res_in = Raw(obj!(crossed_end = res0.crossed_end, overshoot = res0.overshoot, remaining_before_wrap = res0.remaining_before_wrap)),
                res = Raw(obj!(crossed_end = res.crossed_end, overshoot = res.overshoot, remaining_before_wrap = res.remaining_before_wrap)), status = status, sample = c.sample_time(),
                clock = Raw(obj!(frames = c.frames, fps = c.fps, base_speed = c.base_speed, speed = c.speed, length = c.length, time = c.time, previous_time = c.previous_time, loops_since_evaluation = c.loops_since_evaluation, looping = c.looping, phase_controlled = c.phase_controlled))));
        }
        writeln!(s, "\t\t{{ clock = {}, steps = {{\n\t\t\t{}\n\t\t}} }},", obj!(frames = c0.frames, fps = c0.fps, base_speed = c0.base_speed, speed = c0.speed, length = c0.length, time = c0.time, previous_time = c0.previous_time, loops_since_evaluation = c0.loops_since_evaluation, looping = c0.looping, phase_controlled = c0.phase_controlled), steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n\tchannel = {\n");
    for _ in 0..30 {
        let mk = |r: &mut Rng| cp::ChannelSettings { priority: (r.next() % 4) as i32, keep_alive: r.bool(), mirrored: r.bool(), speed: r.range(0.5, 2.0), blend_in: pick!(r, [0.0, 0.25, r.range(0.0, 1.0)]), hold_during_blend_in: r.bool(), blend_out: pick!(r, [0.0, 0.25, r.range(0.0, 1.0)]), hold_during_blend_out: r.bool(), use_attributes: r.bool() };
        let st = mk(&mut r);
        let mut c = cp::ChannelPlayback::new(st);
        let sl = |x: &cp::ChannelSettings| Raw(obj!(priority = x.priority, keep_alive = x.keep_alive, mirrored = x.mirrored, speed = x.speed, blend_in = x.blend_in, hold_during_blend_in = x.hold_during_blend_in, blend_out = x.blend_out, hold_during_blend_out = x.hold_during_blend_out, use_attributes = x.use_attributes));
        let mut steps = Vec::new();
        for _ in 0..40 {
            let op = r.next() % 12;
            let (dt, len, t) = (r.range(0.0, 0.2), r.range(0.0, 2.0), r.range(0.0, 2.0));
            let st2 = mk(&mut r);
            let res = r.bool();
            let sec = r.range(0.0, 1.0);
            let crossed = r.bool();
            let out = match op {
                0 => { c.end(); Raw("nil".into()) }
                1 => { c.end_with(sec, res); Raw("nil".into()) }
                2 => { let ok = c.can_transition(res); if ok { c.transition(st2, res); } Raw(ok.l()) }
                3 => { c.did_advance(AdvanceResult { crossed_end: crossed, overshoot: 0.0, remaining_before_wrap: 0.0 }); Raw("nil".into()) }
                _ => Raw(c.advance(dt, len, t).l()),
            };
            steps.push(obj!(op = op, dt = dt, length = len, time = t, settings = sl(&st2), resurrect = res, seconds = sec, crossed = crossed, out = out, weight = c.weight, expired = c.expired()));
        }
        let base: Vec<AnimationAttribute> = { let mut v: Vec<_> = (0..(r.next() % 6)).map(|_| attr(&mut r)).collect(); v.sort_by(|a, b| a.name.0.cmp(&b.name.0)); v };
        let chan: Vec<AnimationAttribute> = { let mut v: Vec<_> = (0..(r.next() % 6)).map(|_| attr(&mut r)).collect(); v.sort_by(|a, b| a.name.0.cmp(&b.name.0)); v };
        let merged = c.merge_attributes(base.clone(), &chan);
        writeln!(s, "\t\t{{ settings = {}, steps = {{\n\t\t\t{}\n\t\t}}, base = {}, chan = {}, merged = {} }},", sl(&st).l(), steps.join(",\n\t\t\t"),
            base.iter().map(attr_l).collect::<Vec<_>>().l(), chan.iter().map(attr_l).collect::<Vec<_>>().l(), merged.iter().map(attr_l).collect::<Vec<_>>().l()).unwrap();
    }
    s.push_str("\t},\n\tcrouch = {\n");
    for _ in 0..20 {
        let a = crouching::AutoPumpSettings { maximum_crouch: gn::<4>(&mut r, 0.0, 1.0, 4.0, 1.0), sufficient_crouch: r.range(0.0, 0.5), standing_threshold: r.range(0.0, 0.3), rise_speed: r.range(0.0, 0.1), pump_speed: r.range(0.0, 0.1), potential_threshold: r.range(-1.0, 1.0), potential_blend: r.range(0.0, 1.0), intent_magnitude_start: r.range(0.0, 0.8), intent_angle_region: r.range(0.1, 1.5), crouch_time: r.range(0.0, 0.5), crouch_speed: r.range(0.0, 0.2) };
        let st = crouching::Settings { maximum_height: gn::<8>(&mut r, 0.0, 0.5, 3.0, 1.5), absorption_upforce: gn::<8>(&mut r, 0.0, 0.05, 0.3, 0.3), pump_maxspeed: gn::<8>(&mut r, 0.0, 0.05, 0.3, 0.3), minimum_height: r.range(0.0, 0.5), maximum_ratio: r.range(0.0, 1.0), maximum_delta_delta: r.range(0.0, 0.1), maximum_delta: r.range(0.0, 0.2), input_blend: r.range(-0.2, 1.2), pump_vertical_speed: r.range(0.0, 2.0), maximum_crouch_from_deck: r.range(0.0, 1.0), skateboard_damping: r.range(0.5, 1.0), maximum_force: r.range(1.0, 100.0), maximum_ground_force: r.range(1.0, 100.0), absorption_factor: r.range(0.0, 1.0), auto_pump: a.clone() };
        let ph = |r: &mut Rng| crouching::Physical { body_84: r.range(-2.0, 2.0), body_164: r.range(0.0, 10.0), body_188: r.range(-2.0, 2.0), force_516: r.range(-100.0, 100.0), ground_force_520: r.range(-100.0, 100.0), minimum_crouch_528: r.range(0.0, 0.3), deck_angle_532: r.range(0.0, 1.0), animation_height_72: r.range(0.0, 1.5) };
        let pl = |p: &crouching::Physical| Raw(obj!(body_84 = p.body_84, body_164 = p.body_164, body_188 = p.body_188, force_516 = p.force_516, ground_force_520 = p.ground_force_520, minimum_crouch_528 = p.minimum_crouch_528, deck_angle_532 = p.deck_angle_532, animation_height_72 = p.animation_height_72));
        let p0 = ph(&mut r);
        let mut state = crouching::State::begin(p0, &st);
        let f0 = state.fraction;
        let mut steps = Vec::new();
        let mut magnitude = 0.0f32;
        for _ in 0..50 {
            let p = ph(&mut r);
            if r.next() % 5 == 0 { magnitude = if magnitude > 0.5 { 0.0 } else { 1.0 }; }
            let it = crouching::Intents { auto_pump_angle: if r.next() % 4 == 0 { None } else { Some(r.range(-0.5, 0.5)) }, auto_pump_magnitude: if r.next() % 5 == 0 { None } else { Some(magnitude) }, crouch: if r.bool() { None } else { Some(r.range(0.0, 1.0)) }, hard_turn_crouch: if r.bool() { None } else { Some(r.range(0.0, 1.0)) }, manual: if r.bool() { None } else { Some(r.range(-1.0, 1.0)) }, motion_flag_108: r.bool() };
            let dt = r.range(0.0, 0.1);
            let o = state.update(p, it, dt, &st);
            steps.push(obj!(p = pl(&p), intents = Raw(obj!(auto_pump_angle = it.auto_pump_angle, auto_pump_magnitude = it.auto_pump_magnitude, crouch = it.crouch, hard_turn_crouch = it.hard_turn_crouch, manual = it.manual, motion_flag_108 = it.motion_flag_108)), dt = dt,
                out = Raw(obj!(height = o.height, new_auto_pump = o.new_auto_pump, player_controlled_pump = o.player_controlled_pump)), fraction = state.fraction));
        }
        let sl = Raw(obj!(maximum_height = st.maximum_height, absorption_upforce = st.absorption_upforce, pump_maxspeed = st.pump_maxspeed, minimum_height = st.minimum_height, maximum_ratio = st.maximum_ratio, maximum_delta_delta = st.maximum_delta_delta, maximum_delta = st.maximum_delta, input_blend = st.input_blend, pump_vertical_speed = st.pump_vertical_speed, maximum_crouch_from_deck = st.maximum_crouch_from_deck, skateboard_damping = st.skateboard_damping, maximum_force = st.maximum_force, maximum_ground_force = st.maximum_ground_force, absorption_factor = st.absorption_factor,
            auto_pump = Raw(obj!(maximum_crouch = a.maximum_crouch, sufficient_crouch = a.sufficient_crouch, standing_threshold = a.standing_threshold, rise_speed = a.rise_speed, pump_speed = a.pump_speed, potential_threshold = a.potential_threshold, potential_blend = a.potential_blend, intent_magnitude_start = a.intent_magnitude_start, intent_angle_region = a.intent_angle_region, crouch_time = a.crouch_time, crouch_speed = a.crouch_speed))));
        writeln!(s, "\t\t{{ settings = {}, begin = {}, fraction0 = {}, steps = {{\n\t\t\t{}\n\t\t}} }},", sl.l(), pl(&p0).l(), f0.l(), steps.join(",\n\t\t\t")).unwrap();
    }
    // output
    s.push_str("\t},\n\tsqt = {\n");
    let rsqt = |r: &mut Rng| Sqt { scale: v4(r, 2.0), rotation: v4(r, 1.0), translation: v4(r, 5.0) };
    let sqt_l = |q: &Sqt| Raw(obj!(scale = q.scale, rotation = q.rotation, translation = q.translation));
    for _ in 0..300 { let q = rsqt(&mut r); writeln!(s, "\t\t{},", obj!(input = sqt_l(&q), out = m_l(&output::sqt_to_matrix(q)))).unwrap(); }
    s.push_str("\t},\n\tsqt_local = {\n");
    for _ in 0..20 {
        let n = (r.next() % 9) as usize; let off = ((r.next() % 8) * 16) as u8;
        let padded = (n + 3) & !3; let src: Vec<Sqt> = (0..padded).map(|_| rsqt(&mut r)).collect();
        let mut dst: Vec<[[f32; 4]; 4]> = (0..padded + 3).map(|_| core::array::from_fn(|_| v4(&mut r, 9.0))).collect();
        let d0 = dst.clone();
        let res = output::sqt_to_local(n, off, &src, &mut dst);
        writeln!(s, "\t\t{},", obj!(n = n, offset = off as u32, src = src.iter().map(sqt_l).collect::<Vec<_>>(), dst = d0, out = res.ok(), result = dst)).unwrap();
    }
    s.push_str("\t},\n\thierarchy = {\n");
    for _ in 0..40 {
        let n = 1 + (r.next() % 10) as usize; let detached = (r.next() % 12) as i32 - 1;
        let parents: Vec<i32> = (0..n).map(|i| if i == 0 || r.next() % 5 == 0 { -1 } else { (r.next() % (n as u32 + 1)) as i32 - (if r.next() % 7 == 0 { 0 } else { 0 }) }).map(|p| p.min(n as i32 - 1)).collect();
        let local: Vec<[[f32; 4]; 4]> = (0..n).map(|_| core::array::from_fn(|_| v4(&mut r, 2.0))).collect();
        let mut dst: Vec<[[f32; 4]; 4]> = (0..n).map(|_| core::array::from_fn(|_| v4(&mut r, 2.0))).collect();
        let d0 = dst.clone();
        let ok = output::compose_hierarchy(n as i32, &parents, detached, &local, &mut dst).is_ok();
        let mut inplace = local.clone();
        let ok2 = output::compose_hierarchy_in_place(n as i32, &parents, detached, &mut inplace).is_ok();
        writeln!(s, "\t\t{},", obj!(n = n, detached = detached, parents = parents, local_ = local, dst = d0, ok = ok, out = dst, ok2 = ok2, inplace = inplace)).unwrap();
    }
    s.push_str("\t},\n\tintent_map = {\n");
    for _ in 0..20 {
        let mut m = IntentMap::default();
        let mut ops = Vec::new();
        for _ in 0..80 {
            let name = IntentName([r.next() % 70, r.next() % 2, 0, 0, 0, r.next() % 2]);
            let v = r.range(-1.0, 1.0);
            let op = r.next() % 5;
            let out = match op {
                0 => Raw(match m.insert(Intent { name, value: v }) { Ok(b) => b.l(), Err(_) => "\"err\"".into() }),
                1 => Raw(match m.set(name, v) { Ok(b) => b.l(), Err(_) => "\"err\"".into() }),
                2 => Raw(m.remove(name).l()),
                3 => Raw(m.get(name).l()),
                _ => { if r.next() % 10 == 0 { m.clear(); } Raw("nil".into()) }
            };
            let entries: Vec<Raw> = m.entries().map(|e| Raw(obj!(name = e.name.0, value = e.value))).collect();
            ops.push(obj!(op = op, name = name.0, value = v, out = out, len = m.len(), entries = entries));
        }
        let mut copy = IntentMap::default(); copy.replace_from(&m);
        let ce: Vec<Raw> = copy.entries().map(|e| Raw(obj!(name = e.name.0, value = e.value))).collect();
        writeln!(s, "\t\t{{ ops = {{\n\t\t\t{}\n\t\t}}, replaced = {} }},", ops.join(",\n\t\t\t"), ce.l()).unwrap();
    }
    s.push_str("\t},\n\tpacket = {\n");
    for _ in 0..40 {
        let n = (r.next() % 5) as u32;
        let mk = |r: &mut Rng, k: usize| (0..k).map(|_| core::array::from_fn(|_| v4(r, 2.0))).collect::<Vec<[[f32; 4]; 4]>>();
        let mut pose = pp::PhysicsPosePacket { bone_count: n, hierarchy: mk(&mut r, 5), local: mk(&mut r, 5), timestep: r.range(0.0, 1.0), foot_surface_ids: [r.next(), r.next()], flags: r.next(), board_flipped: r.bool(), mirrored: r.bool(), riding_switch: r.bool(), riding_fakie: r.bool(), weight_forwards: r.bool(), regular_stance: r.bool(), air_dismount_revert_frames: (r.next() % 9) as i32 };
        let pose_l = |p: &pp::PhysicsPosePacket| Raw(obj!(bone_count = p.bone_count, hierarchy = p.hierarchy.clone(), local_ = p.local.clone(), timestep = p.timestep, foot_surface_ids = p.foot_surface_ids, flags = p.flags, board_flipped = p.board_flipped, mirrored = p.mirrored, riding_switch = p.riding_switch, riding_fakie = p.riding_fakie, weight_forwards = p.weight_forwards, regular_stance = p.regular_stance, air_dismount_revert_frames = p.air_dismount_revert_frames));
        let mut fields = packet_reset::AdditionalResetFields { compression: r.range(0.0, 1.0), foot_ik_influence: [r.range(0.0, 1.0), r.range(0.0, 1.0)], next_step_position_valid: r.bool(), actor_flag_1904_bit23: r.bool(), actor_flag_1908_bit2: r.bool(), external_impulse_active: r.bool(), external_physics_input_active: r.bool(), externally_controlled: r.bool(), prevent_manual_respawn: r.bool(), ignore_respawn_reset_button: r.next() as u8, force_braking: r.bool(), truck_tightness: r.range(0.0, 1.0), wheel_hardness: r.range(0.0, 1.0), auxiliary_vectors: core::array::from_fn(|_| v4(&mut r, 1.0)), requested_physics_mode: r.next() % 5 };
        let fields_l = |f: &packet_reset::AdditionalResetFields| Raw(obj!(compression = f.compression, foot_ik_influence = f.foot_ik_influence, next_step_position_valid = f.next_step_position_valid, actor_flag_1904_bit23 = f.actor_flag_1904_bit23, actor_flag_1908_bit2 = f.actor_flag_1908_bit2, external_impulse_active = f.external_impulse_active, external_physics_input_active = f.external_physics_input_active, externally_controlled = f.externally_controlled, prevent_manual_respawn = f.prevent_manual_respawn, ignore_respawn_reset_button = f.ignore_respawn_reset_button, force_braking = f.force_braking, truck_tightness = f.truck_tightness, wheel_hardness = f.wheel_hardness, auxiliary_vectors = f.auxiliary_vectors, requested_physics_mode = f.requested_physics_mode));
        let pose0 = pose_l(&pose); let fields0 = fields_l(&fields);
        packet_reset::reset(&mut pose, &mut fields).unwrap();
        let after_reset = pose_l(&pose);
        let mut st = pp::SkaterPublicationState { orientation_bit31: r.bool(), mirrored: r.bool(), riding_fakie: r.bool(), weight_on_nose: r.bool(), relative_stance: (r.next() % 3) as i32, natural_stance: (r.next() % 2) as i32, request_bit16: r.bool(), request_bit15: r.bool(), air_dismount_revert_requested: r.bool(), air_dismount_revert_frames: (r.next() % 7) as i32, signal: if r.bool() { Some(pp::AnimationSignal { name_hash: r.next(), active: 1 }) } else { None } };
        let st_l = |x: &pp::SkaterPublicationState| Raw(obj!(orientation_bit31 = x.orientation_bit31, mirrored = x.mirrored, riding_fakie = x.riding_fakie, weight_on_nose = x.weight_on_nose, relative_stance = x.relative_stance, natural_stance = x.natural_stance, request_bit16 = x.request_bit16, request_bit15 = x.request_bit15, air_dismount_revert_requested = x.air_dismount_revert_requested, air_dismount_revert_frames = x.air_dismount_revert_frames, signal = x.signal.as_ref().map(|g| Raw(obj!(name_hash = g.name_hash, active = g.active))))); 
        let st0 = st_l(&st);
        let h = mk(&mut r, 5); let l = mk(&mut r, 5);
        let ts = r.range(0.0, 0.1) as f64;
        let name = ["signup", "", "Abc\u{e9}", "x"][(r.next() % 4) as usize];
        let ret = pp::publish_evaluated(&mut st, &h, &l, &mut pose, ts, name.as_bytes()).unwrap();
        writeln!(s, "\t\t{},", obj!(pose = pose0, fields = fields0, reset_pose = after_reset, reset_fields = fields_l(&fields), state = st0, h = h, l = l, ts = ts as f32, name = name, ret = ret, out_pose = pose_l(&pose), out_state = st_l(&st))).unwrap();
    }
    s.push_str("\t},\n\tsignal_hash = {\n");
    for name in ["signup", "", "A", "abcdefghijklmnopqrstuvwxyz0123456789", "\u{ff}\u{80}zz", "nul\0after"] {
        writeln!(s, "\t\t{{ {:?}, {} }},", name, pp::signal_hash(name.as_bytes())).unwrap();
    }
    s.push_str("\t},\n\tactor = {\n");
    struct Env { scene: Option<i32>, ignore: u8, slot: u8, tight: f32, hard: f32, mode: u32, log: Vec<String> }
    struct Set<'a> { e: *mut Env, _p: std::marker::PhantomData<&'a ()> }
    impl ap::PlayerPhysicsSettingsSource for Set<'_> { type Error = String;
        fn truck_tightness(&mut self, i: u32) -> Result<f32, String> { unsafe { (*self.e).log.push(format!("tight:{i}")); Ok((*self.e).tight) } }
        fn wheel_hardness(&mut self, i: u32) -> Result<f32, String> { unsafe { (*self.e).log.push(format!("hard:{i}")); Ok((*self.e).hard) } }
        fn requested_physics_mode(&mut self, i: u32) -> Result<u32, String> { unsafe { (*self.e).log.push(format!("mode:{i}")); Ok((*self.e).mode) } } }
    impl ap::ActorPublicationEnvironment for Env { type Error = String; type Settings = Set<'static>;
        fn current_scene_mode(&mut self) -> Result<Option<i32>, String> { self.log.push("scene".into()); Ok(self.scene) }
        fn ignore_respawn_reset_button(&mut self) -> Result<u8, String> { self.log.push("ignore".into()); Ok(self.ignore) }
        fn actor_subobject56_slot16(&mut self, a: &mut ap::ActorPublicationState) -> Result<u8, String> { self.log.push(format!("slot16:{}", a.flags1904)); Ok(self.slot) }
        fn capture_physics_settings(&mut self) -> Result<Set<'static>, String> { self.log.push("capture".into()); Ok(Set { e: self as *mut Env, _p: std::marker::PhantomData }) } }
    for _ in 0..60 {
        let mut env = Env { scene: [None, Some(19), Some(20), Some(3)][(r.next() % 4) as usize], ignore: r.next() as u8, slot: (r.next() % 3) as u8, tight: r.range(0.0, 1.0), hard: r.range(0.0, 1.0), mode: r.next() % 4, log: Vec::new() };
        let ext = |r: &mut Rng| ap::ExternalPhysicsInput { vectors: core::array::from_fn(|_| core::array::from_fn(|_| r.next())), flags: r.next() };
        let mut actor = ap::ActorPublicationState { flags1904: r.next(), flags1908: r.next(), external_controller_present: r.next() % 4 == 0, external_impulse: core::array::from_fn(|_| r.next()), external_physics: ext(&mut r), external_reset: ap::ExternalReset { transform: core::array::from_fn(|_| core::array::from_fn(|_| r.next())), byte64: r.next() as u8 }, player_index: r.next() % 4 };
        let actor_l = |a: &ap::ActorPublicationState| Raw(obj!(flags1904 = a.flags1904, flags1908 = a.flags1908, external_controller_present = a.external_controller_present, external_impulse = a.external_impulse, external_physics = Raw(obj!(vectors = a.external_physics.vectors, flags = a.external_physics.flags)), external_reset = Raw(obj!(transform = a.external_reset.transform, byte64 = a.external_reset.byte64)), player_index = a.player_index));
        let a0 = actor_l(&actor);
        let mut pose = pp::PhysicsPosePacket { bone_count: 0, hierarchy: vec![], local: vec![], timestep: 0.0, foot_surface_ids: [0; 2], flags: r.next(), board_flipped: false, mirrored: false, riding_switch: false, riding_fakie: false, weight_forwards: false, regular_stance: false, air_dismount_revert_frames: 0 };
        let flags0 = pose.flags;
        let mut fields = packet_reset::AdditionalResetFields { compression: 0.0, foot_ik_influence: [0.0; 2], next_step_position_valid: false, actor_flag_1904_bit23: false, actor_flag_1908_bit2: false, external_impulse_active: false, external_physics_input_active: false, externally_controlled: false, prevent_manual_respawn: false, ignore_respawn_reset_button: 0, force_braking: false, truck_tightness: 0.0, wheel_hardness: 0.0, auxiliary_vectors: [[0.0; 4]; 6], requested_physics_mode: 0 };
        let mut pf = ap::ActorPacketFields { external_impulse: [0; 4], external_physics: ext(&mut r), external_reset: ap::ExternalReset { transform: [[0; 4]; 4], byte64: 0 }, actor_flag_1904_bit29: false };
        let pf_flags0 = pf.external_physics.flags;
        ap::publish(&mut actor, &mut pose, &mut fields, &mut pf, &mut env).unwrap();
        writeln!(s, "\t\t{},", obj!(env = Raw(obj!(scene = env.scene, ignore = env.ignore, slot = env.slot, tight = env.tight, hard = env.hard, mode = env.mode)), actor = a0, flags = flags0, pf_flags = pf_flags0,
            log = env.log.clone(), out_actor = actor_l(&actor), out_flags = pose.flags,
            fields = Raw(obj!(actor_flag_1904_bit23 = fields.actor_flag_1904_bit23, actor_flag_1908_bit2 = fields.actor_flag_1908_bit2, external_impulse_active = fields.external_impulse_active, external_physics_input_active = fields.external_physics_input_active, externally_controlled = fields.externally_controlled, prevent_manual_respawn = fields.prevent_manual_respawn, ignore_respawn_reset_button = fields.ignore_respawn_reset_button, force_braking = fields.force_braking, truck_tightness = fields.truck_tightness, wheel_hardness = fields.wheel_hardness, requested_physics_mode = fields.requested_physics_mode)),
            pf = Raw(obj!(external_impulse = pf.external_impulse, external_physics = Raw(obj!(vectors = pf.external_physics.vectors, flags = pf.external_physics.flags)), external_reset = Raw(obj!(transform = pf.external_reset.transform, byte64 = pf.external_reset.byte64)), actor_flag_1904_bit29 = pf.actor_flag_1904_bit29)))).unwrap();
    }
    s.push_str("\t},\n\tset_data = {\n");
    for _ in 0..30 {
        let mut buffers = PoseBuffers::default();
        let nb = 3 + (r.next() % 4) as usize;
        let mut bufs = Vec::new(); let mut init = Vec::new();
        for _ in 0..nb {
            let len = 2 + (r.next() % 6) as usize;
            if r.bool() { let vals: Vec<[[f32; 4]; 4]> = (0..len).map(|_| core::array::from_fn(|_| v4(&mut r, 2.0))).collect(); init.push(Raw(obj!(len = len, values = vals.clone()))); bufs.push((buffers.matrices.initialized(vals), len)); }
            else { init.push(Raw(obj!(len = len))); bufs.push((buffers.matrices.allocate(len), len)); }
        }
        let max_units = 1 + (r.next() % 3) as u16;
        let mut q = SetDataQueue::new(buffers, std::num::NonZeroU16::new(max_units).unwrap());
        let mut cmds = Vec::new(); let mut ids = Vec::new();
        for _ in 0..(1 + r.next() % 6) {
            let bi = |r: &mut Rng| (r.next() as usize) % nb;
            let (a, b, c) = (bi(&mut r), bi(&mut r), bi(&mut r));
            let sl = |i: usize, r: &mut Rng| BoneSlice { buffer: bufs[i].0, first_bone: (r.next() as usize) % bufs[i].1 };
            let (sa, sb, sc) = (sl(a, &mut r), sl(b, &mut r), sl(c, &mut r));
            let set = r.bool(); let cnt = (r.next() % 3) as u8; let has_ext = r.bool(); let bones = (r.next() % 3) as u16;
            let update = if set { InternalUpdate::Set { source: sa, bone_count: cnt } } else { InternalUpdate::Preserve };
            let cmd = SetDataCommand::Matrix(CopyCommand { update, internal: sb, external: if has_ext { Some(sc) } else { None } });
            let dep_k: Option<usize> = if !ids.is_empty() && r.bool() { Some((r.next() as usize) % ids.len()) } else { None };
            let deps: Vec<Option<skate_core::animation::commands::batch::JobId>> = match dep_k { Some(k) => vec![Some(ids[k]), None], None => vec![None] };
            let res = q.enqueue(bones, cmd, &deps);
            let ok = res.is_ok(); if let Ok(id) = res { ids.push(id); }
            cmds.push(Raw(obj!(a = a, fa = sa.first_bone, b = b, fb = sb.first_bone, c = c, fc = sc.first_bone, set = set, count = cnt as u32, external = has_ext, bones = bones as u32, dep = dep_k, ok = ok)));
        }
        let done = q.submit().complete();
        let (ok, err, result) = match done {
            Ok(c) => { let b = c.buffers(); (true, Raw("nil".into()), bufs.iter().map(|(bf, len)| Raw((0..*len).map(|k| b.matrices.read(bf.at(k), 1).map(|v| m_l(&v[0])).unwrap_or(Raw("false".into()))).collect::<Vec<_>>().l())).collect::<Vec<_>>()) }
            Err(f) => { let j = format!("{:?}", f.job); let idx = j.split("index: ").nth(1).unwrap().trim_end_matches(" }").to_string(); (false, Raw(format!("{{ job = {}, cause = {:?} }}", idx, format!("{:?}", f.cause))), vec![]) }
        };
        writeln!(s, "\t\t{},", obj!(init = init, max_units = max_units as u32, cmds = cmds, ok = ok, err = err, result = result)).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/anim1.luau"), s).unwrap();
}
