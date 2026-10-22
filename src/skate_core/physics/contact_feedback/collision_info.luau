--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/contact_feedback/collision_info.rs (коммит 2e16697)

local feedback = require("../contact_feedback")

local word, put = feedback.word, feedback.put

local collision_info = {}

local function up(bytes: buffer, offset: number)
	buffer.fill(bytes, offset, 0, 16)
	put(bytes, offset + 4, 0x3f80_0000)
end

-- Complete 82C00CA0 selective per-frame reset. Wheel surface/audio/object
-- slots and line-test state survive; this differs from startup 82C00D68.
function collision_info.reset_frame_collision_info(info: buffer)
	up(info, 0)
	for i = 0, 6 do
		up(info, 32 + i * 16)
		for _, offset in { 144, 368, 480 } do
			buffer.fill(info, offset + i * 16, 0, 16)
		end
		buffer.writeu8(info, 780 + i, 0)
	end
	for i = 4, 6 do
		for _, offset in { 692, 720, 748 } do
			put(info, offset + i * 4, 0)
		end
	end
	buffer.fill(info, 592, 0, 16)
	buffer.fill(info, 688, 1, 4)
	for _, offset in { 776, 788, 796, 800 } do
		put(info, offset, 0)
	end
	buffer.writeu8(info, 804, 0)
	buffer.writeu8(info, 805, 0)
	local flags = bit32.band(word(info, 808), 0x01ff_ffff)
	put(info, 808, flags)
end

-- Typed82C08818 boundary. Values are the retained wheel surface outputs;
-- query misses and contact replacements belong to their original producers.
-- Noncontacting wheels contribute one vote; contacting wheels four. Equal counts
-- favor the lower ID. IDs14/15 are accumulated but not considered.
function collision_info.choose_surface(surfaces: { number }, contacts: { boolean }, forced_twelve: boolean): number
	local votes = table.create(16, 0) :: { number }
	for i = 1, 4 do
		local surface = surfaces[i]
		if surface ~= 0 then
			assert(surface < 16, "native surface histogram index exceeded")
			votes[surface + 1] += if contacts[i] then 4 else 1
		end
	end
	local winner, maximum = 1, 0
	for surface = 1, 13 do
		local count = votes[surface + 1]
		if count > maximum then
			maximum = count
			winner = surface
		end
	end
	return if forced_twelve then 12 else winner
end

-- Complete 82C08818 surface vote over CollisionInfo.
function collision_info.choose_physics_surface(info: buffer)
	local surfaces, contacts = {}, {}
	for i = 0, 3 do
		surfaces[i + 1] = word(info, 692 + i * 4)
		contacts[i + 1] = buffer.readu8(info, 780 + i) ~= 0
	end
	local result = collision_info.choose_surface(surfaces, contacts, bit32.band(word(info, 808), 0x0200_0000) ~= 0)
	put(info, 776, result)
end

return collision_info
