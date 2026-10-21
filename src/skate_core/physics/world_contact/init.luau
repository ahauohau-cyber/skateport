--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/mod.rs (коммит 2e16697)
--
-- TU3 world-contact production and native temporary-contact retention.
-- General primitive dispatch remains a separate provider dependency.
--
-- В Rust этот файл объявляет подмодули, переэкспортирует их функции и задаёт
-- типы-записи. ROBLOX: переэкспорт не повторяем — код подключает подмодуль,
-- где функция определена (например ./primitive_query). Типы записей:
--   MaximumFeature = [u32; 144]  -- Maximum-feature record consumed by 82ACE190.
--   FeaturePrism   = [u32; 136]  -- Native two point arrays, normal, count, flags
--                                --  and untouched trailing padding.
--   ContactRecord  = [u32; 64]   -- Native 256-byte contact record, including
--                                --  both body workspaces.
-- В Luau это таблицы слов u32; слово k из Rust лежит в [k + 1].

return {}
