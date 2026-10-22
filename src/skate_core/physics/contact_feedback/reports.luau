--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/contact_feedback/reports.rs (коммит 2e16697)

local rt = require("../../../rt")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits

local reports = {}

-- Registered target for a rigid-body pointer (Island+80 lookup).
export type ContactTarget = { body: number, owner: number, tag: number }

-- Supplied storage preserves every unwritten byte when records are reused.
-- ROBLOX: records [[u8; 96]; 16] -> 16 буферов по 96 байт.
export type ContactReportBuffer = { count: number, records: { buffer } }

-- Container/locking boundary of 827682B0. The map operation inserts an absent
-- Body key; clearing resets existing vector ends without erasing keys/storage.
-- ROBLOX: трейт -> таблица с методами; Option -> значение или nil.
export type ContactReportBackend = {
	lock: (self: any) -> (),
	clear_report_counts: (self: any) -> (),
	lookup_target: (self: any, rigid_body: number) -> ContactTarget?,
	get_or_insert_reports: (self: any, body: number) -> number,
	reports: (self: any, handle: number) -> ContactReportBuffer,
	linear_velocity: (self: any, rigid_body: number) -> { number },
	unlock: (self: any) -> (),
}

-- Live tree traversal and Body virtual+8 dispatch boundary of 827685C8.
export type ContactReportDispatchBackend = {
	first_report_entry: (self: any) -> number?,
	next_report_entry: (self: any, handle: number) -> number?,
	report_count: (self: any, handle: number) -> number,
	dispatch_reports: (self: any, handle: number) -> (),
}

-- Complete 82768250 lookup lifetime: lock, operator[] (possibly inserts),
-- unlock, return the live vector handle. No detached report copy is produced.
function reports.get_contact_reports(body: number, backend: ContactReportBackend): number
	backend:lock()
	local handle = backend:get_or_insert_reports(body)
	backend:unlock()
	return handle
end

-- Complete 827685C8. Visits every map entry, invokes only nonempty live vectors,
-- and performs no list clearing or local locking around callbacks.
function reports.resolve_contact_reports(backend: ContactReportDispatchBackend)
	local entry = backend:first_report_entry()
	while entry ~= nil do
		if backend:report_count(entry) ~= 0 then
			backend:dispatch_reports(entry)
		end
		entry = backend:next_report_entry(entry)
	end
end

local function put(record: buffer, offset: number, value: number)
	buffer.writeu32(record, offset, bit32.byteswap(value))
end

-- Complete 827682B0 report construction/filter/order, with its native map and
-- lock operations supplied by the backend. `spy_base` retains native pointer
-- identity; reports borrow that simulation storage through the consuming phase.
-- ROBLOX: spies — таблица записей по 28 слов (слово k в [k + 1]).
function reports.create_contact_reports(spies: { { number } }, spy_base: number, backend: ContactReportBackend)
	backend:lock()
	backend:clear_report_counts()
	for index0, spy in spies do
		local index = index0 - 1
		local a = backend:lookup_target(spy[25])
		local b = backend:lookup_target(spy[26])
		local a_body = if a then a.body else 0
		local b_body = if b then b.body else 0
		local a_owner = if a then a.owner else 0
		local b_owner = if b then b.owner else 0
		local same_body = a ~= nil and b ~= nil and a_body == b_body
		local excluded = same_body or (a_owner ~= 0 and a_owner == b_owner)
		for _, item in { { a, true }, { b, false } } do
			local target = item[1] :: ContactTarget?
			local is_a = item[2] :: boolean
			if target ~= nil then
				-- Native operator[] runs even for a subsequently excluded pair.
				local handle = backend:get_or_insert_reports(target.body)
				local count = backend:reports(handle).count
				if not (count >= 16 or excluded) then
					local other = if is_a then spy[26] else spy[25]
					local this = if is_a then spy[25] else spy[26]
					local ov = backend:linear_velocity(other)
					local tv = backend:linear_velocity(this)
					local normal, relative = {}, {}
					for i = 1, 4 do
						normal[i] = to_bits(f32(from_bits(spy[i]) * (if is_a then 1.0 else -1.0)))
						relative[i] = to_bits(f32(from_bits(tv[i]) - from_bits(ov[i])))
					end
					local buf = backend:reports(handle)
					local record = buf.records[count + 1]
					put(record, 0, rt.wrapping_add_u32(spy_base, rt.wrapping_mul_u32(index, 112)))
					for i = 0, 3 do
						put(record, 16 + i * 4, normal[i + 1])
						put(record, 32 + i * 4, spy[12 + i + 1])
						put(record, 48 + i * 4, relative[i + 1])
					end
					put(record, 64, target.tag)
					put(record, 68, if is_a then bit32.band(spy[27], 0xffff) else bit32.rshift(spy[27], 16))
					put(record, 72, target.body)
					put(record, 76, if is_a then b_body else a_body)
					buffer.writeu8(record, 80, 0)
					buffer.writeu8(record, 81, if is_a then 1 else 0)
					buf.count += 1
				end
			end
		end
	end
	backend:unlock()
end

return reports
