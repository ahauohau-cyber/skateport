--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/graph/expression.rs (коммит 2e16697)
--
-- TU3 ExpressionOperator::GetActivationMasked (82C12508).
-- Excluded children do not participate in AND/OR/NOT. Preserve lazy calls:
-- condition operations may read or modify their own instance state.

local expression = {}

-- ParseOperator 82C12438: case-sensitive strings, zero for missing/unknown.
function expression.parse_operator(name: string?): number
	if name == "and" then
		return 1
	elseif name == "or" then
		return 2
	elseif name == "not" then
		return 3
	end
	return 0
end

-- ROBLOX: &mut u8 -> ячейка { value = number }.
export type Cell = { value: number }

-- Execute the complete operator with the native virtual child-call boundary.
-- The callback receives its ordered child index (с нуля) and the initially true
-- excluded byte; it returns the native result word. Context/mask are supplied
-- by the caller's closure, without an invented default condition result.
-- NOT requires a first child, as in the native caller contract.
function expression.evaluate_operator(operator: number, child_count: number, excluded: Cell, child: (number, Cell) -> number): number
	if operator > 3 then
		return 1 -- Native default leaves the caller's excluded byte untouched.
	end
	if operator == 3 then
		assert(child_count > 0, "stock NOT expression requires a child")
		local child_excluded = { value = 1 }
		local value = bit32.band(child(0, child_excluded), 255)
		excluded.value = child_excluded.value
		if child_excluded.value ~= 0 then
			return 1
		end
		return if value == 0 then 1 else 0
	end
	local is_or = operator == 2
	local value = if is_or then 0 else 1
	local all_excluded = 1
	for index = 0, child_count - 1 do
		local low = bit32.band(value, 255)
		if (is_or and low ~= 0) or (not is_or and low == 0) then
			break
		end
		local child_excluded = { value = 1 }
		local result = child(index, child_excluded)
		if child_excluded.value == 0 then
			all_excluded = 0
			value = if is_or then result else bit32.band(bit32.band(result, 255), low)
		end
	end
	excluded.value = all_excluded
	return if all_excluded ~= 0 then 1 else value
end

return expression
