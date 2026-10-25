--!nocheck
local emu = require("./roblox")
local root = "/home/claude/skateport"
local rs = emu.service("ReplicatedStorage")
local skate3 = emu.new_instance("Folder", "Skate3", rs)
emu.mount(skate3, "sim", root .. "/vendor/sim")
emu.mount(skate3, "sim_data", root .. "/vendor/sim_data", { maps = true, hud = true, build_items = true, input_icons = true })
local port = emu.mount(rs, "SkatePort", root .. "/src")
local engine = emu.require(port.roblox.skate3.engine)
local collision = {}
local function quad(a, b, c, d)
	table.insert(collision, { points = { a, b, c }, surface = 0, material = 1 })
	table.insert(collision, { points = { a, c, d }, surface = 0, material = 1 })
end
quad({ -300, 0, -300 }, { -300, 0, 300 }, { 300, 0, 300 }, { 300, 0, -300 })
local mat = { name = "g", flags = 0, friction = 0.5, restitution = 0, color = { 1, 1, 1 }, roughness = 1, emissive = 0, textures = { 0, 0, 0, 0, 0 },
	indirect_strength = 1, alpha_mode = 0, alpha_cutoff = 0, audio = 0, physics = 0, pattern = 0 }
local map = { version = 1, name = "emu", spawn = { 0, 0, 0 }, heading = 0, environment = {}, materials = { mat }, textures = {},
	geometry = { vertices = {}, indices = {}, collision = collision }, rails = {}, doors = {}, lights = {}, routes = {}, extensions = {} }
local e = engine.boot(map)
local hips
for i, n in e.bone_names do if n == "HIPS" then hips = i end end
local LY = 0
local function pad(b) return { buttons = b or 0, left_trigger = 0, right_trigger = 0, left_x = 0, left_y = LY, right_x = 0, right_y = 0 } end
local function st() return e.skater.player_input.physical.state.state_16 end
for i = 1, 30 do engine.tick(e, pad()) end
for i = 1, 4 do engine.tick(e, pad(0x8000)) end
for i = 1, 60 do engine.tick(e, pad()) end
print("offboard state", st())
local function rootpos() local b = engine.bone_world(e, {}) return string.format("%.2f %.2f %.2f", b[hips][4][1], b[hips][4][2], b[hips][4][3]) end
print("before walk hips", rootpos())
LY = 32767
for i = 1, 60 do engine.tick(e, pad()) end
print("after walk hips", rootpos())
local s0 = engine.status(e)
print("walking state", st(), "hips", engine.bone_height(e, hips))
for _, b in { { "A", 0x1000 }, { "X", 0x4000 }, { "B", 0x2000 }, { "RB", 0x0200 }, { "LB", 0x0100 } } do
	local seen = {}
	local maxh = 0
	for i = 1, 6 do engine.tick(e, pad(b[2])) seen[st()] = true end
	for i = 1, 60 do engine.tick(e, pad()) seen[st()] = true maxh = math.max(maxh, engine.bone_height(e, hips)) end
	local list = {}
	for k in seen do table.insert(list, k) end
	table.sort(list)
	print(b[1], "states", table.concat(list, ","), string.format("max hips %.2f", maxh), "now", st())
	if st() ~= 500 then for i = 1, 4 do engine.tick(e, pad(0x8000)) end for i = 1, 60 do engine.tick(e, pad()) end end
end
