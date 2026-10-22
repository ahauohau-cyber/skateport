--!strict
--!native
-- ROBLOX: вспомогательный модуль порта. В Rust его нет.
-- Здесь собраны замены встроенных операций Rust, которых нет в Luau:
-- биты f32, округление «к чётному», min/max с правилами Rust для NaN.
-- Используется модулями core/ и data/. Обращений к Roblox API нет.
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine

local rt = {}

-- ROBLOX: один буфер на 4 байта для переинтерпретации f32 <-> u32.
local scratch = buffer.create(4)

-- ROBLOX: самое маленькое нормальное f32 и шаг субнормальных f32.
-- Roblox (в отличие от Luau CLI) обнуляет субнормальные f32 и в vector,
-- и в buffer.writef32/readf32. Rust их сохраняет, поэтому такие числа
-- (|x| < 2^-126) переводим вручную. Обычные числа идут быстрым путём.
local MIN_NORMAL = 2 ^ -126
local SUBNORMAL_STEP = 2 ^ -149

-- Округление «к чётному» для субнормального диапазона (без знака нуля).
local function round_half_even(value: number): number
	local floor = math.floor(value)
	local fraction = value - floor
	if fraction > 0.5 or (fraction == 0.5 and floor % 2 == 1) then
		return floor + 1
	end
	return floor
end

-- Ближайшее f32 для 0 < |value| < 2^-126, со знаком.
local function round_subnormal(value: number): number
	local units = round_half_even(math.abs(value) / SUBNORMAL_STEP)
	local magnitude = units * SUBNORMAL_STEP
	if value < 0 then
		return -magnitude
	end
	return magnitude
end

-- ROBLOX: f32::from_bits. Число u32 -> f32 с теми же битами.
function rt.from_bits(bits: number): number
	if bits % 0x8000_0000 < 0x0080_0000 and bits % 0x8000_0000 ~= 0 then
		-- субнормальное: экспонента 0, мантисса не 0
		local magnitude = (bits % 0x0080_0000) * SUBNORMAL_STEP
		if bits >= 0x8000_0000 then
			return -magnitude
		end
		return magnitude
	end
	buffer.writeu32(scratch, 0, bits)
	return buffer.readf32(scratch, 0)
end

-- ROBLOX: f32::to_bits. Число -> биты ближайшего f32.
function rt.to_bits(value: number): number
	if value ~= 0 and value > -MIN_NORMAL and value < MIN_NORMAL then
		local units = round_half_even(math.abs(value) / SUBNORMAL_STEP)
		if value < 0 or (value == 0 and 1 / value < 0) then
			return units + 0x8000_0000
		end
		return units
	end
	buffer.writef32(scratch, 0, value)
	return buffer.readu32(scratch, 0)
end

-- ROBLOX: округление до ближайшего f32 — результат любой операции f32 в Rust.
-- Luau считает в f64, Rust — в f32. Если после каждой операции округлять
-- результат до f32, вычисления совпадают с Rust бит в бит (проверено тестами).
-- Встроенный `vector` хранит компоненты в f32, поэтому vector.create(x, 0, 0).x
-- и есть округление; так на ~30% быстрее, чем через buffer.
function rt.f32(value: number): number
	local rounded = vector.create(value, 0, 0).x
	if rounded ~= 0 or value == 0 or value ~= value then
		return rounded
	end
	-- ROBLOX: Roblox обнулил субнормальное значение — считаем вручную.
	return round_subnormal(value)
end

-- ROBLOX: то же округление через buffer (для проверки rt.f32).
function rt.fround(value: number): number
	if value ~= 0 and value > -MIN_NORMAL and value < MIN_NORMAL then
		return round_subnormal(value)
	end
	buffer.writef32(scratch, 0, value)
	return buffer.readf32(scratch, 0)
end

-- ROBLOX: f32 a * b + c с ОДНИМ округлением, как fma (mul_add) в Rust.
-- Произведение двух f32 в f64 точное. Сумма в f64 может округлиться, и тогда
-- второе округление до f32 изредка ошибается: когда сумма в f64 попадает ровно
-- в середину между двумя f32. Поэтому считаем точную ошибку сложения (TwoSum)
-- и в этом случае выбираем соседнее f32 по её знаку.
-- Быстрый путь (одно округление): если rounded == sum, или rounded лежит со
-- стороны err, ответ — rounded. Иначе проверяем середину: тогда
-- candidate = 2·sum − rounded — соседнее f32, и оно представимо точно.
function rt.mul_add(value: number, a: number, b: number): number
	local product = value * a
	local sum = product + b
	if sum - sum ~= 0 then
		-- NaN или бесконечность
		return sum
	end
	-- TwoSum: точная ошибка округления сложения в f64.
	local bb = sum - product
	local err = (product - (sum - bb)) + (b - bb)
	if sum == 0 then
		-- в f64 сумма обнулилась, но точное значение — это err
		if err == 0 then
			return rt.f32(sum)
		end
		return rt.f32(err)
	end
	local rounded = vector.create(sum, 0, 0).x
	if rounded == 0 then
		-- ROBLOX: субнормальный результат — Roblox обнуляет его в vector.
		rounded = round_subnormal(sum)
	end
	if err == 0 then
		return rounded
	end
	local d = rounded - sum
	if d == 0 or (d > 0) == (err > 0) or rounded - rounded ~= 0 then
		-- sum уже f32, либо rounded на стороне err, либо переполнение
		return rounded
	end
	local candidate = sum - d
	if rt.f32(candidate) == candidate then
		-- sum ровно посередине между f32: точное значение сдвинуто на err
		return candidate
	end
	return rounded
end

-- ROBLOX: f32::round_ties_even. Половина округляется к чётному.
function rt.round_ties_even(value: number): number
	if value ~= value or value == math.huge or value == -math.huge then
		return value
	end
	local floor = math.floor(value)
	local fraction = value - floor
	local result
	if fraction > 0.5 then
		result = floor + 1
	elseif fraction < 0.5 then
		result = floor
	elseif floor % 2 == 0 then
		result = floor
	else
		result = floor + 1
	end
	-- ROBLOX: Rust сохраняет знак нуля (-0.4 -> -0.0).
	if result == 0 and (value < 0 or 1 / value < 0) then
		return -0.0
	end
	return result
end

-- ROBLOX: f32::min. Если один аргумент NaN, Rust возвращает другой.
function rt.fmin(left: number, right: number): number
	if left ~= left then
		return right
	end
	if right ~= right then
		return left
	end
	if left < right then
		return left
	end
	return right
end

-- ROBLOX: f32::max. Если один аргумент NaN, Rust возвращает другой.
function rt.fmax(left: number, right: number): number
	if left ~= left then
		return right
	end
	if right ~= right then
		return left
	end
	if left > right then
		return left
	end
	return right
end

-- ROBLOX: u32::wrapping_add. Результат по модулю 2^32.
function rt.wrapping_add_u32(left: number, right: number): number
	return (left + right) % 0x1_0000_0000
end

-- ROBLOX: u32::wrapping_sub. Результат по модулю 2^32.
function rt.wrapping_sub_u32(left: number, right: number): number
	return (left - right) % 0x1_0000_0000
end

-- ROBLOX: u32::wrapping_mul. Делим множитель на 16-битные половины,
-- чтобы произведение не вышло за 2^53 и не потеряло младшие биты.
function rt.wrapping_mul_u32(left: number, right: number): number
	local low = (left % 0x1_0000) * right
	local high = ((left // 0x1_0000) * right) % 0x1_0000
	return (high * 0x1_0000 + low) % 0x1_0000_0000
end

-- ROBLOX: `x as i32` для целого u32: биты те же, знак — по старшему биту.
function rt.to_i32(value: number): number
	local wrapped = value % 0x1_0000_0000
	if wrapped >= 0x8000_0000 then
		return wrapped - 0x1_0000_0000
	end
	return wrapped
end

-- ROBLOX: f64::from_bits для 64-битной константы, заданной двумя половинами.
local scratch64 = buffer.create(8)
function rt.f64_from_bits(high: number, low: number): number
	buffer.writeu32(scratch64, 0, low)
	buffer.writeu32(scratch64, 4, high)
	return buffer.readf64(scratch64, 0)
end

-- ROBLOX: `flags & mask != 0` для u32.
function rt.has_bits(flags: number, mask: number): boolean
	return bit32.band(flags, mask) ~= 0
end

-- ROBLOX: срезы и копирование массивов слов. Индексы и диапазоны — как в Rust
-- (с нуля, конец не включается); в Luau элемент k лежит в [k + 1].

-- `words[from..to]` -> новая таблица (копия).
function rt.slice(words: { number }, from: number, to: number): { number }
	local result = table.create(to - from) :: { number }
	for i = from + 1, to do
		result[i - from] = words[i]
	end
	return result
end

-- `dst[offset..offset + src.len()].copy_from_slice(&src)`.
function rt.copy_into(dst: { number }, offset: number, src: { number })
	for i = 1, #src do
		dst[offset + i] = src[i]
	end
end

-- `dst[offset..].copy_from_slice(&src[from..to])`.
function rt.copy_range(dst: { number }, offset: number, src: { number }, from: number, to: number)
	for i = from + 1, to do
		dst[offset + i - from] = src[i]
	end
end

-- `dst[from..to].fill(value)`.
function rt.fill(dst: { number }, from: number, to: number, value: number)
	for i = from + 1, to do
		dst[i] = value
	end
end

-- `[0u32; n]`.
function rt.zeros(n: number): { number }
	local result = table.create(n, 0) :: { number }
	return result
end

-- `x ^ 0x8000_0000` — смена знака f32 через биты.
function rt.flip_sign_bits(words: { number }): { number }
	local result = table.create(#words) :: { number }
	for i, w in words do
		result[i] = bit32.bxor(w, 0x8000_0000)
	end
	return result
end

-- f32::MIN_POSITIVE и f32::MAX.
rt.F32_MIN_POSITIVE = 2 ^ -126
rt.F32_MAX = 3.4028234663852886e38

-- ROBLOX: f32::is_nan.
function rt.is_nan(value: number): boolean
	return value ~= value
end

-- ROBLOX: f32::is_finite.
function rt.is_finite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

return rt
