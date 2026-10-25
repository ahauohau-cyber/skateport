--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/slide_state/mod.rs (коммит 2e16697)
--
-- PhysicsSlideGround101: Enter82D3A700, Exit82D3A828 and board82D3A900.

local forces = require("@self/forces")

local slide_state = {}

slide_state.forces = forces
slide_state.angular_correction = forces.angular_correction
slide_state.sliding_force = forces.sliding_force

export type SlideInput = forces.SlideInput
export type SlideSettings = forces.SlideSettings
export type SlideSurface = forces.SlideSurface

export type SlideState = {
	start_speed: number,
	steering_push: number,
	damped_turn: number,
	flag48: boolean,
	wall_riding: boolean,
}

local SlideState = {}
slide_state.SlideState = SlideState

-- Host storage; Enter defines every represented native field before use.
function SlideState.new(): SlideState
	return {
		start_speed = 0.0,
		steering_push = 1.0,
		damped_turn = 0.0,
		flag48 = false,
		wall_riding = false,
	}
end

function SlideState.enter(self: SlideState, speed: number)
	self.start_speed = speed
	SlideState.exit(self)
end

function SlideState.exit(self: SlideState)
	self.flag48 = false
	self.wall_riding = false
	self.steering_push = 1.0
	self.damped_turn = 0.0
end

return slide_state
