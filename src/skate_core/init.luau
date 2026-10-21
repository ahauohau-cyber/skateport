--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/lib.rs (коммит 2e16697)
--
-- Engine-independent recovered calculations. No rendering, file I/O, or ECS.
-- В Rust этот файл только объявляет подмодули (`pub mod ...`).
-- ROBLOX: в Luau подмодули не подключаются заранее, каждый модуль
-- требует нужные ему файлы по пути, например require("@self/math").
-- Так нет циклов require и лишней загрузки.

return {}
