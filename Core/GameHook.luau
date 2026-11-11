local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
end

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

function GameHook.HookTracers(Config: any, Tracers: any)
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
                                    Tracers.FireTracer(startPos, hitPos, isEnemy, Config, Config.Tag)
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

function GameHook.Init(Config: any, Aura: any, Tracers: any)
    pcall(function()
        local controllers = LocalPlayer:WaitForChild("PlayerScripts", 4):WaitForChild("Controllers", 4)
        GameHook.FighterController = require(controllers:WaitForChild("FighterController", 4))
    end)

    GameHook.HookTracers(Config, Tracers)

    local function updatePlayer(player: Player)
        if not player or not Aura then return end
        local isLocal = (player == LocalPlayer)
        if isLocal and not Config.Visuals.ESP.IncludeLocal then
            local oldModel = GameHook.GetModelForPlayer(player)
            if oldModel then
                Aura.Remove(oldModel, Config.Tag)
            end
            return
        end
        local m = GameHook.GetModelForPlayer(player)
        if m then
            Aura.Apply(m, GameHook.IsAlly(player), Config, Config.Tag)
        end
    end

    local function watchFighter(fighter: any)
        if not fighter or not Aura then return end
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
            Aura.Apply(m, p and GameHook.IsAlly(p) or false, Config, Config.Tag)
        end

        if fighter.EntityAdded then
            table.insert(conns, fighter.EntityAdded:Connect(onEntity))
        end
        if fighter.EntityRemoved then
            table.insert(conns, fighter.EntityRemoved:Connect(function(entity)
                if entity and entity.Model then
                    Aura.Remove(entity.Model, Config.Tag)
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
            if not char or not Aura then return end
            local hum = char:WaitForChild("Humanoid", 5)
            local root = char:WaitForChild("HumanoidRootPart", 5)
            if not hum or not root then return end
            task.wait(0.05)
            if not char.Parent then return end
            if player == LocalPlayer and not Config.Visuals.ESP.IncludeLocal then
                return
            end
            Aura.Apply(char, GameHook.IsAlly(player), Config, Config.Tag)

            local diedConn
            diedConn = hum.Died:Connect(function()
                if diedConn then diedConn:Disconnect() end
                Aura.Remove(char, Config.Tag)
            end)
            table.insert(pConns, diedConn)
        end

        table.insert(pConns, player.CharacterAdded:Connect(handleChar))
        table.insert(pConns, player.CharacterRemoving:Connect(function(char)
            if Aura then Aura.Remove(char, Config.Tag) end
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
        if m and Aura then
            Aura.Remove(m, Config.Tag)
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        watchPlayer(p)
    end

    table.insert(GameHook.Connections, Players.PlayerAdded:Connect(watchPlayer))
    table.insert(GameHook.Connections, Players.PlayerRemoving:Connect(unwatchPlayer))

    local function refreshAll()
        for _, p in ipairs(Players:GetPlayers()) do
            updatePlayer(p)
        end
        local fc = GameHook.FighterController
        if fc and fc.Objects then
            for _, f in pairs(fc.Objects) do
                if f.Entity and f.Entity.Model and f.Entity.Model.Parent then
                    local p = f.Player
                    Aura.Apply(f.Entity.Model, p and GameHook.IsAlly(p) or false, Config, Config.Tag)
                end
            end
        end
    end
    GameHook.RefreshAuras = refreshAll

    table.insert(GameHook.Connections, LocalPlayer:GetAttributeChangedSignal("TeamID"):Connect(refreshAll))
    table.insert(GameHook.Connections, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(refreshAll))

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
        if Aura and Config.Visuals.ESP.Aura then
            Aura.Step(t, dt, Config)
        end

        if Tracers and Config.Visuals.Tracers.Enabled then
            if Config.Visuals.Tracers.FallbackCameraRaycast and GameHook.FiringHeld then
                if t - lastTracerAt >= (Config.Visuals.Tracers.Interval or 0.11) then
                    lastTracerAt = t
                    Tracers.SpawnTracerFromCamera(Config, Config.Tag)
                end
            end
            Tracers.Step(dt, Config)
        end
    end))

    local scanTimer = 0
    table.insert(GameHook.Connections, RunService.Heartbeat:Connect(function(dt)
        scanTimer += dt
        if scanTimer < 0.8 then return end
        scanTimer = 0
        if not Aura or not Config.Visuals.ESP.Aura then return end

        for _, player in ipairs(Players:GetPlayers()) do
            local m = GameHook.GetModelForPlayer(player)
            if m and m.Parent and not Aura.Tracked[m] then
                if player ~= LocalPlayer or Config.Visuals.ESP.IncludeLocal then
                    Aura.Apply(m, GameHook.IsAlly(player), Config, Config.Tag)
                end
            end
        end
    end))
end

function GameHook.Destroy(Config: any, Aura: any, Tracers: any)
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

    if Aura then
        for model in pairs(Aura.Tracked) do
            Aura.Remove(model, Config.Tag)
        end
        table.clear(Aura.Tracked)
    end

    if Tracers then
        Tracers.Cleanup(Config.Tag)
    end
end

return GameHook
