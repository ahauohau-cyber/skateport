--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: ники и титулы над головой скейтера прячем, пока он в режиме скейта.
-- Его настоящий персонаж спрятан (у других его двигает сервер рывками), а
-- рисуется копия — без этого над игроком висели бы два титула.
-- Прячем только у себя на экране (Enabled локально), сам тег не трогаем:
-- система титулов плейса после выхода из скейта работает как раньше.

local name_tags = {}

-- Что спрятали: гуи -> было ли включено.
export type Hidden = { [LayerCollector]: boolean }

local function is_tag(d: Instance): boolean
	return d:IsA("BillboardGui") or d:IsA("SurfaceGui")
end

-- Спрятать теги персонажа (и те, что появятся позже, — при следующем вызове).
-- Звать каждый кадр: бабл-чат и система титулов включают тег обратно.
function name_tags.hide(character: Model?, hidden: Hidden)
	for gui, _ in hidden do
		if gui.Parent == nil then
			hidden[gui] = nil
		elseif gui.Enabled then
			gui.Enabled = false
		end
	end
	if character == nil then
		return
	end
	local head = character:FindFirstChild("Head")
	-- Новые теги ищем только в голове и в самой модели (там их держат системы
	-- титулов), чтобы не обходить всё дерево персонажа каждый кадр.
	for _, place in { head, character } do
		if place then
			for _, d in place:GetChildren() do
				if is_tag(d) and hidden[d :: LayerCollector] == nil then
					local gui = d :: LayerCollector
					hidden[gui] = gui.Enabled
					gui.Enabled = false
				end
			end
		end
	end
end

-- Вернуть как было.
function name_tags.show(hidden: Hidden)
	for gui, was in hidden do
		if gui.Parent then
			gui.Enabled = was
		end
	end
	table.clear(hidden)
end

-- Убрать теги из копии персонажа совсем.
function name_tags.strip(model: Model)
	for _, d in model:GetDescendants() do
		if is_tag(d) or d:IsA("ProximityPrompt") then
			d:Destroy()
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

return name_tags
