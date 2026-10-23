--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_forces/post.rs (коммит 2e16697)
--
-- Grind Post82D43098 -> Wipeout82D90898; S2 82D85E78 ->82DDF248.
-- Unlike Ground, no cooldown/vehicle/squash/balance checks are added here.

local rt = require("../../../rt")
local board_motion_output = require("../board_motion_output")
local native_arithmetic = require("../native_arithmetic")
local wipeout = require("../../player/wipeout")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local dot3 = native_arithmetic.dot3
local request = wipeout.Requests.request
local regional_force = wipeout.regional_force

local post = {}

-- Required physics_wipeout/default layout values. No borrowed Ground/Air
-- thresholds and no default-value fallback. Shared stock wiring supplies these.
export type Settings = {
	max_arm_contact_164: number,
	max_body_contact_168: number,
	xz_acceleration_204: number,
	max_displacement_208: number,
	max_angular_deck_error_212: number,
}

function post.check(state: wipeout.Requests, settings: Settings, frame: wipeout.Frame)
	state.mode = 5 -- Preserve balance, timers and existing requests.
	if dot3(frame.pose_error, frame.pose_error) > f32(settings.max_displacement_208 * settings.max_displacement_208) then
		request(state, 1, 0.0)
	elseif regional_force(frame, settings.max_body_contact_168, settings.max_arm_contact_164) then
		request(state, 0, 0.0)
	end
	-- 82D90AB8. Closing-velocity checks still run after displacement/contact.
	if frame.board_contact then
		local v = frame.closing_velocity
		local m = frame.world_to_animation
		local loc = {}
		for i = 1, 4 do
			loc[i] = mul_add(m[3][i], v[3], mul_add(m[2][i], v[2], f32(m[1][i] * v[1])))
		end
		local planar = { loc[1], 0.0, loc[3], loc[4] }
		local square = dot3(planar, planar)
		local length = if square == 0.0 then 0.0 else f32(square * board_motion_output.inverse_length_squared(square, 2))
		if length > settings.xz_acceleration_204 or math.abs(loc[2]) > 100.0 then
			request(state, 2, 0.0)
			if regional_force(frame, 1.0, 20.0) then
				request(state, 0, 0.0)
			end
		end
	end
	-- 82D909B0 always checks all three corresponding deck/Input axes.
	local cosine = rt.fmin(rt.fmin(dot3(frame.deck[1], frame.input_board[1]), dot3(frame.deck[2], frame.input_board[2])), dot3(frame.deck[3], frame.input_board[3]))
	if trigonometry.acos(rt.fmin(rt.fmax(cosine, -1.0), 1.0)) > settings.max_angular_deck_error_212 then
		request(state, 3, 0.0)
	end
end

return post
