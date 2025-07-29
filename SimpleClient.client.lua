-- SimpleClient.client.lua - Simplified client that WORKS
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

print("🏁 Simple Motocross Client Starting...")

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteEvents then
    warn("❌ RemoteEvents not found!")
    return
end

local spawnBikeEvent = remoteEvents:WaitForChild("SpawnBike", 5)
local bikeControlEvent = remoteEvents:WaitForChild("BikeControl", 5)

if not spawnBikeEvent or not bikeControlEvent then
    warn("❌ Required events not found!")
    return
end

print("✅ Connected to server events")

-- Input tracking
local keysPressed = {}
local inputValues = {
    throttle = 0,
    brake = 0,
    steer = 0
}
local lastInputSent = 0

-- Handle input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local keyName = input.KeyCode.Name
    
    if keyName == "R" then
        print("🏍️ R pressed - requesting bike spawn...")
        if spawnBikeEvent then
            spawnBikeEvent:FireServer()
            print("✅ Spawn request sent to server")
        else
            print("❌ spawnBikeEvent not found!")
        end
        return
    end
    
    -- Track WASD keys
    keysPressed[keyName] = true
    updateInputValues()
    print("🎮 Key pressed: " .. keyName)
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local keyName = input.KeyCode.Name
    keysPressed[keyName] = false
    updateInputValues()
    print("🎮 Key released: " .. keyName)
end)

-- Update input values based on keys pressed
function updateInputValues()
    -- Throttle (W or Up Arrow)
    if keysPressed["W"] or keysPressed["Up"] then
        inputValues.throttle = 1
    else
        inputValues.throttle = 0
    end
    
    -- Brake (S or Down Arrow)
    if keysPressed["S"] or keysPressed["Down"] then
        inputValues.brake = 1
    else
        inputValues.brake = 0
    end
    
    -- Steering (A/D or Left/Right Arrow)
    local steerLeft = keysPressed["A"] or keysPressed["Left"]
    local steerRight = keysPressed["D"] or keysPressed["Right"]
    
    if steerLeft and not steerRight then
        inputValues.steer = -1
    elseif steerRight and not steerLeft then
        inputValues.steer = 1
    else
        inputValues.steer = 0
    end
end

-- Track if player has a bike
local hasBike = false

-- Send input to server at regular intervals - BUT ONLY IF BIKE EXISTS
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    -- Check if player has a bike in workspace
    local bikeName = player.Name .. "_Bike"
    local bike = workspace:FindFirstChild(bikeName)
    hasBike = bike ~= nil
    
    -- Only send input if bike exists AND we have actual input to send AND input values are 1 or -1 or 0
    if hasBike and currentTime - lastInputSent > 0.033 then
        local hasInput = inputValues.throttle ~= 0 or inputValues.brake ~= 0 or inputValues.steer ~= 0
        if hasInput then
            -- Send clean values (0, 1, or -1) not decimals
            bikeControlEvent:FireServer("throttle", inputValues.throttle)
            bikeControlEvent:FireServer("brake", inputValues.brake)
            bikeControlEvent:FireServer("steer", inputValues.steer)
        end
        lastInputSent = currentTime
    end
end)

-- Create simple UI
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleMotocrossUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Instructions frame
local instructionsFrame = Instance.new("Frame")
instructionsFrame.Size = UDim2.new(0, 300, 0, 100)
instructionsFrame.Position = UDim2.new(0, 20, 1, -120)
instructionsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
instructionsFrame.BackgroundTransparency = 0.3
instructionsFrame.BorderSizePixel = 0
instructionsFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = instructionsFrame

-- Instructions text
local instructionsLabel = Instance.new("TextLabel")
instructionsLabel.Size = UDim2.new(1, -20, 1, -20)
instructionsLabel.Position = UDim2.new(0, 10, 0, 10)
instructionsLabel.BackgroundTransparency = 1
instructionsLabel.Text = "🏍️ MOTOCROSS RACING\n\nCONTROLS:\n• R - Spawn Bike\n• W - Throttle (Forward)\n• S - Brake (Reverse)\n• A - Turn Left\n• D - Turn Right\n\nBike will auto-sit you!"
instructionsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
instructionsLabel.TextSize = 16
instructionsLabel.Font = Enum.Font.Gotham
instructionsLabel.TextXAlignment = Enum.TextXAlignment.Left
instructionsLabel.TextYAlignment = Enum.TextYAlignment.Top
instructionsLabel.Parent = instructionsFrame

print("✅ Simple UI created")
print("🚀 Simple Motocross Client Ready! Press R to spawn bike!")
