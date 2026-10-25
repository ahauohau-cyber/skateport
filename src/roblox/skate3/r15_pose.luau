--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: перенос позы скейтера (36 костей рига Skate 3) на R15-аватар игрока.
--
-- В Rust поза идёт на собственную модель скейтера (retail_character.rs).
-- Здесь вместо неё — R15: по мировым позициям костей строим ориентацию
-- каждой части (куда смотрит кость, в какой плоскости сгибается сустав),
-- затем переводим в Motor6D.Transform сверху вниз по цепочке.
-- Позиции не копируем один в один: у аватара свои длины рук и ног, поэтому
-- бёдра ставим так, чтобы ступни остались на доске (масштаб ног).

local r15_pose = {}

export type Bones = { CFrame } -- мировые CFrame костей в стадах (engine.bone_cframes)

-- Поверх позы скейтера можно наложить позу рук/корпуса:
--   "christ"  — руки в стороны (поза Христа).
export type Override = "christ"

-- motor: Motor6D (классический R15) или AnimationConstraint (новые аватары
-- Roblox: сустав между двумя Attachment, у него тоже есть Transform).
type Joint = { motor: any, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame }

export type Rig = {
	character: Model,
	root: BasePart,
	joints: { [string]: Joint }, -- по имени Part1
	index: { [string]: number }, -- имя кости -> индекс
	leg_scale: number?,
	studs_per_metre: number,
	kinematic: { [Instance]: boolean }, -- прежние IsKinematic у AnimationConstraint
}

local PARTS = {
	"LowerTorso",
	"UpperTorso",
	"Head",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
}

function r15_pose.bind(character: Model, bone_names: { string }, studs_per_metre: number): Rig?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root == nil then
		return nil
	end
	local joints = {}
	for _, d in character:GetDescendants() do
		if d:IsA("Motor6D") and d.Part0 and d.Part1 then
			joints[d.Part1.Name] = { motor = d, part0 = d.Part0, part1 = d.Part1, c0 = d.C0, c1 = d.C1 }
		elseif d:IsA("AnimationConstraint") then
			local a0, a1 = d.Attachment0, d.Attachment1
			if a0 and a1 and a0.Parent and a1.Parent and a0.Parent:IsA("BasePart") and a1.Parent:IsA("BasePart") then
				local part0, part1 = a0.Parent :: BasePart, a1.Parent :: BasePart
				joints[part1.Name] = { motor = d, part0 = part0, part1 = part1, c0 = a0.CFrame, c1 = a1.CFrame }
			end
		end
	end
	for _, name in PARTS do
		if joints[name] == nil then
			return nil -- не R15
		end
	end
	local index = {}
	for i, name in bone_names do
		index[string.upper(name)] = i
	end
	-- ROBLOX: у новых аватаров суставы — AnimationConstraint, их держит физика
	-- с ограниченной силой, и под гравитацией тело «оседает». На время
	-- катания делаем их жёсткими (IsKinematic), потом возвращаем как было.
	local kinematic = {}
	for _, j in joints do
		if j.motor:IsA("AnimationConstraint") then
			kinematic[j.motor] = j.motor.IsKinematic
			j.motor.IsKinematic = true
		end
	end
	return { character = character, root = root, joints = joints, index = index, leg_scale = nil, studs_per_metre = studs_per_metre, kinematic = kinematic }
end

local function pos(rig: any, bones: Bones, name: string): Vector3
	return bones[rig.index[name]].Position
end

local function unit(v: Vector3, fallback: Vector3): Vector3
	local l = v.Magnitude
	if l < 1e-6 then
		return fallback
	end
	return v / l
end

-- Ориентация по оси Y (вдоль кости) и примерной оси X.
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

-- Ось сгиба сустава: для руки предплечье уходит вперёд (-Z), для ноги голень — назад (+Z).
local function bend_axis(upper_up: Vector3, lower_dir: Vector3, is_leg: boolean, fallback: Vector3): Vector3
	local axis = if is_leg then upper_up:Cross(lower_dir) else lower_dir:Cross(upper_up)
	if axis.Magnitude < 0.05 then
		return fallback
	end
	return axis.Unit
end

-- Желаемые мировые ориентации частей (только поворот).
-- rig здесь нужен только ради rig.index (имя кости -> индекс), поэтому
-- функцию использует и bone_pose (свои риги на Bone).
local function orientations(rig: any, bones: Bones): ({ [string]: CFrame }, Vector3)
	local hips = pos(rig, bones, "HIPS")
	local spine1 = pos(rig, bones, "SPINE1")
	local neck = pos(rig, bones, "NECK")
	local head = pos(rig, bones, "HEAD")
	local r_up, l_up = pos(rig, bones, "RIGHTUPLEG"), pos(rig, bones, "LEFTUPLEG")
	local r_arm, l_arm = pos(rig, bones, "RIGHTARM"), pos(rig, bones, "LEFTARM")

	local hip_right = unit(r_up - l_up, Vector3.xAxis)
	local shoulder_right = unit(r_arm - l_arm, hip_right)
	local out: { [string]: CFrame } = {}
	out.LowerTorso = frame(unit(spine1 - hips, Vector3.yAxis), hip_right)
	out.UpperTorso = frame(unit(neck - spine1, Vector3.yAxis), shoulder_right)
	out.Head = frame(unit(head - neck, Vector3.yAxis), shoulder_right)

	for _, side in { "RIGHT", "LEFT" } do
		local prefix = if side == "RIGHT" then "Right" else "Left"
		local body_right = shoulder_right
		-- Рука: плечо -> локоть -> кисть.
		local shoulder = pos(rig, bones, side .. "ARM")
		local elbow = pos(rig, bones, side .. "FOREARM")
		local wrist = pos(rig, bones, side .. "HAND")
		local upper_up = unit(shoulder - elbow, -Vector3.yAxis)
		local lower_up = unit(elbow - wrist, upper_up)
		local arm_axis = bend_axis(upper_up, -lower_up, false, body_right)
		out[prefix .. "UpperArm"] = frame(upper_up, arm_axis)
		out[prefix .. "LowerArm"] = frame(lower_up, arm_axis)
		out[prefix .. "Hand"] = frame(lower_up, arm_axis)
		-- Нога: бедро -> колено -> стопа -> носок.
		local hip = pos(rig, bones, side .. "UPLEG")
		local knee = pos(rig, bones, side .. "LEG")
		local ankle = pos(rig, bones, side .. "FOOT")
		local toe = pos(rig, bones, side .. "TOEBASE")
		local thigh_up = unit(hip - knee, Vector3.yAxis)
		local shin_up = unit(knee - ankle, thigh_up)
		local leg_axis = bend_axis(thigh_up, -shin_up, true, hip_right)
		out[prefix .. "UpperLeg"] = frame(thigh_up, leg_axis)
		out[prefix .. "LowerLeg"] = frame(shin_up, leg_axis)
		-- Стопа: -Z смотрит на носок, X — ось сгиба ноги.
		local forward = unit(toe - ankle, -shin_up:Cross(leg_axis))
		local foot_x = leg_axis - forward * leg_axis:Dot(forward)
		foot_x = unit(foot_x, leg_axis)
		local foot_y = (-forward):Cross(foot_x)
		out[prefix .. "Foot"] = CFrame.fromMatrix(Vector3.zero, foot_x, foot_y, -forward)
	end
	return out, hips
end

r15_pose.orientations = orientations

-- Длина ноги аватара по суставам (бедро -> колено -> голеностоп) / та же у скейтера.
local function leg_scale(rig: Rig, bones: Bones): number
	local j = rig.joints
	-- Бедро: точка крепления в UpperLeg (c1 тазобедренного), колено — c0 коленного там же.
	local thigh = (j.RightUpperLeg.c1.Position - j.RightLowerLeg.c0.Position).Magnitude
	local shin = (j.RightLowerLeg.c1.Position - j.RightFoot.c0.Position).Magnitude
	local hip, knee, ankle = pos(rig, bones, "RIGHTUPLEG"), pos(rig, bones, "RIGHTLEG"), pos(rig, bones, "RIGHTFOOT")
	local skater = (hip - knee).Magnitude + (knee - ankle).Magnitude
	if skater < 1e-3 then
		return 1
	end
	return (thigh + shin) / skater
end

-- Середина тазобедренных суставов аватара в осях LowerTorso.
local function hip_mid_local(rig: Rig): Vector3
	local j = rig.joints
	return (j.RightUpperLeg.c0.Position + j.LeftUpperLeg.c0.Position) / 2
end

-- Применить позу. Вызывать каждый кадр после того, как Animator отработал
-- (RunService.PreSimulation), иначе анимации перезапишут Transform.
local function apply_override(rot: { [string]: CFrame }, override: Override)
	local torso = rot.UpperTorso
	local right = torso.RightVector
	local back = torso.ZVector
	if override == "christ" then
		-- Руки в стороны: у правой руки ось Y смотрит внутрь (к плечу) = -right.
		local up = torso.UpVector
		local function arm(y: Vector3): CFrame
			local x = up:Cross(y)
			return CFrame.fromMatrix(Vector3.zero, x.Unit, y, x.Unit:Cross(y))
		end
		rot.RightUpperArm = arm(-right)
		rot.RightLowerArm = arm(-right)
		rot.RightHand = arm(-right)
		rot.LeftUpperArm = arm(right)
		rot.LeftLowerArm = arm(right)
		rot.LeftHand = arm(right)
		-- Голова чуть вверх-вбок, как на иконе.
		rot.Head = rot.Head * CFrame.Angles(math.rad(-12), 0, math.rad(8))
	end
end

function r15_pose.apply(rig: Rig, bones: Bones, override: Override?)
	local rot = orientations(rig, bones)
	if override then
		apply_override(rot, override)
	end
	if rig.leg_scale == nil then
		rig.leg_scale = leg_scale(rig, bones)
	end
	-- Таз: голеностопы остаются на месте, середина тазобедренных суставов
	-- поднята над ними в масштабе длины ног аватара.
	local feet = (pos(rig, bones, "RIGHTFOOT") + pos(rig, bones, "LEFTFOOT")) / 2
	local uplegs = (pos(rig, bones, "RIGHTUPLEG") + pos(rig, bones, "LEFTUPLEG")) / 2
	local hips_at = feet + (uplegs - feet) * (rig.leg_scale :: number)

	-- Корень: LowerTorso = HRP * C0 * T * C1^-1 с T = 1  =>  HRP = LT * C1 * C0^-1.
	local root = rig.joints.LowerTorso
	local lower = CFrame.new(hips_at) * rot.LowerTorso * CFrame.new(-hip_mid_local(rig))
	root.motor.Transform = CFrame.identity
	rig.root.CFrame = lower * root.c1 * root.c0:Inverse()

	-- Остальные суставы: только поворот, сверху вниз.
	for _, name in PARTS do
		if name ~= "LowerTorso" then
			local j = rig.joints[name]
			local parent = rot[j.part0.Name]
			local child = rot[name]
			if parent and child then
				j.motor.Transform = (parent * j.c0.Rotation):Inverse() * child * j.c1.Rotation
			end
		end
	end
end

-- Вернуть суставы в покой (когда скейт выключили).
function r15_pose.reset(rig: Rig)
	for _, j in rig.joints do
		j.motor.Transform = CFrame.identity
	end
	for motor, was in rig.kinematic do
		(motor :: any).IsKinematic = was
	end
end

return r15_pose
