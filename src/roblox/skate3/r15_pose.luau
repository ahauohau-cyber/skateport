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

export type Bones = { any } -- мировые матрицы 4x4 (столбцы), метры

type Joint = { motor: Motor6D, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame }

export type Rig = {
	character: Model,
	root: BasePart,
	joints: { [string]: Joint }, -- по имени Part1
	index: { [string]: number }, -- имя кости -> индекс
	leg_scale: number?,
	studs_per_metre: number,
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
	return { character = character, root = root, joints = joints, index = index, leg_scale = nil, studs_per_metre = studs_per_metre }
end

local function pos(rig: Rig, bones: Bones, name: string): Vector3
	local m = bones[rig.index[name]]
	local s = rig.studs_per_metre
	return Vector3.new(m[4][1] * s, m[4][2] * s, m[4][3] * s)
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
local function orientations(rig: Rig, bones: Bones): ({ [string]: CFrame }, Vector3)
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

-- Длина ноги аватара в стадах (по суставам в позе покоя) / длина ноги скейтера.
local function leg_scale(rig: Rig, bones: Bones): number
	local j = rig.joints
	local avatar = (j.RightUpperLeg.part1.Size.Y + j.RightLowerLeg.part1.Size.Y)
	local hip, knee, ankle = pos(rig, bones, "RIGHTUPLEG"), pos(rig, bones, "RIGHTLEG"), pos(rig, bones, "RIGHTFOOT")
	local skater = (hip - knee).Magnitude + (knee - ankle).Magnitude
	if skater < 1e-3 then
		return 1
	end
	return avatar / skater
end

-- Применить позу. Вызывать каждый кадр после того, как Animator отработал
-- (RunService.PreSimulation), иначе анимации перезапишут Transform.
function r15_pose.apply(rig: Rig, bones: Bones)
	local rot, hips = orientations(rig, bones)
	if rig.leg_scale == nil then
		rig.leg_scale = leg_scale(rig, bones)
	end
	-- Бёдра: ступни остаются на месте, высота бёдер над ними — по длине ног аватара.
	local feet = (pos(rig, bones, "RIGHTFOOT") + pos(rig, bones, "LEFTFOOT")) / 2
	local hips_at = feet + (hips - feet) * (rig.leg_scale :: number)

	-- Корень: LowerTorso = HRP * C0 * T * C1^-1 с T = 1  =>  HRP = LT * C1 * C0^-1.
	local root = rig.joints.LowerTorso
	local lower = CFrame.new(hips_at) * rot.LowerTorso
	root.motor.Transform = CFrame.identity
	rig.root.CFrame = lower * root.c1 * root.c0:Inverse()
	rig.root.AssemblyLinearVelocity = Vector3.zero
	rig.root.AssemblyAngularVelocity = Vector3.zero

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
end

return r15_pose
