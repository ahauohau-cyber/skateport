--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/constraint_batch.rs (коммит 2e16697)
--
-- Joint/drive batch eligibility: TU3 82AE39D0 and 82AE1778.
--
-- Native clears the output counts, traverses the registered list in order,
-- and compiles a row only when at least one endpoint has state bit 4. This
-- does not register, wake, freeze or reorder bodies.

local constraint_batch = {}

-- pub fn compile_active<T, R>(registered, endpoint_states, compile) -> Vec<R>
-- ROBLOX: endpoint_states возвращает два состояния (a, b).
function constraint_batch.compile_active<T, R>(registered: { T }, endpoint_states: (T) -> (number, number), compile: (T) -> R): { R }
	local out = {}
	for _, constraint in registered do
		local a, b = endpoint_states(constraint)
		if bit32.band(bit32.bor(a, b), 4) ~= 0 then
			table.insert(out, compile(constraint))
		end
	end
	return out
end

return constraint_batch
