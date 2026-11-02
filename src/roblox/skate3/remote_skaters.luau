--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: другие скейтеры на этом клиенте. Ядро у них не грузим: рисуем по
-- снимкам из Skate3Net.Stream (net_codec), как Interp/Remote примерочного плейса:
--   * буфер снимков и воспроизведение с задержкой ~100-250 мс: задержка сама
--     растёт с дрожанием сети, между снимками — плавное смешивание;
--   * резкий скачок (телепорт, респаун) не размазываем, а ставим сразу;
--   * LOD по расстоянию до камеры: ближние — поза каждый кадр, дальние — раз
--     в 2/4/8 кадров; вне поля зрения позу не считаем вовсе;
--   * бюджет времени на кадр: сначала ближние, остальным — в следующем кадре.
-- Модель: копия аватара игрока (R15) или его модель из атрибута SkateRigShown
-- (на костях, bone_pose). Настоящего персонажа на время катания прячем.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local net_codec = require(script.Parent.net_codec)
local skeleton = require(script.Parent.skeleton)
local r15_pose = require(script.Parent.r15_pose)
local bone_pose = require(script.Parent.bone_pose)
local board_model = require(script.Parent.board_model)

local remote_skaters = {}

local STUDS_PER_METRE = 1 / 0.28

remote_skaters.CONFIG = {
	min_delay = 0.08, -- с
	max_delay = 0.6,
	stale_after = 2.0, -- с без пакетов — прячем модель
	teleport = 40, -- стады за один интервал — не смешиваем
	keep = 32, -- снимков в буфере
	-- LOD: расстояние до камеры (стады) -> позу раз в N кадров.
	tiers = { { distance = 120, every = 1 }, { distance = 300, every = 2 }, { distance = 700, every = 4 } },
	far_every = 8,
	budget = 0.0015, -- с на позы всех скейтеров за кадр
	cull_radius = 8, -- стады: «размер» скейтера для проверки поля зрения
	cull_margin = 10, -- градусов запаса к полю зрения камеры
}

local INDEX: { [string]: number } = {}
for i, name in skeleton.BONE_NAMES do
	INDEX[name] = i
end

type Snap = net_codec.Snapshot & { arrival: number }

type Remote = {
	player: Player,
	snaps: { Snap },
	interval: number, -- с: среднее между снимками
	jitter: number,
	delay: number,
	last_arrival: number?,
	last_source: number?,
	model: Model?,
	r15: r15_pose.Rig?,
	custom: bone_pose.Rig?,
	board: board_model.Board?,
	rig_name: string,
	bones: { CFrame },
	hidden: { [Instance]: number },
	hidden_humanoid: { humanoid: Humanoid, distance: Enum.HumanoidDisplayDistanceType }?,
	frame: number, -- счётчик кадров для LOD
	shown: boolean,
	posed_hips: Vector3?,
}

local remotes: { [Player]: Remote } = {}
local folder: Folder? = nil
local tpose_cache: { CFrame }? = nil

local function container(): Folder
	if folder == nil or folder.Parent == nil then
		local f = Instance.new("Folder")
		f.Name = "Skate3Remotes"
		f.Parent = workspace
		folder = f
	end
	return folder :: Folder
end

local function tpose(): { CFrame }
	if tpose_cache == nil then
		tpose_cache = skeleton.tpose(STUDS_PER_METRE)
	end
	return tpose_cache :: { CFrame }
end

-- Спрятать настоящего персонажа (его двигает сервер грубо, 5 Гц).
local function hide_character(r: Remote)
	local character = r.player.Character
	if character == nil then
		return
	end
	-- Детали собираем один раз; дальше каждый кадр только ставим (камера
	-- Roblox сама меняет LocalTransparencyModifier).
	if next(r.hidden) ~= nil then
		for d in r.hidden do
			(d :: any).LocalTransparencyModifier = 1
		end
		return
	end
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			if r.hidden[d] == nil then
				r.hidden[d] = (d :: any).LocalTransparencyModifier
			end
			(d :: any).LocalTransparencyModifier = 1
		end
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and r.hidden_humanoid == nil then
		r.hidden_humanoid = { humanoid = humanoid, distance = humanoid.DisplayDistanceType }
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

local function show_character(r: Remote)
	for d, was in r.hidden do
		if d.Parent then
			(d :: any).LocalTransparencyModifier = was
		end
	end
	table.clear(r.hidden)
	local h = r.hidden_humanoid
	if h and h.humanoid.Parent then
		h.humanoid.DisplayDistanceType = h.distance
	end
	r.hidden_humanoid = nil
end

-- Копия аватара для позы R15: без скриптов, аниматора и физики.
local function clone_avatar(player: Player): Model?
	local character = player.Character
	if character == nil then
		return nil
	end
	local was = character.Archivable
	character.Archivable = true
	local ok, copy = pcall(function()
		return character:Clone()
	end)
	character.Archivable = was
	if not ok or copy == nil then
		return nil
	end
	local model = copy :: Model
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("Animator") or d:IsA("ForceField") or d:IsA("Sound") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.LocalTransparencyModifier = 0
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
		humanoid.EvaluateStateMachine = false
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.Anchored = true
	end
	model.Name = player.Name .. "_skate"
	model:SetAttribute("SkateIgnore", true)
	return model
end

local function destroy_model(r: Remote)
	if r.custom then
		r.custom.model:Destroy()
		r.custom = nil
	end
	if r.model then
		r.model:Destroy()
		r.model = nil
	end
	r.r15 = nil
	if r.board then
		board_model.destroy(r.board)
		r.board = nil
	end
	r.posed_hips = nil
end

-- Создать модель скейтера (лениво, при первом снимке).
local function build(r: Remote)
	local rig_name = r.player:GetAttribute("SkateRigShown")
	r.rig_name = if type(rig_name) == "string" then rig_name else ""
	local parent = container()
	if r.rig_name ~= "" then
		local template = workspace:FindFirstChild(r.rig_name) or ReplicatedStorage:FindFirstChild(r.rig_name)
		if template and template:IsA("Model") then
			local ok, custom = pcall(bone_pose.bind, template, skeleton.BONE_NAMES, parent, tpose())
			if ok and custom then
				custom.model.Name = r.player.Name .. "_skate"
				r.custom = custom
			end
		end
	end
	if r.custom == nil then
		local model = clone_avatar(r.player)
		if model then
			model.Parent = parent
			r.model = model
			r.r15 = r15_pose.bind(model, skeleton.BONE_NAMES, STUDS_PER_METRE)
		end
	end
	r.board = board_model.new(parent)
	r.board.model.Name = r.player.Name .. "_board"
	r.shown = true
end

local function remote_of(player: Player): Remote
	local r = remotes[player]
	if r == nil then
		r = {
			player = player,
			snaps = {},
			interval = 1 / 15,
			jitter = 0,
			delay = 0.15,
			last_arrival = nil,
			last_source = nil,
			model = nil,
			r15 = nil,
			custom = nil,
			board = nil,
			rig_name = "",
			bones = table.create(#skeleton.BONE_NAMES),
			hidden = {},
			hidden_humanoid = nil,
			frame = math.random(0, 7), -- разносим дальних по кадрам
			shown = false,
			posed_hips = nil,
		}
		remotes[player] = r
	end
	return r
end

local function on_character(player: Player)
	local r = remotes[player]
	if r then
		show_character(r)
		destroy_model(r)
		r.shown = false
	end
end

local function drop(player: Player)
	local r = remotes[player]
	if r then
		destroy_model(r)
		show_character(r)
		remotes[player] = nil
	end
end

-- Отладка: свои снимки с сервера (атрибут SkateNetEcho) рисуем призраком сбоку.
local ECHO_OFFSET = Vector3.new(10, 0, 0)

local function is_echo(player: Player): boolean
	return player == Players.LocalPlayer and player:GetAttribute("SkateNetEcho") == true
end

local function receive(player: Player, packet: any)
	if (player == Players.LocalPlayer and not is_echo(player)) or player:GetAttribute("Skate3") ~= true then
		return
	end
	local snap = net_codec.decode(packet) :: Snap?
	if snap == nil then
		return
	end
	local now = workspace:GetServerTimeNow()
	snap.arrival = now
	local r = remote_of(player)
	-- Оценка интервала и дрожания (как delivery_observe в Interp).
	if r.last_source and r.last_arrival and snap.time > r.last_source then
		local gap = math.clamp(snap.time - r.last_source, 0.01, 2)
		r.interval += (gap - r.interval) * 0.1
		local arrival_gap = now - r.last_arrival
		r.jitter += (math.min(math.abs(arrival_gap - gap), 1) - r.jitter) * 0.1
	end
	r.last_source = snap.time
	r.last_arrival = now
	-- Вставка по времени; старые и повторы выбрасываем.
	local snaps = r.snaps
	local newest = snaps[#snaps]
	if newest and snap.time <= newest.time then
		return
	end
	table.insert(snaps, snap)
	while #snaps > remote_skaters.CONFIG.keep do
		table.remove(snaps, 1)
	end
end

-- Поза на момент t: смешивание двух соседних снимков (или последний).
local function sample(r: Remote, t: number): (CFrame?, Vector3?)
	local snaps = r.snaps
	local n = #snaps
	if n == 0 then
		return nil, nil
	end
	local a, b, alpha = snaps[n], snaps[n], 0
	if t <= snaps[1].time then
		a, b = snaps[1], snaps[1]
	else
		for i = n - 1, 1, -1 do
			if snaps[i].time <= t then
				a, b = snaps[i], snaps[i + 1]
				alpha = math.clamp((t - a.time) / math.max(b.time - a.time, 1e-4), 0, 1)
				break
			end
		end
	end
	-- Телепорт: не размазываем.
	if (b.hips - a.hips).Magnitude > remote_skaters.CONFIG.teleport then
		alpha = if alpha < 0.5 then 0 else 1
	end
	local offset = if is_echo(r.player) then ECHO_OFFSET else Vector3.zero
	local bones = r.bones
	for name, cf in b.bones do
		local from = a.bones[name]
		bones[INDEX[name]] = (if alpha <= 0 then from elseif alpha >= 1 then cf else from:Lerp(cf, alpha)) + offset
	end
	local deck = (if alpha <= 0 then a.deck elseif alpha >= 1 then b.deck else a.deck:Lerp(b.deck, alpha)) + offset
	local hips = a.hips:Lerp(b.hips, alpha) + offset
	return deck, hips
end

local function every_for(distance: number): number
	for _, tier in remote_skaters.CONFIG.tiers do
		if distance <= tier.distance then
			return tier.every
		end
	end
	return remote_skaters.CONFIG.far_every
end

-- Попадает ли сфера в поле зрения камеры (как view_cone в Net).
local function in_view(camera: Camera, at: Vector3): boolean
	local cf = camera.CFrame
	local to = at - cf.Position
	local along = to:Dot(cf.LookVector)
	local cfg = remote_skaters.CONFIG
	if along < -cfg.cull_radius then
		return false
	end
	local viewport = camera.ViewportSize
	local tan_v = math.tan(math.rad(camera.FieldOfView * 0.5))
	local tan_h = tan_v * viewport.X / math.max(viewport.Y, 1)
	local half = math.atan(math.sqrt(tan_v * tan_v + tan_h * tan_h)) + math.rad(cfg.cull_margin)
	if half >= 1.5 then
		return true
	end
	local side = math.sqrt(math.max(to:Dot(to) - along * along, 0))
	return side <= along * math.tan(half) + cfg.cull_radius / math.cos(half)
end

type Job = { r: Remote, distance: number, deck: CFrame, hips: Vector3, pose: boolean }

local function frame()
	local now = workspace:GetServerTimeNow()
	local camera = workspace.CurrentCamera
	local cfg = remote_skaters.CONFIG
	local jobs: { Job } = {}
	for player, r in remotes do
		if player.Parent == nil or player:GetAttribute("Skate3") ~= true then
			drop(player)
			continue
		end
		local newest = r.snaps[#r.snaps]
		if newest == nil then
			continue
		end
		-- Пропали пакеты — прячем модель, показываем настоящего персонажа.
		if now - newest.arrival > cfg.stale_after then
			if r.shown then
				destroy_model(r)
				show_character(r)
				r.shown = false
			end
			continue
		end
		if not r.shown or (r.custom == nil and r.model == nil) then
			destroy_model(r)
			build(r)
		end
		-- Модель сменили (атрибут SkateRigShown) — пересобрать.
		local wanted = r.player:GetAttribute("SkateRigShown")
		if type(wanted) == "string" and wanted ~= r.rig_name then
			destroy_model(r)
			build(r)
		end
		if not is_echo(player) then
			hide_character(r)
		end
		-- Задержка воспроизведения: 1.5 интервала + 2 дрожания, плавно.
		local target = math.clamp(r.interval * 1.5 + r.jitter * 2, cfg.min_delay, cfg.max_delay)
		r.delay += (target - r.delay) * 0.05
		local deck, hips = sample(r, now - r.delay)
		if deck == nil or hips == nil then
			continue
		end
		r.frame += 1
		local distance = if camera then (camera.CFrame.Position - hips).Magnitude else 0
		local visible = camera == nil or in_view(camera, hips)
		local pose = visible and (r.posed_hips == nil or r.frame % every_for(distance) == 0)
		table.insert(jobs, { r = r, distance = distance, deck = deck, hips = hips, pose = pose })
	end
	-- Ближние первыми; позы — пока хватает бюджета.
	table.sort(jobs, function(a, b)
		return a.distance < b.distance
	end)
	local started = os.clock()
	for i, job in jobs do
		local r = job.r
		if r.board then
			board_model.place(r.board, job.deck)
		end
		local can_pose = job.pose and (i == 1 or os.clock() - started < cfg.budget)
		if can_pose then
			if r.custom then
				bone_pose.apply(r.custom, r.bones)
			elseif r.r15 then
				r15_pose.apply(r.r15, r.bones, nil)
			end
			r.posed_hips = job.hips
		elseif r.posed_hips then
			-- Без новой позы: двигаем модель целиком вслед за тазом (дёшево).
			local shift = job.hips - r.posed_hips
			if shift.Magnitude > 1e-3 then
				local root = if r.custom then r.custom.root elseif r.r15 then r.r15.root else nil
				if root then
					root.CFrame += shift
				end
				r.posed_hips = job.hips
			end
		end
	end
end

local started = false

-- Запустить приём на этом клиенте (один раз).
function remote_skaters.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local net = ReplicatedStorage:WaitForChild("Skate3Net", 30)
		if net == nil then
			warn("skate3: нет Skate3Net — других скейтеров не видно (нужен серверный скрипт Skate3Net)")
			return
		end
		local stream = net:WaitForChild("Stream") :: UnreliableRemoteEvent
		stream.OnClientEvent:Connect(receive)
		RunService.PreRender:Connect(frame)
		Players.PlayerRemoving:Connect(drop)
		-- Новый персонаж (респаун): пересобрать копию и кэш спрятанных деталей.
		local function watch(player: Player)
			player.CharacterAdded:Connect(function()
				on_character(player)
			end)
		end
		Players.PlayerAdded:Connect(watch)
		for _, player in Players:GetPlayers() do
			watch(player)
		end
	end)
end

-- Для отладки: сколько скейтеров видим и с какой задержкой.
function remote_skaters.stats(): { { name: string, snaps: number, delay: number, interval: number, jitter: number } }
	local out = {}
	for player, r in remotes do
		table.insert(out, { name = player.Name, snaps = #r.snaps, delay = r.delay, interval = r.interval, jitter = r.jitter })
	end
	return out
end

return remote_skaters
