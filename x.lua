_G.Main = _G.Main or {}

-- Settings are now for session state only, not saved.
_G.Main.Settings = {
    ButtonStates = {},
    FramePositions = {},
    ModuleStates = {},
    GuiVisible = true,
    SeenIntro = false
}

_G.Main.UIReferences = {
    Buttons = {},
    Frames = {},
    MainGui = nil,
    ToggleButton = nil,
    BlurEffect = nil -- Reference for the blur effect
}

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

-- Animation presets
local ANIMATION_SETTINGS = {
    FrameEntrance = {
        Time = 0.5,
        Easing = Enum.EasingStyle.Quint,
        Offset = UDim2.new(0, 0, 0.1, 0)
    },
    ButtonHover = {
        Time = 0.15,
        Easing = Enum.EasingStyle.Linear
    },
    ButtonPress = {
        Time = 0.1,
        Easing = Enum.EasingStyle.Back
    },
    GuiToggle = {
        Time = 0.3,
        Easing = Enum.EasingStyle.Quad
    },
    Intro = {
        Time = 0.6,
        Easing = Enum.EasingStyle.Quint
    }
}

-- Initialize the GUI system
function _G.Main.Init()
    -- Create main container GUI
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "SapienMainGui"
    mainGui.ResetOnSpawn = false
    mainGui.IgnoreGuiInset = true
    mainGui.DisplayOrder = 10
    mainGui.Parent = game:GetService("CoreGui")
    _G.Main.UIReferences.MainGui = mainGui

    -- Create toggle button
    _G.Main.CreateToggleButton(mainGui)

    -- Show intro GUI if first time this session
    if not _G.Main.Settings.SeenIntro then
        _G.Main.ShowIntroGui()
        _G.Main.Settings.SeenIntro = true
    end

    -- Set up hotkeys
    _G.Main.SetupHotkeys()
end

-- Create the GUI toggle button
function _G.Main.CreateToggleButton(parent)
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleGUIButton"
    toggleButton.Size = UDim2.new(0, 120, 0, 36)
    toggleButton.Position = UDim2.new(0, 10, 0, 10)
    toggleButton.AnchorPoint = Vector2.new(0, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 102, 204)
    toggleButton.BackgroundTransparency = 0.3
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Text = _G.Main.Settings.GuiVisible and "Hide GUI" or "Show GUI"
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.BorderSizePixel = 0
    toggleButton.ZIndex = 20
    toggleButton.Parent = parent

    -- Visual styling
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toggleButton

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 204, 255)
    stroke.Transparency = 0.3
    stroke.Parent = toggleButton

    -- Animation on hover
    toggleButton.MouseEnter:Connect(function()
        TweenService:Create(toggleButton, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.2,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)

    toggleButton.MouseLeave:Connect(function()
        TweenService:Create(toggleButton, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.3,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)

    -- Click functionality
    toggleButton.MouseButton1Click:Connect(function()
        _G.Main.ToggleGuiVisibility()
    end)
end

-- Toggles GUI visibility and screen blur
function _G.Main.ToggleGuiVisibility()
    -- Toggle the state
    _G.Main.Settings.GuiVisible = not _G.Main.Settings.GuiVisible
    local isVisible = _G.Main.Settings.GuiVisible

    -- Handle the Blur Effect
    if not _G.Main.UIReferences.BlurEffect then
        _G.Main.UIReferences.BlurEffect = Instance.new("BlurEffect")
        _G.Main.UIReferences.BlurEffect.Name = "SapienGuiBlur"
        _G.Main.UIReferences.BlurEffect.Parent = Lighting
    end
    
    _G.Main.UIReferences.BlurEffect.Enabled = isVisible
    _G.Main.UIReferences.BlurEffect.Size = isVisible and 16 or 0

    -- Update the main toggle button's visibility and text
    if _G.Main.UIReferences.ToggleButton then
        _G.Main.UIReferences.ToggleButton.Text = isVisible and "Hide GUI" or "Show GUI"
        _G.Main.UIReferences.ToggleButton.Visible = isVisible
    end
    
    -- Set visibility for all registered frames
    for _, frame in pairs(_G.Main.UIReferences.Frames) do
        frame.Visible = isVisible
    end
end


-- Set up hotkeys
function _G.Main.SetupHotkeys()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            _G.Main.ToggleGuiVisibility()
        end
    end)
end

function _G.Main.ShowIntroGui()
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    -- Create main GUI
    local introGui = Instance.new("ScreenGui")
    introGui.Name = "SapienIntroGui"
    introGui.ResetOnSpawn = false
    introGui.IgnoreGuiInset = true
    introGui.Parent = game:GetService("CoreGui")
    introGui.DisplayOrder = 20

    -- Fullscreen background with animated gradient
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(5, 10, 20)
    bg.BackgroundTransparency = 1 -- Start fully transparent for fade-in
    bg.Parent = introGui

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 10, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 25, 50))
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0.7)
    })
    gradient.Parent = bg

    -- Animated particles background
    local particles = Instance.new("Frame")
    particles.Size = UDim2.new(1, 0, 1, 0)
    particles.BackgroundTransparency = 1
    particles.Parent = bg

    for i = 1, 30 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, math.random(2, 5), 0, math.random(2, 5))
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        particle.BackgroundTransparency = 0.7
        particle.BorderSizePixel = 0
        particle.Parent = particles

        task.spawn(function()
            local currentTween
            while particle.Parent do
                local moveTime = math.random(3, 7)
                local targetPosition = UDim2.new(math.random(), 0, math.random(), 0)
                currentTween = TweenService:Create(particle, TweenInfo.new(moveTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = targetPosition
                })
                currentTween:Play()
                currentTween.Completed:Wait()
                currentTween:Destroy()
            end
            if currentTween and not currentTween.Completed then
                currentTween:Cancel()
            end
        end)
    end

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.7, 0, 0.6, 0)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1
    container.Parent = bg

    local shine = Instance.new("Frame")
    shine.Size = UDim2.new(0.8, 0, 0.8, 0)
    shine.Position = UDim2.new(0.5, 0, 0.5, 0)
    shine.AnchorPoint = Vector2.new(0.5, 0.5)
    shine.BackgroundTransparency = 1
    shine.Parent = container

    local shineGradient = Instance.new("UIGradient")
    shineGradient.Rotation = 45
    shineGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 180, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 255))
    })
    shineGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 1)
    })
    shineGradient.Parent = shine

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.Position = UDim2.new(0.5, 0, 0.2, 0)
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.BackgroundTransparency = 1
    title.Text = "" -- Set initially empty for typewriter effect
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.TextTransparency = 1 -- Start transparent
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.TextStrokeTransparency = 0.7
    title.TextStrokeColor3 = Color3.fromRGB(0, 80, 150)
    title.ZIndex = 2
    title.Parent = container

    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1.5, 0, 1.5, 0)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = Color3.fromRGB(0, 120, 255)
    glow.ImageTransparency = 1 -- Start transparent
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(100, 100, 100, 100)
    glow.ZIndex = 1
    glow.Parent = title

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0.15, 0)
    subtitle.Position = UDim2.new(0.5, 0, 0.45, 0)
    subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "JOIN OUR DISCORD FOR UPDATES AND OP SCRIPTS"
    subtitle.TextColor3 = Color3.fromRGB(150, 220, 255)
    subtitle.TextTransparency = 1 -- Start transparent
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextStrokeTransparency = 0.8
    subtitle.TextStrokeColor3 = Color3.fromRGB(0, 50, 100)
    subtitle.ZIndex = 2
    subtitle.Parent = container

    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(1, 0, 0.1, 0)
    version.Position = UDim2.new(0.5, 0, 0.9, 0)
    version.AnchorPoint = Vector2.new(0.5, 0.5)
    version.BackgroundTransparency = 1
    version.Text = "v1.0.0"
    version.TextColor3 = Color3.fromRGB(100, 180, 255)
    version.TextTransparency = 1 -- Start transparent
    version.TextScaled = true
    version.Font = Enum.Font.Gotham
    version.TextStrokeTransparency = 0.9
    version.ZIndex = 2
    version.Parent = container

    -- Fade in background
    TweenService:Create(bg, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 0
    }):Play()

    -- Animate shine offset
    TweenService:Create(shineGradient, TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
        Offset = Vector2.new(1, 1)
    }):Play()

    -- Manual transparency animation for shineGradient
    task.spawn(function()
        local duration = 0.8
        local startTime = tick()
        
        local startKeypoints = {{Time = 0, Value = 1}, {Time = 0.5, Value = 1}, {Time = 1, Value = 1}}
        local targetKeypoints = {{Time = 0, Value = 0.9}, {Time = 0.5, Value = 0.7}, {Time = 1, Value = 0.9}}

        local connection
        connection = RunService.RenderStepped:Connect(function()
            local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
            
            local newKeypoints = {}
            for i, startKp in ipairs(startKeypoints) do
                local targetKp = targetKeypoints[i]
                local currentValue = startKp.Value + (targetKp.Value - startKp.Value) * alpha
                table.insert(newKeypoints, NumberSequenceKeypoint.new(startKp.Time, currentValue))
            end
            
            shineGradient.Transparency = NumberSequence.new(newKeypoints)
            
            if alpha >= 1 then
                connection:Disconnect()
            end
        end)
    end)

    -- Typewriter effect for title
    task.spawn(function()
        local fullText = "SAPIEN"
        for i = 1, #fullText do
            title.Text = string.sub(fullText, 1, i)
            title.TextTransparency = 0
            task.wait(0.08)
        end

        -- Main title glow animation loop
        while title.Parent do
            TweenService:Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.85,
                Size = UDim2.new(1.6, 0, 1.6, 0)
            }):Play()
            task.wait(1.5)
            TweenService:Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.7,
                Size = UDim2.new(1.4, 0, 1.4, 0)
            }):Play()
            task.wait(1.5)
        end
    end)

    -- Delayed animations for subtitle and version
    task.delay(0.8, function()
        TweenService:Create(subtitle, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {
            TextTransparency = 0.2
        }):Play()

        TweenService:Create(version, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {
            TextTransparency = 0.3
        }):Play()
    end)

    -- Outro animation
    task.delay(4.5, function()
        -- Animate elements out
        TweenService:Create(title, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {
            TextTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.1, 0),
            TextColor3 = Color3.fromRGB(0, 255, 255)
        }):Play()

        TweenService:Create(subtitle, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {
            TextTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()

        TweenService:Create(version, TweenInfo.new(0.7, Enum.EasingStyle.Quint), { TextTransparency = 1 }):Play()

        TweenService:Create(glow, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {
            ImageTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0),
            ImageColor3 = Color3.fromRGB(0, 255, 255)
        }):Play()

        -- Manual fade out for shineGradient
        task.spawn(function()
            local duration = 0.7
            local startTime = tick()
            local initialTransparency = shineGradient.Transparency
            
            local connection
            connection = RunService.RenderStepped:Connect(function()
                local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
                local newKeypoints = {}
                local currentKeypoints = initialTransparency.Keypoints
                
                for _, kp in ipairs(currentKeypoints) do
                    local interpolatedValue = kp.Value + (1 - kp.Value) * alpha
                    table.insert(newKeypoints, NumberSequenceKeypoint.new(kp.Time, interpolatedValue))
                end
                
                shineGradient.Transparency = NumberSequence.new(newKeypoints)
                
                if alpha >= 1 then
                    connection:Disconnect()
                end
            end)
        end)

        local bgFadeOut = TweenService:Create(bg, TweenInfo.new(1, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 1
        })
        bgFadeOut:Play()

        bgFadeOut.Completed:Connect(function()
            introGui:Destroy()
        end)
    end)
end

function _G.Main.createFrame(parent, position, color, text, name, maxHeight)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Visible = true
    frame.Name = name or "Frame"
    frame.Size = UDim2.new(0, 150, 0, 50)
    frame.Position = (position or UDim2.new(0.5, -100, 0.5, 0)) + UDim2.new(0, 0, 0.1, 50) -- Start below
    frame.BackgroundColor3 = color or Color3.fromRGB(15, 25, 49)
    frame.BackgroundTransparency = 1 -- Start transparent
    frame.ClipsDescendants = true
    frame.Visible = _G.Main.Settings.GuiVisible
    maxHeight = maxHeight or 270

    if _G.Main.Settings.GuiVisible then
        TweenService:Create(frame, TweenInfo.new(
            ANIMATION_SETTINGS.FrameEntrance.Time,
            ANIMATION_SETTINGS.FrameEntrance.Easing
        ), {
            Position = position or UDim2.new(0.5, -100, 0.5, 0),
            BackgroundTransparency = 0.2
        }):Play()
    else
        frame.BackgroundTransparency = 1
        frame.Position = position or UDim2.new(0.5, -100, 0.5, 0)
    end

    local drag = Instance.new("UIDragDetector", frame)
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Parent = frame
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 153, 255)
    stroke.Transparency = 1 -- Start transparent

    if _G.Main.Settings.GuiVisible then
        TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Transparency = 0.3 }):Play()
    end

    local title = Instance.new("Frame")
    title.Parent = frame
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(0, 102, 204)
    title.BackgroundTransparency = 1 -- Start transparent
    title.BorderSizePixel = 0
    
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 102, 204)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 153, 255))
    })
    titleGradient.Rotation = 90
    titleGradient.Parent = title

    if _G.Main.Settings.GuiVisible then
        TweenService:Create(title, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
    end

    local titleText = Instance.new("TextLabel")
    titleText.Parent = title
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Font = Enum.Font.GothamBold
    titleText.Text = "" -- For typing effect
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextScaled = true
    titleText.TextWrapped = true

    if _G.Main.Settings.GuiVisible then
        task.spawn(function()
            local fullText = text or "Frame"
            for i = 1, #fullText do
                titleText.Text = string.sub(fullText, 1, i)
                task.wait(0.03)
            end
        end)
    else
        titleText.Text = text or "Frame"
    end

    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Parent = frame
    scrollingFrame.Size = UDim2.new(1, -10, 1, -45)
    scrollingFrame.Position = UDim2.new(0, 5, 0, 40)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.ScrollBarThickness = 4
    scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 153, 255)
    scrollingFrame.ClipsDescendants = true
    scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollingFrame.ScrollBarImageTransparency = 1 -- Start transparent

    if _G.Main.Settings.GuiVisible then
        TweenService:Create(scrollingFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { ScrollBarImageTransparency = 0.3 }):Play()
    end

    local layout = Instance.new("UIListLayout", scrollingFrame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local contentHeight = layout.AbsoluteContentSize.Y
        if contentHeight <= maxHeight then
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
            frame.Size = UDim2.new(0, frame.Size.X.Offset, 0, contentHeight + 45)
            scrollingFrame.ClipsDescendants = false
        else
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
            frame.Size = UDim2.new(0, frame.Size.X.Offset, 0, maxHeight + 45)
            scrollingFrame.ClipsDescendants = true
        end
    end)

    _G.Main.UIReferences.Frames[name] = frame
    return scrollingFrame
end

function _G.Main.createButton(parentFrame, text, onClick, size, color)
    local button = Instance.new("TextButton")
    button.Parent = parentFrame
    button.BackgroundColor3 = color or Color3.fromRGB(30, 60, 120)
    button.BackgroundTransparency = 0.7
    button.Text = text or "Button"
    button.Font = Enum.Font.GothamMedium
    button.TextScaled = true
    button.TextSize = 14
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false
    button.TextColor3 = Color3.fromRGB(200, 230, 255)

    local originalSize = size or UDim2.new(0, 140, 0, 32)
    button.Size = UDim2.new(0, 0, 0, originalSize.Y.Offset)
    TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Size = originalSize }):Play()

    _G.Main.UIReferences.Buttons[text] = button

    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0, 6)

    button.MouseEnter:Connect(function()
        if not (_G.Main.Settings.ButtonStates[text] or false) then
            TweenService:Create(button, TweenInfo.new(ANIMATION_SETTINGS.ButtonHover.Time), {
                BackgroundTransparency = 0.4,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        end
    end)

    button.MouseLeave:Connect(function()
        if not (_G.Main.Settings.ButtonStates[text] or false) then
            TweenService:Create(button, TweenInfo.new(ANIMATION_SETTINGS.ButtonHover.Time), {
                BackgroundTransparency = 0.7,
                TextColor3 = Color3.fromRGB(200, 230, 255)
            }):Play()
        end
    end)

    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(ANIMATION_SETTINGS.ButtonPress.Time, ANIMATION_SETTINGS.ButtonPress.Easing), {
            Size = originalSize - UDim2.new(0, 10, 0, 5)
        }):Play()
    end)

    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(ANIMATION_SETTINGS.ButtonPress.Time * 1.5, ANIMATION_SETTINGS.ButtonPress.Easing), {
            Size = originalSize
        }):Play()
    end)

    button.MouseButton1Click:Connect(function()
        local newIsActive = not (_G.Main.Settings.ButtonStates[text] or false)
        _G.Main.Settings.ButtonStates[text] = newIsActive

        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundTransparency = newIsActive and 0.1 or 0.7,
            TextColor3 = newIsActive and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(200, 230, 255)
        }):Play()

        if newIsActive then
            task.spawn(function()
                TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(0, 180, 255)}):Play()
                task.wait(0.1)
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color or Color3.fromRGB(30, 60, 120)}):Play()
            end)
        end
        
        if onClick then onClick(newIsActive) end
    end)
    
    return button
end

-- Initialize the library
_G.Main.Init()
--variables
local runservice = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local plr = game.Players.LocalPlayer
local plrgui = plr.PlayerGui
local sapien = Instance.new("ScreenGui",plrgui)
local workspace = game.workspace
local rake = workspace:FindFirstChild("Rake")
sapien.ResetOnSpawn = false

local gui = false
local stunstick = false
local Fly = false
local RakeE = false
local ScrapE = false
local LootBoxE = false
local FlareE = false
local PlayersE = false
local AutoOpenDoorW = false
local FullBrightW = false
local NoFallDamageW = false
local autoopenlootW = false

-- Functions

-- Function to highlight an object and display its name
function toggleHighlight(object, name, pp, color, state)
    if state then
        -- Enable ESP
        if not object:FindFirstChild("Highlight") then
            local highlight = Instance.new("Highlight")
            highlight.Parent = object
            highlight.FillColor = color or Color3.new(1, 1, 1) -- Default to white
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.Adornee = object
        end

        if not pp:FindFirstChild("BillboardGui") then
            local billboardGui = Instance.new("BillboardGui")
            billboardGui.Size = UDim2.new(2, 0, 2, 0) -- Bigger size
            billboardGui.StudsOffset = Vector3.new(0, 5, 0) -- Higher offset
            billboardGui.AlwaysOnTop = true
            billboardGui.Parent = pp -- Parent the BillboardGui to pp

            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(4, 0, 4, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = name
            textLabel.TextColor3 = color or Color3.new(1, 1, 1)
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.TextScaled = true
            textLabel.Parent = billboardGui

            -- Make BillboardGui visible through walls
            textLabel.ZIndex = 10
            billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        end
    else
        -- Disable ESP
        if object:FindFirstChild("Highlight") then
            object.Highlight:Destroy()
        end

        if pp:FindFirstChild("BillboardGui") then
            pp.BillboardGui:Destroy()
        end
    end
end

local function scrapesp()
        if ScrapE == true then
            local scrapspawn = workspace.Filter.ScrapSpawns:GetChildren()
            for _, v in pairs(scrapspawn) do
                local children = v:GetChildren()
                if #children > 0 then
                    for _, checkin in pairs(children) do
                        if checkin:IsA("Model") and not checkin:FindFirstChild("Highlight") then
                            toggleHighlight(checkin, checkin.Name, checkin.Scrap, Color3.new(255, 255, 0), true)
                        end
                    end
                end
            end
        end
end 


UserInputService.InputBegan:Connect(function(keycode)
    if keycode.KeyCode == Enum.KeyCode.E then
       if AutoOpenDoorW == true then
			local args = {
        	[1] = "Door"
        	}
        	workspace.Map.SafeHouse.Door.RemoteEvent:FireServer(unpack(args))
    	end
	end
end)



local function fullbr()
    if FullBrightW == true then
		game.Lighting.FogEnd = 9999999999
		game.Lighting.FogColor = Color3.fromRGB(79, 125, 166)
		game.Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
		game.Lighting.Ambient = Color3.fromRGB(200, 200, 200)
		game.Lighting.FogColor = Color3.fromRGB(77, 119, 159)
		game.Lighting.BloodHourColor.TintColor = Color3.fromRGB(250, 250, 250)
		game.Lighting.BloodHourColor.Brightness = 0
		game.Lighting.BloodHourColor.Contrast = 0
		game.Lighting.BloodHourColor.Saturation = 0
	end 
end


local function autoopen()
    if autoopenlootW == true then
        if #workspace.Debris.SupplyCrates:GetChildren() >= 1 then
           for i,v in pairs(workspace.Debris.SupplyCrates:GetChildren()) do
               v.UnlockValue.Value = 100
            end   
        end
    end
end


coroutine.wrap(function()

	local UserInputService = game:GetService("UserInputService")
	local player = game.Players.LocalPlayer
	local camera = workspace.CurrentCamera


	local isMouseLocked = true


	local function toggleMouseLock()
		isMouseLocked = not isMouseLocked
		if isMouseLocked then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			camera.CameraType = Enum.CameraType.Custom
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			camera.CameraType = Enum.CameraType.Scriptable
		end
	end


	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end -- Ignore input if game is processing it

		if input.KeyCode == Enum.KeyCode.RightShift then
			task.spawn(toggleMouseLock)
		end
	end)

end)()


runservice.RenderStepped:Connect(function()
	fullbr()
	scrapesp()
	autoopen()
end)

local Combat = _G.Main.createFrame(sapien,UDim2.new(0.353, -49,0.345, 5),nil,"Combat","CombatFrame")

local runService = game:GetService("RunService")
local players = game:GetService("Players")
local player = players.LocalPlayer
local auraConnection
local stunstick = false
local lastHit = 0

local function getRake()
    return workspace:FindFirstChild("Rake")
end


local function aura()
    local char = player.Character
    local rake = getRake()

    if char and rake and rake:FindFirstChild("Head") and char:FindFirstChild("StunStick") then
        local stunStick = char.StunStick
        local now = tick()

        
        if now - lastHit >= 0.2 then
            lastHit = now
            pcall(function()
                stunStick.Event:FireServer("S")
                task.wait(0.01)
                stunStick.Event:FireServer("H", rake.Head)
            end)
        end
    end
end

local function startAuraLoop()
    if auraConnection then auraConnection:Disconnect() end

    auraConnection = runService.Heartbeat:Connect(function()
        if stunstick then
            aura()
        end
    end)
end


local stunbut = _G.Main.createButton(Combat, "StunStickAura", function()
    stunstick = not stunstick

    if stunstick then
        startAuraLoop()
    elseif auraConnection then
        auraConnection:Disconnect()
    end
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Rake" then
        task.wait(0.2)
        if stunstick then
            startAuraLoop()
        end
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    if stunstick then
        startAuraLoop()
    end
end)

local Visuals = _G.Main.createFrame(sapien,UDim2.new(0.557, -105,0.29, -3),nil,"Visuals","VisualsFrame")
local misc = _G.Main.createFrame(sapien,UDim2.new(0.7, -10,0.29, -10),nil,"misc","miscFrame")


local rake2

local function cleanUpHighlights()
    if rake2 and rake2:FindFirstChild("Highlight") then
        rake2.Highlight:Destroy()
    end
    if rake2 and rake2.Head:FindFirstChild("BillboardGui") then
        rake2.Head.BillboardGui:Destroy() 
    end
end

local function highlightRake()
    if rake2 then
        toggleHighlight(rake2, "Rake", rake2.Head, Color3.new(1, 0, 0), true)
    end
end

cleanUpHighlights()

local connection = nil

local re = _G.Main.createButton(Visuals, "RakeEsp", function()
    if not RakeE then
        RakeE = true
        print("Rake ESP Enabled")
        connection = runservice.RenderStepped:Connect(function()
            highlightRake()
        end)
    else
        RakeE = false
        if connection then
            connection:Disconnect()
            connection = nil
        end
        task.wait()
        cleanUpHighlights()
    end
end)

for _, child in ipairs(workspace:GetChildren()) do
    if child.Name == "Rake" then
        rake2 = child
        if RakeE then
            highlightRake()
        end
        break
    end
end


workspace.ChildAdded:Connect(function(child)
    if child.Name == "Rake" then
        rake2 = child
        if RakeE then
            highlightRake()
        end
    end
end)


workspace.ChildRemoved:Connect(function(child)
    if child.Name == "Rake" then
        cleanUpHighlights()
        rake2 = nil
    end
end)




local se = _G.Main.createButton(Visuals, "ScrapEsp", function()
    if ScrapE == false then
        ScrapE = true
    else 
        ScrapE = false
        task.wait()
        local scrapspawn = workspace.Filter.ScrapSpawns:GetChildren()
        for i, v in pairs(scrapspawn) do
            local children = v:GetChildren()
            if #children > 0 then
                for _, checkin in pairs(children) do
                    if checkin and checkin:IsA("Model") then
                        if checkin:FindFirstChild("Highlight") then
                            toggleHighlight(checkin, "hi", checkin.Scrap, Color3.new(1, 0, 0), false)
                        end
                    end
                end
            end
        end
    end
end)



local function updateLootBoxHighlights()
    if #workspace.Debris.SupplyCrates:GetChildren() >= 1 then
        for i, v in pairs(workspace.Debris.SupplyCrates:GetChildren()) do
            if v:FindFirstChild("lid") and v.lid:FindFirstChild("1") then
                local part1 = v.lid[1]
                if LootBoxE then
                    if not v:FindFirstChild("Highlight") then
                        toggleHighlight(v, "LootBox", part1, Color3.new(1, 1, 0), true)
                    end
                else
                    if v:FindFirstChild("Highlight") then
                        toggleHighlight(v, "LootBox", part1, Color3.new(1, 1, 0), false)
                    end
                end
            end
        end
    end
end
      local connection2
      local connection2 = runservice.RenderStepped:Connect(updateLootBoxHighlights)



local Le = _G.Main.createButton(Visuals, "LootBoxEsp", function()
    LootBoxE = not LootBoxE
    print("LootBox ESP Toggled: " .. tostring(LootBoxE))
end)



local function updateFlareGunHighlights()
    local flareGunPickUp = workspace:FindFirstChild("FlareGunPickUp")
    if flareGunPickUp then
        local flareGun = flareGunPickUp:FindFirstChild("FlareGun")
        if flareGun then
            if FlareE then
           if not flareGun:FindFirstChild("Highlight") then
                    toggleHighlight(flareGun, "Flaregun", flareGun, Color3.new(127, 0, 255), true)
                end
            else
                if flareGun:FindFirstChild("Highlight") then
                    toggleHighlight(flareGun, "Flaregun", flareGun, Color3.new(0, 255, 0), false)
                end
            end
        end
    end
end
local connection3
local Fe = _G.Main.createButton(Visuals, "FlareGunEsp", function()
    FlareE = not FlareE
    

    if FlareE then
        connection3 = runservice.RenderStepped:Connect(updateFlareGunHighlights)
    else
        if connection then 
            connection3:Disconnect()
            connection3 = nil
        end
        updateFlareGunHighlights()
    end
end)



local function cleanUpPlayerHighlights()
    for _, player in pairs(game.Players:GetPlayers()) do
        local char = player.Character
        if char then 
            if char:FindFirstChild("Highlight") and player ~= game.Players.LocalPlayer then
                toggleHighlight(char, char.Name, char.Head, Color3.new(0, 0, 255), false)
end
        end    
    end
end
local connection
local Pe = _G.Main.createButton(Visuals, "PlayersEsp", function()
    if not PlayersE then
        PlayersE = true
        connection = runservice.RenderStepped:Connect(function()
            for _, player in pairs(game.Players:GetPlayers()) do
                local char = player.Character
                if char and not char:FindFirstChild("Highlight") and player ~= game.Players.LocalPlayer then
                    toggleHighlight(char, char.Name, char.Head, Color3.new(0, 0, 255), true)
                end    
            end     
        end)
    else
        PlayersE = false

        if connection then
            connection:Disconnect()
            connection = nil
        end 
        cleanUpPlayerHighlights()
    end   
end)


--World

local World = _G.Main.createFrame(sapien,UDim2.new(0.663, 2,0.307, -2),nil,"World","WorldFrame")

local aod = _G.Main.createButton(World,"AutoOpenDoor(E)",function()
   if AutoOpenDoorW == false then
    AutoOpenDoorW = true
    else
        AutoOpenDoorW = false
    end
    end)


local fb = _G.Main.createButton(World,"FullBright",function()
	local f
    if FullBrightW == false then
        FullBrightW = true
        
    else
        FullBrightW = false
    end
end)

local aolb = _G.Main.createButton(World,"AutoOpenLootBox",function()
    if autoopenlootW == false then
        autoopenlootW = true
       
    else autoopenlootW = false
end
end)

local thirdPersonEnabled = false
local thirdPersonConnection = nil

local thirdPersonButton = _G.Main.createButton(World, "Third Person", function()
    if not thirdPersonEnabled then
        thirdPersonEnabled = true

        thirdPersonConnection = runservice.RenderStepped:Connect(function()
            local player = game:GetService("Players").LocalPlayer
            if player then
                player.CameraMaxZoomDistance = math.huge
                player.CameraMinZoomDistance = 0
            end
        end)
    else
        thirdPersonEnabled = false

        if thirdPersonConnection then
            thirdPersonConnection:Disconnect()
            thirdPersonConnection = nil
        end

        local player = game:GetService("Players").LocalPlayer
        if player then
            player.CameraMaxZoomDistance = 0
            player.CameraMinZoomDistance = 0
        end
    end
end)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local instaKillEnabled = false
local instaKillConnection = nil
local rakeMonitorConnection = nil

local function stopInstaKill()
	if instaKillConnection then
		instaKillConnection:Disconnect()
		instaKillConnection = nil
	end
end

local function startInstaKillLoop()
	stopInstaKill() -- just in case
	instaKillConnection = RunService.Heartbeat:Connect(function()
		local rake = workspace:FindFirstChild("Rake")
		if rake and rake:FindFirstChild("Monster") then
			if rake.Monster.Health > 0 then
				rake.Monster.Health = 0
			end
		end
	end)
end


local function monitorRake()
	if rakeMonitorConnection then return end 

	rakeMonitorConnection = RunService.Heartbeat:Connect(function()
		if instaKillEnabled then
			local rake = workspace:FindFirstChild("Rake")
			if rake and rake:FindFirstChild("Monster") and rake.Monster.Health > 0 then
				startInstaKillLoop()
			end
		else
			stopInstaKill()
		end
	end)
end


local instaKillBtn = _G.Main.createButton(Combat, "Insta Kill Rake(trap needed)", function()
	instaKillEnabled = not instaKillEnabled

	if instaKillEnabled then
		monitorRake()
	else
		stopInstaKill()
	end
end)


LocalPlayer.CharacterAdded:Connect(function()
	stopInstaKill()
end)

local noSlowDownEnabled = false
local noSlowDownConnection = nil

local nsdButton = _G.Main.createButton(World, "NoSlowDown", function()
    noSlowDownEnabled = not noSlowDownEnabled

    if noSlowDownEnabled then
        noSlowDownConnection = runservice.RenderStepped:Connect(function()
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = 30
            end
        end)
    else
        if noSlowDownConnection then
            noSlowDownConnection:Disconnect()
            noSlowDownConnection = nil
        end
    end
end)

local placeESPEnabled = false

local places = {
    powerstation = workspace.Map.PowerStation.StationFolder.StationParts.Model:GetChildren()[19],
    safehouse = workspace.Map.SafeHouse.RakeBreak.Touch1,
    observationtower = workspace.Map.ObservationTower:GetChildren()[12],
    shop = workspace.Map.Shack.Merchant.Head,
    basecamp = workspace.Map.BaseCamp.Parts:GetChildren()[8]:GetChildren()[65]
}

local espTexts = {}

local function createESP()
    for name, part in pairs(places) do
        local text = Drawing.new("Text")
        text.Text = name
        text.Size = 16
        text.Color = Color3.new(0, 0, 1)
        text.Outline = true
        text.Center = true
        text.Visible = false
        espTexts[name] = {text = text, part = part}
    end
end

local function removeESP()
    for _, v in pairs(espTexts) do
        v.text:Remove()
    end
    espTexts = {}
end

game:GetService("RunService").RenderStepped:Connect(function()
    if not placeESPEnabled then return end
    local camera = workspace.CurrentCamera
    for _, v in pairs(espTexts) do
        local pos, onScreen = camera:WorldToViewportPoint(v.part.Position)
        v.text.Visible = onScreen
        if onScreen then
            v.text.Position = Vector2.new(pos.X, pos.Y)
        end
    end
end)

_G.Main.createButton(Visuals, "Place ESP", function()
    placeESPEnabled = not placeESPEnabled
    if placeESPEnabled then
        createESP()
    else
        removeESP()
    end
end)

local infoGuiToggle = false
local infoGui

local function createInfoGui()
 if infoGui then infoGui:Destroy() end

 infoGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
 infoGui.Name = "InfoGui"

 local bg = Instance.new("Frame", infoGui)
 bg.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
 bg.BackgroundTransparency = 0.2
 bg.Size = UDim2.new(0, 200, 0, 100)
 bg.Position = UDim2.new(0, 100, 0, 100)
 bg.Name = "InfoFrame"
 bg.Active = true

 local drag = Instance.new("UIDragDetector")
 drag.Parent = bg

 local targetLabel = Instance.new("TextLabel", bg)
 targetLabel.Size = UDim2.new(1, 0, 0, 30)
 targetLabel.Position = UDim2.new(0, 0, 0, 0)
 targetLabel.BackgroundTransparency = 1
 targetLabel.TextColor3 = Color3.new(1, 1, 1)
 targetLabel.Font = Enum.Font.SourceSansBold
 targetLabel.TextScaled = true
 targetLabel.Text = "Target: ..."

 local powerLabel = Instance.new("TextLabel", bg)
 powerLabel.Size = UDim2.new(1, 0, 0, 30)
 powerLabel.Position = UDim2.new(0, 0, 0, 30)
 powerLabel.BackgroundTransparency = 1
 powerLabel.TextColor3 = Color3.new(1, 1, 1)
 powerLabel.Font = Enum.Font.SourceSansBold
 powerLabel.TextScaled = true
 powerLabel.Text = "Power: ..."

 local timerLabel = Instance.new("TextLabel", bg)
 timerLabel.Size = UDim2.new(1, 0, 0, 30)
 timerLabel.Position = UDim2.new(0, 0, 0, 60)
 timerLabel.BackgroundTransparency = 1
 timerLabel.TextColor3 = Color3.new(1, 1, 1)
 timerLabel.Font = Enum.Font.SourceSansBold
 timerLabel.TextScaled = true
 timerLabel.Text = "Timer: ..."

 -- Live Update Loop
 task.spawn(function()
  while infoGui and infoGuiToggle do
   local ReplicatedStorage = game:GetService("ReplicatedStorage")
   local targetVal = workspace:FindFirstChild("Rake") and workspace.Rake:FindFirstChild("TargetVal") and workspace.Rake.TargetVal.Value
   local powerVal = ReplicatedStorage:FindFirstChild("PowerValues") and ReplicatedStorage.PowerValues:FindFirstChild("PowerLevel")
   local timerVal = ReplicatedStorage:FindFirstChild("Timer")

   targetLabel.Text = "Target: " .. (targetVal and targetVal.Parent.Name or "N/A")
   powerLabel.Text = "Power: " .. (powerVal and powerVal.Value or "N/A")
   timerLabel.Text = "Timer: " .. (timerVal and timerVal.Value or "N/A")

   task.wait(0.2)
  end
 end)
end

-- Toggle Button
_G.Main.createButton(Visuals, "Show Info (Target/Power/Timer)", function()
 infoGuiToggle = not infoGuiToggle
 if infoGuiToggle then
  createInfoGui()
 else
  if infoGui then
   infoGui:Destroy()
   infoGui = nil
  end
 end
end)

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local walkSpeed = 24
local dangerDistance = 60
local hasSold = false

-- ⚠️ DANGER ZONES (Defined as rectangles)
local dangerZones = {
	-- Zone near: -93.24, 29.44, -9.17
	{min = Vector3.new(-100, 0, -15), max = Vector3.new(-85, 100, -5)},
	-- Zone near: -109.21, 24.44, -41.74
	{min = Vector3.new(-115, 0, -47), max = Vector3.new(-103, 100, -36)},
	-- Zone near: 163.30, 22.59, -16.64
	{min = Vector3.new(158, 0, -22), max = Vector3.new(168, 100, -11)},
}

-- 📦 Check if position is in any defined danger zone
local function isInDangerZone(pos)
	for _, zone in ipairs(dangerZones) do
		if pos.X >= zone.min.X and pos.X <= zone.max.X and
		   pos.Z >= zone.min.Z and pos.Z <= zone.max.Z then
			return true
		end
	end
	return false
end

local function getCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local hrp = character:WaitForChild("HumanoidRootPart")
	return character, humanoid, hrp
end

local function isRakeNearby()
	local _, _, hrp = getCharacter()
	local rake = Workspace:FindFirstChild("Rake")
	local rakeHRP = rake and rake:FindFirstChild("HumanoidRootPart")
	if not rakeHRP then return false end

	local distance = (rakeHRP.Position - hrp.Position).Magnitude
	if distance <= dangerDistance then
		local dir = (hrp.Position - rakeHRP.Position).Unit
		local target = hrp.Position + dir * 60
		local result = Workspace:Raycast(target + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0), RaycastParams.new())
		local newY = (result and result.Position.Y + 3) or target.Y
		target = Vector3.new(target.X, newY, target.Z)
		moveTo(target)
		return true
	end
	return false
end

local function moveTo(targetPos)
	if isInDangerZone(targetPos) then return false end -- ❌ Don't go into danger zones

	local _, humanoid, hrp = getCharacter()
	humanoid.WalkSpeed = walkSpeed

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = false,
		AgentCanClimb = false,
	})

	path:ComputeAsync(hrp.Position, targetPos)
	if path.Status ~= Enum.PathStatus.Success then return false end

	for _, wp in ipairs(path:GetWaypoints()) do
		if isInDangerZone(wp.Position) then return false end -- ❌ Skip path if any waypoint is in danger

		local start = hrp.Position
		local finish = wp.Position
		local dist = (finish - start).Magnitude
		local duration = dist / walkSpeed
		local startTime = tick()

		while tick() - startTime < duration do
			if isRakeNearby() then return false end
			local alpha = (tick() - startTime) / duration
			local interpolated = start:Lerp(finish, math.clamp(alpha, 0, 1))
			hrp.CFrame = CFrame.new(interpolated)
			RunService.Heartbeat:Wait()
		end

		hrp.CFrame = CFrame.new(finish)
	end

	return true
end

local function findScraps()
	local scraps = {}
	for _, folder in pairs(Workspace.Filter.ScrapSpawns:GetChildren()) do
		for _, item in pairs(folder:GetChildren()) do
			if item:IsA("Model") and item:FindFirstChild("Scrap") and item.Scrap:IsDescendantOf(Workspace) then
				table.insert(scraps, item.Scrap)
			end
		end
	end
	return scraps
end

local function sellScraps()
	local shop = Workspace.Map.Shack.Merchant:FindFirstChild("Head")
	if not shop or isInDangerZone(shop.Position) then return end -- ❌ Avoid shop if inside a danger zone
	moveTo(shop.Position)
	for _ = 1, math.random(10, 15) do
		ReplicatedStorage:WaitForChild("ShopEvent"):FireServer("SellScraps", "Scraps")
	end
	task.wait()
end

local function collectScraps()
	local scraps = findScraps()
	for _, scrap in ipairs(scraps) do
		if not scrap:IsDescendantOf(Workspace) then continue end
		if isInDangerZone(scrap.Position) then continue end -- ❌ Skip scraps in danger zone
		local rake = Workspace:FindFirstChild("Rake")
		if rake and (rake.HumanoidRootPart.Position - scrap.Position).Magnitude < dangerDistance then continue end
		if isRakeNearby() then continue end

		for attempt = 1, 3 do
			if moveTo(scrap.Position) then break end
			if isRakeNearby() then break end
		end
	end
end

-- Bot Threading Logic
local rakeRunning = false
local rakeThread

local function startRakeScript()
	if rakeRunning then return end
	rakeRunning = true

	rakeThread = task.spawn(function()
		while rakeRunning do
			task.wait(0.05)
			if isRakeNearby() then continue end

			local isNight = ReplicatedStorage:FindFirstChild("Night") and ReplicatedStorage.Night.Value
			local scrapFolder = player.Backpack:FindFirstChild("ScrapFolder")
			local scrapPoints = scrapFolder and scrapFolder:FindFirstChild("Points") and scrapFolder.Points.Value or 0
			local leaderstats = player:FindFirstChild("leaderstats")
			local currentPoints = leaderstats and leaderstats:FindFirstChild("Points") and leaderstats.Points.Value or 0

			if isNight then
				hasSold = false
				collectScraps()
			else
				if scrapPoints > 0 and currentPoints < 100000 and not hasSold then
					sellScraps()
					hasSold = true
				end
				collectScraps()
			end
		end
	end)
end

local function stopRakeScript()
	rakeRunning = false
	if rakeThread and coroutine.status(rakeThread) ~= "dead" then
		task.cancel(rakeThread)
	end
	rakeThread = nil
end

-- UI Button Bind
local rakeBotToggle = false
local mainGui = _G.Main -- <- make sure _G.Main exists!
mainGui.createButton(World, "BotPlayer (fast wins + points)", function()
	rakeBotToggle = not rakeBotToggle
	if rakeBotToggle then
		startRakeScript()
	else
		stopRakeScript()
	end
end)
local getinfo = getinfo or debug.getinfo
local DEBUG = false
local Hooked = {}

local Detected, Kill

setthreadidentity(2)

for i, v in getgc(true) do
    if typeof(v) == "table" then
        local DetectFunc = rawget(v, "Detected")
        local KillFunc = rawget(v, "Kill")
    
        if typeof(DetectFunc) == "function" and not Detected then
            Detected = DetectFunc
            
            local Old; Old = hookfunction(Detected, function(Action, Info, NoCrash)
                if Action ~= "_" then
                    if DEBUG then
                        warn(`Adonis AntiCheat flagged\nMethod: {Action}\nInfo: {Info}`)
                    end
                end
                
                return true
            end)

            table.insert(Hooked, Detected)
        end

        if rawget(v, "Variables") and rawget(v, "Process") and typeof(KillFunc) == "function" and not Kill then
            Kill = KillFunc
            local Old; Old = hookfunction(Kill, function(Info)
                if DEBUG then
                    warn(`Adonis AntiCheat tried to kill (fallback): {Info}`)
                end
            end)

            table.insert(Hooked, Kill)
        end
    end
end

local Old; Old = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local LevelOrFunc, Info = ...

    if Detected and LevelOrFunc == Detected then
        if DEBUG then
            warn(`adonis bypassed`)
        end

        return coroutine.yield(coroutine.running())
    end
    
    return Old(...)
end))
setthreadidentity(7)

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local staminaToggle = false
local hookedModules = {}

-- Disables anti-cheat by overriding check() in M_A
local function disableAntiCheat()
	for _, module in ipairs(getloadedmodules()) do
		if module.Name == "M_A" then
			local success, result = pcall(require, module)
			if success and typeof(result.check) == "function" then
				result.check = function() return true end
				warn("[AntiCheat] Disabled:", module:GetFullName())
			end
		end
	end
end

-- Hooks TakeStamina to give infinite stamina
local function enableInfiniteStamina()
	for _, module in ipairs(getloadedmodules()) do
		if module.Name == "M_H" and not hookedModules[module] then
			local success, mod = pcall(require, module)
			if success and typeof(mod.TakeStamina) == "function" then
				local original = mod.TakeStamina
				mod.TakeStamina = function(self, amount)
					if amount > 0 then
						return original(self, -0.5)
					end
					return original(self, amount)
				end
				hookedModules[module] = original
				warn("[Stamina] Hooked:", module:GetFullName())
			end
		end
	end
end

-- Restores original TakeStamina
local function disableInfiniteStamina()
	for module, original in pairs(hookedModules) do
		local success, mod = pcall(require, module)
		if success and mod then
			mod.TakeStamina = original
			warn("[Stamina] Restored:", module:GetFullName())
		end
	end
	table.clear(hookedModules)
end

-- Reapply on respawn if toggle is still active
localPlayer.CharacterAdded:Connect(function()
	if staminaToggle then
		task.wait(1)
		disableAntiCheat()
		enableInfiniteStamina()
	end
end)


-- Create the actual button
_G.Main.createButton(misc, "Infinite Stamina", function()
	staminaToggle = not staminaToggle
	if staminaToggle then
		disableAntiCheat()
		enableInfiniteStamina()
	else
		disableInfiniteStamina()
	end
end)

local noFallToggle = false

-- Hooking __namecall to block FD_Event:FireServer
local mt = getrawmetatable(game)
setreadonly(mt, false)

local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
	if noFallToggle and tostring(self) == "FD_Event" and getnamecallmethod() == "FireServer" then
		warn("[NoFallDamage] Blocked FD_Event:FireServer()")
		return nil
	end
	return oldNamecall(self, ...)
end)

-- Toggle GUI button
_G.Main.createButton(misc, "No Fall Damage", function()
	noFallToggle = not noFallToggle
	if noFallToggle then
		warn("[NoFallDamage] Enabled")
	else
		warn("[NoFallDamage] Disabled")
	end
end)

local antiTrapToggle = false

-- Anti-Trap Loop
task.spawn(function()
	while true do
		if antiTrapToggle then
			local debris = workspace:FindFirstChild("Debris")
			if debris then
				local traps = debris:FindFirstChild("Traps")
				if traps then
					for _, trap in ipairs(traps:GetChildren()) do
						if trap.Name == "RakeTrapModel" then
							local hitbox = trap:FindFirstChild("HitBox")
							if hitbox then
								local ti = hitbox:FindFirstChildWhichIsA("TouchTransmitter", true)
								if ti then
									ti:Destroy()
								end
							end
						end
					end
				end
			end
		end
		task.wait(0.5)
	end
end)

-- GUI Toggle
_G.Main.createButton(misc, "Anti-Trap", function()
	antiTrapToggle = not antiTrapToggle
	if antiTrapToggle then
		warn("[AntiTrap] Enabled")
	else
		warn("[AntiTrap] Disabled")
	end
end)

--[[TextButton.MouseButton1Click:Connect(function()
	local args = {
    	[1] = "Door"
    	}

    workspace.Map.SafeHouse.Door.RemoteEvent:FireServer(unpack(args))
end)]]
