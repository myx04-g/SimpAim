--[[ SimpAIM Fixed Version ]]--

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local camera = workspace:WaitForChild("CurrentCamera")

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
local freecamOrigin = nil

-- ===== Splash =====
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

-- Animate splash
TweenService:Create(splashLabel, TweenInfo.new(2), {TextTransparency=0}):Play()
wait(3)
splashGui:Destroy()

-- ===== Main GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpAIM_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,350,0,300)
frame.Position = UDim2.new(0.5,-175,0.3,-150)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = frame

-- Minimize button
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

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,5)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 20
closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
closeBtn.TextColor3 = Color3.fromRGB(0,0,0)
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    -- Clean up highlights
    for char,_ in pairs(highlights) do
        if highlights[char] then highlights[char]:Destroy() end
    end
    highlights = {}
    -- Disconnect any events by stopping RenderStepped connections
    systemActive = false
    rightMouseDown = false
    lockedTarget = nil
end)

-- Hotkeys frame (scrollable)
local hotkeysFrame = Instance.new("ScrollingFrame")
hotkeysFrame.Size = UDim2.new(1,-20,0,150)
hotkeysFrame.Position = UDim2.new(0,10,0,40)
hotkeysFrame.CanvasSize = UDim2.new(0,0,0,0)
hotkeysFrame.BackgroundTransparency = 0.2
hotkeysFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
hotkeysFrame.BorderSizePixel = 0
hotkeysFrame.Parent = frame

local uiList = Instance.new("UIListLayout")
uiList.Padding = UDim.new(0,5)
uiList.Parent = hotkeysFrame
uiList.SortOrder = Enum.SortOrder.LayoutOrder

local function addHotkeyText(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0,25)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Text = text
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = hotkeysFrame
    hotkeysFrame.CanvasSize = UDim2.new(0,0,0,uiList.AbsoluteContentSize.Y)
end

-- Add default hotkeys
addHotkeyText("Q - Toggle Camera Lock")
addHotkeyText("M - Toggle GUI visibility")
addHotkeyText("J - Toggle Freecam")
addHotkeyText("Shift+Q - Toggle Glow")

-- ===== Glow Functions =====
local function createHighlight(character)
    if not character then return end
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
        highlights[character]=nil
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
    for char,_ in pairs(highlights) do
        removeHighlight(char)
    end
end

local function toggleGlow()
    glowActive = not glowActive
    if glowActive then enableGlow() else disableGlow() end
end

-- ===== Camera Helpers =====
local function getNearestPlayer()
    local closest = nil
    local shortest = math.huge
    local mousePos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    for _,p in pairs(Players:GetPlayers()) do
        if p~=player and p.Character and p.Character:FindFirstChild("Head") then
            local headPos,onScreen = camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (mousePos - Vector2.new(headPos.X,headPos.Y)).Magnitude
                if dist<shortest then shortest=dist closest=p end
            end
        end
    end
    return closest
end

-- ===== Freecam =====
local function toggleFreecam()
    if not freecamActive then
        freecamOrigin = player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.CFrame or nil
        freecamActive = true
    else
        if freecamOrigin and player.Character and player.Character.PrimaryPart then
            player.Character:SetPrimaryPartCFrame(freecamOrigin)
        end
        freecamActive = false
    end
end

-- ===== Input Handling =====
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q and not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        systemActive = not systemActive
        if not systemActive then rightMouseDown=false lockedTarget=nil end
    end
    if input.KeyCode == Enum.KeyCode.Q and (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
        toggleGlow()
    end
    if input.KeyCode == Enum.KeyCode.M then
        guiVisible = not guiVisible
        frame.Visible = guiVisible
    end
    if input.KeyCode == Enum.KeyCode.J then
        toggleFreecam()
    end
    if systemActive and input.UserInputType==Enum.UserInputType.MouseButton2 then
        rightMouseDown=true
        lockedTarget = getNearestPlayer()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2 then
        rightMouseDown=false
        lockedTarget=nil
    end
end)

-- ===== Camera Lock Loop =====
RunService.RenderStepped:Connect(function(dt)
    if systemActive and rightMouseDown and lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("Head") then
        local targetPos = lockedTarget.Character.Head.Position
        local camPos = camera.CFrame.Position
        local newCFrame = CFrame.lookAt(camPos, targetPos)
        camera.CFrame = newCFrame

        -- Rotate player body toward target safely
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local lookVector = (targetPos - hrp.Position)
            if lookVector.Magnitude>0 then
                local newHRP = CFrame.new(hrp.Position, hrp.Position + Vector3.new(lookVector.X,0,lookVector.Z))
                hrp.CFrame = newHRP
            end
        end
    end
end)
