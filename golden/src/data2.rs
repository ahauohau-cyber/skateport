//! Эталон для skate-data: state_graph (+ binding, attributes), animation_banks,
//! animation_metadata, animation_frames, physics_skeleton, gesture_patterns,
//! input_config, manifest. Всё на настоящих файлах установки.
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_data::{
    animation_banks::AnimationBanks,
    animation_frames::AnimationFrames,
    animation_metadata::TreeMetadata,
    gesture_patterns,
    input_config::StockGameplayConfig,
    physics_skeleton::PhysicsSkeleton,
    state_graph::{
        attributes::{byte_hash, key_hash},
        binding::{name_hash, Binding, Node, OperationKind},
        StateGraph,
    },
    GameAssets,
};
use std::fmt::Write as _;
use std::path::Path;

fn node_l(n: Node) -> Raw {
    Raw(match n {
        Node::State(i) => obj!(kind = "State", id = i),
        Node::Transition(i) => obj!(kind = "Transition", id = i),
        Node::Expression(i) => obj!(kind = "Expression", id = i),
        Node::Operation(i) => obj!(kind = "Operation", id = i),
    })
}
fn kind_s(k: OperationKind) -> &'static str { match k { OperationKind::Behavior => "Behavior", OperationKind::Condition => "Condition", OperationKind::Hook => "Hook" } }

pub fn write(out_dir: &str, asset_root: &str) {
    let root = Path::new(asset_root);
    let mut s = format!("-- Сгенерировано golden/src/data2.rs из настоящего skate-data. Не править.\n{HEADER}return {{\n");

    // --- state graphs
    s.push_str("\tgraphs = {\n");
    for name in ["ActionGraph_OnBoard", "MotionGraph_OnBoard"] {
        let rel = format!("stock/data/state/{name}.stategraph");
        let graph = StateGraph::load(&root.join("private").join(&rel)).unwrap();
        let elements: Vec<Raw> = graph.elements.iter().map(|e| Raw(obj!(source_offset = e.source_offset, tag = e.tag.clone(),
            attributes = e.attributes.iter().map(|a| Raw(obj!(name = a.name.clone(), text = a.text.clone(), float_bits = a.float_bits, boolean_byte = a.boolean_byte))).collect::<Vec<_>>(),
            children = e.children.clone()))).collect();
        let b = Binding::from_graph(&graph).unwrap();
        let states: Vec<Raw> = b.states.iter().map(|x| Raw(obj!(element = x.element, name = x.name.clone(), parent = x.parent, children = x.children.clone(), behaviors = x.behaviors.clone(),
            transitions = x.transitions.clone(), expression = x.expression, enabled = x.enabled, active = x.active, interruptibility = x.interruptibility, interrupt_ancestor = x.interrupt_ancestor))).collect();
        let transitions: Vec<Raw> = b.transitions.iter().map(|x| Raw(obj!(element = x.element, owner = x.owner, target = x.target, enabled = x.enabled, priority = x.priority, expression = x.expression, hooks = x.hooks.clone()))).collect();
        let expressions: Vec<Raw> = b.expressions.iter().map(|x| Raw(obj!(element = x.element, enabled = x.enabled, operator = x.operator, children = x.children.iter().map(|n| node_l(*n)).collect::<Vec<_>>()))).collect();
        let operations: Vec<Raw> = b.operations.iter().map(|x| Raw(obj!(element = x.element, parent = node_l(x.parent), kind = kind_s(x.kind), name = x.name.clone(), enabled = x.enabled, condition_mask = x.condition_mask, parameters = x.parameters.clone()))).collect();
        // Хеши всех строк графа.
        let mut texts: Vec<String> = Vec::new();
        for e in &graph.elements { texts.push(e.tag.clone()); for a in &e.attributes { texts.push(a.name.clone()); texts.push(a.text.clone()); } }
        texts.sort(); texts.dedup();
        let hashes: Vec<Raw> = texts.iter().map(|t| Raw(obj!(text = t.clone(), key = key_hash(t), byte = byte_hash(t.as_bytes()), name = name_hash(t)))).collect();
        // find_state по всем именам от нескольких стартов.
        let mut finds = Vec::new();
        for start in (0..b.states.len()).step_by(37) {
            for (k, st) in b.states.iter().enumerate().step_by(53) {
                let path = if k % 2 == 0 { st.name.clone() } else { format!("{}.{}", b.states[st.parent.unwrap_or(0)].name, st.name) };
                finds.push(obj!(start = start, name = path.clone(), ascend = k % 3 != 0, out = b.find_state(start, &path, k % 3 != 0)));
            }
        }
        writeln!(s, "\t\t[{:?}] = {{ path = {:?}, elements = {}, binding = {}, hashes = {}, finds = {{ {} }} }},", name, rel, elements.l(),
            obj!(states = states, transitions = transitions, expressions = expressions, operations = operations, root = b.root), hashes.l(), finds.join(", ")).unwrap();
    }
    s.push_str("\t},\n");

    // --- banks / metadata
    let banks = AnimationBanks::load(root).unwrap();
    let metadata = banks.metadata().unwrap();
    writeln!(s, "\tidentities = {},\n\tclip_count = {},", banks.identities.l(), metadata.clip_count()).unwrap();
    s.push_str("\tsources = {\n");
    for src in metadata.sources() {
        writeln!(s, "\t\t{},", obj!(source_bank = src.source_bank.clone(), source_sha256 = src.source_sha256.clone(), source_bytes = src.source_bytes)).unwrap();
    }
    s.push_str("\t},\n\ttrees = {\n");
    // Все имена записей обоих банков.
    let mut names: Vec<String> = Vec::new();
    for bank in &banks.banks { for r in bank.records() { names.push(r.header.name.clone()); } }
    names.sort(); names.dedup();
    for name in &names {
        let tree = match metadata.tree(name) {
            Ok(TreeMetadata::Clip(c)) => obj!(kind = "Clip", name = c.name.clone(), offset = c.source_offset, fps_bits = c.fps_bits, frames_bits = c.frames_bits, base_speed_bits = c.base_speed_bits, flags_word = c.flags_word,
                attributes = c.attributes.iter().map(|a| Raw(obj!(name = a.name.clone(), type_id = a.type_id, begin_bits = a.begin_bits, end_bits = a.end_bits, payload_words = a.payload_words.clone(), source_offset = a.source_offset))).collect::<Vec<_>>()),
            Ok(TreeMetadata::PhaseBlend(t)) => obj!(kind = "PhaseBlend", name = t.name.clone(), offset = t.source_offset, parameter = t.parameter.clone(), children = t.children.clone()),
            Ok(TreeMetadata::BlendSpace(t)) => obj!(kind = "BlendSpace", name = t.name.clone(), offset = t.source_offset, parameters = t.parameters.clone(), children = t.children.clone(),
                simplexes = t.simplexes.iter().map(|x| Raw(obj!(children = x.children.clone(), vertex_bits = x.vertex_bits.clone(), normal_bits = x.normal_bits.clone(), scale_bits = x.scale_bits.clone()))).collect::<Vec<_>>()),
            Ok(TreeMetadata::Selector(t)) => obj!(kind = "Selector", name = t.name.clone(), offset = t.source_offset, parameter = t.parameter.clone(), default = t.default.clone(), children = t.children.clone(), values = t.values.clone()),
            Ok(TreeMetadata::SelectionSpace(t)) => obj!(kind = "SelectionSpace", name = t.name.clone(), offset = t.source_offset,
                parameters = t.parameters.iter().map(|p| Raw(obj!(name = p.name.clone(), mode = p.mode, weight_bits = p.weight_bits, minimum_bits = p.minimum_bits, maximum_bits = p.maximum_bits))).collect::<Vec<_>>(),
                candidates = t.candidates.iter().map(|c| Raw(obj!(child = c.child.clone(), value_bits = c.value_bits.clone()))).collect::<Vec<_>>()),
            Err(e) => obj!(err = e),
        };
        let src = metadata.source_for(name).map(|x| x.source_bank.clone());
        writeln!(s, "\t\t[{:?}] = {{ tree = {}, source = {} }},", name, tree, src.l()).unwrap();
    }
    s.push_str("\t},\n");

    // --- frames
    let frames = AnimationFrames::from_banks(&banks).unwrap();
    let clip_names: Vec<String> = frames.clip_names().map(str::to_owned).collect();
    writeln!(s, "\tframes = {{ parents = {}, bone_names = {}, mirror_indices = {}, has_trajectory = {}, clip_count = {}, clip_names = {} }},",
        frames.parents.l(), frames.bone_names.l(), frames.mirror_indices.l(), frames.has_trajectory, frames.clip_count(), clip_names.l()).unwrap();
    s.push_str("\tclips = {\n");
    for name in clip_names.iter().step_by(97) {
        let c = frames.clip(name).unwrap();
        writeln!(s, "\t\t[{:?}] = {},", name, obj!(name = c.name.clone(), source_offset = c.source_offset, fps_bits = c.fps_bits, loop_translation_bits = c.loop_translation_bits,
            loop_rotation_bits = c.loop_rotation_bits, channel_animation = c.channel_animation, channel_weights = c.channel_weights.clone(), frames = c.frames.clone(), bank = frames.clip_bank(name).unwrap())).unwrap();
    }
    s.push_str("\t},\n\tposes = {\n");
    for bank in 0..2 {
        for pname in ["RIG_TPOSE", "BOARD_BACKWARDS", "BOARD_BACKWARDS_IK", "NOPE"] {
            match frames.named_pose_in(bank, pname) {
                Ok(p) => writeln!(s, "\t\t{},", obj!(bank = bank, name = pname, out = Raw(obj!(name = p.name.clone(), source_offset = p.source_offset, samples = p.samples.clone())))).unwrap(),
                Err(e) => writeln!(s, "\t\t{},", obj!(bank = bank, name = pname, err = e)).unwrap(),
            }
        }
    }
    s.push_str("\t},\n");

    // --- physics skeleton, gestures, input, manifest
    let sk = PhysicsSkeleton::load(&root.join("private/stock/physics-skeletons.json"), &banks.identities[0], "phys_tpose");
    match sk {
        Ok(sk) => writeln!(s, "\tphysics_skeleton = {},", obj!(name = sk.name.clone(), source_offset = sk.source_offset,
            bones = sk.bones.iter().map(|b| Raw(obj!(name = b.name.clone(), source_offset = b.source_offset, words = b.words))).collect::<Vec<_>>())).unwrap(),
        Err(e) => writeln!(s, "\tphysics_skeleton = {},", obj!(err = e)).unwrap(),
    }
    s.push_str("\tgestures = {\n");
    for name in ["skater", "skater_air", "skater_fingerflip", "skater90", "skaterN90", "skaterls", "skaterstep"] {
        let p = gesture_patterns::load(&root.join(format!("private/stock/data/joystick/{name}.pat")));
        match p {
            Ok(p) => writeln!(s, "\t\t[{:?}] = {},", name, p.iter().map(|x| Raw(obj!(name = x.name.clone(), points = x.points.clone(), tolerance_squared = x.tolerance_squared))).collect::<Vec<_>>().l()).unwrap(),
            Err(e) => writeln!(s, "\t\t[{:?}] = {},", name, obj!(err = e)).unwrap(),
        }
    }
    s.push_str("\t},\n");
    writeln!(s, "\tinput_ok = {},", StockGameplayConfig::load(root).is_ok()).unwrap();
    let m = GameAssets::parse(&std::fs::read_to_string(root.join("private/game.json")).unwrap()).unwrap();
    writeln!(s, "\tmanifest = {},", obj!(version = m.version, character_scene = m.character_scene, initial_animation = m.initial_animation, action_graph = m.action_graph, motion_graph = m.motion_graph)).unwrap();
    s.push_str("}\n");
    std::fs::write(format!("{out_dir}/data2.luau"), s).unwrap();
}
