--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/startup/skateboard.rs (коммит 2e16697)
--
-- ROBLOX: [u8; N] -> buffer (big-endian); PartPose/PoseMatrix — как в board_pose.

local reset = require("./reset")
local board_pose = require("../board_pose")
local part = require("../board_pose/part")

local skateboard = {}

local function put(bytes: buffer, offset: number, value: number)
	buffer.writeu32(bytes, offset, bit32.byteswap(value))
end
local function fill(bytes: buffer, from: number, to: number)
	buffer.fill(bytes, from, 0, to - from)
end

-- Complete 82C05F50 reset orchestration. `authored` supplies the seven matrices
-- produced by InitializeTransforms82C0ADF0 for the current stock geometry;
-- deck6 is published first, then wheels0..3 and trucks4..5. This explicit input
-- does not select a spawn or change joint anchors to a presumed settled pose.
--
-- `wrapper` is the native Skateboard prefix; `wrapper_base` only reconstructs
-- its three force-queue pointers. `body_state` is its SkateboardBody record.
-- Parts must have live bodies, as in the native seven-part board assembly.
-- Processed+2468 bit20 flips all four lanes of Ri and At before SetTransform.
-- The hook receives that target separately and its body rates are not reset.
function skateboard.reset_skateboard(
	wrapper: buffer,
	wrapper_base: number,
	body_state: buffer,
	parts: { part.PartPose },
	hook: part.PartPose,
	authored: { { number } },
	requested_in: { number },
	processed_flags_2468: number,
	gravity: { { number } }
): number
	for _, p in parts do
		assert(p.body ~= nil, "assertion failed: parts.iter().all(|part| part.body.is_some())")
	end
	for _, i in { 6, 0, 1, 2, 3, 4, 5 } do
		part.set_part_transform(parts[i + 1], authored[i + 1])
	end
	local requested = table.clone(requested_in)
	if bit32.btest(processed_flags_2468, 0x0010_0000) then
		for _, i in { 0, 1, 2, 3, 8, 9, 10, 11 } do
			requested[i + 1] = bit32.bxor(requested[i + 1], 0x8000_0000)
		end
	end
	board_pose.set_board_transform(parts, hook, requested)
	-- ROBLOX: тела меняются на месте (таблицы), обратная запись Some(body) не нужна.
	local bodies = {}
	for i = 1, 7 do
		bodies[i] = parts[i].body :: { number }
	end
	reset.reset_board_body(body_state, bodies, gravity)
	put(wrapper, 256, 0)
	put(body_state, 7680, 0)
	put(body_state, 7684, 0)
	fill(wrapper, 240, 256)
	put(wrapper, 252, 0x3f80_0000)
	buffer.writeu8(wrapper, 290, 0)
	fill(body_state, 960, 992)
	put(body_state, 972, 2)
	put(body_state, 988, 2)
	put(wrapper, 324, (wrapper_base + 352) % 0x1_0000_0000)
	put(wrapper, 320, (wrapper_base + 352) % 0x1_0000_0000)
	put(wrapper, 328, (wrapper_base + 1360) % 0x1_0000_0000)
	put(wrapper, 260, 0)
	fill(wrapper, 192, 208)
	put(wrapper, 196, 0x3f80_0000)
	buffer.writeu8(wrapper, 291, 0)
	return 240
end

return skateboard
