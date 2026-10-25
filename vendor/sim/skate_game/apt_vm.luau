-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 6
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

require(sim.import)

local t1 = {}
local t2 = {
    tag = "Undefined"
}
local t3 = {
    tag = "Bool",
    true
}
local t4 = {
    tag = "Bool",
    false
}

local function bool_value(p2) -- line: 37
    -- upvalues: t3 (copy), t4 (copy)
    if p2 then
        return t3
    end

    return t4
end

local function parse_f64(p3) -- line: 42
    local v2 = string.sub(p3, 1, 1)
    local v3, v4

    if v2 == "+" or v2 == "-" then
        v4 = v2 == "-"
        v3 = string.sub(p3, 2)
    else
        v3 = p3
        v4 = false
    end

    local v5 = string.lower(v3)
    local v6

    if v5 == "inf" or v5 == "infinity" then
        v6 = 1e999
    elseif v5 == "nan" then
        v6 = (0/0)
    else
        local v7, v8 = string.match(v3, "^([%d%.]+)[eE]([%+%-]?%d+)$")

        if v7 == nil or v8 == nil then
            v7 = v3
        end

        if string.match(v7, "^%d+%.?%d*$") == nil and string.match(v7, "^%.%d+$") == nil then
            return nil
        end

        v6 = tonumber(v3)

        if v6 == nil then
            return nil
        end
    end

    if v4 then
        return -v6
    end

    return v6
end

local function f64_to_string(p4) -- line: 75
    if p4 ~= p4 then
        return "NaN"
    end

    if p4 == 1e999 then
        return "inf"
    end

    if p4 == (-1e999) then
        return "-inf"
    end

    if p4 == 0 then
        if 1 / p4 < 0 then
            return "-0"
        end

        return "0"
    end

    if p4 ~= math.floor(p4) or not (math.abs(p4) < 9007199254740992) then
        return (tostring(p4))
    end

    return string.format("%d", p4)
end

t1.Value = {}

function t1.Value.default() -- line: 94
    -- upvalues: t2 (copy)
    return t2
end

function t1.Value.eq(p5, p6) -- line: 99
    if p5.tag == p6.tag then
        return p5[1] == p6[1]
    end

    return false
end

local eq2 = t1.Value.eq

function t1.Value.number(p7) -- line: 105
    -- upvalues: parse_f64 (copy)
    local tag = p7.tag

    if tag == "Number" then
        return p7[1]
    end

    if tag == "Bool" then
        if p7[1] then
            return 1
        end

        return 0
    end

    if tag ~= "Text" then
        return (0/0)
    end

    local v9 = parse_f64(p7[1])

    if v9 == nil then
        return (0/0)
    end

    return v9
end

local number2 = t1.Value.number

function t1.Value.truth(p8) -- line: 127
    local tag = p8.tag

    if tag == "Undefined" then
        return false
    end

    if tag == "Number" then
        local v10 = p8[1]

        if v10 == 0 then
            return false
        end

        return v10 == v10
    end

    if tag == "Bool" then
        return p8[1]
    end

    if tag == "Text" then
        return #p8[1] ~= 0
    end

    return true
end

local truth2 = t1.Value.truth

function t1.Value.text(p9) -- line: 144
    -- upvalues: f64_to_string (copy)
    local tag = p9.tag

    if tag == "Undefined" then
        return "undefined"
    end

    if tag == "Number" then
        return f64_to_string(p9[1])
    end

    if tag == "Bool" then
        if p9[1] then
            return "true"
        end

        return "false"
    end

    if tag == "Text" then
        return p9[1]
    end

    return "[object Object]"
end

local text2 = t1.Value.text

t1.Constant = {}

function t1.Constant.value(p10) -- line: 164
    -- upvalues: t2 (copy), t3 (copy), t4 (copy)
    local kind, value = p10.kind, p10.value

    if kind == 1 then
        if type(value) ~= "string" then
            error("Invalid APT string constant", 0)
        end

        return {
            tag = "Text",
            value
        }
    end

    if kind == 5 then
        if type(value) ~= "number" or value < 0 or value ~= math.floor(value) then
            error("Invalid APT bool constant", 0)
        end

        if value ~= 0 then
            return t3
        end

        return t4
    end

    if kind == 6 or kind == 7 then
        if type(value) ~= "number" then
            error("Invalid APT number constant", 0)
        end

        return {
            tag = "Number",
            value
        }
    end

    if kind == 3 then
        return t2
    end

    error(("Unresolved APT constant type %*"):format(kind), 0)
end

local value2 = t1.Constant.value

t1.Parameter = {}
t1.Instruction = {}
t1.ObjectKind = {}

local t5 = {
    tag = "Plain"
}

t1.Object = {}
t1.Function = {}
t1.Scope = {}
t1.Host = {}

function t1.Host.property_changed(_, _, _, _) -- line: 224
end

t1.Vm = {}

local Vm = t1.Vm

function t1.Vm.default() -- line: 236
    return {
        global = 0,
        remaining = 0,
        depth = 0,
        objects = {},
        free_objects = {},
        functions = {}
    }
end

function t1.Vm.variable(p15, p16, p17) -- line: 248
    -- upvalues: Vm (copy)
    local v11 = p16.locals[p17]

    if v11 ~= nil then
        return v11
    end

    local v12 = Vm.get(p15, p16.this, p17)

    if v12.tag == "Undefined" then
        return Vm.get(p15, p15.global, p17)
    end

    return v12
end

function t1.Vm.new() -- line: 261
    -- upvalues: t5 (copy), Vm (copy)
    local v13 = Vm.default()

    v13.global = Vm.object(v13, t5)

    return v13
end

function t1.Vm.object(p18, p19) -- line: 268
    local free_objects = p18.free_objects
    local v14 = #free_objects

    if v14 > 0 then
        local v15 = free_objects[v14]

        free_objects[v14] = nil
        p18.objects[v15 + 1] = {
            prototype = nil,
            kind = p19,
            fields = {}
        }

        return v15
    end

    local v16 = #p18.objects

    table.insert(p18.objects, {
        prototype = nil,
        kind = p19,
        fields = {}
    })

    return v16
end

local t7 = {}
local t8 = {}

function t1.Vm.collect(p20, p21) -- line: 304
    -- upvalues: t5 (copy), t7 (copy), t8 (copy)
    if p20.depth ~= 0 then
        error("Cannot collect during an APT call", 0)
    end

    local objects = p20.objects
    local v17 = #objects

    table.clear(t8)
    table.clear(t7)

    local v18 = #p21

    table.move(p21, 1, v18, 1, t7)

    local v19 = v18 + 1

    t7[v19] = p20.global

    while v19 > 0 do
        local v20 = t7[v19]

        t7[v19] = nil

        local v21 = v19 - 1

        if v20 < 0 or v17 <= v20 then
            table.clear(t7)
            error("Invalid APT collection root", 0)
        end

        local v22

        if t8[v20 + 1] then
            v22 = v21
        else
            t8[v20 + 1] = true

            local v23 = objects[v20 + 1]
            local v24

            if v23.prototype ~= nil then
                v24 = v21 + 1
                t7[v24] = v23.prototype
            else
                v24 = v21
            end

            local v25 = v24

            v22 = v24

            for _, v26 in v23.fields do
                if v26.tag == "Object" then
                    v25 += 1
                    t7[v25] = v26[1]
                end

                v22 = v25
            end
        end

        v19 = v22
    end

    local free_objects = p20.free_objects

    table.clear(free_objects)

    local n1 = 0

    for i = 1, v17 do
        local v27

        if t8[i] then
            v27 = n1
        else
            local v28 = objects[i]

            if v28.kind ~= t5 or v28.prototype ~= nil or next(v28.fields) ~= nil then
                objects[i] = {
                    prototype = nil,
                    kind = t5,
                    fields = {}
                }
            end

            v27 = n1 + 1
            free_objects[v27] = i - 1
        end

        n1 = v27
    end
end

function t1.Vm.collect_reference(p22, p23) -- line: 365
    -- upvalues: t5 (copy)
    if p22.depth ~= 0 then
        error("Cannot collect during an APT call", 0)
    end

    local objects = p22.objects
    local v29 = #objects
    local v30 = table.create(v29, false)
    local v31 = table.clone(p23)

    table.insert(v31, p22.global)

    while true do
        local v32 = #v31

        if v32 == 0 then
            break
        end

        local v33 = v31[v32]

        v31[v32] = nil

        if v33 < 0 or v29 <= v33 then
            error("Invalid APT collection root", 0)
        end

        if not v30[v33 + 1] then
            v30[v33 + 1] = true

            local v34 = objects[v33 + 1]

            if v34.prototype ~= nil then
                table.insert(v31, v34.prototype)
            end

            for _, v35 in v34.fields do
                if v35.tag == "Object" then
                    table.insert(v31, v35[1])
                end
            end
        end
    end

    table.clear(p22.free_objects)

    for i = 1, v29 do
        if not v30[i] then
            objects[i] = {
                prototype = nil,
                kind = t5,
                fields = {}
            }
            table.insert(p22.free_objects, i - 1)
        end
    end
end

function t1.Vm.set(p24, p25, p26, p27) -- line: 412
    local v37 = p24.objects[p25 + 1]

    if v37 == nil then
        error("Invalid APT object handle", 0)
    end

    v37.fields[p26] = p27
end

function t1.Vm.get(p28, p29, p30) -- line: 421
    -- upvalues: t2 (copy)
    local objects = p28.objects
    local v38 = p29

    for _ = 1, 64 do
        if v38 == nil then
            break
        end

        local v39 = objects[v38 + 1]

        if v39 == nil then
            break
        end

        local v40 = v39.fields[p30]

        if v40 ~= nil then
            return v40
        end

        v38 = v39.prototype
    end

    return t2
end

function t1.Vm.begin_update(p31) -- line: 442
    p31.remaining = 1E+05
end

function t1.Vm.run(p32, p33, p34) -- line: 447
    -- upvalues: Vm (copy)
    Vm.begin_update(p32)

    return Vm.run_on(p32, p32.global, p33, p34)
end

local v41 = table.create(256, t2)
local v42 = false

function t1.Vm.run_on(p35, p36, p37, p38) -- line: 459
    -- upvalues: t2 (copy), Vm (copy), v41 (copy), v42 (ref)
    if v42 then
        return Vm.run_on_reference(p35, p36, p37, p38)
    end

    for i = 1, 256 do
        v41[i] = t2
    end

    for i = #v41, 257, -1 do
        v41[i] = nil
    end

    v42 = true

    local execute = Vm.execute
    local t11 = {}
    local t12 = {
        local_definitions = false,
        this = p36,
        locals = {}
    }
    local ok, result = pcall(execute, p35, p37, v41, t11, t12, p38)

    v42 = false

    if not ok then
        error(result, 0)
    end

    return result
end

function t1.Vm.run_on_reference(p39, p40, p41, p42) -- line: 484
    -- upvalues: t2 (copy), Vm (copy)
    return Vm.execute(p39, p41, table.create(256, t2), {}, {
        local_definitions = false,
        this = p40,
        locals = {}
    }, p42)
end

function t1.Vm.call_method(p43, p44, p45, p46, p47) -- line: 494
    -- upvalues: Vm (copy)
    local v43 = Vm.get(p43, p44, p45)

    if v43.tag == "Object" then
        local v44 = p43.objects[v43[1] + 1]

        if v44 ~= nil and v44.kind.tag == "Function" then
            return Vm.invoke(p43, v44.kind[1], p44, p46, p47)
        end
    end

    return p47.call(p47, p43, p44, p45, p46)
end

function t1.Vm.invoke(p48, p49, p50, p51, p52) -- line: 506
    -- upvalues: t2 (copy), t5 (copy), Vm (copy)
    if p48.depth >= 32 then
        error("APT call-depth limit", 0)
    end

    local v45 = p48.functions[p49 + 1]

    if v45 == nil then
        error("Invalid APT function", 0)
    end

    local code = v45.code
    local v46 = code.flags or 0
    local v47 = table.create(256, t2)
    local t13 = {
        local_definitions = true,
        this = p50,
        locals = {}
    }

    if bit32.band(v46, 2) == 0 then
        t13.locals.this = {
            tag = "Object",
            p50
        }
    end

    local _root = Vm.get(p48, p50, "_root")

    if _root.tag == "Undefined" then
        _root = {
            tag = "Object",
            p48.global
        }
    end

    local _parent = Vm.get(p48, p50, "_parent")
    local t14

    if bit32.band(v46, 4) ~= 0 or bit32.band(v46, 8) == 0 then
        local v48 = Vm.object(p48, t5)

        for v49, v50 in p51 do
            Vm.set(p48, v48, string.format("%d", v49 - 1), v50)
        end

        Vm.set(p48, v48, "length", {
            tag = "Number",
            #p51
        })
        t14 = {
            tag = "Object",
            v48
        }
    else
        t14 = t2
    end

    if bit32.band(v46, 8) == 0 then
        t13.locals.arguments = t14
    end

    local v51

    if bit32.band(v46, 1) == 0 then
        v51 = 1
    else
        v47[1 + 1] = {
            tag = "Object",
            p50
        }
        v51 = 1 + 1
    end

    if bit32.band(v46, 4) ~= 0 then
        v47[v51 + 1] = t14
        v51 += 1
    end

    if bit32.band(v46, 16) ~= 0 then
        v47[v51 + 1] = t2
        v51 += 1
    end

    if bit32.band(v46, 64) ~= 0 then
        v47[v51 + 1] = _root
        v51 += 1
    end

    if bit32.band(v46, 128) ~= 0 then
        v47[v51 + 1] = _parent
        v51 += 1
    end

    if bit32.band(v46, 256) ~= 0 then
        v47[v51 + 1] = {
            tag = "Object",
            p48.global
        }

        local _ = v51 + 1
    end

    local parameters = code.parameters

    if parameters ~= nil then
        for v52, v53 in parameters do
            if v53.register >= 256 then
                error("APT parameter register outside bank", 0)
            end

            local v54 = p51[v52]

            if v54 == nil then
                v54 = t2
            end

            if v53.register == 0 then
                t13.locals[v53.name] = v54
            else
                v47[v53.register + 1] = v54
            end
        end
    end

    p48.depth += 1

    local execute = Vm.execute
    local v55 = code.body or {}
    local v56 = table.clone(v45.constants)
    local ok, result = pcall(execute, p48, v55, v47, v56, t13, p52)

    p48.depth -= 1

    if not ok then
        error(result, 0)
    end

    return result
end

local self = setmetatable({}, {
    __mode = "k"
})

local function jump_table(p53) -- line: 600
    -- upvalues: self (copy)
    local v58 = self[p53]

    if v58 == nil then
        v58 = {}

        for v59, v60 in p53 do
            if v58[v60.offset] == nil then
                v58[v60.offset] = v59 - 1
            end
        end

        self[p53] = v58
    end

    return v58
end

function t1.Vm.execute(p54, p55, p56, p57, p58, p59) -- line: 617
    -- upvalues: rt (copy), v1 (copy), t2 (copy), t3 (copy), t4 (copy), eq2 (copy), number2 (copy), truth2 (copy), text2 (copy), value2 (copy), t5 (copy), Vm (copy), jump_table (copy)
    local t17 = {}
    local n2 = 0
    local n3 = 0

    while true do
        local v61 = p55[n3 + 1]

        if v61 == nil then
            break
        end

        if p54.remaining == 0 or #p54.objects > 4096 then
            error("APT execution/object budget exceeded", 0)
        end

        p54.remaining -= 1
        n3 += 1

        local opcode, operand = v61.opcode, v61.operand
        local v62 = if type(operand) == "number" and operand >= 0 and operand == math.floor(operand) then operand else 0

        if opcode == 0 then
            break
        end

        if opcode == 112 then
            n2 += 1
            t17[n2] = {
                tag = "Object",
                p58.this
            }
        elseif opcode == 161 then
            if type(operand) ~= "string" then
                error("APT string operand missing", 0)
            end

            n2 += 1
            t17[n2] = {
                tag = "Text",
                operand
            }
        elseif opcode == 164 then
            if type(operand) ~= "string" then
                error("APT variable operand missing", 0)
            end

            n2 += 1
            t17[n2] = Vm.variable(p54, p58, operand)
        elseif opcode == 6 or opcode == 7 then
            p59.call(p59, p54, p58.this, opcode == 6 and "play" or "stop", {})
        elseif opcode == 23 then
            if n2 == 0 then
                error("APT stack underflow", 0)
            end

            t17[n2] = nil
            n2 -= 1
        elseif opcode == 18 then
            if n2 == 0 then
                error("APT stack underflow", 0)
            end

            if not truth2(t17[n2]) then
                t17[n2] = t3
            else
                t17[n2] = t4
            end
        elseif opcode == 76 then
            if n2 == 0 then
                error("APT duplicate on empty stack", 0)
            end

            t17[n2 + 1] = t17[n2]
            n2 += 1
        elseif opcode == 89 then
            n2 += 1
            t17[n2] = {
                tag = "Number",
                0
            }
        elseif opcode == 90 then
            n2 += 1
            t17[n2] = {
                tag = "Number",
                1
            }
        elseif opcode == 113 then
            n2 += 1
            t17[n2] = {
                tag = "Object",
                p54.global
            }
        elseif opcode == 115 then
            n2 += 1
            t17[n2] = t3
        elseif opcode == 116 then
            n2 += 1
            t17[n2] = t4
        elseif opcode == 117 or opcode == 118 then
            n2 += 1
            t17[n2] = t2
        elseif opcode == 181 then
            local v63 = v62 % 256

            if v63 >= 128 then
                v63 -= 256
            end

            n2 += 1
            t17[n2] = {
                tag = "Number",
                v63
            }
        elseif opcode == 182 then
            local v64 = v62 % 65536

            if v64 >= 32768 then
                v64 -= 65536
            end

            n2 += 1
            t17[n2] = {
                tag = "Number",
                v64
            }
        elseif opcode == 183 then
            n2 += 1
            t17[n2] = {
                tag = "Number",
                (rt.to_i32(v62 % 4294967296))
            }
        elseif opcode == 180 then
            n2 += 1
            buffer.writeu32(v1, 0, v62 % 4294967296)
            t17[n2] = {
                tag = "Number",
                (buffer.readf32(v1, 0))
            }
        elseif opcode == 185 then
            local v66 = p56[v62 + 1]

            if v66 == nil then
                error("APT register outside bank", 0)
            end

            n2 += 1
            t17[n2] = v66
        elseif opcode == 135 then
            if #p56 <= v62 then
                error("APT register outside bank", 0)
            end

            if n2 == 0 then
                error("APT register store on empty stack", 0)
            end

            p56[v62 + 1] = t17[n2]
        elseif opcode == 136 then
            local t19 = {}
            local values = v61.values

            if values ~= nil then
                for v67, v68 in values do
                    t19[v67] = value2(v68)
                end
            end

            table.clear(p57)
            table.move(t19, 1, #t19, 1, p57)
        elseif opcode == 150 then
            local values = v61.values

            if values ~= nil then
                local v69 = n2

                for _, v70 in values do
                    v69 += 1
                    n2 = v69
                    t17[v69] = value2(v70)
                end
            end
        elseif opcode == 162 or opcode == 163 then
            local v71 = p57[v62 + 1]

            if v71 == nil then
                error(string.format("APT constant index %d at %x", v62, v61.offset), 0)
            end

            n2 += 1
            t17[n2] = v71
        elseif opcode == 174 then
            local v72 = p57[v62 + 1]

            if v72 == nil then
                error(string.format("APT constant index %d at %x", v62, v61.offset), 0)
            end

            n2 += 1
            t17[n2] = Vm.variable(p54, p58, text2(v72))
        elseif opcode == 78 or opcode == 175 then
            local v73

            if opcode == 175 then
                v73 = p57[v62 + 1]

                if v73 == nil then
                    error(string.format("APT constant index %d at %x", v62, v61.offset), 0)
                end
            else
                if n2 == 0 then
                    error("APT stack underflow", 0)
                end

                v73 = t17[n2]
                t17[n2] = nil
                n2 -= 1
            end

            local v74 = text2(v73)

            if n2 == 0 then
                error("APT stack underflow", 0)
            end

            v73 = t17[n2]

            if v73.tag == "Object" then
                t17[n2] = Vm.get(p54, v73[1], v74)
            else
                t17[n2] = t2
            end
        elseif opcode == 79 then
            if n2 < 3 then
                error("APT stack underflow", 0)
            end

            local v75 = t17[n2]
            local v76 = text2(t17[n2 - 1])
            local v77 = t17[n2 - 2]

            t17[n2] = nil
            t17[n2 - 1] = nil
            t17[n2 - 2] = nil
            n2 -= 3

            if v77.tag == "Object" then
                local v78 = v77[1]

                Vm.set(p54, v78, v76, v75)
                p59.property_changed(p59, p54, v78, v76)
            end
        elseif opcode == 28 then
            if n2 == 0 then
                error("APT stack underflow", 0)
            end

            local v79 = text2(t17[n2])

            t17[n2] = Vm.variable(p54, p58, v79)
        elseif opcode == 29 or opcode == 60 then
            if n2 < 2 then
                error("APT stack underflow", 0)
            end

            local v80 = t17[n2]
            local v81 = text2(t17[n2 - 1])

            t17[n2] = nil
            t17[n2 - 1] = nil
            n2 -= 2

            if (opcode ~= 60 or not p58.local_definitions) and p58.locals[v81] == nil then
                Vm.set(p54, p58.this, v81, v80)
                p59.property_changed(p59, p54, p58.this, v81)
            else
                p58.locals[v81] = v80
            end
        elseif opcode == 58 then
            if n2 < 2 then
                error("APT stack underflow", 0)
            end

            local v82 = text2(t17[n2])
            local v83 = t17[n2 - 1]

            t17[n2] = nil
            n2 -= 1

            local v84

            if v83.tag == "Object" then
                local fields = p54.objects[v83[1] + 1].fields

                v84 = fields[v82] ~= nil
                fields[v82] = nil
            else
                v84 = false
            end

            if v84 then
                t17[n2] = t3
            else
                t17[n2] = t4
            end
        elseif opcode == 71 then
            if n2 < 2 then
                error("APT stack underflow", 0)
            end

            local v85 = t17[n2]
            local v86 = t17[n2 - 1]

            t17[n2] = nil
            n2 -= 1

            local t20

            if opcode == 71 then
                local v87 = v86.tag == "Text"
                local v88 = if not v87 then v85.tag == "Text" else nil

                if v87 or v88 then
                    t20 = {
                        tag = "Text"
                    }
                    t20[1] = text2(v86) .. text2(v85)
                else
                    t20 = {
                        tag = "Number"
                    }
                    t20[1] = number2(v86) + number2(v85)
                end
            elseif opcode == 11 then
                t20 = {
                    tag = "Number"
                }
                t20[1] = number2(v86) - number2(v85)
            elseif opcode == 12 then
                t20 = {
                    tag = "Number"
                }
                t20[1] = number2(v86) * number2(v85)
            elseif opcode == 13 then
                t20 = {
                    tag = "Number"
                }
                t20[1] = number2(v86) / number2(v85)
            else
                t20 = if opcode == 72 then if number2(v86) < number2(v85) then t3 else t4
                    elseif opcode == 103 then if number2(v86) > number2(v85) then t3 else t4
                    elseif opcode == 102 then if eq2(v86, v85) then t3 else t4
                    elseif eq2(v86, v85) or number2(v86) == number2(v85) then t3
                    else t4
            end

            t17[n2] = t20
        elseif opcode == 11
            or opcode == 12
            or opcode == 13
            or opcode == 72
            or opcode == 73
            or opcode == 102
            or opcode == 103 then
            if n2 < 2 then
                error("APT stack underflow", 0)
            end

            local v89 = t17[n2]
            local v90 = t17[n2 - 1]

            t17[n2] = nil
            n2 -= 1

            local v91

            if opcode == 71 then
                v91 = v90.tag

                if v91 == "Text" or v89.tag == "Text" then
                    v91 = {
                        tag = "Text"
                    }
                    v91[1] = text2(v90) .. text2(v89)
                else
                    v91 = {
                        tag = "Number"
                    }
                    v91[1] = number2(v90) + number2(v89)
                end
            elseif opcode == 11 then
                v91 = {
                    tag = "Number"
                }
                v91[1] = number2(v90) - number2(v89)
            elseif opcode == 12 then
                v91 = {
                    tag = "Number"
                }
                v91[1] = number2(v90) * number2(v89)
            elseif opcode == 13 then
                v91 = {
                    tag = "Number"
                }
                v91[1] = number2(v90) / number2(v89)
            else
                v91 = if opcode == 72 then if number2(v90) < number2(v89) then t3 else t4
                    elseif opcode == 103 then if number2(v90) > number2(v89) then t3 else t4
                    elseif opcode == 102 then if eq2(v90, v89) then t3 else t4
                    elseif eq2(v90, v89) or number2(v90) == number2(v89) then t3
                    else t4
            end

            t17[n2] = v91
        elseif opcode == 80 or opcode == 81 then
            if n2 == 0 then
                error("APT stack underflow", 0)
            end

            t17[n2] = {
                tag = "Number",
                number2(t17[n2]) + (opcode == 80 and 1 or -1)
            }
        elseif opcode == 153 or opcode == 157 or opcode == 184 then
            local v93 = opcode == 153
            local v94, v95

            if v93 then
                v94 = v93
                v95 = n2
            else
                if n2 == 0 then
                    error("APT stack underflow", 0)
                end

                v94 = truth2(t17[n2])
                t17[n2] = nil
                v95 = n2 - 1

                if opcode == 184 then
                    v94 = not v94
                end
            end

            if v94 then
                local target = v61.target

                if target == nil then
                    error("APT branch lacks target", 0)
                end

                local v96 = p55[#p55]

                if target == (v96 ~= nil and v96.next or 0) then
                    break
                end

                n3 = jump_table(p55)[target]

                if n3 == nil then
                    error(string.format("APT invalid jump target %x", target), 0)
                end
            end

            n2 = v95
        elseif opcode == 142 or opcode == 155 then
            local v97 = #p54.functions

            table.insert(p54.functions, {
                code = v61,
                constants = table.clone(p57)
            })

            local v99 = Vm.object(p54, {
                tag = "Function",
                v97
            })
            local v98 = Vm.object(p54, t5)

            Vm.set(p54, v99, "prototype", {
                tag = "Object",
                v98
            })
            v97 = v61.name

            if v97 == nil or #v97 == 0 then
                n2 += 1
                t17[n2] = {
                    tag = "Object",
                    v99
                }
            else
                Vm.set(p54, p54.global, v97, {
                    tag = "Object",
                    v99
                })
            end
        elseif opcode == 105 then
            if n2 < 2 then
                error("APT stack underflow", 0)
            end

            local v100 = t17[n2]
            local v101 = t17[n2 - 1]

            t17[n2] = nil
            t17[n2 - 1] = nil
            n2 -= 2

            if v101.tag == "Object" and v100.tag == "Object" then
                local v102 = Vm.get(p54, v101[1], "prototype")
                local v103 = Vm.get(p54, v100[1], "prototype")

                if v102.tag == "Object" and v103.tag == "Object" then
                    p54.objects[v102[1] + 1].prototype = v103[1]
                end
            end
        elseif opcode == 64 then
            if n2 < 2 then
                error("APT stack underflow", 0)
            end

            local v104 = text2(t17[n2])
            local v105 = rt.f_to_usize(number2(t17[n2 - 1]))

            t17[n2] = nil
            t17[n2 - 1] = nil
            n2 -= 2

            if v105 > 256 then
                error("APT argument limit", 0)
            end

            local v106 = table.create(v105)

            for i = 1, v105 do
                if n2 == 0 then
                    error("APT stack underflow", 0)
                end

                v106[i] = t17[n2]
                t17[n2] = nil
                n2 -= 1
            end

            local v107 = Vm.object(p54, t5)

            if v104 == "Array" then
                for v108, v109 in v106 do
                    Vm.set(p54, v107, string.format("%d", v108 - 1), v109)
                end

                Vm.set(p54, v107, "length", {
                    tag = "Number",
                    v105
                })
            else
                local v110 = Vm.get(p54, p54.global, v104)

                if v110.tag == "Object" then
                    local prototype = Vm.get(p54, v110[1], "prototype")

                    if prototype.tag == "Object" then
                        p54.objects[v107 + 1].prototype = prototype[1]
                    end

                    prototype = p54.objects[v110[1] + 1].kind

                    if prototype.tag == "Function" then
                        Vm.invoke(p54, prototype[1], v107, v106, p59)
                    end
                else
                    error(("APT constructor absent: %*"):format(v104), 0)
                end
            end

            n2 += 1
            t17[n2] = {
                tag = "Object",
                v107
            }
        elseif opcode ~= 82 and opcode ~= 176 and opcode ~= 177 and opcode ~= 178 and opcode ~= 179 and opcode ~= 61 and opcode ~= 93 then
            if opcode == 62 then
                if n2 == 0 then
                    return t2
                end

                return t17[n2]
            end

            error(string.format("Unsupported APT opcode %02x at %x", opcode, v61.offset), 0)
        else
            local v111

            if opcode ~= 176 and opcode ~= 177 and opcode ~= 178 and opcode ~= 179 then
                if n2 == 0 then
                    error("APT stack underflow", 0)
                end

                v111 = t17[n2]
                t17[n2] = nil
                n2 -= 1
            else
                v111 = p57[v62 + 1]

                if v111 == nil then
                    error(string.format("APT constant index %d at %x", v62, v61.offset), 0)
                end
            end

            local v112

            if opcode ~= 61 and opcode ~= 176 and opcode ~= 177 then
                if n2 == 0 then
                    error("APT stack underflow", 0)
                end

                v112 = t17[n2]
                t17[n2] = nil
                n2 -= 1
            else
                v112 = {
                    tag = "Object",
                    p54.global
                }
            end

            if n2 == 0 then
                error("APT stack underflow", 0)
            end

            local v113 = rt.f_to_usize(number2(t17[n2]))

            t17[n2] = nil
            n2 -= 1

            if v113 > 256 then
                error("APT argument limit", 0)
            end

            local v114 = table.create(v113)

            for i = 1, v113 do
                if n2 == 0 then
                    error("APT stack underflow", 0)
                end

                v114[i] = t17[n2]
                t17[n2] = nil
                n2 -= 1
            end

            local v115 = if v112.tag == "Object" then Vm.call_method(p54, v112[1], text2(v111), v114, p59) else t2

            if opcode == 177 or opcode == 179 then
                return v115
            end

            if opcode ~= 176 and opcode ~= 178 and opcode ~= 93 then
                n2 += 1
                t17[n2] = v115
            end
        end

        if n2 > 1024 then
            error("APT stack limit", 0)
        end
    end

    return t2
end

return t1
