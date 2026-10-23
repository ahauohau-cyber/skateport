--!strict
-- Запуск всех тестов порта: luau tests/run.luau
local harness = require("./harness")

local specs = {
	require("./skate_core/physics/native_arithmetic.spec"),
	require("./skate_core/point_graph.spec"),
	require("./skate_core/trigonometry.spec"),
	require("./skate_game/physics/clock.spec"),
	require("./roblox/fixed_step.spec"),
	require("./skate_core/physics/collision.spec"),
	require("./skate_core/physics/triangle_query.spec"),
	require("./skate_core/physics/triangle_query_unit.spec"),
	require("./skate_core/physics/world_contact.spec"),
	require("./skate_core/physics/contact.spec"),
	require("./skate_core/physics/bodies.spec"),
	require("./skate_game/skate_world.spec"),
	require("./skate_core/physics/mass.spec"),
	require("./skate_core/physics/drive.spec"),
	require("./skate_core/physics/solver.spec"),
	require("./skate_core/physics/assembly.spec"),
	require("./skate_core/physics/board.spec"),
	require("./skate_core/physics/board_world.spec"),
	require("./skate_core/riding/riding_basics.spec"),
	require("./skate_core/physics/board_ground.spec"),
	require("./skate_core/riding/reckoning.spec"),
	require("./skate_core/riding/riding_forces.spec"),
	require("./skate_core/riding/riding_push.spec"),
	require("./skate_core/riding/grounded.spec"),
	require("./skate_data/data.spec"),
	require("./skate_game/physics/settings.spec"),
	require("./skate_game/physics/colliders.spec"),
	require("./skate_game/physics/riding_outputs.spec"),
	require("./skate_core/input/input_golden.spec"),
	require("./skate_core/input/input_rust.spec"),
	require("./skate_game/input/controllers.spec"),
	require("./skate_game/physics/controls.spec"),
	require("./skate_core/graph/graph.spec"),
	require("./skate_core/animation/anim1.spec"),
	require("./skate_core/animation/anim2.spec"),
	require("./skate_core/animation/anim3.spec"),
	require("./skate_core/physics/skeleton.spec"),
	require("./skate_core/physics/skeleton2.spec"),
	require("./skate_data/data2.spec"),
	require("./skate_game/graph_runtime.spec"),
}

local report = harness.new()
for _, spec in specs do
	spec(report)
end
harness.print(report)
if report.failed > 0 then
	error("tests failed", 0)
end
