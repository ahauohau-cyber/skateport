--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/physics_skeleton.rs (коммит 2e16697)
--
-- Lossless stock physics-bone records. Core consumes typed values derived here.

local rt = require("../rt")
local files = require("./files")
local json = require("./json")

local from_bits = rt.from_bits

local physics_skeleton = {}

export type PhysicsBone = {
	name: string,
	source_offset: number,
	words: { number },
}

local PhysicsBone = {}
physics_skeleton.PhysicsBone = PhysicsBone

function PhysicsBone.size(self: PhysicsBone): { number }
	return { from_bits(self.words[9]), from_bits(self.words[10]), from_bits(self.words[11]) }
end

function PhysicsBone.rotation(self: PhysicsBone): { number }
	return { from_bits(self.words[13]), from_bits(self.words[14]), from_bits(self.words[15]), from_bits(self.words[16]) }
end

function PhysicsBone.translation(self: PhysicsBone): { number }
	return { from_bits(self.words[17]), from_bits(self.words[18]), from_bits(self.words[19]) }
end

export type PhysicsSkeleton = {
	name: string,
	source_offset: number,
	bones: { PhysicsBone },
}

local PhysicsSkeleton = {}
physics_skeleton.PhysicsSkeleton = PhysicsSkeleton

-- ROBLOX: serde (deny_unknown_fields, [u32; 28]) -> проверки вручную.
local function decode(text: string): any
	local file = json.decode(text)
	json.expect_fields(file, { "version", "source_sha256", "skeletons" }, "File")
	for _, s in file.skeletons do
		json.expect_fields(s, { "name", "source_offset", "bones" }, "PhysicsSkeleton")
		for _, b in s.bones do
			json.expect_fields(b, { "name", "source_offset", "words" }, "PhysicsBone")
			if #b.words ~= 28 then
				rt.raise(string.format("invalid length %d, expected an array of length 28", #b.words))
			end
		end
	end
	return file
end

-- ROBLOX: path — путь в упакованных файлах (files.luau), например
-- "stock/physics-skeletons.json".
function PhysicsSkeleton.load(path: string, bank_sha256: string, name: string): PhysicsSkeleton
	local text, err = rt.catch(files.read_string, path)
	if err ~= nil then
		rt.raise(string.format("%s: %s", path, tostring(err)))
	end
	local file, err2 = rt.catch(decode, text)
	if err2 ~= nil then
		rt.raise(tostring(err2))
	end
	if file.version ~= 1 or file.source_sha256 ~= bank_sha256 then
		rt.raise("Physics skeleton bank identity or format differs from animation data")
	end
	local identities = {}
	for _, s in file.skeletons do
		if identities[s.name] then
			rt.raise("Converted physics skeleton has unresolved duplicate names")
		end
		identities[s.name] = true
	end
	local selected: any = nil
	for _, s in file.skeletons do
		if string.lower(s.name) == string.lower(name) then
			selected = s
			break
		end
	end
	if selected == nil then
		rt.raise(string.format("Required stock physics skeleton %s is absent", name))
	end
	if #selected.bones == 0 or #selected.bones > 255 then
		rt.raise("Invalid stock physical bone count")
	end
	local names = {}
	for _, bone in selected.bones do
		local bad = names[bone.name] ~= nil
		names[bone.name] = true
		for _, list in { PhysicsBone.size(bone), PhysicsBone.rotation(bone), PhysicsBone.translation(bone) } do
			for _, v in list do
				if not rt.is_finite(v) then
					bad = true
				end
			end
		end
		if bad then
			rt.raise(string.format("Invalid or repeated stock physics bone %s", bone.name))
		end
	end
	return selected
end

return physics_skeleton
