--[[ SimpAIM.lua - Full Version ]]--

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local camera = workspace:WaitForChild("CurrentCamera")

-- Prevent duplicates
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

TweenService:Create(splashLabel, TweenInfo.new(2), {TextTransparency=0}):Play()
task.delay(3, function() splashGui:Destroy() end)

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

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0,12)

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
    screenGui:Destroy()
    freecamActive = false
    systemActive = false
    for _,h in pairs(highlights) do h:Destroy() end
end)

-- Hotkeys Scroll
local hotkeys = Instance.new("ScrollingFrame")
hotkeys.Size = UDim2.new(1,-20,0,240)
hotkeys.Position = UDim2.new(0,10,0,50)
hotkeys.BackgroundTransparency = 1
hotkeys.CanvasSize = UDim2.new(0,0,0,0)
hotkeys.ScrollBarThickness = 6
hotkeys.Parent = frame

local layout = Instance.new("UIListLayout", hotkeys)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0,5)

local function addHotkey(name,key)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,25)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextScaled = true
    lbl.Text = name..": "..key
    lbl.Parent = hotkeys
    hotkeys.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+5)
end

-- Default hotkeys
addHotkey("Toggle Camera Lock","Q + RMB")
addHotkey("Toggle Glow","Shift + Q")
addHotkey("Toggle GUI","M")
addHotkey("Toggle Freecam","J")

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

local function toggleGlow()
    glowActive = not glowActive
    if glowActive then
        for _,p in pairs(Players:GetPlayers()) do
            if p.Character then createHighlight(p.Character) end
            p.CharacterAdded:Connect(function(c) if glowActive then createHighlight(c) end end)
        end
    else
        for c,_ in pairs(highlights) do removeHighlight(c) end
    end
end

-- ===== Camera Helper =====
local function getNearestPlayer()
    local closest = nil
    local shortest = math.huge
    local mousePos = UIS:GetMouseLocation()
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            local headPos,onScreen = camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(headPos.X,headPos.Y)-Vector2.new(mousePos.X,mousePos.Y)).Magnitude
                if dist < shortest then shortest = dist closest = p end
            end
        end
    end
    return closest
end

-- ===== Input Handling =====
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Q then
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
            toggleGlow()
        else
            systemActive = not systemActive
            if not systemActive then rightMouseDown = false lockedTarget = nil end
        end
    end
    if input.KeyCode == Enum.KeyCode.M then
        guiVisible = not guiVisible
        frame.Visible = guiVisible
    end
    if input.KeyCode == Enum.KeyCode.J then
        if freecamActive then
            freecamActive = false
            if freecamOrigin then
                player.Character:SetPrimaryPartCFrame(freecamOrigin)
                camera.CameraType = Enum.CameraType.Custom
            end
        else
            if player.Character and player.Character.PrimaryPart then
                freecamOrigin = player.Character.PrimaryPart.CFrame
                freecamActive = true
                camera.CameraType = Enum.CameraType.Scriptable
            end
        end
    end
    if systemActive and input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseDown = true
        lockedTarget = getNearestPlayer()
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseDown = false
        lockedTarget = nil
    end
end)

-- ===== Camera Glide & Character Rotation =====
RunService.RenderStepped:Connect(function()
    if systemActive and rightMouseDown and lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("Head") then
        local targetPos = lockedTarget.Character.Head.Position
        if player.Character and player.Character.PrimaryPart then
            local root = player.Character.PrimaryPart
            local dir = (targetPos - root.Position).Unit
            root.CFrame = CFrame.new(root.Position, root.Position + dir)
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPos)
        end
    end
end)
