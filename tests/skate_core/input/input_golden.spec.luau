--!strict
-- Сверка skate_core/input с настоящим skate-core (golden/src/input.rs):
-- контроллер по сценариям и все производители намерений, Pad, xbox,
-- история, жесты, graph_intents, turn_remap, set_turning, turn_conditioner,
-- power_sliding, body_flip_signal, animation_packet.

local harness = require("../../harness")
local u = require("../../util")
local input = require("../../../src/skate_core/input")
local golden = require("../../golden/input") :: any

local rt = require("../../../src/rt")
local rt_f = rt.from_bits
local controller = input.controller
local gameplay_map = input.gameplay_map
local GameplayActions = gameplay_map.GameplayActions
local Derived = controller.DerivedControllerInput
local Raw = controller.RawControllerInput

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end

-- Тот же Recorder, что в эталоне: пишет порядок вызовов карты действий.
local function recorder(values: { number }): any
	local actions = GameplayActions.from_values(values)
	local self = { calls = {} }
	function self:value(a: number): number
		local v = GameplayActions.value(actions, a)
		table.insert(self.calls, { a, v })
		return v
	end
	function self:state(a: number): number
		local v = GameplayActions.state(actions, a)
		table.insert(self.calls, { a + 1000, v })
		return v
	end
	return self
end

return function(report: harness.Report)
	harness.test(report, "input/angle: atan 2000 значений vs Rust", function()
		for i, c in golden.atan do
			check(u.diff(input.angle.atan(c[1]), c[2]), "atan #" .. i)
		end
	end)

	harness.test(report, "rt.atan2f: 5072 пар vs Rust f32::atan2", function()
		for i, c in golden.atan2 do
			check(u.diff(rt.atan2f(c[1], c[2]), c[3]), "atan2 #" .. i)
		end
	end)

	harness.test(report, "input/controller: 25 сценариев × 40 тиков, Derived + все намерения vs Rust", function()
		for si, sc in golden.controller do
			local c = Derived.from_words(sc.init_words)
			if sc.initialize then
				Derived.initialize(c)
			end
			for ti, t in sc.ticks do
				local at = string.format("сценарий %d тик %d", si, ti)
				local rec = recorder(t.values)
				Derived.update(c, rec, t.dt, t.s502, t.s104, { attribute = t.attribute, missing_attribute_value = t.missing })
				check(u.diff(rec.calls, t.calls), at .. " calls")
				check(u.diff(c.words, t.words), at .. " words")
				local prefs = { automatic_push_enabled = t.auto, automatic_push_right = t.auto_right }
				check(u.diff(input.riding_intentions.produce(c, t.actor, prefs), t.riding), at .. " riding")
				check(u.diff(input.trick_intentions.produce(c), t.trick), at .. " trick")
				check(u.diff(input.manual_intentions.produce(c, t.actor), t.manual), at .. " manual")
				check(u.diff(input.grind_intentions.produce(c), t.grind), at .. " grind")
				check(u.diff(input.wipeout_intentions.produce(c, t.actor, t.phys), t.wipeout), at .. " wipeout")
				check(u.diff(input.anticipation_intentions.produce(c), t.antic), at .. " antic")
				check(u.diff(input.gameplay_gestures.produce(c), t.gestures), at .. " gestures")
				check(u.diff(input.offboard_intentions.produce_discrete(c, t.actor, t.air), t.off_d), at .. " off_d")
				local obs = { effective_skeleton_z = t.obs_z, biped_correction = t.obs_c }
				check(u.diff(input.offboard_intentions.produce_analog(c, obs), t.off_a), at .. " off_a")
				local steer = input.steering_intentions.produce({ rt_f(c.words[8]), rt_f(c.words[9]) }, t.actor)
				check(u.diff(steer, t.steer), at .. " steer")
				-- ROBLOX: Option nil в эталоне не видно в diff; проверяем отсутствие явно.
				for _, k in { "turn", "hard_turn", "hard_turn_crouch" } do
					if (steer :: any)[k] ~= nil and t.steer[k] == nil then
						error(at .. " steer." .. k .. " должен быть nil")
					end
				end
			end
		end
	end)

	harness.test(report, "input/controller: RawControllerInput.update 300 случаев vs Rust", function()
		for i, c in golden.raw do
			local cur = Raw.from_words(c.start)
			Raw.update(cur, Raw.from_words(c.previous), GameplayActions.as_map(GameplayActions.from_values(c.values)), c.s502, c.s104)
			check(u.diff(cur.words, c.out), "raw #" .. i)
		end
	end)

	harness.test(report, "input/pad: 10 × 80 обновлений и from_pad vs Rust", function()
		for si, steps in golden.pad do
			local p = input.pad.Pad.new()
			for ti, st in steps do
				input.pad.Pad.update(p, st.values)
				local at = string.format("pad %d шаг %d", si, ti)
				assert(p.count == st.count, at .. " count")
				check(u.diff(p.records, st.records), at .. " records")
				if st.actions then
					check(u.diff(GameplayActions.from_pad(p).values, st.actions), at .. " actions")
				end
			end
		end
	end)

	harness.test(report, "input/xbox: convert 400 состояний vs Rust", function()
		for i, c in golden.xbox do
			local out = input.xbox.convert({ buttons = c.buttons, triggers = c.triggers, left = c.left, right = c.right }, c.dev)
			check(u.diff(out, c.out), "xbox #" .. i)
		end
	end)

	harness.test(report, "input/history: 6 × 70 операций publish/drain vs Rust", function()
		local history = input.history
		for si, ops in golden.history do
			local h = history.PadHistory.new()
			local pads = { input.pad.Pad.new(), input.pad.Pad.new(), input.pad.Pad.new(), input.pad.Pad.new() }
			for oi, op in ops do
				local at = string.format("history %d op %d", si, oi)
				if op.op == "publish" then
					local recs = {}
					for k, values in op.records do
						local r = history.HistoryRecord.new(values)
						if op.clear[k] then
							history.HistoryRecord.clear_count(r)
						end
						recs[k] = r
					end
					history.PadHistory.publish(h, recs)
				else
					assert(history.PadHistory.drain_to_latest(h, pads) == op.ok, at .. " ok")
					for k, p in pads do
						assert(p.count == op.pads[k].count, at .. " count")
						check(u.diff(p.records, op.pads[k].records), at .. " pad " .. k)
					end
				end
				assert(h.read == op.read and h.write == op.write, at .. " индексы")
			end
		end
	end)

	harness.test(report, "input/gesture: 24 распознавателя × 120 сэмплов vs Rust", function()
		local Recognizer = input.gesture.Recognizer
		for si, sc in golden.gesture do
			local g = Recognizer.new(sc.patterns)
			local settings = { maximum_misses = sc.misses, difficulty = sc.difficulty }
			for ti, st in sc.steps do
				local at = string.format("gesture %d шаг %d", si, ti)
				local held = Recognizer.held(g, st.sample)
				assert(held == st.held, at .. " held")
				local rec = Recognizer.sample(g, st.sample, settings)
				assert((rec == nil) == (st.rec == nil), at .. " rec presence")
				if rec then
					check(u.diff(rec, st.rec), at .. " rec")
				end
			end
		end
	end)

	harness.test(report, "input/graph_intents: фильтры, цепочки, CreateMgIntent vs Rust", function()
		local gi = input.graph_intents
		for i, c in golden.filters do
			check(u.diff(gi.apply_filter(c[1], c[2]), c[3]), "filter #" .. i)
		end
		for i, c in golden.chains do
			check(u.diff(gi.filter_chain(c.value, c.filters, c.stance), c.out), "chain #" .. i)
		end
		for i, c in golden.mg do
			local mg = { on_update = c.on_update, default_value = c.default_value, scale = c.scale, filters = c.filters }
			local created = { value = c.start }
			for k, st in c.steps do
				local out
				if st.op == "enter" then
					out = gi.CreateMgIntent.enter(mg, created, st.action, st.stance)
				elseif st.op == "exit" then
					out = gi.CreateMgIntent.exit(mg)
				else
					out = gi.CreateMgIntent.update(mg, created, st.action, st.stance)
				end
				check(u.diff(out, st.out), string.format("mg %d шаг %d ", i, k))
				assert(created.value == st.created, "created")
			end
		end
	end)

	harness.test(report, "input/turn_remap: 10 × 60 vs Rust", function()
		for i, c in golden.remap do
			for k, case in c.cases do
				check(u.diff(input.turn_remap.TurnRemap.apply(c.remap, case.input), case.out), string.format("remap %d/%d", i, k))
			end
		end
	end)

	harness.test(report, "input/set_turning: 12 × 40 тиков vs Rust", function()
		local st_mod = input.set_turning
		for i, c in golden.set_turning do
			local state = table.clone(c.state)
			for k, st in c.steps do
				local latch = st_mod.SlideLatch.from_words(st.latch_in)
				local emitted = {}
				st_mod.update(state, latch, st.physical, st.stance, st.dt, c.settings, st.intents, function(a, v)
					table.insert(emitted, { a, v })
				end)
				local at = string.format("set_turning %d тик %d", i, k)
				check(u.diff(emitted, st.emitted), at .. " emitted")
				check(u.diff(latch.words, st.latch), at .. " latch")
				check(u.diff(state, st.state), at .. " state")
			end
		end
	end)

	harness.test(report, "input/turn_conditioner: 12 × 50 vs Rust", function()
		local tc = input.turn_conditioner
		for i, c in golden.conditioner do
			local state = { history = table.clone(c.state.history), filters = { table.clone(c.state.filters[1]), table.clone(c.state.filters[2]), table.clone(c.state.filters[3]) } }
			for k, st in c.steps do
				local at = string.format("conditioner %d шаг %d", i, k)
				if st.reset then
					tc.State.reset_history(state)
				else
					check(u.diff(tc.update(state, st.input, c.settings), st.out), at .. " out")
				end
				check(u.diff(state.history, st.history), at .. " history")
				check(u.diff(state.filters, st.filters), at .. " filters")
			end
		end
	end)

	harness.test(report, "input/power_sliding: 12 × 50 + alignment 300 vs Rust", function()
		local ps = input.power_sliding
		for i, c in golden.power do
			local state = table.clone(c.state)
			local latch = table.clone(c.latch)
			for k, st in c.steps do
				local ci = 0
				ps.update(state, latch, st.input, c.settings, function()
					ci += 1
					return st.clocks[ci]
				end)
				local at = string.format("power %d шаг %d", i, k)
				assert(ci == st.calls, at .. " clock calls")
				check(u.diff(latch, st.latch), at .. " latch")
				check(u.diff(state, st.state), at .. " state")
			end
		end
		for i, c in golden.alignment do
			check(u.diff(ps.alignment(c.input), c.out), "alignment #" .. i)
		end
	end)

	harness.test(report, "input/body_flip_signal: 12 × 50 vs Rust", function()
		local State = input.body_flip_signal.State
		for i, c in golden.body_flip do
			local settings = { gesture_window = c.gesture_window, takeoff_window = c.takeoff_window }
			local st = State.default()
			if c.begin then
				State.begin(st, settings)
			end
			for k, step in c.steps do
				if step.begin then
					State.begin(st, settings)
				else
					assert(State.update(st, step.present, step.category, step.dt, settings) == step.out, string.format("body_flip %d шаг %d", i, k))
				end
			end
		end
	end)

	harness.test(report, "input/animation_packet: publish 100 vs Rust", function()
		for i, c in golden.packet do
			local out = { flags_2468 = c.flags_2468, flags_2476 = c.flags_2476, timestep = 0, scalar_2668 = 0, vector_1520 = { 0, 0, 0, 0 }, matrix_1536 = {}, byte_1600 = 0, truck_tightness = 0, scalar_2764 = 0 }
			input.animation_packet.publish(c.source, out :: any)
			check(u.diff(out, c.out), "packet #" .. i)
		end
	end)
end
