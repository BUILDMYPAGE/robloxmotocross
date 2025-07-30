--[[
    CleanPrototype.client.lua - Simple Client Controller
    
    This handles the client-side input for the motocross bike prototype.
    It's designed to work with CleanPrototype.server.lua
    
    Place this in StarterPlayerScripts (StarterPlayer > StarterPlayerScripts)
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

print("🏁 CLEAN MOTOCROSS CLIENT STARTING...")

-- Wait for RemoteEvents (try both old and new names)
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteEvents then
    warn("❌ RemoteEvents not found!")
    return
end

-- Try to get the clean events first, fallback to old names
local spawnBikeEvent = remoteEvents:FindFirstChild("CleanSpawnBike") or remoteEvents:WaitForChild("SpawnBike", 5)
local bikeControlEvent = remoteEvents:FindFirstChild("CleanBikeControl") or remoteEvents:WaitForChild("BikeControl", 5)

if not spawnBikeEvent or not bikeControlEvent then
    warn("❌ Required RemoteEvents not found!")
    return
end

print("✅ RemoteEvents connected (using " .. spawnBikeEvent.Name .. " and " .. bikeControlEvent.Name .. ")")

-- Input state
local inputState = {
    throttle = 0,
    brake = 0,
    steer = 0
}

local lastSentInputs = {
    throttle = 0,
    brake = 0,
    steer = 0
}

local keysPressed = {}

-- Handle input
local function handleInput(input, isPressed)
    local keyName = input.KeyCode.Name
    
    -- Handle bike spawning
    if keyName == "R" and isPressed then
        print("🏍️ Requesting bike spawn...")
        spawnBikeEvent:FireServer()
        
        -- Show feedback
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "🏍️ Spawning bike...";
            Color = Color3.fromRGB(0, 255, 0);
            Font = Enum.Font.Gotham;
            FontSize = Enum.FontSize.Size18;
        })
        return
    end
    
    -- Track key states
    keysPressed[keyName] = isPressed
    
    -- Update input values based on key states
    -- Throttle (W or Up Arrow)
    inputState.throttle = (keysPressed["W"] or keysPressed["Up"]) and 1 or 0
    
    -- Brake (S or Down Arrow)
    inputState.brake = (keysPressed["S"] or keysPressed["Down"]) and 1 or 0
    
    -- Steering (A/D or Left/Right Arrows)
    local steerLeft = keysPressed["A"] or keysPressed["Left"]
    local steerRight = keysPressed["D"] or keysPressed["Right"]
    
    if steerLeft and not steerRight then
        inputState.steer = -1
    elseif steerRight and not steerLeft then
        inputState.steer = 1
    else
        inputState.steer = 0
    end
    
    -- Debug output
    if isPressed then
        print("🎹 Key pressed: " .. keyName)
        print("🎮 Input state: Throttle=" .. inputState.throttle .. 
              ", Brake=" .. inputState.brake .. 
              ", Steer=" .. inputState.steer)
    end
end

-- Connect input events
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    handleInput(input, true)
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    handleInput(input, false)
end)

-- Send input to server (with throttling to reduce network traffic)
local lastInputSent = 0
local function sendInputToServer()
    local currentTime = tick()
    
    -- Only send if enough time has passed (30 FPS max for input)
    if currentTime - lastInputSent < 0.033 then
        return
    end
    
    -- Only send inputs that have changed
    local inputsChanged = false
    
    if inputState.throttle ~= lastSentInputs.throttle then
        bikeControlEvent:FireServer("throttle", inputState.throttle)
        lastSentInputs.throttle = inputState.throttle
        inputsChanged = true
    end
    
    if inputState.brake ~= lastSentInputs.brake then
        bikeControlEvent:FireServer("brake", inputState.brake)
        lastSentInputs.brake = inputState.brake
        inputsChanged = true
    end
    
    if inputState.steer ~= lastSentInputs.steer then
        bikeControlEvent:FireServer("steer", inputState.steer)
        lastSentInputs.steer = inputState.steer
        inputsChanged = true
    end
    
    if inputsChanged then
        lastInputSent = currentTime
        print("📡 Sent inputs to server: T=" .. inputState.throttle .. 
              ", B=" .. inputState.brake .. 
              ", S=" .. inputState.steer)
    end
end

-- Input update loop
RunService.Heartbeat:Connect(sendInputToServer)

-- Create simple UI
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MotocrossUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Instructions frame
    local instructionsFrame = Instance.new("Frame")
    instructionsFrame.Size = UDim2.new(0, 300, 0, 200)
    instructionsFrame.Position = UDim2.new(0, 20, 1, -220)
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
    instructionsLabel.Text = "🏍️ MOTOCROSS RACING\n\n" ..
                            "CONTROLS:\n" ..
                            "• R - Spawn Bike\n" ..
                            "• W / ↑ - Throttle\n" ..
                            "• S / ↓ - Brake\n" ..
                            "• A / ← - Turn Left\n" ..
                            "• D / → - Turn Right\n\n" ..
                            "Have fun racing!"
    instructionsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    instructionsLabel.TextSize = 16
    instructionsLabel.Font = Enum.Font.Gotham
    instructionsLabel.TextXAlignment = Enum.TextXAlignment.Left
    instructionsLabel.TextYAlignment = Enum.TextYAlignment.Top
    instructionsLabel.Parent = instructionsFrame
    
    -- Status display
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(0, 250, 0, 100)
    statusFrame.Position = UDim2.new(0, 20, 0, 20)
    statusFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statusFrame.BackgroundTransparency = 0.3
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = screenGui
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 12)
    statusCorner.Parent = statusFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 1, -20)
    statusLabel.Position = UDim2.new(0, 10, 0, 10)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🏁 CLEAN PROTOTYPE\n\nReady to race!\nPress R to spawn bike"
    statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    statusLabel.TextSize = 16
    statusLabel.Font = Enum.Font.HighwayGothic
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.Parent = statusFrame
    
    print("✅ UI created")
end

-- Create UI when player spawns
player.CharacterAdded:Connect(function(character)
    print("🏃 Character spawned")
    wait(1)
    createUI()
end)

-- Create UI immediately if character already exists
if player.Character then
    createUI()
end

-- Welcome message
wait(2)
StarterGui:SetCore("ChatMakeSystemMessage", {
    Text = "🏍️ Welcome to Clean Motocross Prototype! Press R to spawn your bike!";
    Color = Color3.fromRGB(255, 215, 0);
    Font = Enum.Font.HighwayGothic;
    FontSize = Enum.FontSize.Size18;
})

print("🚀 CLEAN MOTOCROSS CLIENT READY!")
print("📋 Press R to spawn bike, WASD to drive!")
