-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local IDENTITY = require(sim.import)("skate_core/physics/skeleton_animation_record").IDENTITY
local t1 = {
    GroundLaunchInfo = {}
}

function t1.GroundLaunchInfo.default() -- line: 37
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        cone_angle_x = 0,
        cone_angle_z = 0,
        time_step = 0,
        flag_269 = false,
        wall_jump = false,
        flags_270 = 0,
        system = rt.copy(IDENTITY),
        inverse_system = rt.copy(IDENTITY),
        velocity = { 0, 0, 0, 0 },
        angular_velocity = { 0, 0, 0, 0 },
        skeleton_vector_16208 = { 0, 0, 0, 0 },
        skeleton_vector_16240 = { 0, 0, 0, 0 },
        board_position = { 0, 0, 0, 0 },
        physical_center_of_mass = { 0, 0, 0, 0 },
        vector_224 = { 0, 0, 0, 0 },
        vector_240 = { 0, 0, 0, 0 }
    }
end

t1.GroundLaunchPhysical = {}

function t1.GroundLaunchInfo.selector_launch(p1) -- line: 76
    -- upvalues: rt (copy)
    return {
        reckoning_transform = rt.copy(p1.system),
        reckoning_inverse = rt.copy(p1.inverse_system),
        start_velocity = rt.copy(p1.velocity),
        com_velocity = rt.copy(p1.angular_velocity),
        skeleton_vector_160 = rt.copy(p1.skeleton_vector_16208),
        skeleton_vector_176 = rt.copy(p1.skeleton_vector_16240),
        board_position = rt.copy(p1.board_position),
        animation_com_position = rt.copy(p1.physical_center_of_mass),
        start_position_override = rt.copy(p1.vector_224),
        board_position_override = rt.copy(p1.vector_240),
        cone_angle_x = p1.cone_angle_x,
        cone_angle_z = p1.cone_angle_z,
        timestep = p1.time_step,
        player_jumped = p1.wall_jump,
        use_position_override = p1.flag_269,
        trajectory_count = p1.flags_270
    }
end

function t1.GroundLaunchInfo.fill(p2, p3, p4, p5) -- line: 97
    -- upvalues: rt (copy)
    p2.board_position = rt.copy(p3.board_position)
    p2.physical_center_of_mass = rt.copy(p3.physical_center_of_mass)
    p2.skeleton_vector_16208 = rt.copy(p3.skeleton_vector_16208)
    p2.skeleton_vector_16240 = rt.copy(p3.skeleton_vector_16240)
    p2.system = rt.copy(p3.reckoning.system)
    p2.inverse_system = rt.copy(p3.reckoning.inverse_system)
    p2.velocity = rt.copy(p3.velocity)
    p2.angular_velocity = rt.copy(p3.angular_velocity)
    p2.time_step = p3.time_step
    p2.flags_270 = bit32.band(p3.flags_2468, 8192) == 0 and 1 or 7
    p2.cone_angle_x = p4
    p2.cone_angle_z = p5
end

function t1.GroundLaunchInfo.wall_jump(p6, p7) -- line: 113
    -- upvalues: rt (copy)
    p6.velocity = rt.copy(p7)
    p6.angular_velocity = rt.copy(p7)
    p6.wall_jump = true
end

return t1
