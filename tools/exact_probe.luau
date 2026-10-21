local rt = require("../src/rt")
local golden = require("../tests/golden/trigonometry")
local f, fb = rt.fround, rt.from_bits
local function sin(angle)
	local turns = rt.round_ties_even(f(angle * fb(0x3E22_F983)))
	local x = f((-fb(0x40C9_0FDB)) * turns + angle)
	local x2 = f(x * x)
	local power = f(x * x2)
	local result = x
	for _, c in {0xBE2A_AAAB,0x3C08_8889,0xB950_0D01,0x3638_EF1D,0xB2D7_322B,0x2F30_9231,0xAB57_3F9F,0x274A_963C,0xA317_A4DA,0x1EB8_DC78,0x9A3B_0DA1} do
		result = f(fb(c) * power + result)
		power = f(power * x2)
	end
	return result
end
local exact, total, worst = 0, 0, 0
for _, case in golden.sin do
	total += 1
	local b = rt.to_bits(sin(fb(case[1])))
	if b == case[2] then exact += 1 else worst = math.max(worst, math.abs(b - case[2])) end
end
print("exact", exact, "/", total, "worst raw diff", worst)
local t = os.clock(); local s = 0
for i = 1, 200000 do s += sin(i * 0.001) end
print("rounded sin x200k", os.clock() - t)
local trig = require("../src/skate_core/trigonometry")
t = os.clock(); s = 0
for i = 1, 200000 do s += trig.sin(i * 0.001) end
print("f64 sin x200k", os.clock() - t)
