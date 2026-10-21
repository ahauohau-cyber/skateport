-- Одинаковый расчёт в Luau CLI и в Studio. Совпадение сумм = Roblox считает так же.
return function(root)
	local rt = (require :: any)(root.rt)
	local trig = (require :: any)(root.trig)
	local pg = (require :: any)(root.pg)
	local h, seed = 0, 12345
	local function add(v) h = (h * 31 + rt.to_bits(v)) % 4294967296 end
	for _ = 1, 20000 do
		seed = (seed * 1103515245 + 12345) % 2147483648
		local a = rt.f32((seed / 2147483648 - 0.5) * 40)
		local s, c = trig.sin_cos(a)
		add(s); add(c); add(trig.sin(a)); add(trig.cos(a))
		local u = rt.f32(seed / 2147483648 * 2 - 1)
		add(trig.asin(u)); add(trig.acos(u))
	end
	local g = pg.PointGraph.new({0, 1, 4, 9}, {2, -1, 0.5, 7.25})
	for i = 0, 1000 do add(pg.PointGraph.evaluate(g, rt.f32(-2 + i * 0.013))) end
	-- субнормальные числа и знак нуля
	for _, v in {1e-40, -1e-40, 1.4e-45, -0.0, 3.5e38} do add(rt.f32(v)); add(rt.fround(v)) end
	return h
end
