--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/contact_state.rs (коммит 2e16697)
--
-- Ground contact identity/update leaf (`82D38430`).

local rt = require("../../../../rt")
local data = require("./data")

local from_bits = rt.from_bits

type F4 = { number }

local contact_state = {}

-- Values copied into the native contact publication record.
export type GroundContactStateInput = {
	flags_2476: number,
	flags_2480: number,
	velocity_400: F4,
	axis_464: F4,
	contact_position_560: F4,
	trajectory_position_592: F4,
	reckoning_vector_1200: F4,
	-- Selected global collection +396 -> layout+4 -> +560.
	differing_contact_frame_limit: number,
}

-- Required owner/collision operations around state-owned counter logic.
-- ROBLOX: трейт -> таблица методов, каждый возвращает (значение, ошибка):
--   stop_contact_tracking_82d62f20(), clear_inactive_contact_output_3024(),
--   initial_contact_handle_1920() -> handle?, identify_contact_82d63c30(frame) -> handle?,
--   publish_contact_82d61268(frame, retained?)
-- Handle сравнивается через ==.

local function wrapping_add_i32(value: number, add: number): number
	return rt.to_i32(value + add)
end

local function call(err: any)
	if err ~= nil then
		rt.raise(err)
	end
end

-- Runs the full TU3 state/call order. Counter updates use wrapping integer
-- arithmetic because the native body uses ordinary `addi` instructions.
-- ROBLOX: Result<(), S::Error> -> (true) или (nil, ошибка).
function contact_state.update(history: data.GroundContactHistory, input: GroundContactStateInput, services: any): (boolean?, any)
	return rt.catch(function()
		if bit32.band(input.flags_2476, 0x0040_0000) == 0 then
			local _, e1 = services:stop_contact_tracking_82d62f20()
			call(e1)
			local _, e2 = services:clear_inactive_contact_output_3024()
			call(e2)
			return true
		end
		if bit32.btest(input.flags_2480, 0x2000_0000) or not bit32.btest(input.flags_2480, 0x1000_0000) then
			history.tracked_contact_2760 = nil
			history.differing_contact_frames_2756 = 0
		end
		if bit32.btest(input.flags_2480, 0x1000_0000) then
			if input.axis_464[2] < from_bits(0x3f73_3333) then
				if history.tracked_contact_2760 == nil then
					local handle, e = services:initial_contact_handle_1920()
					call(e)
					history.tracked_contact_2760 = handle
				end
				local current, e = services:identify_contact_82d63c30(input)
				call(e)
				history.differing_contact_frames_2756 = if current == history.tracked_contact_2760
					then 0
					else wrapping_add_i32(history.differing_contact_frames_2756, 1)
				if history.differing_contact_frames_2756 > input.differing_contact_frame_limit then
					history.tracked_contact_2760 = nil
				end
			else
				-- Native label clears only the retained handle here.
				history.tracked_contact_2760 = nil
			end
		end
		local _, e = services:publish_contact_82d61268(input, history.tracked_contact_2760)
		call(e)
		return true
	end)
end

return contact_state
