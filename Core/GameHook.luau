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

function GameHook.RefreshAuras(Config: any, Aura: any)
    if not Config.Visuals.ESP.Aura then
        Aura.SetVisible(false)
        return
    end

    Aura.SetVisible(true)
    local chars = GameHook.GetUniqueCharacters()

    for m, info in pairs(chars) do
        if info.isLocal and not Config.Visuals.ESP.IncludeLocal then
            Aura.Remove(m)
        else
            if not Aura.Tracked[m] then
                Aura.Apply(m, info.isAlly, Config, Config.Tag)
            end
        end
    end

    for m in pairs(Aura.Tracked) do
        if not chars[m] then
            Aura.Remove(m)
        end
    end

    Aura.UpdateColors(Config)
    Aura.UpdateThroughWalls(Config.Visuals.ESP.ThroughWalls)
end

function GameHook.HookTracers(Config: any, Tracers: any)
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
                                        Tracers.FireTracer(startPos, hitPos, isEnemy, Config, Config.Tag)
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

function GameHook.Init(Config: any, Aura: any, Tracers: any)
    pcall(function()
        local controllers = LocalPlayer:WaitForChild("PlayerScripts", 4):WaitForChild("Controllers", 4)
        GameHook.FighterController = require(controllers:WaitForChild("FighterController", 4))
    end)

    GameHook.HookTracers(Config, Tracers)

    local function onCharacterModel(m: Model?, isAlly: boolean, isLocal: boolean)
        if not m or not m.Parent or not Config.Visuals.ESP.Aura then return end
        if isLocal and not Config.Visuals.ESP.IncludeLocal then return end
        local hum = m:WaitForChild("Humanoid", 3)
        local root = m:WaitForChild("HumanoidRootPart", 3)
        if not hum or not root then return end
        task.wait(0.04)
        if not m.Parent then return end
        Aura.Apply(m, isAlly, Config, Config.Tag)
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
        end))
        table.insert(pConns, player:GetAttributeChangedSignal("TeamID"):Connect(function()
            GameHook.RefreshAuras(Config, Aura)
        end))
        table.insert(pConns, player:GetPropertyChangedSignal("Team"):Connect(function()
            GameHook.RefreshAuras(Config, Aura)
        end))

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
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        watchPlayer(p)
    end

    table.insert(GameHook.Connections, Players.PlayerAdded:Connect(watchPlayer))
    table.insert(GameHook.Connections, Players.PlayerRemoving:Connect(unwatchPlayer))
    table.insert(GameHook.Connections, LocalPlayer:GetAttributeChangedSignal("TeamID"):Connect(function()
        GameHook.RefreshAuras(Config, Aura)
    end))
    table.insert(GameHook.Connections, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        GameHook.RefreshAuras(Config, Aura)
    end))

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
            Aura.Step(t, dt, Config)
        end

        if Config.Visuals.Tracers.Enabled then
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
        if scanTimer < 1.5 then return end
        scanTimer = 0
        if not Config.Visuals.ESP.Aura then return end

        local chars = GameHook.GetUniqueCharacters()
        for m, info in pairs(chars) do
            if not Aura.Tracked[m] then
                if not info.isLocal or Config.Visuals.ESP.IncludeLocal then
                    Aura.Apply(m, info.isAlly, Config, Config.Tag)
                end
            end
        end
    end))

    GameHook.RefreshAuras(Config, Aura)
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
            Aura.Remove(model)
        end
        table.clear(Aura.Tracked)
    end

    if Tracers then
        Tracers.Cleanup()
    end
end

return GameHook
