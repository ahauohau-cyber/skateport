# SkatePort — правила перевода Rust → Luau

Порт [skate-3-rust-engine](https://github.com/SK8-ENGINE/skate-3-rust-engine) (GPL-3.0), коммит `2e16697`.
Порт — производная работа и распространяется под GPL-3.0.

## Структура

| Папка | Что | Roblox API |
|---|---|---|
| `src/rt.luau` | замены встроенных операций Rust | нет |
| `src/skate_core/` | = `crates/skate-core/src` | нет |
| `src/skate_data/` | = `crates/skate-data/src` | нет |
| `src/skate_game/` | = `crates/skate-game/src` (только симуляция) | нет |
| `src/roblox/` | прослойка к движку Roblox | только здесь |
| `tests/` | тесты; `tests/golden/` — эталон из настоящего Rust | — |
| `golden/` | программа на Rust, которая пишет эталон | — |

`src` заливается в `ReplicatedStorage.SkatePort`. Файл `x.luau` → ModuleScript `x`,
папка с `init.luau` → ModuleScript с детьми, папка без `init.luau` → Folder.

## Модули

- Один `.rs` = один `.luau`, тот же путь и имя.
- `mod.rs` / `lib.rs` → `init.luau`. Объявления `pub mod` и переэкспорт `pub use`
  не повторяем: код подключает модуль, где тип определён.
- Подключение — `require("./x")`, `require("../x")`, `require("@self/x")`.
  Одинаково работает в Studio и в Luau CLI.
- В `папка/init.luau` путь `./` указывает на соседей папки (её родителя), а детей
  подключают через `@self/x`. В `папка/x.luau` путь `./` — это сама папка.
- Шапка каждого файла: строка GPL и путь оригинального Rust-файла.
- Каждая замена API помечена `-- ROBLOX: что и почему`. Неясное — `-- TODO`.

## Числа (главное правило)

Rust считает в f32, Luau — в f64. Чтобы совпадать с Rust бит в бит:

- каждая арифметическая операция над f32 → `f32(...)`;
- `a.mul_add(b, c)` → `mul_add(a, b, c)` — настоящая fma с одним округлением (`rt.mul_add` ловит
  двойное округление через TwoSum; простое `f32(a * b + c)` изредка ошибается на 1 бит);
- `f32::from_bits` / `to_bits` → `rt.from_bits` / `rt.to_bits`;
- `x.min(y)` / `x.max(y)` → `rt.fmin` / `rt.fmax` (правила NaN как в Rust);
- `round_ties_even` → `rt.round_ties_even`;
- u32-арифметика с переполнением → `rt.wrapping_*_u32`, `as i32` → `rt.to_i32`;
- целое деление положительных → `//`.

Roblox обнуляет субнормальные f32 в `vector` и `buffer`; `rt` обрабатывает их вручную.

Записи-массивы слов (`[u32; N]`) → таблицы чисел u32, слово k лежит в `[k + 1]`;
срезы `&a[x..y]` → `rt.slice` (копия), запись в срез → `rt.copy_into` / `rt.copy_range`.
Цикл `require` между двумя файлами → подключение внутри функции (см. triangle_query).

## Типы

- `Vector3` → встроенный `vector` (f32, копируется по значению). Поле на месте не меняем:
  `v = vector.create(v.x, y, v.z)`. Известное отличие: Roblox обнуляет субнормальные
  компоненты `vector`.
- Прочие `Copy`-структуры → таблицы + явный `copy()` там, где Rust копирует неявно.
- Массивы → таблицы с индекса 1: `a[i]` → `a[i + 1]`; цикл `0..n` → `1..n`.
- `Option` → значение или `nil`; `Result` → `(значение)` или `(nil, ошибка)`.
- Кортеж → несколько возвращаемых значений.
- Ключевые слова Luau (`end`, ...) в именах → суффикс `_` (`end_`).

## Тесты

```
luau tests/run.luau                         # все тесты
cd golden && cargo run --release -- ../tests/golden   # пересобрать эталон
```

Rust-тесты переносятся рядом с модулем (`tests/<путь>.spec.luau`).
Для функций без Rust-тестов — сверка с эталоном из `golden/` с допуском 0 ULP.
