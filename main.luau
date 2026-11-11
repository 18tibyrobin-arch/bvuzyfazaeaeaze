local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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

local Config = {
    Tag = "RivalsHubV1",
    Visuals = {
        ESP = {
            Box = false,
            BoxColor = Color3.fromRGB(255, 255, 255),
            Skeleton = false,
            SkeletonColor = Color3.fromRGB(255, 255, 255),
            Name = false,
            NameColor = Color3.fromRGB(255, 255, 255),
            Health = false,
            HealthColor = Color3.fromRGB(0, 255, 120),
            Distance = false,
            DistanceColor = Color3.fromRGB(200, 200, 200),
            Weapon = false,
            WeaponColor = Color3.fromRGB(255, 220, 100),

            Chams = false,
            ChamsThroughWalls = true,
            ChamsColor = Color3.fromRGB(255, 60, 60),

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
        }
    },
    Settings = {
        Theme = "Default Dark",
        ShowWatermark = true,
    }
}

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
        end
    end

    for _, m in ipairs(deadModels) do
        Aura.Remove(m)
    end
end

local Chams = {}
Chams.Highlights = setmetatable({}, { __mode = "k" })

function Chams.Apply(character: Model, isAlly: boolean, isLocal: boolean)
    local espCfg = Config.Visuals.ESP
    if not character or not character.Parent then return end
    if isLocal and not espCfg.IncludeLocal then
        Chams.Remove(character)
        return
    end

    local hl = Chams.Highlights[character]
    if not hl or not hl.Parent then
        hl = Instance.new("Highlight")
        hl.Name = "RH_Chams"
        hl.Adornee = character
        hl:SetAttribute(Config.Tag .. "_Chams", true)
        hl.Parent = character
        Chams.Highlights[character] = hl
    end

    local chamsColor = isAlly and espCfg.Colors.Ally or espCfg.ChamsColor
    local h, s, v = chamsColor:ToHSV()
    local outlineColor = Color3.fromHSV(h, math.clamp(s * 0.45, 0, 1), math.clamp(v * 1.3, 0, 1))

    hl.Enabled = espCfg.Chams
    hl.DepthMode = espCfg.ChamsThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    hl.FillColor = chamsColor
    hl.FillTransparency = 0.5
    hl.OutlineColor = outlineColor
    hl.OutlineTransparency = 0.05
end

function Chams.Remove(character: Model?)
    if not character then return end
    local hl = Chams.Highlights[character]
    if hl and hl.Parent then
        hl:Destroy()
    end
    Chams.Highlights[character] = nil
end

function Chams.UpdateProperties(characters: {[Model]: {player: Player?, isAlly: boolean, isLocal: boolean}})
    local espCfg = Config.Visuals.ESP
    for model, info in pairs(characters) do
        if espCfg.Chams then
            Chams.Apply(model, info.isAlly, info.isLocal)
        else
            Chams.Remove(model)
        end
    end
end

function Chams.Cleanup()
    for _, hl in pairs(Chams.Highlights) do
        if hl and hl.Parent then
            hl:Destroy()
        end
    end
    table.clear(Chams.Highlights)
end

local ESP2D = {}
ESP2D.Entries = {}
ESP2D.HasDrawing = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function")
ESP2D.FallbackGui = nil

local function getFallbackGui(): ScreenGui
    if ESP2D.FallbackGui and ESP2D.FallbackGui.Parent then
        return ESP2D.FallbackGui
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "RH_ESP2D_Fallback"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    local parentTarget = game:GetService("CoreGui")
    pcall(function()
        gui.Parent = parentTarget
    end)
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    ESP2D.FallbackGui = gui
    return gui
end

local function createDrawObject(drawType: string, props: {[string]: any})
    if ESP2D.HasDrawing then
        local obj = Drawing.new(drawType)
        for k, v in pairs(props) do
            obj[k] = v
        end
        return obj
    else
        local gui = getFallbackGui()
        if drawType == "Square" then
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = props.Filled and 0 or 1
            frame.BorderSizePixel = props.Thickness or 1
            frame.BorderColor3 = props.Color or Color3.new(1, 1, 1)
            frame.Visible = false
            frame.Parent = gui
            return {
                _inst = frame,
                Visible = false,
                Position = Vector2.zero,
                Size = Vector2.zero,
                Color = props.Color or Color3.new(1, 1, 1),
                Thickness = props.Thickness or 1,
                Remove = function(self) if self._inst then self._inst:Destroy() end end
            }
        elseif drawType == "Line" then
            local frame = Instance.new("Frame")
            frame.BorderSizePixel = 0
            frame.Visible = false
            frame.Parent = gui
            return {
                _inst = frame,
                Visible = false,
                From = Vector2.zero,
                To = Vector2.zero,
                Color = props.Color or Color3.new(1, 1, 1),
                Thickness = props.Thickness or 1,
                Remove = function(self) if self._inst then self._inst:Destroy() end end
            }
        elseif drawType == "Text" then
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.TextSize = props.Size or 13
            label.Font = Enum.Font.RobotoMono
            label.Visible = false
            label.Parent = gui
            return {
                _inst = label,
                Visible = false,
                Position = Vector2.zero,
                Text = "",
                Color = props.Color or Color3.new(1, 1, 1),
                Size = props.Size or 13,
                Center = props.Center or false,
                Remove = function(self) if self._inst then self._inst:Destroy() end end
            }
        end
    end
end

local SKELETON_BONES_R15 = {
    { "Head", "UpperTorso" },
    { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" },
    { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" },
    { "RightUpperArm", "RightLowerArm" },
    { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" },
    { "RightUpperLeg", "RightLowerLeg" },
    { "RightLowerLeg", "RightFoot" },
}

local SKELETON_BONES_R6 = {
    { "Head", "Torso" },
    { "Torso", "Left Arm" },
    { "Torso", "Right Arm" },
    { "Torso", "Left Leg" },
    { "Torso", "Right Leg" },
}

function ESP2D.CreateEntry(model: Model)
    local entry = {
        model = model,
        boxOutline = createDrawObject("Square", { Filled = false, Thickness = 3, Color = Color3.new(0, 0, 0), Visible = false }),
        box = createDrawObject("Square", { Filled = false, Thickness = 1, Color = Color3.new(1, 1, 1), Visible = false }),
        healthBg = createDrawObject("Line", { Thickness = 4, Color = Color3.new(0, 0, 0), Visible = false }),
        healthBar = createDrawObject("Line", { Thickness = 2, Color = Color3.fromRGB(0, 255, 120), Visible = false }),
        name = createDrawObject("Text", { Size = 13, Center = true, Outline = true, Color = Color3.new(1, 1, 1), Visible = false }),
        distance = createDrawObject("Text", { Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(200, 200, 200), Visible = false }),
        weapon = createDrawObject("Text", { Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(255, 220, 100), Visible = false }),
        skeleton = {},
    }

    for i = 1, 14 do
        table.insert(entry.skeleton, createDrawObject("Line", { Thickness = 1, Color = Color3.new(1, 1, 1), Visible = false }))
    end

    ESP2D.Entries[model] = entry
    return entry
end

function ESP2D.RemoveEntry(model: Model)
    local entry = ESP2D.Entries[model]
    if entry then
        entry.boxOutline:Remove()
        entry.box:Remove()
        entry.healthBg:Remove()
        entry.healthBar:Remove()
        entry.name:Remove()
        entry.distance:Remove()
        entry.weapon:Remove()
        for _, line in ipairs(entry.skeleton) do
            line:Remove()
        end
        ESP2D.Entries[model] = nil
    end
end

function ESP2D.HideEntry(entry: any)
    entry.boxOutline.Visible = false
    entry.box.Visible = false
    entry.healthBg.Visible = false
    entry.healthBar.Visible = false
    entry.name.Visible = false
    entry.distance.Visible = false
    entry.weapon.Visible = false
    for _, line in ipairs(entry.skeleton) do
        line.Visible = false
    end
end

local function syncFallback(obj: any, drawType: string)
    if not ESP2D.HasDrawing and obj and obj._inst then
        local inst = obj._inst
        inst.Visible = obj.Visible
        if not obj.Visible then return end
        if drawType == "Square" then
            inst.Position = UDim2.fromOffset(obj.Position.X, obj.Position.Y)
            inst.Size = UDim2.fromOffset(obj.Size.X, obj.Size.Y)
            inst.BorderColor3 = obj.Color
        elseif drawType == "Line" then
            local diff = obj.To - obj.From
            local len = diff.Magnitude
            inst.Size = UDim2.fromOffset(len, obj.Thickness)
            inst.Position = UDim2.fromOffset(obj.From.X, obj.From.Y)
            inst.Rotation = math.deg(math.atan2(diff.Y, diff.X))
            inst.BackgroundColor3 = obj.Color
        elseif drawType == "Text" then
            inst.Position = UDim2.fromOffset(obj.Position.X - (obj.Center and 75 or 0), obj.Position.Y)
            inst.Size = UDim2.fromOffset(150, 16)
            inst.Text = obj.Text
            inst.TextColor3 = obj.Color
        end
    end
end

function ESP2D.Step(camera: Camera, characters: {[Model]: {player: Player?, isAlly: boolean, isLocal: boolean}})
    local espCfg = Config.Visuals.ESP
    local any2DEnabled = espCfg.Box or espCfg.Skeleton or espCfg.Name or espCfg.Health or espCfg.Distance or espCfg.Weapon

    for model, entry in pairs(ESP2D.Entries) do
        if not characters[model] or not model.Parent then
            ESP2D.RemoveEntry(model)
        end
    end

    if not any2DEnabled then
        for _, entry in pairs(ESP2D.Entries) do
            ESP2D.HideEntry(entry)
        end
        return
    end

    local camPos = camera.CFrame.Position

    for model, info in pairs(characters) do
        if info.isLocal and not espCfg.IncludeLocal then
            if ESP2D.Entries[model] then
                ESP2D.HideEntry(ESP2D.Entries[model])
            end
            continue
        end

        local entry = ESP2D.Entries[model] or ESP2D.CreateEntry(model)
        local root = model:FindFirstChild("HumanoidRootPart")
        local head = model:FindFirstChild("Head")
        local hum = model:FindFirstChildOfClass("Humanoid")

        if not root or not head or not model.Parent then
            ESP2D.HideEntry(entry)
            continue
        end

        local rootPos = root.Position
        local headPos = head.Position
        local rootViewport, onScreen = camera:WorldToViewportPoint(rootPos)

        if not onScreen or rootViewport.Z <= 0 then
            ESP2D.HideEntry(entry)
            continue
        end

        local topViewport = camera:WorldToViewportPoint(headPos + Vector3.new(0, 0.7, 0))
        local bottomViewport = camera:WorldToViewportPoint(rootPos - Vector3.new(0, 2.8, 0))

        local boxHeight = math.abs(bottomViewport.Y - topViewport.Y)
        local boxWidth = boxHeight * 0.62
        local boxX = topViewport.X - boxWidth / 2
        local boxY = topViewport.Y

        local isAlly = info.isAlly
        local defaultColor = isAlly and espCfg.Colors.Ally or espCfg.Colors.Enemy

        if espCfg.Box then
            local col = espCfg.BoxColor or defaultColor
            entry.boxOutline.Position = Vector2.new(boxX - 1, boxY - 1)
            entry.boxOutline.Size = Vector2.new(boxWidth + 2, boxHeight + 2)
            entry.boxOutline.Visible = true

            entry.box.Position = Vector2.new(boxX, boxY)
            entry.box.Size = Vector2.new(boxWidth, boxHeight)
            entry.box.Color = col
            entry.box.Visible = true
        else
            entry.boxOutline.Visible = false
            entry.box.Visible = false
        end

        if espCfg.Health then
            local health = hum and hum.Health or 100
            local maxHealth = (hum and hum.MaxHealth and hum.MaxHealth > 0) and hum.MaxHealth or 100
            local hpPct = math.clamp(health / maxHealth, 0, 1)

            local barX = boxX - 5
            local barTopY = boxY
            local barBottomY = boxY + boxHeight

            entry.healthBg.From = Vector2.new(barX, barTopY)
            entry.healthBg.To = Vector2.new(barX, barBottomY)
            entry.healthBg.Visible = true

            local fillTopY = barBottomY - (boxHeight * hpPct)
            local hpColor = Color3.fromHSV(hpPct * 0.33, 1, 1)

            entry.healthBar.From = Vector2.new(barX, fillTopY)
            entry.healthBar.To = Vector2.new(barX, barBottomY)
            entry.healthBar.Color = hpColor
            entry.healthBar.Visible = true
        else
            entry.healthBg.Visible = false
            entry.healthBar.Visible = false
        end

        if espCfg.Name then
            local playerName = info.player and (info.player.DisplayName or info.player.Name) or model.Name
            entry.name.Text = playerName
            entry.name.Position = Vector2.new(topViewport.X, boxY - 15)
            entry.name.Color = espCfg.NameColor or defaultColor
            entry.name.Visible = true
        else
            entry.name.Visible = false
        end

        local textOffsetY = 2

        local distStuds = (camPos - rootPos).Magnitude
        if espCfg.Distance then
            entry.distance.Text = string.format("%d studs", math.floor(distStuds))
            entry.distance.Position = Vector2.new(topViewport.X, boxY + boxHeight + textOffsetY)
            entry.distance.Color = espCfg.DistanceColor or Color3.fromRGB(200, 200, 200)
            entry.distance.Visible = true
            textOffsetY += 12
        else
            entry.distance.Visible = false
        end

        if espCfg.Weapon then
            local tool = model:FindFirstChildOfClass("Tool")
            local weaponName = tool and tool.Name or model:GetAttribute("EquippedWeapon")
            if not weaponName or #weaponName == 0 then
                weaponName = "Hands"
            end

            local ammoVal = tool and (tool:GetAttribute("Ammo") or tool:GetAttribute("Clip"))
            local weaponText = ammoVal and string.format("%s [%d]", weaponName, ammoVal) or weaponName

            entry.weapon.Text = weaponText
            entry.weapon.Position = Vector2.new(topViewport.X, boxY + boxHeight + textOffsetY)
            entry.weapon.Color = espCfg.WeaponColor or Color3.fromRGB(255, 220, 100)
            entry.weapon.Visible = true
        else
            entry.weapon.Visible = false
        end

        if espCfg.Skeleton then
            local isR15 = (model:FindFirstChild("UpperTorso") ~= nil)
            local bonePairs = isR15 and SKELETON_BONES_R15 or SKELETON_BONES_R6
            local skColor = espCfg.SkeletonColor or defaultColor

            for i, pair in ipairs(bonePairs) do
                local line = entry.skeleton[i]
                if line then
                    local p1 = model:FindFirstChild(pair[1])
                    local p2 = model:FindFirstChild(pair[2])
                    if p1 and p2 and p1:IsA("BasePart") and p2:IsA("BasePart") then
                        local v1, on1 = camera:WorldToViewportPoint(p1.Position)
                        local v2, on2 = camera:WorldToViewportPoint(p2.Position)
                        if on1 and on2 and v1.Z > 0 and v2.Z > 0 then
                            line.From = Vector2.new(v1.X, v1.Y)
                            line.To = Vector2.new(v2.X, v2.Y)
                            line.Color = skColor
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    else
                        line.Visible = false
                    end
                end
            end
            for i = #bonePairs + 1, #entry.skeleton do
                entry.skeleton[i].Visible = false
            end
        else
            for _, line in ipairs(entry.skeleton) do
                line.Visible = false
            end
        end

        if not ESP2D.HasDrawing then
            syncFallback(entry.boxOutline, "Square")
            syncFallback(entry.box, "Square")
            syncFallback(entry.healthBg, "Line")
            syncFallback(entry.healthBar, "Line")
            syncFallback(entry.name, "Text")
            syncFallback(entry.distance, "Text")
            syncFallback(entry.weapon, "Text")
            for _, l in ipairs(entry.skeleton) do
                syncFallback(l, "Line")
            end
        end
    end
end

function ESP2D.Cleanup()
    for model in pairs(ESP2D.Entries) do
        ESP2D.RemoveEntry(model)
    end
    table.clear(ESP2D.Entries)

    if ESP2D.FallbackGui then
        ESP2D.FallbackGui:Destroy()
        ESP2D.FallbackGui = nil
    end
end

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

local GameHook = {}
GameHook.Connections = {}
GameHook.PlayerConnections = {}
GameHook.FighterController = nil
GameHook.TracerHooked = false

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

function GameHook.RefreshVisuals()
    local chars = GameHook.GetUniqueCharacters()

    if Config.Visuals.ESP.Aura then
        Aura.SetVisible(true)
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
    else
        Aura.SetVisible(false)
    end

    Chams.UpdateProperties(chars)
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
        if not m or not m.Parent then return end
        if isLocal and not Config.Visuals.ESP.IncludeLocal then return end
        local hum = m:WaitForChild("Humanoid", 3)
        local root = m:WaitForChild("HumanoidRootPart", 3)
        if not hum or not root then return end
        task.wait(0.04)
        if not m.Parent then return end

        if Config.Visuals.ESP.Aura then
            Aura.Apply(m, isAlly)
        end
        if Config.Visuals.ESP.Chams then
            Chams.Apply(m, isAlly, isLocal)
        end
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
            Chams.Remove(char)
            ESP2D.RemoveEntry(char)
        end))
        table.insert(pConns, player:GetAttributeChangedSignal("TeamID"):Connect(GameHook.RefreshVisuals))
        table.insert(pConns, player:GetPropertyChangedSignal("Team"):Connect(GameHook.RefreshVisuals))

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
            Chams.Remove(m)
            ESP2D.RemoveEntry(m)
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        watchPlayer(p)
    end

    table.insert(GameHook.Connections, Players.PlayerAdded:Connect(watchPlayer))
    table.insert(GameHook.Connections, Players.PlayerRemoving:Connect(unwatchPlayer))
    table.insert(GameHook.Connections, LocalPlayer:GetAttributeChangedSignal("TeamID"):Connect(GameHook.RefreshVisuals))
    table.insert(GameHook.Connections, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(GameHook.RefreshVisuals))

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
                        Chams.Remove(entity.Model)
                        ESP2D.RemoveEntry(entity.Model)
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

    local t = 0
    local cam = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")

    table.insert(GameHook.Connections, RunService.RenderStepped:Connect(function(dt)
        t += dt
        local currentCam = Workspace.CurrentCamera or cam

        if Config.Visuals.ESP.Aura then
            Aura.Step(t, dt)
        end

        if Config.Visuals.Tracers.Enabled then
            Tracers.Step(dt)
        end

        if currentCam then
            local chars = GameHook.GetUniqueCharacters()
            ESP2D.Step(currentCam, chars)
        end
    end))

    local scanTimer = 0
    table.insert(GameHook.Connections, RunService.Heartbeat:Connect(function(dt)
        scanTimer += dt
        if scanTimer < 1.5 then return end
        scanTimer = 0

        local chars = GameHook.GetUniqueCharacters()
        for m, info in pairs(chars) do
            if Config.Visuals.ESP.Aura and not Aura.Tracked[m] then
                if not info.isLocal or Config.Visuals.ESP.IncludeLocal then
                    Aura.Apply(m, info.isAlly)
                end
            end
            if Config.Visuals.ESP.Chams and not Chams.Highlights[m] then
                Chams.Apply(m, info.isAlly, info.isLocal)
            end
        end
    end))

    GameHook.RefreshVisuals()
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

    for model in pairs(Aura.Tracked) do
        Aura.Remove(model)
    end
    table.clear(Aura.Tracked)

    Chams.Cleanup()
    ESP2D.Cleanup()
    Tracers.Cleanup()
end

local Themes = {
    ["Default Dark"] = {
        AccentColor = Color3.fromRGB(0, 85, 255),
        MainColor = Color3.fromRGB(28, 28, 28),
        BackgroundColor = Color3.fromRGB(20, 20, 20),
        OutlineColor = Color3.fromRGB(50, 50, 50),
        FontColor = Color3.fromRGB(255, 255, 255),
    },
    ["Blood Crimson"] = {
        AccentColor = Color3.fromRGB(255, 40, 60),
        MainColor = Color3.fromRGB(26, 20, 22),
        BackgroundColor = Color3.fromRGB(18, 14, 15),
        OutlineColor = Color3.fromRGB(60, 30, 35),
        FontColor = Color3.fromRGB(255, 240, 240),
    },
    ["Toxic Emerald"] = {
        AccentColor = Color3.fromRGB(0, 230, 110),
        MainColor = Color3.fromRGB(20, 28, 24),
        BackgroundColor = Color3.fromRGB(14, 20, 16),
        OutlineColor = Color3.fromRGB(30, 55, 40),
        FontColor = Color3.fromRGB(240, 255, 245),
    },
    ["Cyberpunk Violet"] = {
        AccentColor = Color3.fromRGB(170, 50, 255),
        MainColor = Color3.fromRGB(25, 20, 32),
        BackgroundColor = Color3.fromRGB(16, 12, 22),
        OutlineColor = Color3.fromRGB(55, 35, 70),
        FontColor = Color3.fromRGB(250, 240, 255),
    },
    ["Midnight Sapphire"] = {
        AccentColor = Color3.fromRGB(0, 200, 255),
        MainColor = Color3.fromRGB(18, 24, 34),
        BackgroundColor = Color3.fromRGB(12, 16, 24),
        OutlineColor = Color3.fromRGB(35, 50, 70),
        FontColor = Color3.fromRGB(240, 250, 255),
    },
}

local function buildUI(onUnload: () -> ())
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
        AutoShow = false,
        TabPadding = 8,
        MenuFadeTime = 0.1,
    })

    local esp = Config.Visuals.ESP
    local tr = Config.Visuals.Tracers

    local function applyTheme(themeName: string)
        local t = Themes[themeName]
        if not t or not Library then return end
        Library.AccentColor = t.AccentColor
        Library.AccentColorDark = Library:GetDarkerColor(t.AccentColor)
        Library.MainColor = t.MainColor
        Library.BackgroundColor = t.BackgroundColor
        Library.OutlineColor = t.OutlineColor
        Library.FontColor = t.FontColor
        Library:UpdateColorsUsingRegistry()
    end

    local Tabs = {
        ESP = Window:AddTab("ESP"),
        Tracers = Window:AddTab("Bullet Tracers"),
        Settings = Window:AddTab("Settings"),
    }

    local OverlayBox = Tabs.ESP:AddLeftGroupbox("2D Overlay ESP")

    OverlayBox:AddToggle("BoxToggle", {
        Text = "Box ESP",
        Default = esp.Box,
        Tooltip = "Draw 2D bounding boxes around players",
        Callback = function(value)
            esp.Box = value
        end,
    }):AddColorPicker("BoxColorPicker", {
        Default = esp.BoxColor,
        Title = "Box Color",
        Callback = function(value)
            esp.BoxColor = value
        end,
    })

    OverlayBox:AddToggle("SkeletonToggle", {
        Text = "Skeleton ESP",
        Default = esp.Skeleton,
        Tooltip = "Draw real-time bone lines connecting player joints",
        Callback = function(value)
            esp.Skeleton = value
        end,
    }):AddColorPicker("SkeletonColorPicker", {
        Default = esp.SkeletonColor,
        Title = "Skeleton Color",
        Callback = function(value)
            esp.SkeletonColor = value
        end,
    })

    OverlayBox:AddToggle("NameToggle", {
        Text = "Name ESP",
        Default = esp.Name,
        Tooltip = "Display player name above character",
        Callback = function(value)
            esp.Name = value
        end,
    }):AddColorPicker("NameColorPicker", {
        Default = esp.NameColor,
        Title = "Name Color",
        Callback = function(value)
            esp.NameColor = value
        end,
    })

    OverlayBox:AddToggle("HealthToggle", {
        Text = "Health Bar",
        Default = esp.Health,
        Tooltip = "Render dynamic health bar on box side",
        Callback = function(value)
            esp.Health = value
        end,
    }):AddColorPicker("HealthColorPicker", {
        Default = esp.HealthColor,
        Title = "Health Bar Color",
        Callback = function(value)
            esp.HealthColor = value
        end,
    })

    OverlayBox:AddToggle("DistanceToggle", {
        Text = "Distance ESP",
        Default = esp.Distance,
        Tooltip = "Display distance in studs below player",
        Callback = function(value)
            esp.Distance = value
        end,
    }):AddColorPicker("DistanceColorPicker", {
        Default = esp.DistanceColor,
        Title = "Distance Color",
        Callback = function(value)
            esp.DistanceColor = value
        end,
    })

    OverlayBox:AddToggle("WeaponToggle", {
        Text = "Weapon & Ammo",
        Default = esp.Weapon,
        Tooltip = "Display equipped weapon and ammo counter",
        Callback = function(value)
            esp.Weapon = value
        end,
    }):AddColorPicker("WeaponColorPicker", {
        Default = esp.WeaponColor,
        Title = "Weapon Color",
        Callback = function(value)
            esp.WeaponColor = value
        end,
    })

    local WorldBox = Tabs.ESP:AddRightGroupbox("3D World ESP (Chams & Aura)")

    WorldBox:AddToggle("ChamsToggle", {
        Text = "Chams",
        Default = esp.Chams,
        Tooltip = "Render body highlight chams on players",
        Callback = function(value)
            esp.Chams = value
            GameHook.RefreshVisuals()
        end,
    }):AddColorPicker("ChamsColorPicker", {
        Default = esp.ChamsColor,
        Title = "Chams Color",
        Callback = function(value)
            esp.ChamsColor = value
            GameHook.RefreshVisuals()
        end,
    })

    WorldBox:AddToggle("ChamsThroughWallsToggle", {
        Text = "Chams Through Walls",
        Default = esp.ChamsThroughWalls,
        Tooltip = "Display chams through map geometry",
        Callback = function(value)
            esp.ChamsThroughWalls = value
            GameHook.RefreshVisuals()
        end,
    })

    WorldBox:AddToggle("AuraToggle", {
        Text = "Aura",
        Default = esp.Aura,
        Tooltip = "Render orbital orbs and flames aura",
        Callback = function(value)
            esp.Aura = value
            Aura.SetVisible(value)
            if value then
                GameHook.RefreshVisuals()
            end
        end,
    }):AddColorPicker("EnemyColorPicker", {
        Default = esp.Colors.Enemy,
        Title = "Enemy Aura Color",
        Callback = function(value)
            esp.Colors.Enemy = value
            Aura.UpdateColors()
        end,
    })

    WorldBox:AddToggle("AuraThroughWallsToggle", {
        Text = "Aura Through Walls",
        Default = esp.ThroughWalls,
        Tooltip = "Display aura highlights through walls",
        Callback = function(value)
            esp.ThroughWalls = value
            Aura.UpdateThroughWalls(value)
        end,
    })

    WorldBox:AddToggle("IncludeLocalToggle", {
        Text = "Include Local Player",
        Default = esp.IncludeLocal,
        Tooltip = "Render visuals on your own character",
        Callback = function(value)
            esp.IncludeLocal = value
            GameHook.RefreshVisuals()
        end,
    })

    WorldBox:AddLabel("Ally Color"):AddColorPicker("AllyColorPicker", {
        Default = esp.Colors.Ally,
        Title = "Ally Color",
        Callback = function(value)
            esp.Colors.Ally = value
            Aura.UpdateColors()
            GameHook.RefreshVisuals()
        end,
    })

    WorldBox:AddLabel("Local Color"):AddColorPicker("LocalColorPicker", {
        Default = esp.Colors.Local,
        Title = "Local Color",
        Callback = function(value)
            esp.Colors.Local = value
            Aura.UpdateColors()
        end,
    })

    local TracerBox = Tabs.Tracers:AddLeftGroupbox("Bullet Tracers")

    TracerBox:AddToggle("TracersToggle", {
        Text = "Bullet Tracers",
        Default = tr.Enabled,
        Tooltip = "Hook gunshots and render spiral bullet beams",
        Callback = function(value)
            tr.Enabled = value
            if not value then
                Tracers.Cleanup()
            end
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

    local TracerColorBox = Tabs.Tracers:AddRightGroupbox("Tracer Colors")

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

    local MenuBox = Tabs.Settings:AddLeftGroupbox("Menu Settings")

    local KeyLabel = MenuBox:AddLabel("Menu Keybind")
    KeyLabel:AddKeyPicker("MenuKeyPicker", {
        Default = "RightShift",
        NoUI = false,
        Text = "Menu Keybind",
        Callback = function()
        end,
    })
    Library.ToggleKeybind = Library.Options and Library.Options.MenuKeyPicker

    MenuBox:AddDropdown("ThemeDropdown", {
        Values = { "Default Dark", "Blood Crimson", "Toxic Emerald", "Cyberpunk Violet", "Midnight Sapphire" },
        Default = 1,
        Multi = false,
        Text = "UI Theme",
        Tooltip = "Select menu color scheme",
        Callback = function(value)
            Config.Settings.Theme = value
            applyTheme(value)
        end,
    })

    MenuBox:AddToggle("WatermarkToggle", {
        Text = "Show Watermark",
        Default = Config.Settings.ShowWatermark,
        Tooltip = "Toggle screen watermark display",
        Callback = function(value)
            Config.Settings.ShowWatermark = value
            Library:SetWatermarkVisibility(value)
        end,
    })

    Library:SetWatermark("RIVALS HUB | Zero-Lag")
    Library:SetWatermarkVisibility(Config.Settings.ShowWatermark)

    Library:OnUnload(function()
        if typeof(onUnload) == "function" then
            onUnload()
        end
    end)

    Library:Notify("Rivals Hub loaded (Press RightShift to show menu)", 4)

    return {
        Library = Library,
        Window = Window,
    }
end

local App = {
    Config = Config,
    Aura = Aura,
    Tracers = Tracers,
    ESP2D = ESP2D,
    Chams = Chams,
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
