--!nocheck
-- Мини-эмулятор Roblox для Lune: дерево ModuleScript из папок (правила Rojo),
-- require(instance), game:GetService, HttpService (JSON), EncodingService (zstd).
-- Нужен, чтобы гонять sim (vendor/sim) и нашу обвязку без Studio.
-- Запуск: lune run tools/emu/<скрипт>.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")

local emu = {}

local Instance = {}
Instance.__index = function(self, key)
	local method = Instance[key]
	if method ~= nil then
		return method
	end
	for _, c in rawget(self, "_children") do
		if c.Name == key then
			return c
		end
	end
	return nil
end

local function new_instance(class: string, name: string, parent)
	local self = setmetatable({ ClassName = class, Name = name, Parent = parent, _children = {}, _attributes = {} }, Instance)
	if parent then
		table.insert(parent._children, self)
	end
	return self
end
emu.new_instance = new_instance

function Instance:GetChildren()
	return table.clone(self._children)
end
function Instance:GetDescendants()
	local out = {}
	local function walk(i)
		for _, c in i._children do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function Instance:FindFirstChild(name: string)
	for _, c in self._children do
		if c.Name == name then
			return c
		end
	end
	return nil
end
function Instance:WaitForChild(name: string)
	local c = self:FindFirstChild(name)
	if c == nil then
		error("WaitForChild: no " .. name .. " under " .. self:GetFullName(), 2)
	end
	return c
end
function Instance:IsA(class: string)
	if class == "LuaSourceContainer" then
		return self.ClassName == "ModuleScript" or self.ClassName == "Script" or self.ClassName == "LocalScript"
	end
	return self.ClassName == class or class == "Instance"
end
function Instance:GetFullName()
	local parts = {}
	local i = self
	while i ~= nil and i.ClassName ~= "DataModel" do
		table.insert(parts, 1, i.Name)
		i = i.Parent
	end
	return table.concat(parts, ".")
end
function Instance:IsDescendantOf(other)
	local i = self.Parent
	while i ~= nil do
		if i == other then
			return true
		end
		i = i.Parent
	end
	return false
end
function Instance:GetAttribute(name: string)
	return self._attributes[name]
end
function Instance:SetAttribute(name: string, value)
	self._attributes[name] = value
end
function Instance:FindFirstAncestorOfClass(class: string)
	local i = self.Parent
	while i ~= nil do
		if i.ClassName == class then
			return i
		end
		i = i.Parent
	end
	return nil
end

-- Папка -> дерево (как Rojo: init.luau делает папку ModuleScript).
function emu.mount(parent, name: string, dir: string, skip: { [string]: boolean }?)
	local init = dir .. "/init.luau"
	local node
	if fs.isFile(init) then
		node = new_instance("ModuleScript", name, parent)
		node._path = init
	else
		node = new_instance("Folder", name, parent)
	end
	local entries = fs.readDir(dir)
	table.sort(entries)
	for _, entry in entries do
		if skip and skip[entry] then
			continue
		end
		local path = dir .. "/" .. entry
		if fs.isDir(path) then
			emu.mount(node, entry, path)
		elseif entry ~= "init.luau" and string.sub(entry, -5) == ".luau" then
			local m = new_instance("ModuleScript", string.sub(entry, 1, -6), node)
			m._path = path
		end
	end
	return node
end

emu.DataModel = new_instance("DataModel", "game", nil)
local services = {}
local function service(name: string)
	local s = services[name]
	if s == nil then
		s = new_instance(name, name, emu.DataModel)
		services[name] = s
	end
	return s
end

local HttpService = service("HttpService")
function HttpService:JSONDecode(text: string)
	return serde.decode("json", text)
end
function HttpService:JSONEncode(value)
	return serde.encode("json", value)
end

local EncodingService = service("EncodingService")
function EncodingService:Base64Decode(b: buffer)
	local text = buffer.tostring(b)
	-- Lune: base64 через serde нет, раскодируем сами.
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local map = {}
	for i = 1, 64 do
		map[string.byte(alphabet, i)] = i - 1
	end
	local out = buffer.create(#text * 3 // 4 + 3)
	local n, acc, bits = 0, 0, 0
	for i = 1, #text do
		local v = map[string.byte(text, i)]
		if v ~= nil then
			acc = bit32.bor(bit32.lshift(acc, 6), v)
			bits += 6
			if bits >= 8 then
				bits -= 8
				buffer.writeu8(out, n, bit32.band(bit32.rshift(acc, bits), 0xff))
				n += 1
			end
		end
	end
	local result = buffer.create(n)
	buffer.copy(result, 0, out, 0, n)
	return result
end
function EncodingService:DecompressBuffer(b: buffer, _algorithm)
	return buffer.fromstring(serde.decompress("zstd", buffer.tostring(b)))
end

function emu.DataModel:GetService(name: string)
	return service(name)
end
emu.service = service

emu.Enum = {
	CompressionAlgorithm = { Zstd = "Zstd" },
}

local cache = {}
local loading = {}
local env_globals

local function require_instance(target)
	if type(target) == "string" then
		error("emu: require по строке не поддержан: " .. target, 2)
	end
	local hit = cache[target]
	if hit ~= nil then
		return hit[1]
	end
	if target._path == nil then
		error("emu: " .. target:GetFullName() .. " не ModuleScript", 2)
	end
	if loading[target] then
		error("emu: цикл require через " .. target:GetFullName(), 2)
	end
	loading[target] = true
	local source = fs.readFile(target._path)
	local env = { script = target }
	for k, v in env_globals do
		env[k] = v
	end
	local chunk = luau.load(source, { debugName = target:GetFullName(), environment = env, injectGlobals = true, codegenEnabled = true })
	local result = chunk()
	if emu.on_module then
		result = emu.on_module(target, result)
	end
	loading[target] = nil
	cache[target] = { result }
	return result
end
emu.require = require_instance

env_globals = {
	game = emu.DataModel,
	require = require_instance,
	Enum = emu.Enum,
	Vector3 = { new = vector.create, zero = vector.zero, one = vector.one },
	warn = function(...) print("[warn]", ...) end,
	task = { wait = function() end, defer = function(f, ...) f(...) end, spawn = function(f, ...) f(...) end },
}
emu.globals = env_globals

return emu
