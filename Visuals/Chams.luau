local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
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

return Chams
