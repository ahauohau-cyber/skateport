--!strict
-- ROBLOX: демо доски без скейтера. Повторяет тестовый тик Rust
-- `GamePhysics::advance_board` (crates/skate-game/src/physics.rs):
--   clear_forces -> colliders::world_volumes -> world.query_primitives -> board.advance,
-- плюс проверка на неконечную позу. riding outputs (start_wheel_queries и
-- finish_post_physics) ещё не перенесены — TODO вместе с этапом катания.
-- Отличие от Rust только в источнике сил: вместо графа скейтера тестовые толчки
-- с клавиатуры (W/S — толчок вдоль деки, A/D — цели поворота траков).
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local root = script.Parent.Parent
local collections = require(root.skate_data.collections)
local settings_mod = require(root.skate_game.physics.settings)
local colliders = require(root.skate_game.physics.colliders)
local board_runtime = require(root.skate_core.physics.board_runtime)
local board_world = require(root.skate_core.physics.board_world)
local force_queue = require(root.skate_core.physics.force_queue)
local drive_frames = require(root.skate_core.physics.drive_frames)
local world_geometry = require(script.Parent.world_geometry)
local fixed_step = require(script.Parent.fixed_step)

local BoardRuntime = board_runtime.BoardRuntime
local BoardWorld = board_world.BoardWorld
local SCALE = world_geometry.METRES_PER_STUD

local board_demo = {}

-- Тестовые значения демо (не из игры): сила толчка в ньютонах и цель поворота траков.
local PUSH_FORCE = 30.0
local STEER_TARGET = 0.25

-- ground::query_settings() в Rust.
local QUERY = {
	volume_padding = 0.05,
	maximum_separating_distance = 0.5,
	edge_cos_bend_normal_threshold = 0.999,
	convexity_epsilon = 0.01,
	is_object = false,
}
local RETENTION = { capacity = 0xFFFFFFFF, duplicate_distance_squared = -1.0, deferred_reduction = true }

-- ROBLOX: литералы f32 из Rust.
do
	local f32 = (require(root.rt) :: any).f32
	for k, v in QUERY do
		if type(v) == "number" then
			(QUERY :: any)[k] = f32(v)
		end
	end
end

local function to_cframe(pose: any): CFrame
	local c = pose.basis.columns
	local t = pose.translation
	return CFrame.fromMatrix(
		Vector3.new(t.x, t.y, t.z) / SCALE,
		Vector3.new(c[1][1], c[1][2], c[1][3]),
		Vector3.new(c[2][1], c[2][2], c[2][3]),
		Vector3.new(c[3][1], c[3][2], c[3][3])
	)
end

local function visual(name: string, size: Vector3, shape: Enum.PartType, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

export type Demo = {
	stop: () -> (),
	model: Model,
	stats: { ticks: number, contacts: number, last_ms: number },
}

-- Запустить доску перед точкой `at` (CFrame в стадах; LookVector — нос доски).
function board_demo.start(at: CFrame): Demo
	local data = collections.expect(collections.Collections.from_data(require(root.skate_data.stock) :: any))
	local settings = assert(settings_mod.PhysicsSettings.load(data))

	local model = Instance.new("Model")
	model.Name = "SkatePortBoard"
	model.Parent = workspace

	local world, skipped = world_geometry.collect(workspace)
	assert(world, skipped)
	if #(skipped :: { BasePart }) > 0 then
		warn(string.format("[skateport] пропущено деталей неизвестной формы: %d", #(skipped :: { BasePart })))
	end

	-- Поза спавна: нос доски (+Z) смотрит вдоль LookVector, Y вверх.
	local look = Vector3.new(at.LookVector.X, 0, at.LookVector.Z)
	look = if look.Magnitude > 1e-3 then look.Unit else Vector3.zAxis
	local x = Vector3.yAxis:Cross(look)
	local p = at.Position * SCALE
	local spawn = drive_frames.RetailAffineTransform.IDENTITY()
	spawn.basis = { columns = { { x.X, x.Y, x.Z }, { 0.0, 1.0, 0.0 }, { look.X, look.Y, look.Z } } }
	spawn.translation = vector.create(p.X, p.Y, p.Z)

	local board = BoardRuntime.new(settings.masses, settings.authored, spawn, settings.step.simulation, board_runtime.BoardMotion.Active)

	-- Видимые детали по коллайдерам стоковой доски (размеры в стадах).
	local r = settings.wheel_radius / SCALE
	local parts: { Part } = {}
	for i = 1, 4 do
		parts[i] = visual("Wheel" .. i, Vector3.new(0.03 / SCALE, 2 * r, 2 * r), Enum.PartType.Cylinder, Color3.fromRGB(235, 235, 225), model)
	end
	local ts = settings.truck_shape
	for i = 5, 6 do
		parts[i] = visual(if i == 5 then "FrontTruck" else "BackTruck",
			Vector3.new(2 * ts.radius, 2 * ts.radius, 2 * (ts.half_length + ts.radius)) / SCALE, Enum.PartType.Block, Color3.fromRGB(150, 150, 160), model)
	end
	local deck_size = Vector3.new(0.2, 0.012, 0.8)
	for _, child in settings.deck_geometry.children do
		if child.shape.kind == "RoundedBox" then
			local h = child.shape.half_extents :: vector
			local rad = child.shape.radius :: number
			deck_size = Vector3.new(2 * (h.x + rad), 2 * (h.y + rad), 2 * (h.z + rad))
			break
		end
	end
	parts[7] = visual("Deck", deck_size / SCALE, Enum.PartType.Block, Color3.fromRGB(60, 45, 35), model)
	model.PrimaryPart = parts[7]

	local stats = { ticks = 0, contacts = 0, last_ms = 0 }
	local clock = fixed_step.new()
	local failed = false

	local function tick()
		local t0 = os.clock()
		BoardRuntime.clear_forces(board)
		local deck = BoardRuntime.bodies(board)[7].rates
		local forward = deck.basis.columns[3]
		local push = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			push += PUSH_FORCE
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			push -= PUSH_FORCE
		end
		if push ~= 0 then
			force_queue.BoardForceQueue.append(BoardRuntime.forces_mut(board), {
				tag = 1,
				force_world = vector.create(forward[1] * push, 0.0, forward[3] * push),
				point_body = vector.zero,
			})
		end
		local steer = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			steer += STEER_TARGET
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			steer -= STEER_TARGET
		end
		local volumes = colliders.world_volumes(board, settings)
		local contacts = BoardWorld.query_primitives(world :: any, volumes, QUERY, RETENTION)
		stats.contacts = #contacts
		BoardRuntime.advance(board, contacts, { steer, steer }, settings.step)
		stats.ticks += 1
		for _, body in BoardRuntime.bodies(board) do
			local q = body.rates.position
			if q.x ~= q.x or q.y ~= q.y or q.z ~= q.z or math.abs(q.x) == math.huge or math.abs(q.y) == math.huge or math.abs(q.z) == math.huge then
				failed = true
				warn(string.format("[skateport] Board solver produced a non-finite pose on tick %d", stats.ticks))
				break
			end
		end
		stats.last_ms = (os.clock() - t0) * 1000
	end

	local function render()
		for i, pose in BoardRuntime.part_transforms(board) do
			parts[i].CFrame = to_cframe(pose)
		end
	end
	render()

	local connection = RunService.PreSimulation:Connect(function(dt)
		if failed then
			return
		end
		fixed_step.advance(clock, dt, function()
			return settings.step.simulation.time_step
		end, tick)
		render()
	end)

	local demo: Demo = {
		model = model,
		stats = stats,
		stop = function()
			connection:Disconnect()
			model:Destroy()
		end,
	}
	return demo
end

-- Перевести доску в точку (для кнопки R в клиенте).
return board_demo
