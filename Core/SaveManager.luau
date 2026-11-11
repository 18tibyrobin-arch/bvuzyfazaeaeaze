local httpService = game:GetService("HttpService")

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

return SaveManager
