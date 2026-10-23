--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/drag.rs (коммит 2e16697)
--
-- Ground drag calculation82D39100/104 and inertia publication82D392A8..B4.
-- Body::SetLinearDrag82D9CD60 writes inertia fields, not current velocities.

local rt = require("../../../rt")
local braking = require("../braking")

local f32 = rt.f32
local from_bits = rt.from_bits

local drag = {}

-- Literal at822F860C, verified in the original TU3 image. It is not replaced
-- by60 or recomputed from the current simulation timestep.
drag.DRAG_FREQUENCY = from_bits(0x426f_ffff)
local DRAG_FREQUENCY = drag.DRAG_FREQUENCY

export type GroundDragInput = {
	flags_2468: number,
	absolute_body_speed_2616: number,
	balance_2720: number,
	scalar_2724: number,
	-- Ground context+1216 vector Y, passed in f1 at82D39100. This is not
	-- Processed speed, a manual output, or a timestep.
	ground_normal_y: number,
}

local GroundDragInput = {}
drag.GroundDragInput = GroundDragInput

-- Calculate before the manual-output80 branch at82D39110. The returned
-- drag must be retained across force submission, then applied afterward.
function GroundDragInput.calculate(self: GroundDragInput, settings: braking.LinearDragSettings): number
	return braking.calculate_linear_drag({
		flags_2468 = self.flags_2468,
		absolute_body_speed = self.absolute_body_speed_2616,
		balance_2720 = self.balance_2720,
		scalar_2724 = self.scalar_2724,
		comparison_scalar = self.ground_normal_y,
	}, settings)
end

-- Native body+24 assembly contains part count+28 and definitions+8; each
-- 96-byte part resolves body+76 -> inertia+92. Shared inertias remain shared:
-- this binding references the live dynamics objects, not copies per part.
-- ROBLOX: part_inertia_indices — индексы с нуля, как в Rust; inertias — живые таблицы.
export type BodyInertias = {
	part_inertia_indices: { number },
	inertias: { any },
}

-- ROBLOX: enum DragSelection -> "AllParts" или { part = номер с нуля }.
-- enum DragBindingError -> строки.
drag.DragSelection = { AllParts = "AllParts" }
drag.DragBindingError = { PartOutsideAssembly = "PartOutsideAssembly", InertiaOutsideStorage = "InertiaOutsideStorage" }

local BodyInertias = {}
drag.BodyInertias = BodyInertias

-- Exact valid-binding setter82D9CD60. Invalid host bindings are rejected
-- before writes; native would address invalid storage rather than recover.
-- All-parts order is0..count, with four resolved handles before each group
-- of four writes and a remaining single-part tail. Only inertia+32 changes.
-- ROBLOX: Result<(), DragBindingError> -> (true) или (nil, ошибка).
function BodyInertias.set_linear_drag(self: BodyInertias, value: number, selection: any): (boolean?, string?)
	local selected: { number }
	if selection == drag.DragSelection.AllParts then
		selected = self.part_inertia_indices
	else
		local index = self.part_inertia_indices[selection.part + 1]
		if selection.part < 0 or index == nil then
			return nil, drag.DragBindingError.PartOutsideAssembly
		end
		selected = { index }
	end
	for _, index in selected do
		if index >= #self.inertias then
			return nil, drag.DragBindingError.InertiaOutsideStorage
		end
	end
	local groups = #selected // 4
	for g = 0, groups - 1 do
		local coefficient = f32(value * DRAG_FREQUENCY)
		for k = 1, 4 do
			self.inertias[selected[g * 4 + k] + 1].linear_drag = coefficient
		end
	end
	for k = groups * 4 + 1, #selected do
		self.inertias[selected[k] + 1].linear_drag = f32(value * DRAG_FREQUENCY)
	end
	return true, nil
end

-- Ground82D392B4: after either ordinary tag16 or alternate tag7 submission,
-- apply the drag retained from82D39104 to all parts. The caller owns the
-- remaining force-strength flag and ground-correction helpers afterward.
function BodyInertias.apply_ground_drag(self: BodyInertias, calculated_drag: number): (boolean?, string?)
	return BodyInertias.set_linear_drag(self, calculated_drag, drag.DragSelection.AllParts)
end

return drag
