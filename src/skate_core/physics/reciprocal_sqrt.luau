--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/reciprocal_sqrt.rs (коммит 2e16697)
--
-- Compatibility entry point for recovered callers that use `vrsqrtefp`.

local native_arithmetic = require("./native_arithmetic")

local reciprocal_sqrt = {}

-- pub(crate) fn estimate(value: f32) -> f32
function reciprocal_sqrt.estimate(value: number): number
	return native_arithmetic.reciprocal_square_root_estimate(value)
end

return reciprocal_sqrt
