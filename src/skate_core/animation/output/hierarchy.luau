--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/output/hierarchy.rs (коммит 2e16697)

local rt = require("../../../rt")
local sqt = require("./sqt")

local f32 = rt.f32
local mul_add = rt.mul_add

local hierarchy = {}

type NativeMatrix = sqt.NativeMatrix

-- ROBLOX: PoseBufferError -> rt.raise({ kind = ..., bone?, parent? }).
local function validate(count: number, parents: { number }, detached_parent: number, input_len: number, output_len: number)
	if input_len < math.max(count, 1) then
		rt.raise({ kind = "ShortInput" })
	end
	if output_len < math.max(count, 1) then
		rt.raise({ kind = "ShortOutput" })
	end
	if #parents < count then
		rt.raise({ kind = "ShortParents" })
	end
	for bone = 0, count - 1 do
		local parent = parents[bone + 1]
		if parent ~= -1 and parent ~= detached_parent and (parent < 0 or parent >= output_len) then
			rt.raise({ kind = "InvalidParent", bone = bone, parent = parent })
		end
	end
end

local function concatenate(localm: NativeMatrix, parent: NativeMatrix): NativeMatrix
	local result = { table.clone(localm[1]), table.clone(localm[2]), table.clone(localm[3]), table.clone(localm[4]) }
	for row = 1, 4 do
		for lane = 1, 4 do
			local first
			if row == 4 then
				first = mul_add(parent[1][lane], localm[row][1], parent[4][lane])
			else
				first = f32(parent[1][lane] * localm[row][1])
			end
			local second = mul_add(parent[2][lane], localm[row][2], first)
			result[row][lane] = mul_add(parent[3][lane], localm[row][3], second)
		end
	end
	return result
end

local function copy(m: NativeMatrix): NativeMatrix
	return { table.clone(m[1]), table.clone(m[2]), table.clone(m[3]), table.clone(m[4]) }
end

-- TU3 0x828D3B58: local matrices to hierarchy-composed matrices.
--
-- `detached_parent` is native r5 (hierarchy +8 at the caller). A parent equal to
-- it, or -1, causes a verbatim local copy. No world transform is introduced.
-- The first matrix is copied even for a nonpositive count. Other output slots
-- retain caller state until visited, including when a forward parent is read.
-- ROBLOX: parents — индексы костей с нуля (как в Rust), матрицы — с 1.
function hierarchy.compose_hierarchy(bone_count: number, parents: { number }, detached_parent: number, localm: { NativeMatrix }, destination: { NativeMatrix })
	local count = math.max(bone_count, 0)
	validate(count, parents, detached_parent, #localm, #destination)
	destination[1] = copy(localm[1])
	for bone = 0, count - 1 do
		local parent = parents[bone + 1]
		if parent == -1 or parent == detached_parent then
			destination[bone + 1] = copy(localm[bone + 1])
		else
			destination[bone + 1] = concatenate(localm[bone + 1], destination[parent + 1])
		end
	end
end

-- The same native function with identical source/destination matrix pointers.
function hierarchy.compose_hierarchy_in_place(bone_count: number, parents: { number }, detached_parent: number, matrices: { NativeMatrix })
	local count = math.max(bone_count, 0)
	validate(count, parents, detached_parent, #matrices, #matrices)
	for bone = 0, count - 1 do
		local parent = parents[bone + 1]
		if parent ~= -1 and parent ~= detached_parent then
			matrices[bone + 1] = concatenate(matrices[bone + 1], matrices[parent + 1])
		end
	end
end

return hierarchy
