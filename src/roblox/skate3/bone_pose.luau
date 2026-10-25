--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: перенос позы скейтера на свою модель со скиннингом (кости Bone),
-- например MMD-персонажа: один MeshPart и дерево костей
-- Hips → Spine → Chest → Neck → Head, Right arm/elbow/wrist, Right leg/knee/ankle/toe.
--
-- Ориентации частей тела берём те же, что для R15 (r15_pose.orientations).
-- Для каждой части строим такую же рамку по позе покоя модели и поворачиваем
-- кость на разницу «рамка скейтера × рамка покоя⁻¹». Так модель в любой позе
-- покоя (T, A) повторяет движения скейтера. Пальцы, волосы, одежда — просто
-- едут за родительскими костями.

local r15_pose = require(script.Parent.r15_pose)

local bone_pose = {}

-- Имена костей (сравниваем без регистра, пробелов, точек и подчёркиваний).
local NAMES: { [string]: { string } } = {
	hips = { "hips", "pelvis" },
	spine = { "spine", "spine1", "abdomen", "lowerspine" },
	chest = { "chest", "upperchest", "spine2", "upperspine" },
	neck = { "neck" },
	head = { "head" },
	r_arm = { "rightarm", "rightupperarm", "upperarmr", "armr" },
	r_elbow = { "rightelbow", "rightforearm", "rightlowerarm", "lowerarmr", "forearmr", "elbowr" },
	r_wrist = { "rightwrist", "righthand", "handr", "wristr" },
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

-- Какая кость какой частью тела R15 управляется.
local ROLES: { { string } } = {
	{ "hips", "LowerTorso" },
	{ "spine", "UpperTorso" },
	{ "chest", "UpperTorso" },
	{ "neck", "Head" },
	{ "head", "Head" },
	{ "r_arm", "RightUpperArm" },
	{ "r_elbow", "RightLowerArm" },
	{ "r_wrist", "RightHand" },
	{ "l_arm", "LeftUpperArm" },
	{ "l_elbow", "LeftLowerArm" },
	{ "l_wrist", "LeftHand" },
	{ "r_leg", "RightUpperLeg" },
	{ "r_knee", "RightLowerLeg" },
	{ "r_ankle", "RightFoot" },
	{ "l_leg", "LeftUpperLeg" },
	{ "l_knee", "LeftLowerLeg" },
	{ "l_ankle", "LeftFoot" },
}

export type Rig = {
	model: Model,
	root: BasePart,
	root_rotation: CFrame, -- поворот корневой детали в покое
	order: { Bone }, -- кости, которые считаем (сверху вниз)
	role: { [Bone]: string }, -- кость -> часть R15
	rest_world: { [Bone]: CFrame }, -- поворот кости в мире в покое
	rest_frame: { [string]: CFrame }, -- рамка части R15 в покое
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

-- Как frame в r15_pose: Y вдоль кости, X — ортогонализованная подсказка.
local function frame(y: Vector3, x_hint: Vector3): CFrame
	local x = x_hint - y * x_hint:Dot(y)
	if x.Magnitude < 1e-4 then
		x = Vector3.xAxis - y * y.X
		if x.Magnitude < 1e-4 then
			x = Vector3.zAxis - y * y.Z
		end
	end
	x = x.Unit
	return CFrame.fromMatrix(Vector3.zero, x, y, x:Cross(y))
end

-- Кратчайший поворот, переводящий направление a в b.
local function swing(a: Vector3, b: Vector3): CFrame
	local axis = a:Cross(b)
	local c = math.clamp(a:Dot(b), -1, 1)
	if axis.Magnitude < 1e-6 then
		if c > 0 then
			return CFrame.identity
		end
		return CFrame.fromAxisAngle(Vector3.zAxis, math.pi)
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(c))
end

-- Рамка конечности в покое: X — «вправо» висящей конечности, повёрнутое
-- вместе с ней (так одинаково работают T- и A-поза).
local function limb_rest(y: Vector3, right: Vector3): CFrame
	return frame(y, swing(Vector3.yAxis, y):VectorToWorldSpace(right))
end

local function foot_frame(ankle: Vector3, toe: Vector3, right: Vector3): CFrame
	local forward = unit(toe - ankle, -Vector3.zAxis)
	local x = unit(right - forward * right:Dot(forward), right)
	local y = (-forward):Cross(x)
	return CFrame.fromMatrix(Vector3.zero, x, y, -forward)
end

-- Найти модель-риг: корневая деталь с костями внутри.
function bone_pose.bind(template: Model, bone_names: { string }, parent: Instance): Rig?
	local model = template:Clone()
	-- Свою анимацию у клона выключаем: позу ставим только мы.
	for _, d in model:GetDescendants() do
		if d:IsA("Animator") or d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	local found: { [string]: Bone } = {}
	local by_key: { [string]: Bone } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Bone") then
			local k = key(d.Name)
			if by_key[k] == nil then
				by_key[k] = d
			end
		end
	end
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
	found.spine = found.spine or found.chest
	found.head = found.head or found.neck

	-- Корневая деталь, в которой висят кости.
	local root: BasePart? = nil
	local p = found.hips.Parent
	while p and not p:IsA("BasePart") do
		p = p.Parent
	end
	root = p :: BasePart?
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

	-- Мировые CFrame костей в покое: без Transform, от корневой детали.
	local root_cf = (root :: BasePart).CFrame
	local rest_cf: { [Bone]: CFrame } = {}
	local order: { Bone } = {}
	for _, d in (root :: BasePart):GetDescendants() do
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

	local role: { [Bone]: string } = {}
	for _, pair in ROLES do
		local b = found[pair[1]]
		if b and role[b] == nil then
			role[b] = pair[2]
		end
	end
	-- Порядок обхода: все кости по пути к управляемым (предки раньше детей).
	local needed: { [Bone]: boolean } = {}
	for b in role do
		local x: Instance? = b
		while x and x:IsA("Bone") do
			needed[x :: Bone] = true
			x = x.Parent
		end
	end
	for _, d in (root :: BasePart):GetDescendants() do
		if d:IsA("Bone") and needed[d] then
			table.insert(order, d)
		end
	end

	-- Рамки частей тела в покое (в мире), в тех же соглашениях, что r15_pose.
	local hip_right = unit(at("r_leg") - at("l_leg"), Vector3.xAxis)
	local shoulder_right = unit(at("r_arm") - at("l_arm"), hip_right)
	local chest_at = if found.chest then at("chest") else at("spine")
	local rest_frame: { [string]: CFrame } = {}
	rest_frame.LowerTorso = frame(unit(at("spine") - at("hips"), Vector3.yAxis), hip_right)
	rest_frame.UpperTorso = frame(unit(at("neck") - at("spine"), unit(at("neck") - chest_at, Vector3.yAxis)), shoulder_right)
	rest_frame.Head = frame(Vector3.yAxis, shoulder_right)
	for _, side in { "r", "l" } do
		local Side = if side == "r" then "Right" else "Left"
		local upper = unit(at(side .. "_arm") - at(side .. "_elbow"), -Vector3.yAxis)
		local lower = unit(at(side .. "_elbow") - at(side .. "_wrist"), upper)
		rest_frame[Side .. "UpperArm"] = limb_rest(upper, shoulder_right)
		rest_frame[Side .. "LowerArm"] = limb_rest(lower, shoulder_right)
		rest_frame[Side .. "Hand"] = rest_frame[Side .. "LowerArm"]
		local thigh = unit(at(side .. "_leg") - at(side .. "_knee"), Vector3.yAxis)
		local shin = unit(at(side .. "_knee") - at(side .. "_ankle"), thigh)
		rest_frame[Side .. "UpperLeg"] = limb_rest(thigh, hip_right)
		rest_frame[Side .. "LowerLeg"] = limb_rest(shin, hip_right)
		local toe = if found[side .. "_toe"] then at(side .. "_toe") else at(side .. "_ankle") - Vector3.zAxis
		rest_frame[Side .. "Foot"] = foot_frame(at(side .. "_ankle"), toe, hip_right)
	end
	-- Пустая часть (если такой роли нет) — без поворота.
	local rest_world: { [Bone]: CFrame } = {}
	for b, cf in rest_cf do
		rest_world[b] = cf.Rotation
	end

	local leg_mid = (at("r_leg") + at("l_leg")) / 2
	local leg_length = (at("r_leg") - at("r_knee")).Magnitude + (at("r_knee") - at("r_ankle")).Magnitude
	local index = {}
	for i, name in bone_names do
		index[string.upper(name)] = i
	end
	return {
		model = model,
		root = root :: BasePart,
		root_rotation = root_cf.Rotation,
		order = order,
		role = role,
		rest_world = rest_world,
		rest_frame = rest_frame,
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
	local target = r15_pose.orientations(rig, bones)
	if rig.leg_scale == nil then
		local hip, knee, ankle = bone_at(rig, bones, "RIGHTUPLEG"), bone_at(rig, bones, "RIGHTLEG"), bone_at(rig, bones, "RIGHTFOOT")
		local skater = (hip - knee).Magnitude + (knee - ankle).Magnitude
		rig.leg_scale = if skater > 1e-3 then rig.leg_length / skater else 1
	end
	-- Разница поворотов частей: куда повернуть кость из позы покоя.
	local delta: { [string]: CFrame } = {}
	for name, rest in rig.rest_frame do
		local t = target[name]
		if t then
			delta[name] = t * rest:Inverse()
		end
	end
	-- Таз: голеностопы на месте, бёдра выше на длину ног модели (как в r15_pose).
	local feet = (bone_at(rig, bones, "RIGHTFOOT") + bone_at(rig, bones, "LEFTFOOT")) / 2
	local uplegs = (bone_at(rig, bones, "RIGHTUPLEG") + bone_at(rig, bones, "LEFTUPLEG")) / 2
	local hips_at = feet + (uplegs - feet) * (rig.leg_scale :: number)
	local pelvis = delta.LowerTorso or CFrame.identity
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
		local r = rig.role[b]
		local d = if r then delta[r] else nil
		if d then
			local want = d * rig.rest_world[b]
			b.Transform = base.Rotation:Inverse() * want
			world[b] = CFrame.new(base.Position) * want
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
