--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/mass.rs (коммит 2e16697)
--
-- Recovered board-part mass properties, separate from integration.
-- ROBLOX: подмодули `#[path = "construction/..."]` лежат в construction/
-- и подключаются оттуда; их типы берём из тех файлов, без переэкспорта.

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")
local rigid_body = require("./rigid_body")
local primitive_mass_mod = require("./construction/primitive_mass")
local board_parts = require("./construction/board_parts")
local deck_geometry = require("./construction/deck_geometry")
local mass_moments = require("./construction/mass_moments")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

type Vector3 = vector
type RetailBodyMassProperties = rigid_body.RetailBodyMassProperties
type RetailLocalMassFrame = rigid_body.RetailLocalMassFrame

local mass = {}

-- fn refined_reciprocal(value: f32) -> f32
-- ROBLOX: в Rust приватная, но её зовут дочерние модули construction/* (super::).
function mass.refined_reciprocal(value: number): number
	local estimate = native_arithmetic.reciprocal_estimate(value)
	for _ = 1, 2 do
		local residual = mul_add(-estimate, value, 1.0)
		estimate = mul_add(estimate, residual, estimate)
	end
	return estimate
end
local refined_reciprocal = mass.refined_reciprocal

mass.RETAIL_UNBOUNDED_VELOCITY = from_bits(0x7F7F_FFFF)
mass.RETAIL_WHEEL_MAXIMUM_ANGULAR_VELOCITY = from_bits(0x476A_5FFF)

-- Final finite path in TU3 `ComputeMassProperties` (`0x82AE7770`). The Xenon
-- reciprocal estimate is followed by two fused Newton refinements for each
-- principal moment. Inverse mass and the spherical energy term use scalar
-- division in the recovered function.
local function finalize_principal_mass(
	local_mass_frame: RetailLocalMassFrame,
	body_mass: number,
	principal_moments: Vector3,
	maximum_angular_velocity: number,
	angular_drag: number
): RetailBodyMassProperties
	local inverse_tensor = vector.create(
		refined_reciprocal(principal_moments.x),
		refined_reciprocal(principal_moments.y),
		refined_reciprocal(principal_moments.z)
	)
	-- S3 82AE7A98/7AAC and S2 82AE9DA0/9DB4 retain the left operand
	-- only for ordered LT. Rust min would discard a right-hand NaN.
	local smallest_xy = if inverse_tensor.x < inverse_tensor.y then inverse_tensor.x else inverse_tensor.y
	local smallest_inverse = if smallest_xy < inverse_tensor.z then smallest_xy else inverse_tensor.z
	return {
		local_mass_frame = local_mass_frame,
		dynamics = {
			inverse_tensor = inverse_tensor,
			inverse_mass = f32(1.0 / body_mass),
			spherical = f32(1.0 / smallest_inverse),
			maximum_linear_velocity = mass.RETAIL_UNBOUNDED_VELOCITY,
			maximum_angular_velocity = maximum_angular_velocity,
			linear_drag = 0.0,
			angular_drag = angular_drag,
		},
	}
end

-- TU3 ComputeMassProperties82AE7770 for one centered primitive. Skeleton
-- parts use this same finalizer as board parts, including volume fallback
-- when the requested mass is strictly below MIN_POSITIVE; NaN is preserved.
-- pub fn primitive_mass_properties(input, maximum_angular_velocity, angular_drag) -> Option<...>
function mass.primitive_mass_properties(
	input: board_parts.PartMassInput,
	maximum_angular_velocity: number,
	angular_drag: number
): RetailBodyMassProperties?
	local primitive = primitive_mass_mod.primitive_mass(input.shape)
	if primitive == nil then
		return nil
	end
	local body_mass = if input.requested_mass < rt.F32_MIN_POSITIVE then primitive.volume else input.requested_mass
	local inertia = primitive.moments_per_unit_mass
	return finalize_principal_mass(
		rigid_body.RetailLocalMassFrame.IDENTITY(),
		body_mass,
		vector.create(f32(inertia.x * body_mass), f32(inertia.y * body_mass), f32(inertia.z * body_mass)),
		maximum_angular_velocity,
		angular_drag
	)
end

-- 82AE78BC..79DC: omit negligible local-frame corrections, otherwise store
-- inverseBodyLTM. The inverse translation starts with Z, then adds Y and X
-- through fused operations, as in the native matrix transpose/inverse path.
local function inverse_mass_frame(forward: RetailLocalMassFrame, inertia: Vector3): RetailLocalMassFrame
	local center = forward.translation
	local center_squared = native_arithmetic.dot3({ center.x, center.y, center.z, 0.0 }, { center.x, center.y, center.z, 0.0 })
	local minimum_offset_squared = f32(f32(f32(inertia.y + inertia.z) + inertia.x) * from_bits(0x3586_37BE))
	-- S3 82AE78EC / S2 82AE9BE0: bge after fcmpu means LT is clear,
	-- so an unordered comparison also retains the inverse mass frame.
	local translated = not (center_squared < minimum_offset_squared)
	local rotated = false
	local threshold = from_bits(0x3A83_126F)
	for column = 1, 3 do
		for row = 1, 3 do
			local identity = if column == row then 1.0 else 0.0
			if math.abs(f32(forward.basis.columns[column][row] - identity)) > threshold then
				rotated = true
			end
		end
	end
	if not translated and not rotated then
		return rigid_body.RetailLocalMassFrame.IDENTITY()
	end
	local columns = {}
	for column = 1, 3 do
		columns[column] = {}
		for row = 1, 3 do
			columns[column][row] = forward.basis.columns[row][column]
		end
	end
	local negative_center = { f32(0.0 - center.x), f32(0.0 - center.y), f32(0.0 - center.z) }
	local translation = {}
	for row = 1, 3 do
		translation[row] = mul_add(
			negative_center[1],
			columns[1][row],
			mul_add(negative_center[2], columns[2][row], f32(negative_center[3] * columns[3][row]))
		)
	end
	return {
		basis = { columns = columns },
		translation = vector.create(translation[1], translation[2], translation[3]),
	}
end

-- TU3 ComputeMassProperties82AE7770 after compound-volume accumulation.
-- The caller may apply a source-owned part-frame override after this result.
-- ROBLOX: `mut moments` по значению — работаем с копией, аргумент не меняется.
-- pub fn aggregate_mass_properties(moments, requested_mass, maximum_angular_velocity, angular_drag)
function mass.aggregate_mass_properties(
	moments_in: mass_moments.MassMoments,
	requested_mass: number,
	maximum_angular_velocity: number,
	angular_drag: number
): RetailBodyMassProperties
	local moments = mass_moments.MassMoments.copy(moments_in)
	local properties = mass_moments.MassMoments.principal_properties(moments)
	-- 82AE79EC BO4/BI24 skips fallback when CR6.LT is clear, including NaN.
	local body_mass = if requested_mass < rt.F32_MIN_POSITIVE then properties.volume else requested_mass
	local inertia = properties.moments_per_unit_mass
	return finalize_principal_mass(
		inverse_mass_frame(properties.local_mass_frame, inertia),
		body_mass,
		vector.create(f32(inertia.x * body_mass), f32(inertia.y * body_mass), f32(inertia.z * body_mass)),
		maximum_angular_velocity,
		angular_drag
	)
end

-- Stock wheel properties produced by TU3 `0x82C0AA78 -> 0x82AE7770`.
function mass.retail_wheel_mass_properties(): RetailBodyMassProperties
	return mass.wheel_mass_properties(board_parts.WheelMassSettings.STOCK())
end

function mass.wheel_mass_properties(settings: board_parts.WheelMassSettings): RetailBodyMassProperties
	local forward = board_parts.forward_mass_properties(board_parts.wheel_mass_input(settings))
	assert(forward, "the stock wheel is a supported sphere")
	return finalize_principal_mass(
		rigid_body.RetailLocalMassFrame.IDENTITY(),
		forward.mass,
		forward.principal_moments,
		mass.RETAIL_WHEEL_MAXIMUM_ANGULAR_VELOCITY,
		0.0
	)
end

-- Stock truck properties produced by TU3 `0x82C0A6F8 -> 0x82AE7770`.
function mass.retail_truck_mass_properties(): RetailBodyMassProperties
	return mass.truck_mass_properties(board_parts.TruckMassSettings.STOCK())
end

function mass.truck_mass_properties(settings: board_parts.TruckMassSettings): RetailBodyMassProperties
	local forward = board_parts.forward_mass_properties(board_parts.truck_mass_input(settings))
	assert(forward, "the stock truck is a supported capsule")
	return finalize_principal_mass(
		rigid_body.RetailLocalMassFrame.IDENTITY(),
		forward.mass,
		forward.principal_moments,
		mass.RETAIL_UNBOUNDED_VELOCITY,
		0.0
	)
end

-- TU3 deck construction82C09290 -> mass accumulation82AE7058 ->
-- ComputeMassProperties82AE7770. Every authored child contributes to mass.
-- pub fn deck_mass_properties(geometry: &DeckGeometry, mass: f32, angular_drag: f32)
function mass.deck_mass_properties(
	geometry: deck_geometry.DeckGeometry,
	deck_mass: number,
	angular_drag: number
): RetailBodyMassProperties
	local properties = mass.aggregate_mass_properties(
		deck_geometry.DeckGeometry.mass_moments(geometry),
		deck_mass,
		mass.RETAIL_UNBOUNDED_VELOCITY,
		angular_drag
	)
	-- 82C0A264..278 overrides the deck inverse-body local transform after
	-- calculating its principal inertia. Keep that inertia, reset the frame.
	properties.local_mass_frame = rigid_body.RetailLocalMassFrame.IDENTITY()
	return properties
end

-- Stock convenience constructor; the game supplies its loaded XML settings.
function mass.retail_deck_mass_properties(): RetailBodyMassProperties
	local geometry = deck_geometry.DeckGeometry.new(deck_geometry.DeckGeometrySettings.STOCK())
	-- physicsdeck.DeckMass * physics_world.SkateboardMassFactor,
	-- DeckAngularDrag * the refined fixed-step Simulation::frequency.
	return mass.deck_mass_properties(geometry, 6.0, f32(from_bits(0x3EE6_6666) * from_bits(0x426F_FFFF)))
end

-- Body order used by `SkateboardBody`: wheels 0..3, trucks 4..5, deck 6.
function mass.default_skateboard_mass_properties(): { RetailBodyMassProperties }
	return {
		mass.retail_wheel_mass_properties(),
		mass.retail_wheel_mass_properties(),
		mass.retail_wheel_mass_properties(),
		mass.retail_wheel_mass_properties(),
		mass.retail_truck_mass_properties(),
		mass.retail_truck_mass_properties(),
		mass.retail_deck_mass_properties(),
	}
end

return mass
