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
local ESP2D = loadModule("Visuals/ESP2D.luau")
local Chams = loadModule("Visuals/Chams.luau")
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
    ESP2D = ESP2D,
    Chams = Chams,
    GameHook = GameHook,
    Interface = nil,
}

function App.Destroy()
    if App.GameHook then
        App.GameHook.Destroy(App.Config, App.Aura, App.Tracers, App.ESP2D, App.Chams)
    end
    if App.Interface and App.Interface.Library and App.Interface.Library.Unload then
        pcall(App.Interface.Library.Unload)
    end
    if env.RivalsHubInstance == App then
        env.RivalsHubInstance = nil
    end
end

env.RivalsHubInstance = App

GameHook.Init(Config, Aura, Tracers, ESP2D, Chams)
App.Interface = Interface.Init(Config, Aura, Tracers, GameHook, Chams, function()
    App.Destroy()
end)

return App
