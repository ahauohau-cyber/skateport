--!strict
--!optimize 2
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: звуки скейта. Один «голос» на скейтера: своего и чужих (у чужих —
-- по режиму из пакета net_codec и скорости деки между кадрами), поэтому все
-- слышат одно и то же.
--
--   roll  — колёса по земле (петля), громкость и высота тона по скорости
--   grind — металл/бетон в грайнде (петля)
--   pop   — щелчок хвоста при отрыве (земля -> воздух)
--   land  — приземление (воздух -> земля), громче при быстром падении
--   clack — заход в грайнд
--   bail  — падение (режим bail)
--
-- Звуки — бесплатные Pro Sound Effects из Creator Store (никаких файлов EA).
-- Свои id можно задать атрибутами SoundService: Skate3Sound_<имя> = "rbxassetid://…".
-- Громкость всех звуков скейта — SoundService.Skate3 (SoundGroup).

local SoundService = game:GetService("SoundService")

local skate_audio = {}

export type Clip = {
	id: string,
	volume: number,
	loop: boolean,
	from: number?, -- с: начало куска файла
	to: number?, -- с: конец куска (nil — до конца)
}

skate_audio.CLIPS = {
	-- Куски файлов подобраны по громкости (PlaybackLoudness) в Studio.
	roll = { id = "rbxassetid://9125955680", volume = 0.35, loop = true, from = 2, to = 31 } :: Clip,
	grind = { id = "rbxassetid://9125957232", volume = 0.6, loop = true, from = 0.25, to = 2.55 } :: Clip,
	pop = { id = "rbxassetid://9125958103", volume = 0.8, loop = false, from = 0.24, to = 0.62 } :: Clip,
	land = { id = "rbxassetid://9120884238", volume = 0.8, loop = false, from = 0.08, to = 0.62 } :: Clip,
	clack = { id = "rbxassetid://9119175992", volume = 1, loop = false, from = 0.18, to = 0.45 } :: Clip,
	bail = { id = "rbxassetid://9113469532", volume = 0.8, loop = false, from = 0.35, to = 2.3 } :: Clip,
}

skate_audio.HEAR_DISTANCE = 140 -- стады: дальше чужие голоса не создаём
skate_audio.ROLL_FULL_SPEED = 12 -- м/с: на этой скорости петля колёс на полную

-- Режимы — как net_codec.MODE (копия, чтобы не тянуть модуль).
local GROUND, AIR, GRIND, BAIL = 0, 1, 2, 3

local group: SoundGroup? = nil
local function sound_group(): SoundGroup
	if group and group.Parent then
		return group
	end
	local existing = SoundService:FindFirstChild("Skate3")
	if existing and existing:IsA("SoundGroup") then
		group = existing
		return existing
	end
	local g = Instance.new("SoundGroup")
	g.Name = "Skate3"
	g.Volume = 1
	g.Parent = SoundService
	group = g
	return g
end

local function clip_id(name: string, clip: Clip): string
	local custom = SoundService:GetAttribute("Skate3Sound_" .. name)
	return if type(custom) == "string" and custom ~= "" then custom else clip.id
end

export type Voice = {
	attachment: Attachment,
	sounds: { [string]: Sound },
	mode: number,
	air_time: number,
	speed: number, -- м/с, сглаженная
	last_position: Vector3?,
	fall: number, -- стады/с вниз (для громкости приземления)
	roll_level: number,
	grind_level: number,
	cooldown: { [string]: number },
}

local function make_sound(name: string, clip: Clip, parent: Instance): Sound
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = clip_id(name, clip)
	s.Volume = clip.volume
	s.Looped = clip.loop
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = skate_audio.HEAR_DISTANCE
	s.SoundGroup = sound_group()
	if clip.from or clip.to then
		s.PlaybackRegionsEnabled = true
		local range = NumberRange.new(clip.from or 0, clip.to or 600)
		if clip.loop then
			s.LoopRegion = range
		else
			s.PlaybackRegion = range
		end
	end
	s.Parent = parent
	return s
end

-- Новый голос (звуки висят на Attachment в Terrain и двигаются за декой).
function skate_audio.new(name: string): Voice
	local attachment = Instance.new("Attachment")
	attachment.Name = name .. "_skate_audio"
	local sounds = {}
	for key, clip in skate_audio.CLIPS do
		sounds[key] = make_sound(key, clip, attachment)
	end
	attachment.Parent = workspace.Terrain
	return {
		attachment = attachment,
		sounds = sounds,
		mode = GROUND,
		air_time = 0,
		speed = 0,
		last_position = nil,
		fall = 0,
		roll_level = 0,
		grind_level = 0,
		cooldown = {},
	}
end

local function one_shot(v: Voice, name: string, volume_scale: number)
	local s = v.sounds[name]
	local now = os.clock()
	if s == nil or (v.cooldown[name] or 0) > now then
		return
	end
	v.cooldown[name] = now + 0.12
	local clip = skate_audio.CLIPS[name]
	s.Volume = clip.volume * volume_scale
	s.PlaybackSpeed = 0.95 + math.random() * 0.1
	s.TimePosition = clip.from or 0
	s:Play()
end

local function set_loop(s: Sound, level: number, base: number, pitch: number)
	if level > 0.01 then
		s.Volume = base * level
		s.PlaybackSpeed = pitch
		if not s.IsPlaying then
			s:Play()
		end
	elseif s.IsPlaying then
		s:Stop()
	end
end

-- Кадр голоса. mode — net_codec.MODE; position — дека в мире (стады);
-- speed — м/с, если известна (свой скейтер), иначе считаем по позиции.
function skate_audio.update(v: Voice, dt: number, mode: number, position: Vector3, studs_per_metre: number, speed: number?)
	dt = math.max(dt, 1e-3)
	local last = v.last_position
	v.last_position = position
	local velocity_y = 0
	if last then
		local d = position - last
		if d.Magnitude > 30 then
			last = nil -- телепорт: не считаем скорость
		else
			velocity_y = d.Y / dt
			if speed == nil then
				speed = Vector3.new(d.X, 0, d.Z).Magnitude / dt / studs_per_metre
			end
		end
	end
	local target = speed or 0
	v.speed += (target - v.speed) * math.min(1, dt * 8)
	v.attachment.WorldPosition = position

	-- События по смене режима.
	local before = v.mode
	if mode ~= before then
		if mode == AIR and before == GROUND then
			one_shot(v, "pop", 1)
		elseif mode == GROUND and (before == AIR or before == GRIND) then
			local hard = math.clamp(v.fall / 40, 0.35, 1)
			if v.air_time > 0.12 or before == GRIND then
				one_shot(v, "land", hard)
			end
		elseif mode == GRIND then
			one_shot(v, "clack", 1)
		elseif mode == BAIL then
			one_shot(v, "bail", 1)
		end
		v.mode = mode
		v.air_time = 0
	end
	if mode == AIR then
		v.air_time += dt
		v.fall = math.max(v.fall * 0.98, -velocity_y)
	else
		v.fall = 0
	end

	-- Петли: плавно включаем/выключаем.
	local roll_goal = if mode == GROUND then math.clamp(v.speed / skate_audio.ROLL_FULL_SPEED, 0, 1) else 0
	if v.speed < 0.4 then
		roll_goal = 0
	end
	local grind_goal = if mode == GRIND then math.clamp(0.5 + v.speed / 16, 0.5, 1) else 0
	local k = math.min(1, dt * 12)
	v.roll_level += (roll_goal - v.roll_level) * k
	v.grind_level += (grind_goal - v.grind_level) * k
	set_loop(v.sounds.roll, v.roll_level, skate_audio.CLIPS.roll.volume, 0.75 + math.clamp(v.speed / 20, 0, 0.6))
	set_loop(v.sounds.grind, v.grind_level, skate_audio.CLIPS.grind.volume, 0.85 + math.clamp(v.speed / 30, 0, 0.35))
end

-- Заглушить петли (скейтер пропал или далеко), не уничтожая голос.
function skate_audio.mute(v: Voice)
	v.roll_level = 0
	v.grind_level = 0
	for _, s in v.sounds do
		if s.Looped and s.IsPlaying then
			s:Stop()
		end
	end
	v.last_position = nil
end

function skate_audio.destroy(v: Voice)
	v.attachment:Destroy()
end

return skate_audio
