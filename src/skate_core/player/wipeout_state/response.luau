--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/response.rs (коммит 2e16697)
--
-- Original Wipeout response82D3E678 and retained-velocity82D3E348/82D3E8C0.
-- ROBLOX: Option<V> -> V или nil.

local rt = require("../../../rt")
local m = require("./math")
local data = require("./data")
local body = require("./body")
local drives = require("./drives")
local recovery = require("./recovery")

local f32 = rt.f32
local from_bits = rt.from_bits

type V = m.V

local response = {}

-- 82D3C2B0: only upward collision/prediction normals are accepted.
function response.response_normal(support: V?, prediction: V?): V
	if support ~= nil and support[2] > 0.0 then
		return support
	end
	if prediction ~= nil and prediction[2] > 0.0 then
		return prediction
	end
	return { 0.0, 1.0, 0.0, 0.0 }
end

function response.trigger(state: data.State, b: any, normal: V, input: { number })
	state.response_frames = 0
	state.response_start_speed = m.length(state.velocity)
	local strength = recovery.response_strength(state)
	if f32(state.maximum_speed * f32(0.1)) < 1.0 then
		state.response_count = rt.wrapping_add_u32(state.response_count, 1)
	else
		state.response_count = 0
	end
	state.maximum_speed = 0.0
	state.extra_weight = 0.0
	state.response_scalar = 0.0
	if strength == 0.0 then
		return
	end
	state.response_time = 0.0
	strength = if f32(strength - 1.0) >= 0.0 then 1.0 else strength
	state.response_scalar = strength
	state.extra_weight = strength
	local control = { input[1], 0.0, input[2], 0.0 }
	local projection = m.dot(normal, control)
	if projection < 0.0 then
		control = m.sub(control, m.scale(normal, projection))
	end
	-- 82D3E868: raw vmadd A=normal,C=zero,B=control*1.25.
	local velocity = m.scale(m.madd(normal, 0.0, m.scale(control, 1.25)), strength)
	body.add_velocity(b, velocity)
end

function response.update_counter(state: data.State, contact: boolean)
	state.response_finished = false
	if state.response_frames < 0 then
		return
	end
	state.response_frames = rt.to_i32(state.response_frames + 1)
	if state.response_frames == 3 then
		local factor = if state.response_start_speed < 1.0 then f32(1.0 - state.response_start_speed) else f32(state.response_start_speed * f32(0.2))
		state.response_change = f32(f32(m.length(state.velocity) - state.response_start_speed) * f32(factor + 1.0))
	end
	if state.response_frames == 8 then
		state.response_frames = -1
		state.response_finished = true
		if not contact then
			state.response_change = f32(math.abs(state.response_change) * 2.0)
		end
		state.response_change = m.clamp(f32(f32(state.response_change - f32(0.1)) * f32(0.2)), 0.0, 1.0)
	end
end

local function release(state: data.State, b: any, targets: any, settings: drives.Settings)
	if not state.retained_velocity_active then
		return
	end
	drives.set_linear_root(targets, settings, 0.0)
	body.set_velocity(b, state.retained_velocity)
	state.retained_velocity_active = false
	state.velocity = { 0.0, 0.0, 0.0, 0.0 }
end

function response.retained_velocity(state: data.State, b: any, targets: any, settings: drives.Settings, contact: boolean, flags2468: number, com_velocity: V)
	local requested = bit32.btest(flags2468, 8)
	if state.retained_velocity_active or requested then
		if contact then
			state.allow_retained_velocity = false
			release(state, b, targets, settings)
		elseif not requested then
			release(state, b, targets, settings)
		elseif not state.retained_velocity_active and state.allow_retained_velocity and com_velocity[2] < 2.0 then
			drives.set_linear_root(targets, settings, 1.0)
			state.retained_velocity_active = true
			state.retained_velocity = state.velocity
		end
	end
	if state.retained_velocity_active then
		state.velocity = state.retained_velocity
		state.time = f32(state.time - from_bits(0x3C88_8889))
	end
end

return response
