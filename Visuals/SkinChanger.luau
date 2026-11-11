local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
end

local SkinChanger = {}
SkinChanger.Connections = {}
SkinChanger.Overrides = {} -- [weaponName] = { Skin = string, Wrap = string, Finisher = string }
SkinChanger.GlobalFinisher = "Default"
SkinChanger.AutoApply = true
SkinChanger.Hooked = false

local WrapController = nil
local PlayerDataController = nil
local PlayerDataUtility = nil
local FighterController = nil

local function getControllers()
    if not WrapController then
        pcall(function()
            local controllers = LocalPlayer:WaitForChild("PlayerScripts", 2):WaitForChild("Controllers", 2)
            WrapController = require(controllers:WaitForChild("WrapController", 2))
        end)
    end
    if not PlayerDataController then
        pcall(function()
            local controllers = LocalPlayer:WaitForChild("PlayerScripts", 2):WaitForChild("Controllers", 2)
            PlayerDataController = require(controllers:WaitForChild("PlayerDataController", 2))
        end)
    end
    if not PlayerDataUtility then
        pcall(function()
            local modules = ReplicatedStorage:WaitForChild("Modules", 2)
            PlayerDataUtility = require(modules:WaitForChild("PlayerDataUtility", 2))
        end)
    end
    if not FighterController then
        pcall(function()
            local controllers = LocalPlayer:WaitForChild("PlayerScripts", 2):WaitForChild("Controllers", 2)
            FighterController = require(controllers:WaitForChild("FighterController", 2))
        end)
    end
end

function SkinChanger.GetEquippedWeaponName(): string?
    getControllers()
    if FighterController and FighterController.LocalFighter then
        local lf = FighterController.LocalFighter
        if lf.Items then
            for _, item in pairs(lf.Items) do
                if typeof(item.IsMainItem) == "function" and item:IsMainItem() then
                    return item.Name
                end
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then return tool.Name end
    end
    return nil
end

function SkinChanger.ApplyWrapToModel(model: Instance, wrapName: string)
    if not model or not wrapName or wrapName == "Default" then return end
    getControllers()
    if not WrapController then return end

    pcall(function()
        local CosmeticLibrary = require(ReplicatedStorage.Modules.CosmeticLibrary)
        local cosData = CosmeticLibrary and CosmeticLibrary.Cosmetics and CosmeticLibrary.Cosmetics[wrapName]
        if not cosData then return end

        local wrappableParts = {}
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("BasePart") and desc:HasTag("Wrappable") then
                wrappableParts[desc] = {
                    WrapGroup = desc:GetAttribute("WrapGroup") or 1,
                    IgnoreMaterial = desc:GetAttribute("IgnoreMaterial"),
                    IgnoreTransparency = desc:GetAttribute("IgnoreTransparency")
                }
            end
        end
        if model:IsA("BasePart") and model:HasTag("Wrappable") then
            wrappableParts[model] = {
                WrapGroup = model:GetAttribute("WrapGroup") or 1,
                IgnoreMaterial = model:GetAttribute("IgnoreMaterial"),
                IgnoreTransparency = model:GetAttribute("IgnoreTransparency")
            }
        end

        local originalProps = WrapController:RecordOriginalWrapProperties(wrappableParts)
        WrapController:ApplyWrap(originalProps, { Name = wrapName, Inverted = false }, true)
    end)
end

function SkinChanger.ApplySkinToViewModel(viewModel: any, skinName: string)
    if not viewModel or not skinName or skinName == "Default" then return end
    pcall(function()
        local assets = LocalPlayer.PlayerScripts.Assets
        local viewModelsFolder = assets and assets:FindFirstChild("ViewModels")
        local skinAsset = viewModelsFolder and (viewModelsFolder:FindFirstChild(skinName, true))
        if skinAsset and viewModel.ItemModel then
            local currentVisual = viewModel.ItemModel:FindFirstChild("ItemVisual") or viewModel.ItemModel
            for _, child in ipairs(currentVisual:GetChildren()) do
                if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
                    child.Transparency = 1
                end
            end
            local clone = skinAsset:Clone()
            clone.Name = "SkinChanger_Visual"
            clone.Parent = currentVisual
            clone:PivotTo(currentVisual:GetPivot())
        end
    end)
end

function SkinChanger.Apply(weaponName: string, skinName: string?, wrapName: string?, finisherName: string?)
    if not weaponName then return end

    if not SkinChanger.Overrides[weaponName] then
        SkinChanger.Overrides[weaponName] = {}
    end

    if skinName then
        SkinChanger.Overrides[weaponName].Skin = skinName
    end
    if wrapName then
        SkinChanger.Overrides[weaponName].Wrap = wrapName
    end
    if finisherName then
        SkinChanger.Overrides[weaponName].Finisher = finisherName
        if finisherName ~= "Default" then
            SkinChanger.GlobalFinisher = finisherName
        end
    end

    -- 1) Try native server equip remote if available
    pcall(function()
        local equipRemote = ReplicatedStorage:FindFirstChild("Remotes")
            and ReplicatedStorage.Remotes:FindFirstChild("Data")
            and ReplicatedStorage.Remotes.Data:FindFirstChild("EquipCosmetic")

        if equipRemote then
            if skinName and skinName ~= "Default" then
                equipRemote:FireServer(weaponName, "Skin", skinName)
            end
            if wrapName and wrapName ~= "Default" then
                equipRemote:FireServer(weaponName, "Wrap", wrapName)
            end
            if finisherName and finisherName ~= "Default" then
                equipRemote:FireServer(weaponName, "Finisher", finisherName)
            end
        end
    end)

    -- 2) Client-side Realtime Application to Current Weapon
    pcall(function()
        getControllers()
        local currentWeapon = SkinChanger.GetEquippedWeaponName()
        if currentWeapon == weaponName or not currentWeapon then
            -- Apply to Workspace ViewModels
            local vmFolder = Workspace:FindFirstChild("ViewModels")
            if vmFolder then
                local firstPerson = vmFolder:FindFirstChild("FirstPerson")
                if firstPerson and wrapName and wrapName ~= "Default" then
                    SkinChanger.ApplyWrapToModel(firstPerson, wrapName)
                end
            end

            -- Apply to Fighter Items
            if FighterController and FighterController.LocalFighter and FighterController.LocalFighter.Items then
                for _, item in pairs(FighterController.LocalFighter.Items) do
                    if item.Name == weaponName or not currentWeapon then
                        if item.ViewModel then
                            if wrapName and wrapName ~= "Default" then
                                SkinChanger.ApplyWrapToModel(item.ViewModel.Model, wrapName)
                                if typeof(item.ViewModel._UpdateWrap) == "function" then
                                    pcall(item.ViewModel._UpdateWrap, item.ViewModel)
                                end
                            end
                            if skinName and skinName ~= "Default" then
                                SkinChanger.ApplySkinToViewModel(item.ViewModel, skinName)
                            end
                        end
                    end
                end
            end
        end
    end)
end

function SkinChanger.HookGame()
    if SkinChanger.Hooked then return end
    getControllers()

    -- 1) Hook PlayerDataUtility.GetWeaponData
    pcall(function()
        if PlayerDataUtility and typeof(PlayerDataUtility.GetWeaponData) == "function" and not PlayerDataUtility._SkinChangerHooked then
            PlayerDataUtility._SkinChangerHooked = true
            local origGetWeaponData = PlayerDataUtility.GetWeaponData
            PlayerDataUtility.GetWeaponData = function(self, playerData, wName)
                local v, i = origGetWeaponData(self, playerData, wName)
                local override = SkinChanger.Overrides[wName]
                if override then
                    if not v then
                        v = { Name = wName }
                    end
                    if override.Skin and override.Skin ~= "Default" then
                        v.Skin = { Name = override.Skin }
                    end
                    if override.Wrap and override.Wrap ~= "Default" then
                        v.Wrap = { Name = override.Wrap, Inverted = false }
                    end
                    if override.Finisher and override.Finisher ~= "Default" then
                        v.Finisher = { Name = override.Finisher }
                    end
                end
                return v, i
            end
        end
    end)

    -- 2) Watch local character and weapon switches
    table.insert(SkinChanger.Connections, RunService.Heartbeat:Connect(function()
        if not SkinChanger.AutoApply then return end
        local wName = SkinChanger.GetEquippedWeaponName()
        if wName and SkinChanger.Overrides[wName] then
            local ov = SkinChanger.Overrides[wName]
            if ov.Wrap and ov.Wrap ~= "Default" then
                local vmFolder = Workspace:FindFirstChild("ViewModels")
                local fp = vmFolder and vmFolder:FindFirstChild("FirstPerson")
                if fp and not fp:GetAttribute("SC_WrapApplied_" .. ov.Wrap) then
                    fp:SetAttribute("SC_WrapApplied_" .. ov.Wrap, true)
                    SkinChanger.ApplyWrapToModel(fp, ov.Wrap)
                end
            end
        end
    end))

    -- 3) Custom Finisher trigger on elimination
    pcall(function()
        local rep = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Replication")
        local elimRemote = rep and rep:FindFirstChild("Elimination")
        if elimRemote and elimRemote:IsA("RemoteEvent") then
            table.insert(SkinChanger.Connections, elimRemote.OnClientEvent:Connect(function(killerPlayer, victimPlayer, extraData)
                if killerPlayer == LocalPlayer and SkinChanger.GlobalFinisher ~= "Default" then
                    task.spawn(function()
                        pcall(function()
                            local finishersFolder = ReplicatedStorage.Modules:FindFirstChild("Finishers")
                            local finModule = finishersFolder and finishersFolder:FindFirstChild(SkinChanger.GlobalFinisher)
                            if finModule and finModule:IsA("ModuleScript") then
                                local finisher = require(finModule)
                                if typeof(finisher.Play) == "function" then
                                    finisher:Play(victimPlayer)
                                end
                            end
                        end)
                    end)
                end
            end))
        end
    end)

    SkinChanger.Hooked = true
end

function SkinChanger.Destroy()
    for _, conn in ipairs(SkinChanger.Connections) do
        conn:Disconnect()
    end
    table.clear(SkinChanger.Connections)
    table.clear(SkinChanger.Overrides)
    SkinChanger.Hooked = false
end

return SkinChanger
