--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/pose_blend.rs (коммит 2e16697)
--
-- Standard SQT blend in TU3 ACS 828CB418..4A4 and worker 828D6BA8..6C2C.
-- The caller owns tree order and coefficients; interpolation does not flatten
-- nested blends or use a renderer's quaternion blend implementation.

local rt = require("../../rt")
local native_arithmetic = require("../physics/native_arithmetic")
local sqt = require("./output/sqt")

local f32 = rt.f32
local mul_add = rt.mul_add

local pose_blend = {}

type Sqt = sqt.Sqt

local function interpolate(first: { number }, second: { number }, weight: number): { number }
	local out = {}
	for lane = 1, 4 do
		out[lane] = mul_add(f32(second[lane] - first[lane]), weight, first[lane])
	end
	return out
end

function pose_blend.blend_sample(first: Sqt, second: Sqt, weight: number): Sqt
	local positive = native_arithmetic.dot4(first.rotation, second.rotation) > 0.0
	local rotation = {}
	for lane = 1, 4 do
		local a, b = first.rotation[lane], second.rotation[lane]
		if positive then
			rotation[lane] = mul_add(f32(b - a), weight, a)
		else
			rotation[lane] = mul_add(-f32(b + a), weight, a)
		end
	end
	local squared = native_arithmetic.dot4(rotation, rotation)
	local inverse = native_arithmetic.reciprocal_square_root_estimate(squared)
	for _ = 1, 2 do
		inverse = mul_add(f32(inverse * 0.5), mul_add(-squared, f32(inverse * inverse), 1.0), inverse)
	end
	return {
		scale = interpolate(first.scale, second.scale, weight),
		rotation = { f32(rotation[1] * inverse), f32(rotation[2] * inverse), f32(rotation[3] * inverse), f32(rotation[4] * inverse) },
		translation = interpolate(first.translation, second.translation, weight),
	}
end

-- ROBLOX: Result<(), PoseBufferError> -> rt.raise({ kind = ... }).
function pose_blend.blend(first: { Sqt }, second: { Sqt }, weight: number, output: { Sqt })
	if #first ~= #second then
		rt.raise({ kind = "ShortInput" })
	end
	if #output < #first then
		rt.raise({ kind = "ShortOutput" })
	end
	for i = 1, #first do
		output[i] = pose_blend.blend_sample(first[i], second[i], weight)
	end
end

-- ACSChannelBlend 828CC91C..CA64 selects the first subtree's translation.W
-- when requested, otherwise the second's, and clamps the weighted coefficient.
function pose_blend.channel_blend_sample(first: Sqt, second: Sqt, weight: number, use_first_weights: boolean): Sqt
	local channel = if use_first_weights then first.translation[4] else second.translation[4]
	local coefficient = f32(weight * channel)
	coefficient = if coefficient > 1.0 then 1.0 else coefficient
	coefficient = if 0.0 > coefficient then 0.0 else coefficient
	return pose_blend.blend_sample(first, second, coefficient)
end

-- ACS 828CBF68..828CC0B4: weighted SQT accumulation in authored order,
-- then one quaternion normalization. This is distinct from repeated two-pose
-- shortest-arc blending; the native multi-pose path does not flip hemispheres.
function pose_blend.weighted(poses: { { Sqt } }, weights: { number }): { Sqt }
	local first = poses[1]
	if first == nil then
		rt.raise({ kind = "ShortInput" })
	end
	if #poses ~= #weights then
		rt.raise({ kind = "ShortInput" })
	end
	for _, p in poses do
		if #p ~= #first then
			rt.raise({ kind = "ShortInput" })
		end
	end
	for _, w in weights do
		if not rt.is_finite(w) then
			rt.raise({ kind = "NonFiniteWeight" })
		end
	end
	local w0 = weights[1]
	local output = {}
	for i, s in first do
		local o = { scale = {}, rotation = {}, translation = {} }
		for lane = 1, 4 do
			o.scale[lane] = f32(s.scale[lane] * w0)
			o.rotation[lane] = f32(s.rotation[lane] * w0)
			o.translation[lane] = f32(s.translation[lane] * w0)
		end
		output[i] = o
	end
	for k = 2, #poses do
		local weight = weights[k]
		for i, s in poses[k] do
			local o = output[i]
			for lane = 1, 4 do
				o.scale[lane] = mul_add(s.scale[lane], weight, o.scale[lane])
				o.rotation[lane] = mul_add(s.rotation[lane], weight, o.rotation[lane])
				o.translation[lane] = mul_add(s.translation[lane], weight, o.translation[lane])
			end
		end
	end
	for _, o in output do
		local squared = native_arithmetic.dot4(o.rotation, o.rotation)
		if not rt.is_finite(squared) or squared <= 0.0 then
			rt.raise({ kind = "InvalidQuaternion" })
		end
		local inverse = native_arithmetic.reciprocal_square_root_estimate(squared)
		for _ = 1, 2 do
			inverse = mul_add(f32(inverse * 0.5), mul_add(-squared, f32(inverse * inverse), 1.0), inverse)
		end
		for lane = 1, 4 do
			o.rotation[lane] = f32(o.rotation[lane] * inverse)
			if not rt.is_finite(o.rotation[lane]) then
				rt.raise({ kind = "InvalidQuaternion" })
			end
		end
	end
	return output
end

return pose_blend
