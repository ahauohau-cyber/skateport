--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_pose/part.rs (коммит 2e16697)

local rt = require("../../../rt")
local a = require("./arithmetic")
local normalization = require("./normalization")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits

local part = {}

-- Explicit referenced records for a native 96-byte Part. Optional fields model
-- the actual null-pointer branches; callers own loading and activation policy.
-- ROBLOX: PoseMatrix = [u32; 16], body = [u32; 44], inertia = [u32; 10] — таблицы слов.
export type PartPose = {
	transform: { number },
	-- Record addressed by Part+68 (the local mass-frame transform).
	local_mass_frame: { number }?,
	body: { number }?,
	inertia: { number }?,
}

local function load(w: { number }, off: number): a.V
	return { from_bits(w[off + 1]), from_bits(w[off + 2]), from_bits(w[off + 3]), from_bits(w[off + 4]) }
end

local function store_xyz(w: { number }, off: number, v: a.V)
	for i = 1, 3 do
		w[off + i] = to_bits(v[i])
	end
end

local function quaternion(m: a.M): a.V
	local ri, up, at = m[1], m[2], m[3]
	-- Sign masks are initialized by TU3 82F83360/90/C0, not image defaults.
	local rx = { ri[1], ri[1], -ri[1], -ri[1] }
	local uy = { up[2], -up[2], up[2], -up[2] }
	local az = { at[3], -at[3], -at[3], at[3] }
	local first = a.add(rx, uy)
	local d = a.add(first, a.add(az, a.splat(1.0)))
	local inv = { a.rsqrt(d[1]), a.rsqrt(d[2]), a.rsqrt(d[3]), a.rsqrt(d[4]) }
	local roots = a.mul(d, inv)
	local halves = a.mul(a.splat(0.5), inv)
	local pa = { up[3], at[1], ri[2], 0.5 }
	local pb = { at[2], ri[3], up[1], 0.0 }
	local minus = a.sub(pa, pb)
	local plus = a.add(pa, pb)
	local y = a.mul({ plus[3], minus[4], plus[1], minus[2] }, { halves[3], roots[3], halves[3], halves[3] })
	local z = a.mul({ plus[2], plus[1], minus[4], minus[3] }, { halves[4], halves[4], roots[4], halves[4] })
	local x = a.mul({ minus[4], plus[3], plus[2], minus[1] }, { roots[2], halves[2], halves[2], halves[2] })
	local w = a.mul(minus, { halves[1], halves[1], halves[1], roots[1] })
	local yz = if up[2] > at[3] then y else z
	local xyz = if ri[1] > up[2] and ri[1] > at[3] then x else yz
	return a.normalize(if f32(first[1] + at[3]) > 0.0 then w else xyz, true)
end

-- 82585CB0: return the Part transform from its body, or its cached part matrix
-- if no body exists. This is not the whole game Body::GetPosition method.
function part.part_transform(p: PartPose): { number }
	local body = p.body
	if body == nil then
		return p.transform
	end
	local m = { load(body, 16), load(body, 20), load(body, 24), load(body, 4) }
	if p.local_mass_frame ~= nil then
		return a.words(a.compose(m, a.matrix(p.local_mass_frame)))
	end
	return a.words(m)
end

-- 82BD4318: update a live body's pose/caches, then always copy the original
-- requested matrix to the part. Velocity, forces and other packed lanes survive.
-- ROBLOX: `&mut PartPose` — таблица меняется на месте.
function part.set_part_transform(p: PartPose, requested: { number })
	local body = p.body
	if body ~= nil then
		local mw = if p.local_mass_frame ~= nil
			then a.words(a.compose(a.matrix(requested), a.inverse_rigid(a.matrix(p.local_mass_frame))))
			else requested
		local m = a.matrix(normalization.orthonormalize_part_basis(mw))
		store_xyz(body, 16, m[1])
		store_xyz(body, 20, m[2])
		store_xyz(body, 24, m[3])
		store_xyz(body, 4, m[4])
		local q = quaternion(m)
		for i = 1, 4 do
			body[i] = to_bits(q[i])
		end
		local inertia = p.inertia
		if inertia ~= nil then
			local ri, up, at = m[1], m[2], m[3]
			local r = a.mul(ri, a.splat(from_bits(inertia[1])))
			local u = a.mul(up, a.splat(from_bits(inertia[2])))
			local aa = a.mul(at, a.splat(from_bits(inertia[3])))
			local full = a.madd(aa, a.splat(at[1]), a.madd(r, a.splat(ri[1]), a.mul(u, a.splat(up[1]))))
			local function pp(v: a.V): a.V
				return a.perm(v, { 2, 1, 1, 3 })
			end
			local function s(v: a.V): a.V
				return a.perm(v, { 2, 1, 2, 3 })
			end
			local split = a.madd(pp(at), s(aa), a.madd(pp(ri), s(r), a.mul(pp(up), s(u))))
			store_xyz(body, 28, full)
			store_xyz(body, 32, split)
			body[32] = inertia[5]
		end
	end
	p.transform = table.clone(requested)
end

-- ROBLOX: #[derive(Clone)].
function part.clone(p: PartPose): PartPose
	return {
		transform = table.clone(p.transform),
		local_mass_frame = if p.local_mass_frame then table.clone(p.local_mass_frame) else nil,
		body = if p.body then table.clone(p.body) else nil,
		inertia = if p.inertia then table.clone(p.inertia) else nil,
	}
end

return part
