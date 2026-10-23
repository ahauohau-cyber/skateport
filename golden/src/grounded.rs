//! Эталон для physics/manual, riding/ground_contact_response и
//! riding/grounded (board::update с детерминированными сервисами-заглушками,
//! drag, propulsion, manual_entry, lifecycle, output, corrections, motion).
use crate::collision::{Rng};
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use crate::riding::graph;
use crate::riding2::{graph16, r4, thr, u4, up4, flags};
use skate_core::math::Vector3;
use skate_core::physics::force_queue::{BoardForceQueue, QueuedPointForce};
use skate_core::physics::manual::{angle, controller::{self, ManualAngleMeasurement, ManualInput}, settings::{ManualGains, ManualMode, ManualSettings}, state::ManualState};
use skate_core::physics::rigid_body::RetailInertiaDynamics;
use skate_core::riding::anti_flip::{AntiFlipInput, AntiFlipSettings};
use skate_core::riding::braking::{BrakeSettings, LinearDragSettings};
use skate_core::riding::collision_response::signed_angle;
use skate_core::riding::ground_contact_response::{wall_ride_response, WallRidePhysical, WallRideSettings};
use skate_core::riding::ground_correction_math as gcm;
use skate_core::riding::ground_force::GroundForceSettings;
use skate_core::riding::grounded::drag::{BodyInertias, GroundDragInput};
use skate_core::riding::grounded::propulsion::{GroundPropulsionInput, GroundPropulsionSettings};
use skate_core::riding::grounded::state::board::{self, GroundBoardOutcome};
use skate_core::riding::grounded::state::board_types::*;
use skate_core::riding::grounded::state::corrections::*;
use skate_core::riding::grounded::state::data::PhysicsGroundState;
use skate_core::riding::grounded::state::output::{fill_physics_output, GroundOutputFrame, GroundOutputSettings};
use skate_core::riding::grounded::state::motion;
use skate_core::riding::heading::{HeadingInput, HeadingSettings};
use skate_core::riding::pumping::PumpForceInput;
use skate_core::riding::slide_friction::{SlideFrictionInput, SlideFrictionSettings};
use skate_core::riding::speed_model::{SpeedModelInput, SpeedModelSettings, SpeedModelState};
use skate_core::riding::speed_wobble::{SpeedWobbleInput, SpeedWobbleSettings, SpeedWobbleState};
use skate_core::riding::steering::{SteeringInput, SteeringSettings, TruckSteeringState};
use skate_core::riding::straighten::{StraightenInput, StraightenSettings};
use std::fmt::Write as _;

fn xyz(v: [f32; 4]) -> Vector3 { Vector3::new(v[0], v[1], v[2]) }

struct Angle;
impl ManualAngleMeasurement for Angle {
    type Error = String;
    fn angle_between(&mut self, d: [f32; 4], z: [f32; 4], x: [f32; 4]) -> Result<f32, String> { Ok(signed_angle(xyz(d), xyz(z), xyz(x))) }
}

/// Детерминированные сервисы: каждый метод либо записывает событие и значение,
/// либо вызывает настоящую функцию ядра. Luau-тест повторяет их один в один.
struct Mock {
    com_height: f32,
    wall: WallRideSettings,
    wall_physical: WallRidePhysical,
    collision: Option<CollisionForceResponse>,
    edge: [[f32; 4]; 3],
    hung: bool,
    deck_y: [f32; 4],
    deck_z: [f32; 4],
    events: Vec<String>,
    vectors: Vec<[f32; 4]>,
}
impl Mock { fn ev(&mut self, s: &str) { self.events.push(s.to_string()); } }
impl ManualAngleMeasurement for Mock {
    type Error = String;
    fn angle_between(&mut self, d: [f32; 4], z: [f32; 4], x: [f32; 4]) -> Result<f32, String> { self.ev("angle"); Ok(signed_angle(xyz(d), xyz(z), xyz(x))) }
}
impl AntiFlipNudgeMath for Mock {
    type Error = String;
    fn dot3(&mut self, a: [f32; 4], b: [f32; 4]) -> Result<f32, String> { self.ev("dot3"); Ok(gcm::dot_product(a, b)) }
    fn scale_to_magnitude(&mut self, v: [f32; 4], sq: f32, m: f32) -> Result<[f32; 4], String> { self.ev("scale"); Ok(gcm::scale_to_magnitude(v, sq, m)) }
}
impl HangUpServices for Mock {
    type Error = String;
    fn build_hang_force(&mut self) -> Result<[f32; 4], String> { self.ev("build_hang"); Ok(gcm::hang_force(self.edge[0], self.edge[1], self.edge[2])) }
    fn apply_hang_force(&mut self, f: [f32; 4]) -> Result<(), String> { self.ev("apply_hang"); self.vectors.push(f); Ok(()) }
    fn detect_hung_up_geometry(&mut self) -> Result<bool, String> { self.ev("detect_hung"); Ok(self.hung) }
    fn request_wipeout(&mut self) -> Result<(), String> { self.ev("wipeout"); Ok(()) }
}
impl HalfpipeWheelCatchServices for Mock {
    type Error = String;
    fn angular_displacement(&mut self) -> Result<[f32; 4], String> { self.ev("catch_disp"); Ok(gcm::wheel_catch_displacement(self.deck_y, self.deck_z)) }
    fn apply_angular_displacement(&mut self, v: [f32; 4]) -> Result<(), String> { self.ev("catch_apply"); self.vectors.push(v); Ok(()) }
}
impl PinningServices for Mock {
    type Error = String;
    fn pin_to_captured_position(&mut self, x: f32, z: f32) -> Result<(), String> { self.ev("pin"); self.vectors.push([x, 0.0, z, 0.0]); Ok(()) }
}
impl GroundBoardServices for Mock {
    type BoardError = String;
    type AnimatedPose = u32;
    fn center_of_mass_height_82d38838(&mut self) -> Result<f32, String> { self.ev("com_height"); Ok(self.com_height) }
    fn set_contact_wheel_materials(&mut self) -> Result<(), String> { self.ev("wheel_materials"); Ok(()) }
    fn contact_response_82d93df0(&mut self, frame: GroundContactFrame, prev: [f32; 4]) -> Result<GroundContactResponse, String> { self.ev("contact_response"); Ok(wall_ride_response(&self.wall, self.wall_physical, frame, prev)) }
    fn update_body_accumulator_82d389dc(&mut self) -> Result<(), String> { self.ev("accumulator"); Ok(()) }
    fn set_animated_velocity_82c04168(&mut self, v: [f32; 4]) -> Result<(), String> { self.ev("set_animated_velocity"); self.vectors.push(v); Ok(()) }
    fn write_processed_velocity_400(&mut self, v: [f32; 4]) -> Result<(), String> { self.ev("write_velocity"); self.vectors.push(v); Ok(()) }
    fn build_animated_pose_82d33448(&mut self) -> Result<u32, String> { self.ev("build_pose"); Ok(7) }
    fn publish_animated_pose_82be33d0(&mut self, p: &u32) -> Result<(), String> { self.ev(&format!("publish_pose{p}")); Ok(()) }
    fn update_external_player_82d67848(&mut self, p: &u32, v: [f32; 4]) -> Result<(), String> { self.ev(&format!("external{p}")); self.vectors.push(v); Ok(()) }
    fn commit_external_player_82d68800(&mut self) -> Result<(), String> { self.ev("commit_external"); Ok(()) }
    fn finalize_animated_board_sk83_na_f_01a4(&mut self) -> Result<(), String> { self.ev("finalize"); Ok(()) }
    fn collision_force_82d944e8(&mut self, v: [f32; 4]) -> Result<Option<CollisionForceResponse>, String> { self.ev("collision_force"); self.vectors.push(v); Ok(self.collision) }
    fn collision_force_dot_velocity_82d38e18(&mut self, f: [f32; 4], v: [f32; 4]) -> Result<f32, String> { self.ev("collision_dot"); Ok(gcm::collision_force_projection(f, v)) }
    fn apply_vector_82c07000(&mut self, v: [f32; 4]) -> Result<(), String> { self.ev("apply_vector"); self.vectors.push(v); Ok(()) }
    fn apply_angular_displacement_82c075b8(&mut self, v: [f32; 4]) -> Result<(), String> { self.ev("apply_angular"); self.vectors.push(v); Ok(()) }
}

fn gl(r: &mut Rng) -> skate_core::point_graph::PointGraph<8> { graph(r) }
fn ms(r: &mut Rng) -> ManualSettings {
    let g = |r: &mut Rng| ManualGains { proportional: r.range(0.0, 1.0), integral: r.range(0.0, 0.5), derivative: r.range(0.0, 1.0) };
    ManualSettings { noise_vs_speed: gl(r), torque_scale_without_contact: r.range(0.0, 1.0), torque_bleed_without_contact: r.range(0.0, 1.0), start_torque_scale: r.range(0.0, 1.0),
        procedural_noise_scale: r.range(0.0, 0.2), procedural_noise_frequency: r.range(0.0, 3.0), powerslide: g(r), manual: g(r), maximum_tilt_degrees: r.range(0.0, 40.0),
        maximum_angle_error: r.range(0.05, 1.0), derivative_limit: r.range(0.05, 1.0), brake_tilt_degrees: r.range(0.0, 30.0), animation_noise_scale: r.range(0.0, 1.0) }
}
fn ms_l(s: &ManualSettings) -> String {
    let g = |g: ManualGains| obj!(proportional = g.proportional, integral = g.integral, derivative = g.derivative);
    obj!(noise_vs_speed = s.noise_vs_speed, torque_scale_without_contact = s.torque_scale_without_contact, torque_bleed_without_contact = s.torque_bleed_without_contact,
        start_torque_scale = s.start_torque_scale, procedural_noise_scale = s.procedural_noise_scale, procedural_noise_frequency = s.procedural_noise_frequency,
        powerslide = Raw(g(s.powerslide)), manual = Raw(g(s.manual)), maximum_tilt_degrees = s.maximum_tilt_degrees, maximum_angle_error = s.maximum_angle_error,
        derivative_limit = s.derivative_limit, brake_tilt_degrees = s.brake_tilt_degrees, animation_noise_scale = s.animation_noise_scale)
}
fn mi(r: &mut Rng) -> ManualInput {
    ManualInput { balance: if r.next() % 4 == 0 { 0.0 } else { r.range(-1.0, 1.0) }, flipped_controls: if r.bool() { 1.0 } else { -1.0 }, procedural_noise_time: r.range(0.0, 10.0),
        absolute_speed: r.range(0.0, 10.0), animation_noise: r.range(-1.0, 1.0), timestep: 1.0 / 60.0, powersliding: r.next() % 5 == 0, braking: r.next() % 3 == 0,
        positive_balance_contact: r.bool(), negative_balance_contact: r.bool(), reversed_point_selection: r.bool(), reference_x: u4(r), reference_z: u4(r), deck_z: u4(r),
        velocity_frame_z: u4(r), angular_velocity_world: r4(r, 3.0), correction_point_7888: r4(r, 0.5), correction_point_7952: r4(r, 0.5) }
}
fn mi_l(i: &ManualInput) -> String {
    obj!(balance = i.balance, flipped_controls = i.flipped_controls, procedural_noise_time = i.procedural_noise_time, absolute_speed = i.absolute_speed, animation_noise = i.animation_noise,
        timestep = i.timestep, powersliding = i.powersliding, braking = i.braking, positive_balance_contact = i.positive_balance_contact, negative_balance_contact = i.negative_balance_contact,
        reversed_point_selection = i.reversed_point_selection, reference_x = i.reference_x, reference_z = i.reference_z, deck_z = i.deck_z, velocity_frame_z = i.velocity_frame_z,
        angular_velocity_world = i.angular_velocity_world, correction_point_7888 = i.correction_point_7888, correction_point_7952 = i.correction_point_7952)
}
fn mstate_l(s: &ManualState) -> String { obj!(filtered_angle_error = s.filtered_angle_error, target_angle = s.target_angle, measured_angle = s.measured_angle, angular_correction = s.angular_correction, elapsed = s.elapsed) }
fn effect_l(e: &controller::ManualEffect) -> String {
    obj!(angular_displacement = e.angular_displacement, force_world = e.force_world, force_point_body = e.force_point_body, corrective_force_world = e.corrective_force_world,
        corrective_point_body = e.corrective_point_body, correction_active = e.correction_active, opposing_motion_without_correction = e.opposing_motion_without_correction)
}
fn mode(r: &mut Rng) -> ManualMode { ManualMode { correction_angular_speed_threshold: r.range(0.0, 2.0), corrective_force_enabled: r.bool() } }
fn mode_l(m: &ManualMode) -> String { obj!(correction_angular_speed_threshold = m.correction_angular_speed_threshold, corrective_force_enabled = m.corrective_force_enabled) }
fn wall(r: &mut Rng) -> WallRideSettings {
    WallRideSettings { anti_gravity_vs_time: gl(r), max_dot_floor_wall: r.range(0.0, 1.0), foot_force_time: r.range(0.0, 0.3), auto_jump_height: r.range(0.0, 1.0), max_time: r.range(0.0, 2.0),
        velocity_time_to_consider: r.range(0.0, 0.5), auto_jump_y_down_scalar: r.range(0.0, 1.0), auto_jump_force: r.range(0.0, 5.0) }
}
fn wall_l(w: &WallRideSettings) -> String {
    obj!(anti_gravity_vs_time = w.anti_gravity_vs_time, max_dot_floor_wall = w.max_dot_floor_wall, foot_force_time = w.foot_force_time, auto_jump_height = w.auto_jump_height,
        max_time = w.max_time, velocity_time_to_consider = w.velocity_time_to_consider, auto_jump_y_down_scalar = w.auto_jump_y_down_scalar, auto_jump_force = w.auto_jump_force)
}
fn wallp(r: &mut Rng) -> WallRidePhysical {
    let n = if r.bool() { [1.0, 0.1, 0.0, 0.0] } else { up4(r) };
    WallRidePhysical { board_normal: n, up: if r.bool() { n } else { u4(r) }, velocity: r4(r, 6.0), board_mass: r.range(1.0, 80.0), gravity: 9.81, speed: r.range(0.0, 8.0), contact_count: (r.next() % 3) as i32 }
}
fn wallp_l(p: &WallRidePhysical) -> String { obj!(board_normal = p.board_normal, up = p.up, velocity = p.velocity, board_mass = p.board_mass, gravity = p.gravity, speed = p.speed, contact_count = p.contact_count) }
fn frame(r: &mut Rng) -> GroundContactFrame {
    GroundContactFrame { vector_8032: r4(r, 2.0), vector_8048: r4(r, 2.0), vector_8064: up4(r), word_8080: r.next() & 0xffff, flag_8084: r.next() % 3 != 0, scalar_2752: r.range(0.0, 0.3), scalar_2756: r.range(-1.5, 1.5) }
}
fn frame_l(f: &GroundContactFrame) -> String { obj!(vector_8032 = f.vector_8032, vector_8048 = f.vector_8048, vector_8064 = f.vector_8064, word_8080 = f.word_8080, flag_8084 = f.flag_8084, scalar_2752 = f.scalar_2752, scalar_2756 = f.scalar_2756) }
fn response_l(c: &GroundContactResponse) -> String { obj!(active_2731 = c.active_2731, tag_16_force = c.tag_16_force, vector_2688 = c.vector_2688, scalar_2704 = c.scalar_2704, animated_board_2708 = c.animated_board_2708) }
fn state_l(s: &PhysicsGroundState) -> String {
    obj!(collision_force_2528 = s.collision_force_2528, collision_point_2544 = s.collision_point_2544, word_2560 = s.word_2560, word_2564 = s.word_2564, vector_2592 = s.vector_2592,
        vector_2608 = s.vector_2608, anti_flip_torque_2624 = s.anti_flip_torque_2624, steering_push_scalar_2640 = s.steering_push_scalar_2640, steering_damped_turn_2644 = s.steering_damped_turn_2644,
        elapsed_2648 = s.elapsed_2648, collision_countdown_2652 = s.collision_countdown_2652, captured_position_x_2656 = s.captured_position_x_2656, captured_position_z_2660 = s.captured_position_z_2660,
        scalar_2664 = s.scalar_2664, scalar_2668 = s.scalar_2668, straighten_scale_2672 = s.straighten_scale_2672, vector_2688 = s.vector_2688, scalar_2704 = s.scalar_2704, flag_2708 = s.flag_2708,
        flag_2720 = s.flag_2720, flag_2721 = s.flag_2721, flag_2722 = s.flag_2722, anti_flip_nudge_applied_2723 = s.anti_flip_nudge_applied_2723, human_player_2724 = s.human_player_2724,
        controls_latched_2725 = s.controls_latched_2725, captured_position_valid_2726 = s.captured_position_valid_2726, pinning_2727 = s.pinning_2727, was_pinning_2728 = s.was_pinning_2728,
        flag_2729 = s.flag_2729, push_suppressed_2730 = s.push_suppressed_2730, flag_2731 = s.flag_2731, manual_correction_2732 = s.manual_correction_2732, manual_opposition_2733 = s.manual_opposition_2733,
        hang_detection_frames_2740 = s.hang_detection_frames_2740, hang_force_frames_2744 = s.hang_force_frames_2744, hung_wipeout_frames_2748 = s.hung_wipeout_frames_2748, anti_flip_nudge_frames_2752 = s.anti_flip_nudge_frames_2752)
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x6e0d_d00d);
    let mut s = String::from("-- Сгенерировано golden/src/grounded.rs из настоящего skate-core. Не править.\n");
    s.push_str(HEADER);
    s.push_str("return {\n\tangle = {\n");
    for _ in 0..2000 {
        let a = match r.next() % 4 { 0 => r.range(-3.0, 3.0), 1 => r.range(-100.0, 100.0), 2 => r.range(-1e9, 1e9), _ => if r.bool() { f32::NAN } else { r.range(-3.2e10, 3.2e10) } };
        let out = match angle::normalize(a) { Ok(v) => v.l(), Err(_) => "false".into() };
        writeln!(s, "\t\t{{ {}, {} }},", a.l(), out).unwrap();
    }
    s.push_str("\t},\n\tmanual = {\n");
    for _ in 0..120 {
        let st = ms(&mut r); let m = mode(&mut r);
        let mut state = ManualState { filtered_angle_error: 0.0, target_angle: 0.0, measured_angle: 0.0, angular_correction: 0.0, elapsed: 0.0 };
        let mut steps = String::new();
        for _ in 0..25 {
            let i = mi(&mut r);
            let e = controller::calculate(&mut state, &st, m, &i, &mut Angle).unwrap();
            write!(steps, "{{ input = {}, effect = {}, state = {} }}, ", mi_l(&i), effect_l(&e), mstate_l(&state)).unwrap();
        }
        let mut entry = String::new();
        for _ in 0..4 {
            let cat = if r.bool() { 100 } else { 200 }; let sc = r.range(0.0, 1.0);
            let before = mstate_l(&state);
            let c = state.enter_ground(cat, sc);
            write!(entry, "{{ {}, {}, {}, {}, {} }}, ", cat, sc.l(), before, matches!(c, skate_core::physics::manual::state::ManualEntryContinuation::RemoveVelocityIntoGround), mstate_l(&state)).unwrap();
        }
        writeln!(s, "\t\t{{ settings = {}, mode = {}, steps = {{ {} }}, entry = {{ {} }} }},", ms_l(&st), mode_l(&m), steps, entry).unwrap();
    }
    s.push_str("\t},\n\twall = {\n");
    for _ in 0..1500 {
        let w = wall(&mut r); let p = wallp(&mut r); let f = frame(&mut r); let prev = r4(&mut r, 3.0);
        let o = wall_ride_response(&w, p, f, prev);
        writeln!(s, "\t\t{{ {}, {}, {}, {}, {} }},", wall_l(&w), wallp_l(&p), frame_l(&f), prev.l(), response_l(&o)).unwrap();
    }
    s.push_str("\t},\n\tboard = {\n");
    for case in 0..25 {
        let steering = SteeringSettings { hard_turn_increase: r.range(0.0, 2.0), damping: r.range(0.0, 1.0), speed_graph_max_speed: r.range(0.5, 10.0), push_scalar_increment: r.range(0.0, 0.2),
            push_scalar_decrement: r.range(0.0, 0.2), push_scalar_min: r.range(0.0, 0.8), manual_scalar: r.range(0.0, 2.0), general_scalar: r.range(0.0, 2.0), tight_trucks_scalar: r.range(0.0, 2.0),
            speed_graph: gl(&mut r), input_graph: gl(&mut r), tilt_blending: r.range(0.0, 1.0) };
        let wobble = SpeedWobbleSettings { frequency_time: gl(&mut r), frequency_speed: gl(&mut r), amplitude_time: gl(&mut r), amplitude_speed: gl(&mut r), tightness_threshold: r.range(0.0, 3.0),
            time_range: r.range(0.2, 3.0), speed_range: r.range(0.5, 5.0), frequency_scale: r.range(0.0, 20.0), amplitude_scale: r.range(0.0, 0.5), crouch_threshold: r.range(0.0, 3.0), height_min: 0.3, height_max: 1.0 };
        let gforce = GroundForceSettings { range_1220: r.range(0.1, 5.0), speed_scale_1224: r.range(0.0, 3.0), scale_1228: r.range(0.0, 3.0), normal_threshold: thr(&mut r) };
        let smodel = SpeedModelSettings { negative_gain: r.range(0.0, 3.0), maximum_gravity_acceleration: r.range(0.0, 10.0), gravity: 9.81, positive_gain: r.range(0.0, 3.0), coffin_acceleration: r.range(0.0, 3.0),
            speed_error_bound: r.range(0.1, 3.0), surface_friction: gl(&mut r), manual_acceleration: r.range(0.0, 3.0), negative_manual_angle_limit: r.range(0.0, 1.0), manual_angle_limit: r.range(0.0, 1.0),
            no_input_delay: r.range(0.0, 3.0), no_input_friction: gl(&mut r), manual_friction: gl(&mut r), override_enabled: r.bool(), override_speed: r.range(0.0, 15.0), normal_threshold: thr(&mut r),
            override_direction_threshold: core::array::from_fn(|_| r.range(-1.0, 1.0)) };
        let slide = SlideFrictionSettings { angle_response: graph16(&mut r), speed_response: gl(&mut r), time_response: graph16(&mut r), scalar_516: r.range(0.0, 1.0), heading_time_limit: r.range(0.1, 2.0), friction: r.range(0.0, 5.0) };
        let straight = StraightenSettings { time_response: graph16(&mut r), opposite_turn_limit: r.range(0.1, 1.0), time_scalar: r.range(0.0, 1.0), heading_time_limit: r.range(0.1, 2.0), strength: r.range(0.0, 5.0) };
        let head = HeadingSettings { manual_wrong_wheel_scalar: r.range(0.0, 2.0), manual_damping: r.range(0.0, 1.0), speed_max: r.range(0.5, 12.0), heading_strength: r.range(0.0, 5.0), turn_strength: r.range(0.0, 5.0),
            angular_response: gl(&mut r), manual_response: gl(&mut r), inclination_response: gl(&mut r), speed_response: gl(&mut r), normal_threshold: thr(&mut r) };
        let aflip = AntiFlipSettings { axis_96_response: gl(&mut r), axis_64_response: gl(&mut r), normal_threshold: thr(&mut r) };
        let manual = ms(&mut r); let mmode = mode(&mut r);
        let prop = GroundPropulsionSettings { braking: BrakeSettings { input_force: r.range(0.0, 50.0), override_force: r.range(0.0, 50.0), minimum_speed: r.range(0.0, 1.0) },
            maximum_pushable_speed: r.range(1.0, 10.0), mode_speed_changes: [r.range(0.0, 3.0), r.range(0.0, 3.0)] };
        let ldrag = LinearDragSettings { brake_speed: r.range(0.0, 2.0), balance_speed: r.range(0.0, 5.0), comparison_threshold: r.range(0.0, 1.0), balance_drag: r.range(0.0, 3.0) };
        let crd = r.range(0.0, 0.5); let crs = r.range(0.0, 1.0); let gfl = r.range(0.0, 1.0); let smr = r.range(0.0, 2000.0);
        let settings_l = obj!(steering = Raw(obj!(hard_turn_increase = steering.hard_turn_increase, damping = steering.damping, speed_graph_max_speed = steering.speed_graph_max_speed,
                push_scalar_increment = steering.push_scalar_increment, push_scalar_decrement = steering.push_scalar_decrement, push_scalar_min = steering.push_scalar_min, manual_scalar = steering.manual_scalar,
                general_scalar = steering.general_scalar, tight_trucks_scalar = steering.tight_trucks_scalar, speed_graph = steering.speed_graph, input_graph = steering.input_graph, tilt_blending = steering.tilt_blending)),
            speed_wobble = Raw(obj!(frequency_time = wobble.frequency_time, frequency_speed = wobble.frequency_speed, amplitude_time = wobble.amplitude_time, amplitude_speed = wobble.amplitude_speed,
                tightness_threshold = wobble.tightness_threshold, time_range = wobble.time_range, speed_range = wobble.speed_range, frequency_scale = wobble.frequency_scale, amplitude_scale = wobble.amplitude_scale,
                crouch_threshold = wobble.crouch_threshold, height_min = wobble.height_min, height_max = wobble.height_max)),
            propulsion = Raw(obj!(braking = Raw(obj!(input_force = prop.braking.input_force, override_force = prop.braking.override_force, minimum_speed = prop.braking.minimum_speed)),
                maximum_pushable_speed = prop.maximum_pushable_speed, mode_speed_changes = prop.mode_speed_changes)),
            ground_force = Raw(obj!(range_1220 = gforce.range_1220, speed_scale_1224 = gforce.speed_scale_1224, scale_1228 = gforce.scale_1228, normal_threshold = gforce.normal_threshold)),
            speed_model = Raw(obj!(negative_gain = smodel.negative_gain, maximum_gravity_acceleration = smodel.maximum_gravity_acceleration, gravity = smodel.gravity, positive_gain = smodel.positive_gain,
                coffin_acceleration = smodel.coffin_acceleration, speed_error_bound = smodel.speed_error_bound, surface_friction = smodel.surface_friction, manual_acceleration = smodel.manual_acceleration,
                negative_manual_angle_limit = smodel.negative_manual_angle_limit, manual_angle_limit = smodel.manual_angle_limit, no_input_delay = smodel.no_input_delay, no_input_friction = smodel.no_input_friction,
                manual_friction = smodel.manual_friction, override_enabled = smodel.override_enabled, override_speed = smodel.override_speed, normal_threshold = smodel.normal_threshold,
                override_direction_threshold = smodel.override_direction_threshold)),
            slide_friction = Raw(obj!(angle_response = slide.angle_response, speed_response = slide.speed_response, time_response = slide.time_response, scalar_516 = slide.scalar_516,
                heading_time_limit = slide.heading_time_limit, friction = slide.friction)),
            straighten = Raw(obj!(time_response = straight.time_response, opposite_turn_limit = straight.opposite_turn_limit, time_scalar = straight.time_scalar, heading_time_limit = straight.heading_time_limit, strength = straight.strength)),
            heading = Raw(obj!(manual_wrong_wheel_scalar = head.manual_wrong_wheel_scalar, manual_damping = head.manual_damping, speed_max = head.speed_max, heading_strength = head.heading_strength,
                turn_strength = head.turn_strength, angular_response = head.angular_response, manual_response = head.manual_response, inclination_response = head.inclination_response,
                speed_response = head.speed_response, normal_threshold = head.normal_threshold)),
            anti_flip = Raw(obj!(axis_96_response = aflip.axis_96_response, axis_64_response = aflip.axis_64_response, normal_threshold = aflip.normal_threshold)),
            manual = Raw(ms_l(&manual)), manual_mode = Raw(mode_l(&mmode)),
            linear_drag = Raw(obj!(brake_speed = ldrag.brake_speed, balance_speed = ldrag.balance_speed, comparison_threshold = ldrag.comparison_threshold, balance_drag = ldrag.balance_drag)),
            collision_response_duration = crd, collision_response_scale = crs, ground_force_contact_time_limit = gfl, speed_model_reset_force_squared = smr);
        // Состояния компонентов живут через тики.
        let mut state = PhysicsGroundState::before_first_enter(r.bool());
        state.finish_entry(if r.bool() { 101 } else { 0 });
        let mut wob = SpeedWobbleState([0; 8]);
        let mut truck = TruckSteeringState::default();
        let mut sm = SpeedModelState { target_speed: r.range(0.0, 5.0), flags_1360: 0 };
        let mut mstate = ManualState { filtered_angle_error: 0.0, target_angle: 0.0, measured_angle: 0.0, angular_correction: 0.0, elapsed: 0.0 };
        let mut heading_prev = 0.0f32;
        let indices: Vec<usize> = (0..7).map(|_| (r.next() % 3) as usize).collect();
        let mut inertias: Vec<RetailInertiaDynamics> = (0..3).map(|_| RetailInertiaDynamics { inverse_tensor: r.vec(1.0), inverse_mass: r.range(0.0, 1.0), spherical: 0.0,
            maximum_linear_velocity: 100.0, maximum_angular_velocity: 100.0, linear_drag: r.range(0.0, 1.0), angular_drag: 0.0 }).collect();
        let init_inertia = inertias.iter().map(|i| Raw(obj!(linear_drag = i.linear_drag))).collect::<Vec<_>>();
        let init = obj!(state = Raw(state_l(&state)), target_speed = sm.target_speed, indices = indices.clone(), inertias = init_inertia);
        let mut ticks = String::new();
        for tick in 0..20 {
            let w = wall(&mut r); let wp = wallp(&mut r);
            let collision = if r.next() % 8 == 0 { Some(CollisionForceResponse { force_2528: r4(&mut r, 50.0), point_2544: r4(&mut r, 0.3), vector_2592: r4(&mut r, 1.0) }) } else { None };
            let mut mock = Mock { com_height: r.range(0.2, 1.2), wall: w.clone(), wall_physical: wp, collision, edge: [r4(&mut r, 2.0), r4(&mut r, 2.0), r4(&mut r, 2.0)], hung: r.next() % 3 == 0,
                deck_y: up4(&mut r), deck_z: u4(&mut r), events: vec![], vectors: vec![] };
            let st_in = SteeringInput { turn: r.range(-1.0, 1.0), hard_turn: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, absolute_body_speed: r.range(0.0, 10.0), flipped_controls_scalar: 1.0,
                balance: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, truck_tightness: r.range(0.0, 1.0), pushing: r.bool() };
            let wob_in = SpeedWobbleInput { tilt: 0.0, speed: r.range(0.0, 10.0), center_of_mass_height: 0.0, truck_tightness: st_in.truck_tightness, activation_threshold: r.range(0.0, 8.0), amplitude_multiplier: r.range(0.0, 2.0) };
            let f2468 = flags(&mut r) | (if r.bool() { 0x0200_0000 } else { 0 }) | (if r.next() % 4 == 0 { 0x4000_0000 } else { 0 });
            let f2472 = flags(&mut r) | (if r.bool() { 3 << 26 } else { 0 });
            let cf = frame(&mut r);
            let speed = r.range(-8.0, 8.0);
            let propulsion = GroundPropulsionInput { flags_2468: f2468, flags_2472: f2472, target_speed: r.range(0.0, 10.0), signed_speed: speed, absolute_body_speed: speed.abs(), scalar_2660: r.range(5.0, 80.0),
                timestep: 1.0 / 60.0, brake_input: r.range(0.0, 1.0), push_direction: r.vec(1.0), brake_direction: r.vec(1.0), surface_braking_factor: r.range(0.0, 2.0) };
            let gff = GroundForceFrame { argument_1_2752: r.range(0.0, 3.0), processed_2776: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, processed_2780: r.range(-1.0, 1.0), previous_state_scalar_56: r.range(-1.0, 1.0),
                ground_scalar_1216: r.range(-1.0, 1.0), ground_scalar_1232: r.range(-1.0, 1.0), ground_scalar_1236: r.range(-1.0, 1.0), ground_scalar_1240: r.range(-1.0, 1.0),
                balance_2720: st_in.balance, surface_speed_2656: r.range(0.0, 10.0), axis_384: u4(&mut r), velocity_400: r4(&mut r, 6.0), axis_544: up4(&mut r) };
            let smi = SpeedModelInput { flags_2468: f2468 & !0x6201_0000, flags_2476: flags(&mut r), wheel_contact_count: (r.next() % 5) as i32, frames_2580: (r.next() % 60) as i32, timestep: 1.0 / 60.0,
                signed_speed: speed, angle_2652: r.range(-1.0, 1.0), surface_speed: r.range(0.0, 10.0), turn_2672: r.range(-1.0, 1.0), balance: st_in.balance, elapsed_without_input: r.range(0.0, 4.0),
                manual_state_276: 0.0, vector_160: u4(&mut r), vector_352: u4(&mut r), velocity_416: r4(&mut r, 6.0), normal_464: up4(&mut r), effective_forward: u4(&mut r), mass: r.range(5.0, 80.0) };
            let sfi = SlideFrictionInput { heading_time: 0.0, normal: up4(&mut r), velocity: r4(&mut r, 6.0), side_axis: u4(&mut r), surface_speed: r.range(0.0, 10.0), scalar_2764: r.range(0.0, 1.0) };
            let pfi = PumpForceInput { flags_2476: r.next() & 3, mode_multiplier: r.range(0.0, 2.0), pumping_scalar: r.range(-0.5, 0.5), input_scalar_2660: r.range(5.0, 80.0), timestep: 1.0 / 60.0, direction_432: r4(&mut r, 3.0), normal_threshold: thr(&mut r) };
            let sti = StraightenInput { heading_time: 0.0, scalar_2764: r.range(0.0, 1.0), turn: st_in.turn, forward: u4(&mut r), velocity: r4(&mut r, 6.0), normal: up4(&mut r) };
            let hi = HeadingInput { balance: st_in.balance, manual_turn: if r.bool() { r.range(-1.0, 1.0) } else { 0.0 }, flags_2472: f2472, timestep: 1.0 / 60.0, signed_speed: speed, manual_curve_input: r.range(0.0, 1.0),
                turn_2712: r.range(-1.0, 1.0), scalar_2740: r.range(0.0, 2.0), velocity: r4(&mut r, 6.0), normal: up4(&mut r), angular_velocity: r4(&mut r, 2.0), transform: [up4(&mut r), u4(&mut r), u4(&mut r), r4(&mut r, 5.0)] };
            let afi = AntiFlipInput { flags_2468: f2468, balance: st_in.balance, axis_96: u4(&mut r), axis_64: up4(&mut r), projection_axis_544: up4(&mut r) };
            let mut man = mi(&mut r); man.balance = st_in.balance;
            let gdi = GroundDragInput { flags_2468: f2468, absolute_body_speed_2616: speed.abs(), balance_2720: st_in.balance, scalar_2724: r.range(-1.0, 1.0), ground_normal_y: r.range(0.0, 1.0) };
            let nudge = AntiFlipNudgeInput { deck_speed_2652: r.range(0.0, 2.0), deck_axis_96: u4(&mut r) };
            let hang = HangUpInput { flags_1516: if r.bool() { 0x0c00_0000 } else { flags(&mut r) }, deck_speed_2652: r.range(0.0, 2.0), scalar_84: r.range(0.0, 1.0), geometry_axis_dot_positive: r.bool() };
            let catch = HalfpipeWheelCatchInput { flags_1516: if r.bool() { 0x0800_0000 } else { 0 }, deck_speed_2652: r.range(0.0, 4.0), deck_x_axis_y: r.range(-1.0, 1.0), deck_y_axis_y: r.range(-0.2, 0.2), signed_deck_distance: r.range(-0.1, 0.2) };
            let pin = PinningInput { flags_2488: r.next() % 4 / 3, frames_since_teleport_2584: (r.next() % 100) as i32, flags_2472: f2472 };
            let input_l = obj!(steering = Raw(obj!(turn = st_in.turn, hard_turn = st_in.hard_turn, absolute_body_speed = st_in.absolute_body_speed, flipped_controls_scalar = st_in.flipped_controls_scalar,
                    balance = st_in.balance, truck_tightness = st_in.truck_tightness, pushing = st_in.pushing)),
                speed_wobble = Raw(obj!(tilt = wob_in.tilt, speed = wob_in.speed, center_of_mass_height = wob_in.center_of_mass_height, truck_tightness = wob_in.truck_tightness,
                    activation_threshold = wob_in.activation_threshold, amplitude_multiplier = wob_in.amplitude_multiplier)),
                truck_flags_2468 = f2468, truck_flags_2472 = f2472, contact = Raw(frame_l(&cf)), ground_vector_1216 = gff.axis_544,
                propulsion = Raw(obj!(flags_2468 = propulsion.flags_2468, flags_2472 = propulsion.flags_2472, target_speed = propulsion.target_speed, signed_speed = propulsion.signed_speed,
                    absolute_body_speed = propulsion.absolute_body_speed, scalar_2660 = propulsion.scalar_2660, timestep = propulsion.timestep, brake_input = propulsion.brake_input,
                    push_direction = propulsion.push_direction, brake_direction = propulsion.brake_direction, surface_braking_factor = propulsion.surface_braking_factor)),
                ground_force = Raw(obj!(argument_1_2752 = gff.argument_1_2752, processed_2776 = gff.processed_2776, processed_2780 = gff.processed_2780, previous_state_scalar_56 = gff.previous_state_scalar_56,
                    ground_scalar_1216 = gff.ground_scalar_1216, ground_scalar_1232 = gff.ground_scalar_1232, ground_scalar_1236 = gff.ground_scalar_1236, ground_scalar_1240 = gff.ground_scalar_1240,
                    balance_2720 = gff.balance_2720, surface_speed_2656 = gff.surface_speed_2656, axis_384 = gff.axis_384, velocity_400 = gff.velocity_400, axis_544 = gff.axis_544)),
                speed_model = Raw(obj!(flags_2468 = smi.flags_2468, flags_2476 = smi.flags_2476, wheel_contact_count = smi.wheel_contact_count, frames_2580 = smi.frames_2580, timestep = smi.timestep,
                    signed_speed = smi.signed_speed, angle_2652 = smi.angle_2652, surface_speed = smi.surface_speed, turn_2672 = smi.turn_2672, balance = smi.balance, elapsed_without_input = smi.elapsed_without_input,
                    manual_state_276 = smi.manual_state_276, vector_160 = smi.vector_160, vector_352 = smi.vector_352, velocity_416 = smi.velocity_416, normal_464 = smi.normal_464,
                    effective_forward = smi.effective_forward, mass = smi.mass)),
                slide_friction = Raw(obj!(heading_time = sfi.heading_time, normal = sfi.normal, velocity = sfi.velocity, side_axis = sfi.side_axis, surface_speed = sfi.surface_speed, scalar_2764 = sfi.scalar_2764)),
                pump_force = Raw(obj!(flags_2476 = pfi.flags_2476, mode_multiplier = pfi.mode_multiplier, pumping_scalar = pfi.pumping_scalar, input_scalar_2660 = pfi.input_scalar_2660, timestep = pfi.timestep,
                    direction_432 = pfi.direction_432, normal_threshold = pfi.normal_threshold)),
                straighten = Raw(obj!(heading_time = sti.heading_time, scalar_2764 = sti.scalar_2764, turn = sti.turn, forward = sti.forward, velocity = sti.velocity, normal = sti.normal)),
                heading = Raw(obj!(balance = hi.balance, manual_turn = hi.manual_turn, flags_2472 = hi.flags_2472, timestep = hi.timestep, signed_speed = hi.signed_speed, manual_curve_input = hi.manual_curve_input,
                    turn_2712 = hi.turn_2712, scalar_2740 = hi.scalar_2740, velocity = hi.velocity, normal = hi.normal, angular_velocity = hi.angular_velocity, transform = hi.transform)),
                anti_flip = Raw(obj!(flags_2468 = afi.flags_2468, balance = afi.balance, axis_96 = afi.axis_96, axis_64 = afi.axis_64, projection_axis_544 = afi.projection_axis_544)),
                manual = Raw(mi_l(&man)),
                ground_drag = Raw(obj!(flags_2468 = gdi.flags_2468, absolute_body_speed_2616 = gdi.absolute_body_speed_2616, balance_2720 = gdi.balance_2720, scalar_2724 = gdi.scalar_2724, ground_normal_y = gdi.ground_normal_y)),
                contact_time_2756 = cf.scalar_2756.abs(), trajectory_state_1776_bits = if r.bool() { 0x8000_0000u32 } else { 0 },
                anti_flip_nudge = Raw(obj!(deck_speed_2652 = nudge.deck_speed_2652, deck_axis_96 = nudge.deck_axis_96)),
                hang_up = Raw(obj!(flags_1516 = hang.flags_1516, deck_speed_2652 = hang.deck_speed_2652, scalar_84 = hang.scalar_84, geometry_axis_dot_positive = hang.geometry_axis_dot_positive)),
                halfpipe_wheel_catch = Raw(obj!(flags_1516 = catch.flags_1516, deck_speed_2652 = catch.deck_speed_2652, deck_x_axis_y = catch.deck_x_axis_y, deck_y_axis_y = catch.deck_y_axis_y, signed_deck_distance = catch.signed_deck_distance)),
                pinning = Raw(obj!(flags_2488 = pin.flags_2488, frames_since_teleport_2584 = pin.frames_since_teleport_2584, flags_2472 = pin.flags_2472)));
            // Восстанавливаем значение trajectory_state_1776_bits из уже записанной строки.
            let traj = if input_l.contains("trajectory_state_1776_bits = 2147483648") { 0x8000_0000u32 } else { 0 };
            let mock_l = obj!(com_height = mock.com_height, wall = Raw(wall_l(&w)), wall_physical = Raw(wallp_l(&wp)),
                collision = Raw(match collision { Some(c) => obj!(force_2528 = c.force_2528, point_2544 = c.point_2544, vector_2592 = c.vector_2592), None => "nil".into() }),
                edge = mock.edge, hung = mock.hung, deck_y = mock.deck_y, deck_z = mock.deck_z);
            let input = GroundBoardInput { steering: st_in, speed_wobble: wob_in, truck_flags_2468: f2468, truck_flags_2472: f2472, contact: cf, ground_vector_1216: gff.axis_544,
                propulsion, ground_force: gff, speed_model: smi, slide_friction: sfi, pump_force: pfi, straighten: sti, heading: hi, anti_flip: afi, manual: man, ground_drag: gdi,
                contact_time_2756: cf.scalar_2756.abs(), trajectory_state_1776_bits: traj, anti_flip_nudge: nudge, hang_up: hang, halfpipe_wheel_catch: catch, pinning: pin };
            let settings = GroundBoardSettings { steering: &steering, speed_wobble: &wobble, propulsion: prop, ground_force: &gforce, speed_model: &smodel, slide_friction: &slide, straighten: &straight,
                heading: &head, anti_flip: &aflip, manual: &manual, manual_mode: mmode, linear_drag: ldrag, collision_response_duration: crd, collision_response_scale: crs,
                ground_force_contact_time_limit: gfl, speed_model_reset_force_squared: smr };
            let mut queue = BoardForceQueue::default();
            let mut binding = BodyInertias { part_inertia_indices: &indices, inertias: &mut inertias };
            let components = GroundBoardComponents { speed_wobble: &mut wob, truck_steering: &mut truck, speed_model: &mut sm, manual: &mut mstate, heading_previous: &mut heading_prev,
                force_queue: &mut queue, inertias: &mut binding };
            let outcome = board::update(&mut state, components, settings, input, &mut mock).unwrap();
            let outcome_l = match outcome {
                GroundBoardOutcome::Animated => obj!(kind = "Animated"),
                GroundBoardOutcome::Collision { tag_15_queued } => obj!(kind = "Collision", tag_15_queued = tag_15_queued),
                GroundBoardOutcome::Ordinary(o) => obj!(kind = "Ordinary", result = Raw(obj!(manual_correction = o.manual_correction, terminal_force_tag = o.terminal_force_tag,
                    terminal_force_queued = o.terminal_force_queued, speed_model_reset = o.speed_model_reset))),
            };
            let out_l = obj!(outcome = Raw(outcome_l), state = Raw(state_l(&state)), queue = queue.entries().to_vec(), wobble = wob.0, truck = Raw(obj!(deck_tilt = truck.deck_tilt, targets = truck.targets,
                    activation_time = truck.activation_time)), speed_model = Raw(obj!(target_speed = sm.target_speed, flags_1360 = sm.flags_1360)), manual = Raw(mstate_l(&mstate)),
                heading_previous = heading_prev, drags = inertias.iter().map(|i| i.linear_drag).collect::<Vec<_>>(), events = mock.events.clone(), vectors = mock.vectors.clone());
            writeln!(ticks, "\t\t\t{{ input = {}, mock = {}, out = {} }},", input_l, mock_l, out_l).unwrap();
            let _ = (case, tick);
        }
        writeln!(s, "\t\t{{ settings = {}, init = {}, ticks = {{\n{}\t\t}} }},", settings_l, init, ticks).unwrap();
    }
    s.push_str("\t},\n\toutput = {\n");
    for _ in 0..500 {
        let mut st = PhysicsGroundState::before_first_enter(r.bool());
        st.flag_2721 = r.bool(); st.flag_2720 = r.bool(); st.anti_flip_nudge_applied_2723 = r.bool(); st.pinning_2727 = r.bool(); st.anti_flip_torque_2624 = r4(&mut r, 2.0);
        st.scalar_2664 = r.range(-1.0, 3.0); st.scalar_2668 = r.range(0.0, 2.0); st.word_2560 = r.next(); st.word_2564 = r.next(); st.flag_2731 = r.bool(); st.flag_2729 = r.bool();
        st.manual_correction_2732 = r.bool(); st.manual_opposition_2733 = r.bool(); st.push_suppressed_2730 = r.bool();
        let fr = GroundOutputFrame { axis_464: up4(&mut r), velocity_608: if r.next() % 6 == 0 { [1e-20, 1e-38, -1e-39, 0.0] } else { r4(&mut r, 6.0) }, absolute_body_speed_2616: r.range(0.0, 10.0),
            deck_speed_2652: r.range(0.0, 10.0), state_timer_2664: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, scalar_2720: r.range(-1.0, 1.0), flags_2476: flags(&mut r) | (if r.bool() { 0x0040_0000 } else { 0 }),
            flags_2484: flags(&mut r), selected_mode_flag_109: r.bool() };
        let se = GroundOutputSettings { pushable_speed_terms_4_8: [r.range(0.0, 5.0), r.range(0.0, 5.0)], mode_speed_threshold_0: r.range(0.0, 10.0) };
        let o = fill_physics_output(&st, fr, se);
        let vp = match o.velocity_projection_36 { Some(v) => obj!(velocity_without_axis_component = v.velocity_without_axis_component, active = v.active), None => "nil".into() };
        writeln!(s, "\t\t{{ state = {}, frame = {}, settings = {}, out = {} }},", state_l(&st),
            obj!(axis_464 = fr.axis_464, velocity_608 = fr.velocity_608, absolute_body_speed_2616 = fr.absolute_body_speed_2616, deck_speed_2652 = fr.deck_speed_2652, state_timer_2664 = fr.state_timer_2664,
                scalar_2720 = fr.scalar_2720, flags_2476 = fr.flags_2476, flags_2484 = fr.flags_2484, selected_mode_flag_109 = fr.selected_mode_flag_109),
            obj!(pushable_speed_terms_4_8 = se.pushable_speed_terms_4_8, mode_speed_threshold_0 = se.mode_speed_threshold_0),
            obj!(skateboard_motion_4 = Raw(obj!(is_push_accelerating = o.skateboard_motion_4.is_push_accelerating, is_at_pushable_speed = o.skateboard_motion_4.is_at_pushable_speed)),
                velocity_projection_36 = Raw(vp),
                ground_32 = Raw(obj!(wall_ride_exit = o.ground_32.wall_ride_exit, anti_flip_nudge_present = o.ground_32.anti_flip_nudge_present, is_pinning = o.ground_32.is_pinning,
                    anti_flip_torque = o.ground_32.anti_flip_torque, time_to_skitch = o.ground_32.time_to_skitch, skitch_spline_height = o.ground_32.skitch_spline_height,
                    processed_scalar_2720 = o.ground_32.processed_scalar_2720, processed_flag_2484_bit_13 = o.ground_32.processed_flag_2484_bit_13)),
                state_28 = Raw(obj!(grab_spline_type = o.state_28.grab_spline_type, grab_spline_object_id = o.state_28.grab_spline_object_id, flag_84 = o.state_28.flag_84,
                    has_world_grab_intent_without_object = o.state_28.has_world_grab_intent_without_object, manual_correction_write_78 = o.state_28.manual_correction_write_78)),
                intents_52 = Raw(obj!(has_world_grab_intent = o.intents_52.has_world_grab_intent, selected_mode_below_speed_threshold_58 = o.intents_52.selected_mode_below_speed_threshold_58)),
                is_grabbing_object_72_304 = o.is_grabbing_object_72_304, manual_opposition_56_168 = o.manual_opposition_56_168, push_suppressed_20_596 = o.push_suppressed_20_596)).unwrap();
    }
    s.push_str("\t},\n\tmotion = {\n");
    for _ in 0..800 {
        let n = up4(&mut r); let a = r4(&mut r, 3.0); let vel = r.vec(6.0); let fw = u4(&mut r);
        let pv = r4(&mut r, 6.0); let av = r4(&mut r, 6.0); let mass = r.range(1.0, 80.0); let strength = r.range(0.0, 1.0); let py = r.range(-0.1, 0.1);
        let mut q = BoardForceQueue::default();
        for _ in 0..(r.next() % 6) { q.append(QueuedPointForce { tag: r.next() % 20, force_world: r.vec(60.0), point_body: r.vec(0.3) }); }
        let dt = 1.0 / 60.0; let pushing = r.next() % 5 == 0; let mc = r.next() % 6 == 0;
        writeln!(s, "\t\t{{ input = {}, out = {} }},",
            obj!(normal = n, angular = a, velocity = vel, forward = fw, physical = pv, animation = av, mass = mass, strength = strength, point_y = py, forces = q.entries().to_vec(), dt = dt, pushing = pushing, manual_correction = mc),
            obj!(entry_angular_velocity = motion::entry_angular_velocity(n, a), entry_target_speed = motion::entry_target_speed(vel, n, fw),
                landing = motion::landing_on_deck_force(pv, av, n, mass, strength, py), future = motion::future_deck_displacement(&q, mass, dt, n, pushing, mc))).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/grounded.luau"), s).unwrap();
}
