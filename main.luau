--[[
    RIVALS HUB - Visuals
    Self-contained single-file bundle for executor loadstring execution.
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
-- Common Helpers
-------------------------------------------------------------------
local function tagInstance(inst: Instance): Instance
    inst:SetAttribute(Config.Tag, true)
    return inst
end

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

local function buildAttachment(name: string, parent: Instance, offset: Vector3?): Attachment
    local att = Instance.new("Attachment")
    att.Name = name
    if offset then att.Position = offset end
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
    local wingRoot = buildCosmeticPart("RH_WingRoot", Vector3.new(0.2, 0.2, 0.2), Color3.new(1, 1, 1), 1, character)
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
        local feather = buildCosmeticPart("RH_Feather", Vector3.new(0.14, len, width), Color3.new(1, 1, 1), 0.05, character)
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

-------------------------------------------------------------------
-- Aura System
-------------------------------------------------------------------
local Aura = {}
Aura.Tracked = {}

function Aura.Remove(character: Model?)
    if not character then return end
    Aura.Tracked[character] = nil
    for _, item in ipairs(character:GetDescendants()) do
        if item:GetAttribute(Config.Tag) == true then
            item:Destroy()
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

function Aura.Apply(character: Model, isAllyTeam: boolean)
    local espCfg = Config.Visuals.ESP
    if not espCfg.Aura or not character or not character.Parent then return end

    local isLocalChar = (character == LocalPlayer.Character)
    if isLocalChar and not espCfg.IncludeLocal then
        Aura.Remove(character)
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

    local h, s, v = mainColor:ToHSV()
    local brightColor = Color3.fromHSV(h, math.clamp(s * 0.5, 0, 1), math.clamp(v * 1.2, 0, 1))

    local mul = espCfg.Intensity or 1
    local zOff = isLocalChar and -1 or 0
    local fireTex = "rbxasset://textures/particles/fire_main.dds"

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

    local hl = Instance.new("Highlight")
    hl.Name = "RH_Highlight"
    hl.Adornee = character
    hl.DepthMode = espCfg.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    hl.FillColor = mainColor
    hl.FillTransparency = 0.75
    hl.OutlineColor = brightColor
    hl.OutlineTransparency = 0.1
    tagInstance(hl)
    hl.Parent = character
    data.highlight = hl

    if espCfg.UseOrbs then
        for i = 1, espCfg.OrbCount do
            local orb = buildCosmeticPart("RH_Orb" .. i, Vector3.new(0.65, 0.65, 0.65), brightColor, 0, character)
            orb.Anchored = true
            local orbMesh = Instance.new("SpecialMesh")
            orbMesh.MeshType = Enum.MeshType.Sphere
            tagInstance(orbMesh)
            orbMesh.Parent = orb

            local orbAtt = buildAttachment("RH_OrbGlow", orb)
            buildEmitter({
                Name = "RH_OrbFire",
                Texture = fireTex,
                Rate = 4 * mul,
                Lifetime = NumberRange.new(0.25, 0.3),
                Speed = NumberRange.new(0, 0),
                LightEmission = 1,
                Brightness = 1.6,
                Orientation = Enum.ParticleOrientation.FacingCamera,
                Size = NumberSequence.new({ kp(0, 1.2), kp(1, 0.4) }),
                Transparency = NumberSequence.new({ kp(0, 0.5), kp(1, 1) }),
                Color = ColorSequence.new(brightColor, mainColor),
            }, orbAtt)

            local ta0 = buildAttachment("RH_OrbT0", orb, Vector3.new(0, 0.3, 0))
            local ta1 = buildAttachment("RH_OrbT1", orb, Vector3.new(0, -0.3, 0))
            local orbTrail = Instance.new("Trail")
            orbTrail.Name = "RH_OrbTrail"
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
            orbTrail.Color = ColorSequence.new(brightColor, mainColor)
            orbTrail.Transparency = NumberSequence.new({ kp(0, 0.12), kp(0.6, 0.55), kp(1, 1) })
            tagInstance(orbTrail)
            orbTrail.Parent = orb

            table.insert(data.orbTrails, orbTrail)
            table.insert(data.orbs, orb)
        end
    end

    if isLocalChar and espCfg.UseWings then
        data.wingWelds = {
            buildWing(character, anchor, -1),
            buildWing(character, anchor, 1),
        }
    end

    if espCfg.UseFlames then
        local coreAtt = buildAttachment("RH_Core", anchor)

        buildEmitter({
            Name = "RH_CoreFire",
            Texture = fireTex,
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
                ColorSequenceKeypoint.new(0, brightColor),
                ColorSequenceKeypoint.new(0.45, mainColor),
                ColorSequenceKeypoint.new(1, mainColor),
            }),
        }, coreAtt)

        buildEmitter({
            Name = "RH_CoreFireInner",
            Texture = fireTex,
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
            Color = ColorSequence.new(brightColor, mainColor),
        }, coreAtt)

        for _, armName in ipairs({ "Left Arm", "Right Arm" }) do
            local arm = getLimb(character, armName)
            if arm then
                local fistAtt = buildAttachment("RH_Fist", arm, Vector3.new(0, -arm.Size.Y * 0.4, 0))
                buildEmitter({
                    Name = "RH_FistFire",
                    Texture = fireTex,
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
                    Color = ColorSequence.new(brightColor, mainColor),
                }, fistAtt)
            end
        end
    end

    if espCfg.UseLight then
        local lightAtt = buildAttachment("RH_LightAtt", anchor)
        local light = Instance.new("PointLight")
        light.Name = "RH_Light"
        light.Color = mainColor
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
    local espCfg = Config.Visuals.ESP
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
                        local ang = t * espCfg.OrbSpeed + phase + (i - 1) * (TAU / n)
                        orb.CFrame = CFrame.new(basePos)
                            * CFrame.Angles(0, ang, 0)
                            * CFrame.new(espCfg.OrbRadius, math.sin(t * 1.8 + i * 2.1) * 0.6, 0)
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

-------------------------------------------------------------------
-- Bullet Tracers System
-------------------------------------------------------------------
local Tracers = {}
Tracers.ActiveTracers = {}
Tracers.Folder = nil

local function getTracerFolder(): Folder
    if Tracers.Folder and Tracers.Folder.Parent then
        return Tracers.Folder
    end
    local f = Instance.new("Folder")
    f.Name = "RH_Tracers"
    tagInstance(f)
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
    tagInstance(rail)
    rail.Parent = folder

    local a0 = buildAttachment("RH_Tr0", rail, Vector3.new(0, 0, length / 2))
    local a1 = buildAttachment("RH_Tr1", rail, Vector3.new(0, 0, -length / 2))

    local beam = Instance.new("Beam")
    beam.Name = "RH_TracerBeam"
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
    orb.Name = "RH_TracerOrb"
    orb.Size = Vector3.new(0.22, 0.22, 0.22)
    orb.Material = Enum.Material.Neon
    orb.Color = spiralColor
    orb.Anchored = true
    orb.CanCollide = false
    orb.CanQuery = false
    orb.CanTouch = false
    orb.CastShadow = false
    orb.CFrame = railCF * CFrame.new(tCfg.SpiralRadius, 0, 0)
    tagInstance(orb)

    local orbMesh = Instance.new("SpecialMesh")
    orbMesh.MeshType = Enum.MeshType.Sphere
    tagInstance(orbMesh)
    orbMesh.Parent = orb
    orb.Parent = folder

    local ta0 = buildAttachment("RH_TrS0", orb, Vector3.new(0, 0.11, 0))
    local ta1 = buildAttachment("RH_TrS1", orb, Vector3.new(0, -0.11, 0))

    local spiralTrail = Instance.new("Trail")
    spiralTrail.Name = "RH_SpiralTrail"
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
            tr.rail:Destroy()
            tr.orb:Destroy()
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
    table.clear(Tracers.ActiveTracers)
    if Tracers.Folder then
        Tracers.Folder:Destroy()
        Tracers.Folder = nil
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:GetAttribute(Config.Tag) == true then
            obj:Destroy()
        end
    end
end

-------------------------------------------------------------------
-- Game Hook System (FighterController + TracerEffect Hook)
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

function GameHook.HookTracers()
    if GameHook.TracerHooked then return end

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

        if tracerModule and typeof(tracerModule.Play) == "function" and not tracerModule._RivalsHubHooked then
            tracerModule._RivalsHubHooked = true
            local originalPlay = tracerModule.Play
            tracerModule.Play = function(self, p9, p10, p11)
                if Config.Visuals.Tracers.Enabled then
                    task.spawn(function()
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
                end
                return originalPlay(self, p9, p10, p11)
            end
            GameHook.TracerHooked = true
        end
    end)
end

function GameHook.RefreshAuras()
    if not Config.Visuals.ESP.Aura then return end
    for _, p in ipairs(Players:GetPlayers()) do
        local isLocal = (p == LocalPlayer)
        if isLocal and not Config.Visuals.ESP.IncludeLocal then
            local oldModel = GameHook.GetModelForPlayer(p)
            if oldModel then
                Aura.Remove(oldModel)
            end
        else
            local m = GameHook.GetModelForPlayer(p)
            if m then
                Aura.Apply(m, GameHook.IsAlly(p))
            end
        end
    end
    local fc = GameHook.FighterController
    if fc and fc.Objects then
        for _, f in pairs(fc.Objects) do
            if f.Entity and f.Entity.Model and f.Entity.Model.Parent then
                local p = f.Player
                Aura.Apply(f.Entity.Model, p and GameHook.IsAlly(p) or false)
            end
        end
    end
end

function GameHook.Init()
    pcall(function()
        local controllers = LocalPlayer:WaitForChild("PlayerScripts", 4):WaitForChild("Controllers", 4)
        GameHook.FighterController = require(controllers:WaitForChild("FighterController", 4))
    end)

    GameHook.HookTracers()

    local function updatePlayer(player: Player)
        if not player or not Config.Visuals.ESP.Aura then return end
        local isLocal = (player == LocalPlayer)
        if isLocal and not Config.Visuals.ESP.IncludeLocal then
            local oldModel = GameHook.GetModelForPlayer(player)
            if oldModel then
                Aura.Remove(oldModel)
            end
            return
        end
        local m = GameHook.GetModelForPlayer(player)
        if m then
            Aura.Apply(m, GameHook.IsAlly(player))
        end
    end

    local function watchFighter(fighter: any)
        if not fighter then return end
        local conns = {}

        local function onEntity(entity: any)
            if not entity or not entity.Model then return end
            local m = entity.Model
            local hum = m:WaitForChild("Humanoid", 4)
            local root = m:WaitForChild("HumanoidRootPart", 4)
            if not hum or not root then return end
            task.wait(0.05)
            if not m.Parent then return end
            local p = fighter.Player
            if p == LocalPlayer and not Config.Visuals.ESP.IncludeLocal then
                return
            end
            Aura.Apply(m, p and GameHook.IsAlly(p) or false)
        end

        if fighter.EntityAdded then
            table.insert(conns, fighter.EntityAdded:Connect(onEntity))
        end
        if fighter.EntityRemoved then
            table.insert(conns, fighter.EntityRemoved:Connect(function(entity)
                if entity and entity.Model then
                    Aura.Remove(entity.Model)
                end
            end))
        end
        if fighter.Entity and fighter.Entity.Model then
            task.spawn(onEntity, fighter.Entity)
        end

        return conns
    end

    local function watchPlayer(player: Player)
        if GameHook.PlayerConnections[player] then
            for _, conn in ipairs(GameHook.PlayerConnections[player]) do
                conn:Disconnect()
            end
        end

        local pConns = {}
        GameHook.PlayerConnections[player] = pConns

        local function handleChar(char: Model?)
            if not char then return end
            local hum = char:WaitForChild("Humanoid", 5)
            local root = char:WaitForChild("HumanoidRootPart", 5)
            if not hum or not root then return end
            task.wait(0.05)
            if not char.Parent then return end
            if player == LocalPlayer and not Config.Visuals.ESP.IncludeLocal then
                return
            end
            Aura.Apply(char, GameHook.IsAlly(player))

            local diedConn
            diedConn = hum.Died:Connect(function()
                if diedConn then diedConn:Disconnect() end
                Aura.Remove(char)
            end)
            table.insert(pConns, diedConn)
        end

        table.insert(pConns, player.CharacterAdded:Connect(handleChar))
        table.insert(pConns, player.CharacterRemoving:Connect(function(char)
            Aura.Remove(char)
        end))
        table.insert(pConns, player:GetAttributeChangedSignal("TeamID"):Connect(function()
            updatePlayer(player)
        end))
        table.insert(pConns, player:GetPropertyChangedSignal("Team"):Connect(function()
            updatePlayer(player)
        end))

        if player.Character and player.Character.Parent then
            task.spawn(handleChar, player.Character)
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
        if fc.Objects then
            for _, fighter in pairs(fc.Objects) do
                local conns = watchFighter(fighter)
                if conns then
                    for _, c in ipairs(conns) do table.insert(GameHook.Connections, c) end
                end
            end
        end
        if fc.ObjectAdded then
            table.insert(GameHook.Connections, fc.ObjectAdded:Connect(function(fighter)
                local conns = watchFighter(fighter)
                if conns then
                    for _, c in ipairs(conns) do table.insert(GameHook.Connections, c) end
                end
            end))
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
        if scanTimer < 0.8 then return end
        scanTimer = 0
        if not Config.Visuals.ESP.Aura then return end

        for _, player in ipairs(Players:GetPlayers()) do
            local m = GameHook.GetModelForPlayer(player)
            if m and m.Parent and not Aura.Tracked[m] then
                if player ~= LocalPlayer or Config.Visuals.ESP.IncludeLocal then
                    Aura.Apply(m, GameHook.IsAlly(player))
                end
            end
        end
    end))
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
-- UI Initialization (Rayfield Framework)
-------------------------------------------------------------------
local function buildUI()
    local ok, Rayfield = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if not ok or not Rayfield then
        warn("[RivalsHub] Could not load Rayfield UI framework")
        return nil
    end

    local Window = Rayfield:CreateWindow({
        Name = "RIVALS HUB",
        LoadingTitle = "RIVALS HUB",
        LoadingSubtitle = "Visuals",
        ConfigurationSaving = {
            Enabled = false,
        },
        KeySystem = false,
    })

    local VisualsTab = Window:CreateTab("Visuals", 4483362458)

    VisualsTab:CreateSection("ESP")

    local esp = Config.Visuals.ESP

    VisualsTab:CreateToggle({
        Name = "Aura",
        CurrentValue = esp.Aura,
        Flag = "Aura",
        Callback = function(value)
            esp.Aura = value
            if value then
                GameHook.RefreshAuras()
            else
                for m in pairs(Aura.Tracked) do
                    Aura.Remove(m)
                end
            end
        end,
    })

    VisualsTab:CreateToggle({
        Name = "Through Walls",
        CurrentValue = esp.ThroughWalls,
        Flag = "ThroughWalls",
        Callback = function(value)
            esp.ThroughWalls = value
            Aura.UpdateThroughWalls(value)
        end,
    })

    VisualsTab:CreateColorPicker({
        Name = "Local Color",
        Color = esp.Colors.Local,
        Flag = "LocalColor",
        Callback = function(value)
            esp.Colors.Local = value
            if esp.Aura then GameHook.RefreshAuras() end
        end,
    })

    VisualsTab:CreateColorPicker({
        Name = "Ally Color",
        Color = esp.Colors.Ally,
        Flag = "AllyColor",
        Callback = function(value)
            esp.Colors.Ally = value
            if esp.Aura then GameHook.RefreshAuras() end
        end,
    })

    VisualsTab:CreateColorPicker({
        Name = "Enemy Color",
        Color = esp.Colors.Enemy,
        Flag = "EnemyColor",
        Callback = function(value)
            esp.Colors.Enemy = value
            if esp.Aura then GameHook.RefreshAuras() end
        end,
    })

    VisualsTab:CreateSection("Bullet Tracers")

    local tr = Config.Visuals.Tracers

    VisualsTab:CreateToggle({
        Name = "Tracers",
        CurrentValue = tr.Enabled,
        Flag = "Tracers",
        Callback = function(value)
            tr.Enabled = value
            if not value then
                Tracers.Cleanup()
            end
        end,
    })

    VisualsTab:CreateSlider({
        Name = "Duration",
        Range = {0.1, 2},
        Increment = 0.05,
        Suffix = "s",
        CurrentValue = tr.Duration or 0.4,
        Flag = "Duration",
        Callback = function(value)
            tr.Duration = value
        end,
    })

    VisualsTab:CreateColorPicker({
        Name = "Friendly Color",
        Color = tr.FriendlyColor,
        Flag = "FriendlyColor",
        Callback = function(value)
            tr.FriendlyColor = value
        end,
    })

    VisualsTab:CreateColorPicker({
        Name = "Enemy Color",
        Color = tr.EnemyColor,
        Flag = "EnemyColor",
        Callback = function(value)
            tr.EnemyColor = value
        end,
    })

    return {
        Rayfield = Rayfield,
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
    if App.UI and App.UI.Rayfield and App.UI.Rayfield.Destroy then
        pcall(App.UI.Rayfield.Destroy)
    end
    if env.RivalsHubInstance == App then
        env.RivalsHubInstance = nil
    end
end

env.RivalsHubInstance = App

GameHook.Init()
App.UI = buildUI()

return App
