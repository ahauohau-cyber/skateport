//! Эталон для skate_core::input: контроллер (Raw/Derived) по сценариям,
//! все производители намерений, Pad/история/xbox, распознавание жестов,
//! graph_intents, turn_remap, set_turning, turn_conditioner, power_sliding,
//! body_flip_signal, animation_packet.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use crate::riding2::flags;
use skate_core::input::*;
use skate_core::input::controller::{ActionMap, DerivedControllerInput, MagnitudeHeldSettings, RawControllerInput};
use skate_core::input::gameplay_map::GameplayActions;
use skate_core::point_graph::PointGraph;
use std::fmt::Write as _;

fn il<'a>(v: impl Iterator<Item = (&'a str, f32)>) -> Raw {
    Raw(format!("{{ {} }}", v.map(|(n, x)| format!("{{ name = {:?}, value = {} }}", n, x.l())).collect::<Vec<_>>().join(", ")))
}
fn gn<const N: usize>(r: &mut Rng, lo: f32, step_lo: f32, step_hi: f32, ys: f32) -> PointGraph<N> {
    let mut x = [0f32; N];
    let mut acc = lo;
    for k in 0..N { x[k] = acc; acc += r.range(step_lo, step_hi); }
    PointGraph { x, y: core::array::from_fn(|_| r.range(-ys, ys)) }
}
macro_rules! pick { ($r:expr, [$($x:expr),*]) => {{ let a: Vec<f32> = vec![$($x),*]; let i = ($r.next() as usize) % a.len(); a[i] }} }
fn stick(r: &mut Rng) -> f32 {
    match r.next() % 6 { 0 => 0.0, 1 => 1.0, 2 => -1.0, 3 => (r.range(-1.0, 1.0) * 8.0).round() / 8.0, _ => r.range(-1.0, 1.0) }
}
fn remap_l(t: &turn_remap::TurnRemap) -> Raw { Raw(obj!(magnitude = t.magnitude, angle = t.angle, angle_offset = t.angle_offset)) }
fn latch_words(l: &set_turning::SlideLatch) -> [u32; 5] { unsafe { std::mem::transmute::<set_turning::SlideLatch, [u32; 5]>(*l) } }
fn latch_from(w: [u32; 5]) -> set_turning::SlideLatch { unsafe { std::mem::transmute::<[u32; 5], set_turning::SlideLatch>(w) } }

struct Recorder(Vec<(u32, f32)>, GameplayActions);
impl ActionMap for Recorder {
    fn value(&mut self, a: u32) -> f32 { let v = self.1.value(a); self.0.push((a, v)); v }
    fn state(&mut self, a: u32) -> u8 { let v = self.1.state(a); self.0.push((a + 1000, v as f32)); v }
}

fn controller_scenarios(s: &mut String, r: &mut Rng) {
    s.push_str("\tcontroller = {\n");
    for sc in 0..25 {
        let mut words = [0u32; 26];
        if sc % 3 == 0 { for w in words.iter_mut() { *w = r.next(); } }
        let init_words = words;
        let mut c = DerivedControllerInput::from_words(words);
        let do_init = sc % 3 != 2;
        if do_init { c.initialize(); }
        let mut values = [0f32; 18];
        let mut ticks = Vec::new();
        for _ in 0..40 {
            for i in 0..18 {
                let change = r.next() % 4 == 0;
                if !change { continue; }
                values[i] = match i {
                    0 | 1 | 3 | 4 => stick(r),
                    6 | 7 => pick!(r, [0.0, 1.0, 1.0, 0.5, 0.99, r.range(0.0, 1.0)]),
                    _ => if r.next() % 3 == 0 { 1.0 } else { 0.0 },
                };
            }
            let dt = pick!(r, [1.0 / 30.0, 1.0 / 60.0, r.range(0.0, 0.2)]);
            let s502 = r.bool();
            let s104 = r.bool();
            let settings = MagnitudeHeldSettings { attribute: if r.bool() { Some(r.range(0.0, 1.0)) } else { None }, missing_attribute_value: r.range(0.0, 1.0) };
            let mut rec = Recorder(Vec::new(), GameplayActions::from_values(values));
            c.update(&mut rec, dt, s502, s104, &settings);
            let actor = if r.bool() { 0 } else { flags(r) | if r.bool() { 1 << (6 + r.next() % 6) } else { 0 } };
            let prefs = riding_intentions::PushPreferences { automatic_push_enabled: r.bool(), automatic_push_right: r.bool() };
            let phys = r.next() & 0x1c0;
            let air = r.next() % 4 == 0;
            let obs_z = [r.range(-2.0, 2.0), r.range(-2.0, 2.0), r.range(-2.0, 2.0), 0.0];
            let obs_c = if r.bool() { Some([r.range(-1.0, 1.0), 0.0, r.range(-1.0, 1.0), 0.0]) } else { None };
            let steer = steering_intentions::produce([f32::from_bits(c.words()[7]), f32::from_bits(c.words()[8])], actor);
            let off_a = offboard_intentions::produce_analog(&c, offboard_intentions::AnalogObservation { effective_skeleton_z: obs_z, biped_correction: obs_c });
            ticks.push(obj!(
                values = values, dt = dt, s502 = s502, s104 = s104, attribute = settings.attribute, missing = settings.missing_attribute_value,
                calls = Raw(format!("{{ {} }}", rec.0.iter().map(|(a, v)| format!("{{ {}, {} }}", a, v.l())).collect::<Vec<_>>().join(", "))),
                words = *c.words(), actor = actor, auto = prefs.automatic_push_enabled, auto_right = prefs.automatic_push_right,
                phys = phys, air = air, obs_z = obs_z, obs_c = obs_c,
                riding = il(riding_intentions::produce(&c, actor, prefs).iter().map(|i| (i.name, i.value))),
                trick = il(trick_intentions::produce(&c).iter().map(|i| (i.name, i.value))),
                manual = il(manual_intentions::produce(&c, actor).iter().map(|i| (i.name, i.value))),
                grind = il(grind_intentions::produce(&c).iter().map(|i| (i.name, i.value))),
                wipeout = il(wipeout_intentions::produce(&c, actor, phys).iter().map(|i| (i.name, i.value))),
                antic = il(anticipation_intentions::produce(&c).iter().map(|i| (i.name, i.value))),
                gestures = il(gameplay_gestures::produce(&c).iter().map(|i| (i.name, i.value))),
                off_d = il(offboard_intentions::produce_discrete(&c, actor, air).iter().map(|i| (i.name, i.value))),
                off_a = il(off_a.iter().map(|i| (i.name, i.value))),
                steer = Raw(obj!(turn = steer.turn, hard_turn = steer.hard_turn, hard_turn_crouch = steer.hard_turn_crouch)),
            ));
        }
        writeln!(s, "\t\t{{ init_words = {}, initialize = {}, ticks = {{\n\t\t\t{}\n\t\t}} }},", init_words.l(), do_init, ticks.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n");
    // Raw update отдельно: случайные предыдущие слова.
    s.push_str("\traw = {\n");
    for _ in 0..300 {
        let prev: [u32; 7] = core::array::from_fn(|_| r.next());
        let mut cur_w: [u32; 7] = core::array::from_fn(|_| r.next());
        if r.bool() { cur_w[6] |= 3 << 28; }
        let mut prev2 = prev;
        prev2[6] = (prev2[6] & !(3 << 28)) | ((r.next() % 4) << 28);
        let values: [f32; 18] = core::array::from_fn(|i| if i < 6 || i == 6 || i == 7 { stick(r) } else if r.bool() { 1.0 } else { 0.0 });
        let mut cur = RawControllerInput::from_words(cur_w);
        let (a, b) = (r.bool(), r.bool());
        let mut map = GameplayActions::from_values(values);
        cur.update(&RawControllerInput::from_words(prev2), &mut map, a, b);
        writeln!(s, "\t\t{},", obj!(previous = prev2, start = cur_w, values = values, s502 = a, s104 = b, out = *cur.words())).unwrap();
    }
    s.push_str("\t},\n");
}

fn pad_scenarios(s: &mut String, r: &mut Rng) {
    s.push_str("\tpad = {\n");
    for _ in 0..10 {
        let mut p = pad::Pad::new();
        let mut held = [0f32; 24];
        let mut steps = Vec::new();
        for _ in 0..80 {
            let n = match r.next() % 8 { 0 => (r.next() % 24) as usize, 1 => 0, _ => 24 };
            for h in held.iter_mut() { if r.next() % 5 == 0 { *h = pick!(r, [0.0, 1.0, 0.5, 0.51, r.range(0.0, 1.0)]); } }
            let vals = &held[..n];
            p.update(vals);
            let actions = if p.records().len() >= 24 { Some(*GameplayActions::from_pad(&p).values()) } else { None };
            steps.push(obj!(values = vals.to_vec(), count = p.count(), records = p.records().to_vec(), actions = actions));
        }
        writeln!(s, "\t\t{{\n\t\t\t{}\n\t\t}},", steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n\txbox = {\n");
    for _ in 0..400 {
        let st = xbox::XboxState {
            buttons: r.next() as u16,
            triggers: [r.next() as u8, r.next() as u8],
            left: [if r.next() % 5 == 0 { 0 } else { r.next() as i16 }, if r.next() % 5 == 0 { (r.next() % 9000) as i16 } else { r.next() as i16 }],
            right: [r.next() as i16, if r.bool() { i16::MIN } else { r.next() as i16 }],
        };
        let dev = if r.next() % 4 == 0 { 1 } else { 0 };
        writeln!(s, "\t\t{},", obj!(buttons = st.buttons as u32, triggers = [st.triggers[0] as u32, st.triggers[1] as u32], left = [st.left[0] as i32, st.left[1] as i32], right = [st.right[0] as i32, st.right[1] as i32], dev = dev as u32, out = xbox::convert(&st, dev))).unwrap();
    }
    s.push_str("\t},\n\thistory = {\n");
    for _ in 0..6 {
        let mut h = history::PadHistory::new();
        let mut pads = [pad::Pad::new(), pad::Pad::new(), pad::Pad::new(), pad::Pad::new()];
        let mut ops = Vec::new();
        for _ in 0..70 {
            if r.next() % 3 != 0 {
                let k = (r.next() % 5) as usize;
                let recs: Vec<Vec<f32>> = (0..k).map(|_| (0..(r.next() % 25)).map(|_| pick!(r, [0.0, 1.0, r.range(0.0, 1.0)])).collect()).collect();
                let mut hr: Vec<history::HistoryRecord> = recs.iter().map(|v| history::HistoryRecord::new(v)).collect();
                let clear: Vec<bool> = hr.iter().map(|_| r.next() % 6 == 0).collect();
                for (x, c) in hr.iter_mut().zip(&clear) { if *c { x.clear_count(); } }
                h.publish(&hr);
                ops.push(obj!(op = "publish", records = recs, clear = clear, read = h.read_index(), write = h.write_index()));
            } else {
                let ok = h.drain_to_latest(&mut pads);
                let pr: Vec<Raw> = pads.iter().map(|p| Raw(obj!(count = p.count(), records = p.records().to_vec()))).collect();
                ops.push(obj!(op = "drain", ok = ok, pads = pr, read = h.read_index(), write = h.write_index()));
            }
        }
        writeln!(s, "\t\t{{\n\t\t\t{}\n\t\t}},", ops.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n");
}

fn gesture_scenarios(s: &mut String, r: &mut Rng) {
    s.push_str("\tgesture = {\n");
    for _ in 0..24 {
        let np = 1 + (r.next() % 4) as usize;
        let patterns: Vec<gesture::Pattern> = (0..np).map(|i| {
            let n = 2 + (r.next() % 5) as usize;
            let mut a = r.range(-3.14, 3.14);
            let step = r.range(-1.2, 1.2);
            let points = (0..n).map(|_| { a += step; [a.cos(), a.sin()] }).collect();
            let t = r.range(0.25, 0.5);
            gesture::Pattern { name: format!("P{i}"), points, tolerance_squared: t * t }
        }).collect();
        let settings = gesture::Settings { maximum_misses: (r.next() % 6) as u8, difficulty: if r.bool() { 2 } else { 0 } };
        let mut g = gesture::Recognizer::new(patterns.clone()).unwrap();
        let mut steps = Vec::new();
        let mut target = 0usize;
        let mut idx = 0usize;
        for _ in 0..120 {
            let p = &patterns[target];
            let sample = if r.next() % 5 == 0 { [r.range(-1.0, 1.0), r.range(-1.0, 1.0)] } else {
                let pt = p.points[idx.min(p.points.len() - 1)];
                [pt[0] + r.range(-0.2, 0.2), pt[1] + r.range(-0.2, 0.2)]
            };
            if r.next() % 3 != 0 { idx += 1; }
            if idx > p.points.len() + 2 { idx = 0; target = (r.next() as usize) % patterns.len(); }
            let held = g.held(sample);
            let rec = g.sample(sample, settings);
            let rec = rec.map(|x| Raw(obj!(pattern = x.pattern, strength = x.strength, distance = x.distance, elapsed = x.elapsed)));
            steps.push(obj!(sample = sample, held = held, rec = rec));
        }
        let pl: Vec<Raw> = patterns.iter().map(|p| Raw(obj!(name = p.name.clone(), points = p.points.clone(), tolerance_squared = p.tolerance_squared))).collect();
        writeln!(s, "\t\t{{ patterns = {}, misses = {}, difficulty = {}, steps = {{\n\t\t\t{}\n\t\t}} }},", pl.l(), settings.maximum_misses, settings.difficulty, steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n");
}

fn graph_scenarios(s: &mut String, r: &mut Rng) {
    s.push_str("\tfilters = {\n");
    for _ in 0..600 {
        let v = pick!(r, [0.0, -0.0, 1.0, -1.0, 3.1415927, -3.1415927, r.range(-4.0, 4.0), r.range(-1.5, 1.5)]);
        let kind = r.next() % 10;
        writeln!(s, "\t\t{{ {}, {}, {} }},", v.l(), kind, graph_intents::apply_filter(v, kind).l()).unwrap();
    }
    s.push_str("\t},\n\tchains = {\n");
    for _ in 0..300 {
        let v = r.range(-4.0, 4.0);
        let f: [u32; 4] = core::array::from_fn(|_| r.next() % 10);
        let st = if r.next() % 4 == 0 { None } else { Some((r.bool(), r.bool())) };
        let out = graph_intents::filter_chain(v, f, st);
        writeln!(s, "\t\t{},", obj!(value = v, filters = f, stance = st.map(|(a, b)| [a, b]), out = out)).unwrap();
    }
    s.push_str("\t},\n\tmg = {\n");
    fn m(x: graph_intents::IntentMutation) -> Raw {
        match x { graph_intents::IntentMutation::None => Raw("{ kind = \"None\" }".into()), graph_intents::IntentMutation::Remove => Raw("{ kind = \"Remove\" }".into()), graph_intents::IntentMutation::Set(v) => Raw(format!("{{ kind = \"Set\", value = {} }}", v.l())) }
    }
    for _ in 0..40 {
        let mg = graph_intents::CreateMgIntent { on_update: r.bool(), default_value: if r.bool() { Some(r.range(-1.0, 1.0)) } else { None }, scale: r.range(-2.0, 2.0), filters: core::array::from_fn(|_| r.next() % 10) };
        let mut created = r.bool();
        let created0 = created;
        let mut steps = Vec::new();
        for k in 0..12 {
            let av = if r.bool() { Some(r.range(-1.0, 1.0)) } else { None };
            let st = if r.next() % 4 == 0 { None } else { Some((r.bool(), r.bool())) };
            let (op, out) = if k == 0 || r.next() % 6 == 0 { ("enter", mg.enter(&mut created, av, st)) } else if r.next() % 10 == 0 { ("exit", mg.exit()) } else { ("update", mg.update(&mut created, av, st)) };
            steps.push(obj!(op = op, action = av, stance = st.map(|(a, b)| [a, b]), out = m(out), created = created));
        }
        writeln!(s, "\t\t{{ on_update = {}, default_value = {}, scale = {}, filters = {}, start = {}, steps = {{ {} }} }},",
            mg.on_update, mg.default_value.l(), mg.scale.l(), mg.filters.l(), created0, steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n");
}

fn remap(r: &mut Rng) -> turn_remap::TurnRemap {
    turn_remap::TurnRemap { magnitude: gn::<16>(r, 0.0, 0.05, 0.25, 1.5), angle: gn::<16>(r, 0.0, 0.05, 0.25, 3.0), angle_offset: r.range(-1.0, 1.0) }
}

fn turning_scenarios(s: &mut String, r: &mut Rng) {
    s.push_str("\tremap = {\n");
    for _ in 0..10 {
        let t = remap(r);
        let mut cases = Vec::new();
        for _ in 0..60 {
            let i = [stick(r), stick(r)];
            cases.push(obj!(input = i, out = t.apply(i)));
        }
        writeln!(s, "\t\t{{ remap = {}, cases = {{ {} }} }},", remap_l(&t).l(), cases.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tset_turning = {\n");
    for _ in 0..12 {
        let settings = set_turning::Settings {
            remaps: [remap(r), remap(r)],
            speed_tuck: gn::<8>(r, 0.0, 0.1, 2.0, 1.0),
            blend: gn::<8>(r, 0.0, 0.02, 0.2, 1.0),
            speed_threshold: r.range(0.0, 5.0),
            maximum_delta: r.range(0.01, 0.5),
            override_turn: r.range(-1.0, 1.0),
        };
        let mut st = set_turning::State { elapsed: 0.0, smoothed: 0.0, mode: 2 };
        if r.bool() { st = set_turning::State { elapsed: r.range(0.0, 1.0), smoothed: r.range(-1.0, 1.0), mode: r.next() % 3 }; }
        let st0 = st;
        let mut words: [u32; 5] = core::array::from_fn(|_| r.next() & 0xf000_0000);
        words[0] = r.range(0.0, 1.0).to_bits();
        words[2] = r.range(0.0, 1.0).to_bits();
        let w0 = words;
        let mut steps = Vec::new();
        for _ in 0..40 {
            let mut w = words;
            for &i in &[1usize, 3, 4] { if r.next() % 4 == 0 { w[i] ^= [0x8000_0000u32, 0x4000_0000, 0x2000_0000][(r.next() % 3) as usize]; } }
            let pre = w;
            let mut latch = latch_from(w);
            let phys = set_turning::Physical { field_32: stick(r), field_36: stick(r), field_52: r.range(0.0, 1.0), field_56: stick(r), field_60: r.range(0.0, 1.0), body_168: r.range(-10.0, 10.0) };
            let stance = (r.bool(), r.bool());
            let dt = pick!(r, [1.0 / 30.0, r.range(0.0, 0.1)]);
            let intents = set_turning::Intents { fakie_turn: if r.bool() { Some(r.range(-1.0, 1.0)) } else { None }, mode_0_slide: if r.bool() { Some(r.range(-1.0, 1.0)) } else { None }, mode_1_slide: if r.bool() { Some(r.range(-1.0, 1.0)) } else { None } };
            let mut em = Vec::new();
            set_turning::update(&mut st, &mut latch, phys, stance, dt, &settings, intents, |a, v| em.push((format!("{a:?}"), v)));
            words = latch_words(&latch);
            steps.push(obj!(latch_in = pre, physical = Raw(obj!(field_32 = phys.field_32, field_36 = phys.field_36, field_52 = phys.field_52, field_56 = phys.field_56, field_60 = phys.field_60, body_168 = phys.body_168)),
                stance = [stance.0, stance.1], dt = dt,
                intents = Raw(obj!(fakie_turn = intents.fakie_turn, mode_0_slide = intents.mode_0_slide, mode_1_slide = intents.mode_1_slide)),
                emitted = Raw(format!("{{ {} }}", em.iter().map(|(n, v)| format!("{{ {:?}, {} }}", n, v.l())).collect::<Vec<_>>().join(", "))),
                latch = words, state = Raw(obj!(elapsed = st.elapsed, smoothed = st.smoothed, mode = st.mode))));
        }
        let sl = Raw(obj!(remaps = [remap_l(&settings.remaps[0]), remap_l(&settings.remaps[1])], speed_tuck = settings.speed_tuck, blend = settings.blend, speed_threshold = settings.speed_threshold, maximum_delta = settings.maximum_delta, override_turn = settings.override_turn));
        writeln!(s, "\t\t{{ settings = {}, state = {}, latch = {}, steps = {{\n\t\t\t{}\n\t\t}} }},", sl.l(), obj!(elapsed = st0.elapsed, smoothed = st0.smoothed, mode = st0.mode), w0.l(), steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n\tconditioner = {\n");
    for _ in 0..12 {
        let mut p: [f32; 13] = core::array::from_fn(|_| r.range(0.05, 1.0));
        p[10] = r.range(0.5, 3.0); p[11] = r.range(1.0, 10.0); p[12] = r.range(0.5, 2.0);
        let settings = turn_conditioner::Settings {
            filter_coefficients: core::array::from_fn(|_| [r.range(0.0, 1.0), r.range(0.0, 1.0), r.range(0.0, 1.0), r.range(0.05, 1.0)]),
            input_curve: gn::<8>(r, 0.0, 0.05, 0.3, 1.5),
            quickness_curve: gn::<8>(r, 0.0, 0.05, 0.3, 1.5),
            speed_curve: gn::<8>(r, 0.0, 0.5, 2.0, 1.5),
            smoothing_curve: gn::<4>(r, -1.0, 0.2, 1.0, 1.0),
            parameters: p,
        };
        let mut st = turn_conditioner::State { history: core::array::from_fn(|_| if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }), filters: core::array::from_fn(|_| core::array::from_fn(|_| r.range(-0.5, 0.5))) };
        let st0 = st;
        let mut steps = Vec::new();
        for k in 0..50 {
            if k == 25 && r.bool() { st.reset_history(); steps.push(obj!(reset = true, history = st.history, filters = st.filters)); continue; }
            let input = turn_conditioner::Input { body_160: r.range(0.0, 12.0), body_176: r.range(-1.0, 1.0), bundle_36_field_160: r.range(-3.0, 3.0), bundle_32_field_264: stick(r), animation_152: (r.next() % 3) as u8, animation_156: (r.next() % 2) as u8 };
            let out = turn_conditioner::update(&mut st, input, &settings);
            steps.push(obj!(input = Raw(obj!(body_160 = input.body_160, body_176 = input.body_176, bundle_36_field_160 = input.bundle_36_field_160, bundle_32_field_264 = input.bundle_32_field_264, animation_152 = input.animation_152, animation_156 = input.animation_156)), out = out, history = st.history, filters = st.filters));
        }
        let sl = Raw(obj!(filter_coefficients = settings.filter_coefficients, input_curve = settings.input_curve, quickness_curve = settings.quickness_curve, speed_curve = settings.speed_curve, smoothing_curve = settings.smoothing_curve, parameters = settings.parameters));
        writeln!(s, "\t\t{{ settings = {}, state = {}, steps = {{\n\t\t\t{}\n\t\t}} }},", sl.l(), obj!(history = st0.history, filters = st0.filters), steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n\tpower = {\n");
    for _ in 0..12 {
        let settings = power_sliding::Settings { minimum_speed: r.range(0.0, 3.0), minimum_slide_time: r.range(0.0, 0.5), stop_time: gn::<4>(r, -1.0, 0.2, 0.8, 1.0), speed_response: gn::<4>(r, 0.0, 0.5, 3.0, 1.0), angle_response: gn::<4>(r, -1.0, 0.2, 0.8, 1.0) };
        let mut st = power_sliding::State { elapsed: r.range(0.0, 1.0), previous_right: r.range(-1.0, 1.0), previous_left: r.range(-1.0, 1.0), flags: r.next() & 0xe000_0000 };
        let st0 = st;
        let mut latch: [u32; 5] = core::array::from_fn(|i| if i % 2 == 0 { r.range(0.0, 0.3).to_bits() } else { r.next() });
        let l0 = latch;
        let mut steps = Vec::new();
        for _ in 0..50 {
            let input = power_sliding::Input { category: if r.next() % 5 == 0 { r.next() % 3 } else { 1 }, speed: r.range(0.0, 6.0), right_slide: if r.bool() { Some(r.range(-1.0, 1.0)) } else { None }, left_slide: if r.bool() { Some(r.range(-1.0, 1.0)) } else { None }, right_query: r.bool(), left_query: r.bool(), graph_scalar: r.range(-1.0, 1.0) };
            let clocks: [f32; 3] = core::array::from_fn(|_| pick!(r, [1.0 / 30.0, r.range(0.0, 0.1)]));
            let mut ci = 0;
            power_sliding::update(&mut st, &mut latch, input, &settings, || { let v = clocks[ci]; ci += 1; v });
            steps.push(obj!(input = Raw(obj!(category = input.category, speed = input.speed, right_slide = input.right_slide, left_slide = input.left_slide, right_query = input.right_query, left_query = input.left_query, graph_scalar = input.graph_scalar)), clocks = clocks, calls = ci, latch = latch, state = Raw(obj!(elapsed = st.elapsed, previous_right = st.previous_right, previous_left = st.previous_left, flags = st.flags))));
        }
        let sl = Raw(obj!(minimum_speed = settings.minimum_speed, minimum_slide_time = settings.minimum_slide_time, stop_time = settings.stop_time, speed_response = settings.speed_response, angle_response = settings.angle_response));
        writeln!(s, "\t\t{{ settings = {}, state = {}, latch = {}, steps = {{\n\t\t\t{}\n\t\t}} }},", sl.l(), obj!(elapsed = st0.elapsed, previous_right = st0.previous_right, previous_left = st0.previous_left, flags = st0.flags), l0.l(), steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n\talignment = {\n");
    for i in 0..300 {
        let inp = if i % 10 == 0 { None } else {
            let v = if i % 7 == 0 { [r.range(-0.01, 0.01), 0.0, r.range(-0.01, 0.01), 0.0] } else { [r.range(-8.0, 8.0), r.range(-1.0, 1.0), r.range(-8.0, 8.0), r.range(-1.0, 1.0)] };
            Some((v, [r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0)], (r.next() % 3) as u8))
        };
        let out = power_sliding::alignment(inp);
        let il = inp.map(|(a, b, c)| Raw(format!("{{ {}, {}, {} }}", a.l(), b.l(), c)));
        writeln!(s, "\t\t{},", obj!(input = il, out = out)).unwrap();
    }
    s.push_str("\t},\n\tbody_flip = {\n");
    for _ in 0..12 {
        let settings = body_flip_signal::Settings { gesture_window: r.range(0.05, 0.5), takeoff_window: r.range(0.05, 0.5) };
        let mut st = body_flip_signal::State::default();
        let begin = r.bool();
        if begin { st.begin(settings); }
        let mut steps = Vec::new();
        for _ in 0..50 {
            let present = [r.next() % 6 == 0, r.next() % 6 == 0];
            let cat = if r.next() % 3 == 0 { r.next() % 4 } else { 2 };
            let dt = pick!(r, [1.0 / 30.0, r.range(0.0, 0.1)]);
            if r.next() % 25 == 0 { st.begin(settings); steps.push("{ begin = true }".to_string()); }
            let out = st.update(present, cat, dt, settings);
            steps.push(obj!(present = present, category = cat, dt = dt, out = out));
        }
        writeln!(s, "\t\t{{ gesture_window = {}, takeoff_window = {}, begin = {}, steps = {{ {} }} }},", settings.gesture_window.l(), settings.takeoff_window.l(), begin, steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n\tpacket = {\n");
    for _ in 0..100 {
        let src = animation_packet::AnimationPacketFields {
            stance_byte: r.next() as u8, timestep: r.range(0.0, 0.1), scalar_10388: r.range(-5.0, 5.0),
            flags_10375_10496_10784: [r.next() as u8, r.next() as u8, r.next() as u8],
            vector_10480: core::array::from_fn(|_| r.next()), matrix_10704: core::array::from_fn(|_| core::array::from_fn(|_| r.next())),
            byte_10768: r.next() as u8, truck_tightness: r.range(0.0, 1.0), scalar_10792: r.range(-1.0, 1.0), flag_10371: r.next() as u8,
        };
        let mut out = animation_packet::ProcessedPacketFields { flags_2468: r.next(), flags_2476: r.next(), timestep: 0.0, scalar_2668: 0.0, vector_1520: [0; 4], matrix_1536: [[0; 4]; 4], byte_1600: 0, truck_tightness: 0.0, scalar_2764: 0.0 };
        let (f68, f76) = (out.flags_2468, out.flags_2476);
        animation_packet::publish(&src, &mut out);
        writeln!(s, "\t\t{},", obj!(
            source = Raw(obj!(stance_byte = src.stance_byte, timestep = src.timestep, scalar_10388 = src.scalar_10388, flags_10375_10496_10784 = src.flags_10375_10496_10784, vector_10480 = src.vector_10480, matrix_10704 = src.matrix_10704, byte_10768 = src.byte_10768, truck_tightness = src.truck_tightness, scalar_10792 = src.scalar_10792, flag_10371 = src.flag_10371)),
            flags_2468 = f68, flags_2476 = f76,
            out = Raw(obj!(flags_2468 = out.flags_2468, flags_2476 = out.flags_2476, timestep = out.timestep, scalar_2668 = out.scalar_2668, vector_1520 = out.vector_1520, matrix_1536 = out.matrix_1536, byte_1600 = out.byte_1600, truck_tightness = out.truck_tightness, scalar_2764 = out.scalar_2764)))).unwrap();
    }
    s.push_str("\t},\n");
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x1a9e_7_0002);
    let mut s = format!("-- Сгенерировано golden/src/input.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");
    s.push_str("\tatan = {\n");
    for i in 0..2000 {
        let v = match i { 0 => 0.0, 1 => -0.0, 2 => f32::INFINITY, 3 => f32::NEG_INFINITY, 4 => 1.0, 5 => -1.0, 6 => 1e30, 7 => f32::NAN, _ => if i % 3 == 0 { r.range(-1.2, 1.2) } else { r.range(-1.0, 1.0) / r.range(0.001, 1.0) } };
        writeln!(s, "\t\t{{ {}, {} }},", v.l(), atan(v).l()).unwrap();
    }
    s.push_str("\t},\n");
    s.push_str("\tatan2 = {\n");
    for i in 0..5000u32 {
        let (y, x) = if i % 3 == 0 { (f32::from_bits(r.next() ^ (r.next() << 16)), f32::from_bits(r.next() ^ (r.next() << 16))) } else { (r.range(-1.0, 1.0), r.range(-1.0, 1.0)) };
        writeln!(s, "\t\t{{ {}, {}, {} }},", y.l(), x.l(), y.atan2(x).l()).unwrap();
    }
    for &y in &[0.0f32, -0.0, 1.0, -1.0, f32::INFINITY, f32::NEG_INFINITY, f32::NAN, 1e-40] { for &x in &[0.0f32, -0.0, 1.0, -1.0, f32::INFINITY, f32::NEG_INFINITY, f32::NAN, 1e30, -1e30] {
        writeln!(s, "\t\t{{ {}, {}, {} }},", y.l(), x.l(), y.atan2(x).l()).unwrap();
    } }
    s.push_str("\t},\n");
    controller_scenarios(&mut s, &mut r);
    pad_scenarios(&mut s, &mut r);
    gesture_scenarios(&mut s, &mut r);
    graph_scenarios(&mut s, &mut r);
    turning_scenarios(&mut s, &mut r);
    s.push_str("}\n");
    std::fs::write(format!("{out_dir}/input.luau"), s).unwrap();
}
fn atan(v: f32) -> f32 { angle::atan(v) }
