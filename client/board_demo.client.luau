--!strict
-- ROBLOX: клиентский запуск демо доски (временный; позже его заменит админ-команда).
-- B — поставить/убрать доску перед персонажем. Пока доска есть, персонаж
-- стоит (ходьба и прыжок выключены), а клавиатура и мышь идут в порт
-- как геймпад: Space — толчок, F — тормоз, A/D — поворот, ЛКМ+мышь — флик-стик
-- (полная раскладка в roblox/keyboard_pad).
-- Камера смотрит на деку, пока доска есть.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local board_demo = require(ReplicatedStorage:WaitForChild("SkatePort"):WaitForChild("roblox"):WaitForChild("board_demo"))

local player = Players.LocalPlayer
local current: any = nil
local saved: { walk: number, jump: number, use_power: boolean }? = nil

-- Персонаж не должен ходить и прыгать от тех же клавиш, пока катается доска.
local function freeze(humanoid: Humanoid?, on: boolean)
	if not humanoid then
		return
	end
	if on then
		saved = { walk = humanoid.WalkSpeed, jump = humanoid.JumpPower, use_power = humanoid.UseJumpPower }
		humanoid.WalkSpeed = 0
		humanoid.UseJumpPower = true
		humanoid.JumpPower = 0
	elseif saved then
		humanoid.WalkSpeed = saved.walk
		humanoid.UseJumpPower = saved.use_power
		humanoid.JumpPower = saved.jump
		saved = nil
	end
end

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
		freeze(humanoid, false)
		return
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local at = hrp.CFrame * CFrame.new(0, 0, -6)
	current = board_demo.start(at)
	freeze(character:FindFirstChildOfClass("Humanoid"), true)
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
