-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/physics/drive_parameters")
local RetailDriveParams, RetailDriveType = v1.RetailDriveParams, v1.RetailDriveType
local t1 = {
    FREQUENCY = 59.999996185302734,
    FREQUENCY_SQUARED = 3599.99951171875,
    HARD_VELOCITY = 599.9999389648438,
    HARD_STRENGTH = 35999.99609375
}
local FREQUENCY, FREQUENCY_SQUARED, HARD_VELOCITY, HARD_STRENGTH = t1.FREQUENCY, t1.FREQUENCY_SQUARED, t1.HARD_VELOCITY, t1.HARD_STRENGTH

t1.AnimationDriveSettings = {}
t1.DriveInterpolation = {}
t1.BoneDriveSettings = {}
t1.BoneDriveDynamics = {}

function t1.BoneDriveDynamics.default() -- line: 43
    -- upvalues: rt (copy), RetailDriveParams (copy)
    return {
        mode = 0,
        transition_counter = 0,
        transition_active = false,
        channels = rt.filled(2, {
            linear = RetailDriveParams.DISABLED,
            angular = RetailDriveParams.DISABLED
        }),
        strengths = table.create(2, 0)
    }
end

local DISABLED = RetailDriveParams.DISABLED
local HardDrive, SoftDrive = RetailDriveType.HardDrive, RetailDriveType.SoftDrive

local function set_params(p1, p2, p3, p4, p5) -- line: 62
    p1.spring_or_max_velocity = p2
    p1.damping = p3
    p1.max_strength = p4
    p1.drive_type = p5
end

local function interpolated(p6, p7, p8) -- line: 70
    -- upvalues: FREQUENCY (copy), FREQUENCY_SQUARED (copy)
    local v2 = p6.spring[1] * p7
    local v3 = p6.strength[1] * p7
    local v4 = (p6.spring[2] * p7 - v2) * p8 + v2
    local v5 = (p6.strength[2] * p7 - v3) * p8 + v3
    local v6 = (p6.damping[2] - p6.damping[1]) * p8 + p6.damping[1]

    if not (v4 >= 0) then
        v4 = 0
    end

    local v7 = v4 * FREQUENCY

    if not (v5 >= 0) then
        v5 = 0
    end

    local v8 = v5 * FREQUENCY_SQUARED

    if v6 >= 0 then
        return v7, v8, v6
    end

    return v7, v8, 0
end

function t1.BoneDriveDynamics.enable(p9, p10, p11, p12) -- line: 97
    -- upvalues: t1 (copy), FREQUENCY (copy), FREQUENCY_SQUARED (copy), HARD_VELOCITY (copy), HARD_STRENGTH (copy), DISABLED (copy), HardDrive (copy), SoftDrive (copy), interpolated (copy)
    if not (p10 < 2) then
        error("assertion failed: channel < 2", 0)
    end

    local mode = p9.mode

    if mode > 5 then
        return
    end

    local channels = p9.channels
    local v9 = channels[p10 + 1]
    local v10 = channels[2 - p10]
    local v11 = type(v9) == "table" and v9 ~= v10
    local v12, linear, angular

    if v11 then
        local linear2, angular2 = v9.linear, v9.angular

        v12 = type(linear2) == "table" and type(angular2) == "table" and linear2 ~= angular2 and linear2 ~= DISABLED and angular2 ~= DISABLED and linear2 ~= v9 and angular2 ~= v9
        linear = linear2
        angular = angular2
    else
        v12 = v11
    end

    local v13

    if v12 and type(v10) == "table" then
        local linear2, angular2 = v10.linear, v10.angular

        v13 = linear ~= linear2 and linear ~= angular2 and angular ~= linear2 and angular ~= angular2 and linear ~= v10 and angular ~= v10
    else
        v13 = v12
    end

    if not v13 then
        return t1.BoneDriveDynamics.enable_reference(p9, p10, p11, p12)
    end

    if mode ~= 5 then
        p9.transition_active = false
    end

    local v14 = p12.animation[p10 + 1]

    if mode == 0 then
        local v15 = v14.linear_displacement * FREQUENCY
        local v16 = v14.linear_strength * FREQUENCY_SQUARED
        local v17 = v14.angular_displacement * FREQUENCY
        local v18 = v14.angular_strength * FREQUENCY_SQUARED

        linear.spring_or_max_velocity = v15
        linear.damping = 0
        linear.max_strength = v16
        linear.drive_type = HardDrive
        angular.spring_or_max_velocity = v17
        angular.damping = 0
        angular.max_strength = v18
        angular.drive_type = HardDrive
    elseif mode == 1 then
        linear.spring_or_max_velocity = HARD_VELOCITY
        linear.damping = 0
        linear.max_strength = HARD_STRENGTH
        linear.drive_type = HardDrive
        angular.spring_or_max_velocity = HARD_VELOCITY
        angular.damping = 0
        angular.max_strength = HARD_STRENGTH
        angular.drive_type = HardDrive
    elseif mode == 2 then
        local v19 = v14.angular_displacement * FREQUENCY
        local v20 = v14.angular_strength * FREQUENCY_SQUARED

        linear.spring_or_max_velocity = 0
        linear.damping = 0
        linear.max_strength = 0
        linear.drive_type = HardDrive
        angular.spring_or_max_velocity = v19
        angular.damping = 0
        angular.max_strength = v20
        angular.drive_type = HardDrive
    elseif mode == 3 then
        local v21 = p12.collision_soft_displacement * p11
        local v22 = p12.collision_soft_strength * p11 * FREQUENCY_SQUARED

        linear.spring_or_max_velocity = 0
        linear.damping = 0
        linear.max_strength = 0
        linear.drive_type = SoftDrive
        angular.spring_or_max_velocity = v21
        angular.damping = 200
        angular.max_strength = v22
        angular.drive_type = SoftDrive
    elseif mode == 4 then
        local v23, v24, v25

        if p11 <= 0.5 then
            v23 = 0
            v24 = 0
            v25 = 0
        else
            v23 = p12.ragdoll_soft_displacement * p11 * 0.5
            v24 = 200
            v25 = p11 * p12.ragdoll_soft_strength * FREQUENCY_SQUARED
        end

        local v26 = p12.ragdoll_soft_displacement * p11
        local v27 = p11 * p12.ragdoll_soft_strength * FREQUENCY_SQUARED

        linear.spring_or_max_velocity = v23
        linear.damping = v24
        linear.max_strength = v25
        linear.drive_type = SoftDrive
        angular.spring_or_max_velocity = v26
        angular.damping = 200
        angular.max_strength = v27
        angular.drive_type = SoftDrive
    elseif mode == 5 then
        if p9.transition_active then
            if p9.transition_counter < p12.transition_calls then
                p9.transition_counter += 1
            end
        else
            p9.transition_active = true
            p9.transition_counter = 1
        end

        local v28 = p9.transition_counter / p12.transition_calls
        local v29, v30, v31 = interpolated(p12.transition_linear, p11, v28)
        local v32, v33, v34 = interpolated(p12.transition_angular, p11, v28)

        linear.spring_or_max_velocity = v29
        linear.damping = v31
        linear.max_strength = v30
        linear.drive_type = HardDrive
        angular.spring_or_max_velocity = v32
        angular.damping = v34
        angular.max_strength = v33
        angular.drive_type = HardDrive
    else
        error("internal error: entered unreachable code", 0)
    end
end

function t1.BoneDriveDynamics.enable_reference(p13, p14, p15, p16) -- line: 196
    -- upvalues: t1 (copy), FREQUENCY (copy), FREQUENCY_SQUARED (copy), HARD_VELOCITY (copy), HARD_STRENGTH (copy)
    if not (p14 < 2) then
        error("assertion failed: channel < 2", 0)
    end

    if p13.mode > 5 then
        return
    end

    if p13.mode ~= 5 then
        p13.transition_active = false
    end

    local v35 = p16.animation[p14 + 1]
    local mode = p13.mode
    local t2

    if mode == 0 then
        t2 = {
            linear = t1.hard(v35.linear_displacement * FREQUENCY, v35.linear_strength * FREQUENCY_SQUARED),
            angular = t1.hard(v35.angular_displacement * FREQUENCY, v35.angular_strength * FREQUENCY_SQUARED)
        }
    elseif mode == 1 then
        t2 = {
            linear = t1.hard(HARD_VELOCITY, HARD_STRENGTH),
            angular = t1.hard(HARD_VELOCITY, HARD_STRENGTH)
        }
    elseif mode == 2 then
        t2 = {
            linear = t1.hard(0, 0),
            angular = t1.hard(v35.angular_displacement * FREQUENCY, v35.angular_strength * FREQUENCY_SQUARED)
        }
    elseif mode == 3 then
        t2 = {
            linear = t1.soft(0, 0, 0),
            angular = t1.soft(p16.collision_soft_displacement * p15, 200, p16.collision_soft_strength * p15 * FREQUENCY_SQUARED)
        }
    elseif mode == 4 then
        t2 = {
            linear = if p15 <= 0.5 then t1.soft(0, 0, 0) else t1.soft(p16.ragdoll_soft_displacement * p15 * 0.5, 200, p15 * p16.ragdoll_soft_strength * FREQUENCY_SQUARED),
            angular = t1.soft(p16.ragdoll_soft_displacement * p15, 200, p15 * p16.ragdoll_soft_strength * FREQUENCY_SQUARED)
        }
    elseif mode == 5 then
        if p13.transition_active then
            if p13.transition_counter < p16.transition_calls then
                p13.transition_counter += 1
            end
        else
            p13.transition_active = true
            p13.transition_counter = 1
        end

        local v36 = p13.transition_counter / p16.transition_calls

        t2 = {
            linear = t1.interpolate(p16.transition_linear, p15, v36),
            angular = t1.interpolate(p16.transition_angular, p15, v36)
        }
    else
        error("internal error: entered unreachable code", 0)
    end

    p13.channels[p14 + 1] = t2
end

function t1.hard(p17, p18) -- line: 270
    -- upvalues: RetailDriveType (copy)
    return {
        damping = 0,
        spring_or_max_velocity = p17,
        max_strength = p18,
        drive_type = RetailDriveType.HardDrive
    }
end

function t1.soft(p19, p20, p21) -- line: 279
    -- upvalues: RetailDriveType (copy)
    return {
        spring_or_max_velocity = p19,
        damping = p20,
        max_strength = p21,
        drive_type = RetailDriveType.SoftDrive
    }
end

function t1.interpolate(p22, p23, p24) -- line: 288
    -- upvalues: RetailDriveType (copy), FREQUENCY (copy), FREQUENCY_SQUARED (copy)
    local v37 = p22.spring[1] * p23
    local v38 = p22.strength[1] * p23
    local v39 = (p22.spring[2] * p23 - v37) * p24 + v37
    local v40 = (p22.strength[2] * p23 - v38) * p24 + v38
    local v41 = (p22.damping[2] - p22.damping[1]) * p24 + p22.damping[1]

    local function nonnegative(p25) -- line: 296
        if p25 >= 0 then
            return p25
        end

        return 0
    end

    if not (v39 >= 0) then
        v39 = 0
    end

    local t3 = {}

    t3.spring_or_max_velocity = v39 * FREQUENCY

    if not (v40 >= 0) then
        v40 = 0
    end

    t3.max_strength = v40 * FREQUENCY_SQUARED
    t3.damping = if not (v41 >= 0) then 0 else v41
    t3.drive_type = RetailDriveType.HardDrive

    return t3
end

return t1
