--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: сеанс катания на клиенте. Включается админ-командой (атрибут
-- игрока Skate3 = true), выключается ею же.
--
-- Что делает:
--   1. собирает карту SKATE из Workspace: детали, меши, Terrain (world_map);
--   2. грузит ядро sim с доской под ногами персонажа (engine.boot);
--   3. каждый кадр: клавиатура -> геймпад -> тики ядра с шагом 1/60;
--   4. между тиками плавно смешивает позы (кадр Roblox идёт чаще 60 Гц,
--      без смешивания картинка дёргается);
--   5. ставит доску и позу скейтера на R15, камера мягко следует сзади.
-- Ходьба тоже идёт через ядро: в Skate 3 сойти с доски — Y (клавиша R).
--
-- Горячие клавиши сверху раскладки keyboard_pad:
--   G — спид-глитч (speed_glitch), с места или прямо из катания («дабл глитч»).
--       Глитч запускается только этой клавишей;
--   + / - — множитель буста глитча (×1 … ×4, по умолчанию ×1.5);
--   J — Christ Air: держишь в воздухе — ядро делает родной трюк (триггер + B).
--       На земле клавиша ничего не делает.

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local engine = require(script.Parent.engine)
local world_map = require(script.Parent.world_map)
local board_model = require(script.Parent.board_model)
local r15_pose = require(script.Parent.r15_pose)
local bone_pose = require(script.Parent.bone_pose)
local speed_glitch = require(script.Parent.speed_glitch)
local keyboard_pad = require(script.Parent.Parent.keyboard_pad)
local fixed_step = require(script.Parent.Parent.fixed_step)

local session = {}

-- Кнопки XInput.
local B, LT = 0x2000, 255

-- Камера: расстояние и высота (стады), скорости сглаживания (1/с).
-- Камера не догоняет скейтера по позиции (иначе на скорости она отстаёт),
-- а держится ровно позади точки взгляда; сглаживаются только направление
-- и высота, поэтому на кочках и поворотах картинка не дёргается.
session.CAMERA = {
	distance = 12,
	height = 4,
	look_height = 2.2,
	focus = 14, -- точка взгляда по горизонтали
	focus_y = 4, -- точка взгляда по вертикали (гасит подпрыгивания)
	turn = 2.2, -- поворот за направлением движения
	min_speed = 3, -- стад/с: медленнее — направление не меняем
}

export type Snapshot = { deck: CFrame, bones: { CFrame } }

export type Session = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	engine: any,
	board: any,
	rig: any,
	pad: any,
	clock: any,
	previous: Snapshot?,
	current: Snapshot?,
	render_bones: { CFrame },
	connections: { RBXScriptConnection },
	saved: { [string]: any },
	camera_pos: Vector3?,
	camera_focus: Vector3?,
	camera_forward: Vector3?,
	camera_prev: Vector3?,
	camera_vel: Vector3?,
	status_text: TextLabel?,
	stopped: boolean,
	glitch: any,
	hips_index: number?,
	christ_held: boolean,
	pose_override: r15_pose.Override?,
	custom: bone_pose.Rig?, -- своя модель на костях вместо аватара (тест)
	glitch_watch: number, -- тиков осталось мерить скорость после глитча
	boost: number, -- множитель буста спид-глитча (клавиши + и -)
	glitch_before: number, -- м/с: скорость доски, когда глитч начался из катания
	boost_wait: number, -- тиков ждать приземления, чтобы применить буст
	ramp: { from: number, to: number, tick: number }?, -- плавный разгон после глитча
	glitch_best: number,
}

local function set_animations(character: Model, humanoid: Humanoid, on: boolean)
	local animate = character:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		animate.Enabled = on
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator and not on then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end
end

local function set_collide(character: Model, saved: { [string]: any }, on: boolean)
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") then
			if on then
				local was = saved[d:GetFullName()]
				if was ~= nil then
					d.CanCollide = was
				end
			else
				saved[d:GetFullName()] = d.CanCollide
				d.CanCollide = false
			end
		end
	end
end

local function make_status(player: Player): TextLabel
	local gui = Instance.new("ScreenGui")
	gui.Name = "Skate3Status"
	gui.ResetOnSpawn = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 520, 0, 22)
	label.Position = UDim2.new(0, 10, 1, -32)
	label.BackgroundTransparency = 0.5
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.Code
	label.TextSize = 14
	label.Text = "skate3: загрузка..."
	label.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	return label
end

local function snapshot(e: any, reuse: Snapshot?): Snapshot
	local s = reuse or { deck = CFrame.identity, bones = {} }
	s.deck = engine.deck_cframe(e)
	engine.bone_cframes(e, s.bones)
	return s
end

-- Экспоненциальное сглаживание, не зависящее от частоты кадров.
local function damp(rate: number, dt: number): number
	return 1 - math.exp(-rate * dt)
end

local function update_camera(self: Session, dt: number)
	local camera = workspace.CurrentCamera
	if camera == nil or dt <= 0 then
		return
	end
	local root = self.character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root == nil then
		return
	end
	local cfg = session.CAMERA
	local here = root.Position
	local previous = self.camera_prev or here
	self.camera_prev = here
	local raw = (here - previous) / dt
	raw = Vector3.new(raw.X, 0, raw.Z)
	-- Скорость тоже сглаживаем: таз раскачивается при толчках.
	local velocity = if self.camera_vel then self.camera_vel:Lerp(raw, damp(6, dt)) else raw
	self.camera_vel = velocity
	-- Направление камеры — угол рысканья, догоняет направление движения по
	-- кратчайшему повороту (без провала через ноль при развороте).
	local forward = self.camera_forward or Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if forward.Magnitude < 1e-3 then
		forward = Vector3.zAxis
	end
	local yaw = math.atan2(forward.X, forward.Z)
	if velocity.Magnitude > cfg.min_speed then
		local target = math.atan2(velocity.X, velocity.Z)
		local delta = (target - yaw + math.pi) % (2 * math.pi) - math.pi
		yaw += delta * damp(cfg.turn, dt)
	end
	forward = Vector3.new(math.sin(yaw), 0, math.cos(yaw))
	self.camera_forward = forward

	local focus_target = here + Vector3.new(0, cfg.look_height, 0)
	local focus = self.camera_focus
	if focus then
		local horizontal = Vector3.new(focus.X, 0, focus.Z):Lerp(Vector3.new(focus_target.X, 0, focus_target.Z), damp(cfg.focus, dt))
		local y = focus.Y + (focus_target.Y - focus.Y) * damp(cfg.focus_y, dt)
		focus = Vector3.new(horizontal.X, y, horizontal.Z)
	else
		focus = focus_target
	end
	self.camera_focus = focus
	local position = focus - forward * cfg.distance + Vector3.new(0, cfg.height, 0)
	self.camera_pos = position
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(position, focus)
end

-- Настройки глитча можно переопределить атрибутами игрока (тики по 1/60 с):
-- SkateGlitchDropHold, SkateGlitchSettle, SkateGlitchXHold, SkateGlitchRbAt,
-- SkateGlitchRbHold, SkateGlitchYAfterRb, SkateGlitchYHold.
local GLITCH_ATTRIBUTES = {
	drop_hold = "SkateGlitchDropHold",
	settle = "SkateGlitchSettle",
	x_hold = "SkateGlitchXHold",
	rb_at = "SkateGlitchRbAt",
	rb_hold = "SkateGlitchRbHold",
	y_after_rb = "SkateGlitchYAfterRb",
	y_hold = "SkateGlitchYHold",
}

-- ROBLOX: буст спид-глитча. Ядро даёт после глитча ~13-14 м/с всегда, и
-- повторный глитч из катания скорость не складывает. Поэтому после приземления
-- ставим скорость max(до глитча, после) × множитель — так «дабл глитч»
-- разгоняет дальше. Множитель меняется клавишами + и - (×1 — как в ядре).
local BOOST_STEPS = { 1, 1.25, 1.5, 2, 2.5, 3, 4 }
local BOOST_CAP = 70 -- м/с: выше доска начинает пролетать сквозь стены
local GLITCH_BASE = 14 -- м/с: столько ядро даёт после удачного глитча (Studio)
local RAMP_TICKS = 20
local SAFE_DISMOUNT = 12 -- м/с: быстрее сход с доски = падение

local function riding(state: number): boolean
	return state == 100 or state == 103
end

local function horizontal_speed(e: any): number
	local v = engine.status(e).velocity
	return math.sqrt(v[1] * v[1] + v[3] * v[3])
end

local function step_boost(self: any, dir: number)
	local index = 1
	for i, v in BOOST_STEPS do
		if math.abs(v - self.boost) < 1e-3 then
			index = i
		end
	end
	index = math.clamp(index + dir, 1, #BOOST_STEPS)
	self.boost = BOOST_STEPS[index]
	self.player:SetAttribute("SkateBoost", self.boost)
end

local function start_glitch(self: any)
	local settings = speed_glitch.defaults()
	for key, attribute in GLITCH_ATTRIBUTES do
		local value = self.player:GetAttribute(attribute)
		if type(value) == "number" then
			(settings :: any)[key] = value
		end
	end
	self.glitch.settings = settings
	if self.glitch.phase == "idle" then
		-- Глитч из катания: запомнить скорость, чтобы буст складывался.
		local e = self.engine
		local state = e.skater.player_input.physical.state.state_16
		self.glitch_before = if riding(state) then horizontal_speed(e) else 0
		self.ramp = nil
		if self.glitch_before > SAFE_DISMOUNT then
			-- Сойти с доски на большой скорости — падение (как в Skate 3).
			-- Притормаживаем до безопасной; скорость вернётся после глитча.
			local v = engine.status(e).velocity
			local k = SAFE_DISMOUNT / self.glitch_before
			engine.set_speed(e, v[1] * k, v[3] * k)
		end
	end
	speed_glitch.start(self.glitch)
end

-- ROBLOX: карта из Workspace собирается долго (лучи по Terrain, меши), поэтому
-- держим последнюю и берём её снова, пока игрок в пределах CACHE_RADIUS от
-- места сборки и в Workspace не добавляли/не убирали детали.
local CACHE_RADIUS = 200 -- стады
local map_cache: { centre: Vector3, map: any }? = nil
local cache_watch: { RBXScriptConnection }? = nil

local function cached_map(feet: Vector3, heading: number, log: (string) -> ()): any
	if cache_watch == nil then
		local function invalidate(item: Instance)
			if item:IsA("BasePart") and item:GetAttribute("SkateIgnore") ~= true and item:FindFirstAncestorWhichIsA("Model") == nil then
				map_cache = nil
			elseif item:IsA("BasePart") then
				-- Детали внутри моделей: персонажи и наши модели не считаем.
				local model = item:FindFirstAncestorOfClass("Model")
				if model and model:GetAttribute("SkateIgnore") ~= true and model:FindFirstChildOfClass("Humanoid") == nil and model:FindFirstChildOfClass("AnimationController") == nil then
					map_cache = nil
				end
			end
		end
		cache_watch = {
			workspace.DescendantAdded:Connect(invalidate),
			workspace.DescendantRemoving:Connect(invalidate),
		}
	end
	local cache = map_cache
	local map
	if cache and (cache.centre - feet).Magnitude <= CACHE_RADIUS then
		log("[skate3] карта из кэша")
		map = cache.map
	else
		local t = os.clock()
		local built = world_map.build(workspace, feet, heading, {
			yield = function()
				task.wait()
			end,
			log = log,
		})
		log(string.format("[skate3] карта собрана за %.2f с", os.clock() - t))
		map = built.map
		map_cache = { centre = feet, map = map }
		task.wait()
	end
	-- Своя точка появления и направление; геометрия общая.
	local copy = table.clone(map)
	copy.spawn = { feet.X / engine.STUDS_PER_METRE, feet.Y / engine.STUDS_PER_METRE, feet.Z / engine.STUDS_PER_METRE }
	copy.heading = heading
	return copy
end

local function airborne(state: number): boolean
	return state >= 200 and state < 300
end

function session.start(player: Player): Session?
	local character = player.Character
	if character == nil then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid == nil or root == nil then
		return nil
	end
	local label = make_status(player)
	local function log(line: string)
		print(line)
		label.Text = line
	end

	-- Доска встаёт под ногами, носом туда, куда смотрит персонаж.
	local feet = root.Position - Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)
	local look = root.CFrame.LookVector
	-- В ядре доска едет по +Z; heading — поворот вокруг Y.
	local heading = math.atan2(look.X, look.Z)
	local map = cached_map(feet, heading, log)

	engine.set_performance(player:GetAttribute("SkatePerf") :: string?)
	local ok, result = pcall(engine.boot, map, log, function()
		task.wait()
	end)
	if not ok then
		label.Text = "skate3: ошибка загрузки (см. вывод)"
		warn(result)
		return nil
	end

	local self: Session = {
		player = player,
		character = character,
		humanoid = humanoid,
		engine = result,
		board = board_model.new(workspace),
		rig = nil,
		pad = keyboard_pad.new(),
		clock = fixed_step.new(),
		previous = nil,
		current = nil,
		render_bones = {},
		connections = {},
		saved = {
			walk = humanoid.WalkSpeed,
			jump = humanoid.JumpPower,
			platform = humanoid.PlatformStand,
			anchored = root.Anchored,
			collide = {},
		},
		camera_pos = nil,
		camera_focus = nil,
		camera_forward = nil,
		camera_prev = nil,
		camera_vel = nil,
		status_text = label,
		stopped = false,
		glitch = speed_glitch.new(),
		hips_index = nil,
		christ_held = false,
		pose_override = nil,
		custom = nil,
		glitch_watch = 0,
		glitch_best = 0,
		boost = if type(player:GetAttribute("SkateBoost")) == "number" then player:GetAttribute("SkateBoost") :: number else 1.5,
		glitch_before = 0,
		boost_wait = 0,
		ramp = nil,
	}
	for i, name in result.bone_names do
		if string.upper(name) == "HIPS" then
			self.hips_index = i
		end
	end
	self.rig = r15_pose.bind(character, result.bone_names, engine.STUDS_PER_METRE)
	if self.rig == nil then
		warn("skate3: персонаж не R15 — поза не переносится, видна только доска")
	end
	-- Своя модель вместо аватара: атрибут игрока SkateRig = имя модели в
	-- Workspace или ReplicatedStorage (по умолчанию CustomRig, если такая есть;
	-- SkateRig = "none" — без неё).
	local rig_name = player:GetAttribute("SkateRig")
	if type(rig_name) ~= "string" then
		rig_name = "CustomRig"
	end
	local template = workspace:FindFirstChild(rig_name :: string) or game:GetService("ReplicatedStorage"):FindFirstChild(rig_name :: string)
	if template and template:IsA("Model") then
		local ok, custom = pcall(function()
			return bone_pose.bind(template :: Model, result.bone_names, workspace, engine.reference_pose(result, "RIG_TPOSE"))
		end)
		if ok and custom then
			self.custom = custom
			bone_pose.hide(custom, character)
		elseif not ok then
			warn("skate3: модель " .. (rig_name :: string) .. ": " .. tostring(custom))
		end
	end

	humanoid.PlatformStand = true
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	-- Корень ставим сами каждый кадр: физика Roblox его не трогает.
	root.Anchored = true
	set_animations(character, humanoid, false)
	set_collide(character, self.saved.collide, false)

	self.current = snapshot(result, nil)
	self.previous = snapshot(result, nil)

	-- ROBLOX: Animator пишет Transform суставов на шаге PreAnimation, то есть
	-- после PreRender. Поэтому позу суставов ставим ещё раз в PreSimulation
	-- (после аниматора), иначе он сбрасывает её в стойку покоя.
	table.insert(self.connections, RunService.PreSimulation:Connect(function()
		if not self.stopped and self.rig and #self.render_bones > 0 then
			r15_pose.apply(self.rig, self.render_bones, self.pose_override)
		end
	end))

	-- Тики ядра и отрисовка — перед кадром (PreRender).
	table.insert(self.connections, RunService.PreRender:Connect(function(dt)
		if self.stopped then
			return
		end
		local e = self.engine
		local gamepad = keyboard_pad.gamepad(self.pad)
		local t = os.clock()
		local ticks, alpha = fixed_step.advance(self.clock, dt, function()
			return engine.period(e)
		end, function()
			if e.failure ~= nil then
				return
			end
			local pad = gamepad
			local extra = 0
			local state = e.skater.player_input.physical.state.state_16
			local rt = 0
			local was_running = self.glitch.phase ~= "idle"
			if was_running and self.hips_index then
				-- Доска в руках: дека почти на высоте таза (на земле она ~0.8 м ниже).
				local hips_y = engine.bone_height(e, self.hips_index)
				local deck_y = engine.deck_transform(e).translation.y
				extra, rt = speed_glitch.step(self.glitch, state, hips_y - deck_y < 0.45)
			end
			local lt = 0
			if self.christ_held and airborne(state) then
				-- Christ Air в ядре: триггер грэба + B в воздухе.
				extra = bit32.bor(extra, B)
				lt = LT
			end
			if extra ~= 0 or lt ~= 0 or rt ~= 0 then
				pad = table.clone(gamepad)
				pad.buttons = bit32.bor(pad.buttons, extra)
				pad.left_trigger = math.max(pad.left_trigger, lt)
				pad.right_trigger = math.max(pad.right_trigger, rt)
			end
			engine.tick(e, pad)
			if was_running and self.glitch.phase == "idle" then
				self.glitch_watch = 150
				self.glitch_best = 0
				-- Буст — только если макрос дошёл до конца (RB → Y), а не
				-- прервался: иначе он сработал бы на обычном приземлении.
				if self.glitch.completed then
					self.boost_wait = 60
				end
			end
			local ramp = self.ramp
			if ramp then
				-- Плавный разгон за RAMP_TICKS тиков: резкий скачок скорости
				-- иногда сбрасывает райдера с доски.
				ramp.tick += 1
				local speed = ramp.from + (ramp.to - ramp.from) * math.min(ramp.tick / RAMP_TICKS, 1)
				local v = engine.status(e).velocity
				local dir = Vector3.new(v[1], 0, v[3])
				if dir.Magnitude < 3 then
					-- Почти стоим: туда, куда смотрит доска (ядро катит её по +Z деки).
					dir = engine.deck_cframe(e).ZVector * Vector3.new(1, 0, 1)
				end
				if dir.Magnitude > 1e-3 then
					dir = dir.Unit * speed
					engine.set_speed(e, dir.X, dir.Z)
				end
				if ramp.tick >= RAMP_TICKS or not riding(e.skater.player_input.physical.state.state_16) then
					self.ramp = nil
				end
			end
			if self.boost_wait > 0 then
				self.boost_wait -= 1
				local now = e.skater.player_input.physical.state.state_16
				if riding(now) then
					-- Приземлились на доску: складываем скорость с множителем.
					self.boost_wait = 0
					local v = horizontal_speed(e)
					-- Ядро после глитча даёт ~14 м/с; если доска приземлилась почти
					-- без скорости, считаем базой это значение.
					local base = math.max(v, self.glitch_before, if v < 3 then GLITCH_BASE else 0)
					local target = math.min(base * self.boost, BOOST_CAP)
					if target > v then
						self.ramp = { from = v, to = target, tick = 0 }
					end
				end
			end
			if self.glitch_watch > 0 then
				self.glitch_watch -= 1
				local speed = engine.status(e).speed
				if speed > self.glitch_best then
					self.glitch_best = speed
				end
				if self.glitch_watch == 0 then
					-- Итог для подбора настроек: лучшая скорость за 2.5 с после глитча.
					self.player:SetAttribute("SkateGlitchSpeed", self.glitch_best)
				end
			end
			-- Две последние позы для смешивания между тиками.
			local old = self.previous
			self.previous = self.current
			self.current = snapshot(e, old)
		end)
		local cost = os.clock() - t
		if e.failure ~= nil then
			label.Text = "skate3: ядро остановилось: " .. tostring(e.failure)
			return
		end

		local a, b = self.previous :: Snapshot, self.current :: Snapshot
		board_model.place(self.board, a.deck:Lerp(b.deck, alpha))
		local bones = self.render_bones
		for i, cf in b.bones do
			local from = a.bones[i]
			bones[i] = if from then from:Lerp(cf, alpha) else cf
		end
		if self.rig then
			r15_pose.apply(self.rig, bones, nil)
			self.pose_override = nil
		end
		if self.custom and #self.render_bones > 0 then
			bone_pose.apply(self.custom, self.render_bones)
			bone_pose.keep_hidden(self.custom)
		end
		update_camera(self, dt)

		local st = engine.status(e)
		local extras = {}
		if self.glitch.phase ~= "idle" then
			table.insert(extras, "спид-глитч: " .. self.glitch.phase)
		end
		if self.christ_held then
			table.insert(extras, "Christ Air")
		end
		label.Text = string.format(
			"skate3: состояние %d  скорость %.1f м/с  буст ×%.2g (+/-)  тиков %d  %.1f мс%s",
			st.state,
			st.speed,
			self.boost,
			ticks,
			cost * 1000,
			if #extras > 0 then "  [" .. table.concat(extras, ", ") .. "]" else ""
		)
	end))

	table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.Equals or key == Enum.KeyCode.KeypadPlus then
			step_boost(self, 1)
		elseif key == Enum.KeyCode.Minus or key == Enum.KeyCode.KeypadMinus then
			step_boost(self, -1)
		elseif input.KeyCode == Enum.KeyCode.G then
			start_glitch(self)
		elseif input.KeyCode == Enum.KeyCode.J then
			self.christ_held = true
		end
	end))
	table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.J then
			self.christ_held = false
		end
	end))
	table.insert(self.connections, humanoid.Died:Connect(function()
		session.stop(self)
	end))
	return self
end

function session.stop(self: Session)
	if self.stopped then
		return
	end
	self.stopped = true
	for _, c in self.connections do
		c:Disconnect()
	end
	keyboard_pad.destroy(self.pad)
	board_model.destroy(self.board)
	if self.rig then
		r15_pose.reset(self.rig)
	end
	if self.custom then
		bone_pose.destroy(self.custom)
		self.custom = nil
	end
	local humanoid = self.humanoid
	local root = self.character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.Anchored = self.saved.anchored
	end
	if humanoid.Parent then
		humanoid.PlatformStand = self.saved.platform
		humanoid.WalkSpeed = self.saved.walk
		humanoid.JumpPower = self.saved.jump
		set_animations(self.character, humanoid, true)
		set_collide(self.character, self.saved.collide, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
	end
	if self.status_text then
		local gui = self.status_text.Parent
		if gui then
			gui:Destroy()
		end
	end
end

return session
