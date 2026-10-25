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
local H = 6
-- платформа: верх y=H, z от -60 до 0
quad({ -10, H, -60 }, { -10, H, 0 }, { 10, H, 0 }, { 10, H, -60 })
-- стенка платформы (смотрит в +Z)
quad({ -10, 0, 0 }, { 10, 0, 0 }, { 10, H, 0 }, { -10, H, 0 })
-- земля дальше
quad({ -100, 0, 0 }, { -100, 0, 200 }, { 100, 0, 200 }, { 100, 0, 0 })
local mat = { name = "g", flags = 0, friction = 0.5, restitution = 0, color = { 1, 1, 1 }, roughness = 1, emissive = 0, textures = { 0, 0, 0, 0, 0 },
	indirect_strength = 1, alpha_mode = 0, alpha_cutoff = 0, audio = 0, physics = 0, pattern = 0 }
local combos = {
	{ "LT+B", 0x2000, 255, 0 }, { "RT+B", 0x2000, 0, 255 }, { "LT+RT", 0, 255, 255 }, { "B", 0x2000, 0, 0 },
	{ "LT+Y", 0x8000, 255, 0 }, { "LT+X", 0x4000, 255, 0 }, { "LT+A", 0x1000, 255, 0 }, { "RT+X", 0x4000, 0, 255 },
	{ "LT+RT+B", 0x2000, 255, 255 }, { "LT", 0, 255, 0 }, { "RT+Y", 0x8000, 0, 255 },
}
local which = tonumber((...)) or 0
for ci, combo in combos do
	if which ~= 0 and ci ~= which then continue end
	local map = { version = 1, name = "emu", spawn = { 0, H, -50 }, heading = 0, environment = {}, materials = { mat }, textures = {},
		geometry = { vertices = {}, indices = {}, collision = collision }, rails = {}, doors = {}, lights = {}, routes = {}, extensions = {} }
	local e = engine.boot(map)
	local function pad(b, lt, rt) return { buttons = b or 0, left_trigger = lt or 0, right_trigger = rt or 0, left_x = 0, left_y = 0, right_x = 0, right_y = 0 } end
	local function st() return e.skater.player_input.physical.state.state_16 end
	for i = 1, 30 do engine.tick(e, pad()) end
	for i = 1, 240 do engine.tick(e, pad(i % 25 < 6 and 0x1000 or 0)) end -- толчки
	local airborne_at, christ, states = nil, false, {}
	for i = 1, 300 do
		local s = engine.status(e)
		local air = st() >= 200 and st() < 300
		if air and not airborne_at then airborne_at = i end
		local hold = airborne_at and i - airborne_at > 6 and i - airborne_at < 60
		engine.tick(e, if hold then pad(combo[2], combo[3], combo[4]) else pad())
		states[st()] = true
		if bit32.band(e.skater.player_input.processed.flags_2472, 0x40) ~= 0 then christ = true end
	end
	local list = {}
	for k in states do table.insert(list, k) end
	table.sort(list)
	print(string.format("%-8s airborne@%s christ=%s states %s", combo[1], tostring(airborne_at), tostring(christ), table.concat(list, ",")))
end
