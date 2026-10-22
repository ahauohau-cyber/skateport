//! Эталон для skate_game/physics/riding_outputs: копия Rust-кода
//! crates/skate-game/src/physics/riding_outputs{.rs,/probes.rs,/ground_input.rs}
//! (там он pub(crate)) с минимальным ProcessedPhysicsInput из нужных полей.
//! Прогон: стоковая доска на рампе, riding outputs каждый тик.
use crate::collision::{b, v};
use crate::colliders::{stock, world_volumes, Stock};
use skate_core::air::body_spin::{self, BodySpinState};
use skate_core::math::Vector3;
use skate_core::physics::board::BodyId;
use skate_core::physics::board_ground::{wheel_lines, BoardGroundState, WheelLine, WheelLineHit, WheelLineState};
use skate_core::physics::board_motion_output::BoardMotionOutput;
use skate_core::physics::board_probes::{self, BoardProbeHit, BoardProbeState, WallLineInput};
use skate_core::physics::board_runtime::{BoardMotion, BoardRuntime};
use skate_core::physics::board_toolkit::BoardToolkit;
use skate_core::physics::board_world::{BoardWorld, ContactRetentionSettings, WorldLineHit};
use skate_core::physics::collision::WorldContactSettings;
use skate_core::physics::drive_frames::RetailAffineTransform;
use skate_core::physics::force_queue::QueuedPointForce;
use skate_core::point_graph::PointGraph;
use skate_core::riding::ground_orientation::{GroundOrientation, GroundOrientationInput, GroundOrientationSettings};
use skate_core::riding::reckoning_frames::ReckoningFrames;
use skate_core::riding::speed_and_slope::SpeedAndSlopeSettings;
use skate_data::collections::Collections;
use std::fmt::Write as _;

pub struct Processed {
    pub vectors_464_480_496_512_528: [[u32; 4]; 5],
    pub vectors_544_560_592_608: [[u32; 4]; 4],
    pub scalar_2652: f32,
    pub scalar_2616: f32,
    pub wheel_count_2556: u32,
    pub state_2508: u32,
    pub time_on_ground_2752: f32,
}
struct GroundPacketInputs { wheel_normal: Vector3, dynamic_up: Vector3, speed: f32, absolute_speed: f32, wheel_count: i32 }
impl GroundPacketInputs {
    fn from_processed(input: &Processed) -> Self {
        let vector = |bits: [u32; 4]| { let value = bits.map(f32::from_bits); Vector3::new(value[0], value[1], value[2]) };
        Self { wheel_normal: vector(input.vectors_464_480_496_512_528[0]), dynamic_up: vector(input.vectors_464_480_496_512_528[4]),
            speed: input.scalar_2652, absolute_speed: input.scalar_2616, wheel_count: input.wheel_count_2556 as i32 }
    }
}
pub struct BoardProbes { pub deck: BoardProbeState, pub wall: BoardProbeState, wall_line: Option<WheelLine>, pending: Option<Pending> }
struct Pending { deck: Option<BoardProbeHit>, wall: Option<Option<BoardProbeHit>> }
impl BoardProbes {
    fn default() -> Self { Self { deck: BoardProbeState::default(), wall: BoardProbeState::default(), wall_line: None, pending: None } }
    pub fn prepare_wall(&mut self, input: &Processed, toolkit: &BoardToolkit) {
        let vector = |value: [f32; 4]| Vector3::new(value[0], value[1], value[2]);
        self.wall_line = board_probes::wall_probe(WallLineInput { state: input.state_2508,
            contact_normal: vector(input.vectors_464_480_496_512_528[0].map(f32::from_bits)),
            skater_up: vector(input.vectors_544_560_592_608[0].map(f32::from_bits)),
            deck_position: vector(toolkit.deck[3]), time: input.time_on_ground_2752 });
    }
    fn start(&mut self, board: &BoardRuntime, world: &BoardWorld) -> Result<(), String> {
        if self.pending.is_some() { return Err("twice".into()); }
        let line = board_probes::deck_probe(board.part_transforms()[BodyId::Deck.index()].translation);
        self.deck.start(line.start);
        let deck = world.query_swept_line(line.start, line.end, board_probes::DECK_PROBE_RADIUS).map_err(|e| e.to_string())?.map(hit);
        let wall = if let Some(line) = self.wall_line { self.wall.start(line.start); Some(world.query_thin_line(line.start, line.end).map_err(|e| e.to_string())?.map(hit)) } else { self.wall.disable(); None };
        self.pending = Some(Pending { deck, wall });
        Ok(())
    }
    fn publish(&mut self) -> Result<(), String> {
        let pending = self.pending.take().ok_or("none")?;
        self.deck.publish(pending.deck);
        if let Some(result) = pending.wall { self.wall.publish(result); } else { self.wall.disable(); }
        Ok(())
    }
}
fn hit(hit: WorldLineHit) -> BoardProbeHit { BoardProbeHit { point: hit.geometry.position, normal: hit.geometry.normal, surface_tag: hit.tag } }

pub struct RidingOutputs {
    pub ground: BoardGroundState, pub wheel_lines: WheelLineState, pub probes: BoardProbes, pub reckoning: GroundOrientation,
    pub reckoning_frames: ReckoningFrames, pub body_spin: BodySpinState, pub motion: BoardMotionOutput,
    orientation_settings: GroundOrientationSettings, tilt_vs_rotation: PointGraph<8>, tilt_vs_slope: PointGraph<8>,
    speed_settings: SpeedAndSlopeSettings, maximum_ground_angle: f32, heading_adjust_factor: f32,
    pending_wheel_queries: Option<[Option<WheelLineHit>; 4]>,
}
fn graph(data: &Collections, class: &str, field: &str) -> Result<PointGraph<8>, String> {
    let words = data.words::<16>(class, "default", field)?.map(f32::from_bits);
    Ok(PointGraph { x: words[..8].try_into().unwrap(), y: words[8..].try_into().unwrap() })
}
fn lanes(v: Vector3) -> [f32; 4] { [v.x, v.y, v.z, 0.0] }
fn vector(v: [f32; 3]) -> Vector3 { Vector3::new(v[0], v[1], v[2]) }
impl RidingOutputs {
    pub fn load(data: &Collections, board: &BoardRuntime, processed_flags_2468: u32) -> Result<Self, String> {
        let f = |field| data.float("physics_reckoning", "default", field);
        let control = |field| data.words::<4>("physics_reckoning", "default", field).map(|v| v.map(f32::from_bits));
        let curve = |field| graph(data, "physics_reckoning", field);
        let deck_curve = data.words::<20>("physics_reckoning", "default", "DeckAngleUsageVsSpeed")?.map(f32::from_bits);
        let orientation_settings = GroundOrientationSettings {
            ground_normal_smoothing: control("GroundNormalSmoothing")?, up_vector_smoothing_slow: control("UpVectorSmoothingSlow")?,
            up_vector_smoothing_fast: control("UpVectorSmoothingFast")?, dynamic_up_vs_ground_y: curve("DynamicUpVsGroundY")?,
            ground_vector_blend: curve("GroundVectorBlendGraph")?,
            deck_angle_usage_vs_speed: PointGraph { x: deck_curve[4..12].try_into().unwrap(), y: deck_curve[12..20].try_into().unwrap() },
            up_vector_smoothing_vs_speed: curve("UpVectorSmoothingVsSpeed")?, up_vector_max_delta_vs_speed: curve("UpVectorMaxDeltaVsSpeed")?,
            ground_blend_max_delta: f("GroundVMaxBlendDelta")?, up_vector_max_acceleration: f("UpVectorMaxAcceleration")?,
            anti_wobble_damping: f("UpVectAntiWobbleDamping")?, extra_side_damping: f("ExtraSideDamping")?,
            minimum_wheels_for_ground_blend: data.integer("physics_reckoning", "default", "MinWheelsToUseGroundVector")? as i32,
        };
        let speed_settings = SpeedAndSlopeSettings { turn_torque_vs_speed: graph(data, "physics_heading", "TurnTorqueVsSpeed")?,
            turn_torque_vs_slope: graph(data, "physics_heading", "TurnTorqueVsSlope")?, heading_adjust_max_speed: data.float("physics_heading", "default", "HeadingAdjustMaxSpeed")? };
        let reckoning = GroundOrientation::new(&orientation_settings);
        let motion = BoardMotionOutput::from_board(board, reckoning.ground_normal, processed_flags_2468);
        let ground = BoardGroundState::default();
        let heading_adjust_factor = speed_settings.calculate(ground.wheel_normal.y, motion.forward_speed);
        Ok(Self { ground, wheel_lines: WheelLineState::default(), probes: BoardProbes::default(), reckoning, reckoning_frames: ReckoningFrames::new(),
            body_spin: BodySpinState::new(), motion, orientation_settings, tilt_vs_rotation: curve("TiltVsRotGround")?, tilt_vs_slope: curve("TiltVsSlopeGround")?,
            speed_settings, maximum_ground_angle: f("MaxAllowedGroundNormalFromUp")?, heading_adjust_factor, pending_wheel_queries: None })
    }
    pub fn update_input_heading(&mut self, normal_y: f32, speed: f32) -> f32 { self.heading_adjust_factor = self.speed_settings.calculate(normal_y, speed); self.heading_adjust_factor }
    pub fn update_ground_reckoning(&mut self, board: &BoardRuntime, com_to_deck: Vector3, body_spin_input: f32, flags: u32, balance: f32, coffin: bool, processed: &Processed) {
        let deck = board.part_transforms()[BodyId::Deck.index()];
        let heading = [deck.basis.columns[2][0], deck.basis.columns[2][1], deck.basis.columns[2][2], 0.0];
        let observations = GroundPacketInputs::from_processed(processed);
        let previous_right = self.reckoning_frames.system[0];
        self.reckoning_frames.heading = heading;
        body_spin::update_ground(&mut self.body_spin, body_spin_input);
        let effective = BoardMotionOutput::from_board(board, self.reckoning.ground_normal, flags);
        self.reckoning.update(&self.orientation_settings, GroundOrientationInput {
            com_to_deck, ground_normal: observations.wheel_normal, dynamic_up: observations.dynamic_up, speed: observations.speed,
            wheel_contact_count: observations.wheel_count, animation_balance: balance, deck_angle_curve_input: observations.absolute_speed,
            board_up: vector(deck.basis.columns[1]), board_forward: vector(deck.basis.columns[2]), effective_board_forward: vector(effective.effective_basis.columns[2]),
            previous_reckoning_right: Vector3::new(previous_right[0], previous_right[1], previous_right[2]), prevent_up_behind_board: coffin });
        let up = lanes(self.reckoning.up);
        self.reckoning_frames.calculate_transform(up, lanes(self.reckoning.ground_normal));
        self.reckoning_frames.calculate_dynamic_lean(up, lanes(self.reckoning.dynamic_up));
        self.reckoning_frames.calculate_tilt(flags & 0x100000 != 0, &self.tilt_vs_rotation, &self.tilt_vs_slope);
    }
    pub fn start_wheel_queries(&mut self, board: &BoardRuntime, world: &BoardWorld) -> Result<(), String> {
        let lines = wheel_lines(board, self.reckoning.up);
        let mut results = [None; 4];
        for (i, line) in lines.into_iter().enumerate() {
            results[i] = world.query_thin_line(line.start, line.end).map_err(|e| e.to_string())?.map(|hit| WheelLineHit { fraction: hit.geometry.fraction, normal: hit.geometry.normal, surface_tag: hit.tag });
        }
        self.probes.start(board, world)?;
        self.pending_wheel_queries = Some(results);
        Ok(())
    }
    pub fn finish_wheel_queries(&mut self) -> Result<(), String> {
        let hits = self.pending_wheel_queries.take().ok_or("none")?;
        self.wheel_lines.publish(hits);
        self.probes.publish()
    }
    pub fn finish_post_physics(&mut self, board: &mut BoardRuntime, wiping: bool, flags: u32, time_step: f32) {
        self.ground.update(board.contact_reports(), &self.wheel_lines, self.reckoning.up, self.maximum_ground_angle, wiping);
        self.ground.sample_accelerations(core::array::from_fn(|i| board.bodies()[i].rates.linear_velocity), time_step);
        self.ground.advance_contact_time(time_step);
        for (body, drag) in board.bodies_mut()[..4].iter_mut().zip(self.ground.wheel_angular_drag) { body.inertia.angular_drag = drag; }
        self.motion = BoardMotionOutput::from_board(board, self.reckoning.ground_normal, flags);
    }
}

fn bits4(v: Vector3) -> [u32; 4] { [v.x.to_bits(), v.y.to_bits(), v.z.to_bits(), 0] }
fn f4(x: [f32; 4]) -> String { format!("{{ {}, {}, {}, {} }}", b(x[0]), b(x[1]), b(x[2]), b(x[3])) }
fn probe_s(p: &BoardProbeState) -> String { format!("{{ {}, {}, {}, {}, {} }}", v(p.start), v(p.point), v(p.normal), p.surface_tag, p.hit) }

pub fn write(out_dir: &str) {
    let Some(Stock { settings, masses, authored, step, simulation, data }) = stock() else { return };
    let (mut world, _, h) = crate::world::ramp();
    let query = WorldContactSettings { volume_padding: 0.05, maximum_separating_distance: 0.5, edge_cos_bend_normal_threshold: 0.999, convexity_epsilon: 0.01, is_object: false };
    let retention = ContactRetentionSettings { capacity: u32::MAX, duplicate_distance_squared: -1.0, deferred_reduction: true };
    let flags = 0x2000u32;
    let spawn = RetailAffineTransform { translation: Vector3::new(0.0, h + 0.3, 11.0), ..RetailAffineTransform::IDENTITY };
    let mut board = BoardRuntime::new(masses, authored, spawn, simulation, BoardMotion::Active);
    let mut riding = RidingOutputs::load(&data, &board, flags).unwrap();
    let dt = simulation.time_step;
    let mut s = String::from("-- Сгенерировано golden/src/riding_outputs.rs из настоящего skate-core. Не править.\nreturn {\n");
    writeln!(s, "\tspawn = {},\n\tload = {{ {}, {} }},\n\tticks = {{", v(spawn.translation), b(riding.heading_adjust_factor), b(riding.motion.forward_speed)).unwrap();
    let mut retained = [0.0, 1.0, 0.0, 0.0];
    for tick in 0..240u32 {
        board.clear_forces();
        if tick < 40 { board.forces_mut().append(QueuedPointForce { tag: 1, force_world: Vector3::new(0.0, 0.0, -24.0), point_body: Vector3::ZERO }); }
        riding.start_wheel_queries(&board, &world).unwrap();
        riding.finish_wheel_queries().unwrap();
        let processed = Processed {
            vectors_464_480_496_512_528: [bits4(riding.ground.wheel_normal), [0; 4], [0; 4], [0; 4], bits4(riding.ground.overall_normal)],
            vectors_544_560_592_608: [bits4(riding.reckoning.up), [0; 4], [0; 4], [0; 4]],
            scalar_2652: riding.motion.speed, scalar_2616: riding.motion.forward_speed.abs(), wheel_count_2556: riding.ground.wheel_contact_count as u32,
            state_2508: if tick % 50 < 25 { 100 } else { 101 }, time_on_ground_2752: tick as f32 * dt,
        };
        let spin = (tick as f32 * 0.05).sin() * 0.3;
        let balance = if tick % 60 < 40 { 0.0 } else { 0.25 };
        let com = Vector3::new(0.0, 0.9, 0.05);
        riding.update_ground_reckoning(&board, com, spin, flags, balance, tick % 97 == 0, &processed);
        let heading = riding.update_input_heading(riding.ground.wheel_normal.y, riding.motion.forward_speed);
        let volumes = world_volumes(&board, &settings);
        let collisions = world.query_primitives(&volumes, query, retention).to_vec();
        board.advance(&collisions, [0.0; 2], step);
        riding.finish_post_physics(&mut board, false, flags, dt);
        let toolkit = BoardToolkit::from_board(&board, flags, riding.motion.forward_speed, lanes(riding.ground.wheel_normal), retained);
        retained = toolkit.filtered_normal;
        riding.probes.prepare_wall(&processed, &toolkit);
        let g = &riding.ground; let wl = &riding.wheel_lines; let rc = &riding.reckoning; let rf = &riding.reckoning_frames; let m = &riding.motion;
        let deck = board.bodies()[6].rates;
        let words: Vec<String> = riding.body_spin.words().iter().map(|w| format!("0x{w:08x}")).collect();
        writeln!(s, "\t\t{{ spin = {}, balance = {}, coffin = {}, state = {}, contacts = {}, heading = {}, ground = {{ {}, {}, {}, {}, {{ {} }}, {} }}, lines = {{ {{ {} }}, {} }}, deck_probe = {}, wall_probe = {}, reck = {{ {}, {}, {}, {}, {} }}, frames = {{ {}, {}, {}, {}, {} }}, motion = {{ {}, {}, {}, {}, {} }}, body_spin = {{ {} }}, deck = {{ {}, {} }}, drag = {{ {} }}, toolkit = {} }},",
            b(spin), b(balance), tick % 97 == 0, processed.state_2508, collisions.len(), b(heading),
            v(g.wheel_normal), v(g.overall_normal), g.wheel_contact_count, g.part_contact_count, g.accelerations.iter().map(|&x| v(x)).collect::<Vec<_>>().join(", "), b(g.time_without_wheel_contact),
            wl.distances.map(b).join(", "), b(wl.minimum_distance), probe_s(&riding.probes.deck), probe_s(&riding.probes.wall),
            v(rc.up), v(rc.target), v(rc.up_velocity), v(rc.ground_normal), b(rc.ground_blend),
            f4(rf.system[0]), f4(rf.system[2]), f4(rf.heading), b(rf.target_lean_angle), f4(rf.lateral_tilt),
            b(m.speed), b(m.ground_speed), b(m.forward_speed), v(m.linear_velocity), v(m.ground_velocity),
            words.join(", "), v(deck.position), v(deck.linear_velocity), board.bodies()[..4].iter().map(|x| b(x.inertia.angular_drag)).collect::<Vec<_>>().join(", "), f4(toolkit.filtered_normal)).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/riding_outputs.luau"), s).unwrap();
}
