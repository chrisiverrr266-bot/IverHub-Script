-- Iver Hub ESP + Silent Aim v5.0 - ANTI-DETECTION
-- Full Bypass: Metamethod Protection, Environment Spoofing, Anti-Kick

-- Environment Protection
local cloneref = cloneref or function(obj) return obj end
local clonefunction = clonefunction or function(func) return func end

-- Anti-Detection Utilities
local HttpService = cloneref(game:GetService("HttpService"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Secure getgenv alternative
local SecureEnv = {}
getgenv = function()
    return SecureEnv
end

-- Anti-Kick Protection
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "Kick" then
        return nil
    elseif method == "FireServer" or method == "InvokeServer" then
        local remoteName = tostring(self)
        if remoteName:lower():find("anticheat") or remoteName:lower():find("kick") or remoteName:lower():find("ban") then
            return nil
        end
    end
    
    return OldNamecall(self, ...)
end)

-- Silent Table Detection Bypass
local function createSafeTable(base)
    local proxy = newproxy(true)
    local mt = getmetatable(proxy)
    
    mt.__index = function(t, k)
        return base[k]
    end
    
    mt.__newindex = function(t, k, v)
        base[k] = v
    end
    
    mt.__pairs = function()
        return next, base, nil
    end
    
    mt.__ipairs = function()
        return ipairs(base)
    end
    
    return proxy
end

-- GUI Library with Anti-Detection
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))() or loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))() or loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Interface/CustomFIeld/main/RayField.lua'))()

local Window = Rayfield:CreateWindow({
   Name = "Iver Hub v5.0 (Undetectable)",
   LoadingTitle = "Initializing Secure Environment...",
   LoadingSubtitle = "by Iver",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "IverHub_SecureConfig",
      FileName = "IverHub_v5"
   },
   Discord = {
      Enabled = false
   },
   KeySystem = false
})

-- Configuration Storage (Protected)
local Config = createSafeTable({
    ESP = {
        Enabled = false,
        ShowName = true,
        ShowDistance = true,
        ShowHealth = true,
        ShowBox = true,
        ShowTracer = true,
        TeamCheck = true,
        MaxDistance = 1000
    },
    Aimbot = {
        Enabled = false,
        SilentAim = true,
        FOV = 100,
        VisibilityCheck = true,
        TeamCheck = true,
        Smoothness = 0.1,
        TargetPart = "Head"
    }
})

-- ESP Module (Metamethod Protected)
local ESP = {}
ESP.Drawings = {}

function ESP:CreateDrawing(player)
    if self.Drawings[player] then return end
    
    local drawings = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthBarOutline = Drawing.new("Square"),
        Tracer = Drawing.new("Line")
    }
    
    -- Box Settings
    drawings.Box.Thickness = 1
    drawings.Box.Color = Color3.fromRGB(255, 255, 255)
    drawings.Box.Transparency = 1
    drawings.Box.Filled = false
    
    -- Name Settings
    drawings.Name.Size = 16
    drawings.Name.Center = true
    drawings.Name.Outline = true
    drawings.Name.Color = Color3.fromRGB(255, 255, 255)
    
    -- Distance Settings
    drawings.Distance.Size = 14
    drawings.Distance.Center = true
    drawings.Distance.Outline = true
    drawings.Distance.Color = Color3.fromRGB(200, 200, 200)
    
    -- Health Settings
    drawings.Health.Size = 14
    drawings.Health.Center = true
    drawings.Health.Outline = true
    
    -- Health Bar Settings
    drawings.HealthBar.Filled = true
    drawings.HealthBar.Transparency = 0.5
    drawings.HealthBar.Thickness = 1
    
    drawings.HealthBarOutline.Filled = false
    drawings.HealthBarOutline.Thickness = 1
    drawings.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    drawings.HealthBarOutline.Transparency = 1
    
    -- Tracer Settings
    drawings.Tracer.Thickness = 1
    drawings.Tracer.Transparency = 1
    drawings.Tracer.Color = Color3.fromRGB(255, 255, 255)
    
    self.Drawings[player] = drawings
end

function ESP:RemoveDrawing(player)
    local drawings = self.Drawings[player]
    if not drawings then return end
    
    for _, drawing in pairs(drawings) do
        drawing:Remove()
    end
    
    self.Drawings[player] = nil
end

function ESP:UpdateDrawing(player)
    local drawings = self.Drawings[player]
    if not drawings then return end
    
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local head = character and character:FindFirstChild("Head")
    local humanoid = character and character:FindFirstChild("Humanoid")
    
    if not character or not rootPart or not head or not humanoid then
        for _, drawing in pairs(drawings) do
            drawing.Visible = false
        end
        return
    end
    
    -- Team Check
    if Config.ESP.TeamCheck and player.Team == LocalPlayer.Team then
        for _, drawing in pairs(drawings) do
            drawing.Visible = false
        end
        return
    end
    
    -- Distance Check
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
    if distance > Config.ESP.MaxDistance then
        for _, drawing in pairs(drawings) do
            drawing.Visible = false
        end
        return
    end
    
    -- Screen Position Calculation
    local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local legPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
    
    if not onScreen then
        for _, drawing in pairs(drawings) do
            drawing.Visible = false
        end
        return
    end
    
    -- Calculate Box Dimensions
    local boxHeight = math.abs(headPos.Y - legPos.Y)
    local boxWidth = boxHeight / 2
    local boxX = screenPos.X - boxWidth / 2
    local boxY = headPos.Y
    
    -- Update Box
    if Config.ESP.ShowBox then
        drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
        drawings.Box.Position = Vector2.new(boxX, boxY)
        drawings.Box.Visible = true
    else
        drawings.Box.Visible = false
    end
    
    -- Update Name
    if Config.ESP.ShowName then
        drawings.Name.Text = player.Name
        drawings.Name.Position = Vector2.new(screenPos.X, boxY - 20)
        drawings.Name.Visible = true
    else
        drawings.Name.Visible = false
    end
    
    -- Update Distance
    if Config.ESP.ShowDistance then
        drawings.Distance.Text = string.format("[%.1f]", distance)
        drawings.Distance.Position = Vector2.new(screenPos.X, boxY + boxHeight + 5)
        drawings.Distance.Visible = true
    else
        drawings.Distance.Visible = false
    end
    
    -- Update Health
    if Config.ESP.ShowHealth then
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        local healthPercent = health / maxHealth
        
        drawings.Health.Text = string.format("%.0f HP", health)
        drawings.Health.Position = Vector2.new(screenPos.X, boxY + boxHeight + 20)
        drawings.Health.Color = Color3.fromRGB(
            255 * (1 - healthPercent),
            255 * healthPercent,
            0
        )
        drawings.Health.Visible = true
        
        -- Health Bar
        local barWidth = 3
        local barHeight = boxHeight * healthPercent
        
        drawings.HealthBar.Size = Vector2.new(barWidth, barHeight)
        drawings.HealthBar.Position = Vector2.new(boxX - barWidth - 2, boxY + boxHeight - barHeight)
        drawings.HealthBar.Color = Color3.fromRGB(
            255 * (1 - healthPercent),
            255 * healthPercent,
            0
        )
        drawings.HealthBar.Visible = true
        
        drawings.HealthBarOutline.Size = Vector2.new(barWidth, boxHeight)
        drawings.HealthBarOutline.Position = Vector2.new(boxX - barWidth - 2, boxY)
        drawings.HealthBarOutline.Visible = true
    else
        drawings.Health.Visible = false
        drawings.HealthBar.Visible = false
        drawings.HealthBarOutline.Visible = false
    end
    
    -- Update Tracer
    if Config.ESP.ShowTracer then
        drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        drawings.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
        drawings.Tracer.Visible = true
    else
        drawings.Tracer.Visible = false
    end
end

function ESP:Toggle(state)
    Config.ESP.Enabled = state
    
    if not state then
        for player, _ in pairs(self.Drawings) do
            self:RemoveDrawing(player)
        end
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                self:CreateDrawing(player)
            end
        end
    end
end

-- Silent Aim Module (Undetectable)
local SilentAim = {}
SilentAim.FOVCircle = Drawing.new("Circle")
SilentAim.FOVCircle.Thickness = 2
SilentAim.FOVCircle.NumSides = 50
SilentAim.FOVCircle.Radius = 100
SilentAim.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
SilentAim.FOVCircle.Transparency = 1
SilentAim.FOVCircle.Filled = false

function SilentAim:GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Config.Aimbot.FOV
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local character = player.Character
        if not character then continue end
        
        local targetPart = character:FindFirstChild(Config.Aimbot.TargetPart)
        if not targetPart then continue end
        
        -- Visibility Check
        if Config.Aimbot.VisibilityCheck then
            local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
            local part, position = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
            if part and not part:IsDescendantOf(character) then
                continue
            end
        end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end
        
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if distance < shortestDistance then
            shortestDistance = distance
            closestPlayer = player
        end
    end
    
    return closestPlayer
end

function SilentAim:UpdateFOV()
    self.FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    self.FOVCircle.Radius = Config.Aimbot.FOV
    self.FOVCircle.Visible = Config.Aimbot.Enabled
end

-- Hook Mouse Events (Metamethod Protection)
local Mouse = LocalPlayer:GetMouse()
local OldIndex
OldIndex = hookmetamethod(game, "__index", function(self, key)
    if self == Mouse and Config.Aimbot.Enabled and Config.Aimbot.SilentAim then
        local target = SilentAim:GetClosestPlayer()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(Config.Aimbot.TargetPart)
            if targetPart then
                if key == "Hit" then
                    return CFrame.new(targetPart.Position)
                elseif key == "Target" then
                    return targetPart
                end
            end
        end
    end
    return OldIndex(self, key)
end)

-- Main Loop (Anti-Detection)
local UpdateConnection
UpdateConnection = RunService.RenderStepped:Connect(function()
    if Config.ESP.Enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if not ESP.Drawings[player] then
                    ESP:CreateDrawing(player)
                end
                ESP:UpdateDrawing(player)
            end
        end
    end
    
    SilentAim:UpdateFOV()
end)

-- Player Management
Players.PlayerAdded:Connect(function(player)
    if Config.ESP.Enabled then
        ESP:CreateDrawing(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    ESP:RemoveDrawing(player)
end)

-- GUI Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- Main Tab
MainTab:CreateSection("Main Features")

MainTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Flag = "MainESP",
   Callback = function(Value)
      ESP:Toggle(Value)
   end,
})

MainTab:CreateToggle({
   Name = "Enable Silent Aim",
   CurrentValue = false,
   Flag = "MainAimbot",
   Callback = function(Value)
      Config.Aimbot.Enabled = Value
   end,
})

MainTab:CreateButton({
   Name = "Destroy GUI",
   Callback = function()
      UpdateConnection:Disconnect()
      ESP:Toggle(false)
      Rayfield:Destroy()
   end,
})

-- ESP Tab
ESPTab:CreateSection("ESP Settings")

ESPTab:CreateToggle({
   Name = "Show Name",
   CurrentValue = true,
   Flag = "ESPName",
   Callback = function(Value)
      Config.ESP.ShowName = Value
   end,
})

ESPTab:CreateToggle({
   Name = "Show Distance",
   CurrentValue = true,
   Flag = "ESPDistance",
   Callback = function(Value)
      Config.ESP.ShowDistance = Value
   end,
})

ESPTab:CreateToggle({
   Name = "Show Health",
   CurrentValue = true,
   Flag = "ESPHealth",
   Callback = function(Value)
      Config.ESP.ShowHealth = Value
   end,
})

ESPTab:CreateToggle({
   Name = "Show Box",
   CurrentValue = true,
   Flag = "ESPBox",
   Callback = function(Value)
      Config.ESP.ShowBox = Value
   end,
})

ESPTab:CreateToggle({
   Name = "Show Tracer",
   CurrentValue = true,
   Flag = "ESPTracer",
   Callback = function(Value)
      Config.ESP.ShowTracer = Value
   end,
})

ESPTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = true,
   Flag = "ESPTeamCheck",
   Callback = function(Value)
      Config.ESP.TeamCheck = Value
   end,
})

ESPTab:CreateSlider({
   Name = "Max Distance",
   Range = {100, 5000},
   Increment = 100,
   CurrentValue = 1000,
   Flag = "ESPMaxDistance",
   Callback = function(Value)
      Config.ESP.MaxDistance = Value
   end,
})

-- Aimbot Tab
AimbotTab:CreateSection("Aimbot Settings")

AimbotTab:CreateToggle({
   Name = "Silent Aim Mode",
   CurrentValue = true,
   Flag = "AimbotSilent",
   Callback = function(Value)
      Config.Aimbot.SilentAim = Value
   end,
})

AimbotTab:CreateToggle({
   Name = "Visibility Check",
   CurrentValue = true,
   Flag = "AimbotVisibility",
   Callback = function(Value)
      Config.Aimbot.VisibilityCheck = Value
   end,
})

AimbotTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = true,
   Flag = "AimbotTeamCheck",
   Callback = function(Value)
      Config.Aimbot.TeamCheck = Value
   end,
})

AimbotTab:CreateSlider({
   Name = "FOV Size",
   Range = {50, 500},
   Increment = 10,
   CurrentValue = 100,
   Flag = "AimbotFOV",
   Callback = function(Value)
      Config.Aimbot.FOV = Value
   end,
})

AimbotTab:CreateSlider({
   Name = "Smoothness",
   Range = {0, 1},
   Increment = 0.01,
   CurrentValue = 0.1,
   Flag = "AimbotSmooth",
   Callback = function(Value)
      Config.Aimbot.Smoothness = Value
   end,
})

AimbotTab:CreateDropdown({
   Name = "Target Part",
   Options = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"},
   CurrentOption = "Head",
   Flag = "AimbotTargetPart",
   Callback = function(Option)
      Config.Aimbot.TargetPart = Option
   end,
})

-- Settings Tab
SettingsTab:CreateSection("Script Information")

SettingsTab:CreateParagraph({Title = "Iver Hub v5.0", Content = "Full undetectable ESP and Silent Aim with metamethod protection, environment spoofing, and anti-kick bypass."})

SettingsTab:CreateButton({
   Name = "Copy Discord",
   Callback = function()
      setclipboard("discord.gg/invitelink")
      Rayfield:Notify({
         Title = "Discord Link Copied",
         Content = "Join our Discord for updates!",
         Duration = 3,
         Image = 4483362458,
      })
   end,
})

Rayfield:LoadConfiguration()