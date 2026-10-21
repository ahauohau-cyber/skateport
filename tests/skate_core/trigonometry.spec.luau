--!strict
-- Сверка core/trigonometry с настоящим skate-core (эталон из golden/).
-- В Rust для этого файла отдельных тестов нет.

local harness = require("../harness")
local rt = require("../../src/rt")
local trigonometry = require("../../src/skate_core/trigonometry")
local golden = require("../golden/trigonometry")

-- Допуск 0 ULP: каждая операция округляется до f32, как в Rust.
-- Записываем фактический разрыв, чтобы видеть его в отчёте.
local MAX_ULP = 0

return function(report: harness.Report)
	local function compare(name: string, cases: { { number } }, call: (number) -> number)
		harness.test(report, "trigonometry: " .. name .. " vs Rust", function()
			local stats = harness.stats()
			for _, case in cases do
				local actual = call(rt.from_bits(case[1]))
				harness.record(stats, case[1], actual, case[2])
			end
			table.insert(report.lines, "      " .. name .. ": " .. harness.describe(stats))
			harness.check(stats.max_ulp <= MAX_ULP, name .. ": " .. harness.describe(stats))
		end)
	end

	harness.test(report, "trigonometry: sin_cos vs Rust", function()
		local s, c = harness.stats(), harness.stats()
		for _, case in golden.sin_cos do
			local sn, cs = trigonometry.sin_cos(rt.from_bits(case[1]))
			harness.record(s, case[1], sn, case[2])
			harness.record(c, case[1], cs, case[3])
		end
		table.insert(report.lines, "      sin_cos.sin: " .. harness.describe(s))
		table.insert(report.lines, "      sin_cos.cos: " .. harness.describe(c))
		harness.check(s.max_ulp <= MAX_ULP and c.max_ulp <= MAX_ULP, "sin_cos ulp")
	end)
	compare("sin", golden.sin, trigonometry.sin)
	compare("cos", golden.cos, trigonometry.cos)
	compare("asin", golden.asin, trigonometry.asin)
	compare("acos", golden.acos, trigonometry.acos)
end
