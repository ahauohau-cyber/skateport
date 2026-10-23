--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_contact/investigator.rs (коммит 2e16697)
--
-- Family/proximity arbitration from S3 82D875A8.
-- Geometry refinement and balance/engagement run afterward in the manager.
-- ROBLOX: `use super::*` -> investigator.parent (ставит grind_contact/init.luau);
-- замыкания `|| ...` + or_else -> локальные функции, вызываемые по очереди.

local admission = require("./admission")
local families = require("./families")

local test = admission.Admission.test

type V = { number }
type TruckContact = { position: V, primitive: number }
type Hit = TruckContact | false

local investigator = {}
investigator.parent = (nil :: any)

local rt = require("../../../rt")
local rt_i32 = rt.to_i32 -- ROBLOX: `low_wheel_frames as i32` (u32 -> i32 с переносом знака).

export type Query = {
	board: { V },
	admission: admission.Admission,
	flags_2468: number,
	flags_2472: number,
	flags_2476: number,
	flags_2484: number,
	tip_state: number,
	truck_to_wheel: number,
	deck_to_truck: number,
	test_above: number,
	test_below: number,
	translation: number,
	stability_nudge: number,
	balance: number,
	reference_right: V,
	ground_frames: number,
	low_wheel_frames: number,
	-- Grind permission OR retained70-frame exclusion while published kind!=2.
	forbidden: boolean,
}

export type Proximity = {
	contact: TruckContact,
	-- Investigator412 bit26: deck/inverted rather than truck contact.
	deck_contact: boolean,
}

export type Investigation = {
	candidate: families.Contact?,
	-- Only the fallback path sets412 bit27. It does not authorize a grind.
	proximity: Proximity?,
}

local function fallback(trucks: { Hit }, deck: TruckContact?, inverted: TruckContact?, tips: { Hit }): Proximity?
	-- 82D87D24 short-circuits: v82 becomes1 only on an actual deck hit.
	local t = trucks[1] or trucks[2]
	if t then
		return { contact = t, deck_contact = false }
	end
	if deck then
		return { contact = deck, deck_contact = true }
	end
	local other = inverted or tips[1] or tips[2]
	if other then
		return { contact = other, deck_contact = false }
	end
	return nil
end

-- ROBLOX: приватная fn fallback открыта для переноса Rust-тестов.
investigator.fallback = fallback

-- `edges` is already the native bounded query result, in its selection order.
-- ROBLOX: Investigation::default() -> { candidate = nil, proximity = nil }.
function investigator.investigate(query: Query, edges: { any }): Investigation
	if #edges == 0 then
		return { candidate = nil, proximity = nil }
	end
	local P = investigator.parent
	local q = query
	local a = q.admission
	local trucks = P.truck_contacts(q.board, q.flags_2484, q.truck_to_wheel, q.deck_to_truck, edges)
	local tips = families.tip_contacts(q.board, q.flags_2484, q.tip_state, q.flags_2468, q.deck_to_truck, edges)
	local deck = P.deck_contact(q.board, q.flags_2484, q.test_above, q.test_below, q.deck_to_truck, edges)
	local inverted = families.inverted_contact(q.board, q.flags_2484, q.test_above, q.test_below, edges)

	if not q.forbidden then
		local function fifty(): families.Contact?
			local geometry = P.fifty_fifty_candidate_on_splines(q.board, { q.translation, q.stability_nudge }, trucks, edges)
			if geometry == nil then
				return nil
			end
			local decision = test(a, 401, geometry.direction, false)
			if not decision.allowed then
				return nil
			end
			return { geometry = geometry, front = false, kind = 0, entry_kind = decision.kind }
		end
		local function five(): families.Contact?
			return families.five_o(q.board, trucks, edges, a.velocity, q.flags_2476, q.flags_2472, q.ground_frames, q.translation, a)
		end
		local function tip(): families.Contact?
			return families.tipslide(q.board, tips, edges, a.velocity, a.category, q.flags_2476, q.flags_2472, q.ground_frames, q.balance, q.reference_right, a)
		end
		local function slide(): families.Contact?
			local hit = deck
			if hit == nil then
				return nil
			end
			local geometry = P.boardslide_candidate(q.board, hit, edges[hit.primitive + 1], a.velocity, a.category, rt_i32(q.low_wheel_frames), q.flags_2476, q.deck_to_truck, q.truck_to_wheel, a)
			if geometry == nil then
				return nil
			end
			return { geometry = geometry, front = false, kind = 1, entry_kind = test(a, 400, geometry.direction, false).kind }
		end
		local function dark(): families.Contact?
			local hit = inverted
			if hit == nil then
				return nil
			end
			return families.darkslide(q.board, hit, edges[hit.primitive + 1], a.velocity, a.category, q.low_wheel_frames, a)
		end
		-- The original retries the truck family as 50-50 first, even in403.
		local retained: families.Contact? = nil
		local state = a.state
		if state == 401 or state == 403 then
			retained = fifty() or five()
		elseif state == 402 or state == 404 then
			retained = tip()
		elseif state == 400 then
			retained = slide()
		elseif state == 405 then
			retained = dark()
		end
		local candidate = retained or fifty() or five() or tip() or slide() or dark()
		if candidate then
			return { candidate = candidate, proximity = nil }
		end
	end
	-- 82D87C5C..82D87E60: keep contact-only metadata even when entry is denied.
	local proximity = fallback(trucks, deck, inverted, tips)
	return { candidate = nil, proximity = proximity }
end

return investigator
