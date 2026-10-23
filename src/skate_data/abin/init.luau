--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/abin/mod.rs (коммит 2e16697)
--
-- Direct stock Andale bank storage and format descriptions.
--
-- Source: TU3 DataBase::SetDBContent 82D1B340, Clip::Init 827B8AB0,
-- FetchSys::BatchFetch 82D20560/82D20788 and codec identifier 82D17A60.
-- This module owns bytes and bounds checks; codec arithmetic belongs to core.
--
-- ROBLOX: структуры (RecordHeader, Record, RecordData, Clip, Pose, PhysicsPose,
-- PartEntry, AnimationPart, Hierarchy, HierarchyPart) — таблицы с теми же
-- полями; Range<usize> -> { start, end }; Option -> nil; enum RecordData ->
-- { kind = "Clip" | "Pose" | "Hierarchy" | "PhysicsPose" | "Opaque", value }.
-- Error { offset, message } -> rt.raise({ offset, message }).

local abin = {}

local bank = require("@self/bank")
local reader = require("@self/reader")
abin.Bank = bank.Bank
abin.Reader = reader.Reader

-- ROBLOX: enum Codec -> "Raw" | "Vbr" | { other = word }.
-- 82D17A60 reverses the disk word and compares RD\0\0 and VBR\0.
function abin.codec_from_word(word: number): any
	if word == 0x00004452 then
		return "Raw"
	elseif word == 0x00524256 then
		return "Vbr"
	end
	return { other = word }
end

function abin.record_codec(header: any): any
	return abin.codec_from_word(header.codec_word)
end

-- Clip flag helpers.
function abin.clip_looping(clip: any): boolean
	return bit32.band(clip.flags, 0x10000000) ~= 0
end
function abin.clip_channel_animation(clip: any): boolean
	return bit32.band(clip.flags, 0x20000000) ~= 0
end
function abin.clip_phase_controlled(clip: any): boolean
	return bit32.band(clip.flags, 0x40000000) ~= 0
end

function abin.hierarchy_compatible_with(a: any, b: any): boolean
	if a.bone_count ~= b.bone_count or a.has_trajectory ~= b.has_trajectory then
		return false
	end
	for _, k in { "parents", "mirrors", "bone_names" } do
		local x, y = a[k], b[k]
		if #x ~= #y then
			return false
		end
		for i = 1, #x do
			if x[i] ~= y[i] then
				return false
			end
		end
	end
	if #a.parts ~= #b.parts then
		return false
	end
	for i, p in a.parts do
		local q = b.parts[i]
		for _, k in { "name", "bone_count", "sqt_offset", "flags", "encoded_id" } do
			if p[k] ~= q[k] then
				return false
			end
		end
	end
	return true
end

return abin
