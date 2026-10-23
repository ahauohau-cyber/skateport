--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/grind_intentions.rs (коммит 2e16697)
--
-- Original S3 Fill 825999F0; emissions 8259ACF0..8259AD94.
-- Derived controller-space values: graph filters own stance/mirror transforms.

local rt = require("../../rt")
local controller = require("./controller")
local riding_intentions = require("./riding_intentions")

local f32 = rt.f32
local from_bits = rt.from_bits

local grind_intentions = {}

function grind_intentions.produce(ctrl: controller.DerivedControllerInput): { riding_intentions.RidingIntent }
	local words = ctrl.words
	local left_x = from_bits(words[8])
	local right_x = from_bits(words[10])
	local right_y = from_bits(words[11])
	-- S3 adds both X axes. S2 Fill 825FB4C8 uses right X alone: do not copy it.
	local sum = f32(left_x + right_x)
	local lower = if f32(-1.0 - sum) >= 0.0 then -1.0 else sum
	local translation = if f32(1.0 - lower) >= 0.0 then lower else 1.0
	local out: { riding_intentions.RidingIntent } = {}
	for _, pair in { { "GrindBalanceX", -left_x }, { "PhysGrindTranslation", translation }, { "PhysGrindStabilityNudge", left_x }, { "PhysGrindUpDown", right_y } } do
		local value = pair[2] :: number
		if value ~= 0.0 then
			table.insert(out, { name = pair[1] :: string, value = value })
		end
	end
	return out
end

return grind_intentions
