local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat
        task.wait()
        LocalPlayer = Players.LocalPlayer
    until LocalPlayer
end

local kp = NumberSequenceKeypoint.new

local Tracers = {}
Tracers.ActiveTracers = {}
Tracers.Connections = {}
Tracers.FiringHeld = false
Tracers.Folder = nil
Tracers.Hooked = false

Tracers.Config = {
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
    Tag = "RivalsTracersV5",
}

local function tagInstance(inst: Instance): Instance
    inst:SetAttribute(Tracers.Config.Tag, true)
    return inst
end

local function getTracerFolder(): Folder
    if Tracers.Folder and Tracers.Folder.Parent then
        return Tracers.Folder
    end
    local f = Instance.new("Folder")
    f.Name = "RA_Tracers"
    tagInstance(f)
    f.Parent = Workspace
    Tracers.Folder = f
    return f
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

function Tracers.FireTracer(origin: Vector3, hitPos: Vector3, isEnemy: boolean?)
    local cfg = Tracers.Config
    if not cfg.Enabled then return end

    local dirVec = hitPos - origin
    local length = dirVec.Magnitude
    if length < 2 then return end

    local folder = getTracerFolder()
    local railCF = CFrame.lookAt(origin, hitPos)

    local coreColor = isEnemy and cfg.EnemyCore or cfg.Core
    local spiralColor = isEnemy and cfg.EnemySpiral or cfg.Spiral

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
    orb.CFrame = railCF * CFrame.new(cfg.SpiralRadius, 0, 0)
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

    table.insert(Tracers.ActiveTracers, {
        rail = rail,
        beam = beam,
        orb = orb,
        railCF = railCF,
        length = length,
        dist = 0,
        age = 0,
        duration = math.max(cfg.Duration, length / cfg.SpiralSpeed + 0.15),
    })
end

function Tracers.SpawnTracerFromCamera()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local cfg = Tracers.Config

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
    local result = Workspace:Raycast(camPos, look * cfg.MaxDistance, params)
    local hitPos = result and result.Position or (camPos + look * cfg.MaxDistance)

    Tracers.FireTracer(origin, hitPos, false)
end

function Tracers.Step(dt: number)
    local cfg = Tracers.Config
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
                tr.dist = math.min(tr.dist + cfg.SpiralSpeed * dt, tr.length)
                local spin = tr.dist * cfg.SpiralTwist
                tr.orb.CFrame = tr.railCF
                    * CFrame.new(0, 0, -tr.dist)
                    * CFrame.Angles(0, 0, spin)
                    * CFrame.new(cfg.SpiralRadius, 0, 0)
                if tr.dist >= tr.length then
                    tr.orb.Transparency = 1
                end
            end
        end
    end
end

function Tracers.HookGame()
    if Tracers.Hooked then return end

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
                if Tracers.Config.Enabled then
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
            Tracers.Hooked = true
        end
    end)

    table.insert(Tracers.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Tracers.FiringHeld = true
        end
    end))

    table.insert(Tracers.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Tracers.FiringHeld = false
        end
    end))
end

function Tracers.Cleanup()
    for _, conn in ipairs(Tracers.Connections) do
        conn:Disconnect()
    end
    table.clear(Tracers.Connections)
    table.clear(Tracers.ActiveTracers)
    Tracers.FiringHeld = false

    if Tracers.Folder then
        Tracers.Folder:Destroy()
        Tracers.Folder = nil
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:GetAttribute(Tracers.Config.Tag) == true then
            obj:Destroy()
        end
    end
end

return Tracers
