local baseUrl = "https://raw.githubusercontent.com/18tibyrobin-arch/bvuzyfazaeaeaze/main/"

local function loadModule(relPath: string)
    local okFile, fileFunc = pcall(function()
        return loadfile(relPath) or loadfile("hub/" .. relPath)
    end)
    if okFile and type(fileFunc) == "function" then
        return fileFunc()
    end

    local urls = {
        baseUrl .. relPath,
        baseUrl .. "hub/" .. relPath,
    }

    for _, url in ipairs(urls) do
        local okHttp, content = pcall(function()
            return game:HttpGet(url)
        end)
        if okHttp and content and #content > 0 then
            local loaded = loadstring(content)
            if loaded then
                return loaded()
            end
        end
    end

    error("[RivalsHub] Could not load module: " .. relPath)
end

local Config = loadModule("Core/Config.luau")
local Aura = loadModule("Visuals/Aura.luau")
local Tracers = loadModule("Visuals/Tracers.luau")
local GameHook = loadModule("Core/GameHook.luau")
local Interface = loadModule("UI/Interface.luau")

local env = (typeof(getgenv) == "function" and getgenv()) or _G
if env.RivalsHubInstance and typeof(env.RivalsHubInstance.Destroy) == "function" then
    pcall(env.RivalsHubInstance.Destroy)
end

local App = {
    Config = Config,
    Aura = Aura,
    Tracers = Tracers,
    GameHook = GameHook,
    Interface = nil,
}

function App.Destroy()
    if App.GameHook then
        App.GameHook.Destroy(App.Config, App.Aura, App.Tracers)
    end
    if App.Interface and App.Interface.Rayfield and App.Interface.Rayfield.Destroy then
        pcall(App.Interface.Rayfield.Destroy)
    end
    if env.RivalsHubInstance == App then
        env.RivalsHubInstance = nil
    end
end

env.RivalsHubInstance = App

GameHook.Init(Config, Aura, Tracers)
App.Interface = Interface.Init(Config, Aura, Tracers, GameHook, function()
    App.Destroy()
end)

return App
