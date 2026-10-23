--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout/ground.rs (коммит 2e16697)
--
-- Complete original Ground checks82D8F9E0 and all its nonexternal leaves.

local rt = require("../../../rt")
local native_arithmetic = require("../../physics/native_arithmetic")
local trigonometry = require("../../trigonometry")
local data = require("./data")
local requests = require("./requests")
local common = require("./common")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3
local vector_min, vector_max = native_arithmetic.vector_min, native_arithmetic.vector_max
local Requests = requests.Requests
local request = Requests.request

local ground = {}

local function bit(n: number): number
	return bit32.lshift(1, n)
end

function ground.check(state: requests.Requests, s: data.Settings, mode: data.Mode, f: data.Frame)
	Requests.enter_ground(state)
	if state.cooldown > 0.0 then
		state.cooldown = f32(state.cooldown - f.timestep)
		return
	end
	local g = s.ground
	local vehicle = if f.group_8 then g.vehicle_scalar else 1.0
	local trick = if bit32.btest(f.flags_2472, bit(15)) then from_bits(0x3e99_999a) else 1.0
	local skitch = if bit32.btest(f.flags_2476, 8) then g.skitch_scalar else 1.0
	local arms = if bit32.btest(f.flags_2476, 8) then g.skitch_arms_scalar else 1.0
	local skater = if not bit32.btest(f.flags_2472, bit(28)) and f.maximum_skater_force > 0.0 then g.skater_scalar else 1.0
	local scale = f32(f32(f32(vehicle * trick) * skitch) * skater)
	local squash = if bit32.btest(f.flags_2476, bit(30)) then g.max_squash_coffin else g.max_squash
	local displacement = f32(g.max_displacement * scale)
	if (mode.check_squash or f.time_on_ground > from_bits(0x3d4c_cccd)) and f.maximum_pose_error > f32(vehicle * squash) then
		request(state, 18, 0.0)
	elseif dot3(f.pose_error, f.pose_error) > f32(displacement * displacement) then
		request(state, 1, 0.0)
	elseif common.force(f, f32(g.max_contact * scale), f32(g.max_arm_contact * arms)) then
		request(state, 0, 0.0)
	end
	common.vehicle(state, s, f)
	if not bit32.btest(f.flags_2484, bit(21)) then
		local cosine = vector_min(vector_min(dot3(f.deck[1], f.input_board[1]), dot3(f.deck[2], f.input_board[2])), dot3(f.deck[3], f.input_board[3]))
		if trigonometry.acos(vector_min(vector_max(cosine, -1.0), 1.0)) > g.max_deck_error then
			request(state, 3, 0.0)
		end
	end
	local xz, y
	if bit32.btest(f.flags_2472, bit(15)) then
		xz, y = s.air.xz_trick, s.air.y_trick
	else
		xz, y = mode.ground_xz, g.y_acceleration
		if bit32.btest(f.board_material_flags, bit(30)) then
			local scalar = if bit32.btest(f.flags_2472, bit(28)) then g.ai_scalar else g.player_scalar
			xz = f32(xz * scalar)
			y = f32(y * scalar)
		end
		if bit32.btest(f.board_material_flags, bit(29)) then
			xz = f32(xz * g.light_dmo_scalar)
		end
		if bit32.btest(f.flags_2476, 8) then
			xz = f32(xz * g.skitch_acc_scalar)
			y = f32(y * g.skitch_acc_scalar)
		end
		if bit32.btest(f.flags_2484, bit(21)) then
			xz = 0.0
			y = 0.0
		end
	end
	common.closing(state, f, xz, y)
	local skitch_gate = if bit32.btest(f.flags_2476, bit(23)) then 0.0 else 1.0
	local slide_gate = if bit32.btest(f.flags_2468, bit(5)) then 0.0 else 1.0
	local speed = f32(f32(g.balance_min_speed - f.speed) / g.balance_min_speed)
	local amount = f32(f32(speed * f32(1.0 - f.animation_up[2])) * slide_gate)
	local delta = mul_add(amount, skitch_gate, -g.balance_base)
	state.balance = if delta > 0.0 then f32(state.balance + delta) else 0.0
	if state.balance > g.balance_total then
		request(state, 11, 0.0)
	end
	if f.conflicting then
		request(state, 16, 0.0)
	end
	common.leaning(state, s, f)
end

-- GroundAnimation82D8F918. These additional checks run even when the shared
-- ground check returns during its cooldown. Caller82D34140 supplies scale1.
function ground.check_animation(state: requests.Requests, s: data.Settings, mode: data.Mode, f: data.Frame, scale: number)
	ground.check(state, s, mode, f)
	if common.force(f, s.air.max_contact, s.air.max_arm_contact) then
		request(state, 0, 0.0)
	end
	if f.opposing_contact > f32(s.ground.opposing_contact * scale) then
		request(state, 20, 0.0)
	end
end

-- 82D8FDC0, FootPlant postphysics checks. HandPlant calls check_air(false).
function ground.check_plant(state: requests.Requests, s: data.Settings, f: data.Frame)
	state.mode = 3
	if f.maximum_pose_error > s.ground.max_squash then
		request(state, 18, 0.0)
	elseif common.length(f.pose_error) > s.air.max_displacement then
		request(state, 1, 0.0)
	elseif common.force(f, s.air.max_contact, s.air.max_arm_contact) then
		request(state, 0, 0.0)
	end
	common.closing(state, f, s.air.xz_trick, s.air.y_trick)
end

return ground
