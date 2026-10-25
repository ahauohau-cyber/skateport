-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local Collections = require(sim.import)("skate_data/collections").Collections
local graph8, negative_graph4
local t1 = {}

function t1.load(p2) -- line: 25
    -- upvalues: rt (copy), Collections (copy), graph8 (ref), negative_graph4 (ref)
    local function t(p3) -- line: 26
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "physics_trajectory", "default", p3)
    end

    local function r(p4) -- line: 29
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "physics_reckoning", "default", p4)
    end

    return {
        cone_x = Collections.float(p2, "physics_trajectory", "default", "ConeAngleX"),
        cone_z = Collections.float(p2, "physics_trajectory", "default", "ConeAngleZ"),
        trajectory_max_time = Collections.float(p2, "physics_trajectory", "default", "TrajectoryMaxTime"),
        trajectory_max_drop = Collections.float(p2, "physics_trajectory", "default", "TrajectoryMaxDrop"),
        trajectory_error_start = Collections.float(p2, "physics_trajectory", "default", "TrajectoryMaxErrorStart"),
        trajectory_error_end = Collections.float(p2, "physics_trajectory", "default", "TrajectoryMaxErrorEnd"),
        speed_factor_min = Collections.float(p2, "physics_trajectory", "default", "SpeedFactorMin"),
        speed_factor_max = Collections.float(p2, "physics_trajectory", "default", "SpeedFactorMax"),
        cone_angle_z_vs_speed = graph8(p2, "physics_trajectory", "ConeAngleZVsSpeed", false),
        cone_x_second_pass = Collections.float(p2, "physics_trajectory", "default", "ConeAngleXSecondPass"),
        cone_z_second_pass = Collections.float(p2, "physics_trajectory", "default", "ConeAngleZSecondPass"),
        landing_time_bonus = graph8(p2, "physics_trajectory", "LandingTimeBonus", true),
        landing_com_scalar_vs_slope = graph8(p2, "physics_trajectory", "LandingComScalarVsSlope", true),
        landing_force_scalar = graph8(p2, "physics_trajectory", "LandingForceScalarVsDPVelNorm", false),
        grind_penalty_vs_distance = graph8(p2, "physics_trajectory", "GrindPenaltyVsDistToGrind", true),
        score_middle_bonus = Collections.float(p2, "physics_trajectory", "default", "ScoreMiddleBonus"),
        score_landing_force = Collections.float(p2, "physics_trajectory", "default", "ScoreLandingForce"),
        score_landing_direction = Collections.float(p2, "physics_trajectory", "default", "ScoreLandingDirection"),
        score_transition = Collections.float(p2, "physics_trajectory", "default", "ScoreTransition"),
        surface_unrideable_score = Collections.float(p2, "physics_trajectory", "default", "ScoreSurface_Unrideable"),
        surface_dont_align_score = Collections.float(p2, "physics_trajectory", "default", "ScoreSurface_DontAlign"),
        natural_air_off_verts_scalar = Collections.float(p2, "physics_trajectory", "default", "NaturalAirOffVertsScalar"),
        minimum_valid_time = Collections.float(p2, "physics_trajectory", "default", "MinTimeForTrajectoryToBeValid"),
        minimum_time_after_apex = Collections.float(p2, "physics_trajectory", "default", "MinTimeAfterApexForTransition"),
        minimum_normal_delta_second_pass = Collections.float(p2, "physics_trajectory", "default", "MinNormalDeltaForSecondPass"),
        maximum_trajectory_adjust = Collections.float(p2, "physics_trajectory", "default", "MaxTrajectoryAdjust"),
        wall_ride_test_distance = Collections.float(p2, "physics_trajectory", "default", "WallRideTestDist"),
        wall_ride_minimum_height = Collections.float(p2, "physics_trajectory", "default", "WallRideMinHeightFromGround"),
        wall_ride_angle_allow_landing = Collections.float(p2, "physics_trajectory", "default", "WallRideAngleToAllowLanding"),
        wall_ride_height_score = Collections.float(p2, "physics_trajectory", "default", "ScoreWallrideHeight"),
        wall_ride_boost = negative_graph4(p2, "physics_trajectory", "WallRideBoost"),
        wall_ride_normal_dot_limit = Collections.float(p2, "physics_feet", "default", "WallRideMaxDotFloorWall"),
        displacement_vs_speed = graph8(p2, "physics_reckoning", "TrajectoryDispVsSpeed", false),
        displacement_vs_ground_normal = graph8(p2, "physics_reckoning", "TrajectoryDispVsGroundNorm", false),
        trajectory_radius = Collections.float(p2, "physics_reckoning", "default", "TrajectoryRadius"),
        trajectory_displacement = Collections.float(p2, "physics_reckoning", "default", "TrajectoryDisplacement"),
        minimum_trajectory_frames = rt.to_i32(Collections.integer(p2, "physics_reckoning", "default", "MinTrajectorySize")),
        vert_jump_align_factor = Collections.float(p2, "physics_reckoning", "default", "VertJumpAlignFactor"),
        vert_jump_align_max_ground_normal_y = Collections.float(p2, "physics_reckoning", "default", "VertJumpAlignMaxGroundNormalY"),
        vert_jump_align_min_direction_y = Collections.float(p2, "physics_reckoning", "default", "VertJumpAlignMinJumpDirY"),
        vert_jump_align_max_angle = Collections.float(p2, "physics_reckoning", "default", "VertJumpAlignMaxAngle")
    }
end

function graph8(p5, p6, p7, p8) -- line: 81
    -- upvalues: v1 (copy), Collections (copy)
    local v2 = if p8 then "Sk8::PointNegGraphData8" else "Sk8::PointGraphData8"

    if Collections.field(p5, p6, "default", p7).type_name ~= v2 then
        error(string.format("Wrong stock graph type %s/%s", p6, p7), 0)
    end

    local t2, t3

    if p8 then
        local v3 = Collections.words(p5, 20, p6, "default", p7)

        buffer.writeu32(v1, 0, v3[5])

        local v5 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[6])

        local v7 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[7])

        local v9 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[8])

        local v11 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[9])

        local v13 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[10])

        local v15 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[11])

        local v17 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[12])
        t2 = {
            v5,
            v7,
            v9,
            v11,
            v13,
            v15,
            v17,
            (buffer.readf32(v1, 0))
        }
        buffer.writeu32(v1, 0, v3[13])

        local v20 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[14])

        local v22 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[15])

        local v24 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[16])

        local v26 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[17])

        local v28 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[18])

        local v30 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[19])

        local v32 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[20])
        t3 = {
            v20,
            v22,
            v24,
            v26,
            v28,
            v30,
            v32,
            (buffer.readf32(v1, 0))
        }
    else
        local v34 = Collections.words(p5, 16, p6, "default", p7)

        buffer.writeu32(v1, 0, v34[1])

        local v36 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[2])

        local v38 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[3])

        local v40 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[4])

        local v42 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[5])

        local v44 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[6])

        local v46 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[7])

        local v48 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[8])
        t2 = {
            v36,
            v38,
            v40,
            v42,
            v44,
            v46,
            v48,
            (buffer.readf32(v1, 0))
        }
        buffer.writeu32(v1, 0, v34[9])

        local v51 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[10])

        local v53 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[11])

        local v55 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[12])

        local v57 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[13])

        local v59 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[14])

        local v61 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[15])

        local v63 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v34[16])
        t3 = {
            v51,
            v53,
            v55,
            v57,
            v59,
            v61,
            v63,
            (buffer.readf32(v1, 0))
        }
    end

    return {
        x = t2,
        y = t3
    }
end

t1.graph8 = graph8

function negative_graph4(p9, p10, p11) -- line: 138
    -- upvalues: v1 (copy), Collections (copy)
    if Collections.field(p9, p10, "default", p11).type_name ~= "Sk8::PointNegGraphData4" then
        error(string.format("Wrong stock graph type %s/%s", p10, p11), 0)
    end

    local v65 = Collections.words(p9, 12, p10, "default", p11)
    local t4 = {}

    buffer.writeu32(v1, 0, v65[5])

    local v67 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[6])

    local v69 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[7])

    local v71 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[8])
    t4.x = {
        v67,
        v69,
        v71,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v65[9])

    local v74 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[10])

    local v76 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[11])

    local v78 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[12])
    t4.y = {
        v74,
        v76,
        v78,
        (buffer.readf32(v1, 0))
    }

    return t4
end

t1.negative_graph4 = negative_graph4

return t1
