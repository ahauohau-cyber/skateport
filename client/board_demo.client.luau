--!strict
-- ROBLOX: клиентский запуск демо доски (временный; позже его заменит админ-команда).
-- B — поставить/убрать доску перед персонажем; W/S — толчок; A/D — поворот траков.
-- Камера смотрит на деку, пока доска есть.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local board_demo = require(ReplicatedStorage:WaitForChild("SkatePort"):WaitForChild("roblox"):WaitForChild("board_demo"))

local player = Players.LocalPlayer
local current: any = nil

local function toggle()
	local camera = workspace.CurrentCamera
	if current then
		current.stop()
		current = nil
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
		return
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local at = hrp.CFrame * CFrame.new(0, 0, -6)
	current = board_demo.start(at)
	camera.CameraSubject = current.model.PrimaryPart
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		toggle()
	end
end)
