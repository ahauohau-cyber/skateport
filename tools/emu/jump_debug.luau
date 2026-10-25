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
local ob = e.import("skate_core/input/offboard_intentions")
local orig = ob.produce_discrete
local tick_no = 0
ob.produce_discrete = function(c, flags, air)
	local out = orig(c, flags, air)
	for _, i in out do
		if i.name ~= "OB_AirBodyTweakX" and i.name ~= "OB_AirBodyTweakY" then print("tick", tick_no, "intent", i.name, i.value) end
	end
	return out
end
local LY, HOLD = 0, 0
local function pad(b) return { buttons = bit32.bor(b or 0, HOLD), left_trigger = 0, right_trigger = 0, left_x = 0, left_y = LY, right_x = 0, right_y = 0 } end
local function st() return e.skater.player_input.physical.state.state_16 end
local function T(b) tick_no += 1 engine.tick(e, pad(b)) end
for i = 1, 30 do T() end
for i = 1, 4 do T(0x8000) end
for i = 1, 60 do T() end
print("state", st())
LY = 32767
HOLD = 0x1000
for i = 1, 60 do T() end
print("running state", st())
for i = 1, 4 do T(0x4000) end
for i = 1, 40 do T() if st() ~= 500 then print("tick", tick_no, "state", st()) end end
