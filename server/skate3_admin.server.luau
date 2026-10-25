--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: админ-команда скейта.
--   /skate            — включить/выключить скейт себе
--   /skate <ник>      — включить/выключить игроку (по началу ника или DisplayName)
-- Права: владелец игры (или владелец группы / ранг >= 254), плюс ADMINS ниже.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- Добавь сюда UserId админов.
local ADMINS: { number } = {}

local function is_admin(player: Player): boolean
	if table.find(ADMINS, player.UserId) then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		if player.UserId == game.CreatorId then
			return true
		end
	elseif game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(function()
			return player:GetRankInGroup(game.CreatorId)
		end)
		if ok and rank >= 254 then
			return true
		end
	end
	-- В Studio (Play Solo) владельца нет — разрешаем.
	return game:GetService("RunService"):IsStudio()
end

local function find_player(text: string): Player?
	local needle = string.lower(text)
	for _, p in Players:GetPlayers() do
		if string.sub(string.lower(p.Name), 1, #needle) == needle or string.sub(string.lower(p.DisplayName), 1, #needle) == needle then
			return p
		end
	end
	return nil
end

local function toggle(target: Player)
	target:SetAttribute("Skate3", not (target:GetAttribute("Skate3") == true))
end

local function run(speaker: Player, text: string)
	if not is_admin(speaker) then
		return
	end
	local arg = string.match(text, "^/%S+%s+(.-)%s*$")
	local target = if arg and #arg > 0 then find_player(arg) else speaker
	if target then
		toggle(target)
	end
end

-- Новый чат: TextChatCommand.
local command = Instance.new("TextChatCommand")
command.Name = "Skate3Command"
command.PrimaryAlias = "/skate"
command.SecondaryAlias = "/скейт"
command.Triggered:Connect(function(source: TextSource, text: string)
	local speaker = Players:GetPlayerByUserId(source.UserId)
	if speaker then
		run(speaker, text)
	end
end)
command.Parent = TextChatService

-- Старый чат.
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local lower = string.lower(message)
		if string.sub(lower, 1, 6) == "/skate" or string.sub(message, 1, #"/скейт") == "/скейт" then
			if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
				run(player, message)
			end
		end
	end)
end)
