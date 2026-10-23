--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/pumping.rs (коммит 2e16697)
--
-- Pumping lifecycle, native geometry and CalcPumpForce82D933D0 publication.
-- Ground supplies the current stock mode and queues the resulting board force.
-- ROBLOX: init.luau — подмодули через @self, соседи через ./.

local rt = require("../../rt")
local vector_mod = require("./vector")

local f32 = rt.f32
local normalize = vector_mod.normalize

type F4 = { number }

local pumping = {
	controller = require("@self/controller"),
	geometry = require("@self/geometry"),
	settings = require("@self/settings"),
	state = require("@self/state"),
}

export type PumpForceInput = {
	flags_2476: number,
	mode_multiplier: number, -- selected-mode layout+8
	pumping_scalar: number, -- Pumping+48 argument f1
	input_scalar_2660: number,
	timestep: number, -- Processed+2604
	direction_432: F4,
	normal_threshold: F4,
}

function pumping.calculate(i: PumpForceInput): { number }
	local p = if bit32.band(i.flags_2476, 2) == 0 then f32(i.mode_multiplier * i.pumping_scalar) else i.pumping_scalar
	local scalar = f32(f32(i.input_scalar_2660 * p) / i.timestep)
	local direction = normalize(i.direction_432, i.normal_threshold)
	local result = table.create(8, 0.0)
	for n = 1, 4 do
		result[n] = f32(direction[n] * scalar)
	end
	return result
end

return pumping
