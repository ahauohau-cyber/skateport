-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local Collections = require(sim.import)("skate_data/collections").Collections

return {
    load = function(p1) -- load | line: 16
        -- upvalues: Collections (copy)
        local function scalar(p2) -- line: 17
            -- upvalues: p1 (copy), Collections (copy)
            return Collections.float(p1, "physics_skeleton_drives", "default", p2)
        end

        local function animation(p3) -- line: 21
            -- upvalues: p1 (copy), Collections (copy)
            local function f(p4) -- line: 22
                -- upvalues: p3 (copy), p1 (copy), Collections (copy)
                return Collections.float(p1, "animation_drives", p3, p4)
            end

            return {
                linear_strength = Collections.float(p1, "animation_drives", p3, "LinearStrMin"),
                linear_displacement = Collections.float(p1, "animation_drives", p3, "LinearDispMin"),
                angular_strength = Collections.float(p1, "animation_drives", p3, "AngularStrMin"),
                angular_displacement = Collections.float(p1, "animation_drives", p3, "AngularDispMin")
            }
        end

        local v1 = animation("local")
        local root = animation("root")
        local CollisionSoftDisp = Collections.float(p1, "physics_skeleton_drives", "default", "CollisionSoftDisp")
        local CollisionSoftStrength = Collections.float(p1, "physics_skeleton_drives", "default", "CollisionSoftStrength")
        local RagdollSoftDisp = Collections.float(p1, "physics_skeleton_drives", "default", "RagdollSoftDisp")
        local RagdollSoftStrength = Collections.float(p1, "physics_skeleton_drives", "default", "RagdollSoftStrength")
        local Hash_138976EAF99DF926 = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_138976EAF99DF926")
        local Hash_C313093118C7A83F = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_C313093118C7A83F")
        local Hash_1E6BDF62043784FC = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_1E6BDF62043784FC")
        local Hash_BD3E4F132848A588 = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_BD3E4F132848A588")
        local Hash_D7652B4B19BB4747 = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_D7652B4B19BB4747")
        local Hash_C4B564DFD233CF04 = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_C4B564DFD233CF04")
        local Hash_14A2DDDD0A35C267 = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_14A2DDDD0A35C267")
        local Hash_24D5AA7F214A901C = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_24D5AA7F214A901C")
        local Hash_6C6CCD16A0A438AD = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_6C6CCD16A0A438AD")
        local Hash_7379F8AB250BF611 = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_7379F8AB250BF611")
        local Hash_28446A9E25DCC04C = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_28446A9E25DCC04C")
        local Hash_B59D493B3DB372C8 = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_B59D493B3DB372C8")
        local Hash_E1B89BB09D725EEC = Collections.float(p1, "physics_skeleton_drives", "default", "Hash_E1B89BB09D725EEC")

        return {
            animation = { v1, root },
            collision_soft_displacement = CollisionSoftDisp,
            collision_soft_strength = CollisionSoftStrength,
            ragdoll_soft_displacement = RagdollSoftDisp,
            ragdoll_soft_strength = RagdollSoftStrength,
            transition_linear = {
                spring = { Hash_138976EAF99DF926, Hash_C313093118C7A83F },
                strength = { Hash_1E6BDF62043784FC, Hash_BD3E4F132848A588 },
                damping = { Hash_D7652B4B19BB4747, Hash_C4B564DFD233CF04 }
            },
            transition_angular = {
                spring = { Hash_14A2DDDD0A35C267, Hash_24D5AA7F214A901C },
                strength = { Hash_6C6CCD16A0A438AD, Hash_7379F8AB250BF611 },
                damping = { Hash_28446A9E25DCC04C, Hash_B59D493B3DB372C8 }
            },
            transition_calls = Hash_E1B89BB09D725EEC
        }
    end
}
