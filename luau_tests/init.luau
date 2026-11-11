local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat
        task.wait()
        LocalPlayer = Players.LocalPlayer
    until LocalPlayer
end

local env = (typeof(getgenv) == "function" and getgenv()) or _G

local currentScript = ...
local scriptFolder = typeof(currentScript) == "Instance" and currentScript.Parent or nil

local Aura = nil
local Tracers = nil

pcall(function()
    if scriptFolder then
        Aura = require(scriptFolder:WaitForChild("aura"))
        Tracers = require(scriptFolder:WaitForChild("tracers"))
    end
end)

if not Aura or not Tracers then
    local okAura, resAura = pcall(function()
        return loadfile("luau_tests/aura.luau")()
    end)
    if okAura and resAura then Aura = resAura end

    local okTr, resTr = pcall(function()
        return loadfile("luau_tests/tracers.luau")()
    end)
    if okTr and resTr then Tracers = resTr end
end

local FighterController
pcall(function()
    local controllers = LocalPlayer:WaitForChild("PlayerScripts", 5):WaitForChild("Controllers", 5)
    FighterController = require(controllers:WaitForChild("FighterController", 5))
end)

local RivalsVisuals = {}
RivalsVisuals.Aura = Aura
RivalsVisuals.Tracers = Tracers
RivalsVisuals.Connections = {}
RivalsVisuals.PlayerConnections = {}

function RivalsVisuals.IsAlly(player: Player?): boolean
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

function RivalsVisuals.GetModelForPlayer(player: Player): Model?
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

function RivalsVisuals.UpdatePlayer(player: Player)
    if not player or not Aura then return end
    if player == LocalPlayer and not Aura.Config.IncludeLocalPlayer then
        local oldModel = RivalsVisuals.GetModelForPlayer(player)
        if oldModel then
            Aura.Remove(oldModel)
        end
        return
    end
    local targetModel = RivalsVisuals.GetModelForPlayer(player)
    if targetModel then
        Aura.Apply(targetModel, RivalsVisuals.IsAlly(player))
    end
end

function RivalsVisuals.UpdateAll()
    if not Aura then return end
    for _, player in ipairs(Players:GetPlayers()) do
        RivalsVisuals.UpdatePlayer(player)
    end
    if FighterController and FighterController.Objects then
        for _, fighter in pairs(FighterController.Objects) do
            if fighter.Entity and fighter.Entity.Model and fighter.Entity.Model.Parent then
                local p = fighter.Player
                Aura.Apply(fighter.Entity.Model, p and RivalsVisuals.IsAlly(p) or false)
            end
        end
    end
end

function RivalsVisuals.WatchFighter(fighter: any)
    if not fighter or not Aura then return end
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
        if p == LocalPlayer and not Aura.Config.IncludeLocalPlayer then
            return
        end
        Aura.Apply(m, p and RivalsVisuals.IsAlly(p) or false)
    end

    if fighter.EntityAdded then
        table.insert(fConns, fighter.EntityAdded:Connect(onEntity))
    end
    if fighter.EntityRemoved then
        table.insert(fConns, fighter.EntityRemoved:Connect(function(entity)
            if entity and entity.Model then
                Aura.Remove(entity.Model)
            end
        end))
    end
    if fighter.Entity and fighter.Entity.Model then
        task.spawn(onEntity, fighter.Entity)
    end

    return fConns
end

function RivalsVisuals.WatchPlayer(player: Player)
    if RivalsVisuals.PlayerConnections[player] then
        for _, conn in ipairs(RivalsVisuals.PlayerConnections[player]) do
            conn:Disconnect()
        end
    end

    local pConns = {}
    RivalsVisuals.PlayerConnections[player] = pConns

    local function handleCharacter(char: Model?)
        if not char or not Aura then return end
        local hum = char:WaitForChild("Humanoid", 5)
        local rootPart = char:WaitForChild("HumanoidRootPart", 5)
        if not hum or not rootPart then return end
        task.wait(0.05)
        if not char.Parent then return end
        if player == LocalPlayer and not Aura.Config.IncludeLocalPlayer then
            return
        end
        Aura.Apply(char, RivalsVisuals.IsAlly(player))

        local diedConn
        diedConn = hum.Died:Connect(function()
            if diedConn then diedConn:Disconnect() end
            Aura.Remove(char)
        end)
        table.insert(pConns, diedConn)
    end

    table.insert(pConns, player.CharacterAdded:Connect(handleCharacter))
    table.insert(pConns, player.CharacterRemoving:Connect(function(char)
        if Aura then Aura.Remove(char) end
    end))
    table.insert(pConns, player:GetAttributeChangedSignal("TeamID"):Connect(function()
        RivalsVisuals.UpdatePlayer(player)
    end))
    table.insert(pConns, player:GetPropertyChangedSignal("Team"):Connect(function()
        RivalsVisuals.UpdatePlayer(player)
    end))

    if player.Character and player.Character.Parent then
        task.spawn(handleCharacter, player.Character)
    end
end

function RivalsVisuals.UnwatchPlayer(player: Player)
    if RivalsVisuals.PlayerConnections[player] then
        for _, conn in ipairs(RivalsVisuals.PlayerConnections[player]) do
            conn:Disconnect()
        end
        RivalsVisuals.PlayerConnections[player] = nil
    end
    local m = RivalsVisuals.GetModelForPlayer(player)
    if m and Aura then
        Aura.Remove(m)
    end
end

function RivalsVisuals.Init()
    if Tracers then
        Tracers.HookGame()
    end

    for _, player in ipairs(Players:GetPlayers()) do
        RivalsVisuals.WatchPlayer(player)
    end

    table.insert(RivalsVisuals.Connections, Players.PlayerAdded:Connect(function(player)
        RivalsVisuals.WatchPlayer(player)
    end))

    table.insert(RivalsVisuals.Connections, Players.PlayerRemoving:Connect(function(player)
        RivalsVisuals.UnwatchPlayer(player)
    end))

    table.insert(RivalsVisuals.Connections, LocalPlayer:GetAttributeChangedSignal("TeamID"):Connect(function()
        RivalsVisuals.UpdateAll()
    end))

    table.insert(RivalsVisuals.Connections, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        RivalsVisuals.UpdateAll()
    end))

    if FighterController then
        if FighterController.Objects then
            for _, fighter in pairs(FighterController.Objects) do
                local conns = RivalsVisuals.WatchFighter(fighter)
                if conns then
                    for _, c in ipairs(conns) do
                        table.insert(RivalsVisuals.Connections, c)
                    end
                end
            end
        end
        if FighterController.ObjectAdded then
            table.insert(RivalsVisuals.Connections, FighterController.ObjectAdded:Connect(function(fighter)
                local conns = RivalsVisuals.WatchFighter(fighter)
                if conns then
                    for _, c in ipairs(conns) do
                        table.insert(RivalsVisuals.Connections, c)
                    end
                end
            end))
        end
    end

    local t = 0
    local lastTracerAt = 0
    table.insert(RivalsVisuals.Connections, RunService.RenderStepped:Connect(function(dt)
        t += dt
        if Aura and Aura.Config.Enabled then
            Aura.Step(t, dt)
        end

        if Tracers and Tracers.Config.Enabled then
            if Tracers.Config.FallbackCameraRaycast and Tracers.FiringHeld then
                if t - lastTracerAt >= Tracers.Config.Interval then
                    lastTracerAt = t
                    Tracers.SpawnTracerFromCamera()
                end
            end
            Tracers.Step(dt)
        end
    end))

    local scanTimer = 0
    table.insert(RivalsVisuals.Connections, RunService.Heartbeat:Connect(function(dt)
        scanTimer += dt
        if scanTimer < 0.75 then return end
        scanTimer = 0
        if not Aura or not Aura.Config.Enabled then return end

        for _, player in ipairs(Players:GetPlayers()) do
            local m = RivalsVisuals.GetModelForPlayer(player)
            if m and m.Parent and not Aura.Tracked[m] then
                if player ~= LocalPlayer or Aura.Config.IncludeLocalPlayer then
                    Aura.Apply(m, RivalsVisuals.IsAlly(player))
                end
            end
        end
    end))
end

function RivalsVisuals.Destroy()
    for _, conn in ipairs(RivalsVisuals.Connections) do
        conn:Disconnect()
    end
    table.clear(RivalsVisuals.Connections)

    for _, pConns in pairs(RivalsVisuals.PlayerConnections) do
        for _, conn in ipairs(pConns) do
            conn:Disconnect()
        end
    end
    table.clear(RivalsVisuals.PlayerConnections)

    if Aura then
        for model in pairs(Aura.Tracked) do
            Aura.Remove(model)
        end
        table.clear(Aura.Tracked)
    end

    if Tracers then
        Tracers.Cleanup()
    end

    if env.RivalsVisuals == RivalsVisuals then
        env.RivalsVisuals = nil
    end
end

if env.RivalsVisuals and typeof(env.RivalsVisuals.Destroy) == "function" then
    pcall(env.RivalsVisuals.Destroy)
end

env.RivalsVisuals = RivalsVisuals
RivalsVisuals.Init()

return RivalsVisuals
