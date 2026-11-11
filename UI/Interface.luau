local Interface = {}

function Interface.Init(Config: any, Aura: any, Tracers: any, GameHook: any)
    local Rayfield
    local ok, res = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and res then
        Rayfield = res
    else
        warn("[RivalsHub] Failed to load Rayfield UI framework")
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
                if GameHook and GameHook.RefreshAuras then
                    GameHook.RefreshAuras()
                end
            else
                if Aura then
                    for m in pairs(Aura.Tracked) do
                        Aura.Remove(m, Config.Tag)
                    end
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
            if Aura and Aura.UpdateThroughWalls then
                Aura.UpdateThroughWalls(value)
            end
        end,
    })

    VisualsTab:CreateColorPicker({
        Name = "Local Color",
        Color = esp.Colors.Local,
        Flag = "LocalColor",
        Callback = function(value)
            esp.Colors.Local = value
            if esp.Aura and GameHook and GameHook.RefreshAuras then
                GameHook.RefreshAuras()
            end
        end,
    })

    VisualsTab:CreateColorPicker({
        Name = "Ally Color",
        Color = esp.Colors.Ally,
        Flag = "AllyColor",
        Callback = function(value)
            esp.Colors.Ally = value
            if esp.Aura and GameHook and GameHook.RefreshAuras then
                GameHook.RefreshAuras()
            end
        end,
    })

    VisualsTab:CreateColorPicker({
        Name = "Enemy Color",
        Color = esp.Colors.Enemy,
        Flag = "EnemyColor",
        Callback = function(value)
            esp.Colors.Enemy = value
            if esp.Aura and GameHook and GameHook.RefreshAuras then
                GameHook.RefreshAuras()
            end
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
            if not value and Tracers and Tracers.Cleanup then
                Tracers.Cleanup(Config.Tag)
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

    Interface.Rayfield = Rayfield
    Interface.Window = Window
    return Interface
end

return Interface
