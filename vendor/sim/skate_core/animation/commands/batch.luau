-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/commands/buffers")
local v2 = import("skate_core/animation/commands/set_data")
local t1 = {
    JobId = {}
}

function t1.JobId.eq(p1, p2) -- line: 26
    if p1.owner == p2.owner then
        return p1.index == p2.index
    end

    return false
end

t1.QueueError = {}
t1.Job = {}

function t1.Job.new() -- line: 40
    return {
        bone_count = 0,
        commands = {},
        dependencies = {}
    }
end

t1.SetDataQueue = {}

function t1.SetDataQueue.new(p3, p4) -- line: 54
    -- upvalues: v1 (copy), t1 (copy)
    return {
        command_count = 0,
        owner = v1.new_owner(),
        buffers = p3,
        max_work_units = p4,
        prepared = {},
        current = t1.Job.new()
    }
end

function t1.SetDataQueue.enqueue(p5, p6, p7, p8) -- line: 69
    -- upvalues: rt (copy), t1 (copy)
    if p5.command_count == 65535 then
        error("CommandCapacityExceeded", 0)
    end

    local v3 = #p5.current.commands == p5.max_work_units
    local t2 = {
        owner = p5.owner,
        index = #p5.prepared + (v3 and 1 or 0)
    }
    local v4 = if v3 then {} else rt.copy(p5.current.dependencies)

    for i = 1, table.maxn(p8) do
        local v5 = p8[i]

        if v5 ~= nil and not t1.JobId.eq(v5, t2) then
            if v5.owner ~= p5.owner or v5.index >= t2.index then
                error("UnavailableDependency", 0)
            end

            local v6 = false

            for _, v7 in ipairs(v4) do
                if t1.JobId.eq(v7, v5) then
                    v6 = true
                    break
                end
            end

            if not v6 then
                if #v4 == 255 then
                    error("DependencyCapacityExceeded", 0)
                end

                table.insert(v4, rt.copy(v5))
            end
        end
    end

    if v3 then
        t1.SetDataQueue.flush(p5)
    end

    p5.current.bone_count = p6
    table.insert(p5.current.commands, p7)
    p5.current.dependencies = v4
    p5.command_count += 1

    return t2
end

function t1.SetDataQueue.flush(p9) -- line: 122
    -- upvalues: t1 (copy)
    if #p9.current.commands == 0 then
        return false
    end

    local current = p9.current

    p9.current = t1.Job.new()
    table.insert(p9.prepared, current)

    return true
end

function t1.SetDataQueue.submit(p10) -- line: 134
    -- upvalues: t1 (copy)
    t1.SetDataQueue.flush(p10)

    return {
        owner = p10.owner,
        buffers = p10.buffers,
        jobs = p10.prepared
    }
end

function t1.SetDataQueue.cancel(p11) -- line: 144
    return p11.buffers
end

t1.PendingSetData = {}

function t1.PendingSetData.complete(p12) -- line: 155
    -- upvalues: v2 (copy)
    for v8, v9 in ipairs(p12.jobs) do
        local v10 = v8 - 1
        local execute = v2.execute
        local buffers = p12.buffers
        local bone_count, commands = v9.bone_count, v9.commands
        local ok, result = pcall(execute, buffers, bone_count, commands)

        if not ok then
            error({
                buffers = p12.buffers,
                job = {
                    owner = p12.owner,
                    index = v10
                },
                cause = result
            }, 0)
        end
    end

    return {
        buffers = p12.buffers
    }
end

t1.ExecutionFailure = {}
t1.CompletedSetData = {}

function t1.CompletedSetData.buffers(p13) -- line: 183
    return p13.buffers
end

function t1.CompletedSetData.into_buffers(p14) -- line: 188
    return p14.buffers
end

return t1
