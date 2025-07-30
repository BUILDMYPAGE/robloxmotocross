--[[
    Main.client.lua - Main Client Initialization Script
    
    This script should be placed in StarterPlayerScripts and will initialize
    the client-side components of the motocross racing game.
    
    It handles:
    - Loading client modules
    - Setting up UI components
    - Handling server communication
    - Managing local game state
    
    Usage: Place in StarterPlayer > StarterPlayerScripts
--]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🏁 Motocross Racing Game - Client Starting...")

-- Wait for RemoteEvents to be available
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteEvents then
    warn("❌ RemoteEvents not found! Client may not function properly.")
    return
end

-- Wait for required RemoteEvents
local bikeControlEvent = remoteEvents:WaitForChild("BikeControl", 5)
local raceUpdateEvent = remoteEvents:WaitForChild("RaceUpdate", 5)
local spawnBikeEvent = remoteEvents:WaitForChild("SpawnBike", 5)
local gameStateEvent = remoteEvents:WaitForChild("GameState", 5)

-- Check if all required events are available
if not bikeControlEvent or not raceUpdateEvent or not spawnBikeEvent or not gameStateEvent then
    warn("⚠️ Some RemoteEvents are missing. Client functionality may be limited.")
end

-- Try to load shared configuration
local GameConfig = nil
local configScript = script.Parent.Parent:FindFirstChild("shared")
if configScript then
    configScript = configScript:FindFirstChild("GameConfig")
    if configScript then
        local success, result = pcall(require, configScript)
        if success then
            GameConfig = result
            print("✅ Game configuration loaded on client")
        else
            warn("⚠️ Failed to load GameConfig: " .. tostring(result))
        end
    end
end

-- Fallback configuration if shared config isn't available
if not GameConfig then
    GameConfig = {
        Input = {
            ThrottleKeys = {"W", "Up"},
            BrakeKeys = {"S", "Down"},
            SteerLeftKeys = {"A", "Left"},
            SteerRightKeys = {"D", "Right"},
            SpawnBikeKey = "R"
        },
        UI = {
            PrimaryColor = Color3.fromRGB(255, 215, 0),
            BackgroundColor = Color3.fromRGB(30, 30, 30),
            TextColor = Color3.fromRGB(255, 255, 255)
        }
    }
    print("⚠️ Using fallback configuration")
end

-- Client state
local clientState = {
    gameConnected = false,
    bikeSpawned = false,
    inputController = nil,
    uiManager = nil,
    raceData = {},
    lastServerUpdate = 0
}

-- Safe module loading function
local function safeRequire(modulePath, moduleName)
    local success, result = pcall(require, modulePath)
    if success then
        print("✅ " .. moduleName .. " loaded successfully")
        return result
    else
        warn("❌ Failed to load " .. moduleName .. ": " .. tostring(result))
        return nil
    end
end

-- Simple input controller fallback
local SimpleBikeControls = {}
SimpleBikeControls.__index = SimpleBikeControls

function SimpleBikeControls.new()
    local self = setmetatable({}, SimpleBikeControls)
    self.inputValues = {throttle = 0, brake = 0, steer = 0}
    self.keysPressed = {}
    
    -- Connect input events
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        self:handleInput(input, true)
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        self:handleInput(input, false)
    end)
    
    -- Send input updates
    RunService.Heartbeat:Connect(function()
        self:updateInputs()
    end)
    
    return self
end

function SimpleBikeControls:handleInput(input, isPressed)
    local keyName = input.KeyCode.Name
    
    print("🎹 CLIENT INPUT: " .. keyName .. " - " .. tostring(isPressed))
    
    if keyName == "R" and isPressed then
        -- Spawn bike
        print("🏍️ R KEY PRESSED - Attempting to spawn bike...")
        if spawnBikeEvent then
            spawnBikeEvent:FireServer()
            print("🏍️ Spawn request sent to server!")
        else
            print("❌ spawnBikeEvent is nil!")
        end
        return
    end
    
    -- Track key states
    self.keysPressed[keyName] = isPressed
    
    -- Update input values
    self.inputValues.throttle = (self.keysPressed["W"] or self.keysPressed["Up"]) and 1 or 0
    self.inputValues.brake = (self.keysPressed["S"] or self.keysPressed["Down"]) and 1 or 0
    
    local steerLeft = self.keysPressed["A"] or self.keysPressed["Left"]
    local steerRight = self.keysPressed["D"] or self.keysPressed["Right"]
    
    if steerLeft and not steerRight then
        self.inputValues.steer = -1
    elseif steerRight and not steerLeft then
        self.inputValues.steer = 1
    else
        self.inputValues.steer = 0
    end
end

function SimpleBikeControls:updateInputs()
    if not bikeControlEvent then return end
    
    -- More aggressive throttling to prevent queue overflow
    local currentTime = tick()
    if currentTime - (self.lastInputSent or 0) < 0.1 then -- Only send every 0.1 seconds (10 FPS)
        return
    end
    
    -- Only send if there are actual changes to prevent spam
    local newValues = {
        throttle = self.inputValues.throttle,
        brake = self.inputValues.brake,
        steer = self.inputValues.steer
    }
    
    local lastValues = self.lastSentValues or {throttle = 0, brake = 0, steer = 0}
    
    -- Check if any values changed
    local hasChanges = false
    for key, value in pairs(newValues) do
        if math.abs(value - (lastValues[key] or 0)) > 0.01 then
            hasChanges = true
            break
        end
    end
    
    -- Only send if there are changes or if it's been a while since last update
    if hasChanges or (currentTime - (self.lastInputSent or 0)) > 1.0 then
        -- Send all inputs in one event to reduce network traffic
        bikeControlEvent:FireServer("allInputs", {
            throttle = newValues.throttle,
            brake = newValues.brake,
            steer = newValues.steer
        })
        
        self.lastInputSent = currentTime
        self.lastSentValues = newValues
    end
end

-- Simple UI manager fallback
local SimpleUI = {}
SimpleUI.__index = SimpleUI

function SimpleUI.new()
    local self = setmetatable({}, SimpleUI)
    
    -- Ensure all required methods exist
    self.updateStatus = SimpleUI.updateStatus
    self.showMessage = SimpleUI.showMessage
    self.createBasicUI = SimpleUI.createBasicUI
    
    self:createBasicUI()
    
    -- Verify the method exists after creation
    if not self.updateStatus then
        print("❌ updateStatus method missing after creation!")
        self.updateStatus = function(self, status)
            print("🔧 FALLBACK updateStatus called: " .. tostring(status))
        end
    end
    
    return self
end

function SimpleUI:createBasicUI()
    -- Create basic UI
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "MotocrossUI"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.Parent = playerGui
    
    -- Instructions frame
    local instructionsFrame = Instance.new("Frame")
    instructionsFrame.Size = UDim2.new(0, 300, 0, 150)
    instructionsFrame.Position = UDim2.new(0, 20, 1, -170)
    instructionsFrame.BackgroundColor3 = GameConfig.UI.BackgroundColor
    instructionsFrame.BackgroundTransparency = 0.3
    instructionsFrame.BorderSizePixel = 0
    instructionsFrame.Parent = self.screenGui
    
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
                            "• W/↑ - Throttle\n" ..
                            "• S/↓ - Brake\n" ..
                            "• A/← D/→ - Steer\n" ..
                            "• R - Spawn Bike\n\n" ..
                            "Type /help for more info"
    instructionsLabel.TextColor3 = GameConfig.UI.TextColor
    instructionsLabel.TextSize = 14
    instructionsLabel.Font = Enum.Font.Gotham
    instructionsLabel.TextXAlignment = Enum.TextXAlignment.Left
    instructionsLabel.TextYAlignment = Enum.TextYAlignment.Top
    instructionsLabel.Parent = instructionsFrame
    
    -- Status frame
    self.statusFrame = Instance.new("Frame")
    self.statusFrame.Size = UDim2.new(0, 250, 0, 80)
    self.statusFrame.Position = UDim2.new(0, 20, 0, 20)
    self.statusFrame.BackgroundColor3 = GameConfig.UI.BackgroundColor
    self.statusFrame.BackgroundTransparency = 0.3
    self.statusFrame.BorderSizePixel = 0
    self.statusFrame.Parent = self.screenGui
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 12)
    statusCorner.Parent = self.statusFrame
    
    self.statusLabel = Instance.new("TextLabel")
    self.statusLabel.Size = UDim2.new(1, -20, 1, -20)
    self.statusLabel.Position = UDim2.new(0, 10, 0, 10)
    self.statusLabel.BackgroundTransparency = 1
    self.statusLabel.Text = "🏁 GAME STATUS\nConnecting to server..."
    self.statusLabel.TextColor3 = GameConfig.UI.TextColor
    self.statusLabel.TextSize = 14
    self.statusLabel.Font = Enum.Font.Gotham
    self.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    self.statusLabel.Parent = self.statusFrame
    
    print("✅ Basic UI created")
end

function SimpleUI:updateStatus(status)
    if self.statusLabel then
        self.statusLabel.Text = "🏁 GAME STATUS\n" .. status
    end
end

function SimpleUI:showMessage(title, message)
    -- Create popup message
    local messageFrame = Instance.new("Frame")
    messageFrame.Size = UDim2.new(0, 400, 0, 200)
    messageFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
    messageFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    messageFrame.BackgroundTransparency = 0.2
    messageFrame.BorderSizePixel = 0
    messageFrame.Parent = self.screenGui
    
    local messageCorner = Instance.new("UICorner")
    messageCorner.CornerRadius = UDim.new(0, 16)
    messageCorner.Parent = messageFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 40)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = GameConfig.UI.PrimaryColor
    titleLabel.TextSize = 24
    titleLabel.Font = Enum.Font.HighwayGothic
    titleLabel.Parent = messageFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 1, -60)
    messageLabel.Position = UDim2.new(0, 10, 0, 50)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = GameConfig.UI.TextColor
    messageLabel.TextSize = 16
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.Parent = messageFrame
    
    -- Auto-hide after 5 seconds
    game:GetService("Debris"):AddItem(messageFrame, 5)
    
    -- Animate in
    messageFrame.Size = UDim2.new(0, 0, 0, 0)
    local showTween = TweenService:Create(
        messageFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 400, 0, 200)}
    )
    showTween:Play()
end

-- Initialize client systems
local function initializeClient()
    print("🎮 Initializing Motocross Racing Client...")
    
    -- Try to load advanced modules
    local InputController = nil
    local UIManager = nil
    
    -- Check if we have the full module structure
    -- Look for modules in the same folder as this script
    local inputScript = script.Parent:FindFirstChild("InputController")
    local uiScript = script.Parent:FindFirstChild("UIManager")
    
    if inputScript then
        InputController = safeRequire(inputScript, "InputController")
    end
    
    if uiScript then
        UIManager = safeRequire(uiScript, "UIManager")
    end
    
    -- Initialize input controller
    if InputController then
        clientState.inputController = InputController.new()
        print("✅ Advanced input controller initialized")
    else
        clientState.inputController = SimpleBikeControls.new()
        print("⚠️ Using basic input controller")
    end
    
    -- Initialize UI manager
    if UIManager then
        clientState.uiManager = UIManager.new()
        print("✅ Advanced UI manager initialized")
    else
        print("⚠️ UIManager module not found, creating SimpleUI...")
        clientState.uiManager = SimpleUI.new()
        print("⚠️ Using basic UI manager")
        
        -- Debug the UI manager object
        if clientState.uiManager then
            print("🔍 UI Manager created successfully")
            print("🔍 UI Manager type:", typeof(clientState.uiManager))
            print("🔍 updateStatus method exists:", clientState.uiManager.updateStatus and "YES" or "NO")
            
            -- List all methods available
            print("🔍 Available methods:")
            for key, value in pairs(clientState.uiManager) do
                if type(value) == "function" then
                    print("   - " .. key)
                end
            end
            
            -- Add updateStatus method if it's missing
            if not clientState.uiManager.updateStatus then
                print("🔧 Adding missing updateStatus method...")
                clientState.uiManager.updateStatus = function(self, status)
                    print("📢 STATUS UPDATE: " .. tostring(status))
                    if self.statusLabel then
                        self.statusLabel.Text = "🏁 GAME STATUS\n" .. status
                    end
                end
            end
        else
            print("❌ Failed to create UI Manager!")
        end
    end
    
    -- Setup server event handlers
    if gameStateEvent then
        gameStateEvent.OnClientEvent:Connect(function(data)
            handleServerMessage(data)
        end)
    end
    
    if raceUpdateEvent then
        raceUpdateEvent.OnClientEvent:Connect(function(raceData)
            clientState.raceData = raceData
            clientState.lastServerUpdate = tick()
            
            if clientState.uiManager and clientState.uiManager.updateRaceData then
                clientState.uiManager:updateRaceData(raceData)
            end
        end)
    end
    
    clientState.gameConnected = true
    if clientState.uiManager and clientState.uiManager.updateStatus then
        clientState.uiManager:updateStatus("Connected! Press R to spawn bike")
    else
        print("⚠️ UI Manager updateStatus method not available")
    end
    
    print("✅ Client initialization complete!")
end

-- Handle server messages
function handleServerMessage(data)
    if not data then return end
    
    if data.type == "welcome" then
        clientState.uiManager:showMessage("WELCOME!", data.message)
    elseif data.type == "help" then
        clientState.uiManager:showMessage("HELP", data.message)
    elseif data.type == "status" then
        clientState.uiManager:showMessage("SERVER STATUS", data.message)
    elseif data.type == "serverReady" then
        local status = "Server Ready"
        if data.gameInitialized then
            status = status .. "\nFull game features available"
        else
            status = status .. "\nBasic mode only"
        end
        if clientState.uiManager and clientState.uiManager.updateStatus then
            clientState.uiManager:updateStatus(status)
        else
            print("⚠️ UI Manager updateStatus method not available for server ready message")
        end
    end
end

-- Handle character respawning
player.CharacterAdded:Connect(function(character)
    print("🏍️ Character spawned for " .. player.Name)
    
    -- Reset bike spawned state
    clientState.bikeSpawned = false
    
    -- Update UI
    if clientState.uiManager and clientState.uiManager.updateStatus then
        clientState.uiManager:updateStatus("Character ready! Press R to spawn bike")
    else
        print("⚠️ UI Manager updateStatus method not available for character spawn")
    end
end)

-- Start client initialization
spawn(function()
    -- Wait a moment for everything to load
    wait(1)
    initializeClient()
end)

-- Chat commands
player.Chatted:Connect(function(message)
    local lowerMessage = message:lower()
    if lowerMessage:sub(1, 1) == "/" then
        -- Don't show chat commands in the chat
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "Command sent: " .. message;
            Color = Color3.fromRGB(255, 255, 0);
            Font = Enum.Font.Gotham;
            FontSize = Enum.FontSize.Size18;
        })
    end
end)

print("🚀 Motocross Racing Client is ready!")

-- Export global reference for debugging
_G.MotocrossClient = {
    state = clientState,
    config = GameConfig,
    version = "1.0.0"
}
