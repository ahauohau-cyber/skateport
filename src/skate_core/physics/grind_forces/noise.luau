--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_forces/noise.rs (коммит 2e16697)
--
-- Original orientation noise82D40580 / S2 AddNoiseToOrientation82D8FE78.
-- No replacement RNG: caller supplies the three consecutive board-stream u32
-- draws, even for zero amount/speed. S3 hardcodes S2's full-speed/scalar tunables.

local rt = require("../../../rt")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add

type V = { number }

local noise = {}

function noise.angles(speed: number, amount: number, samples: { number }): { number }
	local speed_factor = rt.fmin(f32(speed * 0.5), 1.0)
	local amplitude = f32(f32(speed_factor * amount) * f32(0.06))
	local width = f32(amplitude * 2.0)
	local out = {}
	for i = 1, 3 do
		local unit = f32(f32(samples[i] % 100000) * f32(0.00001))
		out[i] = mul_add(unit, width, -amplitude)
	end
	return out
end

function noise.apply(frame: { V }, speed: number, amount: number, samples: { number }): { V }
	local a = noise.angles(speed, amount, samples)
	local sx, cx = trigonometry.sin_cos(a[1])
	local sy, cy = trigonometry.sin_cos(a[2])
	local sz, cz = trigonometry.sin_cos(a[3])
	-- Raw standard-VMX words82D407F0=10CC526E and82D407F4=118C4AAE
	-- disambiguate IDA's misleading printed multiply/add operand order.
	local sx_cz = f32(sx * cz)
	local cx_sz = f32(cx * sz)
	local cx_cz = f32(cx * cz)
	local sx_sz = f32(sx * sz)
	local columns = {
		{ f32(cy * cz), f32(cy * sz), -sy },
		{ f32(f32(sy * sx_cz) - cx_sz), mul_add(sy, sx_sz, cx_cz), f32(cy * sx) },
		{ mul_add(sy, cx_cz, sx_sz), f32(f32(sy * cx_sz) - sx_cz), f32(cy * cx) },
	}
	local result = table.clone(frame)
	for column = 1, 3 do
		local v = columns[column]
		local c = {}
		for lane = 1, 4 do
			c[lane] = mul_add(v[3], frame[3][lane], mul_add(v[2], frame[2][lane], f32(v[1] * frame[1][lane])))
		end
		result[column] = c
	end
	-- 82D407EC/40810/40828 multiply the three basis vectors by zero
	-- and add the original translation. No positional jitter is introduced.
	return result
end

return noise
