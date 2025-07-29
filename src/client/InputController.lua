--[[
    InputController.lua - Client-side Input Handler
    
    This script handles:
    - Player input for bike controls (WASD, Arrow keys)
    - Mobile touch controls
    - Input validation and smoothing
    - Communication with server
    
    Usage: Place in StarterGui or StarterPlayerScripts
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local bikeControlEvent = remoteEvents:WaitForChild("BikeControl")
local spawnBikeEvent = remoteEvents:WaitForChild("SpawnBike")

local InputController = {}
InputController.__index = InputController

-- Input configuration
local INPUT_CONFIG = {
    ThrottleKeys = {Enum.KeyCode.W, Enum.KeyCode.Up},
    BrakeKeys = {Enum.KeyCode.S, Enum.KeyCode.Down},
    SteerLeftKeys = {Enum.KeyCode.A, Enum.KeyCode.Left},
    SteerRightKeys = {Enum.KeyCode.D, Enum.KeyCode.Right},
    SpawnBikeKey = Enum.KeyCode.R,
    
    -- Input smoothing
    InputSmoothing = 0.1,
    DeadZone = 0.05
}

function InputController.new()
    local self = setmetatable({}, InputController)
    
    self.inputValues = {
        throttle = 0,
        brake = 0,
        steer = 0
    }
    
    self.targetInputValues = {
        throttle = 0,
        brake = 0,
        steer = 0
    }
    
    self.lastSentInputs = {
        throttle = 0,
        brake = 0,
        steer = 0
    }
    
    self.keysPressed = {}
    self.mobileControls = nil
    
    self:setupInputHandling()
    self:createMobileControls()
    self:startInputLoop()
    
    return self
end

function InputController:setupInputHandling()
    -- Handle key press
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        self:handleInputBegan(input)
    end)
    
    -- Handle key release
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        self:handleInputEnded(input)
    end)
    
    -- Handle touch input for mobile
    if UserInputService.TouchEnabled then
        UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
            if gameProcessed then return end
            
            self:handleTouchInput(touch)
        end)
    end
end

function InputController:handleInputBegan(input)
    local keyCode = input.KeyCode
    
    -- Mark key as pressed
    self.keysPressed[keyCode] = true
    
    -- Handle spawn bike
    if keyCode == INPUT_CONFIG.SpawnBikeKey then
        self:spawnBike()
        return
    end
    
    -- Update target input values
    self:updateTargetInputs()
end

function InputController:handleInputEnded(input)
    local keyCode = input.KeyCode
    
    -- Mark key as released
    self.keysPressed[keyCode] = false
    
    -- Update target input values
    self:updateTargetInputs()
end

function InputController:updateTargetInputs()
    -- Reset target values
    self.targetInputValues.throttle = 0
    self.targetInputValues.brake = 0
    self.targetInputValues.steer = 0
    
    -- Check throttle keys
    for _, key in ipairs(INPUT_CONFIG.ThrottleKeys) do
        if self.keysPressed[key] then
            self.targetInputValues.throttle = 1
            break
        end
    end
    
    -- Check brake keys
    for _, key in ipairs(INPUT_CONFIG.BrakeKeys) do
        if self.keysPressed[key] then
            self.targetInputValues.brake = 1
            break
        end
    end
    
    -- Check steering keys
    local steerLeft = false
    local steerRight = false
    
    for _, key in ipairs(INPUT_CONFIG.SteerLeftKeys) do
        if self.keysPressed[key] then
            steerLeft = true
            break
        end
    end
    
    for _, key in ipairs(INPUT_CONFIG.SteerRightKeys) do
        if self.keysPressed[key] then
            steerRight = true
            break
        end
    end
    
    if steerLeft and not steerRight then
        self.targetInputValues.steer = -1
    elseif steerRight and not steerLeft then
        self.targetInputValues.steer = 1
    else
        self.targetInputValues.steer = 0
    end
end

function InputController:handleTouchInput(touch)
    -- Handle mobile touch controls
    if self.mobileControls then
        local touchPosition = touch.Position
        
        -- Check which mobile control was touched
        -- Implementation depends on mobile UI layout
        -- This is a simplified version
        self:updateMobileInputs(touchPosition)
    end
end

function InputController:createMobileControls()
    -- Only create mobile controls on touch devices
    if not UserInputService.TouchEnabled then
        return
    end
    
    -- Create mobile UI for bike controls
    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "MotocrossMobileControls"
    mobileGui.ResetOnSpawn = false
    mobileGui.Parent = playerGui
    
    -- Create control frame
    local controlFrame = Instance.new("Frame")
    controlFrame.Name = "ControlFrame"
    controlFrame.Size = UDim2.new(1, 0, 1, 0)
    controlFrame.Position = UDim2.new(0, 0, 0, 0)
    controlFrame.BackgroundTransparency = 1
    controlFrame.Parent = mobileGui
    
    -- Create throttle/brake control (right side)
    local rightControlFrame = Instance.new("Frame")
    rightControlFrame.Name = "RightControls"
    rightControlFrame.Size = UDim2.new(0, 120, 0, 200)
    rightControlFrame.Position = UDim2.new(1, -140, 1, -220)
    rightControlFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    rightControlFrame.BackgroundTransparency = 0.5
    rightControlFrame.BorderSizePixel = 0
    rightControlFrame.Parent = controlFrame
    
    -- Add corner radius
    local rightCorner = Instance.new("UICorner")
    rightCorner.CornerRadius = UDim.new(0, 12)
    rightCorner.Parent = rightControlFrame
    
    -- Throttle button
    local throttleButton = Instance.new("TextButton")
    throttleButton.Name = "ThrottleButton"
    throttleButton.Size = UDim2.new(1, -10, 0, 80)
    throttleButton.Position = UDim2.new(0, 5, 0, 5)
    throttleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    throttleButton.Text = "THROTTLE"
    throttleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    throttleButton.TextScaled = true
    throttleButton.Font = Enum.Font.HighwayGothic
    throttleButton.BorderSizePixel = 0
    throttleButton.Parent = rightControlFrame
    
    local throttleCorner = Instance.new("UICorner")
    throttleCorner.CornerRadius = UDim.new(0, 8)
    throttleCorner.Parent = throttleButton
    
    -- Brake button
    local brakeButton = Instance.new("TextButton")
    brakeButton.Name = "BrakeButton"
    brakeButton.Size = UDim2.new(1, -10, 0, 80)
    brakeButton.Position = UDim2.new(0, 5, 0, 95)
    brakeButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    brakeButton.Text = "BRAKE"
    brakeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    brakeButton.TextScaled = true
    brakeButton.Font = Enum.Font.HighwayGothic
    brakeButton.BorderSizePixel = 0
    brakeButton.Parent = rightControlFrame
    
    local brakeCorner = Instance.new("UICorner")
    brakeCorner.CornerRadius = UDim.new(0, 8)
    brakeCorner.Parent = brakeButton
    
    -- Create steering control (left side)
    local leftControlFrame = Instance.new("Frame")
    leftControlFrame.Name = "LeftControls"
    leftControlFrame.Size = UDim2.new(0, 200, 0, 120)
    leftControlFrame.Position = UDim2.new(0, 20, 1, -140)
    leftControlFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    leftControlFrame.BackgroundTransparency = 0.5
    leftControlFrame.BorderSizePixel = 0
    leftControlFrame.Parent = controlFrame
    
    local leftCorner = Instance.new("UICorner")
    leftCorner.CornerRadius = UDim.new(0, 12)
    leftCorner.Parent = leftControlFrame
    
    -- Left steering button
    local leftSteerButton = Instance.new("TextButton")
    leftSteerButton.Name = "LeftSteerButton"
    leftSteerButton.Size = UDim2.new(0, 80, 1, -10)
    leftSteerButton.Position = UDim2.new(0, 5, 0, 5)
    leftSteerButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    leftSteerButton.Text = "◀"
    leftSteerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    leftSteerButton.TextScaled = true
    leftSteerButton.Font = Enum.Font.HighwayGothic
    leftSteerButton.BorderSizePixel = 0
    leftSteerButton.Parent = leftControlFrame
    
    local leftSteerCorner = Instance.new("UICorner")
    leftSteerCorner.CornerRadius = UDim.new(0, 8)
    leftSteerCorner.Parent = leftSteerButton
    
    -- Right steering button
    local rightSteerButton = Instance.new("TextButton")
    rightSteerButton.Name = "RightSteerButton"
    rightSteerButton.Size = UDim2.new(0, 80, 1, -10)
    rightSteerButton.Position = UDim2.new(0, 95, 0, 5)
    rightSteerButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    rightSteerButton.Text = "▶"
    rightSteerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    rightSteerButton.TextScaled = true
    rightSteerButton.Font = Enum.Font.HighwayGothic
    rightSteerButton.BorderSizePixel = 0
    rightSteerButton.Parent = leftControlFrame
    
    local rightSteerCorner = Instance.new("UICorner")
    rightSteerCorner.CornerRadius = UDim.new(0, 8)
    rightSteerCorner.Parent = rightSteerButton
    
    -- Spawn bike button
    local spawnButton = Instance.new("TextButton")
    spawnButton.Name = "SpawnButton"
    spawnButton.Size = UDim2.new(0, 100, 0, 50)
    spawnButton.Position = UDim2.new(0.5, -50, 0, 20)
    spawnButton.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
    spawnButton.Text = "SPAWN BIKE"
    spawnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    spawnButton.TextScaled = true
    spawnButton.Font = Enum.Font.HighwayGothic
    spawnButton.BorderSizePixel = 0
    spawnButton.Parent = controlFrame
    
    local spawnCorner = Instance.new("UICorner")
    spawnCorner.CornerRadius = UDim.new(0, 8)
    spawnCorner.Parent = spawnButton
    
    -- Connect mobile button events
    self:connectMobileButtons(throttleButton, brakeButton, leftSteerButton, rightSteerButton, spawnButton)
    
    self.mobileControls = mobileGui
end

function InputController:connectMobileButtons(throttleButton, brakeButton, leftSteerButton, rightSteerButton, spawnButton)
    -- Throttle button
    throttleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            self.targetInputValues.throttle = 1
        end
    end)
    
    throttleButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            self.targetInputValues.throttle = 0
        end
    end)
    
    -- Brake button
    brakeButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            self.targetInputValues.brake = 1
        end
    end)
    
    brakeButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            self.targetInputValues.brake = 0
        end
    end)
    
    -- Left steering button
    leftSteerButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            self.targetInputValues.steer = -1
        end
    end)
    
    leftSteerButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if self.targetInputValues.steer == -1 then
                self.targetInputValues.steer = 0
            end
        end
    end)
    
    -- Right steering button
    rightSteerButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            self.targetInputValues.steer = 1
        end
    end)
    
    rightSteerButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if self.targetInputValues.steer == 1 then
                self.targetInputValues.steer = 0
            end
        end
    end)
    
    -- Spawn button
    spawnButton.Activated:Connect(function()
        self:spawnBike()
    end)
end

function InputController:updateMobileInputs(touchPosition)
    -- This could be used for more advanced touch controls
    -- Like a virtual joystick for steering
    -- For now, we use the button-based approach above
end

function InputController:startInputLoop()
    -- Main input processing loop
    self.inputConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:updateInputSmoothing(deltaTime)
        self:sendInputToServer()
    end)
end

function InputController:updateInputSmoothing(deltaTime)
    -- Smooth input transitions for better bike control
    local smoothingFactor = math.min(deltaTime / INPUT_CONFIG.InputSmoothing, 1)
    
    -- Smooth throttle
    self.inputValues.throttle = self.inputValues.throttle + 
        (self.targetInputValues.throttle - self.inputValues.throttle) * smoothingFactor
    
    -- Smooth brake
    self.inputValues.brake = self.inputValues.brake + 
        (self.targetInputValues.brake - self.inputValues.brake) * smoothingFactor
    
    -- Smooth steering
    self.inputValues.steer = self.inputValues.steer + 
        (self.targetInputValues.steer - self.inputValues.steer) * smoothingFactor
    
    -- Apply dead zone
    if math.abs(self.inputValues.throttle) < INPUT_CONFIG.DeadZone then
        self.inputValues.throttle = 0
    end
    if math.abs(self.inputValues.brake) < INPUT_CONFIG.DeadZone then
        self.inputValues.brake = 0
    end
    if math.abs(self.inputValues.steer) < INPUT_CONFIG.DeadZone then
        self.inputValues.steer = 0
    end
end

function InputController:sendInputToServer()
    -- Send input values to server
    -- Only send if values have changed significantly to reduce network traffic
    local throttle = math.floor(self.inputValues.throttle * 100) / 100
    local brake = math.floor(self.inputValues.brake * 100) / 100
    local steer = math.floor(self.inputValues.steer * 100) / 100
    
    if throttle ~= self.lastSentInputs.throttle then
        bikeControlEvent:FireServer("throttle", throttle)
        self.lastSentInputs.throttle = throttle
    end
    
    if brake ~= self.lastSentInputs.brake then
        bikeControlEvent:FireServer("brake", brake)
        self.lastSentInputs.brake = brake
    end
    
    if steer ~= self.lastSentInputs.steer then
        bikeControlEvent:FireServer("steer", steer)
        self.lastSentInputs.steer = steer
    end
end

function InputController:spawnBike()
    -- Request bike spawn from server
    spawnBikeEvent:FireServer()
end

function InputController:destroy()
    -- Clean up connections
    if self.inputConnection then
        self.inputConnection:Disconnect()
    end
    
    -- Remove mobile controls
    if self.mobileControls then
        self.mobileControls:Destroy()
    end
end

-- Initialize the input controller
local inputController = InputController.new()

return InputController
