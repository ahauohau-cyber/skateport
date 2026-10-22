--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/collision/mod.rs (коммит 2e16697)
--
-- TU3 feature-prism collision. Geometry and triangle adjacency come from the
-- collision mesh, independently of rendering and material response.
--
-- В Rust этот файл объявляет подмодули и переэкспортирует:
--   fixup::{ContactPair, TriangleFeature, TriangleFixup, TriangleRegion, fix_up_triangle}
--   sphere_triangle::{Sphere, SphereTrianglePair, Triangle, intersect_sphere_triangle}
--   world_contact::{WorldContact, WorldContactSettings, sphere_triangle_world_contact, world_separation_limit}
-- ROBLOX: переэкспорт не повторяем, код подключает нужный подмодуль напрямую.

return {}
