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
quad({ -100, 0, -100 }, { -100, 0, 100 }, { 100, 0, 100 }, { 100, 0, -100 })
local mat = { name = "g", flags = 0, friction = 0.5, restitution = 0, color = { 1, 1, 1 }, roughness = 1, emissive = 0, textures = { 0, 0, 0, 0, 0 },
	indirect_strength = 1, alpha_mode = 0, alpha_cutoff = 0, audio = 0, physics = 0, pattern = 0 }
local map = { version = 1, name = "emu", spawn = { 0, 0, 0 }, heading = 0, environment = {}, materials = { mat }, textures = {},
	geometry = { vertices = {}, indices = {}, collision = collision }, rails = {}, doors = {}, lights = {}, routes = {}, extensions = {} }
local function pad(b, lt, rt, ly) return { buttons = b or 0, left_trigger = lt or 0, right_trigger = rt or 0, left_x = 0, left_y = ly or 0, right_x = 0, right_y = 0 } end
local cases0 = { { "RB", 0x200 }, { "LB", 0x100 }, { "B", 0x2000 }, { "A", 0x1000 }, { "RT", 0, 0, 255 }, { "LT", 0, 255, 0 }, { "LB+RB", 0x300 }, {"RS", 0x80}, {"LS", 0x40}, {"back", 0x20}, {"Yhold", 0x8000} }
local cases = { { "RT", 0, 0, 255 }, { "LT", 0, 255, 0 }, { "none", 0 } }
for _, c in cases do
	local e = engine.boot(map, function() end)
	for i = 1, 30 do engine.tick(e, pad()) end
	for i = 1, 3 do engine.tick(e, pad(0x8000)) end
	for i = 1, 60 do engine.tick(e, pad()) end
	local hold = c[1] == "Yhold" and 60 or 10
	for i = 1, hold do engine.tick(e, pad(c[2], c[3], c[4])) end
	for i = 1, 60 do engine.tick(e, pad(0, 0, 0, 32767)) end
	local d = engine.deck_transform(e).translation
	local s = engine.status(e)
	local h = engine.bone_world(e, {})[2][4]
	s = { state = s.state, position = { x = h[1], y = h[2], z = h[3] } }
	print(string.format("%-6s state=%d deck-skater=%.2f deck_y=%.2f", c[1], s.state, math.sqrt((d.x - s.position.x) ^ 2 + (d.z - s.position.z) ^ 2), d.y))
end
