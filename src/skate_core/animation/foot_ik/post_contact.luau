--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/post_contact.rs (коммит 2e16697)
--
-- SkeletonIK::CheckFootAgainstBoard82BF0D70, including raised deck ends.

local rt = require("../../../rt")
local m = require("./math")
local settings_mod = require("./settings")
local transforms = require("./transforms")
local native_arithmetic = require("../../physics/native_arithmetic")
local sar = require("../../physics/skeleton_animation_record")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local reciprocal = m.reciprocal
local inverse_rigid = transforms.inverse_rigid
local vector_min = native_arithmetic.vector_min
local transform_point = sar.transform_point

type Transform = sar.AnimationPartTransform
type F4 = { number }

local post_contact = {}

export type SettingsPost = {
	--physics_animation/default layout780.
	minimum_board_up: number,
	--Global212's authored layout412/416, selected by the wipeout argument.
	wipeout_height: number,
	riding_height: number,
}

-- ///Scalar constructor path through original8252D980. Its argument is already
-- ///clamped to [.01,1.5607964]; coefficients come from822FE3C0..E0.
function post_contact.tangent(angle: number): number
	local quadrant = rt.round_ties_even(f32(angle * from_bits(0x3F22_F983)))
	local reduced = mul_add(-quadrant, from_bits(0x3FC9_0FDB), angle)
	reduced = mul_add(-quadrant, from_bits(0x2E85_A309), reduced)
	local squared = f32(reduced * reduced)
	local denominator = mul_add(squared, from_bits(0x3505_BBA8), from_bits(0xB9A3_7B25))
	denominator = mul_add(squared, denominator, from_bits(0x3CD2_3CF5))
	denominator = mul_add(squared, denominator, from_bits(0xBEEE_F582))
	denominator = mul_add(squared, denominator, 1.0)
	local numerator = mul_add(squared, from_bits(0xB795_D5B9), from_bits(0x3B60_7415))
	numerator = mul_add(squared, numerator, from_bits(0xBE08_95AF))
	numerator = mul_add(reduced, f32(squared * numerator), reduced)
	--vcmpbfp's two high result bits select corresponding sign/exponent bits.
	--The bounded constructor argument preserves these bits in both operands;
	--retain the actual bit-select rather than replacing it by a boolean branch.
	local bound = from_bits(0x3980_0000)
	local mask = bit32.bor(if reduced > bound then 0x8000_0000 else 0, if reduced < -bound then 0x4000_0000 else 0)
	denominator = from_bits(bit32.bor(bit32.band(to_bits(denominator), bit32.bnot(mask)), bit32.band(to_bits(1.0), mask)))
	numerator = from_bits(bit32.bor(bit32.band(to_bits(numerator), bit32.bnot(mask)), bit32.band(to_bits(reduced), mask)))
	-- ROBLOX: `quadrant.abs() as i32 & 1`.
	if bit32.band(rt.to_i32(math.abs(quadrant)), 1) == 0 then
		return f32(numerator * reciprocal(denominator, 2))
	end
	return f32(denominator * reciprocal(-numerator, 2))
end
local tangent = post_contact.tangent

-- ROBLOX: Option<[f32; 4]> -> таблица или nil.
function post_contact.target(board: Transform, foot: F4, adjacent: F4, animated_board_position: F4, wipeout: boolean, settings: settings_mod.Settings, post: SettingsPost): F4?
	local inverse = inverse_rigid(board)
	local local_foot = transform_point(inverse, foot)
	local local_adjacent = transform_point(inverse, adjacent)
	local midpoint = {}
	for i = 1, 4 do
		midpoint[i] = f32(f32(local_foot[i] + local_adjacent[i]) * 0.5)
	end
	--vrlimi mask4 preserves the foot's Y; X/Z test both foot and midpoint.
	midpoint[2] = local_foot[2]
	local x = vector_min(math.abs(local_foot[1]), math.abs(midpoint[1]))
	local z = vector_min(math.abs(local_foot[3]), math.abs(midpoint[3]))
	if x >= f32(settings.deck_half_width + settings.post_ik_padding[1]) or z >= f32(settings.deck_total_half_length + settings.post_ik_padding[3]) then
		return nil
	end
	local height = if wipeout then post.wipeout_height else post.riding_height
	if z > settings.deck_half_length then
		local distance = f32(z - settings.deck_half_length)
		local end_ = f32(settings.deck_total_half_length - settings.deck_half_length)
		distance = if f32(end_ - distance) >= 0.0 then distance else end_
		--Constructor82BED418 caches tan(clamp(authored degrees*.01745...)).
		local angle = f32(settings.deck_front_angle_degrees * from_bits(0x3C8E_FA35))
		angle = if f32(f32(0.01) - angle) >= 0.0 then f32(0.01) else angle
		local maximum = from_bits(0x3FC7_C82D)
		angle = if f32(maximum - angle) >= 0.0 then angle else maximum
		height = mul_add(distance, tangent(angle), height)
	end
	if midpoint[2] >= height or midpoint[2] <= f32(height - from_bits(0x3E99_999A)) then
		return nil
	end
	local result = table.clone(animated_board_position)
	result[2] = height
	return transform_point(board, result)
end

return post_contact
