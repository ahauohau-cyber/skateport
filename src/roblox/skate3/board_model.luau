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

function board_model.new(parent: Instance): Board
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

-- transform: { translation = {x,y,z}, basis = { columns = {{..},{..},{..}} } } в метрах.
function board_model.place(self: Board, transform: any)
	local t = transform.translation
	local c = transform.basis.columns
	local cf = CFrame.fromMatrix(
		Vector3.new(t.x * S, t.y * S, t.z * S),
		Vector3.new(c[1][1], c[1][2], c[1][3]),
		Vector3.new(c[2][1], c[2][2], c[2][3]),
		Vector3.new(c[3][1], c[3][2], c[3][3])
	)
	self.deck.CFrame = cf
	for p, offset in self.offsets do
		p.CFrame = cf * offset
	end
end

function board_model.destroy(self: Board)
	self.model:Destroy()
end

return board_model
