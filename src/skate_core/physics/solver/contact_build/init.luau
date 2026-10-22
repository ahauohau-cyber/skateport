--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/contact_build.rs (коммит 2e16697)
--
-- TU3 ContactBatchBuild `82AE10C8`: contact geometry, mass response and targets.
--
-- Arithmetic is reconstructed for finite inputs and finite intermediates. The
-- reciprocal response uses the isolated accepted Xenon `vrefp` approximation;
-- callers can still inject captured hardware results through
-- ContactMassResponse without changing the recovered builder order.

local native_arithmetic = require("../native_arithmetic")
local input = require("@self/input")
local geometry = require("@self/geometry")
local publication = require("@self/publication")

type Vector3 = vector

local contact_build = {}

-- Complete preparation before the native reciprocal-estimate operation.
-- ROBLOX: приватные поля Rust (reaction_ids и др.) — обычные поля таблицы.
export type ContactPreparation = {
	arms: { Vector3 },
	axes: { Vector3 },
	active: { boolean },
	inverse_mass: { number },
	point_acceleration: { Vector3 },
	-- XYZ inverse-inertia response; W is the native packed carry value.
	angular_response_a: { { number } },
	angular_response_b: { { number } },
	-- Angular response plus both inverse masses, in normal/tangent order.
	effective_mass: { number },
	separation_projection: { number },
	restitution_projection: { number },
	predicted_separation_projection: { number },
	reaction_ids: { number },
	body_ids: { number },
	static_friction_bits: number,
	dynamic_friction_bits: number,
	contact_tag: number,
	combined_state_bit_8: number,
}

-- pub enum ContactBuildError { ReciprocalEstimateUnavailable { effective_mass } }
export type ContactBuildError = { kind: "ReciprocalEstimateUnavailable", effective_mass: { number } }

-- pub trait ContactMassResponse
-- ROBLOX: трейт -> таблица с методом; Result -> (значение) или (nil, ошибка).
export type ContactMassResponse = {
	inverse_effective_mass: (self: any, effective_mass: { number }) -> ({ number }?, ContactBuildError?),
}

-- pub struct UnavailableContactMassResponse
contact_build.UnavailableContactMassResponse = {
	inverse_effective_mass = function(_self: any, effective_mass: { number }): ({ number }?, ContactBuildError?)
		return nil, { kind = "ReciprocalEstimateUnavailable", effective_mass = effective_mass }
	end,
}

-- Default host implementation of the three `vrefp` lanes at `0x82AE158C`.
-- The approximation is isolated in `native_arithmetic` so hardware traces can
-- replace it without changing contact geometry or publication.
contact_build.NativeContactMassResponse = {
	inverse_effective_mass = function(_self: any, effective_mass: { number }): ({ number }?, ContactBuildError?)
		return {
			native_arithmetic.reciprocal_estimate(effective_mass[1]),
			native_arithmetic.reciprocal_estimate(effective_mass[2]),
			native_arithmetic.reciprocal_estimate(effective_mass[3]),
		},
			nil
	end,
}

-- pub fn prepare_contact(record: &[u32; 64], time_step: f32) -> ContactPreparation
function contact_build.prepare_contact(record: { number }, time_step: number): ContactPreparation
	return geometry.prepare(input.ContactInput.decode(record), time_step)
end

-- Builds all rows privately and publishes only after mass response succeeds.
-- ROBLOX: `*record = compile(...)` — слова переписываются в той же таблице.
-- pub fn build_with_response(record, time_step, response) -> Result<(), ContactBuildError>
function contact_build.build_with_response(
	record: { number },
	time_step: number,
	response: ContactMassResponse
): (boolean?, ContactBuildError?)
	local prepared = contact_build.prepare_contact(record, time_step)
	local inverse_response, err = response:inverse_effective_mass(prepared.effective_mass)
	if inverse_response == nil then
		return nil, err
	end
	local words = publication.compile(prepared, inverse_response)
	for i = 1, 64 do
		record[i] = words[i]
	end
	return true, nil
end

-- pub(super) fn build(record: &mut [u32; 64], time_step: f32)
function contact_build.build(record: { number }, time_step: number)
	local ok = contact_build.build_with_response(record, time_step, contact_build.NativeContactMassResponse)
	assert(ok, "the native contact mass response is infallible")
end

return contact_build
