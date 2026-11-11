local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat
        task.wait()
        LocalPlayer = Players.LocalPlayer
    until LocalPlayer
end

local env = (typeof(getgenv) == "function" and getgenv()) or _G

local FighterController
pcall(function()
    local controllers = LocalPlayer:WaitForChild("PlayerScripts", 5):WaitForChild("Controllers", 5)
    FighterController = require(controllers:WaitForChild("FighterController", 5))
end)

local TAU = math.pi * 2
local kp = NumberSequenceKeypoint.new

local RivalsAura = {}
RivalsAura.Connections = {}
RivalsAura.PlayerConnections = {}
RivalsAura.Tracked = {}
RivalsAura.ActiveTracers = {}
RivalsAura.FiringHeld = false
RivalsAura.TracerFolder = nil
RivalsAura.TracerHooked = false

RivalsAura.Config = {
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
    Tracers = {
        Enabled = true,
        Duration = 0.4,
        Interval = 0.11,
        MaxDistance = 800,
        SpiralSpeed = 420,
        SpiralRadius = 0.32,
        SpiralTwist = 1.25,
        Core = Color3.fromRGB(150, 40, 255),
        Spiral = Color3.fromRGB(220, 170, 255),
        EnemyCore = Color3.fromRGB(255, 60, 60),
        EnemySpiral = Color3.fromRGB(255, 160, 160),
        FallbackCameraRaycast = true,
    },
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
    inst:SetAttribute(RivalsAura.Config.Tag, true)
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

function RivalsAura.IsAlly(player: Player?): boolean
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

function RivalsAura.Remove(character: Model?)
    if not character then return end
    RivalsAura.Tracked[character] = nil
    for _, item in ipairs(character:GetDescendants()) do
        if item:GetAttribute(RivalsAura.Config.Tag) == true then
            item:Destroy()
        end
    end
end

function RivalsAura.UpdateHighlightDepth()
    local depth = RivalsAura.Config.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    for _, data in pairs(RivalsAura.Tracked) do
        if data.highlight and data.highlight.Parent then
            data.highlight.DepthMode = depth
        end
    end
end

function RivalsAura.Apply(character: Model, isAllyTeam: boolean)
    local cfg = RivalsAura.Config
    if not cfg.Enabled or not character or not character.Parent then
        return
    end

    local isLocalChar = (character == LocalPlayer.Character)
    if isLocalChar and not cfg.IncludeLocalPlayer then
        RivalsAura.Remove(character)
        return
    end

    RivalsAura.Remove(character)

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

    RivalsAura.Tracked[character] = data
end

local function getTracerFolder(): Folder
    if RivalsAura.TracerFolder and RivalsAura.TracerFolder.Parent then
        return RivalsAura.TracerFolder
    end
    local f = Instance.new("Folder")
    f.Name = "RA_Tracers"
    tagInstance(f)
    f.Parent = Workspace
    RivalsAura.TracerFolder = f
    return f
end

function RivalsAura.FireTracer(origin: Vector3, hitPos: Vector3, isEnemy: boolean?)
    local cfgT = RivalsAura.Config.Tracers
    if not cfgT.Enabled then return end

    local dirVec = hitPos - origin
    local length = dirVec.Magnitude
    if length < 2 then return end

    local folder = getTracerFolder()
    local railCF = CFrame.lookAt(origin, hitPos)

    local coreColor = isEnemy and cfgT.EnemyCore or cfgT.Core
    local spiralColor = isEnemy and cfgT.EnemySpiral or cfgT.Spiral

    local rail = Instance.new("Part")
    rail.Name = "RA_TracerRail"
    rail.Size = Vector3.new(0.1, 0.1, 0.1)
    rail.Transparency = 1
    rail.Anchored = true
    rail.CanCollide = false
    rail.CanQuery = false
    rail.CanTouch = false
    rail.CastShadow = false
    rail.CFrame = railCF * CFrame.new(0, 0, -length / 2)
    tagInstance(rail)
    rail.Parent = folder

    local a0 = buildAttachment("RA_Tr0", rail, Vector3.new(0, 0, length / 2))
    local a1 = buildAttachment("RA_Tr1", rail, Vector3.new(0, 0, -length / 2))

    local beam = Instance.new("Beam")
    beam.Name = "RA_TracerBeam"
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Brightness = 3
    beam.Width0 = 0.16
    beam.Width1 = 0.09
    beam.Color = ColorSequence.new(coreColor)
    beam.Transparency = NumberSequence.new(0.1)
    tagInstance(beam)
    beam.Parent = rail

    local orb = Instance.new("Part")
    orb.Name = "RA_TracerOrb"
    orb.Size = Vector3.new(0.22, 0.22, 0.22)
    orb.Material = Enum.Material.Neon
    orb.Color = spiralColor
    orb.Anchored = true
    orb.CanCollide = false
    orb.CanQuery = false
    orb.CanTouch = false
    orb.CastShadow = false
    orb.CFrame = railCF * CFrame.new(cfgT.SpiralRadius, 0, 0)
    tagInstance(orb)
    local orbMesh = Instance.new("SpecialMesh")
    orbMesh.MeshType = Enum.MeshType.Sphere
    tagInstance(orbMesh)
    orbMesh.Parent = orb
    orb.Parent = folder

    local ta0 = buildAttachment("RA_TrS0", orb, Vector3.new(0, 0.11, 0))
    local ta1 = buildAttachment("RA_TrS1", orb, Vector3.new(0, -0.11, 0))
    local spiralTrail = Instance.new("Trail")
    spiralTrail.Name = "RA_SpiralTrail"
    spiralTrail.Attachment0 = ta0
    spiralTrail.Attachment1 = ta1
    spiralTrail.Lifetime = 0.22
    spiralTrail.MinLength = 0.02
    spiralTrail.FaceCamera = true
    spiralTrail.LightEmission = 1
    spiralTrail.LightInfluence = 0
    spiralTrail.Brightness = 2.5
    spiralTrail.WidthScale = NumberSequence.new({ kp(0, 1), kp(1, 0.2) })
    spiralTrail.Color = ColorSequence.new(spiralColor, coreColor)
    spiralTrail.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
    tagInstance(spiralTrail)
    spiralTrail.Parent = orb

    table.insert(RivalsAura.ActiveTracers, {
        rail = rail,
        beam = beam,
        orb = orb,
        railCF = railCF,
        length = length,
        dist = 0,
        age = 0,
        duration = math.max(cfgT.Duration, length / cfgT.SpiralSpeed + 0.15),
    })
end

function RivalsAura.SpawnTracerFromCamera()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local cfgT = RivalsAura.Config.Tracers

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
    if RivalsAura.TracerFolder then table.insert(filter, RivalsAura.TracerFolder) end
    params.FilterDescendantsInstances = filter

    local camPos = cam.CFrame.Position
    local look = cam.CFrame.LookVector
    local result = Workspace:Raycast(camPos, look * cfgT.MaxDistance, params)
    local hitPos = result and result.Position or (camPos + look * cfgT.MaxDistance)

    RivalsAura.FireTracer(origin, hitPos, false)
end

function RivalsAura.HookGameTracers()
    if RivalsAura.TracerHooked then return end

    task.spawn(function()
        local tracerModule
        while not tracerModule do
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

        if tracerModule and typeof(tracerModule.Play) == "function" and not tracerModule._RivalsHooked then
            tracerModule._RivalsHooked = true
            local originalPlay = tracerModule.Play
            tracerModule.Play = function(self, p9, p10, p11)
                if RivalsAura.Config.Tracers.Enabled then
                    task.spawn(function()
                        local u12, _, u14 = self:VerifyTracerData(p9, p10, p11)
                        if u14 and u14.MuzzlePosition and u12 and u12.RaycastResults then
                            local isEnemy = u12.IsEnemy or false
                            for _, res in pairs(u12.RaycastResults) do
                                local startPos = res.StartPosition or u14.MuzzlePosition
                                local hitPos = res.Position
                                if startPos and hitPos then
                                    RivalsAura.FireTracer(startPos, hitPos, isEnemy)
                                end
                            end
                        end
                    end)
                end
                return originalPlay(self, p9, p10, p11)
            end
            RivalsAura.TracerHooked = true
        end
    end)

    table.insert(RivalsAura.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            RivalsAura.FiringHeld = true
        end
    end))

    table.insert(RivalsAura.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            RivalsAura.FiringHeld = false
        end
    end))
end

function RivalsAura.GetModelForPlayer(player: Player): Model?
    if FighterController and typeof(FighterController.GetFighter) == "function" then
        local ok, fighter = pcall(FighterController.GetFighter, FighterController, player)
        if ok and fighter and fighter.Entity and fighter.Entity.Model and fighter.Entity.Model.Parent then
            return fighter.Entity.Model
        end
    end
    if player.Character and player.Character.Parent then
        return player.Character
    end
    return nil
end

function RivalsAura.UpdatePlayer(player: Player)
    if not player then return end
    if player == LocalPlayer and not RivalsAura.Config.IncludeLocalPlayer then
        local oldModel = RivalsAura.GetModelForPlayer(player)
        if oldModel then
            RivalsAura.Remove(oldModel)
        end
        return
    end
    local targetModel = RivalsAura.GetModelForPlayer(player)
    if targetModel then
        RivalsAura.Apply(targetModel, RivalsAura.IsAlly(player))
    end
end

function RivalsAura.UpdateAll()
    for _, player in ipairs(Players:GetPlayers()) do
        RivalsAura.UpdatePlayer(player)
    end
    if FighterController and FighterController.Objects then
        for _, fighter in pairs(FighterController.Objects) do
            if fighter.Entity and fighter.Entity.Model and fighter.Entity.Model.Parent then
                local p = fighter.Player
                RivalsAura.Apply(fighter.Entity.Model, p and RivalsAura.IsAlly(p) or false)
            end
        end
    end
end

function RivalsAura.WatchFighter(fighter: any)
    if not fighter then return end
    local fConns = {}

    local function onEntity(entity: any)
        if not entity or not entity.Model then return end
        local m = entity.Model
        local hum = m:WaitForChild("Humanoid", 4)
        local rootPart = m:WaitForChild("HumanoidRootPart", 4)
        if not hum or not rootPart then return end
        task.wait(0.05)
        if not m.Parent then return end
        local p = fighter.Player
        if p == LocalPlayer and not RivalsAura.Config.IncludeLocalPlayer then
            return
        end
        RivalsAura.Apply(m, p and RivalsAura.IsAlly(p) or false)
    end

    if fighter.EntityAdded then
        table.insert(fConns, fighter.EntityAdded:Connect(onEntity))
    end
    if fighter.EntityRemoved then
        table.insert(fConns, fighter.EntityRemoved:Connect(function(entity)
            if entity and entity.Model then
                RivalsAura.Remove(entity.Model)
            end
        end))
    end
    if fighter.Entity and fighter.Entity.Model then
        task.spawn(onEntity, fighter.Entity)
    end

    return fConns
end

function RivalsAura.WatchPlayer(player: Player)
    if RivalsAura.PlayerConnections[player] then
        for _, conn in ipairs(RivalsAura.PlayerConnections[player]) do
            conn:Disconnect()
        end
    end

    local pConns = {}
    RivalsAura.PlayerConnections[player] = pConns

    local function handleCharacter(char: Model?)
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 5)
        local rootPart = char:WaitForChild("HumanoidRootPart", 5)
        if not hum or not rootPart then return end
        task.wait(0.05)
        if not char.Parent then return end
        if player == LocalPlayer and not RivalsAura.Config.IncludeLocalPlayer then
            return
        end
        RivalsAura.Apply(char, RivalsAura.IsAlly(player))

        local diedConn
        diedConn = hum.Died:Connect(function()
            if diedConn then diedConn:Disconnect() end
            RivalsAura.Remove(char)
        end)
        table.insert(pConns, diedConn)
    end

    table.insert(pConns, player.CharacterAdded:Connect(handleCharacter))
    table.insert(pConns, player.CharacterRemoving:Connect(function(char)
        RivalsAura.Remove(char)
    end))
    table.insert(pConns, player:GetAttributeChangedSignal("TeamID"):Connect(function()
        RivalsAura.UpdatePlayer(player)
    end))
    table.insert(pConns, player:GetPropertyChangedSignal("Team"):Connect(function()
        RivalsAura.UpdatePlayer(player)
    end))

    if player.Character and player.Character.Parent then
        task.spawn(handleCharacter, player.Character)
    end
end

function RivalsAura.UnwatchPlayer(player: Player)
    if RivalsAura.PlayerConnections[player] then
        for _, conn in ipairs(RivalsAura.PlayerConnections[player]) do
            conn:Disconnect()
        end
        RivalsAura.PlayerConnections[player] = nil
    end
    local m = RivalsAura.GetModelForPlayer(player)
    if m then
        RivalsAura.Remove(m)
    end
end

function RivalsAura.SetEnabled(state: boolean)
    RivalsAura.Config.Enabled = state
    if state then
        RivalsAura.UpdateAll()
    else
        for model in pairs(RivalsAura.Tracked) do
            RivalsAura.Remove(model)
        end
    end
end

function RivalsAura.Init()
    RivalsAura.HookGameTracers()

    for _, player in ipairs(Players:GetPlayers()) do
        RivalsAura.WatchPlayer(player)
    end

    table.insert(RivalsAura.Connections, Players.PlayerAdded:Connect(function(player)
        RivalsAura.WatchPlayer(player)
    end))
    table.insert(RivalsAura.Connections, Players.PlayerRemoving:Connect(function(player)
        RivalsAura.UnwatchPlayer(player)
    end))
    table.insert(RivalsAura.Connections, LocalPlayer:GetAttributeChangedSignal("TeamID"):Connect(function()
        RivalsAura.UpdateAll()
    end))
    table.insert(RivalsAura.Connections, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        RivalsAura.UpdateAll()
    end))

    if FighterController then
        if FighterController.Objects then
            for _, fighter in pairs(FighterController.Objects) do
                local conns = RivalsAura.WatchFighter(fighter)
                if conns then
                    for _, c in ipairs(conns) do
                        table.insert(RivalsAura.Connections, c)
                    end
                end
            end
        end
        if FighterController.ObjectAdded then
            table.insert(RivalsAura.Connections, FighterController.ObjectAdded:Connect(function(fighter)
                local conns = RivalsAura.WatchFighter(fighter)
                if conns then
                    for _, c in ipairs(conns) do
                        table.insert(RivalsAura.Connections, c)
                    end
                end
            end))
        end
    end

    local t = 0
    local lastTracerAt = 0
    table.insert(RivalsAura.Connections, RunService.RenderStepped:Connect(function(dt)
        t += dt
        local cfg = RivalsAura.Config

        if cfg.Enabled then
            for model, data in pairs(RivalsAura.Tracked) do
                if not model.Parent then
                    RivalsAura.Tracked[model] = nil
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

        local cfgT = cfg.Tracers
        if cfgT.Enabled then
            if cfgT.FallbackCameraRaycast and RivalsAura.FiringHeld and cfg.Enabled then
                if t - lastTracerAt >= cfgT.Interval then
                    lastTracerAt = t
                    RivalsAura.SpawnTracerFromCamera()
                end
            end

            for i = #RivalsAura.ActiveTracers, 1, -1 do
                local tr = RivalsAura.ActiveTracers[i]
                tr.age += dt

                if tr.age >= tr.duration or not tr.rail.Parent then
                    tr.rail:Destroy()
                    tr.orb:Destroy()
                    table.remove(RivalsAura.ActiveTracers, i)
                else
                    local fade = math.clamp(tr.age / tr.duration, 0, 1)
                    tr.beam.Transparency = NumberSequence.new(0.1 + 0.9 * fade * fade)

                    if tr.dist < tr.length then
                        tr.dist = math.min(tr.dist + cfgT.SpiralSpeed * dt, tr.length)
                        local spin = tr.dist * cfgT.SpiralTwist
                        tr.orb.CFrame = tr.railCF
                            * CFrame.new(0, 0, -tr.dist)
                            * CFrame.Angles(0, 0, spin)
                            * CFrame.new(cfgT.SpiralRadius, 0, 0)
                        if tr.dist >= tr.length then
                            tr.orb.Transparency = 1
                        end
                    end
                end
            end
        end
    end))

    local scanTimer = 0
    table.insert(RivalsAura.Connections, RunService.Heartbeat:Connect(function(dt)
        scanTimer += dt
        if scanTimer < 0.75 then return end
        scanTimer = 0
        if not RivalsAura.Config.Enabled then return end

        for _, player in ipairs(Players:GetPlayers()) do
            local m = RivalsAura.GetModelForPlayer(player)
            if m and m.Parent and not RivalsAura.Tracked[m] then
                if player ~= LocalPlayer or RivalsAura.Config.IncludeLocalPlayer then
                    RivalsAura.Apply(m, RivalsAura.IsAlly(player))
                end
            end
        end
    end))
end

function RivalsAura.Destroy()
    for _, conn in ipairs(RivalsAura.Connections) do
        conn:Disconnect()
    end
    table.clear(RivalsAura.Connections)

    for _, pConns in pairs(RivalsAura.PlayerConnections) do
        for _, conn in ipairs(pConns) do
            conn:Disconnect()
        end
    end
    table.clear(RivalsAura.PlayerConnections)
    table.clear(RivalsAura.Tracked)
    table.clear(RivalsAura.ActiveTracers)
    if RivalsAura.TracerFolder then
        RivalsAura.TracerFolder:Destroy()
        RivalsAura.TracerFolder = nil
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:GetAttribute(RivalsAura.Config.Tag) == true then
            obj:Destroy()
        end
    end

    if env.RivalsAura == RivalsAura then
        env.RivalsAura = nil
    end
end

if env.RivalsAura and typeof(env.RivalsAura.Destroy) == "function" then
    pcall(env.RivalsAura.Destroy)
end

env.RivalsAura = RivalsAura
RivalsAura.Init()

return RivalsAura
