local Interface = {}

local function createDebounced(fn, delay)
    local last = 0
    local pending = false
    return function(...)
        local args = {...}
        local now = os.clock()
        if now - last >= delay then
            last = now
            fn(table.unpack(args))
        elseif not pending then
            pending = true
            task.delay(delay, function()
                pending = false
                last = os.clock()
                fn(table.unpack(args))
            end)
        end
    end
end

function Interface.Init(Config: any, Aura: any, Tracers: any, GameHook: any, onUnload: () -> ())
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
        LoadingSubtitle = "Visuals Client",
        ConfigurationSaving = {
            Enabled = false,
        },
        KeySystem = false,
    })

    local esp = Config.Visuals.ESP
    local tr = Config.Visuals.Tracers

    local debouncedUpdateColors = createDebounced(function()
        if Aura and Aura.UpdateColors then
            Aura.UpdateColors(Config)
        end
    end, 0.04)

    -- TAB 1: Aura ESP (Side Navigation)
    local ESPTab = Window:CreateTab("Aura ESP", 4483362458)

    ESPTab:CreateSection("ESP")

    ESPTab:CreateToggle({
        Name = "Aura",
        CurrentValue = esp.Aura,
        Flag = "AuraToggle",
        Callback = function(value)
            esp.Aura = value
            if Aura and Aura.SetVisible then
                Aura.SetVisible(value)
            end
            if value and GameHook and GameHook.RefreshAuras then
                GameHook.RefreshAuras(Config, Aura)
            end
        end,
    })

    ESPTab:CreateToggle({
        Name = "Through Walls",
        CurrentValue = esp.ThroughWalls,
        Flag = "ThroughWallsToggle",
        Callback = function(value)
            esp.ThroughWalls = value
            if Aura and Aura.UpdateThroughWalls then
                Aura.UpdateThroughWalls(value)
            end
        end,
    })

    ESPTab:CreateToggle({
        Name = "Include Local Player",
        CurrentValue = esp.IncludeLocal,
        Flag = "IncludeLocalToggle",
        Callback = function(value)
            esp.IncludeLocal = value
            if GameHook and GameHook.RefreshAuras then
                GameHook.RefreshAuras(Config, Aura)
            end
        end,
    })

    ESPTab:CreateSection("Colors")

    ESPTab:CreateColorPicker({
        Name = "Local Color",
        Color = esp.Colors.Local,
        Flag = "LocalColorPicker",
        Callback = function(value)
            esp.Colors.Local = value
            debouncedUpdateColors()
        end,
    })

    ESPTab:CreateColorPicker({
        Name = "Ally Color",
        Color = esp.Colors.Ally,
        Flag = "AllyColorPicker",
        Callback = function(value)
            esp.Colors.Ally = value
            debouncedUpdateColors()
        end,
    })

    ESPTab:CreateColorPicker({
        Name = "Enemy Color",
        Color = esp.Colors.Enemy,
        Flag = "EnemyColorPicker",
        Callback = function(value)
            esp.Colors.Enemy = value
            debouncedUpdateColors()
        end,
    })

    ESPTab:CreateSection("Modifiers")

    ESPTab:CreateToggle({
        Name = "Angel Wings",
        CurrentValue = esp.UseWings,
        Flag = "AngelWingsToggle",
        Callback = function(value)
            esp.UseWings = value
            if GameHook and GameHook.RefreshAuras then
                GameHook.RefreshAuras(Config, Aura)
            end
        end,
    })

    ESPTab:CreateSlider({
        Name = "Orb Count",
        Range = {1, 5},
        Increment = 1,
        Suffix = "orbs",
        CurrentValue = esp.OrbCount,
        Flag = "OrbCountSlider",
        Callback = function(value)
            esp.OrbCount = value
            if GameHook and GameHook.RefreshAuras then
                GameHook.RefreshAuras(Config, Aura)
            end
        end,
    })

    ESPTab:CreateSlider({
        Name = "Intensity",
        Range = {0.5, 2.5},
        Increment = 0.1,
        Suffix = "x",
        CurrentValue = esp.Intensity,
        Flag = "IntensitySlider",
        Callback = function(value)
            esp.Intensity = value
            debouncedUpdateColors()
        end,
    })

    -- TAB 2: Bullet Tracers (Side Navigation)
    local TracersTab = Window:CreateTab("Bullet Tracers", 4483362458)

    TracersTab:CreateSection("Bullet Tracers")

    TracersTab:CreateToggle({
        Name = "Tracers",
        CurrentValue = tr.Enabled,
        Flag = "TracersToggle",
        Callback = function(value)
            tr.Enabled = value
            if not value and Tracers and Tracers.Cleanup then
                Tracers.Cleanup()
            end
        end,
    })

    TracersTab:CreateToggle({
        Name = "Fallback Click Raycast",
        CurrentValue = tr.FallbackCameraRaycast,
        Flag = "FallbackRaycastToggle",
        Callback = function(value)
            tr.FallbackCameraRaycast = value
        end,
    })

    TracersTab:CreateSlider({
        Name = "Duration",
        Range = {0.1, 2.0},
        Increment = 0.05,
        Suffix = "s",
        CurrentValue = tr.Duration or 0.4,
        Flag = "DurationSlider",
        Callback = function(value)
            tr.Duration = value
        end,
    })

    TracersTab:CreateSection("Colors")

    TracersTab:CreateColorPicker({
        Name = "Friendly Color",
        Color = tr.FriendlyColor,
        Flag = "FriendlyColorPicker",
        Callback = function(value)
            tr.FriendlyColor = value
        end,
    })

    TracersTab:CreateColorPicker({
        Name = "Enemy Color",
        Color = tr.EnemyColor,
        Flag = "EnemyColorPicker",
        Callback = function(value)
            tr.EnemyColor = value
        end,
    })

    TracersTab:CreateSection("Spiral Physics")

    TracersTab:CreateSlider({
        Name = "Spiral Speed",
        Range = {200, 800},
        Increment = 20,
        Suffix = "studs/s",
        CurrentValue = tr.SpiralSpeed or 420,
        Flag = "SpiralSpeedSlider",
        Callback = function(value)
            tr.SpiralSpeed = value
        end,
    })

    TracersTab:CreateSlider({
        Name = "Spiral Radius",
        Range = {0.1, 0.8},
        Increment = 0.02,
        Suffix = "studs",
        CurrentValue = tr.SpiralRadius or 0.32,
        Flag = "SpiralRadiusSlider",
        Callback = function(value)
            tr.SpiralRadius = value
        end,
    })

    -- TAB 3: Settings (Side Navigation)
    local SettingsTab = Window:CreateTab("Settings", 4483362458)

    SettingsTab:CreateSection("Interface")

    SettingsTab:CreateKeybind({
        Name = "Toggle Menu Key",
        CurrentKeybind = "RightShift",
        HoldToInteract = false,
        Flag = "MenuKeybind",
        Callback = function(Keybind)
            -- Handled natively by Rayfield or custom bind
        end,
    })

    SettingsTab:CreateButton({
        Name = "Unload Hub",
        Callback = function()
            if typeof(onUnload) == "function" then
                onUnload()
            end
        end,
    })

    SettingsTab:CreateSection("Diagnostics")

    SettingsTab:CreateParagraph({
        Title = "Rivals Visuals Client",
        Content = "Optimized zero-allocation rendering engine.\nHooks: TracerEffect (Weapons) + FighterController (Duels).",
    })

    Interface.Rayfield = Rayfield
    Interface.Window = Window
    return Interface
end

return Interface
