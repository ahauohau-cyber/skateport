--!nocheck
-- Профиль тика: оборачиваем функции модулей sim таймерами (inclusive + self).
local emu = require("./roblox")
local root = "/home/claude/skateport"
local stats = {} -- name -> {calls, incl, self}
local enabled = false
local stack_child = { 0 } -- время детей на каждом уровне
local clock = os.clock
local function wrap(name, f)
	return function(...)
		if not enabled then
			return f(...)
		end
		table.insert(stack_child, 0)
		local t = clock()
		local r = table.pack(f(...))
		local dt = clock() - t
		local child = table.remove(stack_child)
		stack_child[#stack_child] += dt
		local s = stats[name]
		if s == nil then
			s = { 0, 0, 0 }
			stats[name] = s
		end
		s[1] += 1
		s[2] += dt
		s[3] += dt - child
		return table.unpack(r, 1, r.n)
	end
end
local seen = {}
local function wrap_table(prefix, t, depth)
	if seen[t] or depth > 2 then
		return
	end
	seen[t] = true
	for k, v in t do
		if type(k) == "string" then
			if type(v) == "function" then
				t[k] = wrap(prefix .. "." .. k, v)
			elseif type(v) == "table" and not table.isfrozen(v) then
				wrap_table(prefix .. "." .. k, v, depth + 1)
			end
		end
	end
end
emu.on_module = function(target, result)
	local name = target:GetFullName()
	if string.find(name, "Skate3.sim", 1, true) and not string.find(name, "sim_data", 1, true) and type(result) == "table" and not table.isfrozen(result) then
		local short = string.gsub(name, "^.-Skate3%.sim%.", "")
		if short ~= "import" and short ~= "rt" then
			pcall(wrap_table, short, result, 0)
		end
	end
	return result
end

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
local map = { version = 1, name = "emu", spawn = { 0, 0, -60 }, heading = 0, environment = {}, materials = { mat }, textures = {},
	geometry = { vertices = {}, indices = {}, collision = collision }, rails = {}, doors = {}, lights = {}, routes = {}, extensions = {} }
local e = engine.boot(map, function() end)
local function pad(b) return { buttons = b or 0, left_trigger = 0, right_trigger = 0, left_x = 0, left_y = 0, right_x = 0, right_y = 0 } end
for i = 1, 30 do engine.tick(e, pad()) end
local N = 240
local t0 = clock()
for i = 1, N do engine.tick(e, pad(i % 20 < 5 and 0x1000 or 0)) end
print(string.format("без профиля: %.2f мс/тик", (clock() - t0) / N * 1000))
enabled = true
local t1 = clock()
for i = 1, N do engine.tick(e, pad(i % 20 < 5 and 0x1000 or 0)) end
enabled = false
print(string.format("с профилем: %.2f мс/тик", (clock() - t1) / N * 1000))
local list = {}
for k, v in stats do table.insert(list, { k, v }) end
table.sort(list, function(a, b) return a[2][3] > b[2][3] end)
print("--- self time (мс/тик) ---")
for i = 1, 30 do
	local x = list[i]
	if x then print(string.format("%7.3f self %7.3f incl %6d calls  %s", x[2][3] / N * 1000, x[2][2] / N * 1000, x[2][1] // N, x[1])) end
end
table.sort(list, function(a, b) return a[2][2] > b[2][2] end)
print("--- inclusive (мс/тик) ---")
for i = 1, 40 do
	local x = list[i]
	if x then print(string.format("%7.3f incl %6d calls  %s", x[2][2] / N * 1000, x[2][1] // N, x[1])) end
end
