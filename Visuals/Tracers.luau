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
Tracers.MAX_ACTIVE = 24

local function getTracerFolder(tag: string): Folder
    if Tracers.Folder and Tracers.Folder.Parent then
        return Tracers.Folder
    end
    local f = Instance.new("Folder")
    f.Name = "RH_Tracers"
    f:SetAttribute(tag, true)
    f.Parent = Workspace
    Tracers.Folder = f
    return f
end

local function buildAttachment(name: string, parent: Instance, tag: string, offset: Vector3?): Attachment
    local att = Instance.new("Attachment")
    att.Name = name
    if offset then att.Position = offset end
    att:SetAttribute(tag, true)
    att.Parent = parent
    return att
end

function Tracers.FireTracer(origin: Vector3, hitPos: Vector3, isEnemy: boolean?, cfg: any, tag: string)
    local tCfg = cfg.Visuals.Tracers
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
    rail:SetAttribute(tag, true)
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
    beam.Width0 = 0.15
    beam.Width1 = 0.08
    beam.Color = ColorSequence.new(coreColor)
    beam.Transparency = NumberSequence.new(0.1)
    beam:SetAttribute(tag, true)
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
    orb:SetAttribute(tag, true)

    local orbMesh = Instance.new("SpecialMesh")
    orbMesh.MeshType = Enum.MeshType.Sphere
    orbMesh:SetAttribute(tag, true)
    orbMesh.Parent = orb
    orb.Parent = folder

    local ta0 = buildAttachment("RH_TrS0", orb, tag, Vector3.new(0, 0.1, 0))
    local ta1 = buildAttachment("RH_TrS1", orb, tag, Vector3.new(0, -0.1, 0))

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
    spiralTrail:SetAttribute(tag, true)
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

return Tracers
