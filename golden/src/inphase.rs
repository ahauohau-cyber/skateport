//! Эталон для player::input_phase: весь process_input с записанными
//! ответами сервисов, плюс publish_deck_angles / publish_twist.
//! Синтетика — файл можно коммитить.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::animation::output::actor_packet::ExternalPhysicsInput;
use skate_core::input::animation_packet::AnimationPacketFields;
use skate_core::physics::skeleton_body::SkeletonPhysicalRecord;
use skate_core::player::input_phase::*;
use std::fmt::Write as _;

fn fb(r: &mut Rng, lo: f32, hi: f32) -> u32 { r.range(lo, hi).to_bits() }
fn rv(r: &mut Rng, span: f32) -> RawVector {
    let w = if r.next() % 4 == 0 { r.range(-1.0, 1.0) } else { 0.0 };
    [fb(r, -span, span), fb(r, -span, span), fb(r, -span, span), w.to_bits()]
}
fn small(r: &mut Rng) -> f32 {
    match r.next() % 6 { 0 => 0.0, 1 => -0.0, _ => r.range(-1.0, 1.0) }
}

struct Svc {
    manager: Option<(u32, u32)>,
    a56: u32,
    a44: u32,
    available: bool,
    transition: f32,
    ground: RawVector,
    skel_2468: u32,
    skel_2472: u32,
    skel_2476: u32,
    spin: f32,
    crouch: f32,
    calls: Vec<&'static str>,
}

impl InputPhaseServices for Svc {
    type Error = ();
    fn update_pre_input_manager_82d81610(&mut self, _p: &mut PlayerInputState, physical: &mut PhysicalPlayerInput) -> Result<(), ()> {
        self.calls.push("manager");
        if let Some((s, c)) = self.manager { physical.state.state_16 = s; physical.state.category_12 = c; }
        Ok(())
    }
    fn reset_processed_input_82bf9ef0(&mut self, o: &mut ProcessedPhysicsInput) -> Result<(), ()> {
        self.calls.push("reset");
        *o = ProcessedPhysicsInput::default();
        Ok(())
    }
    fn actor_query_slot_56(&mut self) -> Result<u32, ()> { self.calls.push("actor56"); Ok(self.a56) }
    fn actor_query_slot_44(&mut self) -> Result<u32, ()> { self.calls.push("actor44"); Ok(self.a44) }
    fn reset_player_probe_82d7a330(&mut self, p: &mut PlayerInputState, _: &mut PhysicalPlayerInput) -> Result<(), ()> {
        self.calls.push("probe_reset");
        p.probe.byte_104 = 0;
        Ok(())
    }
    fn check_teleport_82db88c8(&mut self, _: &mut PlayerInputState, _: &mut PhysicalPlayerInput, _: &mut ProcessedPhysicsInput) -> Result<(), ()> {
        self.calls.push("teleport");
        Ok(())
    }
    fn actor_input_available_slot_4(&mut self) -> Result<bool, ()> { self.calls.push("actor_input"); Ok(self.available) }
    fn transition_action_825903c8(&mut self) -> Result<f32, ()> { self.calls.push("transition"); Ok(self.transition) }
    fn calculate_ground_position_82c02840(&mut self, _: &PhysicalPlayerInput) -> Result<RawVector, ()> {
        self.calls.push("ground_position");
        Ok(self.ground)
    }
    fn prepare_board_toolkit_82c013f0(&mut self, _: &mut PlayerInputState, _: &mut PhysicalPlayerInput, _: &mut ProcessedPhysicsInput) -> Result<(), ()> {
        self.calls.push("board_toolkit");
        Ok(())
    }
    fn process_skeleton_82bd8918(&mut self, _: &AnimationInputPacket<'_>, _: &mut PhysicalPlayerInput, o: &mut ProcessedPhysicsInput) -> Result<(), ()> {
        self.calls.push("skeleton");
        o.flags_2468 |= self.skel_2468;
        o.flags_2472 |= self.skel_2472;
        o.flags_2476 |= self.skel_2476;
        o.spin_input_2672 = self.spin;
        o.crouch_2776 = self.crouch;
        Ok(())
    }
    fn update_grind_manager_82d8a828(&mut self, _: &mut PlayerInputState, _: &mut PhysicalPlayerInput, _: &mut ProcessedPhysicsInput) -> Result<(), ()> {
        self.calls.push("grind");
        Ok(())
    }
}

fn player_l(p: &PlayerInputState) -> Raw {
    Raw(obj!(manager_1856_counter_320 = p.manager_1856_counter_320, manager_1852_flag_256 = p.manager_1852_flag_256, manager_1852_vector_176 = p.manager_1852_vector_176, flags_1296 = p.flags_1296,
        grounded_frames_1300 = p.grounded_frames_1300, state_count_1312 = p.state_count_1312, update_count_1316 = p.update_count_1316,
        spin_same_direction_frames_1324 = p.spin_same_direction_frames_1324, frames_since_teleport_1328 = p.frames_since_teleport_1328,
        state_value_1336 = p.state_value_1336, state_timer_1344 = p.state_timer_1344, time_since_last_input_1348 = p.time_since_last_input_1348,
        time_on_ground_1352 = p.time_on_ground_1352, signed_ground_time_1356 = p.signed_ground_time_1356, previous_spin_input_1360 = p.previous_spin_input_1360,
        previous_crouch_1364 = p.previous_crouch_1364, time_off_board_1368 = p.time_off_board_1368, skitch_value_1372 = p.skitch_value_1372,
        skitch_timer_1376 = p.skitch_timer_1376, ground_timer_1380 = p.ground_timer_1380, secondary_ground_timer_1384 = p.secondary_ground_timer_1384,
        probe_byte_104 = p.probe.byte_104, queued_vector_1280 = p.queued_vector_1280, prepared_jump_velocity_1184 = p.prepared_jump_velocity_1184,
        previous_ground_position_1200 = p.previous_ground_position_1200, current_ground_position_1216 = p.current_ground_position_1216,
        ground_delta_1232 = p.ground_delta_1232, damped_ground_delta_1248 = p.damped_ground_delta_1248,
        overrides = p.state_variants_1408.map(|v| v.surface_override_enabled_60),
        left_valid = p.left_line_test_1536.valid, left_surface = p.left_line_test_1536.surface,
        right_valid = p.right_line_test_1584.valid, right_surface = p.right_line_test_1584.surface, hips_surface = p.hips_line_test_1488.surface,
        ground_history_frames_1304 = p.ground_history_frames_1304,
        cache_flags = p.external_physics_cache_1008.flags, cache_vectors = p.external_physics_cache_1008.vectors))
}

fn output_l(o: &ProcessedPhysicsInput) -> Raw {
    let reference = |r: Option<NativeRelativeReference>| r.map(|r| Raw(obj!(base = format!("{:?}", r.base), offset = r.offset as u32)));
    Raw(obj!(effective_anim_transform_192 = o.effective_anim_transform_192, vectors_400_416 = o.vectors_400_416,
        vectors_464_480_496_512_528 = o.vectors_464_480_496_512_528, vectors_544_560_592_608 = o.vectors_544_560_592_608,
        vectors_624_640_656_672 = o.vectors_624_640_656_672, prepared_jump_704 = o.prepared_jump_704,
        vectors_720_784_800_816_832_864 = o.vectors_720_784_800_816_832_864, vectors_880_896_912_928_944 = o.vectors_880_896_912_928_944,
        external_vectors = o.external_physics_1616.vectors, external_flags = o.external_physics_1616.flags,
        probe_byte_104 = o.probe_1792.byte_104,
        flags_2468 = o.flags_2468, flags_2472 = o.flags_2472, flags_2476 = o.flags_2476, flags_2480 = o.flags_2480, flags_2484 = o.flags_2484, flags_2488 = o.flags_2488,
        state_identifier_2496 = o.state_identifier_2496, state_2504 = o.state_2504, state_2508 = o.state_2508, category_2512 = o.category_2512,
        category_2516 = o.category_2516, player_state_value_2520 = o.player_state_value_2520, filtered_state_2524 = o.filtered_state_2524,
        state_variant_index_2528 = o.state_variant_index_2528, grind_words_2532_2536 = o.grind_words_2532_2536, surface_mode_2540 = o.surface_mode_2540,
        surface_primary_ref_2544 = reference(o.surface_primary_ref_2544), state_variant_ref_2548 = reference(o.state_variant_ref_2548),
        surface_secondary_ref_2552 = reference(o.surface_secondary_ref_2552), wheel_count_2556 = o.wheel_count_2556,
        state_count_2564 = o.state_count_2564, update_count_2568 = o.update_count_2568, spin_same_direction_frames_2580 = o.spin_same_direction_frames_2580,
        frames_since_teleport_2584 = o.frames_since_teleport_2584, skitch_value_2592 = o.skitch_value_2592, left_surface_2596 = o.left_surface_2596,
        right_surface_2600 = o.right_surface_2600, timestep_2604 = o.timestep_2604, scalar_2612 = o.scalar_2612, transition_2636 = o.transition_2636,
        scalar_2652 = o.scalar_2652, scalar_2656 = o.scalar_2656, state_timer_2664 = o.state_timer_2664, scalar_2668 = o.scalar_2668,
        spin_input_2672 = o.spin_input_2672, scalar_2696 = o.scalar_2696, scalar_2700 = o.scalar_2700, scalar_2736 = o.scalar_2736,
        time_since_last_input_2748 = o.time_since_last_input_2748, time_on_ground_2752 = o.time_on_ground_2752, signed_ground_time_2756 = o.signed_ground_time_2756,
        truck_tightness_2760 = o.truck_tightness_2760, scalar_2764 = o.scalar_2764, air_scalar_2772 = o.air_scalar_2772, crouch_2776 = o.crouch_2776,
        crouch_delta_2780 = o.crouch_delta_2780, off_board_scalar_2832 = o.off_board_scalar_2832, time_off_board_2836 = o.time_off_board_2836,
        ground_timer_2848 = o.ground_timer_2848, secondary_ground_timer_2852 = o.secondary_ground_timer_2852, collision_scalar_2924 = o.collision_scalar_2924,
        actor_query_2948 = o.actor_query_2948, actor_query_2952 = o.actor_query_2952))
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x1a9f_7e55);
    let mut s = format!("-- Сгенерировано golden/src/inphase.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n\tphase = {{\n");
    for _ in 0..400 {
        // --- player
        let mut p = PlayerInputState::default();
        p.manager_1856_counter_320 = match r.next() % 4 { 0 => 0, 1 => 0x8000_0000, _ => r.next() % 5 };
        p.manager_1852_flag_256 = (r.next() & 0xff) as u8;
        p.manager_1852_vector_176 = rv(&mut r, 3.0);
        p.flags_1296 = r.next() ^ (r.next() << 16);
        p.grounded_frames_1300 = if r.next() % 8 == 0 { u32::MAX } else { r.next() % 10 };
        p.state_count_1312 = r.next() % 9;
        p.update_count_1316 = r.next() % 100;
        p.spin_same_direction_frames_1324 = r.next() % 5;
        p.frames_since_teleport_1328 = r.next() % 4;
        p.state_value_1336 = r.next() % 1000;
        p.state_timer_1344 = r.range(0.0, 3.0);
        p.time_since_last_input_1348 = r.range(0.0, 2.0);
        p.time_on_ground_1352 = r.range(0.0, 2.0);
        p.signed_ground_time_1356 = small(&mut r);
        p.previous_spin_input_1360 = small(&mut r);
        p.previous_crouch_1364 = r.range(-1.0, 1.0);
        p.time_off_board_1368 = r.range(0.0, 2.0);
        p.skitch_value_1372 = r.next() % 50;
        p.skitch_timer_1376 = if r.bool() { 0.0 } else { r.range(-0.1, 2.0) };
        p.ground_timer_1380 = if r.bool() { 0.0 } else { r.range(-0.1, 1.0) };
        p.secondary_ground_timer_1384 = if r.bool() { 0.0 } else { r.range(-0.1, 1.0) };
        p.probe.byte_104 = (r.next() % 3) as u8;
        p.queued_vector_1280 = rv(&mut r, 2.0);
        for i in 0..10 { p.external_physics_cache_1008.vectors[i] = [r.next(), r.next(), r.next(), r.next()]; }
        p.external_physics_cache_1008.flags = r.next() ^ (r.next() << 16);
        p.prepared_jump_velocity_1184 = rv(&mut r, 5.0);
        p.previous_ground_position_1200 = rv(&mut r, 10.0);
        p.current_ground_position_1216 = rv(&mut r, 10.0);
        p.ground_delta_1232 = rv(&mut r, 1.0);
        p.damped_ground_delta_1248 = rv(&mut r, 1.0);
        for v in p.state_variants_1408.iter_mut() { v.surface_override_enabled_60 = (r.next() % 3) as u8; }
        p.left_line_test_1536.valid = (r.next() % 3) as u8;
        p.left_line_test_1536.surface = r.next() % 5000;
        p.right_line_test_1584.valid = (r.next() % 3) as u8;
        p.right_line_test_1584.surface = r.next() % 5000;
        p.hips_line_test_1488.surface = r.next() % 5000;
        p.ground_history_frames_1304 = (r.next() % 3) as i32 - 1;
        let p_in = player_l(&p);
        // --- physical
        let mut ph = PhysicalPlayerInput::default();
        let cats = [100u32, 200, 300, 500, 600, 700];
        ph.state.category_12 = cats[(r.next() % 6) as usize];
        ph.state.state_16 = [100u32, 104, 11, 201, 503][(r.next() % 5) as usize];
        ph.state.identifier_8 = r.next() % 900;
        ph.state.skitch_value_40 = r.next() % 90;
        ph.state.signed_ground_step_84 = (r.next() % 3) as u8;
        ph.state.flag_61 = (r.next() % 3) as u8;
        ph.state.flag_66 = (r.next() % 3) as u8;
        ph.state.flag_69 = (r.next() % 3) as u8;
        ph.state.flag_74 = (r.next() % 3) as u8;
        ph.ground.scalar_276 = small(&mut r);
        ph.ground.scalar_292 = if r.bool() { 0.0 } else { r.range(-0.5, 1.0) };
        ph.ground.scalar_296 = if r.bool() { 0.0 } else { r.range(-0.5, 1.0) };
        ph.ground.vector_64 = rv(&mut r, 1.0);
        ph.ground.vector_96 = rv(&mut r, 1.0);
        ph.ground.vector_128 = rv(&mut r, 1.0);
        ph.ground.flag_317 = (r.next() % 3) as u8;
        ph.ground.flag_318 = (r.next() % 3) as u8;
        ph.skateboard.vector_64 = rv(&mut r, 3.0);
        ph.skateboard.vector_80 = rv(&mut r, 3.0);
        ph.skateboard.vector_96 = if r.next() % 8 == 0 { [0; 4] } else { rv(&mut r, 8.0) };
        ph.skateboard.vector_128 = rv(&mut r, 3.0);
        ph.skateboard.vector_144 = rv(&mut r, 3.0);
        ph.skateboard.scalar_160 = r.range(0.0, 0.2);
        ph.skateboard.scalar_164 = r.range(-1.0, 1.0);
        ph.skateboard.scalar_168 = r.range(-1.0, 1.0);
        ph.skateboard.scalar_172 = r.range(-1.0, 1.0);
        ph.collision.wheel_count_0 = r.next() % 5;
        ph.collision.wheel_contact_3296_3299 = [(r.next() % 2) as u8, (r.next() % 2) as u8, (r.next() % 2) as u8, (r.next() % 2) as u8];
        ph.collision.flag_215 = (r.next() % 3) as u8;
        ph.collision.flag_216 = (r.next() % 3) as u8;
        ph.collision.flag_3472 = (r.next() % 2) as u8;
        ph.collision.flag_3475 = (r.next() % 2) as u8;
        ph.collision.flag_3477 = (r.next() % 2) as u8;
        ph.collision.flag_3478 = (r.next() % 2) as u8;
        ph.collision.flag_3481 = (r.next() % 2) as u8;
        ph.collision.scalar_28 = r.range(-1.0, 1.0);
        ph.reckoning.vector_16 = rv(&mut r, 3.0);
        ph.reckoning.vector_64 = rv(&mut r, 3.0);
        ph.reckoning.vector_96 = rv(&mut r, 3.0);
        ph.reckoning.vector_144 = rv(&mut r, 3.0);
        ph.reckoning.flag_164 = (r.next() % 2) as u8;
        ph.board_reckoning_side_176 = rv(&mut r, 1.0);
        ph.air.use_air_reckoning_452 = (r.next() % 2) as u8;
        ph.air.vector_160 = rv(&mut r, 3.0);
        ph.air.scalar_184 = r.range(0.0, 1.0);
        ph.air.flag_441 = (r.next() % 2) as u8;
        ph.air.flag_446 = (r.next() % 3) as u8;
        ph.air.flag_447 = (r.next() % 2) as u8;
        ph.air.flag_448 = (r.next() % 2) as u8;
        ph.grinds.words_136_140 = [r.next(), r.next() % 5];
        ph.grinds.flag_318 = (r.next() % 2) as u8;
        ph.grinds.flag_322 = (r.next() % 2) as u8;
        ph.physics.flag_32 = (r.next() % 2) as u8;
        ph.physics.vector_16 = rv(&mut r, 1.0);
        ph.skeleton.flag_597 = (r.next() % 2) as u8;
        ph.skeleton.flag_600 = (r.next() % 2) as u8;
        ph.skeleton.flag_601 = (r.next() % 2) as u8;
        ph.skeleton.anim_to_world_11920 = [rv(&mut r, 1.0), rv(&mut r, 1.0), rv(&mut r, 1.0), rv(&mut r, 9.0)];
        ph.filtered_state_0 = r.next() % 20;
        ph.off_board.flag_304 = (r.next() % 2) as u8;
        ph.off_board.scalar_32 = small(&mut r);
        ph.off_board.flag_311 = (r.next() % 2) as u8;
        ph.off_board.flag_314 = (r.next() % 2) as u8;
        ph.off_board.flag_315 = (r.next() % 2) as u8;
        ph.off_board.flag_316 = (r.next() % 2) as u8;
        ph.off_board.flag_318 = (r.next() % 2) as u8;
        ph.off_board.flag_328 = (r.next() % 2) as u8;
        ph.off_board.vector_64 = rv(&mut r, 1.0);
        ph.surface_default_mode = r.next() % 15;
        ph.component_1832_word_1876 = r.next() ^ (r.next() << 16);
        let ph_in = Raw(obj!(state = Raw(obj!(category_12 = ph.state.category_12, state_16 = ph.state.state_16, identifier_8 = ph.state.identifier_8,
                skitch_value_40 = ph.state.skitch_value_40, signed_ground_step_84 = ph.state.signed_ground_step_84, flag_61 = ph.state.flag_61,
                flag_66 = ph.state.flag_66, flag_69 = ph.state.flag_69, flag_74 = ph.state.flag_74)),
            ground = Raw(obj!(scalar_276 = ph.ground.scalar_276, scalar_292 = ph.ground.scalar_292, scalar_296 = ph.ground.scalar_296, vector_64 = ph.ground.vector_64,
                vector_96 = ph.ground.vector_96, vector_128 = ph.ground.vector_128, flag_317 = ph.ground.flag_317, flag_318 = ph.ground.flag_318)),
            skateboard = Raw(obj!(vector_64 = ph.skateboard.vector_64, vector_80 = ph.skateboard.vector_80, vector_96 = ph.skateboard.vector_96,
                vector_128 = ph.skateboard.vector_128, vector_144 = ph.skateboard.vector_144, scalar_160 = ph.skateboard.scalar_160,
                scalar_164 = ph.skateboard.scalar_164, scalar_168 = ph.skateboard.scalar_168, scalar_172 = ph.skateboard.scalar_172)),
            collision = Raw(obj!(wheel_count_0 = ph.collision.wheel_count_0, wheel_contact_3296_3299 = ph.collision.wheel_contact_3296_3299,
                flag_215 = ph.collision.flag_215, flag_216 = ph.collision.flag_216, flag_3472 = ph.collision.flag_3472, flag_3475 = ph.collision.flag_3475,
                flag_3477 = ph.collision.flag_3477, flag_3478 = ph.collision.flag_3478, flag_3481 = ph.collision.flag_3481, scalar_28 = ph.collision.scalar_28)),
            reckoning = Raw(obj!(vector_16 = ph.reckoning.vector_16, vector_64 = ph.reckoning.vector_64, vector_96 = ph.reckoning.vector_96,
                vector_144 = ph.reckoning.vector_144, flag_164 = ph.reckoning.flag_164)),
            board_reckoning_side_176 = ph.board_reckoning_side_176,
            air = Raw(obj!(use_air_reckoning_452 = ph.air.use_air_reckoning_452, vector_160 = ph.air.vector_160, scalar_184 = ph.air.scalar_184,
                flag_441 = ph.air.flag_441, flag_446 = ph.air.flag_446, flag_447 = ph.air.flag_447, flag_448 = ph.air.flag_448)),
            grinds = Raw(obj!(words_136_140 = ph.grinds.words_136_140, flag_318 = ph.grinds.flag_318, flag_322 = ph.grinds.flag_322)),
            physics = Raw(obj!(flag_32 = ph.physics.flag_32, vector_16 = ph.physics.vector_16)),
            skeleton = Raw(obj!(flag_597 = ph.skeleton.flag_597, flag_600 = ph.skeleton.flag_600, flag_601 = ph.skeleton.flag_601,
                anim_to_world_11920 = ph.skeleton.anim_to_world_11920)),
            filtered_state_0 = ph.filtered_state_0,
            off_board = Raw(obj!(flag_304 = ph.off_board.flag_304, scalar_32 = ph.off_board.scalar_32, flag_311 = ph.off_board.flag_311,
                flag_314 = ph.off_board.flag_314, flag_315 = ph.off_board.flag_315, flag_316 = ph.off_board.flag_316, flag_318 = ph.off_board.flag_318,
                flag_328 = ph.off_board.flag_328, vector_64 = ph.off_board.vector_64)),
            surface_default_mode = ph.surface_default_mode, component_1832_word_1876 = ph.component_1832_word_1876));
        // --- packet
        let publication = AnimationPacketFields {
            stance_byte: (r.next() % 3) as u8, timestep: if r.next() % 10 == 0 { 0.0 } else { r.range(0.005, 0.05) }, scalar_10388: r.range(-1.0, 1.0),
            flags_10375_10496_10784: [(r.next() % 3) as u8, (r.next() % 3) as u8, (r.next() % 3) as u8], vector_10480: rv(&mut r, 1.0),
            matrix_10704: [rv(&mut r, 1.0), rv(&mut r, 1.0), rv(&mut r, 1.0), rv(&mut r, 1.0)], byte_10768: (r.next() & 0xff) as u8,
            truck_tightness: r.range(0.0, 1.0), scalar_10792: r.range(-1.0, 1.0), flag_10371: (r.next() % 3) as u8,
        };
        let external = ExternalPhysicsInput { vectors: std::array::from_fn(|_| [r.next(), r.next(), r.next(), r.next()]), flags: r.next() ^ (r.next() << 16) };
        let packet = AnimationInputPacket {
            publication: &publication, external_physics_10512: &external,
            flag_10369: (r.next() % 3) as u8, flag_10370: (r.next() % 3) as u8, flag_10373: (r.next() % 3) as u8,
            suppress_transition_10376: (r.next() % 3 == 0) as u8, use_external_physics_10688: (r.next() % 2) as u8,
            external_physics_flag_10689: (r.next() % 3) as u8, flag_10786: (r.next() % 3) as u8, flag_10787: (r.next() % 3) as u8,
            force_braking_10796: (r.next() % 2) as u8,
            vector_10816: rv(&mut r, 1.0), vector_10832: rv(&mut r, 1.0), vector_10848: rv(&mut r, 1.0), vector_10864: rv(&mut r, 1.0),
            vector_10880: rv(&mut r, 1.0), vector_10896: rv(&mut r, 1.0), scalar_10912: r.range(-1.0, 1.0), scalar_10916: r.range(-1.0, 1.0),
            state_variant_10928: if r.next() % 12 == 0 { 5 + r.next() % 3 } else { r.next() % 5 }, flags_10932: r.next() ^ (r.next() << 16),
        };
        let packet_in = Raw(obj!(publication = Raw(obj!(stance_byte = publication.stance_byte, timestep = publication.timestep,
                scalar_10388 = publication.scalar_10388, flags_10375_10496_10784 = publication.flags_10375_10496_10784, vector_10480 = publication.vector_10480,
                matrix_10704 = publication.matrix_10704, byte_10768 = publication.byte_10768, truck_tightness = publication.truck_tightness,
                scalar_10792 = publication.scalar_10792, flag_10371 = publication.flag_10371)),
            external = Raw(obj!(vectors = external.vectors, flags = external.flags)),
            flag_10369 = packet.flag_10369, flag_10370 = packet.flag_10370, flag_10373 = packet.flag_10373, suppress_transition_10376 = packet.suppress_transition_10376,
            use_external_physics_10688 = packet.use_external_physics_10688, external_physics_flag_10689 = packet.external_physics_flag_10689,
            flag_10786 = packet.flag_10786, flag_10787 = packet.flag_10787, force_braking_10796 = packet.force_braking_10796,
            vector_10816 = packet.vector_10816, vector_10832 = packet.vector_10832, vector_10848 = packet.vector_10848, vector_10864 = packet.vector_10864,
            vector_10880 = packet.vector_10880, vector_10896 = packet.vector_10896, scalar_10912 = packet.scalar_10912, scalar_10916 = packet.scalar_10916,
            state_variant_10928 = packet.state_variant_10928, flags_10932 = packet.flags_10932));
        // --- services
        let mut svc = Svc {
            manager: if r.next() % 4 == 0 { Some(([100u32, 104, 11][(r.next() % 3) as usize], cats[(r.next() % 6) as usize])) } else { None },
            a56: r.next(), a44: r.next(), available: r.next() % 4 != 0,
            transition: match r.next() % 5 { 0 => f32::NAN, 1 => -0.0, _ => r.range(-3.0, 3.0) },
            ground: rv(&mut r, 10.0),
            skel_2468: if r.bool() { 1 << 21 } else { 0 },
            skel_2472: (if r.bool() { 1 << 21 } else { 0 }) | (if r.bool() { 1 << 23 } else { 0 }),
            skel_2476: if r.bool() { 1 << 22 } else { 0 },
            spin: small(&mut r), crouch: r.range(-1.0, 1.0), calls: Vec::new(),
        };
        let svc_in = Raw(obj!(manager = svc.manager.map(|(a, b)| [a, b]), a56 = svc.a56, a44 = svc.a44, available = svc.available,
            transition = svc.transition, ground = svc.ground, skel_2468 = svc.skel_2468, skel_2472 = svc.skel_2472, skel_2476 = svc.skel_2476,
            spin = svc.spin, crouch = svc.crouch));
        let mut out = ProcessedPhysicsInput::default();
        let result = process_input(&mut p, &mut ph, &packet, &mut out, &mut svc);
        let err = match result { Ok(()) => None, Err(InputPhaseError::InvalidStateVariant(i)) => Some(i), Err(InputPhaseError::Service(())) => unreachable!() };
        writeln!(s, "\t\t{},", obj!(player = p_in, physical = ph_in, packet = packet_in, services = svc_in,
            err = err, calls = svc.calls.clone(), player_out = player_l(&p), out = output_l(&out),
            phys_state = Raw(obj!(state_16 = ph.state.state_16, category_12 = ph.state.category_12)))).unwrap();
    }
    s.push_str("\t},\n\tdeck = {\n");
    for _ in 0..400 {
        let mut f = [r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0)];
        match r.next() % 8 { 0 => f[2] = 0.0, 1 => f[2] = -0.0, 2 => f[0] = 0.0, 3 => { f[0] = -0.0; f[2] = -0.0 } _ => {} }
        let flipped = r.bool();
        let mut o = SkeletonOutputFields::default();
        o.publish_deck_angles(f, flipped);
        writeln!(s, "\t\t{},", obj!(forward = f, flipped = flipped, yaw = o.deck_yaw_536, pitch = o.deck_pitch_540)).unwrap();
    }
    s.push_str("\t},\n\ttwist = {\n");
    for _ in 0..400 {
        let mut record = SkeletonPhysicalRecord::default();
        let p6 = [r.range(-2.0, 2.0), r.range(-2.0, 2.0), r.range(-2.0, 2.0), 1.0];
        let p10 = if r.next() % 10 == 0 { p6 } else { [r.range(-2.0, 2.0), r.range(-2.0, 2.0), r.range(-2.0, 2.0), 1.0] };
        record.pose[6][3] = p6;
        record.pose[10][3] = p10;
        let fwd = { let v = r.vec(1.0); [v.x, v.y, v.z, 0.0] };
        let up = { let v = r.vec(1.0); [v.x, v.y + 1.0, v.z, 0.0] };
        let mut o = SkeletonOutputFields::default();
        o.publish_twist(&record, fwd, up);
        writeln!(s, "\t\t{},", obj!(p6 = p6, p10 = p10, forward = fwd, up = up, twist = o.twist_504)).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/inphase.luau"), s).unwrap();
}
