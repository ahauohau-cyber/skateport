--!nocheck
-- Скорость тика в режимах «Lite» ядра (как Performance mode в примерочном плейсе).
local emu = require("./roblox")
local root = "/home/claude/skateport"
local rs = emu.service("ReplicatedStorage")
local skate3 = emu.new_instance("Folder", "Skate3", rs)
emu.mount(skate3, "sim", root .. "/vendor/sim")
emu.mount(skate3, "sim_data", root .. "/vendor/sim_data", { maps = true, hud = true, build_items = true, input_icons = true })
local port = emu.mount(rs, "SkatePort", root .. "/src")
local engine = emu.require(port.roblox.skate3.engine)
local import = engine.import()
local solver = import("skate_core/physics/solver")
local solve = import("skate_game/physics/solve")
local collision = {}
local function quad(a, b, c, d)
	table.insert(collision, { points = { a, b, c }, surface = 0, material = 1 })
	table.insert(collision, { points = { a, c, d }, surface = 0, material = 1 })
end
quad({ -100, 0, -100 }, { -100, 0, 100 }, { 100, 0, 100 }, { 100, 0, -100 })
local mat = { name = "g", flags = 0, friction = 0.5, restitution = 0, color = { 1, 1, 1 }, roughness = 1, emissive = 0, textures = { 0, 0, 0, 0, 0 },
	indirect_strength = 1, alpha_mode = 0, alpha_cutoff = 0, audio = 0, physics = 0, pattern = 0 }
local map = { version = 1, name = "emu", spawn = { 0, 0, -60 }, heading = 0, environment = {}, materials = { mat }, textures = {},
	geometry = { vertices = {}, indices = {}, collision = collision }, rails = {}, doors = {}, lights = {}, routes = {}, extensions = {} }
local function pad(b) return { buttons = b or 0, left_trigger = 0, right_trigger = 0, left_x = 0, left_y = 0, right_x = 0, right_y = 0 } end
local modes = {
	{ "off", nil, nil },
	{ "rider:auto", { rider_passes = "auto" }, nil },
	{ "vector", { vector_kernels = true }, nil },
	{ "both", { rider_passes = "auto", vector_kernels = true }, nil },
	{ "k", nil, {} },
	{ "rider+k", { rider_passes = "auto" }, {} },
	{ "both+k", { rider_passes = "auto", vector_kernels = true }, {} },
}
for _, m in modes do
	solver.set_mode(m[2])
	solve.set_rider(m[3])
	local e = engine.boot(map, function() end)
	for i = 1, 30 do engine.tick(e, pad()) end
	local N = 300
	local t = os.clock()
	for i = 1, N do engine.tick(e, pad(i % 20 < 5 and 0x1000 or 0)) end
	local per = (os.clock() - t) / N * 1000
	local s = engine.status(e)
	print(string.format("%-10s %.2f мс/тик   z=%.2f speed=%.2f state=%d", m[1], per, s.position.z, s.speed, s.state))
end
