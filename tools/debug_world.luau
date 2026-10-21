local rt = require("../src/rt")
local pq = require("../src/skate_core/physics/world_contact/primitive_query")
local golden = require("../tests/golden/world_contact")
local fb = rt.from_bits
local function V(t) return vector.create(fb(t[1]), fb(t[2]), fb(t[3])) end
local function triangle(t)
	return { vertices = { V(t.vertices[1]), V(t.vertices[2]), V(t.vertices[3]) },
		feature = { normal = V(t.normal), edges = { V(t.edges[1]), V(t.edges[2]), V(t.edges[3]) }, flags = t.flags,
			edge_cosines = { fb(t.edge_cosines[1]), fb(t.edge_cosines[2]), fb(t.edge_cosines[3]) } },
		edge_lengths = { fb(t.edge_lengths[1]), fb(t.edge_lengths[2]), fb(t.edge_lengths[3]) }, fatness = fb(t.fatness) }
end
local function prim(p)
	local c = p.basis
	return { kind = "RoundedBox", center = V(p.center), basis = { columns = {
		{ fb(c[1][1]), fb(c[1][2]), fb(c[1][3]) }, { fb(c[2][1]), fb(c[2][2]), fb(c[2][3]) }, { fb(c[3][1]), fb(c[3][2]), fb(c[3][3]) } } },
		half_extents = V(p.half_extents), radius = fb(p.radius) }
end
local shown = 0
for index, case in golden.world do
	if case.primitive.kind ~= "RoundedBox" then continue end
	local s = case.settings
	local got = pq.primitive_triangle_world_contacts(prim(case.primitive), triangle(case.tri), V(case.velocity),
		{ volume_padding = fb(s[1]), maximum_separating_distance = fb(s[2]), edge_cos_bend_normal_threshold = fb(s[3]), convexity_epsilon = fb(s[4]), is_object = s[5] })
	local want = case.result
	local same = (want == false and got == nil)
	if not same and got and want ~= false and got.count == want.count then
		same = true
		local function eqv(a, b) return rt.to_bits(a.x) == b[1] and rt.to_bits(a.y) == b[2] and rt.to_bits(a.z) == b[3] end
		if not eqv(got.normal, want.normal) then same = false end
		for i = 1, want.count do
			if not eqv(got.points[i].a, want.points[i].a) or not eqv(got.points[i].b, want.points[i].b) then same = false end
		end
	end
	if not same then
		shown += 1
		print("case", index, "want", want == false and "nil" or ("count " .. want.count), "got", got == nil and "nil" or ("count " .. got.count))
		if want ~= false then print("  want normal", fb(want.normal[1]), fb(want.normal[2]), fb(want.normal[3])) end
		if got then print("  got  normal", got.normal.x, got.normal.y, got.normal.z) end
		if want ~= false then for i = 1, want.count do print("  want a", i, fb(want.points[i].a[1]), fb(want.points[i].a[2]), fb(want.points[i].a[3])) end end
		if got then for i = 1, got.count do print("  got  a", i, got.points[i].a.x, got.points[i].a.y, got.points[i].a.z) end end
		if shown >= 3 then break end
	end
end
