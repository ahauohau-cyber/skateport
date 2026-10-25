-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/contact_feedback/board_reports")
local v2 = import("skate_core/physics/contact_feedback/collision_info")
local v3 = import("skate_core/physics/contact_feedback/compression")
local v4 = import("skate_core/physics/contact_feedback/reports")
local v5 = import("skate_core/physics/contact_feedback/spy")

return {
    BoardContactReport = v1.BoardContactReport,
    choose_physics_surface = v2.choose_physics_surface,
    choose_surface = v2.choose_surface,
    reset_frame_collision_info = v2.reset_frame_collision_info,
    average_wheel_compressions = v3.average_wheel_compressions,
    calculate_wheel_compressions = v3.calculate_wheel_compressions,
    part_mass_transform = v3.part_mass_transform,
    ContactReportBuffer = v4.ContactReportBuffer,
    ContactTarget = v4.ContactTarget,
    create_contact_reports = v4.create_contact_reports,
    get_contact_reports = v4.get_contact_reports,
    resolve_contact_reports = v4.resolve_contact_reports,
    spy_contact_jacobians = v5.spy_contact_jacobians,
    spy_contact_jacobians_scalar = v5.spy_contact_jacobians_scalar
}
