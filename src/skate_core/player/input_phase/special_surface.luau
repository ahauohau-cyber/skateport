--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/input_phase/special_surface.rs (коммит 2e16697)
--
-- TU3 ProcessOutput's special-surface writer 82DB8120 and helper 82DB80C8.
-- Consumes the completed per-state packet; never infers contact from proximity.
-- ROBLOX: &mut [bool; 36] -> таблица из 36 boolean; Rust flags[k] -> flags[k + 1].

local rt = require("../../../rt")
local types = require("./types")

type PhysicalPlayerInput = types.PhysicalPlayerInput
type ProcessedPhysicsInput = types.ProcessedPhysicsInput

local special_surface = {}

-- 8208081C in the TU3 mapped image, used by both air-probe branches.
local PROBE_TIME = rt.from_bits(0x3d851eb8)
special_surface.PROBE_TIME = PROBE_TIME

local function react(out: PhysicalPlayerInput, flags: { boolean }, surface: number)
	if surface == 6 then
		flags[69 - 52 + 1] = true
		out.state.flag_69 = 1
	elseif surface == 9 or surface == 12 then
		flags[65 - 52 + 1] = true
	end
end

local function water(out: PhysicalPlayerInput, height: number)
	out.collision.flag_3481 = 1
	out.collision.scalar_28 = height
end

function special_surface.publish_special_surface(
	out: PhysicalPlayerInput,
	p: ProcessedPhysicsInput,
	flags: { boolean },
	board_flags: number,
	board_height: number
)
	local state = p.state_2508
	if (state >= 100 and state <= 104) or state == 503 then
		react(out, flags, out.collision.surface_type_16)
		out.collision.flag_3481 = bit32.band(bit32.rshift(board_flags, 25), 1)
		-- The native branch copies height even when the flag is zero.
		out.collision.scalar_28 = board_height
	elseif state == 201 then
		if out.air.surface_category_232 == 12 and out.air.scalar_184 < PROBE_TIME then
			flags[65 - 52 + 1] = true
			water(out, rt.from_bits(out.air.collision_position_16[2]))
		end
	elseif state == 300 then
		if out.collision.flag_214 ~= 0 then
			flags[69 - 52 + 1] = true
			out.state.flag_69 = 1
		end
		if out.collision.flag_217 ~= 0 then
			water(out, out.collision.surface_height_208)
		elseif out.collision.flag_3483 ~= 0 then
			water(out, rt.from_bits(out.collision.predicted_position_64[2]))
		end
	elseif state == 500 or state == 502 then
		local left, right = p.line_tests_960_1008_1056[1], p.line_tests_960_1008_1056[2]
		local a = bit32.band(bit32.rshift(left.surface, 7), 31)
		local b = bit32.band(bit32.rshift(right.surface, 7), 31)
		if out.off_board.flags_306_307[1] ~= 0 then
			react(out, flags, a)
			if a == 12 then
				water(out, rt.from_bits(left.position[2]))
			end
		elseif out.off_board.flags_306_307[2] ~= 0 then
			react(out, flags, b)
			if b == 12 and out.collision.flag_3481 == 0 then
				water(out, rt.from_bits(right.position[2]))
			end
		elseif a == 12 and b == 12 then
			flags[65 - 52 + 1] = true
			if out.collision.flag_3481 == 0 then
				local l = rt.from_bits(left.position[2])
				local r = rt.from_bits(right.position[2])
				-- vminfp v59,v60,v61 (right, left), including unordered/equal selection.
				water(out, if r < l then r else l)
			end
		end
	elseif state == 501 then
		if out.off_board.word_144 == 12 and out.off_board.scalar_32 < PROBE_TIME then
			flags[65 - 52 + 1] = true
			water(out, out.off_board.scalar_148)
		end
	elseif state == 601 and out.air.flag_448 ~= 0 then
		local surface = bit32.band(bit32.rshift(out.air.footplant_surface_224, 7), 31)
		react(out, flags, surface)
		if surface == 12 then
			water(out, out.air.footplant_surface_height_216)
		end
	elseif state == 602 then
		local line = p.line_tests_960_1008_1056[3]
		if line.valid ~= 0 then
			local surface = bit32.band(bit32.rshift(line.surface, 7), 31)
			react(out, flags, surface)
			if surface == 12 then
				water(out, rt.from_bits(line.position[2]))
			end
		end
	end
end

return special_surface
