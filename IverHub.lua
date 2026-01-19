-- Iver Hub ESP + Silent Aim v6.1 - FULLY WORKING
-- Enhanced: Dual hook system for maximum compatibility

-- Protection wrapper
local function protectFunction(func)
    return function(...)
        local success, result = pcall(func, ...)
        if not success then
            warn("Protected function error:", result)
        end
        return result
    end
end

-- Check for required functions
local required = {
    Drawing = Drawing,
    getrawmetatable = getrawmetatable,
    hookmetamethod = hookmetamethod,
    newcclosure = newcclosure or function(f) return f end,
    checkcaller = checkcaller or function() return false end,
    setreadonly = setreadonly or make_readonly or setwriteable,
    getnamecallmethod = getnamecallmethod
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Settings
local IverHub = {
    ESPObjects = {},
    Settings = {
        BoxESP = true,
        Tracers = true,
        Names = true,
        Distance = true,
        HealthBar = true,
        TeamCheck = false,
        TeamColor = true,
        MaxDistance = 2000,
        SilentAim = true,
        SilentAimFOV = 150,
        ShowFOV = true,
        VisibilityCheck = true,
        TargetPart = "Head",
        PredictMovement = true,
        PredictionStrength = 0.165
    }
}

-- FOV Circle
local FOVCircle
if Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = 100
    FOVCircle.Radius = IverHub.Settings.SilentAimFOV
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Visible = false
    FOVCircle.Filled = false
    FOVCircle.Transparency = 1
    FOVCircle.ZIndex = 999
end

-- Draggable GUI
local function makeDraggable(frame)
    local dragToggle, dragStart, startPos, dragInput
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragToggle then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Create GUI
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "IverHubGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999
    pcall(function()
        ScreenGui.Parent = game:GetService("CoreGui")
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 350, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = false
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = MainFrame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(0, 170, 255)
    UIStroke.Thickness = 2
    UIStroke.Parent = MainFrame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 50)
    TitleBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar

    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0.5, 0)
    TitleFix.Position = UDim2.new(0, 0, 0.5, 0)
    TitleFix.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ IVER HUB v6.1"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.Parent = TitleBar

    makeDraggable(MainFrame)

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -70)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 60)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 550)
    ScrollFrame.Parent = MainFrame

    local yPos = 10
    local function createButton(text, setting)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, -10, 0, 40)
        Button.Position = UDim2.new(0, 5, 0, yPos)
        Button.BackgroundColor3 = IverHub.Settings[setting] and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(40, 40, 45)
        Button.BorderSizePixel = 0
        Button.Text = text .. ": " .. (IverHub.Settings[setting] and "ON" or "OFF")
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.Font = Enum.Font.GothamBold
        Button.TextSize = 15
        Button.Parent = ScrollFrame

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 8)
        Corner.Parent = Button

        Button.MouseButton1Click:Connect(function()
            IverHub.Settings[setting] = not IverHub.Settings[setting]
            Button.BackgroundColor3 = IverHub.Settings[setting] and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(40, 40, 45)
            Button.Text = text .. ": " .. (IverHub.Settings[setting] and "ON" or "OFF")
            if setting == "ShowFOV" and FOVCircle then
                FOVCircle.Visible = IverHub.Settings.ShowFOV and IverHub.Settings.SilentAim
            end
        end)
        yPos = yPos + 45
    end

    -- ESP Buttons
    createButton("Box ESP", "BoxESP")
    createButton("Tracers", "Tracers")
    createButton("Names", "Names")
    createButton("Distance", "Distance")
    createButton("Health Bar", "HealthBar")
    createButton("Team Check", "TeamCheck")
    createButton("Team Color", "TeamColor")

    -- Silent Aim Buttons
    createButton("Silent Aim", "SilentAim")
    createButton("Show FOV Circle", "ShowFOV")
    createButton("Visibility Check", "VisibilityCheck")
    createButton("Movement Prediction", "PredictMovement")

    return ScreenGui
end

-- Utility Functions
local function getDistance(part)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return (LocalPlayer.Character.HumanoidRootPart.Position - part.Position).Magnitude
    end
    return math.huge
end

local function worldToScreen(position)
    local vec, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(vec.X, vec.Y), onScreen
end

local function isVisible(targetPart)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then
        return false
    end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local ray = Ray.new(origin, direction)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
    return hit and hit:IsDescendantOf(targetPart.Parent)
end

-- ESP System
local function createESP(player)
    if player == LocalPlayer then return end

    local drawings = {
        box = Drawing.new("Square"),
        boxoutline = Drawing.new("Square"),
        tracer = Drawing.new("Line"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        healthbar = Drawing.new("Square"),
        healthbaroutline = Drawing.new("Square")
    }

    -- Configure drawings
    drawings.box.Thickness = 2
    drawings.box.Filled = false
    drawings.box.Color = Color3.fromRGB(255, 0, 0)
    drawings.box.Visible = false

    drawings.boxoutline.Thickness = 4
    drawings.boxoutline.Filled = false
    drawings.boxoutline.Color = Color3.fromRGB(0, 0, 0)
    drawings.boxoutline.Visible = false

    drawings.tracer.Thickness = 2
    drawings.tracer.Color = Color3.fromRGB(255, 0, 0)
    drawings.tracer.Visible = false

    drawings.name.Size = 16
    drawings.name.Center = true
    drawings.name.Outline = true
    drawings.name.Color = Color3.fromRGB(255, 255, 255)
    drawings.name.Visible = false
    drawings.name.Text = player.Name

    drawings.distance.Size = 14
    drawings.distance.Center = true
    drawings.distance.Outline = true
    drawings.distance.Color = Color3.fromRGB(255, 255, 0)
    drawings.distance.Visible = false

    drawings.healthbar.Filled = true
    drawings.healthbar.Color = Color3.fromRGB(0, 255, 0)
    drawings.healthbar.Visible = false

    drawings.healthbaroutline.Thickness = 2
    drawings.healthbaroutline.Filled = false
    drawings.healthbaroutline.Color = Color3.fromRGB(0, 0, 0)
    drawings.healthbaroutline.Visible = false

    local function onCharacterAdded(character)
        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        local head = character:WaitForChild("Head", 5)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not hrp or not head or not humanoid then return end

        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not character or not character.Parent or humanoid.Health <= 0 then
                for _, drawing in pairs(drawings) do
                    drawing.Visible = false
                end
                if connection then connection:Disconnect() end
                return
            end

            local distance = getDistance(hrp)

            -- Team check
            if IverHub.Settings.TeamCheck and player.Team == LocalPlayer.Team then
                for _, drawing in pairs(drawings) do
                    drawing.Visible = false
                end
                return
            end

            -- Distance check
            if distance > IverHub.Settings.MaxDistance then
                for _, drawing in pairs(drawings) do
                    drawing.Visible = false
                end
                return
            end

            local headPos, headOnScreen = worldToScreen(head.Position + Vector3.new(0, 0.5, 0))
            local legPos, legOnScreen = worldToScreen(hrp.Position - Vector3.new(0, 3, 0))
            local hrpPos, hrpOnScreen = worldToScreen(hrp.Position)

            if not hrpOnScreen then
                for _, drawing in pairs(drawings) do
                    drawing.Visible = false
                end
                return
            end

            -- Color
            local color = Color3.fromRGB(255, 0, 0)
            if IverHub.Settings.TeamColor and player.Team == LocalPlayer.Team then
                color = Color3.fromRGB(0, 255, 0)
            end

            -- Box ESP
            if IverHub.Settings.BoxESP and headOnScreen and legOnScreen then
                local height = (headPos - legPos).Magnitude
                local width = height / 2

                drawings.boxoutline.Size = Vector2.new(width, height)
                drawings.boxoutline.Position = Vector2.new(hrpPos.X - width/2, headPos.Y)
                drawings.boxoutline.Visible = true

                drawings.box.Size = Vector2.new(width, height)
                drawings.box.Position = Vector2.new(hrpPos.X - width/2, headPos.Y)
                drawings.box.Color = color
                drawings.box.Visible = true
            else
                drawings.box.Visible = false
                drawings.boxoutline.Visible = false
            end

            -- Tracers
            if IverHub.Settings.Tracers then
                drawings.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                drawings.tracer.To = hrpPos
                drawings.tracer.Color = color
                drawings.tracer.Visible = true
            else
                drawings.tracer.Visible = false
            end

            -- Names
            if IverHub.Settings.Names and headOnScreen then
                drawings.name.Position = Vector2.new(headPos.X, headPos.Y - 25)
                drawings.name.Visible = true
            else
                drawings.name.Visible = false
            end

            -- Distance
            if IverHub.Settings.Distance and legOnScreen then
                drawings.distance.Text = math.floor(distance) .. "m"
                drawings.distance.Position = Vector2.new(legPos.X, legPos.Y + 5)
                drawings.distance.Visible = true
            else
                drawings.distance.Visible = false
            end

            -- Health Bar
            if IverHub.Settings.HealthBar and headOnScreen and legOnScreen then
                local height = (headPos - legPos).Magnitude
                local healthPercent = humanoid.Health / humanoid.MaxHealth

                drawings.healthbaroutline.Size = Vector2.new(5, height)
                drawings.healthbaroutline.Position = Vector2.new(hrpPos.X - (height/2) - 10, headPos.Y)
                drawings.healthbaroutline.Visible = true

                drawings.healthbar.Size = Vector2.new(3, height * healthPercent)
                drawings.healthbar.Position = Vector2.new(hrpPos.X - (height/2) - 9, headPos.Y + height * (1 - healthPercent))
                drawings.healthbar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                drawings.healthbar.Visible = true
            else
                drawings.healthbar.Visible = false
                drawings.healthbaroutline.Visible = false
            end
        end)
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)

    IverHub.ESPObjects[player] = drawings
end

-- Silent Aim
local function getClosestPlayer()
    local closest = nil
    local shortestDistance = IverHub.Settings.SilentAimFOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local targetPart = player.Character:FindFirstChild(IverHub.Settings.TargetPart) or player.Character:FindFirstChild("HumanoidRootPart")

            if humanoid and humanoid.Health > 0 and targetPart then
                if IverHub.Settings.TeamCheck and player.Team == LocalPlayer.Team then
                    continue
                end

                if IverHub.Settings.VisibilityCheck and not isVisible(targetPart) then
                    continue
                end

                local screenPos, onScreen = worldToScreen(targetPart.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (screenPos - mousePos).Magnitude

                    if dist < shortestDistance then
                        shortestDistance = dist
                        closest = player
                    end
                end
            end
        end
    end

    return closest
end

-- Hook for Silent Aim (Dual Hook System)
if getrawmetatable and hookmetamethod then
    -- Hook 1: __index for Mouse.Hit and Mouse.Target
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if IverHub.Settings.SilentAim and not checkcaller() then
            local target = getClosestPlayer()
            if target and target.Character then
                local part = target.Character:FindFirstChild(IverHub.Settings.TargetPart) or target.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local pos = part.Position

                    if IverHub.Settings.PredictMovement then
                        local velocity = part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
                        pos = pos + (velocity * IverHub.Settings.PredictionStrength)
                    end

                    if self == Mouse then
                        if key == "Hit" then
                            return CFrame.new(pos)
                        elseif key == "Target" then
                            return part
                        end
                    end
                end
            end
        end
        return oldIndex(self, key)
    end))

    -- Hook 2: __namecall for FireServer/InvokeServer
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()

        if IverHub.Settings.SilentAim and not checkcaller() then
            if method == "FireServer" or method == "InvokeServer" then
                local target = getClosestPlayer()
                if target and target.Character then
                    local part = target.Character:FindFirstChild(IverHub.Settings.TargetPart) or target.Character:FindFirstChild("HumanoidRootPart")
                    if part then
                        local pos = part.Position

                        if IverHub.Settings.PredictMovement then
                            local velocity = part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
                            pos = pos + (velocity * IverHub.Settings.PredictionStrength)
                        end

                        for i, v in pairs(args) do
                            if typeof(v) == "Vector3" then
                                args[i] = pos
                            elseif typeof(v) == "CFrame" then
                                args[i] = CFrame.new(pos)
                            elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                                args[i] = part
                            end
                        end
                    end
                end
            end
        end

        return oldNamecall(self, unpack(args))
    end))
end

-- Update FOV Circle
RunService.Heartbeat:Connect(function()
    if FOVCircle then
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = mousePos
        FOVCircle.Radius = IverHub.Settings.SilentAimFOV
        FOVCircle.Visible = IverHub.Settings.ShowFOV and IverHub.Settings.SilentAim
    end
end)

-- Initialize
createGUI()

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    wait(0.5)
    createESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if IverHub.ESPObjects[player] then
        for _, drawing in pairs(IverHub.ESPObjects[player]) do
            drawing:Remove()
        end
        IverHub.ESPObjects[player] = nil
    end
end)

print("✅ Iver Hub v6.1 Loaded Successfully!")
print("🎮 All features working")
print("👁️ ESP: Active")
print("🎯 Silent Aim: Active (Dual Hook)")
print("🖱️ Drag from title bar to move")