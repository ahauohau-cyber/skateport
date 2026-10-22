//! Эталон для physics/drive_frames, drive_parameters и construction/authored_transforms.
use crate::collision::{b, v, Rng};
use skate_core::math::{Basis3, Vector3};
use skate_core::physics::drive_frames::{
    authored_body_pose_records, authored_body_transforms, calculate_truck_transforms,
    default_body_transforms, default_live_body_orientations, default_live_body_transforms,
    default_truck_drive_frames, default_truck_transforms, default_wheel_drive_frames,
    retail_quaternion_from_basis, set_drive_frames_2, AuthoredTransformInputs,
    RetailAffineTransform, RetailDriveFrames, RetailTruckTransformInputs,
};
use skate_core::physics::drive_parameters::{
    retail_truck_drive_dynamics, retail_wheel_drive_dynamics, RetailDriveDynamics,
    RetailTruckDriveSettings,
};
use skate_core::physics::rigid_body::RetailQuaternion;
use std::fmt::Write as _;

fn basis(x: Basis3) -> String {
    let c = x.columns;
    format!(
        "{{ {{ {}, {}, {} }}, {{ {}, {}, {} }}, {{ {}, {}, {} }} }}",
        b(c[0][0]), b(c[0][1]), b(c[0][2]), b(c[1][0]), b(c[1][1]), b(c[1][2]),
        b(c[2][0]), b(c[2][1]), b(c[2][2])
    )
}
fn aff(t: RetailAffineTransform) -> String {
    format!("{{ {}, {} }}", basis(t.basis), v(t.translation))
}
fn q(x: RetailQuaternion) -> String {
    format!("{{ {}, {}, {}, {} }}", b(x.x), b(x.y), b(x.z), b(x.w))
}
fn frames(f: RetailDriveFrames) -> String {
    format!(
        "{{ {}, {}, {}, {} }}",
        q(f.body_a.orientation), v(f.body_a.translation), q(f.body_b.orientation), v(f.body_b.translation)
    )
}
fn dynamics(d: RetailDriveDynamics) -> String {
    format!(
        "{{ {{ {}, {}, {}, {} }}, {{ {}, {}, {}, {} }} }}",
        b(d.linear.spring_or_max_velocity), b(d.linear.damping), b(d.linear.max_strength), d.linear.drive_type as u32,
        b(d.angular.spring_or_max_velocity), b(d.angular.damping), b(d.angular.max_strength), d.angular.drive_type as u32
    )
}
fn rand_basis(r: &mut Rng) -> Basis3 {
    let (x, y, z, w) = (r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0), r.range(-1.0, 1.0));
    let l = (x * x + y * y + z * z + w * w).sqrt();
    let (x, y, z, w) = (x / l, y / l, z / l, w / l);
    Basis3 {
        columns: [
            [1.0 - 2.0 * (y * y + z * z), 2.0 * (x * y + z * w), 2.0 * (x * z - y * w)],
            [2.0 * (x * y - z * w), 1.0 - 2.0 * (x * x + z * z), 2.0 * (y * z + x * w)],
            [2.0 * (x * z + y * w), 2.0 * (y * z - x * w), 1.0 - 2.0 * (x * x + y * y)],
        ],
    }
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0xd21e_f00d);
    let mut s = String::from("-- Сгенерировано golden/src/drive.rs из настоящего skate-core. Не править.\nreturn {\n");
    let list = |xs: Vec<String>| xs.join(", ");
    writeln!(s, "\ttruck_transforms = {{ {} }},", list(default_truck_transforms().map(aff).to_vec())).unwrap();
    writeln!(s, "\tbody_transforms = {{ {} }},", list(default_body_transforms().map(aff).to_vec())).unwrap();
    writeln!(s, "\tlive_transforms = {{ {} }},", list(default_live_body_transforms().map(aff).to_vec())).unwrap();
    writeln!(s, "\tlive_orientations = {{ {} }},", list(default_live_body_orientations().map(q).to_vec())).unwrap();
    writeln!(s, "\ttruck_frames = {{ {} }},", list(default_truck_drive_frames().map(frames).to_vec())).unwrap();
    writeln!(s, "\twheel_frames = {{ {} }},", list(default_wheel_drive_frames().map(frames).to_vec())).unwrap();
    let records = authored_body_pose_records(AuthoredTransformInputs::STOCK);
    writeln!(s, "\tpose_records = {{ {} }},", list(records.iter().map(|w| format!("{{ {} }}", list(w.iter().map(|x| x.to_string()).collect()))).collect())).unwrap();
    let mut dyns = vec![];
    for (lin, hard) in [(false, false), (false, true), (true, false), (true, true)] {
        dyns.push(dynamics(retail_truck_drive_dynamics(RetailTruckDriveSettings { use_linear_drives: lin, use_hard_linear_drives: hard, ..RetailTruckDriveSettings::STOCK })));
    }
    dyns.push(dynamics(retail_wheel_drive_dynamics(true)));
    dyns.push(dynamics(retail_wheel_drive_dynamics(false)));
    writeln!(s, "\tdynamics = {{ {} }},", list(dyns)).unwrap();
    s.push_str("\tquaternion = {\n");
    for i in 0..4000 {
        let m = if i % 50 == 0 {
            Basis3 { columns: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]] }
        } else if i % 7 == 0 {
            // произвольная (не ортонормированная) матрица — все ветки выбора
            let a = r.vec(1.0); let c = r.vec(1.0); let d = r.vec(1.0);
            Basis3 { columns: [[a.x, a.y, a.z], [c.x, c.y, c.z], [d.x, d.y, d.z]] }
        } else {
            rand_basis(&mut r)
        };
        writeln!(s, "\t\t{{ {}, {} }},", basis(m), q(retail_quaternion_from_basis(m))).unwrap();
    }
    s.push_str("\t},\n\tset_frames = {\n");
    for _ in 0..1500 {
        let p = RetailAffineTransform { basis: rand_basis(&mut r), translation: r.vec(3.0) };
        let c = RetailAffineTransform { basis: rand_basis(&mut r), translation: r.vec(3.0) };
        writeln!(s, "\t\t{{ {}, {}, {} }},", aff(p), aff(c), frames(set_drive_frames_2(p, c))).unwrap();
    }
    s.push_str("\t},\n\ttruck_inputs = {\n");
    for _ in 0..500 {
        let i = RetailTruckTransformInputs {
            deck_mid_length: r.range(0.3, 0.8),
            truck_z_position_front: r.range(-0.1, 0.1),
            truck_z_position_back: r.range(-0.1, 0.1),
            truck_y_position: r.range(-0.1, 0.0),
            truck_rotation_axis_angle_degrees: r.range(0.0, 60.0),
        };
        let t = calculate_truck_transforms(i);
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {}, {} }}, {}, {} }},", b(i.deck_mid_length), b(i.truck_z_position_front), b(i.truck_z_position_back), b(i.truck_y_position), b(i.truck_rotation_axis_angle_degrees), aff(t[0]), aff(t[1])).unwrap();
    }
    s.push_str("\t},\n\tauthored = {\n");
    for _ in 0..300 {
        let i = AuthoredTransformInputs {
            deck_mid_length: r.range(0.3, 0.8),
            wheel_x_distance: r.range(0.05, 0.15),
            truck_z_position_front: r.range(-0.1, 0.1),
            truck_z_position_back: r.range(-0.1, 0.1),
            truck_y_position: r.range(-0.1, 0.0),
        };
        writeln!(s, "\t\t{{ {{ {}, {}, {}, {}, {} }}, {{ {} }} }},", b(i.deck_mid_length), b(i.wheel_x_distance), b(i.truck_z_position_front), b(i.truck_z_position_back), b(i.truck_y_position), list(authored_body_transforms(i).map(aff).to_vec())).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/drive.luau"), s).unwrap();
}
