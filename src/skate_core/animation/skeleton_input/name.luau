--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/skeleton_input/name.rs (коммит 2e16697)
--
-- Native five-word text encoding 823C3C78 and six-character chunk 82382B50.
-- This is an encoded string, not a vault/hash-table key or pointer identity.

local rt = require("../../../rt")

local name = {}

-- Encode up to 30 bytes, stopping at NUL. Native accepts signed bytes and does
-- not validate its alphabet. Preserve its case folding, punctuation behavior,
-- wrapping word arithmetic and truncation; do not substitute UTF-8 casefold.
-- ROBLOX: &[u8] -> строка Luau (байты string.byte); AttributeName -> { 5 слов }.
function name.encode(text: string): { number }
	local words = { 0, 0, 0, 0, 0 }
	local len = #text
	local position = 0
	while position < 30 and position < len and string.byte(text, position + 1) ~= 0 do
		local weight = 79235168 -- 38^5, exactly the native first weight.
		local word = position // 6
		local count = 0
		while count < 6 and position < len and string.byte(text, position + 1) ~= 0 do
			local byte = string.byte(text, position + 1)
			if byte >= 128 then
				byte -= 256 -- as i8
			end
			local digit
			if byte >= 97 then
				digit = byte - 86
			elseif byte > 90 then
				digit = byte - 58
			elseif byte > 57 then
				digit = byte - 54
			else
				digit = byte - 47
			end
			-- ROBLOX: (digit as u32).wrapping_mul(weight) -> rt.wrapping_mul_u32.
			words[word + 1] = rt.wrapping_add_u32(words[word + 1], rt.wrapping_mul_u32(digit % 0x100000000, weight))
			weight //= 38
			count += 1
			position += 1
		end
	end
	return words
end

return name
