//! Эталон для animation/foot_ik и остальных physics/skeleton_* модулей:
//! board_frames, board_offset, air_frames, general, motion, biped_air, landing,
//! landing_on_board, skeleton_output. Геометрия IK и настройки — стоковые
//! (как в skate-game/physics/foot_ik.rs), позы синтетические.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::animation::foot_ik::{
    self as fik,
    drive::Geometry,
    post_contact::SettingsPost,
    post_physics,
    settings::Settings,
    state::{FootIkState, UpdateInput, LIMBS},
    status::{self, BlendSettings, LimbStatus, Mode},
    two_bone::{self, AngleLimits, SolveResult},
};
use skate_core::math::Vector3;
use skate_core::physics::{
    rigid_body::RetailSimulationStep,
    skeleton_air_frames::{self as air, AirDismountRevert},
    skeleton_animation_record::{physics_bone_frame, AnimationPartTransform, SkeletonAnimationRecord, IDENTITY},
    skeleton_biped_air,
    skeleton_board_frames::SkeletonBoardFrames,
    skeleton_board_offset::SkateboardOffset,
    skeleton_body::*,
    skeleton_general,
    skeleton_landing::{LandingAdjustment, LandingInput, LandingSettings},
    skeleton_landing_on_board as lob,
    skeleton_motion::SkeletonMotion,
    skeleton_output::{self as so, board as sob, correction, wobble},
    skeleton_root::SkeletonRootFrames,
};
use skate_core::point_graph::PointGraph;
use skate_data::{abin::Bank, collections::Collections, physics_skeleton::PhysicsSkeleton};
use std::fmt::Write as _;
use std::path::Path;

type T = AnimationPartTransform;

fn quat(r: &mut Rng) -> [f32; 4] {
    let a = r.vec(1.0);
    let w = r.range(-1.0, 1.0);
    let l = (a.x * a.x + a.y * a.y + a.z * a.z + w * w).sqrt();
    [a.x / l, a.y / l, a.z / l, w / l]
}
fn rigid(r: &mut Rng, span: f32) -> T { let t = r.vec(span); physics_bone_frame(quat(r), [t.x, t.y, t.z, 0.0]) }
fn noisy(r: &mut Rng, span: f32) -> T { let mut m = rigid(r, span); for c in 0..3 { for l in 0..3 { m[c][l] += r.range(-0.02, 0.02); } } m }
fn v4(r: &mut Rng, span: f32) -> [f32; 4] { let v = r.vec(span); [v.x, v.y, v.z, r.range(-span, span)] }
fn p4(r: &mut Rng, span: f32) -> [f32; 4] { let v = r.vec(span); [v.x, v.y, v.z, 0.0] }
fn graph<const N: usize>(r: &mut Rng, span: f32) -> PointGraph<N> {
    let mut x = [0.0f32; N];
    let mut acc = 0.0;
    for i in 0..N { x[i] = acc; acc += r.range(0.05, 0.4); }
    PointGraph { x, y: std::array::from_fn(|_| r.range(-span, span)) }
}
fn mode_s(m: Mode) -> &'static str { match m { Mode::Disabled => "Disabled", Mode::OnDeck => "OnDeck", Mode::External => "External", Mode::Local => "Local" } }
fn res_s(m: SolveResult) -> &'static str { match m { SolveResult::Solved => "Solved", SolveResult::Extended => "Extended", SolveResult::Invalid => "Invalid" } }
fn limb_l(l: &LimbStatus) -> Raw {
    Raw(obj!(mode = mode_s(l.mode), board_blend = l.board_blend, external_blend = l.external_blend, target_blend = l.target_blend, external_target_set = l.external_target_set,
        local_target_set = l.local_target_set, external_target_local_delta = l.external_target_local_delta, part_position = l.part_position))
}
fn fik_l(s: &FootIkState) -> Raw {
    Raw(obj!(limbs = s.limbs.iter().map(limb_l).collect::<Vec<_>>(),
        frames = s.frames.iter().map(|f| Raw(obj!(target = f.target, world = f.world, external_world = f.external_world, board = f.board, parent_world = f.parent_world, external_parent_world = f.external_parent_world, parent_board = f.parent_board, within_contact_bounds = f.within_contact_bounds))).collect::<Vec<_>>(),
        external_targets = s.external_targets.iter().map(|t| Raw(obj!(world_position = t.world_position, animation_position = t.animation_position, normal = t.normal, normal_set = t.normal_set, normal_blend = t.normal_blend))).collect::<Vec<_>>(),
        contacts = Raw(obj!(feet = s.contacts.feet.iter().map(|c| Raw(obj!(query_state = c.query_state, position = c.position, desired_offset = c.desired_offset, offset = c.offset))).collect::<Vec<_>>(), support_failed = s.contacts.support_failed, support_failed_this_update = s.contacts.support_failed_this_update)),
        feet_enabled = s.feet_enabled()))
}
fn root_l(f: &SkeletonRootFrames) -> Raw {
    Raw(obj!(board = f.board, inverse_board = f.inverse_board, previous_board_position = f.previous_board_position, predicted_board_position = f.predicted_board_position,
        supplied_prediction = f.supplied_prediction, animation_to_board = f.animation_to_board, animation_to_world = f.animation_to_world,
        world_to_animation = f.world_to_animation, heading_alignment = f.heading_alignment, initialize_heading = f.initialize_heading))
}
fn random_root(r: &mut Rng) -> SkeletonRootFrames {
    let mut f = SkeletonRootFrames::default();
    f.update(noisy(r, 10.0), v4(r, 5.0), 1.0 / 60.0, &rigid(r, 1.0), &noisy(r, 0.5));
    f.initialize_heading = r.bool();
    f
}
fn bf_l(b: &SkeletonBoardFrames) -> Raw {
    Raw(obj!(physical_board = b.physical_board, skate_root = b.skate_root, animation_target = b.animation_target, com_frame = b.com_frame, lifted_com_frame = b.lifted_com_frame,
        centre_of_mass = b.centre_of_mass, previous_centre_of_mass = b.previous_centre_of_mass, com_velocity = b.com_velocity, local_centre_of_mass = b.local_centre_of_mass,
        local_board_position = b.local_board_position, lift_height = b.lift_height))
}
fn off_l(o: &SkateboardOffset) -> Raw { Raw(obj!(transform = o.transform, orientation_frames = o.orientation_frames, height_frames = o.height_frames, orientation_refreshed = o.orientation_refreshed, height_refreshed = o.height_refreshed)) }
fn record_l(p: &SkeletonPhysicalRecord) -> Raw {
    Raw(obj!(pose = p.pose, positions = p.positions, velocities = p.velocities, velocity_changes = p.velocity_changes,
        centre_of_mass = p.centre_of_mass, centre_of_mass_velocity = p.centre_of_mass_velocity, timestep = p.timestep))
}

pub fn write(out_dir: &str, asset_root: &str) {
    let root = Path::new(asset_root);
    let data = Collections::load(root).unwrap();
    let bank = Bank::load(&root.join("private/stock/data/anim/OnBoard.abin")).unwrap();
    let hierarchy = bank.hierarchy().unwrap();
    let json: serde_json::Value = serde_json::from_slice(&std::fs::read(root.join("private/stock/physics-skeletons.json")).unwrap()).unwrap();
    let sha = json["source_sha256"].as_str().unwrap().to_string();
    let skeleton = PhysicsSkeleton::load(&root.join("private/stock/physics-skeletons.json"), &sha, "PHYS_TPOSE").unwrap();
    let mut r = Rng(0x5ce1_e702);
    let mut s = format!("-- Сгенерировано golden/src/skel2.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");

    // --- foot_ik math
    s.push_str("\tmath = {\n");
    for i in 0..300 {
        let a = noisy(&mut r, 2.0);
        let mut b = match i % 5 { 0 => a, 1 => { let mut b = a; b[3] = p4(&mut r, 1.0); b }, _ => noisy(&mut r, 2.0) };
        if i % 7 == 3 { b[0] = a[0].map(|v| -v); b[2] = a[2].map(|v| -v); }
        let w = [0.0, 1.0, -0.5, 1.5, r.unit(), r.unit(), r.unit()][(r.next() % 7) as usize];
        let (m, rem) = fik::interpolate_native(&a, &b, w);
        writeln!(s, "\t\t{},", obj!(a = a, b = b, w = w, m = m, rem = rem, aff = fik::interpolate_affine(&a, &b, w), inv = fik::inverse_affine(&a))).unwrap();
    }
    s.push_str("\t},\n\ttwo_bone = {\n");
    for _ in 0..400 {
        let root_p = p4(&mut r, 0.5);
        let up = r.range(0.1, 0.6);
        let lo = r.range(0.1, 0.6);
        let d1 = r.vec(1.0); let d2 = r.vec(1.0);
        let n1 = (d1.x * d1.x + d1.y * d1.y + d1.z * d1.z).sqrt().max(1e-3);
        let n2 = (d2.x * d2.x + d2.y * d2.y + d2.z * d2.z).sqrt().max(1e-3);
        let middle = [root_p[0] + d1.x / n1 * up, root_p[1] + d1.y / n1 * up, root_p[2] + d1.z / n1 * up, 0.0];
        let end = [middle[0] + d2.x / n2 * lo, middle[1] + d2.y / n2 * lo, middle[2] + d2.z / n2 * lo, 0.0];
        let reach = r.range(0.0, 1.4) * (up + lo);
        let dt = r.vec(1.0); let nt = (dt.x * dt.x + dt.y * dt.y + dt.z * dt.z).sqrt().max(1e-3);
        let target_in = [root_p[0] + dt.x / nt * reach, root_p[1] + dt.y / nt * reach, root_p[2] + dt.z / nt * reach, 0.0];
        let limits = AngleLimits { minimum_degrees: r.range(0.0, 30.0), maximum_degrees: [180.0, r.range(120.0, 179.0)][(r.next() % 2) as usize] };
        let ovr = r.bool();
        let budget = r.next() % 4;
        let mut target = target_in;
        let mut solved = [0.0f32; 4];
        let res = two_bone::solve(root_p, middle, end, &mut solved, &mut target, limits, ovr, budget);
        writeln!(s, "\t\t{},", obj!(root = root_p, middle = middle, end_ = end, target_in = target_in, min = limits.minimum_degrees, max = limits.maximum_degrees, ovr = ovr, budget = budget,
            res = res_s(res), solved = solved, target = target)).unwrap();
    }
    s.push_str("\t},\n");

    // --- status
    let blend_settings = BlendSettings {
        hand_inner_padding: data.words::<4>("physics_skeletonik", "default", "IKOnPadding").unwrap().map(f32::from_bits),
        hand_outer_padding: data.words::<4>("physics_skeletonik", "default", "IKOffPadding").unwrap().map(f32::from_bits),
        external_blend_step: data.float("physics_skeletonik", "default", "FeetIKMaxBlendDeltaOut").unwrap(),
        board_blend_step: data.float("physics_skeletonik", "default", "FeetIKMaxBlendDelta").unwrap(),
    };
    let half_width = data.float("physicsdeck", "default", "DeckWidth").unwrap() * 0.5;
    let half_length = data.float("physicsdeck", "default", "DeckMidLength").unwrap() * 0.5;
    let vector = |name| data.words::<4>("physics_skeletonik", "default", name).unwrap().map(f32::from_bits);
    let settings = Settings {
        angle_limits: AngleLimits { minimum_degrees: data.float("physics_animation", "default", "IKMinAngle").unwrap(), maximum_degrees: data.float("physics_animation", "default", "IKMaxAngle").unwrap() },
        blend: blend_settings,
        post_ik_padding: vector("PostIKPadding"), contact_bounds: vector("IKBoneOnDeckBBox"), foot_on_deck_padding: vector("FootOnDeckPadding"),
        wipeout_feet_offset: data.float("physics_skeletonik", "default", "WipeoutFeetOffset").unwrap(),
        deck_half_width: half_width, deck_half_length: half_length,
        deck_total_half_length: data.float("physicsdeck", "default", "DeckFrontEndSize").unwrap() + half_length,
        deck_front_angle_degrees: data.float("physicsdeck", "default", "DeckFrontEndAngle").unwrap(),
    };
    let post = SettingsPost { minimum_board_up: data.float("physics_animation", "default", "PostIKMinYAxisVal").unwrap(),
        wipeout_height: data.float("animation", "default", "FeetRelativeHeightWipeout").unwrap(), riding_height: data.float("animation", "default", "FeetRelativeHeightOnDeck").unwrap() };
    let bs = &settings.blend;
    writeln!(s, "\tsettings = {},\n\tpost = {},", obj!(
        angle_limits = Raw(obj!(minimum_degrees = settings.angle_limits.minimum_degrees, maximum_degrees = settings.angle_limits.maximum_degrees)),
        blend = Raw(obj!(hand_inner_padding = bs.hand_inner_padding, hand_outer_padding = bs.hand_outer_padding, external_blend_step = bs.external_blend_step, board_blend_step = bs.board_blend_step)),
        post_ik_padding = settings.post_ik_padding, contact_bounds = settings.contact_bounds, foot_on_deck_padding = settings.foot_on_deck_padding, wipeout_feet_offset = settings.wipeout_feet_offset,
        deck_half_width = settings.deck_half_width, deck_half_length = settings.deck_half_length, deck_total_half_length = settings.deck_total_half_length, deck_front_angle_degrees = settings.deck_front_angle_degrees),
        obj!(minimum_board_up = post.minimum_board_up, wipeout_height = post.wipeout_height, riding_height = post.riding_height)).unwrap();
    s.push_str("\tstatus = {\n");
    for _ in 0..40 {
        let mut limbs = [LimbStatus::default(); 4];
        let mut steps = Vec::new();
        for _ in 0..10 {
            for l in limbs.iter_mut() {
                l.external_target_set = r.next() % 3 == 0;
                l.local_target_set = r.next() % 3 == 0;
                l.target_blend = [0.0, 1.0, r.unit()][(r.next() % 3) as usize];
                l.part_position = v4(&mut r, 0.6);
            }
            let input = limbs.iter().map(limb_l).collect::<Vec<_>>();
            let feet = r.next() % 4 != 0;
            let f2472 = r.next() & 0x180;
            let f2480 = r.next() & 0x0800_0000;
            status::update_modes(&mut limbs, feet, f2472);
            let after_modes = limbs.iter().map(limb_l).collect::<Vec<_>>();
            status::update_blends(&mut limbs, half_width, settings.deck_total_half_length, f2480, &settings.blend);
            steps.push(obj!(input = input, feet = feet, f2472 = f2472, f2480 = f2480, modes = after_modes, out = limbs.iter().map(limb_l).collect::<Vec<_>>()));
        }
        writeln!(s, "\t\t{{ {} }},", steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n");

    // --- foot ik geometry (как FootIk::load)
    let lookup = |name: &str| hierarchy.bone_names.iter().position(|b| b.eq_ignore_ascii_case(name)).unwrap();
    let bone_indices: [usize; 24] = std::array::from_fn(|i| lookup(&skeleton.bones[i].name));
    let mut parents = [None; 24];
    for (part, &bone) in bone_indices.iter().enumerate() {
        let mut ancestor = hierarchy.parents[bone];
        while ancestor >= 0 {
            let index = ancestor as usize;
            if let Some(p) = bone_indices.iter().position(|&b| b == index) { parents[part] = Some(p); break; }
            ancestor = hierarchy.parents[index];
        }
    }
    let physics_frames: [T; 24] = std::array::from_fn(|i| { let b = &skeleton.bones[i]; physics_bone_frame(b.rotation(), std::array::from_fn(|k| f32::from_bits(b.words[16 + k]))) });
    let geometry = Geometry::new(parents, &physics_frames).unwrap();
    geometry.validate_limbs(&LIMBS).unwrap();
    writeln!(s, "\tgeometry = {},", obj!(parents = parents.map(|p| Raw(match p { Some(v) => v.to_string(), None => "false".into() })), physics_frames = physics_frames, inverse_part_frames = geometry.inverse_part_frames, bone_indices = bone_indices)).unwrap();

    // --- body (как skate-game/physics/skeleton_body.rs::load)
    let mut sizes = [Vector3::ZERO; 24];
    let mut bones = Vec::new();
    for (i, bone) in skeleton.bones.iter().enumerate() {
        let [x, y, z] = bone.size();
        sizes[i] = Vector3::new(x, y, z);
        let w = data.words::<6>("physics_skeleton_bones", "default", &format!("PART_{}", bone.name)).unwrap();
        bones.push(BoneSettings { mass_factor: f32::from_bits(w[0]), ragdoll_mass_factor: f32::from_bits(w[1]), has_collision: w[2] >> 24 != 0,
            use_root_drive: (w[2] >> 16) & 255 != 0, volume_type: w[3], volume_scalar: f32::from_bits(w[4]), num_parents: w[5] });
    }
    let bones: [BoneSettings; 24] = bones.try_into().unwrap();
    let value = |name| data.float("physics_skeleton", "default", name).unwrap();
    let body_settings = SkeletonBodySettings {
        density: value("MassOfSkeleton"), root_radius: value("SkateRootCapsuleRadius"), root_half_length: value("SkateRootCapsuleLength"),
        capsule_radius_scalar: data.float("physics_skeleton_bones", "default", "CapsuleRadiusScalar").unwrap(), capsule_length_scalar: value("CapsuleLengthScalar"),
        ragdoll_inverse_mass_factor: data.float("physics_wipeout", "default", "RagdollInvMassFactor").unwrap(),
        inertia_multiply_type: data.integer("animation", "default", "InertiaMultiplyType").unwrap(), inertia_factor: data.float("animation", "default", "InertiaMultFactor").unwrap(),
    };
    let simulation = RetailSimulationStep::fixed_60_hz(30, 0.0005, Vector3::new(0.0, -9.81, 0.0));
    let authored: [T; 24] = std::array::from_fn(|_| noisy(&mut r, 1.0));
    let spawn = rigid(&mut r, 10.0);
    let mut body = SkeletonBody::new(SkeletonBodyDefinition::new(sizes, bones, body_settings, None).unwrap(), &authored, spawn, simulation);
    writeln!(s, "\tauthored = {},\n\tspawn = {},", authored.l(), spawn.l()).unwrap();

    // --- FootIkState::update + post_physics
    s.push_str("\tfoot_ik = {\n");
    for seq in 0..10 {
        let mut state = FootIkState::default();
        let mut steps = Vec::new();
        for _ in 0..8 {
            if r.next() % 5 == 0 { state.enable_feet(r.bool()); }
            if r.next() % 9 == 0 { state.mark_support_failed_this_update(); }
            for l in 0..4 {
                state.limbs[l].external_target_set = r.next() % 4 == 0;
                state.limbs[l].local_target_set = r.next() % 5 == 0;
                state.limbs[l].target_blend = [0.0, 1.0, r.unit()][(r.next() % 3) as usize];
                state.external_targets[l].world_position = p4(&mut r, 2.0);
                state.external_targets[l].animation_position = p4(&mut r, 1.0);
                state.external_targets[l].normal = p4(&mut r, 1.0);
                state.external_targets[l].normal_set = r.bool();
                state.external_targets[l].normal_blend = [0.0, r.unit(), 1.0][(r.next() % 3) as usize];
            }
            let pre = fik_l(&state);
            let a2w = noisy(&mut r, 3.0);
            let w2a = noisy(&mut r, 3.0);
            let physical_board = noisy(&mut r, 3.0);
            let contact_board = rigid(&mut r, 3.0);
            let inverse_contact_board = noisy(&mut r, 3.0);
            let animation: [T; 24] = std::array::from_fn(|_| noisy(&mut r, 0.8));
            let original: [T; 24] = std::array::from_fn(|_| noisy(&mut r, 0.8));
            let targets: [T; 4] = std::array::from_fn(|_| noisy(&mut r, 0.8));
            let mut drives: [T; 24] = std::array::from_fn(|_| noisy(&mut r, 0.8));
            let drives_in = drives;
            let flags = [r.next() & 0x43a0_0000, r.next() & 0x180, r.next() & 0x0800_0000];
            let hips = p4(&mut r, 1.0);
            let contact_bone = [bone_indices[15], bone_indices[19], 3][(r.next() % 3) as usize];
            let foot_bones = [bone_indices[15], bone_indices[19]];
            let current = [if r.bool() { Some(p4(&mut r, 0.3)) } else { None }, if r.bool() { Some(p4(&mut r, 0.3)) } else { None }];
            let updated = state.update(UpdateInput { flags_2468: flags[0], flags_2472: flags[1], flags_2480: flags[2], animation_to_world: &a2w, world_to_animation: &w2a,
                physical_board: &physical_board, contact_board: &contact_board, inverse_contact_board: &inverse_contact_board, animation: &animation, original_animation: &original,
                targets: &targets, hips_world_position: hips, contact_bone, foot_bones, current_contacts: current }, &geometry, &settings, &mut drives);
            let mid = fik_l(&state);
            // Чаще попадать в физическое решение: цели рядом с текущей позой тела.
            if r.bool() {
                for limb in 0..2 {
                    let adjacent = LIMBS[limb].parent_part.unwrap();
                    let part = LIMBS[limb].part;
                    let near = |r: &mut Rng, p: [f32; 4]| { let d = p4(r, 0.05); [p[0] + d[0], p[1] + d[1], p[2] + d[2], p[3]] };
                    state.frames[limb].parent_world = body.record.pose[adjacent];
                    state.frames[limb].parent_world[3] = near(&mut r, body.record.pose[adjacent][3]);
                    state.frames[limb].world = body.record.pose[part];
                    state.frames[limb].world[3] = near(&mut r, body.record.pose[part][3]);
                    state.limbs[limb].external_blend = r.range(0.1, 1.0);
                }
            }
            let post_state = fik_l(&state);
            // post_physics на теле
            let state_id = [702u32, 200, 201, 100, 300][(r.next() % 5) as usize];
            let category = [500u32, 100][(r.next() % 2) as usize];
            let pinput = (state_id, category, r.bool(), r.next() % 3 == 0, r.next() & 0x0004_0000, r.next() & 0x0030_0000, r.unit() * 0.1, [500u32, 0][(r.next() % 2) as usize]);
            let pw2a = noisy(&mut r, 1.0);
            let pboard = noisy(&mut r, 1.0);
            let pupdated = post_physics::update(&mut state, &mut body, &geometry, &settings, &post, post_physics::Input { state_id: pinput.0, category_id: pinput.1, board_body_flag_868: pinput.2,
                wipeout: pinput.3, flags_2468: pinput.4, flags_2484: pinput.5, value_2664: pinput.6, state_2520: pinput.7, world_to_animation: &pw2a, board: &pboard });
            steps.push(obj!(pre = pre, a2w = a2w, w2a = w2a, physical_board = physical_board, contact_board = contact_board, inverse_contact_board = inverse_contact_board,
                animation = animation, original = original, targets = targets, drives_in = drives_in, flags = flags, hips = hips, contact_bone = contact_bone, foot_bones = foot_bones,
                current = current.map(|c| Raw(match c { Some(v) => v.l(), None => "false".into() })), updated = updated, drives = drives, mid = mid, post_state = post_state,
                post_in = Raw(obj!(state_id = pinput.0, category_id = pinput.1, board_body_flag_868 = pinput.2, wipeout = pinput.3, flags_2468 = pinput.4, flags_2484 = pinput.5, value_2664 = pinput.6, state_2520 = pinput.7, world_to_animation = pw2a, board = pboard)),
                post_updated = pupdated, out = fik_l(&state), record = record_l(&body.record), body_pose = body.part_transforms()));
        }
        writeln!(s, "\t\t{{ seq = {}, steps = {{ {} }} }},", seq, steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n");

    // --- board frames / air frames
    s.push_str("\tframes = {\n");
    for _ in 0..60 {
        let mut roots = random_root(&mut r);
        let mut b = SkeletonBoardFrames::default();
        let roots0 = root_l(&roots);
        let mut ops = Vec::new();
        for _ in 0..6 {
            let op = r.next() % 10;
            let t1 = noisy(&mut r, 3.0);
            let t2 = noisy(&mut r, 3.0);
            let p = v4(&mut r, 3.0);
            let p2 = v4(&mut r, 1.0);
            let x = r.range(-0.5, 0.5);
            let flags_in = r.next();
            let revert = AirDismountRevert { requested: r.bool(), frames: 1 + r.next() % 30, goofy: r.bool() };
            let mut flags = flags_in;
            let ret: Option<T> = match op {
                0 => { b.reset(t1); None }
                1 => { b.publish_local_observations(&roots, &t1); None }
                2 => { b.publish_centre_of_mass(p, [1.0 / 60.0, 0.02][(flags_in % 2) as usize], flags_in & 0x400); None }
                3 => Some(b.prepare_ground(&roots, &t1, t2, &mut flags)),
                4 => Some(b.prepare_teleport(&roots, &t1, t2, &mut flags)),
                5 => { b.update_com_lift(&t1, p, x); None }
                6 => Some(air::prepare_animated(&roots, &mut b, &t1, &mut flags)),
                7 => { air::update_known_air_roots(&mut roots, &t1, p, p2, revert); None }
                8 => { let t = air::prepare_known_air(&roots, &mut b, &t1, &mut flags); air::finish_known_air(&mut roots, &mut b, t2); Some(t) }
                _ => { air::update_plant_roots(&mut roots, &t1, p, p2); None }
            };
            ops.push(obj!(op = op, t1 = t1, t2 = t2, p = p, p2 = p2, x = x, flags_in = flags_in, revert = Raw(obj!(requested = revert.requested, frames = revert.frames, goofy = revert.goofy)),
                flags = flags, ret = ret, roots = root_l(&roots), board = bf_l(&b)));
        }
        writeln!(s, "\t\t{{ roots = {}, ops = {{ {} }} }},", roots0.l(), ops.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n");

    // --- board offset
    s.push_str("\toffset = {\n");
    for _ in 0..30 {
        let mut o = SkateboardOffset::default();
        let mut ops = Vec::new();
        for _ in 0..12 {
            let op = r.next() % 4;
            let t = noisy(&mut r, 0.3);
            let h = r.range(-0.3, 0.3);
            let frames = [1.0, 7.0, 15.0, 0.0][(r.next() % 4) as usize];
            let mut board = noisy(&mut r, 1.0);
            let mut targets: [T; 4] = std::array::from_fn(|_| noisy(&mut r, 1.0));
            let (b0, t0) = (board, targets);
            match op { 0 => o.refresh_transform(t), 1 => o.refresh_height(h, frames), _ => {} }
            o.update(&mut board, &mut targets);
            ops.push(obj!(op = op, t = t, h = h, frames = frames, board_in = b0, targets_in = t0, board = board, targets = targets, out = off_l(&o)));
        }
        writeln!(s, "\t\t{{ {} }},", ops.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n");

    // --- general, motion, biped_air, landing_on_board
    s.push_str("\tgeneral = {\n");
    for _ in 0..12 {
        let mut prev = v4(&mut r, 2.0);
        let prev0 = prev;
        let cur = v4(&mut r, 2.0);
        let dt = [1.0f32 / 60.0, 0.02, 0.1][(r.next() % 3) as usize];
        let vel = skeleton_general::root_velocity(&mut prev, cur, dt);
        let g = r.range(5.0, 12.0);
        skeleton_general::apply_gravity_displacement(&mut body, g);
        let forces: Vec<Vector3> = body.bodies().iter().map(|b| b.rates.force_acceleration).collect();
        let mut anim = SkeletonAnimationRecord::default();
        anim.centre_of_mass = v4(&mut r, 1.0);
        anim.com_to_deck_world = v4(&mut r, 1.0);
        let drive_pose: [T; 24] = std::array::from_fn(|_| noisy(&mut r, 1.0));
        let a2w = noisy(&mut r, 5.0);
        let com_frame = noisy(&mut r, 5.0);
        let reset = r.next() % 3 == 0;
        let obs = if reset { Some(skeleton_general::reset_to_animation(&mut body, &mut anim, &drive_pose, &a2w, com_frame, simulation)) } else { None };
        writeln!(s, "\t\t{},", obj!(prev0 = prev0, cur = cur, dt = dt, vel = vel, prev = prev, g = g, forces = forces, reset = reset, drive_pose = drive_pose, a2w = a2w, com_frame = com_frame,
            anim_com = anim.centre_of_mass, anim_deck = anim.com_to_deck_world,
            obs = obs.map(|o| Raw(obj!(local_hips = o.local_hips, world_hips = o.world_hips))), record = record_l(&body.record),
            bodies = body.bodies().iter().map(|b| Raw(obj!(position = b.rates.position, linear_velocity = b.rates.linear_velocity, angular_velocity = b.rates.angular_velocity, force_acceleration = b.rates.force_acceleration, torque_acceleration = b.rates.torque_acceleration))).collect::<Vec<_>>())).unwrap();
    }
    s.push_str("\t},\n\tmotion = {\n");
    for _ in 0..20 {
        let mut m = SkeletonMotion::default();
        if r.bool() { m.reset_board_orientation_history(); }
        let mut ops = Vec::new();
        for _ in 0..5 {
            let tb = noisy(&mut r, 0.2);
            let a2w = noisy(&mut r, 3.0);
            let dt = [1.0f32 / 60.0, 0.02][(r.next() % 2) as usize];
            let board = noisy(&mut r, 1.0);
            let f72 = r.next();
            let f68 = r.next();
            m.process_trajectory(&tb, &a2w, dt);
            let mut f72o = f72;
            SkeletonMotion::publish_unadjusted_board(&board, &mut f72o);
            let mut f68o = f68;
            let delta = m.publish_adjusted_board(&board, &mut f68o);
            ops.push(obj!(tb = tb, a2w = a2w, dt = dt, board = board, f72 = f72, f68 = f68, f72o = f72o, f68o = f68o, delta = delta,
                trajectory = m.trajectory, inverse_trajectory = m.inverse_trajectory, next_trajectory = m.next_trajectory, velocity_world = m.velocity_world));
        }
        writeln!(s, "\t\t{{ {} }},", ops.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n\tbiped = {\n");
    for _ in 0..30 {
        let mut roots = random_root(&mut r);
        let roots0 = root_l(&roots);
        let frame = noisy(&mut r, 2.0);
        let tp = v4(&mut r, 5.0);
        let lc = v4(&mut r, 1.0);
        let mb = noisy(&mut r, 1.0);
        let f76 = r.next() & 4;
        let f68 = r.next();
        let mut f68o = f68;
        let out = skeleton_biped_air::prepare(&mut roots, frame, tp, lc, &mb, f76, &mut f68o);
        writeln!(s, "\t\t{},", obj!(roots0 = roots0, frame = frame, tp = tp, lc = lc, mb = mb, f76 = f76, f68 = f68, f68o = f68o, out = out, roots = root_l(&roots))).unwrap();
    }
    s.push_str("\t},\n\tlanding_on_board = {\n");
    for _ in 0..40 {
        let old = noisy(&mut r, 2.0);
        let com = v4(&mut r, 2.0);
        let f80 = r.next() & 3;
        let gy = r.range(-1.0, 1.0);
        let st = lob::Settings { root_y_offset: r.range(-0.5, 0.5), capsule_radius: r.range(0.0, 0.3), capsule_length: r.range(0.0, 0.5) };
        let sr = lob::skate_root(old, com, f80, gy, st);
        let mut roots = random_root(&mut r);
        let roots0 = root_l(&roots);
        let lc = v4(&mut r, 1.0);
        let spin = r.range(-0.5, 0.5);
        let rf = if r.bool() { Some(1 + r.next() % 20) } else { None };
        let rev = r.bool();
        lob::update_root(&mut roots, com, lc, spin, rf, rev);
        let (w2a, ab, mb, iko) = (noisy(&mut r, 2.0), noisy(&mut r, 2.0), noisy(&mut r, 2.0), v4(&mut r, 0.3));
        let cvy = r.range(-1.0, 0.5);
        let time = r.range(0.0, 1.0);
        let g: PointGraph<8> = graph(&mut r, 1.0);
        let pa = lob::pose_adjustment(&w2a, &ab, &mb, iko, cvy, f80, time, &g);
        writeln!(s, "\t\t{},", obj!(old = old, com = com, f80 = f80, gy = gy, st = Raw(obj!(root_y_offset = st.root_y_offset, capsule_radius = st.capsule_radius, capsule_length = st.capsule_length)),
            sr = sr, roots0 = roots0, lc = lc, spin = spin, rf = rf, rev = rev, roots = root_l(&roots), w2a = w2a, ab = ab, mb = mb, iko = iko, cvy = cvy, time = time, g = g, pa = pa)).unwrap();
    }
    s.push_str("\t},\n");

    // --- landing
    s.push_str("\tlanding = {\n");
    for _ in 0..25 {
        let st = LandingSettings { manual_blend: graph(&mut r, 1.0), grind_blend: graph(&mut r, 1.0), coffin_height: graph(&mut r, 0.5),
            minimum_height: r.range(0.2, 0.6), maximum_velocity: r.range(2.0, 10.0), manual_damping: r.range(5.0, 20.0), manual_spring: r.range(20.0, 80.0),
            ground_minimum_compression_time: r.range(0.0, 0.1), ground_damping: r.range(2.0, 10.0), ground_spring: r.range(20.0, 80.0),
            grind_animation_target_time: r.range(0.0, 0.3), grind_damping: r.range(2.0, 15.0), grind_spring: r.range(20.0, 80.0), grind_target_delta: r.range(0.0, 0.05),
            desired_com_height: r.range(0.6, 1.0), coffin_time: r.range(0.02, 0.2), coffin_maximum_velocity: r.range(1.0, 8.0), coffin_blend_frames: r.range(3.0, 10.0), coffin_base_height: r.range(0.0, 0.4) };
        let mut adj = LandingAdjustment::default();
        let mut off = SkateboardOffset::default();
        let mut steps = Vec::new();
        for _ in 0..40 {
            let input = LandingInput { filtered_state: [1u32, 2, 3, 6, 1, 1][(r.next() % 6) as usize], flags_2468: r.next() & 0x0020_0020 & if r.next() % 4 == 0 { !0 } else { 0x20 },
                flags_2472: r.next() & 1, flags_2476: r.next() & (0x1000_0000 | if r.next() % 6 == 0 { 0x4000_0000 } else { 0 }),
                balance: if r.bool() { 0.0 } else { r.range(-1.0, 1.0) }, physical_com_velocity_along_up: r.range(-4.0, 2.0),
                physical_com_height: r.range(0.3, 1.2), animation_com_height: r.range(0.3, 1.2) };
            adj.update(input, &st, &mut off);
            let upd = r.next() % 5 == 0;
            steps.push(obj!(upd = upd, input = Raw(obj!(filtered_state = input.filtered_state, flags_2468 = input.flags_2468, flags_2472 = input.flags_2472, flags_2476 = input.flags_2476, balance = input.balance,
                physical_com_velocity_along_up = input.physical_com_velocity_along_up, physical_com_height = input.physical_com_height, animation_com_height = input.animation_com_height)),
                adj = Raw(obj!(active = adj.active, kind = adj.kind, time = adj.time, position = adj.position, velocity = adj.velocity, previous_com_velocity = adj.previous_com_velocity,
                    previous_animation_height = adj.previous_animation_height, previous_filtered_state = adj.previous_filtered_state, desired_grind_com = adj.desired_grind_com)),
                off = off_l(&off)));
            if upd { let mut b = IDENTITY; let mut t = [IDENTITY; 4]; off.update(&mut b, &mut t); }
        }
        writeln!(s, "\t\t{{ settings = {}, steps = {{ {} }} }},", obj!(manual_blend = st.manual_blend, grind_blend = st.grind_blend, coffin_height = st.coffin_height, minimum_height = st.minimum_height,
            maximum_velocity = st.maximum_velocity, manual_damping = st.manual_damping, manual_spring = st.manual_spring, ground_minimum_compression_time = st.ground_minimum_compression_time,
            ground_damping = st.ground_damping, ground_spring = st.ground_spring, grind_animation_target_time = st.grind_animation_target_time, grind_damping = st.grind_damping, grind_spring = st.grind_spring,
            grind_target_delta = st.grind_target_delta, desired_com_height = st.desired_com_height, coffin_time = st.coffin_time, coffin_maximum_velocity = st.coffin_maximum_velocity,
            coffin_blend_frames = st.coffin_blend_frames, coffin_base_height = st.coffin_base_height), steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n");

    // --- skeleton_output
    let output = so::SkeletonOutput { bone_indices, geometry: geometry.clone(),
        board_bones: sob::BoneIndices { front_truck: 30, back_truck: 31, front_left_wheel: 32, front_right_wheel: 33, back_left_wheel: 34, back_right_wheel: 35 },
        board_settings: sob::Settings { truck_tilt_scalar: r.range(0.2, 1.0), truck_tilt_max_angle: r.range(0.1, 0.5), truck_tilt_wobble_scalar: r.range(0.0, 1.0), truck_displacement_max: r.range(0.0, 0.05) } };
    let bst = output.board_settings;
    writeln!(s, "\tboard_settings = {},", obj!(truck_tilt_scalar = bst.truck_tilt_scalar, truck_tilt_max_angle = bst.truck_tilt_max_angle, truck_tilt_wobble_scalar = bst.truck_tilt_wobble_scalar, truck_displacement_max = bst.truck_displacement_max)).unwrap();
    s.push_str("\toutput = {\n");
    let n = hierarchy.parents.len();
    for _ in 0..20 {
        let physical: [T; 24] = std::array::from_fn(|_| noisy(&mut r, 2.0));
        let w2a = noisy(&mut r, 2.0);
        let mut bodies: [T; 6] = std::array::from_fn(|_| noisy(&mut r, 0.4));
        if r.next() % 4 == 0 { bodies[1][3] = bodies[0][3]; }
        let sk_board = noisy(&mut r, 1.0);
        let trucks: [T; 2] = std::array::from_fn(|_| noisy(&mut r, 0.3));
        let tilt = r.range(-0.3, 0.3);
        let squish = r.range(-0.02, 0.02);
        let comp = [r.range(-0.01, 0.06), r.range(-0.01, 0.06)];
        let mut globals: Vec<T> = (0..n).map(|_| noisy(&mut r, 1.0)).collect();
        let mut locals: Vec<T> = (0..n).map(|_| noisy(&mut r, 1.0)).collect();
        let (g0, l0) = (globals.clone(), locals.clone());
        output.publish(so::Input { physical_parts: &physical, world_to_animation: &w2a, board: sob::Input { bodies: &bodies, skeleton_board: &sk_board, truck_frames: &trucks,
            deck_wobble_tilt: tilt, deck_wobble_squish: squish, average_compression: comp } }, &mut globals, &mut locals).unwrap();
        writeln!(s, "\t\t{},", obj!(physical = physical, w2a = w2a, bodies = bodies, sk_board = sk_board, trucks = trucks, tilt = tilt, squish = squish, comp = comp, g0 = g0, l0 = l0, globals = globals, locals = locals)).unwrap();
    }
    s.push_str("\t},\n\twobble = {\n");
    for _ in 0..20 {
        let st = wobble::Settings { takeoff_tilt: graph(&mut r, 0.3), landing_tilt: graph(&mut r, 0.3), takeoff_squish: graph(&mut r, 0.05), landing_squish: graph(&mut r, 0.05), maximum_time: r.range(0.1, 0.6) };
        let mut w = wobble::Wobble::default();
        let mut steps = Vec::new();
        for _ in 0..20 {
            let trig = if r.next() % 6 == 0 { Some((r.bool(), r.bool())) } else { None };
            if let Some((l, rv)) = trig { w.trigger(l, rv); }
            let out = w.update(&st);
            let mut board = noisy(&mut r, 1.0);
            let b0 = board;
            wobble::apply(out, &mut board);
            steps.push(obj!(trig = trig.map(|(a, b)| Raw(obj!(landing = a, reverse = b))), out = Raw(obj!(sampled = out.sampled, tilt = out.tilt, squish = out.squish, remains_active = out.remains_active)),
                board_in = b0, board = board, state = Raw(obj!(active = w.active, landing = w.landing, time = w.time, amplitude = w.amplitude, direction = w.direction))));
        }
        writeln!(s, "\t\t{{ settings = {}, steps = {{ {} }} }},", obj!(takeoff_tilt = st.takeoff_tilt, landing_tilt = st.landing_tilt, takeoff_squish = st.takeoff_squish, landing_squish = st.landing_squish, maximum_time = st.maximum_time), steps.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n\tcorrection = {\n");
    for _ in 0..20 {
        let mut c = correction::CorrectionState::default();
        let actual = v4(&mut r, 1.0);
        let predicted = v4(&mut r, 1.0);
        c.observe_board(actual, predicted);
        c.pending = r.bool();
        let pending0 = c.pending;
        let gn = { let v = r.vec(1.0); let l = (v.x * v.x + v.y * v.y + v.z * v.z).sqrt().max(1e-3); [v.x / l, v.y / l, v.z / l, 0.0] };
        let wipeout = r.bool();
        let f68 = r.next() & 0x0004_0000;
        let f76 = r.next() & 0x4000_0000;
        c.apply(&mut body, gn, wipeout, f68, f76);
        writeln!(s, "\t\t{},", obj!(actual = actual, predicted = predicted, pending0 = pending0, gn = gn, wipeout = wipeout, f68 = f68, f76 = f76, error = c.board_prediction_error, pending = c.pending, record = record_l(&body.record), pose = body.part_transforms())).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/skel2.luau"), s).unwrap();
}
