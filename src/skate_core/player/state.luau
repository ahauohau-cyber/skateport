--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/state.rs (коммит 2e16697)
--
-- Physical-player state identities and native object ownership from
-- `PhysicalPlayer` construction and `SetPhysicsState` (`0x82DB8540`).
-- ROBLOX: #[repr(u32)] enum PhysicalStateId -> числа (таблица имён ниже).
-- ROBLOX: TryFrom<u32> -> PhysicalStateId.try_from: значение или
-- rt.raise(UnknownPhysicalState).

local rt = require("../../rt")

local state = {}

export type PhysicalStateId = number

local PhysicalStateId = {
	PhysicsGround = 100,
	SlideGround = 101,
	RevertGround = 102,
	GroundAnimation = 103,
	Skitching = 104,
	FollowPath = 105,
	PhysicsAir = 200,
	KnownAir = 201,
	PhysicsAirSecondary = 202,
	WipeoutGround = 300,
	GrindBoardslide = 400,
	GrindFiftyFifty = 401,
	GrindTipslide = 402,
	GrindFiveO = 403,
	GrindBackslash = 404,
	GrindDarkslide = 405,
	BipedGround = 500,
	BipedAir = 501,
	OffBoardPushing = 502,
	LandingOnDeck = 503,
	HandPlant = 600,
	FootPlant = 601,
	Boneless = 602,
	Sleeping = 700,
	Nonspecific = 701,
	Teleporting = 702,
}
state.PhysicalStateId = PhysicalStateId
local S = PhysicalStateId

-- ROBLOX: struct UnknownPhysicalState(pub u32) -> { value = число }.
export type UnknownPhysicalState = { unknown_physical_state: number }

function state.UnknownPhysicalState(value: number): UnknownPhysicalState
	return { unknown_physical_state = value }
end

local OWNER_OFFSET: { [number]: number } = {
	[S.Sleeping] = 1692,
	[S.PhysicsGround] = 1696,
	[S.SlideGround] = 1700,
	[S.RevertGround] = 1704,
	[S.GroundAnimation] = 1708,
	[S.PhysicsAir] = 1712,
	[S.PhysicsAirSecondary] = 1716,
	[S.KnownAir] = 1720,
	[S.GrindDarkslide] = 1724,
	[S.GrindBoardslide] = 1728,
	[S.GrindFiftyFifty] = 1732,
	[S.GrindTipslide] = 1736,
	[S.GrindFiveO] = 1740,
	[S.GrindBackslash] = 1744,
	[S.WipeoutGround] = 1748,
	[S.Nonspecific] = 1752,
	[S.Teleporting] = 1756,
	[S.FollowPath] = 1760,
	[S.BipedGround] = 1764,
	[S.BipedAir] = 1768,
	[S.Skitching] = 1772,
	[S.OffBoardPushing] = 1776,
	[S.HandPlant] = 1780,
	[S.FootPlant] = 1784,
	[S.Boneless] = 1788,
	[S.LandingOnDeck] = 1792,
}

-- ROBLOX: TryFrom<u32>: неизвестный номер -> rt.raise(UnknownPhysicalState).
function PhysicalStateId.try_from(value: number): PhysicalStateId
	if OWNER_OFFSET[value] == nil then
		rt.raise(state.UnknownPhysicalState(value))
	end
	return value
end

PhysicalStateId.ALL = {
	S.PhysicsGround,
	S.SlideGround,
	S.RevertGround,
	S.GroundAnimation,
	S.Skitching,
	S.FollowPath,
	S.PhysicsAir,
	S.KnownAir,
	S.PhysicsAirSecondary,
	S.WipeoutGround,
	S.GrindBoardslide,
	S.GrindFiftyFifty,
	S.GrindTipslide,
	S.GrindFiveO,
	S.GrindBackslash,
	S.GrindDarkslide,
	S.BipedGround,
	S.BipedAir,
	S.OffBoardPushing,
	S.LandingOnDeck,
	S.HandPlant,
	S.FootPlant,
	S.Boneless,
	S.Sleeping,
	S.Nonspecific,
	S.Teleporting,
}

-- Offset of the owning state pointer inside `PhysicalPlayer`.
function PhysicalStateId.native_owner_offset(self: PhysicalStateId): number
	return OWNER_OFFSET[self]
end

-- Category written by native `GetStateCategory` into ProcessedPhysIn.
function PhysicalStateId.category(self: PhysicalStateId): number
	return (self // 100) * 100
end

function PhysicalStateId.is_grind(self: PhysicalStateId): boolean
	return self == S.GrindBoardslide
		or self == S.GrindFiftyFifty
		or self == S.GrindTipslide
		or self == S.GrindFiveO
		or self == S.GrindBackslash
		or self == S.GrindDarkslide
end

return state
