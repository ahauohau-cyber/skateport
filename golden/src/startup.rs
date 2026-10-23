//! Эталон для physics::startup (reset_collision_info, reset_board_body,
//! reset_skateboard). Синтетические байты — файл можно коммитить.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::physics::board_pose::PartPose;
use skate_core::physics::startup::{reset_board_body, reset_collision_info, reset_skateboard};
use std::fmt::Write as _;

fn hex(b: &[u8]) -> String { b.iter().map(|x| format!("{:02x}", x)).collect() }
fn bytes<const N: usize>(r: &mut Rng) -> [u8; N] { std::array::from_fn(|_| (r.next() & 0xff) as u8) }
fn fbits(r: &mut Rng, span: f32) -> u32 { r.range(-span, span).to_bits() }
fn frame(r: &mut Rng) -> [u32; 16] {
    let q = { let v = r.vec(1.0); let w = r.range(-1.0, 1.0); let l = (v.x * v.x + v.y * v.y + v.z * v.z + w * w).sqrt(); [v.x / l, v.y / l, v.z / l, w / l] };
    let [x, y, z, w] = q;
    let m = [
        [1.0 - 2.0 * (y * y + z * z), 2.0 * (x * y + z * w), 2.0 * (x * z - y * w), 0.0],
        [2.0 * (x * y - z * w), 1.0 - 2.0 * (x * x + z * z), 2.0 * (y * z + x * w), 0.0],
        [2.0 * (x * z + y * w), 2.0 * (y * z - x * w), 1.0 - 2.0 * (x * x + y * y), 0.0],
        [r.range(-3.0, 3.0), r.range(-3.0, 3.0), r.range(-3.0, 3.0), 1.0],
    ];
    std::array::from_fn(|i| (m[i / 4][i % 4] as f32).to_bits())
}
fn body(r: &mut Rng) -> [u32; 44] { std::array::from_fn(|_| fbits(r, 5.0)) }
fn part(r: &mut Rng) -> PartPose {
    PartPose { transform: frame(r), local_mass_frame: if r.bool() { Some(frame(r)) } else { None }, body: Some(body(r)),
        inertia: if r.bool() { Some(std::array::from_fn(|_| r.range(0.1, 2.0).to_bits())) } else { None } }
}
fn part_l(p: &PartPose) -> Raw {
    Raw(obj!(transform = p.transform, local_mass_frame = p.local_mass_frame, body = p.body, inertia = p.inertia))
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x5747_0a11);
    let mut s = format!("-- Сгенерировано golden/src/startup.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n\tcollision = {{\n");
    for _ in 0..20 {
        let mut info: [u8; 812] = bytes(&mut r);
        let before = hex(&info);
        reset_collision_info(&mut info);
        writeln!(s, "\t\t{{ before = {:?}, after = {:?} }},", before, hex(&info)).unwrap();
    }
    s.push_str("\t},\n\tbody = {\n");
    for _ in 0..12 {
        let mut board: [u8; 8400] = bytes(&mut r);
        let n = 1 + (r.next() % 7) as usize;
        let mut bodies: Vec<[u32; 44]> = (0..n).map(|_| body(&mut r)).collect();
        let gravity: Vec<[u32; 4]> = (0..n).map(|_| [fbits(&mut r, 10.0), fbits(&mut r, 10.0), fbits(&mut r, 10.0), fbits(&mut r, 10.0)]).collect();
        let (before, bodies_in) = (hex(&board), bodies.clone());
        let old = reset_board_body(&mut board, &mut bodies, &gravity);
        writeln!(s, "\t\t{},", obj!(before = before, bodies_in = bodies_in, gravity = gravity, after = hex(&board), bodies = bodies, old = old as u32)).unwrap();
    }
    s.push_str("\t},\n\tskateboard = {\n");
    for _ in 0..12 {
        let mut wrapper: [u8; 1360] = bytes(&mut r);
        let mut body_state: [u8; 8400] = bytes(&mut r);
        let base = r.next();
        let mut parts: [PartPose; 7] = std::array::from_fn(|_| part(&mut r));
        let mut hook = part(&mut r);
        let authored: [[u32; 16]; 7] = std::array::from_fn(|_| frame(&mut r));
        let requested = frame(&mut r);
        let flags = if r.bool() { 0x0010_0000 } else { 0 } | (r.next() & 0xff);
        let gravity: [[u32; 4]; 7] = std::array::from_fn(|_| [fbits(&mut r, 10.0), fbits(&mut r, 10.0), fbits(&mut r, 10.0), 0]);
        let (wb, bb) = (hex(&wrapper), hex(&body_state));
        let parts_in: Vec<Raw> = parts.iter().map(part_l).collect();
        let hook_in = part_l(&hook);
        let out = reset_skateboard(&mut wrapper, base, &mut body_state, &mut parts, &mut hook, authored, requested, flags, &gravity);
        writeln!(s, "\t\t{},", obj!(wrapper_before = wb, body_before = bb, base = base, parts_in = parts_in, hook_in = hook_in, authored = authored, requested = requested,
            flags = flags, gravity = gravity, out = out, wrapper_after = hex(&wrapper), body_after = hex(&body_state),
            parts = parts.iter().map(part_l).collect::<Vec<_>>(), hook = part_l(&hook))).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/startup.luau"), s).unwrap();
}
