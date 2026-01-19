-- Iver Hub ESP (Optimized) + Linoria UI
-- Lag-fixed, pooled ESP, single update loop

-- ================= UI =================
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Iver Hub (Optimized)",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab("Main"),
    ESP = Window:AddTab("ESP"),
    Settings = Window:AddTab("Settings")
}

local ESPBox = Tabs.ESP:AddLeftGroupbox("ESP Options")
local MainBox = Tabs.Main:AddLeftGroupbox("Main")

-- ================= SETTINGS =================
local Settings = {
    ESP = {
        Enabled = false,
        ShowBox = true,
        ShowName = true,
        ShowDistance = true,
        ShowHealthBar = true,
        ShowTracers = false,
        MaxDistance = 1000
    }
}

-- ================= SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ================= ESP SYSTEM =================
local ESPPool = {} -- Reusable drawing objects
local ActiveESP = {} -- Currently assigned ESP objects

local function getDrawing(drawingType)
    local pool = ESPPool[drawingType]
    if not pool then
        pool = {}
        ESPPool[drawingType] = pool
    end
    return table.remove(pool) or Drawing.new(drawingType)
end

local function returnDrawing(drawing, drawingType)
    drawing.Visible = false
    table.insert(ESPPool[drawingType], drawing)
end

local function createESP(player)
    local esp = {
        Box = getDrawing("Square"),
        BoxOutline = getDrawing("Square"),
        Name = getDrawing("Text"),
        Distance = getDrawing("Text"),
        HealthBar = getDrawing("Square"),
        HealthBarOutline = getDrawing("Square"),
        Tracer = getDrawing("Line")
    }

    -- Configure Box
    esp.Box.Thickness = 1
    esp.Box.Filled = false
    esp.Box.Color = Color3.fromRGB(255, 255, 255)
    esp.BoxOutline.Thickness = 3
    esp.BoxOutline.Filled = false
    esp.BoxOutline.Color = Color3.fromRGB(0, 0, 0)

    -- Configure Text
    esp.Name.Size = 13
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.Distance.Size = 13
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Color = Color3.fromRGB(255, 255, 0)

    -- Configure Health Bar
    esp.HealthBar.Filled = true
    esp.HealthBarOutline.Thickness = 1
    esp.HealthBarOutline.Filled = false
    esp.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)

    -- Configure Tracer
    esp.Tracer.Thickness = 1
    esp.Tracer.Color = Color3.fromRGB(255, 255, 255)

    ActiveESP[player] = esp
end

local function removeESP(player)
    local esp = ActiveESP[player]
    if not esp then return end

    for drawingType, drawing in pairs(esp) do
        returnDrawing(drawing, drawing.ClassName)
    end
    ActiveESP[player] = nil
end

local function updateESP()
    if not Settings.ESP.Enabled then
        for player in pairs(ActiveESP) do
            removeESP(player)
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local head = character and character:FindFirstChild("Head")
        local humanoid = character and character:FindFirstChild("Humanoid")

        if not hrp or not head or not humanoid then
            if ActiveESP[player] then removeESP(player) end
            continue
        end

        local distance = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
        if distance > Settings.ESP.MaxDistance then
            if ActiveESP[player] then removeESP(player) end
            continue
        end

        if not ActiveESP[player] then createESP(player) end
        local esp = ActiveESP[player]

        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local hrpPos = Camera:WorldToViewportPoint(hrp.Position)

        if not onScreen then
            for _, drawing in pairs(esp) do
                drawing.Visible = false
            end
            continue
        end

        local height = math.abs(headPos.Y - legPos.Y)
        local width = height / 2

        -- Update Box
        if Settings.ESP.ShowBox then
            esp.BoxOutline.Size = Vector2.new(width, height)
            esp.BoxOutline.Position = Vector2.new(hrpPos.X - width / 2, headPos.Y)
            esp.BoxOutline.Visible = true
            esp.Box.Size = Vector2.new(width, height)
            esp.Box.Position = Vector2.new(hrpPos.X - width / 2, headPos.Y)
            esp.Box.Visible = true
        else
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
        end

        -- Update Name
        if Settings.ESP.ShowName then
            esp.Name.Text = player.Name
            esp.Name.Position = Vector2.new(hrpPos.X, headPos.Y - 15)
            esp.Name.Visible = true
        else
            esp.Name.Visible = false
        end

        -- Update Distance
        if Settings.ESP.ShowDistance then
            esp.Distance.Text = math.floor(distance) .. "m"
            esp.Distance.Position = Vector2.new(hrpPos.X, legPos.Y + 5)
            esp.Distance.Visible = true
        else
            esp.Distance.Visible = false
        end

        -- Update Health Bar
        if Settings.ESP.ShowHealthBar then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            esp.HealthBarOutline.Size = Vector2.new(4, height)
            esp.HealthBarOutline.Position = Vector2.new(hrpPos.X - width / 2 - 6, headPos.Y)
            esp.HealthBarOutline.Visible = true
            esp.HealthBar.Size = Vector2.new(2, height * healthPercent)
            esp.HealthBar.Position = Vector2.new(hrpPos.X - width / 2 - 5, headPos.Y + height * (1 - healthPercent))
            esp.HealthBar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
            esp.HealthBar.Visible = true
        else
            esp.HealthBar.Visible = false
            esp.HealthBarOutline.Visible = false
        end

        -- Update Tracer
        if Settings.ESP.ShowTracers then
            esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            esp.Tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
            esp.Tracer.Visible = true
        else
            esp.Tracer.Visible = false
        end
    end
end

-- Single optimized update loop
RunService.Heartbeat:Connect(function()
    updateESP()
end)

-- Player management
Players.PlayerRemoving:Connect(removeESP)

-- ================= UI TOGGLES =================
ESPBox:AddToggle("EnableESP", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(value)
        Settings.ESP.Enabled = value
    end
})

ESPBox:AddToggle("ShowBox", {
    Text = "Show Box",
    Default = true,
    Callback = function(value)
        Settings.ESP.ShowBox = value
    end
})

ESPBox:AddToggle("ShowName", {
    Text = "Show Name",
    Default = true,
    Callback = function(value)
        Settings.ESP.ShowName = value
    end
})

ESPBox:AddToggle("ShowDistance", {
    Text = "Show Distance",
    Default = true,
    Callback = function(value)
        Settings.ESP.ShowDistance = value
    end
})

ESPBox:AddToggle("ShowHealthBar", {
    Text = "Show Health Bar",
    Default = true,
    Callback = function(value)
        Settings.ESP.ShowHealthBar = value
    end
})

ESPBox:AddToggle("ShowTracers", {
    Text = "Show Tracers",
    Default = false,
    Callback = function(value)
        Settings.ESP.ShowTracers = value
    end
})

ESPBox:AddSlider("MaxDistance", {
    Text = "Max Distance",
    Default = 1000,
    Min = 100,
    Max = 5000,
    Rounding = 0,
    Callback = function(value)
        Settings.ESP.MaxDistance = value
    end
})

-- ================= THEME & SAVE =================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("IverHub")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify("Iver Hub Loaded!", 3)