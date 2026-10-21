local rt = require("../src/rt")
local trig = require("../src/skate_core/trigonometry")
local function run()
	local H = {}
	local function add(k, v) H[k] = ((H[k] or 0) * 31 + rt.to_bits(v)) % 4294967296 end
	local seed = 12345
	for _ = 1, 2000 do
		seed = (seed * 1103515245 + 12345) % 2147483648
		add("seed", seed)
		local a = rt.f32((seed / 2147483648 - 0.5) * 40)
		add("a", a)
		local s, c = trig.sin_cos(a)
		add("sc", s); add("sc", c)
		add("sin", trig.sin(a)); add("cos", trig.cos(a))
		local u = rt.f32(seed / 2147483648 * 2 - 1)
		add("asin", trig.asin(u))
	end
	for i, v in {1e-40, -1e-40, 1.4e-45, -0.0, 3.5e38} do add("sub" .. i, rt.f32(v)); add("subb" .. i, rt.fround(v)) end
	local keys = {}
	for k in H do table.insert(keys, k) end
	table.sort(keys)
	local o = {}
	for _, k in keys do table.insert(o, k .. "=" .. H[k]) end
	return table.concat(o, " ")
end
print(run())
