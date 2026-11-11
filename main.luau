--[[
    RIVALS HUB | Professional Standalone Visuals & Skin Changer Client
    Self-Contained Single-Script Release
    Powered by LinoriaLib
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
end

local env = (typeof(getgenv) == "function" and getgenv()) or _G
if env.RivalsHubInstance and typeof(env.RivalsHubInstance.Destroy) == "function" then
    pcall(env.RivalsHubInstance.Destroy)
    env.RivalsHubInstance = nil
end

local TAU = math.pi * 2
local kp = NumberSequenceKeypoint.new


---------------------------------------------------------------------
-- CONFIGURATION
---------------------------------------------------------------------
local Config = {
    Tag = "RivalsHubV1",
    Visuals = {
        ESP = {
            -- 2D Drawing Overlay
            Box = false,
            BoxColor = Color3.fromRGB(255, 255, 255),
            Skeleton = false,
            SkeletonColor = Color3.fromRGB(255, 255, 255),
            Name = false,
            NameColor = Color3.fromRGB(255, 255, 255),
            Health = false,
            HealthColor = Color3.fromRGB(0, 255, 120),
            Distance = false,
            DistanceColor = Color3.fromRGB(200, 200, 200),
            Weapon = false,
            WeaponColor = Color3.fromRGB(255, 220, 100),

            -- 3D Chams
            Chams = false,
            ChamsThroughWalls = true,
            ChamsColor = Color3.fromRGB(255, 60, 60),

            -- 3D Aura
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
        },
        SkinChanger = {
            Enabled = true,
            SelectedWeapon = "Assault Rifle",
            SelectedSkin = "Default",
            SelectedWrap = "Default",
            SelectedFinisher = "Default",
            AutoApply = true,
        }
    },
    Settings = {
        Theme = "Default Dark",
        ShowWatermark = true,
    }
}

---------------------------------------------------------------------
-- CATALOG & COSMETICS DATA
---------------------------------------------------------------------
local SkinData = {}
SkinData.Weapons = {
    "Assault Rifle",
    "Battle Axe",
    "Bow",
    "Burst Rifle",
    "Chainsaw",
    "Crossbow",
    "Daggers",
    "Distortion",
    "Elixir",
    "Energy Pistols",
    "Energy Rifle",
    "Exogun",
    "Fists",
    "Flamethrower",
    "Flare Gun",
    "Flashbang",
    "Freeze Ray",
    "Glass Cannon",
    "Glast Shard",
    "Grappler",
    "Grenade",
    "Grenade Launcher",
    "Gunblade",
    "Handgun",
    "Jump Pad",
    "Katana",
    "Knife",
    "Maul",
    "Medkit",
    "Minigun",
    "Molotov",
    "Paintball Gun",
    "Permafrost",
    "RNG Dice",
    "RPG",
    "Revolver",
    "Riot Shield",
    "Satchel",
    "Scepter",
    "Scythe",
    "Shorty",
    "Shotgun",
    "Slingshot",
    "Smoke Grenade",
    "Sniper",
    "Spear",
    "Spray",
    "Subspace Tripmine",
    "Trowel",
    "Uzi",
    "War Horn",
    "Warper",
    "Warpstone",
    "Wildcat",
}

SkinData.SkinsByWeapon = {
    ["Assault Rifle"] = { "Default", "10B Visits", "AK-47", "AKEY-47", "Augmented Rifle", "Boneclaw Rifle", "Drum Gun", "Gingerbread Augmented Rifle", "Glorious Assault Rifle", "Pearl Rifle", "Phoenix Rifle" },
    ["Battle Axe"] = { "Default", "Balloon Axe", "Ban Axe", "Cerulean Axe", "Glorious Battle Axe", "Keyttle Axe", "Mimic Axe", "Nordic Axe", "Street Sign", "The Shred", "Tiki Axe" },
    ["Bow"] = { "Default", "Balloon Bow", "Bat Bow", "Beloved Bow", "Compound Bow", "Dream Bow", "Frostbite Bow", "Glorious Bow", "Key Bow", "Palm Bow", "Raven Bow" },
    ["Burst Rifle"] = { "Default", "Aqua Burst", "Bullpup Burst", "Electro Rifle", "Glorious Burst Rifle", "Keyst Rifle", "Pine Burst", "Pixel Burst", "Sand Bullpup Burst", "Spectral Burst" },
    ["Chainsaw"] = { "Default", "Blobsaw", "Buzzsaw", "Festive Buzzsaw", "Glorious Chainsaw", "Handsaws", "Mega Drill", "Sharksaw" },
    ["Crossbow"] = { "Default", "Arch Crossbow", "Campfire Crossbow", "Crossbone", "Frostbite Crossbow", "Glorious Crossbow", "Harpoon Crossbow", "Pixel Crossbow", "Spider Crossbow", "Violin Crossbow" },
    ["Daggers"] = { "Default", "Aces", "Bat Daggers", "Broken Hearts", "Cookies", "Crystal Daggers", "Cursed Daggers", "Glorious Daggers", "Keynais", "Paper Planes", "Shurikens", "Starfish", "Toaster" },
    ["Distortion"] = { "Default", "Bubble Distortion", "Cyber Distortion", "Electropunk Distortion", "Experiment D15", "Glorious Distortion", "Magma Distortion", "Plasma Distortion", "Sleighstortion" },
    ["Energy Pistols"] = { "Default", "Apex Pistols", "Enerkey Pistols", "Glorious Energy Pistols", "Hacker Pistols", "Hydro Pistols", "Hyperlaser Guns", "New Year Energy Pistols", "Sol Pistols", "Soul Pistols", "Void Pistols" },
    ["Energy Rifle"] = { "Default", "Apex Rifle", "Enerkey Rifle", "Glorious Energy Rifle", "Hacker Rifle", "Hydro Rifle", "New Year Energy Rifle", "Sol Rifle", "Soul Rifle", "Void Rifle" },
    ["Exogun"] = { "Default", "Exogourd", "Glorious Exogun", "Midnight Festive Exogun", "Pearl Exogun", "Ray Gun", "Repulsor", "Singularity", "Wondergun" },
    ["Fists"] = { "Default", "Boxing Gloves", "Brass Knuckles", "Crab Claws", "Festive Fists", "Fist", "Fists of Hurt", "Glorious Fists", "Pirate Hook", "Pumpkin Claws", "Spy Gloves", "Towerstone Fists" },
    ["Flamethrower"] = { "Default", "Bubblethrower", "Extinguisher", "Glitterthrower", "Glorious Flamethrower", "Jack O' Lantern", "Keythrower", "Lamethrower", "Pixel Flamethrower", "Rainbowthrower", "Snowblower" },
    ["Flare Gun"] = { "Default", "Banana Flare", "Dynamite Gun", "Firework Gun", "Glorious Flare Gun", "Pocket Volcano", "Vexed Flare Gun", "Wrapped Flare Gun" },
    ["Flashbang"] = { "Default", "Camera", "Disco Ball", "Glorious Flashbang", "Lightbulb", "Pixel Flashbang", "Shining Star", "Skullbang", "Sol" },
    ["Freeze Ray"] = { "Default", "Bubble Ray", "Cooler", "Glorious Freeze Ray", "Gum Ray", "Spider Ray", "Temporal Ray", "Wrapped Freeze Ray" },
    ["Grappler"] = { "Default", "Arcade Claw", "Fishing Rod", "Genie Lamp", "Glorious Grappler", "Lasso", "Lifeguard Grappler", "Web Shooters" },
    ["Grenade"] = { "Default", "Batnade", "Cuddle Bomb", "Dynamite", "Fizz Bomb", "Frozen Grenade", "Glorious Grenade", "Jingle Grenade", "Keynade", "Soul Grenade", "Water Balloon", "Whoopee Cushion" },
    ["Grenade Launcher"] = { "Default", "Balloon Launcher", "Coconut Launcher", "Gearnade Launcher", "Glorious Grenade Launcher", "Skull Launcher", "Snowball Launcher", "Swashbuckler", "Uranium Launcher" },
    ["Gunblade"] = { "Default", "Batblade", "Boneblade", "Crude Gunblade", "Elf Blade", "Glorious Gunblade", "Gunsaw", "Hyper Gunblade", "Keyblade", "Sharkbite" },
    ["Handgun"] = { "Default", "Blaster", "Gingerbread Handgun", "Glorious Handgun", "Gumball Handgun", "Hand Gun", "Pixel Handgun", "Pumpkin Handgun", "Sandgun", "Stealth Handgun", "Towerstone Handgun", "Warp Handgun" },
    ["Jump Pad"] = { "Default", "Bounce House", "Flamingo Floatie", "Glorious Jump Pad", "Jolly Man", "Shady Chicken Sandwich", "Spider Web", "Trampoline" },
    ["Katana"] = { "Default", "Arch Katana", "Crystal Katana", "Cutlass", "Evil Trident", "Glorious Katana", "Keytana", "Lightning Bolt", "Linked Sword", "New Year Katana", "Pixel Katana", "Riptide Katana", "Saber", "Stellar Katana", "Swordfish" },
    ["Knife"] = { "Default", "Armature.001", "Balisong", "Birthday Candle", "Caladbolg", "Candy Cane", "Chancla", "Glorious Knife", "Karambat", "Karambit", "Keylisong", "Keyrambit", "Machete", "Pencil", "Shark Tooth", "Trophy Knife" },
    ["MISSING_WEAPON"] = { "Default" },
    ["Maul"] = { "Default", "Ban Hammer", "Clown Hammer", "Excalibur", "Giant Popsicle", "Glorious Maul", "Ice Maul", "Jeremiah", "Sleigh Maul", "Starforge Maul" },
    ["Medkit"] = { "Default", "Box of Chocolates", "Briefcase", "Bucket of Candy", "Glorious Medkit", "Ice Cream", "Laptop", "Medkitty", "Milk & Cookies", "Sandwich" },
    ["Minigun"] = { "Default", "Fighter Jet", "Glorious Minigun", "Lasergun 3000", "Pixel Minigun", "Pumpkin Minigun", "Shark Minigun", "Wrapped Minigun" },
    ["Molotov"] = { "Default", "Arch Molotov", "Campfire Stick", "Coffee", "Glorious Molotov", "Hot Coals", "Lava Lamp", "Ship In A Bottle", "Torch", "Vexed Candle" },
    ["Paintball Gun"] = { "Default", "Boba Gun", "Brain Gun", "Glorious Paintball Gun", "Ketchup Gun", "Lemonade Gun", "Paintballoon Gun", "Slime Gun", "Snowball Gun" },
    ["Permafrost"] = { "Default", "Glorious Permafrost", "Ice Permafrost", "Permafrost.rbxm", "Permasand", "Snowman Permafrost", "Starforge Permafrost", "Temporal Permafrost", "Xenofrost" },
    ["RPG"] = { "Default", "Cupcake Launcher", "Firework Launcher", "Glorious RPG", "Nuke Launcher", "Pencil Launcher", "Pumpkin Launcher", "RPKEY", "Rocket Launcher", "Spaceship Launcher", "Squid Launcher", "Sundae Launcher" },
    ["Revolver"] = { "Default", "Boneclaw Revolver", "Cruise Revolver", "Desert Eagle", "Glorious Revolver", "Keyvolver", "Peppergun", "Peppermint Sheriff", "Sheriff" },
    ["Riot Shield"] = { "Default", "Broken Surfboard", "Door", "Energy Shield", "Glorious Riot Shield", "Masterpiece", "Sled", "Tombstone Shield" },
    ["Satchel"] = { "Default", "Advanced Satchel", "Bag o' Bones", "Glorious Satchel", "Lifeguard Satchel", "Notebook Satchel", "Pizza Box", "Potion Satchel", "Suspicious Gift" },
    ["Scythe"] = { "Default", "Anchor", "Bat Scythe", "Bug Net", "Cryo Scythe", "Crystal Scythe", "Glorious Scythe", "Keythe", "Palm Scythe", "Plastic Flamingo", "Sakura Scythe", "Scythe of Death" },
    ["Shorty"] = { "Default", "Balloon Shorty", "Bubble Shorty", "Cannon Shorty", "Demon Shorty", "Glorious Shorty", "Lovely Shorty", "Not So Shorty", "Too Shorty", "Wrapped Shorty" },
    ["Shotgun"] = { "Default", "Balloon Shotgun", "Broomstick", "Cactus Shotgun", "Glorious Shotgun", "Hyper Shotgun", "Shark Shotgun", "Shotkey", "Wrapped Shotgun" },
    ["Slingshot"] = { "Default", "Boneshot", "Glorious Slingshot", "Goalpost", "Harp", "Keyshot", "Lucky Horseshoe", "Palmshot", "Reindeer Slingshot", "Slingshotula", "Stick" },
    ["Smoke Grenade"] = { "Default", "Balance", "Beach Ball", "Emoji Cloud", "Eyeball", "Glorious Smoke Grenade", "Hourglass", "Snowglobe" },
    ["Sniper"] = { "Default", "Campfire Sniper", "Event Horizon", "Eyething Sniper", "Gingerbread Sniper", "Glorious Sniper", "Hyper Sniper", "Keyper", "Kraken Sniper", "Light Fifty", "Pixel Sniper" },
    ["Spear"] = { "Default", "Chark Kebab", "Fork", "Giant Pencil", "Glorious Spear", "Gravelight", "Plunger", "Studio Light", "Thunderpike" },
    ["Spray"] = { "Default", "Boneclaw Spray", "Campfire Spray", "Glorious Spray", "Key Spray", "Lovely Spray", "Nail Gun", "Pine Spray", "Spray Bottle" },
    ["Subspace Tripmine"] = { "Default", "DIY Tripmine", "Dev-in-the-Box", "Don't Touch", "Glorious Subspace Tripmine", "Hazard Sign", "Pot o' Gold", "Spring", "Trick or Treat" },
    ["Trowel"] = { "Default", "Garden Shovel", "Glorious Trowel", "Paintbrush", "Plastic Shovel", "Pumpkin Carver", "Scooper", "Snow Shovel" },
    ["Uzi"] = { "Default", "Arch Uzi", "Demon Uzi", "Ducky Uzi", "Electro Uzi", "Glorious Uzi", "Keyzi", "Money Gun", "Pine Uzi", "Water Uzi" },
    ["War Horn"] = { "Default", "Air Horn", "Boneclaw Horn", "Glorious War Horn", "Lifeguard Whistle", "Mammoth Horn", "Megaphone", "Trumpet" },
    ["Warper"] = { "Default", "Arcane Warper", "Bubbler", "Electropunk Warper", "Experiment W4", "Frost Warper", "Glitter Warper", "Glorious Warper", "Hotel Bell" },
    ["Warpstone"] = { "Default", "Cyber Warpstone", "Electropunk Warpstone", "Glorious Warpstone", "Teleport Disc", "Unstable Warpstone", "Warp Juice", "Warpbone", "Warpeye", "Warpstar" },
    ["Wildcat"] = { "Default", "Glorious Wildcat", "Mimic Wildcat", "Plasma Wildcat", "Shadow Wildcat", "Towerstone Wildcat" },
}

SkinData.Wraps = {
    "Default",
    "1B Visits",
    "Antimatter",
    "Aurora",
    "Aurum",
    "Black Damascus",
    "Black Glass",
    "Black Opal",
    "Blaze",
    "Blizzard",
    "Bluesteel",
    "Bombastic",
    "Brimstone",
    "Candy Apple",
    "Celestial",
    "Crimson",
    "Crystallized",
    "Damascus",
    "Dark Arena",
    "Dark Matter",
    "Diamond",
    "Fire",
    "Frostbite",
    "Glacier",
    "Gold",
    "Highlighter",
    "Hyperdrive",
    "Ice Queen",
    "Lightning",
    "Limefire",
    "Liquid Gold",
    "Magma",
    "Nebula",
    "Neon Lights",
    "Obsidian",
    "Pine",
    "Pixel Light",
    "Plasma",
    "Shadow Ink",
    "Spectral",
    "Starblaze",
    "Starfall",
    "Winter Solstice",
    ".dll",
    ".exe",
    "Borealis",
}

SkinData.Finishers = {
    "Default",
    "5B Visits",
    "Acid Splash",
    "Ascend",
    "BANG!",
    "BONK!",
    "Balloons",
    "Batsplosion",
    "Become Bat",
    "Bonesplosion",
    "Bubble Ball",
    "Bubblegum",
    "Chill Out",
    "Clapped",
    "Collapse",
    "Confetti",
    "Crushed",
    "Curtain Call",
    "Darkheart",
    "Delete",
    "Dematerialize",
    "Diamond Hands",
    "Digitize",
    "Director's Cut",
    "Disintegrate",
    "Electrocute",
    "Erased",
    "Every Finisher Ever",
    "Faceplant",
    "Firework Show",
    "Freeze",
    "Lost Soul",
    "Orbital Strike",
    "Very Tragic Banana Peel Accident",
    "Blip",
    "Boogie",
}

---------------------------------------------------------------------
-- CONFIG MANAGER (SAVE / LOAD / AUTOLOAD)
---------------------------------------------------------------------
local SaveManager = {}
SaveManager.Folder = "RivalsHub"
SaveManager.Ignore = {}
SaveManager.Library = nil
SaveManager.AutoloadLabel = nil

local function getToggles()
    return (typeof(getgenv) == "function" and getgenv().Toggles) or _G.Toggles or {}
end

local function getOptions()
    return (typeof(getgenv) == "function" and getgenv().Options) or _G.Options or {}
end

local function safeIsFolder(path: string): boolean
    local ok, res = pcall(function() return isfolder(path) end)
    return ok and res or false
end

local function safeMakeFolder(path: string)
    pcall(function()
        if not safeIsFolder(path) then
            makefolder(path)
        end
    end)
end

local function safeIsFile(path: string): boolean
    local ok, res = pcall(function() return isfile(path) end)
    return ok and res or false
end

local function safeReadFile(path: string): string?
    local ok, res = pcall(function() return readfile(path) end)
    if ok and typeof(res) == "string" then return res end
    return nil
end

local function safeWriteFile(path: string, content: string): boolean
    local ok = pcall(function() writefile(path, content) end)
    return ok
end

local function safeListFiles(path: string): {string}
    local ok, res = pcall(function() return listfiles(path) end)
    if ok and typeof(res) == "table" then return res end
    return {}
end

SaveManager.Parser = {
    Toggle = {
        Save = function(idx, object)
            return { type = "Toggle", idx = idx, value = object.Value }
        end,
        Load = function(idx, data)
            local toggles = getToggles()
            if toggles[idx] and typeof(toggles[idx].SetValue) == "function" then
                toggles[idx]:SetValue(data.value)
            end
        end,
    },
    Slider = {
        Save = function(idx, object)
            return { type = "Slider", idx = idx, value = tostring(object.Value) }
        end,
        Load = function(idx, data)
            local options = getOptions()
            if options[idx] and typeof(options[idx].SetValue) == "function" then
                options[idx]:SetValue(tonumber(data.value) or data.value)
            end
        end,
    },
    Dropdown = {
        Save = function(idx, object)
            return { type = "Dropdown", idx = idx, value = object.Value, multi = object.Multi }
        end,
        Load = function(idx, data)
            local options = getOptions()
            if options[idx] and typeof(options[idx].SetValue) == "function" then
                options[idx]:SetValue(data.value)
            end
        end,
    },
    ColorPicker = {
        Save = function(idx, object)
            local hex = (object.Value and typeof(object.Value.ToHex) == "function") and object.Value:ToHex() or "ffffff"
            return { type = "ColorPicker", idx = idx, value = hex, transparency = object.Transparency or 0 }
        end,
        Load = function(idx, data)
            local options = getOptions()
            if options[idx] and typeof(options[idx].SetValueRGB) == "function" then
                pcall(function()
                    options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency or 0)
                end)
            end
        end,
    },
    KeyPicker = {
        Save = function(idx, object)
            return { type = "KeyPicker", idx = idx, mode = object.Mode, key = object.Value }
        end,
        Load = function(idx, data)
            local options = getOptions()
            if options[idx] and typeof(options[idx].SetValue) == "function" then
                options[idx]:SetValue({ data.key, data.mode })
            end
        end,
    },
    Input = {
        Save = function(idx, object)
            return { type = "Input", idx = idx, text = object.Value }
        end,
        Load = function(idx, data)
            local options = getOptions()
            if options[idx] and typeof(options[idx].SetValue) == "function" and type(data.text) == "string" then
                options[idx]:SetValue(data.text)
            end
        end,
    },
}

function SaveManager:SetIgnoreIndexes(list: {string})
    for _, key in ipairs(list) do
        self.Ignore[key] = true
    end
end

function SaveManager:SetFolder(folder: string)
    self.Folder = folder
    self:BuildFolderTree()
end

function SaveManager:BuildFolderTree()
    safeMakeFolder(self.Folder)
    safeMakeFolder(self.Folder .. "/settings")
end

function SaveManager:RefreshConfigList(): {string}
    local list = safeListFiles(self.Folder .. "/settings")
    local out = {}
    for _, file in ipairs(list) do
        if file:sub(-5) == ".json" then
            local pos = file:find(".json", 1, true)
            local startPos = pos
            local char = file:sub(pos, pos)
            while char ~= "/" and char ~= "\\" and char ~= "" do
                pos = pos - 1
                char = file:sub(pos, pos)
            end
            if char == "/" or char == "\\" then
                table.insert(out, file:sub(pos + 1, startPos - 1))
            else
                table.insert(out, file:sub(1, startPos - 1))
            end
        end
    end
    table.sort(out)
    return out
end

function SaveManager:Save(name: string): (boolean, string?)
    if not name or #name:gsub(" ", "") == 0 then
        return false, "Invalid config name"
    end
    self:BuildFolderTree()

    local fullPath = self.Folder .. "/settings/" .. name .. ".json"
    local data = { objects = {} }

    local toggles = getToggles()
    for idx, toggle in pairs(toggles) do
        if not self.Ignore[idx] and toggle.Type and self.Parser[toggle.Type] then
            table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
        end
    end

    local options = getOptions()
    for idx, option in pairs(options) do
        if not self.Ignore[idx] and option.Type and self.Parser[option.Type] then
            table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
        end
    end

    local okEnc, encoded = pcall(httpService.JSONEncode, httpService, data)
    if not okEnc or not encoded then
        return false, "Failed to encode config data"
    end

    local okWrite = safeWriteFile(fullPath, encoded)
    if not okWrite then
        return false, "Failed to write file (executor file system error)"
    end
    return true
end

function SaveManager:Load(name: string): (boolean, string?)
    if not name or #name:gsub(" ", "") == 0 then
        return false, "No config file selected"
    end

    local file = self.Folder .. "/settings/" .. name .. ".json"
    if not safeIsFile(file) then
        return false, "Config file does not exist"
    end

    local content = safeReadFile(file)
    if not content then
        return false, "Failed to read config file"
    end

    local okDec, decoded = pcall(httpService.JSONDecode, httpService, content)
    if not okDec or not decoded or not decoded.objects then
        return false, "Corrupted config JSON format"
    end

    for _, item in ipairs(decoded.objects) do
        if item.type and self.Parser[item.type] then
            task.spawn(function()
                self.Parser[item.type].Load(item.idx, item)
            end)
        end
    end
    return true
end

function SaveManager:SetLibrary(library: any)
    self.Library = library
end

function SaveManager:LoadAutoloadConfig()
    local autoPath = self.Folder .. "/settings/autoload.txt"
    if safeIsFile(autoPath) then
        local name = safeReadFile(autoPath)
        if name and #name:gsub(" ", "") > 0 then
            local success, err = self:Load(name)
            if success and self.Library then
                self.Library:Notify(string.format("Auto-loaded config %q", name), 4)
            end
        end
    end
end

function SaveManager:BuildConfigSection(tab: any)
    assert(self.Library, "Must set SaveManager.Library before BuildConfigSection")

    local section = tab:AddRightGroupbox("Config Manager")

    section:AddInput("SaveManager_ConfigName", {
        Text = "Config Name",
        Placeholder = "Enter name...",
    })

    section:AddDropdown("SaveManager_ConfigList", {
        Text = "Saved Configs",
        Values = self:RefreshConfigList(),
        AllowNull = true,
    })

    section:AddButton({
        Text = "Create Config",
        DoubleClick = false,
        Tooltip = "Save current settings under the entered config name",
        Func = function()
            local options = getOptions()
            local name = options.SaveManager_ConfigName and options.SaveManager_ConfigName.Value
            if not name or #name:gsub(" ", "") == 0 then
                return self.Library:Notify("Please enter a valid config name!", 3)
            end
            local success, err = self:Save(name)
            if success then
                self.Library:Notify(string.format("Created config %q!", name), 3)
                if options.SaveManager_ConfigList then
                    options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                    options.SaveManager_ConfigList:SetValue(name)
                end
            else
                self.Library:Notify("Save failed: " .. tostring(err), 3)
            end
        end,
    }):AddButton({
        Text = "Load Config",
        DoubleClick = false,
        Tooltip = "Load settings from selected config",
        Func = function()
            local options = getOptions()
            local name = options.SaveManager_ConfigList and options.SaveManager_ConfigList.Value
            if not name then
                return self.Library:Notify("Please select a config to load!", 3)
            end
            local success, err = self:Load(name)
            if success then
                self.Library:Notify(string.format("Loaded config %q!", name), 3)
            else
                self.Library:Notify("Load failed: " .. tostring(err), 3)
            end
        end,
    })

    section:AddButton({
        Text = "Overwrite Config",
        DoubleClick = false,
        Tooltip = "Overwrite selected config with current settings",
        Func = function()
            local options = getOptions()
            local name = options.SaveManager_ConfigList and options.SaveManager_ConfigList.Value
            if not name then
                return self.Library:Notify("Please select a config to overwrite!", 3)
            end
            local success, err = self:Save(name)
            if success then
                self.Library:Notify(string.format("Overwrote config %q!", name), 3)
            else
                self.Library:Notify("Overwrite failed: " .. tostring(err), 3)
            end
        end,
    }):AddButton({
        Text = "Refresh List",
        DoubleClick = false,
        Tooltip = "Refresh saved configs list from disk",
        Func = function()
            local options = getOptions()
            if options.SaveManager_ConfigList then
                options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                options.SaveManager_ConfigList:SetValue(nil)
            end
            self.Library:Notify("Refreshed config list!", 2)
        end,
    })

    section:AddButton({
        Text = "Set as Autoload",
        DoubleClick = false,
        Tooltip = "Automatically load this config every time you inject",
        Func = function()
            local options = getOptions()
            local name = options.SaveManager_ConfigList and options.SaveManager_ConfigList.Value
            if not name then
                return self.Library:Notify("Please select a config first!", 3)
            end
            safeWriteFile(self.Folder .. "/settings/autoload.txt", name)
            if SaveManager.AutoloadLabel then
                SaveManager.AutoloadLabel:SetText("Autoload: " .. name)
            end
            self.Library:Notify(string.format("Set %q as autoload!", name), 3)
        end,
    })

    SaveManager.AutoloadLabel = section:AddLabel("Autoload: none", true)

    local autoPath = self.Folder .. "/settings/autoload.txt"
    if safeIsFile(autoPath) then
        local name = safeReadFile(autoPath)
        if name and #name:gsub(" ", "") > 0 then
            SaveManager.AutoloadLabel:SetText("Autoload: " .. name)
        end
    end

    self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
end

---------------------------------------------------------------------
-- AURA ENGINE (V5 ORBITS, FLAMES & HIGHLIGHTS)
---------------------------------------------------------------------
end


local Aura = {}
Aura.Tracked = setmetatable({}, { __mode = "k" })

local function findPart(parent: Instance, name: string): BasePart?
    local inst = parent:FindFirstChild(name)
    if inst and inst:IsA("BasePart") then return inst end
    return nil
end

local function getLimb(character: Model, limbName: string): BasePart?
    if limbName == "Torso" then
        return findPart(character, "UpperTorso") or findPart(character, "Torso")
    elseif limbName == "HumanoidRootPart" then
        return findPart(character, "HumanoidRootPart")
    elseif limbName == "Head" then
        return findPart(character, "Head")
    elseif limbName == "Left Arm" then
        return findPart(character, "LeftUpperArm") or findPart(character, "Left Arm")
    elseif limbName == "Right Arm" then
        return findPart(character, "RightUpperArm") or findPart(character, "Right Arm")
    elseif limbName == "Left Leg" then
        return findPart(character, "LeftUpperLeg") or findPart(character, "Left Leg")
    elseif limbName == "Right Leg" then
        return findPart(character, "RightUpperLeg") or findPart(character, "Right Leg")
    end
    return findPart(character, limbName)
end

local function computeColorPalette(mainColor: Color3)
    local h, s, v = mainColor:ToHSV()
    local brightColor = Color3.fromHSV(h, math.clamp(s * 0.45, 0, 1), math.clamp(v * 1.25, 0, 1))
    local darkColor = Color3.fromHSV(h, math.clamp(s * 1.2, 0, 1), math.clamp(v * 0.35, 0, 1))
    return mainColor, brightColor, darkColor
end

local function buildAttachment(name: string, parent: Instance, tag: string, offset: Vector3?, instancesList: {Instance}): Attachment
    local att = Instance.new("Attachment")
    att.Name = name
    if offset then att.Position = offset end
    att:SetAttribute(tag, true)
    att.Parent = parent
    table.insert(instancesList, att)
    return att
end

local function buildEmitter(props: {[string]: any}, parent: Instance, tag: string, instancesList: {Instance}): ParticleEmitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.LockedToPart = true
    emitter.VelocityInheritance = 0
    emitter.LightInfluence = 0
    for key, val in pairs(props) do
        emitter[key] = val
    end
    emitter:SetAttribute(tag, true)
    emitter.Parent = parent
    table.insert(instancesList, emitter)
    return emitter
end

local function buildCosmeticPart(name: string, size: Vector3, color: Color3, transparency: number, parent: Instance, tag: string, instancesList: {Instance}): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Transparency = transparency
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Massless = true
    p.CastShadow = false
    p.Anchored = false
    p:SetAttribute(tag, true)
    p.Parent = parent
    table.insert(instancesList, p)
    return p
end

local function weldTo(part0: BasePart, part1: Part, c0: CFrame, tag: string, instancesList: {Instance}): Weld
    local w = Instance.new("Weld")
    w.Part0 = part0
    w.Part1 = part1
    w.C0 = c0
    w:SetAttribute(tag, true)
    w.Parent = part1
    table.insert(instancesList, w)
    return w
end

local function buildWing(character: Model, anchor: BasePart, side: number, tag: string, instancesList: {Instance}): Weld
    local wingRoot = buildCosmeticPart("RH_WingRoot", Vector3.new(0.2, 0.2, 0.2), Color3.new(1, 1, 1), 1, character, tag, instancesList)
    local rootWeld = weldTo(anchor, wingRoot, CFrame.new(0.35 * side, 0.55, 0.62), tag, instancesList)

    local feathers = {
        { 14, 2.0, 0.42 },
        { 36, 2.5, 0.50 },
        { 58, 2.8, 0.55 },
        { 80, 2.5, 0.50 },
        { 100, 2.0, 0.42 },
    }

    for i, f in ipairs(feathers) do
        local ang, len, width = f[1], f[2], f[3]
        local feather = buildCosmeticPart("RH_Feather", Vector3.new(0.14, len, width), Color3.new(1, 1, 1), 0.05, character, tag, instancesList)
        local fw = Instance.new("Weld")
        fw.Part0 = wingRoot
        fw.Part1 = feather
        fw.C0 = CFrame.new(0, 0, 0.035 * i)
            * CFrame.Angles(0, 0, math.rad(ang) * -side)
            * CFrame.new(0, len / 2, 0)
        fw:SetAttribute(tag, true)
        fw.Parent = feather
        table.insert(instancesList, fw)
    end

    return rootWeld
end

function Aura.Remove(character: Model?)
    if not character then return end
    local data = Aura.Tracked[character]
    if data and data.instances then
        for _, inst in ipairs(data.instances) do
            if inst and inst.Parent then
                inst:Destroy()
            end
        end
    end
    Aura.Tracked[character] = nil
end

function Aura.SetVisible(visible: boolean, cfg: any?)
    local chamsOn = cfg and cfg.Visuals and cfg.Visuals.ESP and cfg.Visuals.ESP.Chams
    for _, data in pairs(Aura.Tracked) do
        if data.highlight and data.highlight.Parent then
            data.highlight.Enabled = visible and (not chamsOn)
        end
        if data.light and data.light.Parent then
            data.light.Enabled = visible
        end
        for _, em in ipairs(data.emitters) do
            if em.Parent then
                em.Enabled = visible
            end
        end
        for _, orb in ipairs(data.orbs) do
            if orb.Parent then
                orb.Transparency = visible and 0 or 1
            end
        end
        for _, tr in ipairs(data.orbTrails) do
            if tr.Parent then
                tr.Enabled = visible
            end
        end
    end
end

function Aura.UpdateThroughWalls(throughWalls: boolean)
    local depth = throughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    for _, data in pairs(Aura.Tracked) do
        if data.highlight and data.highlight.Parent then
            data.highlight.DepthMode = depth
        end
    end
end

function Aura.UpdateColors(cfg: any)
    local espCfg = cfg.Visuals.ESP
    for _, data in pairs(Aura.Tracked) do
        local mainColor
        if data.isLocal then
            mainColor = espCfg.Colors.Local
        elseif data.isAlly then
            mainColor = espCfg.Colors.Ally
        else
            mainColor = espCfg.Colors.Enemy
        end

        local main, bright = computeColorPalette(mainColor)

        if data.highlight and data.highlight.Parent then
            data.highlight.FillColor = main
            data.highlight.OutlineColor = bright
        end

        if data.light and data.light.Parent then
            data.light.Color = main
        end

        for _, orb in ipairs(data.orbs) do
            if orb.Parent then
                orb.Color = bright
            end
        end

        for _, trail in ipairs(data.orbTrails) do
            if trail.Parent then
                trail.Color = ColorSequence.new(bright, main)
            end
        end

        for _, em in ipairs(data.emitters) do
            if em.Parent then
                em.Color = ColorSequence.new(bright, main)
            end
        end
    end
end

function Aura.Apply(character: Model, isAllyTeam: boolean, cfg: any, tag: string)
    local espCfg = cfg.Visuals.ESP
    if not character or not character.Parent then return end

    local isLocalChar = (character == LocalPlayer.Character)
    if isLocalChar and not espCfg.IncludeLocal then
        Aura.Remove(character)
        return
    end

    if Aura.Tracked[character] then
        local data = Aura.Tracked[character]
        data.isAlly = isAllyTeam
        data.isLocal = isLocalChar
        Aura.UpdateColors(cfg)
        Aura.UpdateThroughWalls(espCfg.ThroughWalls)
        return
    end

    Aura.Remove(character)

    local mainColor
    if isLocalChar then
        mainColor = espCfg.Colors.Local
    elseif isAllyTeam then
        mainColor = espCfg.Colors.Ally
    else
        mainColor = espCfg.Colors.Enemy
    end

    local main, bright = computeColorPalette(mainColor)
    local mul = espCfg.Intensity or 1
    local zOff = isLocalChar and -1 or 0
    local fireTex = "rbxasset://textures/particles/fire_main.dds"

    local torso = getLimb(character, "Torso")
    local root = getLimb(character, "HumanoidRootPart")
    local anchor = torso or root
    if not anchor or not root then return end

    local instancesList: {Instance} = {}

    local data = {
        isAlly = isAllyTeam,
        isLocal = isLocalChar,
        phase = math.random() * TAU,
        root = root,
        orbs = {},
        orbTrails = {},
        emitters = {},
        wingWelds = nil,
        instances = instancesList,
        smoothPos = nil,
    }

    local hl = Instance.new("Highlight")
    hl.Name = "RH_Highlight"
    hl.Adornee = character
    hl.DepthMode = espCfg.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    hl.FillColor = main
    hl.FillTransparency = 0.75
    hl.OutlineColor = bright
    hl.OutlineTransparency = 0.1
    hl.Enabled = espCfg.Aura and (not espCfg.Chams)
    hl:SetAttribute(tag, true)
    hl.Parent = character
    table.insert(instancesList, hl)
    data.highlight = hl

    if espCfg.UseOrbs then
        for i = 1, espCfg.OrbCount do
            local orb = buildCosmeticPart("RH_Orb" .. i, Vector3.new(0.65, 0.65, 0.65), bright, espCfg.Aura and 0 or 1, character, tag, instancesList)
            orb.Anchored = true
            local orbMesh = Instance.new("SpecialMesh")
            orbMesh.MeshType = Enum.MeshType.Sphere
            orbMesh:SetAttribute(tag, true)
            orbMesh.Parent = orb
            table.insert(instancesList, orbMesh)

            local orbAtt = buildAttachment("RH_OrbGlow", orb, tag, nil, instancesList)
            local orbFire = buildEmitter({
                Name = "RH_OrbFire",
                Texture = fireTex,
                Rate = 4 * mul,
                Lifetime = NumberRange.new(0.25, 0.3),
                Speed = NumberRange.new(0, 0),
                LightEmission = 1,
                Brightness = 1.6,
                Enabled = espCfg.Aura,
                Orientation = Enum.ParticleOrientation.FacingCamera,
                Size = NumberSequence.new({ kp(0, 1.2), kp(1, 0.4) }),
                Transparency = NumberSequence.new({ kp(0, 0.5), kp(1, 1) }),
                Color = ColorSequence.new(bright, main),
            }, orbAtt, tag, instancesList)
            table.insert(data.emitters, orbFire)

            local ta0 = buildAttachment("RH_OrbT0", orb, tag, Vector3.new(0, 0.3, 0), instancesList)
            local ta1 = buildAttachment("RH_OrbT1", orb, tag, Vector3.new(0, -0.3, 0), instancesList)
            local orbTrail = Instance.new("Trail")
            orbTrail.Name = "RH_OrbTrail"
            orbTrail.Attachment0 = ta0
            orbTrail.Attachment1 = ta1
            orbTrail.Lifetime = 0.4
            orbTrail.MaxLength = 12
            orbTrail.MinLength = 0.02
            orbTrail.FaceCamera = true
            orbTrail.LightEmission = 1
            orbTrail.LightInfluence = 0
            orbTrail.Brightness = 2
            orbTrail.Enabled = espCfg.Aura
            orbTrail.WidthScale = NumberSequence.new({ kp(0, 1.1), kp(0.5, 0.6), kp(1, 0.1) })
            orbTrail.Color = ColorSequence.new(bright, main)
            orbTrail.Transparency = NumberSequence.new({ kp(0, 0.12), kp(0.6, 0.55), kp(1, 1) })
            orbTrail:SetAttribute(tag, true)
            orbTrail.Parent = orb
            table.insert(instancesList, orbTrail)

            table.insert(data.orbTrails, orbTrail)
            table.insert(data.orbs, orb)
        end
    end

    if isLocalChar and espCfg.UseWings then
        data.wingWelds = {
            buildWing(character, anchor, -1, tag, instancesList),
            buildWing(character, anchor, 1, tag, instancesList),
        }
    end

    if espCfg.UseFlames then
        local coreAtt = buildAttachment("RH_Core", anchor, tag, nil, instancesList)

        local coreFire = buildEmitter({
            Name = "RH_CoreFire",
            Texture = fireTex,
            Rate = 24 * mul,
            Lifetime = NumberRange.new(0.5, 0.65),
            Speed = NumberRange.new(2.5, 3.5),
            SpreadAngle = Vector2.new(9, 9),
            Acceleration = Vector3.new(0, 6, 0),
            LightEmission = 1,
            Brightness = 2,
            Enabled = espCfg.Aura,
            ZOffset = zOff,
            EmissionDirection = Enum.NormalId.Top,
            Orientation = Enum.ParticleOrientation.FacingCamera,
            Rotation = NumberRange.new(-20, 20),
            RotSpeed = NumberRange.new(-30, 30),
            Size = NumberSequence.new({ kp(0, 2.6), kp(0.5, 2.0), kp(1, 0.6) }),
            Transparency = NumberSequence.new({ kp(0, 0.45), kp(0.35, 0.1), kp(0.75, 0.5), kp(1, 1) }),
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, bright),
                ColorSequenceKeypoint.new(0.45, main),
                ColorSequenceKeypoint.new(1, main),
            }),
        }, coreAtt, tag, instancesList)
        table.insert(data.emitters, coreFire)

        local innerFire = buildEmitter({
            Name = "RH_CoreFireInner",
            Texture = fireTex,
            Rate = 10 * mul,
            Lifetime = NumberRange.new(0.3, 0.4),
            Speed = NumberRange.new(4, 5),
            SpreadAngle = Vector2.new(4, 4),
            Acceleration = Vector3.new(0, 8, 0),
            LightEmission = 1,
            Brightness = 2.4,
            Enabled = espCfg.Aura,
            ZOffset = zOff + 0.1,
            EmissionDirection = Enum.NormalId.Top,
            Orientation = Enum.ParticleOrientation.FacingCamera,
            Rotation = NumberRange.new(-15, 15),
            RotSpeed = NumberRange.new(-20, 20),
            Size = NumberSequence.new({ kp(0, 1.2), kp(0.6, 0.8), kp(1, 0.2) }),
            Transparency = NumberSequence.new({ kp(0, 0.3), kp(0.5, 0.15), kp(1, 1) }),
            Color = ColorSequence.new(bright, main),
        }, coreAtt, tag, instancesList)
        table.insert(data.emitters, innerFire)

        for _, armName in ipairs({ "Left Arm", "Right Arm" }) do
            local arm = getLimb(character, armName)
            if arm then
                local fistAtt = buildAttachment("RH_Fist", arm, tag, Vector3.new(0, -arm.Size.Y * 0.4, 0), instancesList)
                local fistFire = buildEmitter({
                    Name = "RH_FistFire",
                    Texture = fireTex,
                    Rate = 10 * mul,
                    Lifetime = NumberRange.new(0.3, 0.4),
                    Speed = NumberRange.new(1, 1.5),
                    SpreadAngle = Vector2.new(8, 8),
                    Acceleration = Vector3.new(0, 4, 0),
                    LightEmission = 1,
                    Brightness = 2,
                    Enabled = espCfg.Aura,
                    ZOffset = zOff,
                    EmissionDirection = Enum.NormalId.Top,
                    Orientation = Enum.ParticleOrientation.FacingCamera,
                    Size = NumberSequence.new({ kp(0, 1.05), kp(1, 0.3) }),
                    Transparency = NumberSequence.new({ kp(0, 0.4), kp(0.4, 0.2), kp(1, 1) }),
                    Color = ColorSequence.new(bright, main),
                }, fistAtt, tag, instancesList)
                table.insert(data.emitters, fistFire)
            end
        end
    end

    if espCfg.UseLight then
        local lightAtt = buildAttachment("RH_LightAtt", anchor, tag, nil, instancesList)
        local light = Instance.new("PointLight")
        light.Name = "RH_Light"
        light.Color = main
        light.Brightness = 1.5
        light.Range = 12
        light.Shadows = false
        light.Enabled = espCfg.Aura
        light:SetAttribute(tag, true)
        light.Parent = lightAtt
        table.insert(instancesList, light)
        data.light = light
    end

    Aura.Tracked[character] = data
end

function Aura.Step(t: number, dt: number, cfg: any)
    local espCfg = cfg.Visuals.ESP
    if not espCfg.Aura then return end

    local deadModels: {Model} = {}

    for model, data in pairs(Aura.Tracked) do
        if not model.Parent or not data.root or not data.root.Parent then
            table.insert(deadModels, model)
        else
            local phase = data.phase
            local pulse = 0.5 + 0.5 * math.sin(t * 2.2 + phase)

            if data.highlight and data.highlight.Parent then
                data.highlight.FillTransparency = 0.76 + 0.1 * pulse
                data.highlight.OutlineTransparency = 0.12 + 0.2 * pulse
            end
            if data.light and data.light.Parent then
                data.light.Brightness = 1 + 0.8 * pulse
            end

            local rootPart = data.root
            if #data.orbs > 0 then
                local rootPos = rootPart.Position
                local k = 14
                local alpha = 1 - math.exp(-dt * k)
                local velVec = rootPart.AssemblyLinearVelocity
                local target = rootPos + velVec * (1 / k)
                if data.smoothPos == nil or (rootPos - data.smoothPos).Magnitude > 15 then
                    data.smoothPos = rootPos
                else
                    data.smoothPos = data.smoothPos:Lerp(target, alpha)
                end
                local basePos = data.smoothPos

                local n = #data.orbs
                for i, orb in ipairs(data.orbs) do
                    if orb.Parent then
                        local ang = t * espCfg.OrbSpeed + phase + (i - 1) * (TAU / n)
                        orb.CFrame = CFrame.new(basePos)
                            * CFrame.Angles(0, ang, 0)
                            * CFrame.new(espCfg.OrbRadius, math.sin(t * 1.8 + i * 2.1) * 0.5, 0)
                    end
                end
            end

            if data.wingWelds then
                local flap = math.sin(t * 2.6)
                local yaw = math.rad(28) + math.rad(20) * flap
                local lift = math.rad(8) * flap
                local wl, wr = data.wingWelds[1], data.wingWelds[2]
                if wl and wl.Parent then
                    wl.C0 = CFrame.new(-0.35, 0.55 + 0.06 * flap, 0.62)
                        * CFrame.Angles(0, yaw, math.rad(12) + lift)
                end
                if wr and wr.Parent then
                    wr.C0 = CFrame.new(0.35, 0.55 + 0.06 * flap, 0.62)
                        * CFrame.Angles(0, -yaw, -(math.rad(12) + lift))
                end
            end
        end
    end

    for _, m in ipairs(deadModels) do
        Aura.Remove(m)
    end
end

---------------------------------------------------------------------
-- CHAMS ENGINE (BODY HIGHLIGHTS)
---------------------------------------------------------------------
end

local Chams = {}
Chams.Highlights = setmetatable({}, { __mode = "k" })

function Chams.Apply(character: Model, isAlly: boolean, isLocal: boolean, cfg: any)
    local espCfg = cfg.Visuals.ESP
    if not character or not character.Parent then return end
    if isLocal and not espCfg.IncludeLocal then
        Chams.Remove(character)
        return
    end

    local hl = Chams.Highlights[character]
    if not hl or not hl.Parent then
        hl = Instance.new("Highlight")
        hl.Name = "RH_Chams"
        hl.Adornee = character
        hl:SetAttribute(cfg.Tag .. "_Chams", true)
        hl.Parent = character
        Chams.Highlights[character] = hl
    end

    local chamsColor = isAlly and espCfg.Colors.Ally or espCfg.ChamsColor
    local h, s, v = chamsColor:ToHSV()
    local outlineColor = Color3.fromHSV(h, math.clamp(s * 0.45, 0, 1), math.clamp(v * 1.3, 0, 1))

    hl.Enabled = espCfg.Chams
    hl.DepthMode = espCfg.ChamsThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    hl.FillColor = chamsColor
    hl.FillTransparency = 0.5
    hl.OutlineColor = outlineColor
    hl.OutlineTransparency = 0.05
end

function Chams.Remove(character: Model?)
    if not character then return end
    local hl = Chams.Highlights[character]
    if hl and hl.Parent then
        hl:Destroy()
    end
    Chams.Highlights[character] = nil
end

function Chams.SetVisible(visible: boolean)
    for _, hl in pairs(Chams.Highlights) do
        if hl and hl.Parent then
            hl.Enabled = visible
        end
    end
end

function Chams.UpdateProperties(cfg: any, characters: {[Model]: {player: Player?, isAlly: boolean, isLocal: boolean}})
    local espCfg = cfg.Visuals.ESP
    for model, info in pairs(characters) do
        if espCfg.Chams then
            Chams.Apply(model, info.isAlly, info.isLocal, cfg)
        else
            Chams.Remove(model)
        end
    end
end

function Chams.Cleanup()
    for model, hl in pairs(Chams.Highlights) do
        if hl and hl.Parent then
            hl:Destroy()
        end
    end
    table.clear(Chams.Highlights)
end

---------------------------------------------------------------------
-- 2D OVERLAY ESP (BOX, SKELETON, NAME, HEALTH, DISTANCE, WEAPON)
---------------------------------------------------------------------
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

---------------------------------------------------------------------
-- BULLET TRACERS ENGINE (SPIRAL BEAMS & GAME HOOK)
---------------------------------------------------------------------
end


local Tracers = {}
Tracers.ActiveTracers = {}
Tracers.Folder = nil
Tracers.MAX_ACTIVE = 24

local function getTracerFolder(tag: string): Folder
    if Tracers.Folder and Tracers.Folder.Parent then
        return Tracers.Folder
    end
    local f = Instance.new("Folder")
    f.Name = "RH_Tracers"
    f:SetAttribute(tag, true)
    f.Parent = Workspace
    Tracers.Folder = f
    return f
end

local function buildTracerAttachment(name: string, parent: Instance, tag: string, offset: Vector3?): Attachment
    local att = Instance.new("Attachment")
    att.Name = name
    if offset then att.Position = offset end
    att:SetAttribute(tag, true)
    att.Parent = parent
    return att
end

function Tracers.FireTracer(origin: Vector3, hitPos: Vector3, isEnemy: boolean?, cfg: any, tag: string)
    local tCfg = cfg.Visuals.Tracers
    if not tCfg.Enabled then return end

    local dirVec = hitPos - origin
    local length = dirVec.Magnitude
    if length < 2 then return end

    if #Tracers.ActiveTracers >= Tracers.MAX_ACTIVE then
        local oldest = table.remove(Tracers.ActiveTracers, 1)
        if oldest then
            if oldest.rail and oldest.rail.Parent then oldest.rail:Destroy() end
            if oldest.orb and oldest.orb.Parent then oldest.orb:Destroy() end
        end
    end

    local folder = getTracerFolder(tag)
    local railCF = CFrame.lookAt(origin, hitPos)

    local coreColor = isEnemy and tCfg.EnemyColor or tCfg.FriendlyColor
    local h, s, v = coreColor:ToHSV()
    local spiralColor = Color3.fromHSV(h, math.clamp(s * 0.45, 0, 1), math.clamp(v * 1.3, 0, 1))

    local rail = Instance.new("Part")
    rail.Name = "RH_TracerRail"
    rail.Size = Vector3.new(0.1, 0.1, 0.1)
    rail.Transparency = 1
    rail.Anchored = true
    rail.CanCollide = false
    rail.CanQuery = false
    rail.CanTouch = false
    rail.CastShadow = false
    rail.CFrame = railCF * CFrame.new(0, 0, -length / 2)
    rail:SetAttribute(tag, true)
    rail.Parent = folder

    local a0 = buildTracerAttachment("RH_Tr0", rail, tag, Vector3.new(0, 0, length / 2))
    local a1 = buildTracerAttachment("RH_Tr1", rail, tag, Vector3.new(0, 0, -length / 2))

    local beam = Instance.new("Beam")
    beam.Name = "RH_TracerBeam"
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Brightness = 3
    beam.Width0 = 0.15
    beam.Width1 = 0.08
    beam.Color = ColorSequence.new(coreColor)
    beam.Transparency = NumberSequence.new(0.1)
    beam:SetAttribute(tag, true)
    beam.Parent = rail

    local orb = Instance.new("Part")
    orb.Name = "RH_TracerOrb"
    orb.Size = Vector3.new(0.2, 0.2, 0.2)
    orb.Material = Enum.Material.Neon
    orb.Color = spiralColor
    orb.Anchored = true
    orb.CanCollide = false
    orb.CanQuery = false
    orb.CanTouch = false
    orb.CastShadow = false
    orb.CFrame = railCF * CFrame.new(tCfg.SpiralRadius, 0, 0)
    orb:SetAttribute(tag, true)

    local orbMesh = Instance.new("SpecialMesh")
    orbMesh.MeshType = Enum.MeshType.Sphere
    orbMesh:SetAttribute(tag, true)
    orbMesh.Parent = orb
    orb.Parent = folder

    local ta0 = buildTracerAttachment("RH_TrS0", orb, tag, Vector3.new(0, 0.1, 0))
    local ta1 = buildTracerAttachment("RH_TrS1", orb, tag, Vector3.new(0, -0.1, 0))

    local spiralTrail = Instance.new("Trail")
    spiralTrail.Name = "RH_SpiralTrail"
    spiralTrail.Attachment0 = ta0
    spiralTrail.Attachment1 = ta1
    spiralTrail.Lifetime = 0.2
    spiralTrail.MinLength = 0.02
    spiralTrail.FaceCamera = true
    spiralTrail.LightEmission = 1
    spiralTrail.LightInfluence = 0
    spiralTrail.Brightness = 2.5
    spiralTrail.WidthScale = NumberSequence.new({ kp(0, 1), kp(1, 0.2) })
    spiralTrail.Color = ColorSequence.new(spiralColor, coreColor)
    spiralTrail.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
    spiralTrail:SetAttribute(tag, true)
    spiralTrail.Parent = orb

    local duration = math.max(tCfg.Duration or 0.4, length / tCfg.SpiralSpeed + 0.15)

    table.insert(Tracers.ActiveTracers, {
        rail = rail,
        beam = beam,
        orb = orb,
        railCF = railCF,
        length = length,
        dist = 0,
        age = 0,
        duration = duration,
    })
end

function Tracers.SpawnTracerFromCamera(cfg: any, tag: string)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local tCfg = cfg.Visuals.Tracers

    local origin = (cam.CFrame * CFrame.new(0.7, -0.5, -1)).Position
    local char = LocalPlayer.Character
    if char then
        local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
        if rightArm and rightArm:IsA("BasePart") then
            origin = (rightArm.CFrame * CFrame.new(0, -rightArm.Size.Y * 0.5, 0)).Position
        end
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter: {Instance} = {}
    if char then table.insert(filter, char) end
    if Tracers.Folder then table.insert(filter, Tracers.Folder) end
    params.FilterDescendantsInstances = filter

    local camPos = cam.CFrame.Position
    local look = cam.CFrame.LookVector
    local result = Workspace:Raycast(camPos, look * tCfg.MaxDistance, params)
    local hitPos = result and result.Position or (camPos + look * tCfg.MaxDistance)

    Tracers.FireTracer(origin, hitPos, false, cfg, tag)
end

function Tracers.Step(dt: number, cfg: any)
    local tCfg = cfg.Visuals.Tracers
    for i = #Tracers.ActiveTracers, 1, -1 do
        local tr = Tracers.ActiveTracers[i]
        tr.age += dt

        if tr.age >= tr.duration or not tr.rail.Parent then
            if tr.rail and tr.rail.Parent then tr.rail:Destroy() end
            if tr.orb and tr.orb.Parent then tr.orb:Destroy() end
            table.remove(Tracers.ActiveTracers, i)
        else
            local fade = math.clamp(tr.age / tr.duration, 0, 1)
            tr.beam.Transparency = NumberSequence.new(0.1 + 0.9 * fade * fade)

            if tr.dist < tr.length then
                tr.dist = math.min(tr.dist + tCfg.SpiralSpeed * dt, tr.length)
                local spin = tr.dist * tCfg.SpiralTwist
                tr.orb.CFrame = tr.railCF
                    * CFrame.new(0, 0, -tr.dist)
                    * CFrame.Angles(0, 0, spin)
                    * CFrame.new(tCfg.SpiralRadius, 0, 0)
                if tr.dist >= tr.length then
                    tr.orb.Transparency = 1
                end
            end
        end
    end
end

function Tracers.Cleanup()
    for _, tr in ipairs(Tracers.ActiveTracers) do
        if tr.rail and tr.rail.Parent then tr.rail:Destroy() end
        if tr.orb and tr.orb.Parent then tr.orb:Destroy() end
    end
    table.clear(Tracers.ActiveTracers)

    if Tracers.Folder and Tracers.Folder.Parent then
        Tracers.Folder:ClearAllChildren()
    end
end

---------------------------------------------------------------------
-- SKIN CHANGER ENGINE (WEAPONS, SKINS, WRAPS, FINISHERS)
---------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

---------------------------------------------------------------------
-- GAME HOOK (FIGHTERCONTROLLER & REPLICATION HOOKING)
---------------------------------------------------------------------
end

local GameHook = {}
GameHook.Connections = {}
GameHook.PlayerConnections = {}
GameHook.FighterController = nil
GameHook.TracerHooked = false

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

function GameHook.GetUniqueCharacters(): {[Model]: {player: Player?, fighter: any?, isAlly: boolean, isLocal: boolean}}
    local results: {[Model]: {player: Player?, fighter: any?, isAlly: boolean, isLocal: boolean}} = {}
    local fc = GameHook.FighterController

    for _, player in ipairs(Players:GetPlayers()) do
        local fighter = nil
        if fc and typeof(fc.GetFighter) == "function" then
            local ok, f = pcall(fc.GetFighter, fc, player)
            if ok and f then fighter = f end
        end

        local m = nil
        if fighter and fighter.Entity and fighter.Entity.Model and fighter.Entity.Model.Parent then
            m = fighter.Entity.Model
        elseif player.Character and player.Character.Parent then
            m = player.Character
        end

        if m and not results[m] then
            results[m] = {
                player = player,
                fighter = fighter,
                isAlly = GameHook.IsAlly(player),
                isLocal = (player == LocalPlayer)
            }
        end
    end

    if fc and fc.Objects then
        for _, fighter in pairs(fc.Objects) do
            if fighter.Entity and fighter.Entity.Model and fighter.Entity.Model.Parent then
                local m = fighter.Entity.Model
                if not results[m] then
                    local p = fighter.Player
                    results[m] = {
                        player = p,
                        fighter = fighter,
                        isAlly = p and GameHook.IsAlly(p) or false,
                        isLocal = (p == LocalPlayer)
                    }
                end
            end
        end
    end

    return results
end

function GameHook.RefreshVisuals(Config: any, Aura: any, Chams: any)
    local chars = GameHook.GetUniqueCharacters()

    -- 1) Refresh Aura
    if Config.Visuals.ESP.Aura then
        Aura.SetVisible(true)
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
    else
        Aura.SetVisible(false)
    end

    -- 2) Refresh Chams
    if Chams and Chams.UpdateProperties then
        Chams.UpdateProperties(Config, chars)
    end
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

function GameHook.Init(Config: any, Aura: any, Tracers: any, ESP2D: any, Chams: any)
    pcall(function()
        local controllers = LocalPlayer:WaitForChild("PlayerScripts", 4):WaitForChild("Controllers", 4)
        GameHook.FighterController = require(controllers:WaitForChild("FighterController", 4))
    end)

    GameHook.HookTracers(Config, Tracers)

    local function onCharacterModel(m: Model?, isAlly: boolean, isLocal: boolean)
        if not m or not m.Parent then return end
        if isLocal and not Config.Visuals.ESP.IncludeLocal then return end
        local hum = m:WaitForChild("Humanoid", 3)
        local root = m:WaitForChild("HumanoidRootPart", 3)
        if not hum or not root then return end
        task.wait(0.04)
        if not m.Parent then return end

        if Config.Visuals.ESP.Aura then
            Aura.Apply(m, isAlly, Config, Config.Tag)
        end
        if Config.Visuals.ESP.Chams and Chams then
            Chams.Apply(m, isAlly, isLocal, Config)
        end
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
            if Chams then Chams.Remove(char) end
            if ESP2D then ESP2D.RemoveEntry(char) end
        end))
        table.insert(pConns, player:GetAttributeChangedSignal("TeamID"):Connect(function()
            GameHook.RefreshVisuals(Config, Aura, Chams)
        end))
        table.insert(pConns, player:GetPropertyChangedSignal("Team"):Connect(function()
            GameHook.RefreshVisuals(Config, Aura, Chams)
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
            if Chams then Chams.Remove(m) end
            if ESP2D then ESP2D.RemoveEntry(m) end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        watchPlayer(p)
    end

    table.insert(GameHook.Connections, Players.PlayerAdded:Connect(watchPlayer))
    table.insert(GameHook.Connections, Players.PlayerRemoving:Connect(unwatchPlayer))
    table.insert(GameHook.Connections, LocalPlayer:GetAttributeChangedSignal("TeamID"):Connect(function()
        GameHook.RefreshVisuals(Config, Aura, Chams)
    end))
    table.insert(GameHook.Connections, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        GameHook.RefreshVisuals(Config, Aura, Chams)
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
                        if Chams then Chams.Remove(entity.Model) end
                        if ESP2D then ESP2D.RemoveEntry(entity.Model) end
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

    local t = 0
    local cam = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")

    table.insert(GameHook.Connections, RunService.RenderStepped:Connect(function(dt)
        t += dt
        local currentCam = Workspace.CurrentCamera or cam

        if Config.Visuals.ESP.Aura then
            Aura.Step(t, dt, Config)
        end

        if Config.Visuals.Tracers.Enabled then
            Tracers.Step(dt, Config)
        end

        if ESP2D and currentCam then
            local chars = GameHook.GetUniqueCharacters()
            ESP2D.Step(currentCam, Config, chars)
        end
    end))

    local scanTimer = 0
    table.insert(GameHook.Connections, RunService.Heartbeat:Connect(function(dt)
        scanTimer += dt
        if scanTimer < 1.5 then return end
        scanTimer = 0

        local chars = GameHook.GetUniqueCharacters()
        for m, info in pairs(chars) do
            if Config.Visuals.ESP.Aura and not Aura.Tracked[m] then
                if not info.isLocal or Config.Visuals.ESP.IncludeLocal then
                    Aura.Apply(m, info.isAlly, Config, Config.Tag)
                end
            end
            if Config.Visuals.ESP.Chams and Chams and not Chams.Highlights[m] then
                Chams.Apply(m, info.isAlly, info.isLocal, Config)
            end
        end
    end))

    GameHook.RefreshVisuals(Config, Aura, Chams)
end

function GameHook.Destroy(Config: any, Aura: any, Tracers: any, ESP2D: any, Chams: any)
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

    if Aura then
        for model in pairs(Aura.Tracked) do
            Aura.Remove(model)
        end
        table.clear(Aura.Tracked)
    end

    if Chams then
        Chams.Cleanup()
    end

    if ESP2D then
        ESP2D.Cleanup()
    end

    if Tracers then
        Tracers.Cleanup()
    end
end

---------------------------------------------------------------------
-- UI THEMES
---------------------------------------------------------------------
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

---------------------------------------------------------------------
-- INTERFACE BUILDER
---------------------------------------------------------------------
local function buildUI(onUnload: () -> ())
    if typeof(SaveManager) == "function" and onUnload == nil then
        onUnload = SaveManager
        SaveManager = nil
    end

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
        SkinChanger = Window:AddTab("Skin Changer"),
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
    -- TAB 3: Skin Changer
    -------------------------------------------------------------------
    local scCfg = Config.Visuals.SkinChanger
    local WeaponBox = Tabs.SkinChanger:AddLeftGroupbox("Weapon & Skin")
    local CosmeticsBox = Tabs.SkinChanger:AddRightGroupbox("Wrap & Finisher")

    local weaponsList = (SkinData and SkinData.Weapons) or { "Assault Rifle", "Sniper", "Shotgun", "Handgun" }
    local currentWeapon = scCfg.SelectedWeapon or "Assault Rifle"
    local initialSkins = (SkinData and SkinData.SkinsByWeapon and SkinData.SkinsByWeapon[currentWeapon]) or { "Default" }

    local skinDropdown = nil

    WeaponBox:AddDropdown("WeaponDropdown", {
        Values = weaponsList,
        Default = 1,
        Multi = false,
        Text = "Select Weapon",
        Tooltip = "Choose weapon to customize",
        Callback = function(value)
            scCfg.SelectedWeapon = value
            local newSkins = (SkinData and SkinData.SkinsByWeapon and SkinData.SkinsByWeapon[value]) or { "Default" }
            local targetDrop = skinDropdown or ((typeof(getgenv) == "function" and getgenv().Options) or _G.Options or {}).SkinDropdown
            if targetDrop and typeof(targetDrop.SetValues) == "function" then
                targetDrop:SetValues(newSkins)
                targetDrop:SetValue("Default")
            end
        end,
    })

    skinDropdown = WeaponBox:AddDropdown("SkinDropdown", {
        Values = initialSkins,
        Default = 1,
        Multi = false,
        Text = "Select Skin",
        Tooltip = "Choose skin model for the selected weapon",
        Callback = function(value)
            scCfg.SelectedSkin = value
        end,
    })

    WeaponBox:AddButton({
        Text = "Apply Skin",
        DoubleClick = false,
        Tooltip = "Apply selected skin to weapon",
        Func = function()
            if SkinChanger and SkinChanger.Apply then
                SkinChanger.Apply(scCfg.SelectedWeapon, scCfg.SelectedSkin, nil, nil)
                Library:Notify(string.format("Applied skin %s to %s", scCfg.SelectedSkin, scCfg.SelectedWeapon), 3)
            end
        end,
    })

    WeaponBox:AddButton({
        Text = "Apply All (Skin, Wrap & Finisher)",
        DoubleClick = false,
        Tooltip = "Equip all chosen cosmetics simultaneously",
        Func = function()
            if SkinChanger and SkinChanger.Apply then
                SkinChanger.Apply(scCfg.SelectedWeapon, scCfg.SelectedSkin, scCfg.SelectedWrap, scCfg.SelectedFinisher)
                Library:Notify(string.format("Applied cosmetics to %s!", scCfg.SelectedWeapon), 3)
            end
        end,
    })

    WeaponBox:AddToggle("AutoApplyToggle", {
        Text = "Auto-Apply on Weapon Equip",
        Default = scCfg.AutoApply,
        Tooltip = "Automatically apply cosmetics when equipping weapons",
        Callback = function(value)
            scCfg.AutoApply = value
            if SkinChanger then
                SkinChanger.AutoApply = value
            end
        end,
    })

    local wrapsList = (SkinData and SkinData.Wraps) or { "Default", "1B Visits", "Glacier", "Pine", "Brimstone" }
    local finishersList = (SkinData and SkinData.Finishers) or { "Default", "Orbital Strike", "Disintegrate", "BONK!" }

    CosmeticsBox:AddDropdown("WrapDropdown", {
        Values = wrapsList,
        Default = 1,
        Multi = false,
        Text = "Select Wrap",
        Tooltip = "Choose wrap texture for the selected weapon",
        Callback = function(value)
            scCfg.SelectedWrap = value
        end,
    })

    CosmeticsBox:AddDropdown("FinisherDropdown", {
        Values = finishersList,
        Default = 1,
        Multi = false,
        Text = "Select Finisher",
        Tooltip = "Choose finisher played on enemy elimination",
        Callback = function(value)
            scCfg.SelectedFinisher = value
        end,
    })

    CosmeticsBox:AddButton({
        Text = "Apply Wrap & Finisher",
        DoubleClick = false,
        Tooltip = "Apply wrap and finisher to weapon",
        Func = function()
            if SkinChanger and SkinChanger.Apply then
                SkinChanger.Apply(scCfg.SelectedWeapon, nil, scCfg.SelectedWrap, scCfg.SelectedFinisher)
                Library:Notify(string.format("Applied wrap & finisher to %s", scCfg.SelectedWeapon), 3)
            end
        end,
    })

    -------------------------------------------------------------------
    -- TAB 4: Settings
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
    local globalOptions = (typeof(getgenv) == "function" and getgenv().Options) or _G.Options or {}
    Library.ToggleKeybind = globalOptions.MenuKeyPicker

    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local pickerVal = (globalOptions.MenuKeyPicker and globalOptions.MenuKeyPicker.Value) or "RightShift"
        if input.KeyCode.Name == pickerVal then
            return
        end
        if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightControl then
            task.spawn(Library.Toggle)
        end
    end)

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

    if SaveManager then
        SaveManager:SetLibrary(Library)
        SaveManager:SetFolder("RivalsHub")
        SaveManager:BuildConfigSection(Tabs.Settings)
        SaveManager:LoadAutoloadConfig()
    end

    Library:SetWatermark("RIVALS HUB | Zero-Lag")
    Library:SetWatermarkVisibility(Config.Settings.ShowWatermark)

    Library:OnUnload(function()
        if typeof(onUnload) == "function" then
            onUnload()
        end
    end)

    Library:Notify("RIVALS HUB Loaded! Press [RightShift] or [Insert] to toggle menu", 5)

    return {
        Library = Library,
        Window = Window,
    }
end

end

---------------------------------------------------------------------
-- APPLICATION LIFECYCLE
---------------------------------------------------------------------
local App = {
    Config = Config,
    SkinData = SkinData,
    SaveManager = SaveManager,
    SkinChanger = SkinChanger,
    Aura = Aura,
    Tracers = Tracers,
    ESP2D = ESP2D,
    Chams = Chams,
    GameHook = GameHook,
    UI = nil,
}

function App.Destroy()
    GameHook.Destroy(Config, Aura, Tracers, ESP2D, Chams)
    if SkinChanger and SkinChanger.Destroy then
        pcall(SkinChanger.Destroy)
    end
    if App.UI and App.UI.Library and App.UI.Library.Unload then
        pcall(App.UI.Library.Unload)
    end
    if env.RivalsHubInstance == App then
        env.RivalsHubInstance = nil
    end
end

env.RivalsHubInstance = App

GameHook.Init(Config, Aura, Tracers, ESP2D, Chams)
if SkinChanger and SkinChanger.HookGame then
    SkinChanger.HookGame()
end

App.UI = buildUI(function()
    App.Destroy()
end)

return App

