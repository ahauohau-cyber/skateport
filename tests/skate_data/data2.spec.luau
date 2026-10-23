--!strict
-- Сверка skate-data (state_graph, binding, animation_banks, animation_metadata,
-- animation_frames, physics_skeleton, gesture_patterns, input_config, manifest)
-- с настоящим Rust (golden/src/data2.rs) на файлах установки, плюс Rust-тесты
-- gesture_patterns и tests/input_config.rs. Эталон и файлы игры в git не идут.

local harness = require("../harness")
local u = require("../util")
local rt = require("../../src/rt")
local files = require("../../src/skate_data/files")
local state_graph = require("../../src/skate_data/state_graph")
local animation_banks = require("../../src/skate_data/animation_banks")
local animation_frames = require("../../src/skate_data/animation_frames")
local animation_metadata = require("../../src/skate_data/animation_metadata")
local physics_skeleton = require("../../src/skate_data/physics_skeleton")
local gesture_patterns = require("../../src/skate_data/gesture_patterns")
local input_config = require("../../src/skate_data/input_config")
local manifest = require("../../src/skate_data/manifest")
local gameplay_map = require("../../src/skate_core/input/gameplay_map")
local json = require("../../src/skate_data/json")

local StateGraph = state_graph.StateGraph
local Binding = state_graph.binding.Binding
local attributes = state_graph.attributes
local AnimationMetadata = animation_metadata.AnimationMetadata
local AnimationFrames = animation_frames.AnimationFrames

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end

local function load_golden(): any
	local ok, g = pcall(require, "../golden/data2")
	if ok and type(g) == "table" then
		return g
	end
	return nil
end

local function load_files(): boolean
	local ok, src = pcall(require, "../../src/skate_data/stock_files")
	if not ok or type(src) ~= "table" then
		return false
	end
	files.set_source(src)
	return files.exists("stock/data/anim/OnBoard.abin")
end

local function stock_input(): string
	local parts = {}
	for i, name in input_config.BUTTON_NAMES do
		table.insert(parts, string.format("%s = Button%d;\n", name, i - 1))
	end
	for _, action in gameplay_map.ACTIONS do
		table.insert(parts, string.format("%s = %s;\n", action.name, action.expression))
	end
	return table.concat(parts)
end

local function replace(s: string, a: string, b: string): string
	local i, j = string.find(s, a, 1, true)
	if i == nil then
		return s
	end
	return string.sub(s, 1, i - 1) .. b .. string.sub(s, (j :: number) + 1)
end

return function(report: harness.Report)
	harness.test(report, "gesture_patterns: authored_order_and_per_pattern_tolerances_are_preserved", function()
		local p = gesture_patterns.parse("global_tolerance_dist 0.4\nglobal_anticipation_delay 15\npattern Ollie\ntolerance_dist 0.55\ncoord 0 1\ncoord 0 -1\npattern Test\ncoord 1 0\ncoord -1 0")
		check(u.diff(p[1].points, { { 0.0, 1.0 }, { 0.0, -1.0 } }), "points")
		assert(p[1].tolerance_squared == rt.f32(rt.f32(0.55) * rt.f32(0.55)))
		assert(p[2].tolerance_squared == rt.f32(rt.f32(0.4) * rt.f32(0.4)))
		local _, err = rt.catch(gesture_patterns.parse, "global_tolerance_dist 0.4\npattern Broken\ncoord 0 1")
		assert(err ~= nil)
	end)

	harness.test(report, "input_config: accepts_spacing_comments_and_unrelated_menu_expressions", function()
		local source = "// controller mapping\n" .. replace(stock_input(), "LStickR-LStickL", "LStickR - LStickL // same expression\n") .. "\nMenuKey = A.released ? 1 : -1;"
		local _, err = rt.catch(input_config.StockGameplayConfig.validate, source)
		assert(err == nil, tostring(err))
	end)

	harness.test(report, "input_config: rejects_changed_axis_or_button_instead_of_using_incompatible_specialization", function()
		local base = stock_input()
		for _, changed in {
			replace(base, "GP_LStickX = LStickR-LStickL", "GP_LStickX = LStickL-LStickR"),
			replace(base, "A = Button12", "A = Button13"),
			replace(base, "GP_AFace = A;", ""),
			base .. "GP_AFace = B;",
		} do
			local _, err = rt.catch(input_config.StockGameplayConfig.validate, changed)
			assert(err ~= nil)
		end
	end)

	harness.test(report, "json: разбор чисел, строк, вложенности и ошибок", function()
		local v = json.decode('{"a": [1, -2.5, 3e2, true, false, null], "b": "x\\n\\u0041", "c": {}}')
		assert(v.a[1] == 1 and v.a[2] == -2.5 and v.a[3] == 300 and v.a[4] == true and v.a[5] == false and v.a[6] == json.null)
		assert(v.b == "x\nA")
		local _, err = rt.catch(json.decode, '{"a": 1,}')
		assert(err ~= nil)
	end)

	local golden = load_golden()
	if not golden or not load_files() then
		return
	end

	harness.test(report, "skate_data/state_graph: разбор, хеши, Binding и find_state обоих графов vs Rust", function()
		for name, g in golden.graphs do
			local graph = StateGraph.load(g.path)
			check(u.diff(graph.elements, g.elements), name .. " elements")
			for _, h in g.hashes do
				check(u.diff(attributes.key_hash(h.text), h.key), name .. " key " .. h.text)
				check(u.diff(attributes.byte_hash(h.text), h.byte), name .. " byte " .. h.text)
				check(u.diff(state_graph.binding.name_hash(h.text), h.name), name .. " name " .. h.text)
			end
			local b = Binding.from_graph(graph)
			check(u.diff(b, g.binding), name .. " binding")
			for i, f in g.finds do
				check(u.diff(Binding.find_state(b, f.start, f.name, f.ascend), f.out), name .. " find#" .. i)
				assert((Binding.find_state(b, f.start, f.name, f.ascend) == nil) == (f.out == nil), name .. " find nil#" .. i)
			end
		end
	end)

	local banks = animation_banks.AnimationBanks.load()
	harness.test(report, "skate_data/animation_banks + animation_metadata: идентичности и все деревья vs Rust", function()
		check(u.diff(banks.identities, golden.identities), "identities")
		local metadata = animation_banks.AnimationBanks.metadata(banks)
		check(u.diff(AnimationMetadata.clip_count(metadata), golden.clip_count), "clip_count")
		check(u.diff(AnimationMetadata.sources(metadata), golden.sources), "sources")
		for name, t in golden.trees do
			local tree, err = rt.catch(AnimationMetadata.tree, metadata, name)
			local want = t.tree
			if want.err ~= nil then
				check(u.diff(tostring(err), want.err), name .. " err")
			else
				assert(err == nil, name .. ": " .. tostring(err))
				check(u.diff(tree.kind, want.kind), name .. " kind")
				local v = tree.value
				check(u.diff(v.name, want.name), name .. " name")
				check(u.diff(v.source_offset, want.offset), name .. " offset")
				for k, w in want do
					if k ~= "kind" and k ~= "name" and k ~= "offset" then
						check(u.diff(v[k], w), name .. " " .. k)
					end
				end
			end
			local src = AnimationMetadata.source_for(metadata, name)
			check(u.diff(if src then src.source_bank else nil, t.source), name .. " source")
		end
	end)

	harness.test(report, "skate_data/animation_frames: иерархия, клипы и опорные позы vs Rust", function()
		local frames = AnimationFrames.from_banks(banks)
		local gf = golden.frames
		check(u.diff(frames.parents, gf.parents), "parents")
		check(u.diff(frames.bone_names, gf.bone_names), "bone_names")
		check(u.diff(frames.mirror_indices, gf.mirror_indices), "mirror_indices")
		assert(frames.has_trajectory == gf.has_trajectory)
		check(u.diff(AnimationFrames.clip_count(frames), gf.clip_count), "clip_count")
		check(u.diff(AnimationFrames.clip_names(frames), gf.clip_names), "clip_names")
		for name, c in golden.clips do
			local clip = AnimationFrames.clip(frames, name)
			local bank = c.bank
			c.bank = nil
			check(u.diff(clip, c), name)
			check(u.diff(AnimationFrames.clip_bank(frames, name), bank), name .. " bank")
			c.bank = bank
		end
		for i, p in golden.poses do
			local pose, err = rt.catch(AnimationFrames.named_pose_in, frames, p.bank, p.name)
			if p.err ~= nil then
				check(u.diff(tostring(err), p.err), "pose#" .. i)
			else
				check(u.diff(pose, p.out), "pose#" .. i)
			end
		end
	end)

	harness.test(report, "skate_data/physics_skeleton, gesture_patterns, input_config, manifest vs Rust", function()
		local sk, err = rt.catch(physics_skeleton.PhysicsSkeleton.load, "stock/physics-skeletons.json", banks.identities[1], "phys_tpose")
		if golden.physics_skeleton.err ~= nil then
			check(u.diff(tostring(err), golden.physics_skeleton.err), "physics_skeleton err")
		else
			assert(err == nil, tostring(err))
			check(u.diff(sk, golden.physics_skeleton), "physics_skeleton")
		end
		for name, g in golden.gestures do
			local p, perr = rt.catch(gesture_patterns.load, string.format("stock/data/joystick/%s.pat", name))
			if g.err ~= nil then
				assert(perr ~= nil, name)
			else
				assert(perr == nil, tostring(perr))
				check(u.diff(p, g), name)
			end
		end
		local _, ierr = rt.catch(input_config.StockGameplayConfig.load)
		check(u.diff(ierr == nil, golden.input_ok), "input " .. tostring(ierr))
		check(u.diff(manifest.GameAssets.load(), golden.manifest), "manifest")
	end)
end
