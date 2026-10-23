//! Эталон для physics/skeleton_root и physics/skeleton_body: стоковые настройки
//! из коллекций и physics-skeletons.json (как в skate-game/physics/skeleton_body.rs),
//! синтетические позы, затем конструкторы, суставы, драйвы, режимы коллизий,
//! обратная связь контактов и ошибки позы.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::math::{Basis3, Vector3};
use skate_core::physics::{
    assembly::BodySnapshot,
    mass::MassShape,
    contact::RetailContactMaterial,
    drive_frames::RetailDriveFrames,
    drive_parameters::{RetailDriveDynamics, RetailDriveParams},
    drive_solver::RetailDriveRows,
    rigid_body::{RetailBodyMassProperties, RetailBodyRates, RetailInertiaDynamics, RetailQuaternion, RetailSimulationStep},
    skeleton_animation_record::{physics_bone_frame, AnimationPartTransform, IDENTITY},
    skeleton_body::*,
    skeleton_root::SkeletonRootFrames,
};
use skate_data::{abin::Bank, collections::Collections, physics_skeleton::PhysicsSkeleton};
use std::fmt::Write as _;
use std::path::Path;

type T = AnimationPartTransform;

fn ql(x: RetailQuaternion) -> Raw { Raw(obj!(x = x.x, y = x.y, z = x.z, w = x.w)) }
fn basis_l(x: Basis3) -> Raw { Raw(format!("{{ columns = {} }}", x.columns.l())) }
fn rates_l(r: &RetailBodyRates) -> Raw {
    Raw(obj!(orientation = ql(r.orientation), basis = basis_l(r.basis), world_inverse_inertia = basis_l(r.world_inverse_inertia), position = r.position,
        linear_velocity = r.linear_velocity, angular_velocity = r.angular_velocity, force_acceleration = r.force_acceleration,
        torque_acceleration = r.torque_acceleration, kinetic_energy = r.kinetic_energy, cool_down = r.cool_down))
}
fn inertia_l(i: &RetailInertiaDynamics) -> Raw {
    Raw(obj!(inverse_tensor = i.inverse_tensor, inverse_mass = i.inverse_mass, spherical = i.spherical, maximum_linear_velocity = i.maximum_linear_velocity,
        maximum_angular_velocity = i.maximum_angular_velocity, linear_drag = i.linear_drag, angular_drag = i.angular_drag))
}
fn snap_l(s: &BodySnapshot) -> Raw { Raw(obj!(state_flags = s.state_flags, rates = rates_l(&s.rates), inertia = inertia_l(&s.inertia))) }
fn props_l(p: &RetailBodyMassProperties) -> Raw {
    Raw(obj!(local_mass_frame = Raw(obj!(basis = basis_l(p.local_mass_frame.basis), translation = p.local_mass_frame.translation)), dynamics = inertia_l(&p.dynamics)))
}
fn shape_l(s: &MassShape) -> Raw {
    Raw(match *s {
        MassShape::Sphere { radius } => obj!(kind = "Sphere", radius = radius),
        MassShape::Capsule { radius, half_length } => obj!(kind = "Capsule", radius = radius, half_length = half_length),
        MassShape::RoundedBox { half_extents, radius } => obj!(kind = "RoundedBox", half_extents = half_extents, radius = radius),
        MassShape::Cylinder { radius, half_length, padding } => obj!(kind = "Cylinder", radius = radius, half_length = half_length, padding = padding),
        _ => obj!(kind = "Unsupported"),
    })
}
fn params_l(p: &RetailDriveParams) -> Raw {
    Raw(obj!(spring_or_max_velocity = p.spring_or_max_velocity, damping = p.damping, max_strength = p.max_strength, drive_type = p.drive_type as u32))
}
fn dyn_l(d: &RetailDriveDynamics) -> Raw { Raw(obj!(linear = params_l(&d.linear), angular = params_l(&d.angular))) }
fn frames_l(f: &RetailDriveFrames) -> Raw {
    Raw(obj!(body_a = Raw(obj!(orientation = ql(f.body_a.orientation), translation = f.body_a.translation)),
        body_b = Raw(obj!(orientation = ql(f.body_b.orientation), translation = f.body_b.translation))))
}
fn rows_l(r: &RetailDriveRows) -> Raw {
    Raw(obj!(arm_a = r.arm_a, arm_b = r.arm_b, linear_axes = r.linear_axes, angular_axes = r.angular_axes,
        linear_inverse_effective_mass = r.linear_inverse_effective_mass, angular_inverse_effective_mass = r.angular_inverse_effective_mass,
        linear_softness = r.linear_softness, angular_softness = r.angular_softness, linear_target_impulse = r.linear_target_impulse,
        angular_target_impulse = r.angular_target_impulse, linear_maximum_impulse = r.linear_maximum_impulse, angular_maximum_impulse = r.angular_maximum_impulse))
}
fn material_l(m: &RetailContactMaterial) -> Raw { Raw(obj!(static_friction = m.static_friction, dynamic_friction = m.dynamic_friction, restitution = m.restitution)) }
fn opt_usize(x: Option<usize>) -> Raw { Raw(match x { Some(v) => v.to_string(), None => "false".into() }) }

fn quat(r: &mut Rng) -> [f32; 4] {
    let a = r.vec(1.0);
    let w = r.range(-1.0, 1.0);
    let l = (a.x * a.x + a.y * a.y + a.z * a.z + w * w).sqrt();
    [a.x / l, a.y / l, a.z / l, w / l]
}
fn rigid(r: &mut Rng, span: f32) -> T {
    let t = r.vec(span);
    physics_bone_frame(quat(r), [t.x, t.y, t.z, 0.0])
}
fn noisy(r: &mut Rng, span: f32) -> T {
    let mut m = rigid(r, span);
    for c in 0..3 { for l in 0..3 { m[c][l] += r.range(-0.02, 0.02); } }
    m
}
fn v4(r: &mut Rng, span: f32) -> [f32; 4] { let v = r.vec(span); [v.x, v.y, v.z, r.range(-span, span)] }

fn root_l(f: &SkeletonRootFrames) -> Raw {
    Raw(obj!(board = f.board, inverse_board = f.inverse_board, previous_board_position = f.previous_board_position, predicted_board_position = f.predicted_board_position,
        supplied_prediction = f.supplied_prediction, animation_to_board = f.animation_to_board, animation_to_world = f.animation_to_world,
        world_to_animation = f.world_to_animation, heading_alignment = f.heading_alignment, initialize_heading = f.initialize_heading))
}
fn record_l(p: &SkeletonPhysicalRecord) -> Raw {
    Raw(obj!(pose = p.pose, positions = p.positions, velocities = p.velocities, velocity_changes = p.velocity_changes,
        centre_of_mass = p.centre_of_mass, centre_of_mass_velocity = p.centre_of_mass_velocity, timestep = p.timestep))
}
fn body_l(b: &SkeletonBody) -> Raw {
    Raw(obj!(bodies = b.bodies().iter().map(snap_l).collect::<Vec<_>>(), record = record_l(&b.record), animation_to_world = b.animation_to_world))
}
fn mode_l(m: &SkeletonCollisionMode) -> Raw {
    Raw(obj!(parts = m.parts.iter().map(|p| Raw(obj!(enabled = p.enabled, volume_group = p.volume_group, part_group = p.part_group, material = material_l(&p.material)))).collect::<Vec<_>>(),
        disable_count = m.disable_count, pending_reenable = m.pending_reenable, assembly_group = m.assembly_group, partial_ragdoll = m.partial_ragdoll,
        is_ragdoll = m.is_ragdoll, self_culling = m.self_culling))
}
fn feedback_l(c: &SkeletonCollisionFeedback) -> Raw {
    let f = &c.flags;
    Raw(obj!(contact_age = c.contact_age, priority = c.priority, compliant = c.compliant, current = c.current,
        bones = c.bones.iter().map(|b| Raw(obj!(normal = b.normal, specific_normal = b.specific_normal, tangent = b.tangent, specific_tangent = b.specific_tangent, point = b.point, force = b.force, specific_force = b.specific_force, tag = b.tag, specific_tag = b.specific_tag, groups = b.groups))).collect::<Vec<_>>(),
        regions = c.regions.iter().map(|r| Raw(obj!(force = r.force, weighted_force = r.weighted_force, tangent_speed = r.tangent_speed, material_flags = r.material_flags, normal = r.normal, part = r.part))).collect::<Vec<_>>(),
        planes = c.planes.iter().map(|p| Raw(obj!(normal = p.normal, part = p.part))).collect::<Vec<_>>(),
        specific = c.specific.iter().map(|p| Raw(obj!(part = p.part, local_point = p.local_point, world_point = p.world_point, radius_squared = p.radius_squared, current = p.current, recent = p.recent))).collect::<Vec<_>>(),
        highest_normal = c.highest_normal, foot_normal = c.foot_normal, material_normals = c.material_normals, timer = c.timer, drive_weight = c.drive_weight,
        maximum_priority = c.maximum_priority, wipeout_times = c.wipeout_times, maximum_skater_force = c.maximum_skater_force, other_skater = c.other_skater,
        maximum_group_8_force = c.maximum_group_8_force, maximum_group_11_force = c.maximum_group_11_force, material_12_height = c.material_12_height,
        flags = Raw(obj!(material_6 = f.material_6, noncompliant = f.noncompliant, compliant = f.compliant, recovering = f.recovering, group_8 = f.group_8, nonboard = f.nonboard, ragdoll = f.ragdoll, conflicting = f.conflicting, impaled = f.impaled, has_impulse = f.has_impulse, foot_board = f.foot_board, material_10 = f.material_10, material_11 = f.material_11, material_12 = f.material_12, any = f.any))))
}

pub fn write(out_dir: &str, asset_root: &str) {
    let root = Path::new(asset_root);
    let data = Collections::load(root).unwrap();
    let bank = Bank::load(&root.join("private/stock/data/anim/OnBoard.abin")).unwrap();
    let hierarchy = bank.hierarchy().unwrap();
    let json: serde_json::Value = serde_json::from_slice(&std::fs::read(root.join("private/stock/physics-skeletons.json")).unwrap()).unwrap();
    let sha = json["source_sha256"].as_str().unwrap().to_string();
    let skeleton = PhysicsSkeleton::load(&root.join("private/stock/physics-skeletons.json"), &sha, "PHYS_TPOSE").unwrap();
    let mut r = Rng(0x5ce1_e70d);
    let mut s = format!("-- Сгенерировано golden/src/skel.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n");

    // --- skeleton_root
    s.push_str("\troot = {\n");
    for _ in 0..30 {
        let mut f = SkeletonRootFrames::default();
        let mut steps = Vec::new();
        for _ in 0..6 {
            let kind = r.next() % 5;
            let board = noisy(&mut r, 20.0);
            let velocity = v4(&mut r, 8.0);
            let dt = [1.0 / 60.0, 0.02, 0.0][(r.next() % 3) as usize];
            let mut animation_board = rigid(&mut r, 1.0);
            if r.next() % 6 == 0 { animation_board[2] = [0.0, 1.0, 0.0, 0.0]; }
            let reckoning = noisy(&mut r, 0.5);
            let supplied = if kind == 1 { Some(v4(&mut r, 30.0)) } else { None };
            let heading = kind == 2;
            if let Some(p) = supplied { f.supplied_prediction = Some(p); }
            if heading { f.initialize_heading = true; }
            match kind {
                3 => f.update_teleport(board, &animation_board, &reckoning),
                4 => f.reset_initial_alignment(board),
                _ => f.update(board, velocity, dt, &animation_board, &reckoning),
            }
            steps.push(obj!(kind = kind, board = board, velocity = velocity, dt = dt, animation_board = animation_board, reckoning = reckoning, supplied = supplied, heading = heading, out = root_l(&f)));
        }
        writeln!(s, "\t\t{{ {} }},", steps.join(", ")).unwrap();
    }
    s.push_str("\t},\n");

    // --- settings (как skate-game/physics/skeleton_body.rs)
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
        capsule_radius_scalar: data.float("physics_skeleton_bones", "default", "CapsuleRadiusScalar").unwrap(),
        capsule_length_scalar: value("CapsuleLengthScalar"),
        ragdoll_inverse_mass_factor: data.float("physics_wipeout", "default", "RagdollInvMassFactor").unwrap(),
        inertia_multiply_type: data.integer("animation", "default", "InertiaMultiplyType").unwrap(),
        inertia_factor: data.float("animation", "default", "InertiaMultFactor").unwrap(),
    };
    let bones_l: Vec<Raw> = bones.iter().map(|b| Raw(obj!(mass_factor = b.mass_factor, ragdoll_mass_factor = b.ragdoll_mass_factor, has_collision = b.has_collision, use_root_drive = b.use_root_drive, volume_type = b.volume_type, volume_scalar = b.volume_scalar, num_parents = b.num_parents))).collect();
    let bs = &body_settings;
    let settings_l = Raw(obj!(density = bs.density, root_radius = bs.root_radius, root_half_length = bs.root_half_length, capsule_radius_scalar = bs.capsule_radius_scalar,
        capsule_length_scalar = bs.capsule_length_scalar, ragdoll_inverse_mass_factor = bs.ragdoll_inverse_mass_factor, inertia_multiply_type = bs.inertia_multiply_type, inertia_factor = bs.inertia_factor));
    let hat_in = (r.range(0.05, 0.2), r.range(0.01, 0.1), r.vec(1.0), r.vec(0.1));
    let hat = HatGeometry::from_offsets(hat_in.0, hat_in.1, hat_in.2, hat_in.3);
    s.push_str("\tdefinitions = {\n");
    for with_hat in [false, true] {
        let def = SkeletonBodyDefinition::new(sizes, bones, body_settings, if with_hat { Some(hat) } else { None }).unwrap();
        let parts: Vec<Raw> = def.parts.iter().map(|p| Raw(obj!(shape = shape_l(&p.shape), animated = props_l(&p.animated), ragdoll = props_l(&p.ragdoll), inverse_mass_animated = p.inverse_mass_animated, inverse_mass_ragdoll = p.inverse_mass_ragdoll,
            hat = p.hat.map(|h| Raw(obj!(radius = h.radius, half_length = h.half_length, basis = basis_l(h.basis), translation = h.translation)))))).collect();
        let m = &def.animation_masses;
        writeln!(s, "\t\t{},", obj!(with_hat = with_hat, parts = parts, masses = Raw(obj!(part_weights = m.part_weights, total = m.total, fractional = m.fractional)))).unwrap();
    }
    writeln!(s, "\t}},\n\tsizes = {},\n\tbones = {},\n\tbody_settings = {},\n\that_in = {},", sizes.l(), bones_l.l(), settings_l.l(),
        obj!(radius = hat_in.0, thickness = hat_in.1, angles = hat_in.2, translation = hat_in.3)).unwrap();

    // --- body
    let simulation = RetailSimulationStep::fixed_60_hz(30, 0.0005, Vector3::new(0.0, -9.81, 0.0));
    let definition = SkeletonBodyDefinition::new(sizes, bones, body_settings, None).unwrap();
    let authored: [T; 24] = std::array::from_fn(|_| noisy(&mut r, 1.0));
    let spawn = rigid(&mut r, 10.0);
    let mut body = SkeletonBody::new(definition, &authored, spawn, simulation);
    writeln!(s, "\tbody_new = {},", obj!(authored = authored, spawn = spawn, out = body_l(&body))).unwrap();
    s.push_str("\tbody_ops = {\n");
    for _ in 0..40 {
        let op = r.next() % 3;
        let part = (r.next() % 26) as usize;
        let frame = noisy(&mut r, 5.0);
        let disp = v4(&mut r, 0.3);
        match op {
            0 => body.set_part_transform(part, frame),
            1 => body.apply_part_displacement(part % 24, disp),
            _ => body.publish_physical_record(frame),
        }
        writeln!(s, "\t\t{},", obj!(op = op, part = part, frame = frame, disp = disp, out = body_l(&body))).unwrap();
    }
    s.push_str("\t},\n");

    // --- joints (как load_joints)
    let n = hierarchy.parents.len();
    let initial_hierarchy: Vec<T> = (0..n).map(|_| rigid(&mut r, 1.0)).collect();
    let lookup = |name: &str| hierarchy.bone_names.iter().position(|b| b.eq_ignore_ascii_case(name)).unwrap();
    let bone_indices: [usize; 24] = std::array::from_fn(|i| lookup(&skeleton.bones[i].name));
    let initial_bones: [T; 24] = std::array::from_fn(|i| initial_hierarchy[bone_indices[i]]);
    let mut parents = [None; 24];
    for child in 0..24 {
        let mut parent = hierarchy.parents[bone_indices[child]];
        while parent != -1 {
            let index = parent as usize;
            if let Some(physical) = bone_indices.iter().position(|b| *b == index) { parents[child] = Some(physical); break; }
            parent = hierarchy.parents[index];
        }
    }
    let joint_bones: [JointBone; 24] = std::array::from_fn(|i| {
        let bone = &skeleton.bones[i];
        let [x, y, z] = bone.translation();
        JointBone { parent_orientation: std::array::from_fn(|l| f32::from_bits(bone.words[l])), joint_orientation: std::array::from_fn(|l| f32::from_bits(bone.words[4 + l])),
            volume_frame: physics_bone_frame(bone.rotation(), [x, y, z, 0.0]), swing_limit: f32::from_bits(bone.words[21]), twist_limit: f32::from_bits(bone.words[20]) }
    });
    const JOINT_NAMES: [&str; 22] = ["JOINT_NECK_NECK1", "JOINT_SPINE3_NECK", "JOINT_LEFT_FOREARM_HAND", "JOINT_LEFT_ARM_FOREARM", "JOINT_LEFT_SHOULDER_ARM", "JOINT_SPINE3_LEFT_SHOULDER",
        "JOINT_RIGHT_FOREARM_HAND", "JOINT_RIGHT_ARM_FOREARM", "JOINT_RIGHT_SHOULDER_ARM", "JOINT_SPINE3_RIGHT_SHOULDER", "JOINT_SPINE2_SPINE3", "JOINT_SPINE1_SPINE2", "JOINT_SPINE_SPINE1",
        "JOINT_HIPS_SPINE", "JOINT_LEFT_FOOT_TOE_BASE", "JOINT_LEFT_LEG_FOOT", "JOINT_LEFT_UPLEG_LEG", "JOINT_HIPS_LEFT_LEG", "JOINT_RIGHT_FOOT_TOE_BASE", "JOINT_RIGHT_LEG_FOOT",
        "JOINT_RIGHT_UPLEG_LEG", "JOINT_HIPS_RIGHT_LEG"];
    let joint_settings: [JointSettings; 22] = std::array::from_fn(|i| {
        let w = data.words::<5>("physics_skeleton_joints", "default", JOINT_NAMES[i]).unwrap();
        JointSettings { ball_joint: w[0] >> 24 != 0, swing_angle: f32::from_bits(w[1]), twist_angle: f32::from_bits(w[2]), swing_ragdoll: f32::from_bits(w[3]), twist_ragdoll: f32::from_bits(w[4]) }
    });
    let global = SkeletonJointSettings {
        displacement_limit: data.words::<4>("physics_skeleton", "default", "DisplacementLimit").unwrap().map(f32::from_bits),
        twist_displacement_limit: value("TwistDisplacementLimit"), swing_displacement_limit: value("SwingDisplacementLimit"),
        enforce_swing_free: data.boolean("physics_skeleton_joints", "default", "EnforceSwingFree").unwrap(),
        enforce_twist_free: data.boolean("physics_skeleton_joints", "default", "EnforceTwistFree").unwrap(),
    };
    let joints = SkeletonJoints::new(&initial_bones, &parents, &joint_bones, &joint_settings, global).unwrap();
    let built = joints.build(body.bodies(), 10, simulation.time_step);
    writeln!(s, "\tjoints = {},", obj!(
        initial_bones = initial_bones, parents = parents.map(opt_usize),
        bones = joint_bones.iter().map(|b| Raw(obj!(parent_orientation = b.parent_orientation, joint_orientation = b.joint_orientation, volume_frame = b.volume_frame, swing_limit = b.swing_limit, twist_limit = b.twist_limit))).collect::<Vec<_>>(),
        settings = joint_settings.iter().map(|j| Raw(obj!(ball_joint = j.ball_joint, swing_angle = j.swing_angle, twist_angle = j.twist_angle, swing_ragdoll = j.swing_ragdoll, twist_ragdoll = j.twist_ragdoll))).collect::<Vec<_>>(),
        global = Raw(obj!(displacement_limit = global.displacement_limit, twist_displacement_limit = global.twist_displacement_limit, swing_displacement_limit = global.swing_displacement_limit, enforce_swing_free = global.enforce_swing_free, enforce_twist_free = global.enforce_twist_free)),
        records = joints.records.iter().map(|j| Raw(obj!(parent = j.parent, child = j.child, parameters = Raw(obj!(words = j.parameters.words)), frames = Raw(obj!(words = j.frames.words))))).collect::<Vec<_>>(),
        built = built.iter().map(|c| Raw(obj!(jacobian = Raw(obj!(words = c.jacobian.words.to_vec())), reaction_a = c.reaction_a, reaction_b = c.reaction_b))).collect::<Vec<_>>())).unwrap();

    // --- drives (как load_drives)
    let mut collision_strength = [[0.0f32; 2]; 24];
    let scalar = data.float("physics_skeleton_drives", "default", "CollisionDriveScalar").unwrap();
    for part in 1..24 {
        let w = data.words::<9>("physics_skeleton_drives", "default", &format!("PART_{}", skeleton.bones[part].name)).unwrap();
        collision_strength[part] = [f32::from_bits(w[5]) * scalar, f32::from_bits(w[6]) * scalar];
    }
    let sc = |name| data.float("physics_skeleton_drives", "default", name).unwrap();
    let anim = |key| { let f = |name| data.float("animation_drives", key, name).unwrap();
        AnimationDriveSettings { linear_strength: f("LinearStrMin"), linear_displacement: f("LinearDispMin"), angular_strength: f("AngularStrMin"), angular_displacement: f("AngularDispMin") } };
    let bone_drive = BoneDriveSettings {
        animation: [anim("local"), anim("root")],
        collision_soft_displacement: sc("CollisionSoftDisp"), collision_soft_strength: sc("CollisionSoftStrength"),
        ragdoll_soft_displacement: sc("RagdollSoftDisp"), ragdoll_soft_strength: sc("RagdollSoftStrength"),
        transition_linear: DriveInterpolation { spring: [sc("Hash_138976EAF99DF926"), sc("Hash_C313093118C7A83F")], strength: [sc("Hash_1E6BDF62043784FC"), sc("Hash_BD3E4F132848A588")], damping: [sc("Hash_D7652B4B19BB4747"), sc("Hash_C4B564DFD233CF04")] },
        transition_angular: DriveInterpolation { spring: [sc("Hash_14A2DDDD0A35C267"), sc("Hash_24D5AA7F214A901C")], strength: [sc("Hash_6C6CCD16A0A438AD"), sc("Hash_7379F8AB250BF611")], damping: [sc("Hash_28446A9E25DCC04C"), sc("Hash_B59D493B3DB372C8")] },
        transition_calls: sc("Hash_E1B89BB09D725EEC"),
    };
    let drive_settings = SkeletonDriveSettings { bone: bone_drive, enabled: data.boolean("animation", "default", "Use_Drives").unwrap(),
        strength: [data.float("animation", "default", "DriveStrengthLocal").unwrap(), data.float("animation", "default", "DriveStrengthRootLocal").unwrap()], collision_strength };
    let interp_l = |d: &DriveInterpolation| Raw(obj!(spring = d.spring, strength = d.strength, damping = d.damping));
    let bd = &bone_drive;
    let drive_settings_l = Raw(obj!(
        bone = Raw(obj!(animation = bd.animation.iter().map(|a| Raw(obj!(linear_strength = a.linear_strength, linear_displacement = a.linear_displacement, angular_strength = a.angular_strength, angular_displacement = a.angular_displacement))).collect::<Vec<_>>(),
            collision_soft_displacement = bd.collision_soft_displacement, collision_soft_strength = bd.collision_soft_strength, ragdoll_soft_displacement = bd.ragdoll_soft_displacement,
            ragdoll_soft_strength = bd.ragdoll_soft_strength, transition_linear = interp_l(&bd.transition_linear), transition_angular = interp_l(&bd.transition_angular), transition_calls = bd.transition_calls)),
        enabled = drive_settings.enabled, strength = drive_settings.strength, collision_strength = drive_settings.collision_strength));
    let mut drive_parents = [None; 24];
    for j in &joints.records { drive_parents[j.child] = Some(j.parent); }
    let initial_mapped: [T; 24] = std::array::from_fn(|_| noisy(&mut r, 1.0));
    let mut drives = SkeletonDrives::new(&initial_bones, &initial_mapped, &drive_parents, body.animation_to_world, spawn, simulation, drive_settings).unwrap();
    let drives_l = |d: &SkeletonDrives| Raw(obj!(
        targets = Raw(obj!(bodies = d.targets.bodies.iter().map(snap_l).collect::<Vec<_>>(), frames = d.targets.frames.iter().map(frames_l).collect::<Vec<_>>(), dynamics = d.targets.dynamics.iter().map(dyn_l).collect::<Vec<_>>())),
        bones = d.bones.iter().map(|b| match b { None => Raw("false".into()), Some(b) => Raw(obj!(parent = b.parent, active = b.active, frames = b.frames.iter().map(frames_l).collect::<Vec<_>>(),
            dynamics = Raw(obj!(channels = b.dynamics.channels.iter().map(dyn_l).collect::<Vec<_>>(), mode = b.dynamics.mode, strengths = b.dynamics.strengths, transition_counter = b.dynamics.transition_counter, transition_active = b.dynamics.transition_active)))) }).collect::<Vec<_>>()));
    writeln!(s, "\tdrives_new = {},", obj!(settings = drive_settings_l, parents = drive_parents.map(opt_usize), initial_mapped = initial_mapped, out = drives_l(&drives))).unwrap();
    s.push_str("\tdrives_ops = {\n");
    for i in 0..12 {
        let pose: [T; 24] = std::array::from_fn(|_| noisy(&mut r, 1.0));
        let partial = r.bool();
        let weight = [1.0, 0.0, 0.5, r.unit(), 1.5][(r.next() % 5) as usize];
        // Переходный режим 5 и режимы 1/2/4 включаются вручную через dynamics.mode.
        let forced = if i % 3 == 2 { Some((r.next() % 7) as u32) } else { None };
        drives.update(&pose, partial, weight);
        if let Some(m) = forced {
            for b in drives.bones.iter_mut().flatten() { b.dynamics.mode = m; let st = b.dynamics.strengths; for c in 0..2 { b.dynamics.enable(c, st[c], drive_settings.bone); } }
        }
        let batch = drives.build(body.bodies(), 0, 26, simulation.time_step);
        writeln!(s, "\t\t{},", obj!(pose = pose, partial = partial, weight = weight, forced = forced, out = drives_l(&drives),
            rows = batch.rows.iter().map(rows_l).collect::<Vec<_>>(),
            identities = batch.identities.iter().map(|x| Raw(match x { SkeletonDriveIdentity::Target(t) => obj!(kind = "Target", index = *t), SkeletonDriveIdentity::Bone { part, channel } => obj!(kind = "Bone", part = *part, channel = *channel) })).collect::<Vec<_>>(),
            spy = batch.spy)).unwrap();
    }
    s.push_str("\t},\n");
    // targets
    s.push_str("\ttargets = {\n");
    for _ in 0..10 {
        let (h, b, a, i, sr, c, l) = (noisy(&mut r, 1.0), noisy(&mut r, 1.0), noisy(&mut r, 5.0), noisy(&mut r, 5.0), noisy(&mut r, 5.0), noisy(&mut r, 5.0), noisy(&mut r, 5.0));
        let teleporting = r.next() % 4 == 0;
        let disp = r.vec(0.5);
        drives.targets.apply_future_deck_displacement(disp);
        let u = drives.targets.update_positions(SkeletonTargetInput { animation_hips: &h, animation_board: &b, animation_to_world: &a, inverse_board: &i, skate_root: &sr, com_frame: &c, lifted_com_frame: &l, teleporting }, &mut body);
        writeln!(s, "\t\t{},", obj!(h = h, b = b, a = a, i = i, sr = sr, c = c, l = l, teleporting = teleporting, disp = disp,
            out = Raw(obj!(animation_board_to_physics = u.animation_board_to_physics, positions = Raw(obj!(com = u.positions.com, lifted_com = u.positions.lifted_com, following_com = u.positions.following_com)), continuous = u.continuous)),
            target_bodies = drives.targets.bodies.iter().map(snap_l).collect::<Vec<_>>(), extra_velocity = [body.bodies()[24].rates.linear_velocity, body.bodies()[25].rates.linear_velocity])).unwrap();
    }
    s.push_str("\t},\n");

    // --- collision mode (как collision_settings::load)
    let mut compliant = [false; 24];
    let mut priority = [0.0f32; 24];
    compliant[0] = true;
    for part in 1..24 {
        let w = data.words::<9>("physics_skeleton_drives", "default", &format!("PART_{}", skeleton.bones[part].name)).unwrap();
        compliant[part] = w[7] >> 24 != 0;
        priority[part] = f32::from_bits(w[8]);
    }
    let friction = data.float("physics_skeleton", "default", "FrictionNormal").unwrap();
    let csettings = SkeletonCollisionSettings { enabled: data.boolean("physics_skeleton", "default", "EnableCollision").unwrap(),
        normal_material: RetailContactMaterial { static_friction: friction, dynamic_friction: friction, restitution: value("RestitutionNormal") },
        compliant, priority, effect_time: value("CollisionEffectTime") };
    let csettings_l = Raw(obj!(enabled = csettings.enabled, normal_material = material_l(&csettings.normal_material), compliant = csettings.compliant, priority = csettings.priority, effect_time = csettings.effect_time));
    s.push_str("\tmodes = {\n");
    for (seq, cull) in [false, true, false, false].into_iter().enumerate() {
        let mut settings = csettings;
        if seq == 3 { settings.enabled = false; }
        let mut mode = SkeletonCollisionMode::new_normal(settings, cull);
        let mut skel = SkeletonBody::new(SkeletonBodyDefinition::new(sizes, bones, body_settings, None).unwrap(), &authored, spawn, simulation);
        let mut feedback = SkeletonCollisionFeedback::new(SkeletonFeedbackSettings { body: settings, response: CollisionResponseSettings { force_scale: 0.5, velocity_scale: 9.0, divisor: 1000.0, region_scale: 10.0 },
            small_object_mass: 5.5, ground_plane_max_distance: 0.3, ground_plane_max_angle: 0.8, skater_scalar: 0.5, ai_scalar: 1.0, groin_offset: [0.0; 4], face_offset: [0.0; 4], groin_radius: 0.0, face_radius: 0.0 });
        let mut ops = Vec::new();
        for _ in 0..30 {
            let op = r.next() % 11;
            let a = r.next();
            let b = r.next();
            let mut err = false;
            let drag = [r.range(0.0, 1.0), r.range(0.0, 1.0)];
            let mats = [RetailContactMaterial { static_friction: r.unit(), dynamic_friction: r.unit(), restitution: r.unit() }, RetailContactMaterial { static_friction: r.unit(), dynamic_friction: r.unit(), restitution: r.unit() }];
            match op {
                0 => mode.disable_handplant_contacts(a % 4),
                1 => err = mode.select_driven([1, 3, 5, 6, 2, 0][(a % 6) as usize]).is_err(),
                2 => mode.normal_collision(),
                3 => mode.disable_all(a % 2 == 0),
                4 => mode.enable_bone((a % 24) as usize),
                5 => mode.finish_contact_frame(),
                6 => mode.normal_bone((a % 24) as usize, b % 2 == 0),
                7 => mode.restore_normal_properties(&mut skel),
                8 => mode.apply_ragdoll_properties(&mut skel, a % 2 == 0, b % 2 == 0, drag, mats),
                9 => mode.finish_ragdoll_request(7 + a % 4),
                _ => mode.reset_body_state(&mut feedback),
            }
            ops.push(obj!(op = op, a = a, b = b, err = err, drag = drag, mats = mats.iter().map(material_l).collect::<Vec<_>>(), out = mode_l(&mode),
                inertia = skel.bodies().iter().map(|x| inertia_l(&x.inertia)).collect::<Vec<_>>(), wii = skel.bodies().iter().map(|x| basis_l(x.rates.world_inverse_inertia)).collect::<Vec<_>>()));
        }
        writeln!(s, "\t\t{{ cull = {}, disabled = {}, ops = {{ {} }} }},", cull, seq == 3, ops.join(",\n\t\t\t")).unwrap();
    }
    writeln!(s, "\t}},\n\tcollision_settings = {},", csettings_l.l()).unwrap();

    // --- feedback (как collision_settings::feedback)
    let fv = |name| data.float("physics_collision", "default", name).unwrap();
    let fvec = |name| data.words::<4>("physics_collision", "default", name).unwrap().map(f32::from_bits);
    let fsettings = SkeletonFeedbackSettings { body: csettings,
        response: CollisionResponseSettings { force_scale: fv("Hash_FBF5CD7734E8AE5A"), velocity_scale: fv("Hash_AD7ECC44569EBEF9"), divisor: fv("Hash_06C10E1F5E1B4730"), region_scale: fv("Hash_1430BD50F0A33475") },
        small_object_mass: value("SmallObjectMassThreshold"), ground_plane_max_distance: fv("GroundPlaneMaxDist"), ground_plane_max_angle: fv("GroundPlaneMaxAngle"),
        skater_scalar: fv("SkaterSkeletonScalar"), ai_scalar: fv("AISkeletonScalar"), groin_offset: fvec("GroinLocalOffset"), face_offset: fvec("FaceLocalOffset"),
        groin_radius: fv("GroinRadius"), face_radius: fv("FaceRadius") };
    let fr = &fsettings.response;
    let fsettings_l = Raw(obj!(response = Raw(obj!(force_scale = fr.force_scale, velocity_scale = fr.velocity_scale, divisor = fr.divisor, region_scale = fr.region_scale)),
        small_object_mass = fsettings.small_object_mass, ground_plane_max_distance = fsettings.ground_plane_max_distance, ground_plane_max_angle = fsettings.ground_plane_max_angle,
        skater_scalar = fsettings.skater_scalar, ai_scalar = fsettings.ai_scalar, groin_offset = fsettings.groin_offset, face_offset = fsettings.face_offset,
        groin_radius = fsettings.groin_radius, face_radius = fsettings.face_radius));
    s.push_str("\tfeedback = {\n");
    let frames26 = body.part_transforms();
    let weights = body.definition.animation_masses.fractional;
    for seq in 0..8 {
        let mut fb = SkeletonCollisionFeedback::new(fsettings);
        if seq % 2 == 1 { fb.set_up_normal(); }
        let mut steps = Vec::new();
        for _ in 0..8 {
            let ragdoll = r.next() % 4 == 0;
            let unit = |r: &mut Rng| { let v = r.vec(1.0); let l = (v.x * v.x + v.y * v.y + v.z * v.z).sqrt().max(1e-3); [v.x / l, v.y / l, v.z / l, 0.0] };
            let plane_normal = if r.bool() { [0.0, 1.0, 0.0, 0.0] } else { unit(&mut r) };
            let flags_in = [ragdoll, r.next() % 5 == 0, r.bool(), r.next() % 4 == 0, r.next() % 6 == 0, r.next() % 5 == 0, r.next() % 8 == 0];
            let (plane_point, reference_velocity, com_velocity) = (v4(&mut r, 0.5), v4(&mut r, 5.0), v4(&mut r, 5.0));
            let input_l = obj!(dt = 1.0f32 / 60.0, plane_point = plane_point, plane_normal = plane_normal, reference_velocity = reference_velocity, com_velocity = com_velocity, flags = flags_in);
            let mut reports = Vec::new();
            let count = r.next() % 7;
            for _ in 0..count {
                let groups = [0u32, 4, 5, 8, 11, 3];
                let state_a = [4u32, 1, 2][(r.next() % 3) as usize];
                let state_b = [4u32, 1, 2][(r.next() % 3) as usize];
                reports.push(SkeletonContactReport { part: (r.next() % 24) as usize, normal: if r.bool() { unit(&mut r) } else { [0.0, [1.0, -1.0][(r.next() % 2) as usize], 0.0, 0.0] }, point: v4(&mut r, 1.0),
                    tag: r.next() & 0xfff, other_group: groups[(r.next() % 6) as usize], other_entity: if r.bool() { Some((r.next() % 10) as i32) } else { None },
                    body_a: SkeletonContactBody { state_flags: state_a, inverse_mass: r.range(0.0, 2.0), linear_velocity: v4(&mut r, 6.0) },
                    body_b: SkeletonContactBody { state_flags: state_b, inverse_mass: r.range(0.0, 2.0), linear_velocity: v4(&mut r, 6.0) },
                    side_a: r.bool(), solved_vector: v4(&mut r, 50.0) });
            }
            steps.push((input_l, plane_point, plane_normal, reference_velocity, com_velocity, flags_in, reports));
        }
        let mut out_steps = Vec::new();
        for (input_l, plane_point, plane_normal, reference_velocity, com_velocity, flags_in, reports) in steps {
            let input = SkeletonCollisionInput { dt: 1.0 / 60.0, plane_point, plane_normal, reference_velocity, com_velocity,
                ragdoll: flags_in[0], disable_ground_filter: flags_in[1], ai_collision_scalar: flags_in[2], offboard: flags_in[3], entering_offboard: flags_in[4], category_600: flags_in[5], request_partial_ragdoll: flags_in[6],
                physical: &body.record, part_weights: &weights, body_frames: &frames26 };
            fb.update(&input, &reports);
            let axis = [0.0, 1.0, 0.0, 0.0];
            let error = v4(&mut r, 1.0);
            let filtered = fb.filter_error(error, axis);
            let response = fb.fill_response(&body.record, &weights);
            let mut errors = SkeletonPoseErrors::default();
            errors.set_targets(ExtraTargetPositions { com: v4(&mut r, 3.0), lifted_com: v4(&mut r, 3.0), following_com: v4(&mut r, 3.0) });
            let drive_frames: [T; 24] = std::array::from_fn(|_| noisy(&mut r, 1.0));
            errors.update(&body.record, body.animation_to_world, &drive_frames);
            let normal = errors.normal_response(&fb, plane_normal);
            let partial = errors.partial_response();
            out_steps.push(obj!(input = Raw(input_l),
                reports = reports.iter().map(|x| Raw(obj!(part = x.part, normal = x.normal, point = x.point, tag = x.tag, other_group = x.other_group, other_entity = x.other_entity, side_a = x.side_a, solved_vector = x.solved_vector,
                    body_a = Raw(obj!(state_flags = x.body_a.state_flags, inverse_mass = x.body_a.inverse_mass, linear_velocity = x.body_a.linear_velocity)),
                    body_b = Raw(obj!(state_flags = x.body_b.state_flags, inverse_mass = x.body_b.inverse_mass, linear_velocity = x.body_b.linear_velocity))))).collect::<Vec<_>>(),
                out = feedback_l(&fb), error = error, filtered = filtered, response = response,
                errors_in = Raw(obj!(targets = errors.targets, drive_frames = drive_frames)),
                errors = Raw(obj!(parts = errors.parts, extra = errors.extra, targets = errors.targets)),
                normal = Raw(obj!(impulse = normal.impulse, extra = normal.extra, maximum_error = normal.maximum_error)),
                partial = Raw(obj!(impulse = partial.impulse, extra = partial.extra, maximum_error = partial.maximum_error))));
        }
        writeln!(s, "\t\t{{ set_up = {}, steps = {{ {} }} }},", seq % 2 == 1, out_steps.join(",\n\t\t\t")).unwrap();
    }
    writeln!(s, "\t}},\n\tfeedback_settings = {},\n\tfeedback_record = {},\n\tfeedback_frames = {},\n\tfeedback_weights = {},\n\tfeedback_animation_to_world = {},",
        fsettings_l.l(), record_l(&body.record).l(), frames26.l(), weights.l(), body.animation_to_world.l()).unwrap();
    s.push_str("}\n");
    std::fs::write(format!("{out_dir}/skel.luau"), s).unwrap();
    wipeout_state_section(out_dir, &mut r, sizes, bones, body_settings, &authored, spawn, simulation, &initial_bones, &initial_mapped, &drive_parents, drive_settings, drives_l);
}

// --- player::wipeout_state на настоящем теле скелета (данные игры, не в git).
#[allow(clippy::too_many_arguments)]
fn wipeout_state_section(out_dir: &str, r: &mut Rng, sizes: [Vector3; 24], bones: [BoneSettings; 24], body_settings: SkeletonBodySettings, authored: &[T; 24], spawn: T,
    simulation: RetailSimulationStep, initial_bones: &[T; 24], initial_mapped: &[T; 24], drive_parents: &[Option<usize>; 24], drive_settings: SkeletonDriveSettings,
    drives_l: fn(&SkeletonDrives) -> Raw) {
    use skate_core::player::wipeout_state::{self as ws, State};
    use skate_core::player::input_phase::ProcessedPhysicsInput;
    use skate_core::point_graph::PointGraph;
    let unit = |r: &mut Rng| { let v = r.vec(1.0); let l = (v.x * v.x + v.y * v.y + v.z * v.z).sqrt().max(1e-3); [v.x / l, v.y / l, v.z / l, 0.0] };
    let v4z = |r: &mut Rng, span: f32| { let v = r.vec(span); [v.x, v.y, v.z, 0.0] };
    let mut s = format!("-- Сгенерировано golden/src/skel.rs (wipeout_state) из настоящего skate-core. Не править.\n{HEADER}return {{\n");
    let state_l = |st: &State| Raw(obj!(time = st.time, settled_time = st.settled_time, time_until_teleport = st.time_until_teleport, impaled_time = st.impaled_time,
        no_support_time = st.no_support_time, response_time = st.response_time, extra_weight_zero_time = st.extra_weight_zero_time, slow_time = st.slow_time,
        surface_height = st.surface_height, board_offset = st.board_offset, forward = st.forward, right = st.right, angular_velocity = st.angular_velocity,
        retained_tilt = st.retained_tilt, velocity = st.velocity, retained_velocity = st.retained_velocity, predicted_position = st.predicted_position, over = st.over,
        slow = st.slow, material_eleven_response = st.material_eleven_response, air_collision_mode = st.air_collision_mode, request_teleport = st.request_teleport,
        move_board = st.move_board, special_surface = st.special_surface, below_surface = st.below_surface, retained_velocity_active = st.retained_velocity_active,
        sideways_input = st.sideways_input, forward_input = st.forward_input, orientation = st.orientation, collision_weight = st.collision_weight,
        controlled_weight = st.controlled_weight, control_time = st.control_time, retained_sideways_input = st.retained_sideways_input,
        retained_forward_input = st.retained_forward_input, response_scalar = st.response_scalar, extra_weight = st.extra_weight, maximum_speed = st.maximum_speed,
        response_start_speed = st.response_start_speed, response_change = st.response_change, board_move_frames = st.board_move_frames, response_count = st.response_count,
        response_frames = st.response_frames, airborne_frames = st.airborne_frames, teleport_countdown = st.teleport_countdown, prevent_manual = st.prevent_manual,
        ignore_reset = st.ignore_reset, reset_ever = st.reset_ever, ever_settled = st.ever_settled, recovery_eligible = st.recovery_eligible,
        teleport_pending = st.teleport_pending, ever_impaled = st.ever_impaled, direction_initialized = st.direction_initialized,
        material_ten_response = st.material_ten_response, imminent_surface_twelve = st.imminent_surface_twelve, allow_retained_velocity = st.allow_retained_velocity,
        response_finished = st.response_finished, surface_query = st.surface_query, profile = st.profile, predicted_time = st.predicted_time));
    let graph8 = |r: &mut Rng| { let mut x = [0.0f32; 8]; let mut acc = 0.0; for i in 0..8 { x[i] = acc; acc += r.range(0.05, 0.5); } PointGraph { x, y: std::array::from_fn(|_| r.range(0.0, 2.0)) } };
    for case in 0..6 {
        let mut body = SkeletonBody::new(SkeletonBodyDefinition::new(sizes, bones, body_settings, None).unwrap(), authored, spawn, simulation);
        let mut drives = SkeletonDrives::new(initial_bones, initial_mapped, drive_parents, body.animation_to_world, spawn, simulation, drive_settings.clone()).unwrap();
        // Разные позы записи: отпускаем тело и публикуем запись с разными досками.
        let mut boards = Vec::new();
        for _ in 0..(case % 3) { let board = rigid(r, 3.0); body.publish_physical_record(board); boards.push(board); }
        let mut st = State::default();
        st.velocity = v4z(r, 6.0);
        st.maximum_speed = r.range(0.0, 15.0);
        let (sv, sm) = (st.velocity, st.maximum_speed);
        let profiles: [ws::profiles::Profile; 5] = std::array::from_fn(|_| ws::profiles::Profile { roll_axis: unit(r), horizontal_axis: unit(r), align_euler: [r.range(-90.0, 90.0), r.range(-90.0, 90.0), 0.0, 0.0],
            spin_vs_time: graph8(r), direction_follow: r.range(0.0, 1.0), torque_velocity: r.range(0.0, 2.0), torque_distance: r.range(0.0, 2.0), spin_inertia: r.range(0.0, 1.0),
            roll_on_ground: r.bool(), ground_roll_torque: r.range(0.0, 2.0), sideways_spin: r.range(-10.0, 10.0), forward_spin: r.range(-10.0, 10.0), horizontal_directed: r.bool(),
            drift_maximum_speed: r.range(0.0, 5.0), drift_forward: r.range(0.0, 5.0), drift_sideways: r.range(0.0, 5.0), align_with_velocity: r.bool(),
            align_ground_with_velocity: r.bool(), ground_align_torque: r.range(0.0, 2.0), tilt_degrees: r.range(0.0, 45.0), drift_drag: r.range(0.0, 1.0) });
        let profile_l = |p: &ws::profiles::Profile| Raw(obj!(roll_axis = p.roll_axis, horizontal_axis = p.horizontal_axis, align_euler = p.align_euler, spin_vs_time = p.spin_vs_time,
            direction_follow = p.direction_follow, torque_velocity = p.torque_velocity, torque_distance = p.torque_distance, spin_inertia = p.spin_inertia, roll_on_ground = p.roll_on_ground,
            ground_roll_torque = p.ground_roll_torque, sideways_spin = p.sideways_spin, forward_spin = p.forward_spin, horizontal_directed = p.horizontal_directed,
            drift_maximum_speed = p.drift_maximum_speed, drift_forward = p.drift_forward, drift_sideways = p.drift_sideways, align_with_velocity = p.align_with_velocity,
            align_ground_with_velocity = p.align_ground_with_velocity, ground_align_torque = p.ground_align_torque, tilt_degrees = p.tilt_degrees, drift_drag = p.drift_drag));
        let dsettings = ws::drives::Settings { bone: std::array::from_fn(|_| std::array::from_fn(|_| r.range(0.0, 1.5))), root: std::array::from_fn(|_| r.range(0.0, 1.5)),
            strength: [r.range(100.0, 2000.0), r.range(100.0, 2000.0)], hook_spring: r.range(0.0, 50.0), hook_strength: r.range(0.0, 50.0), hook_damping: r.range(0.0, 5.0) };
        let wsettings = ws::weights::Settings { remove_target_time: r.range(0.0, 1.0), remove_drives_time: if r.bool() { 0.0 } else { r.range(0.0, 1.0) }, collision_step: r.range(0.0, 0.2), controlled_step: r.range(0.0, 0.2) };
        let rsettings = ws::recovery::Settings { minimum_time: r.range(0.0, 2.0), minimum_settled: r.range(0.0, 1.0), maximum_time: r.range(1.0, 5.0), fade_time: r.range(0.0, 1.0),
            over_speed: r.range(0.1, 3.0), over_minimum_time: r.range(0.0, 1.0) };
        let mut contact = ws::contact_response::ContactResponse::new();
        let mut roots = SkeletonRootFrames::default();
        let mut steps = Vec::new();
        for _ in 0..40 {
            let op = r.next() % 21;
            let (a, b, c) = (v4z(r, 4.0), unit(r), r.range(-1.0, 3.0));
            let input = [r.range(-1.0, 1.0), r.range(-1.0, 1.0)];
            let gesture = if r.bool() { [0.0, 0.0] } else { [r.range(-1.0, 1.0), r.range(-1.0, 1.0)] };
            let flags = [r.next(), r.next(), r.next()];
            let contact_flag = r.bool();
            let com = v4z(r, 2.0);
            let effective = rigid(r, 2.0);
            let pose: [T; 24] = std::array::from_fn(|_| noisy(r, 1.0));
            let mut out = Raw("nil".into());
            let pi = st.profile;
            let (x1, u1, u2, v1) = (rigid(r, 2.0), unit(r), unit(r), v4z(r, 2.0));
            match op {
                0 => ws::body::set_velocity(&mut body, a),
                1 => ws::body::add_velocity(&mut body, a),
                2 => ws::body::remove_normal_velocity(&mut body, b),
                3 => ws::body::blend_velocity(&mut body, a),
                4 => ws::body::limit_velocity(&mut body, c.abs() * 2.0),
                5 => { if contact_flag { ws::body::set_drag(&mut body, input[0].abs(), input[1].abs()) } else { ws::body::set_wipeout_drag(&mut body, c) } }
                6 => ws::body::special_surface(&mut body, com[1] - 1.0),
                7 => { let w = ws::torque::angular_velocity(&body.record, &body.definition.animation_masses.fractional); ws::torque::apply(&mut body, com, a); out = Raw(w.l()); }
                8 => { let ok = ws::control_air::update(&mut st, &mut body, com, input, contact_flag); out = Raw(ok.l()); }
                9 => { let mut processed = ProcessedPhysicsInput::default(); processed.vectors_464_480_496_512_528[0] = b.map(f32::to_bits);
                    ws::control_ground::update(&mut st, &mut body, com, &effective, &processed, &profiles[pi], &x1, &pose); }
                10 => ws::control_profile_air::update(&mut st, &mut body, com, &effective, input, &profiles[pi]),
                11 => { ws::profiles::prepare(&mut st, &profiles, gesture, input); ws::profiles::drift(&st, &mut body, &profiles[st.profile]); }
                12 => { let n = ws::response::response_normal(if contact_flag { Some(b) } else { None }, if gesture[0] > 0.0 { Some(u1) } else { None });
                    ws::response::trigger(&mut st, &mut body, n, input); ws::response::update_counter(&mut st, contact_flag); out = Raw(n.l()); }
                13 => { ws::response::update_counter(&mut st, contact_flag); ws::response::retained_velocity(&mut st, &mut body, &mut drives, &dsettings, contact_flag, flags[0] & 8, com); }
                14 => { let w = ws::drives::Weights { start: r.range(0.0, 1.0), end: r.range(0.0, 1.0), controlled: r.range(0.0, 1.0), upper_extra: if r.bool() { 0.0 } else { r.unit() }, lower_extra: if r.bool() { 0.0 } else { r.unit() } };
                    let res = ws::drives::update(&mut drives, &pose, &dsettings, w);
                    out = Raw(obj!(weights = Raw(format!("{{ start = {}, [\"end\"] = {}, controlled = {}, upper_extra = {}, lower_extra = {} }}", w.start.l(), w.end.l(), w.controlled.l(), w.upper_extra.l(), w.lower_extra.l())), residual = res)); }
                15 => { ws::drives::set_linear_root(&mut drives, &dsettings, c); ws::drives::set_angular_root(&mut drives, &dsettings, input[0]); }
                16 => { let o = ws::weights::update(&mut st, wsettings, contact_flag, gesture[0] > 0.0, flags[1], gesture);
                    out = Raw(format!("{{ target_weight = {}, start = {}, [\"end\"] = {}, controlled = {}, extra = {} }}", o.target_weight.l(), o.start.l(), o.end.l(), o.controlled.l(), o.extra.l())); }
                17 => { st.time += 0.5; st.manage_recovery(flags[0] & 1, flags[1], flags[2], 1.0 / 60.0, &rsettings); st.post_physics(a, v1, contact_flag, &rsettings);
                    out = Raw(st.response_strength().l()); }
                18 => { ws::skeleton::update_roots(&mut roots, &pose[23], &x1, a, com, v1, c);
                    out = Raw(obj!(a2w = roots.animation_to_world, w2a = roots.world_to_animation)); }
                19 => { let o = contact.update(&mut body, ws::contact_response::ContactResponseInput { com_velocity_608: a, material10_normal: if contact_flag { Some(b) } else { None },
                        material11_normal: if gesture[0] > 0.0 { Some(u1) } else { None }, effective_axis_224: u2, wipeout_control_2824_2828: input });
                    out = Raw(obj!(material10_phase = o.material10_phase, material10_finished_77 = o.material10_finished_77, material11_active_73 = o.material11_active_73)); }
                _ => { let o = st.output(&effective, b);
                    out = Raw(obj!(over_599 = o.over_599, scalar_544 = o.scalar_544, no_support_time_548 = o.no_support_time_548, can_leave_72 = o.can_leave_72,
                        collision_time_144 = o.collision_time_144, profile_148 = o.profile_148, retained = o.retained_air_velocity_160, change = o.response_change_588,
                        teleport_countdown_68 = o.teleport_countdown_68, hips_right_angle_496 = o.hips_right_angle_496, hips_up_angle_500 = o.hips_up_angle_500,
                        up = ws::orientation::alignment_up(a[0] * 20.0, a[1] * 20.0), projected = ws::orientation::projected_angle(a, b, u2))); }
            }
            steps.push(obj!(op = op, a = a, b = b, c = c, x1 = x1, u1 = u1, u2 = u2, v1 = v1, input = input, gesture = gesture, flags = flags, contact = contact_flag, com = com, effective = effective, pose = pose,
                out = out, state = state_l(&st), body = body_l(&body), drives = drives_l(&drives)));
        }
        writeln!(s, "	{{ boards = {}, state_velocity = {}, state_maximum_speed = {}, case = {}, profiles = {}, drives = {}, weights = {}, recovery = {}, steps = {{ {} }} }},", boards.l(), sv.l(), sm.l(), case, profiles.iter().map(profile_l).collect::<Vec<_>>().l(),
            obj!(bone = dsettings.bone, root = dsettings.root, strength = dsettings.strength, hook_spring = dsettings.hook_spring, hook_strength = dsettings.hook_strength, hook_damping = dsettings.hook_damping),
            obj!(remove_target_time = wsettings.remove_target_time, remove_drives_time = wsettings.remove_drives_time, collision_step = wsettings.collision_step, controlled_step = wsettings.controlled_step),
            obj!(minimum_time = rsettings.minimum_time, minimum_settled = rsettings.minimum_settled, maximum_time = rsettings.maximum_time, fade_time = rsettings.fade_time,
                over_speed = rsettings.over_speed, over_minimum_time = rsettings.over_minimum_time), steps.join(",\n\t\t")).unwrap();
    }
    s.push_str("}\n");
    std::fs::write(format!("{out_dir}/wst.luau"), s).unwrap();
}
