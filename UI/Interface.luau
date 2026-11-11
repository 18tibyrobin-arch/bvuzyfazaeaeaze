local Interface = {}

local Themes = {
    ["Default Dark"] = {
        AccentColor = Color3.fromRGB(0, 85, 255),
        MainColor = Color3.fromRGB(28, 28, 28),
        BackgroundColor = Color3.fromRGB(20, 20, 20),
        OutlineColor = Color3.fromRGB(50, 50, 50),
        FontColor = Color3.fromRGB(255, 255, 255),
    },
    ["Blood Crimson"] = {
        AccentColor = Color3.fromRGB(255, 40, 60),
        MainColor = Color3.fromRGB(26, 20, 22),
        BackgroundColor = Color3.fromRGB(18, 14, 15),
        OutlineColor = Color3.fromRGB(60, 30, 35),
        FontColor = Color3.fromRGB(255, 240, 240),
    },
    ["Toxic Emerald"] = {
        AccentColor = Color3.fromRGB(0, 230, 110),
        MainColor = Color3.fromRGB(20, 28, 24),
        BackgroundColor = Color3.fromRGB(14, 20, 16),
        OutlineColor = Color3.fromRGB(30, 55, 40),
        FontColor = Color3.fromRGB(240, 255, 245),
    },
    ["Cyberpunk Violet"] = {
        AccentColor = Color3.fromRGB(170, 50, 255),
        MainColor = Color3.fromRGB(25, 20, 32),
        BackgroundColor = Color3.fromRGB(16, 12, 22),
        OutlineColor = Color3.fromRGB(55, 35, 70),
        FontColor = Color3.fromRGB(250, 240, 255),
    },
    ["Midnight Sapphire"] = {
        AccentColor = Color3.fromRGB(0, 200, 255),
        MainColor = Color3.fromRGB(18, 24, 34),
        BackgroundColor = Color3.fromRGB(12, 16, 24),
        OutlineColor = Color3.fromRGB(35, 50, 70),
        FontColor = Color3.fromRGB(240, 250, 255),
    },
}

function Interface.Init(Config: any, Aura: any, Tracers: any, GameHook: any, Chams: any, onUnload: () -> ())
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
        AutoShow = false,
        TabPadding = 8,
        MenuFadeTime = 0.1,
    })

    local esp = Config.Visuals.ESP
    local tr = Config.Visuals.Tracers

    local function applyTheme(themeName: string)
        local t = Themes[themeName]
        if not t or not Library then return end
        Library.AccentColor = t.AccentColor
        Library.AccentColorDark = Library:GetDarkerColor(t.AccentColor)
        Library.MainColor = t.MainColor
        Library.BackgroundColor = t.BackgroundColor
        Library.OutlineColor = t.OutlineColor
        Library.FontColor = t.FontColor
        Library:UpdateColorsUsingRegistry()
    end

    local Tabs = {
        ESP = Window:AddTab("ESP"),
        Tracers = Window:AddTab("Bullet Tracers"),
        Settings = Window:AddTab("Settings"),
    }

    -------------------------------------------------------------------
    -- TAB 1: ESP (2D Overlay & 3D World Visuals)
    -------------------------------------------------------------------
    local OverlayBox = Tabs.ESP:AddLeftGroupbox("2D Overlay ESP")

    OverlayBox:AddToggle("BoxToggle", {
        Text = "Box ESP",
        Default = esp.Box,
        Tooltip = "Draw 2D bounding boxes around players",
        Callback = function(value)
            esp.Box = value
        end,
    }):AddColorPicker("BoxColorPicker", {
        Default = esp.BoxColor,
        Title = "Box Color",
        Callback = function(value)
            esp.BoxColor = value
        end,
    })

    OverlayBox:AddToggle("SkeletonToggle", {
        Text = "Skeleton ESP",
        Default = esp.Skeleton,
        Tooltip = "Draw real-time bone lines connecting player joints",
        Callback = function(value)
            esp.Skeleton = value
        end,
    }):AddColorPicker("SkeletonColorPicker", {
        Default = esp.SkeletonColor,
        Title = "Skeleton Color",
        Callback = function(value)
            esp.SkeletonColor = value
        end,
    })

    OverlayBox:AddToggle("NameToggle", {
        Text = "Name ESP",
        Default = esp.Name,
        Tooltip = "Display player name above character",
        Callback = function(value)
            esp.Name = value
        end,
    }):AddColorPicker("NameColorPicker", {
        Default = esp.NameColor,
        Title = "Name Color",
        Callback = function(value)
            esp.NameColor = value
        end,
    })

    OverlayBox:AddToggle("HealthToggle", {
        Text = "Health Bar",
        Default = esp.Health,
        Tooltip = "Render dynamic health bar on box side",
        Callback = function(value)
            esp.Health = value
        end,
    }):AddColorPicker("HealthColorPicker", {
        Default = esp.HealthColor,
        Title = "Health Bar Color",
        Callback = function(value)
            esp.HealthColor = value
        end,
    })

    OverlayBox:AddToggle("DistanceToggle", {
        Text = "Distance ESP",
        Default = esp.Distance,
        Tooltip = "Display distance in studs below player",
        Callback = function(value)
            esp.Distance = value
        end,
    }):AddColorPicker("DistanceColorPicker", {
        Default = esp.DistanceColor,
        Title = "Distance Color",
        Callback = function(value)
            esp.DistanceColor = value
        end,
    })

    OverlayBox:AddToggle("WeaponToggle", {
        Text = "Weapon & Ammo",
        Default = esp.Weapon,
        Tooltip = "Display equipped weapon and ammo counter",
        Callback = function(value)
            esp.Weapon = value
        end,
    }):AddColorPicker("WeaponColorPicker", {
        Default = esp.WeaponColor,
        Title = "Weapon Color",
        Callback = function(value)
            esp.WeaponColor = value
        end,
    })

    local WorldBox = Tabs.ESP:AddRightGroupbox("3D World ESP (Chams & Aura)")

    WorldBox:AddToggle("ChamsToggle", {
        Text = "Chams",
        Default = esp.Chams,
        Tooltip = "Render body highlight chams on players",
        Callback = function(value)
            esp.Chams = value
            if Chams and GameHook then
                GameHook.RefreshVisuals(Config, Aura, Chams)
            end
        end,
    }):AddColorPicker("ChamsColorPicker", {
        Default = esp.ChamsColor,
        Title = "Chams Color",
        Callback = function(value)
            esp.ChamsColor = value
            if Chams and GameHook then
                GameHook.RefreshVisuals(Config, Aura, Chams)
            end
        end,
    })

    WorldBox:AddToggle("ChamsThroughWallsToggle", {
        Text = "Chams Through Walls",
        Default = esp.ChamsThroughWalls,
        Tooltip = "Display chams through map geometry",
        Callback = function(value)
            esp.ChamsThroughWalls = value
            if Chams and GameHook then
                GameHook.RefreshVisuals(Config, Aura, Chams)
            end
        end,
    })

    WorldBox:AddToggle("AuraToggle", {
        Text = "Aura",
        Default = esp.Aura,
        Tooltip = "Render orbital orbs and flames aura",
        Callback = function(value)
            esp.Aura = value
            if Aura and Aura.SetVisible then
                Aura.SetVisible(value)
            end
            if value and GameHook then
                GameHook.RefreshVisuals(Config, Aura, Chams)
            end
        end,
    }):AddColorPicker("EnemyColorPicker", {
        Default = esp.Colors.Enemy,
        Title = "Enemy Aura Color",
        Callback = function(value)
            esp.Colors.Enemy = value
            if Aura and Aura.UpdateColors then
                Aura.UpdateColors(Config)
            end
        end,
    })

    WorldBox:AddToggle("AuraThroughWallsToggle", {
        Text = "Aura Through Walls",
        Default = esp.ThroughWalls,
        Tooltip = "Display aura highlights through walls",
        Callback = function(value)
            esp.ThroughWalls = value
            if Aura and Aura.UpdateThroughWalls then
                Aura.UpdateThroughWalls(value)
            end
        end,
    })

    WorldBox:AddToggle("IncludeLocalToggle", {
        Text = "Include Local Player",
        Default = esp.IncludeLocal,
        Tooltip = "Render visuals on your own character",
        Callback = function(value)
            esp.IncludeLocal = value
            if GameHook then
                GameHook.RefreshVisuals(Config, Aura, Chams)
            end
        end,
    })

    WorldBox:AddLabel("Ally Color"):AddColorPicker("AllyColorPicker", {
        Default = esp.Colors.Ally,
        Title = "Ally Color",
        Callback = function(value)
            esp.Colors.Ally = value
            if Aura and Aura.UpdateColors then
                Aura.UpdateColors(Config)
            end
            if Chams and GameHook then
                GameHook.RefreshVisuals(Config, Aura, Chams)
            end
        end,
    })

    WorldBox:AddLabel("Local Color"):AddColorPicker("LocalColorPicker", {
        Default = esp.Colors.Local,
        Title = "Local Color",
        Callback = function(value)
            esp.Colors.Local = value
            if Aura and Aura.UpdateColors then
                Aura.UpdateColors(Config)
            end
        end,
    })

    -------------------------------------------------------------------
    -- TAB 2: Bullet Tracers
    -------------------------------------------------------------------
    local TracerBox = Tabs.Tracers:AddLeftGroupbox("Bullet Tracers")

    TracerBox:AddToggle("TracersToggle", {
        Text = "Bullet Tracers",
        Default = tr.Enabled,
        Tooltip = "Hook gunshots and render spiral bullet beams",
        Callback = function(value)
            tr.Enabled = value
            if not value and Tracers and Tracers.Cleanup then
                Tracers.Cleanup()
            end
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

    local TracerColorBox = Tabs.Tracers:AddRightGroupbox("Tracer Colors")

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

    -------------------------------------------------------------------
    -- TAB 3: Settings
    -------------------------------------------------------------------
    local MenuBox = Tabs.Settings:AddLeftGroupbox("Menu Settings")

    local KeyLabel = MenuBox:AddLabel("Menu Keybind")
    KeyLabel:AddKeyPicker("MenuKeyPicker", {
        Default = "RightShift",
        NoUI = false,
        Text = "Menu Keybind",
        Callback = function()
        end,
    })
    Library.ToggleKeybind = Library.Options and Library.Options.MenuKeyPicker

    MenuBox:AddDropdown("ThemeDropdown", {
        Values = { "Default Dark", "Blood Crimson", "Toxic Emerald", "Cyberpunk Violet", "Midnight Sapphire" },
        Default = 1,
        Multi = false,
        Text = "UI Theme",
        Tooltip = "Select menu color scheme",
        Callback = function(value)
            Config.Settings.Theme = value
            applyTheme(value)
        end,
    })

    MenuBox:AddToggle("WatermarkToggle", {
        Text = "Show Watermark",
        Default = Config.Settings.ShowWatermark,
        Tooltip = "Toggle screen watermark display",
        Callback = function(value)
            Config.Settings.ShowWatermark = value
            Library:SetWatermarkVisibility(value)
        end,
    })

    Library:SetWatermark("RIVALS HUB | Zero-Lag")
    Library:SetWatermarkVisibility(Config.Settings.ShowWatermark)

    Library:OnUnload(function()
        if typeof(onUnload) == "function" then
            onUnload()
        end
    end)

    Library:Notify("Rivals Hub loaded (Press RightShift to show menu)", 4)

    Interface.Library = Library
    Interface.Window = Window
    return Interface
end

return Interface
