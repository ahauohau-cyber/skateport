--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/post_input.rs (коммит 2e16697)
--
-- Complete player-owned portion of TU3 `PhysicalPlayerHiLOD::PostInput`
-- (`0x82DB5588`) and its flag-latch helper (`0x82DB5CF8`).
--
-- Grind, trajectory, the scalar calculation at `0x82DB5E10`, and candidate
-- registration remain required services because they own separate systems.
-- ROBLOX: `&mut u32` в replace_bit -> функция возвращает новое слово.
-- ROBLOX: enum CandidateRegistration -> строки "First1888" / "Second2176".

local rt = require("../../rt")

local post_input = {}

export type PostInputPlayerFields = {
	-- Player+1264, captured from PhysOut when its +442 byte is set.
	jump_reference_1264: { number },
	-- Player+1296.
	flags_1296: number,
	-- Player+1304.
	state_frames_1304: number,
	-- Player+1308.
	jump_fix_frames_1308: number,
	-- Player+1320, owned by `0x82DB5CF8`.
	latch_frames_1320: number,
}

export type PostInputProcessedFields = {
	-- ProcessedPhysIn+848.
	jump_reference_848: { number },
	word_2464: number,
	flags_2468: number,
	flags_2472: number,
	flags_2480: number,
	flags_2484: number,
	current_state_2508: number,
	state_frames_2572: number,
	jump_fix_frames_2576: number,
	scalar_2740: number,
}

export type PostInputPhysOutFields = {
	-- PhysOut+32 -> +316.
	reset_state_frames_316: boolean,
	-- PhysOut+8 -> +442.
	capture_jump_reference_442: boolean,
	-- PhysOut+8 -> +128.
	jump_reference_128: { number },
	-- PhysOut+76, set after every successful PostInput pass.
	complete_76: boolean,
}

-- Player+1840 data consumed by `0x82D740F8`.
export type CandidatePublicationFields = {
	first_object_present_196: boolean,
	first_pending_288: boolean,
	second_object_present_500: boolean,
	second_pending_592: boolean,
	staged_word_12768: number,
	staged_valid_12772: number,
	staged_latched_12776: number,
	staged_pending_12780: boolean,
}

-- First1888: `sub_82762AB0(ProcessedPhysIn+1888, component)`.
-- Second2176: `sub_82762AB0(ProcessedPhysIn+2176, component+304)`.
export type CandidateRegistration = "First1888" | "Second2176"

-- Calls to independent systems, in their exact `0x82DB5588` order.
export type PostInputServices = {
	update_grind_manager_82d8ab08: (self: any) -> (),
	update_trajectory_selector_82d68800: (self: any) -> number,
	calculate_scalar_2740_82db5e10: (self: any) -> number,
	register_candidate_82762ab0: (self: any, registration: CandidateRegistration) -> (),
}

export type PostInputContext = {
	player: PostInputPlayerFields,
	processed: PostInputProcessedFields,
	phys_out: PostInputPhysOutFields,
	candidates: CandidatePublicationFields,
}

local function replace_bit(word: number, b: number, value: number): number
	return bit32.bor(bit32.band(word, bit32.bnot(bit32.lshift(1, b))), bit32.lshift(bit32.band(value, 1), b))
end

local function from_bool(value: boolean): number
	return if value then 1 else 0
end

-- Exact scalar bit transfers and latch lifetime from TU3 `0x82DB5CF8`.
local function update_flag_latches_82db5cf8(player: PostInputPlayerFields, processed: PostInputProcessedFields)
	if bit32.band(processed.flags_2468, 0x00200000) ~= 0 then
		player.latch_frames_1320 = 0
		player.flags_1296 = bit32.bor(player.flags_1296, 0x02000000)
	end
	if bit32.band(processed.flags_2472, 0x00000020) ~= 0 or bit32.band(processed.flags_2468, 0x00400000) ~= 0 then
		player.latch_frames_1320 = 0
		player.flags_1296 = bit32.bor(player.flags_1296, 0x06000000)
	end

	local flags_before_expiry = player.flags_1296
	if bit32.band(flags_before_expiry, 0x02000000) ~= 0 then
		if
			bit32.band(processed.flags_2472, 0x00000010) ~= 0
			or (bit32.band(flags_before_expiry, 0x08000000) ~= 0 and bit32.band(processed.flags_2472, 0x00008000) == 0)
		then
			player.flags_1296 = bit32.band(player.flags_1296, 0xF9FFFFFF)
		end
		local frames = player.latch_frames_1320
		if frames > 20 and bit32.band(player.flags_1296, 0x08000000) == 0 then
			player.flags_1296 = bit32.band(player.flags_1296, 0xF9FFFFFF)
		end
		player.latch_frames_1320 = rt.wrapping_add_u32(frames, 1)
	end

	player.flags_1296 = replace_bit(player.flags_1296, 28, bit32.band(bit32.rshift(processed.flags_2472, 4), 1))
	player.flags_1296 = replace_bit(player.flags_1296, 27, bit32.band(bit32.rshift(processed.flags_2472, 15), 1))
	player.flags_1296 = replace_bit(player.flags_1296, 17, bit32.band(bit32.rshift(processed.flags_2480, 17), 1))
	processed.flags_2472 = replace_bit(processed.flags_2472, 3, bit32.band(bit32.rshift(player.flags_1296, 26), 1))
	processed.flags_2472 = replace_bit(processed.flags_2472, 2, bit32.band(bit32.rshift(player.flags_1296, 25), 1))
end

-- Complete TU3 `0x82D740F8` publication/reset behavior.
local function publish_candidates_82d740f8(fields: CandidatePublicationFields, processed: PostInputProcessedFields, services: any)
	local first = fields.first_pending_288 and fields.first_object_present_196
	if first then
		services:register_candidate_82762ab0("First1888")
	end
	processed.flags_2480 = replace_bit(processed.flags_2480, 22, from_bool(first))
	fields.first_pending_288 = false

	local second = fields.second_pending_592 and fields.second_object_present_500
	if second then
		services:register_candidate_82762ab0("Second2176")
	end
	processed.flags_2480 = replace_bit(processed.flags_2480, 21, from_bool(second))
	fields.second_pending_592 = false

	if fields.staged_pending_12780 then
		fields.staged_latched_12776 = 0
		if fields.staged_valid_12772 ~= 0 then
			fields.staged_latched_12776 = 1
			processed.flags_2480 = bit32.bor(processed.flags_2480, 0x00100000)
			processed.word_2464 = fields.staged_word_12768
		else
			processed.flags_2480 = bit32.band(processed.flags_2480, bit32.bnot(0x00100000))
		end
	end
	fields.staged_pending_12780 = false
end

-- ROBLOX: приватная функция открыта для теста tests/post_input.rs.
post_input.update_flag_latches_82db5cf8 = update_flag_latches_82db5cf8

-- Runs the full TU3 PostInput phase for the fields owned by PhysicalPlayer.
function post_input.run_post_input(context: PostInputContext, services: any)
	local player, processed, phys_out, candidates = context.player, context.processed, context.phys_out, context.candidates

	services:update_grind_manager_82d8ab08()

	if phys_out.reset_state_frames_316 then
		player.state_frames_1304 = 0
	end
	player.state_frames_1304 = rt.wrapping_add_u32(player.state_frames_1304, 1)

	local reset_state_frames = bit32.band(processed.flags_2480, 0x00002000) ~= 0
		or (bit32.band(processed.flags_2468, 0x00400000) ~= 0 and bit32.band(player.flags_1296, 0x40000000) ~= 0)
	if reset_state_frames then
		player.state_frames_1304 = 0
		player.flags_1296 = bit32.band(player.flags_1296, bit32.bnot(0x40000000))
	else
		player.flags_1296 = replace_bit(player.flags_1296, 30, from_bool(bit32.band(processed.flags_2468, 0x00400000) == 0))
		processed.flags_2468 = bit32.band(processed.flags_2468, bit32.bnot(0x00400000))
	end
	processed.state_frames_2572 = player.state_frames_1304

	if phys_out.capture_jump_reference_442 then
		player.jump_fix_frames_1308 = 1
		player.jump_reference_1264 = table.clone(phys_out.jump_reference_128)
	else
		player.jump_fix_frames_1308 = rt.wrapping_add_u32(player.jump_fix_frames_1308, 1)
	end
	processed.jump_fix_frames_2576 = player.jump_fix_frames_1308
	processed.jump_reference_848 = table.clone(player.jump_reference_1264)

	processed.flags_2468 = replace_bit(processed.flags_2468, 10, bit32.band(services:update_trajectory_selector_82d68800(), 1))
	processed.scalar_2740 = services:calculate_scalar_2740_82db5e10()
	processed.flags_2484 = replace_bit(processed.flags_2484, 25, bit32.band(bit32.rshift(player.flags_1296, 24), 1))

	if bit32.band(processed.flags_2484, 0x00000800) ~= 0 then
		player.flags_1296 = bit32.bor(player.flags_1296, 0x00200000)
	elseif processed.current_state_2508 == 103 then
		processed.flags_2484 = replace_bit(processed.flags_2484, 11, bit32.band(bit32.rshift(player.flags_1296, 21), 1))
	else
		player.flags_1296 = bit32.band(player.flags_1296, bit32.bnot(0x00200000))
	end

	update_flag_latches_82db5cf8(player, processed)
	publish_candidates_82d740f8(candidates, processed, services)
	phys_out.complete_76 = true
end

-- 82762AB0 copies the defined fields, preserving destination padding and the
-- low five bits of byte200. Words use native big-endian bit positions.
-- ROBLOX: срезы [a..b] -> индексы a+1..b.
function post_input.copy_grab_record_82762ab0(destination: { number }, source: { number })
	for i = 1, 50 do
		destination[i] = source[i]
	end
	destination[51] = bit32.bor(bit32.band(destination[51], 0x1fffffff), bit32.band(source[51], 0xe0000000))
	for i = 52, 55 do
		destination[i] = source[i]
	end
	for i = 57, 66 do
		destination[i] = source[i]
	end
	destination[69] = source[69]
end

return post_input
