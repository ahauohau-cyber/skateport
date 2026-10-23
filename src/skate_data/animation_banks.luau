--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/animation_banks.rs (коммит 2e16697)
--
-- Own both stock skater banks once. Clip/tree names are disjoint; poses retain
-- their bank identity because the banks share several reference-pose names.
-- ROBLOX: Arc<Bank> -> общая таблица; файлы — из files.luau.

local rt = require("../rt")
local abin = require("./abin")
local animation_metadata = require("./animation_metadata")
local files = require("./files")
local sha256 = require("./sha256")

local Bank = abin.Bank
local AnimationMetadata = animation_metadata.AnimationMetadata

local animation_banks = {}

export type AnimationBanks = {
	banks: { any },
	identities: { string },
}

local AnimationBanks = {}
animation_banks.AnimationBanks = AnimationBanks

function AnimationBanks.load(): AnimationBanks
	local banks, identities = {}, {}
	for _, name in { "OnBoard", "OffBoard" } do
		local bank, err = rt.catch(function()
			return Bank.parse(files.read(string.format("stock/data/anim/%s.abin", name)))
		end)
		if err ~= nil then
			rt.raise(string.format("%s: %s", name, abin.error_to_string(err)))
		end
		local _, verr = rt.catch(Bank.validate_positional_parts, bank)
		if verr ~= nil then
			rt.raise(abin.error_to_string(verr))
		end
		table.insert(identities, sha256.digest(Bank.bytes(bank)))
		table.insert(banks, bank)
	end
	local first = Bank.hierarchy(banks[1])
	if first == nil then
		rt.raise("OnBoard has no animation hierarchy")
	end
	local second = Bank.hierarchy(banks[2])
	if second == nil then
		rt.raise("OffBoard has no animation hierarchy")
	end
	if not abin.hierarchy_compatible_with(first, second) then
		rt.raise("Skater animation bank hierarchies differ")
	end
	return { banks = banks, identities = identities }
end

function AnimationBanks.metadata(self: AnimationBanks): animation_metadata.AnimationMetadata
	local result = AnimationMetadata.from_bank(self.banks[1], "OnBoard.abin", self.identities[1])
	AnimationMetadata.merge(result, AnimationMetadata.from_bank(self.banks[2], "OffBoard.abin", self.identities[2]))
	return result
end

return animation_banks
