--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: снимок скейтера для репликации другим игрокам (буфер ≤ 1 КБ для
-- UnreliableRemoteEvent). Схема квантования — как в Codec примерочного плейса:
-- позиция кости относительно корня в int16 (у нас 1/1000 стада, ±32 стада),
-- поворот — кватернион «smallest three» в 32 битах (2 бита индекс + 3×10 бит).
--
-- Пакет (little-endian):
--   0  u8   версия
--   1  u8   флаги (бит 0 — на доске)
--   2  u16  номер пакета
--   4  f64  время отправки (workspace:GetServerTimeNow())
--  12  f32×3 таз (HIPS) в мире, стады
--  24  i16×3 + u32 — дека (позиция относительно таза + поворот)
--  34  i16×3 + u32 на каждую кость из BONES (21 кость) = 210
-- итого 244 байта.

local net_codec = {}

net_codec.VERSION = 1

-- Кости, которые нужны r15_pose и bone_pose на приёмной стороне.
net_codec.BONES = {
	"HIPS",
	"SPINE1",
	"SPINE3",
	"NECK",
	"HEAD",
	"RIGHTSHOULDER",
	"RIGHTARM",
	"RIGHTFOREARM",
	"RIGHTHAND",
	"LEFTSHOULDER",
	"LEFTARM",
	"LEFTFOREARM",
	"LEFTHAND",
	"RIGHTUPLEG",
	"RIGHTLEG",
	"RIGHTFOOT",
	"RIGHTTOEBASE",
	"LEFTUPLEG",
	"LEFTLEG",
	"LEFTFOOT",
	"LEFTTOEBASE",
}

local HEADER = 24
local ROW = 10
net_codec.SIZE = HEADER + ROW * (1 + #net_codec.BONES)

local POS_SCALE = 1000 -- единиц на стад
local POS_LIMIT = 32.767 -- стады

-- Кватернион -> 32 бита (smallest three, как quat_bits в примерочном плейсе).
local function quat_bits(x: number, y: number, z: number, w: number): number
	local ax, ay, az, aw = math.abs(x), math.abs(y), math.abs(z), math.abs(w)
	local index, a, b, c, big = 0, y, z, w, x
	local best = ax
	if ay > best then
		index, best, a, b, c, big = 1, ay, x, z, w, y
	end
	if az > best then
		index, best, a, b, c, big = 2, az, x, y, w, z
	end
	if aw > best then
		index, a, b, c, big = 3, x, y, z, w
	end
	local sign = if big < 0 then -1 else 1
	local function q(v: number): number
		return math.clamp(math.floor((v * sign * math.sqrt(2) * 0.5 + 0.5) * 1023 + 0.5), 0, 1023)
	end
	return index + q(a) * 4 + q(b) * 4096 + q(c) * 4194304
end

local function quat_unbits(bits: number): (number, number, number, number)
	local index = bit32.band(bits, 3)
	local function u(v: number): number
		return (v / 1023 - 0.5) * 2 / math.sqrt(2)
	end
	local a = u(bit32.band(bit32.rshift(bits, 2), 1023))
	local b = u(bit32.band(bit32.rshift(bits, 12), 1023))
	local c = u(bit32.band(bit32.rshift(bits, 22), 1023))
	local big = math.sqrt(math.max(0, 1 - a * a - b * b - c * c))
	if index == 0 then
		return big, a, b, c
	elseif index == 1 then
		return a, big, b, c
	elseif index == 2 then
		return a, b, big, c
	end
	return a, b, c, big
end

-- Кватернион поворота CFrame (x, y, z, w).
local function cframe_quat(cf: CFrame): (number, number, number, number)
	local axis, angle = cf:ToAxisAngle()
	local s = math.sin(angle / 2)
	return axis.X * s, axis.Y * s, axis.Z * s, math.cos(angle / 2)
end

local function write_row(b: buffer, offset: number, origin: Vector3, cf: CFrame)
	local d = cf.Position - origin
	local function q(v: number): number
		return math.round(math.clamp(v, -POS_LIMIT, POS_LIMIT) * POS_SCALE)
	end
	buffer.writei16(b, offset, q(d.X))
	buffer.writei16(b, offset + 2, q(d.Y))
	buffer.writei16(b, offset + 4, q(d.Z))
	local x, y, z, w = cframe_quat(cf)
	buffer.writeu32(b, offset + 6, quat_bits(x, y, z, w))
end

local function read_row(b: buffer, offset: number, origin: Vector3): CFrame
	local x = buffer.readi16(b, offset) / POS_SCALE
	local y = buffer.readi16(b, offset + 2) / POS_SCALE
	local z = buffer.readi16(b, offset + 4) / POS_SCALE
	local qx, qy, qz, qw = quat_unbits(buffer.readu32(b, offset + 6))
	local p = origin + Vector3.new(x, y, z)
	return CFrame.new(p.X, p.Y, p.Z, qx, qy, qz, qw)
end

-- index — имя кости скейтера -> индекс в bones (как bone_names ядра).
function net_codec.encode(seq: number, time: number, on_board: boolean, deck: CFrame, bones: { CFrame }, index: { [string]: number }): buffer?
	local hips = bones[index.HIPS]
	if hips == nil then
		return nil
	end
	local origin = hips.Position
	if origin ~= origin or origin.Magnitude > 1e6 then
		return nil
	end
	local b = buffer.create(net_codec.SIZE)
	buffer.writeu8(b, 0, net_codec.VERSION)
	buffer.writeu8(b, 1, if on_board then 1 else 0)
	buffer.writeu16(b, 2, seq % 65536)
	buffer.writef64(b, 4, time)
	buffer.writef32(b, 12, origin.X)
	buffer.writef32(b, 16, origin.Y)
	buffer.writef32(b, 20, origin.Z)
	write_row(b, HEADER, origin, deck)
	for i, name in net_codec.BONES do
		local cf = bones[index[name]]
		if cf == nil then
			return nil
		end
		write_row(b, HEADER + ROW * i, origin, cf)
	end
	return b
end

export type Snapshot = {
	seq: number,
	time: number,
	on_board: boolean,
	hips: Vector3,
	deck: CFrame,
	bones: { [string]: CFrame }, -- по именам из BONES
}

-- Лёгкая проверка для сервера: версия, длина и позиция таза (без разбора костей).
function net_codec.peek(b: any): Vector3?
	if typeof(b) ~= "buffer" or buffer.len(b) ~= net_codec.SIZE or buffer.readu8(b, 0) ~= net_codec.VERSION then
		return nil
	end
	local p = Vector3.new(buffer.readf32(b, 12), buffer.readf32(b, 16), buffer.readf32(b, 20))
	if p ~= p or p.Magnitude > 1e6 then
		return nil
	end
	return p
end

function net_codec.decode(b: any): Snapshot?
	local origin = net_codec.peek(b)
	if origin == nil then
		return nil
	end
	local bones = {}
	for i, name in net_codec.BONES do
		bones[name] = read_row(b, HEADER + ROW * i, origin)
	end
	return {
		seq = buffer.readu16(b, 2),
		time = buffer.readf64(b, 4),
		on_board = bit32.band(buffer.readu8(b, 1), 1) ~= 0,
		hips = origin,
		deck = read_row(b, HEADER, origin),
		bones = bones,
	}
end

net_codec.quat_bits = quat_bits
net_codec.quat_unbits = quat_unbits

return net_codec
