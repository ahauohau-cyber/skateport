--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: клиент скейта. Сервер ставит игроку атрибут Skate3 (админ-командой
-- /skate или своим скриптом), этот скрипт запускает или останавливает сеанс.
--
-- Ядро (~25 МБ) приходит не всем: сервер копирует ServerStorage.SkateLib в
-- PlayerGui только скейтеру. Перед стартом ждём, пока дойдут все объекты
-- (атрибут SkateLibSize), и показываем прогресс. Чужих скейтеров видят все —
-- для этого хватает лёгкого ReplicatedStorage.SkatePort.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local skate3 = ReplicatedStorage:WaitForChild("SkatePort"):WaitForChild("roblox"):WaitForChild("skate3")
local session = require(skate3:WaitForChild("session"))
local remote_skaters = require(skate3:WaitForChild("remote_skaters"))

-- Других скейтеров видят все игроки, даже те, кто сам не катается.
remote_skaters.start()

local player = Players.LocalPlayer
local current: any = nil
local busy = false
-- Если запуск не удался, не повторяем, пока атрибут не выключат и не включат снова.
local failed = false

-- Надпись «Загрузка скейта N%» внизу экрана.
local function progress_label(): TextLabel
	local gui = Instance.new("ScreenGui")
	gui.Name = "Skate3Loading"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -90)
	label.Size = UDim2.fromOffset(320, 36)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.4
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Text = "Загрузка скейта…"
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	label.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	return label
end

-- Дождаться копии ядра в PlayerGui (если плейс устроен через SkateLocator).
local function wait_lib(): boolean
	if ReplicatedStorage:FindFirstChild("SkateLocator") == nil then
		return true -- тестовый плейс: ядро прямо в ReplicatedStorage
	end
	local gui = player:WaitForChild("PlayerGui")
	local label: TextLabel? = nil
	local started = os.clock()
	while true do
		if player:GetAttribute("Skate3") ~= true then
			if label then
				(label.Parent :: Instance):Destroy()
			end
			return false
		end
		local lib = gui:FindFirstChild("SkateLib")
		local size = lib and lib:GetAttribute("SkateLibSize")
		if lib and type(size) == "number" then
			local have = #lib:GetDescendants()
			if have >= size then
				if label then
					(label.Parent :: Instance):Destroy()
				end
				return true
			end
			if label == nil and os.clock() - started > 0.3 then
				label = progress_label()
			end
			if label then
				label.Text = string.format("Загрузка скейта… %d%%", math.floor(have / size * 100))
			end
		elseif label == nil and os.clock() - started > 0.3 then
			label = progress_label()
		end
		task.wait(0.2)
	end
end

local function sync()
	if busy then
		return
	end
	busy = true
	local want = player:GetAttribute("Skate3") == true
	if not want then
		failed = false
	end
	if want and current == nil and not failed then
		if wait_lib() then
			local ok, result = pcall(session.start, player)
			current = if ok then result else nil
			if current == nil then
				failed = true
				warn("skate3: не удалось начать сеанс", if ok then "" else result)
			end
		end
	elseif not want and current ~= nil then
		session.stop(current)
		current = nil
	end
	busy = false
	-- Атрибут мог поменяться, пока шла загрузка.
	if not failed and (player:GetAttribute("Skate3") == true) ~= (current ~= nil) then
		task.defer(sync)
	end
end

player:GetAttributeChangedSignal("Skate3"):Connect(sync)
player.CharacterAdded:Connect(function()
	if current ~= nil then
		session.stop(current)
		current = nil
	end
	task.wait(1)
	sync()
end)
sync()
