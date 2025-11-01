--[[ SimpAIM Fixed Version ]]--

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Wait safely for Camera
local camera = workspace:FindFirstChild("CurrentCamera")
while not camera do
    wait(0.1)
    camera = workspace:FindFirstChild("CurrentCamera")
end

-- Wait for PlayerGui
local PlayerGui = player:WaitForChild("PlayerGui")

-- Prevent duplicate GUI
if PlayerGui:FindFirstChild("SimpAIM_UI") then PlayerGui.SimpAIM_UI:Destroy() end
if PlayerGui:FindFirstChild("SimpAIM_Splash") then PlayerGui.SimpAIM_Splash:Destroy() end

-- Flags
local systemActive = false
local rightMouseDown = false
local lockedTarget = nil
local glowActive = false
local highlights = {}
local guiVisible = true
local freecamActive = false
local originalCameraCFrame

-- ===== Splash =====
do
    local splashGui = Instance.new("ScreenGui")
    splashGui.Name = "SimpAIM_Splash"
    splashGui.ResetOnSpawn = false
    splashGui.Parent = PlayerGui

    local splashLabel = Instance.new("TextLabel")
    splashLabel.Size = UDim2.new(0,300,0,80)
    splashLabel.Position = UDim2.new(0.5,-150,0.5,-40)
    splashLabel.BackgroundTransparency = 0.5
    splashLabel.BackgroundColor3 = Color3.new(0,0,0)
    splashLabel.TextColor3 = Color3.new(1,1,1)
    splashLabel.TextScaled = true
    splashLabel.Font = Enum.Font.SourceSansBold
    splashLabel.Text = "SimpAIM"
    splashLabel.TextTransparency = 1
    splashLabel.Parent = splashGui

    TweenService:Create(splashLabel, TweenInfo.new(2), {TextTransparency=0}):Play()
    wait(3)
    splashGui:Destroy()
end

-- ===== Main GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpAIM_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,300,0,300)
frame.Position = UDim2.new(0.5,-150,0.3,-150)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = frame

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0,30,0,30)
minimizeBtn.Position = UDim2.new(1,-70,0,5)
minimizeBtn.Text = "_"
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 20
minimizeBtn.BackgroundColor3 = Color3.fromRGB(200,200,200)
minimizeBtn.TextColor3 = Color3.fromRGB(0,0,0)
minimizeBtn.Parent = frame
minimizeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    guiVisible = false
end)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,5)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 20
closeBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function()
    systemActive = false
    rightMouseDown = false
    lockedTarget = nil
    glowActive = false
    freecamActive = false
    for _,h in pairs(highlights) do h:Destroy() end
    screenGui:Destroy()
end)

-- Hotkeys Label (scrollable)
local hotkeyFrame = Instance.new("ScrollingFrame")
hotkeyFrame.Size = UDim2.new(0,280,0,100)
hotkeyFrame.Position = UDim2.new(0,10,0,40)
hotkeyFrame.BackgroundTransparency = 0.2
hotkeyFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
hotkeyFrame.CanvasSize = UDim2.new(0,0,1,0)
hotkeyFrame.ScrollBarThickness = 6
hotkeyFrame.Parent = frame

local hotkeysList = {
    "Q - Toggle Camera Lock",
    "Shift+Q - Toggle Glow",
    "M - Toggle GUI",
    "N - Show Hotkeys",
    "J - Toggle Freecam",
}

local function refreshHotkeys()
    for _,v in pairs(hotkeyFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    for i,txt in ipairs(hotkeysList) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,0,20)
        label.Position = UDim2.new(0,0,0,(i-1)*22)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,1,1)
        label.Font = Enum.Font.SourceSans
        label.TextSize = 18
        label.Text = txt
        label.Parent = hotkeyFrame
    end
    hotkeyFrame.CanvasSize = UDim2.new(0,0,0,#hotkeysList*22)
end

refreshHotkeys()

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0,280,0,50)
statusLabel.Position = UDim2.new(0,10,0,150)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 18
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Text = "Camera Lock: Inactive | Idle\nGlow: OFF"
statusLabel.Parent = frame

-- ===== Glow Functions =====
local function createHighlight(character)
    if highlights[character] then highlights[character]:Destroy() end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255,0,0)
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    highlights[character] = highlight
end

local function removeHighlight(character)
    if highlights[character] then
        highlights[character]:Destroy()
        highlights[character] = nil
    end
end

local function enableGlow()
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Character then createHighlight(p.Character) end
        p.CharacterAdded:Connect(function(char)
            if glowActive then createHighlight(char) end
        end)
    end
end

local function disableGlow()
    for char,_ in pairs(highlights) do removeHighlight(char) end
end

local function toggleGlow()
    glowActive = not glowActive
    if glowActive then enableGlow() else disableGlow() end
end

-- ===== Camera Helpers =====
local function getNearestPlayer()
    local closest = nil
    local shortest = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _,p in pairs(Players:GetPlayers()) do
        if p~=player and p.Character and p.Character:FindFirstChild("Head") then
            local headPos,onScreen = camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(headPos.X,headPos.Y)-Vector2.new(mousePos.X,mousePos.Y)).Magnitude
                if dist<shortest then
                    shortest=dist
                    closest=p
                end
            end
        end
    end
    return closest
end

-- ===== Freecam =====
local function toggleFreecam()
    if not freecamActive then
        originalCameraCFrame = camera.CFrame
        freecamActive = true
    else
        if originalCameraCFrame then camera.CFrame = originalCameraCFrame end
        freecamActive = false
    end
end

-- ===== Input Handling =====
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            toggleGlow()
        else
            systemActive = not systemActive
            if not systemActive then rightMouseDown=false lockedTarget=nil end
        end
    elseif input.KeyCode == Enum.KeyCode.M then
        guiVisible = not guiVisible
        frame.Visible = guiVisible
    elseif input.KeyCode == Enum.KeyCode.N then
        refreshHotkeys()
    elseif input.KeyCode == Enum.KeyCode.J then
        toggleFreecam()
    elseif systemActive and input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseDown = true
        lockedTarget = getNearestPlayer()
    end
end)

UserInputService.InputEnded:Connect(function
