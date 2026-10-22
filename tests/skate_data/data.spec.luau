--!strict
-- Сверка skate_data (attrib_hash, collections) с настоящим skate-data (golden/src/data.rs).

local harness = require("../harness")
local rt = require("../../src/rt")
local attrib_hash = require("../../src/skate_data/attrib_hash")
local collections = require("../../src/skate_data/collections")
local golden = require("../golden/data")

local Collections = collections.Collections

return function(report: harness.Report)
	harness.test(report, "attrib_hash: hash / numeric_name vs Rust", function()
		local bad = 0
		for _, case in golden.hash do
			local hi, lo = attrib_hash.hash(case[1])
			if hi ~= case[2] or lo ~= case[3] or attrib_hash.numeric_name(case[1]) ~= case[4] then
				bad += 1
			end
		end
		table.insert(report.lines, string.format("      hash: %d строк, расхождений %d", #golden.hash, bad))
		harness.check(bad == 0, "hash mismatch")
	end)

	harness.test(report, "collections: настройки из skater-collections.json vs Rust", function()
		local ok, stock = pcall(require, "../../src/skate_data/stock")
		if not ok then
			table.insert(report.lines, "      пропуск: нет src/skate_data/stock (сгенерируй tools/stock_collections.py)")
			return
		end
		local data = collections.expect(Collections.from_data(stock :: any))
		for _, case in golden.values do
			local kind, class, field, want = case[1], case[2], case[3], case[4]
			if kind == "float" then
				local v = collections.expect(Collections.float(data, class, "default", field))
				harness.check(rt.to_bits(v) == want, class .. "/" .. field)
			elseif kind == "bool" then
				harness.check(collections.expect(Collections.boolean(data, class, "default", field)) == want, class .. "/" .. field)
			elseif kind == "int" then
				harness.check(collections.expect(Collections.integer(data, class, "default", field)) == want, class .. "/" .. field)
			else
				local w = collections.expect(Collections.words(data, class, "default", field, 4))
				for i = 1, 4 do
					harness.check(w[i] == want[i], class .. "/" .. field)
				end
			end
		end
		-- читаемое имя и хеш-имя указывают на одно поле
		local a = Collections.field(data, "physicswheels", "default", "WheelRadius")
		local b = Collections.field(data, attrib_hash.numeric_name("physicswheels"), "default", attrib_hash.numeric_name("WheelRadius"))
		harness.check(a ~= nil and a == b, "numeric names")
		harness.check(select(2, Collections.field(data, "physicswheels", "default", "NoSuchField")) ~= nil, "missing field error")
	end)
end
