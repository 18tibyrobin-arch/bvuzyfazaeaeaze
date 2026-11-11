local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
end

local TAU = math.pi * 2
local kp = NumberSequenceKeypoint.new

local Aura = {}
Aura.Tracked = setmetatable({}, { __mode = "k" })

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

local function buildAttachment(name: string, parent: Instance, tag: string, offset: Vector3?, instancesList: {Instance}): Attachment
    local att = Instance.new("Attachment")
    att.Name = name
    if offset then att.Position = offset end
    att:SetAttribute(tag, true)
    att.Parent = parent
    table.insert(instancesList, att)
    return att
end

local function buildEmitter(props: {[string]: any}, parent: Instance, tag: string, instancesList: {Instance}): ParticleEmitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.LockedToPart = true
    emitter.VelocityInheritance = 0
    emitter.LightInfluence = 0
    for key, val in pairs(props) do
        emitter[key] = val
    end
    emitter:SetAttribute(tag, true)
    emitter.Parent = parent
    table.insert(instancesList, emitter)
    return emitter
end

local function buildCosmeticPart(name: string, size: Vector3, color: Color3, transparency: number, parent: Instance, tag: string, instancesList: {Instance}): Part
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
    p:SetAttribute(tag, true)
    p.Parent = parent
    table.insert(instancesList, p)
    return p
end

local function weldTo(part0: BasePart, part1: Part, c0: CFrame, tag: string, instancesList: {Instance}): Weld
    local w = Instance.new("Weld")
    w.Part0 = part0
    w.Part1 = part1
    w.C0 = c0
    w:SetAttribute(tag, true)
    w.Parent = part1
    table.insert(instancesList, w)
    return w
end

local function buildWing(character: Model, anchor: BasePart, side: number, tag: string, instancesList: {Instance}): Weld
    local wingRoot = buildCosmeticPart("RH_WingRoot", Vector3.new(0.2, 0.2, 0.2), Color3.new(1, 1, 1), 1, character, tag, instancesList)
    local rootWeld = weldTo(anchor, wingRoot, CFrame.new(0.35 * side, 0.55, 0.62), tag, instancesList)

    local feathers = {
        { 14, 2.0, 0.42 },
        { 36, 2.5, 0.50 },
        { 58, 2.8, 0.55 },
        { 80, 2.5, 0.50 },
        { 100, 2.0, 0.42 },
    }

    for i, f in ipairs(feathers) do
        local ang, len, width = f[1], f[2], f[3]
        local feather = buildCosmeticPart("RH_Feather", Vector3.new(0.14, len, width), Color3.new(1, 1, 1), 0.05, character, tag, instancesList)
        local fw = Instance.new("Weld")
        fw.Part0 = wingRoot
        fw.Part1 = feather
        fw.C0 = CFrame.new(0, 0, 0.035 * i)
            * CFrame.Angles(0, 0, math.rad(ang) * -side)
            * CFrame.new(0, len / 2, 0)
        fw:SetAttribute(tag, true)
        fw.Parent = feather
        table.insert(instancesList, fw)
    end

    return rootWeld
end

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

function Aura.SetVisible(visible: boolean, cfg: any?)
    local chamsOn = cfg and cfg.Visuals and cfg.Visuals.ESP and cfg.Visuals.ESP.Chams
    for _, data in pairs(Aura.Tracked) do
        if data.highlight and data.highlight.Parent then
            data.highlight.Enabled = visible and (not chamsOn)
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

function Aura.UpdateColors(cfg: any)
    local espCfg = cfg.Visuals.ESP
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

function Aura.Apply(character: Model, isAllyTeam: boolean, cfg: any, tag: string)
    local espCfg = cfg.Visuals.ESP
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
        Aura.UpdateColors(cfg)
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
    hl.Enabled = espCfg.Aura and (not espCfg.Chams)
    hl:SetAttribute(tag, true)
    hl.Parent = character
    table.insert(instancesList, hl)
    data.highlight = hl

    if espCfg.UseOrbs then
        for i = 1, espCfg.OrbCount do
            local orb = buildCosmeticPart("RH_Orb" .. i, Vector3.new(0.65, 0.65, 0.65), bright, espCfg.Aura and 0 or 1, character, tag, instancesList)
            orb.Anchored = true
            local orbMesh = Instance.new("SpecialMesh")
            orbMesh.MeshType = Enum.MeshType.Sphere
            orbMesh:SetAttribute(tag, true)
            orbMesh.Parent = orb
            table.insert(instancesList, orbMesh)

            local orbAtt = buildAttachment("RH_OrbGlow", orb, tag, nil, instancesList)
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
            }, orbAtt, tag, instancesList)
            table.insert(data.emitters, orbFire)

            local ta0 = buildAttachment("RH_OrbT0", orb, tag, Vector3.new(0, 0.3, 0), instancesList)
            local ta1 = buildAttachment("RH_OrbT1", orb, tag, Vector3.new(0, -0.3, 0), instancesList)
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
            orbTrail:SetAttribute(tag, true)
            orbTrail.Parent = orb
            table.insert(instancesList, orbTrail)

            table.insert(data.orbTrails, orbTrail)
            table.insert(data.orbs, orb)
        end
    end

    if isLocalChar and espCfg.UseWings then
        data.wingWelds = {
            buildWing(character, anchor, -1, tag, instancesList),
            buildWing(character, anchor, 1, tag, instancesList),
        }
    end

    if espCfg.UseFlames then
        local coreAtt = buildAttachment("RH_Core", anchor, tag, nil, instancesList)

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
        }, coreAtt, tag, instancesList)
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
        }, coreAtt, tag, instancesList)
        table.insert(data.emitters, innerFire)

        for _, armName in ipairs({ "Left Arm", "Right Arm" }) do
            local arm = getLimb(character, armName)
            if arm then
                local fistAtt = buildAttachment("RH_Fist", arm, tag, Vector3.new(0, -arm.Size.Y * 0.4, 0), instancesList)
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
                }, fistAtt, tag, instancesList)
                table.insert(data.emitters, fistFire)
            end
        end
    end

    if espCfg.UseLight then
        local lightAtt = buildAttachment("RH_LightAtt", anchor, tag, nil, instancesList)
        local light = Instance.new("PointLight")
        light.Name = "RH_Light"
        light.Color = main
        light.Brightness = 1.5
        light.Range = 12
        light.Shadows = false
        light.Enabled = espCfg.Aura
        light:SetAttribute(tag, true)
        light.Parent = lightAtt
        table.insert(instancesList, light)
        data.light = light
    end

    Aura.Tracked[character] = data
end

function Aura.Step(t: number, dt: number, cfg: any)
    local espCfg = cfg.Visuals.ESP
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

return Aura
