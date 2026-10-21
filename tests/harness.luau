--!strict
-- ROBLOX: маленький тест-раннер. Работает и в Luau CLI, и в Studio.
-- Заменяет #[test] из Rust: тест = функция, ошибка = провал.

local rt = require("../src/rt")

local harness = {}

export type Report = { passed: number, failed: number, lines: { string } }

function harness.new(): Report
	return { passed = 0, failed = 0, lines = {} }
end

function harness.test(report: Report, name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		report.passed += 1
		table.insert(report.lines, "ok    " .. name)
	else
		report.failed += 1
		table.insert(report.lines, "FAIL  " .. name .. ": " .. tostring(err))
	end
end

-- assert_eq! для чисел. NaN == NaN считаем равными, знак нуля проверяем.
function harness.eq(actual: number, expected: number, label: string?)
	local same = actual == expected
		or (actual ~= actual and expected ~= expected)
	if same and actual == 0 and expected == 0 then
		same = (1 / actual > 0) == (1 / expected > 0)
	end
	if not same then
		error(string.format("%s: %s ~= %s", label or "assert_eq", tostring(actual), tostring(expected)), 2)
	end
end

function harness.check(condition: boolean, label: string?)
	if not condition then
		error(label or "assertion failed", 2)
	end
end

-- Расстояние в ULP между двумя f32 (по битам). Для NaN-пары — 0.
local function ordered(bits: number): number
	if bits >= 0x8000_0000 then
		return 0x8000_0000 - bits
	end
	return bits
end

function harness.ulp(actual: number, expected_bits: number): number
	local actual_bits = rt.to_bits(actual)
	local expected = rt.from_bits(expected_bits)
	if actual ~= actual and expected ~= expected then
		return 0
	end
	return math.abs(ordered(actual_bits) - ordered(expected_bits))
end

-- Сверка с эталоном Rust: сколько совпало бит в бит и максимальный разрыв в ULP.
export type Stats = { total: number, exact: number, max_ulp: number, worst_input: number }

function harness.stats(): Stats
	return { total = 0, exact = 0, max_ulp = 0, worst_input = 0 }
end

function harness.record(stats: Stats, input_bits: number, actual: number, expected_bits: number)
	local d = harness.ulp(actual, expected_bits)
	stats.total += 1
	if d == 0 then
		stats.exact += 1
	end
	if d > stats.max_ulp then
		stats.max_ulp = d
		stats.worst_input = input_bits
	end
end

function harness.describe(stats: Stats): string
	return string.format(
		"%d/%d бит в бит, макс. %d ULP (вход 0x%08x)",
		stats.exact,
		stats.total,
		stats.max_ulp,
		stats.worst_input
	)
end

function harness.print(report: Report)
	for _, line in report.lines do
		print(line)
	end
	print(string.format("итого: %d прошло, %d упало", report.passed, report.failed))
end

return harness
