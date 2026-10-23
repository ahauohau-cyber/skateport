//! Эталон для riding: steering, heading, braking, ground_force, anti_flip,
//! straighten, slide_friction, speed_wobble, speed_model.
use crate::collision::{b, v, Rng};
use crate::riding::{graph, gs};
use skate_core::math::Vector3;
use skate_core::point_graph::PointGraph;
use skate_core::riding::anti_flip::{self, AntiFlipInput, AntiFlipSettings};
use skate_core::riding::braking::{calculate_braking, calculate_linear_drag, BrakeInput, BrakeSettings, LinearDragInput, LinearDragSettings};
use skate_core::riding::ground_force::{self, GroundForceInput, GroundForceSettings};
use skate_core::riding::heading::{self, HeadingInput, HeadingSettings};
use skate_core::riding::slide_friction::{self, SlideFrictionInput, SlideFrictionSettings};
use skate_core::riding::speed_model::{self, SpeedModelInput, SpeedModelSettings, SpeedModelState};
use skate_core::riding::speed_wobble::{self, SpeedWobbleInput, SpeedWobbleSettings, SpeedWobbleState};
use skate_core::riding::steering::{calculate_tilt, SteeringInput, SteeringSettings, TruckSteeringState};
use skate_core::riding::straighten::{self, StraightenInput, StraightenSettings};
use std::fmt::Write as _;

pub fn graph16(r: &mut Rng) -> PointGraph<16> {
    let mut x = [0f32; 16]; let mut acc = r.range(-0.5, 0.0);
    for k in 0..16 { x[k] = acc; acc += r.range(0.01, 0.2); }
    PointGraph { x, y: core::array::from_fn(|_| r.range(-3.0, 3.0)) }
}
pub fn gs16(g: &PointGraph<16>) -> String { format!("{{ {{ {} }}, {{ {} }} }}", g.x.map(b).join(", "), g.y.map(b).join(", ")) }
pub fn f4(x: [f32; 4]) -> String { format!("{{ {}, {}, {}, {} }}", b(x[0]), b(x[1]), b(x[2]), b(x[3])) }
fn f8(x: [f32; 8]) -> String { format!("{{ {} }}", x.map(b).join(", ")) }
pub fn r4(r: &mut Rng, s: f32) -> [f32; 4] { [r.range(-s, s), r.range(-s, s), r.range(-s, s), r.range(-s * 0.1, s * 0.1)] }
pub fn u4(r: &mut Rng) -> [f32; 4] { let a = r.vec(1.0); let l = (a.x*a.x+a.y*a.y+a.z*a.z).sqrt().max(1e-3); [a.x/l, a.y/l, a.z/l, 0.0] }
pub fn up4(r: &mut Rng) -> [f32; 4] { match r.next() % 3 { 0 => [0.0, 1.0, 0.0, 0.0], 1 => u4(r), _ => { let a = [r.range(-0.4,0.4), 1.0, r.range(-0.4,0.4)]; let l=(a[0]*a[0]+a[1]*a[1]+a[2]*a[2]).sqrt(); [a[0]/l,a[1]/l,a[2]/l,0.0] } } }
pub fn thr(r: &mut Rng) -> [f32; 4] { if r.bool() { [f32::from_bits(0x3586_37BD); 4] } else { core::array::from_fn(|_| r.range(0.0, 0.1)) } }
pub fn flags(r: &mut Rng) -> u32 { let mut f = 0u32; for _ in 0..(r.next() % 4) { f |= 1 << (r.next() % 32); } f }
fn rot(r: &mut Rng) -> [[f32; 4]; 4] { let x = up4(r); let y = u4(r); let z = u4(r); [x, y, z, r4(r, 5.0)] }

pub fn write(out_dir: &str) {
    let mut r = Rng(0x57ee_7111);
    let mut s = String::from("-- Сгенерировано golden/src/riding2.rs из настоящего skate-core. Не править.\nreturn {\n\tsteering = {\n");
    for _ in 0..200 {
        let st = SteeringSettings { hard_turn_increase: r.range(0.0, 2.0), damping: r.range(0.0, 1.0), speed_graph_max_speed: r.range(0.5, 10.0), push_scalar_increment: r.range(0.0, 0.2),
            push_scalar_decrement: r.range(0.0, 0.2), push_scalar_min: r.range(0.0, 0.8), manual_scalar: r.range(0.0, 2.0), general_scalar: r.range(0.0, 2.0), tight_trucks_scalar: r.range(0.0, 2.0),
            speed_graph: graph(&mut r), input_graph: graph(&mut r), tilt_blending: r.range(0.0, 1.0) };
        let push0 = r.range(0.0, 1.0); let damped0 = r.range(-1.0, 1.0); let mut push = push0; let mut damped = damped0;
        let mut truck = TruckSteeringState::default();
        let mut steps = String::new();
        for _ in 0..30 {
            let inp = SteeringInput { turn: r.range(-1.2, 1.2), hard_turn: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, absolute_body_speed: r.range(0.0, 12.0),
                flipped_controls_scalar: if r.bool() { 1.0 } else { -1.0 }, balance: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, truck_tightness: r.range(0.0, 1.0), pushing: r.bool() };
            let mode = r.next() % 4;
            let tilt = match mode { 0 => calculate_tilt(&st, inp, Some(&mut push), Some(&mut damped)), 1 => calculate_tilt(&st, inp, None, Some(&mut damped)), 2 => calculate_tilt(&st, inp, Some(&mut push), None), _ => calculate_tilt(&st, inp, None, None) };
            let f2468 = if r.bool() { 1 << 20 } else { 0 }; let f2472 = flags(&mut r) | if r.bool() { 1 << 27 } else { 0 } | if r.bool() { 1 << 26 } else { 0 };
            let blend = st.tilt_blending;
            truck.update(tilt, blend, f2468, f2472);
            write!(steps, "{{ {{ {}, {}, {}, {}, {}, {}, {} }}, {}, {}, {}, {}, {}, {}, {{ {}, {}, {}, {}, {} }} }}, ", b(inp.turn), b(inp.hard_turn), b(inp.absolute_body_speed), b(inp.flipped_controls_scalar), b(inp.balance), b(inp.truck_tightness), inp.pushing,
                mode, b(tilt), b(push), b(damped), f2468, f2472, b(truck.deck_tilt), b(truck.targets[0]), b(truck.targets[1]), b(truck.activation_time[0]), b(truck.activation_time[1])).unwrap();
        }
        writeln!(s, "\t\t{{ settings = {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}, init = {{ {}, {} }}, steps = {{ {} }} }},",
            b(st.hard_turn_increase), b(st.damping), b(st.speed_graph_max_speed), b(st.push_scalar_increment), b(st.push_scalar_decrement), b(st.push_scalar_min), b(st.manual_scalar), b(st.general_scalar), b(st.tight_trucks_scalar),
            gs(&st.speed_graph), gs(&st.input_graph), b(st.tilt_blending), b(push0), b(damped0), steps).unwrap();
    }
    s.push_str("\t},\n\theading = {\n");
    for _ in 0..600 {
        let st = HeadingSettings { manual_wrong_wheel_scalar: r.range(0.0, 2.0), manual_damping: r.range(0.0, 1.0), speed_max: r.range(0.5, 12.0), heading_strength: r.range(0.0, 5.0), turn_strength: r.range(0.0, 5.0),
            angular_response: graph(&mut r), manual_response: graph(&mut r), inclination_response: graph(&mut r), speed_response: graph(&mut r), normal_threshold: thr(&mut r) };
        let inp = HeadingInput { balance: if r.next() % 3 == 0 { r.range(-1.0, 1.0) } else { 0.0 }, manual_turn: if r.bool() { r.range(-1.0, 1.0) } else { 0.0 }, flags_2472: flags(&mut r) | (r.next() & 0x0c00_0000),
            timestep: 1.0 / 60.0, signed_speed: r.range(-12.0, 12.0), manual_curve_input: r.range(0.0, 1.5), turn_2712: r.range(-1.0, 1.0), scalar_2740: r.range(0.0, 2.0),
            velocity: r4(&mut r, 8.0), normal: up4(&mut r), angular_velocity: r4(&mut r, 3.0), transform: rot(&mut r) };
        let prev0 = r.range(-0.5, 0.5); let mut prev = prev0;
        let out = heading::calculate(&st, &inp, &mut prev);
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}, {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {{ {}, {}, {}, {} }} }}, {}, {}, {} }},",
            b(st.manual_wrong_wheel_scalar), b(st.manual_damping), b(st.speed_max), b(st.heading_strength), b(st.turn_strength), gs(&st.angular_response), gs(&st.manual_response), gs(&st.inclination_response), gs(&st.speed_response), f4(st.normal_threshold),
            b(inp.balance), b(inp.manual_turn), inp.flags_2472, b(inp.timestep), b(inp.signed_speed), b(inp.manual_curve_input), b(inp.turn_2712), b(inp.scalar_2740), f4(inp.velocity), f4(inp.normal), f4(inp.angular_velocity),
            f4(inp.transform[0]), f4(inp.transform[1]), f4(inp.transform[2]), f4(inp.transform[3]), b(prev0), f4(out), b(prev)).unwrap();
    }
    s.push_str("\t},\n\tbraking = {\n");
    for _ in 0..800 {
        let st = BrakeSettings { input_force: r.range(0.0, 50.0), override_force: r.range(0.0, 50.0), minimum_speed: r.range(0.0, 2.0) };
        let inp = BrakeInput { flags_2468: flags(&mut r) | (r.next() & 0x6000_0000), input_2728: r.range(0.0, 1.0), signed_speed: r.range(-10.0, 10.0), absolute_body_speed: r.range(0.0, 10.0), surface_factor: r.range(0.0, 2.0), direction: r.vec(1.0) };
        let out = calculate_braking(inp, st);
        let ds = LinearDragSettings { brake_speed: r.range(0.0, 2.0), balance_speed: r.range(0.0, 5.0), comparison_threshold: r.range(0.0, 1.0), balance_drag: r.range(0.0, 3.0) };
        let di = LinearDragInput { flags_2468: inp.flags_2468, absolute_body_speed: inp.absolute_body_speed, balance_2720: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, scalar_2724: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, comparison_scalar: r.range(0.0, 1.0) };
        let drag = calculate_linear_drag(di, ds);
        writeln!(s, "\t\t{{ {{ {}, {}, {} }}, {{ {}, {}, {}, {}, {}, {} }}, {}, {{ {}, {}, {}, {} }}, {{ {}, {}, {} }}, {} }},", b(st.input_force), b(st.override_force), b(st.minimum_speed),
            inp.flags_2468, b(inp.input_2728), b(inp.signed_speed), b(inp.absolute_body_speed), b(inp.surface_factor), v(inp.direction), v(out.force_world),
            b(ds.brake_speed), b(ds.balance_speed), b(ds.comparison_threshold), b(ds.balance_drag), b(di.balance_2720), b(di.scalar_2724), b(di.comparison_scalar), b(drag)).unwrap();
    }
    s.push_str("\t},\n\tground_force = {\n");
    for _ in 0..800 {
        let st = GroundForceSettings { range_1220: r.range(0.1, 5.0), speed_scale_1224: r.range(0.0, 3.0), scale_1228: r.range(0.0, 3.0), normal_threshold: thr(&mut r) };
        let inp = GroundForceInput { argument_1: if r.next() % 4 == 0 { 0.0 } else { r.range(0.0, 6.0) }, application_z: r.range(-0.5, 0.5), argument_3: r.range(-3.0, 3.0), argument_4: r.range(-3.0, 3.0),
            balance: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, surface_speed: r.range(0.0, 12.0), axis_384: u4(&mut r), velocity_400: if r.next() % 8 == 0 { [0.0; 4] } else { r4(&mut r, 8.0) }, axis_544: up4(&mut r) };
        let out = ground_force::calculate(&st, &inp);
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {} }}, {{ {}, {}, {}, {}, {}, {}, {}, {}, {} }}, {} }},", b(st.range_1220), b(st.speed_scale_1224), b(st.scale_1228), f4(st.normal_threshold),
            b(inp.argument_1), b(inp.application_z), b(inp.argument_3), b(inp.argument_4), b(inp.balance), b(inp.surface_speed), f4(inp.axis_384), f4(inp.velocity_400), f4(inp.axis_544), f8(out)).unwrap();
    }
    s.push_str("\t},\n\tanti_flip = {\n");
    for _ in 0..800 {
        let st = AntiFlipSettings { axis_96_response: graph(&mut r), axis_64_response: graph(&mut r), normal_threshold: thr(&mut r) };
        let inp = AntiFlipInput { flags_2468: flags(&mut r) | (if r.next() % 6 == 0 { 0x2000_0000 } else { 0 }), balance: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, axis_96: u4(&mut r), axis_64: up4(&mut r), projection_axis_544: up4(&mut r) };
        let out = anti_flip::calculate(&st, &inp);
        writeln!(s, "\t\t{{ {{ {}, {}, {} }}, {{ {}, {}, {}, {}, {} }}, {} }},", gs(&st.axis_96_response), gs(&st.axis_64_response), f4(st.normal_threshold),
            inp.flags_2468, b(inp.balance), f4(inp.axis_96), f4(inp.axis_64), f4(inp.projection_axis_544), f4(out)).unwrap();
    }
    s.push_str("\t},\n\tstraighten = {\n");
    for _ in 0..800 {
        let st = StraightenSettings { time_response: graph16(&mut r), opposite_turn_limit: r.range(0.1, 1.0), time_scalar: r.range(0.0, 1.0), heading_time_limit: r.range(0.1, 2.0), strength: r.range(0.0, 5.0) };
        let inp = StraightenInput { heading_time: r.range(-0.2, 3.0), scalar_2764: r.range(0.0, 1.0), turn: r.range(-1.0, 1.0), forward: u4(&mut r), velocity: r4(&mut r, 8.0), normal: up4(&mut r) };
        let out = straighten::calculate(&st, &inp);
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {}, {} }}, {{ {}, {}, {}, {}, {}, {} }}, {} }},", gs16(&st.time_response), b(st.opposite_turn_limit), b(st.time_scalar), b(st.heading_time_limit), b(st.strength),
            b(inp.heading_time), b(inp.scalar_2764), b(inp.turn), f4(inp.forward), f4(inp.velocity), f4(inp.normal), f4(out)).unwrap();
    }
    s.push_str("\t},\n\tslide = {\n");
    for _ in 0..800 {
        let st = SlideFrictionSettings { angle_response: graph16(&mut r), speed_response: graph(&mut r), time_response: graph16(&mut r), scalar_516: r.range(0.0, 1.0), heading_time_limit: r.range(0.1, 2.0), friction: r.range(0.0, 5.0) };
        let inp = SlideFrictionInput { heading_time: r.range(-0.2, 3.0), normal: up4(&mut r), velocity: r4(&mut r, 8.0), side_axis: u4(&mut r), surface_speed: r.range(0.0, 12.0), scalar_2764: r.range(0.0, 1.0) };
        let out = slide_friction::calculate(&st, &inp);
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {}, {}, {} }}, {{ {}, {}, {}, {}, {}, {} }}, {} }},", gs16(&st.angle_response), gs(&st.speed_response), gs16(&st.time_response), b(st.scalar_516), b(st.heading_time_limit), b(st.friction),
            b(inp.heading_time), f4(inp.normal), f4(inp.velocity), f4(inp.side_axis), b(inp.surface_speed), b(inp.scalar_2764), f8(out)).unwrap();
    }
    s.push_str("\t},\n\twobble = {\n");
    for _ in 0..100 {
        let st = SpeedWobbleSettings { frequency_time: graph(&mut r), frequency_speed: graph(&mut r), amplitude_time: graph(&mut r), amplitude_speed: graph(&mut r), tightness_threshold: r.range(0.0, 3.0),
            time_range: r.range(0.2, 3.0), speed_range: r.range(0.5, 5.0), frequency_scale: r.range(0.0, 20.0), amplitude_scale: r.range(0.0, 0.5), crouch_threshold: r.range(0.0, 3.0), height_min: r.range(0.2, 0.6), height_max: r.range(0.7, 1.2) };
        let init: [u32; 8] = core::array::from_fn(|i| if i == 7 { r.next() & 0x00ff_ffff } else if i == 1 { r.next() } else { 0 });
        let mut state = SpeedWobbleState(init);
        let mut steps = String::new();
        for _ in 0..40 {
            let inp = SpeedWobbleInput { tilt: r.range(-0.3, 0.3), speed: r.range(0.0, 12.0), center_of_mass_height: r.range(0.2, 1.2), truck_tightness: r.range(0.0, 1.0), activation_threshold: r.range(0.0, 6.0), amplitude_multiplier: r.range(0.0, 2.0) };
            let out = speed_wobble::calculate(&mut state, &st, inp);
            write!(steps, "{{ {{ {}, {}, {}, {}, {}, {} }}, {}, {{ {} }} }}, ", b(inp.tilt), b(inp.speed), b(inp.center_of_mass_height), b(inp.truck_tightness), b(inp.activation_threshold), b(inp.amplitude_multiplier), b(out),
                state.0.map(|w| format!("0x{w:08x}")).join(", ")).unwrap();
        }
        writeln!(s, "\t\t{{ settings = {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}, init = {{ {} }}, steps = {{ {} }} }},",
            gs(&st.frequency_time), gs(&st.frequency_speed), gs(&st.amplitude_time), gs(&st.amplitude_speed), b(st.tightness_threshold), b(st.time_range), b(st.speed_range), b(st.frequency_scale), b(st.amplitude_scale),
            b(st.crouch_threshold), b(st.height_min), b(st.height_max), init.map(|w| format!("0x{w:08x}")).join(", "), steps).unwrap();
    }
    s.push_str("\t},\n\tspeed_model = {\n");
    for _ in 0..100 {
        let st = SpeedModelSettings { negative_gain: r.range(0.0, 3.0), maximum_gravity_acceleration: r.range(0.0, 10.0), gravity: r.range(0.0, 15.0), positive_gain: r.range(0.0, 3.0), coffin_acceleration: r.range(0.0, 3.0),
            speed_error_bound: r.range(0.1, 3.0), surface_friction: graph(&mut r), manual_acceleration: r.range(0.0, 3.0), negative_manual_angle_limit: r.range(0.0, 1.0), manual_angle_limit: r.range(0.0, 1.0),
            no_input_delay: r.range(0.0, 3.0), no_input_friction: graph(&mut r), manual_friction: graph(&mut r), override_enabled: r.bool(), override_speed: r.range(0.0, 15.0),
            normal_threshold: thr(&mut r), override_direction_threshold: core::array::from_fn(|_| r.range(-1.0, 1.0)) };
        let mut state = SpeedModelState { target_speed: r.range(0.0, 8.0), flags_1360: if r.bool() { 0x8000_0000 } else { 0 } | (r.next() & 0xffff) };
        let init = state;
        let mut steps = String::new();
        for _ in 0..40 {
            if r.next() % 15 == 0 { state.flags_1360 |= 0x8000_0000; }
            let pre = state.flags_1360;
            let inp = SpeedModelInput { flags_2468: flags(&mut r) & !0x6201_0000 | (if r.next() % 6 == 0 { 0x0001_0000 } else { 0 }), flags_2476: flags(&mut r) | (if r.next() % 4 == 0 { 0x0040_0000 } else { 0 }) | (if r.next() % 5 == 0 { 0x4000_0000 } else { 0 }),
                wheel_contact_count: (r.next() % 5) as i32, frames_2580: (r.next() % 60) as i32, timestep: if r.bool() { 1.0 / 60.0 } else { r.range(0.005, 0.05) }, signed_speed: r.range(-12.0, 12.0),
                angle_2652: r.range(-1.0, 1.0), surface_speed: r.range(0.0, 12.0), turn_2672: r.range(-1.0, 1.0), balance: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, elapsed_without_input: r.range(0.0, 5.0),
                manual_state_276: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, vector_160: u4(&mut r), vector_352: u4(&mut r), velocity_416: r4(&mut r, 8.0), normal_464: up4(&mut r), effective_forward: u4(&mut r), mass: r.range(1.0, 90.0) };
            let out = speed_model::update(&mut state, &st, &inp);
            write!(steps, "{{ {}, {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}, {}, {{ {}, {} }} }}, ", pre,
                inp.flags_2468, inp.flags_2476, inp.wheel_contact_count, inp.frames_2580, b(inp.timestep), b(inp.signed_speed), b(inp.angle_2652), b(inp.surface_speed), b(inp.turn_2672), b(inp.balance), b(inp.elapsed_without_input),
                b(inp.manual_state_276), f4(inp.vector_160), f4(inp.vector_352), f4(inp.velocity_416), f4(inp.normal_464), f4(inp.effective_forward), b(inp.mass), f8(out), b(state.target_speed), state.flags_1360).unwrap();
        }
        writeln!(s, "\t\t{{ settings = {{ {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }}, init = {{ {}, {} }}, steps = {{ {} }} }},",
            b(st.negative_gain), b(st.maximum_gravity_acceleration), b(st.gravity), b(st.positive_gain), b(st.coffin_acceleration), b(st.speed_error_bound), gs(&st.surface_friction), b(st.manual_acceleration),
            b(st.negative_manual_angle_limit), b(st.manual_angle_limit), b(st.no_input_delay), gs(&st.no_input_friction), gs(&st.manual_friction), st.override_enabled, b(st.override_speed), f4(st.normal_threshold), f4(st.override_direction_threshold),
            b(init.target_speed), init.flags_1360, steps).unwrap();
    }
    s.push_str("\t},\n}\n");
    let _ = Vector3::ZERO;
    std::fs::write(format!("{out_dir}/riding2.luau"), s).unwrap();
}
