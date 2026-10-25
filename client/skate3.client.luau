--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: клиент скейта. Сервер ставит игроку атрибут Skate3 (админ-командой
-- /skate), этот скрипт запускает или останавливает сеанс катания.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local session = require(ReplicatedStorage:WaitForChild("SkatePort"):WaitForChild("roblox"):WaitForChild("skate3"):WaitForChild("session"))

local player = Players.LocalPlayer
local current: any = nil
local busy = false

local function sync()
	if busy then
		return
	end
	busy = true
	local want = player:GetAttribute("Skate3") == true
	if want and current == nil then
		current = session.start(player)
		if current == nil then
			warn("skate3: не удалось начать сеанс")
		end
	elseif not want and current ~= nil then
		session.stop(current)
		current = nil
	end
	busy = false
	-- Атрибут мог поменяться, пока шла загрузка.
	if (player:GetAttribute("Skate3") == true) ~= (current ~= nil) then
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
