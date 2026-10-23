--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/offboard_intentions.rs (коммит 2e16697)
--
-- Off-board inputs from original TU3 Fill 825999F0 and helper 8259C260.
-- The stock ActionGraph owns activation; these inputs do not change state.

local rt = require("../../rt")
local controller = require("./controller")
local reciprocal_sqrt = require("../physics/reciprocal_sqrt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local offboard_intentions = {}

export type OffboardIntent = { name: string, value: number }

local K_3cf5c28f = from_bits(0x3cf5c28f)
local K_3f666666 = from_bits(0x3f666666)
local K_358637bd = from_bits(0x358637bd)

-- Read the already-updated controller prefix exactly once per input tick.
-- `air_reckoning_active` is actual PhysOut bundle+8 byte452, not a state test.
-- Analog movement has a separate physical-output-dependent producer.
function offboard_intentions.produce_discrete(ctrl: controller.DerivedControllerInput, actor_flags: number, air_reckoning_active: boolean): { OffboardIntent }
	local words = ctrl.words
	local previous = words[7]
	local current = words[14]
	local function axis(slot: number): number
		return from_bits(words[slot + 1])
	end
	local function held(b: number): boolean
		return bit32.band(current, bit32.lshift(1, b)) ~= 0
	end
	local function rising(b: number): boolean
		return held(b) and bit32.band(previous, bit32.lshift(1, b)) == 0
	end
	local output: { OffboardIntent } = {}
	local function emit(name: string, value: number)
		table.insert(output, { name = name, value = value })
	end

	-- 8259AA8C invokes 8259C260 before the later toggle/sprint publications.
	if rising(23) then
		emit("OB_Jump", 1.0)
	end
	local right_x = axis(9)
	local right_y = axis(10)
	if right_x ~= 0.0 then
		emit("OB_LookAtX", right_x)
	end
	if right_y ~= 0.0 then
		emit("OB_LookAtY", right_y)
	end
	local drop_board = axis(4) ~= 1.0 and axis(11) == 1.0
	local throw_board = axis(5) ~= 1.0 and axis(12) == 1.0
	if drop_board then
		emit("OB_DropBoard", 1.0)
	end
	if throw_board then
		emit("OB_ThrowBoard", 1.0)
	end
	if drop_board or throw_board then
		emit("OB_RetrieveBoard", 1.0)
	end
	if held(28) or held(30) then
		emit("OB_DoAirBodyTweak", 1.0)
	end
	emit("OB_AirBodyTweakX", right_x)
	emit("OB_AirBodyTweakY", right_y)

	-- 8259A604..A6C0 computes both; 8259AF80 gates only NewToggle by actor bit10.
	-- The listener has no biped/category gate. Stock OffBoard AG maps these
	-- same toggle intentions to OB_Mount/OB_MountRaw; trigger edges recall.
	if not air_reckoning_active and not held(29) and held(22) then
		-- Native bge does not take the branch for unordered timer values.
		if (rising(22) or not (axis(23) >= K_3cf5c28f)) and bit32.band(actor_flags, bit32.lshift(1, 10)) == 0 then
			emit("NewToggleOffBoardState", 1.0)
		end
		emit("ToggleOffBoardState", 1.0)
	end
	if not (axis(21) > 0.0) and axis(20) > 0.0 then
		emit("OB_Sprint", 1.0)
	end
	return output
end

-- Completed physical publication read by Fill 825999F0.
export type AnalogObservation = {
	-- PhysOutSkeleton+0: effective animation root Z, including processed 2476 bit2.
	effective_skeleton_z: { number },
	-- Some(OffBoard 288) iff actual OffBoard 333 is nonzero. This vector is not
	-- normalized here. A missing Biped producer must not be converted to None.
	biped_correction: { number }?,
}

local function dot(a: { number }, b: { number }): number
	return f32(f32(f32(a[1] * b[1]) + f32(a[2] * b[2])) + f32(a[3] * b[3]))
end

local function safe_unit(vector: { number }): { number }
	local squared = dot(vector, vector)
	local inverse = reciprocal_sqrt.estimate(squared)
	for _ = 1, 2 do
		local correction = mul_add(-squared, f32(inverse * inverse), 1.0)
		inverse = mul_add(f32(inverse * 0.5), correction, inverse)
	end
	local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
	-- Initializer 82F826F8 supplies 830BD350 from 82181A88: LENGTH threshold 1e-6.
	if length > K_358637bd then
		return { f32(vector[1] * inverse), f32(vector[2] * inverse), f32(vector[3] * inverse), f32(vector[4] * inverse) }
	end
	return { 0.0, 0.0, 0.0, 0.0 }
end

-- 8259A7A8..A9BC calculation and 8259AFFC..B088 ordered movement publications.
function offboard_intentions.produce_analog(ctrl: controller.DerivedControllerInput, observation: AnalogObservation): { OffboardIntent }
	local words = ctrl.words
	local stick = { from_bits(words[8]), 0.0, from_bits(words[9]), 0.0 }
	local horizontal = table.clone(observation.effective_skeleton_z)
	horizontal[2] = 0.0
	local forward = safe_unit(horizontal)
	local magnitude
	local normal = observation.biped_correction
	if normal ~= nil then
		-- ROBLOX: XOR знакового бита -> унарный минус (то же для f32).
		local negative = { -normal[1], -normal[2], -normal[3], -normal[4] }
		local projection = dot(stick, negative)
		local lower = if -projection >= 0.0 then 0.0 else projection
		local coefficient = if f32(1.0 - lower) >= 0.0 then lower else 1.0
		-- 8259A994 ble takes only ordered <=. Unordered follows the zero branch.
		if not (dot(safe_unit(stick), negative) <= K_3f666666) then
			magnitude = 0.0
		else
			local corrected = {}
			for i = 1, 4 do
				corrected[i] = mul_add(normal[i], coefficient, stick[i])
			end
			magnitude = dot(forward, corrected)
		end
	else
		magnitude = dot(forward, stick)
	end
	return {
		{ name = "OB_Mag", value = magnitude },
		{ name = "OB_BipedWorldZ", value = stick[3] },
		{ name = "OB_BipedWorldX", value = stick[1] },
		{ name = "OB_BipedStickMag", value = controller.magnitude(dot(stick, stick)) },
	}
end

return offboard_intentions
