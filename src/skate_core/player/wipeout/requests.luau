--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout/requests.rs (коммит 2e16697)
--
-- Original request arrays20/56,count200,mode208 and timers192/196/204.
-- ROBLOX: индексы причин с нуля, как в Rust: reasons[index + 1].

local rt = require("../../../rt")
local data = require("./data")

local from_bits = rt.from_bits

local requests = {}

export type Requests = {
	reasons: { boolean }, -- [bool; 34]
	values: { number }, -- [f32; 34]
	count: number,
	cooldown: number,
	contact_frames: number,
	balance: number,
	mode: number,
}

local Requests = {}
requests.Requests = Requests

-- Player ctor82DB20B8..D8 and first ClearRequests initialize this storage.
function Requests.new(): Requests
	return {
		reasons = table.create(34, false),
		values = table.create(34, 0.0),
		count = 0,
		cooldown = 0.0,
		contact_frames = 0,
		balance = 0.0,
		mode = 0,
	}
end
-- ROBLOX: #[derive(Clone)].
function Requests.clone(self: Requests): Requests
	local c = table.clone(self)
	c.reasons = table.clone(self.reasons)
	c.values = table.clone(self.values)
	return c
end
-- Player initialization82DB3024 supplies the short initial grace period.
function Requests.initialize_player(self: Requests)
	self.cooldown = from_bits(0x3d23_d70a)
end
-- Teleport82DB8DB4 overwrites only the cooldown; ResetSystems is separate.
function Requests.teleport(self: Requests)
	self.cooldown = from_bits(0x3ecc_cccd)
end
-- Ground Enter82D378E0..F4 and CheckForGroundWipeout share this state.
function Requests.enter_ground(self: Requests)
	if self.mode ~= 1 then
		self.balance = 0.0
		self.mode = 1
	end
end
-- A repeated request increments the original counter even if its bit was set.
function Requests.request(self: Requests, index: number, value: number)
	self.reasons[index + 1] = true
	self.values[index + 1] = value
	self.count = rt.wrapping_add_u32(self.count, 1)
end
-- SystemLogic82DB6000 after state selection: preserve cooldown and histories.
function Requests.clear_after_selection(self: Requests)
	for i = 1, 34 do
		self.reasons[i] = false
		self.values[i] = 0.0
	end
	self.count = 0
end
-- ResetSystems82DB9354..9360 clears mode and count only.
function Requests.reset_systems(self: Requests)
	self.mode = 0
	self.count = 0
end
-- 82DB9188: count reflects individual triggers, not unique reasons.
function Requests.requests_runout(self: Requests, frame: data.RequestInput): boolean
	return (
		self.count == 1
		and (self.reasons[3] or self.reasons[25] or self.reasons[11])
		and not bit32.btest(frame.flags_2468, bit32.lshift(1, 5))
		and not bit32.btest(frame.flags_2476, bit32.lshift(1, 26))
		and math.abs(frame.animation_up_y) > from_bits(0x3f4f_5c29)
	) or (bit32.btest(frame.flags_2484, bit32.lshift(1, 12)) and frame.category == 400)
end
-- 82DB9100 first excludes runout, then combines reason OR with2480bit3.
function Requests.requests_wipeout(self: Requests, frame: data.RequestInput): boolean
	if Requests.requests_runout(self, frame) then
		return false
	end
	for _, v in self.reasons do
		if v then
			return true
		end
	end
	return bit32.btest(frame.flags_2480, bit32.lshift(1, 3))
end

return requests
