--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/skeleton_input/attribute_finalization.rs (коммит 2e16697)
--
-- Special scalar handlers and unconditional suffix of 82BDA0D0.

local rt = require("../../../rt")
local scalar_attributes = require("./scalar_attributes")
local extended_attributes = require("./extended_attributes")

local f32 = rt.f32

local attribute_finalization = {}

export type JumpAttributeState = {
	-- Skeleton 16488/16492, cached by PrepareJump.
	prepared_controls: { number },
	-- Skeleton 16496/16511; this cache survives only the native suffix gate.
	height_override: number,
	height_override_active: boolean,
}

local JumpAttributeState = {}
attribute_finalization.JumpAttributeState = JumpAttributeState

-- Skeleton constructor 82BD7A54..82BD7A98, once per skeleton.
function JumpAttributeState.new(): JumpAttributeState
	return { prepared_controls = { 0.0, 0.0 }, height_override = 0.0, height_override_active = false }
end

export type FinalizationInput = {
	-- Selected global 292 layout 1872/1876/1880.
	select_jump_extremes: boolean,
	low_jump_threshold: number,
	high_jump_threshold: number,
	-- Selected state variant layout 76.
	allow_height_override: boolean,
	-- Selected global 208 layout 452.
	use_prepared_controls: boolean,
	-- Actual AnimOutPhysIn 10496 and 10932.
	external_impulse_active: boolean,
	animation_flags: number,
}

-- Function locals are reset on every ProcessAnimAttributes invocation.
export type Accumulator = { revert: boolean, revert_direction: number, minimum_jump: number, trick_height: number, has_trick_height: boolean }

local Accumulator = {}
attribute_finalization.Accumulator = Accumulator

function Accumulator.new(): Accumulator
	return { revert = false, revert_direction = 1.0, minimum_jump = 0.0, trick_height = 0.0, has_trick_height = false }
end

local function clamp_control(value: number): number
	local lower = if f32(-1.0 - value) >= 0.0 then -1.0 else value
	return if f32(1.0 - lower) >= 0.0 then lower else 1.0
end

-- ROBLOX: map: Option<&mut dyn ActionMap> -> ActionMap или nil.
function Accumulator.dispatch(self: Accumulator, name: string, scalar: () -> number, fields: scalar_attributes.ScalarAttributeInputs, cached: JumpAttributeState, map: any?): boolean
	if name == "Revert" then
		self.revert = true
	elseif name == "RevertDir" then
		self.revert_direction = scalar()
		fields.flags2472 = bit32.bor(fields.flags2472, 0x200000)
	elseif name == "MinJump" then
		self.minimum_jump = scalar()
	elseif name == "TrickHeight" then
		self.trick_height = scalar()
		self.has_trick_height = true
	elseif name == "PrepareJump" then
		fields.flags2468 = bit32.bor(fields.flags2468, 0x200000)
		if map ~= nil then
			-- 82590358/825903C8 call stock cInputMap 64 and 65.
			local x = clamp_control(map:value(64))
			cached.prepared_controls = { x, clamp_control(map:value(65)) }
		end
	elseif name == "JumpHeightOverride" then
		cached.height_override = scalar()
		cached.height_override_active = true
	else
		return false
	end
	return true
end

function Accumulator.finish(self: Accumulator, fields: scalar_attributes.ScalarAttributeInputs, extra: extended_attributes.ExtendedAttributes, cached: JumpAttributeState, input: FinalizationInput, map: any?)
	if self.revert then
		extra.revert_direction = self.revert_direction
	end
	if bit32.band(fields.flags2468, 0x400000) ~= 0 then
		if input.select_jump_extremes and self.trick_height <= input.low_jump_threshold then
			extra.jump_strength = self.minimum_jump
		elseif input.select_jump_extremes and self.trick_height >= input.high_jump_threshold then
			extra.jump_strength = 1.0
		else
			extra.jump_strength = self.trick_height
		end
	end
	if self.has_trick_height and input.allow_height_override then
		if cached.height_override_active then
			local difference = f32(cached.height_override - extra.jump_strength)
			if difference >= 0.0 then
				extra.jump_strength = cached.height_override
			end
		end
	else
		cached.height_override = 0.0
		cached.height_override_active = false
	end
	if bit32.band(extra.flags2480, 0x1000) ~= 0 then
		extra.jump_strength = self.trick_height
	end
	if input.use_prepared_controls then
		extra.jump_controls = table.clone(cached.prepared_controls)
	elseif map ~= nil then
		-- The suffix deliberately selects 68 through 8255E010, not 65 used
		-- by PrepareJump. Keep the recovered source's distinct routing.
		local x = clamp_control(map:value(64))
		extra.jump_controls = { x, clamp_control(map:value(68)) }
	end
	if input.external_impulse_active then
		fields.flags2468 = bit32.bor(fields.flags2468, 0x40000)
	end
	-- 82BDC650 reads a BYTE at 10932, the high byte of this big-endian
	-- word. The later publications read the complete word separately.
	local a = input.animation_flags
	extra.flags2480 = bit32.bor(bit32.band(extra.flags2480, bit32.bnot(8)), bit32.band(bit32.rshift(a, 24), 8))
	fields.flags2484 = bit32.bor(bit32.band(fields.flags2484, bit32.bnot(2)), bit32.band(bit32.rshift(a, 22), 2))
	fields.flags2484 = bit32.bor(bit32.band(fields.flags2484, 0x7fffffff), bit32.band(bit32.lshift(a, 6), 0x80000000))
	fields.flags2484 = bit32.bor(bit32.band(fields.flags2484, bit32.bnot(0x01000000)), bit32.band(bit32.rshift(a, 4), 0x01000000))
	if bit32.band(fields.flags2476, 0x600) ~= 0 then
		fields.flags2476 = bit32.band(fields.flags2476, bit32.bnot(0x400000))
	end
end

return attribute_finalization
