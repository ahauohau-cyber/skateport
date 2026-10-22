--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/feature.rs (коммит 2e16697)

local rt = require("../../../rt")
local reciprocal_sqrt = require("../reciprocal_sqrt")
local arithmetic = require("./arithmetic")
local prism_math = require("./prism_math")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local estimate = reciprocal_sqrt.estimate

local feature = {}

-- fn load(words: &[u32], offset: usize) -> [f32; 4]
local function load(words: { number }, offset: number): { number }
	return {
		from_bits(words[offset + 1]),
		from_bits(words[offset + 2]),
		from_bits(words[offset + 3]),
		from_bits(words[offset + 4]),
	}
end

-- Complete 82AC6E50 segment initialization. Writes origin, normalized direction
-- and broadcast length; preserves the unwritten plane vector at words8..12.
-- pub fn initialize_feature_segment(output: &mut [u32; 16], origin: [u32; 4], end: [u32; 4])
function feature.initialize_feature_segment(output: { number }, origin_bits: { number }, end_bits: { number })
	rt.copy_into(output, 0, origin_bits)
	local origin = { from_bits(origin_bits[1]), from_bits(origin_bits[2]), from_bits(origin_bits[3]), from_bits(origin_bits[4]) }
	local finish = { from_bits(end_bits[1]), from_bits(end_bits[2]), from_bits(end_bits[3]), from_bits(end_bits[4]) }
	local delta = {
		f32(finish[1] - origin[1]),
		f32(finish[2] - origin[2]),
		f32(finish[3] - origin[3]),
		f32(finish[4] - origin[4]),
	}
	local squared = arithmetic.dot({ delta[1], delta[2], delta[3] }, { delta[1], delta[2], delta[3] })
	-- One rsqrt refinement, then one reciprocal refinement. Runtime initializer
	-- 82F837D8 broadcasts 8212BF78 (34000000) to threshold vector830BDD40.
	local reciprocal = estimate(squared)
	reciprocal = mul_add(f32(reciprocal * 0.5), mul_add(-squared, f32(reciprocal * reciprocal), 1.0), reciprocal)
	local length
	if squared > from_bits(0x3400_0000) then
		length = if squared == 0.0 then 0.0 else f32(squared * reciprocal)
	else
		length = 0.0
	end
	rt.fill(output, 12, 16, to_bits(length))
	local r = prism_math.reciprocal_estimate(length)
	r = mul_add(r, mul_add(-r, length, 1.0), r)
	local direction
	if squared > from_bits(0x3400_0000) then
		direction = { f32(delta[1] * r), f32(delta[2] * r), f32(delta[3] * r), f32(delta[4] * r) }
	else
		direction = { 0.0, 0.0, 0.0, 0.0 }
	end
	rt.copy_into(output, 4, { to_bits(direction[1]), to_bits(direction[2]), to_bits(direction[3]), to_bits(direction[4]) })
end

-- Complete capsule maximum-feature callback82AD98A0. `segment_scratch` carries
-- the native local64-byte segment, including its unwritten plane vector.
-- No fabricated value is assigned to those copied scratch words. Native r4
-- mode is unused by this capsule callback.
-- pub fn capsule_maximum_feature(gp: &[u32; 48], direction: [u32; 4], output: &mut MaximumFeature, segment_scratch: &mut [u32; 16])
function feature.capsule_maximum_feature(
	gp: { number },
	direction: { number },
	output: { number },
	segment_scratch: { number }
)
	local axis = load(gp, 16)
	local normal = { from_bits(direction[1]), from_bits(direction[2]), from_bits(direction[3]), from_bits(direction[4]) }
	local projection = arithmetic.dot({ axis[1], axis[2], axis[3] }, { normal[1], normal[2], normal[3] })
	local half = from_bits(gp[29])
	local center = load(gp, 0)
	if math.abs(projection) < from_bits(0x3d4c_cccd) then
		local scaled = { f32(axis[1] * half), f32(axis[2] * half), f32(axis[3] * half), f32(axis[4] * half) }
		local plus, minus = {}, {}
		for i = 1, 4 do
			plus[i] = to_bits(f32(center[i] + scaled[i]))
			minus[i] = to_bits(f32(center[i] - scaled[i]))
		end
		feature.initialize_feature_segment(segment_scratch, plus, minus)
		rt.copy_into(output, 4, segment_scratch)
		output[141] = 1
	else
		local point = {}
		for i = 1, 4 do
			if projection > 0.0 then
				point[i] = mul_add(axis[i], half, center[i])
			else
				point[i] = f32(center[i] - f32(axis[i] * half))
			end
		end
		rt.copy_into(output, 136, { to_bits(point[1]), to_bits(point[2]), to_bits(point[3]), to_bits(point[4]) })
		output[141] = 0
	end
	output[1] = 0
end

return feature
