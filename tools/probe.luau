local rt = require("../src/rt")
for _, v in {1e-40, -1e-40, 1.4e-45, 0.1, 1/3, 3.4e38, 1e39, -0.0} do
	print(v, string.format("%08x", rt.to_bits(v)), rt.fround(v), rt.from_bits(rt.to_bits(v)))
end
print(rt.round_ties_even(2.5), rt.round_ties_even(3.5), rt.round_ties_even(-2.5), rt.round_ties_even(-0.4))
