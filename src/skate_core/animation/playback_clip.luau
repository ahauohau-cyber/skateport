--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/playback_clip.rs (коммит 2e16697)
--
-- Stateful direct Andale Clip clock and attribute evaluation.
-- Init 827B8AB0, AddTime 82D25A00, GetAttributes 82D25E30,
-- Attribute::Init 82D164F8 and scalar curve lookup 82D193E0.

local rt = require("../../rt")
local clip_clock = require("./clip_clock")
local attributes = require("./output/attributes")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local playback_clip = {}

export type ClipAttribute = { name: attributes.AttributeName, kind: number, begin: number, ["end"]: number, payload: { number } }

export type PlaybackClip = { clock: clip_clock.ClipClock, attributes: { ClipAttribute } }

local PlaybackClip = {}
playback_clip.PlaybackClip = PlaybackClip

function PlaybackClip.new(frames: number, fps: number, base_speed: number, flags: number, attrs: { ClipAttribute }): PlaybackClip
	return {
		clock = {
			frames = frames,
			fps = fps,
			base_speed = base_speed,
			speed = 1.0,
			length = f32(f32(frames - 1.0) / f32(f32(1.0 * base_speed) * fps)),
			time = 0.0,
			previous_time = 0.0,
			loops_since_evaluation = 0,
			looping = bit32.band(flags, 0x10000000) ~= 0,
			phase_controlled = bit32.band(flags, 0x40000000) ~= 0,
		},
		attributes = attrs,
	}
end

-- Animatable 825310F0 resets the property before every AddTime call.
function PlaybackClip.advance(self: PlaybackClip, dt: number, phase: number): clip_clock.AdvanceResult
	local result = { crossed_end = false, overshoot = -1.0, remaining_before_wrap = -1.0 }
	clip_clock.ClipClock.advance(self.clock, dt, phase, result)
	return result
end

-- The curve record is an opaque word, point count, then (x,y) pairs. Native
-- binary search interpolates the final crossed bounds with a fused multiply.
-- ROBLOX: Result<f32, String> -> число или rt.raise(строка).
function playback_clip.sample_curve(words: { number }, time: number): number
	local count = words[2]
	if count == nil then
		rt.raise("Missing animation curve count")
	end
	if count == 0 or count > math.max(#words - 2, 0) // 2 then
		rt.raise("Truncated/empty animation curve")
	end
	local function point(index: number): (number, number)
		return from_bits(words[3 + 2 * index]), from_bits(words[4 + 2 * index])
	end
	local low = 0
	local high = count - 1
	local low_x, low_y = point(low)
	local high_x, high_y = point(high)
	if not (time > low_x) then
		return low_y
	end
	if not (time < high_x) then
		return high_y
	end
	while not (low_x > high_x) do
		local middle = (low + high) // 2
		local x, y = point(middle)
		if time > x then
			low = middle + 1
			if low >= count then
				rt.raise("Malformed animation curve search bounds")
			end
			low_x, low_y = point(low)
		elseif time < x then
			if middle == 0 then
				rt.raise("Malformed animation curve search bounds")
			end
			high = middle - 1
			high_x, high_y = point(high)
		else
			return y
		end
	end
	local slope = f32(f32(low_y - high_y) / f32(low_x - high_x))
	return mul_add(slope, f32(time - high_x), high_y)
end

local function materialize(self: PlaybackClip, attribute: ClipAttribute, status: number): attributes.AnimationAttribute
	local payload: { number | false } = { false, false, false, false, false, false }
	local lanes = if attribute.kind == 0 then 1 elseif attribute.kind == 1 then 4 elseif attribute.kind == 3 then 6 else 0
	if #attribute.payload < lanes then
		rt.raise("Truncated clip attribute payload")
	end
	for i = 1, lanes do
		payload[i] = attribute.payload[i]
	end
	if attribute.kind == 2 then
		-- The source deliberately multiplies time*fps*playback_speed;
		-- base_speed is not an additional factor in Attribute::Init.
		local frame = f32(f32(self.clock.time * self.clock.fps) * self.clock.speed)
		payload[1] = rt.to_bits(playback_clip.sample_curve(attribute.payload, frame))
	end
	local untimed = bit32.band(status, 2) ~= 0
	return {
		name = attribute.name,
		kind = attribute.kind,
		payload = payload,
		status = status,
		sequence_id = -1,
		begin_time = if untimed then -1.0 else f32(attribute.begin * self.clock.length),
		end_time = if untimed then -1.0 else f32(attribute["end"] * self.clock.length),
	}
end

-- Ordered GetAttributes. The untimed bulk path passes status 4, unlike
-- GetAttributeStatus's untimed status 6; its times are multiplied by length.
function PlaybackClip.attributes(self: PlaybackClip, mask: number): { attributes.AnimationAttribute }
	local output = {}
	for _, attribute in self.attributes do
		local status = if attribute.begin == -1.0 then 4 else clip_clock.ClipClock.attribute_status(self.clock, attribute.begin, attribute["end"])
		local skip = attribute.begin ~= -1.0 and (bit32.band(mask, 0x1c, status) == 0 or bit32.band(mask, 3, status) == 0)
		if not skip then
			table.insert(output, materialize(self, attribute, status))
		end
	end
	return output
end

-- 82D25CA0 uses status 6 for untimed records and returns first valid match.
function PlaybackClip.attribute(self: PlaybackClip, name: attributes.AttributeName, mask: number): attributes.AnimationAttribute?
	for _, attribute in self.attributes do
		if attributes.name_eq(attribute.name, name) then
			local status = clip_clock.ClipClock.attribute_status(self.clock, attribute.begin, attribute["end"])
			if not (bit32.band(mask, 0x1c, status) == 0 or bit32.band(mask, 3, status) == 0) then
				return materialize(self, attribute, status)
			end
		end
	end
	return nil
end

return playback_clip
