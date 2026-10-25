-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/world_contact/primitive_pair")
local v2 = import("skate_core/physics/world_contact/axes")
local v3 = import("skate_core/physics/world_contact/box_feature")
local v4 = import("skate_core/physics/world_contact/buffer")
local v5 = import("skate_core/physics/world_contact/dispatch")
local v6 = import("skate_core/physics/world_contact/primitive_query")
local v7 = import("skate_core/physics/world_contact/face_clip")
local v8 = import("skate_core/physics/world_contact/face_edge")
local v9 = import("skate_core/physics/world_contact/feature")
local v10 = import("skate_core/physics/world_contact/point_feature")
local v11 = import("skate_core/physics/world_contact/projection")
local v12 = import("skate_core/physics/world_contact/segment_face")
local v13 = import("skate_core/physics/world_contact/segment_prism")
local v14 = import("skate_core/physics/world_contact/triangle_feature")
local v15 = import("skate_core/physics/world_contact/reduction")

return {
    PrimitivePairSettings = v1.PrimitivePairSettings,
    primitive_pair_contacts = v1.primitive_pair_contacts,
    separating_axis_candidates = v2.separating_axis_candidates,
    box_maximum_feature = v3.box_maximum_feature,
    ContactBuffer = v4.ContactBuffer,
    find_feature_intersection_prism = v5.find_feature_intersection_prism,
    ContactPrimitive = v6.ContactPrimitive,
    PrimitiveContactManifold = v6.PrimitiveContactManifold,
    primitive_triangle_world_contacts = v6.primitive_triangle_world_contacts,
    transform_triangle_volume = v6.transform_triangle_volume,
    triangle_from_volume = v6.triangle_from_volume,
    clamp_point_to_feature = v7.clamp_point_to_feature,
    clip_segment_to_feature = v7.clip_segment_to_feature,
    intersect_feature_corner_edge = v8.intersect_feature_corner_edge,
    capsule_maximum_feature = v9.capsule_maximum_feature,
    initialize_feature_segment = v9.initialize_feature_segment,
    closest_feature_segment = v10.closest_feature_segment,
    intersect_point_face = v10.intersect_point_face,
    PrimitiveKind = v11.PrimitiveKind,
    best_separating_direction = v11.best_separating_direction,
    project_direction = v11.project_direction,
    project_directions = v11.project_directions,
    intersect_segment_face = v12.intersect_segment_face,
    intersect_feature_segments = v13.intersect_feature_segments,
    build_feature_edge_planes = v14.build_feature_edge_planes,
    triangle_maximum_feature = v14.triangle_maximum_feature,
    coplanar_contacts = v15.coplanar_contacts,
    select_contact_points = v15.select_contact_points
}
