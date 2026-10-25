-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/modding/participation")

local function skate_dynamics() -- line: 22
    -- upvalues: import (copy)
    return import("skate_dynamics")
end

local t1 = {
    player_suspended = v1.player_suspended,
    peer_suspended = v1.peer_suspended,
    ModMenu = {}
}

function t1.ModMenu.default() -- line: 40
    return {
        open = false,
        just_opened = false,
        id = nil,
        custom = nil,
        return_to_pause = false,
        selected = 0,
        editing = nil,
        status = "",
        path = {}
    }
end

function t1.ModMenu.begin(p1) -- line: 55
    p1.open = true
    p1.return_to_pause = false
    p1.just_opened = true
    p1.id = nil
    p1.custom = nil
    table.clear(p1.path)
    p1.selected = 0
    p1.editing = nil
    p1.status = ""
end

function t1.ModMenu.open_registered(p2, p3, p4) -- line: 68
    -- upvalues: t1 (copy)
    t1.ModMenu.begin(p2)
    p2.id = p3
    p2.custom = p4
    p2.return_to_pause = true
end

t1.Mods = {}
t1.NetWire = {}
t1.ModCameraSet = {}
t1.AttachState = {}
t1.CameraOverride = {}

function t1.CameraOverride.default() -- line: 136
    return {
        owner = nil,
        rig = nil,
        saved_near = nil,
        follow = nil,
        fixed = nil,
        watch = nil
    }
end

function t1.CameraOverride.clear(p5) -- line: 147
    -- upvalues: rt (copy), t1 (copy)
    local saved_near = p5.saved_near

    p5.saved_near = nil

    local v2 = t1.CameraOverride.default()

    v2.saved_near = saved_near
    rt.assign(p5, v2)
end

function t1.CameraOverride.claim(p6, p7) -- line: 157
    if p6.owner ~= nil and p6.owner ~= p7 then
        error("camera is owned by another mod", 0)
    end

    p6.owner = p7
end

function t1.CameraOverride.follows(p8, p9, p10) -- line: 164
    local v3, v4

    if p8.owner == p9 then
        if p8.rig ~= nil then
            if p8.rig.body == p10 then
                v3 = true
                v4 = true
            else
                v4 = false
            end
        else
            v4 = false
        end
    else
        v3 = false
        v4 = true
    end

    if not v4 then
        v3 = p8.follow ~= nil and p8.follow[2] == p10
    end

    return v3
end

t1.ModdingPlugin = {}

function t1.ModdingPlugin.build() -- line: 178
    -- upvalues: import (copy), t1 (copy)
    return {
        manager = {
            packages = {},
            commands = {},
            retired = {}
        },
        native_snapshot = nil,
        world = import("skate_dynamics").DynamicsWorld.default(),
        bodies = {},
        joints = {},
        graphics = {},
        overlays = {},
        canvases = {},
        attach = nil,
        detach_error = nil,
        detach_pending = nil,
        camera = t1.CameraOverride.default(),
        generation = "0xFFFFFFFFFFFFFFFF",
        graphics_serial = 0,
        debug_owners = {},
        ground_ready = false,
        skater_proxies = {},
        dyn_published = {},
        replication = {},
        net_states = {},
        net_published = {},
        net_remote = {},
        net_remote_wire = {},
        net_status = "",
        multiplayer_debug = {},
        last_contacts = {},
        graph_gates = {},
        command_results = {},
        input_overrides = {},
        session = {},
        skater_remote = {},
        pending_remote_teleport = nil,
        volumes = {},
        custom_menus = {},
        suspended_by = {},
        hidden_players = {},
        remote_cameras = {}
    }
end

function t1.register_source() -- line: 222
end

function t1.package_root(p11, p12) -- line: 227
    if p11 ~= nil then
        return p11
    end

    if p12 == nil or p12 == "" then
        return "mods"
    end

    local v5 = string.sub(p12, -1)

    if v5 == "/" or v5 == "\\" then
        return p12 .. "mods"
    end

    return p12 .. "/mods"
end

function t1.player_attached(p13) -- line: 245
    return p13.attach ~= nil
end

function t1.Mods.runtime_busy(p14) -- line: 252
    for _, v6 in p14.manager.packages do
        if v6.running == true then
            return true
        end
    end

    if #p14.manager.commands == 0 and #p14.manager.retired == 0 and next(p14.bodies) == nil and next(p14.graphics) == nil and next(p14.overlays) == nil and next(p14.joints) == nil and p14.attach == nil and next(p14.canvases) == nil and next(p14.skater_proxies) == nil then
        return next(p14.volumes) ~= nil
    end

    return true
end

local function count_keys(p15) -- line: 278
    local n1 = 0

    for _ in p15 do
        n1 += 1
    end

    return n1
end

local function sorted_keys(p16) -- line: 286
    local t2 = {}

    for v7 in p16 do
        table.insert(t2, v7)
    end

    table.sort(t2)

    return t2
end

function t1.Mods.multiplayer_debug_sections(p17) -- line: 299
    local format = string.format
    local v8 = "MOD REPLICATION\n%s\nLocal network keys: %d | Remote keys: %d\nPublished dynamics: %d | Local bodies: %d | Local scenes: %d"
    local v9 = if p17.net_status == "" then "No active mod replication" else p17.net_status
    local n2 = 0

    for _ in p17.net_states do
        n2 += 1
    end

    local n3 = 0

    for _ in p17.net_remote do
        n3 += 1
    end

    local n4 = 0

    for _ in p17.dyn_published do
        n4 += 1
    end

    local n5 = 0

    for _ in p17.bodies do
        n5 += 1
    end

    local n6 = 0

    for _ in p17.graphics do
        n6 += 1
    end

    local v10 = format(v8, v9, n2, n3, n4, n5, n6)
    local t3 = {}
    local _ipairs = ipairs
    local t4 = {}

    for v11 in p17.manager.packages do
        table.insert(t4, v11)
    end

    table.sort(t4)

    for _, v12 in _ipairs(t4) do
        local v13 = p17.manager.packages[v12]
        local v14 = if v13.running == true then "running" elseif v13.enabled then "enabled / stopped" else "disabled"

        table.insert(t3, v13.manifest.name .. " — " .. v14 .. (if v13.error == nil then "" else "\n" .. v13.error))
    end

    local v16 = table.concat(t3, "\n")
    local t5 = {}

    for _, v17 in ipairs(p17.multiplayer_debug) do
        local v18 = v17[1][1]
        local v19 = v17[1][2]
        local v20 = v17[2]
        local v21 = p17.manager.packages[v18]

        if v21 ~= nil then
            v18 = v21.manifest.name
        end

        table.insert(t5, v18 .. " / " .. v19 .. "\n" .. v20)
    end

    local v23 = table.concat(t5, "\n\n")

    if v16 == "" then
        v16 = "No packages installed"
    end

    local v24 = "MOD PACKAGES\n" .. v16

    if v23 == "" then
        v23 = "No mod multiplayer diagnostics reported"
    end

    return {
        v10,
        v24,
        "MOD DIAGNOSTICS\n" .. v23
    }
end

function t1.override_actions(p18, p19) -- line: 342
    if p18 == nil then
        return
    end

    local _ipairs = ipairs
    local t7 = {}

    for v26 in p18.input_overrides do
        table.insert(t7, v26)
    end

    table.sort(t7)

    for _, v27 in _ipairs(t7) do
        p19[v27 - 64 + 1] = p18.input_overrides[v27][2]
    end
end

return t1
