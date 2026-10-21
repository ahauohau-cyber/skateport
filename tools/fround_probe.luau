local rt = require("../src/rt")
local function fv(x) return vector.create(x, 0, 0).x end
local bad = 0
local vals = {0.1, 1/3, 1e-40, -1e-40, 1.4e-45, 3.4028235677973366e38, 3.5e38, -0.0, 0/0, math.huge, 2^-149*0.5, 2^-149*0.75, 1+2^-24, 1+3*2^-24}
for _, v in vals do
	local a, b = rt.fround(v), fv(v)
	if not (a == b or (a ~= a and b ~= b)) or (a == 0 and 1/a ~= 1/b) then bad += 1; print("diff", v, a, b) end
end
local seed = 1
for i = 1, 200000 do
	seed = (seed * 1103515245 + 12345) % 2^31
	local v = (seed / 2^31 - 0.5) * 10 ^ ((seed % 80) - 40)
	if rt.fround(v) ~= fv(v) then bad += 1 end
end
print("mismatches", bad)
local t = os.clock(); local s = 0
for i = 1, 2000000 do s += rt.fround(i * 0.37) end
print("buffer fround", os.clock() - t)
t = os.clock(); s = 0
for i = 1, 2000000 do s += fv(i * 0.37) end
print("vector fround", os.clock() - t)
