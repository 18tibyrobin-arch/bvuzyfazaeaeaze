local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat
        task.wait()
        LocalPlayer = Players.LocalPlayer
    until LocalPlayer
end

local TAU = math.pi * 2
local kp = NumberSequenceKeypoint.new

local Aura = {}
Aura.Tracked = {}

Aura.Config = {
    Enabled = true,
    ThroughWalls = true,
    IncludeLocalPlayer = true,
    Intensity = 1,
    UseHighlight = true,
    UseOrbs = true,
    UseFlames = true,
    UseLight = true,
    UseWings = false,
    OrbCount = 3,
    OrbRadius = 2.3,
    OrbSpeed = 2.2,
    Tag = "RivalsAuraV5",
    Textures = {
        Fire = "rbxasset://textures/particles/fire_main.dds",
    },
    Colors = {
        Me = {
            Main = Color3.fromRGB(255, 255, 255),
            Bright = Color3.fromRGB(255, 255, 245),
            Dark = Color3.fromRGB(170, 185, 205),
        },
        Ally = {
            Main = Color3.fromRGB(0, 255, 120),
            Bright = Color3.fromRGB(190, 255, 220),
            Dark = Color3.fromRGB(0, 60, 25),
        },
        Enemy = {
            Main = Color3.fromRGB(170, 40, 255),
            Bright = Color3.fromRGB(235, 190, 255),
            Dark = Color3.fromRGB(45, 0, 85),
        },
    },
}

local function findPart(parent: Instance, name: string): BasePart?
    local inst = parent:FindFirstChild(name)
    if inst and inst:IsA("BasePart") then
        return inst
    end
    return nil
end

local function getLimb(character: Model, limbName: string): BasePart?
    if limbName == "Torso" then
        return findPart(character, "UpperTorso") or findPart(character, "Torso")
    elseif limbName == "HumanoidRootPart" then
        return findPart(character, "HumanoidRootPart")
    elseif limbName == "Head" then
        return findPart(character, "Head")
    elseif limbName == "Left Arm" then
        return findPart(character, "LeftUpperArm") or findPart(character, "Left Arm")
    elseif limbName == "Right Arm" then
        return findPart(character, "RightUpperArm") or findPart(character, "Right Arm")
    elseif limbName == "Left Leg" then
        return findPart(character, "LeftUpperLeg") or findPart(character, "Left Leg")
    elseif limbName == "Right Leg" then
        return findPart(character, "RightUpperLeg") or findPart(character, "Right Leg")
    end
    return findPart(character, limbName)
end

local function tagInstance(inst: Instance): Instance
    inst:SetAttribute(Aura.Config.Tag, true)
    return inst
end

local function buildAttachment(name: string, parent: Instance, offset: Vector3?): Attachment
    local att = Instance.new("Attachment")
    att.Name = name
    if offset then
        att.Position = offset
    end
    tagInstance(att)
    att.Parent = parent
    return att
end

local function buildEmitter(props: {[string]: any}, parent: Instance): ParticleEmitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.LockedToPart = true
    emitter.VelocityInheritance = 0
    emitter.LightInfluence = 0
    for key, val in pairs(props) do
        emitter[key] = val
    end
    tagInstance(emitter)
    emitter.Parent = parent
    return emitter
end

local function buildCosmeticPart(name: string, size: Vector3, color: Color3, transparency: number, parent: Instance): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Transparency = transparency
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Massless = true
    p.CastShadow = false
    p.Anchored = false
    tagInstance(p)
    p.Parent = parent
    return p
end

local function weldTo(part0: BasePart, part1: Part, c0: CFrame): Weld
    local w = Instance.new("Weld")
    w.Part0 = part0
    w.Part1 = part1
    w.C0 = c0
    tagInstance(w)
    w.Parent = part1
    return w
end

local function buildWing(character: Model, anchor: BasePart, side: number): Weld
    local wingRoot = buildCosmeticPart("RA_WingRoot", Vector3.new(0.2, 0.2, 0.2), Color3.new(1, 1, 1), 1, character)
    local rootWeld = weldTo(anchor, wingRoot, CFrame.new(0.35 * side, 0.55, 0.62))

    local feathers = {
        { 14, 2.0, 0.42 },
        { 36, 2.5, 0.50 },
        { 58, 2.8, 0.55 },
        { 80, 2.5, 0.50 },
        { 100, 2.0, 0.42 },
    }

    for i, f in ipairs(feathers) do
        local ang, len, width = f[1], f[2], f[3]
        local feather = buildCosmeticPart(
            "RA_Feather",
            Vector3.new(0.14, len, width),
            Color3.new(1, 1, 1),
            0.05,
            character
        )
        local fw = Instance.new("Weld")
        fw.Part0 = wingRoot
        fw.Part1 = feather
        fw.C0 = CFrame.new(0, 0, 0.035 * i)
            * CFrame.Angles(0, 0, math.rad(ang) * -side)
            * CFrame.new(0, len / 2, 0)
        tagInstance(fw)
        fw.Parent = feather
    end

    return rootWeld
end

function Aura.Remove(character: Model?)
    if not character then return end
    Aura.Tracked[character] = nil
    for _, item in ipairs(character:GetDescendants()) do
        if item:GetAttribute(Aura.Config.Tag) == true then
            item:Destroy()
        end
    end
end

function Aura.UpdateHighlightDepth()
    local depth = Aura.Config.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    for _, data in pairs(Aura.Tracked) do
        if data.highlight and data.highlight.Parent then
            data.highlight.DepthMode = depth
        end
    end
end

function Aura.Apply(character: Model, isAllyTeam: boolean)
    local cfg = Aura.Config
    if not cfg.Enabled or not character or not character.Parent then
        return
    end

    local isLocalChar = (character == LocalPlayer.Character)
    if isLocalChar and not cfg.IncludeLocalPlayer then
        Aura.Remove(character)
        return
    end

    Aura.Remove(character)

    local scheme
    if isLocalChar then
        scheme = cfg.Colors.Me
    elseif isAllyTeam then
        scheme = cfg.Colors.Ally
    else
        scheme = cfg.Colors.Enemy
    end

    local mul = cfg.Intensity
    local zOff = isLocalChar and -1 or 0
    local tex = cfg.Textures

    local torso = getLimb(character, "Torso")
    local root = getLimb(character, "HumanoidRootPart")
    local anchor = torso or root
    if not anchor or not root then return end

    local data = {
        isAlly = isAllyTeam,
        isLocal = isLocalChar,
        phase = math.random() * TAU,
        root = root,
        orbs = {},
        orbTrails = {},
        smoothPos = nil,
        wingWelds = nil,
    }

    if cfg.UseHighlight then
        local hl = Instance.new("Highlight")
        hl.Name = "RA_Highlight"
        hl.Adornee = character
        hl.DepthMode = cfg.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        hl.FillColor = scheme.Main
        hl.FillTransparency = 0.75
        hl.OutlineColor = scheme.Bright
        hl.OutlineTransparency = 0.1
        tagInstance(hl)
        hl.Parent = character
        data.highlight = hl
    end

    if cfg.UseOrbs then
        for i = 1, cfg.OrbCount do
            local orb = buildCosmeticPart("RA_Orb" .. i, Vector3.new(0.65, 0.65, 0.65), scheme.Bright, 0, character)
            orb.Anchored = true
            local orbMesh = Instance.new("SpecialMesh")
            orbMesh.MeshType = Enum.MeshType.Sphere
            tagInstance(orbMesh)
            orbMesh.Parent = orb

            local orbAtt = buildAttachment("RA_OrbGlow", orb)
            buildEmitter({
                Name = "RA_OrbFire",
                Texture = tex.Fire,
                Rate = 4 * mul,
                Lifetime = NumberRange.new(0.25, 0.3),
                Speed = NumberRange.new(0, 0),
                LightEmission = 1,
                Brightness = 1.6,
                Orientation = Enum.ParticleOrientation.FacingCamera,
                Size = NumberSequence.new({ kp(0, 1.2), kp(1, 0.4) }),
                Transparency = NumberSequence.new({ kp(0, 0.5), kp(1, 1) }),
                Color = ColorSequence.new(scheme.Bright, scheme.Main),
            }, orbAtt)

            local ta0 = buildAttachment("RA_OrbT0", orb, Vector3.new(0, 0.3, 0))
            local ta1 = buildAttachment("RA_OrbT1", orb, Vector3.new(0, -0.3, 0))
            local orbTrail = Instance.new("Trail")
            orbTrail.Name = "RA_OrbTrail"
            orbTrail.Attachment0 = ta0
            orbTrail.Attachment1 = ta1
            orbTrail.Lifetime = 0.5
            orbTrail.MaxLength = 14
            orbTrail.MinLength = 0.02
            orbTrail.FaceCamera = true
            orbTrail.LightEmission = 1
            orbTrail.LightInfluence = 0
            orbTrail.Brightness = 2
            orbTrail.WidthScale = NumberSequence.new({ kp(0, 1.1), kp(0.5, 0.6), kp(1, 0.1) })
            orbTrail.Color = ColorSequence.new(scheme.Bright, scheme.Main)
            orbTrail.Transparency = NumberSequence.new({ kp(0, 0.12), kp(0.6, 0.55), kp(1, 1) })
            tagInstance(orbTrail)
            orbTrail.Parent = orb

            table.insert(data.orbTrails, orbTrail)
            table.insert(data.orbs, orb)
        end
    end

    if isLocalChar and cfg.UseWings then
        data.wingWelds = {
            buildWing(character, anchor, -1),
            buildWing(character, anchor, 1),
        }
    end

    if cfg.UseFlames then
        local coreAtt = buildAttachment("RA_Core", anchor)

        buildEmitter({
            Name = "RA_CoreFire",
            Texture = tex.Fire,
            Rate = 26 * mul,
            Lifetime = NumberRange.new(0.5, 0.65),
            Speed = NumberRange.new(2.5, 3.5),
            SpreadAngle = Vector2.new(9, 9),
            Acceleration = Vector3.new(0, 6, 0),
            LightEmission = 1,
            Brightness = 2,
            ZOffset = zOff,
            EmissionDirection = Enum.NormalId.Top,
            Orientation = Enum.ParticleOrientation.FacingCamera,
            Rotation = NumberRange.new(-20, 20),
            RotSpeed = NumberRange.new(-30, 30),
            Size = NumberSequence.new({ kp(0, 2.6), kp(0.5, 2.0), kp(1, 0.6) }),
            Transparency = NumberSequence.new({ kp(0, 0.45), kp(0.35, 0.1), kp(0.75, 0.5), kp(1, 1) }),
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, scheme.Bright),
                ColorSequenceKeypoint.new(0.45, scheme.Main),
                ColorSequenceKeypoint.new(1, scheme.Main),
            }),
        }, coreAtt)

        buildEmitter({
            Name = "RA_CoreFireInner",
            Texture = tex.Fire,
            Rate = 12 * mul,
            Lifetime = NumberRange.new(0.3, 0.4),
            Speed = NumberRange.new(4, 5),
            SpreadAngle = Vector2.new(4, 4),
            Acceleration = Vector3.new(0, 8, 0),
            LightEmission = 1,
            Brightness = 2.4,
            ZOffset = zOff + 0.1,
            EmissionDirection = Enum.NormalId.Top,
            Orientation = Enum.ParticleOrientation.FacingCamera,
            Rotation = NumberRange.new(-15, 15),
            RotSpeed = NumberRange.new(-20, 20),
            Size = NumberSequence.new({ kp(0, 1.2), kp(0.6, 0.8), kp(1, 0.2) }),
            Transparency = NumberSequence.new({ kp(0, 0.3), kp(0.5, 0.15), kp(1, 1) }),
            Color = ColorSequence.new(scheme.Bright, scheme.Main),
        }, coreAtt)

        for _, armName in ipairs({ "Left Arm", "Right Arm" }) do
            local arm = getLimb(character, armName)
            if arm then
                local fistAtt = buildAttachment("RA_Fist", arm, Vector3.new(0, -arm.Size.Y * 0.4, 0))
                buildEmitter({
                    Name = "RA_FistFire",
                    Texture = tex.Fire,
                    Rate = 11 * mul,
                    Lifetime = NumberRange.new(0.3, 0.4),
                    Speed = NumberRange.new(1, 1.5),
                    SpreadAngle = Vector2.new(8, 8),
                    Acceleration = Vector3.new(0, 4, 0),
                    LightEmission = 1,
                    Brightness = 2,
                    ZOffset = zOff,
                    EmissionDirection = Enum.NormalId.Top,
                    Orientation = Enum.ParticleOrientation.FacingCamera,
                    Size = NumberSequence.new({ kp(0, 1.05), kp(1, 0.3) }),
                    Transparency = NumberSequence.new({ kp(0, 0.4), kp(0.4, 0.2), kp(1, 1) }),
                    Color = ColorSequence.new(scheme.Bright, scheme.Main),
                }, fistAtt)
            end
        end
    end

    if cfg.UseLight then
        local lightAtt = buildAttachment("RA_LightAtt", anchor)
        local light = Instance.new("PointLight")
        light.Name = "RA_Light"
        light.Color = scheme.Main
        light.Brightness = 1.5
        light.Range = 12
        light.Shadows = false
        tagInstance(light)
        light.Parent = lightAtt
        data.light = light
    end

    Aura.Tracked[character] = data
end

function Aura.Step(t: number, dt: number)
    local cfg = Aura.Config
    for model, data in pairs(Aura.Tracked) do
        if not model.Parent then
            Aura.Tracked[model] = nil
        else
            local phase = data.phase
            local pulse = 0.5 + 0.5 * math.sin(t * 2.2 + phase)

            if data.highlight and data.highlight.Parent then
                data.highlight.FillTransparency = 0.76 + 0.1 * pulse
                data.highlight.OutlineTransparency = 0.12 + 0.2 * pulse
            end
            if data.light and data.light.Parent then
                data.light.Brightness = 1 + 0.9 * pulse
            end

            local rootPart = data.root
            if rootPart and rootPart.Parent and #data.orbs > 0 then
                local rootPos = rootPart.Position
                local k = 14
                local alpha = 1 - math.exp(-dt * k)
                local velVec = rootPart.AssemblyLinearVelocity
                local target = rootPos + velVec * (1 / k)
                if data.smoothPos == nil or (rootPos - data.smoothPos).Magnitude > 15 then
                    data.smoothPos = rootPos
                else
                    data.smoothPos = data.smoothPos:Lerp(target, alpha)
                end
                local basePos = data.smoothPos

                local vel = velVec.Magnitude
                local targetLife = math.clamp(0.5 * 18 / (18 + vel), 0.15, 0.5)
                for _, tr in ipairs(data.orbTrails) do
                    if tr.Parent then
                        tr.Lifetime = tr.Lifetime + (targetLife - tr.Lifetime) * alpha
                    end
                end

                local n = #data.orbs
                for i, orb in ipairs(data.orbs) do
                    if orb.Parent then
                        local ang = t * cfg.OrbSpeed + phase + (i - 1) * (TAU / n)
                        orb.CFrame = CFrame.new(basePos)
                            * CFrame.Angles(0, ang, 0)
                            * CFrame.new(cfg.OrbRadius, math.sin(t * 1.8 + i * 2.1) * 0.6, 0)
                    end
                end
            end

            if data.wingWelds then
                local flap = math.sin(t * 2.6)
                local yaw = math.rad(28) + math.rad(20) * flap
                local lift = math.rad(8) * flap
                local wl, wr = data.wingWelds[1], data.wingWelds[2]
                if wl and wl.Parent then
                    wl.C0 = CFrame.new(-0.35, 0.55 + 0.06 * flap, 0.62)
                        * CFrame.Angles(0, yaw, math.rad(12) + lift)
                end
                if wr and wr.Parent then
                    wr.C0 = CFrame.new(0.35, 0.55 + 0.06 * flap, 0.62)
                        * CFrame.Angles(0, -yaw, -(math.rad(12) + lift))
                end
            end
        end
    end
end

return Aura
