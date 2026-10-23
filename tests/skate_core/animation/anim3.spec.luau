--!strict
-- Сверка animation/skeleton_input, animation/vbr и skate_data/abin с настоящим
-- skate-core (golden/src/anim3.rs) на стоковых банках OnBoard/OffBoard,
-- плюс перенос Rust-тестов skeleton_input/tests.rs и vbr/tests/bits.rs.
-- Эталон и банки — данные игры: в git не идут, без них тест пропускается.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local name_mod = require("../../../src/skate_core/animation/skeleton_input/name")
local catalog = require("../../../src/skate_core/animation/skeleton_input/catalog")
local process_attributes = require("../../../src/skate_core/animation/skeleton_input/process_attributes")
local scalar_attributes = require("../../../src/skate_core/animation/skeleton_input/scalar_attributes")
local extended_attributes = require("../../../src/skate_core/animation/skeleton_input/extended_attributes")
local attribute_finalization = require("../../../src/skate_core/animation/skeleton_input/attribute_finalization")
local attributes = require("../../../src/skate_core/animation/output/attributes")
local packet_reset = require("../../../src/skate_core/animation/output/packet_reset")
local vbr = require("../../../src/skate_core/animation/vbr")
local bits = require("../../../src/skate_core/animation/vbr/bits")
local abin = require("../../../src/skate_data/abin")
local files = require("../../../src/skate_data/files")

local encode = name_mod.encode
local to_bits = rt.to_bits

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

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end

local function load_golden(): any
	local ok, g = pcall(require, "../../golden/anim3")
	if ok and type(g) == "table" then
		return g
	end
	return nil
end

local function load_files(): boolean
	local ok, src = pcall(require, "../../../src/skate_data/stock_files")
	if not ok or type(src) ~= "table" then
		return false
	end
	files.set_source(src)
	return files.exists("stock/data/anim/OnBoard.abin")
end

return function(report: harness.Report)
	local golden = load_golden()
	local names = { encode("Trajectory"), encode("RightToeBase"), encode("LeftToeBase"), encode("righthand") }

	if golden then
		harness.test(report, "animation/skeleton_input: process_attributes 120 пакетов vs Rust", function()
			for i, c in golden.process do
				local fields, extra = deep(c.fields), deep(c.extra)
				local contacts, cached, output = deep(c.contacts), deep(c.cached), deep(c.output)
				local pose = { bone_names = names, hierarchy = c.hierarchy, trajectory_bone = c.trajectory_bone, right_toe_bone = c.right_toe_bone, timestep = c.timestep }
				local calls = {}
				local map = if c.has_map
					then {
						value = function(_, k: number): number
							table.insert(calls, k)
							return rt.f32((k % 7) * 0.25 - 0.75)
						end,
						state = function(_, _k: number): number
							return 0
						end,
					}
					else nil
				local _, err = rt.catch(process_attributes.process, deep(c.attrs), pose, fields, extra, contacts, cached, output, c.fin, map)
				local at = "#" .. i
				check(u.diff(err ~= nil, c.err), at .. " err")
				check(u.diff(fields, c.out_fields), at .. " fields")
				check(u.diff(extra, c.out_extra), at .. " extra")
				check(u.diff(contacts, c.out_contacts), at .. " contacts")
				check(u.diff(cached, c.out_cached), at .. " cached")
				check(u.diff(output, c.out_output), at .. " output")
				check(u.diff(calls, c.calls), at .. " calls")
			end
		end)
	end

	harness.test(report, "skeleton_input: complete_attribute_packet_keeps_contact_timing_reset_and_finalization", function()
		local fields = scalar_attributes.ScalarAttributeInputs.reset(8, 0xffffffff)
		local extra = extended_attributes.ExtendedAttributes.reset(0.0)
		local contacts = { bone = 0, push_speed = 0.0 }
		local cached = attribute_finalization.JumpAttributeState.new()
		local output = { grind_name = encode(""), flags = 0 }
		local pnames = { encode("Trajectory"), encode("RightToeBase") }
		local hierarchy = { deep(packet_reset.RESET_POSE), deep(packet_reset.RESET_POSE) }
		hierarchy[1][4] = { 0.0, 0.0, rt.f32(0.1), 0.0 }
		hierarchy[2][4] = { 20.0, 10.0, -40.0, 0.0 }
		local pose = { bone_names = pnames, hierarchy = hierarchy, trajectory_bone = 0, right_toe_bone = 1, timestep = rt.f32(1.0 / 60.0) }
		local map = {
			value = function(_, key: number): number
				if key == 64 then
					return 0.25
				elseif key == 65 then
					return -0.75
				elseif key == 68 then
					return 0.5
				end
				error("Unexpected source action" .. key)
			end,
			state = function(_, _k: number): number
				error("Attribute finalization reads analog values only")
			end,
		}
		local input = { select_jump_extremes = true, low_jump_threshold = 0.25, high_jump_threshold = 0.75, allow_height_override = true, use_prepared_controls = false, external_impulse_active = false, animation_flags = 0x08000000 }
		local event = attributes.MotionGraphAttribute.to_animation({ name = encode("push_contact"), value = 0.0 })
		event.kind = 3
		event.status = 4
		for i = 1, 6 do
			event.payload[i] = if i <= 5 then pnames[2][i] else to_bits(1.0)
		end
		process_attributes.process({ event }, pose, fields, extra, contacts, cached, output, input, map)
		assert(contacts.bone == 1)
		assert(math.abs(contacts.push_speed - 6.0) < 0.00001)
		assert(bit32.band(fields.flags2468, 0x0f000000) == 0x0e000000)
		assert(bit32.band(extra.flags2480, 8) == 8)
		assert(extra.jump_controls[1] == 0.25 and extra.jump_controls[2] == 0.5)
		event.status = 2
		contacts.push_speed = 7.0
		process_attributes.process({ event }, pose, fields, extra, contacts, cached, output, input, map)
		assert(contacts.push_speed == 7.0)
		local all = {}
		for _, a in catalog.SCALAR_ATTRIBUTES do
			table.insert(all, attributes.MotionGraphAttribute.to_animation({ name = a.encoded_name, value = 0.5 }))
		end
		process_attributes.process(all, pose, fields, extra, contacts, cached, output, input, map)
		assert(cached.prepared_controls[1] == 0.25 and cached.prepared_controls[2] == -0.75)
		assert(bit32.band(fields.flags2476, 2) == 2)
		assert(bit32.band(fields.flags2476, 0x400000) == 0)
		local reset = scalar_attributes.ScalarAttributeInputs.reset(fields.flags2468, fields.flags2488)
		assert(reset.flags2468 == 0x2008)
		assert(reset.turn_scale == 1.0 and reset.magnitude_scale == 1.0 and reset.cadence_end_percent == -1.0)
	end)

	local function buf(t: { number }): buffer
		local b = buffer.create(#t)
		for i, v in t do
			buffer.writeu8(b, i - 1, v)
		end
		return b
	end

	harness.test(report, "vbr/bits: native_sign_bit_and_zero_width_do_not_consume_extra_selectors", function()
		local b = buf({ 2, 3, 0x5a })
		local values = bits.unpack(b, 0, buffer.len(b), { 0x0203 })
		assert(values[1][1] == -5.0 and values[1][2] == 0.0 and values[1][3] == 2.0)
		local nz = buf({ 1, 1, 0 })
		local negative_zero = bits.unpack(nz, 0, 3, { 1 })
		assert(to_bits(negative_zero[1][1]) == 0x80000000)
	end)

	harness.test(report, "vbr/bits: packed_words_continue_across_the_native_vector_boundary", function()
		local t = { 9, 0xff, 1, 0xff, 0xff, 2, 0, 5, 0, 6, 0, 9, 0, 10, 0, 13, 0, 14, 0, 17, 0 }
		local b = buf(t)
		local values = bits.unpack(b, 0, buffer.len(b), { 0xffffffff, 15 })
		local want = { 32767.0, -1.0, 2.0, -3.0, 4.0, -5.0, 6.0, -7.0 }
		for i = 1, 8 do
			assert(values[1][i] == want[i], "lane " .. i)
		end
		assert(values[2][1] == 8.0)
		local _, err = rt.catch(bits.unpack, b, 0, buffer.len(b) - 1, { 0xffffffff, 15 })
		assert(err ~= nil)
	end)

	if golden and load_files() then
		harness.test(report, "skate_data/abin + vbr: стоковые банки OnBoard/OffBoard vs Rust", function()
			local Bank = abin.Bank
			for name, g in golden.banks do
				local bank = Bank.parse(files.read("stock/data/anim/" .. name .. ".abin"))
				Bank.validate_positional_parts(bank)
				check(u.diff(#Bank.records(bank), g.records_n), name .. " records_n")
				check(u.diff(bank.wrapper_bytes, g.wrapper_bytes), name .. " wrapper")
				check(u.diff(bank.trailer, g.trailer), name .. " trailer")
				check(u.diff(Bank.hierarchy(bank), g.hierarchy), name .. " hierarchy")
				for _, r in g.records do
					check(u.diff(Bank.records(bank)[r.index + 1], { header = r.header, data = r.data }), name .. " record" .. r.index)
				end
				for _, v in g.vbr do
					local _, clip = Bank.clip(bank, v.clip)
					assert(clip, v.clip)
					local part = (clip :: any).parts[v.table_index + 1].part
					local d, err = rt.catch(vbr.VbrDecoder.new, Bank.bytes(bank), part.offset, part.compression_header_relative, part.compressed_data_relative)
					local at = name .. " " .. v.clip .. "/" .. v.table_index
					if v.err then
						assert(err ~= nil, at)
						continue
					end
					assert(d, at .. ": " .. tostring(err))
					check(u.diff(vbr.VbrDecoder.frame_count(d), v.frames_n), at .. " frames")
					check(u.diff(vbr.VbrDecoder.channel_count(d), v.channels), at .. " channels")
					for k, f in v.frames do
						check(u.diff(vbr.VbrDecoder.decode_frame(d, f), v.out[k]), at .. " frame" .. f)
					end
				end
			end
		end)
	end
end
