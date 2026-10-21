--!strict
-- Сверка core/point_graph с настоящим skate-core (эталон из golden/).

local harness = require("../harness")
local rt = require("../../src/rt")
local point_graph = require("../../src/skate_core/point_graph")
local golden = require("../golden/point_graph")

local PointGraph = point_graph.PointGraph
local MAX_ULP = 0

return function(report: harness.Report)
	for index, case in golden do
		harness.test(report, "point_graph: graph " .. index .. " vs Rust", function()
			local x, y = {}, {}
			for i, b in case.x do
				x[i] = rt.from_bits(b)
			end
			for i, b in case.y do
				y[i] = rt.from_bits(b)
			end
			local graph = PointGraph.new(x, y)
			local stats = harness.stats()
			for _, pair in case.cases do
				harness.record(stats, pair[1], PointGraph.evaluate(graph, rt.from_bits(pair[1])), pair[2])
			end
			table.insert(report.lines, "      graph " .. index .. ": " .. harness.describe(stats))
			harness.check(stats.max_ulp <= MAX_ULP, harness.describe(stats))
		end)
	end

	harness.test(report, "point_graph: eq", function()
		local a = PointGraph.new({ 0, 1 }, { 2, 3 })
		harness.check(PointGraph.eq(a, PointGraph.new({ 0, 1 }, { 2, 3 })), "equal graphs")
		harness.check(not PointGraph.eq(a, PointGraph.new({ 0, 1 }, { 2, 4 })), "different y")
	end)
end
