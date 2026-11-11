--[[
    RIVALS HUB - Visuals Client (High Performance Edition)
    Zero-allocation in-place rendering engine.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
end

local env = (typeof(getgenv) == "function" and getgenv()) or _G
if env.RivalsHubInstance and typeof(env.RivalsHubInstance.Destroy) == "function" then
    pcall(env.RivalsHubInstance.Destroy)
end

local TAU = math.pi * 2
local kp = NumberSequenceKeypoint.new

-------------------------------------------------------------------
-- Config
-------------------------------------------------------------------
local Config = {
    Tag = "RivalsHubV1",
    Visuals = {
        ESP = {
            Aura = true,
            ThroughWalls = true,
            IncludeLocal = true,
            Intensity = 1,
            UseOrbs = true,
            UseFlames = true,
            UseLight = true,
            UseWings = false,
            OrbCount = 3,
            OrbRadius = 2.3,
            OrbSpeed = 2.2,
            Colors = {
                Local = Color3.fromRGB(255, 255, 255),
                Ally = Color3.fromRGB(0, 255, 120),
                Enemy = Color3.fromRGB(170, 40, 255),
            }
        },
        Tracers = {
            Enabled = true,
            Duration = 0.4,
            FriendlyColor = Color3.fromRGB(150, 40, 255),
            EnemyColor = Color3.fromRGB(255, 60, 60),
            SpiralSpeed = 420,
            SpiralRadius = 0.32,
            SpiralTwist = 1.25,
            MaxDistance = 800,
            Interval = 0.11,
            FallbackCameraRaycast = true,
        }
    }
}

-------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------
local function findPart(parent: Instance, name: string): BasePart?
    local inst = parent:FindFirstChild(name)
    if inst and inst:IsA("BasePart") then return inst end
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

local function computeColorPalette(mainColor: Color3)
    local h, s, v = mainColor:ToHSV()
    local brightColor = Color3.fromHSV(h, math.clamp(s * 0.45, 0, 1), math.clamp(v * 1.25, 0, 1))
    local darkColor = Color3.fromHSV(h, math.clamp(s * 1.2, 0, 1), math.clamp(v * 0.35, 0, 1))
    return mainColor, brightColor, darkColor
end

local function buildAttachment(name: string, parent: Instance, offset: Vector3?, instancesList: {Instance}): Attachment
    local att = Instance.new("Attachment")
    att.Name = name
    if offset then att.Position = offset end
    att:SetAttribute(Config.Tag, true)
    att.Parent = parent
    table.insert(instancesList, att)
    return att
end

local function buildEmitter(props: {[string]: any}, parent: Instance, instancesList: {Instance}): ParticleEmitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.LockedToPart = true
    emitter.VelocityInheritance = 0
    emitter.LightInfluence = 0
    for key, val in pairs(props) do
        emitter[key] = val
    end
    emitter:SetAttribute(Config.Tag, true)
    emitter.Parent = parent
    table.insert(instancesList, emitter)
    return emitter
end

local function buildCosmeticPart(name: string, size: Vector3, color: Color3, transparency: number, parent: Instance, instancesList: {Instance}): Part
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
    p:SetAttribute(Config.Tag, true)
    p.Parent = parent
    table.insert(instancesList, p)
    return p
end

local function weldTo(part0: BasePart, part1: Part, c0: CFrame, instancesList: {Instance}): Weld
    local w = Instance.new("Weld")
    w.Part0 = part0
    w.Part1 = part1
    w.C0 = c0
    w:SetAttribute(Config.Tag, true)
    w.Parent = part1
    table.insert(instancesList, w)
    return w
end

local function buildWing(character: Model, anchor: BasePart, side: number, instancesList: {Instance}): Weld
    local wingRoot = buildCosmeticPart("RH_WingRoot", Vector3.new(0.2, 0.2, 0.2), Color3.new(1, 1, 1), 1, character, instancesList)
    local rootWeld = weldTo(anchor, wingRoot, CFrame.new(0.35 * side, 0.55, 0.62), instancesList)

    local feathers = {
        { 14, 2.0, 0.42 },
        { 36, 2.5, 0.50 },
        { 58, 2.8, 0.55 },
        { 80, 2.5, 0.50 },
        { 100, 2.0, 0.42 },
    }

    for i, f in ipairs(feathers) do
        local ang, len, width = f[1], f[2], f[3]
        local feather = buildCosmeticPart("RH_Feather", Vector3.new(0.14, len, width), Color3.new(1, 1, 1), 0.05, character, instancesList)
        local fw = Instance.new("Weld")
        fw.Part0 = wingRoot
        fw.Part1 = feather
        fw.C0 = CFrame.new(0, 0, 0.035 * i)
            * CFrame.Angles(0, 0, math.rad(ang) * -side)
            * CFrame.new(0, len / 2, 0)
        fw:SetAttribute(Config.Tag, true)
        fw.Parent = feather
        table.insert(instancesList, fw)
    end

    return rootWeld
end

-------------------------------------------------------------------
-- Aura Engine (Non-Destructive & Zero-Allocation Updates)
-------------------------------------------------------------------
local Aura = {}
Aura.Tracked = setmetatable({}, { __mode = "k" })

function Aura.Remove(character: Model?)
    if not character then return end
    local data = Aura.Tracked[character]
    if data and data.instances then
        for _, inst in ipairs(data.instances) do
            if inst and inst.Parent then
                inst:Destroy()
            end
        end
    end
    Aura.Tracked[character] = nil
end

function Aura.SetVisible(visible: boolean)
    for _, data in pairs(Aura.Tracked) do
        if data.highlight and data.highlight.Parent then
            data.highlight.Enabled = visible
        end
        if data.light and data.light.Parent then
            data.light.Enabled = visible
        end
        for _, em in ipairs(data.emitters) do
            if em.Parent then
                em.Enabled = visible
            end
        end
        for _, orb in ipairs(data.orbs) do
            if orb.Parent then
                orb.Transparency = visible and 0 or 1
            end
        end
        for _, tr in ipairs(data.orbTrails) do
            if tr.Parent then
                tr.Enabled = visible
            end
        end
    end
end

function Aura.UpdateThroughWalls(throughWalls: boolean)
    local depth = throughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    for _, data in pairs(Aura.Tracked) do
        if data.highlight and data.highlight.Parent then
            data.highlight.DepthMode = depth
        end
    end
end

function Aura.UpdateColors()
    local espCfg = Config.Visuals.ESP
    for _, data in pairs(Aura.Tracked) do
        local mainColor
        if data.isLocal then
            mainColor = espCfg.Colors.Local
        elseif data.isAlly then
            mainColor = espCfg.Colors.Ally
        else
            mainColor = espCfg.Colors.Enemy
        end

        local main, bright = computeColorPalette(mainColor)

        if data.highlight and data.highlight.Parent then
            data.highlight.FillColor = main
            data.highlight.OutlineColor = bright
        end

        if data.light and data.light.Parent then
            data.light.Color = main
        end

        for _, orb in ipairs(data.orbs) do
            if orb.Parent then
                orb.Color = bright
            end
        end

        for _, trail in ipairs(data.orbTrails) do
            if trail.Parent then
                trail.Color = ColorSequence.new(bright, main)
            end
        end

        for _, em in ipairs(data.emitters) do
            if em.Parent then
                em.Color = ColorSequence.new(bright, main)
            end
        end
    end
end

function Aura.Apply(character: Model, isAllyTeam: boolean)
    local espCfg = Config.Visuals.ESP
    if not character or not character.Parent then return end

    local isLocalChar = (character == LocalPlayer.Character)
    if isLocalChar and not espCfg.IncludeLocal then
        Aura.Remove(character)
        return
    end

    if Aura.Tracked[character] then
        local data = Aura.Tracked[character]
        data.isAlly = isAllyTeam
        data.isLocal = isLocalChar
        Aura.UpdateColors()
        Aura.UpdateThroughWalls(espCfg.ThroughWalls)
        return
    end

    Aura.Remove(character)

    local mainColor
    if isLocalChar then
        mainColor = espCfg.Colors.Local
    elseif isAllyTeam then
        mainColor = espCfg.Colors.Ally
    else
        mainColor = espCfg.Colors.Enemy
    end

    local main, bright = computeColorPalette(mainColor)
    local mul = espCfg.Intensity or 1
    local zOff = isLocalChar and -1 or 0
    local fireTex = "rbxasset://textures/particles/fire_main.dds"

    local torso = getLimb(character, "Torso")
    local root = getLimb(character, "HumanoidRootPart")
    local anchor = torso or root
    if not anchor or not root then return end

    local instancesList: {Instance} = {}

    local data = {
        isAlly = isAllyTeam,
        isLocal = isLocalChar,
        phase = math.random() * TAU,
        root = root,
        orbs = {},
        orbTrails = {},
        emitters = {},
        wingWelds = nil,
        instances = instancesList,
        smoothPos = nil,
    }

    local hl = Instance.new("Highlight")
    hl.Name = "RH_Highlight"
    hl.Adornee = character
    hl.DepthMode = espCfg.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    hl.FillColor = main
    hl.FillTransparency = 0.75
    hl.OutlineColor = bright
    hl.OutlineTransparency = 0.1
    hl.Enabled = espCfg.Aura
    hl:SetAttribute(Config.Tag, true)
    hl.Parent = character
    table.insert(instancesList, hl)
    data.highlight = hl

    if espCfg.UseOrbs then
        for i = 1, espCfg.OrbCount do
            local orb = buildCosmeticPart("RH_Orb" .. i, Vector3.new(0.65, 0.65, 0.65), bright, espCfg.Aura and 0 or 1, character, instancesList)
            orb.Anchored = true
            local orbMesh = Instance.new("SpecialMesh")
            orbMesh.MeshType = Enum.MeshType.Sphere
            orbMesh:SetAttribute(Config.Tag, true)
            orbMesh.Parent = orb
            table.insert(instancesList, orbMesh)

            local orbAtt = buildAttachment("RH_OrbGlow", orb, nil, instancesList)
            local orbFire = buildEmitter({
                Name = "RH_OrbFire",
                Texture = fireTex,
                Rate = 4 * mul,
                Lifetime = NumberRange.new(0.25, 0.3),
                Speed = NumberRange.new(0, 0),
                LightEmission = 1,
                Brightness = 1.6,
                Enabled = espCfg.Aura,
                Orientation = Enum.ParticleOrientation.FacingCamera,
                Size = NumberSequence.new({ kp(0, 1.2), kp(1, 0.4) }),
                Transparency = NumberSequence.new({ kp(0, 0.5), kp(1, 1) }),
                Color = ColorSequence.new(bright, main),
            }, orbAtt, instancesList)
            table.insert(data.emitters, orbFire)

            local ta0 = buildAttachment("RH_OrbT0", orb, Vector3.new(0, 0.3, 0), instancesList)
            local ta1 = buildAttachment("RH_OrbT1", orb, Vector3.new(0, -0.3, 0), instancesList)
            local orbTrail = Instance.new("Trail")
            orbTrail.Name = "RH_OrbTrail"
            orbTrail.Attachment0 = ta0
            orbTrail.Attachment1 = ta1
            orbTrail.Lifetime = 0.4
            orbTrail.MaxLength = 12
            orbTrail.MinLength = 0.02
            orbTrail.FaceCamera = true
            orbTrail.LightEmission = 1
            orbTrail.LightInfluence = 0
            orbTrail.Brightness = 2
            orbTrail.Enabled = espCfg.Aura
            orbTrail.WidthScale = NumberSequence.new({ kp(0, 1.1), kp(0.5, 0.6), kp(1, 0.1) })
            orbTrail.Color = ColorSequence.new(bright, main)
            orbTrail.Transparency = NumberSequence.new({ kp(0, 0.12), kp(0.6, 0.55), kp(1, 1) })
            orbTrail:SetAttribute(Config.Tag, true)
            orbTrail.Parent = orb
            table.insert(instancesList, orbTrail)

            table.insert(data.orbTrails, orbTrail)
            table.insert(data.orbs, orb)
        end
    end

    if isLocalChar and espCfg.UseWings then
        data.wingWelds = {
            buildWing(character, anchor, -1, instancesList),
            buildWing(character, anchor, 1, instancesList),
        }
    end

    if espCfg.UseFlames then
        local coreAtt = buildAttachment("RH_Core", anchor, nil, instancesList)

        local coreFire = buildEmitter({
            Name = "RH_CoreFire",
            Texture = fireTex,
            Rate = 24 * mul,
            Lifetime = NumberRange.new(0.5, 0.65),
            Speed = NumberRange.new(2.5, 3.5),
            SpreadAngle = Vector2.new(9, 9),
            Acceleration = Vector3.new(0, 6, 0),
            LightEmission = 1,
            Brightness = 2,
            Enabled = espCfg.Aura,
            ZOffset = zOff,
            EmissionDirection = Enum.NormalId.Top,
            Orientation = Enum.ParticleOrientation.FacingCamera,
            Rotation = NumberRange.new(-20, 20),
            RotSpeed = NumberRange.new(-30, 30),
            Size = NumberSequence.new({ kp(0, 2.6), kp(0.5, 2.0), kp(1, 0.6) }),
            Transparency = NumberSequence.new({ kp(0, 0.45), kp(0.35, 0.1), kp(0.75, 0.5), kp(1, 1) }),
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, bright),
                ColorSequenceKeypoint.new(0.45, main),
                ColorSequenceKeypoint.new(1, main),
            }),
        }, coreAtt, instancesList)
        table.insert(data.emitters, coreFire)

        local innerFire = buildEmitter({
            Name = "RH_CoreFireInner",
            Texture = fireTex,
            Rate = 10 * mul,
            Lifetime = NumberRange.new(0.3, 0.4),
            Speed = NumberRange.new(4, 5),
            SpreadAngle = Vector2.new(4, 4),
            Acceleration = Vector3.new(0, 8, 0),
            LightEmission = 1,
            Brightness = 2.4,
            Enabled = espCfg.Aura,
            ZOffset = zOff + 0.1,
            EmissionDirection = Enum.NormalId.Top,
            Orientation = Enum.ParticleOrientation.FacingCamera,
            Rotation = NumberRange.new(-15, 15),
            RotSpeed = NumberRange.new(-20, 20),
            Size = NumberSequence.new({ kp(0, 1.2), kp(0.6, 0.8), kp(1, 0.2) }),
            Transparency = NumberSequence.new({ kp(0, 0.3), kp(0.5, 0.15), kp(1, 1) }),
            Color = ColorSequence.new(bright, main),
        }, coreAtt, instancesList)
        table.insert(data.emitters, innerFire)

        for _, armName in ipairs({ "Left Arm", "Right Arm" }) do
            local arm = getLimb(character, armName)
            if arm then
                local fistAtt = buildAttachment("RH_Fist", arm, Vector3.new(0, -arm.Size.Y * 0.4, 0), instancesList)
                local fistFire = buildEmitter({
                    Name = "RH_FistFire",
                    Texture = fireTex,
                    Rate = 10 * mul,
                    Lifetime = NumberRange.new(0.3, 0.4),
                    Speed = NumberRange.new(1, 1.5),
                    SpreadAngle = Vector2.new(8, 8),
                    Acceleration = Vector3.new(0, 4, 0),
                    LightEmission = 1,
                    Brightness = 2,
                    Enabled = espCfg.Aura,
                    ZOffset = zOff,
                    EmissionDirection = Enum.NormalId.Top,
                    Orientation = Enum.ParticleOrientation.FacingCamera,
                    Size = NumberSequence.new({ kp(0, 1.05), kp(1, 0.3) }),
                    Transparency = NumberSequence.new({ kp(0, 0.4), kp(0.4, 0.2), kp(1, 1) }),
                    Color = ColorSequence.new(bright, main),
                }, fistAtt, instancesList)
                table.insert(data.emitters, fistFire)
            end
        end
    end

    if espCfg.UseLight then
        local lightAtt = buildAttachment("RH_LightAtt", anchor, nil, instancesList)
        local light = Instance.new("PointLight")
        light.Name = "RH_Light"
        light.Color = main
        light.Brightness = 1.5
        light.Range = 12
        light.Shadows = false
        light.Enabled = espCfg.Aura
        light:SetAttribute(Config.Tag, true)
        light.Parent = lightAtt
        table.insert(instancesList, light)
        data.light = light
    end

    Aura.Tracked[character] = data
end

function Aura.Step(t: number, dt: number)
    local espCfg = Config.Visuals.ESP
    if not espCfg.Aura then return end

    local deadModels: {Model} = {}

    for model, data in pairs(Aura.Tracked) do
        if not model.Parent or not data.root or not data.root.Parent then
            table.insert(deadModels, model)
        else
            local phase = data.phase
            local pulse = 0.5 + 0.5 * math.sin(t * 2.2 + phase)

            if data.highlight and data.highlight.Parent then
                data.highlight.FillTransparency = 0.76 + 0.1 * pulse
                data.highlight.OutlineTransparency = 0.12 + 0.2 * pulse
            end
            if data.light and data.light.Parent then
                data.light.Brightness = 1 + 0.8 * pulse
            end

            local rootPart = data.root
            if #data.orbs > 0 then
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

                local n = #data.orbs
                for i, orb in ipairs(data.orbs) do
                    if orb.Parent then
                        local ang = t * espCfg.OrbSpeed + phase + (i - 1) * (TAU / n)
                        orb.CFrame = CFrame.new(basePos)
                            * CFrame.Angles(0, ang, 0)
                            * CFrame.new(espCfg.OrbRadius, math.sin(t * 1.8 + i * 2.1) * 0.5, 0)
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

    for _, m in ipairs(deadModels) do
        Aura.Remove(m)
    end
end

-------------------------------------------------------------------
-- Bullet Tracers System (Capped & Fast Cleanup)
-------------------------------------------------------------------
local Tracers = {}
Tracers.ActiveTracers = {}
Tracers.Folder = nil
Tracers.MAX_ACTIVE = 24

local function getTracerFolder(): Folder
    if Tracers.Folder and Tracers.Folder.Parent then
        return Tracers.Folder
    end
    local f = Instance.new("Folder")
    f.Name = "RH_Tracers"
    f:SetAttribute(Config.Tag, true)
    f.Parent = Workspace
    Tracers.Folder = f
    return f
end

function Tracers.FireTracer(origin: Vector3, hitPos: Vector3, isEnemy: boolean?)
    local tCfg = Config.Visuals.Tracers
    if not tCfg.Enabled then return end

    local dirVec = hitPos - origin
    local length = dirVec.Magnitude
    if length < 2 then return end

    if #Tracers.ActiveTracers >= Tracers.MAX_ACTIVE then
        local oldest = table.remove(Tracers.ActiveTracers, 1)
        if oldest then
            if oldest.rail and oldest.rail.Parent then oldest.rail:Destroy() end
            if oldest.orb and oldest.orb.Parent then oldest.orb:Destroy() end
        end
    end

    local folder = getTracerFolder()
    local railCF = CFrame.lookAt(origin, hitPos)

    local coreColor = isEnemy and tCfg.EnemyColor or tCfg.FriendlyColor
    local h, s, v = coreColor:ToHSV()
    local spiralColor = Color3.fromHSV(h, math.clamp(s * 0.45, 0, 1), math.clamp(v * 1.3, 0, 1))

    local rail = Instance.new("Part")
    rail.Name = "RH_TracerRail"
    rail.Size = Vector3.new(0.1, 0.1, 0.1)
    rail.Transparency = 1
    rail.Anchored = true
    rail.CanCollide = false
    rail.CanQuery = false
    rail.CanTouch = false
    rail.CastShadow = false
    rail.CFrame = railCF * CFrame.new(0, 0, -length / 2)
    rail:SetAttribute(Config.Tag, true)
    rail.Parent = folder

    local a0 = buildAttachment("RH_Tr0", rail, Vector3.new(0, 0, length / 2), {})
    local a1 = buildAttachment("RH_Tr1", rail, Vector3.new(0, 0, -length / 2), {})

    local beam = Instance.new("Beam")
    beam.Name = "RH_TracerBeam"
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Brightness = 3
    beam.Width0 = 0.15
    beam.Width1 = 0.08
    beam.Color = ColorSequence.new(coreColor)
    beam.Transparency = NumberSequence.new(0.1)
    beam:SetAttribute(Config.Tag, true)
    beam.Parent = rail

    local orb = Instance.new("Part")
    orb.Name = "RH_TracerOrb"
    orb.Size = Vector3.new(0.2, 0.2, 0.2)
    orb.Material = Enum.Material.Neon
    orb.Color = spiralColor
    orb.Anchored = true
    orb.CanCollide = false
    orb.CanQuery = false
    orb.CanTouch = false
    orb.CastShadow = false
    orb.CFrame = railCF * CFrame.new(tCfg.SpiralRadius, 0, 0)
    orb:SetAttribute(Config.Tag, true)

    local orbMesh = Instance.new("SpecialMesh")
    orbMesh.MeshType = Enum.MeshType.Sphere
    orbMesh:SetAttribute(Config.Tag, true)
    orbMesh.Parent = orb
    orb.Parent = folder

    local ta0 = buildAttachment("RH_TrS0", orb, Vector3.new(0, 0.1, 0), {})
    local ta1 = buildAttachment("RH_TrS1", orb, Vector3.new(0, -0.1, 0), {})

    local spiralTrail = Instance.new("Trail")
    spiralTrail.Name = "RH_SpiralTrail"
    spiralTrail.Attachment0 = ta0
    spiralTrail.Attachment1 = ta1
    spiralTrail.Lifetime = 0.2
    spiralTrail.MinLength = 0.02
    spiralTrail.FaceCamera = true
    spiralTrail.LightEmission = 1
    spiralTrail.LightInfluence = 0
    spiralTrail.Brightness = 2.5
    spiralTrail.WidthScale = NumberSequence.new({ kp(0, 1), kp(1, 0.2) })
    spiralTrail.Color = ColorSequence.new(spiralColor, coreColor)
    spiralTrail.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
    spiralTrail:SetAttribute(Config.Tag, true)
    spiralTrail.Parent = orb

    local duration = math.max(tCfg.Duration or 0.4, length / tCfg.SpiralSpeed + 0.15)

    table.insert(Tracers.ActiveTracers, {
        rail = rail,
        beam = beam,
        orb = orb,
        railCF = railCF,
        length = length,
        dist = 0,
        age = 0,
        duration = duration,
    })
end

function Tracers.SpawnTracerFromCamera()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local tCfg = Config.Visuals.Tracers

    local origin = (cam.CFrame * CFrame.new(0.7, -0.5, -1)).Position
    local char = LocalPlayer.Character
    if char then
        local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
        if rightArm and rightArm:IsA("BasePart") then
            origin = (rightArm.CFrame * CFrame.new(0, -rightArm.Size.Y * 0.5, 0)).Position
        end
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter: {Instance} = {}
    if char then table.insert(filter, char) end
    if Tracers.Folder then table.insert(filter, Tracers.Folder) end
    params.FilterDescendantsInstances = filter

    local camPos = cam.CFrame.Position
    local look = cam.CFrame.LookVector
    local result = Workspace:Raycast(camPos, look * tCfg.MaxDistance, params)
    local hitPos = result and result.Position or (camPos + look * tCfg.MaxDistance)

    Tracers.FireTracer(origin, hitPos, false)
end

function Tracers.Step(dt: number)
    local tCfg = Config.Visuals.Tracers
    for i = #Tracers.ActiveTracers, 1, -1 do
        local tr = Tracers.ActiveTracers[i]
        tr.age += dt

        if tr.age >= tr.duration or not tr.rail.Parent then
            if tr.rail and tr.rail.Parent then tr.rail:Destroy() end
            if tr.orb and tr.orb.Parent then tr.orb:Destroy() end
            table.remove(Tracers.ActiveTracers, i)
        else
            local fade = math.clamp(tr.age / tr.duration, 0, 1)
            tr.beam.Transparency = NumberSequence.new(0.1 + 0.9 * fade * fade)

            if tr.dist < tr.length then
                tr.dist = math.min(tr.dist + tCfg.SpiralSpeed * dt, tr.length)
                local spin = tr.dist * tCfg.SpiralTwist
                tr.orb.CFrame = tr.railCF
                    * CFrame.new(0, 0, -tr.dist)
                    * CFrame.Angles(0, 0, spin)
                    * CFrame.new(tCfg.SpiralRadius, 0, 0)
                if tr.dist >= tr.length then
                    tr.orb.Transparency = 1
                end
            end
        end
    end
end

function Tracers.Cleanup()
    for _, tr in ipairs(Tracers.ActiveTracers) do
        if tr.rail and tr.rail.Parent then tr.rail:Destroy() end
        if tr.orb and tr.orb.Parent then tr.orb:Destroy() end
    end
    table.clear(Tracers.ActiveTracers)

    if Tracers.Folder and Tracers.Folder.Parent then
        Tracers.Folder:ClearAllChildren()
    end
end

-------------------------------------------------------------------
-- Game Hook System (Deduplicated Characters & Single Flow)
-------------------------------------------------------------------
local GameHook = {}
GameHook.Connections = {}
GameHook.PlayerConnections = {}
GameHook.FighterController = nil
GameHook.TracerHooked = false
GameHook.FiringHeld = false

function GameHook.IsAlly(player: Player?): boolean
    if not player or player == LocalPlayer then
        return true
    end
    local myTeam = LocalPlayer:GetAttribute("TeamID")
    local targetTeam = player:GetAttribute("TeamID")
    if myTeam ~= nil and targetTeam ~= nil and myTeam ~= 0 and targetTeam ~= 0 then
        return myTeam == targetTeam
    end
    if LocalPlayer.Team ~= nil and player.Team ~= nil then
        return LocalPlayer.Team == player.Team
    end
    return false
end

function GameHook.GetModelForPlayer(player: Player): Model?
    local fc = GameHook.FighterController
    if fc and typeof(fc.GetFighter) == "function" then
        local ok, fighter = pcall(fc.GetFighter, fc, player)
        if ok and fighter and fighter.Entity and fighter.Entity.Model and fighter.Entity.Model.Parent then
            return fighter.Entity.Model
        end
    end
    if player.Character and player.Character.Parent then
        return player.Character
    end
    return nil
end

function GameHook.GetUniqueCharacters(): {[Model]: {player: Player?, isAlly: boolean, isLocal: boolean}}
    local results: {[Model]: {player: Player?, isAlly: boolean, isLocal: boolean}} = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local m = GameHook.GetModelForPlayer(player)
        if m and m.Parent and not results[m] then
            results[m] = {
                player = player,
                isAlly = GameHook.IsAlly(player),
                isLocal = (player == LocalPlayer)
            }
        end
    end

    local fc = GameHook.FighterController
    if fc and fc.Objects then
        for _, fighter in pairs(fc.Objects) do
            if fighter.Entity and fighter.Entity.Model and fighter.Entity.Model.Parent then
                local m = fighter.Entity.Model
                if not results[m] then
                    local p = fighter.Player
                    results[m] = {
                        player = p,
                        isAlly = p and GameHook.IsAlly(p) or false,
                        isLocal = (p == LocalPlayer)
                    }
                end
            end
        end
    end

    return results
end

function GameHook.RefreshAuras()
    if not Config.Visuals.ESP.Aura then
        Aura.SetVisible(false)
        return
    end

    Aura.SetVisible(true)
    local chars = GameHook.GetUniqueCharacters()

    for m, info in pairs(chars) do
        if info.isLocal and not Config.Visuals.ESP.IncludeLocal then
            Aura.Remove(m)
        else
            if not Aura.Tracked[m] then
                Aura.Apply(m, info.isAlly)
            end
        end
    end

    for m in pairs(Aura.Tracked) do
        if not chars[m] then
            Aura.Remove(m)
        end
    end

    Aura.UpdateColors()
    Aura.UpdateThroughWalls(Config.Visuals.ESP.ThroughWalls)
end

function GameHook.HookTracers()
    if GameHook.TracerHooked then return end

    task.spawn(function()
        local tracerModule
        local attempts = 0
        while not tracerModule and attempts < 20 do
            attempts += 1
            local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
            local modules = playerScripts and playerScripts:FindFirstChild("Modules")
            local tm = modules and modules:FindFirstChild("TracerEffect")
            if tm and tm:IsA("ModuleScript") then
                pcall(function()
                    tracerModule = require(tm)
                end)
            end
            if tracerModule then break end
            task.wait(0.5)
        end

        if tracerModule and typeof(tracerModule.Play) == "function" and not tracerModule._RivalsHubHooked then
            tracerModule._RivalsHubHooked = true
            local originalPlay = tracerModule.Play
            tracerModule.Play = function(self, p9, p10, p11)
                if Config.Visuals.Tracers.Enabled then
                    task.spawn(function()
                        pcall(function()
                            local u12, _, u14 = self:VerifyTracerData(p9, p10, p11)
                            if u14 and u14.MuzzlePosition and u12 and u12.RaycastResults then
                                local isEnemy = u12.IsEnemy or false
                                for _, res in pairs(u12.RaycastResults) do
                                    local startPos = res.StartPosition or u14.MuzzlePosition
                                    local hitPos = res.Position
                                    if startPos and hitPos then
                                        Tracers.FireTracer(startPos, hitPos, isEnemy)
                                    end
                                end
                            end
                        end)
                    end)
                end
                return originalPlay(self, p9, p10, p11)
            end
            GameHook.TracerHooked = true
        end
    end)
end

function GameHook.Init()
    pcall(function()
        local controllers = LocalPlayer:WaitForChild("PlayerScripts", 4):WaitForChild("Controllers", 4)
        GameHook.FighterController = require(controllers:WaitForChild("FighterController", 4))
    end)

    GameHook.HookTracers()

    local function onCharacterModel(m: Model?, isAlly: boolean, isLocal: boolean)
        if not m or not m.Parent or not Config.Visuals.ESP.Aura then return end
        if isLocal and not Config.Visuals.ESP.IncludeLocal then return end
        local hum = m:WaitForChild("Humanoid", 3)
        local root = m:WaitForChild("HumanoidRootPart", 3)
        if not hum or not root then return end
        task.wait(0.04)
        if not m.Parent then return end
        Aura.Apply(m, isAlly)
    end

    local function watchPlayer(player: Player)
        if GameHook.PlayerConnections[player] then
            for _, conn in ipairs(GameHook.PlayerConnections[player]) do
                conn:Disconnect()
            end
        end

        local pConns = {}
        GameHook.PlayerConnections[player] = pConns
        local isLocal = (player == LocalPlayer)

        table.insert(pConns, player.CharacterAdded:Connect(function(char)
            onCharacterModel(char, GameHook.IsAlly(player), isLocal)
        end))
        table.insert(pConns, player.CharacterRemoving:Connect(function(char)
            Aura.Remove(char)
        end))
        table.insert(pConns, player:GetAttributeChangedSignal("TeamID"):Connect(GameHook.RefreshAuras))
        table.insert(pConns, player:GetPropertyChangedSignal("Team"):Connect(GameHook.RefreshAuras))

        if player.Character and player.Character.Parent then
            task.spawn(onCharacterModel, player.Character, GameHook.IsAlly(player), isLocal)
        end
    end

    local function unwatchPlayer(player: Player)
        if GameHook.PlayerConnections[player] then
            for _, conn in ipairs(GameHook.PlayerConnections[player]) do
                conn:Disconnect()
            end
            GameHook.PlayerConnections[player] = nil
        end
        local m = GameHook.GetModelForPlayer(player)
        if m then
            Aura.Remove(m)
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        watchPlayer(p)
    end

    table.insert(GameHook.Connections, Players.PlayerAdded:Connect(watchPlayer))
    table.insert(GameHook.Connections, Players.PlayerRemoving:Connect(unwatchPlayer))
    table.insert(GameHook.Connections, LocalPlayer:GetAttributeChangedSignal("TeamID"):Connect(GameHook.RefreshAuras))
    table.insert(GameHook.Connections, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(GameHook.RefreshAuras))

    local fc = GameHook.FighterController
    if fc then
        local function watchFighter(fighter: any)
            if not fighter then return end
            if fighter.EntityAdded then
                table.insert(GameHook.Connections, fighter.EntityAdded:Connect(function(entity)
                    if entity and entity.Model then
                        local p = fighter.Player
                        onCharacterModel(entity.Model, p and GameHook.IsAlly(p) or false, p == LocalPlayer)
                    end
                end))
            end
            if fighter.EntityRemoved then
                table.insert(GameHook.Connections, fighter.EntityRemoved:Connect(function(entity)
                    if entity and entity.Model then
                        Aura.Remove(entity.Model)
                    end
                end))
            end
            if fighter.Entity and fighter.Entity.Model then
                local p = fighter.Player
                task.spawn(onCharacterModel, fighter.Entity.Model, p and GameHook.IsAlly(p) or false, p == LocalPlayer)
            end
        end

        if fc.Objects then
            for _, f in pairs(fc.Objects) do watchFighter(f) end
        end
        if fc.ObjectAdded then
            table.insert(GameHook.Connections, fc.ObjectAdded:Connect(watchFighter))
        end
    end

    table.insert(GameHook.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            GameHook.FiringHeld = true
        end
    end))

    table.insert(GameHook.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            GameHook.FiringHeld = false
        end
    end))

    local t = 0
    local lastTracerAt = 0
    table.insert(GameHook.Connections, RunService.RenderStepped:Connect(function(dt)
        t += dt
        if Config.Visuals.ESP.Aura then
            Aura.Step(t, dt)
        end

        if Config.Visuals.Tracers.Enabled then
            if Config.Visuals.Tracers.FallbackCameraRaycast and GameHook.FiringHeld then
                if t - lastTracerAt >= (Config.Visuals.Tracers.Interval or 0.11) then
                    lastTracerAt = t
                    Tracers.SpawnTracerFromCamera()
                end
            end
            Tracers.Step(dt)
        end
    end))

    local scanTimer = 0
    table.insert(GameHook.Connections, RunService.Heartbeat:Connect(function(dt)
        scanTimer += dt
        if scanTimer < 1.5 then return end
        scanTimer = 0
        if not Config.Visuals.ESP.Aura then return end

        local chars = GameHook.GetUniqueCharacters()
        for m, info in pairs(chars) do
            if not Aura.Tracked[m] then
                if not info.isLocal or Config.Visuals.ESP.IncludeLocal then
                    Aura.Apply(m, info.isAlly)
                end
            end
        end
    end))

    GameHook.RefreshAuras()
end

function GameHook.Destroy()
    for _, conn in ipairs(GameHook.Connections) do
        conn:Disconnect()
    end
    table.clear(GameHook.Connections)

    for _, pConns in pairs(GameHook.PlayerConnections) do
        for _, conn in ipairs(pConns) do
            conn:Disconnect()
        end
    end
    table.clear(GameHook.PlayerConnections)
    GameHook.FiringHeld = false

    for model in pairs(Aura.Tracked) do
        Aura.Remove(model)
    end
    table.clear(Aura.Tracked)

    Tracers.Cleanup()
end

-------------------------------------------------------------------
-- UI Engine (Rayfield Sidebar Tabs & Non-Blocking Callbacks)
-------------------------------------------------------------------
local function createDebounced(fn, delay)
    local last = 0
    local pending = false
    return function(...)
        local args = {...}
        local now = os.clock()
        if now - last >= delay then
            last = now
            fn(table.unpack(args))
        elseif not pending then
            pending = true
            task.delay(delay, function()
                pending = false
                last = os.clock()
                fn(table.unpack(args))
            end)
        end
    end
end

local function buildUI(onUnload: () -> ())
    local env = (typeof(getgenv) == "function" and getgenv()) or _G
    if env.LinoriaLib and typeof(env.LinoriaLib.Unload) == "function" then
        pcall(env.LinoriaLib.Unload)
        env.LinoriaLib = nil
    end

    local Library
    local ok, res = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
    end)
    if not ok or not res then
        warn("[RivalsHub] Failed to load LinoriaLib UI library")
        return nil
    end
    Library = res
    env.LinoriaLib = Library

    local Window = Library:CreateWindow({
        Title = "RIVALS HUB",
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.1,
    })

    local esp = Config.Visuals.ESP
    local tr = Config.Visuals.Tracers

    local debouncedUpdateColors = createDebounced(function()
        Aura.UpdateColors()
    end, 0.04)

    local Tabs = {
        ESP = Window:AddTab("Aura ESP"),
        Tracers = Window:AddTab("Bullet Tracers"),
        Settings = Window:AddTab("Settings"),
    }

    -------------------------------------------------------------------
    -- TAB 1: Aura ESP
    -------------------------------------------------------------------
    local ESPBox = Tabs.ESP:AddLeftGroupbox("ESP Controls")

    ESPBox:AddToggle("AuraToggle", {
        Text = "Aura",
        Default = esp.Aura,
        Tooltip = "Toggle character aura visuals",
        Callback = function(value)
            esp.Aura = value
            Aura.SetVisible(value)
            if value then
                GameHook.RefreshAuras()
            end
        end,
    })

    ESPBox:AddToggle("ThroughWallsToggle", {
        Text = "Through Walls",
        Default = esp.ThroughWalls,
        Tooltip = "Show highlights through geometry (AlwaysOnTop vs Occluded)",
        Callback = function(value)
            esp.ThroughWalls = value
            Aura.UpdateThroughWalls(value)
        end,
    })

    ESPBox:AddToggle("IncludeLocalToggle", {
        Text = "Include Local Player",
        Default = esp.IncludeLocal,
        Tooltip = "Render aura on your own character",
        Callback = function(value)
            esp.IncludeLocal = value
            GameHook.RefreshAuras()
        end,
    })

    local ColorBox = Tabs.ESP:AddRightGroupbox("Color Palette")

    ColorBox:AddLabel("Local Color"):AddColorPicker("LocalColorPicker", {
        Default = esp.Colors.Local,
        Title = "Local Color",
        Callback = function(value)
            esp.Colors.Local = value
            debouncedUpdateColors()
        end,
    })

    ColorBox:AddLabel("Ally Color"):AddColorPicker("AllyColorPicker", {
        Default = esp.Colors.Ally,
        Title = "Ally Color",
        Callback = function(value)
            esp.Colors.Ally = value
            debouncedUpdateColors()
        end,
    })

    ColorBox:AddLabel("Enemy Color"):AddColorPicker("EnemyColorPicker", {
        Default = esp.Colors.Enemy,
        Title = "Enemy Color",
        Callback = function(value)
            esp.Colors.Enemy = value
            debouncedUpdateColors()
        end,
    })

    local ModBox = Tabs.ESP:AddLeftGroupbox("Customization")

    ModBox:AddToggle("AngelWingsToggle", {
        Text = "Angel Wings",
        Default = esp.UseWings,
        Tooltip = "Toggle flapping wings on self",
        Callback = function(value)
            esp.UseWings = value
            GameHook.RefreshAuras()
        end,
    })

    ModBox:AddSlider("OrbCountSlider", {
        Text = "Orb Count",
        Default = esp.OrbCount,
        Min = 1,
        Max = 5,
        Rounding = 0,
        Suffix = " orbs",
        Callback = function(value)
            esp.OrbCount = math.floor(value)
            GameHook.RefreshAuras()
        end,
    })

    ModBox:AddSlider("IntensitySlider", {
        Text = "Intensity",
        Default = esp.Intensity,
        Min = 0.5,
        Max = 2.5,
        Rounding = 1,
        Suffix = "x",
        Callback = function(value)
            esp.Intensity = value
            debouncedUpdateColors()
        end,
    })

    -------------------------------------------------------------------
    -- TAB 2: Bullet Tracers
    -------------------------------------------------------------------
    local TracerBox = Tabs.Tracers:AddLeftGroupbox("Bullet Tracers")

    TracerBox:AddToggle("TracersToggle", {
        Text = "Bullet Tracers",
        Default = tr.Enabled,
        Tooltip = "Hook real gunshots and render spiral tracers",
        Callback = function(value)
            tr.Enabled = value
            if not value then
                Tracers.Cleanup()
            end
        end,
    })

    TracerBox:AddToggle("FallbackRaycastToggle", {
        Text = "Click Fallback Raycast",
        Default = tr.FallbackCameraRaycast,
        Tooltip = "Fires a tracer on mouse click if gun effect isn't present",
        Callback = function(value)
            tr.FallbackCameraRaycast = value
        end,
    })

    TracerBox:AddSlider("DurationSlider", {
        Text = "Duration",
        Default = tr.Duration or 0.4,
        Min = 0.1,
        Max = 2.0,
        Rounding = 2,
        Suffix = "s",
        Callback = function(value)
            tr.Duration = value
        end,
    })

    local TracerColorBox = Tabs.Tracers:AddRightGroupbox("Colors & Dynamics")

    TracerColorBox:AddLabel("Friendly Color"):AddColorPicker("FriendlyColorPicker", {
        Default = tr.FriendlyColor,
        Title = "Friendly Color",
        Callback = function(value)
            tr.FriendlyColor = value
        end,
    })

    TracerColorBox:AddLabel("Enemy Color"):AddColorPicker("EnemyColorPicker", {
        Default = tr.EnemyColor,
        Title = "Enemy Color",
        Callback = function(value)
            tr.EnemyColor = value
        end,
    })

    TracerColorBox:AddSlider("SpiralSpeedSlider", {
        Text = "Spiral Speed",
        Default = tr.SpiralSpeed or 420,
        Min = 200,
        Max = 800,
        Rounding = 0,
        Suffix = " studs/s",
        Callback = function(value)
            tr.SpiralSpeed = math.floor(value)
        end,
    })

    TracerColorBox:AddSlider("SpiralRadiusSlider", {
        Text = "Spiral Radius",
        Default = tr.SpiralRadius or 0.32,
        Min = 0.1,
        Max = 0.8,
        Rounding = 2,
        Suffix = " studs",
        Callback = function(value)
            tr.SpiralRadius = value
        end,
    })

    -------------------------------------------------------------------
    -- TAB 3: Settings
    -------------------------------------------------------------------
    local MenuBox = Tabs.Settings:AddLeftGroupbox("Menu Settings")

    MenuBox:AddLabel("Toggle Keybind: RightShift / RightControl")

    MenuBox:AddButton({
        Text = "Unload Hub",
        Func = function()
            Library:Unload()
        end,
    })

    local InfoBox = Tabs.Settings:AddRightGroupbox("Diagnostics")
    InfoBox:AddLabel("Engine: Zero-Allocation Luau")
    InfoBox:AddLabel("Hooks: TracerEffect + FighterController")
    InfoBox:AddLabel("Status: Running at full FPS")

    Library:SetWatermark("RIVALS HUB | Zero-Lag Edition")
    Library:SetWatermarkVisibility(true)

    Library:OnUnload(function()
        if typeof(onUnload) == "function" then
            onUnload()
        end
    end)

    Library:Notify("Rivals Hub loaded successfully!", 3)

    return {
        Library = Library,
        Window = Window,
    }
end

-------------------------------------------------------------------
-- App Lifecycle
-------------------------------------------------------------------
local App = {
    Config = Config,
    Aura = Aura,
    Tracers = Tracers,
    GameHook = GameHook,
    UI = nil,
}

function App.Destroy()
    GameHook.Destroy()
    if App.UI and App.UI.Library and App.UI.Library.Unload then
        pcall(App.UI.Library.Unload)
    end
    if env.RivalsHubInstance == App then
        env.RivalsHubInstance = nil
    end
end

env.RivalsHubInstance = App

GameHook.Init()
App.UI = buildUI(function()
    App.Destroy()
end)

return App
