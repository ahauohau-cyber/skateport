--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/pose_mirror.rs (коммит 2e16697)
--
-- ACS immediate Mirror 828CDAF8. Pairing comes from the stock hierarchy.

local rt = require("../../rt")
local sqt = require("./output/sqt")
local pose_trajectory = require("./pose_trajectory")

local pose_mirror = {}

local function reflect(pose: sqt.Sqt)
	pose.rotation[1] = -pose.rotation[1]
	pose.rotation[2] = -pose.rotation[2]
	pose.translation[3] = -pose.translation[3]
end

-- ROBLOX: parents/partners — индексы костей с нуля. Result<(), String> -> rt.raise.
-- ROBLOX: x *= -1.0 в f32 — то же, что смена знака (-x).
function pose_mirror.mirror(pose: { sqt.Sqt }, parents: { number }, partners: { number }, trajectory_mode: number)
	if #pose ~= #parents or #pose ~= #partners then
		rt.raise("Mirror pose and hierarchy dimensions differ")
	end
	for i0, partner in partners do
		local i = i0 - 1
		if partner < -1 or partner >= #pose then
			rt.raise(string.format("Invalid mirror partner for bone%d", i))
		end
		-- -1 excludes a bone; the smaller index processes both sides of a pair.
		if partner >= i then
			local p = pose[i0]
			if trajectory_mode == 1 and (i == 0 or parents[i0] == 0) then
				if i ~= 0 then
					-- Literal quaternion 8232F740, before the alternate reflection.
					p.rotation = pose_trajectory.multiply(p.rotation, { 0.0, 1.0, 0.0, 0.0 })
				end
				p.rotation[2] = -p.rotation[2]
				p.rotation[3] = -p.rotation[3]
				p.translation[1] = -p.translation[1]
			else
				reflect(p)
			end
			if partner > i then
				pose[i0], pose[partner + 1] = pose[partner + 1], pose[i0]
				reflect(pose[i0])
			end
		end
	end
end

return pose_mirror
