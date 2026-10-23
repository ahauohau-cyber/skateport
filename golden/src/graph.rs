//! Эталон для skate_core::graph: случайные графы (топология, выражения,
//! условия, поведения, хуки) прогоняются Controller::update с
//! детерминированным хостом, который пишет журнал вызовов. Плюс
//! NumericCondition и DisablePushBrake.
use crate::collision::Rng;
use crate::lua::{L, Raw, HEADER};
use crate::obj;
use skate_core::graph::activation::{ActivationProgram, Child, Condition, ConditionHost, ConditionId, Expression};
use skate_core::graph::conditions::{Comparison, NumericCondition, PushBrakeInputs};
use skate_core::graph::controller::{Behavior, BehaviorId, Controller, Frame, Host, HookId, Program};
use skate_core::graph::selection::{State, Topology, Transition};
use std::fmt::Write as _;

struct LogHost<'a> { values: &'a [u32], log: Vec<String>, next_instance: u32 }
impl ConditionHost for LogHost<'_> {
    fn condition_activation(&mut self, c: ConditionId, _: &Frame) -> u32 { self.log.push(format!("cond:{c}")); self.values[c] }
}
impl Host for LogHost<'_> {
    fn context(&self) -> [u32; 6] { [1, 2, 0, 4, 5, 6] }
    fn allocate(&mut self, b: BehaviorId, f: &Frame) -> u32 { self.next_instance += 1; self.log.push(format!("alloc:{b}:{}", f.current.map_or(-1, |x| x as i64))); self.next_instance }
    fn begin(&mut self, b: BehaviorId, c: [u32; 6], _: &Frame) { self.log.push(format!("begin:{b}:{}:{}", c[2], c[5])); }
    fn update(&mut self, b: BehaviorId, c: [u32; 6], _: &Frame) { self.log.push(format!("update:{b}:{}", c[2])); }
    fn end(&mut self, b: BehaviorId, c: [u32; 6], _: &Frame) { self.log.push(format!("end:{b}:{}", c[2])); }
    fn hook(&mut self, h: HookId, _: &Frame) { self.log.push(format!("hook:{h}")); }
    fn release(&mut self, i: u32) { self.log.push(format!("release:{i}")); }
}

fn opt(x: Option<usize>) -> Raw { Raw(match x { Some(v) => v.to_string(), None => "false".into() }) }

fn program(r: &mut Rng) -> Program {
    let n = 6 + (r.next() % 20) as usize;
    let mut states: Vec<State> = Vec::new();
    for i in 0..n {
        let parent = if i == 0 { None } else { Some((r.next() as usize) % i) };
        states.push(State { parent, enabled: r.next() % 8 != 0, active: r.next() % 8 != 0, interruptibility: r.next() % 4 % 3, interrupt_ancestor: None, children: Vec::new(), transitions: Vec::new() });
    }
    states[0].enabled = true; states[0].active = true;
    for i in 1..n { let p = states[i].parent.unwrap(); states[p].children.push(i); }
    for i in 0..n {
        if states[i].interruptibility == 2 {
            let mut chain = vec![i]; let mut c = states[i].parent; while let Some(p) = c { chain.push(p); c = states[p].parent; }
            states[i].interrupt_ancestor = Some(chain[(r.next() as usize) % chain.len()]);
        }
    }
    let nt = (r.next() % (2 * n as u32)) as usize;
    let mut transitions = Vec::new();
    for id in 0..nt {
        let from = (r.next() as usize) % n;
        transitions.push(Transition { enabled: r.next() % 6 != 0, target: (r.next() as usize) % n, priority: r.next() % 4 });
        states[from].transitions.push(id);
    }
    let nc = 4 + (r.next() % 12) as usize;
    let conditions: Vec<Condition> = (0..nc).map(|_| Condition { enabled: r.next() % 6 != 0, mask: r.next() % 4 }).collect();
    let mut expressions: Vec<Expression> = Vec::new();
    let ne = 3 + (r.next() % 10) as usize;
    for e in 0..ne {
        let operator = [1, 1, 2, 2, 3, 0, 5][(r.next() % 7) as usize];
        let k = if operator == 3 { 1 + (r.next() % 2) as usize } else { (r.next() % 4) as usize };
        let children = (0..k).map(|_| if e > 0 && r.next() % 3 == 0 { Child::Expression((r.next() as usize) % e) } else { Child::Condition((r.next() as usize) % nc) }).collect();
        expressions.push(Expression { operator, children });
    }
    let pick = |r: &mut Rng| if r.next() % 3 == 0 { None } else { Some((r.next() as usize) % ne) };
    let state_expressions = (0..n).map(|_| pick(r)).collect();
    let transition_expressions = (0..nt).map(|_| pick(r)).collect();
    let nb = (r.next() % (2 * n as u32)) as usize;
    let behaviors: Vec<Behavior> = (0..nb).map(|_| Behavior { owner: (r.next() as usize) % n, enabled: r.next() % 5 != 0 }).collect();
    let mut state_behaviors = vec![Vec::new(); n];
    for (b, beh) in behaviors.iter().enumerate() { state_behaviors[beh.owner].push(b); }
    let transition_hooks = (0..nt).map(|_| (0..(r.next() % 3)).map(|_| (r.next() % 50) as usize).collect()).collect();
    Program { topology: Topology { states, transitions }, root: 0, activation: ActivationProgram { state_expressions, transition_expressions, expressions, conditions }, behaviors, state_behaviors, transition_hooks }
}

fn program_l(p: &Program) -> String {
    let states: Vec<Raw> = p.topology.states.iter().map(|s| Raw(obj!(parent = s.parent, enabled = s.enabled, active = s.active, interruptibility = s.interruptibility, interrupt_ancestor = s.interrupt_ancestor, children = s.children.clone(), transitions = s.transitions.clone()))).collect();
    let transitions: Vec<Raw> = p.topology.transitions.iter().map(|t| Raw(obj!(enabled = t.enabled, target = t.target, priority = t.priority))).collect();
    let expressions: Vec<Raw> = p.activation.expressions.iter().map(|e| Raw(obj!(operator = e.operator, children = e.children.iter().map(|c| Raw(match c { Child::Expression(i) => format!("{{ kind = \"Expression\", id = {i} }}"), Child::Condition(i) => format!("{{ kind = \"Condition\", id = {i} }}") })).collect::<Vec<_>>()))).collect();
    let conditions: Vec<Raw> = p.activation.conditions.iter().map(|c| Raw(obj!(enabled = c.enabled, mask = c.mask))).collect();
    let behaviors: Vec<Raw> = p.behaviors.iter().map(|b| Raw(obj!(owner = b.owner, enabled = b.enabled))).collect();
    let se: Vec<Raw> = p.activation.state_expressions.iter().map(|x| opt(*x)).collect();
    let te: Vec<Raw> = p.activation.transition_expressions.iter().map(|x| opt(*x)).collect();
    obj!(topology = Raw(obj!(states = states, transitions = transitions)), root = p.root,
        activation = Raw(obj!(state_expressions = se, transition_expressions = te, expressions = expressions, conditions = conditions)),
        behaviors = behaviors, state_behaviors = p.state_behaviors.clone(), transition_hooks = p.transition_hooks.clone())
}

pub fn write(out_dir: &str) {
    let mut r = Rng(0x6a4f_0003);
    let mut s = format!("-- Сгенерировано golden/src/graph.rs из настоящего skate-core. Не править.\n{HEADER}return {{\n\tcontroller = {{\n");
    for _ in 0..60 {
        let p = program(&mut r);
        let mut c = Controller::new(p.topology.states.len());
        let mut ticks = Vec::new();
        let mut instance = 0;
        for k in 0..30 {
            let values: Vec<u32> = (0..p.activation.conditions.len()).map(|_| [0, 1, 1, 2, 256, 257][(r.next() % 6) as usize]).collect();
            let dt = if r.bool() { 1.0 / 60.0 } else { r.range(0.0, 0.1) };
            let mut host = LogHost { values: &values, log: Vec::new(), next_instance: instance };
            if k == 29 && r.bool() { c.end_all_behaviors(&mut host); instance = host.next_instance;
                ticks.push(obj!(end_all = true, log = host.log, active = c.active.iter().map(|a| [a.behavior as u32, a.instance]).collect::<Vec<_>>()));
                continue; }
            c.update(&p, dt, &mut host);
            instance = host.next_instance;
            let times: Vec<Raw> = c.frame.state_times.iter().map(|t| Raw(match t { Some(v) => v.l(), None => "false".into() })).collect();
            ticks.push(obj!(values = values, dt = dt, log = host.log, current = c.frame.current, last = c.frame.last, state_times = times,
                active = c.active.iter().map(|a| [a.behavior as u32, a.instance]).collect::<Vec<_>>()));
        }
        writeln!(s, "\t\t{{ program = {}, ticks = {{\n\t\t\t{}\n\t\t}} }},", program_l(&p), ticks.join(",\n\t\t\t")).unwrap();
    }
    s.push_str("\t},\n\tnumeric = {\n");
    let comps = [Comparison::None, Comparison::Equal, Comparison::NotEqual, Comparison::Greater, Comparison::Less, Comparison::GreaterEqual, Comparison::LessEqual, Comparison::GreaterAbsolute];
    for _ in 0..600 {
        let c = comps[(r.next() % 8) as usize];
        let n = NumericCondition { comparison: c, threshold: if r.bool() { 0.5 } else { r.range(-2.0, 2.0) }, absolute: r.bool() };
        let v = [f32::NAN, 0.5, -0.5, 0.0, -0.0, r.range(-3.0, 3.0)][(r.next() % 6) as usize];
        writeln!(s, "\t\t{},", obj!(comparison = format!("{c:?}"), threshold = n.threshold, absolute = n.absolute, value = v, out = n.matches(v))).unwrap();
    }
    s.push_str("\t},\n\tpush_brake = {\n");
    for _ in 0..600 {
        let p = PushBrakeInputs { ground_axis_y: r.range(-1.0, 1.0), skeleton_disables_push_brake: r.next() % 8 == 0, maximum_ground_angle_degrees: r.range(0.0, 90.0) };
        writeln!(s, "\t\t{},", obj!(ground_axis_y = p.ground_axis_y, skeleton_disables_push_brake = p.skeleton_disables_push_brake, maximum_ground_angle_degrees = p.maximum_ground_angle_degrees, out = p.disabled())).unwrap();
    }
    s.push_str("\t},\n}\n");
    std::fs::write(format!("{out_dir}/graph.luau"), s).unwrap();
}
