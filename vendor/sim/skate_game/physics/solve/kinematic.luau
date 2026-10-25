-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local import = require(sim.import)
local v1 = import("skate_core/physics/skeleton_animation_record")
local v2 = import("skate_core/physics/skeleton_body")
local compose_affine = v1.compose_affine
local SkeletonBody = v2.SkeletonBody
local v3, v4
local t1 = {}

t1.DEFAULTS = {
    probe_every = 2,
    probe_speed = 6,
    early = 8,
    land_hold = 12,
    blend = 8,
    hold = 45,
    settle = 6,
    soft = 2,
    riding = true,
    air = true,
    grind = true,
    sleep = true,
    sleep_after = 30,
    sleep_speed = 0.15,
    sleep_spin = 0.6
}
t1.IGNORE_PARTS = {}

local v5
local n1 = 0
local n2 = 0
local n3 = 0
local v6 = table.create(312, 0)
local t2 = {}

t2[1] = v6

local v7 = false
local n4 = 0
local v8 = false
local n5 = 0
local v9 = table.create(156, 0)
local v10 = nil
local self = setmetatable({}, {
    __mode = "k"
})
local v12 = false
local v13
local v14 = table.create(26, 0)
local v15 = false

local function fresh_state() -- line: 96
    -- upvalues: v5 (ref), n1 (ref), n2 (ref), n3 (ref), t2 (copy), v7 (ref), n4 (ref), v8 (ref), n5 (ref), v12 (ref), v13 (ref), v14 (ref), v15 (ref)
    n1 = if v5 ~= nil then v5.settle else 0
    n2 = 0
    n3 = 0
    t2[1] = table.create(312, 0)
    v7 = false
    n4 = if v5 ~= nil then v5.blend else 0
    v8 = false
    n5 = 0
    v12 = false
    v13 = nil
    v15 = false
    v14 = table.create(26, 0)
end

local function bind(p1) -- line: 108
    -- upvalues: n1 (ref), n2 (ref), n3 (ref), t2 (copy), v7 (ref), n4 (ref), v8 (ref), n5 (ref), v10 (ref), self (copy), v12 (ref), v13 (ref), v14 (ref), v15 (ref), fresh_state (copy)
    if v10 ~= nil then
        local v16 = v10

        self[v16] = {
            n1,
            n2,
            n3,
            t2[1],
            v7,
            n4,
            v8,
            n5,
            v12,
            v13,
            v14,
            v15
        }
    end

    local v17 = self[p1]

    if v17 ~= nil then
        self[p1] = nil

        local v18 = v17[1]
        local v19 = v17[2]
        local v20 = v17[3]
        local v21 = v17[4]
        local v22 = v17[5]
        local v23 = v17[6]
        local v24 = v17[7]
        local v25 = v17[8]

        n1 = v18
        n2 = v19
        n3 = v20
        t2[1] = v21
        v7 = v22
        n4 = v23
        v8 = v24
        n5 = v25

        local v26 = v17[9]
        local v27 = v17[10]
        local v28 = v17[11]
        local v29 = v17[12]

        v12 = v26
        v13 = v27
        v14 = v28
        v15 = v29
    else
        fresh_state()
    end

    v10 = p1
end

local function forget_engines() -- line: 126
    -- upvalues: v10 (ref), self (copy)
    for _, v30 in self do
        local v31 = v30[10]
        local v32 = v30[11]

        if v30[9] and v31 ~= nil then
            for i = 1, 24 do
                local v33 = v31[i]

                if v33 ~= nil and bit32.band(v32[i], 4) ~= 0 then
                    v33.state_flags = bit32.bor(v33.state_flags, 4)
                end
            end
        end
    end

    table.clear(self)
    v10 = nil
end

function t1.engines(p2) -- line: 142
    -- upvalues: v10 (ref), self (copy)
    local n6 = 0

    for _ in self do
        n6 += 1
    end

    return n6, v10 ~= nil and v10 == p2
end

t1.stats = {
    solves = 0,
    kinematic = 0,
    probes = 0,
    probe_hits = 0,
    holds = 0,
    place_seconds = 0,
    soft = 0,
    place_literal = 0,
    blended = 0,
    asleep = 0,
    sleeps = 0,
    by_state = {},
    solves_by_state = {},
    full_by = {},
    by_part = {},
    wake_by = {}
}

function t1.reset_stats() -- line: 168
    -- upvalues: t1 (copy)
    local stats = t1.stats

    stats.solves = 0
    stats.kinematic = 0
    stats.probes = 0
    stats.probe_hits = 0
    stats.holds = 0
    stats.place_seconds = 0
    stats.soft = 0
    stats.place_literal = 0
    stats.blended = 0
    stats.asleep = 0
    stats.sleeps = 0
    table.clear(stats.wake_by)
    table.clear(stats.by_state)
    table.clear(stats.solves_by_state)
    table.clear(stats.full_by)
    table.clear(stats.by_part)
end

function t1.configure(p3) -- line: 183
    -- upvalues: t1 (copy), v4 (ref), v5 (ref), fresh_state (copy), forget_engines (copy)
    v4("off")
    v5 = table.clone(t1.DEFAULTS)

    for v35, v36 in p3 do
        if t1.DEFAULTS[v35] ~= nil then
            v5[v35] = v36
        end
    end

    table.clear(t1.IGNORE_PARTS)

    for _, v38 in p3.ignore_parts or { 15, 16, 17, 18, 19, 20, 21, 22 } do
        t1.IGNORE_PARTS[v38] = true
    end

    forget_engines()
    fresh_state()

    return true
end

local function state_id(p4) -- line: 201
    local player_input = p4.player_input
    local v39 = player_input and player_input.physical
    local v40 = v39 and v39.state
    local v41 = v40 and v40.state_16

    if type(v41) == "number" then
        return v41
    end

    return -1
end

function t1.begin(p5, p6) -- line: 211
    -- upvalues: t1 (copy), v3 (ref), v4 (ref), v5 (ref), n1 (ref), n2 (ref), n3 (ref), v7 (ref), n4 (ref), v8 (ref), n5 (ref), v10 (ref), bind (copy)
    if p5 ~= v10 then
        bind(p5)
    end

    local stats = t1.stats

    stats.solves += 1
    n3 += 1

    local player_input = p6.player_input
    local v42 = player_input and player_input.physical
    local v43 = v42 and v42.state
    local v44 = v43 and v43.state_16

    if type(v44) ~= "number" then
        v44 = -1
    end

    local v45 = v44 // 100

    stats.solves_by_state[v45] = (stats.solves_by_state[v45] or 0) + 1

    if v45 ~= 3 or not v5.sleep then
        v4("state")
    elseif v3(p5, p6) then
        stats.asleep += 1
        n1 = v5.settle
        v7 = false
        v8 = false
        n4 = v5.blend

        return 3
    end

    local v46 = if (v45 ~= 1 or not v5.riding) and (v45 ~= 2 or not v5.air) and (v45 ~= 4 or not v5.grind) then "state" else nil

    if v46 == nil then
        local network_proxies = p5.network_proxies

        if network_proxies ~= nil and (network_proxies.volumes ~= nil and #network_proxies.volumes > 0 or network_proxies.solids ~= nil and #network_proxies.solids > 0 or network_proxies.pending ~= nil and #network_proxies.pending > 0) then
            v46 = "proxy"
        end
    end

    if v46 == nil and p6.skeleton_input.drive_frames == nil then
        v46 = "frames"
    end

    if v46 == nil and p5.board_wiping_out then
        v46 = "wipeout"
    end

    local v49 = v46

    if v46 == nil then
        local board_possession = p6.board_possession

        board_possession = board_possession and board_possession.state and board_possession.state.hands

        if board_possession ~= nil then
            for i = 1, 2 do
                local dynamics = board_possession[i].dynamics
                local v50 = dynamics[1]

                if not (bit32.band(v50[1], 2147483647) == 0 and bit32.band(v50[3], 2147483647) == 0) then
                    v49 = "hands"
                end

                local v55 = dynamics[2]

                if not (bit32.band(v55[1], 2147483647) == 0 and bit32.band(v55[3], 2147483647) == 0) then
                    v49 = "hands"
                end
            end
        else
            v49 = "hands"
        end
    end

    local v60 = v49

    if v49 == nil and v45 == 2 and v5.early > 0 then
        local physical = p6.player_input.physical
        local v61 = physical and physical.air
        local scalar_184 = if v44 == 201 and type(v61) == "table" and v61.known_air_valid_437 == 1 then v61.scalar_184 else nil

        if type(scalar_184) ~= "number" or not (v5.early * 0.016666666666666666 < scalar_184) then
            v60 = "landing"
        end
    end

    local v62 = false
    local v63 = false
    local v64 = false
    local v65 = false
    local v66 = false

    if v60 ~= nil then
        v66 = true
    else
        v62 = true
    end

    if v62 then
        if n1 > 0 then
            v66 = true
        else
            v63 = true
        end
    end

    v62 = false

    if v63 then
        if n2 > 0 then
            v66 = true
        else
            v62 = true
        end
    end

    v63 = false

    local probe_every, v67

    if v62 then
        v8 = true
        n5 = 0
        stats.kinematic += 1
        stats.by_state[v45] = (stats.by_state[v45] or 0) + 1
        probe_every = v5.probe_every

        if probe_every > 1 then
            v63 = true
        else
            v67 = probe_every
            v66 = false
        end
    end

    v62 = false

    if v63 then
        if v45 == 2 then
            v64 = true
        else
            v62 = true
        end
    end

    v63 = false

    local board, v68

    if v62 then
        board = p5.board

        if board then
            v63 = true
        else
            v68 = board
            v65 = true
        end
    end

    v62 = false

    if v63 then
        local bodies = board.bodies

        if bodies then
            v62 = true
        else
            v68 = bodies
            v65 = true
        end
    end

    v63 = false

    if v62 then
        v68 = board.bodies[7]
        v65 = true
    end

    v62 = false

    local v69

    if v65 then
        if v68 then
            v62 = true
        else
            v69 = v68
            v63 = true
        end
    end

    v65 = false

    if v62 then
        local rates = v68.rates

        if rates then
            v65 = true
        else
            v69 = rates
            v63 = true
        end
    end

    if v65 then
        v69 = v68.rates.linear_velocity
        v63 = true
    end

    v65 = false

    if v63 then
        if v69 ~= nil then
            v65 = true
        else
            v67 = probe_every
            v66 = false
        end
    end

    v63 = false

    if v65 then
        if v69.x * v69.x + v69.y * v69.y + v69.z * v69.z >= v5.probe_speed * v5.probe_speed then
            v63 = true
        else
            v67 = probe_every
            v66 = false
        end
    end

    if v63 then
        v67 = 1
        v66 = false
    end

    if v64 then
        v67 = 1
        v66 = false
    end

    if not v66 then
        if not (v67 > 0) or n3 % v67 ~= 0 then
            return 1
        end

        stats.probes += 1

        return 2
    end

    if v60 == "landing" then
        n1 = math.max(v5.settle, v5.land_hold)
    elseif v60 ~= nil then
        n1 = v5.settle
    elseif n1 > 0 then
        n1 -= 1
        v60 = "settle"
    else
        n2 -= 1
        v60 = "hold"
    end

    stats.full_by[v60] = (stats.full_by[v60] or 0) + 1
    v7 = false
    n4 = v5.blend

    if v8 then
        n5 = v5.soft
        v8 = false
    end

    if v60 == "wipeout" or v45 == 3 then
        n5 = 0
    end

    return 0
end

t1.FLOOR = 0.6
t1.DECK_FLOOR = true

local n7 = 0
local n8 = 1
local n9 = 0

local function read_deck_up(p7) -- line: 356
    -- upvalues: t1 (copy), n7 (ref), n8 (ref), n9 (ref)
    n7 = 0
    n8 = 1
    n9 = 0

    if t1.DECK_FLOOR then
        local v70 = p7 and p7.board

        v70 = v70 and v70.bodies and v70.bodies[7]

        local v71 = v70 and v70.rates
        local v72 = v71 and v71.basis

        v72 = v72 and v72.columns and v72.columns[2]

        if type(v72) == "table" and type(v72[1]) == "number" and type(v72[2]) == "number" and type(v72[3]) == "number" then
            local v76 = v72[1]
            local v77 = v72[2]
            local v78 = v72[3]

            n7 = v76
            n8 = v77
            n9 = v78
        end
    end
end

local function ordinary(p8, p9) -- line: 370
    -- upvalues: t1 (copy), n7 (ref), n8 (ref), n9 (ref)
    if type(p9) ~= "number" or not t1.IGNORE_PARTS[p9] then
        return false
    end

    local contact = p8.contact
    local v79 = contact and contact.normal
    local v80 = v79 and v79.y

    if type(v80) ~= "number" then
        return false
    end

    if math.abs(v80) >= t1.FLOOR then
        return true
    end

    local x, z = v79.x, v79.z

    if type(x) == "number" and type(z) == "number" then
        return x * n7 + v80 * n8 + z * n9 >= t1.FLOOR
    end

    return false
end

function t1.blocked(p10) -- line: 388
    -- upvalues: t1 (copy), v4 (ref), v5 (ref), n1 (ref), n3 (ref), v7 (ref), n4 (ref), v8 (ref), n5 (ref), v10 (ref), bind (copy)
    if p10 ~= nil and p10 ~= v10 then
        bind(p10)
    end

    v4("proxy")
    n4 = v5.blend
    t1.stats.solves += 1
    t1.stats.full_by.blocked = (t1.stats.full_by.blocked or 0) + 1
    n3 += 1
    n1 = v5.settle
    v7 = false

    if v8 then
        n5 = v5.soft
        v8 = false
    end
end

function t1.empty_rows() -- line: 406
    return {}, {
        rows = {},
        identities = {},
        spy = {}
    }
end

function t1.probe(p11, p12) -- line: 412
    -- upvalues: t1 (copy), v5 (ref), n2 (ref), n3 (ref), read_deck_up (copy), ordinary (copy)
    local stats = t1.stats

    read_deck_up(p12)

    local v81 = false

    for _, v82 in p11 do
        local body_a = v82.body_a
        local v83 = if type(body_a) == "table" then body_a[1] else nil

        if type(v83) == "number" then
            stats.by_part[v83] = (stats.by_part[v83] or 0) + 1
        end

        if not ordinary(v82, v83) then
            if t1.on_hit ~= nil then
                t1.on_hit(v82, v83, n3)
            end

            v81 = true
        end
    end

    if not v81 then
        return
    end

    stats.probe_hits += 1
    stats.holds += 1
    n2 = v5.hold
end

function t1.observe(p13, p14) -- line: 441
    -- upvalues: v5 (ref), n2 (ref), read_deck_up (copy), ordinary (copy)
    if n2 <= 0 then
        return
    end

    read_deck_up(p14)

    for _, v84 in p13 do
        local body_a = v84.body_a

        if not ordinary(v84, if type(body_a) == "table" then body_a[1] else nil) then
            n2 = v5.hold

            return
        end
    end
end

function t1.soft_begin(p15) -- line: 462
    -- upvalues: SkeletonBody (copy), n5 (ref), v9 (copy)
    if n5 <= 0 then
        return false
    end

    n5 -= 1

    local v86 = SkeletonBody.bodies_mut(p15.skeleton)

    for i = 0, 25 do
        local rates = v86[i + 1].rates
        local linear_velocity, angular_velocity = rates.linear_velocity, rates.angular_velocity
        local v87 = i * 6
        local v88 = v87 + 2
        local v89 = v87 + 3
        local x, y, z = linear_velocity.x, linear_velocity.y, linear_velocity.z

        v9[v87 + 1] = x
        v9[v88] = y
        v9[v89] = z

        local v90 = v87 + 5
        local v91 = v87 + 6
        local x2, y2, z2 = angular_velocity.x, angular_velocity.y, angular_velocity.z

        v9[v87 + 4] = x2
        v9[v90] = y2
        v9[v91] = z2
    end

    return true
end

function t1.soft_end(p16) -- line: 477
    -- upvalues: SkeletonBody (copy), t1 (copy), v9 (copy)
    t1.stats.soft += 1

    local v92 = SkeletonBody.bodies_mut(p16.skeleton)

    for i = 0, 25 do
        local rates = v92[i + 1].rates
        local linear_velocity, angular_velocity = rates.linear_velocity, rates.angular_velocity
        local v93 = i * 6
        local v94 = v9[v93 + 1]
        local v95 = v9[v93 + 2]
        local v96 = v9[v93 + 3]

        linear_velocity.x = v94
        linear_velocity.y = v95
        linear_velocity.z = v96

        local v97 = v9[v93 + 4]
        local v98 = v9[v93 + 5]
        local v99 = v9[v93 + 6]

        angular_velocity.x = v97
        angular_velocity.y = v98
        angular_velocity.z = v99
    end
end

function t1.place_reference(p17, p18) -- line: 494
    -- upvalues: compose_affine (copy), SkeletonBody (copy), t1 (copy), t2 (copy), v7 (ref), n4 (ref)
    local elapsed = os.clock()
    local skeleton, animated_skeleton = p17.skeleton, p17.animated_skeleton
    local drive_frames = p17.skeleton_input.drive_frames
    local animation_to_world = animated_skeleton.roots.animation_to_world
    local com_frame = animated_skeleton.board_frames.com_frame
    local v100 = SkeletonBody.bodies_mut(skeleton)
    local v101 = 1 / p18
    local v102 = v101 * 0.5
    local v103 = v7
    local v104, v105

    if n4 > 0 then
        v104 = SkeletonBody.part_transforms(skeleton)
        v105 = 1 / n4
        n4 -= 1
        t1.stats.blended += 1
    else
        v105 = 1
    end

    for i = 0, 25 do
        local v106 = if i < 24 then compose_affine(animation_to_world, drive_frames[i + 1]) else table.clone(com_frame)

        if i >= 24 then
            v106[1] = table.clone(v106[1])
            v106[2] = table.clone(v106[2])
            v106[3] = table.clone(v106[3])
            v106[4] = table.clone(v106[4])
        end

        if v104 ~= nil and i < 24 then
            local v107 = v104[i + 1]

            for j = 1, 4 do
                local v108 = v107[j]
                local v109 = v106[j]

                v109[1] = v108[1] + (v109[1] - v108[1]) * v105
                v109[2] = v108[2] + (v109[2] - v108[2]) * v105
                v109[3] = v108[3] + (v109[3] - v108[3]) * v105
                v109[4] = v108[4] + (v109[4] - v108[4]) * v105
            end
        end

        SkeletonBody.set_part_transform(skeleton, i, v106)

        local rates = v100[i + 1].rates
        local position = rates.position
        local columns = rates.basis.columns
        local v110 = columns[1]
        local v111 = columns[2]
        local v112 = columns[3]
        local v113 = i * 12

        if v103 then
            local linear_velocity = rates.linear_velocity

            linear_velocity.x = (position.x - t2[1][v113 + 1]) * v101
            linear_velocity.y = (position.y - t2[1][v113 + 2]) * v101
            linear_velocity.z = (position.z - t2[1][v113 + 3]) * v101

            local n10 = 0
            local n11 = 0
            local n12 = 0

            for k = 0, 2 do
                local v114 = if k == 0 then v110 elseif k == 1 then v111 else v112
                local v115 = t2[1][v113 + 4 + k * 3]
                local v116 = t2[1][v113 + 5 + k * 3]
                local v117 = t2[1][v113 + 6 + k * 3]
                local v118 = v114[1]
                local v119 = v114[2]
                local v120 = v114[3]

                n10 += v116 * v120 - v117 * v119
                n11 += v117 * v118 - v115 * v120
                n12 += v115 * v119 - v116 * v118
            end

            local angular_velocity = rates.angular_velocity
            local v121 = n10 * v102
            local v122 = n11 * v102
            local v123 = n12 * v102

            angular_velocity.x = v121
            angular_velocity.y = v122
            angular_velocity.z = v123
        end

        local v124 = t2[1]
        local v125 = t2[1]
        local v126 = v113 + 2
        local v127 = t2[1]
        local v128 = v113 + 3
        local x, y, z = position.x, position.y, position.z

        v124[v113 + 1] = x
        v125[v126] = y
        v127[v128] = z

        local v129 = t2[1]
        local v130 = t2[1]
        local v131 = v113 + 5
        local v132 = t2[1]
        local v133 = v113 + 6
        local v134 = v110[1]
        local v135 = v110[2]
        local v136 = v110[3]

        v129[v113 + 4] = v134
        v130[v131] = v135
        v132[v133] = v136

        local v137 = t2[1]
        local v138 = t2[1]
        local v139 = v113 + 8
        local v140 = t2[1]
        local v141 = v113 + 9
        local v142 = v111[1]
        local v143 = v111[2]
        local v144 = v111[3]

        v137[v113 + 7] = v142
        v138[v139] = v143
        v140[v141] = v144

        local v145 = t2[1]
        local v146 = t2[1]
        local v147 = v113 + 11
        local v148 = t2[1]
        local v149 = v113 + 12
        local v150 = v112[1]
        local v151 = v112[2]
        local v152 = v112[3]

        v145[v113 + 10] = v150
        v146[v147] = v151
        v148[v149] = v152
    end

    v7 = true
    t1.stats.place_seconds += os.clock() - elapsed
end

local to_bits = require(sim.rt).to_bits
local v153 = buffer.create(4)
local writef32, readf32, writeu32 = buffer.writef32, buffer.readf32, buffer.writeu32

local function f32r(p19) -- line: 586
    -- upvalues: to_bits (copy), v153 (copy), writef32 (copy), readf32 (copy), writeu32 (copy)
    if p19 < 1.1754943508222875E-38 and p19 > -1.1754943508222875E-38 and p19 ~= 0 then
        writeu32(v153, 0, to_bits(p19))

        return (readf32(v153, 0))
    end

    writef32(v153, 0, p19)

    return (readf32(v153, 0))
end

local function rsqrt_s(p20) -- line: 595
    local v154 = 1 / math.sqrt(p20)
    local v155 = v154 * v154
    local v156 = v154 * 0.5 * (-p20 * v155 + 1) + v154
    local v157 = v156 * v156

    return v156 * 0.5 * (-p20 * v157 + 1) + v156
end

t1.USE_REFERENCE_PLACE = false

local function literal_part(p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36, p37, p38) -- line: 608
    -- upvalues: SkeletonBody (copy)
    SkeletonBody.set_part_transform(p21, p22, {
        { p23, p24, p25, p26 },
        { p27, p28, p29, p30 },
        { p31, p32, p33, p34 },
        { p35, p36, p37, p38 }
    })
end

function t1.place_fast(p39, p40) -- line: 617
    -- upvalues: SkeletonBody (copy), t1 (copy), t2 (copy), v7 (ref), n4 (ref), to_bits (copy), v153 (copy), writef32 (copy), readf32 (copy), writeu32 (copy), literal_part (copy)
    local elapsed = os.clock()
    local skeleton, animated_skeleton = p39.skeleton, p39.animated_skeleton
    local drive_frames = p39.skeleton_input.drive_frames
    local animation_to_world = animated_skeleton.roots.animation_to_world
    local com_frame = animated_skeleton.board_frames.com_frame
    local v158 = SkeletonBody.bodies_mut(skeleton)
    local parts = skeleton.definition.parts
    local pose = skeleton.record.pose
    local v159 = 1 / p40
    local v160 = v159 * 0.5
    local v161 = v7
    local v162 = t2[1]
    local v163, v164, orientation

    if n4 > 0 then
        v163 = SkeletonBody.part_transforms(skeleton)
        v164 = 1 / n4
        n4 -= 1
        orientation = t1.stats
        orientation.blended += 1
    else
        v164 = 1
    end

    orientation = animation_to_world[1]

    local rates = animation_to_world[2]
    local v165 = animation_to_world[3]
    local v166 = animation_to_world[4]
    local v167 = orientation[1]
    local v168 = orientation[2]
    local v169 = orientation[3]
    local v170 = orientation[4]
    local v171 = rates[1]
    local v172 = rates[2]
    local v173 = rates[3]
    local v174 = rates[4]
    local v175 = v165[1]
    local v176 = v165[2]
    local v177 = v165[3]
    local v178 = v165[4]
    local v179 = v166[1]
    local v180 = v166[2]
    local v181 = v166[3]
    local v182 = v166[4]

    for i = 0, 25 do
        local v183, v184, v185, v186, v187, v188, v189, v190, v191, v192, v193, v194, v195, v196, v197, v198, position, local_mass_frame, columns, inverse_tensor, v199, v200, v201, v202, v203, v204, v205, v206, v207, v208, v209, v210

        if i < 24 then
            v166 = drive_frames[i + 1]
            position = v166[1]
            local_mass_frame = v166[2]
            v203 = v166[3]
            v204 = v166[4]
            columns = position[1]
            inverse_tensor = position[2]
            v199 = position[3]
            v200 = local_mass_frame[1]
            v201 = local_mass_frame[2]
            v202 = local_mass_frame[3]
            v205 = v203[1]
            v207 = v203[2]
            v209 = v203[3]
            v206 = v204[1]
            v208 = v204[2]
            v210 = v204[3]
            v183 = v199 * v175 + (inverse_tensor * v171 + columns * v167)
            v184 = v199 * v176 + (inverse_tensor * v172 + columns * v168)
            v185 = v199 * v177 + (inverse_tensor * v173 + columns * v169)
            v186 = v199 * v178 + (inverse_tensor * v174 + columns * v170)
            v187 = v202 * v175 + (v201 * v171 + v200 * v167)
            v188 = v202 * v176 + (v201 * v172 + v200 * v168)
            v189 = v202 * v177 + (v201 * v173 + v200 * v169)
            v190 = v202 * v178 + (v201 * v174 + v200 * v170)
            v191 = v209 * v175 + (v207 * v171 + v205 * v167)
            v192 = v209 * v176 + (v207 * v172 + v205 * v168)
            v193 = v209 * v177 + (v207 * v173 + v205 * v169)
            v194 = v209 * v178 + (v207 * v174 + v205 * v170)
            v195 = v175 * v210 + (v171 * v208 + (v167 * v206 + v179))
            v196 = v176 * v210 + (v172 * v208 + (v168 * v206 + v180))
            v197 = v177 * v210 + (v173 * v208 + (v169 * v206 + v181))
            v198 = v178 * v210 + (v174 * v208 + (v170 * v206 + v182))

            if v163 ~= nil then
                v210 = v163[i + 1]
                v208 = v210[1]
                v183 = v208[1] + (v183 - v208[1]) * v164
                v184 = v208[2] + (v184 - v208[2]) * v164
                v185 = v208[3] + (v185 - v208[3]) * v164
                v186 = v208[4] + (v186 - v208[4]) * v164
                v208 = v210[2]
                v187 = v208[1] + (v187 - v208[1]) * v164
                v188 = v208[2] + (v188 - v208[2]) * v164
                v189 = v208[3] + (v189 - v208[3]) * v164
                v190 = v208[4] + (v190 - v208[4]) * v164
                v208 = v210[3]
                v191 = v208[1] + (v191 - v208[1]) * v164
                v192 = v208[2] + (v192 - v208[2]) * v164
                v193 = v208[3] + (v193 - v208[3]) * v164
                v194 = v208[4] + (v194 - v208[4]) * v164
                v208 = v210[4]
                v195 = v208[1] + (v195 - v208[1]) * v164
                v196 = v208[2] + (v196 - v208[2]) * v164
                v197 = v208[3] + (v197 - v208[3]) * v164
                v198 = v208[4] + (v198 - v208[4]) * v164
            end
        else
            position = com_frame[1]
            local_mass_frame = com_frame[2]
            v203 = com_frame[3]
            v204 = com_frame[4]
            v183 = position[1]
            v184 = position[2]
            v185 = position[3]
            v186 = position[4]
            v187 = local_mass_frame[1]
            v188 = local_mass_frame[2]
            v189 = local_mass_frame[3]
            v190 = local_mass_frame[4]
            v191 = v203[1]
            v192 = v203[2]
            v193 = v203[3]
            v194 = v203[4]
            v195 = v204[1]
            v196 = v204[2]
            v197 = v204[3]
            v198 = v204[4]
        end

        v165 = v158[i + 1]
        rates = v165.rates
        orientation = rates.orientation
        position = rates.position
        local_mass_frame = rates.basis
        v203 = local_mass_frame and local_mass_frame.columns
        local_mass_frame = rates.world_inverse_inertia
        v204 = local_mass_frame and local_mass_frame.columns
        local_mass_frame = parts[i + 1].animated.local_mass_frame
        columns = local_mass_frame.basis.columns
        inverse_tensor = v165.inertia.inverse_tensor
        v199 = pose[i + 1]
        v207 = v165.state_flags

        local v211, v212, v213, v214, v215, v216, v217, v218, v219, v220, v221, v222

        if bit32.band(v207, 4) ~= 0 and type(orientation) == "table" and type(position) == "table" and type(v203) == "table" and #v203 == 3 and type(v204) == "table" and #v204 == 3 and #columns == 3 and type(v199) == "table" and #v199 == 4 and v199 ~= animation_to_world and v199 ~= com_frame then
            if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
                writeu32(v153, 0, to_bits(v183))
            else
                writef32(v153, 0, v183)
            end

            v205 = readf32(v153, 0)

            if v184 < 1.1754943508222875E-38 and v184 > -1.1754943508222875E-38 and v184 ~= 0 then
                writeu32(v153, 0, to_bits(v184))
            else
                writef32(v153, 0, v184)
            end

            v207 = readf32(v153, 0)

            if v185 < 1.1754943508222875E-38 and v185 > -1.1754943508222875E-38 and v185 ~= 0 then
                writeu32(v153, 0, to_bits(v185))
            else
                writef32(v153, 0, v185)
            end

            v209 = readf32(v153, 0)

            if v187 < 1.1754943508222875E-38 and v187 > -1.1754943508222875E-38 and v187 ~= 0 then
                writeu32(v153, 0, to_bits(v187))
            else
                writef32(v153, 0, v187)
            end

            v206 = readf32(v153, 0)

            if v188 < 1.1754943508222875E-38 and v188 > -1.1754943508222875E-38 and v188 ~= 0 then
                writeu32(v153, 0, to_bits(v188))
            else
                writef32(v153, 0, v188)
            end

            v208 = readf32(v153, 0)

            if v189 < 1.1754943508222875E-38 and v189 > -1.1754943508222875E-38 and v189 ~= 0 then
                writeu32(v153, 0, to_bits(v189))
            else
                writef32(v153, 0, v189)
            end

            v210 = readf32(v153, 0)

            if v191 < 1.1754943508222875E-38 and v191 > -1.1754943508222875E-38 and v191 ~= 0 then
                writeu32(v153, 0, to_bits(v191))
            else
                writef32(v153, 0, v191)
            end

            v213 = readf32(v153, 0)

            if v192 < 1.1754943508222875E-38 and v192 > -1.1754943508222875E-38 and v192 ~= 0 then
                writeu32(v153, 0, to_bits(v192))
            else
                writef32(v153, 0, v192)
            end

            v214 = readf32(v153, 0)

            if v193 < 1.1754943508222875E-38 and v193 > -1.1754943508222875E-38 and v193 ~= 0 then
                writeu32(v153, 0, to_bits(v193))
            else
                writef32(v153, 0, v193)
            end

            v215 = readf32(v153, 0)

            if v195 < 1.1754943508222875E-38 and v195 > -1.1754943508222875E-38 and v195 ~= 0 then
                writeu32(v153, 0, to_bits(v195))
            else
                writef32(v153, 0, v195)
            end

            v216 = readf32(v153, 0)

            if v196 < 1.1754943508222875E-38 and v196 > -1.1754943508222875E-38 and v196 ~= 0 then
                writeu32(v153, 0, to_bits(v196))
            else
                writef32(v153, 0, v196)
            end

            v217 = readf32(v153, 0)

            if v197 < 1.1754943508222875E-38 and v197 > -1.1754943508222875E-38 and v197 ~= 0 then
                writeu32(v153, 0, to_bits(v197))
            else
                writef32(v153, 0, v197)
            end

            v218 = readf32(v153, 0)
            v219 = columns[1]
            v220 = columns[2]
            v211 = columns[3]

            local v223 = v219[1]

            if v223 < 1.1754943508222875E-38 and v223 > -1.1754943508222875E-38 and v223 ~= 0 then
                writeu32(v153, 0, to_bits(v223))
            else
                writef32(v153, 0, v223)
            end

            v221 = readf32(v153, 0)
            v223 = v219[2]

            if v223 < 1.1754943508222875E-38 and v223 > -1.1754943508222875E-38 and v223 ~= 0 then
                writeu32(v153, 0, to_bits(v223))
            else
                writef32(v153, 0, v223)
            end

            v212 = readf32(v153, 0)
            v223 = v219[3]

            if v223 < 1.1754943508222875E-38 and v223 > -1.1754943508222875E-38 and v223 ~= 0 then
                writeu32(v153, 0, to_bits(v223))
            else
                writef32(v153, 0, v223)
            end

            v222 = readf32(v153, 0)

            local v224 = v220[1]

            if v224 < 1.1754943508222875E-38 and v224 > -1.1754943508222875E-38 and v224 ~= 0 then
                writeu32(v153, 0, to_bits(v224))
            else
                writef32(v153, 0, v224)
            end

            v223 = readf32(v153, 0)
            v224 = v220[2]

            if v224 < 1.1754943508222875E-38 and v224 > -1.1754943508222875E-38 and v224 ~= 0 then
                writeu32(v153, 0, to_bits(v224))
            else
                writef32(v153, 0, v224)
            end

            local v225 = readf32(v153, 0)

            v224 = v220[3]

            if v224 < 1.1754943508222875E-38 and v224 > -1.1754943508222875E-38 and v224 ~= 0 then
                writeu32(v153, 0, to_bits(v224))
            else
                writef32(v153, 0, v224)
            end

            local v226 = readf32(v153, 0)
            local v227 = v211[1]

            if v227 < 1.1754943508222875E-38 and v227 > -1.1754943508222875E-38 and v227 ~= 0 then
                writeu32(v153, 0, to_bits(v227))
            else
                writef32(v153, 0, v227)
            end

            v224 = readf32(v153, 0)
            v227 = v211[2]

            if v227 < 1.1754943508222875E-38 and v227 > -1.1754943508222875E-38 and v227 ~= 0 then
                writeu32(v153, 0, to_bits(v227))
            else
                writef32(v153, 0, v227)
            end

            local v228 = readf32(v153, 0)

            v227 = v211[3]

            if v227 < 1.1754943508222875E-38 and v227 > -1.1754943508222875E-38 and v227 ~= 0 then
                writeu32(v153, 0, to_bits(v227))
            else
                writef32(v153, 0, v227)
            end

            local v229 = readf32(v153, 0)

            v211 = local_mass_frame.translation

            local v230 = v211.x

            if v230 < 1.1754943508222875E-38 and v230 > -1.1754943508222875E-38 and v230 ~= 0 then
                writeu32(v153, 0, to_bits(v230))
            else
                writef32(v153, 0, v230)
            end

            v220 = 0 - readf32(v153, 0)
            v230 = v211.y

            if v230 < 1.1754943508222875E-38 and v230 > -1.1754943508222875E-38 and v230 ~= 0 then
                writeu32(v153, 0, to_bits(v230))
            else
                writef32(v153, 0, v230)
            end

            v219 = 0 - readf32(v153, 0)

            local v231 = v211.z

            if v231 < 1.1754943508222875E-38 and v231 > -1.1754943508222875E-38 and v231 ~= 0 then
                writeu32(v153, 0, to_bits(v231))
            else
                writef32(v153, 0, v231)
            end

            v227 = 0 - readf32(v153, 0)
            v211 = v220 * v221 + (v219 * v212 + v227 * v222)
            v230 = v220 * v223 + (v219 * v225 + v227 * v226)
            v231 = v220 * v224 + (v219 * v228 + v227 * v229)

            local v232 = v224 * v213 + (v223 * v206 + v221 * v205)

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v227 = readf32(v153, 0)
            v232 = v224 * v214 + (v223 * v208 + v221 * v207)

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v220 = readf32(v153, 0)
            v232 = v224 * v215 + (v223 * v210 + v221 * v209)

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v219 = readf32(v153, 0)
            v232 = v228 * v213 + (v225 * v206 + v212 * v205)

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v224 = readf32(v153, 0)
            v232 = v228 * v214 + (v225 * v208 + v212 * v207)

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v223 = readf32(v153, 0)
            v232 = v228 * v215 + (v225 * v210 + v212 * v209)

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v221 = readf32(v153, 0)
            v232 = v229 * v213 + (v226 * v206 + v222 * v205)

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v228 = readf32(v153, 0)
            v232 = v229 * v214 + (v226 * v208 + v222 * v207)

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v225 = readf32(v153, 0)
            v232 = v229 * v215 + (v226 * v210 + v222 * v209)

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v212 = readf32(v153, 0)
            v232 = v231 * v213 + (v230 * v206 + (v211 * v205 + v216))

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v229 = readf32(v153, 0)
            v232 = v231 * v214 + (v230 * v208 + (v211 * v207 + v217))

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v226 = readf32(v153, 0)
            v232 = v231 * v215 + (v230 * v210 + (v211 * v209 + v218))

            if v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
                writeu32(v153, 0, to_bits(v232))
            else
                writef32(v153, 0, v232)
            end

            v222 = readf32(v153, 0)
            v231 = v227 * v227 + v220 * v220 + v219 * v219
            v230 = v224 * v224 + v223 * v223 + v221 * v221
            v211 = v228 * v228 + v225 * v225 + v212 * v212
            v232 = 1 / math.sqrt(v231)
            v218 = v232 * v232
            v232 = v232 * 0.5 * (-v231 * v218 + 1) + v232
            v218 = v232 * v232
            v232 = v232 * 0.5 * (-v231 * v218 + 1) + v232

            local v233 = 1 / math.sqrt(v230)

            v216 = v233 * v233
            v233 = v233 * 0.5 * (-v230 * v216 + 1) + v233
            v216 = v233 * v233
            v233 = v233 * 0.5 * (-v230 * v216 + 1) + v233

            local v234 = 1 / math.sqrt(v211)

            v214 = v234 * v234
            v234 = v234 * 0.5 * (-v211 * v214 + 1) + v234
            v214 = v234 * v234
            v234 = v234 * 0.5 * (-v211 * v214 + 1) + v234

            local v235 = v231 * v232
            local v236 = v230 * v233
            local v237 = v211 * v234

            if v231 == 0 then
                v235 = 0
            end

            if v230 == 0 then
                v236 = 0
            end

            if v211 == 0 then
                v237 = 0
            end

            v227 *= v232
            v220 *= v232
            v219 *= v232
            v224 *= v233
            v223 *= v233
            v221 *= v233
            v228 *= v234
            v225 *= v234
            v212 *= v234

            local v238, v239, v240

            if v235 > 0 then
                if v236 > 0 then
                    if v237 > 0 then
                        v238 = v228 * v227 + v225 * v220 + v212 * v219
                        v240 = math.abs(v238)
                        v238 = v224 * v228 + v223 * v225 + v221 * v212

                        local v241 = math.abs(v238)

                        v238 = v227 * v224 + v220 * v223 + v219 * v221

                        local v242 = math.abs(v238)

                        v239 = if v241 < v240 then if v241 < v242 then 1 else 0 elseif v240 < v242 then 2 else 0
                    else
                        v239 = 0
                    end
                else
                    v239 = 2
                end
            else
                v239 = 1
            end

            local v243, v244, v245, v246

            if v239 == 0 then
                v245 = v221
                v240 = v227
                v238 = v220
                v243 = v219
                v246 = v224
                v244 = v223
            elseif v239 == 1 then
                v245 = v212
                v240 = v224
                v238 = v223
                v243 = v221
                v246 = v228
                v244 = v225
            else
                v245 = v219
                v240 = v228
                v238 = v225
                v243 = v212
                v246 = v227
                v244 = v220
            end

            v236 = -v243 * v244 + v238 * v245
            v235 = -v240 * v245 + v243 * v246
            v232 = -v238 * v246 + v240 * v244

            local v247 = v236 * v236 + v235 * v235 + v232 * v232

            v231 = 1 / math.sqrt(v247)
            v230 = v231 * v231
            v231 = v231 * 0.5 * (-v247 * v230 + 1) + v231
            v230 = v231 * v231
            v231 = v231 * 0.5 * (-v247 * v230 + 1) + v231
            v247 = v236 * v231

            local v248 = v235 * v231
            local v249 = v232 * v231

            v236 = -v249 * v238 + v248 * v243
            v235 = -v247 * v243 + v249 * v240
            v232 = -v248 * v240 + v247 * v238

            local v250 = v236 * v236 + v235 * v235 + v232 * v232

            v231 = 1 / math.sqrt(v250)
            v243 = v231 * v231
            v231 = v231 * 0.5 * (-v250 * v243 + 1) + v231
            v243 = v231 * v231
            v231 = v231 * 0.5 * (-v250 * v243 + 1) + v231
            v246 = v236 * v231
            v244 = v235 * v231
            v245 = v232 * v231

            if v239 ~= 0 then
                if v239 == 1 then
                    v219, v220, v245, v249, v244, v248, v246, v247, v227 = v249, v248, v221, v245, v223, v244, v224, v246, v247
                else
                    v219, v220, v245, v249, v244, v248, v246, v247, v227 = v245, v244, v249, v212, v248, v225, v247, v228, v246
                end
            end

            if v227 < 1.1754943508222875E-38 and v227 > -1.1754943508222875E-38 and v227 ~= 0 then
                writeu32(v153, 0, to_bits(v227))
            else
                writef32(v153, 0, v227)
            end

            v227 = readf32(v153, 0)

            if v220 < 1.1754943508222875E-38 and v220 > -1.1754943508222875E-38 and v220 ~= 0 then
                writeu32(v153, 0, to_bits(v220))
            else
                writef32(v153, 0, v220)
            end

            v220 = readf32(v153, 0)

            if v219 < 1.1754943508222875E-38 and v219 > -1.1754943508222875E-38 and v219 ~= 0 then
                writeu32(v153, 0, to_bits(v219))
            else
                writef32(v153, 0, v219)
            end

            v219 = readf32(v153, 0)

            if v246 < 1.1754943508222875E-38 and v246 > -1.1754943508222875E-38 and v246 ~= 0 then
                writeu32(v153, 0, to_bits(v246))
            else
                writef32(v153, 0, v246)
            end

            v224 = readf32(v153, 0)

            if v244 < 1.1754943508222875E-38 and v244 > -1.1754943508222875E-38 and v244 ~= 0 then
                writeu32(v153, 0, to_bits(v244))
            else
                writef32(v153, 0, v244)
            end

            v223 = readf32(v153, 0)

            if v245 < 1.1754943508222875E-38 and v245 > -1.1754943508222875E-38 and v245 ~= 0 then
                writeu32(v153, 0, to_bits(v245))
            else
                writef32(v153, 0, v245)
            end

            v221 = readf32(v153, 0)

            if v247 < 1.1754943508222875E-38 and v247 > -1.1754943508222875E-38 and v247 ~= 0 then
                writeu32(v153, 0, to_bits(v247))
            else
                writef32(v153, 0, v247)
            end

            v228 = readf32(v153, 0)

            if v248 < 1.1754943508222875E-38 and v248 > -1.1754943508222875E-38 and v248 ~= 0 then
                writeu32(v153, 0, to_bits(v248))
            else
                writef32(v153, 0, v248)
            end

            v225 = readf32(v153, 0)

            if v249 < 1.1754943508222875E-38 and v249 > -1.1754943508222875E-38 and v249 ~= 0 then
                writeu32(v153, 0, to_bits(v249))
            else
                writef32(v153, 0, v249)
            end

            v212 = readf32(v153, 0)
            v208 = v227 + v223

            if v208 + v212 > 0 then
                v206 = v208 + (v212 + 1)
                v209 = 1 / math.sqrt(v206)
                v207 = v209 * v209
                v209 = v209 * 0.5 * (-v206 * v207 + 1) + v209
                v207 = v209 * v209
                v209 = v209 * 0.5 * (-v206 * v207 + 1) + v209
                v236 = v206 * v209
                v206 = v209 * 0.5
                v232 = (v221 - v225) * v206
                v233 = (v228 - v219) * v206
                v234 = (v220 - v224) * v206
                v235 = v236 * 0.5
            elseif v223 < v227 and v212 < v227 then
                v236 = v227 + -v223 + (-v212 + 1)
                v237 = 1 / math.sqrt(v236)
                v239 = v237 * v237
                v237 = v237 * 0.5 * (-v236 * v239 + 1) + v237
                v239 = v237 * v237
                v237 = v237 * 0.5 * (-v236 * v239 + 1) + v237
                v239 = v236 * v237
                v236 = v237 * 0.5
                v232 = v239 * 0.5
                v233 = (v220 + v224) * v236
                v234 = (v228 + v219) * v236
                v235 = (v221 - v225) * v236
            elseif v212 < v223 then
                v236 = -v227 + v223 + (-v212 + 1)
                v237 = 1 / math.sqrt(v236)
                v239 = v237 * v237
                v237 = v237 * 0.5 * (-v236 * v239 + 1) + v237
                v239 = v237 * v237
                v237 = v237 * 0.5 * (-v236 * v239 + 1) + v237
                v239 = v236 * v237
                v236 = v237 * 0.5
                v232 = (v220 + v224) * v236
                v233 = v239 * 0.5
                v234 = (v221 + v225) * v236
                v235 = (v228 - v219) * v236
            else
                v236 = -v227 + -v223 + (v212 + 1)
                v237 = 1 / math.sqrt(v236)
                v239 = v237 * v237
                v237 = v237 * 0.5 * (-v236 * v239 + 1) + v237
                v239 = v237 * v237
                v237 = v237 * 0.5 * (-v236 * v239 + 1) + v237
                v239 = v236 * v237
                v236 = v237 * 0.5
                v232 = (v228 + v219) * v236
                v233 = (v221 + v225) * v236
                v234 = v239 * 0.5
                v235 = (v220 - v224) * v236
            end

            v236 = v232 * v232 + v233 * v233 + v234 * v234 + v235 * v235
            v208 = 1 / math.sqrt(v236)
            v237 = v208 * v208
            v208 = v208 * 0.5 * (-v236 * v237 + 1) + v208
            v237 = v208 * v208
            v208 = v208 * 0.5 * (-v236 * v237 + 1) + v208
            v236 = v232 * v208

            if v236 < 1.1754943508222875E-38 and v236 > -1.1754943508222875E-38 and v236 ~= 0 then
                writeu32(v153, 0, to_bits(v236))
            else
                writef32(v153, 0, v236)
            end

            v232 = readf32(v153, 0)
            v236 = v233 * v208

            if v236 < 1.1754943508222875E-38 and v236 > -1.1754943508222875E-38 and v236 ~= 0 then
                writeu32(v153, 0, to_bits(v236))
            else
                writef32(v153, 0, v236)
            end

            v233 = readf32(v153, 0)
            v236 = v234 * v208

            if v236 < 1.1754943508222875E-38 and v236 > -1.1754943508222875E-38 and v236 ~= 0 then
                writeu32(v153, 0, to_bits(v236))
            else
                writef32(v153, 0, v236)
            end

            v234 = readf32(v153, 0)
            v236 = v235 * v208

            if v236 < 1.1754943508222875E-38 and v236 > -1.1754943508222875E-38 and v236 ~= 0 then
                writeu32(v153, 0, to_bits(v236))
            else
                writef32(v153, 0, v236)
            end

            v235 = readf32(v153, 0)
            v240 = inverse_tensor.x

            if v240 < 1.1754943508222875E-38 and v240 > -1.1754943508222875E-38 and v240 ~= 0 then
                writeu32(v153, 0, to_bits(v240))
            else
                writef32(v153, 0, v240)
            end

            v236 = readf32(v153, 0)
            v240 = inverse_tensor.y

            if v240 < 1.1754943508222875E-38 and v240 > -1.1754943508222875E-38 and v240 ~= 0 then
                writeu32(v153, 0, to_bits(v240))
            else
                writef32(v153, 0, v240)
            end

            v237 = readf32(v153, 0)
            v240 = inverse_tensor.z

            if v240 < 1.1754943508222875E-38 and v240 > -1.1754943508222875E-38 and v240 ~= 0 then
                writeu32(v153, 0, to_bits(v240))
            else
                writef32(v153, 0, v240)
            end

            v239 = readf32(v153, 0)
            v240 = v227 * v236
            v238 = v220 * v236
            v243 = v219 * v236
            v246 = v224 * v237
            v244 = v223 * v237
            v245 = v221 * v237
            v247 = v228 * v239
            v248 = v225 * v239
            v249 = v212 * v239
            v250 = v247 * v228 + (v240 * v227 + v246 * v224)

            if v250 < 1.1754943508222875E-38 and v250 > -1.1754943508222875E-38 and v250 ~= 0 then
                writeu32(v153, 0, to_bits(v250))
            else
                writef32(v153, 0, v250)
            end

            v239 = readf32(v153, 0)
            v250 = v248 * v228 + (v238 * v227 + v244 * v224)

            if v250 < 1.1754943508222875E-38 and v250 > -1.1754943508222875E-38 and v250 ~= 0 then
                writeu32(v153, 0, to_bits(v250))
            else
                writef32(v153, 0, v250)
            end

            v247 = readf32(v153, 0)
            v250 = v249 * v228 + (v243 * v227 + v245 * v224)

            if v250 < 1.1754943508222875E-38 and v250 > -1.1754943508222875E-38 and v250 ~= 0 then
                writeu32(v153, 0, to_bits(v250))
            else
                writef32(v153, 0, v250)
            end

            v246 = readf32(v153, 0)
            v250 = v212 * v249 + (v219 * v243 + v221 * v245)

            if v250 < 1.1754943508222875E-38 and v250 > -1.1754943508222875E-38 and v250 ~= 0 then
                writeu32(v153, 0, to_bits(v250))
            else
                writef32(v153, 0, v250)
            end

            v240 = readf32(v153, 0)
            v250 = v225 * v248 + (v220 * v238 + v223 * v244)

            if v250 < 1.1754943508222875E-38 and v250 > -1.1754943508222875E-38 and v250 ~= 0 then
                writeu32(v153, 0, to_bits(v250))
            else
                writef32(v153, 0, v250)
            end

            v237 = readf32(v153, 0)
            v250 = v225 * v249 + (v220 * v243 + v223 * v245)

            if v250 < 1.1754943508222875E-38 and v250 > -1.1754943508222875E-38 and v250 ~= 0 then
                writeu32(v153, 0, to_bits(v250))
            else
                writef32(v153, 0, v250)
            end

            v248 = readf32(v153, 0)
            orientation.x = v232
            orientation.y = v233
            orientation.z = v234
            orientation.w = v235
            position.x = v229
            position.y = v226
            position.z = v222
            v200 = v203[1]
            v201 = v203[2]
            v202 = v203[3]
            v200[1] = v227
            v200[2] = v220
            v200[3] = v219
            v201[1] = v224
            v201[2] = v223
            v201[3] = v221
            v202[1] = v228
            v202[2] = v225
            v202[3] = v212
            v250 = v204[1]

            local v251 = v204[2]
            local v252 = v204[3]

            v250[1] = v239
            v250[2] = v247
            v250[3] = v246
            v251[1] = v247
            v251[2] = v237
            v251[3] = v248
            v252[1] = v246
            v252[2] = v248
            v252[3] = v240

            local v253 = v199[1]
            local v254 = v199[2]
            local v255 = v199[3]
            local v256 = v199[4]

            v253[1] = v183
            v253[2] = v184
            v253[3] = v185
            v253[4] = v186
            v254[1] = v187
            v254[2] = v188
            v254[3] = v189
            v254[4] = v190
            v255[1] = v191
            v255[2] = v192
            v255[3] = v193
            v255[4] = v194
            v256[1] = v195
            v256[2] = v196
            v256[3] = v197
            v256[4] = v198
        else
            literal_part(skeleton, i, v183, v184, v185, v186, v187, v188, v189, v190, v191, v192, v193, v194, v195, v196, v197, v198)
            v205 = t1.stats
            v205.place_literal += 1
            rates = v165.rates
            position = rates.position
            v203 = rates.basis.columns
            v200 = v203[1]
            v201 = v203[2]
            v202 = v203[3]
        end

        v199 = i * 12
        v205 = position.x
        v207 = position.y
        v209 = position.z
        v206 = v200[1]
        v208 = v200[2]
        v210 = v200[3]
        v213 = v201[1]
        v214 = v201[2]
        v215 = v201[3]
        v216 = v202[1]
        v217 = v202[2]
        v218 = v202[3]

        if v161 then
            v202 = rates.linear_velocity
            v202.x = (v205 - v162[v199 + 1]) * v159
            v202.y = (v207 - v162[v199 + 2]) * v159
            v202.z = (v209 - v162[v199 + 3]) * v159
            v219 = v162[v199 + 4]
            v220 = v162[v199 + 5]
            v211 = v162[v199 + 6]
            v202 = 0 + (v220 * v210 - v211 * v208)
            v201 = 0 + (v211 * v206 - v219 * v210)
            v200 = 0 + (v219 * v208 - v220 * v206)
            v219 = v162[v199 + 7]
            v220 = v162[v199 + 8]
            v211 = v162[v199 + 9]
            v202 += v220 * v215 - v211 * v214
            v201 += v211 * v213 - v219 * v215
            v200 += v219 * v214 - v220 * v213
            v219 = v162[v199 + 10]
            v220 = v162[v199 + 11]
            v211 = v162[v199 + 12]
            v202 += v220 * v218 - v211 * v217
            v201 += v211 * v216 - v219 * v218
            v200 += v219 * v217 - v220 * v216
            v211 = rates.angular_velocity
            v221 = v202 * v160
            v212 = v201 * v160
            v222 = v200 * v160
            v211.x = v221
            v211.y = v212
            v211.z = v222
        end

        v219 = v199 + 1
        v220 = v199 + 2
        v211 = v199 + 3
        v162[v219] = v205
        v162[v220] = v207
        v162[v211] = v209
        v219 = v199 + 4
        v220 = v199 + 5
        v211 = v199 + 6
        v162[v219] = v206
        v162[v220] = v208
        v162[v211] = v210
        v219 = v199 + 7
        v220 = v199 + 8
        v211 = v199 + 9
        v162[v219] = v213
        v162[v220] = v214
        v162[v211] = v215
        v219 = v199 + 10
        v220 = v199 + 11
        v211 = v199 + 12
        v162[v219] = v216
        v162[v220] = v217
        v162[v211] = v218
    end

    v7 = true
    t1.stats.place_seconds += os.clock() - elapsed
end

function t1.place(p41, p42) -- line: 932
    -- upvalues: t1 (copy)
    if t1.USE_REFERENCE_PLACE then
        return t1.place_reference(p41, p42)
    end

    return t1.place_fast(p41, p42)
end

t1.SLEEP_NEAR = 2
t1.SLEEP_BOARD_SPEED = 0.6

v4 = function(p43) -- line: 969
    -- upvalues: t1 (copy), v5 (ref), n5 (ref), v12 (ref), v13 (ref), v14 (ref)
    if not v12 then
        return
    end

    v12 = false

    local v257 = v13

    v13 = nil

    if v257 ~= nil then
        for i = 1, 24 do
            local v258 = v257[i]

            if v258 ~= nil then
                local v259 = v14[i]

                if bit32.band(v259, 4) ~= 0 then
                    v258.state_flags = bit32.bor(v258.state_flags, 4)
                end
            end
        end
    end

    if v5 ~= nil then
        n5 = v5.soft
    end

    if p43 ~= nil then
        local wake_by = t1.stats.wake_by

        wake_by[p43] = (wake_by[p43] or 0) + 1
    end
end

function t1.release() -- line: 995
    -- upvalues: v4 (ref), fresh_state (copy), forget_engines (copy)
    v4("off")
    forget_engines()
    fresh_state()
end

local function sleep_check(p44, p45, p46) -- line: 1002
    -- upvalues: t1 (copy), v5 (ref), v15 (ref)
    local wipeout_state = p45.wipeout_state
    local v260 = wipeout_state and wipeout_state.state

    if type(v260) ~= "table" or v260.over ~= true then
        return false, "moving"
    end

    if p46 and (type(v260.settled_time) ~= "number" or not (v260.settled_time >= v5.sleep_after * 0.016666666666666666)) then
        return false, nil
    end

    local animation_input = p45.animation_input
    local v261 = animation_input and animation_input.extra

    if type(v261) == "table" then
        local wipeout_control, wipeout_gesture = v261.wipeout_control, v261.wipeout_gesture

        if type(wipeout_control) == "table" and (wipeout_control[1] ~= 0 or wipeout_control[2] ~= 0) or type(wipeout_gesture) == "table" and (wipeout_gesture[1] ~= 0 or wipeout_gesture[2] ~= 0) then
            return false, "control"
        end
    end

    local bodies = p45.skeleton.bodies
    local board = p44.board

    board = board and board.bodies and board.bodies[7]

    local v262 = bodies[24]

    v15 = true

    if board ~= nil and v262 ~= nil then
        local position, linear_velocity = board.rates.position, board.rates.linear_velocity
        local position2 = v262.rates.position
        local v263 = position.x - position2.x
        local v264 = position.y - position2.y
        local v265 = position.z - position2.z
        local v266 = v263 * v263 + v264 * v264 + v265 * v265 < t1.SLEEP_NEAR * t1.SLEEP_NEAR

        v15 = v266

        if v266 and linear_velocity.x * linear_velocity.x + linear_velocity.y * linear_velocity.y + linear_velocity.z * linear_velocity.z > t1.SLEEP_BOARD_SPEED * t1.SLEEP_BOARD_SPEED then
            return false, "board"
        end
    end

    if p46 then
        local v267 = v5.sleep_speed * v5.sleep_speed
        local v268 = v5.sleep_spin * v5.sleep_spin

        for i = 1, 24 do
            local v269 = bodies[i]

            if bit32.band(v269.state_flags, 4) == 0 then
                return false, nil
            end

            local rates = v269.rates
            local linear_velocity, angular_velocity = rates.linear_velocity, rates.angular_velocity

            if v267 < linear_velocity.x * linear_velocity.x + linear_velocity.y * linear_velocity.y + linear_velocity.z * linear_velocity.z or v268 < angular_velocity.x * angular_velocity.x + angular_velocity.y * angular_velocity.y + angular_velocity.z * angular_velocity.z then
                return false, nil
            end
        end
    end

    return true, nil
end

v3 = function(p47, p48) -- line: 1055
    -- upvalues: t1 (copy), v4 (ref), v12 (ref), v13 (ref), v14 (ref), sleep_check (copy)
    local skeleton = p48.skeleton
    local v270 = skeleton and skeleton.bodies

    if type(v270) == "table" and not (#v270 < 24) then
        if v12 and v13 ~= v270 then
            v12 = false
            v13 = nil
        end

        local v271, v272 = sleep_check(p47, p48, not v12)

        if v271 then
            if not v12 then
                v12 = true
                v13 = v270
                t1.stats.sleeps += 1

                for i = 1, 24 do
                    local v273 = v270[i]

                    v14[i] = v273.state_flags
                    v273.state_flags = bit32.band(v273.state_flags, 4294967291)
                end

                t1.asleep_end(p48, p47)
            end

            return true
        end

        v4(v272 or "moving")

        return false
    end

    v4("moving")

    return false
end

function t1.asleep_pairs() -- line: 1086
    -- upvalues: v15 (ref)
    return v15
end

local v275, bounds_xyzr
local t5 = {}
local t6 = {}
local t7 = {}
local t8 = {}

function t1.asleep_board_pairs(p49, p50, p51, p52, p53) -- line: 1097
    -- upvalues: import (copy), v275 (ref), bounds_xyzr (ref), t5 (copy), t6 (copy), t7 (copy), t8 (copy)
    if v275 == nil then
        v275 = import("skate_game/physics/solve/assembly_contacts")
        bounds_xyzr = import("skate_game/physics/network").bounds_xyzr
    end

    local group_pair_allowed = v275.group_pair_allowed

    if p52 >= 21 or p53.assembly_group >= 21 or not group_pair_allowed(p52, p53.assembly_group) then
        return
    end

    local parts = p53.parts
    local v276 = #p51

    for i = 1, v276 do
        local v277, v278, v279, v280 = bounds_xyzr(p51[i].primitive)

        t5[i] = v277
        t6[i] = v278
        t7[i] = v279
        t8[i] = v280
    end

    for _, v281 in ipairs(p50) do
        local v282, v283, v284, v285 = bounds_xyzr(v281.primitive)

        for j = 1, v276 do
            local v286 = v282 - t5[j]
            local v287 = v283 - t6[j]
            local v288 = v284 - t7[j]
            local v289 = v285 + t8[j] + 0.05

            if v286 * v286 + v287 * v287 + v288 * v288 <= v289 * v289 then
                local v290 = p51[j]
                local v291 = parts[v290.body[1] + 1]

                if v291 ~= nil and v291.part_group < 21 and group_pair_allowed(p52, v291.part_group) then
                    v275.append_pair_pooled(p49, v281, v290)
                end
            end
        end
    end
end

function t1.asleep_end(p54, p55) -- line: 1133
    -- upvalues: to_bits (copy), v153 (copy), writef32 (copy), readf32 (copy), writeu32 (copy)
    local gravity_acceleration = p55.settings.step.simulation.gravity_acceleration
    local x = gravity_acceleration.x

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        writeu32(v153, 0, to_bits(x))
    else
        writef32(v153, 0, x)
    end

    local v292 = readf32(v153, 0)
    local y = gravity_acceleration.y

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        writeu32(v153, 0, to_bits(y))
    else
        writef32(v153, 0, y)
    end

    local v293 = readf32(v153, 0)
    local z = gravity_acceleration.z

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        writeu32(v153, 0, to_bits(z))
    else
        writef32(v153, 0, z)
    end

    local v294 = readf32(v153, 0)
    local bodies = p54.skeleton.bodies

    for i = 1, 24 do
        local rates = bodies[i].rates
        local linear_velocity, angular_velocity, force_acceleration, torque_acceleration = rates.linear_velocity, rates.angular_velocity, rates.force_acceleration, rates.torque_acceleration

        linear_velocity.x = 0
        linear_velocity.y = 0
        linear_velocity.z = 0
        angular_velocity.x = 0
        angular_velocity.y = 0
        angular_velocity.z = 0
        force_acceleration.x = v292
        force_acceleration.y = v293
        force_acceleration.z = v294
        torque_acceleration.x = 0
        torque_acceleration.y = 0
        torque_acceleration.z = 0
    end
end

function t1.is_asleep() -- line: 1147
    -- upvalues: v12 (ref)
    return v12
end

return t1
