--!nocheck
local emu = require("./roblox")
local root = "/home/claude/skateport"
local rs = emu.service("ReplicatedStorage")
local skate3 = emu.new_instance("Folder", "Skate3", rs)
emu.mount(skate3, "sim", root .. "/vendor/sim")
emu.mount(skate3, "sim_data", root .. "/vendor/sim_data", { maps = true, hud = true, build_items = true, input_icons = true })
local import = emu.require(skate3.sim.import)
local function stage(name, f)
	local t = os.clock()
	local ok, r = xpcall(f, function(e) return tostring(e) .. "\n" .. debug.traceback() end)
	print(string.format("[boot] %-14s %6.2fs %s", name, os.clock() - t, ok and "ok" or "FAIL"))
	if not ok then print(r) error("stop", 0) end
	return r
end
local config = stage("config", function()
	return import("skate_game/config").Config.from_env({}, { skate3_assets = "roblox:sim_data" })
end)
print("map", config.map, "root", config.asset_root, "difficulty", config.difficulty)
stage("input_config", function()
	import("skate_data/input_config").StockGameplayConfig.load(config.asset_root)
end)
local manifest = stage("manifest", function() return import("skate_data").GameAssets.load(config.asset_root) end)
local graphs = stage("graphs", function() return import("skate_game/graph_runtime").StockGraphs.load(config.asset_root, manifest) end)

-- Тестовая карта: пол 200x200 м на высоте 0.
local function quad(a, b, c, d, out)
	table.insert(out, { points = { a, b, c }, surface = 0, material = 1, native_edges = nil })
	table.insert(out, { points = { a, c, d }, surface = 0, material = 1, native_edges = nil })
end
local collision = {}
local S = 100
quad({ -S, 0, -S }, { -S, 0, S }, { S, 0, S }, { S, 0, -S }, collision)
local map = {
	version = 1, name = "emu", spawn = { 0, 0, 0 }, heading = 0, environment = {},
	materials = { { name = "ground", flags = 0, friction = 0.5, restitution = 0, color = { 1, 1, 1 }, roughness = 1, emissive = 0,
		textures = { 0, 0, 0, 0, 0 }, indirect_strength = 1, alpha_mode = 0, alpha_cutoff = 0, audio = 0, physics = 0, pattern = 0 } },
	textures = {}, geometry = { vertices = {}, indices = {}, collision = collision }, rails = {}, doors = {}, lights = {}, routes = {}, extensions = {},
}
local physics_mod
local physics = stage("physics", function()
	physics_mod = import("skate_game/physics")
	return physics_mod.GamePhysics.load_with_difficulty(config.asset_root, map, config.difficulty)
end)
local skater = stage("skater", function()
	local Difficulty = import("skate_game/difficulty").Difficulty
	return physics_mod.SkaterRuntime.load(config.asset_root, graphs, physics, Difficulty.profile_key(config.difficulty))
end)
local controls = stage("controls", function() return physics_mod.PlayerControls.load(config.asset_root) end)
local res = stage("resources", function()
	local input = import("skate_game/input")
	local controllers = import("skate_game/input/controllers")
	local platform = import("skate_game/input/platform")
	return {
		presentation = import("skate_game/presentation").Presentation.default(),
		controller_input = controllers.ControllerInput.default(),
		published = input.PublishedTickInput.default(),
		capabilities = { platform.CapabilityCache.default(), platform.CapabilityCache.default(), platform.CapabilityCache.default(), platform.CapabilityCache.default() },
		input = input,
	}
end)
local camera = stage("camera", function()
	return import("skate_game/camera").spawn(config, emu.require(skate3.sim_data.misc.camera_shake))
end)
local controls_mod = import("skate_game/physics/controls")
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local BodyId = import("skate_core/physics/board").BodyId
local deck = BodyId.index(BodyId.Deck)
local packet = 0
local function pad(buttons, lx, ly)
	packet += 1
	return { now = os.clock(), { subtype = 1, number = packet, gamepad = { buttons = buttons or 0, left_trigger = 0, right_trigger = 0, left_x = lx or 0, left_y = ly or 0, right_x = 0, right_y = 0 } } }
end
local function tick(p)
	res.input.poll_controllers(res.controller_input, nil, false, true, res.capabilities, p)
	res.input.publish_actions(res.controller_input, res.published, true, false, nil)
	controls_mod.sample(res.published, physics, skater, camera, controls)
	local err = physics_mod.advance(physics, skater, controls, graphs, res.published, camera, nil)
	if err ~= nil then print("advance error", err) end
end
local function status(label)
	local t = BoardRuntime.part_transforms(physics.board)[deck + 1]
	local st = skater.player_input.physical.state
	local v = physics.board.bodies[deck + 1].rates.linear_velocity
	print(string.format("%-10s tick %4d pos %7.3f %7.3f %7.3f vel %6.2f %6.2f %6.2f state %d", label, physics.ticks, t.translation.x, t.translation.y, t.translation.z, v.x, v.y, v.z, st.state_16))
end
local t0 = os.clock()
for i = 1, 120 do tick(pad()) end
status("idle")
for i = 1, 60 do tick(pad(i % 20 < 5 and 0x1000 or 0)) end
status("push A")
for i = 1, 120 do tick(pad(0, 0, 32767)) end
status("stick up")
print(string.format("%.2f ms/tick", (os.clock() - t0) * 1000 / 300))
local anim = import("skate_game/animation")
local names = skater.animation.evaluator.frames.bone_names
print("bones", #names, "render_pose", #skater.render_pose)
print(table.concat(names, " ", 1, math.min(#names, 80)))
local function idx(n) for i, v in names do if string.upper(v) == n then return i end end end
for _, n in { "TRAJECTORY", "HIPS", "HEAD", "RIGHTFOOT", "LEFTFOOT", "SKATEBOARD_ROOT" } do
	local i = idx(n)
	if i then
		local m = anim.native_matrix(skater.render_pose[i])
		print(n, i, typeof(m), m and #m)
		if type(m) == "table" then for c = 1, 4 do print("  col", c, string.format("%.3f %.3f %.3f %.3f", m[c][1], m[c][2], m[c][3], m[c][4])) end end
	end
end
local rb = anim.render_basis() for c = 1, 4 do print("basis", c, rb[c][1], rb[c][2], rb[c][3], rb[c][4]) end
local t = BoardRuntime.part_transforms(physics.board)[deck + 1]
print("deck", t.translation.x, t.translation.y, t.translation.z)
local a2w = anim.native_matrix(skater.animated_skeleton.roots.animation_to_world)
local function mul(a, b) -- column-major 4x4: (a*b) col c = a * b[c]
	local r = {}
	for c = 1, 4 do
		r[c] = {}
		for row = 1, 4 do
			r[c][row] = a[1][row] * b[c][1] + a[2][row] * b[c][2] + a[3][row] * b[c][3] + a[4][row] * b[c][4]
		end
	end
	return r
end
for c = 1, 4 do print("a2w", c, string.format("%.3f %.3f %.3f %.3f", a2w[c][1], a2w[c][2], a2w[c][3], a2w[c][4])) end
for _, n in { "HIPS", "HEAD", "RIGHTFOOT", "LEFTFOOT" } do
	local w = mul(a2w, anim.native_matrix(skater.render_pose[idx(n)]))
	print("world", n, string.format("%.3f %.3f %.3f", w[4][1], w[4][2], w[4][3]))
end
