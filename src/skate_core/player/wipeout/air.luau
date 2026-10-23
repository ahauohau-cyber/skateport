--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout/air.rs (коммит 2e16697)
--
-- Complete Air checks82D90358 including bad landing82D90D08.

local rt = require("../../../rt")
local native_arithmetic = require("../../physics/native_arithmetic")
local point_graph = require("../../point_graph")
local data = require("./data")
local requests = require("./requests")
local common = require("./common")

local f32 = rt.f32
local mul_add = rt.mul_add
local dot3 = native_arithmetic.dot3
local request = requests.Requests.request

local air = {}

-- 82D8FEE8, shared off-board air collision check; no on-board cooldown/landing tests.
function air.check_collision(state: requests.Requests, s: data.Settings, mode: data.Mode, f: data.Frame)
	if mode.check_squash and f.maximum_pose_error > s.air.max_squash then
		request(state, 18, 0.0)
	elseif dot3(f.pose_error, f.pose_error) > f32(s.air.max_displacement * s.air.max_displacement) then
		request(state, 1, 0.0)
	elseif common.force(f, s.air.max_contact, s.air.max_arm_contact) then
		request(state, 0, 0.0)
	end
end

local function bad_landing(state: requests.Requests, s: data.Settings, mode: data.Mode, f: data.Frame, use_com: boolean)
	if not mode.check_bad_landing or not f.board_contact then
		return
	end
	local velocity = if use_com then f.com_velocity else f.deck_velocity
	local normal = f.board_contact_normal
	if f.grind_selected then
		if f.grind_normal_valid then
			normal = f.grind_normal
		end
		if -dot3(normal, velocity) > f32(s.air.max_grind_speed * mode.bad_landing_scale) then
			request(state, 8, 0.0)
		end
	else
		local into = -dot3(normal, velocity)
		local tangent = {}
		for i = 1, 4 do
			tangent[i] = mul_add(normal[i], into, velocity[i])
		end
		local limit = f32(point_graph.PointGraph.evaluate(s.air.max_landing_angle, common.length(tangent)) * mode.bad_landing_scale)
		if math.abs(f.landing_angle) > limit then
			request(state, 5, 0.0)
		end
		local speed_limit = if bit32.btest(f.board_material_flags, bit32.lshift(1, 31)) then s.air.max_stairs_speed else s.air.max_landing_speed
		if into > f32(speed_limit * mode.bad_landing_scale) then
			request(state, 6, into)
		end
	end
end

function air.check(state: requests.Requests, s: data.Settings, mode: data.Mode, f: data.Frame, use_com: boolean)
	if state.mode ~= 2 then
		state.mode = 2
		state.contact_frames = 0
	end
	if f.board_contact then
		state.contact_frames = 4
	end
	if state.contact_frames > 0 then
		state.contact_frames -= 1
	end
	if state.cooldown > 0.0 then
		state.cooldown = f32(state.cooldown - f.timestep)
		return
	end
	common.vehicle(state, s, f)
	local a = s.air
	local body_flip = bit32.btest(f.flags_2476, bit32.lshift(1, 26))
	local scalar = if body_flip then a.body_flip_scalar else 1.0
	local deck_scalar = if body_flip then a.body_flip_acc_scalar else 1.0
	local xz, y
	if bit32.btest(f.flags_2472, bit32.lshift(1, 15)) and f.jump_fix_frames > a.ignore_danger_frames then
		xz, y = a.xz_trick, a.y_trick
	elseif f.wheel_contact then
		xz, y = f32(mode.ground_xz * deck_scalar), s.ground.y_acceleration
	else
		xz, y = f32(a.xz_acceleration * deck_scalar), a.y_acceleration
	end
	if bit32.btest(f.board_material_flags, bit32.lshift(1, 29)) then
		xz = f32(xz * a.light_dmo_scalar)
	end
	common.closing(state, f, xz, y)
	local displacement = f32(a.max_displacement * scalar)
	if mode.check_squash and f.maximum_pose_error > f32(a.max_squash * scalar) then
		request(state, 18, 0.0)
	elseif dot3(f.pose_error, f.pose_error) > f32(displacement * displacement) then
		request(state, 1, 0.0)
	elseif common.force(f, f32(a.max_contact * scalar), a.max_arm_contact) then
		request(state, 0, 0.0)
	end
	if f.flip_active and f.flip_requested_speed == 0.0 and f.system_up_y < 0.0 then
		request(state, 4, 0.0)
	end
	bad_landing(state, s, mode, f, use_com)
	common.leaning(state, s, f)
	-- Two independent sensitive conditions can request21 twice.
	if bit32.btest(f.flags_2476, bit32.lshift(1, 26)) and f.compliant then
		request(state, 21, 0.0)
	end
	if bit32.btest(f.flags_2472, bit32.lshift(1, 6)) and (f.compliant or f.board_contact) then
		request(state, 21, 0.0)
	end
end

return air
