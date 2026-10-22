--!strict
-- Замер: сколько стоит один тик доски (50 итераций решателя, 4 контакта колёс).
local rt = require("../src/rt")
local board_runtime = require("../src/skate_core/physics/board_runtime")
local board_step = require("../src/skate_core/physics/board_step")
local board = require("../src/skate_core/physics/board")
local drive_frames = require("../src/skate_core/physics/drive_frames")
local drive_parameters = require("../src/skate_core/physics/drive_parameters")
local mass = require("../src/skate_core/physics/mass")
local rigid_body = require("../src/skate_core/physics/rigid_body")

local BoardRuntime = board_runtime.BoardRuntime
local gravity = vector.create(0, rt.f32(-9.81), 0)
local simulation = rigid_body.RetailSimulationStep.fixed_60_hz(0, rt.f32(0.001), gravity)
local settings = {
	simulation = simulation,
	iterations = 50,
	base_truck_transforms = drive_frames.default_truck_transforms(),
	truck_dynamics = drive_parameters.retail_truck_drive_dynamics(drive_parameters.RetailTruckDriveSettings.STOCK()),
	force_point_y_offset = 0,
}
local height = rt.f32(board.RETAIL_WHEEL_RADIUS - drive_frames.default_body_transforms()[1].translation.y)
local b = BoardRuntime.new(mass.default_skateboard_mass_properties(), drive_frames.default_body_transforms(),
	{ basis = { columns = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } } }, translation = vector.create(0, height, 0) },
	simulation, board_runtime.BoardMotion.Active)
local function collisions()
	local out = {}
	for id = 0, 3 do
		local p = b.bodies[id + 1].rates.position
		local bottom = rt.f32(p.y - board.RETAIL_WHEEL_RADIUS)
		table.insert(out, {
			body_a = board_step.CollisionBody.Board(id),
			body_b = board_step.CollisionBody.StaticWorld,
			contact = { position_on_a = vector.create(p.x, bottom, p.z), position_on_b = vector.create(p.x, 0, p.z),
				normal = vector.create(0, 1, 0), restitution = 0, static_friction = rt.f32(0.9), dynamic_friction = rt.f32(0.8), tag = id },
		})
	end
	return out
end
local N = 200
local t0 = os.clock()
for _ = 1, N do
	BoardRuntime.advance(b, collisions(), { 0, 0 }, settings)
end
local dt = (os.clock() - t0) / N
print(string.format("тик доски: %.2f мс (бюджет 60 Гц = 16.7 мс); дека y=%.4f", dt * 1000, b.bodies[7].rates.position.y))

-- Разбивка: доля решателя и стоимость базовых операций.
local solver = require("../src/skate_core/physics/solver")
local orig = solver.solve_constraints
local spent = 0
solver.solve_constraints = function(...)
	local s = os.clock()
	orig(...)
	spent += os.clock() - s
end
local t1 = os.clock()
for _ = 1, N do
	BoardRuntime.advance(b, collisions(), { 0, 0 }, settings)
end
local total = os.clock() - t1
print(string.format("решатель: %.0f%% тика", spent / total * 100))
local M = 2_000_000
local s = os.clock()
local x = 0.0
for i = 1, M do x = rt.f32(x + 1.1) end
print(string.format("rt.f32: %.1f нс", (os.clock() - s) / M * 1e9))
s = os.clock()
for i = 1, M do x = rt.mul_add(x, 0.999, 0.37) end
print(string.format("rt.mul_add: %.1f нс", (os.clock() - s) / M * 1e9))
s = os.clock()
for i = 1, M do x = rt.from_bits(rt.to_bits(x)) end
print(string.format("from_bits(to_bits): %.1f нс", (os.clock() - s) / M * 1e9))

-- Разбивка решателя по семействам
local contact_k = require("../src/skate_core/physics/solver/contact")
local joint_k = require("../src/skate_core/physics/solver/joint")
local drive_k = require("../src/skate_core/physics/solver/drive")
local times = { contact = 0, joint = 0, drive = 0 }
local calls = { contact = 0, joint = 0, drive = 0 }
for name, mod in { contact = contact_k, joint = joint_k, drive = drive_k } do
	local f = mod.solve
	mod.solve = function(r, a, bb)
		local s0 = os.clock()
		f(r, a, bb)
		times[name] += os.clock() - s0
		calls[name] += 1
	end
end
local packed = require("../src/skate_core/physics/solver/packed")
-- packed захватил ссылки на solve при загрузке, поэтому перезагрузка не нужна:
-- pass() вызывает contact.solve через таблицу модуля? проверим
for _ = 1, 20 do
	BoardRuntime.advance(b, collisions(), { 0, 0 }, settings)
end
for name, t in times do
	print(string.format("%s: %d вызовов, %.1f мкс/вызов", name, calls[name], calls[name] > 0 and t / calls[name] * 1e6 or 0))
end
