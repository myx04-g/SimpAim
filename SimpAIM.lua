--[[ SimpAIM Console Paste Version ]]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Prevent duplicate GUIs
if PlayerGui:FindFirstChild("SimpAIM_UI") then
    PlayerGui.SimpAIM_UI:Destroy()
end
if PlayerGui:FindFirstChild("SimpAIM_Splash") then
    PlayerGui.SimpAIM_Splash:Destroy()
end

-- Flags
local systemActive = false
local rightMouseDown = false
local lockedTarget = nil
local glowActive = false
local highlights = {}
local guiVisible = true
local freecamActive = false
local freecamCFrame = nil

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
frame.Size = UDim2.new(0,400,0,300)
frame.Position = UDim2.new(0.5,-200,0.3,-150)
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

-- Terminate Button
local terminateBtn = Instance.new("TextButton")
terminateBtn.Size = UDim2.new(0,30,0,30)
terminateBtn.Position = UDim2.new(1,-35,0,5)
terminateBtn.Text = "X"
terminateBtn.Font = Enum.Font.SourceSansBold
terminateBtn.TextSize = 20
terminateBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
terminateBtn.TextColor3 = Color3.fromRGB(0,0,0)
terminateBtn.Parent = frame
terminateBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    -- Cleanup
    highlights = {}
    systemActive = false
    rightMouseDown = false
    lockedTarget = nil
    freecamActive = false
end)

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0,380,0,60)
statusLabel.Position = UDim2.new(0,10,0,40)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 16
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Text = ""
statusLabel.Parent = frame

-- Hotkeys frame
local hotkeysFrame = Instance.new("ScrollingFrame")
hotkeysFrame.Size = UDim2.new(0,380,0,150)
hotkeysFrame.Position = UDim2.new(0,10,0,110)
hotkeysFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
hotkeysFrame.CanvasSize = UDim2.new(0,0,0,0)
hotkeysFrame.ScrollBarThickness = 8
hotkeysFrame.Parent = frame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = hotkeysFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0,5)

local function addHotkey(desc)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,30)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextScaled = true
    lbl.Text = desc
    lbl.Parent = hotkeysFrame
    hotkeysFrame.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y)
end

-- Add hotkeys
addHotkey("Q - Toggle Camera Lock")
addHotkey("Shift+Q - Toggle Glow")
addHotkey("M - Toggle GUI")
addHotkey("N - Show Hotkeys")
addHotkey("J - Toggle Freecam")
addHotkey("Right Mouse - Lock Target")

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
    local mousePos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    for _,p in pairs(Players:GetPlayers()) do
        if p~=player and p.Character and p.Character:FindFirstChild("Head") then
            local headPos,onScreen = camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (mousePos - Vector2.new(headPos.X,headPos.Y)).Magnitude
                if dist<shortest then
                    shortest = dist
                    closest = p
                end
            end
        end
    end
    return closest
end

-- ===== Input Handling =====
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q then
        systemActive = not systemActive
        if not systemActive then rightMouseDown=false lockedTarget=nil end
    end
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            toggleGlow()
        end
    end
    if input.KeyCode == Enum.KeyCode.M then
        guiVisible = not guiVisible
        frame.Visible = guiVisible
    end
    if input.KeyCode == Enum.KeyCode.N then
        hotkeysFrame.Visible = not hotkeysFrame.Visible
    end
    if input.KeyCode == Enum.KeyCode.J then
        freecamActive = not freecamActive
        if freecamActive then
            freecamCFrame = camera.CFrame
        else
            if freecamCFrame then camera.CFrame = freecamCFrame end
        end
    end
    if systemActive and input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseDown = true
        lockedTarget = getNearestPlayer()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2 then
        rightMouseDown=false
        lockedTarget=nil
    end
end)

-- ===== Camera Glide Loop =====
local glideSpeed = 0.1
RunService.RenderStepped:Connect(function(dt)
    if systemActive and rightMouseDown and lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("Head") then
        local targetPos = lockedTarget.Character.Head.Position
        local camPos = camera.CFrame.Position
        local newPos = camPos:Lerp(targetPos, glideSpeed)
        camera.CFrame = CFrame.lookAt(newPos, targetPos)
        player.Character:SetPrimaryPartCFrame(CFrame.new(newPos))
    end
    statusLabel.Text = string.format(
        "Camera Lock: %s | %s\nGlow: %s | Freecam: %s",
        systemActive and "Active" or "Inactive",
        (systemActive and rightMouseDown and lockedTarget) and "RUNNING" or "Idle",
        glowActive and "ON" or "OFF",
        freecamActive and "ON" or "OFF"
    )
end)
