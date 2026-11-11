local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
end

local kp = NumberSequenceKeypoint.new

local Tracers = {}
Tracers.ActiveTracers = {}
Tracers.Folder = nil

local function tagInstance(inst: Instance, tag: string): Instance
    inst:SetAttribute(tag, true)
    return inst
end

local function getTracerFolder(tag: string): Folder
    if Tracers.Folder and Tracers.Folder.Parent then
        return Tracers.Folder
    end
    local f = Instance.new("Folder")
    f.Name = "RH_Tracers"
    tagInstance(f, tag)
    f.Parent = Workspace
    Tracers.Folder = f
    return f
end

local function buildAttachment(name: string, parent: Instance, tag: string, offset: Vector3?): Attachment
    local att = Instance.new("Attachment")
    att.Name = name
    if offset then
        att.Position = offset
    end
    tagInstance(att, tag)
    att.Parent = parent
    return att
end

function Tracers.FireTracer(origin: Vector3, hitPos: Vector3, isEnemy: boolean?, cfg: any, tag: string)
    local tCfg = cfg.Visuals.Tracers
    if not tCfg.Enabled then return end

    local dirVec = hitPos - origin
    local length = dirVec.Magnitude
    if length < 2 then return end

    local folder = getTracerFolder(tag)
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
    tagInstance(rail, tag)
    rail.Parent = folder

    local a0 = buildAttachment("RH_Tr0", rail, tag, Vector3.new(0, 0, length / 2))
    local a1 = buildAttachment("RH_Tr1", rail, tag, Vector3.new(0, 0, -length / 2))

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
    tagInstance(beam, tag)
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
    tagInstance(orb, tag)

    local orbMesh = Instance.new("SpecialMesh")
    orbMesh.MeshType = Enum.MeshType.Sphere
    tagInstance(orbMesh, tag)
    orbMesh.Parent = orb
    orb.Parent = folder

    local ta0 = buildAttachment("RH_TrS0", orb, tag, Vector3.new(0, 0.11, 0))
    local ta1 = buildAttachment("RH_TrS1", orb, tag, Vector3.new(0, -0.11, 0))

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
    tagInstance(spiralTrail, tag)
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

function Tracers.SpawnTracerFromCamera(cfg: any, tag: string)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local tCfg = cfg.Visuals.Tracers

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

    Tracers.FireTracer(origin, hitPos, false, cfg, tag)
end

function Tracers.Step(dt: number, cfg: any)
    local tCfg = cfg.Visuals.Tracers
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

function Tracers.Cleanup(tag: string)
    table.clear(Tracers.ActiveTracers)

    if Tracers.Folder then
        Tracers.Folder:Destroy()
        Tracers.Folder = nil
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:GetAttribute(tag) == true then
            obj:Destroy()
        end
    end
end

return Tracers
