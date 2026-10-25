--!nocheck
-- Заезд на клин: пол + отдельный замкнутый клин (как деталь Roblox), с флагами рёбер и без.
local emu = require("./roblox")
local root = "/home/claude/skateport"
local rs = emu.service("ReplicatedStorage")
local skate3 = emu.new_instance("Folder", "Skate3", rs)
emu.mount(skate3, "sim", root .. "/vendor/sim")
emu.mount(skate3, "sim_data", root .. "/vendor/sim_data", { maps = true, hud = true, build_items = true, input_icons = true })
local port = emu.mount(rs, "SkatePort", root .. "/src")
local engine = emu.require(port.roblox.skate3.engine)
local edge_flags = emu.require(port.roblox.skate3.edge_flags)

local function sub(a, b) return { a[1] - b[1], a[2] - b[2], a[3] - b[3] } end
local function cross(a, b) return { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] } end
local function dot(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end

local function build(with_flags, height, len)
	local collision = {}
	local function tri(a, b, c, centre)
		local n = cross(sub(b, a), sub(c, a))
		local mid = { (a[1] + b[1] + c[1]) / 3, (a[2] + b[2] + c[2]) / 3, (a[3] + b[3] + c[3]) / 3 }
		if centre and dot(n, sub(mid, centre)) < 0 then b, c = c, b end
		table.insert(collision, { points = { a, b, c }, surface = 0, material = 1 })
	end
	local function quad(a, b, c, d, centre) tri(a, b, c, centre); tri(a, c, d, centre) end
	-- пол (большой, нормаль вверх)
	quad({ -100, 0, -300 }, { -100, 0, 100 }, { 100, 0, 100 }, { 100, 0, -300 })
	-- клин
	local z0, z1 = 6, 6 + len
	local A, B, C, D = { -6, 0, z0 }, { 6, 0, z0 }, { -6, 0, z1 }, { 6, 0, z1 }
	local E, F = { -6, height, z1 }, { 6, height, z1 }
	local centre = { 0, height / 3, z0 + len * 2 / 3 }
	quad(A, B, D, C, centre) -- дно
	quad(A, B, F, E, centre) -- склон
	quad(C, D, F, E, centre) -- зад
	tri(A, C, E, centre) -- бока
	tri(B, D, F, centre)
	if with_flags then edge_flags.compute(collision) end
	return collision
end

local mat = { name = "g", flags = 0, friction = 0.5, restitution = 0, color = { 1, 1, 1 }, roughness = 1, emissive = 0, textures = { 0, 0, 0, 0, 0 },
	indirect_strength = 1, alpha_mode = 0, alpha_cutoff = 0, audio = 0, physics = 0, pattern = 0 }
local function pad(b, lx, ly) return { buttons = b or 0, left_trigger = 0, right_trigger = 0, left_x = lx or 0, left_y = ly or 0, right_x = 0, right_y = 0 } end

for _, height in { 0.5, 1.0 } do
	for _, with_flags in { false, true } do
		local map = { version = 1, name = "emu", spawn = { 0, 0, -40 }, heading = 0, environment = {}, materials = { mat }, textures = {},
			geometry = { vertices = {}, indices = {}, collision = build(with_flags, height, 2) }, rails = {}, doors = {}, lights = {}, routes = {}, extensions = {} }
		local e = engine.boot(map, function() end)
		for i = 1, 30 do engine.tick(e, pad()) end
		local trace = {}
		local before, max_y, reached = 0, -1, -math.huge
		for i = 1, 900 do
			local s = engine.status(e)
			local push = (s.position.z < 2 and i % 20 < 5) and 0x1000 or 0
			engine.tick(e, pad(push))
			s = engine.status(e)
			if s.position.z < 5.6 then before = s.speed end
			if s.position.z >= 5.6 and s.position.z < 8.5 then
				table.insert(trace, string.format("%.1f,%.1f/%.2f/%.2f", s.position.x, s.position.z, s.position.y, s.speed))
			end
			max_y = math.max(max_y, s.position.y)
			reached = math.max(reached, s.position.z)
		end
		local s = engine.status(e)
		print(string.format("h=%.1f flags=%-5s before=%.2f max_y=%.2f reached z=%.2f state=%d", height, tostring(with_flags), before, max_y, reached, s.state))
		print("   ", table.concat(trace, " ", 1, math.min(#trace, 14)))
	end
end
