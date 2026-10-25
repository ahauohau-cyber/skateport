--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: перенос позы скейтера на свою модель со скиннингом (кости Bone),
-- например MMD-персонажа: один MeshPart и дерево костей
-- Hips → Spine → Chest → Neck → Head, Right shoulder/arm/elbow/wrist,
-- Right leg/knee/ankle/toe.
--
-- Переносим полные повороты костей скейтера (с кистью и скручиванием руки),
-- а не восстанавливаем их по позициям: по позициям не видно, как повёрнута
-- кисть, а у прямой руки нет оси сгиба — отсюда были дёрганья рук, когда
-- персонаж держит, бросает или подзывает доску и встаёт.
--
-- Связка двух скелетов — через T-позу скейтера из данных игры (RIG_TPOSE):
--   1. G — общий поворот «T-поза скейтера → поза покоя модели» по тазу и спине;
--   2. A — для каждой кости поворот, который ставит её из позы покоя модели
--      (часто A-поза) в направление той же кости в T-позе скейтера;
--   3. каждый кадр: поворот кости модели = поворот кости скейтера ×
--      (её поворот в T-позе)⁻¹ × G⁻¹ × A × поворот кости модели в покое.
-- Пальцы, волосы, одежда — едут за родительскими костями.

local bone_pose = {}

-- Имена костей модели (сравниваем без регистра, пробелов, точек и подчёркиваний).
local NAMES: { [string]: { string } } = {
	hips = { "hips", "pelvis" },
	spine = { "spine", "spine1", "abdomen", "lowerspine" },
	chest = { "chest", "upperchest", "spine2", "upperspine" },
	neck = { "neck" },
	head = { "head" },
	r_shoulder = { "rightshoulder", "shoulderr", "rightclavicle", "clavicler" },
	r_arm = { "rightarm", "rightupperarm", "upperarmr", "armr" },
	r_elbow = { "rightelbow", "rightforearm", "rightlowerarm", "lowerarmr", "forearmr", "elbowr" },
	r_wrist = { "rightwrist", "righthand", "handr", "wristr" },
	l_shoulder = { "leftshoulder", "shoulderl", "leftclavicle", "claviclel" },
	l_arm = { "leftarm", "leftupperarm", "upperarml", "arml" },
	l_elbow = { "leftelbow", "leftforearm", "leftlowerarm", "lowerarml", "forearml", "elbowl" },
	l_wrist = { "leftwrist", "lefthand", "handl", "wristl" },
	r_leg = { "rightleg", "rightupperleg", "rightupleg", "rightthigh", "upperlegr", "thighr", "legr" },
	r_knee = { "rightknee", "rightlowerleg", "rightshin", "lowerlegr", "kneer", "shinr" },
	r_ankle = { "rightankle", "rightfoot", "footr", "ankler" },
	r_toe = { "righttoe", "righttoebase", "righttoes", "toer", "toebaser" },
	l_leg = { "leftleg", "leftupperleg", "leftupleg", "leftthigh", "upperlegl", "thighl", "legl" },
	l_knee = { "leftknee", "leftlowerleg", "leftshin", "lowerlegl", "kneel", "shinl" },
	l_ankle = { "leftankle", "leftfoot", "footl", "anklel" },
	l_toe = { "lefttoe", "lefttoebase", "lefttoes", "toel", "toebasel" },
}

-- Слот модели -> кость скейтера; child — по какой паре костей выравнивать
-- направление (слот модели, кость скейтера). Без child — поворот A родителя.
type Slot = { slot: string, skater: string, child: string?, skater_child: string?, inherit: string? }
local SLOTS: { Slot } = {
	{ slot = "hips", skater = "HIPS", child = "spine", skater_child = "SPINE1" },
	{ slot = "spine", skater = "SPINE1", child = "chest", skater_child = "SPINE3" },
	{ slot = "chest", skater = "SPINE3", child = "neck", skater_child = "NECK" },
	{ slot = "neck", skater = "NECK", child = "head", skater_child = "HEAD" },
	{ slot = "head", skater = "HEAD", inherit = "neck" },
	{ slot = "r_shoulder", skater = "RIGHTSHOULDER", child = "r_arm", skater_child = "RIGHTARM" },
	{ slot = "r_arm", skater = "RIGHTARM", child = "r_elbow", skater_child = "RIGHTFOREARM" },
	{ slot = "r_elbow", skater = "RIGHTFOREARM", child = "r_wrist", skater_child = "RIGHTHAND" },
	{ slot = "r_wrist", skater = "RIGHTHAND", inherit = "r_elbow" },
	{ slot = "l_shoulder", skater = "LEFTSHOULDER", child = "l_arm", skater_child = "LEFTARM" },
	{ slot = "l_arm", skater = "LEFTARM", child = "l_elbow", skater_child = "LEFTFOREARM" },
	{ slot = "l_elbow", skater = "LEFTFOREARM", child = "l_wrist", skater_child = "LEFTHAND" },
	{ slot = "l_wrist", skater = "LEFTHAND", inherit = "l_elbow" },
	{ slot = "r_leg", skater = "RIGHTUPLEG", child = "r_knee", skater_child = "RIGHTLEG" },
	{ slot = "r_knee", skater = "RIGHTLEG", child = "r_ankle", skater_child = "RIGHTFOOT" },
	{ slot = "r_ankle", skater = "RIGHTFOOT", child = "r_toe", skater_child = "RIGHTTOEBASE" },
	{ slot = "r_toe", skater = "RIGHTTOEBASE", inherit = "r_ankle" },
	{ slot = "l_leg", skater = "LEFTUPLEG", child = "l_knee", skater_child = "LEFTLEG" },
	{ slot = "l_knee", skater = "LEFTLEG", child = "l_ankle", skater_child = "LEFTFOOT" },
	{ slot = "l_ankle", skater = "LEFTFOOT", child = "l_toe", skater_child = "LEFTTOEBASE" },
	{ slot = "l_toe", skater = "LEFTTOEBASE", inherit = "l_ankle" },
}

export type Rig = {
	model: Model,
	root: BasePart,
	root_rotation: CFrame, -- поворот корневой детали в покое
	order: { Bone }, -- кости, которые считаем (сверху вниз)
	source: { [Bone]: number }, -- кость модели -> индекс кости скейтера
	offset: { [Bone]: CFrame }, -- (T-поза скейтера)⁻¹ × G⁻¹ × A × покой модели
	rest_world: { [Bone]: CFrame }, -- поворот кости модели в покое (мир)
	hips: Bone,
	hips_local: Vector3, -- кость Hips в осях корневой детали (покой)
	hips_offset: Vector3, -- кость Hips минус середина бёдер (мир, покой)
	leg_length: number, -- стады
	index: { [string]: number }, -- имя кости скейтера -> индекс
	leg_scale: number?,
	hidden: { [Instance]: number }, -- прежний LocalTransparencyModifier персонажа
}

local function key(name: string): string
	return (string.gsub(string.lower(name), "[%s%._%-]", ""))
end

local function unit(v: Vector3, fallback: Vector3): Vector3
	local l = v.Magnitude
	if l < 1e-6 then
		return fallback
	end
	return v / l
end

-- Кратчайший поворот, переводящий направление a в b.
local function swing(a: Vector3, b: Vector3): CFrame
	local axis = a:Cross(b)
	local c = math.clamp(a:Dot(b), -1, 1)
	if axis.Magnitude < 1e-6 then
		if c > 0 then
			return CFrame.identity
		end
		local any = if math.abs(a.X) < 0.9 then Vector3.xAxis else Vector3.yAxis
		return CFrame.fromAxisAngle(a:Cross(any).Unit, math.pi)
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(c))
end

-- Рамка тела: X — вправо (бёдра), Y — вверх (таз → шея).
local function body_frame(right: Vector3, up: Vector3): CFrame
	local y = unit(up, Vector3.yAxis)
	local x = unit(right - y * right:Dot(y), Vector3.xAxis)
	return CFrame.fromMatrix(Vector3.zero, x, y, x:Cross(y))
end

-- Собрать риг из модели-шаблона. tpose — CFrame костей скейтера в T-позе
-- (engine.reference_pose(e, "RIG_TPOSE")), bone_names — имена костей скейтера.
function bone_pose.bind(template: Model, bone_names: { string }, parent: Instance, tpose: { CFrame }): Rig?
	local index: { [string]: number } = {}
	for i, name in bone_names do
		index[string.upper(name)] = i
	end
	local model = template:Clone()
	-- Свою анимацию у клона выключаем: позу ставим только мы.
	for _, d in model:GetDescendants() do
		if d:IsA("Animator") or d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	local by_key: { [string]: Bone } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Bone") then
			local k = key(d.Name)
			if by_key[k] == nil then
				by_key[k] = d
			end
		end
	end
	local found: { [string]: Bone } = {}
	for slot, names in NAMES do
		for _, n in names do
			local b = by_key[n]
			if b then
				found[slot] = b
				break
			end
		end
	end
	for _, need in { "hips", "neck", "r_arm", "r_elbow", "r_wrist", "l_arm", "l_elbow", "l_wrist", "r_leg", "r_knee", "r_ankle", "l_leg", "l_knee", "l_ankle" } do
		if found[need] == nil then
			model:Destroy()
			warn("skate3: в модели " .. template.Name .. " нет кости для " .. need)
			return nil
		end
	end

	-- Корневая деталь, в которой висят кости.
	local p = found.hips.Parent
	while p and not p:IsA("BasePart") do
		p = p.Parent
	end
	local root = p :: BasePart?
	if root == nil then
		model:Destroy()
		return nil
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	model:SetAttribute("SkateIgnore", true)
	model.Name = template.Name .. "_skate"
	model.Parent = parent

	-- Мировые CFrame костей модели в покое: без Transform, от корневой детали.
	local root_cf = root.CFrame
	local rest_cf: { [Bone]: CFrame } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("Bone") then
			d.Transform = CFrame.identity
			local parent_cf = if d.Parent == root then root_cf else rest_cf[d.Parent :: Bone]
			if parent_cf then
				rest_cf[d] = parent_cf * d.CFrame
			end
		end
	end
	local function at(slot: string): Vector3
		return rest_cf[found[slot]].Position
	end
	local function sk(name: string): CFrame
		return tpose[index[name]]
	end

	-- 1. Общий поворот G: T-поза скейтера -> поза покоя модели.
	local g_rig = body_frame(at("r_leg") - at("l_leg"), at("neck") - at("hips"))
	local g_sk = body_frame(sk("RIGHTUPLEG").Position - sk("LEFTUPLEG").Position, sk("NECK").Position - sk("HIPS").Position)
	local G = g_rig * g_sk:Inverse()
	local G_inv = G:Inverse()

	-- 2-3. Поворот A каждой кости и постоянная поправка offset.
	local A: { [string]: CFrame } = {}
	local source: { [Bone]: number } = {}
	local offset: { [Bone]: CFrame } = {}
	for _, s in SLOTS do
		local b = found[s.slot]
		if b == nil or index[s.skater] == nil then
			continue
		end
		local a = CFrame.identity
		if s.child and found[s.child] and s.skater_child and index[s.skater_child] then
			local rig_dir = unit(at(s.child) - at(s.slot), Vector3.yAxis)
			local sk_dir = unit(G:VectorToWorldSpace(sk(s.skater_child).Position - sk(s.skater).Position), rig_dir)
			a = swing(rig_dir, sk_dir)
		elseif s.inherit and A[s.inherit] then
			a = A[s.inherit]
		end
		A[s.slot] = a
		source[b] = index[s.skater]
		offset[b] = sk(s.skater).Rotation:Inverse() * G_inv * a * rest_cf[b].Rotation
	end

	-- Порядок обхода: все кости по пути к управляемым (предки раньше детей).
	local needed: { [Bone]: boolean } = {}
	for b in source do
		local x: Instance? = b
		while x and x:IsA("Bone") do
			needed[x :: Bone] = true
			x = x.Parent
		end
	end
	local order: { Bone } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("Bone") and needed[d] then
			table.insert(order, d)
		end
	end
	local rest_world: { [Bone]: CFrame } = {}
	for b, cf in rest_cf do
		rest_world[b] = cf.Rotation
	end

	local leg_mid = (at("r_leg") + at("l_leg")) / 2
	local leg_length = (at("r_leg") - at("r_knee")).Magnitude + (at("r_knee") - at("r_ankle")).Magnitude
	return {
		model = model,
		root = root,
		root_rotation = root_cf.Rotation,
		order = order,
		source = source,
		offset = offset,
		rest_world = rest_world,
		hips = found.hips,
		hips_local = root_cf:PointToObjectSpace(at("hips")),
		hips_offset = at("hips") - leg_mid,
		leg_length = leg_length,
		index = index,
		leg_scale = nil,
		hidden = {},
	}
end

local function bone_at(rig: Rig, bones: { CFrame }, name: string): Vector3
	return bones[rig.index[name]].Position
end

-- Поставить позу. bones — мировые CFrame костей скейтера в стадах.
function bone_pose.apply(rig: Rig, bones: { CFrame })
	if rig.leg_scale == nil then
		local hip, knee, ankle = bone_at(rig, bones, "RIGHTUPLEG"), bone_at(rig, bones, "RIGHTLEG"), bone_at(rig, bones, "RIGHTFOOT")
		local skater = (hip - knee).Magnitude + (knee - ankle).Magnitude
		rig.leg_scale = if skater > 1e-3 then rig.leg_length / skater else 1
	end
	local function want(b: Bone): CFrame
		return bones[rig.source[b]].Rotation * rig.offset[b]
	end

	-- Таз: голеностопы на месте, бёдра выше на длину ног модели.
	local feet = (bone_at(rig, bones, "RIGHTFOOT") + bone_at(rig, bones, "LEFTFOOT")) / 2
	local uplegs = (bone_at(rig, bones, "RIGHTUPLEG") + bone_at(rig, bones, "LEFTUPLEG")) / 2
	local hips_at = feet + (uplegs - feet) * (rig.leg_scale :: number)
	local pelvis = want(rig.hips) * rig.rest_world[rig.hips]:Inverse()
	local hips_pos = hips_at + pelvis:VectorToWorldSpace(rig.hips_offset)

	-- Корневая деталь: в покойном повороте, так чтобы кость Hips попала в hips_pos.
	local root_cf = CFrame.new(hips_pos) * rig.root_rotation * CFrame.new(-rig.hips_local)
	rig.root.CFrame = root_cf

	local world: { [Bone]: CFrame } = {}
	for _, b in rig.order do
		local parent = b.Parent
		local parent_cf = if parent == rig.root then root_cf else world[parent :: Bone]
		if parent_cf == nil then
			continue
		end
		local base = parent_cf * b.CFrame -- кость с Transform = 1
		if rig.source[b] then
			local w = want(b)
			b.Transform = base.Rotation:Inverse() * w
			world[b] = CFrame.new(base.Position) * w
		else
			b.Transform = CFrame.identity
			world[b] = base
		end
	end
end

-- Спрятать персонажа игрока (видна только модель). Камера Roblox сама
-- меняет LocalTransparencyModifier, поэтому каждый кадр — keep_hidden.
function bone_pose.hide(rig: Rig, character: Model)
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			if rig.hidden[d] == nil then
				rig.hidden[d] = (d :: any).LocalTransparencyModifier
			end
			(d :: any).LocalTransparencyModifier = 1
		end
	end
end

-- Дёшево каждый кадр: только уже найденные детали.
function bone_pose.keep_hidden(rig: Rig)
	for d in rig.hidden do
		(d :: any).LocalTransparencyModifier = 1
	end
end

function bone_pose.destroy(rig: Rig)
	for d, was in rig.hidden do
		if d.Parent then
			(d :: any).LocalTransparencyModifier = was
		end
	end
	rig.model:Destroy()
end

return bone_pose
