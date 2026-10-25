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
table.insert(collision, { points = { {-100,0,-100}, {-100,0,100}, {100,0,100} }, surface = 0, material = 1 })
table.insert(collision, { points = { {-100,0,-100}, {100,0,100}, {100,0,-100} }, surface = 0, material = 1 })
local mat = { name = "g", flags = 0, friction = 0.5, restitution = 0, color = { 1, 1, 1 }, roughness = 1, emissive = 0, textures = { 0, 0, 0, 0, 0 },
	indirect_strength = 1, alpha_mode = 0, alpha_cutoff = 0, audio = 0, physics = 0, pattern = 0 }
local map = { version = 1, name = "emu", spawn = { 0, 0, 0 }, heading = 0, environment = {}, materials = { mat }, textures = {},
	geometry = { vertices = {}, indices = {}, collision = collision }, rails = {}, doors = {}, lights = {}, routes = {}, extensions = {} }
local e = engine.boot(map, function() end)
local frames = e.skater.animation.evaluator.frames
print("native?", frames.native ~= nil)
local names = {}
if frames.native then
	for k in frames.native.pose_names do table.insert(names, k) end
else
	for id, p in frames.reference_poses do table.insert(names, string.format("%x=%s", id, p.name)) end
end
table.sort(names)
print(#names, table.concat(names, ", "))
print("bones", #frames.bone_names, table.concat(frames.bone_names, ","))
print("parents", table.concat(frames.parents, ","))
