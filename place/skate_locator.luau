--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: где лежит ядро скейта (Skate3 = sim + sim_data, ~25 МБ).
--   Сервер: ServerStorage.SkateLib (не реплицируется).
--   Клиент: PlayerGui.SkateLib — копию выдаёт Skate3Admin только тому, кто
--   катается; остальные игроки ядро не скачивают. Чужих скейтеров они рисуют
--   лёгким ReplicatedStorage.SkatePort (remote_skaters).
if game:GetService("RunService"):IsServer() then
	return game:GetService("ServerStorage"):WaitForChild("SkateLib")
end
return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("SkateLib")
