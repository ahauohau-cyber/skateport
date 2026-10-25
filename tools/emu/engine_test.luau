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
local rails = { { name = "rail", closed = false, points = { { 0.6, 0.4, 2 }, { 0.6, 0.4, 10 } } } }
local map = { version = 1, name = "emu", spawn = { 0, 0, 0 }, heading = 0, environment = {}, materials = { mat }, textures = {},
	geometry = { vertices = {}, indices = {}, collision = collision }, rails = rails, doors = {}, lights = {}, routes = {}, extensions = {} }
local e = engine.boot(map, print)
local function pad(b, lx, ly) return { buttons = b or 0, left_trigger = 0, right_trigger = 0, left_x = lx or 0, left_y = ly or 0, right_x = 0, right_y = 0 } end
print("period", engine.period(e))
for i = 1, 60 do engine.tick(e, pad()) end
local s = engine.status(e)
print("after idle", s.position.x, s.position.y, s.position.z, s.state, s.speed)
for i = 1, 90 do engine.tick(e, pad(i % 20 < 5 and 0x1000 or 0)) end
s = engine.status(e)
print("after push", s.position.x, s.position.y, s.position.z, s.state, s.speed)
local bones = engine.bone_world(e, {})
print("bones", #bones, "hips y", bones[2][4][2], "failure", e.failure)
local d = engine.deck_transform(e)
print("deck translation", d.translation.x, d.translation.y, d.translation.z)
for i = 1, 3 do local col = d.basis.columns[i]; print("col", i, col[1], col[2], col[3], col.x) end
