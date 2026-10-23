//! Эталон для player::wipeout (check_air, check_air_collision, check_ground,
//! check_ground_animation, check_plant, Requests) и physics::grind_forces::post.
//! Синтетика — файл можно коммитить.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::physics::grind_forces::post;
use skate_core::player::wipeout::{
    check_air, check_air_collision, check_ground, check_ground_animation, check_plant, AirSettings, Frame, GroundSettings, Mode, RequestInput,
    Requests, Settings,
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
fn tf(r: &mut Rng) -> [V; 4] {
    let up = unit(r);
    let f = { let a = unit(r); let c = [up[1] * a[2] - up[2] * a[1], up[2] * a[0] - up[0] * a[2], up[0] * a[1] - up[1] * a[0]]; let l = (c[0] * c[0] + c[1] * c[1] + c[2] * c[2]).sqrt().max(1e-3); [c[0] / l, c[1] / l, c[2] / l, 0.0] };
    let ri = [up[1] * f[2] - up[2] * f[1], up[2] * f[0] - up[0] * f[2], up[0] * f[1] - up[1] * f[0], 0.0];
    [ri, up, f, v4(r, 3.0)]
}
fn flags(r: &mut Rng) -> u32 { let mut x = 0; for _ in 0..4 { x |= 1 << (r.next() % 32); } x }
fn frame(r: &mut Rng) -> Frame {
    let deck = tf(r);
    let input_board = if r.bool() { deck } else { tf(r) };
    Frame { flags_2468: flags(r), flags_2472: flags(r), flags_2476: flags(r), flags_2480: flags(r), flags_2484: flags(r), category: [100u32, 200, 400, 600][(r.next() % 4) as usize],
        timestep: r.range(0.005, 0.05), time_on_ground: r.range(0.0, 1.0), speed: r.range(0.0, 10.0), animation_up: unit(r), landing_angle: r.range(-1.5, 1.5),
        deck_velocity: v4(r, 10.0), com_velocity: v4(r, 10.0), jump_fix_frames: (r.next() % 30) as i32 - 5, deck, input_board, world_to_animation: tf(r),
        closing_velocity: v4(r, 15.0), board_material_flags: flags(r), board_contact: r.bool(), wheel_contact: r.bool(), board_contact_normal: unit(r),
        opposing_contact: r.range(0.0, 3.0), regions_force: std::array::from_fn(|_| r.range(0.0, 150.0)), maximum_skater_force: if r.bool() { 0.0 } else { r.range(0.0, 10.0) },
        vehicle_force: r.range(0.0, 150.0), group_8: r.bool(), conflicting: r.next() % 5 == 0, compliant: r.bool(), highest_normal: unit(r), pose_error: v4(r, 1.0),
        maximum_pose_error: r.range(0.0, 1.0), flip_active: r.bool(), flip_requested_speed: if r.bool() { 0.0 } else { r.range(-5.0, 5.0) }, system_up_y: r.range(-1.0, 1.0),
        grind_selected: r.next() % 3 == 0, grind_normal_valid: r.bool(), grind_normal: unit(r) }
}
fn frame_l(f: &Frame) -> Raw {
    Raw(obj!(flags_2468 = f.flags_2468, flags_2472 = f.flags_2472, flags_2476 = f.flags_2476, flags_2480 = f.flags_2480, flags_2484 = f.flags_2484, category = f.category,
        timestep = f.timestep, time_on_ground = f.time_on_ground, speed = f.speed, animation_up = f.animation_up, landing_angle = f.landing_angle, deck_velocity = f.deck_velocity,
        com_velocity = f.com_velocity, jump_fix_frames = f.jump_fix_frames, deck = f.deck, input_board = f.input_board, world_to_animation = f.world_to_animation,
        closing_velocity = f.closing_velocity, board_material_flags = f.board_material_flags, board_contact = f.board_contact, wheel_contact = f.wheel_contact,
        board_contact_normal = f.board_contact_normal, opposing_contact = f.opposing_contact, regions_force = f.regions_force, maximum_skater_force = f.maximum_skater_force,
        vehicle_force = f.vehicle_force, group_8 = f.group_8, conflicting = f.conflicting, compliant = f.compliant, highest_normal = f.highest_normal, pose_error = f.pose_error,
        maximum_pose_error = f.maximum_pose_error, flip_active = f.flip_active, flip_requested_speed = f.flip_requested_speed, system_up_y = f.system_up_y,
        grind_selected = f.grind_selected, grind_normal_valid = f.grind_normal_valid, grind_normal = f.grind_normal))
}
fn settings(r: &mut Rng) -> Settings {
    Settings {
        ground: GroundSettings { vehicle_scalar: r.range(0.5, 2.0), vehicle_contact: r.range(20.0, 120.0), skitch_contact: r.range(20.0, 120.0), skitch_scalar: r.range(0.5, 2.0),
            skitch_arms_scalar: r.range(0.5, 2.0), skater_scalar: r.range(0.5, 2.0), max_squash: r.range(0.1, 1.0), max_squash_coffin: r.range(0.1, 1.0),
            max_displacement: r.range(0.2, 1.5), max_contact: r.range(50.0, 140.0), max_arm_contact: r.range(50.0, 140.0), max_deck_error: r.range(0.1, 1.5),
            opposing_contact: r.range(0.5, 2.5), y_acceleration: r.range(2.0, 15.0), light_dmo_scalar: r.range(0.5, 2.0), player_scalar: r.range(0.5, 2.0), ai_scalar: r.range(0.5, 2.0),
            skitch_acc_scalar: r.range(0.5, 2.0), balance_total: r.range(0.0, 3.0), balance_min_speed: r.range(0.5, 5.0), balance_base: r.range(-0.5, 0.5) },
        air: AirSettings { xz_trick: r.range(1.0, 15.0), y_trick: r.range(1.0, 15.0), xz_acceleration: r.range(2.0, 15.0), y_acceleration: r.range(2.0, 15.0),
            max_squash: r.range(0.1, 1.0), max_displacement: r.range(0.2, 1.5), max_contact: r.range(50.0, 140.0), max_arm_contact: r.range(50.0, 140.0),
            body_flip_scalar: r.range(0.5, 2.0), body_flip_acc_scalar: r.range(0.5, 2.0), light_dmo_scalar: r.range(0.5, 2.0), ignore_danger_frames: (r.next() % 20) as i32,
            max_landing_speed: r.range(2.0, 10.0), max_stairs_speed: r.range(2.0, 10.0), max_grind_speed: r.range(2.0, 10.0),
            max_landing_angle: PointGraph { x: [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0], y: std::array::from_fn(|_| r.range(0.1, 1.5)) } },
        lean_contact_y: r.range(-1.0, 0.5),
    }
}
fn settings_l(s: &Settings) -> Raw {
    let g = &s.ground;
    let a = &s.air;
    Raw(obj!(ground = Raw(obj!(vehicle_scalar = g.vehicle_scalar, vehicle_contact = g.vehicle_contact, skitch_contact = g.skitch_contact, skitch_scalar = g.skitch_scalar,
        skitch_arms_scalar = g.skitch_arms_scalar, skater_scalar = g.skater_scalar, max_squash = g.max_squash, max_squash_coffin = g.max_squash_coffin,
        max_displacement = g.max_displacement, max_contact = g.max_contact, max_arm_contact = g.max_arm_contact, max_deck_error = g.max_deck_error,
        opposing_contact = g.opposing_contact, y_acceleration = g.y_acceleration, light_dmo_scalar = g.light_dmo_scalar, player_scalar = g.player_scalar, ai_scalar = g.ai_scalar,
        skitch_acc_scalar = g.skitch_acc_scalar, balance_total = g.balance_total, balance_min_speed = g.balance_min_speed, balance_base = g.balance_base)),
        air = Raw(obj!(xz_trick = a.xz_trick, y_trick = a.y_trick, xz_acceleration = a.xz_acceleration, y_acceleration = a.y_acceleration, max_squash = a.max_squash,
            max_displacement = a.max_displacement, max_contact = a.max_contact, max_arm_contact = a.max_arm_contact, body_flip_scalar = a.body_flip_scalar,
            body_flip_acc_scalar = a.body_flip_acc_scalar, light_dmo_scalar = a.light_dmo_scalar, ignore_danger_frames = a.ignore_danger_frames,
            max_landing_speed = a.max_landing_speed, max_stairs_speed = a.max_stairs_speed, max_grind_speed = a.max_grind_speed, max_landing_angle = a.max_landing_angle)),
        lean_contact_y = s.lean_contact_y))
}
fn requests_l(q: &Requests) -> Raw {
    Raw(obj!(reasons = q.reasons, values = q.values, count = q.count, cooldown = q.cooldown, contact_frames = q.contact_frames, balance = q.balance, mode = q.mode))
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x0b1a_ce55);
    let mut s = format!("-- Сгенерировано golden/src/wipeout.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");
    for _ in 0..80 {
        let st = settings(&mut r);
        let ps = post::Settings { max_arm_contact_164: r.range(50.0, 140.0), max_body_contact_168: r.range(50.0, 140.0), xz_acceleration_204: r.range(2.0, 15.0),
            max_displacement_208: r.range(0.2, 1.5), max_angular_deck_error_212: r.range(0.1, 1.5) };
        let mut q = Requests::new();
        let init = r.next() % 4;
        match init { 1 => q.initialize_player(), 2 => q.teleport(), _ => {} }
        let mut steps = Vec::new();
        for _ in 0..12 {
            let f = frame(&mut r);
            let mode = Mode { check_squash: r.bool(), check_bad_landing: r.bool(), ground_xz: r.range(2.0, 15.0), bad_landing_scale: r.range(0.5, 2.0) };
            let action = r.next() % 9;
            let (use_com, scale, sub) = (r.bool(), r.range(0.5, 2.0), r.bool());
            match action {
                0 | 1 => check_air(&mut q, &st, &mode, &f, use_com),
                2 => check_air_collision(&mut q, &st, &mode, &f),
                3 | 4 => check_ground(&mut q, &st, &mode, &f),
                5 => check_ground_animation(&mut q, &st, &mode, &f, scale),
                6 => check_plant(&mut q, &st, &f),
                7 => post::check(&mut q, ps, &f),
                _ => { if sub { q.clear_after_selection() } else { q.reset_systems() } }
            }
            let ri = RequestInput { flags_2468: f.flags_2468, flags_2476: f.flags_2476, flags_2480: f.flags_2480, flags_2484: f.flags_2484, animation_up_y: f.animation_up[1], category: f.category };
            let clear = r.next() % 3 == 0;
            steps.push(obj!(action = action, frame = frame_l(&f), mode = Raw(obj!(check_squash = mode.check_squash, check_bad_landing = mode.check_bad_landing,
                ground_xz = mode.ground_xz, bad_landing_scale = mode.bad_landing_scale)), use_com = use_com, scale = scale, sub = sub, requests = requests_l(&q),
                runout = q.requests_runout(&ri), wipeout = q.requests_wipeout(&ri), clear = clear));
            if clear { q.clear_after_selection(); }
        }
        writeln!(s, "\t{{ settings = {}, post = {}, init = {}, steps = {{ {} }} }},", settings_l(&st).0,
            obj!(max_arm_contact_164 = ps.max_arm_contact_164, max_body_contact_168 = ps.max_body_contact_168, xz_acceleration_204 = ps.xz_acceleration_204,
                max_displacement_208 = ps.max_displacement_208, max_angular_deck_error_212 = ps.max_angular_deck_error_212), init, steps.join(",\n\t\t")).unwrap();
    }
    s.push_str("}\n");
    std::fs::write(format!("{out_dir}/wipeout.luau"), s).unwrap();
}
