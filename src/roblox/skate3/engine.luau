--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: запуск ядра sim (ReplicatedStorage.Skate3.sim) для одного скейтера.
--
-- Порядок загрузки и тика — как в Rust (crates/skate-game/src/main.rs и
-- PhysicsPlugin в physics.rs): Config -> StockGameplayConfig -> GameAssets ->
-- StockGraphs -> GamePhysics (с нашей картой из Workspace) -> SkaterRuntime ->
-- PlayerControls; тик: poll_controllers -> publish_actions -> controls.sample ->
-- physics.advance. Модуль без Roblox API, кроме поиска sim в ReplicatedStorage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local engine = {}

-- Скейт меряет в метрах; 1 стад = 0.28 м.
engine.STUDS_PER_METRE = 1 / 0.28

local function sim_root(): Instance
	return ReplicatedStorage:WaitForChild("Skate3"):WaitForChild("sim")
end

function engine.import(): (string) -> any
	return require(sim_root():WaitForChild("import") :: ModuleScript) :: any
end

export type Engine = {
	import: (string) -> any,
	config: any,
	graphs: any,
	physics: any,
	skater: any,
	controls: any,
	camera: any,
	presentation: any,
	controller_input: any,
	published: any,
	capabilities: { any },
	modules: { [string]: any },
	packet: number,
	failure: string?,
	timings: { { name: string, seconds: number } },
	bone_names: { string },
}

-- ROBLOX: режимы производительности ядра (как Performance mode / host.Lite
-- в примерочном плейсе). Физику доски не меняют, облегчают тело райдера:
--   "off"     — полный солвер, как в Rust;
--   "k"       — кинематический райдер (тело по анимации, без полного солвера);
--   "rider+k" — плюс меньше проходов солвера по скелету;
--   "both+k"  — плюс векторные ядра солвера (дефолт примерочного плейса).
-- В эмуляторе: off 15.7 мс/тик, k 9.5, both+k 9.8 (tools/emu/perf_modes.luau).
engine.PERFORMANCE = {
	off = { solver = nil, rider = nil },
	k = { solver = nil, rider = {} },
	["rider+k"] = { solver = { rider_passes = "auto" }, rider = {} },
	["both+k"] = { solver = { rider_passes = "auto", vector_kernels = true }, rider = {} },
}
engine.DEFAULT_PERFORMANCE = "k"

function engine.set_performance(mode: string?): string
	local name = if mode and engine.PERFORMANCE[mode] then mode else engine.DEFAULT_PERFORMANCE
	local m = engine.PERFORMANCE[name]
	local import = engine.import()
	import("skate_core/physics/solver").set_mode(m.solver)
	import("skate_game/physics/solve").set_rider(m.rider)
	return name
end

-- Загрузить всё ядро. map — таблица SkateMap (см. world_map.build).
-- log(text) — необязательный вывод этапов; yield() — уступить кадр между этапами.
function engine.boot(map: any, log: ((string) -> ())?, yield: (() -> ())?): Engine
	local import = engine.import()
	local timings = {}
	local function stage<T>(name: string, f: () -> T): T
		local t = os.clock()
		local ok, result = xpcall(f, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end)
		local seconds = os.clock() - t
		table.insert(timings, { name = name, seconds = seconds })
		if log then
			log(string.format("[skate3] %-12s %6.2f s%s", name, seconds, if ok then "" else " FAILED"))
		end
		if not ok then
			error(string.format("skate3 boot %s: %s", name, tostring(result)), 0)
		end
		if yield then
			yield()
		end
		return result
	end

	local config = stage("config", function()
		return import("skate_game/config").Config.from_env({}, { skate3_assets = "roblox:sim_data" })
	end)
	config.map = map
	stage("input", function()
		import("skate_data/input_config").StockGameplayConfig.load(config.asset_root)
		return true
	end)
	local manifest = stage("manifest", function()
		return import("skate_data").GameAssets.load(config.asset_root)
	end)
	local graphs = stage("graphs", function()
		return import("skate_game/graph_runtime").StockGraphs.load(config.asset_root, manifest)
	end)
	local physics_mod = import("skate_game/physics")
	local physics = stage("physics", function()
		return physics_mod.GamePhysics.load_with_difficulty(config.asset_root, map, config.difficulty)
	end)
	local skater = stage("skater", function()
		local Difficulty = import("skate_game/difficulty").Difficulty
		return physics_mod.SkaterRuntime.load(config.asset_root, graphs, physics, Difficulty.profile_key(config.difficulty))
	end)
	local controls = stage("controls", function()
		return physics_mod.PlayerControls.load(config.asset_root)
	end)
	local camera = stage("camera", function()
		local shake = ReplicatedStorage.Skate3.sim_data.misc:FindFirstChild("camera_shake")
		return import("skate_game/camera").spawn(config, if shake then require(shake :: ModuleScript) else nil)
	end)

	local input = import("skate_game/input")
	local controllers = import("skate_game/input/controllers")
	local platform = import("skate_game/input/platform")
	return {
		import = import,
		config = config,
		graphs = graphs,
		physics = physics,
		skater = skater,
		controls = controls,
		camera = camera,
		presentation = import("skate_game/presentation").Presentation.default(),
		controller_input = controllers.ControllerInput.default(),
		published = input.PublishedTickInput.default(),
		capabilities = {
			platform.CapabilityCache.default(),
			platform.CapabilityCache.default(),
			platform.CapabilityCache.default(),
			platform.CapabilityCache.default(),
		},
		modules = {
			input = input,
			controls = import("skate_game/physics/controls"),
			physics = physics_mod,
			animation = import("skate_game/animation"),
			board_runtime = import("skate_core/physics/board_runtime"),
			board = import("skate_core/physics/board"),
		},
		packet = 0,
		failure = nil,
		timings = timings,
		bone_names = skater.animation.evaluator.frames.bone_names,
	}
end

-- Длина тика в секундах (SimulationClock может менять её, например в слоу-мо).
function engine.period(self: Engine): number
	return self.modules.physics.GamePhysics.period(self.physics) * 1e-9
end

-- Один тик симуляции. gamepad — состояние в формате XInput:
-- { buttons, left_trigger, right_trigger, left_x, left_y, right_x, right_y }.
function engine.tick(self: Engine, gamepad: any)
	local modules = self.modules
	self.packet = (self.packet + 1) % 4294967296
	local raw = { now = os.clock(), { subtype = 1, number = self.packet, gamepad = gamepad } }
	modules.input.poll_controllers(self.controller_input, nil, false, true, self.capabilities, raw)
	modules.input.publish_actions(self.controller_input, self.published, true, false, nil)
	modules.controls.sample(self.published, self.physics, self.skater, self.camera, self.controls)
	local failure = modules.physics.advance(self.physics, self.skater, self.controls, self.graphs, self.published, self.camera, nil)
	if failure ~= nil and self.failure == nil then
		self.failure = tostring(failure)
	end
end

-- Состояние для HUD/отладки: позиция деки (метры), скорость, физическое состояние.
function engine.status(self: Engine): any
	local BoardRuntime = self.modules.board_runtime.BoardRuntime
	local BodyId = self.modules.board.BodyId
	local deck = BodyId.index(BodyId.Deck)
	local transform = BoardRuntime.part_transforms(self.physics.board)[deck + 1]
	local rates = self.physics.board.bodies[deck + 1].rates
	local v = rates.linear_velocity
	local state = self.skater.player_input.physical.state
	return {
		position = transform.translation,
		basis = transform.basis,
		velocity = { v.x, v.y, v.z },
		speed = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z),
		state = state.state_16,
		category = state.category_12,
		tick = self.physics.ticks,
	}
end

-- Мировые матрицы всех костей скейтера (метры, столбцы 4x4) — в том же
-- порядке, что bone_names. Корень: animated_skeleton.roots.animation_to_world.
function engine.bone_world(self: Engine, out: { any }): { any }
	local anim = self.modules.animation
	local root = anim.native_matrix(self.skater.animated_skeleton.roots.animation_to_world)
	local pose = self.skater.render_pose
	for i = 1, #pose do
		local m = anim.native_matrix(pose[i])
		local r = out[i]
		if r == nil then
			r = { {}, {}, {}, {} }
			out[i] = r
		end
		for c = 1, 4 do
			local col = m[c]
			local rc = r[c]
			for row = 1, 4 do
				rc[row] = root[1][row] * col[1] + root[2][row] * col[2] + root[3][row] * col[3] + root[4][row] * col[4]
			end
		end
	end
	return out
end

-- Мировые CFrame всех костей в стадах (для отрисовки и интерполяции).
function engine.bone_cframes(self: Engine, out: { CFrame }): { CFrame }
	local anim = self.modules.animation
	local root = anim.native_matrix(self.skater.animated_skeleton.roots.animation_to_world)
	local pose = self.skater.render_pose
	local s = engine.STUDS_PER_METRE
	for i = 1, #pose do
		local m = anim.native_matrix(pose[i])
		local w = table.create(4)
		for c = 1, 4 do
			local col = m[c]
			w[c] = {
				root[1][1] * col[1] + root[2][1] * col[2] + root[3][1] * col[3] + root[4][1] * col[4],
				root[1][2] * col[1] + root[2][2] * col[2] + root[3][2] * col[3] + root[4][2] * col[4],
				root[1][3] * col[1] + root[2][3] * col[2] + root[3][3] * col[3] + root[4][3] * col[4],
			}
		end
		-- ROBLOX: столбцы 1..3 — оси кости, 4 — позиция; CFrame хочет строки.
		out[i] = CFrame.new(
			w[4][1] * s, w[4][2] * s, w[4][3] * s,
			w[1][1], w[2][1], w[3][1],
			w[1][2], w[2][2], w[3][2],
			w[1][3], w[2][3], w[3][3]
		):Orthonormalize()
	end
	return out
end

-- CFrame деки в стадах.
function engine.deck_cframe(self: Engine): CFrame
	local t = engine.deck_transform(self)
	local p = t.translation
	local c = t.basis.columns
	local s = engine.STUDS_PER_METRE
	return CFrame.fromMatrix(
		Vector3.new(p.x * s, p.y * s, p.z * s),
		Vector3.new(c[1][1], c[1][2], c[1][3]),
		Vector3.new(c[2][1], c[2][2], c[2][3]),
		Vector3.new(c[3][1], c[3][2], c[3][3])
	):Orthonormalize()
end

-- Мировая высота (метры) одной кости по индексу bone_names — дёшево, без всей позы.
function engine.bone_height(self: Engine, index: number): number
	local anim = self.modules.animation
	local root = anim.native_matrix(self.skater.animated_skeleton.roots.animation_to_world)
	local m = anim.native_matrix(self.skater.render_pose[index])
	local t = m[4]
	return root[1][2] * t[1] + root[2][2] * t[2] + root[3][2] * t[3] + root[4][2] * t[4]
end

-- ROBLOX: умножить горизонтальную скорость доски и тела райдера (буст после
-- спид-глитча, клавиши + и -). Вертикальную не трогаем, чтобы не подбросить.
function engine.scale_speed(self: Engine, factor: number)
	local function scale(rates: any)
		local v = rates.linear_velocity
		v.x *= factor
		v.z *= factor
	end
	local board = self.physics.board
	for _, body in self.modules.board_runtime.BoardRuntime.bodies(board) do
		scale(body.rates)
	end
	if board.hook and board.hook.body then
		scale(board.hook.body.rates)
	end
	local skeleton = self.skater.skeleton
	if skeleton and skeleton.bodies then
		for _, body in skeleton.bodies do
			scale(body.rates)
		end
	end
end

-- ROBLOX: поставить горизонтальную скорость (м/с) доске и телу райдера —
-- когда после глитча доска почти стоит и умножать нечего.
function engine.set_speed(self: Engine, vx: number, vz: number)
	local function set(rates: any)
		local v = rates.linear_velocity
		v.x = vx
		v.z = vz
	end
	local board = self.physics.board
	for _, body in self.modules.board_runtime.BoardRuntime.bodies(board) do
		set(body.rates)
	end
	if board.hook and board.hook.body then
		set(board.hook.body.rates)
	end
	local skeleton = self.skater.skeleton
	if skeleton and skeleton.bodies then
		for _, body in skeleton.bodies do
			set(body.rates)
		end
	end
end

-- Мировая матрица деки (метры) из физики доски.
function engine.deck_transform(self: Engine): any
	local BoardRuntime = self.modules.board_runtime.BoardRuntime
	local BodyId = self.modules.board.BodyId
	return BoardRuntime.part_transforms(self.physics.board)[BodyId.index(BodyId.Deck) + 1]
end

return engine
