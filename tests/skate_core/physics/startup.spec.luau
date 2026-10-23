--!strict
-- Сверка physics::startup (reset_collision_info, reset_board_body,
-- reset_skateboard) с настоящим Rust (golden/src/startup.rs).

local harness = require("../../harness")
local u = require("../../util")
local startup = require("../../../src/skate_core/physics/startup")
local golden = require("../../golden/startup") :: any
assert(type(golden) == "table", tostring(golden))

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end
local function from_hex(h: string): buffer
	local b = buffer.create(#h // 2)
	for i = 0, #h // 2 - 1 do
		buffer.writeu8(b, i, tonumber(string.sub(h, i * 2 + 1, i * 2 + 2), 16) :: number)
	end
	return b
end
local function to_hex(b: buffer): string
	local parts = table.create(buffer.len(b))
	for i = 0, buffer.len(b) - 1 do
		parts[i + 1] = string.format("%02x", buffer.readu8(b, i))
	end
	return table.concat(parts)
end
local function deep(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = deep(v)
	end
	return c
end

return function(report: harness.Report)
	harness.test(report, "physics/startup: reset_collision_info, reset_board_body, reset_skateboard vs Rust", function()
		for n, c in golden.collision do
			local b = from_hex(c.before)
			startup.reset_collision_info(b)
			assert(to_hex(b) == c.after, "collision#" .. n)
		end
		for n, c in golden.body do
			local board = from_hex(c.before)
			local bodies = deep(c.bodies_in)
			local old = startup.reset_board_body(board, bodies, c.gravity)
			assert(to_hex(board) == c.after, "body#" .. n .. " board")
			check(u.diff(bodies, c.bodies), "body#" .. n .. " bodies")
			assert(old == c.old, "body#" .. n .. " old")
		end
		for n, c in golden.skateboard do
			local w = "skateboard#" .. n
			local wrapper, body_state = from_hex(c.wrapper_before), from_hex(c.body_before)
			local parts, hook = deep(c.parts_in), deep(c.hook_in)
			local out = startup.reset_skateboard(wrapper, c.base, body_state, parts, hook, c.authored, c.requested, c.flags, c.gravity)
			assert(out == c.out, w .. " out")
			assert(to_hex(wrapper) == c.wrapper_after, w .. " wrapper")
			assert(to_hex(body_state) == c.body_after, w .. " body_state")
			check(u.diff(parts, c.parts), w .. " parts")
			check(u.diff(hook, c.hook), w .. " hook")
		end
	end)
end
