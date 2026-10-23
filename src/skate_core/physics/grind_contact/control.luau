--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_contact/control.rs (коммит 2e16697)
--
-- TU3 one-truck control82D89F58 and orientation82D40290.
-- ROBLOX: `use super::*` -> control.parent (ставит grind_contact/init.luau).

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local fmin, fmax = rt.fmin, rt.fmax
local dot3 = native_arithmetic.dot3

type V = { number }

local control = {}
control.parent = (nil :: any)

local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function add(a: V, b: V): V
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end
local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end
local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		0.0,
	}
end

export type Control = { yaw: number, pitch: number }

local Control = {}
control.Control = Control

-- ROBLOX: #[derive(Default)].
function Control.default(): Control
	return { yaw = 0.0, pitch = 0.0 }
end

-- 82D862B8: signed .25 dead zone, remaining range scaled by4/3.
local function deadzone(v: number): number
	local k = f32(4.0 / 3.0)
	if v > 0.25 then
		return f32(f32(v - 0.25) * k)
	elseif v < -0.25 then
		return f32(f32(v + 0.25) * k)
	end
	return 0.0
end

-- Animation2796/2800/2804/2808; candidate412 bit29 selects the front end.
function Control.update(
	self: Control,
	kind: number,
	board_forward: V,
	normal: V,
	front: boolean,
	switched: boolean,
	hanging_back: boolean,
	translation: number,
	nudge: number,
	up_down: number,
	grab_min_height: number
)
	local yaw, pitch, modified
	if kind == 0 then
		yaw, pitch, modified = 0.0, f32(f32(up_down * up_down) * up_down), false
	elseif kind == 3 then
		local selected = front ~= switched
		local tilt = dot3(normal, board_forward)
		local height = f32((if selected then -tilt else tilt) * (if switched then -1.0 else 1.0))
		local input = up_down
		if height > 0.0 and math.abs(up_down) <= f32(0.01) and height > -0.25 then
			input = if selected then -f32(0.71) else f32(0.71)
		end
		local target = input
		if math.abs(tilt) > f32(0.26) then
			target = if selected then fmin(input, 0.0) else fmax(input, 0.0)
		end
		if height < -0.25 then
			target = if selected then fmax(input, 0.0) else fmin(input, 0.0)
		end
		local sign = (if front then 1.0 else -1.0) * (if switched then -1.0 else 1.0)
		if grab_min_height > 0.0 and height <= grab_min_height then
			local value = f32(f32(f32(grab_min_height - height) * sign) * 10.0)
			target = if sign > 0.0 then fmin(value, sign) else fmax(value, sign)
		end
		if hanging_back then
			target = rt.fclamp(f32(target + f32(sign * 0.5)), -1.0, 1.0)
		end
		-- 82D8A238/240: round the nudge product, then fused translation.
		local y = rt.fclamp(mul_add(deadzone(translation), f32(0.85), f32(deadzone(nudge) * f32(0.79))), -f32(0.85), f32(0.85))
		yaw, pitch, modified = f32(f32(y * y) * y), f32(f32(target * target) * target), target ~= input
	else
		yaw, pitch, modified = 0.0, 0.0, false
	end
	local response = if modified then f32(0.76) else f32(0.91)
	self.yaw = mul_add(self.yaw, f32(0.91), f32(yaw * from_bits(0x3db851e8)))
	self.pitch = mul_add(f32(1.0 - response), pitch, f32(self.pitch * response))
	if math.abs(self.yaw) < f32(0.0001) then
		self.yaw = 0.0
	end
	if math.abs(self.pitch) < f32(0.0001) then
		self.pitch = 0.0
	end
end

function control.rotate(axis: V, value: V, angle: number): V
	local s, c = trigonometry.sin_cos(f32(angle * 0.5))
	local q = scale(axis, s)
	return add(value, scale(cross(q, add(scale(value, c), cross(q, value))), 2.0))
end
local rotate = control.rotate

-- 82D40290: yaw around support, orthogonalize, then pitch around deck right.
function control.truck_frame(board: { V }, normal: V, ctl: Control, switched: boolean): { V }
	local forward = rotate(normal, board[3], f32(ctl.yaw * -f32(0.68)))
	local right = cross(normal, forward)
	-- ROBLOX: f32::sqrt / recip -> f32(math.sqrt) / f32(1 / x).
	local length = f32(math.sqrt(dot3(right, right)))
	if length <= f32(0.001) then
		return board
	end
	right = scale(right, f32(1.0 / length))
	forward = rotate(right, forward, f32(ctl.pitch * (if switched then -f32(0.68) else f32(0.68))))
	return { right, cross(forward, right), forward, board[4] }
end

-- 82D42528/82D42AF8: rotate support by20/42 degrees about the directed rail,
-- then align board-right with the rail. Side is determined by contact offset.
function control.tip_frame(board: { V }, direction: V, normal: V, point: V, backslash: boolean): { V }
	local across = cross(direction, normal)
	local axis = scale(direction, if dot3(across, sub(board[4], point)) > 0.0 then -1.0 else 1.0)
	local angle = if backslash then from_bits(0x3f3ba866) else from_bits(0x3eb2b8c3)
	local up = rotate(axis, normal, angle)
	local right = scale(direction, if dot3(direction, board[1]) > 0.0 then 1.0 else -1.0)
	return { right, up, cross(right, up), board[4] }
end

return control
