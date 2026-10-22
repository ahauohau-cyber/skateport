--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/collections.rs (коммит 2e16697)
--
-- Typed access to converted stock skater XML values, without engine objects.
-- ROBLOX: вместо чтения JSON с диска (Collections::load) данные приходят
-- готовой таблицей из модулей skate_data/stock (их собирает
-- tools/stock_collections.py из skater-collections.json). Result -> (значение)
-- или (nil, ошибка).

local rt = require("../rt")
local attrib_hash = require("./attrib_hash")

local numeric_name = attrib_hash.numeric_name

local collections = {}

export type FieldArray = { text_items: { string } }

export type Field = {
	type_name: string,
	data: string,
	-- An array field's elements (`data` holds the count).
	array: FieldArray?,
}

export type Collection = {
	class_name: string,
	key: string,
	parent: string,
	fields: { [string]: Field },
	source: string,
	sha256: string,
}

export type Collections = {
	version: number,
	collections: { Collection },
	-- (numeric class, numeric key) -> index of the FIRST matching entry, i.e.
	-- exactly what a linear scan in vector order finds. Built on first lookup,
	-- reset by every mutation.
	index: { [string]: number }?,
}

local Collections = {}
collections.Collections = Collections

-- ROBLOX: замена Collections::load — проверка версии и дубликатов.
function Collections.from_data(data: { version: number, collections: { Collection } }): (Collections?, string?)
	if data.version ~= 1 then
		return nil, string.format("Unsupported skater collections version %d", data.version)
	end
	local identities: { [string]: boolean } = {}
	for _, item in data.collections do
		local id = numeric_name(item.class_name) .. "/" .. numeric_name(item.key)
		if identities[id] then
			return nil, string.format("Duplicate collection %s/%s", item.class_name, item.key)
		end
		identities[id] = true
	end
	return { version = data.version, collections = data.collections, index = nil }, nil
end

local function entry(self: Collections, class_id: string, key_id: string): Collection?
	local index = self.index
	if index == nil then
		local built: { [string]: number } = {}
		for position, item in self.collections do
			local id = numeric_name(item.class_name) .. "/" .. numeric_name(item.key)
			if built[id] == nil then
				built[id] = position
			end
		end
		self.index = built
		index = built
	end
	local position = (index :: { [string]: number })[class_id .. "/" .. key_id]
	return if position then self.collections[position] else nil
end

function Collections.entries(self: Collections): { Collection }
	return self.collections
end

-- Replace one profile with a child of a base profile, without editing assets.
function Collections.override_profile(
	self: Collections,
	class: string,
	target: string,
	base: string,
	fields: { [string]: Field }
): (boolean?, string?)
	local id = numeric_name(class)
	local base_id = numeric_name(base)
	local found = false
	for _, c in self.collections do
		if numeric_name(c.class_name) == id and numeric_name(c.key) == base_id then
			found = true
			break
		end
	end
	if not found then
		return nil, "Missing base profile"
	end
	local target_id = numeric_name(target)
	local kept = {}
	for _, c in self.collections do
		if not (numeric_name(c.class_name) == id and numeric_name(c.key) == target_id) then
			table.insert(kept, c)
		end
	end
	table.insert(kept, {
		class_name = class,
		key = target,
		parent = base,
		fields = fields,
		source = "host custom profile",
		sha256 = "",
	})
	self.collections = kept
	self.index = nil
	return true, nil
end

function Collections.field(self: Collections, class: string, key: string, name: string): (Field?, string?)
	-- Converted vaults can retain numeric identities when debug names were
	-- unavailable. Both spellings identify the same native AttribSys entry.
	local class_id = numeric_name(class)
	local field_id = numeric_name(name)
	local current = key
	-- ROBLOX: Rust `for _ in 0..=len` — len + 1 проходов.
	for _ = 1, #self.collections + 1 do
		local item = entry(self, class_id, numeric_name(current))
		if item == nil then
			return nil, string.format("Missing stock collection %s/%s", class, current)
		end
		local field = item.fields[name]
		if field == nil then
			-- ROBLOX: BTreeMap обходит ключи по порядку; первый совпавший по хешу.
			local names: { string } = {}
			for k: string in item.fields do
				table.insert(names, k)
			end
			table.sort(names)
			for _, k in names do
				if numeric_name(k) == field_id then
					field = item.fields[k]
					break
				end
			end
		end
		if field ~= nil then
			return field, nil
		end
		if item.parent == "" then
			return nil, string.format("Missing stock field %s/%s/%s", class, key, name)
		end
		current = item.parent
	end
	return nil, string.format("Cyclic stock collection inheritance %s/%s", class, key)
end

local function decode_words(text: string, n: number): ({ number }?, string?)
	local hex = string.gsub(text, "%s", "")
	if #hex ~= n * 8 or string.find(hex, "[^%x]") then
		return nil, string.format("Expected %d big-endian words, found %d bytes of hex", n, #hex)
	end
	local words = {}
	for i = 0, n - 1 do
		words[i + 1] = tonumber(string.sub(hex, i * 8 + 1, i * 8 + 8), 16) :: number
	end
	return words, nil
end

function Collections.float(self: Collections, class: string, key: string, name: string): (number?, string?)
	local field, err = Collections.field(self, class, key, name)
	if field == nil then
		return nil, err
	end
	if field.type_name ~= "EA::Reflection::Float" then
		return nil, string.format("Expected float at %s/%s/%s", class, key, name)
	end
	local words, werr = decode_words(field.data, 1)
	if words == nil then
		return nil, werr
	end
	local value = rt.from_bits(words[1])
	if not rt.is_finite(value) then
		return nil, string.format("Non-finite stock float %s/%s/%s", class, key, name)
	end
	return value, nil
end

function Collections.integer(self: Collections, class: string, key: string, name: string): (number?, string?)
	local field, err = Collections.field(self, class, key, name)
	if field == nil then
		return nil, err
	end
	if field.type_name ~= "EA::Reflection::Int32" and field.type_name ~= "EA::Reflection::UInt32" then
		return nil, string.format("Expected integer at %s/%s/%s", class, key, name)
	end
	local words, werr = decode_words(field.data, 1)
	if words == nil then
		return nil, werr
	end
	return words[1], nil
end

function Collections.boolean(self: Collections, class: string, key: string, name: string): (boolean?, string?)
	local field, err = Collections.field(self, class, key, name)
	if field == nil then
		return nil, err
	end
	if field.type_name ~= "EA::Reflection::Bool" then
		return nil, string.format("Expected boolean at %s/%s/%s", class, key, name)
	end
	-- Attributes store the byte followed by padding; layout bools may
	-- contain only the byte. Reading a big-endian u32 gives the wrong bit.
	local head = string.sub(field.data, 1, 2)
	if head == "00" then
		return false, nil
	elseif head == "01" then
		return true, nil
	end
	return nil, string.format("Invalid stock boolean %s/%s/%s", class, key, name)
end

-- pub fn words<const N: usize>(...) -> Result<[u32; N], String>
function Collections.words(self: Collections, class: string, key: string, name: string, n: number): ({ number }?, string?)
	local field, err = Collections.field(self, class, key, name)
	if field == nil then
		return nil, err
	end
	return decode_words(field.data, n)
end

-- ROBLOX: удобная обёртка — значение или ошибка Luau (как `?` в Rust,
-- когда вызывающий сам возвращает Result).
function collections.expect<T>(value: T?, err: string?): T
	if value == nil then
		error(err or "missing stock value", 2)
	end
	return value
end

return collections
