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

-- Мировая матрица деки (метры) из физики доски.
function engine.deck_transform(self: Engine): any
	local BoardRuntime = self.modules.board_runtime.BoardRuntime
	local BodyId = self.modules.board.BodyId
	return BoardRuntime.part_transforms(self.physics.board)[BodyId.index(BodyId.Deck) + 1]
end

return engine
