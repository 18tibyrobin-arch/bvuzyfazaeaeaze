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
    local env = (typeof(getgenv) == "function" and getgenv()) or _G
    if env.LinoriaLib and typeof(env.LinoriaLib.Unload) == "function" then
        pcall(env.LinoriaLib.Unload)
        env.LinoriaLib = nil
    end

    local Library
    local ok, res = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
    end)
    if ok and res then
        Library = res
        env.LinoriaLib = Library
    else
        warn("[RivalsHub] Failed to load LinoriaLib UI library")
        return nil
    end

    local Window = Library:CreateWindow({
        Title = "RIVALS HUB",
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.1,
    })

    local esp = Config.Visuals.ESP
    local tr = Config.Visuals.Tracers

    local debouncedUpdateColors = createDebounced(function()
        if Aura and Aura.UpdateColors then
            Aura.UpdateColors(Config)
        end
    end, 0.04)

    local Tabs = {
        ESP = Window:AddTab("Aura ESP"),
        Tracers = Window:AddTab("Bullet Tracers"),
        Settings = Window:AddTab("Settings"),
    }

    -------------------------------------------------------------------
    -- TAB 1: Aura ESP
    -------------------------------------------------------------------
    local ESPBox = Tabs.ESP:AddLeftGroupbox("ESP Controls")

    ESPBox:AddToggle("AuraToggle", {
        Text = "Aura",
        Default = esp.Aura,
        Tooltip = "Toggle character aura visuals",
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

    ESPBox:AddToggle("ThroughWallsToggle", {
        Text = "Through Walls",
        Default = esp.ThroughWalls,
        Tooltip = "Show highlights through geometry (AlwaysOnTop vs Occluded)",
        Callback = function(value)
            esp.ThroughWalls = value
            if Aura and Aura.UpdateThroughWalls then
                Aura.UpdateThroughWalls(value)
            end
        end,
    })

    ESPBox:AddToggle("IncludeLocalToggle", {
        Text = "Include Local Player",
        Default = esp.IncludeLocal,
        Tooltip = "Render aura on your own character",
        Callback = function(value)
            esp.IncludeLocal = value
            if GameHook and GameHook.RefreshAuras then
                GameHook.RefreshAuras(Config, Aura)
            end
        end,
    })

    local ColorBox = Tabs.ESP:AddRightGroupbox("Color Palette")

    ColorBox:AddLabel("Local Color"):AddColorPicker("LocalColorPicker", {
        Default = esp.Colors.Local,
        Title = "Local Color",
        Callback = function(value)
            esp.Colors.Local = value
            debouncedUpdateColors()
        end,
    })

    ColorBox:AddLabel("Ally Color"):AddColorPicker("AllyColorPicker", {
        Default = esp.Colors.Ally,
        Title = "Ally Color",
        Callback = function(value)
            esp.Colors.Ally = value
            debouncedUpdateColors()
        end,
    })

    ColorBox:AddLabel("Enemy Color"):AddColorPicker("EnemyColorPicker", {
        Default = esp.Colors.Enemy,
        Title = "Enemy Color",
        Callback = function(value)
            esp.Colors.Enemy = value
            debouncedUpdateColors()
        end,
    })

    local ModBox = Tabs.ESP:AddLeftGroupbox("Customization")

    ModBox:AddToggle("AngelWingsToggle", {
        Text = "Angel Wings",
        Default = esp.UseWings,
        Tooltip = "Toggle flapping wings on self",
        Callback = function(value)
            esp.UseWings = value
            if GameHook and GameHook.RefreshAuras then
                GameHook.RefreshAuras(Config, Aura)
            end
        end,
    })

    ModBox:AddSlider("OrbCountSlider", {
        Text = "Orb Count",
        Default = esp.OrbCount,
        Min = 1,
        Max = 5,
        Rounding = 0,
        Suffix = " orbs",
        Callback = function(value)
            esp.OrbCount = math.floor(value)
            if GameHook and GameHook.RefreshAuras then
                GameHook.RefreshAuras(Config, Aura)
            end
        end,
    })

    ModBox:AddSlider("IntensitySlider", {
        Text = "Intensity",
        Default = esp.Intensity,
        Min = 0.5,
        Max = 2.5,
        Rounding = 1,
        Suffix = "x",
        Callback = function(value)
            esp.Intensity = value
            debouncedUpdateColors()
        end,
    })

    -------------------------------------------------------------------
    -- TAB 2: Bullet Tracers
    -------------------------------------------------------------------
    local TracerBox = Tabs.Tracers:AddLeftGroupbox("Bullet Tracers")

    TracerBox:AddToggle("TracersToggle", {
        Text = "Bullet Tracers",
        Default = tr.Enabled,
        Tooltip = "Hook real gunshots and render spiral tracers",
        Callback = function(value)
            tr.Enabled = value
            if not value and Tracers and Tracers.Cleanup then
                Tracers.Cleanup()
            end
        end,
    })

    TracerBox:AddToggle("FallbackRaycastToggle", {
        Text = "Click Fallback Raycast",
        Default = tr.FallbackCameraRaycast,
        Tooltip = "Fires a tracer on mouse click if gun effect isn't present",
        Callback = function(value)
            tr.FallbackCameraRaycast = value
        end,
    })

    TracerBox:AddSlider("DurationSlider", {
        Text = "Duration",
        Default = tr.Duration or 0.4,
        Min = 0.1,
        Max = 2.0,
        Rounding = 2,
        Suffix = "s",
        Callback = function(value)
            tr.Duration = value
        end,
    })

    local TracerColorBox = Tabs.Tracers:AddRightGroupbox("Colors & Dynamics")

    TracerColorBox:AddLabel("Friendly Color"):AddColorPicker("FriendlyColorPicker", {
        Default = tr.FriendlyColor,
        Title = "Friendly Color",
        Callback = function(value)
            tr.FriendlyColor = value
        end,
    })

    TracerColorBox:AddLabel("Enemy Color"):AddColorPicker("EnemyColorPicker", {
        Default = tr.EnemyColor,
        Title = "Enemy Color",
        Callback = function(value)
            tr.EnemyColor = value
        end,
    })

    TracerColorBox:AddSlider("SpiralSpeedSlider", {
        Text = "Spiral Speed",
        Default = tr.SpiralSpeed or 420,
        Min = 200,
        Max = 800,
        Rounding = 0,
        Suffix = " studs/s",
        Callback = function(value)
            tr.SpiralSpeed = math.floor(value)
        end,
    })

    TracerColorBox:AddSlider("SpiralRadiusSlider", {
        Text = "Spiral Radius",
        Default = tr.SpiralRadius or 0.32,
        Min = 0.1,
        Max = 0.8,
        Rounding = 2,
        Suffix = " studs",
        Callback = function(value)
            tr.SpiralRadius = value
        end,
    })

    -------------------------------------------------------------------
    -- TAB 3: Settings
    -------------------------------------------------------------------
    local MenuBox = Tabs.Settings:AddLeftGroupbox("Menu Settings")

    MenuBox:AddLabel("Toggle Keybind: RightShift / RightControl")

    MenuBox:AddButton({
        Text = "Unload Hub",
        Func = function()
            Library:Unload()
        end,
    })

    local InfoBox = Tabs.Settings:AddRightGroupbox("Diagnostics")
    InfoBox:AddLabel("Engine: Zero-Allocation Luau")
    InfoBox:AddLabel("Hooks: TracerEffect + FighterController")
    InfoBox:AddLabel("Status: Running at full FPS")

    Library:SetWatermark("RIVALS HUB | Zero-Lag Edition")
    Library:SetWatermarkVisibility(true)

    Library:OnUnload(function()
        if typeof(onUnload) == "function" then
            onUnload()
        end
    end)

    Library:Notify("Rivals Hub loaded successfully!", 3)

    Interface.Library = Library
    Interface.Window = Window
    return Interface
end

return Interface
