--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: видимая доска. Физика доски целиком в ядре sim; здесь только
-- модель из простых деталей, которую каждый кадр ставим в позу деки.
-- Размеры — как у доски Skate 3 (~0.8 м длина, ~0.2 м ширина) в стадах.

local board_model = {}

local S = 1 / 0.28

export type Board = {
	model: Model,
	deck: BasePart,
	offsets: { [BasePart]: CFrame },
	deck_offset: CFrame?, -- смещение самой детали deck от центра деки физики
}

local function part(model: Model, name: string, size: Vector3, color: Color3, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = true
	if shape then
		p.Shape = shape
	end
	p.Parent = model
	return p
end

-- Шаблон настоящей доски: модель "Board" (RootPart + меши SkateBoard /
-- SkateTruck / SkateWheel и кость SKATEBOARD_ROOT). Ищем в ReplicatedStorage,
-- затем в Workspace. Меши уже в масштабе ядра (1 м = 1/0.28 стада).
local function find_template(): Model?
	for _, place in { game:GetService("ReplicatedStorage"), workspace } do
		local m = place:FindFirstChild("Board")
		if m and m:IsA("Model") then
			return m
		end
	end
	return nil
end

-- Доска из шаблона: каждую меш-деталь ставим относительно кости
-- SKATEBOARD_ROOT, которая совпадает с центром деки в физике ядра.
local function from_template(template: Model, parent: Instance): Board?
	local root_bone = template:FindFirstChild("SKATEBOARD_ROOT", true)
	if root_bone == nil or not root_bone:IsA("Bone") then
		return nil
	end
	-- Оси деки = оси модели (доска лежит вдоль Z); от кости берём только позицию.
	local pivot = template:GetPivot()
	local origin = CFrame.new(root_bone.WorldPosition) * pivot.Rotation
	local model = Instance.new("Model")
	model.Name = "Skate3Board"
	model:SetAttribute("SkateIgnore", true)
	local offsets: { [BasePart]: CFrame } = {}
	local deck: BasePart? = nil
	for _, d in template:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "RootPart" then
			local copy = d:Clone()
			for _, child in copy:GetChildren() do
				if child:IsA("JointInstance") or child:IsA("Constraint") or child:IsA("Bone") then
					child:Destroy()
				end
			end
			copy.Anchored = true
			copy.CanCollide = false
			copy.CanQuery = false
			copy.CanTouch = false
			copy.Massless = true
			copy.Parent = model
			offsets[copy] = origin:ToObjectSpace(d.CFrame)
			if d.Name == "SkateBoard" or deck == nil then
				deck = copy
			end
		end
	end
	if deck == nil then
		model:Destroy()
		return nil
	end
	offsets[deck :: BasePart] = nil
	local deck_offset = origin:ToObjectSpace((template:FindFirstChild((deck :: BasePart).Name, true) :: BasePart).CFrame)
	model.PrimaryPart = deck
	model.Parent = parent
	return { model = model, deck = deck :: BasePart, offsets = offsets, deck_offset = deck_offset }
end

function board_model.new(parent: Instance): Board
	local template = find_template()
	if template then
		local board = from_template(template, parent)
		if board then
			return board
		end
		warn("skate3: модель Board без кости SKATEBOARD_ROOT или мешей — ставлю простую доску")
	end
	return board_model.simple(parent)
end

function board_model.simple(parent: Instance): Board
	local model = Instance.new("Model")
	model.Name = "Skate3Board"
	model:SetAttribute("SkateIgnore", true)
	-- Дека: длина вдоль Z, как у деки в ядре (доска едет по своей оси Z).
	local length, width, thick = 0.80 * S, 0.21 * S, 0.012 * S
	local deck = part(model, "Deck", Vector3.new(width, thick, length), Color3.fromRGB(35, 35, 40))
	local griptape = part(model, "Grip", Vector3.new(width * 0.98, 0.002 * S, length * 0.97), Color3.fromRGB(15, 15, 15))
	local offsets: { [BasePart]: CFrame } = {}
	offsets[griptape] = CFrame.new(0, thick / 2 + 0.001 * S, 0)
	-- Подвески и колёса. Высота деки над землёй у ядра ~0.087 м (центр деки),
	-- колёса радиусом ~0.027 м касаются земли.
	local wheel_r = 0.027 * S
	local deck_height = 0.087 * S
	for _, z in { 0.22 * S, -0.22 * S } do
		local truck = part(model, "Truck", Vector3.new(width * 0.9, 0.03 * S, 0.04 * S), Color3.fromRGB(170, 170, 175))
		offsets[truck] = CFrame.new(0, -(deck_height - wheel_r) * 0.6, z)
		for _, x in { width / 2, -width / 2 } do
			local wheel = part(model, "Wheel", Vector3.new(0.032 * S, wheel_r * 2, wheel_r * 2), Color3.fromRGB(240, 240, 230), Enum.PartType.Cylinder)
			offsets[wheel] = CFrame.new(x, -(deck_height - wheel_r), z)
		end
	end
	model.PrimaryPart = deck
	model.Parent = parent
	return { model = model, deck = deck, offsets = offsets }
end

-- cf — CFrame центра деки в стадах (engine.deck_cframe, можно интерполировать).
function board_model.place(self: Board, cf: CFrame)
	self.deck.CFrame = if self.deck_offset then cf * self.deck_offset else cf
	for p, offset in self.offsets do
		p.CFrame = cf * offset
	end
end

function board_model.destroy(self: Board)
	self.model:Destroy()
end

return board_model
