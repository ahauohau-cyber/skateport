//! Эталон для animation/skeleton_input, animation/vbr и skate-data/abin:
//! пакеты атрибутов через process_attributes, разбор стоковых банков
//! OnBoard/OffBoard и VBR-декодирование настоящих клипов.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::animation::output::attributes::{AnimationAttribute, AttributeName, AttributePayload, MotionGraphAttribute};
use skate_core::animation::output::packet_reset::RESET_POSE;
use skate_core::animation::skeleton_input::{attribute_finalization::*, catalog::SCALAR_ATTRIBUTES, contact_events::*, extended_attributes::ExtendedAttributes, name::encode, process_attributes::process, scalar_attributes::{AnimationControlOutput, ScalarAttributeInputs}};
use skate_core::animation::vbr::VbrDecoder;
use skate_core::input::controller::ActionMap;
use skate_data::abin::{Bank, RecordData};
use std::fmt::Write as _;

struct Map(Vec<(u32, f32)>);
impl ActionMap for Map {
    fn value(&mut self, k: u32) -> f32 { let v = (k % 7) as f32 * 0.25 - 0.75; self.0.push((k, v)); v }
    fn state(&mut self, _: u32) -> u8 { 0 }
}
fn attr_l(a: &AnimationAttribute) -> Raw {
    let p: Vec<Raw> = a.payload.0.iter().map(|x| Raw(match x { Some(v) => v.to_string(), None => "false".into() })).collect();
    Raw(obj!(payload = p, begin_time = a.begin_time, end_time = a.end_time, name = a.name.0, status = a.status, kind = a.kind, sequence_id = a.sequence_id))
}
fn fields_l(f: &ScalarAttributeInputs) -> Raw {
    Raw(obj!(flags2468 = f.flags2468, flags2472 = f.flags2472, flags2476 = f.flags2476, flags2484 = f.flags2484, flags2488 = f.flags2488, board_adjust = f.board_adjust, balance = f.balance, spin = f.spin, body_spin = f.body_spin, brake = f.brake, turn = f.turn, turn_scale = f.turn_scale, magnitude_scale = f.magnitude_scale, animation_end_com = f.animation_end_com, animation_translation = f.animation_translation, animation_time = f.animation_time, animation_physics_blend_seconds = f.animation_physics_blend_seconds, cadence_end_percent = f.cadence_end_percent, raw_turn = f.raw_turn, hard_turn = f.hard_turn, slide = f.slide))
}
fn extra_l(e: &ExtendedAttributes) -> Raw {
    Raw(obj!(flags2480 = e.flags2480, grind_translation = e.grind_translation, grind_stability_nudge = e.grind_stability_nudge, grind_up_down = e.grind_up_down, grind_grab_min_height = e.grind_grab_min_height, physical_body_spin = e.physical_body_spin, world_grab_y = e.world_grab_y, world_grab_z = e.world_grab_z, offboard_turn = e.offboard_turn, offboard_magnitude = e.offboard_magnitude, biped_world_x = e.biped_world_x, biped_world_z = e.biped_world_z, look_x = e.look_x, look_y = e.look_y, object_move_z = e.object_move_z, object_move_x = e.object_move_x, object_move_rotation = e.object_move_rotation, wipeout_control = e.wipeout_control, offboard_jump = e.offboard_jump, wipeout_gesture = e.wipeout_gesture, body_adjust = e.body_adjust, biped_start_angle = e.biped_start_angle, biped_spin_angle = e.biped_spin_angle, biped_animation_time = e.biped_animation_time, footstep_strength = e.footstep_strength, jump_strength = e.jump_strength, jump_controls = e.jump_controls, revert_direction = e.revert_direction))
}
fn rng_l(r: &std::ops::Range<usize>) -> Raw { Raw(format!("{{ {}, {} }}", r.start, r.end)) }

pub fn write(out_dir: &str, asset_root: &str) {
    let mut r = Rng(0xa1e0_0003);
    let mut s = format!("-- Сгенерировано golden/src/anim3.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");
    // skeleton_input
    s.push_str("\tprocess = {\n");
    let names = [encode(b"Trajectory"), encode(b"RightToeBase"), encode(b"LeftToeBase"), encode(b"righthand")];
    for _ in 0..120 {
        let mut fields = ScalarAttributeInputs::reset(r.next(), r.next());
        if r.bool() { fields.flags2476 = r.next(); fields.flags2484 = r.next(); }
        let mut extra = ExtendedAttributes::reset(r.range(0.0, 1.0));
        if r.bool() { extra.flags2480 = r.next() & 0x1000; }
        let mut contacts = ContactEventState { bone: (r.next() % 4) as i32 - 1, push_speed: r.range(0.0, 5.0) };
        let mut cached = JumpAttributeState::new();
        if r.bool() { cached.height_override = r.range(0.0, 1.0); cached.height_override_active = r.bool(); cached.prepared_controls = [r.range(-1.0, 1.0), r.range(-1.0, 1.0)]; }
        let mut output = AnimationControlOutput { grind_name: encode(b""), flags: r.next() };
        let f0 = fields_l(&fields); let e0 = extra_l(&extra);
        let c0 = Raw(obj!(bone = contacts.bone, push_speed = contacts.push_speed));
        let j0 = Raw(obj!(prepared_controls = cached.prepared_controls, height_override = cached.height_override, height_override_active = cached.height_override_active));
        let o0 = Raw(obj!(grind_name = output.grind_name.0, flags = output.flags));
        let mut hierarchy = [RESET_POSE; 4];
        for m in hierarchy.iter_mut() { m[3] = [r.range(-0.2, 0.2), r.range(-0.2, 0.2), r.range(-0.2, 0.2), 0.0]; }
        let pose = ContactEventPose { bone_names: &names, hierarchy: &hierarchy, trajectory_bone: (r.next() % 5) as usize, right_toe_bone: (r.next() % 3) as i32, timestep: [1.0 / 60.0, 1.0 / 30.0][(r.next() % 2) as usize] };
        let fin = FinalizationInput { select_jump_extremes: r.bool(), low_jump_threshold: r.range(0.0, 0.5), high_jump_threshold: r.range(0.5, 1.0), allow_height_override: r.bool(), use_prepared_controls: r.bool(), external_impulse_active: r.bool(), animation_flags: r.next() };
        let mut attrs = Vec::new();
        for _ in 0..(r.next() % 12) {
            let mut a = match r.next() % 6 {
                0 => { let mut e = MotionGraphAttribute { name: [encode(b"push_contact"), encode(b"brake_contact"), encode(b"right_hand_grab"), encode(b"left_hand_grab"), encode(b"other")][(r.next() % 5) as usize], value: 0.0 }.to_animation();
                    e.kind = 3; e.status = [4u8, 8, 2, 12][(r.next() % 4) as usize];
                    let bone = names[(r.next() % 4) as usize]; let strength = [1.0f32, -1.0, 0.5][(r.next() % 3) as usize];
                    e.payload = AttributePayload(std::array::from_fn(|i| if i < 5 { Some(bone.0[i]) } else { Some(strength.to_bits()) })); e }
                1 => MotionGraphAttribute { name: AttributeName([r.next() % 5, 0, 0, 0, 0]), value: r.range(-1.0, 1.0) }.to_animation(),
                _ => MotionGraphAttribute { name: SCALAR_ATTRIBUTES[(r.next() as usize) % SCALAR_ATTRIBUTES.len()].encoded_name, value: r.range(-1.0, 1.0) }.to_animation(),
            };
            if r.next() % 20 == 0 { a.payload.0[0] = None; }
            if r.next() % 15 == 0 { a.kind = 1; }
            attrs.push(a);
        }
        let mut map = Map(Vec::new());
        let has_map = r.next() % 4 != 0;
        let res = process(&attrs, &pose, &mut fields, &mut extra, &mut contacts, &mut cached, &mut output, fin, if has_map { Some(&mut map) } else { None });
        writeln!(s, "\t\t{},", obj!(fields = f0, extra = e0, contacts = c0, cached = j0, output = o0, hierarchy = hierarchy, trajectory_bone = pose.trajectory_bone, right_toe_bone = pose.right_toe_bone, timestep = pose.timestep,
            fin = Raw(obj!(select_jump_extremes = fin.select_jump_extremes, low_jump_threshold = fin.low_jump_threshold, high_jump_threshold = fin.high_jump_threshold, allow_height_override = fin.allow_height_override, use_prepared_controls = fin.use_prepared_controls, external_impulse_active = fin.external_impulse_active, animation_flags = fin.animation_flags)),
            attrs = attrs.iter().map(attr_l).collect::<Vec<_>>(), has_map = has_map, err = res.is_err(),
            out_fields = fields_l(&fields), out_extra = extra_l(&extra), out_contacts = Raw(obj!(bone = contacts.bone, push_speed = contacts.push_speed)),
            out_cached = Raw(obj!(prepared_controls = cached.prepared_controls, height_override = cached.height_override, height_override_active = cached.height_override_active)),
            out_output = Raw(obj!(grind_name = output.grind_name.0, flags = output.flags)), calls = map.0.iter().map(|(k, _)| *k).collect::<Vec<_>>())).unwrap();
    }
    s.push_str("\t},\n\tbanks = {\n");
    for name in ["OnBoard", "OffBoard"] {
        let bank = Bank::load(&std::path::Path::new(asset_root).join(format!("private/stock/data/anim/{name}.abin"))).unwrap();
        bank.validate_positional_parts().unwrap();
        let h = bank.hierarchy().unwrap();
        let hl = Raw(obj!(offset = h.offset, bone_count = h.bone_count as u32, has_trajectory = h.has_trajectory, parents = h.parents.clone(), mirrors = h.mirrors.clone(), bone_names = h.bone_names.clone(),
            parts = h.parts.iter().map(|p| Raw(obj!(name = p.name.clone(), bone_count = p.bone_count, sqt_offset = p.sqt_offset, flags = p.flags as u32, encoded_id = p.encoded_id as u32))).collect::<Vec<_>>()));
        let mut records = Vec::new();
        let n = bank.records().len();
        for (i, rec) in bank.records().iter().enumerate() {
            if i % 23 != 0 && i + 1 != n { continue; }
            let hd = &rec.header;
            let parts_l = |parts: &Vec<skate_data::abin::PartEntry>| parts.iter().map(|e| Raw(obj!(table_index = e.table_index, table_offset = e.table_offset, raw_word = e.raw_word, encoded_id = e.encoded_id as u32,
                part = e.part.as_ref().map(|p| Raw(obj!(offset = p.offset, header_word = p.header_word, compressed_size = p.compressed_size, compression_header_relative = p.compression_header_relative, compressed_data_relative = p.compressed_data_relative, channel_count = p.channel_count as u32, compression_header = rng_l(&p.compression_header), compressed_data = rng_l(&p.compressed_data), channel_weights = p.channel_weights.as_ref().map(rng_l))))))).collect::<Vec<_>>();
            let data = match &rec.data {
                RecordData::Clip(c) => Raw(obj!(kind = "Clip", value = Raw(obj!(fps_bits = c.fps_bits, frame_count_bits = c.frame_count_bits, base_speed_bits = c.base_speed_bits, flags = c.flags, loop_translation_words = c.loop_translation_words, loop_rotation_words = c.loop_rotation_words, attribute_offset = c.attribute_offset, attribute_count = c.attribute_count as u32, parts = parts_l(&c.parts))))),
                RecordData::Pose(p) => Raw(obj!(kind = "Pose", value = Raw(obj!(parts = parts_l(&p.parts))))),
                RecordData::Hierarchy(_) => Raw("{ kind = \"Hierarchy\" }".into()),
                RecordData::PhysicsPose(p) => Raw(obj!(kind = "PhysicsPose", value = Raw(obj!(bone_count = p.bone_count, records = rng_l(&p.records))))),
                RecordData::Opaque => Raw("{ kind = \"Opaque\" }".into()),
            };
            records.push(obj!(index = i, header = Raw(obj!(name = hd.name.clone(), name_words = hd.name_words, offset = hd.offset, size = hd.size, payload_offset = hd.payload_offset, type_id = hd.type_id, codec_word = hd.codec_word, guid = hd.guid)), data = data));
        }
        // VBR: каждый 25-й клип, все части, кадры 0/середина/последний.
        let mut vbr = Vec::new();
        let mut k = 0;
        for rec in bank.records() {
            if let RecordData::Clip(c) = &rec.data {
                k += 1;
                if k % 25 != 1 { continue; }
                for e in &c.parts {
                    let Some(p) = &e.part else { continue };
                    let Ok(mut d) = VbrDecoder::new(bank.bytes(), p.offset, p.compression_header_relative as usize, p.compressed_data_relative as usize) else { vbr.push(obj!(clip = rec.header.name.clone(), table_index = e.table_index, err = true)); continue };
                    let fc = d.frame_count();
                    let frames: Vec<usize> = { let mut v = vec![0, fc / 2, fc - 1, (fc).min(9) - 1]; v.dedup(); v };
                    let out: Vec<Raw> = frames.iter().map(|&f| Raw(d.decode_frame(f).unwrap().l())).collect();
                    vbr.push(obj!(clip = rec.header.name.clone(), table_index = e.table_index, offset = p.offset, hr = p.compression_header_relative, dr = p.compressed_data_relative, frames_n = fc, channels = d.channel_count(), frames = frames, out = out));
                }
            }
        }
        writeln!(s, "\t\t[{:?}] = {{ records_n = {}, wrapper_bytes = {}, trailer = {}, hierarchy = {}, records = {{\n\t\t\t{}\n\t\t}}, vbr = {{\n\t\t\t{}\n\t\t}} }},",
            name, n, bank.wrapper_bytes, rng_l(&bank.trailer).l(), hl.l(), records.join(",\n\t\t\t"), vbr.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/anim3.luau"), s).unwrap();
}
