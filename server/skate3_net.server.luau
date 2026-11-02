--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: сервер репликации скейтеров. Физика скейта считается только на
-- клиенте игрока, поэтому остальные видят его через наши снимки:
--   клиент-скейтер -> Stream (UnreliableRemoteEvent, ~15 Гц, 244 байта)
--   сервер -> остальным игрокам, реже для дальних (LOD по дистанции, как
--   ROOT_EVERY/JOINTS_EVERY в Net примерочного плейса).
-- Ещё сервер раз в 0.2 с ставит настоящего персонажа скейтера туда же
-- (якорем), чтобы его видели серверные системы и игроки без этого скрипта.
--
-- Look (RemoteEvent): клиент сообщает, какой моделью рисовать его на других
-- клиентах (атрибут SkateRig: имя модели или ""). Сервер проверяет и ставит
-- атрибут игрока SkateRigShown — он реплицируется всем.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local net_codec = require(ReplicatedStorage:WaitForChild("SkatePort"):WaitForChild("roblox"):WaitForChild("skate3"):WaitForChild("net_codec"))

local folder = Instance.new("Folder")
folder.Name = "Skate3Net"
local stream = Instance.new("UnreliableRemoteEvent")
stream.Name = "Stream"
stream.Parent = folder
local look = Instance.new("RemoteEvent")
look.Name = "Look"
look.Parent = folder
folder.Parent = ReplicatedStorage

-- Через сколько пакетов пересылать по дистанции (стады) между скейтером и
-- получателем. Дальше последнего порога — раз в 8 пакетов (~2 Гц).
local TIERS = {
	{ distance = 150, every = 1 },
	{ distance = 350, every = 2 },
	{ distance = 800, every = 4 },
}
local FAR_EVERY = 8
local MAX_RATE = 30 -- пакетов в секунду от одного игрока, лишние выбрасываем
local ROOT_PERIOD = 0.2 -- с: как часто двигать настоящего персонажа

type State = {
	position: Vector3?,
	count: number, -- принятые пакеты (для LOD)
	window: number, -- начало секундного окна лимита
	in_window: number,
	root_at: number,
	anchored: boolean,
}

local states: { [Player]: State } = {}

local function state_of(player: Player): State
	local s = states[player]
	if s == nil then
		s = { position = nil, count = 0, window = 0, in_window = 0, root_at = 0, anchored = false }
		states[player] = s
	end
	return s
end

-- Где игрок сейчас: по его снимкам, иначе по персонажу.
local function where(player: Player): Vector3?
	local s = states[player]
	if s and s.position and player:GetAttribute("Skate3") == true then
		return s.position
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if root then root.Position else nil
end

local function every_for(distance: number): number
	for _, tier in TIERS do
		if distance <= tier.distance then
			return tier.every
		end
	end
	return FAR_EVERY
end

local function release(player: Player)
	local s = states[player]
	if s and s.anchored then
		s.anchored = false
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.Anchored = false
		end
	end
end

stream.OnServerEvent:Connect(function(player: Player, packet: any)
	if player:GetAttribute("Skate3") ~= true then
		return
	end
	local position = net_codec.peek(packet)
	if position == nil then
		return
	end
	local s = state_of(player)
	local now = os.clock()
	if now - s.window >= 1 then
		s.window = now
		s.in_window = 0
	end
	s.in_window += 1
	if s.in_window > MAX_RATE then
		return
	end
	s.position = position
	s.count += 1

	-- Настоящий персонаж — грубо за скейтером (якорь, 5 Гц).
	if now - s.root_at >= ROOT_PERIOD then
		s.root_at = now
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			if not root.Anchored then
				root.Anchored = true
			end
			s.anchored = true
			root.CFrame = CFrame.new(position) * root.CFrame.Rotation
		end
	end

	-- Отладка: SkateNetEcho = true — свои же снимки обратно (призрак сбоку).
	if player:GetAttribute("SkateNetEcho") == true then
		stream:FireClient(player, player, packet)
	end
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local at = where(other)
			local distance = if at then (at - position).Magnitude else 0
			if s.count % every_for(distance) == 0 then
				stream:FireClient(other, player, packet)
			end
		end
	end
end)

look.OnServerEvent:Connect(function(player: Player, rig: any)
	if type(rig) ~= "string" or #rig > 64 then
		return
	end
	-- Только модели, которые реально есть в плейсе (иначе рисуем аватар).
	if rig ~= "" and workspace:FindFirstChild(rig) == nil and ReplicatedStorage:FindFirstChild(rig) == nil then
		rig = ""
	end
	player:SetAttribute("SkateRigShown", rig)
end)

local function watch(player: Player)
	player:GetAttributeChangedSignal("Skate3"):Connect(function()
		if player:GetAttribute("Skate3") ~= true then
			release(player)
			local s = states[player]
			if s then
				s.position = nil
			end
		end
	end)
	player.CharacterAdded:Connect(function()
		local s = states[player]
		if s then
			s.anchored = false
			s.position = nil
		end
	end)
end

Players.PlayerAdded:Connect(watch)
for _, p in Players:GetPlayers() do
	watch(p)
end
Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)

-- В Studio удобно видеть, что сервер жив.
if RunService:IsStudio() then
	print("[skate3] сеть: Stream/Look готовы")
end
