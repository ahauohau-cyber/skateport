--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_toolkit.rs (коммит 2e16697)
--
-- Skateboard::PrepareBoardToolkit82C013F0, TU3. Derived physical axes and
-- filtered normal are calculated from the same live deck used by the solver.

local rt = require("../../rt")
local board = require("./board")
local bmo = require("./board_motion_output")
local force_queue = require("./force_queue")
local native_arithmetic = require("./native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local inverse_length_squared = bmo.inverse_length_squared
local dot3 = native_arithmetic.dot3

local board_toolkit = {}

type F4 = { number }

-- ROBLOX: [f32; 4] -> таблица из 4, [[f32; 4]; 4] -> таблица из 4 таких.
export type BoardToolkit = {
	deck: { F4 },
	effective: { F4 },
	inverse_effective: { F4 },
	side: F4,
	up: F4,
	forward: F4,
	horizontal_forward: F4,
	transverse_up: F4,
	forward_velocity: F4,
	travel_direction: F4,
	filtered_normal: F4,
	absolute_speed: number,
	control_sign: number,
	total_mass: number,
}

local BoardToolkit = {}
board_toolkit.BoardToolkit = BoardToolkit

local function map(v: F4, s: number): F4
	return { f32(v[1] * s), f32(v[2] * s), f32(v[3] * s), f32(v[4] * s) }
end

-- Board192 is retained by the owner and replaced by filtered_normal after
-- this call. Reset must supply the recovered retained normal, not derive
-- grounded state from board height.
function BoardToolkit.from_board(
	runtime: any,
	flags_2468: number,
	speed_2612: number,
	ground_normal_464: F4,
	retained_normal: F4
): BoardToolkit
	local BoardRuntime = (require("./board_runtime") :: any).BoardRuntime
	local part = BoardRuntime.part_transforms(runtime)[board.BodyId.Deck + 1]
	local function axis(i: number): F4
		local c = part.basis.columns[i]
		return { c[1], c[2], c[3], 0.0 }
	end
	local t = part.translation
	local deck = { axis(1), axis(2), axis(3), { t.x, t.y, t.z, 1.0 } }
	local masses = {}
	for i, body in BoardRuntime.bodies(runtime) do
		masses[i] = body.inertia.inverse_mass
	end
	return BoardToolkit.calculate(deck, masses, flags_2468, speed_2612, ground_normal_464, retained_normal)
end

function BoardToolkit.calculate(
	deck: { F4 },
	inverse_masses: { number },
	flags: number,
	speed: number,
	normal: F4,
	retained_normal: F4
): BoardToolkit
	local control_sign = if bit32.band(flags, 0x0010_0000) ~= 0 then -1.0 else 1.0
	local effective = { table.clone(deck[1]), table.clone(deck[2]), table.clone(deck[3]), table.clone(deck[4]) }
	for _, a in { 1, 3 } do
		effective[a] = map(deck[a], control_sign)
	end
	-- 82C0149C..150C transposes XYZ, clears all W lanes, and composes the
	-- negative translation in Z,Y,X fused order. Native inverse W is zero.
	local inverse_effective = { { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 } }
	for a = 1, 3 do
		for lane = 1, 3 do
			inverse_effective[a][lane] = effective[lane][a]
		end
	end
	for lane = 1, 4 do
		local z = f32(f32(0.0 - effective[4][3]) * inverse_effective[3][lane])
		local yz = mul_add(f32(0.0 - effective[4][2]), inverse_effective[2][lane], z)
		inverse_effective[4][lane] = mul_add(f32(0.0 - effective[4][1]), inverse_effective[1][lane], yz)
	end
	local side = effective[1]
	local up = deck[2]
	local forward = effective[3]
	local horizontal_forward = table.clone(forward)
	horizontal_forward[2] = 0.0
	local horizontal_squared = dot3(horizontal_forward, horizontal_forward)
	if horizontal_squared > from_bits(0x3727_c5ac) then
		horizontal_forward = map(horizontal_forward, inverse_length_squared(horizontal_squared, 2))
	end
	local parallel = dot3(up, horizontal_forward)
	local rejected = {}
	for i = 1, 4 do
		rejected[i] = f32(up[i] - f32(horizontal_forward[i] * parallel))
	end
	local inverse = inverse_length_squared(dot3(rejected, rejected), 2)
	local transverse_up = map(rejected, inverse)
	-- The bgt takes only ordered positive values; zero and NaN use -1.
	local travel_sign = if speed > 0.0 then 1.0 else -1.0
	local filtered_normal
	if not (dot3(retained_normal, normal) <= from_bits(0x3f6f_5c29)) then
		filtered_normal = normal
	else
		local blended = {}
		for i = 1, 4 do
			blended[i] = mul_add(retained_normal[i], from_bits(0x3f66_6666), f32(normal[i] * from_bits(0x3dcc_cccd)))
		end
		local squared = dot3(blended, blended)
		local inv = inverse_length_squared(squared, 2)
		local len = if squared == 0.0 then 0.0 else f32(squared * inv)
		if len > from_bits(0x3586_37bd) then
			filtered_normal = map(blended, inv)
		else
			filtered_normal = { 0.0, 0.0, 0.0, 0.0 }
		end
	end
	return {
		deck = deck,
		effective = effective,
		inverse_effective = inverse_effective,
		side = side,
		up = up,
		forward = forward,
		horizontal_forward = horizontal_forward,
		transverse_up = transverse_up,
		forward_velocity = map(forward, speed),
		travel_direction = map(forward, travel_sign),
		filtered_normal = filtered_normal,
		absolute_speed = f32(speed * travel_sign),
		control_sign = control_sign,
		total_mass = force_queue.total_body_mass(inverse_masses),
	}
end

return board_toolkit
