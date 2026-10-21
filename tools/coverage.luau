-- Считает вызовы функций world_contact во время прогона эталона.
local counts = {}
local function wrap(mod, name, label)
	local f = mod[name]
	mod[name] = function(...)
		counts[label] = (counts[label] or 0) + 1
		return f(...)
	end
end
local base = "../src/skate_core/physics/world_contact/"
wrap(require(base .. "face_face"), "intersect", "face_face")
wrap(require(base .. "face_specialized"), "quad_triangle", "quad_triangle")
wrap(require(base .. "face_specialized"), "quad_quad", "quad_quad")
wrap(require(base .. "face_edge"), "intersect_feature_corner_edge", "corner_edge")
wrap(require(base .. "segment_face"), "intersect_segment_face", "segment_face")
wrap(require(base .. "segment_prism"), "intersect_feature_segments", "segment_segment")
wrap(require(base .. "point_feature"), "intersect_point_face", "point_face")
wrap(require(base .. "face_clip"), "clamp_point_to_feature", "clamp")
wrap(require(base .. "box_box_sat"), "box_box", "box_box")
wrap(require(base .. "triangle_box_sat"), "triangle_box", "triangle_box")
wrap(require(base .. "box_feature"), "box_maximum_feature", "box_feature")
local harness = require("../tests/harness")
local report = harness.new()
require("../tests/skate_core/physics/world_contact.spec")(report)
local keys = {}
for k in counts do table.insert(keys, k) end
table.sort(keys)
for _, k in keys do print(k, counts[k]) end
