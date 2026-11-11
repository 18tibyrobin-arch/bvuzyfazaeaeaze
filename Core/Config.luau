local Config = {
    Tag = "RivalsHubV1",
    Visuals = {
        ESP = {
            Aura = true,
            ThroughWalls = true,
            IncludeLocal = true,
            Intensity = 1,
            UseOrbs = true,
            UseFlames = true,
            UseLight = true,
            UseWings = false,
            OrbCount = 3,
            OrbRadius = 2.3,
            OrbSpeed = 2.2,
            Colors = {
                Local = Color3.fromRGB(255, 255, 255),
                Ally = Color3.fromRGB(0, 255, 120),
                Enemy = Color3.fromRGB(170, 40, 255),
            }
        },
        Tracers = {
            Enabled = true,
            Duration = 0.4,
            FriendlyColor = Color3.fromRGB(150, 40, 255),
            EnemyColor = Color3.fromRGB(255, 60, 60),
            SpiralSpeed = 420,
            SpiralRadius = 0.32,
            SpiralTwist = 1.25,
            MaxDistance = 800,
            Interval = 0.11,
            FallbackCameraRaycast = true,
        }
    },
    Settings = {
        MenuKey = Enum.KeyCode.RightShift,
    }
}

return Config
