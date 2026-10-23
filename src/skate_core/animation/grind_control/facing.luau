--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/grind_control/facing.rs (коммит 2e16697)
--
-- CreateGrindAttributes 82BAF3C8..444: original VMX reduction.
-- Let P(x,y,z,w)=(y,z,x,w). The instructions compute
-- P(n*P(b)-P(n)*b), then read lane1: n.z*b.x-n.x*b.z.
-- Raw vnmsubfp word 1180636F has VA=0,VB=12,VC=13: VB-VA*VC.
-- No normalization, epsilon or grind-name classification occurs here.

local rt = require("../../../rt")

local facing = {}

-- n is Motion+80 deck velocity, b is Basic+128 effective board forward.
-- ground_flag is the historical API name for Motion 273 (processed bit20);
-- mirrored is LIVE ISkaterAnim virtual28. Ground 80 is a different vector.
function facing.backwards(n: { number }, b: { number }, ground_flag: boolean, mirrored: boolean): boolean
	local side = rt.mul_add(-n[1], b[3], rt.f32(n[3] * b[1]))
	-- Native fcmpu/ble falls through on unordered as well as strictly positive.
	local positive_or_unordered = not (side <= 0.0)
	return (positive_or_unordered ~= ground_flag) ~= mirrored
end

return facing
