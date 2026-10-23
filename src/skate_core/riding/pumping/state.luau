--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/pumping/state.rs (коммит 2e16697)
--
-- Owned pumping fields. Layout offsets are evidence, not a runtime memory map.

local state_mod = {}

export type PumpingState = {
	-- +0 and +16, cached after every successful Update, including the first.
	previous_position: { number },
	previous_normal: { number },
	-- +32/+36/+40.
	smoothed_height_change: number,
	pumping_time: number,
	previous_height: number,
	-- +44/+48/+52.
	pumping: number,
	pump_acceleration: number,
	angular_speed: number,
	-- +56/+60/+64/+68, also copied to physics output.
	absorption: number,
	ground_normal_absorption: number,
	minimum_crouch: number,
	deck_angle_absorption: number,
	-- +72 is reset but not read or written by Update/Calculate.
	reset_only_scalar: number,
	-- +76 and +81 are the only bytes touched by these three functions.
	record_valid: boolean,
	intentional_pumping: number,
}

export type PumpingOutput = {
	-- Skeleton output +512/+516/+520/+528/+532.
	compression: number,
	absorption: number,
	ground_normal_absorption: number,
	minimum_crouch: number,
	deck_angle_absorption: number,
	-- Ground output +268/+324.
	pump_acceleration: number,
	intentional_pumping: number,
}

local PumpingState = {}
state_mod.PumpingState = PumpingState

-- The output of the recovered reset, not a claim about the constructor.
function PumpingState.reset_state(): PumpingState
	return {
		previous_position = { 0.0, 0.0, 0.0, 0.0 },
		previous_normal = { 0.0, 0.0, 0.0, 0.0 },
		smoothed_height_change = 0.0,
		pumping_time = 0.0,
		previous_height = 0.0,
		pumping = 0.0,
		pump_acceleration = 0.0,
		angular_speed = 0.0,
		absorption = 0.0,
		ground_normal_absorption = 0.0,
		minimum_crouch = 0.0,
		deck_angle_absorption = 0.0,
		reset_only_scalar = 0.0,
		record_valid = false,
		intentional_pumping = 0,
	}
end

-- TU3 82D8F1A0. Does not initialize bytes +77..80 or +82 onward; those
-- are outside this owned state and must be preserved by any binary adapter.
-- Ground Enter 82D378DC and Exit 82D37B58 both call this reset.
function PumpingState.reset(self: PumpingState)
	for k, v in (PumpingState.reset_state() :: any) do
		(self :: any)[k] = v
	end
end

-- Inline FillPhysOut at 82DB6FA8..7000. Read after Update; force assembly
-- consumes pump_acceleration earlier, within Ground Update 82D38800.
function PumpingState.physics_output(self: PumpingState): PumpingOutput
	return {
		compression = 0.0,
		absorption = self.absorption,
		ground_normal_absorption = self.ground_normal_absorption,
		minimum_crouch = self.minimum_crouch,
		deck_angle_absorption = self.deck_angle_absorption,
		pump_acceleration = self.pump_acceleration,
		intentional_pumping = self.intentional_pumping,
	}
end

return state_mod
