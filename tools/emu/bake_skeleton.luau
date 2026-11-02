--!nocheck
-- Запекает имена костей, родителей и RIG_TPOSE скейтера в src/roblox/skate3/skeleton.luau,
-- чтобы клиенты без загруженного ядра могли рисовать чужих скейтеров.
local fs = require("@lune/fs")
local emu = require("./roblox")
local root = "/home/claude/skateport"
local rs = emu.service("ReplicatedStorage")
local skate3 = emu.new_instance("Folder", "Skate3", rs)
emu.mount(skate3, "sim", root .. "/vendor/sim")
emu.mount(skate3, "sim_data", root .. "/vendor/sim_data", { maps = true, hud = true, build_items = true, input_icons = true })
local port = emu.mount(rs, "SkatePort", root .. "/src")
local engine = emu.require(port.roblox.skate3.engine)
local collision = {
	{ points = { { -100, 0, -100 }, { -100, 0, 100 }, { 100, 0, 100 } }, surface = 0, material = 1 },
	{ points = { { -100, 0, -100 }, { 100, 0, 100 }, { 100, 0, -100 } }, surface = 0, material = 1 },
}
local mat = { name = "g", flags = 0, friction = 0.5, restitution = 0, color = { 1, 1, 1 }, roughness = 1, emissive = 0, textures = { 0, 0, 0, 0, 0 },
	indirect_strength = 1, alpha_mode = 0, alpha_cutoff = 0, audio = 0, physics = 0, pattern = 0 }
local map = { version = 1, name = "emu", spawn = { 0, 0, 0 }, heading = 0, environment = {}, materials = { mat }, textures = {},
	geometry = { vertices = {}, indices = {}, collision = collision }, rails = {}, doors = {}, lights = {}, routes = {}, extensions = {} }
local e = engine.boot(map, function() end)
local frames = e.skater.animation.evaluator.frames
local samples = e.import("skate_data/animation_frames").AnimationFrames.named_pose(frames, "RIG_TPOSE").samples
local bits = buffer.create(4)
local function f(w) buffer.writeu32(bits, 0, w) return buffer.readf32(bits, 0) end
local lines = {}
local function out(s) table.insert(lines, s) end
out("--!strict")
out("-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine")
out("-- ROBLOX: скелет скейтера без загрузки ядра — имена костей, родители и")
out("-- T-поза (RIG_TPOSE) в локальных осях родителя: сдвиг (метры) и кватернион x,y,z,w.")
out("-- Сгенерировано tools/emu/bake_skeleton.luau из данных игры; руками не править.")
out("")
out("local skeleton = {}")
out("")
local names = {}
for _, n in frames.bone_names do table.insert(names, string.format("%q", n)) end
out("skeleton.BONE_NAMES = { " .. table.concat(names, ", ") .. " }")
local parents = {}
for _, p in frames.parents do table.insert(parents, tostring(p)) end
out("skeleton.PARENTS = { " .. table.concat(parents, ", ") .. " } -- -1: корень, иначе индекс с нуля")
out("")
out("-- { tx, ty, tz, qx, qy, qz, qw } на кость, локально относительно родителя")
out("skeleton.TPOSE_LOCAL = {")
for i, w in samples do
	out(string.format("\t{ %.7g, %.7g, %.7g, %.9g, %.9g, %.9g, %.9g }, -- %s", f(w[8]), f(w[9]), f(w[10]), f(w[4]), f(w[5]), f(w[6]), f(w[7]), frames.bone_names[i]))
end
out("}")
out("")
out([[-- T-поза в пространстве модели: CFrame каждой кости в стадах.
function skeleton.tpose(studs_per_metre: number): { CFrame }
	local out: { CFrame } = table.create(#skeleton.PARENTS)
	for i, parent in skeleton.PARENTS do
		local w = skeleton.TPOSE_LOCAL[i]
		local qx, qy, qz, qw = w[4], w[5], w[6], w[7]
		local l = math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw)
		if l < 1e-9 then
			qx, qy, qz, qw, l = 0, 0, 0, 1, 1
		end
		local local_cf = CFrame.new(w[1] * studs_per_metre, w[2] * studs_per_metre, w[3] * studs_per_metre, qx / l, qy / l, qz / l, qw / l)
		out[i] = if parent >= 0 then out[parent + 1] * local_cf else local_cf
	end
	return out
end

return skeleton]])
fs.writeFile(root .. "/src/roblox/skate3/skeleton.luau", table.concat(lines, "\n") .. "\n")
print("ok", #samples)
