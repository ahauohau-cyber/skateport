--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout/common.rs (коммит 2e16697)

local rt = require("../../../rt")
local board_motion_output = require("../../physics/board_motion_output")
local native_arithmetic = require("../../physics/native_arithmetic")
local data = require("./data")
local requests = require("./requests")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3
local request = requests.Requests.request

local common = {}

function common.length(v: { number }): number
	local sq = dot3(v, v)
	local inv = board_motion_output.inverse_length_squared(sq, 2)
	if sq == 0.0 then
		return 0.0
	end
	return f32(sq * inv)
end
local function selected_max(a: number, b: number): number
	if f32(a - b) >= 0.0 then
		return a
	end
	return b
end
-- 82BD88A0 reads unweighted regional forces in this exact pair order.
function common.force(frame: data.Frame, body: number, arms: number): boolean
	local f = frame.regions_force
	local a = selected_max(f[1], f[2])
	local b = selected_max(f[6], f[5])
	local c = selected_max(f[8], f[7])
	return selected_max(selected_max(a, b), c) > body or selected_max(f[3], f[4]) > arms
end
function common.vehicle(state: requests.Requests, s: data.Settings, f: data.Frame)
	local limit = if bit32.btest(f.flags_2476, 8) then s.ground.skitch_contact else s.ground.vehicle_contact
	if f.vehicle_force > limit then
		request(state, 7, 0.0)
	end
end
-- 82D90AB8 rotates closing velocity656 by the actual WorldToAnim basis.
function common.closing(state: requests.Requests, f: data.Frame, xz: number, y: number)
	if not f.board_contact then
		return
	end
	local v = f.closing_velocity
	local m = f.world_to_animation
	local loc = {}
	for i = 1, 4 do
		loc[i] = mul_add(m[3][i], v[3], mul_add(m[2][i], v[2], f32(m[1][i] * v[1])))
	end
	if common.length({ loc[1], 0.0, loc[3], loc[4] }) > xz or math.abs(loc[2]) > y then
		request(state, 2, 0.0)
		if common.force(f, 1.0, 20.0) then
			request(state, 0, 0.0)
		end
	end
end
function common.leaning(state: requests.Requests, s: data.Settings, f: data.Frame)
	if f.animation_up[2] < s.lean_contact_y and f.compliant and f.highest_normal[2] > from_bits(0x3f34_fdf4) then
		request(state, 19, 0.0)
	end
end

return common
