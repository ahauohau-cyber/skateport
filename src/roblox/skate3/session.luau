--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: сеанс катания на клиенте. Включается админ-командой (атрибут
-- игрока Skate3 = true), выключается ею же.
--
-- Что делает:
--   1. собирает карту SKATE из Workspace (world_map);
--   2. грузит ядро sim с доской под ногами персонажа (engine.boot);
--   3. каждый кадр: клавиатура -> геймпад -> тики ядра с шагом 1/60;
--   4. ставит доску (board_model) и позу скейтера на R15 (r15_pose);
--   5. камера следует за скейтером.
-- Ходьба тоже идёт через ядро: в Skate 3 сойти с доски — Y (клавиша R).

local RunService = game:GetService("RunService")

local engine = require(script.Parent.engine)
local world_map = require(script.Parent.world_map)
local board_model = require(script.Parent.board_model)
local r15_pose = require(script.Parent.r15_pose)
local keyboard_pad = require(script.Parent.Parent.keyboard_pad)
local fixed_step = require(script.Parent.Parent.fixed_step)

local session = {}

local S = engine.STUDS_PER_METRE

export type Session = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	engine: any,
	board: any,
	rig: any,
	pad: any,
	clock: any,
	bones: { any },
	connections: { RBXScriptConnection },
	saved: { [string]: any },
	camera_cf: CFrame?,
	camera_prev: Vector3?,
	camera_forward: Vector3?,
	status_text: TextLabel?,
	stopped: boolean,
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
	label.Size = UDim2.new(0, 420, 0, 22)
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

-- Камера сзади: смотрит на скейтера (корень персонажа = таз скейтера) и
-- держится позади по направлению движения. Когда стоим — направление прежнее.
local function update_camera(self: Session, dt: number)
	local camera = workspace.CurrentCamera
	if camera == nil or dt <= 0 then
		return
	end
	local root = self.character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root == nil then
		return
	end
	local here = root.Position
	local previous = self.camera_prev or here
	self.camera_prev = here
	local moved = (here - previous) / dt
	moved = Vector3.new(moved.X, 0, moved.Z)
	local forward = self.camera_forward or Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if moved.Magnitude > 2 then
		forward = forward:Lerp(moved.Unit, 1 - math.exp(-dt * 4))
	end
	if forward.Magnitude < 1e-3 then
		forward = Vector3.zAxis
	end
	forward = forward.Unit
	self.camera_forward = forward
	local target = here + Vector3.new(0, 1.5, 0)
	local desired = target - forward * 12 + Vector3.new(0, 4, 0)
	local current = self.camera_cf
	local alpha = 1 - math.exp(-dt * 8)
	local position = if current then current.Position:Lerp(desired, alpha) else desired
	self.camera_cf = CFrame.lookAt(position, target)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = self.camera_cf :: CFrame
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

	-- Доска встаёт под ногами, носом туда, куда смотрит персонаж.
	local feet = root.Position - Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)
	local look = root.CFrame.LookVector
	-- В ядре доска едет по +Z; Roblox смотрит в -Z. heading — поворот вокруг Y.
	local heading = math.atan2(look.X, look.Z)
	local built = world_map.build(workspace, feet, heading)
	label.Text = string.format("skate3: карта %d треугольников, %d рельсов, загрузка ядра...", built.triangles, built.rails)
	task.wait()

	local ok, result = pcall(engine.boot, built.map, function(line)
		print(line)
		label.Text = line
	end, function()
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
		bones = {},
		connections = {},
		saved = { walk = humanoid.WalkSpeed, jump = humanoid.JumpPower, platform = humanoid.PlatformStand, collide = {} },
		camera_cf = nil,
		camera_prev = nil,
		camera_forward = nil,
		status_text = label,
		stopped = false,
	}
	self.rig = r15_pose.bind(character, result.bone_names, S)
	if self.rig == nil then
		warn("skate3: персонаж не R15 — поза не переносится, видна только доска")
	end

	humanoid.PlatformStand = true
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	set_animations(character, humanoid, false)
	set_collide(character, self.saved.collide, false)

	-- Ядро и доска — до физики Roblox; поза — после аниматора.
	table.insert(self.connections, RunService.PreSimulation:Connect(function(dt)
		if self.stopped then
			return
		end
		local e = self.engine
		local gamepad = keyboard_pad.gamepad(self.pad)
		local t = os.clock()
		local ticks = fixed_step.advance(self.clock, dt, function()
			return engine.period(e)
		end, function()
			if e.failure == nil then
				engine.tick(e, gamepad)
			end
		end)
		local cost = os.clock() - t
		if e.failure ~= nil then
			label.Text = "skate3: ядро остановилось: " .. tostring(e.failure)
			return
		end
		board_model.place(self.board, engine.deck_transform(e))
		if self.rig then
			engine.bone_world(e, self.bones)
			r15_pose.apply(self.rig, self.bones)
		end
		local st = engine.status(e)
		label.Text = string.format("skate3: состояние %d  скорость %.1f м/с  тиков %d  %.1f мс", st.state, st.speed, ticks, cost * 1000)
	end))
	table.insert(self.connections, RunService.RenderStepped:Connect(function(dt)
		if not self.stopped then
			update_camera(self, dt)
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
	local humanoid = self.humanoid
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
