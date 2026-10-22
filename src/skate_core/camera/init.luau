--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/camera/mod.rs (коммит 2e16697)
--
-- Readable camera implementation candidates. Prior generated-code validation
-- is withdrawn; native correctness and full gameplay integration are unverified.
--
-- В Rust этот файл объявляет подмодули и переэкспортирует их типы (`pub use`).
-- ROBLOX: переэкспорт не повторяем: он заставил бы загрузить сразу все 44 модуля
-- камеры. Вызывающий код подключает модуль, где тип определён, например
-- crate::camera::SimulationRateRequest -> require(".../camera/slow_motion").

return {}
