--!strict
-- Перенос Rust-тестов crates/skate-game/src/input/tests/controllers.rs.

local harness = require("../../harness")
local rt = require("../../../src/rt")
local input = require("../../../src/skate_game/input")

local CI = input.ControllerInput
local GA = require("../../../src/skate_core/input/gameplay_map").GameplayActions

local function packet(number: number, buttons: number, left: { number }): any
	return { ok = { number = number, state = { buttons = buttons, triggers = { 0, 0 }, left = left, right = { 0, 0 } }, subtype = 1, kind = nil } }
end
local OFF: any = { err = { kind = "Disconnected" } }
local function all(s: any): { any }
	return { s, s, s, s }
end
local function zeros18(a: { number }): boolean
	for _, v in a do
		if v ~= 0 then
			return false
		end
	end
	return #a == 18
end

return function(report: harness.Report)
	harness.test(report, "controllers: raw_packets_reach_stock_actions_without_losing_device_identity", function()
		local s = CI.default()
		CI.collect(s, { packet(1, 0x1000, { 32767, 0 }), packet(2, 0x2000, { -32768, 0 }), packet(3, 0x4000, { 0, 0 }), packet(4, 0x8000, { 0, 0 }) })
		assert(CI.publish_actions(s))
		assert(math.abs(s.mapped_actions[1][1] - 1.0) < 0.000001)
		assert(math.abs(s.mapped_actions[2][1] + 1.0) < 0.000001)
		assert(s.mapped_actions[1][17] == 1.0 and s.mapped_actions[2][18] == 1.0)
		assert(s.mapped_actions[3][15] == 1.0 and s.mapped_actions[4][16] == 1.0)
		for i = 1, 4 do
			assert(s.packet_numbers[i] == i)
		end
	end)
	harness.test(report, "controllers: unchanged_packet_numbers_do_not_suppress_publication_and_empty_drain_does_not_advance", function()
		local s = CI.default()
		for _ = 1, 4 do
			CI.collect(s, all(packet(7, 0x1000, { 0, 0 })))
			assert(CI.publish_actions(s))
		end
		assert(s.publications == 4 and s.consumed_batches == 4)
		assert(bit32.band(s.pads[1].records[13][2], 0x01000000) ~= 0)
		local prior = {}
		for i, p in s.pads do
			prior[i] = { count = p.count, first = table.concat(p.records[13], ",") }
		end
		assert(not CI.publish_actions(s))
		for i, p in s.pads do
			assert(p.count == prior[i].count and table.concat(p.records[13], ",") == prior[i].first)
		end
	end)
	harness.test(report, "controllers: disconnect_publishes_zero_count_and_reconnect_reinitializes_pad_records", function()
		local s = CI.default()
		CI.collect(s, all(packet(1, 0x1000, { 32767, 0 })))
		CI.publish_actions(s)
		CI.collect(s, all(OFF))
		CI.publish_actions(s)
		for i = 1, 4 do
			assert(zeros18(s.mapped_actions[i]) and s.pads[i].count == 0)
		end
		CI.collect(s, all(packet(1, 0, { 0, 0 })))
		CI.publish_actions(s)
		for i = 1, 4 do
			assert(zeros18(s.mapped_actions[i]))
		end
		assert(table.concat(s.pads[1].records[13], ",") == "0,0,0,1")
	end)
	harness.test(report, "controllers: alternate_guitar_subtype_uses_verified_conversion_mask_and_errors_stay_visible", function()
		local s = CI.default()
		local special: any = { ok = { number = 1, state = { buttons = 0, triggers = { 255, 255 }, left = { 0, 0 }, right = { -32768, 32767 } }, subtype = 7, kind = nil } }
		CI.collect(s, { special, { err = { kind = "Capabilities", code = 5 } } :: any, OFF, OFF })
		CI.publish_actions(s)
		local m = s.mapped_actions[1]
		assert(m[7] == 0 and m[8] == 0 and m[4] == 0 and m[5] == 0)
		assert(s.status[2].kind == "Unavailable" and (s.status[2].error :: any).kind == "Capabilities" and (s.status[2].error :: any).code == 5)
		assert(zeros18(s.mapped_actions[2]))
	end)
	harness.test(report, "controllers: tick_input_is_the_single_fixed_tick_snapshot", function()
		local s = CI.default()
		CI.collect(s, all(packet(1, 0, { 19661, 0 })))
		assert(CI.publish_actions(s))
		local first = CI.tick_input(s)
		assert(first.tick == 1 and first.controller_available)
		local turn = GA.value(first.actions, 64)
		local second = CI.tick_input(s)
		assert(second.tick == first.tick and GA.value(second.actions, 64) == turn)
	end)
	harness.test(report, "controllers: unavailable_controllers_publish_zero_gameplay_actions", function()
		local s = CI.default()
		CI.collect(s, all(packet(1, 0x1000, { 32767, 0 })))
		assert(CI.publish_actions(s))
		assert(CI.tick_input(s).controller_available)
		CI.collect(s, all(OFF))
		assert(CI.publish_actions(s))
		local snap = CI.tick_input(s)
		assert(not snap.controller_available and zeros18(snap.actions.values))
	end)
	-- ROBLOX: controller_kind не переносится; kind здесь — произвольные метаданные.
	harness.test(report, "controllers: controller_identity_is_metadata_and_never_changes_gameplay_actions", function()
		local state = { buttons = bit32.bor(0x1000, 0x0100), triggers = { 255, 30 }, left = { 20000, -12000 }, right = { -32768, 9000 } }
		local kind = { name = "Xbox Elite Series 2 (Bluetooth LE)" }
		local function run(k: any)
			local s = CI.default()
			for number = 1, 3 do
				CI.collect(s, { { ok = { number = number, state = state, subtype = 1, kind = k } } :: any, OFF, OFF, OFF })
				assert(CI.publish_actions(s))
			end
			return s
		end
		local with, without = run(kind), run(nil)
		for d = 1, 4 do
			for i = 1, 18 do
				assert(rt.to_bits(with.mapped_actions[d][i]) == rt.to_bits(without.mapped_actions[d][i]))
			end
		end
		for i = 1, 18 do
			assert(rt.to_bits(CI.tick_input(with).actions.values[i]) == rt.to_bits(CI.tick_input(without).actions.values[i]))
		end
		assert((CI.kind(with, 0) :: any).name == kind.name and CI.active_slot(with) == 0 and CI.kind(without, 0) == nil)
		CI.collect(with, all(OFF))
		assert(CI.kind(with, 0) == nil)
	end)
	harness.test(report, "input: publish_actions blocked/suppress gameplay", function()
		local s = CI.default()
		local published = input.published_default()
		CI.collect(s, all(packet(1, 0x1000, { 32767, 0 })))
		input.publish_actions(s, published, false, false)
		assert(published.value.actions.values[17] == 1.0)
		CI.collect(s, all(packet(2, 0x1000, { 32767, 0 })))
		input.publish_actions(s, published, false, true)
		assert(zeros18(published.value.actions.values) and published.value.controller_available)
		CI.collect(s, all(packet(3, 0x1000, { 32767, 0 })))
		input.publish_actions(s, published, true, false)
		assert(zeros18(published.value.actions.values))
	end)
end
