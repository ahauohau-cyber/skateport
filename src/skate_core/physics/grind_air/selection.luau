--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_air/selection.rs (коммит 2e16697)
--
-- ROBLOX: [f32; 5] -> таблицы, точка p в [p + 1]; Option<usize> -> число или nil;
-- `x as usize` для неотрицательного x -> math.floor(x).

local rt = require("../../../rt")
local targets = require("./targets")

local f32 = rt.f32
local fmin = rt.fmin

type V = { number }

local selection = {}
selection.parent = (nil :: any)

export type Contacts = {
	times: { number },
	distances: { number },
	corrections: { V },
	earliest: number,
}

function selection.contacts(samples: { { V } }, count: number, origin: V, rail: V, normal: V): Contacts
	local P = selection.parent
	local dot, sub, scale, madd, length = P.dot, P.sub, P.scale, P.madd, P.length
	local out: Contacts = {
		times = { -1.0, -1.0, -1.0, -1.0, -1.0 },
		distances = { 0.0, 0.0, 0.0, 0.0, 0.0 },
		corrections = { P.zero(), P.zero(), P.zero(), P.zero(), P.zero() },
		earliest = count,
	}
	for p = 1, 5 do
		for i = 1, count - 1 do
			local a = dot(normal, sub(samples[i][p], origin))
			local b = dot(normal, sub(samples[i + 1][p], origin))
			if f32(a * b) < 0.0 then
				local f = math.abs(f32(a / f32(a - b)))
				local at = madd(samples[i][p], f32(1.0 - f), scale(samples[i + 1][p], f))
				local on = madd(rail, dot(sub(at, origin), rail), origin)
				out.times[p] = f32((i - 1) + f)
				out.corrections[p] = sub(on, at)
				out.distances[p] = length(out.corrections[p])
				out.earliest = fmin(out.earliest, out.times[p])
				break
			end
		end
	end
	return out
end

function selection.choose(c: Contacts, headings: { number }, s: any, inverted: boolean, previous: number?): number?
	local CONTACTS, DESIRED = targets.CONTACTS, targets.DESIRED
	local function valid(kind: number): boolean
		local p = CONTACTS[kind + 1]
		local t = c.times[p + 1]
		if kind == 4 then
			if fmin(c.times[3], c.times[4]) < 4.0 and math.abs(f32(c.times[3] - c.times[4])) > 2.0 then
				return false
			end
		elseif c.earliest < 5.0 and math.abs(f32(c.earliest - t)) > 3.0 then
			return false
		end
		return t > 0.0
			and c.distances[p + 1] < s.distances[kind + 1]
			and math.abs(f32(DESIRED[kind + 1] - math.abs(headings[math.floor(f32(t + 0.5)) + 1]))) < s.ranges[kind + 1]
	end
	local selected: number? = nil
	for k = 0, 6 do
		local kind = k
		if inverted ~= (kind == 0) or not valid(kind) then
			continue
		end
		if kind == 3 then
			if previous ~= nil and (previous == 1 or previous == 2) then
				if valid(previous) then
					kind = previous
				end
			end
		end
		if selected == nil or c.distances[CONTACTS[kind + 1] + 1] < c.distances[CONTACTS[(selected :: number) + 1] + 1] then
			selected = kind
		end
		if selected ~= nil and selected < 5 then
			break
		end
	end
	return selected
end

return selection
