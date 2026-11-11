local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
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
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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
        obj.Visible = false
        obj.Transparency = 1
        obj.ZIndex = 2
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
                Filled = props.Filled or false,
                Thickness = props.Thickness or 1,
                Transparency = 1,
                Remove = function(self)
                    if self._inst then self._inst:Destroy() end
                end
            }
        elseif drawType == "Line" then
            local frame = Instance.new("Frame")
            frame.BorderSizePixel = 0
            frame.AnchorPoint = Vector2.new(0, 0.5)
            frame.Visible = false
            frame.Parent = gui
            return {
                _inst = frame,
                Visible = false,
                From = Vector2.zero,
                To = Vector2.zero,
                Color = props.Color or Color3.new(1, 1, 1),
                Thickness = props.Thickness or 1,
                Transparency = 1,
                Remove = function(self)
                    if self._inst then self._inst:Destroy() end
                end
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
                Outline = props.Outline or false,
                Transparency = 1,
                Remove = function(self)
                    if self._inst then self._inst:Destroy() end
                end
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
        boxOutline = createDrawObject("Square", { Filled = false, Thickness = 3, Color = Color3.new(0, 0, 0), Visible = false, Transparency = 1 }),
        box = createDrawObject("Square", { Filled = false, Thickness = 1, Color = Color3.new(1, 1, 1), Visible = false, Transparency = 1 }),
        healthBg = createDrawObject("Line", { Thickness = 4, Color = Color3.new(0, 0, 0), Visible = false, Transparency = 1 }),
        healthBar = createDrawObject("Line", { Thickness = 2, Color = Color3.fromRGB(0, 255, 120), Visible = false, Transparency = 1 }),
        name = createDrawObject("Text", { Size = 13, Center = true, Outline = true, Color = Color3.new(1, 1, 1), Visible = false, Transparency = 1, ZIndex = 3 }),
        distance = createDrawObject("Text", { Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(200, 200, 200), Visible = false, Transparency = 1, ZIndex = 3 }),
        weapon = createDrawObject("Text", { Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(255, 220, 100), Visible = false, Transparency = 1, ZIndex = 3 }),
        skeleton = {},
    }

    for i = 1, 14 do
        table.insert(entry.skeleton, createDrawObject("Line", { Thickness = 1, Color = Color3.new(1, 1, 1), Visible = false, Transparency = 1 }))
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
            inst.BorderSizePixel = obj.Thickness or 1
        elseif drawType == "Line" then
            local diff = obj.To - obj.From
            local len = diff.Magnitude
            inst.Size = UDim2.fromOffset(len, obj.Thickness or 1)
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

function ESP2D.Step(camera: Camera, cfg: any, characters: {[Model]: {player: Player?, fighter: any?, isAlly: boolean, isLocal: boolean}})
    local espCfg = cfg.Visuals.ESP
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
        local root = model:FindFirstChild("HumanoidRootPart") or (info.fighter and info.fighter.Entity and info.fighter.Entity.RootPart)
        local head = model:FindFirstChild("Head") or (info.fighter and info.fighter.Entity and info.fighter.Entity.Head)
        local hum = model:FindFirstChildOfClass("Humanoid") or (info.fighter and info.fighter.Entity and info.fighter.Entity.Humanoid)

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

        -- 1) Bounding Box
        if espCfg.Box then
            local col = espCfg.BoxColor or defaultColor
            entry.boxOutline.Position = Vector2.new(boxX - 1, boxY - 1)
            entry.boxOutline.Size = Vector2.new(boxWidth + 2, boxHeight + 2)
            entry.boxOutline.Transparency = 1
            entry.boxOutline.Visible = true

            entry.box.Position = Vector2.new(boxX, boxY)
            entry.box.Size = Vector2.new(boxWidth, boxHeight)
            entry.box.Color = col
            entry.box.Transparency = 1
            entry.box.Visible = true
        else
            entry.boxOutline.Visible = false
            entry.box.Visible = false
        end

        -- 2) Health Bar
        if espCfg.Health then
            local health = 100
            local maxHealth = 100
            local f = info.fighter
            if f then
                if typeof(f.GetHealth) == "function" then
                    local ok, h = pcall(f.GetHealth, f)
                    if ok and typeof(h) == "number" then health = h end
                elseif typeof(f.Health) == "number" then
                    health = f.Health
                end
                if typeof(f.GetMaxHealth) == "function" then
                    local ok, mh = pcall(f.GetMaxHealth, f)
                    if ok and typeof(mh) == "number" and mh > 0 then maxHealth = mh end
                end
            end
            if health == 100 and hum then
                health = hum.Health
                maxHealth = (hum.MaxHealth and hum.MaxHealth > 0) and hum.MaxHealth or 100
            end

            local hpPct = math.clamp(health / maxHealth, 0, 1)
            local barX = boxX - 5
            local barTopY = boxY
            local barBottomY = boxY + boxHeight

            entry.healthBg.From = Vector2.new(barX, barTopY)
            entry.healthBg.To = Vector2.new(barX, barBottomY)
            entry.healthBg.Transparency = 1
            entry.healthBg.Visible = true

            local fillTopY = barBottomY - (boxHeight * hpPct)
            local hpColor = Color3.fromHSV(hpPct * 0.33, 1, 1)

            entry.healthBar.From = Vector2.new(barX, fillTopY)
            entry.healthBar.To = Vector2.new(barX, barBottomY)
            entry.healthBar.Color = hpColor
            entry.healthBar.Transparency = 1
            entry.healthBar.Visible = true
        else
            entry.healthBg.Visible = false
            entry.healthBar.Visible = false
        end

        -- 3) Player Name
        if espCfg.Name then
            local playerName = info.player and (info.player.DisplayName or info.player.Name) or model.Name
            entry.name.Text = playerName
            entry.name.Position = Vector2.new(topViewport.X, boxY - 15)
            entry.name.Color = espCfg.NameColor or defaultColor
            entry.name.Transparency = 1
            entry.name.Visible = true
        else
            entry.name.Visible = false
        end

        local textOffsetY = 2

        -- 4) Distance (in studs / meters)
        local distStuds = (camPos - rootPos).Magnitude
        if espCfg.Distance then
            entry.distance.Text = string.format("%d studs", math.floor(distStuds))
            entry.distance.Position = Vector2.new(topViewport.X, boxY + boxHeight + textOffsetY)
            entry.distance.Color = espCfg.DistanceColor or Color3.fromRGB(200, 200, 200)
            entry.distance.Transparency = 1
            entry.distance.Visible = true
            textOffsetY += 12
        else
            entry.distance.Visible = false
        end

        -- 5) Equipped Weapon & Ammo
        if espCfg.Weapon then
            local weaponText = "Hands"
            local f = info.fighter
            if f and f.Items then
                for _, item in pairs(f.Items) do
                    local isMain = false
                    if typeof(item.IsMainItem) == "function" then
                        local ok, m = pcall(item.IsMainItem, item)
                        isMain = ok and m
                    end
                    if isMain then
                        local wName = item.Name or "Weapon"
                        local ammoStr = nil
                        if typeof(item.GetAmmoVariables) == "function" then
                            local ok, cur, resAmmo, infClip = pcall(item.GetAmmoVariables, item)
                            if ok then
                                if infClip then
                                    ammoStr = "∞"
                                elseif typeof(cur) == "number" then
                                    ammoStr = tostring(cur)
                                end
                            end
                        end
                        weaponText = ammoStr and string.format("%s [%s]", wName, ammoStr) or wName
                        break
                    end
                end
            end
            if weaponText == "Hands" then
                local tool = model:FindFirstChildOfClass("Tool")
                if tool then
                    local ammo = tool:GetAttribute("Ammo") or tool:GetAttribute("Clip")
                    weaponText = ammo and string.format("%s [%s]", tool.Name, tostring(ammo)) or tool.Name
                end
            end

            entry.weapon.Text = weaponText
            entry.weapon.Position = Vector2.new(topViewport.X, boxY + boxHeight + textOffsetY)
            entry.weapon.Color = espCfg.WeaponColor or Color3.fromRGB(255, 220, 100)
            entry.weapon.Transparency = 1
            entry.weapon.Visible = true
        else
            entry.weapon.Visible = false
        end

        -- 6) Skeleton Joints
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
                            line.Transparency = 1
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

return ESP2D
