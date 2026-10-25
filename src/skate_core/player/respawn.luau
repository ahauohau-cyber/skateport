--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/respawn.rs (коммит 2e16697)
--
-- TU3 actor checkpoint history (82BFB068..82BFCB38).
-- Scene predicates are supplied by the host; absence is never acceptance.
-- ROBLOX: Matrix ([[f32; 4]; 4]) -> 4 строки по 4 числа; Copy-значения
-- (матрицы, Candidate) копируются при передаче.
-- ROBLOX: trait Validation -> таблица с методами; ошибка — rt.raise(e) внутри
-- метода, Result<Option<Ground>> -> Ground или nil.

local rt = require("../../rt")
local sar = require("../physics/skeleton_animation_record")

local f32 = rt.f32

local respawn = {}

type Matrix = { { number } }

local function copy_matrix(m: Matrix): Matrix
	return { table.clone(m[1]), table.clone(m[2]), table.clone(m[3]), table.clone(m[4]) }
end

export type Candidate = {
	transform: Matrix,
	stance: number,
	offboard: boolean,
	score: number,
}

local function copy_candidate(c: Candidate): Candidate
	return { transform = copy_matrix(c.transform), stance = c.stance, offboard = c.offboard, score = c.score }
end
respawn.copy_candidate = copy_candidate

-- Separate native predicates: history selection does not repeat ground or edge
-- validation, whereas current-position selection does (82BFC038/82BFC378).
export type Validation = {
	ground: (self: any, transform: Matrix) -> Ground?,
	location: (self: any, transform: Matrix) -> boolean,
	occupants: (self: any, transform: Matrix) -> boolean,
	edges: (self: any, transform: Matrix) -> boolean,
}

export type Ground = {
	position: { number },
	offboard: boolean,
}

-- Completed native packet fields. The caller must provide actual producer
-- values, especially Ground323 and conditioner164; neither means grounded.
export type Observation = {
	measurements: number,
	root_position: { number }, -- Skeleton416, unmirrored11920 translation
	com_position: { number }, -- Skeleton64, physical COM16144
	teleport_requested: boolean, -- State69
	physical_state: number, -- State16
	state_frames: number, -- State4
	ground_suppressed: boolean, -- Ground323
	offboard_correction: boolean, -- OffBoard333
	ground_category: number, -- Collision16 low16
	foot_categories: { number }, -- OffBoard52/56 packed categories
	riding_transform: Matrix, -- 82591E30(false)
	offboard_transform: Matrix, -- 82591E30(true)
	stance: number, -- 82592B68
	alternate_world: boolean, -- SimController virtual0
}

export type History = {
	initial: Candidate,
	entries: { Candidate }, -- native33 slots reserve one sentinel:32 entries
	cooldown: number,
	current_orientation: Matrix, -- 208; only eligible riding states write it
	current_position: { number }, -- 272; every actor update writes Skeleton64
}

-- 82BFB3F8 rejects these categories; category8 explicitly requests offboard.
function respawn.surface_allowed(category: number): boolean
	return not (category == 5 or category == 6 or category == 9 or category == 12 or category == 13)
end

-- Jump table82BFB698: category1/2=100,3/4=50,11=20, all others=0.
function respawn.surface_score(category: number): number
	if category == 1 or category == 2 then
		return 100.0
	elseif category == 3 or category == 4 then
		return 50.0
	elseif category == 11 then
		return 20.0
	end
	return 0.0
end

local function distance_squared(a: { number }, b: { number }): number
	-- ROBLOX: powi(2) -> x * x (одно округление f32).
	local dx, dy, dz = f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3])
	return f32(f32(f32(dx * dx) + f32(dy * dy)) + f32(dz * dz))
end

local History = {}
respawn.History = History

function History.new(initial: Candidate): History
	return {
		initial = copy_candidate(initial),
		entries = { copy_candidate(initial) },
		cooldown = 20,
		current_orientation = sar.IDENTITY(),
		current_position = table.clone(initial.transform[4]),
	}
end

-- 82BFB1E0: call even when the physical state cannot supply a candidate.
-- The120 gate uses conditioner164 (EmpiricalMeasurements82DE5858), not
-- State4's time in the current state. Its reset lifecycle is caller-owned.
function History.recording_due(self: History, measurements: number, root_position: { number }): boolean
	local eligible = measurements >= 120
	if not eligible then
		self.cooldown = 0
	end
	if self.cooldown > 0 then
		self.cooldown -= 1
		eligible = false
	end
	if not eligible then
		return false
	end
	for i = #self.entries, 1, -1 do
		if distance_squared(self.entries[i].transform[4], root_position) < 2.25 then
			return false
		end
	end
	return true
end

-- 82BFCB38. Construction and successful recording both refresh cooldown.
function History.insert(self: History, candidate: Candidate)
	if #self.entries == 32 then
		table.remove(self.entries, 1)
	end
	table.insert(self.entries, copy_candidate(candidate))
	self.cooldown = 20
end

-- 82BFB1E0/82BFB3F8. Do not call this with last-grounded observations;
-- the native actor consumes one completed physical publication per update.
function History.observe(self: History, input: Observation, minimum_state_frames: number, scene: any)
	self.current_position = table.clone(input.com_position)
	if not History.recording_due(self, input.measurements, input.root_position) or input.teleport_requested then
		return
	end
	local transform, offboard, score
	local st = input.physical_state
	if st == 100 or st == 104 then
		-- This write precedes both the15-frame gate and terrain checks.
		self.current_orientation = copy_matrix(input.riding_transform)
		if
			input.state_frames <= minimum_state_frames
			or input.ground_suppressed
			or not respawn.surface_allowed(input.ground_category)
		then
			return
		end
		transform = copy_matrix(input.riding_transform)
		offboard = input.ground_category == 8
		score = respawn.surface_score(input.ground_category)
	elseif st == 500 or st == 502 then
		if input.state_frames <= minimum_state_frames or input.offboard_correction then
			return
		end
		transform = copy_matrix(input.offboard_transform)
		offboard = true
		-- ROBLOX: f32::max -> rt.fmax.
		score = rt.fmax(respawn.surface_score(input.foot_categories[1]), respawn.surface_score(input.foot_categories[2]))
	else
		return
	end
	if not scene:location(copy_matrix(transform)) or not scene:edges(copy_matrix(transform)) then
		return
	end
	if not input.alternate_world and scene:ground(copy_matrix(transform)) == nil then
		return
	end
	-- The recording path discards the ray's offboard byte and hit position.
	History.insert(self, { transform = transform, stance = input.stance, offboard = offboard, score = score })
end

-- 82BFC550: descending score, newest wins ties; selected entry is removed
-- before validation, including successful selections. Repeated bails thus
-- cannot keep selecting the same history entry.
local function pop_best(self: History): Candidate?
	local best: number? = nil
	local score = -99990.0
	local n = #self.entries
	-- ROBLOX: (0..len).rev().enumerate() -> age = 0.., index = len-1 .. 0.
	for age = 0, n - 1 do
		local index = n - age
		local value = self.entries[index].score
		if age < 1 then
			value = f32(value - 100.0)
		end
		if age > 5 then
			value = f32(value - 200.0)
		end
		if value > score then
			best = index
			score = value
		end
	end
	if best == nil then
		return nil
	end
	return table.remove(self.entries, best)
end

-- 82BFC9B0, used by automatic actor reset82592518. Manual/session-marker
-- selection82BFC828 has a different history walk and must not call this.
function History.automatic(self: History, stance: number, scene: any): Candidate
	local transform = copy_matrix(self.current_orientation)
	transform[4] = table.clone(self.current_position)
	local ground = scene:ground(copy_matrix(transform))
	if ground ~= nil then
		if scene:location(copy_matrix(transform)) and scene:occupants(copy_matrix(transform)) and scene:edges(copy_matrix(transform)) then
			if ground.offboard then
				transform[4][2] = ground.position[2]
			end
			return { transform = transform, stance = stance, offboard = ground.offboard, score = 0.0 }
		end
	end
	while true do
		local candidate = pop_best(self)
		if candidate == nil then
			break
		end
		if scene:location(copy_matrix(candidate.transform)) and scene:occupants(copy_matrix(candidate.transform)) then
			return candidate
		end
	end
	-- 82BFC718 also serves non-destructive selectors; retain its actual rule.
	local last = self.entries[#self.entries]
	if last ~= nil then
		return copy_candidate(last)
	end
	return { transform = copy_matrix(self.initial.transform), stance = stance, offboard = false, score = 0.0 }
end

return respawn
