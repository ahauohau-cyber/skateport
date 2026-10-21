--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/tests/native_arithmetic.rs (коммит 2e16697)

local harness = require("../../harness")
local native = require("../../../src/skate_core/physics/native_arithmetic")
local reciprocal_sqrt = require("../../../src/skate_core/physics/reciprocal_sqrt")

return function(report: harness.Report)
	harness.test(report, "native_arithmetic: host_math_normalizes_a_direction_without_using_its_homogeneous_lane", function()
		local direction = { 3.0, 4.0, 0.0, 100.0 }
		local inverse_length = native.reciprocal_square_root_estimate(native.dot3(direction, direction))
		-- ROBLOX: direction.map(|v| v * inverse_length)
		local unit = {}
		for i, v in direction do
			unit[i] = v * inverse_length
		end
		harness.check(math.abs(native.dot3(unit, unit) - 1.0) < 1.0e-6, "unit length")
		harness.eq(native.dot3(direction, { 4.0, -3.0, 0.0, 50.0 }), 0.0, "orthogonal dot3")
		harness.eq(native.dot4(direction, { 0.0, 0.0, 0.0, 1.0 }), 100.0, "dot4 w lane")
	end)

	harness.test(report, "native_arithmetic: host_math_handles_scalar_geometry_and_ordinary_float_boundaries", function()
		harness.eq(native.reciprocal_estimate(4.0), 0.25)
		harness.eq(native.reciprocal_square_root_estimate(16.0), 0.25)
		harness.eq(native.reciprocal_estimate(-0.0), -math.huge)
		harness.eq(native.reciprocal_square_root_estimate(math.huge), 0.0)
		local nan = native.reciprocal_square_root_estimate(-1.0)
		harness.check(nan ~= nan, "rsqrt(-1) is NaN")
		harness.eq(native.vector_min(-2.0, 3.0), -2.0)
		harness.eq(native.vector_max(-2.0, 3.0), 3.0)
	end)

	-- ROBLOX: дополнительно — правила Rust для NaN в min/max (у Rust это поведение f32::min/max).
	harness.test(report, "native_arithmetic: vector_min/max ignore a NaN operand like f32::min/max", function()
		local nan = 0 / 0
		harness.eq(native.vector_min(nan, 1.5), 1.5)
		harness.eq(native.vector_min(1.5, nan), 1.5)
		harness.eq(native.vector_max(nan, -1.5), -1.5)
		harness.eq(native.vector_max(-1.5, nan), -1.5)
	end)

	harness.test(report, "reciprocal_sqrt: estimate forwards to native rsqrt", function()
		harness.eq(reciprocal_sqrt.estimate(16.0), 0.25)
		harness.eq(reciprocal_sqrt.estimate(4.0), 0.5)
	end)
end
